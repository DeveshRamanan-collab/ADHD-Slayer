import Foundation
import CryptoKit

/// An ARK sealed to one device: HPKE `P256_SHA256_AES_GCM_256`, base mode, recipient the device's
/// agreement key, info `focus.slot.v1:<accountId>:<epoch>`, plaintext the 32-byte ARK. Key transfers
/// use the same sealing.
public enum DeviceSlot {
    static var ciphersuite: HPKE.Ciphersuite { .P256_SHA256_AES_GCM_256 }

    public static func info(accountId: UUID, epoch: Int) -> Data {
        Data("focus.slot.v1:\(accountId.wire):\(epoch)".utf8)
    }

    public static func seal(_ ark: AccountRootKey, to recipient: P256.KeyAgreement.PublicKey, accountId: UUID) throws -> SealedSlot {
        var sender = try HPKE.Sender(recipientKey: recipient, ciphersuite: ciphersuite,
                                     info: info(accountId: accountId, epoch: ark.epoch))
        let ciphertext = try sender.seal(ark.rawKey)
        return SealedSlot(epoch: ark.epoch, enc: Base64URL.encode(sender.encapsulatedKey),
                          ciphertext: Base64URL.encode(ciphertext))
    }

    public static func open(_ slot: SealedSlot, with privateKey: P256.KeyAgreement.PrivateKey, accountId: UUID) throws -> AccountRootKey {
        guard let enc = Base64URL.decode(slot.enc), let ciphertext = Base64URL.decode(slot.ciphertext) else {
            throw FocusCryptoError.invalidEncoding("slot")
        }
        let raw: Data
        do {
            var recipient = try HPKE.Recipient(privateKey: privateKey, ciphersuite: ciphersuite,
                                               info: info(accountId: accountId, epoch: slot.epoch), encapsulatedKey: enc)
            raw = try recipient.open(ciphertext)
        } catch {
            throw FocusCryptoError.authenticationFailed
        }
        return try AccountRootKey(epoch: slot.epoch, rawKey: raw)
    }

    /// Reads a base64url X9.63 agreement key from the server.
    public static func publicKey(fromBase64URL text: String) throws -> P256.KeyAgreement.PublicKey {
        guard let raw = Base64URL.decode(text), raw.count == 65,
              let key = try? P256.KeyAgreement.PublicKey(x963Representation: raw) else {
            throw FocusCryptoError.invalidPublicKey
        }
        return key
    }
}
