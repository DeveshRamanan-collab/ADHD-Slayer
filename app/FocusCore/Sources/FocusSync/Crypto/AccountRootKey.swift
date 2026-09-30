import Foundation
import CryptoKit

public enum FocusCryptoError: Error, Sendable, Equatable {
    case invalidKeyLength
    case invalidEncoding(String)
    case notASnapshot
    case unsupportedSnapshot(String)
    case wrongAccount
    case missingKey(epoch: Int)
    /// A tag didn't verify: wrong key, or the bytes were changed.
    case authenticationFailed
    case compressionFailed
    case invalidPadding
    case invalidRecoveryKey
    case invalidTransferCode
    case invalidPublicKey
}

/// The account root key (ARK): 32 random bytes per key epoch. Only the person's devices hold it.
public struct AccountRootKey: Sendable, Equatable {
    public let epoch: Int
    private let raw: Data

    public init(epoch: Int, rawKey: Data) throws {
        guard rawKey.count == 32 else { throw FocusCryptoError.invalidKeyLength }
        self.epoch = epoch
        self.raw = Data(rawKey)
    }

    private init(uncheckedEpoch epoch: Int, raw: Data) {
        self.epoch = epoch
        self.raw = raw
    }

    public static func generate(epoch: Int) -> AccountRootKey {
        AccountRootKey(uncheckedEpoch: epoch, raw: SecureRandom.bytes(32))
    }

    public var rawKey: Data { raw }

    var symmetricKey: SymmetricKey { SymmetricKey(data: raw) }

    /// KEK: HKDF-SHA256(ikm ARK, salt UTF-8 of the lowercase account id, info `focus.kek.v1`, 32 bytes).
    /// It lives in memory only.
    public func keyEncryptionKey(accountId: UUID) -> SymmetricKey {
        HKDF<SHA256>.deriveKey(inputKeyMaterial: symmetricKey, salt: Data(accountId.wire.utf8),
                               info: Data("focus.kek.v1".utf8), outputByteCount: 32)
    }
}

/// Account root keys on this phone (`sync.ark.<epoch>`, when unlocked, this device only), with an
/// optional iCloud Keychain copy (service `au.adhdslayer.focus.escrow`, synchronizable) that a new
/// phone signed in to the same iCloud Keychain can use first.
public struct KeyRing: Sendable {
    private struct StoredKey: Codable {
        var accountId: String
        var epoch: Int
        var key: String
    }

    private let store: any SecureStore
    private let escrow: (any SecureStore)?

    public init(store: any SecureStore, escrow: (any SecureStore)? = nil) {
        self.store = store
        self.escrow = escrow
    }

    static func deviceItemName(epoch: Int) -> String { "sync.ark.\(epoch)" }
    static func escrowItemName(accountId: UUID, epoch: Int) -> String { "ark.\(accountId.wire).\(epoch)" }

    /// Keeps the key on this phone and, when an escrow store is set, in iCloud Keychain too.
    public func save(_ ark: AccountRootKey, accountId: UUID) throws {
        let stored = StoredKey(accountId: accountId.wire, epoch: ark.epoch, key: Base64URL.encode(ark.rawKey))
        let data = try JSONEncoder().encode(stored)
        try store.set(data, for: Self.deviceItemName(epoch: ark.epoch))
        try? escrow?.set(data, for: Self.escrowItemName(accountId: accountId, epoch: ark.epoch))
    }

    /// The key for `epoch` held on this phone.
    public func ark(epoch: Int, accountId: UUID) -> AccountRootKey? {
        read(store, Self.deviceItemName(epoch: epoch), accountId: accountId)
    }

    /// The iCloud Keychain copy, when there is one.
    public func escrowedARK(epoch: Int, accountId: UUID) -> AccountRootKey? {
        guard let escrow else { return nil }
        return read(escrow, Self.escrowItemName(accountId: accountId, epoch: epoch), accountId: accountId)
    }

    /// Epochs held on this phone, oldest first.
    public func epochs(accountId: UUID) -> [Int] {
        let names = (try? store.allKeys()) ?? []
        return names.compactMap { name -> Int? in
            guard name.hasPrefix("sync.ark."), let epoch = Int(name.dropFirst("sync.ark.".count)),
                  ark(epoch: epoch, accountId: accountId) != nil else { return nil }
            return epoch
        }.sorted()
    }

    public func latest(accountId: UUID) -> AccountRootKey? {
        epochs(accountId: accountId).last.flatMap { ark(epoch: $0, accountId: accountId) }
    }

    /// Forgets every root key on this phone; with `includingEscrow`, the iCloud copies for this account too.
    public func removeAll(accountId: UUID? = nil, includingEscrow: Bool = false) {
        for name in (try? store.allKeys()) ?? [] where name.hasPrefix("sync.ark.") {
            try? store.remove(name)
        }
        guard includingEscrow, let escrow else { return }
        let prefix = accountId.map { "ark.\($0.wire)." } ?? "ark."
        for name in (try? escrow.allKeys()) ?? [] where name.hasPrefix(prefix) {
            try? escrow.remove(name)
        }
    }

    private func read(_ source: any SecureStore, _ name: String, accountId: UUID) -> AccountRootKey? {
        guard let data = try? source.data(for: name),
              let stored = try? JSONDecoder().decode(StoredKey.self, from: data),
              stored.accountId == accountId.wire,
              let raw = Base64URL.decode(stored.key) else { return nil }
        return try? AccountRootKey(epoch: stored.epoch, rawKey: raw)
    }
}
