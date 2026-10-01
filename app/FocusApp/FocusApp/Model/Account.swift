import Foundation
import Observation
import AuthenticationServices

/// The account made on first launch. It exists so a person's plan, day types and settings can follow
/// them to a new phone (end-to-end encrypted, see the backend spec) and so a subscription bought with
/// Apple is tied to them. It never holds medication data in the clear.
///
/// Three ways in: Sign in with Apple, Google, or an email link. The server side of each lives behind
/// `AuthBackend`; this build ships a local backend so the app runs without a server.
@MainActor @Observable
final class AccountStore {
    struct Account: Codable, Equatable {
        enum Method: String, Codable { case apple, google, email }
        var id: UUID
        var method: Method
        var email: String?
        var name: String?
        var createdAt: Date
    }

    enum AuthError: LocalizedError, Equatable {
        case notConfigured(String)
        case invalidEmail
        case cancelled
        case failed(String)

        var errorDescription: String? {
            switch self {
            case .notConfigured(let what): "\(what) sign-in isn’t switched on in this build yet."
            case .invalidEmail: "That email doesn’t look quite right."
            case .cancelled: nil
            case .failed(let why): why
            }
        }
    }

    private(set) var account: Account?
    private(set) var pendingEmail: String?
    private let backend: AuthBackend

    init(backend: AuthBackend = LocalAuthBackend()) {
        self.backend = backend
        if let data = Keychain.get("account")?.data(using: .utf8) {
            account = try? JSONDecoder().decode(Account.self, from: data)
        }
    }

    var isSignedIn: Bool { account != nil }

    // MARK: Sign in with Apple

    func configure(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    func completeApple(_ result: Result<ASAuthorization, Error>) async throws {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { throw AuthError.failed("Apple didn’t send a sign-in.") }
            let token = credential.identityToken.flatMap { String(data: $0, encoding: .utf8) }
            let name = [credential.fullName?.givenName, credential.fullName?.familyName].compactMap { $0 }.joined(separator: " ")
            let id = try await backend.exchangeApple(userID: credential.user, identityToken: token)
            save(Account(id: id, method: .apple, email: credential.email, name: name.isEmpty ? nil : name, createdAt: .now))
        case .failure(let error):
            if (error as? ASAuthorizationError)?.code == .canceled { throw AuthError.cancelled }
            throw AuthError.failed("Sign in with Apple didn’t finish. Try again?")
        }
    }

    // MARK: Google

    /// Google uses the standard OAuth flow in Apple's secure web sheet (ASWebAuthenticationSession
    /// with PKCE). It needs a client id in Info.plist (`GIDClientID`); without one it says so plainly.
    func signInWithGoogle() async throws {
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String, !clientID.isEmpty else {
            throw AuthError.notConfigured("Google")
        }
        let id = try await backend.exchangeGoogle(clientID: clientID)
        save(Account(id: id, method: .google, email: nil, name: nil, createdAt: .now))
    }

    // MARK: Email

    /// Sends a one-tap sign-in link (no password to forget). The link opens the app and finishes here.
    func startEmail(_ email: String) async throws {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.contains("@"), trimmed.contains("."), trimmed.count >= 5 else { throw AuthError.invalidEmail }
        try await backend.sendEmailLink(to: trimmed)
        pendingEmail = trimmed
    }

    func finishEmail(token: String? = nil) async throws {
        guard let email = pendingEmail else { return }
        let id = try await backend.verifyEmailLink(email: email, token: token)
        save(Account(id: id, method: .email, email: email, name: nil, createdAt: .now))
        pendingEmail = nil
    }

    // MARK: Leaving

    func signOut() {
        account = nil
        Keychain.set(nil, for: "account")
    }

    /// Deletes the account on the server (revoking the Apple token where used), then everything on
    /// this phone. Irreversible, so the UI asks twice.
    func deleteAccount() async {
        if let account { try? await backend.delete(accountID: account.id, method: account.method) }
        signOut()
    }

    private func save(_ account: Account) {
        self.account = account
        if let data = try? JSONEncoder().encode(account) { Keychain.set(String(data: data, encoding: .utf8), for: "account") }
    }
}

/// The server half of sign-in. See the backend spec for the real endpoints.
protocol AuthBackend: Sendable {
    func exchangeApple(userID: String, identityToken: String?) async throws -> UUID
    func exchangeGoogle(clientID: String) async throws -> UUID
    func sendEmailLink(to email: String) async throws
    func verifyEmailLink(email: String, token: String?) async throws -> UUID
    func delete(accountID: UUID, method: AccountStore.Account.Method) async throws
}

/// Runs without a server: makes a local account id and pretends the email link was tapped.
struct LocalAuthBackend: AuthBackend {
    func exchangeApple(userID: String, identityToken: String?) async throws -> UUID { UUID() }
    func exchangeGoogle(clientID: String) async throws -> UUID { UUID() }
    func sendEmailLink(to email: String) async throws {}
    func verifyEmailLink(email: String, token: String?) async throws -> UUID { UUID() }
    func delete(accountID: UUID, method: AccountStore.Account.Method) async throws {}
}

