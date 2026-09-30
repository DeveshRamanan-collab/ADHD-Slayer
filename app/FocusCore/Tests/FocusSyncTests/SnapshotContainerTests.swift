import Foundation
import CryptoKit
import Testing
@testable import FocusSync

@Suite("FCS1 snapshot container (CONTRACT.md Snapshot container)")
struct SnapshotContainerTests {
    let accountId = Fixture.accountId
    let snapshotId = UUID(uuidString: "4F1C2D3E-5A6B-4C7D-8E9F-A0B1C2D3E4F5")!
    let deviceId = UUID(uuidString: "0199A1B2-C3D4-7E5F-8A9B-0C1D2E3F4A5B")!
    let bundle = Data(#"{"meta":{"schema":1},"medicationFile":{"medications":[{"name":"Something","strength":"10 mg"}]},"tasks":[]}"#.utf8)

    private func seal(_ ark: AccountRootKey, bundle: Data? = nil) throws -> SnapshotContainer.Sealed {
        try SnapshotContainer.seal(bundle: bundle ?? self.bundle, with: ark, accountId: accountId, snapshotId: snapshotId,
                                   deviceId: deviceId, schema: 1, createdAt: Date(timeIntervalSince1970: 1_790_000_000.4567))
    }

    @Test func roundTrip() throws {
        let ark = AccountRootKey.generate(epoch: 3)
        let sealed = try seal(ark)
        let opened = try SnapshotContainer.open(sealed.data, accountId: accountId) { $0 == 3 ? ark : nil }
        #expect(opened.bundle == bundle)
        #expect(opened.header == sealed.header)
        #expect(opened.header.epoch == 3)
        #expect(FocusJSON.string(from: opened.header.createdAt) == "2026-09-21T14:13:20.457Z")
    }

    @Test func layoutIsMagicLengthHeaderThenCiphertextAndTag() throws {
        let sealed = try seal(AccountRootKey.generate(epoch: 3))
        #expect(sealed.data.prefix(4) == Data("FCS1".utf8))
        let length = Int(try #require(sealed.data.readUInt32BigEndian(at: 4)))
        #expect(length == sealed.headerBytes.count)
        #expect(sealed.data.bytes(at: 8, length: length) == sealed.headerBytes)
        #expect(sealed.data.count == 8 + length + sealed.header.paddedLength + 16)
        #expect(sealed.header.paddedLength == 16_384)
        #expect(sealed.aad == Data(SHA256.hash(data: sealed.headerBytes)))
        #expect(sealed.sha256Base64URL == Base64URL.encode(SHA256.hash(data: sealed.data)))
        #expect(sealed.sha256Base64 == Data(SHA256.hash(data: sealed.data)).base64EncodedString())

        // Keys sorted, no spaces, lowercase ids, times with milliseconds.
        let header = try #require(String(data: sealed.headerBytes, encoding: .utf8))
        #expect(!header.contains(" "))
        let keys = try #require(try JSONSerialization.jsonObject(with: sealed.headerBytes) as? [String: Any]).keys.sorted()
        #expect(keys == ["accountId", "alg", "createdAt", "dekNonce", "deviceId", "epoch", "nonce", "paddedLength", "schema",
                         "snapshotId", "v", "wrappedDek"])
        #expect(header.hasPrefix(#"{"accountId":"0199a1b2-0000-7000-8000-000000000001","alg":"A256GCM","createdAt":"2026-09-21T14:13:20.457Z","dekNonce":""#))
        #expect(header.hasSuffix(#""snapshotId":"4f1c2d3e-5a6b-4c7d-8e9f-a0b1c2d3e4f5","v":1,"wrappedDek":"\#(sealed.header.wrappedDek)"}"#))
        #expect(Base64URL.decode(sealed.header.wrappedDek)?.count == 48)
        #expect(Base64URL.decode(sealed.header.nonce)?.count == 12)
        #expect(Base64URL.decode(sealed.header.dekNonce)?.count == 12)
    }

    @Test func freshKeysAndNoncesEveryTime() throws {
        let ark = AccountRootKey.generate(epoch: 1)
        let a = try seal(ark)
        let b = try seal(ark)
        #expect(a.header.nonce != b.header.nonce)
        #expect(a.header.wrappedDek != b.header.wrappedDek)
        #expect(a.data != b.data)
    }

    @Test func aChangedHeaderFailsToOpen() throws {
        let ark = AccountRootKey.generate(epoch: 3)
        let sealed = try seal(ark)
        // A header that still parses (the time moved by ten hours) fails the payload's AAD check.
        let time = try #require(sealed.data.range(of: Data("14:13:20.457Z".utf8)))
        var moved = sealed.data
        moved[time.lowerBound] = UInt8(ascii: "0")
        #expect(throws: FocusCryptoError.authenticationFailed) {
            try SnapshotContainer.open(moved, accountId: accountId) { _ in ark }
        }
        // A header that no longer parses is refused before any key is used.
        var broken = sealed.data
        broken[sealed.data.startIndex + 8] = UInt8(ascii: "[")
        #expect(throws: FocusCryptoError.unsupportedSnapshot("header")) {
            try SnapshotContainer.open(broken, accountId: accountId) { _ in ark }
        }
    }

    @Test func aChangedCiphertextOrTagFailsToOpen() throws {
        let ark = AccountRootKey.generate(epoch: 3)
        let sealed = try seal(ark)
        for offset in [8 + sealed.headerBytes.count + 5, sealed.data.count - 1] {
            var data = sealed.data
            data[data.startIndex + offset] ^= 0x01
            #expect(throws: FocusCryptoError.authenticationFailed) {
                try SnapshotContainer.open(data, accountId: accountId) { _ in ark }
            }
        }
        #expect(throws: FocusCryptoError.self) {
            try SnapshotContainer.open(sealed.data.dropLast(), accountId: accountId) { _ in ark }
        }
    }

    @Test func theWrongKeyOrAccountFailsToOpen() throws {
        let ark = AccountRootKey.generate(epoch: 3)
        let sealed = try seal(ark)
        #expect(throws: FocusCryptoError.authenticationFailed) {
            try SnapshotContainer.open(sealed.data, accountId: accountId) { _ in AccountRootKey.generate(epoch: 3) }
        }
        #expect(throws: FocusCryptoError.missingKey(epoch: 3)) {
            try SnapshotContainer.open(sealed.data, accountId: accountId) { _ in nil }
        }
        #expect(throws: FocusCryptoError.wrongAccount) {
            try SnapshotContainer.open(sealed.data, accountId: UUID()) { _ in ark }
        }
        #expect(throws: FocusCryptoError.notASnapshot) {
            try SnapshotContainer.open(Data("FCS2".utf8) + sealed.data.dropFirst(4), accountId: accountId) { _ in ark }
        }
    }

    @Test func paddingRoundsUpToWholeSixteenKiBBlocks() {
        #expect(SnapshotContainer.paddedLength(forCompressedLength: 0) == 16_384)
        #expect(SnapshotContainer.paddedLength(forCompressedLength: 1) == 16_384)
        #expect(SnapshotContainer.paddedLength(forCompressedLength: 16_380) == 16_384)
        #expect(SnapshotContainer.paddedLength(forCompressedLength: 16_381) == 32_768)
        #expect(SnapshotContainer.paddedLength(forCompressedLength: 40_000) == 49_152)
    }

    @Test func largerBundlesPadToTheirBlockAndStillRoundTrip() throws {
        // Random bytes don't compress, so the padded size is predictable.
        var random = SystemRandomNumberGenerator()
        let noise = (0..<20_000).map { _ in UInt8.random(in: 0...255, using: &random) }
        let big = Data(#"{"n":""#.utf8) + Data(Base64URL.encode(noise).utf8) + Data(#""}"#.utf8)
        let ark = AccountRootKey.generate(epoch: 1)
        let sealed = try seal(ark, bundle: big)
        let compressed = try SnapshotContainer.compress(big)
        #expect(sealed.header.paddedLength == SnapshotContainer.paddedLength(forCompressedLength: compressed.count))
        #expect(sealed.header.paddedLength % 16_384 == 0)
        #expect(sealed.header.paddedLength > 16_384)
        #expect(try SnapshotContainer.open(sealed.data, accountId: accountId) { _ in ark }.bundle == big)
    }

    @Test func compressionIsRawDeflate() throws {
        let compressed = try SnapshotContainer.compress(bundle)
        // A zlib stream would start with 0x78; raw DEFLATE has no header.
        #expect(compressed.first != 0x78)
        #expect(try SnapshotContainer.decompress(compressed) == bundle)
    }

    @Test func keyEncryptionKeyIsHKDFOfTheRootKey() throws {
        let ark = try AccountRootKey(epoch: 1, rawKey: Data(repeating: 0x11, count: 32))
        let expected = HKDF<SHA256>.deriveKey(inputKeyMaterial: SymmetricKey(data: Data(repeating: 0x11, count: 32)),
                                              salt: Data("0199a1b2-0000-7000-8000-000000000001".utf8),
                                              info: Data("focus.kek.v1".utf8), outputByteCount: 32)
        let kek = ark.keyEncryptionKey(accountId: accountId)
        #expect(kek.withUnsafeBytes { Data($0) } == expected.withUnsafeBytes { Data($0) })
        #expect(throws: FocusCryptoError.invalidKeyLength) { try AccountRootKey(epoch: 1, rawKey: Data(count: 31)) }
    }
}
