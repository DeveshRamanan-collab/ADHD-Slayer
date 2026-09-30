import Foundation
import CryptoKit

public enum BackupError: Error, Sendable, Equatable {
    /// `setUpKeys` on an account that already has a key.
    case alreadySetUp(epoch: Int)
    /// This phone doesn't hold the key for `epoch`: use the iCloud copy, the old phone or the recovery key.
    case keyNotAvailable(epoch: Int)
    /// A backup written by a newer Focus. Nothing is read: "Update Focus to bring your data over."
    case schemaTooNew(Int)
    case snapshotTooLarge(bytes: Int)
    /// The downloaded bytes don't match the server's hash.
    case checksumMismatch
    /// The snapshot's header doesn't match what the server said about it.
    case snapshotMismatch
    case transferExpired
    /// The key the server handed over isn't the one in the QR code. Stop: someone may be in the middle.
    case fingerprintMismatch
    /// A device has no agreement key in `GET /devices`, so its slot can't be sealed.
    case missingAgreementKey(UUID)
    case unexpected(String)
}

public enum KeyStatus: Sendable, Equatable {
    /// No key yet: this is the first device, so call `setUpKeys`.
    case notSetUp
    /// This phone holds the current key.
    case ready(epoch: Int, rotationRequired: Bool)
    /// A key exists but this phone doesn't have it: move it from the old phone or type the recovery key.
    case locked(epoch: Int, hasRecoveryKey: Bool)
}

public struct KeySetup: Sendable, Equatable {
    public let epoch: Int
    /// Show once with Copy and "Save as PDF to Files". Never stored.
    public let recoveryKey: RecoveryKey?
}

public struct KeyRecipient: Sendable {
    public let deviceId: UUID
    public let agreementKey: P256.KeyAgreement.PublicKey

    public init(deviceId: UUID, agreementKey: P256.KeyAgreement.PublicKey) {
        self.deviceId = deviceId
        self.agreementKey = agreementKey
    }
}

/// What the new phone shows while it waits for its old phone.
public struct KeyTransferOffer: Sendable, Equatable {
    public let transferId: UUID
    public let expiresAt: Date
    public let code: KeyTransfer.Code

    /// Put this in the QR code.
    public var qrPayload: String { code.qrPayload }
    /// Show this under the QR code, for comparing by eye.
    public var displayFingerprint: String { code.displayFingerprint }
}

public enum KeyTransferApproval: Sendable, Equatable {
    case sealed
    /// Another tap already sealed it; nothing to do.
    case alreadySealed
}

public enum SnapshotUploadOutcome: Sendable, Equatable {
    case committed(snapshotId: UUID, version: Int, committedAt: Date?)
    /// Another device committed first. Download, merge, and upload again with `currentVersion` as the base.
    case conflict(currentVersion: Int?)
}

/// A sealed snapshot with its presigned URL, for apps that PUT from a background `URLSession`.
public struct PreparedSnapshotUpload: Sendable, Equatable {
    public let snapshotId: UUID
    public let baseVersion: Int
    public let epoch: Int
    public let schema: Int
    public let sealed: SnapshotContainer.Sealed
    public let ticket: SnapshotUploadTicket

    /// The PUT to send: the presigned URL with exactly the returned headers.
    public var uploadRequest: HTTPRequest {
        HTTPRequest(method: "PUT", url: ticket.uploadUrl, headers: ticket.uploadHeaders, body: sealed.data)
    }
}

public struct RestoredSnapshot: Sendable, Equatable {
    public let snapshotId: UUID
    public let version: Int
    public let schema: Int
    public let epoch: Int
    public let createdAt: Date
    public let deviceId: UUID
    /// The sync bundle JSON. Validate every record and import into an empty store in one transaction.
    public let bundle: Data
}

/// Encrypted backup and moving phones (02-backend.md, Encrypted backup and moving phones).
/// The sync bundle comes in and goes out as JSON `Data`; building and merging it is the app's job.
public actor BackupService {
    public let accountId: UUID
    private let client: APIClient
    private let keyRing: KeyRing
    private let now: @Sendable () -> Date
    private let sleep: @Sendable (Duration) async throws -> Void

    public init(accountId: UUID, client: APIClient, keyRing: KeyRing,
                now: @escaping @Sendable () -> Date = { Date() },
                sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }) {
        self.accountId = accountId
        self.client = client
        self.keyRing = keyRing
        self.now = now
        self.sleep = sleep
    }

    // MARK: - Keys

    /// Where this phone stands. Opens this phone's slot or the iCloud Keychain copy when it can.
    public func keyStatus() async throws -> KeyStatus {
        let state = try await fetchKeys()
        guard state.epoch > 0 else { return .notSetUp }
        if try await currentKey(for: state) != nil {
            return .ready(epoch: state.epoch, rotationRequired: state.rotationRequired)
        }
        let hasRecovery = state.recovery.map { $0.exists && $0.epoch == state.epoch } ?? false
        return .locked(epoch: state.epoch, hasRecoveryKey: hasRecovery)
    }

    /// The first device: a new ARK at epoch 1, sealed to this phone, and optionally a recovery slot,
    /// in one `POST /keys/epochs` from epoch 0.
    public func setUpKeys(createRecoveryKey: Bool = true) async throws -> KeySetup {
        let state = try await fetchKeys()
        guard state.epoch == 0 else { throw BackupError.alreadySetUp(epoch: state.epoch) }
        let identity = try await client.deviceIdentity()
        let ark = AccountRootKey.generate(epoch: 1)
        let slot = try DeviceSlot.seal(ark, to: identity.agreementPublicKey, accountId: accountId)
        let recoveryKey = createRecoveryKey ? RecoveryKey.generate() : nil
        let recovery = try recoveryKey.map { try RecoverySlot.seal(ark, with: $0, accountId: accountId) }
        let epoch = try await client.createEpoch(EpochChange(fromEpoch: 0, toEpoch: 1,
                                                             slots: [DeviceSlotUpload(deviceId: identity.deviceId, slot: slot)],
                                                             recovery: recovery))
        guard epoch == ark.epoch else { throw BackupError.unexpected("Server made epoch \(epoch), expected \(ark.epoch).") }
        try keyRing.save(ark, accountId: accountId)
        return KeySetup(epoch: epoch, recoveryKey: recoveryKey)
    }

    /// Opens the key with the recovery key the person typed, then gives this phone its own slot.
    public func unlock(withRecoveryKey recoveryKey: RecoveryKey) async throws -> AccountRootKey {
        let slot = try await client.recoverySlot()
        let ark = try RecoverySlot.open(slot, with: recoveryKey, accountId: accountId)
        try keyRing.save(ark, accountId: accountId)
        try await uploadOwnSlot(for: ark)
        return ark
    }

    /// Replaces the recovery slot for the current epoch. Show the new key once.
    public func createRecoveryKey() async throws -> RecoveryKey {
        let state = try await fetchKeys()
        guard let ark = try await currentKey(for: state) else { throw BackupError.keyNotAvailable(epoch: state.epoch) }
        let recoveryKey = RecoveryKey.generate()
        try await client.putRecoverySlot(try RecoverySlot.seal(ark, with: recoveryKey, accountId: accountId))
        return recoveryKey
    }

    /// Seals `ark` to this phone and uploads it as this phone's slot.
    public func uploadOwnSlot(for ark: AccountRootKey) async throws {
        let identity = try await client.deviceIdentity()
        let slot = try DeviceSlot.seal(ark, to: identity.agreementPublicKey, accountId: accountId)
        try await client.putDeviceSlot(slot, for: identity.deviceId)
    }

    // MARK: - Key transfer: the new phone

    /// Registers this phone's agreement key for a transfer. Show `qrPayload` as a QR code.
    public func offerKeyTransfer() async throws -> KeyTransferOffer {
        let identity = try await client.deviceIdentity()
        let ticket = try await client.createKeyTransfer(agreementKey: identity.agreementKey)
        let code = KeyTransfer.Code(transferId: ticket.transferId, fingerprint: KeyTransfer.fingerprint(of: identity.agreementPublicKey))
        return KeyTransferOffer(transferId: ticket.transferId, expiresAt: ticket.expiresAt, code: code)
    }

    /// Polls every 2 seconds for up to 10 minutes until the old phone has sealed the key, opens it,
    /// keeps it, and uploads this phone's own slot. A dropped poll doesn't end the wait.
    public func receiveKeyTransfer(_ offer: KeyTransferOffer, pollEvery interval: Duration = .seconds(2),
                                   timeout: TimeInterval = 600) async throws -> AccountRootKey {
        let deadline = min(now().addingTimeInterval(timeout), offer.expiresAt.addingTimeInterval(5))
        let identity = try await client.deviceIdentity()
        while true {
            try Task.checkCancellation()
            do {
                let status = try await client.keyTransfer(offer.transferId)
                if let sealed = status.sealed {
                    let ark = try identity.openSlot(sealed, accountId: accountId)
                    try keyRing.save(ark, accountId: accountId)
                    try await uploadOwnSlot(for: ark)
                    return ark
                }
                if status.state == .expired { throw BackupError.transferExpired }
            } catch let error as APIError {
                if error.code == .transferExpired { throw BackupError.transferExpired }
                if !RetryPolicy.isRetryable(error) { throw error }
            }
            guard now() < deadline else { throw BackupError.transferExpired }
            try await sleep(interval)
        }
    }

    // MARK: - Key transfer: the old phone

    /// After scanning the new phone's QR code: fetch its key, check the fingerprint, seal the current
    /// key to it with HPKE and upload it.
    public func approveKeyTransfer(scannedPayload: String) async throws -> KeyTransferApproval {
        let code = try KeyTransfer.parse(scannedPayload)
        let status: KeyTransferStatus
        do {
            status = try await client.keyTransfer(code.transferId)
        } catch let error as APIError where error.code == .transferExpired {
            throw BackupError.transferExpired
        }
        switch status.state {
        case .sealed, .done: return .alreadySealed
        case .expired: throw BackupError.transferExpired
        case .waiting, .unknown: break
        }
        guard let keyText = status.agreementKey else { throw BackupError.unexpected("The transfer has no key.") }
        let requesterKey = try DeviceSlot.publicKey(fromBase64URL: keyText)
        guard KeyTransfer.matches(requesterKey, code: code) else { throw BackupError.fingerprintMismatch }

        for attempt in 1...2 {
            let state = try await fetchKeys()
            guard let ark = try await currentKey(for: state) else { throw BackupError.keyNotAvailable(epoch: state.epoch) }
            let slot = try DeviceSlot.seal(ark, to: requesterKey, accountId: accountId)
            do {
                try await client.sealKeyTransfer(code.transferId, slot: slot)
                return .sealed
            } catch let error as APIError {
                switch error.code {
                case .transferAlreadySealed: return .alreadySealed
                case .transferExpired: throw BackupError.transferExpired
                case .epochMismatch where attempt == 1: continue
                default: throw error
                }
            }
        }
        throw BackupError.unexpected("The key changed twice while sealing.")
    }

    // MARK: - Rotation

    /// After removing a device, a suspected leak, or on request: a new ARK sealed to every remaining
    /// device in one call. Then commit a new-epoch snapshot and ask the person to save the new recovery
    /// key. `recipients` defaults to `GET /devices` (which must carry each device's `agreementKey`).
    public func rotateKeys(createRecoveryKey: Bool = true, recipients: [KeyRecipient]? = nil) async throws -> KeySetup {
        let state = try await fetchKeys()
        let identity = try await client.deviceIdentity()
        var targets: [KeyRecipient]
        if let recipients {
            targets = recipients
        } else {
            targets = try await deviceRecipients(currentDevice: identity.deviceId)
        }
        targets.removeAll { $0.deviceId == identity.deviceId }
        targets.insert(KeyRecipient(deviceId: identity.deviceId, agreementKey: identity.agreementPublicKey), at: 0)

        let ark = AccountRootKey.generate(epoch: state.epoch + 1)
        let slots = try targets.map { DeviceSlotUpload(deviceId: $0.deviceId, slot: try DeviceSlot.seal(ark, to: $0.agreementKey, accountId: accountId)) }
        let recoveryKey = createRecoveryKey ? RecoveryKey.generate() : nil
        let recovery = try recoveryKey.map { try RecoverySlot.seal(ark, with: $0, accountId: accountId) }
        let epoch = try await client.createEpoch(EpochChange(fromEpoch: state.epoch, toEpoch: ark.epoch, slots: slots, recovery: recovery))
        guard epoch == ark.epoch else { throw BackupError.unexpected("Server made epoch \(epoch), expected \(ark.epoch).") }
        try keyRing.save(ark, accountId: accountId)
        return KeySetup(epoch: epoch, recoveryKey: recoveryKey)
    }

    // MARK: - Snapshots

    /// Seals and uploads the bundle: start, PUT with exactly the returned headers, commit.
    /// `baseVersion` is the version this bundle was built on (0 before the first commit).
    public func uploadSnapshot(bundle: Data, schema: Int, baseVersion: Int) async throws -> SnapshotUploadOutcome {
        let prepared = try await prepareUpload(bundle: bundle, schema: schema, baseVersion: baseVersion)
        try await client.uploadObject(to: prepared.ticket.uploadUrl, headers: prepared.ticket.uploadHeaders, body: prepared.sealed.data)
        return try await commit(prepared)
    }

    /// Seals the bundle with the current key and asks for an upload URL. After `EPOCH_MISMATCH` it
    /// fetches the new key and tries once more.
    public func prepareUpload(bundle: Data, schema: Int, baseVersion: Int) async throws -> PreparedSnapshotUpload {
        let identity = try await client.deviceIdentity()
        var ark: AccountRootKey
        if let held = keyRing.latest(accountId: accountId) {
            ark = held
        } else {
            let state = try await fetchKeys()
            guard let current = try await currentKey(for: state) else { throw BackupError.keyNotAvailable(epoch: state.epoch) }
            ark = current
        }
        var keysChecked = false
        while true {
            let snapshotId = UUID()
            let sealed = try SnapshotContainer.seal(bundle: bundle, with: ark, accountId: accountId, snapshotId: snapshotId,
                                                    deviceId: identity.deviceId, schema: schema, createdAt: now())
            guard sealed.data.count <= FocusSync.maxSnapshotBytes else { throw BackupError.snapshotTooLarge(bytes: sealed.data.count) }
            let start = SnapshotStart(snapshotId: snapshotId, baseVersion: baseVersion, epoch: ark.epoch, schema: schema,
                                      sizeBytes: sealed.data.count, sha256: sealed.sha256Base64URL)
            do {
                let ticket = try await client.startSnapshot(start)
                try checkChecksumHeader(ticket, sealed: sealed)
                return PreparedSnapshotUpload(snapshotId: snapshotId, baseVersion: baseVersion, epoch: ark.epoch, schema: schema,
                                              sealed: sealed, ticket: ticket)
            } catch let error as APIError where error.code == .epochMismatch && !keysChecked {
                keysChecked = true
                let state = try await fetchKeys()
                guard let current = try await currentKey(for: state) else { throw BackupError.keyNotAvailable(epoch: state.epoch) }
                ark = current
            }
        }
    }

    /// Commits an uploaded snapshot. After `UPLOAD_INCOMPLETE` or `CHECKSUM_MISMATCH` it uploads once
    /// more on a fresh URL. `SNAPSHOT_CONFLICT` comes back as `.conflict` for the caller to merge.
    public func commit(_ prepared: PreparedSnapshotUpload) async throws -> SnapshotUploadOutcome {
        var reuploaded = false
        while true {
            do {
                let commit = try await client.commitSnapshot(prepared.snapshotId)
                return .committed(snapshotId: prepared.snapshotId, version: commit.version, committedAt: commit.committedAt)
            } catch let error as APIError {
                if error.code == .snapshotConflict {
                    return .conflict(currentVersion: error.serverError?.details?["currentVersion"]?.intValue)
                }
                guard !reuploaded, error.code == .uploadIncomplete || error.code == .checksumMismatch else { throw error }
                reuploaded = true
                let start = SnapshotStart(snapshotId: prepared.snapshotId, baseVersion: prepared.baseVersion, epoch: prepared.epoch,
                                          schema: prepared.schema, sizeBytes: prepared.sealed.data.count,
                                          sha256: prepared.sealed.sha256Base64URL)
                let ticket = try await client.startSnapshot(start)
                try checkChecksumHeader(ticket, sealed: prepared.sealed)
                try await client.uploadObject(to: ticket.uploadUrl, headers: ticket.uploadHeaders, body: prepared.sealed.data)
            }
        }
    }

    /// The newest committed snapshot, opened. Nil when there's no backup yet.
    public func downloadNewestSnapshot(supportedSchema: Int) async throws -> RestoredSnapshot? {
        let state = try await client.syncState()
        guard state.version > 0, let snapshotId = state.snapshotId else { return nil }
        return try await downloadSnapshot(snapshotId, supportedSchema: supportedSchema)
    }

    /// Downloads one snapshot, checks its hash, and decrypts it. A newer schema is never partly read.
    public func downloadSnapshot(_ snapshotId: UUID, supportedSchema: Int) async throws -> RestoredSnapshot {
        let info = try await client.snapshot(snapshotId)
        guard info.schema <= supportedSchema else { throw BackupError.schemaTooNew(info.schema) }
        let data = try await client.downloadObject(from: info.downloadUrl)
        guard Base64URL.encode(Digest.sha256(data)) == info.sha256, info.sizeBytes.map({ $0 == data.count }) ?? true else {
            throw BackupError.checksumMismatch
        }
        let (header, _) = try SnapshotContainer.readHeader(data)
        guard header.snapshotId == snapshotId, header.epoch == info.epoch, header.schema == info.schema else {
            throw BackupError.snapshotMismatch
        }
        guard header.schema <= supportedSchema else { throw BackupError.schemaTooNew(header.schema) }
        if keyRing.ark(epoch: header.epoch, accountId: accountId) == nil {
            let state = try await fetchKeys()
            if state.epoch == header.epoch { _ = try await currentKey(for: state) }
        }
        let opened: SnapshotContainer.Opened
        do {
            let ring = keyRing
            let account = accountId
            opened = try SnapshotContainer.open(data, accountId: account) { ring.ark(epoch: $0, accountId: account) }
        } catch FocusCryptoError.missingKey(let epoch) {
            throw BackupError.keyNotAvailable(epoch: epoch)
        }
        return RestoredSnapshot(snapshotId: snapshotId, version: info.version, schema: header.schema, epoch: header.epoch,
                                createdAt: header.createdAt, deviceId: header.deviceId, bundle: opened.bundle)
    }

    // MARK: - Helpers

    /// `GET /keys`; NOT_FOUND reads as "no key yet".
    private func fetchKeys() async throws -> KeysState {
        do {
            return try await client.keys()
        } catch let error as APIError where error.code == .notFound {
            return KeysState(epoch: 0)
        }
    }

    /// The key for the server's current epoch: on this phone, in this phone's slot, or in the iCloud copy.
    private func currentKey(for state: KeysState) async throws -> AccountRootKey? {
        guard state.epoch > 0 else { return nil }
        if let ark = keyRing.ark(epoch: state.epoch, accountId: accountId) { return ark }
        if let slot = state.mySlot, slot.epoch == state.epoch {
            let ark = try await client.deviceIdentity().openSlot(slot, accountId: accountId)
            try keyRing.save(ark, accountId: accountId)
            return ark
        }
        if let ark = keyRing.escrowedARK(epoch: state.epoch, accountId: accountId) {
            try keyRing.save(ark, accountId: accountId)
            try await uploadOwnSlot(for: ark)
            return ark
        }
        return nil
    }

    private func deviceRecipients(currentDevice: UUID) async throws -> [KeyRecipient] {
        try await client.devices().compactMap { device in
            if device.id == currentDevice { return nil }
            guard let text = device.agreementKey else { throw BackupError.missingAgreementKey(device.id) }
            return KeyRecipient(deviceId: device.id, agreementKey: try DeviceSlot.publicKey(fromBase64URL: text))
        }
    }

    /// The server builds the S3 checksum header from our hash; a different one would fail the PUT.
    private func checkChecksumHeader(_ ticket: SnapshotUploadTicket, sealed: SnapshotContainer.Sealed) throws {
        guard let header = ticket.uploadHeaders.first(where: { $0.key.caseInsensitiveCompare("x-amz-checksum-sha256") == .orderedSame }) else {
            return
        }
        guard header.value == sealed.sha256Base64 else { throw BackupError.checksumMismatch }
    }
}
