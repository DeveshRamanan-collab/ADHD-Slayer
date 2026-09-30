import Foundation

public enum GoogleSignInError: Error, Sendable, Equatable {
    /// `GIDClientID` is missing or isn't an iOS client id.
    case invalidClientID
    /// The person closed the sheet or said no.
    case cancelled
    /// The callback's `state` isn't the one we sent.
    case stateMismatch
    case missingCode
    /// Google said no, with its error code (`invalid_grant`, for example).
    case provider(String)
    case tokenExchangeFailed(status: Int)
}

/// Google sign-in without the Google SDK: the OpenID Connect code flow with PKCE (S256), opened in
/// `ASWebAuthenticationSession` by the app (02-backend.md, Google).
///
/// 1. Make a request with `GoogleSignInRequest(clientID:)` and open `authorizationURL`, with
///    `callbackScheme` as the callback scheme and a shared (not ephemeral) browser session.
/// 2. Pass the callback URL to `authorizationCode(from:)`, which checks `state`.
/// 3. Send `tokenExchangeRequest(code:)` to Google (no client secret) and read the ID token with
///    `idToken(from:)`. Nothing else from Google is kept: no offline access, no refresh token.
/// 4. Send the ID token and `nonce.raw` to `POST /auth/google`.
public struct GoogleSignInRequest: Sendable, Equatable {
    public static let authorizationEndpoint = URL(string: "https://accounts.google.com/o/oauth2/v2/auth")!
    public static let tokenEndpoint = URL(string: "https://oauth2.googleapis.com/token")!

    public let clientID: String
    public let codeVerifier: String
    public let state: String
    public let nonce: SignInNonce

    public init(clientID: String) throws {
        try self.init(clientID: clientID, codeVerifier: PKCE.makeVerifier(),
                      state: Base64URL.encode(SecureRandom.bytes(16)), nonce: .make())
    }

    /// Fixed inputs, for tests.
    public init(clientID: String, codeVerifier: String, state: String, nonce: SignInNonce) throws {
        let trimmed = clientID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasSuffix(".apps.googleusercontent.com"), trimmed.count > ".apps.googleusercontent.com".count else {
            throw GoogleSignInError.invalidClientID
        }
        self.clientID = trimmed
        self.codeVerifier = codeVerifier
        self.state = state
        self.nonce = nonce
    }

    public var codeChallenge: String { PKCE.challenge(for: codeVerifier) }

    /// The reversed client id, `com.googleusercontent.apps.<id>`: the iOS client's redirect scheme.
    public var callbackScheme: String { clientID.split(separator: ".").reversed().joined(separator: ".") }

    public var redirectURI: String { callbackScheme + ":/oauth2redirect" }

    public var authorizationURL: URL {
        var components = URLComponents(url: Self.authorizationEndpoint, resolvingAgainstBaseURL: false)!
        components.percentEncodedQuery = FormEncoding.encode([
            ("client_id", clientID),
            ("redirect_uri", redirectURI),
            ("response_type", "code"),
            ("scope", "openid email"),
            ("state", state),
            ("nonce", nonce.hashed),
            ("code_challenge", codeChallenge),
            ("code_challenge_method", "S256"),
            ("prompt", "select_account"),
        ])
        return components.url!
    }

    /// Reads the code from the redirect, after checking it answers this request.
    public func authorizationCode(from callbackURL: URL) throws -> String {
        guard callbackURL.scheme?.lowercased() == callbackScheme.lowercased(),
              let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false) else {
            throw GoogleSignInError.missingCode
        }
        let items = components.queryItems ?? []
        func value(_ name: String) -> String? { items.first { $0.name == name }?.value }
        if let error = value("error") {
            throw error == "access_denied" ? GoogleSignInError.cancelled : GoogleSignInError.provider(error)
        }
        guard let returned = value("state"), Data(returned.utf8).constantTimeEquals(Data(state.utf8)) else {
            throw GoogleSignInError.stateMismatch
        }
        guard let code = value("code"), !code.isEmpty else { throw GoogleSignInError.missingCode }
        return code
    }

    /// `POST https://oauth2.googleapis.com/token` with the verifier and no client secret.
    public func tokenExchangeRequest(code: String) -> HTTPRequest {
        let body = FormEncoding.encode([
            ("code", code),
            ("client_id", clientID),
            ("redirect_uri", redirectURI),
            ("grant_type", "authorization_code"),
            ("code_verifier", codeVerifier),
        ])
        return HTTPRequest(method: "POST", url: Self.tokenEndpoint,
                           headers: ["Content-Type": "application/x-www-form-urlencoded", "Accept": "application/json"],
                           body: Data(body.utf8), timeout: 30)
    }

    /// Keeps only the ID token from Google's reply.
    public static func idToken(from response: HTTPResponse) throws -> String {
        struct Reply: Decodable {
            var id_token: String?
            var error: String?
        }
        let reply = try? JSONDecoder().decode(Reply.self, from: response.body)
        guard response.isSuccess else {
            if let error = reply?.error { throw GoogleSignInError.provider(error) }
            throw GoogleSignInError.tokenExchangeFailed(status: response.statusCode)
        }
        guard let token = reply?.id_token, !token.isEmpty else { throw GoogleSignInError.tokenExchangeFailed(status: response.statusCode) }
        return token
    }

    /// Steps 3 in one call.
    public func exchange(code: String, transport: any HTTPTransport) async throws -> String {
        try Self.idToken(from: try await transport.send(tokenExchangeRequest(code: code)))
    }
}

/// `application/x-www-form-urlencoded` and query strings, escaping everything outside RFC 3986's
/// unreserved set (so `+` and spaces are never ambiguous).
enum FormEncoding {
    static let unreserved: CharacterSet = {
        var set = CharacterSet()
        set.insert(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        return set
    }()

    static func escape(_ text: String) -> String {
        text.addingPercentEncoding(withAllowedCharacters: unreserved) ?? text
    }

    static func encode(_ pairs: [(String, String)]) -> String {
        pairs.map { escape($0.0) + "=" + escape($0.1) }.joined(separator: "&")
    }
}
