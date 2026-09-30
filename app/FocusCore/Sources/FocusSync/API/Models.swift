import Foundation

// The shapes in 02-backend.md "API". Decoding is tolerant: optional fields may be missing, unknown
// fields are ignored and unknown enum values read as `.unknown`. Ids go out in lower case.

// MARK: - Sessions, devices, consents

public struct Session: Codable, Sendable, Equatable {
    public var accessToken: String
    public var accessExpiresAt: Date
    public var refreshToken: String
    public var refreshExpiresAt: Date

    public init(accessToken: String, accessExpiresAt: Date, refreshToken: String, refreshExpiresAt: Date) {
        self.accessToken = accessToken
        self.accessExpiresAt = accessExpiresAt
        self.refreshToken = refreshToken
        self.refreshExpiresAt = refreshExpiresAt
    }
}

/// `device {deviceId, model, osVersion, appVersion, signingKey, agreementKey}`, sent at sign-in.
public struct DeviceRegistration: Codable, Sendable, Equatable {
    public var deviceId: UUID
    public var model: String
    public var osVersion: String
    public var appVersion: String
    /// Base64url of the 65-byte X9.63 P-256 point.
    public var signingKey: String
    public var agreementKey: String

    public init(deviceId: UUID, model: String, osVersion: String, appVersion: String, signingKey: String, agreementKey: String) {
        self.deviceId = deviceId
        self.model = model
        self.osVersion = osVersion
        self.appVersion = appVersion
        self.signingKey = signingKey
        self.agreementKey = agreementKey
    }

    private enum CodingKeys: String, CodingKey { case deviceId, model, osVersion, appVersion, signingKey, agreementKey }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(deviceId.wire, forKey: .deviceId)
        try container.encode(model, forKey: .model)
        try container.encode(osVersion, forKey: .osVersion)
        try container.encode(appVersion, forKey: .appVersion)
        try container.encode(signingKey, forKey: .signingKey)
        try container.encode(agreementKey, forKey: .agreementKey)
    }
}

/// `consents {termsVersion, privacyVersion, noticeVersion, adultConfirmedAt}`, sent with sign-up.
public struct Consents: Codable, Sendable, Equatable {
    public var termsVersion: Int
    public var privacyVersion: Int
    public var noticeVersion: Int
    public var adultConfirmedAt: Date

    public init(termsVersion: Int, privacyVersion: Int, noticeVersion: Int, adultConfirmedAt: Date) {
        self.termsVersion = termsVersion
        self.privacyVersion = privacyVersion
        self.noticeVersion = noticeVersion
        self.adultConfirmedAt = adultConfirmedAt
    }
}

public enum ConsentKind: String, Codable, Sendable, CaseIterable {
    case terms, privacy, notice
}

// MARK: - Sign-in

public enum IdentityProvider: String, Codable, Sendable {
    case apple, google, email, unknown

    public init(from decoder: any Decoder) throws {
        self = IdentityProvider(rawValue: try decoder.singleValueContainer().decode(String.self)) ?? .unknown
    }
}

public struct SignInIdentity: Codable, Sendable, Equatable {
    public var provider: IdentityProvider
    public var email: String?
    public var isPrivateRelay: Bool?

    public init(provider: IdentityProvider, email: String? = nil, isPrivateRelay: Bool? = nil) {
        self.provider = provider
        self.email = email
        self.isPrivateRelay = isPrivateRelay
    }
}

/// `backup {exists, epoch, version, updatedAt}` in the sign-in reply and `GET /account`.
public struct BackupSummary: Codable, Sendable, Equatable {
    public var exists: Bool
    public var epoch: Int?
    public var version: Int?
    public var updatedAt: Date?

    public init(exists: Bool, epoch: Int? = nil, version: Int? = nil, updatedAt: Date? = nil) {
        self.exists = exists
        self.epoch = epoch
        self.version = version
        self.updatedAt = updatedAt
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        exists = try container.decodeIfPresent(Bool.self, forKey: .exists) ?? false
        epoch = try container.decodeIfPresent(Int.self, forKey: .epoch)
        version = try container.decodeIfPresent(Int.self, forKey: .version)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
}

/// `signIn {accountId, isNewAccount, session, identity, backup}`.
public struct SignInResponse: Codable, Sendable, Equatable {
    public var accountId: UUID
    public var isNewAccount: Bool
    public var session: Session
    public var identity: SignInIdentity?
    public var backup: BackupSummary?

    public init(accountId: UUID, isNewAccount: Bool, session: Session, identity: SignInIdentity? = nil, backup: BackupSummary? = nil) {
        self.accountId = accountId
        self.isNewAccount = isNewAccount
        self.session = session
        self.identity = identity
        self.backup = backup
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accountId = try container.decode(UUID.self, forKey: .accountId)
        isNewAccount = try container.decodeIfPresent(Bool.self, forKey: .isNewAccount) ?? false
        session = try container.decode(Session.self, forKey: .session)
        identity = try? container.decodeIfPresent(SignInIdentity.self, forKey: .identity)
        backup = try? container.decodeIfPresent(BackupSummary.self, forKey: .backup)
    }
}

/// The 202 from `POST /auth/email/start`, the same for every address.
public struct EmailSignInStart: Codable, Sendable, Equatable {
    public var resendAfterSeconds: Int
    public var expiresInSeconds: Int

    public init(resendAfterSeconds: Int = 60, expiresInSeconds: Int = 900) {
        self.resendAfterSeconds = resendAfterSeconds
        self.expiresInSeconds = expiresInSeconds
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        resendAfterSeconds = try container.decodeIfPresent(Int.self, forKey: .resendAfterSeconds) ?? 60
        expiresInSeconds = try container.decodeIfPresent(Int.self, forKey: .expiresInSeconds) ?? 900
    }
}

/// What proves the email: the link's token, or the 6-digit code typed with the address it went to.
public enum EmailCredential: Sendable, Equatable {
    case link(token: String)
    case code(email: String, code: String)
}

// MARK: - Account and devices

public enum AccountStatus: String, Codable, Sendable {
    case active, deleting, unknown

    public init(from decoder: any Decoder) throws {
        self = AccountStatus(rawValue: try decoder.singleValueContainer().decode(String.self)) ?? .unknown
    }
}

/// `GET /account`.
public struct AccountInfo: Codable, Sendable, Equatable {
    public var accountId: UUID
    public var createdAt: Date?
    public var status: AccountStatus
    public var identities: [SignInIdentity]
    public var deviceCount: Int?
    public var consents: Consents?
    public var entitlement: Entitlement?
    public var backup: BackupSummary?

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accountId = try container.decode(UUID.self, forKey: .accountId)
        createdAt = try? container.decodeIfPresent(Date.self, forKey: .createdAt)
        status = (try? container.decodeIfPresent(AccountStatus.self, forKey: .status)) ?? .unknown
        identities = (try? container.decodeIfPresent([SignInIdentity].self, forKey: .identities)) ?? []
        deviceCount = try? container.decodeIfPresent(Int.self, forKey: .deviceCount)
        consents = try? container.decodeIfPresent(Consents.self, forKey: .consents)
        entitlement = try? container.decodeIfPresent(Entitlement.self, forKey: .entitlement)
        backup = try? container.decodeIfPresent(BackupSummary.self, forKey: .backup)
    }
}

/// `DELETE /account`: 202 `{status: deleting, completesBy}`.
public struct AccountDeletion: Codable, Sendable, Equatable {
    public var status: AccountStatus
    public var completesBy: Date?

    public init(status: AccountStatus, completesBy: Date?) {
        self.status = status
        self.completesBy = completesBy
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = (try? container.decodeIfPresent(AccountStatus.self, forKey: .status)) ?? .deleting
        completesBy = try? container.decodeIfPresent(Date.self, forKey: .completesBy)
    }
}

/// One row of `GET /devices`.
public struct DeviceSummary: Codable, Sendable, Equatable {
    public var id: UUID
    public var model: String?
    public var appVersion: String?
    public var enrolledAt: Date?
    /// A calendar date, `2026-09-30`.
    public var lastSeenOn: String?
    public var isCurrent: Bool
    public var hasKeySlot: Bool
    /// Base64url X9.63 agreement key. Not in the spec's list yet, but key rotation needs it to seal
    /// a slot for every remaining device, so the app reads it when the server sends it.
    public var agreementKey: String?

    public init(id: UUID, model: String? = nil, appVersion: String? = nil, enrolledAt: Date? = nil, lastSeenOn: String? = nil,
                isCurrent: Bool = false, hasKeySlot: Bool = false, agreementKey: String? = nil) {
        self.id = id
        self.model = model
        self.appVersion = appVersion
        self.enrolledAt = enrolledAt
        self.lastSeenOn = lastSeenOn
        self.isCurrent = isCurrent
        self.hasKeySlot = hasKeySlot
        self.agreementKey = agreementKey
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        model = try? container.decodeIfPresent(String.self, forKey: .model)
        appVersion = try? container.decodeIfPresent(String.self, forKey: .appVersion)
        enrolledAt = try? container.decodeIfPresent(Date.self, forKey: .enrolledAt)
        lastSeenOn = try? container.decodeIfPresent(String.self, forKey: .lastSeenOn)
        isCurrent = (try? container.decodeIfPresent(Bool.self, forKey: .isCurrent)) ?? false
        hasKeySlot = (try? container.decodeIfPresent(Bool.self, forKey: .hasKeySlot)) ?? false
        agreementKey = try? container.decodeIfPresent(String.self, forKey: .agreementKey)
    }
}

public enum DeviceRemovalReason: String, Codable, Sendable {
    case lost, replaced, other
}

// MARK: - Keys

/// An ARK sealed to one device with HPKE: `{epoch, enc, ciphertext}`, both base64url.
public struct SealedSlot: Codable, Sendable, Equatable {
    public var epoch: Int
    public var enc: String
    public var ciphertext: String

    public init(epoch: Int, enc: String, ciphertext: String) {
        self.epoch = epoch
        self.enc = enc
        self.ciphertext = ciphertext
    }
}

/// An ARK sealed with the recovery key: `{epoch, nonce, ciphertext}`, ciphertext including the tag.
public struct SealedRecoverySlot: Codable, Sendable, Equatable {
    public var epoch: Int
    public var nonce: String
    public var ciphertext: String

    public init(epoch: Int, nonce: String, ciphertext: String) {
        self.epoch = epoch
        self.nonce = nonce
        self.ciphertext = ciphertext
    }
}

public struct RecoveryState: Codable, Sendable, Equatable {
    public var epoch: Int
    public var exists: Bool

    public init(epoch: Int, exists: Bool) {
        self.epoch = epoch
        self.exists = exists
    }
}

/// `GET /keys`. Epoch 0 means no key has been set up for the account yet.
public struct KeysState: Codable, Sendable, Equatable {
    public var epoch: Int
    public var rotationRequired: Bool
    public var mySlot: SealedSlot?
    public var recovery: RecoveryState?

    public init(epoch: Int, rotationRequired: Bool = false, mySlot: SealedSlot? = nil, recovery: RecoveryState? = nil) {
        self.epoch = epoch
        self.rotationRequired = rotationRequired
        self.mySlot = mySlot
        self.recovery = recovery
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        epoch = try container.decodeIfPresent(Int.self, forKey: .epoch) ?? 0
        rotationRequired = (try? container.decodeIfPresent(Bool.self, forKey: .rotationRequired)) ?? false
        mySlot = try? container.decodeIfPresent(SealedSlot.self, forKey: .mySlot)
        recovery = try? container.decodeIfPresent(RecoveryState.self, forKey: .recovery)
    }
}

/// One device's slot in `POST /keys/epochs`.
public struct DeviceSlotUpload: Codable, Sendable, Equatable {
    public var deviceId: UUID
    public var enc: String
    public var ciphertext: String

    public init(deviceId: UUID, slot: SealedSlot) {
        self.deviceId = deviceId
        self.enc = slot.enc
        self.ciphertext = slot.ciphertext
    }

    private enum CodingKeys: String, CodingKey { case deviceId, enc, ciphertext }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        deviceId = try container.decode(UUID.self, forKey: .deviceId)
        enc = try container.decode(String.self, forKey: .enc)
        ciphertext = try container.decode(String.self, forKey: .ciphertext)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(deviceId.wire, forKey: .deviceId)
        try container.encode(enc, forKey: .enc)
        try container.encode(ciphertext, forKey: .ciphertext)
    }
}

/// `POST /keys/epochs {fromEpoch, toEpoch, slots, recovery?}`. Also the first key setup, from epoch 0 to 1.
public struct EpochChange: Codable, Sendable, Equatable {
    public var fromEpoch: Int
    public var toEpoch: Int
    public var slots: [DeviceSlotUpload]
    public var recovery: SealedRecoverySlot?

    public init(fromEpoch: Int, toEpoch: Int, slots: [DeviceSlotUpload], recovery: SealedRecoverySlot? = nil) {
        self.fromEpoch = fromEpoch
        self.toEpoch = toEpoch
        self.slots = slots
        self.recovery = recovery
    }
}

/// `POST /key-transfers` reply.
public struct KeyTransferTicket: Codable, Sendable, Equatable {
    public var transferId: UUID
    public var expiresAt: Date

    public init(transferId: UUID, expiresAt: Date) {
        self.transferId = transferId
        self.expiresAt = expiresAt
    }
}

public enum KeyTransferState: String, Codable, Sendable {
    case waiting, sealed, done, expired, unknown

    public init(from decoder: any Decoder) throws {
        self = KeyTransferState(rawValue: try decoder.singleValueContainer().decode(String.self)) ?? .unknown
    }
}

/// `GET /key-transfers/{id}`. `sealed` reaches the requester only, and only once.
public struct KeyTransferStatus: Codable, Sendable, Equatable {
    public var state: KeyTransferState
    public var requesterDeviceId: UUID?
    public var agreementKey: String?
    public var sealed: SealedSlot?

    public init(state: KeyTransferState, requesterDeviceId: UUID? = nil, agreementKey: String? = nil, sealed: SealedSlot? = nil) {
        self.state = state
        self.requesterDeviceId = requesterDeviceId
        self.agreementKey = agreementKey
        self.sealed = sealed
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        state = (try? container.decodeIfPresent(KeyTransferState.self, forKey: .state)) ?? .unknown
        requesterDeviceId = try? container.decodeIfPresent(UUID.self, forKey: .requesterDeviceId)
        agreementKey = try? container.decodeIfPresent(String.self, forKey: .agreementKey)
        sealed = try? container.decodeIfPresent(SealedSlot.self, forKey: .sealed)
    }
}

// MARK: - Sync

/// `GET /sync/state`. Version 0 means nothing has been committed yet.
public struct SyncState: Codable, Sendable, Equatable {
    public var version: Int
    public var snapshotId: UUID?
    public var epoch: Int?
    public var rotationRequired: Bool
    public var updatedAt: Date?
    public var usedBytes: Int?
    public var quotaBytes: Int?

    public init(version: Int, snapshotId: UUID? = nil, epoch: Int? = nil, rotationRequired: Bool = false,
                updatedAt: Date? = nil, usedBytes: Int? = nil, quotaBytes: Int? = nil) {
        self.version = version
        self.snapshotId = snapshotId
        self.epoch = epoch
        self.rotationRequired = rotationRequired
        self.updatedAt = updatedAt
        self.usedBytes = usedBytes
        self.quotaBytes = quotaBytes
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = (try? container.decodeIfPresent(Int.self, forKey: .version)) ?? 0
        snapshotId = try? container.decodeIfPresent(UUID.self, forKey: .snapshotId)
        epoch = try? container.decodeIfPresent(Int.self, forKey: .epoch)
        rotationRequired = (try? container.decodeIfPresent(Bool.self, forKey: .rotationRequired)) ?? false
        updatedAt = try? container.decodeIfPresent(Date.self, forKey: .updatedAt)
        usedBytes = try? container.decodeIfPresent(Int.self, forKey: .usedBytes)
        quotaBytes = try? container.decodeIfPresent(Int.self, forKey: .quotaBytes)
    }
}

/// `POST /sync/snapshots {snapshotId, baseVersion, epoch, schema, sizeBytes, sha256}`.
public struct SnapshotStart: Codable, Sendable, Equatable {
    public var snapshotId: UUID
    public var baseVersion: Int
    public var epoch: Int
    public var schema: Int
    public var sizeBytes: Int
    /// Base64url SHA-256 of the whole encrypted object.
    public var sha256: String

    public init(snapshotId: UUID, baseVersion: Int, epoch: Int, schema: Int, sizeBytes: Int, sha256: String) {
        self.snapshotId = snapshotId
        self.baseVersion = baseVersion
        self.epoch = epoch
        self.schema = schema
        self.sizeBytes = sizeBytes
        self.sha256 = sha256
    }

    private enum CodingKeys: String, CodingKey { case snapshotId, baseVersion, epoch, schema, sizeBytes, sha256 }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        snapshotId = try container.decode(UUID.self, forKey: .snapshotId)
        baseVersion = try container.decode(Int.self, forKey: .baseVersion)
        epoch = try container.decode(Int.self, forKey: .epoch)
        schema = try container.decode(Int.self, forKey: .schema)
        sizeBytes = try container.decode(Int.self, forKey: .sizeBytes)
        sha256 = try container.decode(String.self, forKey: .sha256)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(snapshotId.wire, forKey: .snapshotId)
        try container.encode(baseVersion, forKey: .baseVersion)
        try container.encode(epoch, forKey: .epoch)
        try container.encode(schema, forKey: .schema)
        try container.encode(sizeBytes, forKey: .sizeBytes)
        try container.encode(sha256, forKey: .sha256)
    }
}

/// The 201 from `POST /sync/snapshots`: a presigned URL and the headers to send with it, exactly.
public struct SnapshotUploadTicket: Codable, Sendable, Equatable {
    public var uploadUrl: URL
    public var uploadHeaders: [String: String]
    public var expiresAt: Date?

    public init(uploadUrl: URL, uploadHeaders: [String: String], expiresAt: Date?) {
        self.uploadUrl = uploadUrl
        self.uploadHeaders = uploadHeaders
        self.expiresAt = expiresAt
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uploadUrl = try container.decode(URL.self, forKey: .uploadUrl)
        // Header values are strings on the wire; a number (Content-Length) is accepted too.
        let raw = try container.decodeIfPresent([String: JSONValue].self, forKey: .uploadHeaders) ?? [:]
        uploadHeaders = raw.compactMapValues { value in
            switch value {
            case .string(let text): text
            case .number(let number): number.rounded() == number ? String(Int64(number)) : String(number)
            case .bool(let flag): flag ? "true" : "false"
            default: nil
            }
        }
        expiresAt = try? container.decodeIfPresent(Date.self, forKey: .expiresAt)
    }
}

/// `POST /sync/snapshots/{id}/commit`.
public struct SnapshotCommit: Codable, Sendable, Equatable {
    public var version: Int
    public var committedAt: Date?

    public init(version: Int, committedAt: Date?) {
        self.version = version
        self.committedAt = committedAt
    }
}

/// One row of `GET /sync/snapshots`.
public struct SnapshotInfo: Codable, Sendable, Equatable {
    public var id: UUID
    public var version: Int
    public var epoch: Int
    public var schema: Int
    public var sizeBytes: Int?
    public var createdAt: Date?
    public var deviceId: UUID?
}

/// `GET /sync/snapshots/{id}`: a download URL good for 5 minutes.
public struct SnapshotDownload: Codable, Sendable, Equatable {
    public var downloadUrl: URL
    public var sizeBytes: Int?
    /// Base64url SHA-256 of the whole encrypted object.
    public var sha256: String
    public var version: Int
    public var epoch: Int
    public var schema: Int

    public init(downloadUrl: URL, sizeBytes: Int?, sha256: String, version: Int, epoch: Int, schema: Int) {
        self.downloadUrl = downloadUrl
        self.sizeBytes = sizeBytes
        self.sha256 = sha256
        self.version = version
        self.epoch = epoch
        self.schema = schema
    }
}

/// `POST /sync/batches` (Later: encrypted change batches between snapshots).
public struct SyncBatchUpload: Codable, Sendable, Equatable {
    public var deviceId: UUID
    public var seq: Int
    public var epoch: Int
    public var schema: Int
    public var nonce: String
    public var ciphertext: String
    public var aadHash: String

    public init(deviceId: UUID, seq: Int, epoch: Int, schema: Int, nonce: String, ciphertext: String, aadHash: String) {
        self.deviceId = deviceId
        self.seq = seq
        self.epoch = epoch
        self.schema = schema
        self.nonce = nonce
        self.ciphertext = ciphertext
        self.aadHash = aadHash
    }

    private enum CodingKeys: String, CodingKey { case deviceId, seq, epoch, schema, nonce, ciphertext, aadHash }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        deviceId = try container.decode(UUID.self, forKey: .deviceId)
        seq = try container.decode(Int.self, forKey: .seq)
        epoch = try container.decode(Int.self, forKey: .epoch)
        schema = try container.decode(Int.self, forKey: .schema)
        nonce = try container.decode(String.self, forKey: .nonce)
        ciphertext = try container.decode(String.self, forKey: .ciphertext)
        aadHash = try container.decode(String.self, forKey: .aadHash)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(deviceId.wire, forKey: .deviceId)
        try container.encode(seq, forKey: .seq)
        try container.encode(epoch, forKey: .epoch)
        try container.encode(schema, forKey: .schema)
        try container.encode(nonce, forKey: .nonce)
        try container.encode(ciphertext, forKey: .ciphertext)
        try container.encode(aadHash, forKey: .aadHash)
    }
}

public struct SyncBatchReceipt: Codable, Sendable, Equatable {
    public var cursor: String
    public var duplicate: Bool

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let text = try? container.decode(String.self, forKey: .cursor) {
            cursor = text
        } else {
            cursor = String(try container.decode(Int.self, forKey: .cursor))
        }
        duplicate = (try? container.decodeIfPresent(Bool.self, forKey: .duplicate)) ?? false
    }
}

public struct SyncBatch: Codable, Sendable, Equatable {
    public var deviceId: UUID
    public var seq: Int
    public var epoch: Int
    public var schema: Int
    public var nonce: String
    public var ciphertext: String
    public var aadHash: String
    public var cursor: String?
}

public struct SyncBatchPage: Codable, Sendable, Equatable {
    public var batches: [SyncBatch]
    public var nextCursor: String?
    public var hasMore: Bool
}

// MARK: - Subscriptions

public enum EntitlementStatus: String, Codable, Sendable {
    case none, trial, active, grace, billingRetry, expired, revoked, unknown

    public init(from decoder: any Decoder) throws {
        self = EntitlementStatus(rawValue: try decoder.singleValueContainer().decode(String.self)) ?? .unknown
    }
}

/// `entitlement {status, productId, expiresAt, willAutoRenew, isTrial, graceExpiresAt, environment}`.
/// A mirror for support; StoreKit on the phone stays the truth.
public struct Entitlement: Codable, Sendable, Equatable {
    public var status: EntitlementStatus
    public var productId: String?
    public var expiresAt: Date?
    public var willAutoRenew: Bool?
    public var isTrial: Bool?
    public var graceExpiresAt: Date?
    public var environment: String?

    public init(status: EntitlementStatus, productId: String? = nil, expiresAt: Date? = nil, willAutoRenew: Bool? = nil,
                isTrial: Bool? = nil, graceExpiresAt: Date? = nil, environment: String? = nil) {
        self.status = status
        self.productId = productId
        self.expiresAt = expiresAt
        self.willAutoRenew = willAutoRenew
        self.isTrial = isTrial
        self.graceExpiresAt = graceExpiresAt
        self.environment = environment
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = (try? container.decodeIfPresent(EntitlementStatus.self, forKey: .status)) ?? .unknown
        productId = try? container.decodeIfPresent(String.self, forKey: .productId)
        expiresAt = try? container.decodeIfPresent(Date.self, forKey: .expiresAt)
        willAutoRenew = try? container.decodeIfPresent(Bool.self, forKey: .willAutoRenew)
        isTrial = try? container.decodeIfPresent(Bool.self, forKey: .isTrial)
        graceExpiresAt = try? container.decodeIfPresent(Date.self, forKey: .graceExpiresAt)
        environment = try? container.decodeIfPresent(String.self, forKey: .environment)
    }
}

// MARK: - Config and copy

/// A body signed at publish time (`GET /config`, `GET /copy/decks/{version}`).
public struct SignedDocument: Sendable, Equatable {
    public var body: Data
    /// Base64url raw `r || s` over SHA-256 of `body`, from the `Signature` header.
    public var signature: String?
    /// `Signature-Key-Id`, for example `config-2026-1`.
    public var keyId: String?
    public var etag: String?

    public init(body: Data, signature: String?, keyId: String?, etag: String?) {
        self.body = body
        self.signature = signature
        self.keyId = keyId
        self.etag = etag
    }

    public func decode<T: Decodable>(_ type: T.Type) throws -> T {
        try FocusJSON.decode(type, from: body)
    }
}

public enum ConfigFetch: Sendable, Equatable {
    /// 304: the config the app already holds is current.
    case notModified
    case document(SignedDocument)
}

/// The contents of `GET /config`.
public struct RemoteConfig: Codable, Sendable, Equatable {
    public struct CopyPointer: Codable, Sendable, Equatable {
        public var version: String
        public var sha256: String?

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            version = try container.decodeFlexibleString(forKey: .version)
            sha256 = try? container.decodeIfPresent(String.self, forKey: .sha256)
        }
    }

    public var version: Int
    public var issuedAt: Date
    public var expiresAt: Date
    public var minimumAppVersion: String?
    public var flags: [String: JSONValue]
    public var killSwitches: [String: JSONValue]
    public var copy: CopyPointer?
    public var notice: JSONValue?

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(Int.self, forKey: .version)
        issuedAt = try container.decode(Date.self, forKey: .issuedAt)
        expiresAt = try container.decode(Date.self, forKey: .expiresAt)
        minimumAppVersion = try? container.decodeIfPresent(String.self, forKey: .minimumAppVersion)
        flags = (try? container.decodeIfPresent([String: JSONValue].self, forKey: .flags)) ?? [:]
        killSwitches = (try? container.decodeIfPresent([String: JSONValue].self, forKey: .killSwitches)) ?? [:]
        copy = try? container.decodeIfPresent(CopyPointer.self, forKey: .copy)
        notice = try? container.decodeIfPresent(JSONValue.self, forKey: .notice)
    }

    /// Rejects expired configs and anything older than the version already accepted.
    public func validate(now: Date = Date(), lastAcceptedVersion: Int? = nil) throws {
        guard expiresAt > now else { throw SignedContentError.expired }
        if let lastAcceptedVersion, version < lastAcceptedVersion { throw SignedContentError.olderVersion }
    }
}

/// `GET /copy/manifest`.
public struct CopyManifest: Codable, Sendable, Equatable {
    public var version: String
    public var sha256: String
    public var sizeBytes: Int?
    public var minAppVersion: String?
    public var url: URL?

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeFlexibleString(forKey: .version)
        sha256 = try container.decode(String.self, forKey: .sha256)
        sizeBytes = try? container.decodeIfPresent(Int.self, forKey: .sizeBytes)
        minAppVersion = try? container.decodeIfPresent(String.self, forKey: .minAppVersion)
        url = try? container.decodeIfPresent(URL.self, forKey: .url)
    }
}

// MARK: - Diagnostics, analytics, support

/// `POST /diagnostics/crashes`: scrubbed on the phone, no account, device id or token.
public struct CrashReport: Codable, Sendable, Equatable {
    public var reportId: UUID
    /// A random id rotated every 90 days.
    public var diagnosticsId: UUID
    public var appVersion: String
    public var build: String
    public var osVersion: String
    public var model: String
    public var kind: String
    /// At most 256 KB once encoded.
    public var payload: JSONValue

    public init(reportId: UUID, diagnosticsId: UUID, appVersion: String, build: String, osVersion: String, model: String,
                kind: String, payload: JSONValue) {
        self.reportId = reportId
        self.diagnosticsId = diagnosticsId
        self.appVersion = appVersion
        self.build = build
        self.osVersion = osVersion
        self.model = model
        self.kind = kind
        self.payload = payload
    }

    private enum CodingKeys: String, CodingKey { case reportId, diagnosticsId, appVersion, build, osVersion, model, kind, payload }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        reportId = try container.decode(UUID.self, forKey: .reportId)
        diagnosticsId = try container.decode(UUID.self, forKey: .diagnosticsId)
        appVersion = try container.decode(String.self, forKey: .appVersion)
        build = try container.decode(String.self, forKey: .build)
        osVersion = try container.decode(String.self, forKey: .osVersion)
        model = try container.decode(String.self, forKey: .model)
        kind = try container.decode(String.self, forKey: .kind)
        payload = try container.decode(JSONValue.self, forKey: .payload)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(reportId.wire, forKey: .reportId)
        try container.encode(diagnosticsId.wire, forKey: .diagnosticsId)
        try container.encode(appVersion, forKey: .appVersion)
        try container.encode(build, forKey: .build)
        try container.encode(osVersion, forKey: .osVersion)
        try container.encode(model, forKey: .model)
        try container.encode(kind, forKey: .kind)
        try container.encode(payload, forKey: .payload)
    }
}

/// `POST /analytics/batches`: a day of allowlisted counters, opt-in, never linked to an account.
public struct AnalyticsBatch: Codable, Sendable, Equatable {
    public var batchId: UUID
    /// A random id rotated every 90 days.
    public var analyticsId: UUID
    /// `2026-09-30`.
    public var day: String
    public var versions: [String: String]
    public var deviceFamily: String
    public var locale: String
    public var region: String
    public var aiState: String
    public var counters: [String: Int]

    public init(batchId: UUID, analyticsId: UUID, day: String, versions: [String: String], deviceFamily: String, locale: String,
                region: String, aiState: String, counters: [String: Int]) {
        self.batchId = batchId
        self.analyticsId = analyticsId
        self.day = day
        self.versions = versions
        self.deviceFamily = deviceFamily
        self.locale = locale
        self.region = region
        self.aiState = aiState
        self.counters = counters
    }

    private enum CodingKeys: String, CodingKey { case batchId, analyticsId, day, versions, deviceFamily, locale, region, aiState, counters }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        batchId = try container.decode(UUID.self, forKey: .batchId)
        analyticsId = try container.decode(UUID.self, forKey: .analyticsId)
        day = try container.decode(String.self, forKey: .day)
        versions = try container.decode([String: String].self, forKey: .versions)
        deviceFamily = try container.decode(String.self, forKey: .deviceFamily)
        locale = try container.decode(String.self, forKey: .locale)
        region = try container.decode(String.self, forKey: .region)
        aiState = try container.decode(String.self, forKey: .aiState)
        counters = try container.decode([String: Int].self, forKey: .counters)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(batchId.wire, forKey: .batchId)
        try container.encode(analyticsId.wire, forKey: .analyticsId)
        try container.encode(day, forKey: .day)
        try container.encode(versions, forKey: .versions)
        try container.encode(deviceFamily, forKey: .deviceFamily)
        try container.encode(locale, forKey: .locale)
        try container.encode(region, forKey: .region)
        try container.encode(aiState, forKey: .aiState)
        try container.encode(counters, forKey: .counters)
    }
}

/// `POST /support/requests`.
public struct SupportRequest: Codable, Sendable, Equatable {
    public var topic: String
    /// Up to 4,000 characters.
    public var message: String
    /// Required when not signed in.
    public var replyEmail: String?
    /// "Include app details": versions, model, locale and the like, exactly as shown to the person.
    public var diagnostics: [String: String]?

    public init(topic: String, message: String, replyEmail: String? = nil, diagnostics: [String: String]? = nil) {
        self.topic = topic
        self.message = message
        self.replyEmail = replyEmail
        self.diagnostics = diagnostics
    }
}

public struct SupportReceipt: Codable, Sendable, Equatable {
    public var reference: String
}

/// `POST /attest/challenge` (Later: App Attest at registration and email start).
public struct AttestChallenge: Codable, Sendable, Equatable {
    public var challenge: String
    public var expiresAt: Date?
}

extension KeyedDecodingContainer {
    /// A value the server may send as a string or a number.
    func decodeFlexibleString(forKey key: Key) throws -> String {
        if let text = try? decode(String.self, forKey: key) { return text }
        return String(try decode(Int.self, forKey: key))
    }
}
