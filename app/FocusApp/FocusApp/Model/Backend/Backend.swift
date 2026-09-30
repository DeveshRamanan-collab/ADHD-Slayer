import Foundation
import FocusSync

/// The app's link to the Focus server, made once from Info.plist (`FocusAPIBaseURL`,
/// `FocusCDNBaseURL`). An empty base URL (Debug builds by default) means no server: sign-in stays
/// local and nothing leaves the phone. Debug builds also honour `FOCUS_API_BASE_URL` (and
/// `FOCUS_CDN_BASE_URL`) from the environment, so the simulator can use `http://localhost:8080/v1`.
final class Backend {
    static let shared = Backend()

    /// Nil when no server is configured.
    let client: APIClient?

    private init() {
        #if DEBUG
        let allowOverride = true
        #else
        let allowOverride = false
        #endif
        let configuration = APIConfiguration.resolve(infoDictionary: Bundle.main.infoDictionary ?? [:],
                                                     environment: ProcessInfo.processInfo.environment,
                                                     allowEnvironmentOverride: allowOverride)
        client = configuration.map { configuration in
            let store = KeychainStore.deviceItems
            return APIClient(configuration: configuration, sessionStore: SessionStore(store: store),
                             identity: { try DeviceIdentity.loadOrCreate(in: store) })
        }
    }

    /// Posts a StoreKit transaction (`jwsRepresentation`) so the server can link the purchase to this
    /// account. Fire and forget: nothing waits on it, a few quiet retries if offline, and StoreKit on
    /// the phone stays the truth either way.
    func reportTransaction(_ signedTransaction: String) {
        guard let client else { return }
        Task.detached(priority: .utility) {
            guard await client.hasSession else { return }
            _ = try? await withBackgroundRetry(policy: RetryPolicy(maxAttempts: 6)) {
                try await client.postTransaction(signedTransaction: signedTransaction)
            }
        }
    }
}
