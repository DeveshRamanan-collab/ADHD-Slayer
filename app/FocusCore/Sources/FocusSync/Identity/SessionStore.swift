import Foundation

/// Access and refresh tokens in the Keychain (`session.access`, `session.refresh`): after first
/// unlock, this device only, never synchronizable, so they never move to another phone.
public struct SessionStore: Sendable {
    public static let accessKey = "session.access"
    public static let refreshKey = "session.refresh"

    private struct StoredToken: Codable {
        var token: String
        var expiresAt: Date
    }

    private let store: any SecureStore

    public init(store: any SecureStore) {
        self.store = store
    }

    public func load() -> Session? {
        guard let refresh = read(Self.refreshKey) else { return nil }
        // A missing access token (the app stopped between the two writes) just forces a refresh.
        let access = read(Self.accessKey) ?? StoredToken(token: "", expiresAt: .distantPast)
        return Session(accessToken: access.token, accessExpiresAt: access.expiresAt,
                       refreshToken: refresh.token, refreshExpiresAt: refresh.expiresAt)
    }

    /// Writes the refresh token first: if the app stops in between, the next launch refreshes with
    /// the newest refresh token instead of replaying a spent one (which would end the session).
    public func save(_ session: Session) throws {
        try write(StoredToken(token: session.refreshToken, expiresAt: session.refreshExpiresAt), to: Self.refreshKey)
        try write(StoredToken(token: session.accessToken, expiresAt: session.accessExpiresAt), to: Self.accessKey)
    }

    public func clear() {
        try? store.remove(Self.accessKey)
        try? store.remove(Self.refreshKey)
    }

    private func read(_ key: String) -> StoredToken? {
        guard let data = try? store.data(for: key) else { return nil }
        return try? FocusJSON.decode(StoredToken.self, from: data)
    }

    private func write(_ token: StoredToken, to key: String) throws {
        try store.set(try FocusJSON.encode(token), for: key)
    }
}
