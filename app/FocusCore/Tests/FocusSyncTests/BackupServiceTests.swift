import Foundation
import Testing
@testable import FocusSync

@Suite("Backup, restore, key transfer and rotation against a fake server")
struct BackupServiceTests {
    let bundle = Data(#"{"meta":{"schema":1},"tasks":[{"id":"a","title":"Post the parcel"}]}"#.utf8)

    @Test func firstDeviceSetsUpKeysThenBacksUpAndRestores() async throws {
        let server = FakeFocusServer()
        let phone = try await FakePhone.make(server: server)

        #expect(try await phone.backup.keyStatus() == .notSetUp)
        let setup = try await phone.backup.setUpKeys(createRecoveryKey: true)
        #expect(setup.epoch == 1)
        #expect(setup.recoveryKey != nil)
        #expect(await server.epoch == 1)
        #expect(await server.slot(epoch: 1, device: phone.identity.deviceId) != nil)
        #expect(await server.recovery[1] != nil)
        #expect(try await phone.backup.keyStatus() == .ready(epoch: 1, rotationRequired: false))
        await #expect(throws: BackupError.alreadySetUp(epoch: 1)) { try await phone.backup.setUpKeys() }

        guard case .committed(let snapshotId, let version, _) = try await phone.backup.uploadSnapshot(bundle: bundle, schema: 1, baseVersion: 0) else {
            Issue.record("Expected a commit")
            return
        }
        #expect(version == 1)
        // The PUT went to the presigned URL with exactly the returned headers and no token.
        let put = try #require(await phone.transport.requests.first { $0.method == "PUT" && $0.url.host() == FakeFocusServer.objectHost })
        #expect(put.header("Authorization") == nil)
        #expect(Set(put.headers.keys) == ["Content-Type", "x-amz-checksum-sha256", "x-amz-server-side-encryption",
                                          "x-amz-server-side-encryption-aws-kms-key-id", "Content-Length", "User-Agent"])

        let restored = try #require(try await phone.backup.downloadNewestSnapshot(supportedSchema: 1))
        #expect(restored.snapshotId == snapshotId)
        #expect(restored.version == 1)
        #expect(restored.bundle == bundle)
        #expect(restored.deviceId == phone.identity.deviceId)
    }

    @Test func noBackupYetReadsAsNil() async throws {
        let server = FakeFocusServer()
        let phone = try await FakePhone.make(server: server)
        _ = try await phone.backup.setUpKeys(createRecoveryKey: false)
        #expect(try await phone.backup.downloadNewestSnapshot(supportedSchema: 1) == nil)
    }

    @Test func aSecondPhoneGetsAConflictAndMergesFirst() async throws {
        let server = FakeFocusServer()
        let first = try await FakePhone.make(server: server)
        _ = try await first.backup.setUpKeys()
        let second = try await FakePhone.make(server: server)
        // Give the second phone the key through a transfer.
        let offer = try await second.backup.offerKeyTransfer()
        #expect(try await first.backup.approveKeyTransfer(scannedPayload: offer.qrPayload) == .sealed)
        _ = try await second.backup.receiveKeyTransfer(offer)

        #expect(try await first.backup.uploadSnapshot(bundle: bundle, schema: 1, baseVersion: 0) != .conflict(currentVersion: 1))
        let outcome = try await second.backup.uploadSnapshot(bundle: Data(#"{"other":true}"#.utf8), schema: 1, baseVersion: 0)
        #expect(outcome == .conflict(currentVersion: 1))
        // After merging, it uploads on top of version 1.
        guard case .committed(_, let version, _) = try await second.backup.uploadSnapshot(bundle: bundle, schema: 1, baseVersion: 1) else {
            Issue.record("Expected a commit")
            return
        }
        #expect(version == 2)
    }

    @Test func keyTransferMovesTheKeyToANewPhone() async throws {
        let server = FakeFocusServer()
        let oldPhone = try await FakePhone.make(server: server)
        _ = try await oldPhone.backup.setUpKeys()
        _ = try await oldPhone.backup.uploadSnapshot(bundle: bundle, schema: 1, baseVersion: 0)

        let newPhone = try await FakePhone.make(server: server)
        #expect(try await newPhone.backup.keyStatus() == .locked(epoch: 1, hasRecoveryKey: true))
        let offer = try await newPhone.backup.offerKeyTransfer()
        #expect(offer.qrPayload.hasPrefix("focus-transfer:1:\(offer.transferId.uuidString.lowercased()):"))
        #expect(offer.code.fingerprint == KeyTransfer.fingerprint(of: newPhone.identity.agreementPublicKey))

        // The new phone starts waiting; the old phone approves a little later.
        async let received = newPhone.backup.receiveKeyTransfer(offer)
        try await Task.sleep(for: .milliseconds(20))
        #expect(try await oldPhone.backup.approveKeyTransfer(scannedPayload: offer.qrPayload) == .sealed)
        #expect(try await oldPhone.backup.approveKeyTransfer(scannedPayload: offer.qrPayload) == .alreadySealed)
        let ark = try await received

        #expect(ark.epoch == 1)
        // The new phone uploaded its own slot and can now read the backup.
        #expect(await server.slot(epoch: 1, device: newPhone.identity.deviceId) != nil)
        #expect(try await newPhone.backup.keyStatus() == .ready(epoch: 1, rotationRequired: false))
        #expect(try await newPhone.backup.downloadNewestSnapshot(supportedSchema: 1)?.bundle == bundle)
    }

    @Test func aSwappedKeyIsRefused() async throws {
        let server = FakeFocusServer()
        let oldPhone = try await FakePhone.make(server: server)
        _ = try await oldPhone.backup.setUpKeys()
        let newPhone = try await FakePhone.make(server: server)
        let offer = try await newPhone.backup.offerKeyTransfer()
        // A code whose fingerprint names a different key than the one the server holds.
        let forged = KeyTransfer.Code(transferId: offer.transferId, fingerprint: Data(repeating: 1, count: 16))
        await #expect(throws: BackupError.fingerprintMismatch) {
            try await oldPhone.backup.approveKeyTransfer(scannedPayload: forged.qrPayload)
        }
    }

    @Test func waitingStopsAfterTenMinutes() async throws {
        let server = FakeFocusServer()
        let owner = try await FakePhone.make(server: server)
        _ = try await owner.backup.setUpKeys()
        let clock = TestClock()
        let newPhone = try await FakePhone.make(server: server, clock: clock)
        let offer = try await newPhone.backup.offerKeyTransfer()
        let started = clock.now
        await #expect(throws: BackupError.transferExpired) {
            try await newPhone.backup.receiveKeyTransfer(KeyTransferOffer(transferId: offer.transferId,
                                                                           expiresAt: started.addingTimeInterval(600), code: offer.code))
        }
        let polls = await newPhone.transport.requests(path: "/v1/key-transfers/\(offer.transferId.uuidString.lowercased())").count
        #expect(clock.now.timeIntervalSince(started) >= 600)
        #expect((299...302).contains(polls), "polled \(polls) times")
    }

    @Test func recoveryKeyUnlocksANewPhone() async throws {
        let server = FakeFocusServer()
        let oldPhone = try await FakePhone.make(server: server)
        let setup = try await oldPhone.backup.setUpKeys(createRecoveryKey: true)
        _ = try await oldPhone.backup.uploadSnapshot(bundle: bundle, schema: 1, baseVersion: 0)
        let typed = try #require(setup.recoveryKey).formatted.lowercased().replacingOccurrences(of: "-", with: " ")

        let newPhone = try await FakePhone.make(server: server)
        let ark = try await newPhone.backup.unlock(withRecoveryKey: try RecoveryKey(parsing: typed))
        #expect(ark.epoch == 1)
        #expect(await server.slot(epoch: 1, device: newPhone.identity.deviceId) != nil)
        #expect(try await newPhone.backup.downloadNewestSnapshot(supportedSchema: 1)?.bundle == bundle)
    }

    @Test func iCloudKeychainCopyIsTriedFirst() async throws {
        let server = FakeFocusServer()
        let escrow = InMemorySecureStore()
        let oldPhone = try await FakePhone.make(server: server, escrow: escrow)
        _ = try await oldPhone.backup.setUpKeys()
        let newPhone = try await FakePhone.make(server: server, escrow: escrow)
        #expect(try await newPhone.backup.keyStatus() == .ready(epoch: 1, rotationRequired: false))
        #expect(await server.slot(epoch: 1, device: newPhone.identity.deviceId) != nil)
    }

    @Test func rotationSealsANewKeyForEveryRemainingDevice() async throws {
        let server = FakeFocusServer()
        let first = try await FakePhone.make(server: server)
        _ = try await first.backup.setUpKeys()
        let second = try await FakePhone.make(server: server)
        let offer = try await second.backup.offerKeyTransfer()
        _ = try await first.backup.approveKeyTransfer(scannedPayload: offer.qrPayload)
        _ = try await second.backup.receiveKeyTransfer(offer)
        _ = try await first.backup.uploadSnapshot(bundle: bundle, schema: 1, baseVersion: 0)

        let rotation = try await first.backup.rotateKeys(createRecoveryKey: true)
        #expect(rotation.epoch == 2)
        #expect(rotation.recoveryKey != nil)
        #expect(await server.epoch == 2)
        #expect(await server.slot(epoch: 2, device: first.identity.deviceId) != nil)
        #expect(await server.slot(epoch: 2, device: second.identity.deviceId) != nil)
        // The second phone picks up the new key from its slot, and the first commits a new-epoch snapshot.
        #expect(try await second.backup.keyStatus() == .ready(epoch: 2, rotationRequired: false))
        guard case .committed(_, let version, _) = try await first.backup.uploadSnapshot(bundle: bundle, schema: 1, baseVersion: 1) else {
            Issue.record("Expected a commit")
            return
        }
        #expect(version == 2)
        #expect(try await second.backup.downloadNewestSnapshot(supportedSchema: 1)?.epoch == 2)
    }

    @Test func anOldKeyIsReplacedAfterEpochMismatch() async throws {
        let server = FakeFocusServer()
        let first = try await FakePhone.make(server: server)
        _ = try await first.backup.setUpKeys()
        let second = try await FakePhone.make(server: server)
        let offer = try await second.backup.offerKeyTransfer()
        _ = try await first.backup.approveKeyTransfer(scannedPayload: offer.qrPayload)
        _ = try await second.backup.receiveKeyTransfer(offer)
        _ = try await first.backup.rotateKeys(createRecoveryKey: false)
        // The second phone still holds only epoch 1; the upload fetches epoch 2 and goes through.
        guard case .committed = try await second.backup.uploadSnapshot(bundle: bundle, schema: 1, baseVersion: 0) else {
            Issue.record("Expected a commit")
            return
        }
        #expect(await server.snapshots.values.contains { $0.epoch == 2 && $0.version == 1 })
    }

    @Test func aDroppedUploadIsSentOnceMore() async throws {
        let server = FakeFocusServer()
        let phone = try await FakePhone.make(server: server)
        _ = try await phone.backup.setUpKeys()
        await server.setDropNextObjectPut()
        guard case .committed(_, let version, _) = try await phone.backup.uploadSnapshot(bundle: bundle, schema: 1, baseVersion: 0) else {
            Issue.record("Expected a commit")
            return
        }
        #expect(version == 1)
        let puts = await phone.transport.requests.filter { $0.method == "PUT" && $0.url.host() == FakeFocusServer.objectHost }
        #expect(puts.count == 2)
    }

    @Test func newerSchemasAreNeverPartlyRead() async throws {
        let server = FakeFocusServer()
        let phone = try await FakePhone.make(server: server)
        _ = try await phone.backup.setUpKeys()
        _ = try await phone.backup.uploadSnapshot(bundle: bundle, schema: 2, baseVersion: 0)
        await #expect(throws: BackupError.schemaTooNew(2)) { try await phone.backup.downloadNewestSnapshot(supportedSchema: 1) }
        let downloads = await phone.transport.requests.filter { $0.method == "GET" && $0.url.host() == FakeFocusServer.objectHost }
        #expect(downloads.isEmpty)
    }

    @Test func rotationNeedsEveryDevicesAgreementKey() async throws {
        let transport = FakeTransport { request in
            switch request.url.path() {
            case "/v1/keys": return Fixture.json(200, ["epoch": 1])
            case "/v1/devices": return Fixture.json(200, ["devices": [["id": UUID().uuidString.lowercased(), "isCurrent": false]]])
            default: return HTTPResponse(statusCode: 500)
            }
        }
        let clock = TestClock()
        let client = try Fixture.client(transport: transport, session: Fixture.session(now: clock.now), clock: clock)
        let backup = BackupService(accountId: Fixture.accountId, client: client, keyRing: KeyRing(store: InMemorySecureStore()))
        await #expect(throws: BackupError.self) { try await backup.rotateKeys() }
        #expect(await transport.requests(path: "/v1/keys/epochs").isEmpty)
    }
}
