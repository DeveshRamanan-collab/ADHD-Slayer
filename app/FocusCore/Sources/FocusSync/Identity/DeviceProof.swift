import Foundation
import CryptoKit

/// The three proof headers on P and BP calls (CONTRACT.md, Device keys and proofs).
public struct ProofHeaders: Sendable, Equatable {
    /// `X-Device-Id`: the lowercase device id.
    public let deviceId: String
    /// `X-Device-Timestamp`: Unix time in whole seconds.
    public let timestamp: String
    /// `X-Device-Signature`: base64url of the raw 64-byte ES256 `r || s`.
    public let signature: String

    public init(deviceId: String, timestamp: String, signature: String) {
        self.deviceId = deviceId
        self.timestamp = timestamp
        self.signature = signature
    }

    public var dictionary: [String: String] {
        ["X-Device-Id": deviceId, "X-Device-Timestamp": timestamp, "X-Device-Signature": signature]
    }
}

/// Signs requests with this phone's device key.
///
/// The canonical string is four lines joined by `\n` with no trailing newline: the method in upper
/// case, the path with its query exactly as sent (including `/v1`), the timestamp, and the
/// lowercase hex SHA-256 of the exact body bytes (of the empty string when there's no body).
public struct DeviceProof: Sendable {
    public let identity: DeviceIdentity

    public init(identity: DeviceIdentity) {
        self.identity = identity
    }

    public func sign(method: String, pathWithQuery: String, body: Data?, timestamp: Date) throws -> ProofHeaders {
        let seconds = String(Self.unixSeconds(timestamp))
        let canonical = Self.canonicalString(method: method, pathWithQuery: pathWithQuery, timestamp: seconds, body: body)
        let signature = try identity.signature(for: Data(canonical.utf8))
        return ProofHeaders(deviceId: identity.deviceId.wire, timestamp: seconds, signature: Base64URL.encode(signature))
    }

    public static func canonicalString(method: String, pathWithQuery: String, timestamp: String, body: Data?) -> String {
        [method.uppercased(), pathWithQuery, timestamp, Digest.sha256Hex(body ?? Data())].joined(separator: "\n")
    }

    /// What the server does: rebuilds the canonical string and checks the signature.
    public static func isValid(_ headers: ProofHeaders, method: String, pathWithQuery: String, body: Data?,
                               publicKey: P256.Signing.PublicKey) -> Bool {
        guard let raw = Base64URL.decode(headers.signature),
              let signature = try? P256.Signing.ECDSASignature(rawRepresentation: raw) else { return false }
        let canonical = canonicalString(method: method, pathWithQuery: pathWithQuery, timestamp: headers.timestamp, body: body)
        return publicKey.isValidSignature(signature, for: Data(canonical.utf8))
    }

    static func unixSeconds(_ date: Date) -> Int64 {
        Int64(date.timeIntervalSince1970.rounded(.down))
    }
}
