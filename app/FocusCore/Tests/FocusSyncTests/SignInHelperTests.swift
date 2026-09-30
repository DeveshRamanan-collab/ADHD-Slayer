import Foundation
import CryptoKit
import Testing
@testable import FocusSync

@Suite("Sign-in helpers: nonces, PKCE, Google, email links")
struct SignInHelperTests {
    @Test func appleNonceIsHashedToLowercaseHex() {
        let nonce = SignInNonce(raw: "kHf8Z0bH1-Q8dM9eA3nQvP0cY2uW5xR7tL4sJ6gE1aB")
        #expect(nonce.hashed == Hex.encode(SHA256.hash(data: Data(nonce.raw.utf8))))
        #expect(nonce.hashed.count == 64)
        #expect(nonce.hashed == nonce.hashed.lowercased())
        // A known value: SHA-256 of "abc".
        #expect(SignInNonce(raw: "abc").hashed == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")

        let made = SignInNonce.make()
        #expect(made.raw.count == 43)
        #expect(Base64URL.decode(made.raw)?.count == 32)
        #expect(made != SignInNonce.make())
    }

    @Test func pkceMatchesRFC7636AppendixB() {
        #expect(PKCE.challenge(for: "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk") == "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")
        let verifier = PKCE.makeVerifier()
        #expect(verifier.count == 43)
        #expect(verifier.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" })
    }

    @Test func googleAuthorizationURLCarriesPKCEStateAndHashedNonce() throws {
        let nonce = SignInNonce(raw: "raw-nonce")
        let request = try GoogleSignInRequest(clientID: "1234-abc.apps.googleusercontent.com",
                                              codeVerifier: "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk", state: "st4te", nonce: nonce)
        #expect(request.callbackScheme == "com.googleusercontent.apps.1234-abc")
        #expect(request.redirectURI == "com.googleusercontent.apps.1234-abc:/oauth2redirect")
        let components = try #require(URLComponents(url: request.authorizationURL, resolvingAgainstBaseURL: false))
        #expect(components.scheme == "https")
        #expect(components.host == "accounts.google.com")
        #expect(components.path == "/o/oauth2/v2/auth")
        let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        #expect(query == [
            "client_id": "1234-abc.apps.googleusercontent.com",
            "redirect_uri": "com.googleusercontent.apps.1234-abc:/oauth2redirect",
            "response_type": "code",
            "scope": "openid email",
            "state": "st4te",
            "nonce": nonce.hashed,
            "code_challenge": "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM",
            "code_challenge_method": "S256",
            "prompt": "select_account",
        ])
        #expect(request.authorizationURL.absoluteString.contains("scope=openid%20email"))
        #expect(!request.authorizationURL.absoluteString.contains("access_type=offline"))
    }

    @Test func googleCallbackChecksState() throws {
        let request = try GoogleSignInRequest(clientID: "1234-abc.apps.googleusercontent.com", codeVerifier: "v", state: "st4te",
                                              nonce: SignInNonce(raw: "n"))
        let good = URL(string: "com.googleusercontent.apps.1234-abc:/oauth2redirect?state=st4te&code=4%2F0Abc&scope=email%20openid")!
        #expect(try request.authorizationCode(from: good) == "4/0Abc")
        #expect(throws: GoogleSignInError.stateMismatch) {
            try request.authorizationCode(from: URL(string: "com.googleusercontent.apps.1234-abc:/oauth2redirect?state=other&code=x")!)
        }
        #expect(throws: GoogleSignInError.cancelled) {
            try request.authorizationCode(from: URL(string: "com.googleusercontent.apps.1234-abc:/oauth2redirect?error=access_denied&state=st4te")!)
        }
        #expect(throws: GoogleSignInError.invalidClientID) {
            try GoogleSignInRequest(clientID: "", codeVerifier: "v", state: "s", nonce: SignInNonce(raw: "n"))
        }
    }

    @Test func googleTokenExchangeIsAFormPostWithTheVerifierAndNoSecret() async throws {
        let request = try GoogleSignInRequest(clientID: "1234-abc.apps.googleusercontent.com", codeVerifier: "ver+/=", state: "s",
                                              nonce: SignInNonce(raw: "n"))
        let exchange = request.tokenExchangeRequest(code: "4/0Abc")
        #expect(exchange.method == "POST")
        #expect(exchange.url.absoluteString == "https://oauth2.googleapis.com/token")
        #expect(exchange.header("Content-Type") == "application/x-www-form-urlencoded")
        let form = String(data: try #require(exchange.body), encoding: .utf8)
        #expect(form == "code=4%2F0Abc&client_id=1234-abc.apps.googleusercontent.com&redirect_uri=com.googleusercontent.apps.1234-abc%3A%2Foauth2redirect&grant_type=authorization_code&code_verifier=ver%2B%2F%3D")
        #expect(form?.contains("client_secret") == false)

        let transport = FakeTransport { _ in Fixture.json(200, ["id_token": "eyJ.id.token", "access_token": "ya29", "expires_in": 3599]) }
        #expect(try await request.exchange(code: "4/0Abc", transport: transport) == "eyJ.id.token")
        #expect(throws: GoogleSignInError.provider("invalid_grant")) {
            try GoogleSignInRequest.idToken(from: Fixture.json(400, ["error": "invalid_grant"]))
        }
    }

    @Test func emailLinkChallengeIsS256OfTheVerifier() {
        let verifier = EmailLinkVerifier(verifier: "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk")
        #expect(verifier.challenge == "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")
        let made = EmailLinkVerifier.make()
        #expect(Base64URL.decode(made.verifier)?.count == 32)
        #expect(made.challenge == Base64URL.encode(SHA256.hash(data: Data(made.verifier.utf8))))
    }

    @Test func universalLinkFragmentIsRead() {
        #expect(EmailLink.token(from: URL(string: "https://focus.adhdslayer.au/auth/email#t=abc_DEF-123")!) == "abc_DEF-123")
        #expect(EmailLink.token(from: URL(string: "https://focus.adhdslayer.au/auth/email/#x=1&t=abc")!) == "abc")
        #expect(EmailLink.token(from: URL(string: "https://staging.focus.adhdslayer.au/auth/email#t=abc")!) == "abc")
        #expect(EmailLink.token(from: URL(string: "http://localhost:8081/auth/email#t=abc")!) == "abc")
        #expect(EmailLink.token(from: URL(string: "https://focus.adhdslayer.au/auth/email?t=abc")!) == nil)
        #expect(EmailLink.token(from: URL(string: "https://focus.adhdslayer.au/privacy#t=abc")!) == nil)
        #expect(EmailLink.token(from: URL(string: "https://evil.example/auth/email#t=abc")!) == nil)
        #expect(EmailLink.token(from: URL(string: "https://focus.adhdslayer.au/auth/email#t=")!) == nil)
    }

    @Test func linkTokenShowsItsIdAndExpiry() throws {
        var bytes = Data(UUID(uuidString: "0199A1B2-C3D4-7E5F-8A9B-0C1D2E3F4A5B")!.uuidBytes)
        let expiry: UInt64 = 1_790_000_900_000
        bytes.append(contentsOf: (0..<8).reversed().map { UInt8(expiry >> (UInt64($0) * 8) & 0xFF) })
        bytes.append(Data(repeating: 7, count: 64))
        let token = try #require(EmailLink.Token(Base64URL.encode(bytes)))
        #expect(token.id == UUID(uuidString: "0199A1B2-C3D4-7E5F-8A9B-0C1D2E3F4A5B"))
        #expect(token.expiresAt == Date(timeIntervalSince1970: 1_790_000_900))
        #expect(token.isExpired(now: Date(timeIntervalSince1970: 1_790_000_901)))
        #expect(!token.isExpired(now: Date(timeIntervalSince1970: 1_790_000_000)))
        #expect(EmailLink.Token(Base64URL.encode(bytes.prefix(87))) == nil)
    }
}

extension UUID {
    var uuidBytes: [UInt8] {
        withUnsafeBytes(of: uuid) { Array($0) }
    }
}
