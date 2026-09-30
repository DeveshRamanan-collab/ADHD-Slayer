import Foundation
import FocusSync

/// Small wrapper for secrets that must never sit in UserDefaults or files: the account record and any
/// key the person pastes for their own AI provider. Items are this-device-only and need the phone to
/// have been unlocked once since restart. Session tokens, device keys and backup keys live in the same
/// Keychain service through FocusSync.
enum Keychain {
    /// Service `au.adhdslayer.focus`: after first unlock, this device only, never synchronizable.
    static let store = KeychainStore.deviceItems

    static func set(_ value: String?, for key: String) {
        if let value, let data = value.data(using: .utf8) {
            try? store.set(data, for: key)
        } else {
            try? store.remove(key)
        }
    }

    static func get(_ key: String) -> String? {
        guard let data = try? store.data(for: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Removes every item in this app's service except `keeping`.
    static func removeAll(keeping: Set<String> = []) {
        for key in (try? store.allKeys()) ?? [] where !keeping.contains(key) {
            try? store.remove(key)
        }
    }

    /// The iCloud Keychain copy of the backup key. Only account deletion removes it.
    static func removeICloudCopy() {
        try? KeychainStore.iCloudEscrow.removeAll()
    }
}
