import Foundation
import Security
import Synchronization

/// Where secrets live. The app uses `KeychainStore`; tests use `InMemorySecureStore`.
public protocol SecureStore: Sendable {
    func data(for key: String) throws -> Data?
    func set(_ data: Data, for key: String) throws
    func remove(_ key: String) throws
    /// Every item name this store holds.
    func allKeys() throws -> [String]
}

public struct SecureStoreError: Error, Sendable, Equatable, CustomStringConvertible {
    public let status: OSStatus

    public init(_ status: OSStatus) { self.status = status }

    /// The phone is locked and the item needs it unlocked.
    public var isLocked: Bool { status == errSecInteractionNotAllowed }

    public var description: String {
        let text = SecCopyErrorMessageString(status, nil) as String? ?? "unknown"
        return "Keychain error \(status): \(text)"
    }
}

/// Generic-password items in one Keychain service. Never synchronizable unless asked for the iCloud
/// Keychain copy of the root key.
public struct KeychainStore: SecureStore {
    public enum Accessibility: Sendable {
        /// Tokens and device keys: readable in the background after the first unlock, never on another phone.
        case afterFirstUnlockThisDeviceOnly
        /// Account root keys on this phone.
        case whenUnlockedThisDeviceOnly
        /// The iCloud Keychain copy (synchronizable items can't be this-device-only).
        case whenUnlocked
    }

    public let service: String
    public let accessibility: Accessibility
    public let synchronizable: Bool

    public init(service: String = FocusSync.keychainService,
                accessibility: Accessibility = .afterFirstUnlockThisDeviceOnly,
                synchronizable: Bool = false) {
        self.service = service
        self.accessibility = accessibility
        self.synchronizable = synchronizable
    }

    /// Tokens, device id and keys, the link verifier, markers.
    public static let deviceItems = KeychainStore()
    /// Account root keys: `sync.ark.<epoch>`, when unlocked, this device only.
    public static let rootKeys = KeychainStore(accessibility: .whenUnlockedThisDeviceOnly)
    /// The optional iCloud Keychain copy of the root key (service `au.adhdslayer.focus.escrow`).
    public static let iCloudEscrow = KeychainStore(service: FocusSync.escrowKeychainService,
                                                   accessibility: .whenUnlocked, synchronizable: true)

    private var accessibleValue: CFString {
        switch accessibility {
        case .afterFirstUnlockThisDeviceOnly: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        case .whenUnlockedThisDeviceOnly: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case .whenUnlocked: kSecAttrAccessibleWhenUnlocked
        }
    }

    private func query(_ key: String?) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecUseDataProtectionKeychain as String: true,
            kSecAttrSynchronizable as String: synchronizable,
        ]
        if let key { query[kSecAttrAccount as String] = key }
        return query
    }

    public func data(for key: String) throws -> Data? {
        var request = query(key)
        request[kSecReturnData as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(request as CFDictionary, &item)
        switch status {
        case errSecSuccess: return item as? Data
        case errSecItemNotFound: return nil
        default: throw SecureStoreError(status)
        }
    }

    public func set(_ data: Data, for key: String) throws {
        let match = query(key)
        let attributes: [String: Any] = [kSecValueData as String: data, kSecAttrAccessible as String: accessibleValue]
        var status = SecItemUpdate(match as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var add = match
            add.merge(attributes) { _, new in new }
            status = SecItemAdd(add as CFDictionary, nil)
        }
        guard status == errSecSuccess else { throw SecureStoreError(status) }
    }

    public func remove(_ key: String) throws {
        let status = SecItemDelete(query(key) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw SecureStoreError(status) }
    }

    public func allKeys() throws -> [String] {
        var request = query(nil)
        request[kSecReturnAttributes as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitAll
        var items: CFTypeRef?
        let status = SecItemCopyMatching(request as CFDictionary, &items)
        switch status {
        case errSecSuccess:
            let rows = items as? [[String: Any]] ?? []
            return rows.compactMap { $0[kSecAttrAccount as String] as? String }
        case errSecItemNotFound: return []
        default: throw SecureStoreError(status)
        }
    }

    /// Deletes every item in this service (account deletion).
    public func removeAll() throws {
        let status = SecItemDelete(query(nil) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw SecureStoreError(status) }
    }
}

/// For tests and previews.
public final class InMemorySecureStore: SecureStore {
    private let items: Mutex<[String: Data]>

    public init(_ items: [String: Data] = [:]) {
        self.items = Mutex(items)
    }

    public func data(for key: String) throws -> Data? { items.withLock { $0[key] } }
    public func set(_ data: Data, for key: String) throws { items.withLock { $0[key] = data } }
    public func remove(_ key: String) throws { _ = items.withLock { $0.removeValue(forKey: key) } }
    public func allKeys() throws -> [String] { items.withLock { Array($0.keys).sorted() } }
}
