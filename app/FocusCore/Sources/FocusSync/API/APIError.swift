import Foundation

/// Every code in 02-backend.md "Error codes". Codes the app doesn't know yet read as `.unknown`.
public enum APIErrorCode: Sendable, Hashable, CustomStringConvertible {
    case validationError
    case unauthenticated
    case tokenExpired
    case sessionRevoked
    case deviceProofInvalid
    case deviceRevoked
    case forbidden
    case notFound
    case providerTokenInvalid
    case nonceMismatch
    case adultConfirmationRequired
    case linkInvalid
    case codeAttemptsExceeded
    case linkWrongDevice
    case accountDeletionPending
    case snapshotConflict
    case epochMismatch
    case uploadIncomplete
    case checksumMismatch
    case transferExpired
    case transferAlreadySealed
    case seqConflict
    case seqGap
    case idempotencyMismatch
    case payloadTooLarge
    case quotaExceeded
    case jwsInvalid
    case upstreamUnavailable
    case servicePaused
    case rateLimited
    case upgradeRequired
    case internalError
    case unknown(String)

    /// Every code the spec lists, in its order.
    public static let allKnown: [APIErrorCode] = [
        .validationError, .unauthenticated, .tokenExpired, .sessionRevoked, .deviceProofInvalid, .deviceRevoked,
        .forbidden, .notFound, .providerTokenInvalid, .nonceMismatch, .adultConfirmationRequired, .linkInvalid,
        .codeAttemptsExceeded, .linkWrongDevice, .accountDeletionPending, .snapshotConflict, .epochMismatch,
        .uploadIncomplete, .checksumMismatch, .transferExpired, .transferAlreadySealed, .seqConflict, .seqGap,
        .idempotencyMismatch, .payloadTooLarge, .quotaExceeded, .jwsInvalid, .upstreamUnavailable, .servicePaused,
        .rateLimited, .upgradeRequired, .internalError,
    ]

    private static let byRawValue: [String: APIErrorCode] =
        Dictionary(uniqueKeysWithValues: allKnown.map { ($0.rawValue, $0) })

    public init(rawValue: String) {
        self = Self.byRawValue[rawValue] ?? .unknown(rawValue)
    }

    public var rawValue: String {
        switch self {
        case .validationError: "VALIDATION_ERROR"
        case .unauthenticated: "UNAUTHENTICATED"
        case .tokenExpired: "TOKEN_EXPIRED"
        case .sessionRevoked: "SESSION_REVOKED"
        case .deviceProofInvalid: "DEVICE_PROOF_INVALID"
        case .deviceRevoked: "DEVICE_REVOKED"
        case .forbidden: "FORBIDDEN"
        case .notFound: "NOT_FOUND"
        case .providerTokenInvalid: "PROVIDER_TOKEN_INVALID"
        case .nonceMismatch: "NONCE_MISMATCH"
        case .adultConfirmationRequired: "ADULT_CONFIRMATION_REQUIRED"
        case .linkInvalid: "LINK_INVALID"
        case .codeAttemptsExceeded: "CODE_ATTEMPTS_EXCEEDED"
        case .linkWrongDevice: "LINK_WRONG_DEVICE"
        case .accountDeletionPending: "ACCOUNT_DELETION_PENDING"
        case .snapshotConflict: "SNAPSHOT_CONFLICT"
        case .epochMismatch: "EPOCH_MISMATCH"
        case .uploadIncomplete: "UPLOAD_INCOMPLETE"
        case .checksumMismatch: "CHECKSUM_MISMATCH"
        case .transferExpired: "TRANSFER_EXPIRED"
        case .transferAlreadySealed: "TRANSFER_ALREADY_SEALED"
        case .seqConflict: "SEQ_CONFLICT"
        case .seqGap: "SEQ_GAP"
        case .idempotencyMismatch: "IDEMPOTENCY_MISMATCH"
        case .payloadTooLarge: "PAYLOAD_TOO_LARGE"
        case .quotaExceeded: "QUOTA_EXCEEDED"
        case .jwsInvalid: "JWS_INVALID"
        case .upstreamUnavailable: "UPSTREAM_UNAVAILABLE"
        case .servicePaused: "SERVICE_PAUSED"
        case .rateLimited: "RATE_LIMITED"
        case .upgradeRequired: "UPGRADE_REQUIRED"
        case .internalError: "INTERNAL"
        case .unknown(let raw): raw
        }
    }

    /// The HTTP status the spec pairs with each code.
    public var documentedStatus: Int? {
        switch self {
        case .validationError, .adultConfirmationRequired, .checksumMismatch, .idempotencyMismatch, .jwsInvalid: 422
        case .unauthenticated, .tokenExpired, .sessionRevoked, .deviceProofInvalid, .deviceRevoked,
             .providerTokenInvalid, .nonceMismatch: 401
        case .forbidden, .linkWrongDevice: 403
        case .notFound: 404
        case .linkInvalid, .transferExpired: 410
        case .codeAttemptsExceeded, .rateLimited: 429
        case .accountDeletionPending, .snapshotConflict, .epochMismatch, .uploadIncomplete, .transferAlreadySealed,
             .seqConflict, .seqGap: 409
        case .payloadTooLarge, .quotaExceeded: 413
        case .upstreamUnavailable, .servicePaused: 503
        case .upgradeRequired: 426
        case .internalError: 500
        case .unknown: nil
        }
    }

    public var description: String { rawValue }

    /// A best guess when a reply has no error envelope (a load balancer page, for example).
    static func fallback(forStatus status: Int) -> APIErrorCode {
        switch status {
        case 401: .unauthenticated
        case 403: .forbidden
        case 404: .notFound
        case 413: .payloadTooLarge
        case 422: .validationError
        case 426: .upgradeRequired
        case 429: .rateLimited
        case 503: .upstreamUnavailable
        case 500...599: .internalError
        default: .unknown("HTTP_\(status)")
        }
    }
}

/// The server's error envelope: `{"error":{"code","message","details","retryAfterSeconds"}}`.
/// The app shows its own calm copy, never `message`.
public struct ServerError: Error, Sendable, Equatable, CustomStringConvertible {
    public var status: Int
    public var code: APIErrorCode
    /// Developer text. Never shown to the person.
    public var message: String?
    public var details: JSONValue?
    /// From `retryAfterSeconds` or the `Retry-After` header, whichever is longer.
    public var retryAfter: TimeInterval?

    public init(status: Int, code: APIErrorCode, message: String? = nil, details: JSONValue? = nil, retryAfter: TimeInterval? = nil) {
        self.status = status
        self.code = code
        self.message = message
        self.details = details
        self.retryAfter = retryAfter
    }

    /// Decodes the envelope; replies without one get a code from their status.
    public init(response: HTTPResponse, now: Date = Date()) {
        struct Envelope: Decodable {
            struct Body: Decodable {
                var code: String
                var message: String?
                var details: JSONValue?
                var retryAfterSeconds: Double?
            }
            var error: Body
        }
        let header = response.header("Retry-After").flatMap { Self.parseRetryAfter($0, now: now) }
        if let envelope = try? JSONDecoder().decode(Envelope.self, from: response.body) {
            let bodyDelay = envelope.error.retryAfterSeconds
            let delay: TimeInterval? = switch (bodyDelay, header) {
            case let (body?, header?): max(body, header)
            case let (body?, nil): body
            case let (nil, header?): header
            case (nil, nil): nil
            }
            self.init(status: response.statusCode, code: APIErrorCode(rawValue: envelope.error.code),
                      message: envelope.error.message, details: envelope.error.details, retryAfter: delay)
        } else {
            self.init(status: response.statusCode, code: .fallback(forStatus: response.statusCode), retryAfter: header)
        }
    }

    /// `Retry-After` is either whole seconds or an HTTP date.
    public static func parseRetryAfter(_ value: String, now: Date = Date()) -> TimeInterval? {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        if let seconds = Double(trimmed) { return max(0, seconds) }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "GMT")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        guard let date = formatter.date(from: trimmed) else { return nil }
        return max(0, date.timeIntervalSince(now))
    }

    public var description: String { "\(status) \(code.rawValue)" + (message.map { ": \($0)" } ?? "") }
}

/// A request that never got an answer: offline, timed out, DNS, TLS.
public struct TransportError: Error, Sendable, Equatable {
    /// `URLError.Code` raw value, or 0 when the failure wasn't a URL error.
    public var code: Int
    public var message: String
    public var isOffline: Bool

    public init(code: Int, message: String, isOffline: Bool) {
        self.code = code
        self.message = message
        self.isOffline = isOffline
    }

    public init(_ error: URLError) {
        let offline: Set<URLError.Code> = [.notConnectedToInternet, .networkConnectionLost, .cannotFindHost,
                                           .cannotConnectToHost, .timedOut, .dnsLookupFailed,
                                           .internationalRoamingOff, .dataNotAllowed, .callIsActive]
        self.init(code: error.code.rawValue, message: error.localizedDescription, isOffline: offline.contains(error.code))
    }
}

public enum APIError: Error, Sendable, Equatable, CustomStringConvertible {
    /// The server answered with an error.
    case server(ServerError)
    /// No answer arrived.
    case transport(TransportError)
    /// The answer didn't match the contract, or a request couldn't be built.
    case invalidResponse(String)
    /// No session on this phone (never signed in, signed out, or the session ended).
    case notSignedIn

    public var serverError: ServerError? {
        if case .server(let error) = self { return error }
        return nil
    }

    public var code: APIErrorCode? { serverError?.code }

    public var isOffline: Bool {
        if case .transport = self { return true }
        return false
    }

    public var description: String {
        switch self {
        case .server(let error): "Server error \(error)"
        case .transport(let error): "No answer: \(error.message)"
        case .invalidResponse(let why): "Unexpected reply: \(why)"
        case .notSignedIn: "Not signed in"
        }
    }
}
