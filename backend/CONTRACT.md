# Backend contract

The one place the server (`backend/api`), the infrastructure (`backend/infra`), the static site (`backend/web`) and the iPhone client (`app/FocusCore/Sources/FocusSync`) agree on names and byte formats. The product rules live in `docs/build-spec/02-backend.md` (endpoints, errors, limits) and `docs/build-spec/03-data-model.md` (server tables, retention). If this file and the spec disagree on a byte format, this file wins; on behaviour, the spec wins.

## Layout

| Path | What |
|---|---|
| `backend/api` | TypeScript, Node.js 24, Fastify 5, zod. The API server and the job runner (same image). |
| `backend/infra` | AWS CDK v2 in TypeScript. One stack set per environment. |
| `backend/web` | Static files for `focus.adhdslayer.au` (universal links, the email link page, legal and support pages). |
| `.github/workflows` | CI and delivery. |
| `app/FocusCore/Sources/FocusSync` | The Swift client: API, sessions, device proofs, sign-in helpers, snapshot and key crypto. |

## Hosts and base URLs

| Environment | API base | CDN base (config and copy) | Web |
|---|---|---|---|
| local | `http://localhost:8080/v1` | `http://localhost:8080/v1` | `backend/web` served by `npm run web` on 8081 |
| staging | `https://api.staging.focus.adhdslayer.au/v1` | `https://cdn.staging.focus.adhdslayer.au/v1` | `https://staging.focus.adhdslayer.au` |
| production | `https://api.focus.adhdslayer.au/v1` | `https://cdn.focus.adhdslayer.au/v1` | `https://focus.adhdslayer.au` |

- `GET /healthz` sits outside `/v1`. The container listens on `PORT` (8080).
- The CDN is CloudFront with the API load balancer as origin for `/v1/config*` and `/v1/copy/*` only.
- The app reads `FocusAPIBaseURL` and `FocusCDNBaseURL` from Info.plist. Empty means "no server": the app keeps `LocalAuthBackend` and works fully offline.

## Environment variables (API and jobs)

| Name | Example | Notes |
|---|---|---|
| `FOCUS_ENV` | `local`, `staging`, `production` | `local` enables the dev-only routes and local adapters |
| `PORT` | `8080` | |
| `LOG_LEVEL` | `info` | |
| `PUBLIC_API_URL` | `https://api.focus.adhdslayer.au` | no trailing slash, no `/v1` |
| `PUBLIC_WEB_URL` | `https://focus.adhdslayer.au` | email links point here |
| `DATABASE_URL` | `postgres://...` or `pglite://.data/pglite` or `pglite://memory` | if unset, the standard `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSWORD`, `PGSSLMODE` are used |
| `AWS_REGION` | `ap-southeast-2` | |
| `SNAPSHOTS_BUCKET` | `focus-prod-snapshots` | versioned, SSE-KMS |
| `DIAGNOSTICS_BUCKET` | `focus-prod-diagnostics` | crash reports |
| `CONTENT_BUCKET` | `focus-prod-content` | signed config and copy decks |
| `LOCAL_DATA_DIR` | `.data` | local adapters write here |
| `KMS_ENVELOPE_KEY_ID` | alias or ARN | app-envelope: Apple refresh tokens, support text, reply emails |
| `KMS_MAGIC_LINK_HMAC_KEY_ID` | alias or ARN | HMAC_256 key |
| `KMS_RECEIPT_HMAC_KEY_ID` | alias or ARN | HMAC_256 key |
| `KMS_CONFIG_SIGNING_KEY_ID` | alias or ARN | ECC_NIST_P256 sign key, used only by `publish-config` and `publish-copy` |
| `SES_FROM` | `Focus <signin@focus.adhdslayer.au>` | |
| `SES_CONFIGURATION_SET` | `focus-transactional` | |
| `SUPPORT_FROM` | `Focus support <support@focus.adhdslayer.au>` | |
| `APPLE_TEAM_ID` | `ABCDE12345` | |
| `APPLE_BUNDLE_ID` | `au.adhdslayer.focus` | |
| `APPLE_APP_APPLE_ID` | `1234567890` | numeric App Store id, needed in production |
| `APPLE_SIWA_KEY_ID` | | Sign in with Apple key id |
| `APPLE_SIWA_PRIVATE_KEY` | PEM | secret, `.p8` contents |
| `APPSTORE_ISSUER_ID` | | App Store Server API |
| `APPSTORE_KEY_ID` | | |
| `APPSTORE_PRIVATE_KEY` | PEM | secret, `.p8` contents |
| `APPSTORE_ENVIRONMENT` | `Production`, `Sandbox`, `Xcode`, `LocalTesting` | which environment the server API client calls; notifications from both arrive |
| `GOOGLE_IOS_CLIENT_ID` | `...apps.googleusercontent.com` | |
| `HELPDESK_WEBHOOK_URL` | | optional; empty keeps requests in the database only |
| `HELPDESK_API_KEY` | | secret |
| `ALERT_TOPIC_ARN` | | SNS topic jobs publish owner alerts to |

- Secrets come from Secrets Manager as ECS secrets: `focus/<env>/apple-siwa-key`, `focus/<env>/appstore-key`, `focus/<env>/helpdesk-api-key` (plain PEM or string), and the RDS-generated secret (`username`, `password`, `host`, `port`, `dbname` mapped to the `PG*` variables).
- `FOCUS_ENV=local` uses local adapters with no AWS calls: a file object store under `LOCAL_DATA_DIR`, a local KMS (keys generated once into `LOCAL_DATA_DIR/keys.json`), an outbox mailer (`LOCAL_DATA_DIR/outbox/*.eml`, and the sign-in link and code printed to the log), and PGlite when `DATABASE_URL` starts with `pglite://`.

## Jobs

Same image, command `node dist/jobs/run.js <job>`. Scheduled by EventBridge Scheduler as ECS RunTask. Every job is idempotent and safe to run twice at once (row locks with `FOR UPDATE SKIP LOCKED`).

| Job | Schedule | Does |
|---|---|---|
| `process-store-notifications` | every 1 minute | processes stored App Store notifications not yet processed |
| `reconcile-app-store` | daily 03:00 Sydney | Get Notification History for the last 26 hours, fills gaps |
| `app-store-test-notification` | daily 03:10 Sydney | Request a Test Notification, alerts if none arrived in 48 hours |
| `process-deletions` | every 5 minutes | runs account deletions, retries Apple revocation, writes receipts, alerts past 24 hours |
| `retention` | hourly | the sweeps in the Retention table of 03-data-model.md |
| `dormant-accounts` | daily 04:00 Sydney | the 30-day notice at 23 months, deletion at 24 months |

## Wire formats

### General

- JSON, UTF-8, camelCase. Times are UTC ISO 8601 with milliseconds and `Z`, for example `2026-09-30T01:02:03.456Z`.
- Ids are lowercase hyphenated UUID strings. Server-made ids are UUIDv7.
- Binary is unpadded base64url unless a field says otherwise.
- `User-Agent: Focus/<version> (<build>; iOS <os>)` on every app request.
- Errors: `{"error":{"code":"SNAPSHOT_CONFLICT","message":"developer text","details":{},"retryAfterSeconds":30}}`. `retryAfterSeconds` only when useful. `RATE_LIMITED` also sends `Retry-After`.
- Creating POSTs accept `Idempotency-Key` (1 to 128 characters). Scope is the account (or device id, or IP hash when unauthenticated) plus method and route template. Same key and body within 24 hours replays the stored status and body; same key with another body is `IDEMPOTENCY_MISMATCH`.

### Tokens

- Access and refresh tokens: 32 random bytes, base64url (43 characters). Stored as SHA-256 hex. Sent as `Authorization: Bearer <access>`.
- `session` object: `{accessToken, accessExpiresAt, refreshToken, refreshExpiresAt}`.

### Device keys and proofs

- `deviceId`: a UUID made once at install and kept in the Keychain (this device only).
- `signingKey` and `agreementKey`: P-256 public keys as base64url of the 65-byte uncompressed X9.63 point (`0x04 || X || Y`), which is CryptoKit's `x963Representation`.
- The signing key is a Secure Enclave key when the phone has one (`SecureEnclave.P256.Signing.PrivateKey`), otherwise a software key in the Keychain. The agreement key is a software `P256.KeyAgreement.PrivateKey` in the Keychain (HPKE needs it).
- Proof headers on P and BP calls:
  - `X-Device-Id`: the device id.
  - `X-Device-Timestamp`: Unix time in whole seconds, decimal. Accepted within 300 seconds either way.
  - `X-Device-Signature`: ES256 over the UTF-8 bytes of the canonical string, as the 64-byte raw `r || s` (CryptoKit `rawRepresentation`, Node `dsaEncoding: 'ieee-p1363'`), base64url.
- Canonical string, four lines joined by `\n` with no trailing newline:
  1. the HTTP method in upper case
  2. the request path with the query string exactly as sent, including `/v1`, for example `/v1/keys/slots/0199...`
  3. the timestamp string from `X-Device-Timestamp`
  4. lowercase hex SHA-256 of the exact body bytes (the hash of the empty string when there is no body)
- The server also checks that the device belongs to the session's account (BP) or to the refresh token's session (P), and is not revoked.
- A proof can't be replayed: the server stores `(deviceId, signature)` for 10 minutes and refuses a repeat with `DEVICE_PROOF_INVALID`.

### Sign-in nonces

- Apple: the app makes `rawNonce` (32 random bytes, base64url), sets `request.nonce` to the lowercase hex SHA-256 of the UTF-8 bytes of `rawNonce`, and sends `rawNonce` to `POST /auth/apple`. The server checks `nonce` in the identity token equals that hex.
- Google: same `rawNonce` rule; the app sends the hashed hex as the `nonce` parameter of the authorization request, and the server checks the ID token's `nonce` equals it.

### Email links

- The app makes `linkVerifier` (32 random bytes, base64url) and keeps it in the Keychain; `linkChallenge` is base64url(SHA-256(UTF-8 bytes of `linkVerifier`)), like PKCE S256.
- Link token, base64url of 88 bytes: `id` (16, the magic link UUID) `|| expiresAt` (8, big-endian Unix milliseconds) `|| secret` (32 random) `|| mac` (32, HMAC-SHA256 with the magic link key over the first 56 bytes).
- Only SHA-256 of `secret` is stored (`secret_hash`). The 6-digit code is stored as HMAC-SHA256(key, `"code:" || id || ":" || code`) hex.
- The email link is `<PUBLIC_WEB_URL>/auth/email#t=<token>`; the app opens it as a universal link and reads `t` from the fragment.

### Snapshots (the server stores bytes it can't read)

- `POST /sync/snapshots` sends `sha256` as base64url of the SHA-256 of the whole encrypted object. The reply's `uploadHeaders` must be sent exactly: `Content-Type: application/octet-stream`, `x-amz-checksum-sha256: <standard padded base64 of the same digest>`, `x-amz-server-side-encryption: aws:kms`, `x-amz-server-side-encryption-aws-kms-key-id`, and `Content-Length`.
- Object key: `accounts/<accountId>/snapshots/<snapshotId>.fcs`.
- Local mode presigns to `PUBLIC_API_URL/v1/_local/objects/<key>?exp=<unix>&sig=<hmac>` and accepts `PUT` and `GET` there.

### Snapshot container `FCS1` (client only)

- Bytes: ASCII `FCS1`, a 4-byte big-endian header length, the header JSON (UTF-8, keys sorted, no spaces), then the AES-256-GCM ciphertext followed by the 16-byte tag.
- Header: `v` 1, `alg` `A256GCM`, `snapshotId`, `accountId`, `deviceId`, `epoch`, `schema`, `createdAt`, `wrappedDek` (ciphertext and tag of the 32-byte data key under the KEK), `dekNonce`, `nonce`, `paddedLength`.
- AAD: the data key wrap uses the UTF-8 bytes of `focus.dek.v1:<snapshotId>`; the payload uses the SHA-256 of the exact final header bytes.
- Plaintext before encryption: `u32be(compressedLength) || compressed || zero padding` up to the next multiple of 16,384 bytes. `compressed` is raw DEFLATE (`NSData.CompressionAlgorithm.zlib`) of the sync bundle JSON.

### Keys (client only, listed so every phone does the same)

- ARK: 32 random bytes per epoch.
- KEK: HKDF-SHA256(ikm ARK, salt UTF-8 of the lowercase account id, info `focus.kek.v1`, 32 bytes).
- Device slot: HPKE `P256_SHA256_AES_GCM_256`, base mode, recipient the device's agreement key, info UTF-8 of `focus.slot.v1:<accountId>:<epoch>`, plaintext the ARK. `enc` and `ciphertext` are base64url.
- Recovery key: 15 random bytes (120 bits), shown as 24 Crockford base32 characters in six groups of four joined by `-`. Parsing ignores case, spaces and dashes, and reads `O` as `0`, `I` and `L` as `1`.
- Recovery slot: AES-256-GCM under HKDF-SHA256(ikm the 15 bytes, salt UTF-8 of the lowercase account id, info `focus.recovery.v1`, 32 bytes), AAD UTF-8 of `focus.recovery.v1:<accountId>:<epoch>`, 12-byte `nonce`; `ciphertext` includes the tag.
- Transfer fingerprint: the first 16 bytes of SHA-256 of the new phone's 65-byte agreement key, shown as 8 groups of 4 hex characters. QR payload `focus-transfer:1:<transferId>:<fingerprint base64url>`.

## Config and copy signatures

- `GET /config` and `GET /copy/decks/{version}` bodies are signed with ES256 by the config signing key; the signature is the raw 64-byte `r || s` of SHA-256 over the exact body bytes, base64url, in the `Signature` header, with `Signature-Key-Id` naming the key (`config-2026-1` style).
- Signatures are made at publish time (`npm run publish-config`, `npm run publish-copy`), never per request. The app bundles the current and next public keys (base64url X9.63).

## Local development

- `cd backend/api && npm install && npm run dev` starts the API on 8080 with PGlite in `.data/`, local adapters and migrations applied.
- `POST /v1/_local/auth/session` (local only, 404 elsewhere) makes an account and session for a given device so the simulator can test without Apple, Google or email.
- The iOS Debug build uses `http://localhost:8080/v1` when `FocusAPIBaseURL` is set in the scheme; Info.plist allows local networking only (`NSAllowsLocalNetworking`).
