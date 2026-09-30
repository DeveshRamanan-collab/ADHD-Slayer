import Foundation
import Observation
import AuthenticationServices
import FocusSync

/// The account made on first launch. It exists so a person's plan, day types and settings can follow
/// them to a new phone (end-to-end encrypted, see the backend spec) and so a subscription bought with
/// Apple is tied to them. It never holds medication data in the clear.
///
/// Three ways in: Sign in with Apple, Google, or an email link (with a 6-digit code as the fallback).
/// The server side of each lives behind `AuthBackend`: `HTTPAuthBackend` when Info.plist names a
/// server, `LocalAuthBackend` when it doesn't, so the app always runs.
///
/// It never signs out silently. When the server ends a session the account stays, the app keeps
/// working, and `sessionEnded` turns on for the calm "Sign in again to keep your backup up to date."
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
        case offline
        case providerFailed
        /// The server wants the 18+ confirmation again: back to the toggle.
        case adultConfirmationNeeded
        case wrongDevice
        case linkExpired
        case codeMismatch
        case tooManyCodes
        case emailInUse
        case deletionPending(completesBy: Date?)
        case otherAccountsData
        case rateLimited
        case tryLater
        case updateNeeded
        case failed(String)

        var errorDescription: String? {
            switch self {
            case .notConfigured(let what): "\(what) sign-in isn’t switched on in this build yet."
            case .invalidEmail: "That email doesn’t look quite right."
            case .cancelled, .adultConfirmationNeeded: nil
            case .offline: "No connection right now. Try again in a moment."
            case .providerFailed: "That sign-in didn’t work. Try again?"
            case .wrongDevice: "Open it on the iPhone where you asked for it."
            case .linkExpired: "That link has expired. Want a new one?"
            case .codeMismatch: "That code didn’t match. Check the email and try again."
            case .tooManyCodes: "That’s a few wrong codes. Let’s send a fresh link."
            case .emailInUse: "You already have an account with this email. Sign in the way you did before."
            case .deletionPending(let date):
                date.map { "This account is being deleted. That finishes by \($0.formatted(.dateTime.day().month().hour().minute()))." }
                    ?? "This account is being deleted."
            case .otherAccountsData: "This iPhone has another account’s data on it. Sign in with that account, or delete this iPhone’s data in Settings first."
            case .rateLimited: "That’s a lot of tries. Give it a minute, then try again."
            case .tryLater: "We can’t reach sign-in right now. Try again in a little while."
            case .updateNeeded: "Update Focus when you can."
            case .failed(let why): why
            }
        }

        /// "Send a new link" is the way forward.
        var offersNewLink: Bool { self == .linkExpired || self == .tooManyCodes }
    }

    enum DeletionOutcome: Equatable {
        /// The server took it: everything on this phone is gone too.
        case deleted
        /// Offline: this phone is cleared, and the server part finishes at a later launch.
        case pending
        /// The session had ended, so the server can't be asked yet.
        case needsSignIn
    }

    /// Terms and Privacy Policy versions the account step agrees to.
    enum LegalVersion {
        static let terms = 1
        static let privacy = 1
    }

    static let accountKey = "account"
    static let appleUserIDKey = "appleUserID"
    static let pendingDeletionKey = "pendingDeletion"
    /// UserDefaults, like the rest of this phone's data: whose data this is, so another account can't
    /// sign in over it. "Delete everything on this iPhone" clears it along with everything else.
    static let dataOwnerKey = "accountDataOwner"
    /// UserDefaults: when "I'm 18 or older" was switched on (only the time, never a birth date).
    static let adultConfirmedAtKey = "adultConfirmedAt"

    private(set) var account: Account?
    /// The address a link went to, while waiting for the link or its code.
    private(set) var pendingEmail: String?
    private(set) var emailSentAt: Date?
    private(set) var resendAfter: TimeInterval = 60
    /// A link opened from Mail, waiting for the account step to verify it.
    private(set) var pendingLinkToken: String?
    /// The server ended the session. Local use continues; the app can show "Sign in again to keep
    /// your backup up to date."
    private(set) var sessionEnded = false
    /// An account deletion is waiting for a connection ("Deletion will finish when you're back online.").
    private(set) var deletionPending = false

    private let backend: any AuthBackend
    private var appleNonce: SignInNonce?
    private static var launchChecksStarted = false

    init(backend: (any AuthBackend)? = nil) {
        let backend = backend ?? Self.defaultBackend()
        self.backend = backend
        account = Self.loadAccount()
        deletionPending = Keychain.get(Self.pendingDeletionKey) != nil
        pendingEmail = backend.pendingEmail
        backend.onSessionEnded { [weak self] in self?.sessionEnded = true }
        Task { await self.runLaunchChecks() }
    }

    private static func defaultBackend() -> any AuthBackend {
        if let client = Backend.shared.client { return HTTPAuthBackend(client: client) }
        return LocalAuthBackend()
    }

    var isSignedIn: Bool { account != nil }

    /// False when this build has no server (everything stays on the phone).
    var usesServer: Bool { backend.usesServer }

    // MARK: Sign in with Apple

    /// Asks for name and email, and sets the hashed nonce; the raw nonce goes to our server.
    func configure(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
        let nonce = SignInNonce.make()
        appleNonce = nonce
        request.nonce = nonce.hashed
    }

    func completeApple(_ result: Result<ASAuthorization, Error>) async throws {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                throw AuthError.failed("Apple didn’t send a sign-in.")
            }
            let token = credential.identityToken.flatMap { String(data: $0, encoding: .utf8) }
            let code = credential.authorizationCode.flatMap { String(data: $0, encoding: .utf8) }
            let nonce = appleNonce
            appleNonce = nil
            if backend.usesServer, token == nil || code == nil || nonce == nil {
                throw AuthError.failed("Apple didn’t send a sign-in.")
            }
            let name = [credential.fullName?.givenName, credential.fullName?.familyName].compactMap { $0 }.joined(separator: " ")
            await finishPendingDeletion()
            let signedIn = try await backend.signInWithApple(
                AppleCredential(identityToken: token ?? "", authorizationCode: code ?? "", rawNonce: nonce?.raw ?? "", userID: credential.user),
                consents: consents)
            try await complete(signedIn, method: .apple, email: credential.email, name: name.isEmpty ? nil : name)
            Keychain.set(credential.user, for: Self.appleUserIDKey)
        case .failure(let error):
            appleNonce = nil
            if (error as? ASAuthorizationError)?.code == .canceled { throw AuthError.cancelled }
            throw AuthError.failed("Sign in with Apple didn’t finish. Try again?")
        }
    }

    // MARK: Google

    /// Google uses the standard OAuth flow in Apple's secure web sheet (ASWebAuthenticationSession
    /// with PKCE). It needs a client id in Info.plist (`GIDClientID`); without one it says so plainly.
    func signInWithGoogle() async throws {
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String,
              !clientID.trimmingCharacters(in: .whitespaces).isEmpty, !clientID.hasPrefix("$(") else {
            throw AuthError.notConfigured("Google")
        }
        await finishPendingDeletion()
        let signedIn = try await backend.signInWithGoogle(clientID: clientID, consents: consents)
        try await complete(signedIn, method: .google, email: nil, name: nil)
    }

    // MARK: Email

    /// Sends a one-tap sign-in link (no password to forget) with a 6-digit code for when the link
    /// opens somewhere else.
    func startEmail(_ email: String) async throws {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.contains("@"), trimmed.contains("."), trimmed.count >= 5, !trimmed.contains(" ") else {
            throw AuthError.invalidEmail
        }
        await finishPendingDeletion()
        let sent = try await backend.startEmail(trimmed)
        pendingEmail = trimmed
        emailSentAt = .now
        resendAfter = sent.resendAfter
    }

    func resendEmail() async throws {
        guard let pendingEmail else { return }
        try await startEmail(pendingEmail)
    }

    /// The code typed from the email.
    func finishEmail(code: String) async throws {
        guard pendingEmail != nil else { throw AuthError.linkExpired }
        let signedIn = try await backend.verifyEmail(.code(code), consents: consents)
        try await complete(signedIn, method: .email, email: pendingEmail, name: nil)
        clearEmail()
    }

    /// The link opened from the email. Local builds with no server also use this as "I've tapped the link".
    func finishEmailLink() async throws {
        let token = pendingLinkToken ?? ""
        pendingLinkToken = nil
        let signedIn = try await backend.verifyEmail(.link(token), consents: consents)
        try await complete(signedIn, method: .email, email: pendingEmail, name: nil)
        clearEmail()
    }

    /// Takes the universal link `https://focus.adhdslayer.au/auth/email#t=...`. False for any other URL.
    @discardableResult
    func receive(_ url: URL) -> Bool {
        guard let token = EmailLink.token(from: url) else { return false }
        pendingLinkToken = token
        return true
    }

    func useDifferentEmail() {
        backend.cancelEmail()
        clearEmail()
    }

    private func clearEmail() {
        pendingEmail = nil
        emailSentAt = nil
        pendingLinkToken = nil
    }

    // MARK: Leaving

    /// Signs out on the server, then keeps this iPhone's data (the default) or removes it.
    /// Keeping it means only this account can sign back in on this phone.
    func signOut(keepingData: Bool = true) async {
        account = nil
        sessionEnded = false
        Keychain.set(nil, for: Self.accountKey)
        Keychain.set(nil, for: Self.appleUserIDKey)
        await backend.signOut()
        if !keepingData { LocalData.removeThisPhonesData() }
    }

    /// Deletes the account on the server (which revokes the Apple token where used), then everything
    /// on this phone. Offline, this phone is cleared now and a `pendingDeletion` marker finishes the
    /// server part at a later launch. Irreversible, so the UI asks twice.
    func deleteAccount() async -> DeletionOutcome {
        // An account made before this build had a server lives only on this phone.
        if backend.usesServer, UserDefaults.standard.string(forKey: Self.dataOwnerKey) == nil, !(await backend.hasSession) {
            return apply(.done(completesBy: nil))
        }
        Keychain.set("1", for: Self.pendingDeletionKey)
        deletionPending = true
        return apply(await backend.deleteAccount(isRetry: false))
    }

    private func apply(_ result: DeletionResult) -> DeletionOutcome {
        switch result {
        case .done:
            LocalData.wipeEverything()
            account = nil
            sessionEnded = false
            deletionPending = false
            clearEmail()
            return .deleted
        case .retryLater:
            LocalData.wipeKeepingDeletionCredentials()
            account = nil
            sessionEnded = false
            clearEmail()
            return .pending
        case .needsSignIn:
            Keychain.set(nil, for: Self.pendingDeletionKey)
            deletionPending = false
            return .needsSignIn
        }
    }

    /// Retries a deletion that couldn't reach the server. Runs at launch and before any sign-in.
    private func finishPendingDeletion() async {
        guard deletionPending else { return }
        switch await backend.deleteAccount(isRetry: true) {
        case .retryLater: break
        case .done, .needsSignIn: _ = apply(.done(completesBy: nil))
        }
    }

    // MARK: Launch

    private func runLaunchChecks() async {
        guard backend.usesServer, !Self.launchChecksStarted else { return }
        Self.launchChecksStarted = true
        await finishPendingDeletion()
        guard let account else { return }
        guard await backend.hasSession else {
            // Ended while the app was closed, or made before this build had a server.
            sessionEnded = true
            return
        }
        // Sign in with Apple stopped in Settings, Apple ID: end the session here, keep every bit of data.
        if account.method == .apple, let userID = Keychain.get(Self.appleUserIDKey),
           let state = try? await ASAuthorizationAppleIDProvider().credentialState(forUserID: userID), state == .revoked {
            await backend.endSessionLocally()
            sessionEnded = true
        }
    }

    // MARK: Saving

    /// What onboarding recorded, sent with sign-up: the Terms, Privacy Policy and honest-bit versions,
    /// and when "I'm 18 or older" was switched on.
    private var consents: SignUpConsents {
        let defaults = UserDefaults.standard
        let notice = defaults.integer(forKey: "noticeAcceptedVersion")
        let confirmedAt = defaults.double(forKey: Self.adultConfirmedAtKey)
        return SignUpConsents(termsVersion: LegalVersion.terms, privacyVersion: LegalVersion.privacy,
                              noticeVersion: notice > 0 ? notice : MedicalNoticeView.version,
                              adultConfirmedAt: confirmedAt > 0 ? Date(timeIntervalSince1970: confirmedAt) : .now)
    }

    /// Keeps the signed-in account, unless this phone holds another account's data.
    private func complete(_ signedIn: SignedIn, method: Account.Method, email: String?, name: String?) async throws {
        if backend.usesServer {
            let owner = signedIn.accountID.uuidString.lowercased()
            if let current = UserDefaults.standard.string(forKey: Self.dataOwnerKey), current != owner {
                await backend.signOut()
                throw AuthError.otherAccountsData
            }
            UserDefaults.standard.set(owner, forKey: Self.dataOwnerKey)
        }
        let previous = account?.id == signedIn.accountID ? account : nil
        save(Account(id: signedIn.accountID, method: method, email: signedIn.email ?? email ?? previous?.email,
                     name: name ?? previous?.name, createdAt: previous?.createdAt ?? .now))
        sessionEnded = false
    }

    private func save(_ account: Account) {
        self.account = account
        if let data = try? JSONEncoder().encode(account) { Keychain.set(String(data: data, encoding: .utf8), for: Self.accountKey) }
    }

    private static func loadAccount() -> Account? {
        guard let data = Keychain.get(accountKey)?.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(Account.self, from: data)
    }
}

// MARK: - The server half

/// What every sign-up sends besides the provider credential (02-backend.md, Rules for every method).
struct SignUpConsents: Sendable, Equatable {
    var termsVersion: Int
    var privacyVersion: Int
    var noticeVersion: Int
    var adultConfirmedAt: Date
}

/// What Sign in with Apple hands the server: the identity token, the one-time code, the raw nonce
/// (whose SHA-256 went to Apple) and Apple's user id.
struct AppleCredential: Sendable {
    var identityToken: String
    var authorizationCode: String
    var rawNonce: String
    var userID: String
}

enum EmailProof: Sendable, Equatable {
    /// The `t` from the universal link.
    case link(String)
    /// The 6-digit code typed from the email.
    case code(String)
}

struct EmailLinkSent: Sendable {
    var resendAfter: TimeInterval
    var expiresIn: TimeInterval
}

struct SignedIn: Sendable {
    var accountID: UUID
    var email: String?
    var isNewAccount: Bool
}

enum DeletionResult: Sendable {
    case done(completesBy: Date?)
    case retryLater
    case needsSignIn
}

/// The server half of sign-in. `HTTPAuthBackend` talks to the Focus API (Model/Backend);
/// `LocalAuthBackend` runs with no server at all.
protocol AuthBackend: Sendable {
    /// False when nothing leaves the phone.
    var usesServer: Bool { get }
    var hasSession: Bool { get async }
    /// The address of a link still waiting on this phone (its verifier is in the Keychain).
    var pendingEmail: String? { get }
    func signInWithApple(_ credential: AppleCredential, consents: SignUpConsents) async throws -> SignedIn
    func signInWithGoogle(clientID: String, consents: SignUpConsents) async throws -> SignedIn
    func startEmail(_ email: String) async throws -> EmailLinkSent
    func verifyEmail(_ proof: EmailProof, consents: SignUpConsents) async throws -> SignedIn
    func cancelEmail()
    /// `POST /auth/logout`, then forgets the tokens here. Never fails.
    func signOut() async
    /// Forgets the tokens here without telling the server.
    func endSessionLocally() async
    /// `DELETE /account` with a device proof. `isRetry` when finishing an earlier attempt.
    func deleteAccount(isRetry: Bool) async -> DeletionResult
    func onSessionEnded(_ handler: @escaping @MainActor @Sendable () -> Void)
}

/// Runs without a server: makes a local account id and treats the email link or code as done.
struct LocalAuthBackend: AuthBackend {
    var usesServer: Bool { false }
    var hasSession: Bool { get async { false } }
    var pendingEmail: String? { nil }
    func signInWithApple(_ credential: AppleCredential, consents: SignUpConsents) async throws -> SignedIn { SignedIn(accountID: UUID(), isNewAccount: true) }
    func signInWithGoogle(clientID: String, consents: SignUpConsents) async throws -> SignedIn { SignedIn(accountID: UUID(), isNewAccount: true) }
    func startEmail(_ email: String) async throws -> EmailLinkSent { EmailLinkSent(resendAfter: 60, expiresIn: 900) }
    func verifyEmail(_ proof: EmailProof, consents: SignUpConsents) async throws -> SignedIn { SignedIn(accountID: UUID(), isNewAccount: true) }
    func cancelEmail() {}
    func signOut() async {}
    func endSessionLocally() async {}
    func deleteAccount(isRetry: Bool) async -> DeletionResult { .done(completesBy: nil) }
    func onSessionEnded(_ handler: @escaping @MainActor @Sendable () -> Void) {}
}
