import Foundation
import CryptoKit
import Synchronization
import Testing
@testable import FocusSync

@Suite("Configuration, JSON, retries and signed content")
struct SupportingTests {
    @Test func configurationComesFromInfoPlist() throws {
        let info: [String: Any] = ["FocusAPIBaseURL": "https://api.focus.adhdslayer.au/v1/", "FocusCDNBaseURL": "https://cdn.focus.adhdslayer.au/v1",
                                   "CFBundleShortVersionString": "1.4", "CFBundleVersion": "88"]
        let configuration = try #require(APIConfiguration.resolve(infoDictionary: info, osVersion: "26.0.1"))
        #expect(configuration.baseURL.absoluteString == "https://api.focus.adhdslayer.au/v1")
        #expect(configuration.cdnURL.absoluteString == "https://cdn.focus.adhdslayer.au/v1")
        #expect(configuration.rootURL.absoluteString == "https://api.focus.adhdslayer.au/")
        #expect(configuration.userAgent == "Focus/1.4 (88; iOS 26.0.1)")
    }

    @Test func emptyBaseMeansNoServerUnlessDebugOverridesIt() throws {
        let info: [String: Any] = ["FocusAPIBaseURL": "", "FocusCDNBaseURL": "", "CFBundleShortVersionString": "0.1", "CFBundleVersion": "1"]
        #expect(APIConfiguration.resolve(infoDictionary: info) == nil)
        #expect(APIConfiguration.resolve(infoDictionary: ["FocusAPIBaseURL": "$(FOCUS_API_BASE_URL)"]) == nil)
        let environment = ["FOCUS_API_BASE_URL": "http://localhost:8080/v1"]
        #expect(APIConfiguration.resolve(infoDictionary: info, environment: environment, allowEnvironmentOverride: false) == nil)
        let local = try #require(APIConfiguration.resolve(infoDictionary: info, environment: environment, allowEnvironmentOverride: true))
        #expect(local.baseURL.absoluteString == "http://localhost:8080/v1")
        #expect(local.cdnURL == local.baseURL)
        #expect(APIConfiguration.resolve(infoDictionary: ["FocusAPIBaseURL": "ftp://example.com"]) == nil)
    }

    @Test func timesAreISO8601WithMillisecondsAndZ() throws {
        let date = Date(timeIntervalSince1970: 1_790_000_000.456)
        #expect(FocusJSON.string(from: date) == "2026-09-21T14:13:20.456Z")
        #expect(FocusJSON.date(from: "2026-09-21T14:13:20.456Z").map { abs($0.timeIntervalSince(date)) < 0.001 } == true)
        #expect(FocusJSON.date(from: "2026-09-21T14:13:20Z") == Date(timeIntervalSince1970: 1_790_000_000))
        // Formatting what was parsed gives the same text back, for every millisecond.
        for millisecond in stride(from: 0, to: 1000, by: 1) {
            let text = "2026-09-30T01:02:03.\(String(millisecond + 1000).dropFirst())Z"
            #expect(FocusJSON.string(from: try #require(FocusJSON.date(from: text))) == text)
        }
        #expect(FocusJSON.string(from: Date(timeIntervalSince1970: 1_790_000_000.9996)) == "2026-09-21T14:13:21.000Z")
        struct Wrapper: Codable { var at: Date }
        let json = String(data: try FocusJSON.encode(Wrapper(at: Date(timeIntervalSince1970: 0))), encoding: .utf8)
        #expect(json == #"{"at":"1970-01-01T00:00:00.000Z"}"#)
    }

    @Test func base64URLHasNoPaddingAndRejectsJunk() {
        #expect(Base64URL.encode(Data([0xFB, 0xFF])) == "-_8")
        #expect(Base64URL.decode("-_8") == Data([0xFB, 0xFF]))
        #expect(Base64URL.decode("-_8=") == Data([0xFB, 0xFF]))
        #expect(Base64URL.decode("+/8") == nil)
        #expect(Base64URL.decode("a") == nil)
        #expect(Hex.decode("0aFF") == Data([0x0A, 0xFF]))
        #expect(Hex.encode(Data([0x0A, 0xFF])) == "0aff")
    }

    @Test func backoffIsTwoToTheNWithJitterCappedAtSixHours() {
        let policy = RetryPolicy()
        #expect(policy.delay(afterAttempt: 1, unit: 0) == 1)
        #expect(policy.delay(afterAttempt: 1, unit: 1) == 2)
        #expect(policy.delay(afterAttempt: 5, unit: 0) == 16)
        #expect(policy.delay(afterAttempt: 5, unit: 1) == 32)
        for attempt in 1...40 {
            let low = policy.delay(afterAttempt: attempt, unit: 0)
            let high = policy.delay(afterAttempt: attempt, unit: 1)
            #expect(low <= high)
            #expect(high <= 6 * 3600)
        }
        #expect(policy.delay(afterAttempt: 30, unit: 1) == 21_600)
        #expect(policy.delay(afterAttempt: 1, retryAfter: 90, unit: 0) == 90)
    }

    @Test func onlyThingsWorthRetryingAreRetried() {
        #expect(RetryPolicy.isRetryable(APIError.transport(TransportError(URLError(.notConnectedToInternet)))))
        #expect(RetryPolicy.isRetryable(APIError.server(ServerError(status: 500, code: .internalError))))
        #expect(RetryPolicy.isRetryable(APIError.server(ServerError(status: 503, code: .servicePaused))))
        #expect(RetryPolicy.isRetryable(APIError.server(ServerError(status: 429, code: .rateLimited))))
        #expect(!RetryPolicy.isRetryable(APIError.server(ServerError(status: 422, code: .jwsInvalid))))
        #expect(!RetryPolicy.isRetryable(APIError.server(ServerError(status: 426, code: .upgradeRequired))))
        #expect(!RetryPolicy.isRetryable(APIError.notSignedIn))
        #expect(!RetryPolicy.isRetryable(CancellationError()))
    }

    @Test func backgroundRetryWaitsAndStops() async throws {
        let attempts = Counter()
        let waits = Locked<[Duration]>([])
        let value = try await withBackgroundRetry(sleep: { duration in waits.append(duration) }) {
            if attempts.increment() < 4 { throw APIError.server(ServerError(status: 503, code: .upstreamUnavailable)) }
            return "done"
        }
        #expect(value == "done")
        #expect(attempts.count == 4)
        let recorded = waits.value
        #expect(recorded.count == 3)
        #expect(recorded[0] >= .seconds(1) && recorded[0] <= .seconds(2))
        #expect(recorded[2] >= .seconds(4) && recorded[2] <= .seconds(8))

        let clientErrors = Counter()
        await #expect(throws: APIError.self) {
            try await withBackgroundRetry(sleep: { _ in }) {
                clientErrors.increment()
                throw APIError.server(ServerError(status: 422, code: .jwsInvalid))
            }
        }
        #expect(clientErrors.count == 1)

        let capped = Counter()
        await #expect(throws: APIError.self) {
            try await withBackgroundRetry(policy: RetryPolicy(maxAttempts: 3), sleep: { _ in }) {
                capped.increment()
                throw APIError.transport(TransportError(URLError(.timedOut)))
            }
        }
        #expect(capped.count == 3)

        let rateLimited = Locked<[Duration]>([])
        let limited = Counter()
        _ = try await withBackgroundRetry(sleep: { duration in rateLimited.append(duration) }) {
            if limited.increment() == 1 { throw APIError.server(ServerError(status: 429, code: .rateLimited, retryAfter: 120)) }
            return 1
        }
        #expect(rateLimited.value == [.seconds(120)])
    }

    @Test func signedConfigVerifiesWithTheBundledKey() throws {
        let signingKey = P256.Signing.PrivateKey()
        let body = Data(#"{"version":7,"issuedAt":"2026-09-30T00:00:00.000Z","expiresAt":"2026-10-07T00:00:00.000Z","flags":{"x":true},"killSwitches":{}}"#.utf8)
        let signature = Base64URL.encode(try signingKey.signature(for: body).rawRepresentation)
        let verifier = try SignedContentVerifier(publicKeys: ["config-2026-1": Base64URL.encode(signingKey.publicKey.x963Representation)])
        let document = SignedDocument(body: body, signature: signature, keyId: "config-2026-1", etag: nil)
        try verifier.verify(document)

        let config = try document.decode(RemoteConfig.self)
        #expect(config.version == 7)
        #expect(config.flags["x"]?.boolValue == true)
        try config.validate(now: FocusJSON.date(from: "2026-10-01T00:00:00.000Z")!, lastAcceptedVersion: 6)
        #expect(throws: SignedContentError.expired) { try config.validate(now: FocusJSON.date(from: "2026-10-08T00:00:00.000Z")!) }
        #expect(throws: SignedContentError.olderVersion) {
            try config.validate(now: FocusJSON.date(from: "2026-10-01T00:00:00.000Z")!, lastAcceptedVersion: 8)
        }

        var tampered = document
        tampered.body = Data(#"{"version":8}"#.utf8)
        #expect(throws: SignedContentError.badSignature) { try verifier.verify(tampered) }
        #expect(throws: SignedContentError.unknownKey("config-2027-1")) {
            try verifier.verify(SignedDocument(body: body, signature: signature, keyId: "config-2027-1", etag: nil))
        }
        #expect(throws: SignedContentError.missingSignature) {
            try verifier.verify(SignedDocument(body: body, signature: nil, keyId: nil, etag: nil))
        }
    }
}
