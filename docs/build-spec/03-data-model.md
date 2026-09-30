# Data model

## How to read this

- Every entity lists its fields, where it lives, its sync class and how long it is kept. Built means it exists in the code today; To build means it doesn't yet.
- Sync classes: E2E travels only inside the end-to-end encrypted snapshot (02-backend.md); Plain is plaintext account metadata on our server; Device never leaves the phone.

| Code | Place | Protection | Device backup |
|---|---|---|---|
| H | protected store in `Application Support/` (`medication.json` Built; `Health/health.sqlite` with GRDB To build) | complete | excluded |
| D | UserDefaults | until first unlock | included, so never health data |
| K | Keychain, service `au.adhdslayer.focus` | after first unlock, this device only (Built) | never to another phone |
| G | App Group `group.au.adhdslayer.focus` (To build) | until first unlock, so widgets can read it | excluded |
| M, B, S | memory only; app bundle (read only); server in AWS Sydney | KMS at rest on the server | not applicable |

## Conventions

- Ids are random `UUID`s in the app; server ids are UUIDv7; `TaskID` is a String.
- Times inside a kind of day are Int minutes from local midnight; above 1,440 runs past midnight. Durations are Int minutes. Personal windows are hours after the first dose, Double in steps of 0.25.
- Stored JSON uses Foundation's default dates (seconds since 1 Jan 2001); exports use ISO 8601.
- Decoding is tolerant: a missing key takes its default, unknown keys are ignored, and an unknown enum value in a list drops only that element. Built for `CustomSettings`; To build for every other stored type, because synthesised `Decodable` fails on any missing key.
- Every E2E record carries sync metadata (To build): `hlc` UInt64 (48-bit milliseconds plus a 16-bit counter), `modifiedBy` device UUID and `deletedAt` Date? (tombstone).
- Internal names (`booster`, `kicksInMinutes`, `formulation`, onset, offset) never appear in the UI or in exports.
- Nothing health-related is written before a health consent record exists. Built for the Medication page (disabled until "Yes, store them"); To build for Log all, the Action button and Siri, which must store nothing and ask to finish setup.
- The GRDB store lives in `Application Support/Health/` with complete protection on the folder and on the database, `-wal` and `-shm` files, and the folder excluded from backup; both are checked at every launch.

## Medication and kinds of day

### MedKind (Built)

| Raw value | Label | Working well, stops helping, can sleep after (minutes) | Re-log guard |
|---|---|---|---|
| `longActing` | All day | 60, 480, 720 | 8 hours |
| `booster` | Short-acting | 30, 240, 360 | 2 hours |
| `windDown` | Wind-down | 30, 0, 0 | 12 hours |
| `other` | Something else | 30, 360, 480 | 6 hours |

- Raw values are permanent. `booster` is internal only; the UI says "Short-acting", and a wind-down medicine is never called sleep medication.
- Each kind also picks a curve template (`Formulation`) used only for learning and never shown.

### Medication (Built; H; E2E)

| Field | Type | Default | Rule |
|---|---|---|---|
| `id` | UUID | new | |
| `name` | String | required | trimmed, not empty; To build: at most 60 characters |
| `strength` | String | "" | free text such as "50 mg"; To build: at most 30 |
| `kind` | MedKind | chosen | |
| `tint` | Int | 0 | index into 6 colours, wraps |
| `kicksInMinutes` | Int | by kind | "Working well after", 0 to 240 in steps of 5 (wind-down 0 to 120) |
| `lastsMinutes` | Int | by kind | "Stops helping after", 60 to 960 in steps of 15; 0 for wind-down |
| `sleepAfterMinutes` | Int | by kind | "You can usually sleep after", 60 to 1,200 in steps of 15 |
| `learns` | Bool | false | follow check-ins instead of the sliders; All day only |
| `productID` | ProductID (UUID) | new | links dose events and the learned model |

- Derived, never stored: `title` (name plus strength), `product` (display name, curve, re-log guard in seconds) and `shownName(discreet:)`.
- Deleting a medication removes its dose slots from every kind of day (Built); past dose events keep only the product id. To build: `archivedAt: Date?` so history stays readable.
- Only the account holder's own medication. No field or entity exists for anyone else's.

### DoseSlot, AppliesWhen, MinuteRange (Built; inside DayType)

- DoseSlot: `id` UUID; `medicationID` UUID (must exist); `minute` Int, 240 to 1,620 in steps of 5 (4:00 am to 3:00 am the next day).
- To build on DoseSlot: `remind: Bool = false`. A reminder fires only at this minute, which the person set; the app never works out a time.
- AppliesWhen: `weekdays` Set<Int> (1 is Sunday; empty means any day), `from` Date?, `to` Date? (the whole `to` day counts). It matches when the date is inside any set range and, if weekdays are set, falls on one.
- MinuteRange: `start` and `end` Int minutes (may pass 1,440); `length` is `max(0, end minus start)`.

### DayType, "kind of day" (Built; H; E2E)

| Field | Type | Default | Rule |
|---|---|---|---|
| `id` | UUID | new | |
| `name` | String | required | "Uni day", "Night shift"; To build: at most 40 characters |
| `symbol` | String | `sun.horizon` | SF Symbol from the picker |
| `doses` | [DoseSlot] | [] | shown sorted by minute |
| `usesOwnWindows` | Bool | false | false means windows come from each medication's timing |
| `windows` | [MinuteRange] | [] | drawn windows, 300 to 1,560 in steps of 15, at least 30 long |
| `windDownBufferMinutes` | Int | 60 | 0 to 180 in steps of 15 |
| `appliesWhen` | AppliesWhen | empty | |

- The free plan holds 3, Plus is unlimited, and lapsing keeps them all (Built).
- Today's kind of day: today's manual choice, else the matching date range with the shortest span, else the first weekday match without a range, else the first in the list (Built).

### DaySchedule (derived; M; never stored)

- `windows`: automatic ones run from each non-wind-down dose's `minute + kicksIn` to `minute + lasts`, merged across gaps under 20 minutes; drawn ones are merged as drawn.
- `windDownAt` is the earliest wind-down dose. Windows are cut at `windDownAt` minus the buffer and pieces under 15 minutes are dropped. `focusEndsFor` is `windDown` or `lastDose`.
- `gaps`: spaces of 20 minutes or more between windows (low-focus stretches). `sleepReadyAt`: the latest `minute + sleepAfter` of non-wind-down doses.

### MedicationFile (Built; H)

- `version` 1, `medications`, `dayTypes`, `manualChoice` {date, dayTypeID}? (lasts until midnight) and `actionButtonSuggested` Bool (Device only; everything else E2E).
- Written atomically with complete protection, then `isExcludedFromBackup` is set again (Built).
- A new person sees an example set (three medications, three kinds of day) so the page isn't empty; it is saved only once they edit (Built).

## Dose log

### DoseEvent (Built in memory; To build persisted; H; E2E)

| Field | Type | Rule |
|---|---|---|
| `id` | DoseEventID (UUID) | |
| `product` | ProductID | the medication's `productID` |
| `takenAt` | Date | as entered: now, 20 minutes ago, or an earlier time today; never over 1 minute ahead of the tap |
| `loggedAt` | Date | when the tap happened |
| `source` | DoseSource | `app`, `watch`, `intent`, `healthImport` |
| `ateFirst` | Bool? | nil when not asked or skipped |
| `isBooster` | Bool | from the kind; internal name |

- To build: `deviceId`, `editedAt`, `healthSampleUUID` (unique, for Health imports, Later) and sync metadata. Write before the celebration plays; a failed write shows "Couldn't save that log. Nothing was changed." (Built wording).
- Double-dose guard (Built): the same product inside its re-log guard returns the earlier log instead of writing; a second log needs the deliberate confirm. Snooze or dismiss never writes a log.
- Kept until the person deletes it.

### DoseAuditEntry, the audit trail (Built in memory; H; E2E)

- `action` (`logged`, `loggedAfterConfirm`, `undone`, `edited`), `event` (a full copy after the change, or the removed event for undo), `gesture` origin (`button`, `watchButton`, `doubleTap`, `control`, `actionButton`, `siri`, `shortcut`) and `at` Date.
- Append only. To build: persist it, and add `id` and `previousTakenAt` for edits. Kept 24 months.

### Product (FocusCore; derived; M)

- `id`, `displayName`, `formulation`, `minimumRelogInterval` in seconds. Rebuilt from the medications at launch and registered with the dose log on every save (Built).

## Check-ins and learning

### CheckIn (type Built; collecting To build; H; E2E)

- `at` Date, `answer` (`yes`, `partly`, `no`) and `dose` DoseEventID.
- To build: `id`, `scheduledAt` Date? and `source` (notification or app). An unanswered prompt is stored as `missed` and never counts as a no.
- Raw check-ins are kept 12 months; the learned model keeps the summary.

### BrainWeatherEntry (To build; H; E2E)

- `day` (date), `level` (`low`, `okay`, `good`) and `answeredAt`. Today it lives in memory. Low switches the day to its baseline version. Kept 12 months.

### LearnedFocusModel (To build persisted; H; E2E)

- `productID`, `formulation`, `rampUp` and `rampDown` minutes, `stated` {startsHelpingAfter, helpsFor} taken from the medication's own sliders, `manualOverride` {onset, offset}?, `checkInDays`, `checkInCount`, `version`.
- `logPosterior` [Float32]: 741 cells (13 onset by 57 offset steps of 15 minutes), about 3 KB.
- One per learning medication (All day only today). A new model starts from the sliders when the medication's kind, name or strength changes (old answers archived) or on "Start over" (04-intelligence.md). Kept until reset or the medication is deleted.
- Confidence: starting (under 3 check-in days), early (3 to 7), learned (8 or more days with both edges within 30 minutes), or the person's own setting (Built).
- Today the model is rebuilt at launch from 9 simulated days with fixed numbers.

### FocusWindow (derived; M)

- `dose`, `start`, `bestFocusEnd`, `end`, onset and offset minutes, ramps, uncertainty and confidence. Shown only as "your focus window". Never stored.

## Planning

### Task (To build as stored data; H; E2E)

| Field | Type | Default | Rule |
|---|---|---|---|
| `id` | TaskID (String) | UUID string | |
| `title` | String | required | 1 to 120 characters |
| `estimateMinutes` | Int | 30 | 5 to 480 |
| `demand` | `deep`, `medium`, `light`, `body` | `medium` | |
| `deadline` | Date? | nil | |
| `isBaseline` | Bool | false | part of the baseline day |
| `pinnedInterval` | DateInterval? | nil | pinned tasks never move |

- To build: `createdAt`, `updatedAt`, `completedAt`, `archivedAt`, `categoryID`, `notes` (up to 1,000 characters) and sync metadata. `preferredWindow` is worked out at planning time and never stored.
- Today tasks are demo data in memory. Done and archived tasks are kept 12 months.

### TaskOutcome (To build; H; E2E)

- `taskID`, `blockStart`, `blockEnd`, `outcome` (`done`, `doneForNow`, `notStarted`), `minutesSpent` and `at`. Feeds estimates and "Planned and done"; today `completed` is a set in memory. Kept 12 months.

### FixedEvent, a calendar import (Built; M; Device)

- `id` ("cal-" plus the event identifier), `title` and `interval`. Read from EventKit for today at launch and after changes, skipping all-day events. Never written to disk, synced or sent.

### Plan and Block (Built in memory; Device)

- Plan: `blocks` sorted by start. Block: `id`, `taskID?`, `title`, `interval`, `demand?`, `kind` (`task` or `fixed`) and `reason` (ReasonCode).
- PlanResult: `plan`, `changes` (place, move, unplaced; no case can touch medication), `fillPercent`, `solveMilliseconds`.
- To build: keep today's applied plan and up to 20 revisions for undo, for 7 days. Plans hold calendar titles, so they never sync; a new phone rebuilds them.

### Tuning (Built; D key `tuning` today, move to H; E2E)

| Field | Type | Default | Rule |
|---|---|---|---|
| `windowOverride` | [Int]? | nil | two values: onset and offset minutes after the dose |
| `mealRuleMinutes` | Int | 270 | follows the eating window's start |
| `fillCap` | Double | 0.6 | share of free focus time flexible work may fill |
| `transitionMinutes` | Int | 10 | between blocks |
| `afterWindowBufferMinutes` | Int | 20 | |
| `estimateBuffers` | [String: Double] | [:] | task id to multiplier |

- The override and the meal rule are measured from the dose, so this is health data. To build: move it into the protected store.

### Derived views (M)

- Five priorities: 3 or 5 lines with `source` `appleIntelligence` or `plan`, regenerated when the plan changes, never stored or sent.
- Rhythm history (`LifeHistory`): generated demo data today. To build: a projection over dose events, check-ins, brain weather and task outcomes.

## Personalisation

### HourRange and ActivityCategory (Built; E2E)

- HourRange: `from` and `to`, hours after the first dose, 0 to 16 in steps of 0.25, at least 0.5 apart.
- ActivityCategory: `id` UUID, `name` String (required; To build: at most 30 characters), `symbol`, `tint`, `window` HourRange (new ones start 2 to 5) and `keywords` [String], used when Apple Intelligence isn't available.
- The free plan holds 5 categories, Plus is unlimited (Built). Starter set: Deep study, Admin, Prep, Movement, Home stuff.

### Personalisation (Built; D key `personalisation` today, move to H)

| Field | Type | Default | Sync |
|---|---|---|---|
| `categories` | [ActivityCategory] | starter five | E2E |
| `eating` | HourRange | 4.5 to 6 | E2E |
| `social` | HourRange | 7 to 12 | E2E |
| `alone` | HourRange | 0 to 3 | E2E |
| `socialSuggestions` | Bool | true | E2E |
| `dismissedSuggestions` | Set<String> | [] | Device: calendar event ids |
| `taskCategories` | [String: UUID] | [:] | E2E |

- The windows count from the first dose, so this is health data. To build: move it into the protected store.

### SocialSuggestion (Built; M; Device)

- `id` (event id), `eventTitle`, `person`? (a first name from the title), `current` interval, `proposed` start and `why`. Made on the phone from calendar titles; never stored, synced or sent. The person sends any message themselves.

## Look, voice and feel

### CustomSettings (Built; D key `customSettings`; E2E)

| Field | Type | Default | Range or rule |
|---|---|---|---|
| `version` | Int | 1 | |
| `pages` | [TabKind: [PageKind]] | each tab's pages without extras | `now`, `youHome`, `youMore` always stay |
| `tabOrder` | [TabKind] | today, plan, rhythm, you | |
| `hiddenTabs` | Set<TabKind> | [] | only plan and rhythm can hide |
| `tabNames` | [TabKind: String] | [:] | blank means the default name |
| `appearance` | dark, light, system | dark | |
| `darkBackdrop`, `lightBackdrop` | facade, baroque, plain | facade, baroque | |
| `darkness` | Double | 0.5 | 0 to 0.8 in steps of 0.05; dims the dark backdrop |
| `blur` | Double | 0 | 0 to 30 |
| `frost`, `grain` | Double | 0, 0.5 | 0 to 1 in steps of 0.05 |
| `accent` | espresso, champagne, rose, sage, slate | espresso | |
| `typeface` | serif, sans, rounded | serif | |
| `textSize` | matchPhone, smaller, bigger, biggest | matchPhone | |
| `roundness` | Double | 1 | 0.5 to 1.4 |
| `dots` | dots, numbers, hidden | dots | |
| `humour` | straight, little, lots | little | |
| `dailyVariety` | Bool | true | |
| `nickname` | String | "" | |
| `celebrateLogging`, `sliderTicks` | Bool | true | |
| `hapticStrength` | Double | 1 | 0.3 to 1.3 |
| `priorityCount` | Int | 5 | 3 or 5 |
| `showPrioritySource`, `showFirstStep` | Bool | true | |
| `ringStyle` | ring, bar, number | ring | |
| `accessory` | doses, nextThing | doses | |
| `liveFocusMode` | Bool | true | Focus mode Live Activity |
| `liveDay` | Bool | false | Your day Live Activity |
| `liveDayShows` | both, stretch, next | both | only read while `liveDay` is on |
| `liveLogButton` | Bool | true | Log button in Your day |
| `liveHideTaskNames` | Bool | false | "Focus" instead of the task on the Lock Screen |

- Decoding starts from today's defaults and takes each saved key that decodes, so a new option never wipes old choices (Built). Saved page lists missing a required page get it back (Built).
- To build: decode page lists element by element, so one unknown page (for example the old `youPrivacy`, now `youMore`) can't reset a whole layout; map `youPrivacy` to `youMore`.
- `hapticStrength`, `sliderTicks` and `celebrateLogging` are mirrored into their own UserDefaults keys for the haptics engine; CustomSettings stays the source of truth.

### Other UserDefaults keys (Built; D)

| Key | Type | Default | Sync |
|---|---|---|---|
| `onboarded`, `coachDone`, `welcomed` | Bool | false | Device |
| `userName` | String | "" | E2E; never sent to the server or any AI |
| `hapticsEnabled`, `stillMotion` | Bool | true, false | E2E; To build: move into CustomSettings |
| `noticeAcceptedVersion`, `confirmedAdult`, `healthConsent` | Int, Bool, Bool | 0, false, false | replaced by consent records |
| `externalAI` | JSON | see Your own AI | E2E |

- To build: persist `discreetMode` (Bool, default true; today it resets at launch), plus `analyticsID`, `diagnosticsID`, `rolloutBucket` (0 to 99), `analyticsOptIn` and `crashReportsOptIn`, all Device.

## Account and subscription

### Account (Built; K key `account`; Plain on the server)

- `id` UUID (the server's account id; `LocalAuthBackend` makes one today), `method` (`apple`, `google`, `email`), `email`?, `name`? (from Apple, stays on the phone) and `createdAt`.
- Other Keychain items: `externalAIKey` (Built). To build: `session.access`, `session.refresh`, `device.id`, `device.signing` (Secure Enclave), `device.agreement`, `sync.ark.<epoch>` (when unlocked, this device only), `appleUserID`, `linkVerifier`, `pendingDeletion`.
- Optional iCloud Keychain copy of the ARK: service `au.adhdslayer.focus.escrow`, synchronizable (To build).

### Subscription state (Built; M; Plain mirror on the server)

- `Store.Status`: `free`, `trial(until)`, `plus(renews)`, `lapsed`; `trialEligible`; products from StoreKit. Worked out at launch and on `Transaction.updates`. StoreKit caches it and the app stores nothing.
- Limits: `freeDayTypes` 3, `freeCategories` 5. To build: grace and billing retry states.

## Your own AI

### ExternalAIConfig (Built; D key `externalAI`; E2E, with `enabled` off on a new phone)

| Field | Type | Default | Rule |
|---|---|---|---|
| `provider` | openAI, anthropic, custom | openAI | Gemini is never offered |
| `model` | String | provider default | editable |
| `customEndpoint` | String | "" | https only; `/chat/completions` added if missing |
| `enabled` | Bool | false | needs a key and an accepted warning |
| `acceptedWarningAt` | Date? | nil | also written as a consent record (To build) |
| `shareTaskNames`, `shareTimes` | Bool | true, true | To build: default false, so nothing is pre-ticked |

- The key lives only in the Keychain as `externalAIKey`, this device only (Built). It never goes into UserDefaults, snapshots, logs, analytics or the server. To build: tolerant decoding.

## Consent records (To build; H; E2E, some Plain)

- `ConsentRecord`: `id` UUID, `purpose`, `version` Int (the wording shown), `grantedAt`, `withdrawnAt`? and `detail`? (the provider for own AI). Same shape as in 06-compliance-and-safety.md.
- Purposes: `notice`, `terms`, `privacy`, `health`, `calendar`, `ownAI`, `analytics`, `crashReports`, `marketingEmail` (Later) and `adult`, which stores only "confirmed 18 or over" and when, never a birth date.
- Replaces `noticeAcceptedVersion`, `confirmedAdult`, `healthConsent` and `acceptedWarningAt`; the migration writes version 1 records dated at migration.
- Withdrawing `health` stops collection and deletes health data from the phone and the next snapshot. The server keeps only `terms`, `privacy`, `notice` and `adult`, with versions and times.

## Copy deck (Built; B)

- `CopySlot`: 65 slots, each with `tone` (serious, light, playful), `placeholders`, `maxCharacters`, `context` and `example`.
- `Copy.json`: slot name to 100 variants `{t: String, f: Bool}`, where `f` marks a funny one (2,220 in all).
- Choice: the pool by humour (straight drops funny ones; lots uses only funny ones when there are 10 or more), then index `abs(dayOrdinal * 7919 + slotSalt) % poolCount` with daily variety on, else the first. Stable all day.
- Remote decks (To build): `Application Support/Copy/deck-<version>.json` plus its signature; the current and previous decks are kept.

## Notification schedule (To build; Device)

- `ScheduledNudge`: `id` (deterministic, like `dose-<slotID>-<yyyyMMdd>`), `kind` (`medicationReminder`, `checkIn`, `transition`, `digest`, `trialEnding`), `fireAt`, `templateID`, `interruption` level and `countsTowardBudget`.
- A rolling 48 hours, at most 64 pending and at most 5 budgeted nudges a day (user-set medication reminders don't count). Text never names a medicine or a condition. Rebuilt on launch and after changes, never synced. Built today: only `trial-ending`.

## GlanceSnapshot (To build; G; Device)

- `glance.json`, at most 4 KB: `v`, `generatedAt`, `discreet`, `loggedCount`, `plannedCount`, `lastLoggedAt`?, `nextAt`?, `windowStart`?, `windowEnd`?, `now` {title, end}?, `next` {title, start}?, `zone`.
- No medicine names while discreet mode is on, and never strengths (05-platform.md). Written atomically after each log or replan with until-first-unlock protection so the Lock Screen can read it. Readers ignore unknown keys and show "Open Focus to update" for a newer `v`.

## Sync bundle (To build)

```
SyncBundle, schema 1
  medicationFile      medications, dayTypes, manualChoice
  health              doseEvents, doseAudit, checkIns, brainWeather, focusModels
  planning            tasks, taskOutcomes, tuning, personalisation (no dismissedSuggestions)
  settings            customSettings, userName, hapticsEnabled, stillMotion
  consents, externalAIConfig (no key)
  tombstones          entity, id, deletedAt
  meta                schema, createdAt, deviceId, highestHLC
```

- Left out: calendar data and anything made from it, plans, the glance file, the notification schedule, onboarding flags, tokens, keys and `actionButtonSuggested`.

## Server tables

- PostgreSQL. Times are `timestamptz` in UTC; ids are UUIDv7 unless marked. Foreign keys to `accounts` cascade on deletion and are indexed. Every query is scoped to the session's account, and no endpoint lists accounts. `_enc` columns are also encrypted in the application with a KMS data key.

```
accounts            id pk, created_at, status (active|deleting), last_seen_on date,
                    deletion_requested_at
auth_identities     id pk, account_id, provider (apple|google|email), subject, email,
                    email_verified, is_private_relay, apple_refresh_token_enc,
                    created_at, last_used_at; unique (provider, subject)
sessions            id pk, account_id, device_id, access_hash unique, access_expires_at,
                    refresh_hash unique, prev_refresh_hash, rotated_at, idle_expires_at,
                    absolute_expires_at, revoked_at, revoke_reason, created_at, last_used_at
devices             id pk (from the phone), account_id, model, os_version, app_version,
                    signing_key, agreement_key, enrolled_at, last_seen_on, revoked_at
account_keys        account_id pk, epoch, rotation_required, updated_at
key_slots           (account_id, epoch, device_id) pk, enc, ciphertext, created_at
recovery_slots      (account_id, epoch) pk, nonce, ciphertext, created_at
key_transfers       id pk, account_id, requester_device_id, agreement_key, sealed_enc,
                    sealed_ciphertext, sealed_by, created_at, expires_at, completed_at
sync_snapshots      id pk (from the phone), account_id, version, base_version, device_id,
                    epoch, schema, size_bytes, sha256, s3_key,
                    state (pending|committed|superseded), created_at, committed_at;
                    unique (account_id, version)
sync_batches        (account_id, device_id, seq) pk, cursor, epoch, schema, nonce,
                    ciphertext, aad_hash, received_at                       Later
entitlements        account_id pk, original_transaction_id, product_id, status,
                    expires_at, grace_expires_at, will_auto_renew, is_trial,
                    environment, updated_at
store_transactions  transaction_id pk, original_transaction_id, account_id,
                    app_account_token, product_id, purchase_date, expires_date,
                    offer_type, revocation_date, revocation_reason, environment
store_notifications notification_uuid pk, type, subtype, environment,
                    original_transaction_id, received_at, processed_at, status,
                    signed_payload
magic_links         id pk, email, device_id, secret_hash, code_hmac, link_challenge,
                    attempts, created_at, expires_at, used_at
account_consents    (account_id, kind, version) pk, accepted_at, withdrawn_at
support_requests    id pk, account_id, reference, topic, message_enc, reply_email_enc,
                    diagnostics jsonb, helpdesk_id, created_at, last_message_at
deletion_receipts   account_hmac pk, requested_at, completed_at, steps jsonb
audit_log           id bigserial pk, at, actor (system|account|staff), account_id,
                    action, target, request_id, details jsonb (no personal data)
idempotency_keys    (scope, key) pk, body_hash, status, response jsonb, expires_at
rate_limits         key pk, window_start, count, expires_at
analytics_daily     (day, metric, dimension) pk, value, installs
crash_reports       id pk, received_at, app_version, build, os_version, model, kind,
                    s3_key, symbolicated
```

- Checks: `status`, `provider`, `state` and `kind` columns accept only their listed values; `attempts` is at most 5; `version` rises by one per commit; the `sealed_*` columns are written once.
- Indexes beyond keys: `sessions(account_id)`, `store_transactions(original_transaction_id)`, `store_transactions(app_account_token)`, `magic_links(expires_at)`, `sync_snapshots(account_id, created_at)`.
- Retention sweeps run hourly as scheduled jobs and are idempotent.

## Retention

| Data | Where | Kept |
|---|---|---|
| Medications, kinds of day, settings | phone, snapshot | until the person deletes them |
| Dose log | phone, snapshot | until the person deletes it |
| Dose audit trail | phone, snapshot | 24 months |
| Check-ins, brain weather | phone, snapshot | 12 months; the learned summary stays |
| Learned model | phone, snapshot | until reset or its medication is deleted |
| Done or archived tasks, outcomes | phone, snapshot | 12 months |
| Deleted items for undo; tombstones | phone, snapshot | 30 days; 90 days (id and time only) |
| Plan revisions | phone | 7 days |
| Calendar events, suggestions, priorities | memory | never stored |
| Export files | phone temporary folder | until shared or the next launch |
| Snapshots | S3 | newest 10, none older than 30 days except the newest |
| Old S3 versions, database backups | AWS | 35 days |
| Sessions | server | 30 days after expiry or revocation |
| Magic links | server | purged within 24 hours of use or expiry |
| Key transfers | server | sealed key cleared when read or after 10 minutes; row 24 hours |
| App Store notification payloads; transactions | server | 90 days; until account deletion |
| Support requests | server, helpdesk | 24 months after the last message |
| Audit log, deletion receipts | server | 24 months |
| Crash reports | S3 | 90 days |
| Usage batches; aggregates | server | 30 days; 25 months |
| Application logs; WAF and load balancer logs | AWS | 30 days; 14 days |
| Idempotency keys; rate limit rows | server | 24 hours; 48 hours |
| Dormant accounts | server | deleted after 24 months without sign-in or backup, after a 30-day notice |
| Your own AI requests | the person's provider | the provider's terms |

## Migration and versioning

- Every stored document carries a `version` (`MedicationFile` 1 and `CustomSettings` 1 today). Migrations are small ordered steps from one version to the next, run at launch before any screen reads data.
- Before migrating, copy the file to `<name>.v<old>.bak` in the same protected folder, and delete the copy 7 days after a clean launch.
- A file written by a newer app is never rewritten: open it read only and ask for an update.
- First store migration (To build): move `medication.json` into `Health/` and create `health.sqlite` beside it for the dose log, audit trail, check-ins, brain weather, learned models, tasks and consents; move `tuning` and `personalisation` out of UserDefaults; write consent records from the old flags; add sync metadata to every record with the current clock.
- Enum raw values never change. Renamed cases keep a decoding map (`youPrivacy` to `youMore`), and unknown values drop only their own element.
- New fields always get a default and tolerant decoding. GRDB schema changes use its migrator with named, append-only migrations.
- The sync bundle `schema` goes up only for breaking changes. Apps keep decoders for every schema they wrote, and a newer schema blocks restore and merge until the app updates.
- Server: forward-only migrations, expand then contract across two releases; no destructive change ships with the code that stops using a column.
- Config, copy decks and the glance file carry their own version, and readers ignore unknown keys.
- Tests: decode a fixture from every shipped version of every type; round-trip every type; merge two simulated phones with random interleavings until they converge; check that complete protection and backup exclusion are set on every health file.
