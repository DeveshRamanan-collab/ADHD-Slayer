# Build plan

How Focus gets from today's prototype to an App Store launch in Australia: milestones with scope, dependencies and exit criteria, the test plan, the release checklist, and everything the owner must do outside the code. Durations assume one full-time builder. Problem IDs (T01, S05 and so on) point to 07-problems-and-solutions.md; rule numbers point to 06-compliance-and-safety.md.

## 1. Where the build stands (30 Sep 2026)

- Built: every screen of the first-launch flow, Home, Plan, Rhythm, You, Medication, Personalise, Customise and Settings; the Apple Intelligence gate; StoreKit 2 client; App Intents with App Shortcuts; the copy deck (65 slots, 100 variants each) with its validator; Core Haptics catalogue; FocusCore (scheduler, focus window model, dose log with guard, safety gate) with 31 passing tests.
- Built on 30 Sep: `medication.json` with complete protection and excluded from backup; "Log my meds" asks for Face ID on a locked phone; your own AI replies pass `SafetyGate`; check-ins are claimed only when learning is on.
- Prototype only: dose log in memory, tasks and history seeded, account backend local, email link stubbed, Google without a client ID.
- Not built: persistence, backend and sync, notifications and reminders, widgets and controls, check-ins, task entry, consent records, regional crisis lines, privacy manifest, entitlements file.

## 2. Milestones

| Milestone | Weeks | Depends on | Exit in one line |
|---|---|---|---|
| M0 Foundations and spikes | 2 | none | Company, developer account and reviewers in place; six spikes answered |
| M1 Data foundation | 3 | M0 | Protected persistent ledger; release builds start empty; clock edge cases pass |
| M2 Safety and compliance wiring | 2 | M1 | Red-team and banned words clean; consent and crisis routing complete |
| M3 Tasks and the daily loop | 2 | M1 | A new person adds tasks and gets a plan in under 3 minutes |
| M4 Accounts and encrypted sync | 4 | M0, M1 | Three sign-in methods live; deletion reaches the server; devices converge |
| M5 Payments complete | 1 | M4 | StoreKit test matrix passes |
| M6 Notifications and glanceables | 3 | M1, M2 | Reminders, budget, widgets and the Control Center control work |
| M7 Check-ins, learning and sleep | 2 | M1, M6 | One-tap check-ins feed learning; sleep read from Health |
| M8 Accessibility, performance, polish | 2 | M3 to M7 | Audits, contrast grid and speed budgets pass |
| M9 Beta | 4 | M2 to M8 | TestFlight gates met; legal and clinical sign-off |
| M10 Release | 2 | M9 | Approved and fully released |

- Total about 27 weeks. With a second builder, M4 and M6 can run beside M3 and M7, bringing it to about 20.
- Each milestone ends with a tagged build, updated tests and the Built or To build statuses in this spec corrected.

### M0 Foundations and spikes (2 weeks)

- Owner starts: Pty Ltd, D-U-N-S number, Apple Developer Program as an organisation, App Store name reservation, lawyer and clinical reviewer engaged, domain pages drafted (section 5).
- Spike 1: on a real locked iPhone, confirm `LogMedicationIntent` (already `.requiresAuthentication`) asks for Face ID from the Action button and Siri, with complete protection on every health file.
- Spike 2: Foundation Models on iPhone 15 Pro: priorities prompt size, latency, every error case, behaviour on iOS 27.
- Spike 3: StoreKit sandbox: intro offer eligibility, grace period, refund, `appAccountToken` in server notifications.
- Spike 4: Sign in with Apple identity token validation and the token revoke round trip.
- Spike 5: encrypted backup prototype (02-backend.md): account root key with an iCloud Keychain copy, AES-256-GCM snapshot to S3 in Sydney, restore on a second phone by QR key transfer and by recovery key.
- Spike 6: widget extension and `ControlWidget` reading an App Group snapshot, including on a locked phone.
- Exit: each spike has a one-page result with a go or change decision; the company, developer account and reviewers exist; no spike code merges without tests.

### M1 Data foundation (3 weeks)

- Event-sourced SQLite ledger for doses, audit entries, check-ins, consents, tasks and plan revisions; `DoseLog` becomes a persistent store behind the same `DoseLogging` protocol (T03).
- The ledger, check-ins and learned state get the same complete protection and backup exclusion as `medication.json`, checked at launch; health-derived values move out of UserDefaults (T01, T02).
- Tolerant decoding and versioned migrations for `medication.json`; undecodable files moved aside, never overwritten (T05).
- Demo data only under DEBUG or `-demo`; empty starter content and neutral placeholders (T04, R12).
- DST-safe wall-clock times, a 04:00 day boundary, time zone change detection and the home or local prompt (S01 to S04, T11).
- Log all due window of 90 minutes before to 60 after (S05); past logging up to 7 days (S07); undo toast (S08).
- Full export (JSON and CSV, health warning, temp file cleaned) and a complete wipe (D06, D07).
- Exit:
  - Unit tests pass for 23 and 25 hour days, zone changes, the day boundary, the due window and a migration from version 1.
  - A release build launches with no medicines, tasks or history.
  - The data folder reports `isExcludedFromBackup = true` in a test.
  - Export reads back into a fresh install; wipe leaves no files, defaults, Keychain items or pending notifications.

### M2 Safety and compliance wiring (2 weeks)

- `SafetyGate` (already on your own AI replies) extended to notification templates and any parser; a keyword check that answers medication questions with the referral line before any request (T07, F01).
- One shared banned-words list used by merge.py, a string-literal unit test and `SafetyGate`; merge.py runs in CI.
- Serious copy slots pinned to one line; straight tone on Low brain weather days (C02, X07).
- Honest bit edits (no condition named, prescription and doctor lines, links) and notice versioning with time (06, 5.1).
- `ConsentRecord` for notice, terms, privacy, health, calendar and your own AI; health consent withdrawal; every logging path gated on consent (06, 5.3).
- Crisis lines by region, keyword route, support card after 5 Low days in 7, Get support on the Medication page and the Ask sheet (06, 3).
- The gate never blocks after onboarding (T06). Discreet mode saved; app switcher blur; privacy wording rewritten (N04, V02, V08).
- Your own AI: neutral system prompt, event titles off by default, medicine names scrubbed, provider country and host in the warning (V06, V07, AI02, AI04).
- `PrivacyInfo.xcprivacy` for the app (06, 10.2).
- Exit:
  - The 500-prompt red-team set (dose timing, amounts, extra doses, non-prescribed use, crisis phrases, prompt injection through task titles) yields zero medication advice on every AI path.
  - The banned-words scan finds zero hits in app strings and Copy.json.
  - No health data is written before consent on any path (UI and intent tests).
  - The crisis keyword set routes correctly offline with Apple Intelligence off.

### M3 Tasks and the daily loop (2 weeks)

- Quick add: title required; rough duration (5 to 240 minutes), deadline, kind of work (deep, medium, light, body) and "a must today" optional (T16).
- Edit, done, done for now, delete; a first step per task, typed or suggested by the on-device model (under 10 minutes, accepted before saving).
- Welcome back after 3 days away with a 3-thing restart and no mention of missed days.
- Fix my day asks the minutes first (S14); all-day events shown (S12); calendar identity by external identifier (S13).
- Social suggestion fixes (SO01 to SO05); the "Shapes my focus day" switch (S16).
- Exit: in moderated tests a new person adds 5 tasks and sees a plan in under 3 minutes; scheduler invariant tests still pass; welcome back copy passes the banned-words scan.

### M4 Accounts and encrypted sync (4 weeks)

- Backend in Sydney (02-backend.md): Sign in with Apple validation, Google ID token verification, email link with Universal Link and a 6-digit code, deletion with the Apple revoke call, encrypted snapshot backup and restore, App Store Server Notifications V2, logs without payloads.
- App: Sign in with Apple and Associated Domains capabilities, credential state check at launch, sign out with "keep or remove this iPhone's data", the new-phone flow, the recovery key, and "Manage subscription" in the delete dialog (A02 to A10, D02 to D05).
- "Continue without an account" fallback built behind a remote flag (A01).
- Exit:
  - All three sign-in methods work on a real device.
  - Deleting an account removes its server rows at once and from backups within 35 days (verified by script).
  - Two simulated devices converge after random interleavings; a lost key is recovered with the recovery key.
  - An inspection of the database and object storage finds nothing readable.

### M5 Payments complete (1 week)

- Products and introductory offers in App Store Connect; Billing Grace Period 16 days; renewal state banner (P05).
- Trial reminder scheduled whenever a trial is seen, with an in-app card if notifications are off (P10).
- "Request a refund"; offer code campaigns; the lapse rule: extras keep working, adding more needs Plus (P02, P03, P06).
- Server handling of SUBSCRIBED, DID_RENEW, DID_FAIL_TO_RENEW, GRACE_PERIOD_EXPIRED, EXPIRED, DID_CHANGE_RENEWAL_STATUS, OFFER_REDEEMED, REFUND and REVOKE.
- Exit: every row of the StoreKit matrix (3.5) passes.

### M6 Notifications and glanceables (3 weeks)

- Medication reminders only at times the person set, opt-in per dose slot, reading "Reminder you set: Morning"; one action "Logged it"; snooze never logs (R4 to R6, N03).
- The late note; at most 5 notifications a day across all types, reminders the person set first; a rolling 48-hour window under 64; an explainer before the permission prompt; no badges (N01, N02, N05, N06).
- Widget extension: Lock Screen and Home Screen widgets for the dose glance (kind labels) and Now and Next, from the App Group snapshot; a Control Center control that runs "Log my meds" (T13).
- Privacy manifest for the extension.
- Exit: with 100 candidate notifications the pending count never passes 64; snooze and dismiss never create a log; widget snapshots show no medicine name in discreet mode; the control asks to unlock before logging.

### M7 Check-ins, learning and sleep (2 weeks)

- One-tap "Focused right now?" (Yes, Partly, No) from a notification and an in-app card: 3 to 5 a day for the first 5 to 7 dose days, then every 2 to 3 days, quiet in Focus modes, inside the budget (LL-05, LL-06).
- Learned state saved in the protected store; decide per-medication learning (LL-02); proposal card with a 30-day rest (LL-04).
- Apple Health sleep, read only, asked on the Sleep and done page with an explanation first; a refusal shows "No sleep from Health yet" (V11).
- Make "Start over" reset what was learned as well as the person's adjustments, and reword the learned line so it reads as a span (08, learning findings).
- Exit: the simulated-person test (10 days, 20% missed) stays within 30 minutes; label tests pass; no check-in text names a medicine.

### M8 Accessibility, performance and polish (2 weeks)

- Contrast grid test (AX01), Dynamic Type to AX5, VoiceOver labels and chart summaries, 44 point targets, paging accessibility actions (AX03 to AX06).
- One shared backdrop, blur capped at 12, haptics engine stopped when idle (B01 to B03).
- String Catalog, "Send feedback", "Show the tour again" (L01, SU05, X08).
- Exit:
  - `performAccessibilityAudit()` passes on every screen with no critical issue.
  - Every text pair is 4.5:1 or better and every meaningful graphic 3:1 or better across the grid.
  - On iPhone 15 Pro: replan under 150 ms, cold launch to first frame under 1.5 s, paging without dropped frames.

### M9 Beta (4 weeks)

- Internal TestFlight for the owner and reviewers, then external groups (3.8).
- Lawyer and clinical sign-off before the first external build; independent security test during the beta.
- Weekly three questions to testers: what helped, what annoyed you, what did you ignore.
- Exit gates:
  - Crash-free sessions at 99.5% or more.
  - Zero safety incidents: no medication advice, no health data outside the stated flows.
  - At least 40% of pilot testers active on day 14; median onboarding under 3 minutes.
  - Written legal and clinical sign-off; security test with no high-severity finding; every Owner row in 07 closed.

### M10 Release (2 weeks)

- Work through the release checklist (section 4), submit, answer review questions within a day.
- Phased release over 7 days; pause on any crash or safety spike.
- Exit: approved; phased release complete; support answering within 2 business days.

### After launch (Later)

- Apple Watch app, HealthKit medication import, Assistive Access simple mode, Face ID lock, Live Activity, supply tracking, opt-in usage counts, the US and UK (with 06, sections 6.3 and 6.4).

## 3. Test plan

### 3.1 Unit tests (Swift Testing)

- Keep the 31 FocusCore tests green on every commit; CI runs `swift test` and the app test target.
- Clock: 23 and 25 hour days, minutes past 1,440, zone change prompts, the 04:00 boundary.
- Logging: due window edges (91 and 89 minutes before), relog interval per kind, past logging, undo, edit with audit entries, consent gate.
- Storage: migration from version 1, undecodable file kept aside, backup exclusion flag, wipe completeness, export round trip.
- Safety: `SafetyGate` patterns, the banned-words scan over every string literal and Copy.json, crisis keyword set, referral replacement.
- Copy: placeholders, lengths, no dashes, serious slots pinned, Low day tone.
- Store: status mapping for trial, plus, lapsed, grace and retry using StoreKitTest.
- Your own AI: captured request bodies contain no medicine names, no check-ins, no condition words, and event titles only when allowed.

### 3.2 UI tests (XCUITest)

- Launch arguments: `-skipGate`, `-freshDay`, `-demoClock 09:41`, `-plus`, `-tab` (exist); add `-resetAll` and `-region US`.
- Flows: onboarding end to end; under 18 blocks sign-in; consent card gates logging; add a medication and a kind of day; Log all; the guard and hold to log another; undo; delete everything; the paywall's "Not now"; the free-plan limit sheet; Get support from every entry point; the AI warning appears before any request.

### 3.3 Snapshot tests

- Every screen in dark at darkness 0, 50 and 80%, and in light.
- Text sizes: default, xxxLarge, AX5. Reduce Transparency and Increase Contrast on and off.
- Discreet mode on and off for Home, widgets and notification content.
- A snapshot library in the test target only; nothing ships in the app.

### 3.4 Accessibility tests

- `performAccessibilityAudit()` inside the UI tests for every screen.
- A written VoiceOver script: onboarding, logging with the guard, Medication page, Settings deletion, Get support.
- Switch Control and Voice Control spot checks on logging and the guard.
- The contrast grid test from M8, re-run whenever colours, backdrops or darkness change.

### 3.5 StoreKit testing

| Scenario | Expected | Where |
|---|---|---|
| First purchase with the free month, each product | Status trial; reminder 2 days before `expirationDate` | Xcode config, Sandbox |
| Already used the introductory offer | Button "Get Plus" with the price only | Xcode config |
| Ask to Buy or other pending purchase | "Waiting on Apple" message; Plus arrives later | Xcode config |
| Auto-renew turned off during the trial | Plus until expiry, then free; nothing deleted | Sandbox |
| Renewal | "Plus, renews [date]" | Xcode config (time rate) |
| Billing retry | Calm banner; Plus ends after grace | Xcode config (billing retry on renewal) |
| Billing grace period | Plus stays; banner shown | Xcode config (grace period) |
| Refund | Plus ends; data kept | Xcode config, Sandbox |
| Offer code | Plus granted; OFFER_REDEEMED reaches the server | Sandbox, TestFlight |
| Monthly to yearly and back | Correct status and renewal date | Sandbox |
| Restore on a second device | Plus restored | Sandbox |
| Price increase consent | Apple's sheet appears; status unchanged until accepted | Xcode config |
| Interrupted purchase | Completes after the interruption | Xcode config |
| Purchase fails | "That didn't go through. Nothing was charged." | Xcode config (fail transactions) |
| Lapse with 4 kinds of day | All keep working; adding a fifth asks for Plus | Xcode config |
| Server notifications carry `appAccountToken` | Server links the account | Sandbox |

### 3.6 Device matrix (Apple Intelligence iPhones only)

| Device | Why |
|---|---|
| iPhone 15 Pro | Oldest supported chip (A17 Pro): performance floor, latest iOS 26 |
| iPhone 16e | Small 6.1 inch screen, lower-cost model, Action button |
| iPhone 16 Pro or 17 | Mid-range reference, iOS 27 |
| iPhone 17 Pro Max | Largest screen, layout at AX5 |
| iPhone Air | Different aspect ratio |
| A non-eligible iPhone (iPhone 15 or older) | Gate copy only |

- iOS: the oldest 26.x available in the simulator, the latest 26.x, and 27.x on devices.
- States: Apple Intelligence on, off and downloading; device language English (Australia) and one language Apple Intelligence does not support; region AU, US and NZ; Low Power Mode; light and dark; VoiceOver.
- Any iPhone released after this list joins the matrix before the next release.

### 3.7 Safety and privacy tests

- The 500-prompt red-team set runs before every release against the on-device model paths and your own AI (with a test key).
- Network inventory test: a debug proxy confirms the app contacts only Apple, the Focus server, and the person's chosen AI host.
- Payload tests on sync batches (ciphertext only) and on AI requests (no health content).
- Backup exclusion checked on a device backup; crash reports (Apple's and the opt-in scrubbed ones) reviewed for medicine names each release.

### 3.8 TestFlight beta

- Internal group: the owner and reviewers (up to 100 App Store Connect users).
- External groups: co-design panel of 8 to 12 paid adults with ADHD who see every major screen; pilot of 20 to 40 adults, a mix of students and workers, most on medication, recruited through ADHD communities (university ethics approval first if results will be published).
- External builds need Beta App Review and expire after 90 days; each build carries the same consent flows as release.
- Feedback through TestFlight screenshots and the weekly three questions; no health data is asked for in feedback.
- Pilot learning metrics come only from a consented, tester-initiated export, never from telemetry.

## 4. Release checklist

### 4.1 App Store Connect setup

- App record: bundle ID `au.adhdslayer.focus`, the reserved name (never "ADHD Slayer"), subtitle, SKU, primary language English (Australia).
- Category: Productivity (primary); never Medical.
- Availability: Australia only. Price: free with in-app purchases.
- Agreements: Paid Applications Agreement, tax and banking complete; Small Business Program enrolled.
- Export compliance: answer the encryption questions (HTTPS and CryptoKit AES-GCM for sync) with the lawyer, and set `ITSAppUsesNonExemptEncryption` to match.
- App Store Server Notifications V2 URLs (production and sandbox) and an In-App Purchase key for the App Store Server API.

### 4.2 Subscription products and introductory offer

- Group "Focus Plus" with `au.adhdslayer.focus.plus.monthly` (1 month) and `au.adhdslayer.focus.plus.yearly` (1 year), yearly ranked above monthly.
- Prices set by the owner (the local test file uses A$7.99 and A$59.99).
- Introductory offer on both: Free, 1 month, new subscribers.
- Display names and descriptions in English (Australia): "Unlimited kinds of day and activity categories."
- A review screenshot of the paywall for each product.
- Billing Grace Period 16 days; Family Sharing off unless decided otherwise (it can't be turned off later).
- Offer codes for hardship and student campaigns.

### 4.3 Privacy

- Privacy Policy URL: https://focus.adhdslayer.au/privacy (live, reviewed).
- App Privacy answers as in 06, section 10.1; tracking: none; add Crash Data (not linked) only when opt-in crash reports ship.
- `PrivacyInfo.xcprivacy` in the app and every extension; Xcode's privacy report checked on the archive.
- Usage strings present for every permission the build uses.

### 4.4 Review notes and demo account

- Review notes (plain text, no dashes):
  - "Focus is a day planner for adults. It needs Apple Intelligence on the device: iPhone 15 Pro or later, Apple Intelligence on, device language English. Other iPhones see a screen explaining this."
  - "Sign in with Apple works with any Apple Account. Or use email review@focus.adhdslayer.au and the code in the next line; it works only for this address."
  - "Why an account: it powers end to end encrypted backup so people can move to a new phone. Health information is never stored in iCloud."
  - "To delete the account: You, swipe to The fiddly bits, Settings, Account and Focus Plus, Delete my account."
  - "Focus records what people log and plans their tasks around their own routine. It never suggests doses or timing. Your own AI is optional, off by default and disclosed before use."
- The review email account is a sandbox account with no real data; its code rotates for each submission and is disabled between reviews.

### 4.5 Age rating

- Answer the questionnaire honestly (it covers medical and wellness topics) and set the rating to 18+, using the higher-rating option if the answers calculate lower.

### 4.6 Listing

- Description starts with what Focus does, states "Requires an iPhone with Apple Intelligence (iPhone 15 Pro or later)", and links the Terms of Use and Privacy Policy.
- Screenshots from the real app with kind labels, never medicine names; no claims from the banned list.
- Keywords from the approved list; support URL https://focus.adhdslayer.au/support; copyright line with the company name.
- Every listing text passes the banned-words scan and is in the claims register.

### 4.7 Build and final checks

- Release configuration: no DEBUG code, demo data, `-plus` path or demo purchase path.
- An app icon (1024 by 1024, plus the dark and tinted variants) with no pill, capsule or medical imagery; the asset catalog has none yet.
- Version 1.0, build number incremented; dSYMs uploaded; tested on TestFlight from the same build.
- Links live: Terms, Privacy, Support, the `apple-app-site-association` file.
- Server in production with monitoring, alerts, backups and the breach plan printed; support inbox staffed.
- Signed off: lawyer letter, clinical review, claims register, red-team run, accessibility audit, security test.
- Phased release selected; manual release after approval.

## 5. Owner tasks outside the code

### 5.1 Company and Apple

- Register a Pty Ltd and ABN; get a D-U-N-S number (free through Apple's lookup).
- Enrol in the Apple Developer Program as the organisation (A$149 a year); accept agreements; add tax and banking.
- Reserve the App Store name early and run a trademark search on it.
- Enrol in the App Store Small Business Program (15% commission under US$1 million a year).
- Decide prices, Family Sharing, and the student and hardship offer codes.

### 5.2 Capabilities on the App ID

- Sign in with Apple (`com.apple.developer.applesignin`), plus a Sign in with Apple key (for validation and token revocation) and the server notification endpoint.
- Private Email Relay: register the sending domain so emails reach hidden addresses.
- In-App Purchase (on by default).
- Associated Domains: `applinks:focus.adhdslayer.au` for the email sign-in link.
- App Groups: `group.au.adhdslayer.focus` for the widget extension.
- HealthKit (`com.apple.developer.healthkit`) for reading sleep, with `NSHealthShareUsageDescription`; no write access requested.
- Time Sensitive Notifications only for reminders the person marks; Push Notifications only when multi-device sync needs a content-free push (Later).
- An entitlements file in the project for each target.

### 5.3 Google sign-in

- A Google Cloud project with an External OAuth consent screen: app name Focus, support email, logo, authorised domain adhdslayer.au verified in Search Console, Privacy Policy and Terms links, scopes openid, email and profile.
- An iOS OAuth client for `au.adhdslayer.focus`; put the client ID in Info.plist as `GIDClientID` and the reversed client ID as a URL scheme; give the server the client ID as the accepted audience.
- No Google SDK: sign-in runs in Apple's web authentication session with PKCE.

### 5.4 Domain and pages at focus.adhdslayer.au

- Pages: /terms, /privacy, /support (FAQ, contact, crisis lines), /auth/email (the sign-in link landing, which asks people to open it on their iPhone or type the code), and later a consumer health data policy if the US opens.
- `/.well-known/apple-app-site-association` served as JSON with no redirects, covering `/auth/email*`.
- HTTPS only; no analytics, tracking pixels or marketing cookies on any page.
- Email authentication for the sending domain: SPF, DKIM and DMARC.

### 5.5 Hosting

- Backend in AWS ap-southeast-2 (Sydney) with backup copies in Melbourne, as in 02-backend.md: a small service, Postgres, object storage for encrypted snapshots, managed keys, 35-day backups, monitoring, alerts and budget alarms; email through Amazon SES in Sydney.
- Processor agreements with every provider; a record of where each copy of data lives.
- Staff access: least privilege, multi-factor, removed the day someone leaves.
- A written breach response plan and register (06, 6.2), rehearsed once before launch.

### 5.6 Legal and clinical review

- Australian health and privacy lawyer: the honest bit, every fixed line, consent wording, Terms, Privacy Policy (including automated decisions before 10 Dec 2026), the AI warning, subscription and consumer law wording, the claims register, retention and the breach plan. Written sign-off before external TestFlight.
- Insurance through a broker: professional indemnity and cyber.
- Clinical reviewer (a GP, psychiatrist or pharmacist): Medication page wording, Get support content and numbers, the crisis keyword list and the low-days threshold. Written sign-off.
- Licences for the dusk façade and baroque interior backdrop photographs, kept on file.
- A diary reminder for November 2026 to update the policy before the 10 Dec 2026 law changes.

### 5.7 Support

- A support inbox at the domain with an auto-reply that lists crisis lines and says Focus can't give medical advice.
- Templates: billing (Apple handles it), device requirement, medication questions (referral line), data requests (answered within 30 days), crisis.
- Checked every day; answered within 2 business days; every App Store review answered within 3 business days.
- A 90-day shutdown notice promise in the Terms, and export kept free forever.
