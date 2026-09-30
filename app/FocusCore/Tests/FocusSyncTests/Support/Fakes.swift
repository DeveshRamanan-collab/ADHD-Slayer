import Foundation
import CryptoKit
import Synchronization
import Testing
@testable import FocusSync

/// Records every request and answers with a handler.
actor FakeTransport: HTTPTransport {
    typealias Handler = @Sendable (HTTPRequest) async throws -> HTTPResponse

    private var handler: Handler
    private(set) var requests: [HTTPRequest] = []

    init(_ handler: @escaping Handler = { _ in HTTPResponse(statusCode: 204) }) {
        self.handler = handler
    }

    func setHandler(_ handler: @escaping Handler) {
        self.handler = handler
    }

    func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        requests.append(request)
        return try await handler(request)
    }

    var last: HTTPRequest? { requests.last }

    func requests(path: String) -> [HTTPRequest] {
        requests.filter { $0.url.path(percentEncoded: true) == path }
    }

    func reset() {
        requests.removeAll()
    }
}

/// A settable clock.
final class TestClock: Sendable {
    private let current: Mutex<Date>

    init(_ start: Date = Date(timeIntervalSince1970: 1_790_000_000)) {
        current = Mutex(start)
    }

    var now: Date { current.withLock { $0 } }

    func advance(by seconds: TimeInterval) {
        current.withLock { $0 = $0.addingTimeInterval(seconds) }
    }

    var function: @Sendable () -> Date { { [self] in self.now } }
}

/// A value shared with handlers and closures.
final class Locked<Value: Sendable>: Sendable {
    private let mutex: Mutex<Value>

    init(_ value: Value) {
        mutex = Mutex(value)
    }

    var value: Value { mutex.withLock { $0 } }

    func set(_ value: Value) {
        mutex.withLock { $0 = value }
    }

    func append<Element>(_ element: Element) where Value == [Element] {
        mutex.withLock { $0.append(element) }
    }
}

/// A thread-safe counter for handlers.
final class Counter: Sendable {
    private let value = Mutex(0)
    @discardableResult func increment() -> Int { value.withLock { $0 += 1; return $0 } }
    var count: Int { value.withLock { $0 } }
}

enum Fixture {
    static let accountId = UUID(uuidString: "0199A1B2-0000-7000-8000-000000000001")!

    static let configuration = APIConfiguration(baseURL: URL(string: "https://api.test.focus/v1")!,
                                                cdnURL: URL(string: "https://cdn.test.focus/v1")!,
                                                appVersion: "1.2", build: "34", osVersion: "26.0")

    static let consents = Consents(termsVersion: 1, privacyVersion: 1, noticeVersion: 1,
                                   adultConfirmedAt: Date(timeIntervalSince1970: 1_789_999_000))

    static func identity(_ id: UUID = UUID()) -> DeviceIdentity {
        DeviceIdentity(deviceId: id, signingKey: P256.Signing.PrivateKey(), agreementKey: P256.KeyAgreement.PrivateKey())
    }

    static func session(now: Date, accessLeft: TimeInterval = 3600, access: String = "access-1", refresh: String = "refresh-1") -> Session {
        Session(accessToken: access, accessExpiresAt: now.addingTimeInterval(accessLeft),
                refreshToken: refresh, refreshExpiresAt: now.addingTimeInterval(90 * 86_400))
    }

    static func client(transport: FakeTransport, anonymous: FakeTransport? = nil, session: Session? = nil,
                       identity: DeviceIdentity = Fixture.identity(), clock: TestClock = TestClock(),
                       store: InMemorySecureStore = InMemorySecureStore()) throws -> APIClient {
        let sessions = SessionStore(store: store)
        if let session { try sessions.save(session) }
        return APIClient(configuration: configuration, sessionStore: sessions, identity: { identity },
                         transport: transport, anonymousTransport: anonymous ?? transport, now: clock.function)
    }

    static func json(_ status: Int, _ object: Any, headers: [String: String] = [:]) -> HTTPResponse {
        let body = (try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])) ?? Data()
        return HTTPResponse(statusCode: status, headers: headers.merging(["Content-Type": "application/json"]) { a, _ in a }, body: body)
    }

    static func error(_ status: Int, _ code: String, details: [String: Any]? = nil, retryAfterSeconds: Int? = nil,
                      headers: [String: String] = [:]) -> HTTPResponse {
        var error: [String: Any] = ["code": code, "message": "developer text"]
        if let details { error["details"] = details }
        if let retryAfterSeconds { error["retryAfterSeconds"] = retryAfterSeconds }
        return json(status, ["error": error], headers: headers)
    }

    static func sessionJSON(now: Date, access: String, refresh: String) -> [String: Any] {
        ["accessToken": access, "accessExpiresAt": FocusJSON.string(from: now.addingTimeInterval(3600)),
         "refreshToken": refresh, "refreshExpiresAt": FocusJSON.string(from: now.addingTimeInterval(90 * 86_400))]
    }

    static func signInJSON(now: Date, access: String = "access-new", refresh: String = "refresh-new") -> [String: Any] {
        ["accountId": accountId.uuidString.lowercased(), "isNewAccount": true,
         "session": sessionJSON(now: now, access: access, refresh: refresh),
         "identity": ["provider": "apple", "email": "sam@privaterelay.appleid.com", "isPrivateRelay": true],
         "backup": ["exists": false]]
    }
}

func bodyObject(_ request: HTTPRequest?) -> [String: Any] {
    guard let body = request?.body, let object = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else { return [:] }
    return object
}

/// Checks the proof headers the way the server does.
func proofIsValid(_ request: HTTPRequest, identity: DeviceIdentity) -> Bool {
    guard let id = request.header("X-Device-Id"), let timestamp = request.header("X-Device-Timestamp"),
          let signature = request.header("X-Device-Signature") else { return false }
    let headers = ProofHeaders(deviceId: id, timestamp: timestamp, signature: signature)
    return id == identity.deviceId.uuidString.lowercased()
        && DeviceProof.isValid(headers, method: request.method, pathWithQuery: request.pathWithQuery, body: request.body,
                               publicKey: identity.signingPublicKey)
}

/// `Tests/FocusSyncTests/Fixtures/<name>`, found from this source file (tests don't bundle resources).
func fixtureURL(_ name: String) -> URL {
    var directory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    while directory.lastPathComponent != "FocusSyncTests", directory.pathComponents.count > 1 {
        directory.deleteLastPathComponent()
    }
    return directory.appendingPathComponent("Fixtures").appendingPathComponent(name)
}
