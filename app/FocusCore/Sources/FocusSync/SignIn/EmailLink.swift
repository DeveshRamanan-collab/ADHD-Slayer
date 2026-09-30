import Foundation

/// The phone's half of an email link (CONTRACT.md, Email links). `verifier` stays in this phone's
/// Keychain; `challenge` = base64url(SHA-256(UTF-8 of verifier)) goes to `POST /auth/email/start`.
/// Verifying sends the verifier, so a link tapped on another phone fails clearly.
public struct EmailLinkVerifier: Codable, Sendable, Equatable {
    public let verifier: String

    public init(verifier: String) {
        self.verifier = verifier
    }

    public static func make() -> EmailLinkVerifier {
        EmailLinkVerifier(verifier: Base64URL.encode(SecureRandom.bytes(32)))
    }

    public var challenge: String { Base64URL.encode(Digest.sha256(Data(verifier.utf8))) }
}

public enum EmailLink {
    /// Where email links point: production, staging and the local web server.
    public static let hosts: Set<String> = ["focus.adhdslayer.au", "staging.focus.adhdslayer.au", "localhost", "127.0.0.1"]
    public static let path = "/auth/email"

    /// Reads `t` from `https://focus.adhdslayer.au/auth/email#t=<token>`. Nil for any other URL.
    public static func token(from url: URL) -> String? {
        guard let scheme = url.scheme?.lowercased(), scheme == "https" || scheme == "http",
              let host = url.host()?.lowercased(), hosts.contains(host) else { return nil }
        var path = url.path(percentEncoded: false)
        while path.count > 1, path.hasSuffix("/") { path.removeLast() }
        guard path == Self.path, let fragment = url.fragment(percentEncoded: false) else { return nil }
        for pair in fragment.split(separator: "&") {
            let parts = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            if parts.count == 2, parts[0] == "t", !parts[1].isEmpty { return String(parts[1]) }
        }
        return nil
    }

    /// The link token's public parts: base64url of 88 bytes, `id (16) || expiresAt (8, big-endian
    /// Unix milliseconds) || secret (32) || mac (32)`. The phone can't check the MAC (the key is the
    /// server's) but can see a link has expired without asking.
    public struct Token: Sendable, Equatable {
        public static let byteCount = 88
        public let raw: String
        public let id: UUID
        public let expiresAt: Date

        public init?(_ raw: String) {
            guard let bytes = Base64URL.decode(raw), bytes.count == Self.byteCount,
                  let idBytes = bytes.bytes(at: 0, length: 16),
                  let milliseconds = bytes.readUInt64BigEndian(at: 16) else { return nil }
            let b = Array(idBytes)
            self.raw = raw
            self.id = UUID(uuid: (b[0], b[1], b[2], b[3], b[4], b[5], b[6], b[7],
                                  b[8], b[9], b[10], b[11], b[12], b[13], b[14], b[15]))
            self.expiresAt = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
        }

        public func isExpired(now: Date = Date()) -> Bool { expiresAt <= now }
    }
}
