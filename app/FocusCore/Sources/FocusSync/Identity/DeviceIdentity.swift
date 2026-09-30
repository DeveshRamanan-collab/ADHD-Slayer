import Foundation
import CryptoKit
import Security

/// This phone's identity on the server: an id made once at install, a P-256 signing key for device
/// proofs (in the Secure Enclave when the phone has one) and a P-256 agreement key that key slots
/// are sealed to. All three stay in this phone's Keychain.
public final class DeviceIdentity: Sendable {
    public static let deviceIdKey = "device.id"
    public static let signingKeyKey = "device.signing"
    public static let agreementKeyKey = "device.agreement"

    public let deviceId: UUID
    public let usesSecureEnclave: Bool
    public let signingPublicKey: P256.Signing.PublicKey
    public let agreementPublicKey: P256.KeyAgreement.PublicKey
    private let signer: Signer
    private let agreementPrivateKey: P256.KeyAgreement.PrivateKey

    private enum Signer: Sendable {
        case secureEnclave(SecureEnclave.P256.Signing.PrivateKey)
        case software(P256.Signing.PrivateKey)
    }

    private struct StoredSigningKey: Codable {
        enum Kind: String, Codable { case secureEnclave, software }
        var kind: Kind
        /// Secure Enclave `dataRepresentation` (only this phone's enclave can use it) or the software key.
        var key: String
    }

    /// A software identity, for tests and fixed vectors.
    public init(deviceId: UUID, signingKey: P256.Signing.PrivateKey, agreementKey: P256.KeyAgreement.PrivateKey) {
        self.deviceId = deviceId
        self.usesSecureEnclave = false
        self.signer = .software(signingKey)
        self.signingPublicKey = signingKey.publicKey
        self.agreementPrivateKey = agreementKey
        self.agreementPublicKey = agreementKey.publicKey
    }

    private init(deviceId: UUID, signer: Signer, agreementKey: P256.KeyAgreement.PrivateKey) {
        self.deviceId = deviceId
        self.signer = signer
        switch signer {
        case .secureEnclave(let key):
            usesSecureEnclave = true
            signingPublicKey = key.publicKey
        case .software(let key):
            usesSecureEnclave = false
            signingPublicKey = key.publicKey
        }
        self.agreementPrivateKey = agreementKey
        self.agreementPublicKey = agreementKey.publicKey
    }

    /// Loads this phone's identity, making any missing part once.
    ///
    /// The signing key goes in the Secure Enclave when `SecureEnclave.isAvailable` (and
    /// `preferSecureEnclave`), else it's a software key in the Keychain. The agreement key is always a
    /// software key, because HPKE needs it.
    public static func loadOrCreate(in store: any SecureStore, preferSecureEnclave: Bool = true) throws -> DeviceIdentity {
        let deviceId: UUID
        if let data = try store.data(for: deviceIdKey), let text = String(data: data, encoding: .utf8),
           let id = UUID(uuidString: text) {
            deviceId = id
        } else {
            deviceId = UUID()
            try store.set(Data(deviceId.wire.utf8), for: deviceIdKey)
        }

        let signer: Signer
        if let existing = try loadSigner(from: store) {
            signer = existing
        } else {
            signer = try makeSigner(preferSecureEnclave: preferSecureEnclave)
            try store.set(try encodeSigner(signer), for: signingKeyKey)
        }

        let agreement: P256.KeyAgreement.PrivateKey
        if let data = try store.data(for: agreementKeyKey),
           let key = try? P256.KeyAgreement.PrivateKey(rawRepresentation: data) {
            agreement = key
        } else {
            agreement = P256.KeyAgreement.PrivateKey()
            try store.set(agreement.rawRepresentation, for: agreementKeyKey)
        }
        return DeviceIdentity(deviceId: deviceId, signer: signer, agreementKey: agreement)
    }

    /// Forgets this phone's identity (account deletion). A new one is made next time.
    public static func removeStored(from store: any SecureStore) {
        try? store.remove(deviceIdKey)
        try? store.remove(signingKeyKey)
        try? store.remove(agreementKeyKey)
    }

    // MARK: Public keys

    /// Base64url of the 65-byte uncompressed X9.63 point.
    public var signingKey: String { Base64URL.encode(signingPublicKey.x963Representation) }
    public var agreementKey: String { Base64URL.encode(agreementPublicKey.x963Representation) }

    /// The `device` object sent at sign-in.
    public func registration(appVersion: String, osVersion: String, model: String = DeviceModel.identifier) -> DeviceRegistration {
        DeviceRegistration(deviceId: deviceId, model: model, osVersion: osVersion, appVersion: appVersion,
                           signingKey: signingKey, agreementKey: agreementKey)
    }

    // MARK: Using the private keys

    /// ES256 over `message`: the 64-byte raw `r || s`.
    public func signature(for message: Data) throws -> Data {
        switch signer {
        case .secureEnclave(let key): try key.signature(for: message).rawRepresentation
        case .software(let key): try key.signature(for: message).rawRepresentation
        }
    }

    /// Opens a key slot sealed to this phone (a device slot or a key transfer).
    public func openSlot(_ slot: SealedSlot, accountId: UUID) throws -> AccountRootKey {
        try DeviceSlot.open(slot, with: agreementPrivateKey, accountId: accountId)
    }

    // MARK: Storage

    private static func loadSigner(from store: any SecureStore) throws -> Signer? {
        guard let data = try store.data(for: signingKeyKey),
              let stored = try? JSONDecoder().decode(StoredSigningKey.self, from: data),
              let keyData = Base64URL.decode(stored.key) else { return nil }
        switch stored.kind {
        case .secureEnclave:
            guard let key = try? SecureEnclave.P256.Signing.PrivateKey(dataRepresentation: keyData) else { return nil }
            return .secureEnclave(key)
        case .software:
            guard let key = try? P256.Signing.PrivateKey(rawRepresentation: keyData) else { return nil }
            return .software(key)
        }
    }

    private static func makeSigner(preferSecureEnclave: Bool) throws -> Signer {
        if preferSecureEnclave, SecureEnclave.isAvailable,
           let access = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly, .privateKeyUsage, nil),
           let key = try? SecureEnclave.P256.Signing.PrivateKey(compactRepresentable: false, accessControl: access) {
            return .secureEnclave(key)
        }
        return .software(P256.Signing.PrivateKey())
    }

    private static func encodeSigner(_ signer: Signer) throws -> Data {
        let stored = switch signer {
        case .secureEnclave(let key): StoredSigningKey(kind: .secureEnclave, key: Base64URL.encode(key.dataRepresentation))
        case .software(let key): StoredSigningKey(kind: .software, key: Base64URL.encode(key.rawRepresentation))
        }
        return try JSONEncoder().encode(stored)
    }
}
