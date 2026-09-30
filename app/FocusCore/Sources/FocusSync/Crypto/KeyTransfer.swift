import Foundation
import CryptoKit

/// Moving the key from an old phone to a new one. The new phone shows a QR code with the transfer id
/// and its agreement key's fingerprint; the old phone checks the key the server hands it against that
/// fingerprint before sealing, so the server can't swap in its own key.
public enum KeyTransfer {
    public static let qrPrefix = "focus-transfer:1:"

    public struct Code: Sendable, Equatable {
        public let transferId: UUID
        /// The first 16 bytes of SHA-256 of the new phone's 65-byte agreement key.
        public let fingerprint: Data

        public init(transferId: UUID, fingerprint: Data) {
            self.transferId = transferId
            self.fingerprint = fingerprint
        }

        /// `focus-transfer:1:<transferId>:<fingerprint base64url>`.
        public var qrPayload: String { KeyTransfer.qrPrefix + transferId.wire + ":" + Base64URL.encode(fingerprint) }

        /// Eight groups of four lowercase hex characters, for reading aloud or comparing by eye.
        public var displayFingerprint: String { KeyTransfer.displayFingerprint(fingerprint) }
    }

    public static func fingerprint(of agreementKey: P256.KeyAgreement.PublicKey) -> Data {
        Data(Digest.sha256(agreementKey.x963Representation).prefix(16))
    }

    public static func displayFingerprint(_ fingerprint: Data) -> String {
        let hex = Array(Hex.encode(fingerprint))
        return stride(from: 0, to: hex.count, by: 4)
            .map { String(hex[$0..<min($0 + 4, hex.count)]) }
            .joined(separator: " ")
    }

    public static func parse(_ payload: String) throws -> Code {
        let trimmed = payload.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix(qrPrefix) else { throw FocusCryptoError.invalidTransferCode }
        let parts = trimmed.dropFirst(qrPrefix.count).split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count == 2, let transferId = UUID(uuidString: String(parts[0])),
              let fingerprint = Base64URL.decode(String(parts[1])), fingerprint.count == 16 else {
            throw FocusCryptoError.invalidTransferCode
        }
        return Code(transferId: transferId, fingerprint: fingerprint)
    }

    /// True when `agreementKey` is the key the QR code named.
    public static func matches(_ agreementKey: P256.KeyAgreement.PublicKey, code: Code) -> Bool {
        fingerprint(of: agreementKey).constantTimeEquals(code.fingerprint)
    }
}
