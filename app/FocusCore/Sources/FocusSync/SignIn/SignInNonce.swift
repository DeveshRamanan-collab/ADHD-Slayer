import Foundation
import CryptoKit

/// The sign-in nonce for Apple and Google (CONTRACT.md, Sign-in nonces).
///
/// `raw` is 32 random bytes as base64url and goes to our server. `hashed` is the lowercase hex
/// SHA-256 of the UTF-8 bytes of `raw` and goes to the provider (`ASAuthorizationAppleIDRequest.nonce`,
/// or the `nonce` parameter of Google's authorization request). The server checks the ID token's
/// `nonce` claim equals `hashed`.
public struct SignInNonce: Sendable, Equatable {
    public let raw: String

    public init(raw: String) {
        self.raw = raw
    }

    public static func make() -> SignInNonce {
        SignInNonce(raw: Base64URL.encode(SecureRandom.bytes(32)))
    }

    public var hashed: String { Digest.sha256Hex(Data(raw.utf8)) }
}

/// PKCE (RFC 7636) with S256.
public enum PKCE {
    /// 32 random bytes as base64url: 43 characters from the unreserved set.
    public static func makeVerifier() -> String {
        Base64URL.encode(SecureRandom.bytes(32))
    }

    /// `BASE64URL(SHA256(ASCII(verifier)))`.
    public static func challenge(for verifier: String) -> String {
        Base64URL.encode(Digest.sha256(Data(verifier.utf8)))
    }
}
