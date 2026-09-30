import Foundation

/// Why a session ended. The app keeps working locally and shows "Sign in again to keep your backup
/// up to date."; it never signs out silently.
public enum SessionEndReason: Sendable, Equatable {
    /// `SESSION_REVOKED`, or the refresh token stopped working.
    case revoked
    /// `DEVICE_REVOKED`: this phone was removed from the account. Stop syncing.
    case deviceRevoked
    /// The refresh token ran out (90 days unused, or 365 days after sign-in).
    case expired
}

/// The Focus API (02-backend.md, API). One per app.
///
/// - Bearer calls (B, BP) refresh the session first when under 2 minutes are left, and once more
///   after `TOKEN_EXPIRED` or `UNAUTHENTICATED`, then retry once. Refreshes are single flight:
///   every caller waiting on a stale token shares one `POST /auth/refresh`.
/// - Proof calls (P, BP) carry `X-Device-Id`, `X-Device-Timestamp` and `X-Device-Signature`. After
///   `DEVICE_PROOF_INVALID` the client corrects for the server's clock (from its `Date` header) and
///   retries once.
/// - `SESSION_REVOKED` and `DEVICE_REVOKED` end the session: tokens are cleared on this phone and the
///   session-ended handler runs. No other 4xx is retried. For 5xx and offline, callers that want it
///   use `withBackgroundRetry`.
/// - Creating POSTs send `Idempotency-Key`; pass the same key when retrying the same operation.
public actor APIClient {
    public nonisolated let configuration: APIConfiguration

    /// Refresh when less than this is left on the access token.
    public static let refreshLeeway: TimeInterval = 120

    let transport: any HTTPTransport
    let anonymousTransport: any HTTPTransport
    let sessionStore: SessionStore
    let now: @Sendable () -> Date
    private let loadIdentity: @Sendable () throws -> DeviceIdentity

    private var identity: DeviceIdentity?
    private var session: Session?
    private var sessionLoaded = false
    private var refreshTask: Task<Session, any Error>?
    private var clockOffset: TimeInterval = 0
    private var sessionEndedHandler: (@Sendable (SessionEndReason) -> Void)?

    /// - Parameters:
    ///   - identity: loads (or makes) this phone's device identity. Called once, lazily, off the main thread.
    ///   - transport: the API session (no cookies, no cache).
    ///   - anonymousTransport: a separate session for crash reports and usage counts; never carries a token.
    public init(configuration: APIConfiguration,
                sessionStore: SessionStore,
                identity: @escaping @Sendable () throws -> DeviceIdentity,
                transport: any HTTPTransport = URLSessionTransport.api(),
                anonymousTransport: any HTTPTransport = URLSessionTransport.anonymous(),
                now: @escaping @Sendable () -> Date = { Date() }) {
        self.configuration = configuration
        self.sessionStore = sessionStore
        self.loadIdentity = identity
        self.transport = transport
        self.anonymousTransport = anonymousTransport
        self.now = now
    }

    public static func newIdempotencyKey() -> String { UUID().wire }

    // MARK: Session state

    /// Runs when the server ends the session (revoked, device removed) or it runs out on this phone.
    public func setSessionEndedHandler(_ handler: (@Sendable (SessionEndReason) -> Void)?) {
        sessionEndedHandler = handler
    }

    public var hasSession: Bool { storedSession() != nil }

    public func currentSession() -> Session? { storedSession() }

    /// Keeps a session from a sign-in reply (the sign-in methods call this themselves).
    public func adopt(_ session: Session) throws {
        self.session = session
        sessionLoaded = true
        try sessionStore.save(session)
    }

    /// Forgets the tokens on this phone without telling the server.
    public func discardSession() {
        session = nil
        sessionLoaded = true
        sessionStore.clear()
    }

    public func deviceIdentity() throws -> DeviceIdentity {
        if let identity { return identity }
        let loaded = try loadIdentity()
        identity = loaded
        return loaded
    }

    /// The `device` object sent at sign-in.
    public func deviceRegistration() throws -> DeviceRegistration {
        try deviceIdentity().registration(appVersion: configuration.appVersion, osVersion: configuration.osVersion)
    }

    func storedSession() -> Session? {
        if !sessionLoaded {
            session = sessionStore.load()
            sessionLoaded = true
        }
        return session
    }

    // MARK: Refresh (single flight)

    /// Forces a refresh now. Concurrent callers share one request.
    public func refreshSession() async throws -> Session {
        try await refreshedSession(replacing: nil)
    }

    func usableSession() async throws -> Session {
        guard let current = storedSession() else { throw APIError.notSignedIn }
        guard current.refreshExpiresAt > now() else {
            endSession(.expired, refreshToken: current.refreshToken)
            throw APIError.notSignedIn
        }
        if current.accessExpiresAt.timeIntervalSince(now()) < Self.refreshLeeway {
            return try await refreshedSession(replacing: current.accessToken)
        }
        return current
    }

    /// `staleToken` is the access token a caller found stale or had refused. If someone else already
    /// replaced it, their fresh session is returned without another refresh, so a spent refresh
    /// token is never replayed.
    func refreshedSession(replacing staleToken: String?) async throws -> Session {
        if let refreshTask { return try await refreshTask.value }
        if let staleToken, let current = storedSession(), current.accessToken != staleToken,
           current.accessExpiresAt.timeIntervalSince(now()) >= Self.refreshLeeway {
            return current
        }
        let task = Task { try await self.performRefresh() }
        refreshTask = task
        defer { refreshTask = nil }
        return try await task.value
    }

    private func performRefresh() async throws -> Session {
        guard let current = storedSession() else { throw APIError.notSignedIn }
        guard current.refreshExpiresAt > now() else {
            endSession(.expired, refreshToken: current.refreshToken)
            throw APIError.notSignedIn
        }
        struct Body: Encodable { var refreshToken: String }
        let endpoint = try Endpoint(method: "POST", path: "/auth/refresh", json: Body(refreshToken: current.refreshToken), auth: .proof)
        do {
            let fresh = try decode(Session.self, from: try await send(endpoint))
            // Keep going even if the Keychain write fails: this run still has a working session.
            try? adopt(fresh)
            return fresh
        } catch let APIError.server(error) {
            switch error.code {
            case .sessionRevoked, .unauthenticated, .tokenExpired:
                endSession(.revoked, refreshToken: current.refreshToken)
            case .deviceRevoked:
                endSession(.deviceRevoked, refreshToken: current.refreshToken)
            default:
                break
            }
            throw APIError.server(error)
        }
    }

    /// Clears the session only if it's still the one that failed, so a late reply can't end a newer
    /// session from a fresh sign-in.
    func endSession(_ reason: SessionEndReason, accessToken: String? = nil, refreshToken: String? = nil) {
        guard let current = storedSession() else { return }
        if let accessToken, current.accessToken != accessToken { return }
        if let refreshToken, current.refreshToken != refreshToken { return }
        session = nil
        sessionStore.clear()
        sessionEndedHandler?(reason)
    }

    // MARK: Sending

    func send(_ endpoint: Endpoint) async throws -> HTTPResponse {
        var refreshed = false
        var proofRetried = false
        while true {
            try Task.checkCancellation()
            var accessToken: String?
            if endpoint.auth.usesBearer {
                accessToken = try await usableSession().accessToken
            }
            let request = try makeRequest(endpoint, accessToken: accessToken)
            let response = try await deliver(request, anonymous: endpoint.auth == .anonymous)
            if response.isSuccess || response.statusCode == 304 { return response }

            let error = ServerError(response: response, now: now())
            if endpoint.auth.usesBearer, !refreshed, error.code == .tokenExpired || error.code == .unauthenticated {
                refreshed = true
                _ = try await refreshedSession(replacing: accessToken)
                continue
            }
            if endpoint.auth.usesProof, !proofRetried, error.code == .deviceProofInvalid {
                proofRetried = true
                adjustClock(from: response)
                continue
            }
            if endpoint.auth.usesBearer, let accessToken {
                if error.code == .sessionRevoked { endSession(.revoked, accessToken: accessToken) }
                if error.code == .deviceRevoked { endSession(.deviceRevoked, accessToken: accessToken) }
            }
            throw APIError.server(error)
        }
    }

    func makeRequest(_ endpoint: Endpoint, accessToken: String?) throws -> HTTPRequest {
        let url = try endpoint.url(for: configuration)
        var headers: [String: String] = ["User-Agent": configuration.userAgent, "Accept": "application/json"]
        if endpoint.body != nil { headers["Content-Type"] = endpoint.contentType }
        if let accessToken { headers["Authorization"] = "Bearer \(accessToken)" }
        if let key = endpoint.idempotencyKey { headers["Idempotency-Key"] = key }
        for (name, value) in endpoint.headers { headers[name] = value }
        if endpoint.auth.usesProof {
            let proof = try DeviceProof(identity: deviceIdentity())
                .sign(method: endpoint.method, pathWithQuery: url.pathWithQuery, body: endpoint.body,
                      timestamp: now().addingTimeInterval(clockOffset))
            headers.merge(proof.dictionary) { _, new in new }
        }
        return HTTPRequest(method: endpoint.method, url: url, headers: headers, body: endpoint.body,
                           timeout: endpoint.timeout ?? configuration.requestTimeout)
    }

    func deliver(_ request: HTTPRequest, anonymous: Bool = false) async throws -> HTTPResponse {
        do {
            return try await (anonymous ? anonymousTransport : transport).send(request)
        } catch let error as APIError {
            throw error
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError {
            if error.code == .cancelled { throw CancellationError() }
            throw APIError.transport(TransportError(error))
        } catch {
            throw APIError.transport(TransportError(code: 0, message: String(describing: error), isOffline: false))
        }
    }

    /// Learns the server's clock from its `Date` header when a proof was refused.
    private func adjustClock(from response: HTTPResponse) {
        guard let header = response.header("Date") else { return }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "GMT")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        guard let serverTime = formatter.date(from: header) else { return }
        let offset = serverTime.timeIntervalSince(now())
        clockOffset = abs(offset) > 30 ? offset : 0
    }

    func decode<T: Decodable>(_ type: T.Type, from response: HTTPResponse) throws -> T {
        do {
            return try FocusJSON.decode(type, from: response.body)
        } catch {
            throw APIError.invalidResponse("Couldn’t read \(T.self): \(error)")
        }
    }
}

/// One API call, before auth and proofs are added.
struct Endpoint: Sendable {
    enum Host: Sendable { case api, cdn, root }

    enum Auth: Sendable, Equatable {
        /// N: no token.
        case none
        /// N on the separate ephemeral session: never a token, never a device id.
        case anonymous
        /// B.
        case bearer
        /// P.
        case proof
        /// BP.
        case bearerAndProof

        var usesBearer: Bool { self == .bearer || self == .bearerAndProof }
        var usesProof: Bool { self == .proof || self == .bearerAndProof }
    }

    var method: String
    /// Relative to the base, already percent-encoded, starting with `/`.
    var path: String
    var query: [(String, String)] = []
    var body: Data?
    var contentType = "application/json"
    var auth: Auth
    var host: Host = .api
    var idempotencyKey: String?
    var headers: [String: String] = [:]
    var timeout: TimeInterval?

    init(method: String, path: String, query: [(String, String)] = [], auth: Auth, host: Host = .api,
         idempotencyKey: String? = nil, timeout: TimeInterval? = nil) {
        self.method = method
        self.path = path
        self.query = query
        self.auth = auth
        self.host = host
        self.idempotencyKey = idempotencyKey
        self.timeout = timeout
    }

    init(method: String, path: String, json: some Encodable, auth: Auth, host: Host = .api,
         idempotencyKey: String? = nil, timeout: TimeInterval? = nil) throws {
        self.init(method: method, path: path, auth: auth, host: host, idempotencyKey: idempotencyKey, timeout: timeout)
        do { body = try FocusJSON.encode(json) } catch {
            throw APIError.invalidResponse("Couldn’t encode the request: \(error)")
        }
    }

    /// Escapes one path segment (ids, versions, kinds).
    static func segment(_ text: String) -> String { FormEncoding.escape(text) }

    func url(for configuration: APIConfiguration) throws -> URL {
        let base = switch host {
        case .api: configuration.baseURL
        case .cdn: configuration.cdnURL
        case .root: configuration.rootURL
        }
        var text = base.absoluteString
        while text.hasSuffix("/") { text.removeLast() }
        text += path
        if !query.isEmpty { text += "?" + FormEncoding.encode(query) }
        guard let url = URL(string: text) else { throw APIError.invalidResponse("Couldn’t build a URL for \(path).") }
        return url
    }
}
