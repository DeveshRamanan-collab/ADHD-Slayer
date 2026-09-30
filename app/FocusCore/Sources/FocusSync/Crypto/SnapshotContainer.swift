import Foundation
import CryptoKit

/// The `FCS1` snapshot container (CONTRACT.md). The server stores these bytes and can't read them.
///
/// Layout: ASCII `FCS1`, a 4-byte big-endian header length, the header JSON (UTF-8, keys sorted, no
/// spaces), then the AES-256-GCM ciphertext followed by its 16-byte tag.
///
/// - The data key (32 random bytes per snapshot) is wrapped with AES-256-GCM under the KEK, with the
///   AAD `focus.dek.v1:<snapshotId>`; `wrappedDek` is its ciphertext and tag.
/// - The payload's AAD is the 32-byte SHA-256 of the exact header bytes.
/// - The plaintext is `u32be(compressedLength) || compressed || zero padding` up to the next multiple
///   of 16,384 bytes; `compressed` is raw DEFLATE (`NSData.CompressionAlgorithm.zlib`) of the bundle JSON.
public enum SnapshotContainer {
    public static let magic = Data("FCS1".utf8)
    public static let formatVersion = 1
    public static let algorithm = "A256GCM"
    public static let paddingBlock = 16_384
    /// Guards against a corrupt length field.
    static let maxHeaderLength = 64 * 1024

    public struct Header: Codable, Sendable, Equatable {
        public var v: Int
        public var alg: String
        public var snapshotId: UUID
        public var accountId: UUID
        public var deviceId: UUID
        public var epoch: Int
        public var schema: Int
        public var createdAt: Date
        /// Base64url ciphertext and tag (48 bytes) of the data key under the KEK.
        public var wrappedDek: String
        /// Base64url 12-byte nonce for the data key wrap.
        public var dekNonce: String
        /// Base64url 12-byte nonce for the payload.
        public var nonce: String
        public var paddedLength: Int

        /// The exact header bytes: UTF-8 JSON, keys sorted by code point, no spaces.
        public func canonicalBytes() -> Data {
            let fields: [(String, CanonicalJSON)] = [
                ("v", .int(v)),
                ("alg", .string(alg)),
                ("snapshotId", .string(snapshotId.wire)),
                ("accountId", .string(accountId.wire)),
                ("deviceId", .string(deviceId.wire)),
                ("epoch", .int(epoch)),
                ("schema", .int(schema)),
                ("createdAt", .string(FocusJSON.string(from: createdAt))),
                ("wrappedDek", .string(wrappedDek)),
                ("dekNonce", .string(dekNonce)),
                ("nonce", .string(nonce)),
                ("paddedLength", .int(paddedLength)),
            ]
            return CanonicalJSON.object(fields)
        }
    }

    public struct Sealed: Sendable, Equatable {
        /// The whole container, ready to upload.
        public let data: Data
        public let header: Header
        public let headerBytes: Data

        /// SHA-256 of the whole encrypted object.
        public var sha256: Data { Digest.sha256(data) }
        /// For `POST /sync/snapshots` (`sha256`).
        public var sha256Base64URL: String { Base64URL.encode(sha256) }
        /// Standard padded base64, as S3's `x-amz-checksum-sha256` wants it.
        public var sha256Base64: String { sha256.base64EncodedString() }
        /// The payload AAD: SHA-256 of the exact header bytes.
        public var aad: Data { Digest.sha256(headerBytes) }
    }

    public struct Opened: Sendable, Equatable {
        public let header: Header
        /// The sync bundle JSON.
        public let bundle: Data
    }

    /// Padded plaintext length for a compressed payload: `4 + compressedLength` rounded up to 16 KiB.
    public static func paddedLength(forCompressedLength length: Int) -> Int {
        let used = 4 + length
        return ((used + paddingBlock - 1) / paddingBlock) * paddingBlock
    }

    public static func seal(bundle: Data, with ark: AccountRootKey, accountId: UUID, snapshotId: UUID, deviceId: UUID,
                            schema: Int, createdAt: Date = Date()) throws -> Sealed {
        try seal(bundle: bundle, with: ark, accountId: accountId, snapshotId: snapshotId, deviceId: deviceId,
                 schema: schema, createdAt: createdAt, dataKey: SecureRandom.bytes(32),
                 dekNonce: SecureRandom.bytes(12), nonce: SecureRandom.bytes(12))
    }

    /// Deterministic core: the random parts are passed in (tests and fixed vectors).
    static func seal(bundle: Data, with ark: AccountRootKey, accountId: UUID, snapshotId: UUID, deviceId: UUID,
                     schema: Int, createdAt: Date, dataKey: Data, dekNonce: Data, nonce: Data) throws -> Sealed {
        guard dataKey.count == 32, dekNonce.count == 12, nonce.count == 12 else { throw FocusCryptoError.invalidKeyLength }
        let compressed = try compress(bundle)
        guard compressed.count <= Int(UInt32.max) - paddingBlock else { throw FocusCryptoError.compressionFailed }
        let paddedLength = paddedLength(forCompressedLength: compressed.count)
        var plaintext = Data(capacity: paddedLength)
        plaintext.append(Data.bigEndian(UInt32(compressed.count)))
        plaintext.append(compressed)
        plaintext.append(Data(count: paddedLength - plaintext.count))

        let wrap = try AES.GCM.seal(dataKey, using: ark.keyEncryptionKey(accountId: accountId),
                                    nonce: try AES.GCM.Nonce(data: dekNonce), authenticating: dekAAD(snapshotId))
        let header = Header(v: formatVersion, alg: algorithm, snapshotId: snapshotId, accountId: accountId, deviceId: deviceId,
                            epoch: ark.epoch, schema: schema, createdAt: FocusJSON.truncatedToMilliseconds(createdAt),
                            wrappedDek: Base64URL.encode(wrap.ciphertext + wrap.tag),
                            dekNonce: Base64URL.encode(dekNonce), nonce: Base64URL.encode(nonce), paddedLength: paddedLength)
        let headerBytes = header.canonicalBytes()
        let box = try AES.GCM.seal(plaintext, using: SymmetricKey(data: dataKey), nonce: try AES.GCM.Nonce(data: nonce),
                                   authenticating: Digest.sha256(headerBytes))
        var data = magic
        data.append(Data.bigEndian(UInt32(headerBytes.count)))
        data.append(headerBytes)
        data.append(box.ciphertext)
        data.append(box.tag)
        return Sealed(data: data, header: header, headerBytes: headerBytes)
    }

    /// Reads the header without decrypting (for its epoch and schema).
    public static func readHeader(_ data: Data) throws -> (header: Header, headerBytes: Data) {
        guard data.count >= 8, data.bytes(at: 0, length: 4) == magic,
              let length = data.readUInt32BigEndian(at: 4) else { throw FocusCryptoError.notASnapshot }
        let headerLength = Int(length)
        guard headerLength > 0, headerLength <= maxHeaderLength,
              let headerBytes = data.bytes(at: 8, length: headerLength) else { throw FocusCryptoError.notASnapshot }
        let header: Header
        do { header = try FocusJSON.decode(Header.self, from: headerBytes) } catch {
            throw FocusCryptoError.unsupportedSnapshot("header")
        }
        guard header.v == formatVersion, header.alg == algorithm else {
            throw FocusCryptoError.unsupportedSnapshot("v\(header.v) \(header.alg)")
        }
        return (header, headerBytes)
    }

    /// Opens a container for `accountId`. `key` returns the root key for an epoch, when this phone has it.
    public static func open(_ data: Data, accountId: UUID, key: (Int) -> AccountRootKey?) throws -> Opened {
        let (header, headerBytes) = try readHeader(data)
        guard header.accountId == accountId else { throw FocusCryptoError.wrongAccount }
        guard let ark = key(header.epoch), ark.epoch == header.epoch else { throw FocusCryptoError.missingKey(epoch: header.epoch) }
        guard header.paddedLength > 0, header.paddedLength % paddingBlock == 0 else { throw FocusCryptoError.invalidPadding }
        guard let wrapped = Base64URL.decode(header.wrappedDek), wrapped.count == 48,
              let dekNonce = Base64URL.decode(header.dekNonce), dekNonce.count == 12,
              let nonce = Base64URL.decode(header.nonce), nonce.count == 12 else {
            throw FocusCryptoError.invalidEncoding("header fields")
        }

        let dataKey: Data
        do {
            let box = try AES.GCM.SealedBox(nonce: AES.GCM.Nonce(data: dekNonce), ciphertext: wrapped.prefix(32), tag: wrapped.suffix(16))
            dataKey = try AES.GCM.open(box, using: ark.keyEncryptionKey(accountId: accountId), authenticating: dekAAD(header.snapshotId))
        } catch {
            throw FocusCryptoError.authenticationFailed
        }
        guard dataKey.count == 32 else { throw FocusCryptoError.authenticationFailed }

        let payloadOffset = 8 + headerBytes.count
        guard let payload = data.bytes(at: payloadOffset, length: data.count - payloadOffset),
              payload.count == header.paddedLength + 16 else { throw FocusCryptoError.invalidPadding }
        let plaintext: Data
        do {
            let box = try AES.GCM.SealedBox(nonce: AES.GCM.Nonce(data: nonce), ciphertext: payload.prefix(header.paddedLength),
                                            tag: payload.suffix(16))
            plaintext = try AES.GCM.open(box, using: SymmetricKey(data: dataKey), authenticating: Digest.sha256(headerBytes))
        } catch {
            throw FocusCryptoError.authenticationFailed
        }

        guard plaintext.count == header.paddedLength, let length = plaintext.readUInt32BigEndian(at: 0) else {
            throw FocusCryptoError.invalidPadding
        }
        let compressedLength = Int(length)
        guard 4 + compressedLength <= plaintext.count,
              let compressed = plaintext.bytes(at: 4, length: compressedLength),
              let padding = plaintext.bytes(at: 4 + compressedLength, length: plaintext.count - 4 - compressedLength),
              padding.allSatisfy({ $0 == 0 }) else { throw FocusCryptoError.invalidPadding }
        return Opened(header: header, bundle: try decompress(compressed))
    }

    static func dekAAD(_ snapshotId: UUID) -> Data { Data("focus.dek.v1:\(snapshotId.wire)".utf8) }

    /// Raw DEFLATE (RFC 1951), which is what `NSData.CompressionAlgorithm.zlib` produces.
    static func compress(_ data: Data) throws -> Data {
        if data.isEmpty { return Data() }
        do { return try (data as NSData).compressed(using: .zlib) as Data } catch {
            throw FocusCryptoError.compressionFailed
        }
    }

    static func decompress(_ data: Data) throws -> Data {
        if data.isEmpty { return Data() }
        do { return try (data as NSData).decompressed(using: .zlib) as Data } catch {
            throw FocusCryptoError.compressionFailed
        }
    }
}

/// The small, fixed JSON the snapshot header needs: sorted keys, no spaces, strings and integers.
enum CanonicalJSON {
    case string(String)
    case int(Int)

    static func object(_ fields: [(String, CanonicalJSON)]) -> Data {
        let sorted = fields.sorted { $0.0.unicodeScalars.lexicographicallyPrecedes($1.0.unicodeScalars) }
        var out = "{"
        for (index, field) in sorted.enumerated() {
            if index > 0 { out += "," }
            out += quoted(field.0) + ":"
            switch field.1 {
            case .string(let text): out += quoted(text)
            case .int(let number): out += String(number)
            }
        }
        out += "}"
        return Data(out.utf8)
    }

    static func quoted(_ text: String) -> String {
        var out = "\""
        for scalar in text.unicodeScalars {
            switch scalar {
            case "\"": out += "\\\""
            case "\\": out += "\\\\"
            case "\n": out += "\\n"
            case "\r": out += "\\r"
            case "\t": out += "\\t"
            case _ where scalar.value < 0x20: out += String(format: "\\u%04x", scalar.value)
            default: out.unicodeScalars.append(scalar)
            }
        }
        return out + "\""
    }
}
