import Foundation
import AuthenticationServices
import UIKit
import FocusSync

/// Sign-in, sign-out and deletion against the Focus API (02-backend.md, Accounts and sign-in).
/// The session it gets back is kept by FocusSync in the Keychain (this device only).
final class HTTPAuthBackend: AuthBackend {
    private let client: APIClient
    private let keychain: any SecureStore
    private let anchor = WebSignInAnchor()
    private var webSession: ASWebAuthenticationSession?

    /// The link verifier waits here (Keychain `linkVerifier`) until the link or code comes back.
    private struct PendingEmailLink: Codable {
        var email: String
        var verifier: String
        var requestedAt: Date
    }
    private static let pendingLinkKey = "linkVerifier"
    /// Links last 15 minutes; after an hour the verifier is no use to anyone.
    private static let pendingLinkLifetime: TimeInterval = 60 * 60

    init(client: APIClient, keychain: any SecureStore = KeychainStore.deviceItems) {
        self.client = client
        self.keychain = keychain
    }

    var usesServer: Bool { true }

    var hasSession: Bool {
        get async { await client.hasSession }
    }

    func onSessionEnded(_ handler: @escaping @MainActor @Sendable () -> Void) {
        let client = client
        Task {
            await client.setSessionEndedHandler { _ in
                Task { @MainActor in handler() }
            }
        }
    }

    // MARK: Apple

    func signInWithApple(_ credential: AppleCredential, consents: SignUpConsents) async throws -> SignedIn {
        try await mapped(.signIn) {
            SignedIn(try await client.signInWithApple(identityToken: credential.identityToken,
                                                      authorizationCode: credential.authorizationCode,
                                                      rawNonce: credential.rawNonce, appleUserId: credential.userID,
                                                      consents: consents.wire))
        }
    }

    // MARK: Google

    /// OpenID Connect code flow with PKCE in `ASWebAuthenticationSession`, sharing Safari's Google
    /// session so an account already signed in there can be picked. Only the ID token is kept.
    func signInWithGoogle(clientID: String, consents: SignUpConsents) async throws -> SignedIn {
        let request: GoogleSignInRequest
        do { request = try GoogleSignInRequest(clientID: clientID) } catch {
            throw AccountStore.AuthError.notConfigured("Google")
        }
        let callback = try await presentWebSignIn(url: request.authorizationURL, callbackScheme: request.callbackScheme)
        let code: String
        do {
            code = try request.authorizationCode(from: callback)
        } catch GoogleSignInError.cancelled {
            throw AccountStore.AuthError.cancelled
        } catch {
            throw AccountStore.AuthError.providerFailed
        }
        let idToken: String
        do {
            idToken = try await request.exchange(code: code, transport: URLSessionTransport.api())
        } catch is URLError {
            throw AccountStore.AuthError.offline
        } catch {
            throw AccountStore.AuthError.providerFailed
        }
        return try await mapped(.signIn) {
            SignedIn(try await client.signInWithGoogle(idToken: idToken, rawNonce: request.nonce.raw, consents: consents.wire))
        }
    }

    private func presentWebSignIn(url: URL, callbackScheme: String) async throws -> URL {
        defer { webSession = nil }
        do {
            return try await withCheckedThrowingContinuation { continuation in
                let session = ASWebAuthenticationSession(url: url, callback: .customScheme(callbackScheme)) { @Sendable callbackURL, error in
                    if let callbackURL {
                        continuation.resume(returning: callbackURL)
                    } else if (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin {
                        continuation.resume(throwing: WebSignInFailure.cancelled)
                    } else {
                        continuation.resume(throwing: WebSignInFailure.failed)
                    }
                }
                session.presentationContextProvider = anchor
                session.prefersEphemeralWebBrowserSession = false
                webSession = session
                if !session.start() { continuation.resume(throwing: WebSignInFailure.failed) }
            }
        } catch WebSignInFailure.cancelled {
            throw AccountStore.AuthError.cancelled
        } catch {
            throw AccountStore.AuthError.providerFailed
        }
    }

    // MARK: Email

    var pendingEmail: String? { loadPendingLink()?.email }

    func startEmail(_ email: String) async throws -> EmailLinkSent {
        let verifier = EmailLinkVerifier.make()
        let reply = try await mapped(.emailStart) {
            try await client.startEmailSignIn(email: email, linkChallenge: verifier.challenge)
        }
        // A newer link replaces older ones on the server, so only the newest verifier is kept.
        if let data = try? JSONEncoder().encode(PendingEmailLink(email: email, verifier: verifier.verifier, requestedAt: .now)) {
            try? keychain.set(data, for: Self.pendingLinkKey)
        }
        return EmailLinkSent(resendAfter: TimeInterval(reply.resendAfterSeconds), expiresIn: TimeInterval(reply.expiresInSeconds))
    }

    func verifyEmail(_ proof: EmailProof, consents: SignUpConsents) async throws -> SignedIn {
        guard let pending = loadPendingLink() else {
            // No verifier here: the link was asked for on another phone (or this one was reset).
            if case .link = proof { throw AccountStore.AuthError.wrongDevice }
            throw AccountStore.AuthError.linkExpired
        }
        let credential: EmailCredential
        let step: AuthStep
        switch proof {
        case .link(let token):
            if EmailLink.Token(token)?.isExpired() == true { throw AccountStore.AuthError.linkExpired }
            credential = .link(token: token)
            step = .emailLink
        case .code(let code):
            credential = .code(email: pending.email, code: code)
            step = .emailCode
        }
        let signedIn = try await mapped(step) {
            SignedIn(try await client.verifyEmailSignIn(credential, linkVerifier: pending.verifier, consents: consents.wire))
        }
        try? keychain.remove(Self.pendingLinkKey)
        return signedIn
    }

    func cancelEmail() {
        try? keychain.remove(Self.pendingLinkKey)
    }

    private func loadPendingLink() -> PendingEmailLink? {
        guard let data = try? keychain.data(for: Self.pendingLinkKey),
              let pending = try? JSONDecoder().decode(PendingEmailLink.self, from: data) else { return nil }
        guard Date.now.timeIntervalSince(pending.requestedAt) < Self.pendingLinkLifetime else {
            try? keychain.remove(Self.pendingLinkKey)
            return nil
        }
        return pending
    }

    // MARK: Leaving

    func signOut() async {
        await client.logout()
    }

    func endSessionLocally() async {
        await client.discardSession()
    }

    /// `DELETE /account` with a device proof. Offline or a server fault: try again next launch.
    /// On a retry, a session that has ended means the server already started deleting (it ends
    /// sessions at once), so that counts as done.
    func deleteAccount(isRetry: Bool) async -> DeletionResult {
        do {
            let deletion = try await client.deleteAccount()
            await client.discardSession()
            return .done(completesBy: deletion.completesBy)
        } catch let error as APIError {
            switch error {
            case .transport, .invalidResponse:
                return .retryLater
            case .notSignedIn:
                return isRetry ? .done(completesBy: nil) : .needsSignIn
            case .server(let server):
                switch server.code {
                case .accountDeletionPending, .notFound:
                    return .done(completesBy: server.details?["completesBy"]?.dateValue)
                case .sessionRevoked, .deviceRevoked, .unauthenticated, .tokenExpired:
                    return isRetry ? .done(completesBy: nil) : .needsSignIn
                default:
                    return .retryLater
                }
            }
        } catch {
            return .retryLater
        }
    }

    // MARK: Errors

    private func mapped<T>(_ step: AuthStep, _ body: () async throws -> T) async throws -> T {
        do {
            return try await body()
        } catch let error as APIError {
            throw AccountStore.AuthError(error, step: step)
        }
    }
}

/// Which sign-in step failed, so the same server code can read right (a wrong code isn't an expired link).
enum AuthStep {
    case signIn, emailStart, emailLink, emailCode
}

extension AccountStore.AuthError {
    /// The app's calm copy for each code in 02-backend.md "Error codes". The server's `message` is
    /// never shown.
    init(_ error: APIError, step: AuthStep) {
        switch error {
        case .transport:
            self = .offline
        case .notSignedIn, .invalidResponse:
            self = .failed("That didn’t work. Try again?")
        case .server(let server):
            switch server.code {
            case .providerTokenInvalid, .nonceMismatch: self = .providerFailed
            case .adultConfirmationRequired: self = .adultConfirmationNeeded
            case .linkInvalid: self = step == .emailCode ? .codeMismatch : .linkExpired
            case .validationError where step == .emailCode: self = .codeMismatch
            case .codeAttemptsExceeded: self = .tooManyCodes
            case .linkWrongDevice: self = .wrongDevice
            case .accountDeletionPending: self = .deletionPending(completesBy: server.details?["completesBy"]?.dateValue)
            // The spec has no code yet for "this email already has an account with another method";
            // a refused sign-in reads that way.
            case .forbidden: self = .emailInUse
            case .rateLimited: self = .rateLimited
            case .upgradeRequired: self = .updateNeeded
            case .upstreamUnavailable, .servicePaused, .internalError: self = .tryLater
            default: self = .failed("That didn’t work. Try again?")
            }
        }
    }
}

extension SignUpConsents {
    var wire: Consents {
        Consents(termsVersion: termsVersion, privacyVersion: privacyVersion, noticeVersion: noticeVersion, adultConfirmedAt: adultConfirmedAt)
    }
}

extension SignedIn {
    init(_ reply: SignInResponse) {
        self.init(accountID: reply.accountId, email: reply.identity?.email, isNewAccount: reply.isNewAccount)
    }
}

private nonisolated enum WebSignInFailure: Error {
    case cancelled, failed
}

/// Where the web sign-in sheet appears: the app's key window.
private final class WebSignInAnchor: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if let window = scenes.flatMap(\.windows).first(where: \.isKeyWindow) ?? scenes.first?.windows.first {
            return window
        }
        return ASPresentationAnchor()
    }
}
