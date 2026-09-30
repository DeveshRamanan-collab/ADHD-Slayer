import Foundation
import UserNotifications
import FocusSync

/// Clearing this phone when an account goes (02-backend.md, Deleting an account): the health store,
/// UserDefaults, Keychain items, App Group files and pending notifications.
enum LocalData {
    /// Needed to finish an account deletion that couldn't reach the server yet.
    static let deletionCredentials: Set<String> = [
        DeviceIdentity.deviceIdKey, DeviceIdentity.signingKeyKey, DeviceIdentity.agreementKeyKey,
        SessionStore.accessKey, SessionStore.refreshKey, AccountStore.pendingDeletionKey,
    ]

    /// This phone's own identity, which outlives any one account.
    static let deviceIdentity: Set<String> = [DeviceIdentity.deviceIdKey, DeviceIdentity.signingKeyKey, DeviceIdentity.agreementKeyKey]

    /// The shared container widgets and the Live Activity read (FocusGlance.appGroup).
    static let appGroup = "group.au.adhdslayer.focus"

    /// After the server accepted the deletion: everything, the iCloud Keychain copy of the backup key too.
    static func wipeEverything() {
        wipeAppData()
        Keychain.removeAll()
        Keychain.removeICloudCopy()
    }

    /// Offline deletion: this phone is cleared now, keeping only what finishes the job on the server.
    static func wipeKeepingDeletionCredentials() {
        wipeAppData()
        Keychain.removeAll(keeping: deletionCredentials)
    }

    /// Sign out with "Remove it": this phone's data goes; the account, the backup and its iCloud key stay.
    static func removeThisPhonesData() {
        wipeAppData()
        Keychain.removeAll(keeping: deviceIdentity)
    }

    private static func wipeAppData() {
        DataExport.wipe()
        let files = FileManager.default
        if let support = files.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            try? files.removeItem(at: support.appendingPathComponent("Health", isDirectory: true))
        }
        if let group = files.containerURL(forSecurityApplicationGroupIdentifier: appGroup) {
            for item in (try? files.contentsOfDirectory(at: group, includingPropertiesForKeys: nil)) ?? []
            where item.lastPathComponent != "Library" {
                try? files.removeItem(at: item)
            }
            UserDefaults(suiteName: appGroup)?.removePersistentDomain(forName: appGroup)
        }
        let notifications = UNUserNotificationCenter.current()
        notifications.removeAllPendingNotificationRequests()
        notifications.removeAllDeliveredNotifications()
    }
}
