import Foundation
import CryptoKit
import Testing
@testable import FocusSync

@Suite("API requests: paths, auth, proofs, idempotency (02-backend.md API)")
struct APIRequestTests {
    let clock = TestClock()
    let identity = Fixture.identity(UUID(uuidString: "0199A1B2-C3D4-7E5F-8A9B-0C1D2E3F4A5B")!)

    private func signedInClient(_ transport: FakeTransport, anonymous: FakeTransport? = nil) throws -> APIClient {
        try Fixture.client(transport: transport, anonymous: anonymous, session: Fixture.session(now: clock.now),
                           identity: identity, clock: clock)
    }

    private func expectCommonHeaders(_ request: HTTPRequest?) {
        #expect(request?.header("User-Agent") == "Focus/1.2 (34; iOS 26.0)")
        #expect(request?.header("Accept") == "application/json")
    }

    // MARK: Sign-in

    @Test func appleSignInSendsCredentialDeviceAndConsentsWithoutAuth() async throws {
        let transport = FakeTransport { _ in Fixture.json(200, Fixture.signInJSON(now: Date(timeIntervalSince1970: 1_790_000_000))) }
        let client = try Fixture.client(transport: transport, identity: identity, clock: clock)

        let reply = try await client.signInWithApple(identityToken: "eyJ.apple", authorizationCode: "c0de", rawNonce: "raw-nonce",
                                                     appleUserId: "001234.abcd", consents: Fixture.consents, idempotencyKey: "key-1")

        let request = try #require(await transport.last)
        #expect(request.method == "POST")
        #expect(request.url.absoluteString == "https://api.test.focus/v1/auth/apple")
        #expect(request.header("Authorization") == nil)
        #expect(request.header("X-Device-Signature") == nil)
        #expect(request.header("Idempotency-Key") == "key-1")
        #expect(request.header("Content-Type") == "application/json")
        expectCommonHeaders(request)
        let body = bodyObject(request)
        #expect(body["identityToken"] as? String == "eyJ.apple")
        #expect(body["authorizationCode"] as? String == "c0de")
        #expect(body["rawNonce"] as? String == "raw-nonce")
        #expect(body["appleUserId"] as? String == "001234.abcd")
        let device = try #require(body["device"] as? [String: Any])
        #expect(device["deviceId"] as? String == "0199a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b")
        #expect(device["signingKey"] as? String == identity.signingKey)
        #expect(device["agreementKey"] as? String == identity.agreementKey)
        #expect(device["appVersion"] as? String == "1.2")
        #expect(device["osVersion"] as? String == "26.0")
        #expect((device["signingKey"] as? String).flatMap(Base64URL.decode)?.count == 65)
        let consents = try #require(body["consents"] as? [String: Any])
        #expect(consents["termsVersion"] as? Int == 1)
        #expect(consents["adultConfirmedAt"] as? String == "2026-09-21T13:56:40.000Z")
        // The session is kept.
        #expect(reply.accountId == Fixture.accountId)
        #expect(await client.currentSession()?.accessToken == "access-new")
    }

    @Test func googleAndEmailSignInShapes() async throws {
        let transport = FakeTransport { request in
            if request.url.path() == "/v1/auth/email/start" { return Fixture.json(202, ["resendAfterSeconds": 60, "expiresInSeconds": 900]) }
            return Fixture.json(200, Fixture.signInJSON(now: Date()))
        }
        let client = try Fixture.client(transport: transport, identity: identity, clock: clock)

        _ = try await client.signInWithGoogle(idToken: "eyJ.google", rawNonce: "n", consents: Fixture.consents)
        var body = bodyObject(await transport.last)
        #expect(await transport.last?.url.path() == "/v1/auth/google")
        #expect(body["idToken"] as? String == "eyJ.google")
        #expect(body["rawNonce"] as? String == "n")
        #expect(await transport.last?.header("Idempotency-Key") != nil)

        let start = try await client.startEmailSignIn(email: "sam@example.com", linkChallenge: "chal")
        #expect(start == EmailSignInStart(resendAfterSeconds: 60, expiresInSeconds: 900))
        body = bodyObject(await transport.last)
        #expect(body as NSDictionary == ["email": "sam@example.com", "deviceId": "0199a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b", "linkChallenge": "chal"])

        _ = try await client.verifyEmailSignIn(.link(token: "tok"), linkVerifier: "ver", consents: Fixture.consents)
        body = bodyObject(await transport.last)
        #expect(body["token"] as? String == "tok")
        #expect(body["email"] == nil)
        #expect(body["linkVerifier"] as? String == "ver")

        _ = try await client.verifyEmailSignIn(.code(email: "sam@example.com", code: "123456"), linkVerifier: "ver", consents: Fixture.consents)
        body = bodyObject(await transport.last)
        #expect(body["token"] == nil)
        #expect(body["email"] as? String == "sam@example.com")
        #expect(body["code"] as? String == "123456")
        #expect(await transport.last?.url.path() == "/v1/auth/email/verify")
    }

    @Test func logoutSendsBearerAndForgetsTheSessionEvenOffline() async throws {
        let transport = FakeTransport { _ in throw URLError(.notConnectedToInternet) }
        let store = InMemorySecureStore()
        let client = try Fixture.client(transport: transport, session: Fixture.session(now: clock.now), identity: identity,
                                        clock: clock, store: store)
        await client.logout()
        let request = try #require(await transport.last)
        #expect(request.method == "POST")
        #expect(request.url.path() == "/v1/auth/logout")
        #expect(request.header("Authorization") == "Bearer access-1")
        #expect(await client.hasSession == false)
        #expect(SessionStore(store: store).load() == nil)
    }

    // MARK: Account and devices

    @Test func accountCallsUseBearerAndDeletionAddsAProof() async throws {
        let transport = FakeTransport { request in
            switch (request.method, request.url.path()) {
            case ("GET", "/v1/account"):
                return Fixture.json(200, ["accountId": Fixture.accountId.uuidString.lowercased(), "status": "active",
                                          "identities": [["provider": "email", "email": "sam@example.com"]],
                                          "deviceCount": 2, "backup": ["exists": true, "epoch": 1, "version": 4],
                                          "entitlement": ["status": "someNewStatus"]])
            case ("DELETE", "/v1/account"):
                return Fixture.json(202, ["status": "deleting", "completesBy": "2026-10-01T01:02:03.456Z"])
            default:
                return HTTPResponse(statusCode: 204)
            }
        }
        let client = try signedInClient(transport)

        let account = try await client.account()
        #expect(account.status == .active)
        #expect(account.identities.first?.provider == .email)
        #expect(account.backup?.version == 4)
        #expect(account.entitlement?.status == .unknown)
        let get = try #require(await transport.last)
        #expect(get.header("Authorization") == "Bearer access-1")
        #expect(get.header("X-Device-Id") == nil)
        #expect(get.body == nil)

        try await client.acceptConsent(.privacy, version: 2, acceptedAt: Date(timeIntervalSince1970: 1_790_000_000))
        let put = try #require(await transport.last)
        #expect(put.method == "PUT")
        #expect(put.url.path() == "/v1/account/consents/privacy")
        #expect(bodyObject(put)["acceptedAt"] as? String == "2026-09-21T14:13:20.000Z")

        let deletion = try await client.deleteAccount()
        #expect(deletion.status == .deleting)
        #expect(deletion.completesBy == FocusJSON.date(from: "2026-10-01T01:02:03.456Z"))
        let delete = try #require(await transport.last)
        #expect(delete.method == "DELETE")
        #expect(delete.header("Authorization") == "Bearer access-1")
        #expect(bodyObject(delete)["confirm"] as? String == "DELETE")
        #expect(proofIsValid(delete, identity: identity))
    }

    @Test func deviceRoutes() async throws {
        let other = UUID()
        let transport = FakeTransport { request in
            if request.method == "GET" {
                return Fixture.json(200, ["devices": [["id": other.uuidString.lowercased(), "model": "iPhone16,2", "isCurrent": false,
                                                       "hasKeySlot": true, "lastSeenOn": "2026-09-29"]]])
            }
            return HTTPResponse(statusCode: 204)
        }
        let client = try signedInClient(transport)

        let devices = try await client.devices()
        #expect(devices.map(\.id) == [other])
        #expect(devices.first?.hasKeySlot == true)
        #expect(await transport.last?.header("X-Device-Id") == nil)

        try await client.updateCurrentDevice(model: "iPhone17,1")
        let put = try #require(await transport.last)
        #expect(put.url.path() == "/v1/devices/current")
        #expect(bodyObject(put) as NSDictionary == ["model": "iPhone17,1", "osVersion": "26.0", "appVersion": "1.2"])
        #expect(proofIsValid(put, identity: identity))

        try await client.removeDevice(other, reason: .lost)
        let delete = try #require(await transport.last)
        #expect(delete.url.path() == "/v1/devices/\(other.uuidString.lowercased())")
        #expect(bodyObject(delete)["reason"] as? String == "lost")
        #expect(proofIsValid(delete, identity: identity))
    }

    // MARK: Keys and key transfers

    @Test func keyRoutesCarryBearerAndProof() async throws {
        let transferId = UUID()
        let transport = FakeTransport { request in
            switch (request.method, request.url.path()) {
            case ("GET", "/v1/keys"):
                return Fixture.json(200, ["epoch": 3, "rotationRequired": true, "mySlot": NSNull(), "recovery": ["epoch": 3, "exists": true]])
            case ("POST", "/v1/keys/epochs"): return Fixture.json(201, ["epoch": 4])
            case ("POST", "/v1/key-transfers"):
                return Fixture.json(201, ["transferId": transferId.uuidString.lowercased(), "expiresAt": "2026-09-30T01:12:03.000Z"])
            case ("GET", _): return Fixture.json(200, ["state": "waiting", "agreementKey": "abc"])
            default: return HTTPResponse(statusCode: 204)
            }
        }
        let client = try signedInClient(transport)

        let keys = try await client.keys()
        #expect(keys == KeysState(epoch: 3, rotationRequired: true, mySlot: nil, recovery: RecoveryState(epoch: 3, exists: true)))
        #expect(proofIsValid(try #require(await transport.last), identity: identity))

        try await client.putDeviceSlot(SealedSlot(epoch: 3, enc: "e", ciphertext: "c"), for: identity.deviceId)
        let put = try #require(await transport.last)
        #expect(put.url.path() == "/v1/keys/slots/0199a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b")
        #expect(bodyObject(put) as NSDictionary == ["epoch": 3, "enc": "e", "ciphertext": "c"])
        #expect(proofIsValid(put, identity: identity))
        #expect(put.header("Authorization") == "Bearer access-1")

        let epoch = try await client.createEpoch(EpochChange(fromEpoch: 3, toEpoch: 4,
                                                             slots: [DeviceSlotUpload(deviceId: identity.deviceId, slot: SealedSlot(epoch: 4, enc: "e", ciphertext: "c"))],
                                                             recovery: SealedRecoverySlot(epoch: 4, nonce: "n", ciphertext: "c")),
                                                 idempotencyKey: "rotate-1")
        #expect(epoch == 4)
        let post = try #require(await transport.last)
        #expect(post.header("Idempotency-Key") == "rotate-1")
        let slots = try #require(bodyObject(post)["slots"] as? [[String: Any]])
        #expect(slots.first?["deviceId"] as? String == "0199a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b")
        #expect(proofIsValid(post, identity: identity))

        let ticket = try await client.createKeyTransfer(agreementKey: identity.agreementKey)
        #expect(ticket.transferId == transferId)
        let create = try #require(await transport.last)
        #expect(create.header("Idempotency-Key") != nil)
        #expect(proofIsValid(create, identity: identity))

        _ = try await client.keyTransfer(transferId)
        #expect(await transport.last?.url.path() == "/v1/key-transfers/\(transferId.uuidString.lowercased())")
        try await client.sealKeyTransfer(transferId, slot: SealedSlot(epoch: 3, enc: "e", ciphertext: "c"))
        let seal = try #require(await transport.last)
        #expect(seal.method == "PUT")
        #expect(seal.url.path() == "/v1/key-transfers/\(transferId.uuidString.lowercased())/sealed")
        #expect(proofIsValid(seal, identity: identity))
    }

    // MARK: Sync

    @Test func snapshotRoutesAndPresignedUploads() async throws {
        let snapshotId = UUID()
        let transport = FakeTransport { request in
            switch (request.method, request.url.host(), request.url.path()) {
            case ("POST", _, "/v1/sync/snapshots"):
                return Fixture.json(201, ["uploadUrl": "https://bucket.s3.test/x?sig=1",
                                          "uploadHeaders": ["Content-Type": "application/octet-stream", "Content-Length": 5,
                                                            "x-amz-checksum-sha256": "abc="],
                                          "expiresAt": "2026-09-30T01:17:03.000Z"])
            case ("GET", _, "/v1/sync/state"): return Fixture.json(200, ["version": 0])
            default: return HTTPResponse(statusCode: 200)
            }
        }
        let client = try signedInClient(transport)

        #expect(try await client.syncState() == SyncState(version: 0))
        #expect(await transport.last?.header("X-Device-Id") == nil)

        let ticket = try await client.startSnapshot(SnapshotStart(snapshotId: snapshotId, baseVersion: 0, epoch: 1, schema: 1,
                                                                  sizeBytes: 5, sha256: "digest"))
        #expect(ticket.uploadHeaders["Content-Length"] == "5")
        let start = try #require(await transport.last)
        #expect(start.header("Authorization") == "Bearer access-1")
        #expect(start.header("Idempotency-Key") != nil)
        #expect(bodyObject(start)["snapshotId"] as? String == snapshotId.uuidString.lowercased())

        try await client.uploadObject(to: ticket.uploadUrl, headers: ticket.uploadHeaders, body: Data("hello".utf8))
        let put = try #require(await transport.last)
        #expect(put.method == "PUT")
        #expect(put.url.absoluteString == "https://bucket.s3.test/x?sig=1")
        #expect(put.header("Authorization") == nil)
        #expect(put.header("X-Device-Signature") == nil)
        #expect(put.header("x-amz-checksum-sha256") == "abc=")
        #expect(put.header("Content-Type") == "application/octet-stream")

        _ = try? await client.commitSnapshot(snapshotId)
        #expect(await transport.last?.url.path() == "/v1/sync/snapshots/\(snapshotId.uuidString.lowercased())/commit")

        try await client.deleteBackup()
        let delete = try #require(await transport.last)
        #expect(delete.method == "DELETE")
        #expect(delete.url.path() == "/v1/sync")
        #expect(proofIsValid(delete, identity: identity))
    }

    @Test func laterBatchRoutesSignTheQueryString() async throws {
        let transport = FakeTransport { request in
            if request.method == "GET" { return Fixture.json(200, ["batches": [], "hasMore": false]) }
            return Fixture.json(201, ["cursor": 17, "duplicate": false])
        }
        let client = try signedInClient(transport)
        let page = try await client.syncBatches(after: "c/1 2", limit: 100)
        #expect(page.hasMore == false)
        #expect(await transport.last?.url.absoluteString == "https://api.test.focus/v1/sync/batches?after=c%2F1%202&limit=100")
        #expect(await transport.last?.pathWithQuery == "/v1/sync/batches?after=c%2F1%202&limit=100")

        let receipt = try await client.postSyncBatch(SyncBatchUpload(deviceId: identity.deviceId, seq: 7, epoch: 1, schema: 1,
                                                                     nonce: "n", ciphertext: "c", aadHash: "h"))
        #expect(receipt.cursor == "17")
        #expect(await transport.last?.header("Idempotency-Key") == "0199a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b.7")
    }

    // MARK: Entitlements, config, copy

    @Test func entitlementTransactionIsIdempotentByItsJWS() async throws {
        let transport = FakeTransport { _ in Fixture.json(200, ["status": "trial", "productId": "au.adhdslayer.focus.plus.yearly", "isTrial": true]) }
        let client = try signedInClient(transport)
        let entitlement = try await client.postTransaction(signedTransaction: "eyJ.jws.sig")
        #expect(entitlement.status == .trial)
        let first = try #require(await transport.last)
        #expect(first.url.path() == "/v1/entitlements/transactions")
        #expect(bodyObject(first)["signedTransaction"] as? String == "eyJ.jws.sig")
        _ = try await client.postTransaction(signedTransaction: "eyJ.jws.sig")
        #expect(await transport.last?.header("Idempotency-Key") == first.header("Idempotency-Key"))

        #expect(try await client.entitlement().status == .trial)
        #expect(await transport.last?.method == "GET")
    }

    @Test func configAndCopyComeFromTheCDNWithoutAnAccount() async throws {
        let transport = FakeTransport { request in
            if request.header("If-None-Match") == "\"v7\"" { return HTTPResponse(statusCode: 304) }
            return HTTPResponse(statusCode: 200, headers: ["Signature": "sig", "Signature-Key-Id": "config-2026-1", "ETag": "\"v7\""],
                                body: Data("{}".utf8))
        }
        let client = try signedInClient(transport)

        guard case .document(let document) = try await client.config(locale: "en-AU", region: "AU") else {
            Issue.record("Expected a document")
            return
        }
        #expect(document.keyId == "config-2026-1")
        #expect(document.etag == "\"v7\"")
        let request = try #require(await transport.last)
        #expect(request.url.absoluteString == "https://cdn.test.focus/v1/config?appVersion=1.2&build=34&locale=en-AU&region=AU")
        #expect(request.header("Authorization") == nil)
        #expect(request.header("X-Device-Id") == nil)
        #expect(request.timeout == 5)

        #expect(try await client.config(locale: "en-AU", region: "AU", etag: "\"v7\"") == .notModified)

        _ = try await client.copyDeck(version: "12")
        #expect(await transport.last?.url.absoluteString == "https://cdn.test.focus/v1/copy/decks/12")
    }

    // MARK: Diagnostics, analytics, support

    @Test func crashReportsAndUsageUseTheAnonymousSessionAndNoIdentity() async throws {
        let api = FakeTransport()
        let anonymous = FakeTransport { _ in HTTPResponse(statusCode: 202) }
        let client = try signedInClient(api, anonymous: anonymous)
        let reportId = UUID()
        try await client.submitCrashReport(CrashReport(reportId: reportId, diagnosticsId: UUID(), appVersion: "1.2", build: "34",
                                                       osVersion: "26.0", model: "iPhone17,1", kind: "crash",
                                                       payload: .object(["frames": .array([.string("0x1")])])))
        try await client.submitAnalyticsBatch(AnalyticsBatch(batchId: UUID(), analyticsId: UUID(), day: "2026-09-30",
                                                             versions: ["app": "1.2"], deviceFamily: "iPhone", locale: "en-AU",
                                                             region: "AU", aiState: "available", counters: ["tabsOpened": 3]))
        #expect(await api.requests.isEmpty)
        let sent = await anonymous.requests
        #expect(sent.map { $0.url.path() } == ["/v1/diagnostics/crashes", "/v1/analytics/batches"])
        for request in sent {
            #expect(request.header("Authorization") == nil)
            #expect(request.header("X-Device-Id") == nil)
            #expect(request.header("X-Device-Signature") == nil)
            #expect(!(String(data: request.body ?? Data(), encoding: .utf8) ?? "").contains("0199a1b2-c3d4"))
        }
        #expect(sent[0].header("Idempotency-Key") == reportId.uuidString.lowercased())
    }

    @Test func oversizedCrashReportsNeverLeave() async throws {
        let anonymous = FakeTransport()
        let client = try signedInClient(FakeTransport(), anonymous: anonymous)
        let big = JSONValue.string(String(repeating: "x", count: 300 * 1024))
        await #expect(throws: APIError.self) {
            try await client.submitCrashReport(CrashReport(reportId: UUID(), diagnosticsId: UUID(), appVersion: "1", build: "1",
                                                           osVersion: "26.0", model: "x", kind: "crash", payload: big))
        }
        #expect(await anonymous.requests.isEmpty)
    }

    @Test func supportUsesBearerWhenSignedInAndReplyEmailWhenNot() async throws {
        let transport = FakeTransport { _ in Fixture.json(201, ["reference": "FOC-1234"]) }
        let signedIn = try signedInClient(transport)
        let receipt = try await signedIn.submitSupportRequest(SupportRequest(topic: "backup", message: "Hi"))
        #expect(receipt.reference == "FOC-1234")
        #expect(await transport.last?.header("Authorization") == "Bearer access-1")
        #expect(await transport.last?.header("Idempotency-Key") != nil)

        let signedOut = try Fixture.client(transport: transport, identity: identity, clock: clock)
        await #expect(throws: APIError.self) { try await signedOut.submitSupportRequest(SupportRequest(topic: "x", message: "Hi")) }
        _ = try await signedOut.submitSupportRequest(SupportRequest(topic: "x", message: "Hi", replyEmail: "sam@example.com"))
        #expect(await transport.last?.header("Authorization") == nil)
    }

    @Test func healthIsOutsideV1() async throws {
        let transport = FakeTransport { _ in Fixture.json(200, ["status": "ok"]) }
        let client = try signedInClient(transport)
        #expect(await client.isHealthy())
        #expect(await transport.last?.url.absoluteString == "https://api.test.focus/healthz")
    }
}
