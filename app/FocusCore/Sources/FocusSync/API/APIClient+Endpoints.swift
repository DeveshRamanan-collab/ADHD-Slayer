import Foundation

// One method per endpoint in 02-backend.md "API". Auth column: N none, B bearer, P device proof,
// BP both. Methods marked "Later" exist so the reserved routes have one home.

extension APIClient {
    // MARK: - Sign-in, account and devices

    /// `POST /auth/apple` (N). Keeps the returned session.
    public func signInWithApple(identityToken: String, authorizationCode: String, rawNonce: String, appleUserId: String,
                                consents: Consents, idempotencyKey: String = APIClient.newIdempotencyKey()) async throws -> SignInResponse {
        struct Body: Encodable {
            var identityToken, authorizationCode, rawNonce, appleUserId: String
            var device: DeviceRegistration
            var consents: Consents
        }
        let body = Body(identityToken: identityToken, authorizationCode: authorizationCode, rawNonce: rawNonce,
                        appleUserId: appleUserId, device: try deviceRegistration(), consents: consents)
        return try await signIn(Endpoint(method: "POST", path: "/auth/apple", json: body, auth: .none, idempotencyKey: idempotencyKey))
    }

    /// `POST /auth/google` (N). Keeps the returned session.
    public func signInWithGoogle(idToken: String, rawNonce: String, consents: Consents,
                                 idempotencyKey: String = APIClient.newIdempotencyKey()) async throws -> SignInResponse {
        struct Body: Encodable {
            var idToken, rawNonce: String
            var device: DeviceRegistration
            var consents: Consents
        }
        let body = Body(idToken: idToken, rawNonce: rawNonce, device: try deviceRegistration(), consents: consents)
        return try await signIn(Endpoint(method: "POST", path: "/auth/google", json: body, auth: .none, idempotencyKey: idempotencyKey))
    }

    /// `POST /auth/email/start` (N). Always 202 with the same body, so addresses can't be probed.
    public func startEmailSignIn(email: String, linkChallenge: String,
                                 idempotencyKey: String = APIClient.newIdempotencyKey()) async throws -> EmailSignInStart {
        struct Body: Encodable { var email, deviceId, linkChallenge: String }
        let body = Body(email: email, deviceId: try deviceIdentity().deviceId.wire, linkChallenge: linkChallenge)
        let response = try await send(Endpoint(method: "POST", path: "/auth/email/start", json: body, auth: .none,
                                               idempotencyKey: idempotencyKey))
        return response.body.isEmpty ? EmailSignInStart() : try decode(EmailSignInStart.self, from: response)
    }

    /// `POST /auth/email/verify` (N) with the link's token, or the address and 6-digit code, plus the
    /// verifier this phone kept. Keeps the returned session.
    public func verifyEmailSignIn(_ credential: EmailCredential, linkVerifier: String, consents: Consents,
                                  idempotencyKey: String = APIClient.newIdempotencyKey()) async throws -> SignInResponse {
        struct Body: Encodable {
            var token: String?
            var email: String?
            var code: String?
            var linkVerifier: String
            var device: DeviceRegistration
            var consents: Consents
        }
        var body = Body(linkVerifier: linkVerifier, device: try deviceRegistration(), consents: consents)
        switch credential {
        case .link(let token): body.token = token
        case .code(let email, let code):
            body.email = email
            body.code = code
        }
        return try await signIn(Endpoint(method: "POST", path: "/auth/email/verify", json: body, auth: .none,
                                         idempotencyKey: idempotencyKey))
    }

    /// `POST /v1/_local/auth/session`: local development only (404 elsewhere). Makes an account and
    /// session for this device so the simulator can test without Apple, Google or email.
    public func localDevelopmentSession(consents: Consents) async throws -> SignInResponse {
        struct Body: Encodable {
            var device: DeviceRegistration
            var consents: Consents
        }
        return try await signIn(Endpoint(method: "POST", path: "/_local/auth/session",
                                         json: Body(device: try deviceRegistration(), consents: consents), auth: .none))
    }

    private func signIn(_ endpoint: Endpoint) async throws -> SignInResponse {
        let reply = try decode(SignInResponse.self, from: try await send(endpoint))
        try adopt(reply.session)
        return reply
    }

    /// `POST /auth/logout` (B), then forgets the tokens on this phone whatever the answer.
    /// Best effort and idempotent: an offline sign-out still signs out here.
    public func logout() async {
        guard let current = storedSession() else { return }
        var accessToken = current.accessToken
        if current.accessExpiresAt.timeIntervalSince(now()) < Self.refreshLeeway,
           let fresh = try? await refreshedSession(replacing: current.accessToken) {
            accessToken = fresh.accessToken
        }
        discardSession()
        let endpoint = Endpoint(method: "POST", path: "/auth/logout", auth: .bearer, timeout: 10)
        if let request = try? makeRequest(endpoint, accessToken: accessToken) {
            _ = try? await deliver(request)
        }
    }

    /// `GET /account` (B).
    public func account() async throws -> AccountInfo {
        try decode(AccountInfo.self, from: try await send(Endpoint(method: "GET", path: "/account", auth: .bearer)))
    }

    /// `PUT /account/consents/{kind}` (B).
    public func acceptConsent(_ kind: ConsentKind, version: Int, acceptedAt: Date) async throws {
        struct Body: Encodable {
            var version: Int
            var acceptedAt: Date
        }
        _ = try await send(Endpoint(method: "PUT", path: "/account/consents/\(Endpoint.segment(kind.rawValue))",
                                    json: Body(version: version, acceptedAt: acceptedAt), auth: .bearer))
    }

    /// `GET /account/export` (B): the raw JSON, which goes into the export ZIP as `account.json`.
    public func exportAccount() async throws -> Data {
        try await send(Endpoint(method: "GET", path: "/account/export", auth: .bearer)).body
    }

    /// `DELETE /account` (BP) with `{"confirm": "DELETE"}`. Repeats return the same `completesBy`.
    public func deleteAccount() async throws -> AccountDeletion {
        struct Body: Encodable { var confirm = "DELETE" }
        let response = try await send(Endpoint(method: "DELETE", path: "/account", json: Body(), auth: .bearerAndProof))
        return response.body.isEmpty ? AccountDeletion(status: .deleting, completesBy: nil) : try decode(AccountDeletion.self, from: response)
    }

    /// `GET /devices` (B).
    public func devices() async throws -> [DeviceSummary] {
        struct Reply: Decodable { var devices: [DeviceSummary] }
        return try decode(Reply.self, from: try await send(Endpoint(method: "GET", path: "/devices", auth: .bearer))).devices
    }

    /// `PUT /devices/current` (BP). Keys change only by signing in again.
    public func updateCurrentDevice(model: String = DeviceModel.identifier, osVersion: String? = nil, appVersion: String? = nil) async throws {
        struct Body: Encodable { var model, osVersion, appVersion: String }
        let body = Body(model: model, osVersion: osVersion ?? configuration.osVersion, appVersion: appVersion ?? configuration.appVersion)
        _ = try await send(Endpoint(method: "PUT", path: "/devices/current", json: body, auth: .bearerAndProof))
    }

    /// `DELETE /devices/{deviceId}` (BP). Ends its sessions and deletes its key slot; rotation is then required.
    public func removeDevice(_ deviceId: UUID, reason: DeviceRemovalReason) async throws {
        struct Body: Encodable { var reason: DeviceRemovalReason }
        _ = try await send(Endpoint(method: "DELETE", path: "/devices/\(deviceId.wire)", json: Body(reason: reason), auth: .bearerAndProof))
    }

    // MARK: - Keys

    /// `GET /keys` (BP).
    public func keys() async throws -> KeysState {
        try decode(KeysState.self, from: try await send(Endpoint(method: "GET", path: "/keys", auth: .bearerAndProof)))
    }

    /// `PUT /keys/slots/{deviceId}` (BP).
    public func putDeviceSlot(_ slot: SealedSlot, for deviceId: UUID) async throws {
        _ = try await send(Endpoint(method: "PUT", path: "/keys/slots/\(deviceId.wire)", json: slot, auth: .bearerAndProof))
    }

    /// `PUT /keys/recovery` (BP).
    public func putRecoverySlot(_ slot: SealedRecoverySlot) async throws {
        _ = try await send(Endpoint(method: "PUT", path: "/keys/recovery", json: slot, auth: .bearerAndProof))
    }

    /// `GET /keys/recovery` (BP). Ten a day, each read audited.
    public func recoverySlot() async throws -> SealedRecoverySlot {
        try decode(SealedRecoverySlot.self, from: try await send(Endpoint(method: "GET", path: "/keys/recovery", auth: .bearerAndProof)))
    }

    /// `POST /keys/epochs` (BP): slots for every remaining device in one atomic call. Returns the new epoch.
    public func createEpoch(_ change: EpochChange, idempotencyKey: String = APIClient.newIdempotencyKey()) async throws -> Int {
        struct Reply: Decodable { var epoch: Int }
        let response = try await send(Endpoint(method: "POST", path: "/keys/epochs", json: change, auth: .bearerAndProof,
                                               idempotencyKey: idempotencyKey))
        return try decode(Reply.self, from: response).epoch
    }

    /// `POST /key-transfers` (BP, new phone) with this phone's agreement key.
    public func createKeyTransfer(agreementKey: String, idempotencyKey: String = APIClient.newIdempotencyKey()) async throws -> KeyTransferTicket {
        struct Body: Encodable { var agreementKey: String }
        let response = try await send(Endpoint(method: "POST", path: "/key-transfers", json: Body(agreementKey: agreementKey),
                                               auth: .bearerAndProof, idempotencyKey: idempotencyKey))
        return try decode(KeyTransferTicket.self, from: response)
    }

    /// `GET /key-transfers/{id}` (BP).
    public func keyTransfer(_ transferId: UUID) async throws -> KeyTransferStatus {
        try decode(KeyTransferStatus.self, from: try await send(Endpoint(method: "GET", path: "/key-transfers/\(transferId.wire)",
                                                                         auth: .bearerAndProof)))
    }

    /// `PUT /key-transfers/{id}/sealed` (BP, the phone holding the current key).
    public func sealKeyTransfer(_ transferId: UUID, slot: SealedSlot) async throws {
        _ = try await send(Endpoint(method: "PUT", path: "/key-transfers/\(transferId.wire)/sealed", json: slot, auth: .bearerAndProof))
    }

    // MARK: - Sync

    /// `GET /sync/state` (B).
    public func syncState() async throws -> SyncState {
        try decode(SyncState.self, from: try await send(Endpoint(method: "GET", path: "/sync/state", auth: .bearer)))
    }

    /// `POST /sync/snapshots` (B). The same snapshot id gives a fresh URL, so a retry after an
    /// expired URL uses a new idempotency key.
    public func startSnapshot(_ start: SnapshotStart, idempotencyKey: String = APIClient.newIdempotencyKey()) async throws -> SnapshotUploadTicket {
        let response = try await send(Endpoint(method: "POST", path: "/sync/snapshots", json: start, auth: .bearer,
                                               idempotencyKey: idempotencyKey))
        return try decode(SnapshotUploadTicket.self, from: response)
    }

    /// `POST /sync/snapshots/{id}/commit` (B). A recommit returns the same version.
    public func commitSnapshot(_ snapshotId: UUID) async throws -> SnapshotCommit {
        try decode(SnapshotCommit.self, from: try await send(Endpoint(method: "POST", path: "/sync/snapshots/\(snapshotId.wire)/commit",
                                                                      auth: .bearer)))
    }

    /// `GET /sync/snapshots` (B).
    public func snapshots() async throws -> [SnapshotInfo] {
        struct Reply: Decodable { var snapshots: [SnapshotInfo] }
        return try decode(Reply.self, from: try await send(Endpoint(method: "GET", path: "/sync/snapshots", auth: .bearer))).snapshots
    }

    /// `GET /sync/snapshots/{id}` (B): a download URL good for 5 minutes.
    public func snapshot(_ snapshotId: UUID) async throws -> SnapshotDownload {
        try decode(SnapshotDownload.self, from: try await send(Endpoint(method: "GET", path: "/sync/snapshots/\(snapshotId.wire)",
                                                                        auth: .bearer)))
    }

    /// `DELETE /sync` (BP): "Delete my backup". Snapshots go; key slots stay.
    public func deleteBackup() async throws {
        _ = try await send(Endpoint(method: "DELETE", path: "/sync", auth: .bearerAndProof))
    }

    /// `POST /sync/batches` (B, Later).
    public func postSyncBatch(_ batch: SyncBatchUpload, idempotencyKey: String? = nil) async throws -> SyncBatchReceipt {
        let key = idempotencyKey ?? "\(batch.deviceId.wire).\(batch.seq)"
        let response = try await send(Endpoint(method: "POST", path: "/sync/batches", json: batch, auth: .bearer, idempotencyKey: key))
        return try decode(SyncBatchReceipt.self, from: response)
    }

    /// `GET /sync/batches?after=&limit=100` (B, Later).
    public func syncBatches(after cursor: String?, limit: Int = 100) async throws -> SyncBatchPage {
        var endpoint = Endpoint(method: "GET", path: "/sync/batches", auth: .bearer)
        endpoint.query = (cursor.map { [("after", $0)] } ?? []) + [("limit", String(limit))]
        return try decode(SyncBatchPage.self, from: try await send(endpoint))
    }

    // MARK: - Uploads and downloads on presigned URLs

    /// PUTs to a presigned URL with exactly the headers the server returned (plus `User-Agent`).
    /// Never sends a token or a device proof.
    public func uploadObject(to url: URL, headers: [String: String], body: Data) async throws {
        var sent = headers
        if !sent.keys.contains(where: { $0.caseInsensitiveCompare("User-Agent") == .orderedSame }) {
            sent["User-Agent"] = configuration.userAgent
        }
        let response = try await deliver(HTTPRequest(method: "PUT", url: url, headers: sent, body: body, timeout: 120))
        guard response.isSuccess else { throw APIError.server(ServerError(status: response.statusCode, code: .uploadIncomplete)) }
    }

    /// GETs a presigned download URL. Never sends a token or a device proof.
    public func downloadObject(from url: URL) async throws -> Data {
        let response = try await deliver(HTTPRequest(method: "GET", url: url, headers: ["User-Agent": configuration.userAgent], timeout: 120))
        guard response.isSuccess else { throw APIError.server(ServerError(status: response.statusCode, code: .notFound)) }
        return response.body
    }

    // MARK: - Subscriptions

    /// `GET /entitlements` (B).
    public func entitlement() async throws -> Entitlement {
        try decode(Entitlement.self, from: try await send(Endpoint(method: "GET", path: "/entitlements", auth: .bearer)))
    }

    /// `POST /entitlements/transactions` (B) with `Transaction.jwsRepresentation`. Idempotent by
    /// transaction id on the server; the default key is derived from the JWS so retries match.
    public func postTransaction(signedTransaction: String, idempotencyKey: String? = nil) async throws -> Entitlement {
        struct Body: Encodable { var signedTransaction: String }
        let key = idempotencyKey ?? Digest.sha256Hex(Data(signedTransaction.utf8))
        let response = try await send(Endpoint(method: "POST", path: "/entitlements/transactions",
                                               json: Body(signedTransaction: signedTransaction), auth: .bearer, idempotencyKey: key))
        return try decode(Entitlement.self, from: response)
    }

    // MARK: - Config and copy (through the CDN, no account or device id)

    /// `GET /config?appVersion=&build=&locale=&region=` (N). 5-second timeout. Pass the last ETag to get
    /// `.notModified` back. Verify the signature before using it.
    public func config(locale: String = Locale.current.identifier(.bcp47),
                       region: String = Locale.current.region?.identifier ?? "",
                       etag: String? = nil) async throws -> ConfigFetch {
        var endpoint = Endpoint(method: "GET", path: "/config",
                                query: [("appVersion", configuration.appVersion), ("build", configuration.build),
                                        ("locale", locale), ("region", region)],
                                auth: .none, host: .cdn, timeout: configuration.configTimeout)
        if let etag { endpoint.headers["If-None-Match"] = etag }
        let response = try await send(endpoint)
        if response.statusCode == 304 { return .notModified }
        return .document(Self.signedDocument(from: response))
    }

    /// `GET /copy/manifest` (N).
    public func copyManifest() async throws -> CopyManifest {
        try decode(CopyManifest.self, from: try await send(Endpoint(method: "GET", path: "/copy/manifest", auth: .none, host: .cdn)))
    }

    /// `GET /copy/decks/{version}` (N): signed and immutable.
    public func copyDeck(version: String) async throws -> SignedDocument {
        let response = try await send(Endpoint(method: "GET", path: "/copy/decks/\(Endpoint.segment(version))", auth: .none, host: .cdn))
        return Self.signedDocument(from: response)
    }

    static func signedDocument(from response: HTTPResponse) -> SignedDocument {
        SignedDocument(body: response.body, signature: response.header("Signature"),
                       keyId: response.header("Signature-Key-Id"), etag: response.header("ETag"))
    }

    // MARK: - Diagnostics, analytics, support

    /// Crash reports are capped at 256 KB (`payload` included).
    public static let maxCrashReportBytes = 256 * 1024

    /// `POST /diagnostics/crashes` (N, on the anonymous session, never a token or device id).
    public func submitCrashReport(_ report: CrashReport) async throws {
        let endpoint = try Endpoint(method: "POST", path: "/diagnostics/crashes", json: report, auth: .anonymous,
                                    idempotencyKey: report.reportId.wire)
        guard (endpoint.body?.count ?? 0) <= Self.maxCrashReportBytes else {
            throw APIError.server(ServerError(status: 413, code: .payloadTooLarge, message: "Crash report over 256 KB"))
        }
        _ = try await send(endpoint)
    }

    /// `POST /analytics/batches` (N, on the anonymous session).
    public func submitAnalyticsBatch(_ batch: AnalyticsBatch) async throws {
        _ = try await send(Endpoint(method: "POST", path: "/analytics/batches", json: batch, auth: .anonymous,
                                    idempotencyKey: batch.batchId.wire))
    }

    /// `POST /support/requests`: B when signed in, else N with `replyEmail`.
    public func submitSupportRequest(_ request: SupportRequest,
                                     idempotencyKey: String = APIClient.newIdempotencyKey()) async throws -> SupportReceipt {
        let signedIn = storedSession() != nil
        guard signedIn || !(request.replyEmail ?? "").isEmpty else {
            throw APIError.server(ServerError(status: 422, code: .validationError, message: "replyEmail is needed when signed out"))
        }
        let response = try await send(Endpoint(method: "POST", path: "/support/requests", json: request,
                                               auth: signedIn ? .bearer : .none, idempotencyKey: idempotencyKey))
        return try decode(SupportReceipt.self, from: response)
    }

    /// `POST /attest/challenge` (N, Later).
    public func attestChallenge() async throws -> AttestChallenge {
        try decode(AttestChallenge.self, from: try await send(Endpoint(method: "POST", path: "/attest/challenge", auth: .none,
                                                                       idempotencyKey: APIClient.newIdempotencyKey())))
    }

    /// `GET /healthz` (outside `/v1`).
    public func isHealthy() async -> Bool {
        (try? await send(Endpoint(method: "GET", path: "/healthz", auth: .none, host: .root, timeout: 5)))?.isSuccess ?? false
    }
}
