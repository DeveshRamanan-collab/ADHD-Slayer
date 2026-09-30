import Foundation
import CryptoKit
import Security

/// Unpadded base64url (RFC 4648 section 5), the contract's default for binary.
public enum Base64URL {
    public static func encode(_ bytes: some Sequence<UInt8>) -> String {
        var text = Data(bytes).base64EncodedString()
        text = text.replacingOccurrences(of: "+", with: "-")
        text = text.replacingOccurrences(of: "/", with: "_")
        while text.hasSuffix("=") { text.removeLast() }
        return text
    }

    /// Accepts unpadded or padded input. Returns nil for anything that isn't base64url.
    public static func decode(_ text: String) -> Data? {
        var body = text
        while body.hasSuffix("=") { body.removeLast() }
        guard body.utf8.allSatisfy({ byte in
            (byte >= 0x41 && byte <= 0x5A) || (byte >= 0x61 && byte <= 0x7A) || (byte >= 0x30 && byte <= 0x39) || byte == 0x2D || byte == 0x5F
        }) else { return nil }
        body = body.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        switch body.count % 4 {
        case 0: break
        case 2: body += "=="
        case 3: body += "="
        default: return nil
        }
        return Data(base64Encoded: body)
    }
}

/// Lowercase hexadecimal, as used for SHA-256 digests in canonical strings and nonces.
public enum Hex {
    private static let digits = Array("0123456789abcdef".utf8)

    public static func encode(_ bytes: some Sequence<UInt8>) -> String {
        var out: [UInt8] = []
        for byte in bytes {
            out.append(digits[Int(byte >> 4)])
            out.append(digits[Int(byte & 0x0F)])
        }
        return String(decoding: out, as: UTF8.self)
    }

    public static func decode(_ text: String) -> Data? {
        let chars = Array(text.utf8)
        guard chars.count % 2 == 0 else { return nil }
        var out = Data(capacity: chars.count / 2)
        var index = 0
        while index < chars.count {
            guard let high = value(chars[index]), let low = value(chars[index + 1]) else { return nil }
            out.append(high << 4 | low)
            index += 2
        }
        return out
    }

    private static func value(_ char: UInt8) -> UInt8? {
        switch char {
        case 0x30...0x39: char - 0x30
        case 0x61...0x66: char - 0x61 + 10
        case 0x41...0x46: char - 0x41 + 10
        default: nil
        }
    }
}

enum Digest {
    static func sha256(_ bytes: some DataProtocol) -> Data { Data(SHA256.hash(data: bytes)) }
    static func sha256Hex(_ bytes: some DataProtocol) -> String { Hex.encode(SHA256.hash(data: bytes)) }
}

enum SecureRandom {
    /// Cryptographically secure random bytes from the system generator.
    static func bytes(_ count: Int) -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        precondition(status == errSecSuccess, "The system random number generator failed (\(status)).")
        return Data(bytes)
    }
}

extension Data {
    /// Constant-time comparison for secrets and fingerprints.
    func constantTimeEquals(_ other: Data) -> Bool {
        guard count == other.count else { return false }
        var difference: UInt8 = 0
        for (a, b) in zip(self, other) { difference |= a ^ b }
        return difference == 0
    }

    static func bigEndian(_ value: UInt32) -> Data {
        Data([UInt8(value >> 24 & 0xFF), UInt8(value >> 16 & 0xFF), UInt8(value >> 8 & 0xFF), UInt8(value & 0xFF)])
    }

    /// Reads a big-endian UInt32 at `offset` from the start of the data (not from `startIndex` of a slice).
    func readUInt32BigEndian(at offset: Int) -> UInt32? {
        guard offset >= 0, offset + 4 <= count else { return nil }
        let start = startIndex + offset
        return self[start..<start + 4].reduce(UInt32(0)) { $0 << 8 | UInt32($1) }
    }

    func readUInt64BigEndian(at offset: Int) -> UInt64? {
        guard offset >= 0, offset + 8 <= count else { return nil }
        let start = startIndex + offset
        return self[start..<start + 8].reduce(UInt64(0)) { $0 << 8 | UInt64($1) }
    }

    /// A zero-based copy of `length` bytes at `offset`.
    func bytes(at offset: Int, length: Int) -> Data? {
        guard offset >= 0, length >= 0, offset + length <= count else { return nil }
        let start = startIndex + offset
        return Data(self[start..<start + length])
    }
}
