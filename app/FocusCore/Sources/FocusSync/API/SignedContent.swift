import Foundation
import CryptoKit

public enum SignedContentError: Error, Sendable, Equatable {
    case missingSignature
    case unknownKey(String)
    case badSignature
    case expired
    case olderVersion
    case hashMismatch
}

/// Checks config and copy signatures: ES256 by the config signing key, the raw 64-byte `r || s` of
/// SHA-256 over the exact body bytes, base64url, in `Signature`, with `Signature-Key-Id` naming the
/// key. The app bundles the current and next public keys.
public struct SignedContentVerifier: Sendable {
    private let keys: [String: Data]

    /// `publicKeys`: key id to base64url X9.63 public key.
    public init(publicKeys: [String: String]) throws {
        var keys: [String: Data] = [:]
        for (id, text) in publicKeys {
            guard let raw = Base64URL.decode(text), (try? P256.Signing.PublicKey(x963Representation: raw)) != nil else {
                throw FocusCryptoError.invalidPublicKey
            }
            keys[id] = raw
        }
        self.keys = keys
    }

    public func verify(_ document: SignedDocument) throws {
        guard let signatureText = document.signature, let keyId = document.keyId,
              let raw = Base64URL.decode(signatureText) else { throw SignedContentError.missingSignature }
        guard let keyData = keys[keyId], let key = try? P256.Signing.PublicKey(x963Representation: keyData) else {
            throw SignedContentError.unknownKey(keyId)
        }
        guard let signature = try? P256.Signing.ECDSASignature(rawRepresentation: raw),
              key.isValidSignature(signature, for: document.body) else { throw SignedContentError.badSignature }
    }

    /// A copy deck must also match the manifest's base64url SHA-256.
    public func verify(_ deck: SignedDocument, against manifest: CopyManifest) throws {
        try verify(deck)
        guard Base64URL.encode(Digest.sha256(deck.body)) == manifest.sha256 else { throw SignedContentError.hashMismatch }
    }
}
