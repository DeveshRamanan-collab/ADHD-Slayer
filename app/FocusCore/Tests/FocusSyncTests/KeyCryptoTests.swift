import Foundation
import CryptoKit
import Testing
@testable import FocusSync

@Suite("Key slots, recovery keys and transfer codes (CONTRACT.md Keys)")
struct KeyCryptoTests {
    let accountId = Fixture.accountId

    @Test func deviceSlotRoundTripsWithHPKE() throws {
        let recipient = P256.KeyAgreement.PrivateKey()
        let ark = AccountRootKey.generate(epoch: 4)
        let slot = try DeviceSlot.seal(ark, to: recipient.publicKey, accountId: accountId)
        #expect(slot.epoch == 4)
        #expect(Base64URL.decode(slot.enc)?.count == 65)      // P-256 encapsulated key, uncompressed
        #expect(Base64URL.decode(slot.ciphertext)?.count == 48) // 32-byte ARK plus the tag
        #expect(try DeviceSlot.open(slot, with: recipient, accountId: accountId) == ark)
    }

    @Test func deviceSlotsBindTheAccountEpochAndRecipient() throws {
        let recipient = P256.KeyAgreement.PrivateKey()
        let ark = AccountRootKey.generate(epoch: 4)
        let slot = try DeviceSlot.seal(ark, to: recipient.publicKey, accountId: accountId)
        #expect(throws: FocusCryptoError.authenticationFailed) {
            try DeviceSlot.open(slot, with: P256.KeyAgreement.PrivateKey(), accountId: accountId)
        }
        #expect(throws: FocusCryptoError.authenticationFailed) {
            try DeviceSlot.open(slot, with: recipient, accountId: UUID())
        }
        var otherEpoch = slot
        otherEpoch.epoch = 5
        #expect(throws: FocusCryptoError.authenticationFailed) {
            try DeviceSlot.open(otherEpoch, with: recipient, accountId: accountId)
        }
        #expect(DeviceSlot.info(accountId: accountId, epoch: 4) == Data("focus.slot.v1:0199a1b2-0000-7000-8000-000000000001:4".utf8))
    }

    @Test func identityOpensSlotsSealedToIt() throws {
        let identity = Fixture.identity()
        let ark = AccountRootKey.generate(epoch: 2)
        let slot = try DeviceSlot.seal(ark, to: try DeviceSlot.publicKey(fromBase64URL: identity.agreementKey), accountId: accountId)
        #expect(try identity.openSlot(slot, accountId: accountId) == ark)
    }

    @Test func recoveryKeyIsTwentyFourCrockfordCharactersInSixGroups() throws {
        let key = try RecoveryKey(bytes: Data((0..<15).map { UInt8($0 * 17) }))
        let formatted = key.formatted
        #expect(formatted.count == 29)
        let groups = formatted.split(separator: "-")
        #expect(groups.count == 6 && groups.allSatisfy { $0.count == 4 })
        let alphabet = Set("0123456789ABCDEFGHJKMNPQRSTVWXYZ")
        #expect(formatted.replacingOccurrences(of: "-", with: "").allSatisfy { alphabet.contains($0) })
        #expect(key.description == "RecoveryKey(hidden)")

        // All zeros and all ones are the edges of the alphabet.
        #expect(try RecoveryKey(bytes: Data(count: 15)).formatted == "0000-0000-0000-0000-0000-0000")
        #expect(try RecoveryKey(bytes: Data(repeating: 0xFF, count: 15)).formatted == "ZZZZ-ZZZZ-ZZZZ-ZZZZ-ZZZZ-ZZZZ")

        let generated = RecoveryKey.generate()
        #expect(try RecoveryKey(parsing: generated.formatted) == generated)
    }

    @Test func recoveryKeyParsingIsForgiving() throws {
        let key = try RecoveryKey(bytes: Data((0..<15).map { UInt8(truncatingIfNeeded: $0 * 29 + 3) }))
        let formatted = key.formatted
        #expect(try RecoveryKey(parsing: formatted.lowercased()) == key)
        #expect(try RecoveryKey(parsing: formatted.replacingOccurrences(of: "-", with: " ")) == key)
        #expect(try RecoveryKey(parsing: "  " + formatted.replacingOccurrences(of: "-", with: "") + "\n") == key)
        // O reads as 0; I and L read as 1.
        let zeros = try RecoveryKey(bytes: Data(count: 15))
        #expect(try RecoveryKey(parsing: "OOOO-oooo-0000-OOOO-0000-0000") == zeros)
        let ones = try RecoveryKey(parsing: "1111-1111-1111-1111-1111-1111")
        #expect(try RecoveryKey(parsing: "IIII-llll-LLLL-iiii-1111-1111") == ones)
        // U isn't in the alphabet, and length matters.
        #expect(throws: FocusCryptoError.invalidRecoveryKey) { try RecoveryKey(parsing: "UUUU-0000-0000-0000-0000-0000") }
        #expect(throws: FocusCryptoError.invalidRecoveryKey) { try RecoveryKey(parsing: "0000-0000-0000-0000-0000") }
        #expect(throws: FocusCryptoError.invalidRecoveryKey) { try RecoveryKey(parsing: "0000-0000-0000-0000-0000-0000-0000-0") }
    }

    @Test func recoverySlotRoundTrips() throws {
        let key = RecoveryKey.generate()
        let ark = AccountRootKey.generate(epoch: 2)
        let slot = try RecoverySlot.seal(ark, with: key, accountId: accountId)
        #expect(slot.epoch == 2)
        #expect(Base64URL.decode(slot.nonce)?.count == 12)
        #expect(Base64URL.decode(slot.ciphertext)?.count == 48)
        #expect(try RecoverySlot.open(slot, with: key, accountId: accountId) == ark)
        #expect(try RecoverySlot.open(slot, with: RecoveryKey(parsing: key.formatted.lowercased()), accountId: accountId) == ark)
        #expect(throws: FocusCryptoError.authenticationFailed) { try RecoverySlot.open(slot, with: .generate(), accountId: accountId) }
        #expect(throws: FocusCryptoError.authenticationFailed) { try RecoverySlot.open(slot, with: key, accountId: UUID()) }
        var moved = slot
        moved.epoch = 3
        #expect(throws: FocusCryptoError.authenticationFailed) { try RecoverySlot.open(moved, with: key, accountId: accountId) }
    }

    @Test func transferFingerprintIsSixteenBytesInEightGroups() throws {
        let key = P256.KeyAgreement.PrivateKey().publicKey
        let fingerprint = KeyTransfer.fingerprint(of: key)
        #expect(fingerprint == Data(SHA256.hash(data: key.x963Representation)).prefix(16))
        #expect(fingerprint.count == 16)
        let display = KeyTransfer.displayFingerprint(fingerprint)
        #expect(display.count == 39)
        let groups = display.split(separator: " ")
        #expect(groups.count == 8 && groups.allSatisfy { $0.count == 4 && $0.allSatisfy(\.isHexDigit) })
        #expect(display == display.lowercased())
        #expect(KeyTransfer.displayFingerprint(Data(0..<16)) == "0001 0203 0405 0607 0809 0a0b 0c0d 0e0f")
    }

    @Test func transferQRCodeRoundTrips() throws {
        let key = P256.KeyAgreement.PrivateKey().publicKey
        let transferId = UUID(uuidString: "0199A1B2-1111-7222-8333-444455556666")!
        let code = KeyTransfer.Code(transferId: transferId, fingerprint: KeyTransfer.fingerprint(of: key))
        #expect(code.qrPayload == "focus-transfer:1:0199a1b2-1111-7222-8333-444455556666:\(Base64URL.encode(code.fingerprint))")
        let parsed = try KeyTransfer.parse(code.qrPayload)
        #expect(parsed == code)
        #expect(KeyTransfer.matches(key, code: parsed))
        #expect(!KeyTransfer.matches(P256.KeyAgreement.PrivateKey().publicKey, code: parsed))
        #expect(throws: FocusCryptoError.invalidTransferCode) { try KeyTransfer.parse("focus-transfer:2:\(transferId):AAAA") }
        #expect(throws: FocusCryptoError.invalidTransferCode) { try KeyTransfer.parse("focus-transfer:1:not-a-uuid:\(Base64URL.encode(code.fingerprint))") }
        #expect(throws: FocusCryptoError.invalidTransferCode) { try KeyTransfer.parse("focus-transfer:1:\(transferId):AAAA") }
    }

    @Test func keyRingKeepsKeysPerAccountAndEpoch() throws {
        let store = InMemorySecureStore()
        let escrow = InMemorySecureStore()
        let ring = KeyRing(store: store, escrow: escrow)
        let one = AccountRootKey.generate(epoch: 1)
        let two = AccountRootKey.generate(epoch: 2)
        try ring.save(one, accountId: accountId)
        try ring.save(two, accountId: accountId)
        #expect(ring.ark(epoch: 1, accountId: accountId) == one)
        #expect(ring.latest(accountId: accountId) == two)
        #expect(ring.epochs(accountId: accountId) == [1, 2])
        #expect(ring.ark(epoch: 1, accountId: UUID()) == nil)
        #expect(try store.allKeys() == ["sync.ark.1", "sync.ark.2"])
        #expect(try escrow.allKeys() == ["ark.0199a1b2-0000-7000-8000-000000000001.1", "ark.0199a1b2-0000-7000-8000-000000000001.2"])

        // A new phone with only the iCloud Keychain copy.
        let newPhone = KeyRing(store: InMemorySecureStore(), escrow: escrow)
        #expect(newPhone.ark(epoch: 2, accountId: accountId) == nil)
        #expect(newPhone.escrowedARK(epoch: 2, accountId: accountId) == two)

        ring.removeAll(accountId: accountId, includingEscrow: true)
        #expect(try store.allKeys().isEmpty)
        #expect(try escrow.allKeys().isEmpty)
    }
}
