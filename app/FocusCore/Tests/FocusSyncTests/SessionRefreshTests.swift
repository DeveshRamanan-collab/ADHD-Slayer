import Foundation
import Synchronization
import Testing
@testable import FocusSync

@Suite("Sessions: single-flight refresh, one retry, sessions ending (02-backend.md Sessions)")
struct SessionRefreshTests {
    let clock = TestClock()
    let identity = Fixture.identity()

    /// A server with one live access token; refresh rotates to the next pair and counts calls.
    private func rotatingServer(refreshes: Counter, liveAccess: Locked<String>, delay: Duration = .milliseconds(50)) -> FakeTransport {
        let now = clock.now
        let identity = identity
        return FakeTransport { request in
            if request.url.path() == "/v1/auth/refresh" {
                #expect(proofIsValid(request, identity: identity))
                #expect(request.header("Authorization") == nil)
                let number = refreshes.increment()
                try await Task.sleep(for: delay)
                let access = "access-\(number + 1)"
                liveAccess.set(access)
                #expect(bodyObject(request)["refreshToken"] as? String == "refresh-\(number)")
                return Fixture.json(200, Fixture.sessionJSON(now: now, access: access, refresh: "refresh-\(number + 1)"))
            }
            let live = liveAccess.value
            guard request.header("Authorization") == "Bearer \(live)" else { return Fixture.error(401, "TOKEN_EXPIRED") }
            return Fixture.json(200, ["version": 3])
        }
    }

    @Test func manyCallersShareOneRefreshAfterTokenExpired() async throws {
        let refreshes = Counter()
        let live = Locked("access-2") // the server already considers access-1 expired
        let transport = rotatingServer(refreshes: refreshes, liveAccess: live)
        // Locally the token still looks fresh, so every call first goes out with it and gets TOKEN_EXPIRED.
        let client = try Fixture.client(transport: transport, session: Fixture.session(now: clock.now, accessLeft: 3000),
                                        identity: identity, clock: clock)

        let versions = try await withThrowingTaskGroup(of: Int.self) { group in
            for _ in 0..<12 { group.addTask { try await client.syncState().version } }
            return try await group.reduce(into: []) { $0.append($1) }
        }

        #expect(versions == Array(repeating: 3, count: 12))
        #expect(refreshes.count == 1)
        #expect(await client.currentSession()?.accessToken == "access-2")
        #expect(await client.currentSession()?.refreshToken == "refresh-2")
    }

    @Test func refreshesFirstWhenUnderTwoMinutesAreLeft() async throws {
        let refreshes = Counter()
        let live = Locked("access-2")
        let transport = rotatingServer(refreshes: refreshes, liveAccess: live)
        let client = try Fixture.client(transport: transport, session: Fixture.session(now: clock.now, accessLeft: 90),
                                        identity: identity, clock: clock)

        async let a = client.syncState()
        async let b = client.syncState()
        async let c = client.account().accountId
        _ = try await (a, b)
        _ = try? await c

        #expect(refreshes.count == 1)
        // No request went out with the nearly expired token.
        let bearerRequests = await transport.requests.filter { $0.url.path() != "/v1/auth/refresh" }
        #expect(bearerRequests.allSatisfy { $0.header("Authorization") == "Bearer access-2" })
    }

    @Test func retriesOnlyOnceAfterARefresh() async throws {
        let refreshes = Counter()
        let transport = FakeTransport { [clock] request in
            if request.url.path() == "/v1/auth/refresh" {
                refreshes.increment()
                return Fixture.json(200, Fixture.sessionJSON(now: clock.now, access: "access-2", refresh: "refresh-2"))
            }
            return Fixture.error(401, "UNAUTHENTICATED")
        }
        let client = try Fixture.client(transport: transport, session: Fixture.session(now: clock.now), identity: identity, clock: clock)
        await #expect(throws: APIError.server(ServerError(status: 401, code: .unauthenticated, message: "developer text"))) {
            try await client.syncState()
        }
        #expect(refreshes.count == 1)
        #expect(await transport.requests(path: "/v1/sync/state").count == 2)
    }

    @Test func otherClientErrorsAreNotRetried() async throws {
        for (status, code) in [(422, "VALIDATION_ERROR"), (409, "SNAPSHOT_CONFLICT"), (403, "FORBIDDEN"), (404, "NOT_FOUND"),
                               (413, "QUOTA_EXCEEDED"), (426, "UPGRADE_REQUIRED"), (429, "RATE_LIMITED")] {
            let transport = FakeTransport { _ in Fixture.error(status, code) }
            let client = try Fixture.client(transport: transport, session: Fixture.session(now: clock.now), identity: identity, clock: clock)
            await #expect(throws: APIError.self) { try await client.syncState() }
            #expect(await transport.requests.count == 1, "\(code) was retried")
        }
    }

    @Test func serverErrorsAreLeftToTheBackgroundHelper() async throws {
        let transport = FakeTransport { _ in Fixture.error(500, "INTERNAL") }
        let client = try Fixture.client(transport: transport, session: Fixture.session(now: clock.now), identity: identity, clock: clock)
        await #expect(throws: APIError.self) { try await client.syncState() }
        #expect(await transport.requests.count == 1)
    }

    @Test func revokedSessionEndsLocallyAndTellsTheApp() async throws {
        let transport = FakeTransport { _ in Fixture.error(401, "SESSION_REVOKED") }
        let store = InMemorySecureStore()
        let client = try Fixture.client(transport: transport, session: Fixture.session(now: clock.now), identity: identity,
                                        clock: clock, store: store)
        let reasons = Locked<[SessionEndReason]>([])
        await client.setSessionEndedHandler { reason in reasons.append(reason) }

        await #expect(throws: APIError.self) { try await client.entitlement() }
        #expect(reasons.value == [.revoked])
        #expect(await client.hasSession == false)
        #expect(SessionStore(store: store).load() == nil)
        // Later calls fail fast without touching the network.
        await #expect(throws: APIError.notSignedIn) { try await client.entitlement() }
        #expect(await transport.requests.count == 1)
    }

    @Test func removedDeviceEndsTheSessionDuringRefresh() async throws {
        let transport = FakeTransport { _ in Fixture.error(401, "DEVICE_REVOKED") }
        let client = try Fixture.client(transport: transport, session: Fixture.session(now: clock.now, accessLeft: 10), identity: identity, clock: clock)
        let reasons = Locked<[SessionEndReason]>([])
        await client.setSessionEndedHandler { reason in reasons.append(reason) }
        await #expect(throws: APIError.self) { try await client.syncState() }
        #expect(reasons.value == [.deviceRevoked])
        #expect(await transport.requests.map { $0.url.path() } == ["/v1/auth/refresh"])
    }

    @Test func aLateRevocationCantEndANewerSession() async throws {
        let transport = FakeTransport { _ in Fixture.error(401, "SESSION_REVOKED") }
        let client = try Fixture.client(transport: transport, session: Fixture.session(now: clock.now), identity: identity, clock: clock)
        await client.setSessionEndedHandler { _ in Issue.record("The new session must stay") }
        let fresh = Fixture.session(now: clock.now, access: "access-new", refresh: "refresh-new")
        await client.endSession(.revoked, accessToken: "access-old")
        try await client.adopt(fresh)
        await client.endSession(.revoked, accessToken: "access-1")
        #expect(await client.currentSession() == fresh)
    }

    @Test func expiredRefreshTokenEndsTheSessionWithoutCallingTheServer() async throws {
        let transport = FakeTransport()
        var session = Fixture.session(now: clock.now, accessLeft: -10)
        session.refreshExpiresAt = clock.now.addingTimeInterval(-1)
        let client = try Fixture.client(transport: transport, session: session, identity: identity, clock: clock)
        let reasons = Locked<[SessionEndReason]>([])
        await client.setSessionEndedHandler { reason in reasons.append(reason) }
        await #expect(throws: APIError.notSignedIn) { try await client.syncState() }
        #expect(reasons.value == [.expired])
        #expect(await transport.requests.isEmpty)
    }

    @Test func deviceProofRetriesOnceWithTheServersClock() async throws {
        let attempts = Counter()
        let serverTime = clock.now.addingTimeInterval(600) // this phone's clock is 10 minutes slow
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "GMT")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
        let dateHeader = formatter.string(from: serverTime)
        let transport = FakeTransport { request in
            attempts.increment()
            let timestamp = Int(request.header("X-Device-Timestamp") ?? "") ?? 0
            guard abs(TimeInterval(timestamp) - serverTime.timeIntervalSince1970) <= 300 else {
                return Fixture.error(401, "DEVICE_PROOF_INVALID", headers: ["Date": dateHeader])
            }
            return Fixture.json(200, ["epoch": 1])
        }
        let client = try Fixture.client(transport: transport, session: Fixture.session(now: clock.now), identity: identity, clock: clock)
        #expect(try await client.keys().epoch == 1)
        #expect(attempts.count == 2)
        let proofs = await transport.requests.map { $0.header("X-Device-Signature") }
        #expect(proofs[0] != proofs[1])
    }

    @Test func deviceProofFailsAfterOneRetry() async throws {
        let transport = FakeTransport { _ in Fixture.error(401, "DEVICE_PROOF_INVALID") }
        let client = try Fixture.client(transport: transport, session: Fixture.session(now: clock.now), identity: identity, clock: clock)
        await #expect(throws: APIError.self) { try await client.keys() }
        #expect(await transport.requests.count == 2)
    }

    @Test func offlineKeepsTheSession() async throws {
        let transport = FakeTransport { _ in throw URLError(.notConnectedToInternet) }
        let client = try Fixture.client(transport: transport, session: Fixture.session(now: clock.now, accessLeft: 30), identity: identity, clock: clock)
        do {
            _ = try await client.syncState()
            Issue.record("Expected a transport error")
        } catch let error as APIError {
            #expect(error.isOffline)
            #expect(RetryPolicy.isRetryable(error))
        }
        #expect(await client.hasSession)
    }

    @Test func sessionsLiveInTheirTwoKeychainItems() throws {
        let store = InMemorySecureStore()
        let sessions = SessionStore(store: store)
        let session = Fixture.session(now: clock.now)
        try sessions.save(session)
        #expect(try store.allKeys() == ["session.access", "session.refresh"])
        #expect(sessions.load()?.accessToken == session.accessToken)
        #expect(abs((sessions.load()?.refreshExpiresAt.timeIntervalSince1970 ?? 0) - session.refreshExpiresAt.timeIntervalSince1970) < 0.001)
        // An app stopped between the two writes still has the newest refresh token and refreshes next time.
        try store.remove(SessionStore.accessKey)
        #expect(sessions.load()?.refreshToken == "refresh-1")
        #expect(sessions.load()?.accessExpiresAt == .distantPast)
        sessions.clear()
        #expect(sessions.load() == nil)
    }
}
