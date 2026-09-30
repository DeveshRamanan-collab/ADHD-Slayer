# FocusSync

The iPhone side of the Focus backend: the API client, sessions, device proofs, sign-in helpers, and the end-to-end encryption for backups and moving phones. Foundation, CryptoKit and Security only; no third-party packages; `Sendable`-clean under Swift 6.

- Byte formats: `backend/CONTRACT.md` (wins on bytes).
- Behaviour: `docs/build-spec/02-backend.md` (wins on behaviour) and `03-data-model.md`.
- Shared test vectors: `app/FocusCore/Tests/FocusSyncTests/Fixtures/contract-vectors.json`.

## Map

| File | What |
|---|---|
| `API/APIConfiguration.swift` | base and CDN URLs, `User-Agent`, reading Info.plist (and the Debug `FOCUS_API_BASE_URL` override) |
| `API/APIClient.swift` | the actor: bearer tokens, device proofs, single-flight refresh, retries, session ending |
| `API/APIClient+Endpoints.swift` | one typed method per endpoint in 02-backend.md "API" |
| `API/Models.swift` | request and response shapes, tolerant decoding, lowercase ids |
| `API/APIError.swift` | every error code, the envelope, `Retry-After` |
| `API/Retry.swift` | `withBackgroundRetry`: 2^n seconds with jitter, capped at 6 hours |
| `API/SignedContent.swift` | config and copy deck signatures |
| `API/HTTPTransport.swift` | `HTTPTransport` (tests use a fake), `URLSessionTransport` (no cookies, no cache, TLS 1.2+) |
| `Identity/` | `SecureStore` (Keychain or in memory), `SessionStore`, `DeviceIdentity`, `DeviceProof` |
| `SignIn/` | Apple nonce, Google PKCE flow, email link verifier and universal link parsing |
| `Crypto/` | ARK and KEK, `KeyRing`, FCS1 `SnapshotContainer`, HPKE `DeviceSlot`, `RecoveryKey` and `RecoverySlot`, `KeyTransfer` |
| `Backup/BackupService.swift` | upload, download, key setup, transfer (both phones), rotation |

## Setting up

The app makes one client at launch (`app/FocusApp/FocusApp/Model/Backend/Backend.swift`):

```swift
let configuration = APIConfiguration.resolve(infoDictionary: Bundle.main.infoDictionary ?? [:],
                                             environment: ProcessInfo.processInfo.environment,
                                             allowEnvironmentOverride: isDebug)
// nil: no server. The app keeps LocalAuthBackend and works fully offline.
let store = KeychainStore.deviceItems
let client = APIClient(configuration: configuration, sessionStore: SessionStore(store: store),
                       identity: { try DeviceIdentity.loadOrCreate(in: store) })
await client.setSessionEndedHandler { reason in /* show "Sign in again to keep your backup up to date." */ }
```

- The device identity loads lazily, off the main thread, the first time a call needs it.
- Crash reports and usage counts go through a second, ephemeral `URLSession` that never carries a token or a device id.
- Every request sends `User-Agent: Focus/<version> (<build>; iOS <os>)`.

## Keychain items

All in service `au.adhdslayer.focus`, never synchronizable, except the iCloud copy.

| Item | Accessible | Written by |
|---|---|---|
| `session.access`, `session.refresh` | after first unlock, this device only | `SessionStore` (refresh first, then access, so a crash never replays a spent refresh token) |
| `device.id`, `device.signing`, `device.agreement` | after first unlock, this device only | `DeviceIdentity` (signing key in the Secure Enclave when available) |
| `sync.ark.<epoch>` | when unlocked, this device only | `KeyRing` |
| `ark.<accountId>.<epoch>` in `au.adhdslayer.focus.escrow` | when unlocked, synchronizable | `KeyRing` with an escrow store (the optional iCloud Keychain copy) |
| `linkVerifier`, `appleUserID`, `pendingDeletion`, `account` | after first unlock, this device only | the app |

## Sign in

Every sign-in sends the provider credential, the `device` object (id, model, versions, both public keys) and `consents` (terms, privacy and notice versions, `adultConfirmedAt`). The sign-in methods keep the returned session themselves.

- **Apple**: make a `SignInNonce`, set `request.nonce = nonce.hashed`, then `signInWithApple(identityToken:authorizationCode:rawNonce: nonce.raw, appleUserId:consents:)`.
- **Google**: `GoogleSignInRequest(clientID:)` gives the authorization URL (PKCE S256, `state`, hashed `nonce`, `prompt=select_account`) and the callback scheme (the reversed client id). Open it in `ASWebAuthenticationSession` with a shared browser session, pass the callback to `authorizationCode(from:)` (checks `state`), `exchange(code:transport:)` for the ID token (no client secret, nothing else kept), then `signInWithGoogle(idToken:rawNonce:consents:)`.
- **Email**: `EmailLinkVerifier.make()`; keep `verifier` in the Keychain and send `challenge` with `startEmailSignIn`. The universal link `https://focus.adhdslayer.au/auth/email#t=<token>` gives its token through `EmailLink.token(from:)`; `EmailLink.Token` shows its expiry without asking the server. Verify with `.link(token:)` or `.code(email:code:)` plus the verifier.
- **Local development**: `localDevelopmentSession(consents:)` calls `POST /v1/_local/auth/session` (404 outside `FOCUS_ENV=local`).

## Sessions and refresh

- Bearer calls refresh first when under 2 minutes are left, and once more after `TOKEN_EXPIRED` or `UNAUTHENTICATED`, then retry once.
- Refresh is single flight: concurrent callers share one `POST /auth/refresh` (a P call). A caller holding a token someone else already replaced gets the new session, so a spent refresh token is never replayed.
- `SESSION_REVOKED`, `DEVICE_REVOKED`, or a refresh token that ran out end the session: tokens are cleared on this phone and the handler runs. The app keeps working and never signs out silently.
- A late failure for an old token can't end a newer session.
- `logout()` forgets the tokens here at once and tells the server best effort, so offline sign-out still works.

## Device proofs

`DeviceProof(identity:).sign(method:pathWithQuery:body:timestamp:)` returns `X-Device-Id`, `X-Device-Timestamp` and `X-Device-Signature`. The canonical string is the method, the path with its query exactly as sent (including `/v1`), the Unix seconds, and the lowercase hex SHA-256 of the exact body, joined by `\n` with no trailing newline. The signature is ES256, raw 64-byte `r || s`, base64url. After `DEVICE_PROOF_INVALID` the client reads the server's `Date` header, corrects its clock, and retries once.

## Errors and retries

- `APIError.server(ServerError)` carries the HTTP status, an `APIErrorCode` (every code in the spec; unknown codes read as `.unknown(String)`), `details` and `retryAfter`. `.transport` means no answer (`isOffline`). The app shows its own copy, never `message`.
- The client never retries 4xx beyond the refresh and proof retries above. 5xx and offline are left to the caller.
- `withBackgroundRetry(policy:)` retries offline, 5xx, `UPSTREAM_UNAVAILABLE`, `SERVICE_PAUSED` and `RATE_LIMITED` (never sooner than `Retry-After`), waiting 2^n seconds with jitter, capped at 6 hours. Keep the idempotency key fixed across attempts; `postTransaction` derives it from the JWS.

## Backup

`BackupService(accountId:client:keyRing:)` takes and returns the sync bundle as JSON `Data`.

- **Key setup (first device)**: `keyStatus()` is `.notSetUp` while the server says epoch 0. `setUpKeys(createRecoveryKey:)` makes a new ARK at epoch 1, seals it to this phone, optionally makes a recovery slot, and sends it all in one `POST /keys/epochs` from epoch 0. Show the recovery key once (`formatted`), never store it.
- **Upload**: `uploadSnapshot(bundle:schema:baseVersion:)` seals FCS1 with the current key, starts (`POST /sync/snapshots` with the base64url SHA-256), PUTs to the presigned URL with exactly the returned headers (plus `User-Agent`, never a token), and commits. `SNAPSHOT_CONFLICT` returns `.conflict(currentVersion:)`: download, merge, upload again with that version as the base. `UPLOAD_INCOMPLETE` or `CHECKSUM_MISMATCH` upload once more on a fresh URL; `EPOCH_MISMATCH` fetches the new key and tries once more. For a background `URLSession`, use `prepareUpload`, send `uploadRequest` yourself, then `commit`.
- **Restore**: `downloadNewestSnapshot(supportedSchema:)` checks the schema before downloading (a newer schema is never partly read), checks the hash, opens this phone's slot or the iCloud copy if the key isn't here yet, and decrypts. Validating and importing the records is the app's job.
- **Recovery key**: `unlock(withRecoveryKey: RecoveryKey(parsing: typed))` (ignores case, spaces and dashes; `O` is `0`, `I` and `L` are `1`), then uploads this phone's slot. `createRecoveryKey()` replaces the recovery slot.
- **Moving phones, new phone**: `offerKeyTransfer()` registers the agreement key and gives `qrPayload` (`focus-transfer:1:<transferId>:<fingerprint>`) and `displayFingerprint` (8 groups of 4 lowercase hex characters). `receiveKeyTransfer(_:)` polls every 2 seconds for up to 10 minutes, opens the key, keeps it, and uploads this phone's slot.
- **Moving phones, old phone**: `approveKeyTransfer(scannedPayload:)` fetches the transfer, refuses a key whose fingerprint differs from the QR code (`.fingerprintMismatch`), seals the current key with HPKE and uploads it. A second approval returns `.alreadySealed`.
- **Rotation**: `rotateKeys(createRecoveryKey:recipients:)` makes the next epoch's ARK, seals a slot for every remaining device (from `GET /devices` unless given) and sends them in one `POST /keys/epochs`. Then upload a new-epoch snapshot and ask the person to save the new recovery key.

## Config, copy, diagnostics, support

- `config(etag:)` and `copyDeck(version:)` come from the CDN with no account or device id. Check them with `SignedContentVerifier(publicKeys:)` (the app bundles the current and next keys) and `RemoteConfig.validate(now:lastAcceptedVersion:)`.
- `submitCrashReport` (256 KB cap) and `submitAnalyticsBatch` use the anonymous session.
- `submitSupportRequest` sends a bearer token when signed in, otherwise needs `replyEmail`.

## Points agreed by assumption (check with backend/api)

- First key setup is `POST /keys/epochs` with `fromEpoch: 0, toEpoch: 1`; `GET /keys` answers `epoch: 0` (or 404) before any key exists. For `fromEpoch: 0` only the caller's slot is required.
- `GET /devices` rows include `agreementKey` (base64url X9.63). Rotation can't seal slots without it.
- `SNAPSHOT_CONFLICT` puts `currentVersion` in `details`; `ACCOUNT_DELETION_PENDING` puts `completesBy` there.
- The optional `recovery` in `POST /keys/epochs` has the same shape as `PUT /keys/recovery` (`epoch`, `nonce`, `ciphertext`).
- A sign-in refused because the verified email belongs to an account with another method comes back as `FORBIDDEN` (the spec has no code for it); the app shows "You already have an account with this email. Sign in the way you did before."
- `POST /_local/auth/session` takes `{device, consents}` and answers like a sign-in.
- Times are formatted from whole milliseconds rounded to the nearest, so parsing and formatting round-trip exactly.

## Left for the app once persistence exists

- **The sync bundle** (03-data-model.md, Sync bundle): build it from the GRDB store with sync metadata on every record (`hlc`, `modifiedBy`, `deletedAt`), and leave out calendar data, plans, the glance file, notification schedules, onboarding flags, tokens and keys.
- **Merging after a conflict** (02-backend.md, Conflicts): facts (dose events, audit entries, check-ins, brain weather, consents) union by id, with the "Two logs close together, from two phones. Keep both?" card; medications, kinds of day, categories and tasks newest change per record, with the "changed on two phones" card for strength, kind and dose times; Customise, personal windows and tuning newest change per field; rebuild the learned focus state from merged check-ins; tombstones kept 90 days; the over-90-days rule.
- **When to upload**: 2 minutes after the last change, at most every 10 minutes, and on backgrounding with unsent changes, with the PUT on a background `URLSession`; only once health consent exists and a key is set up. Show the last backup time in Settings.
- **Screens**: the restore flow (iCloud copy, "Use your old iPhone" with the QR code and scanner, "Type your recovery key", "Start fresh"), showing the recovery key once with Copy and "Save as PDF to Files", "Welcome back. Sign in to bring your data back.", "Restore an earlier backup", "Delete my backup" (`deleteBackup()`), the iCloud copy switch, and Devices with removal followed by rotation.
- **Restore import**: validate every record and import into an empty store in one transaction, then ask again for calendar and notifications and reschedule local notifications.
- **Elsewhere**: fetching and applying signed config and copy (bundle the public keys), MetricKit crash reports, the analytics counters, the support form, `updateCurrentDevice()` after an app or OS update, and `acceptConsent` when the Terms or Privacy Policy change.
