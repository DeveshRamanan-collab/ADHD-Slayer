import Foundation
import CryptoKit
@testable import FocusSync

/// An in-memory server for the key and backup routes, strict where the real one is: bearer tokens
/// map to devices, BP routes check the device proof, epochs and versions are enforced, and the fake
/// object store checks the S3 checksum header. It never sees a key it could open.
actor FakeFocusServer {
    struct Device {
        var signingKey: P256.Signing.PublicKey
        var agreementKey: String
        var revoked = false
    }

    struct Transfer {
        var requester: UUID
        var agreementKey: String
        var sealed: SealedSlot?
        var delivered = false
    }

    struct Snapshot {
        var id: UUID
        var baseVersion: Int
        var epoch: Int
        var schema: Int
        var sizeBytes: Int
        var sha256: String
        var deviceId: UUID
        var version: Int?
    }

    static let objectHost = "objects.test.focus"

    let accountId: UUID
    private(set) var devices: [UUID: Device] = [:]
    private var tokens: [String: UUID] = [:]
    private(set) var epoch = 0
    private(set) var slots: [Int: [UUID: SealedSlot]] = [:]
    private(set) var recovery: [Int: SealedRecoverySlot] = [:]
    private(set) var transfers: [UUID: Transfer] = [:]
    private(set) var snapshots: [UUID: Snapshot] = [:]
    private var objects: [UUID: Data] = [:]
    private(set) var version = 0
    private(set) var currentSnapshot: UUID?
    /// Test hooks.
    var dropNextObjectPut = false
    private(set) var proofChecks = 0

    init(accountId: UUID = Fixture.accountId) {
        self.accountId = accountId
    }

    /// Registers a device as if it had signed in, and returns its session.
    func signIn(_ identity: DeviceIdentity, now: Date) -> Session {
        devices[identity.deviceId] = Device(signingKey: identity.signingPublicKey, agreementKey: identity.agreementKey)
        let access = "access-\(identity.deviceId.uuidString.prefix(8))-\(tokens.count)"
        tokens[access] = identity.deviceId
        return Session(accessToken: access, accessExpiresAt: now.addingTimeInterval(3600),
                       refreshToken: "refresh-\(access)", refreshExpiresAt: now.addingTimeInterval(90 * 86_400))
    }

    func setDropNextObjectPut() { dropNextObjectPut = true }

    func slot(epoch: Int, device: UUID) -> SealedSlot? { slots[epoch]?[device] }

    // MARK: Routing

    func handle(_ request: HTTPRequest) -> HTTPResponse {
        if request.url.host() == Self.objectHost { return handleObject(request) }
        let path = request.url.path(percentEncoded: true)
        guard path.hasPrefix("/v1/") else { return Fixture.error(404, "NOT_FOUND") }
        let parts = path.dropFirst(4).split(separator: "/").map(String.init)
        guard let bearer = request.header("Authorization"), bearer.hasPrefix("Bearer "),
              let device = tokens[String(bearer.dropFirst(7))], devices[device]?.revoked == false else {
            return Fixture.error(401, "UNAUTHENTICATED")
        }
        let needsProof = parts.first == "keys" || parts.first == "key-transfers" || (request.method == "DELETE")
        if needsProof {
            proofChecks += 1
            guard let key = devices[device]?.signingKey, request.header("X-Device-Id") == device.uuidString.lowercased(),
                  let timestamp = request.header("X-Device-Timestamp"), let signature = request.header("X-Device-Signature"),
                  DeviceProof.isValid(ProofHeaders(deviceId: device.uuidString.lowercased(), timestamp: timestamp, signature: signature),
                                      method: request.method, pathWithQuery: request.pathWithQuery, body: request.body, publicKey: key)
            else { return Fixture.error(401, "DEVICE_PROOF_INVALID") }
        }
        let body = bodyObject(request)
        let id = parts.compactMap { UUID(uuidString: $0) }.first
        let route = request.method + " " + parts.map { UUID(uuidString: $0) == nil ? $0 : ":id" }.joined(separator: "/")
        switch route {
        case "GET keys": return getKeys(device)
        case "POST keys/epochs": return postEpoch(device, body)
        case "PUT keys/slots/:id": return putSlot(id, body)
        case "PUT keys/recovery": return putRecovery(body)
        case "GET keys/recovery":
            guard let slot = recovery[epoch] else { return Fixture.error(404, "NOT_FOUND") }
            return Fixture.json(200, ["epoch": slot.epoch, "nonce": slot.nonce, "ciphertext": slot.ciphertext])
        case "POST key-transfers": return postTransfer(device, body)
        case "GET key-transfers/:id": return getTransfer(device, id)
        case "PUT key-transfers/:id/sealed": return sealTransfer(id, body)
        case "GET devices": return getDevices(device)
        case "GET sync/state":
            var state: [String: Any] = ["version": version, "epoch": epoch, "rotationRequired": false]
            if let currentSnapshot { state["snapshotId"] = currentSnapshot.uuidString.lowercased() }
            return Fixture.json(200, state)
        case "POST sync/snapshots": return startSnapshot(device, body)
        case "POST sync/snapshots/:id/commit": return commit(id)
        case "GET sync/snapshots/:id": return getSnapshot(id)
        default: return Fixture.error(404, "NOT_FOUND")
        }
    }

    // MARK: Keys

    private func getKeys(_ device: UUID) -> HTTPResponse {
        var reply: [String: Any] = ["epoch": epoch, "rotationRequired": false]
        if let slot = slots[epoch]?[device] {
            reply["mySlot"] = ["epoch": slot.epoch, "enc": slot.enc, "ciphertext": slot.ciphertext]
        }
        reply["recovery"] = ["epoch": epoch, "exists": recovery[epoch] != nil]
        return Fixture.json(200, reply)
    }

    private func postEpoch(_ device: UUID, _ body: [String: Any]) -> HTTPResponse {
        guard let from = body["fromEpoch"] as? Int, let to = body["toEpoch"] as? Int, let rows = body["slots"] as? [[String: Any]] else {
            return Fixture.error(422, "VALIDATION_ERROR")
        }
        guard from == epoch else { return Fixture.error(409, "EPOCH_MISMATCH") }
        guard to == epoch + 1 else { return Fixture.error(422, "VALIDATION_ERROR") }
        var newSlots: [UUID: SealedSlot] = [:]
        for row in rows {
            guard let text = row["deviceId"] as? String, text == text.lowercased(), let id = UUID(uuidString: text),
                  let enc = row["enc"] as? String, let ciphertext = row["ciphertext"] as? String,
                  devices[id]?.revoked == false else { return Fixture.error(422, "VALIDATION_ERROR") }
            newSlots[id] = SealedSlot(epoch: to, enc: enc, ciphertext: ciphertext)
        }
        // First setup needs the caller's slot; a rotation needs one for every active device.
        let required = from == 0 ? [device] : devices.filter { !$0.value.revoked }.map(\.key)
        guard required.allSatisfy({ newSlots[$0] != nil }) else { return Fixture.error(422, "VALIDATION_ERROR") }
        if let row = body["recovery"] as? [String: Any], let nonce = row["nonce"] as? String, let ciphertext = row["ciphertext"] as? String {
            recovery[to] = SealedRecoverySlot(epoch: to, nonce: nonce, ciphertext: ciphertext)
        }
        slots[to] = newSlots
        epoch = to
        return Fixture.json(201, ["epoch": to])
    }

    private func putSlot(_ id: UUID?, _ body: [String: Any]) -> HTTPResponse {
        guard let id, devices[id] != nil else { return Fixture.error(404, "NOT_FOUND") }
        guard let slotEpoch = body["epoch"] as? Int, slotEpoch == epoch else { return Fixture.error(409, "EPOCH_MISMATCH") }
        guard let enc = body["enc"] as? String, let ciphertext = body["ciphertext"] as? String else { return Fixture.error(422, "VALIDATION_ERROR") }
        slots[epoch, default: [:]][id] = SealedSlot(epoch: epoch, enc: enc, ciphertext: ciphertext)
        return HTTPResponse(statusCode: 204)
    }

    private func putRecovery(_ body: [String: Any]) -> HTTPResponse {
        guard let slotEpoch = body["epoch"] as? Int, slotEpoch == epoch else { return Fixture.error(409, "EPOCH_MISMATCH") }
        guard let nonce = body["nonce"] as? String, let ciphertext = body["ciphertext"] as? String else { return Fixture.error(422, "VALIDATION_ERROR") }
        recovery[epoch] = SealedRecoverySlot(epoch: epoch, nonce: nonce, ciphertext: ciphertext)
        return HTTPResponse(statusCode: 204)
    }

    // MARK: Transfers

    private func postTransfer(_ device: UUID, _ body: [String: Any]) -> HTTPResponse {
        guard let key = body["agreementKey"] as? String else { return Fixture.error(422, "VALIDATION_ERROR") }
        let id = UUID()
        transfers[id] = Transfer(requester: device, agreementKey: key)
        return Fixture.json(201, ["transferId": id.uuidString.lowercased(),
                                  "expiresAt": FocusJSON.string(from: Date().addingTimeInterval(600))])
    }

    private func getTransfer(_ device: UUID, _ id: UUID?) -> HTTPResponse {
        guard let id, var transfer = transfers[id] else { return Fixture.error(404, "NOT_FOUND") }
        var reply: [String: Any] = ["requesterDeviceId": transfer.requester.uuidString.lowercased(), "agreementKey": transfer.agreementKey]
        switch (transfer.sealed, transfer.delivered) {
        case (nil, _): reply["state"] = "waiting"
        case (let sealed?, false) where device == transfer.requester:
            reply["state"] = "sealed"
            reply["sealed"] = ["epoch": sealed.epoch, "enc": sealed.enc, "ciphertext": sealed.ciphertext]
            transfer.delivered = true
            transfers[id] = transfer
        case (_, true): reply["state"] = "done"
        default: reply["state"] = "sealed"
        }
        return Fixture.json(200, reply)
    }

    private func sealTransfer(_ id: UUID?, _ body: [String: Any]) -> HTTPResponse {
        guard let id, var transfer = transfers[id] else { return Fixture.error(404, "NOT_FOUND") }
        guard transfer.sealed == nil else { return Fixture.error(409, "TRANSFER_ALREADY_SEALED") }
        guard let slotEpoch = body["epoch"] as? Int, slotEpoch == epoch else { return Fixture.error(409, "EPOCH_MISMATCH") }
        guard let enc = body["enc"] as? String, let ciphertext = body["ciphertext"] as? String else { return Fixture.error(422, "VALIDATION_ERROR") }
        transfer.sealed = SealedSlot(epoch: slotEpoch, enc: enc, ciphertext: ciphertext)
        transfers[id] = transfer
        return HTTPResponse(statusCode: 204)
    }

    private func getDevices(_ current: UUID) -> HTTPResponse {
        let rows: [[String: Any]] = devices.filter { !$0.value.revoked }.map { id, device in
            ["id": id.uuidString.lowercased(), "model": "iPhone17,1", "appVersion": "1.2", "isCurrent": id == current,
             "hasKeySlot": slots[epoch]?[id] != nil, "agreementKey": device.agreementKey]
        }
        return Fixture.json(200, ["devices": rows])
    }

    // MARK: Snapshots

    private func startSnapshot(_ device: UUID, _ body: [String: Any]) -> HTTPResponse {
        guard let idText = body["snapshotId"] as? String, idText == idText.lowercased(), let id = UUID(uuidString: idText),
              let baseVersion = body["baseVersion"] as? Int, let snapshotEpoch = body["epoch"] as? Int,
              let schema = body["schema"] as? Int, let size = body["sizeBytes"] as? Int, let sha = body["sha256"] as? String,
              let digest = Base64URL.decode(sha), digest.count == 32 else { return Fixture.error(422, "VALIDATION_ERROR") }
        guard snapshotEpoch == epoch else { return Fixture.error(409, "EPOCH_MISMATCH") }
        snapshots[id] = Snapshot(id: id, baseVersion: baseVersion, epoch: snapshotEpoch, schema: schema, sizeBytes: size,
                                 sha256: sha, deviceId: device)
        return Fixture.json(201, [
            "uploadUrl": "https://\(Self.objectHost)/upload/\(idText)?X-Amz-Signature=abc",
            "uploadHeaders": ["Content-Type": "application/octet-stream",
                              "x-amz-checksum-sha256": digest.base64EncodedString(),
                              "x-amz-server-side-encryption": "aws:kms",
                              "x-amz-server-side-encryption-aws-kms-key-id": "alias/focus-test-s3",
                              "Content-Length": String(size)],
            "expiresAt": FocusJSON.string(from: Date().addingTimeInterval(900)),
        ])
    }

    private func handleObject(_ request: HTTPRequest) -> HTTPResponse {
        let parts = request.url.path().split(separator: "/").map(String.init)
        guard parts.count == 2, let id = UUID(uuidString: parts[1]) else { return HTTPResponse(statusCode: 404) }
        guard request.header("Authorization") == nil, request.header("X-Device-Signature") == nil else {
            return HTTPResponse(statusCode: 400)
        }
        switch (request.method, parts[0]) {
        case ("PUT", "upload"):
            if dropNextObjectPut {
                dropNextObjectPut = false
                return HTTPResponse(statusCode: 200)
            }
            guard let body = request.body, let snapshot = snapshots[id],
                  request.header("Content-Type") == "application/octet-stream",
                  request.header("x-amz-server-side-encryption") == "aws:kms",
                  request.header("Content-Length") == String(body.count),
                  request.header("x-amz-checksum-sha256") == Data(SHA256.hash(data: body)).base64EncodedString(),
                  Base64URL.encode(Data(SHA256.hash(data: body))) == snapshot.sha256 else { return HTTPResponse(statusCode: 400) }
            objects[id] = body
            return HTTPResponse(statusCode: 200)
        case ("GET", "download"):
            guard let data = objects[id] else { return HTTPResponse(statusCode: 404) }
            return HTTPResponse(statusCode: 200, body: data)
        default:
            return HTTPResponse(statusCode: 405)
        }
    }

    private func commit(_ id: UUID?) -> HTTPResponse {
        guard let id, var snapshot = snapshots[id] else { return Fixture.error(404, "NOT_FOUND") }
        if let committed = snapshot.version { return Fixture.json(200, ["version": committed, "committedAt": FocusJSON.string(from: Date())]) }
        guard let data = objects[id] else { return Fixture.error(409, "UPLOAD_INCOMPLETE") }
        guard Base64URL.encode(Data(SHA256.hash(data: data))) == snapshot.sha256 else { return Fixture.error(422, "CHECKSUM_MISMATCH") }
        guard snapshot.epoch == epoch else { return Fixture.error(409, "EPOCH_MISMATCH") }
        guard snapshot.baseVersion == version else {
            return Fixture.error(409, "SNAPSHOT_CONFLICT", details: ["currentVersion": version])
        }
        version += 1
        snapshot.version = version
        snapshots[id] = snapshot
        currentSnapshot = id
        return Fixture.json(200, ["version": version, "committedAt": FocusJSON.string(from: Date())])
    }

    private func getSnapshot(_ id: UUID?) -> HTTPResponse {
        guard let id, let snapshot = snapshots[id], let committed = snapshot.version else { return Fixture.error(404, "NOT_FOUND") }
        return Fixture.json(200, ["downloadUrl": "https://\(Self.objectHost)/download/\(id.uuidString.lowercased())",
                                  "sizeBytes": snapshot.sizeBytes, "sha256": snapshot.sha256, "version": committed,
                                  "epoch": snapshot.epoch, "schema": snapshot.schema])
    }
}

/// One phone talking to a fake server.
struct FakePhone {
    let identity: DeviceIdentity
    let client: APIClient
    let backup: BackupService
    let keyStore: InMemorySecureStore
    let transport: FakeTransport

    static func make(server: FakeFocusServer, clock: TestClock = TestClock(), escrow: InMemorySecureStore? = nil) async throws -> FakePhone {
        let identity = Fixture.identity()
        let transport = FakeTransport { request in await server.handle(request) }
        let session = await server.signIn(identity, now: clock.now)
        let client = try Fixture.client(transport: transport, session: session, identity: identity, clock: clock)
        let keyStore = InMemorySecureStore()
        // Polling moves the virtual clock 2 seconds per wait, with a real millisecond so other tasks run.
        let backup = BackupService(accountId: server.accountId, client: client, keyRing: KeyRing(store: keyStore, escrow: escrow),
                                   now: clock.function, sleep: { _ in
                                       try await Task.sleep(for: .milliseconds(1))
                                       clock.advance(by: 2)
                                   })
        return FakePhone(identity: identity, client: client, backup: backup, keyStore: keyStore, transport: transport)
    }
}
