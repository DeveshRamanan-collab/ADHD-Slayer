import Foundation
import Testing
@testable import FocusSync

@Suite("Error envelope: every code in 02-backend.md, unknown codes, Retry-After")
struct APIErrorTests {
    /// The spec's table, code by code, with its HTTP status.
    static let table: [(String, Int, APIErrorCode)] = [
        ("VALIDATION_ERROR", 422, .validationError),
        ("UNAUTHENTICATED", 401, .unauthenticated),
        ("TOKEN_EXPIRED", 401, .tokenExpired),
        ("SESSION_REVOKED", 401, .sessionRevoked),
        ("DEVICE_PROOF_INVALID", 401, .deviceProofInvalid),
        ("DEVICE_REVOKED", 401, .deviceRevoked),
        ("FORBIDDEN", 403, .forbidden),
        ("NOT_FOUND", 404, .notFound),
        ("PROVIDER_TOKEN_INVALID", 401, .providerTokenInvalid),
        ("NONCE_MISMATCH", 401, .nonceMismatch),
        ("ADULT_CONFIRMATION_REQUIRED", 422, .adultConfirmationRequired),
        ("LINK_INVALID", 410, .linkInvalid),
        ("CODE_ATTEMPTS_EXCEEDED", 429, .codeAttemptsExceeded),
        ("LINK_WRONG_DEVICE", 403, .linkWrongDevice),
        ("ACCOUNT_DELETION_PENDING", 409, .accountDeletionPending),
        ("SNAPSHOT_CONFLICT", 409, .snapshotConflict),
        ("EPOCH_MISMATCH", 409, .epochMismatch),
        ("UPLOAD_INCOMPLETE", 409, .uploadIncomplete),
        ("CHECKSUM_MISMATCH", 422, .checksumMismatch),
        ("TRANSFER_EXPIRED", 410, .transferExpired),
        ("TRANSFER_ALREADY_SEALED", 409, .transferAlreadySealed),
        ("SEQ_CONFLICT", 409, .seqConflict),
        ("SEQ_GAP", 409, .seqGap),
        ("IDEMPOTENCY_MISMATCH", 422, .idempotencyMismatch),
        ("PAYLOAD_TOO_LARGE", 413, .payloadTooLarge),
        ("QUOTA_EXCEEDED", 413, .quotaExceeded),
        ("JWS_INVALID", 422, .jwsInvalid),
        ("UPSTREAM_UNAVAILABLE", 503, .upstreamUnavailable),
        ("SERVICE_PAUSED", 503, .servicePaused),
        ("RATE_LIMITED", 429, .rateLimited),
        ("UPGRADE_REQUIRED", 426, .upgradeRequired),
        ("INTERNAL", 500, .internalError),
    ]

    @Test func everyCodeInTheSpecDecodes() throws {
        #expect(Self.table.count == APIErrorCode.allKnown.count)
        for (raw, status, code) in Self.table {
            let error = ServerError(response: Fixture.error(status, raw, details: ["hint": "x"]))
            #expect(error.code == code, "\(raw)")
            #expect(error.status == status)
            #expect(error.message == "developer text")
            #expect(error.details?["hint"]?.stringValue == "x")
            #expect(code.rawValue == raw)
            #expect(code.documentedStatus == status, "\(raw)")
            #expect(APIErrorCode(rawValue: raw) == code)
        }
    }

    @Test func unknownCodesStayReadable() {
        let error = ServerError(response: Fixture.error(418, "TEAPOT_OVERHEATED"))
        #expect(error.code == .unknown("TEAPOT_OVERHEATED"))
        #expect(error.code.rawValue == "TEAPOT_OVERHEATED")
        #expect(error.code.documentedStatus == nil)
    }

    @Test func conflictDetailsCarryTheCurrentVersion() {
        let error = ServerError(response: Fixture.error(409, "SNAPSHOT_CONFLICT", details: ["currentVersion": 12]))
        #expect(error.details?["currentVersion"]?.intValue == 12)
    }

    @Test func retryAfterComesFromTheBodyOrTheHeader() {
        let body = ServerError(response: Fixture.error(429, "RATE_LIMITED", retryAfterSeconds: 30))
        #expect(body.retryAfter == 30)
        let header = ServerError(response: Fixture.error(429, "RATE_LIMITED", headers: ["Retry-After": "120"]))
        #expect(header.retryAfter == 120)
        let both = ServerError(response: Fixture.error(429, "RATE_LIMITED", retryAfterSeconds: 30, headers: ["retry-after": "45"]))
        #expect(both.retryAfter == 45)
        let now = Date(timeIntervalSince1970: 1_790_000_000)
        #expect(ServerError.parseRetryAfter("Mon, 21 Sep 2026 14:14:20 GMT", now: now) == 60)
        #expect(ServerError.parseRetryAfter("soon", now: now) == nil)
    }

    @Test func repliesWithoutAnEnvelopeGetACodeFromTheirStatus() {
        #expect(ServerError(response: HTTPResponse(statusCode: 502, body: Data("<html>".utf8))).code == .internalError)
        #expect(ServerError(response: HTTPResponse(statusCode: 503)).code == .upstreamUnavailable)
        #expect(ServerError(response: HTTPResponse(statusCode: 429)).code == .rateLimited)
        #expect(ServerError(response: HTTPResponse(statusCode: 418)).code == .unknown("HTTP_418"))
    }

    @Test func offlineErrorsAreRecognised() {
        #expect(TransportError(URLError(.notConnectedToInternet)).isOffline)
        #expect(TransportError(URLError(.timedOut)).isOffline)
        #expect(!TransportError(URLError(.badServerResponse)).isOffline)
    }
}
