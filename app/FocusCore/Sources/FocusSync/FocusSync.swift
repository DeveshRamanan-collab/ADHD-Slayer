import Foundation

/// The iPhone side of the Focus backend: the API client, sessions, device proofs, sign-in helpers,
/// and the end-to-end encryption for backups and moving phones.
///
/// Byte formats follow `backend/CONTRACT.md`; behaviour follows `docs/build-spec/02-backend.md`.
/// See `README.md` in this folder for how the app uses it.
public enum FocusSync {
    /// Bumped only when a byte format in CONTRACT.md changes.
    public static let contractVersion = 1

    /// Keychain service for this device's items: tokens, device keys, root keys, markers.
    public static let keychainService = "au.adhdslayer.focus"

    /// Keychain service for the optional iCloud Keychain copy of the account root key.
    public static let escrowKeychainService = "au.adhdslayer.focus.escrow"

    /// The largest encrypted snapshot the app will try to upload (the server's limit is 10 MB).
    public static let maxSnapshotBytes = 10_000_000
}

extension UUID {
    /// Ids travel as lowercase hyphenated strings (CONTRACT.md, General). `uuidString` is upper case.
    var wire: String { uuidString.lowercased() }
}
