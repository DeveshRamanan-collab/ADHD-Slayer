# Backend

## Summary

- On-device first. The iPhone holds every plan, log and setting, and the app works fully with no network and no server.
- The server has four jobs: accounts, end-to-end encrypted backup for moving phones, a mirror of Apple subscription state, and signed config and copy updates.
- Status: nothing server-side is built. The app ships `LocalAuthBackend` (Account.swift), which makes a local account id and pretends the email link was tapped. Every server item here is To build unless marked Built.
- Hosting: AWS Sydney (ap-southeast-2), backup copies in Melbourne (ap-southeast-4). Entity fields: 03-data-model.md. Legal duties: 06-compliance-and-safety.md.

## Architecture

### What the server does

- Creates accounts and sessions from Sign in with Apple, Google or an email link.
- Stores encrypted snapshots it cannot read, plus sealed key slots only the person's devices can open, and helps a new phone get the key.
- Mirrors App Store subscription state; serves signed config, flags and copy.
- Takes opt-in anonymous crash reports and usage counts, and support messages.
- Deletes everything on request, backups and processors included, on a deadline.

### What the server never does

- Never sees medication, doses, check-ins, the focus pattern, tasks, calendar events, names or settings in plaintext, and never holds a key that could decrypt them.
- Never plans, learns or decides anything, never knows when doses are set, and never sends anything about medication or a condition.
- Never touches a bring-your-own-AI key, prompt or reply, and never receives calendar, Apple Health or location data.
- Never shares data with advertisers, brokers or analytics vendors. The app has no third-party SDKs.
- Never writes request bodies, tokens, emails or IP addresses to application logs.

### Data classes

| Class | What | Leaves the phone as |
|---|---|---|
| Health | medications, kinds of day, dose log and audit trail, check-ins, brain weather, focus pattern, personal windows | encrypted snapshot only |
| Planning and settings | tasks, outcomes, tuning, categories, Customise, name, own-AI settings without the key | encrypted snapshot only |
| Device only | calendar events, social suggestions, plans, API key, tokens, notification schedule | never |
| Account metadata | account id, sign-in identity and email, devices, consent versions, subscription state | plaintext on our server |
| Anonymous | crash reports, usage counts (opt-in) | scrubbed, never linked to an account |

### App network rules

- One `URLSession` for the API (no cookies, no cache); a separate ephemeral one for crash reports and usage counts that never carries a token.
- A host allowlist in code (`api.` and `cdn.focus.adhdslayer.au`, Apple and Google sign-in, the chosen AI host while connected). A test fails on any new host; "What leaves this phone" is generated from the same list.
- Server calls never block logging, planning or a screen. Failed writes retry after 2^n seconds with jitter, capped at 6 hours.
- TLS 1.2 minimum. No certificate pinning (outage risk); config and copy carry their own signatures.

## Accounts and sign-in

### Rules for every method

- The account is made at first launch after the 18+ toggle (Built UI). It powers encrypted backup and moving phones; deletion is in the app. Offline, the account step shows a calm retry.
- Sign-up sends only the provider credential, the device, `adultConfirmedAt` and the Terms, Privacy Policy and honest-bit versions; never a name, birth date or health data. The server keeps the provider subject, email and relay flag.
- One method per account at launch. If a new method's verified email matches an account, the app says "You already have an account with this email. Sign in the way you did before." Nothing merges; linking is Later.
- Email is transactional only and never names ADHD, a medicine or a condition.
- The app never signs out silently. When a session ends it keeps working and shows "Sign in again to keep your backup up to date."

### Sign in with Apple

- Capability `com.apple.developer.applesignin` (To build: no entitlements file yet). Scopes name and email (Built); the name stays on the phone. Register the sending domain with Apple's Private Email Relay so relay addresses get our emails.
- Client (To build): a 32-byte raw nonce, `request.nonce` set to its SHA-256 hex; send `identityToken`, `authorizationCode`, the raw nonce and `credential.user`.
- Server checks the identity token (RS256): signature against `https://appleid.apple.com/auth/keys` by `kid` (cached 24 hours); `iss` `https://appleid.apple.com`; `aud` `au.adhdslayer.focus`; `exp` future; `iat` within 10 minutes; `nonce` equals the SHA-256 hex of the raw nonce; `sub` equals the sent user. Reads `email`, `email_verified`, `is_private_email`.
- Code exchange at `https://appleid.apple.com/auth/token` (code single use, 5 minutes) with a client secret JWT made per call: ES256, `kid`, `iss` team id, `sub` bundle id, `aud` `https://appleid.apple.com`, 5-minute expiry. Apple's refresh token is kept, KMS encrypted, only to revoke.
- On account deletion: `POST https://appleid.apple.com/auth/revoke` with that token (`token_type_hint=refresh_token`); retry with backoff, and page the owner if it still fails after 24 hours.
- Server-to-server notices (`POST /webhooks/apple-id`, signed JWT): `consent-revoked` ends the identity's sessions; `account-delete` starts account deletion; `email-disabled` and `email-enabled` update the relay flag.
- At launch the app calls `getCredentialState(forUserID:)`; `.revoked` ends the local session and keeps local data.

### Google

- No Google SDK: OpenID Connect code flow with PKCE (S256) in `ASWebAuthenticationSession` (`prefersEphemeralWebBrowserSession = false`, so an existing Safari Google session can be picked).
- `https://accounts.google.com/o/oauth2/v2/auth` with `client_id` (Info.plist `GIDClientID`, Built check), `scope=openid email`, `state`, `nonce`, `code_challenge`, `prompt=select_account`, redirect on the reversed client id scheme (`CFBundleURLTypes`, To build).
- The app checks `state`, swaps the code at `https://oauth2.googleapis.com/token` with the verifier (no secret) and keeps only the ID token. No offline access, so no Google refresh token.
- Server checks: signature against `https://www.googleapis.com/oauth2/v3/certs`; `iss` `https://accounts.google.com` or `accounts.google.com`; `aud` our iOS client id; `exp`; `iat` within 10 minutes; `nonce`; `email_verified`. Subject is `sub`. Nothing to revoke at deletion.
- Setup (To build): Google Cloud project, OAuth consent screen, iOS client for `au.adhdslayer.focus`.

### Email magic links

- Start: `POST /auth/email/start` with the email, device id and `linkChallenge`, the SHA-256 of a random `linkVerifier` the app keeps in the Keychain. Always 202 with one body, so addresses can't be probed.
- Token: 16-byte id, 8-byte expiry, 32 random bytes and an HMAC-SHA256 over them (KMS key), base64url. Only the SHA-256 of the random part is stored; the HMAC rejects tampered or expired links before any database read.
- 15 minutes, single use; a newer link for the same email and device replaces older ones; spent rows purge within 24 hours.
- The email holds `https://focus.adhdslayer.au/auth/email#t=<token>` (a fragment never reaches server logs) and a 6-digit code (HMAC stored, 5 tries) for when the link opens elsewhere.
- Universal link `applinks:focus.adhdslayer.au`; `apple-app-site-association` served as JSON with no redirect, `appIDs` `<TeamID>.au.adhdslayer.focus`, component `/auth/email*`. In a browser the page says "Open this on the iPhone where you asked for it, or type the code in Focus."
- Verify: `POST /auth/email/verify` with token or code plus the verifier; a link tapped on another phone fails clearly. Marking used is one `UPDATE ... WHERE used_at IS NULL`, so a double tap can't make two sessions.
- SES Sydney, from "Focus" `signin@focus.adhdslayer.au`, subject "Your sign-in link for Focus", SPF, DKIM and DMARC, no open or click tracking. Bounces and complaints reach `POST /webhooks/email-events` and a suppression list. Addresses are trimmed and lowercased; dots and plus tags stay.
- Today "I've tapped the link" finishes locally (Built). To build: link handling, code entry, verifier.

### Sessions and devices

- Opaque 32-byte tokens, stored on the server as SHA-256. Access: 60 minutes, `Authorization: Bearer`. Refresh: rotates on each use; ends after 90 days unused or 365 days after sign-in.
- Each device registers a Secure Enclave P-256 key at sign-in. Refresh, deletion, key and device calls add a proof: `X-Device-Id`, `X-Device-Timestamp` (within 5 minutes) and `X-Device-Signature` (ES256 over method, path, timestamp and body SHA-256, newline joined).
- A reused refresh token ends the session; a 30-second grace returns the same pair to an exact retry. The app refreshes single flight, on `TOKEN_EXPIRED` or with under 2 minutes left. Every request checks the session row.
- Tokens sit in the Keychain, this device only, after first unlock, so they never move to another phone.
- Sign out: `POST /auth/logout`, then "Keep this iPhone's data" (default) or "Remove it". Another account can't sign in while this account's data is on the phone.
- Devices register at sign-in: id (made at install), model, OS and app versions, signing key and a P-256 agreement key. At most 10 per account. Removing one (Settings, Account, Devices; To build) ends its sessions, deletes its key slot and triggers key rotation.

## Encrypted backup and moving phones

### What goes in

- One snapshot holds the whole encrypted class: medications, kinds of day, dose log and audit trail, check-ins, brain weather, learned focus state, tasks and outcomes, personalisation, tuning, Customise, consents, the name, own-AI settings without the key.
- Never included: calendar data or anything read from it, plans, Health data, keys, tokens, notification schedules, device flags. Exact list: Sync bundle, 03-data-model.md.
- Backup runs once health consent exists and a key is set up; the consent wording names the encrypted copy. Settings, Account shows the last backup time.

### Key hierarchy

| Key | What it is | Where it lives |
|---|---|---|
| Account root key (ARK) | 256 random bits per key epoch | each device's Keychain (when unlocked, this device only); optional iCloud Keychain copy |
| Key-encryption key | HKDF-SHA256(ARK, salt account id, info "focus.kek.v1") | memory only |
| Data key | 256 random bits per snapshot | wrapped by the KEK in the snapshot header |
| Device agreement key | P-256 pair per device | private in the Keychain, public on the server |
| Device slot | ARK sealed with HPKE `P256_SHA256_AES_GCM_256` to one device | server |
| Recovery slot | ARK sealed with AES-256-GCM under HKDF-SHA256(recovery key, salt account id, info "focus.recovery.v1") | server |
| Recovery key | 120 random bits: 24 Crockford base32 characters in six groups | only the person |

- The server holds only slots it can't open.
- The iCloud Keychain copy (synchronizable item, service `au.adhdslayer.focus.escrow`) is on by default, explained plainly and switchable in Settings, Account. It is a key, not health information, and iCloud Keychain is end-to-end encrypted.
- The recovery key is shown once with Copy and "Save as PDF to Files", never stored, and at 120 random bits needs no password stretching.

### Snapshot format and uploads

- Plaintext: the sync bundle as JSON, zlib compressed, zero padded to the next 16 KiB. Container: `FCS1`, 4-byte header length, header JSON, AES-256-GCM ciphertext and tag.
- Header: `v`, `alg` `A256GCM`, `snapshotId`, `accountId`, `deviceId`, `epoch`, `schema`, `createdAt`, `wrappedDek`, `dekNonce`, `nonce`, `paddedLength`. The AAD is the SHA-256 of the exact header bytes. Random 96-bit nonces under a fresh data key per snapshot.
- Limits: 10 MB per snapshot, 50 MB per account with versions.
- Upload 2 minutes after the last change, at most every 10 minutes, and on backgrounding with unsent changes: start, PUT to a presigned S3 URL with a SHA-256 checksum, commit with `baseVersion`. The ciphertext uses a background `URLSession`, so uploads finish after the app closes.
- Kept: the newest 10 commits, none older than 30 days except the newest; "Restore an earlier backup" in Settings (To build).
- `schema` versions the bundle; apps keep every decoder they ever shipped, and a newer schema is never partly read ("Update Focus to bring your data over."). Phones warn if offered a version lower than one they have seen.

### Conflicts

- Commit returns `SNAPSHOT_CONFLICT` if another device got there first: download, merge, upload again. Every record carries a hybrid logical clock value and the last device to change it.
- Dose events, audit entries, check-ins, brain weather and consents are facts: union by id. Two logs of one medication inside its re-log guard, from two phones, both stay and show once: "Two logs close together, from two phones. Keep both?"
- Medications, kinds of day, categories, tasks: newest change wins per record. If both phones changed a medication's strength, kind or dose times, a card says "This was changed on two phones. Check it's right."
- Customise, personal windows and tuning: newest change wins per field. The learned focus state is rebuilt from merged check-ins, never averaged.
- Deletes are tombstones (id and time) kept 90 days; a later edit elsewhere brings the record back and says so. A phone unsynced over 90 days restores the latest snapshot and re-applies only its own newer records, for review.
- Later, only with a second live device type: encrypted change batches between snapshots (endpoints reserved).

### Restore on a new phone

- Sign in with the same method; the reply carries `backup.exists`, epoch and version. Key sources in order: the iCloud Keychain copy, "Use your old iPhone", "Type your recovery key".
- Key transfer: the new phone registers its agreement key and shows a QR with the transfer id and the key's fingerprint (first 16 bytes of its SHA-256). The old phone scans, fetches the key, checks the fingerprint, seals the ARK with HPKE and uploads it; the new phone polls every 2 seconds for 10 minutes. The fingerprint stops the server swapping in its own key.
- Download the newest snapshot, check its hash, decrypt, validate every record and import into an empty store in one transaction; nothing is written unless all of it succeeds.
- Then upload this phone's slot, ask again for calendar and notifications, and schedule local notifications. Own AI stays off until its key is pasted again.
- No key: "Start fresh" explains the old backup can't be opened, offers to delete it, and starts a new epoch.
- An iCloud or computer restore brings settings but no health data. If `onboarded` is set and the health store is missing, the app opens on "Welcome back. Sign in to bring your data back."

### Key rotation

- After removing a device, a suspected leak, or on request: an unlocked enrolled device makes a new ARK, uploads slots for every remaining device in one call, commits a new-epoch snapshot, updates the iCloud copy and asks the person to save a new recovery key.
- Old-epoch snapshots are deleted after the first new-epoch commit; devices keep old ARKs 30 days for anything in flight.

### Never in iCloud, never in device backup

- Built: `medication.json` uses `.completeFileProtection` and gets `isExcludedFromBackup` after every atomic write. To build: the same for the dose log, audit trail, check-ins and learned model, checked at each launch.
- Complete protection locks the store while the phone is locked, so "Log my meds" requires authentication (Built) and widgets read only the App Group glance file, with no medicine names in discreet mode.
- No iCloud capability at all; a release check fails the build if the entitlement appears. To build: move `tuning` and `personalisation` (measured from the first dose) out of UserDefaults into the protected store.

## Subscriptions and entitlements

### Principle

- The phone decides what's unlocked from StoreKit 2 (`currentEntitlements`, `Transaction.updates`; Built). The server mirrors state for support and reconciliation; no feature waits on it.
- Products (Built in `Products.storekit`): `au.adhdslayer.focus.plus.monthly` and `.yearly`, group "Focus Plus", a free 1-month introductory offer on both, not family shareable, test prices A$7.99 and A$59.99.
- App Store Connect (To build): the products, Billing Grace Period 16 days, Small Business Program, existing subscribers keep their price when prices rise.

### Server notifications (V2)

- Production and sandbox URLs both point at production `POST /webhooks/app-store` (TestFlight purchases are sandbox); rows record `environment`.
- Verify `signedPayload`, `signedTransactionInfo` and `signedRenewalInfo` with Apple's App Store Server Library (`SignedDataVerifier`): x5c chain to the bundled Apple Root CA G3, Apple certificate OIDs, ES256, `bundleId`, `appAppleId`, `environment`, online revocation checks.
- Store by `notificationUUID` (unique), reply 200, process from a queue; duplicates are ignored.

| Notification | Effect |
|---|---|
| `SUBSCRIBED`, `OFFER_REDEEMED` | link the transaction; trial or active |
| `DID_RENEW` | active, new expiry; `BILLING_RECOVERY` clears retry |
| `DID_CHANGE_RENEWAL_STATUS`, `DID_CHANGE_RENEWAL_PREF` | record auto-renew and the next product |
| `DID_FAIL_TO_RENEW` | `GRACE_PERIOD` subtype: grace; else billingRetry |
| `GRACE_PERIOD_EXPIRED`; `EXPIRED` | billingRetry; expired with subtype |
| `REFUND`, `REVOKE` | revoked, with reason and date |
| `REFUND_DECLINED`, `REFUND_REVERSED`, `PRICE_INCREASE`, `RENEWAL_EXTENDED`, `RENEWAL_EXTENSION`, `TEST` | recorded |
| `CONSUMPTION_REQUEST` | ignored; no usage data ever goes to Apple |

- Unknown types are stored and ticketed, never errored.

### Server API, linking and states

- App Store Server API JWT: ES256 with our In-App Purchase key, `kid`, `iss` issuer id, `aud` `appstoreconnect-v1`, `bid` bundle id, 15-minute expiry. Hosts `api.storekit.itunes.apple.com` and `api.storekit-sandbox.itunes.apple.com`.
- Calls: Get All Subscription Statuses after the app posts a transaction; Get Notification History (catches anything Apple's retries missed) and Request a Test Notification daily; Get Transaction History for support. Back off on 429.
- The app sends the account id as `appAccountToken` (Built) and posts `Transaction.jwsRepresentation` to `POST /entitlements/transactions` after a purchase, restore or changed entitlement, linking `originalTransactionId` to the account.
- A purchase belongs to the Apple ID: if two accounts present one `originalTransactionId`, the newest gets the link, audited.

| Status | From Apple | The app shows |
|---|---|---|
| none | never subscribed | Free |
| trial | active, free introductory offer | "Free trial until 30 Oct" (Built) |
| active | active, paid | "Plus, renews 12 Mar" (Built) |
| grace | status 4 | Plus, with a calm "Update your payment details" line opening Manage subscription |
| billingRetry | status 3 | Free, same line |
| expired, revoked | status 2, 5 | "Free (Plus ended)" |

- Lapsing never deletes or disables anything made; only adding past the free limits is blocked (Built). To build: grace and retry from `Product.SubscriptionInfo.Status`; "Request a refund" with `refundRequestSheet`.

### Trial-ending reminder

- Local, not pushed: 10:00 local, 2 days before `expirationDate`, passive, id `trial-ending` (Built for in-app purchases).
- It names the day, the price after the trial and where to cancel, never a condition: "Your free month ends Friday. Plus is then A$7.99 a month. Keep it or cancel in Settings, both are fine."
- To build: the price and period from StoreKit; scheduling for any active trial without one; cancelling when auto-renew is off; a quiet Home line for the last 2 days if notifications are off. No trial emails.

## Config, flags and copy

- `GET /config` via CloudFront, no account or device id; fetched at launch when older than 6 hours, 5-second timeout, never blocking a screen.
- Signed ES256 by a KMS key (`Signature` header). The app holds the current and next public keys and rejects bad signatures, expired configs and older versions.
- Contents: `version`, `issuedAt`, `expiresAt`, `minimumAppVersion`, `flags`, `killSwitches`, `copy` (deck version and hash), optional neutral `notice`.
- Flags only switch shipped code. They never change medication logic, the double-dose guard, safety or legal text, crisis numbers or compiled rules. Rollout buckets (0 to 99) are made on the phone and never sent.
- Kill switches: Google sign-in, email links, backup uploads, each own-AI provider, remote copy. Bundled `DefaultConfig.json` keeps everything working without config. Below `minimumAppVersion` the API answers 426 and the app works locally ("Update Focus when you can.").
- Copy: `Copy.json` ships 65 slots of 100 `{t, f}` variants (Built). Updates are whole signed decks (`GET /copy/manifest`, `GET /copy/decks/{version}`), saved in `Application Support/Copy/` and switched in at next launch, so a line never changes mid-day.
- The phone re-checks each variant with the `docs/copy/merge.py` rules: no em or en dash or spaced hyphen; within `maxCharacters`; each placeholder exactly once, no others; none of `due`, `onset`, `wear off`, `booster`, `predict`, `optimal`; no funny variant in a serious slot; no duplicates. A slot changes only if 20 or more pass.
- Serious slots (`accountBody`, `coachMeds`, `medsNothingDue`, `medsNone`, `dayLineRoutine`, `rhythmFooter`, `detailWindow`) change only in app releases. Buttons, legal and safety text aren't in the deck.

## Push notifications

- None at launch: no push entitlement, no device tokens. Local notifications carry every nudge, user-set medication reminder and the trial reminder, offline too. Pushing around someone's day would need the server to know their schedule, which is health information.
- Live Activities past 8 hours chain with a locally scheduled start. Later, only with multi-device sync: one content-free background push ("new snapshot"), at most 3 an hour per device.

## Crash reporting

- Opt-in "Share crash reports" in Settings, Privacy, off by default; after a crash the app asks once, "Focus crashed earlier. Send a report? It has no personal details.", with equal buttons.
- MetricKit `MXDiagnosticPayload` only; no third-party SDK. Scrubbed on the phone to stack frames (binary UUID, offset, address), exception type, code, signal, app version, build, OS, model and the hour; every other string dropped, then a pass strips the person's medication names, strengths, task titles and email.
- `POST /diagnostics/crashes` with a random id rotated every 90 days, never an account, device id or token. Kept 90 days in Sydney, symbolicated in CI. The privacy label then adds Crash Data, not linked.

## Usage analytics

- To build after launch, opt-in, off by default: a switch in Settings, Privacy, and one quiet card after 7 days with equal "Share" and "No thanks". Never in onboarding.
- Daily counters from a fixed allowlist, sent once a day (up to 7 days of backlog), then deleted on the phone: app version, OS, device family, locale, region, Apple Intelligence state, days active, bucketed sessions, tabs opened, onboarding step, coach marks skipped, Fix my day and focus mode used, priorities source, Customise options changed (names only), backup and restore success, permission states, own AI connected (yes or no).
- Pages viewed only where no medication or health data shows: `now`, `restOfToday`, `shapes`, `ifChanges`, `tinyWins`, `breathe`, Plan pages, `rhythmIntro`, `planDone`, `finishHours`, `estimates`, `tune`, `youMore`.
- Never: medication, logging, check-ins, brain weather, the focus window, sleep, kinds of day, task text, calendar, support or crisis screens, times of day, own AI content.
- A random id rotated every 90 days, no account or device id, IPs dropped at the edge. Raw batches 30 days, aggregates 25 months, cells under 20 installs hidden. The privacy label then adds Product Interaction, not linked.

## Support

- Settings, Support, Contact us (To build): a form and `support@focus.adhdslayer.au`; FAQ at `focus.adhdslayer.au/support`.
- Form: topic, message up to 4,000 characters, reply email, and "Include app details" (on, showing exactly what goes: versions, model, locale, Apple Intelligence state, last backup time and error, subscription status). It says "Please leave medication details out. We don't need them to help."
- `POST /support/requests` stores it with message and email KMS encrypted and forwards it to a helpdesk hosted in Australia under a data processing agreement (To decide). The auto-reply includes "If you're not safe right now, call 000 or Lifeline on 13 11 14."
- Staff answer within 2 business days, give medication questions "That's one for your prescriber or pharmacist.", send refunds to Apple, and never ask for health details. Kept 24 months after the last message.

## Export and deletion

### Export

- Settings, Your data, Export everything, offline (Built: JSON of medications, kinds of day, personalisation, tuning, today's dose times).
- To build: a ZIP with `focus.json` (every entity, schema version), `dose-log.csv` (date, time taken, time logged, medication, strength, kind, source, ate first, edited), `check-ins.csv` and `account.json` from `GET /account/export`. Plain field names ("Short-acting", never `booster`).
- Warning first: "This file has your medication details in it. Share it only with people you trust." Complete protection; deleted when the share sheet closes or at next launch. Email access requests: free, within 30 days.

### Deleting an account

- Settings, Account, Delete my account (Built: two confirmations, subscription note; today server errors are ignored). To build: Face ID or passcode, export offered, then the steps below.
- Phone: `DELETE /account` with a device proof; on 202 wipe the health store, UserDefaults, every Keychain item (iCloud copy too), App Group files and pending notifications. Offline, keep a `pendingDeletion` marker and retry each launch ("Deletion will finish when you're back online.").
- Server at once: mark `deleting`, end sessions, refuse sign-in. Within 1 hour: revoke the Apple token, delete every S3 object version and account row, delete helpdesk records by API, write a receipt (keyed hash of the account id and times).
- Deadlines: live systems 24 hours (alert if later); database backups and old S3 versions 35 days; helpdesk backups 30 days by contract. Restores replay receipts before traffic returns.
- Also: Delete my backup keeps the account (`DELETE /sync`, To build). Delete everything on this iPhone (Built) leaves the server alone and says so. Dormant accounts (24 months) get an email 30 days before deletion. A shutdown gives at least 90 days' notice; the app keeps working and export stays.

## Bring your own AI

- Calls go straight from the phone to the provider (`api.openai.com`, `api.anthropic.com` or the person's HTTPS endpoint) with the Keychain key (Built). Our backend is not in the path.
- The backend must never proxy, relay, cache or rewrite these calls; offer its own AI endpoint; receive, store, log, sync or escrow the key; see prompts, context or replies; receive task names or times for AI use; or learn more than, with analytics consent, "own AI connected: yes or no".
- Config can switch a provider off but never point the app at another host. Replies pass the SafetyGate on the phone (Built).
- To build on the phone: send calendar items only as "Appointment" with times (today, allowing task names also sends calendar titles), and replace titles containing the person's medication names or strengths with "Task".

## Hosting and infrastructure

### Stack

| Part | Choice | Notes |
|---|---|---|
| API | TypeScript, Node.js 24 LTS, Fastify, zod | stateless; 2 ECS Fargate tasks (0.25 vCPU, 0.5 GB), 2 zones |
| Database | PostgreSQL 17 or newer, RDS Multi-AZ, KMS | point-in-time recovery 35 days |
| Objects | S3, versioned, SSE-KMS, public access blocked | snapshots, crash reports |
| Edge | ALB with AWS WAF; CloudFront | config, copy, website |
| Email, jobs | SES Sydney; EventBridge Scheduler with ECS tasks | queue, reconciliation, deletion, retention sweeps |
| Code, DNS | AWS CDK in TypeScript; Route 53 with DNSSEC | `focus.adhdslayer.au`, `api.`, `cdn.` |

- Apple and Google calls leave through one NAT gateway; AWS services use VPC endpoints. Sub-processors (AWS, Apple, Google, the helpdesk) are listed in the Privacy Policy. Copy may say "our servers are in Sydney", never "stays in Australia".

### Environments and delivery

| Environment | Use | Apple setup | Data |
|---|---|---|---|
| local | development | Xcode StoreKit testing, `Products.storekit` | synthetic |
| staging | QA, end-to-end tests | separate app record `au.adhdslayer.focus.staging` with its own products and URLs | synthetic only |
| production | App Store and TestFlight | both notification URLs | real |

- One AWS account per environment; production access by SSO with MFA and a logged break-glass role. Debug builds use local or staging, Release uses production.
- GitHub Actions reaches AWS by OIDC. Pull requests: lint, type check, unit and integration tests (Postgres, local S3), migration lint, OpenAPI contract tests, dependency, secret and container scans, SBOM.
- Main: image tagged with the commit, staging deploy, smoke tests (email sign-in against a staging inbox, snapshot round trip, App Store test notification), manual approval. Production: migrations first, ECS rolling deploy with circuit breaker, rollback if the 5xx alarm fires within 15 minutes. Migrations are forward only, expand then contract.
- App: build, `swift test` for FocusCore (31 pass), UI tests, TestFlight upload by App Store Connect API key, 7-day phased release.

### Monitoring and logging

- Page the owner: 5xx above 2% for 5 minutes; `/healthz` failing externally for 3 minutes; any webhook or transaction signature failure; over 5 App Store webhook errors in 15 minutes; a deletion older than 24 hours or Apple revocation failing 24 hours; database storage under 20%, failover or a high GuardDuty finding; KMS or secret access denied.
- Next-day ticket: p95 over 800 ms for 30 minutes; SES bounces over 2% or complaints over 0.05%; no App Store notification (daily test included) for 48 hours; a failed backup copy; a critical advisory; over 2,000 emails an hour.
- External checks every 5 minutes. Target 99.5% monthly; the app never depends on it.
- Logs: structured JSON, allowlisted fields only (time, level, request id, route template, method, status, latency, error code, account id, device id, app version), kept 30 days. Never bodies, tokens, emails, JWS payloads or support messages. IPs only in WAF and load balancer logs, 14 days.
- Audit log (database, 24 months): sign-ins, refresh reuse, device changes, key epochs, recovery slot reads, deletions, staff access.

### Backups, keys and secrets

- RDS point-in-time recovery 35 days; AWS Backup copies daily to Melbourne, kept 35 days; S3 noncurrent versions expire at 35 days and replicate to Melbourne. At most 5 minutes lost, back within 4 hours. Quarterly drill: restore to scratch, replay receipts, decrypt a test account's snapshot.
- KMS keys per environment: `rds`, `s3` (yearly rotation); `app-envelope` (Apple refresh tokens, support text, reply emails); `magic-link-hmac`, `receipt-hmac`; `config-signing` (P-256, next public key ships a release early). Least-privilege task roles, CloudTrail on every use. No server key can open a person's data.
- Secrets Manager holds the Apple .p8 keys (Sign in with Apple, App Store Server API) and database credentials (rotated every 30 days), each with a rotation runbook. Nothing secret in the repo, CI logs or app bundle; secret scanning blocks merges; access ends the day someone leaves.

### Rate limits and abuse

| What | Limit | Keyed by |
|---|---|---|
| Email link start | 3 per 15 minutes and 10 a day; 5 an hour; 20 an hour | email; device; IP |
| Email link verify | 10 per 15 minutes; 5 code tries | device; link |
| Apple or Google sign-in | 10 an hour; 20 an hour | device; IP |
| Refresh | 60 an hour | session |
| Snapshot start; download | 30 an hour; 120 a day | account |
| Recovery read; key transfer | 10 a day; 10 an hour | account |
| Delete account; support | 3 a day; 5 a day | account or IP |
| Crash reports; usage batches | 20 a day; 3 a day | their random ids |
| Anything | 2,000 per 5 minutes | IP at the WAF |

- 429 with `Retry-After`; dropped email starts still get the normal 202. WAF managed rules: core, bad inputs, IP reputation. Bodies 64 KB unless stated. Later: App Attest at registration and email start, tightening limits rather than blocking.

## Incidents and breaches

- SEV1 personal information exposed or all down; SEV2 a feature down; SEV3 degraded. First hour: confirm, contain (revoke keys or sessions, block routes, kill switches), keep evidence.
- Notifiable Data Breaches scheme (Privacy Act 1988, Part IIIC):
  - Assess a suspected breach fast: aim for 72 hours, never over 30 days.
  - Eligible breach (access, disclosure or loss likely to cause serious harm, not prevented by fixing it in time): notify the OAIC with the statement and tell affected people as soon as practicable, by email and an in-app card; publish on the website if contacting them isn't practicable.
  - Exposed account emails or tokens count as likely serious harm, because an account here suggests a health condition. Ciphertext alone is still assessed and recorded.
- US users: FTC Health Breach Notification Rule, people within 60 days, the FTC too at 500 or more.
- A breach register holds every incident; reviews within 14 days. Contacts kept current: owner, privacy lawyer, AWS, Apple key revocation, cyber insurer. Yearly tabletop; independent security test before launch and yearly.

## Costs to watch

| Item | Rough cost (AUD) | Watch for |
|---|---|---|
| Fargate, load balancer, WAF | 70 to 100 a month | WAF request charges |
| RDS Multi-AZ, small | 60 to 90 a month | Multi-AZ doubles it |
| NAT gateway | 60 to 80 a month | biggest fixed item; use VPC endpoints |
| S3, CloudFront, Route 53, SES | under 25 a month at 10,000 people | snapshot versions; keep the debounce |
| KMS, secrets, CloudWatch | 20 to 60 a month | never call KMS per request; log volume |
| Helpdesk | 20 to 60 a month | seats |
| Apple Developer Program | 149 a year | |
| Security test; cyber insurance | 8,000 to 20,000; 1,000 to 3,000 a year | the largest costs |

- AWS estimate: A$250 to 350 a month at launch, A$400 to 600 at 10,000 people, A$800 to 1,200 at 50,000. Apple keeps 15% (Small Business Program); after GST, A$7.99 nets about A$6.17 and A$59.99 about A$46.36.
- AI costs us nothing: Apple Intelligence runs on the phone and own AI is billed to the person.

## API

### Conventions

- Base `https://api.focus.adhdslayer.au/v1` (staging `api.staging.focus.adhdslayer.au`). JSON, UTF-8, camelCase; UTC ISO 8601 times; UUIDs (server-made are UUIDv7); binary as unpadded base64url.
- Auth column: N none; B `Authorization: Bearer`; P device proof; BP both; W webhook signature. Every call sends `User-Agent: Focus/<version> (<build>; iOS <os>)`; authenticated replies carry `Cache-Control: no-store`.
- Creating POSTs take `Idempotency-Key`; key, body hash and reply are kept 24 hours. PUT and DELETE are idempotent.
- Errors: `{"error": {"code": "SNAPSHOT_CONFLICT", "message": "developer text", "details": {}, "retryAfterSeconds": 30}}`. The app shows its own calm copy, never `message`.
- Any endpoint may return `VALIDATION_ERROR`, `RATE_LIMITED` (with `Retry-After`), `UPGRADE_REQUIRED` and `INTERNAL`; B and BP ones also `UNAUTHENTICATED`, `TOKEN_EXPIRED` and `SESSION_REVOKED`.
- One version, `/v1`. New fields are optional; clients ignore unknown fields and read unknown enum values as `unknown`.

```
device      {deviceId, model, osVersion, appVersion, signingKey, agreementKey}
session     {accessToken, accessExpiresAt, refreshToken, refreshExpiresAt}
consents    {termsVersion, privacyVersion, noticeVersion, adultConfirmedAt}
signIn      {accountId, isNewAccount, session, identity {provider, email, isPrivateRelay},
             backup {exists, epoch, version, updatedAt}}
entitlement {status, productId, expiresAt, willAutoRenew, isTrial, graceExpiresAt, environment}
```

### Error codes

| Code | HTTP | When | The app |
|---|---|---|---|
| VALIDATION_ERROR | 422 | schema check failed | report, no retry |
| UNAUTHENTICATED, TOKEN_EXPIRED | 401 | no or expired token | refresh once, retry |
| SESSION_REVOKED | 401 | session ended | sign-in line; local use continues |
| DEVICE_PROOF_INVALID | 401 | proof missing, skewed or wrong | check clock, retry once |
| DEVICE_REVOKED | 401 | device removed | stop syncing; offer sign-in |
| FORBIDDEN, NOT_FOUND | 403, 404 | not this account's, or missing | per endpoint |
| PROVIDER_TOKEN_INVALID, NONCE_MISMATCH | 401 | Apple or Google token failed | "That sign-in didn't work. Try again?" |
| ADULT_CONFIRMATION_REQUIRED | 422 | no 18+ confirmation | back to the toggle |
| LINK_INVALID; CODE_ATTEMPTS_EXCEEDED | 410; 429 | link expired, used or replaced; 5 wrong codes | offer a new link |
| LINK_WRONG_DEVICE | 403 | verifier mismatch | "Open it on the iPhone where you asked for it." |
| ACCOUNT_DELETION_PENDING | 409 | account being deleted | show `completesBy` |
| SNAPSHOT_CONFLICT | 409 | another device committed first | download, merge, upload |
| EPOCH_MISMATCH | 409 | key epoch changed | fetch keys, retry |
| UPLOAD_INCOMPLETE, CHECKSUM_MISMATCH | 409, 422 | S3 object missing or wrong | upload again once |
| TRANSFER_EXPIRED, TRANSFER_ALREADY_SEALED | 410, 409 | over 10 minutes; sealed twice | start again; ignore |
| SEQ_CONFLICT, SEQ_GAP | 409 | batch order (Later) | resend from `expectedSeq` |
| IDEMPOTENCY_MISMATCH | 422 | key reused with another body | new key, report |
| PAYLOAD_TOO_LARGE, QUOTA_EXCEEDED | 413 | over size or 50 MB | report; drop old versions |
| JWS_INVALID | 422 | transaction failed checks | ignore; StoreKit stays the truth |
| UPSTREAM_UNAVAILABLE, SERVICE_PAUSED | 503 | Apple or Google down; kill switch | back off; quiet notice |
| RATE_LIMITED; UPGRADE_REQUIRED | 429; 426 | over a limit; app too old | wait `Retry-After`; local only |
| INTERNAL | 500 | server fault | 2^n seconds with jitter, up to 6 hours |

### Sign-in, account and devices

| Endpoint | Auth | Request | Response | Errors; retries |
|---|---|---|---|---|
| `POST /auth/apple` | N | identityToken, authorizationCode, rawNonce, appleUserId, device, consents | 200 signIn | PROVIDER_TOKEN_INVALID, NONCE_MISMATCH, ADULT_CONFIRMATION_REQUIRED, ACCOUNT_DELETION_PENDING, UPSTREAM_UNAVAILABLE; same token in 5 minutes, same session |
| `POST /auth/google` | N | idToken, rawNonce, device, consents | 200 signIn | as Apple |
| `POST /auth/email/start` | N | email, deviceId, linkChallenge | 202 resendAfterSeconds 60, expiresInSeconds 900, same for every address | SERVICE_PAUSED; repeats within 60 seconds send nothing |
| `POST /auth/email/verify` | N | token, or email and code; linkVerifier, device, consents | 200 signIn | LINK_INVALID, LINK_WRONG_DEVICE, CODE_ATTEMPTS_EXCEEDED, ADULT_CONFIRMATION_REQUIRED, ACCOUNT_DELETION_PENDING; same token in 60 seconds, same session |
| `POST /auth/refresh` | P | refreshToken | 200 session | SESSION_REVOKED, DEVICE_REVOKED, DEVICE_PROOF_INVALID; exact retry in 30 seconds, same pair |
| `POST /auth/logout` | B | | 204 | idempotent |
| `GET /account` | B | | 200 accountId, createdAt, status, identities, deviceCount, consents, entitlement, backup | |
| `PUT /account/consents/{kind}` | B | kind terms, privacy or notice; version, acceptedAt | 204 | VALIDATION_ERROR for older versions |
| `GET /account/export` | B | | 200 account, identities, devices, sessions, consents, entitlement, transactions, snapshot list, support requests | |
| `DELETE /account` | BP | confirm "DELETE" | 202 status deleting, completesBy | DEVICE_PROOF_INVALID; repeats return the same completesBy |
| `GET /devices` | B | | 200 devices: id, model, appVersion, enrolledAt, lastSeenOn, isCurrent, hasKeySlot | |
| `PUT /devices/current` | BP | model, osVersion, appVersion | 204 | DEVICE_REVOKED; keys change only by signing in again |
| `DELETE /devices/{deviceId}` | BP | reason: lost, replaced or other | 204; rotation required | NOT_FOUND, FORBIDDEN |

### Keys, backup and sync

| Endpoint | Auth | Request | Response | Errors; retries |
|---|---|---|---|---|
| `GET /keys` | BP | | 200 epoch, rotationRequired, mySlot (epoch, enc, ciphertext) or null, recovery (epoch, exists) | |
| `PUT /keys/slots/{deviceId}` | BP | epoch, enc, ciphertext | 204 | EPOCH_MISMATCH, NOT_FOUND, DEVICE_REVOKED |
| `PUT /keys/recovery` | BP | epoch, nonce, ciphertext | 204 | EPOCH_MISMATCH |
| `GET /keys/recovery` | BP | | 200 epoch, nonce, ciphertext | NOT_FOUND; 10 a day, each read audited |
| `POST /keys/epochs` | BP | fromEpoch, toEpoch, slots (deviceId, enc, ciphertext), optional recovery | 201 epoch | EPOCH_MISMATCH; VALIDATION_ERROR if a removed device has a slot or an active one lacks one; atomic |
| `POST /key-transfers` | BP (new phone) | agreementKey | 201 transferId, expiresAt | |
| `GET /key-transfers/{id}` | BP | | 200 state (waiting, sealed, done, expired), requesterDeviceId, agreementKey, sealed (requester only, once) | NOT_FOUND, TRANSFER_EXPIRED |
| `PUT /key-transfers/{id}/sealed` | BP (holder of current key) | epoch, enc, ciphertext | 204 | TRANSFER_EXPIRED, TRANSFER_ALREADY_SEALED, EPOCH_MISMATCH |
| `GET /sync/state` | B | | 200 version, snapshotId, epoch, rotationRequired, updatedAt, usedBytes, quotaBytes | |
| `POST /sync/snapshots` | B | snapshotId, baseVersion, epoch, schema, sizeBytes, sha256 | 201 uploadUrl, uploadHeaders, expiresAt (15 minutes) | PAYLOAD_TOO_LARGE, QUOTA_EXCEEDED, EPOCH_MISMATCH, SERVICE_PAUSED; same id gives a fresh URL |
| `POST /sync/snapshots/{id}/commit` | B | | 200 version, committedAt | UPLOAD_INCOMPLETE, CHECKSUM_MISMATCH, SNAPSHOT_CONFLICT (currentVersion); recommit returns the same version |
| `GET /sync/snapshots` | B | | 200 snapshots: id, version, epoch, schema, sizeBytes, createdAt, deviceId | |
| `GET /sync/snapshots/{id}` | B | | 200 downloadUrl (5 minutes), sizeBytes, sha256, version, epoch, schema | NOT_FOUND |
| `DELETE /sync` | BP | | 204; snapshots gone, key slots kept | |
| `POST /sync/batches` (Later) | B | deviceId, seq, epoch, schema, nonce, ciphertext (1 MB), aadHash | 201 cursor, duplicate | SEQ_CONFLICT, SEQ_GAP (expectedSeq); idempotent by device and seq |
| `GET /sync/batches?after=&limit=100` (Later) | B | | 200 batches, nextCursor, hasMore | |

### Subscriptions, config, diagnostics and support

| Endpoint | Auth | Request | Response | Errors; retries |
|---|---|---|---|---|
| `GET /entitlements` | B | | 200 entitlement | |
| `POST /entitlements/transactions` | B | signedTransaction (`jwsRepresentation`) | 200 entitlement | JWS_INVALID, VALIDATION_ERROR (another bundle), UPSTREAM_UNAVAILABLE; idempotent by transaction id |
| `GET /config?appVersion=&build=&locale=&region=` | N | | 200 signed JSON; ETag, Signature, `max-age=3600` | the app keeps its last good config |
| `GET /copy/manifest` | N | | 200 version, sha256, sizeBytes, minAppVersion, url (signed) | |
| `GET /copy/decks/{version}` | N | | 200 deck, signed, immutable | NOT_FOUND |
| `POST /diagnostics/crashes` | N, no token | reportId, diagnosticsId, appVersion, build, osVersion, model, kind, payload (256 KB) | 202 | fields outside the allowlist rejected; idempotent by reportId |
| `POST /analytics/batches` | N, no token | batchId, analyticsId, day, versions, deviceFamily, locale, region, aiState, counters | 202 | unknown counters rejected; idempotent by batchId |
| `POST /support/requests` | B, or N with replyEmail | topic, message (4,000 characters), replyEmail, diagnostics | 201 reference | Idempotency-Key |
| `POST /attest/challenge` (Later) | N | | 200 challenge, expiresAt | |

### Webhooks, health and web

| Endpoint | Auth | Request | Response | Retries |
|---|---|---|---|---|
| `POST /webhooks/app-store` | W: Apple JWS | signedPayload | 200 once stored; 400 on a bad signature | duplicates ignored by notificationUUID |
| `POST /webhooks/apple-id` | W: Apple JWT | payload | 200 | duplicates ignored by type, subject and time |
| `POST /webhooks/email-events` | W: SNS signature v2 | subscription confirmation, bounce or complaint | 200 | idempotent by MessageId |
| `GET /healthz` (outside `/v1`) | N | | 200 status ok, nothing else | |

- Static on `focus.adhdslayer.au`: `/.well-known/apple-app-site-association`, `/auth/email`, `/privacy`, `/terms` (both linked today), `/support`.
