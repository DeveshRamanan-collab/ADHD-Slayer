import Foundation
import CryptoKit

/// The recovery key: 15 random bytes (120 bits), shown once as 24 Crockford base32 characters in
/// six groups of four joined by `-`. Never stored; at 120 random bits it needs no password stretching.
public struct RecoveryKey: Sendable, Equatable, CustomStringConvertible {
    public static let byteCount = 15
    public let bytes: Data

    public init(bytes: Data) throws {
        guard bytes.count == Self.byteCount else { throw FocusCryptoError.invalidRecoveryKey }
        self.bytes = Data(bytes)
    }

    private init(unchecked bytes: Data) {
        self.bytes = bytes
    }

    public static func generate() -> RecoveryKey {
        RecoveryKey(unchecked: SecureRandom.bytes(byteCount))
    }

    /// Reads what the person typed. Ignores case, spaces and dashes; reads `O` as `0`, `I` and `L` as `1`.
    public init(parsing text: String) throws {
        guard let bytes = Crockford.decode(text), bytes.count == Self.byteCount else {
            throw FocusCryptoError.invalidRecoveryKey
        }
        self.bytes = bytes
    }

    /// `ABCD-EFGH-JKMN-PQRS-TVWX-YZ01`.
    public var formatted: String {
        let symbols = Array(Crockford.encode(bytes))
        return stride(from: 0, to: symbols.count, by: 4)
            .map { String(symbols[$0..<min($0 + 4, symbols.count)]) }
            .joined(separator: "-")
    }

    /// Never prints the key.
    public var description: String { "RecoveryKey(hidden)" }
}

enum Crockford {
    static let alphabet = Array("0123456789ABCDEFGHJKMNPQRSTVWXYZ".utf8)

    /// Most significant bit first. 15 bytes make exactly 24 symbols.
    static func encode(_ data: Data) -> String {
        var out: [UInt8] = []
        var buffer: UInt32 = 0
        var bits = 0
        for byte in data {
            buffer = buffer << 8 | UInt32(byte)
            bits += 8
            while bits >= 5 {
                out.append(alphabet[Int((buffer >> UInt32(bits - 5)) & 0x1F)])
                bits -= 5
            }
            buffer &= (1 << UInt32(bits)) - 1
        }
        if bits > 0 { out.append(alphabet[Int((buffer << UInt32(5 - bits)) & 0x1F)]) }
        return String(decoding: out, as: UTF8.self)
    }

    static func decode(_ text: String) -> Data? {
        var values: [UInt8] = []
        for scalar in text.uppercased().unicodeScalars {
            switch scalar {
            case " ", "-", "\t", "\n", "\u{00A0}": continue
            case "O": values.append(0)
            case "I", "L": values.append(1)
            default:
                guard scalar.isASCII, let index = alphabet.firstIndex(of: UInt8(scalar.value)) else { return nil }
                values.append(UInt8(index))
            }
        }
        guard values.count * 5 % 8 == 0 else { return nil }
        var out = Data()
        var buffer: UInt32 = 0
        var bits = 0
        for value in values {
            buffer = buffer << 5 | UInt32(value)
            bits += 5
            if bits >= 8 {
                out.append(UInt8((buffer >> UInt32(bits - 8)) & 0xFF))
                bits -= 8
            }
            buffer &= (1 << UInt32(bits)) - 1
        }
        return out
    }
}

/// The ARK sealed with the recovery key: AES-256-GCM under HKDF-SHA256(ikm the 15 bytes, salt UTF-8
/// of the lowercase account id, info `focus.recovery.v1`, 32 bytes), AAD
/// `focus.recovery.v1:<accountId>:<epoch>`, a 12-byte nonce; `ciphertext` includes the tag.
public enum RecoverySlot {
    public static func key(for recoveryKey: RecoveryKey, accountId: UUID) -> SymmetricKey {
        HKDF<SHA256>.deriveKey(inputKeyMaterial: SymmetricKey(data: recoveryKey.bytes), salt: Data(accountId.wire.utf8),
                               info: Data("focus.recovery.v1".utf8), outputByteCount: 32)
    }

    public static func aad(accountId: UUID, epoch: Int) -> Data {
        Data("focus.recovery.v1:\(accountId.wire):\(epoch)".utf8)
    }

    public static func seal(_ ark: AccountRootKey, with recoveryKey: RecoveryKey, accountId: UUID) throws -> SealedRecoverySlot {
        try seal(ark, with: recoveryKey, accountId: accountId, nonce: SecureRandom.bytes(12))
    }

    static func seal(_ ark: AccountRootKey, with recoveryKey: RecoveryKey, accountId: UUID, nonce: Data) throws -> SealedRecoverySlot {
        let box = try AES.GCM.seal(ark.rawKey, using: key(for: recoveryKey, accountId: accountId),
                                   nonce: try AES.GCM.Nonce(data: nonce), authenticating: aad(accountId: accountId, epoch: ark.epoch))
        return SealedRecoverySlot(epoch: ark.epoch, nonce: Base64URL.encode(nonce), ciphertext: Base64URL.encode(box.ciphertext + box.tag))
    }

    public static func open(_ slot: SealedRecoverySlot, with recoveryKey: RecoveryKey, accountId: UUID) throws -> AccountRootKey {
        guard let nonce = Base64URL.decode(slot.nonce), nonce.count == 12,
              let sealed = Base64URL.decode(slot.ciphertext), sealed.count > 16 else {
            throw FocusCryptoError.invalidEncoding("recovery slot")
        }
        let raw: Data
        do {
            let box = try AES.GCM.SealedBox(nonce: AES.GCM.Nonce(data: nonce), ciphertext: sealed.prefix(sealed.count - 16),
                                            tag: sealed.suffix(16))
            raw = try AES.GCM.open(box, using: key(for: recoveryKey, accountId: accountId),
                                   authenticating: aad(accountId: accountId, epoch: slot.epoch))
        } catch {
            throw FocusCryptoError.authenticationFailed
        }
        return try AccountRootKey(epoch: slot.epoch, rawKey: raw)
    }
}
