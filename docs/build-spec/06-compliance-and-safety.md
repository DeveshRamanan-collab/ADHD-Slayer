# Compliance and safety

The concrete rules Focus follows, where each one lives in the product, and its status: **Built** (in the app code today), **To build**, or **Later** (after launch). This is a build document, not legal advice: the Australian health and privacy lawyer and the clinical reviewer named in 09-build-plan.md sign off every fixed line before launch.

- The rules apply to every surface: app screens, notifications, widgets, Live Activities and controls (when built), Siri and Shortcuts replies, emails, the App Store listing, the website at focus.adhdslayer.au, and anything an AI model writes.
- Where the research and an owner decision differ, this file follows the owner decision and adds the safeguard that keeps it safe.
- Code references point at `app/FocusApp/FocusApp/` and `app/FocusCore/`.

## 1. The red lines

- **R1. Never suggest, calculate or prompt a dose action.** No screen, notification, Siri reply, plan change or AI output tells anyone to take, skip, move, add, double, delay or change a dose, including short-acting doses. Built: `PlanChange` has no medication case; `FocusPlanning` cannot import `FocusMedication`, so no planner, learner or model path can write a dose.
- **R2. No dose maths.** No calculators, conversions, equivalence tables, maximum-dose warnings or "safe interval" advice. Strength is free text the person types for their own record. Built.
- **R3. Dose times are fixed inputs.** The planner moves tasks, never doses. When work does not fit it splits, defers, shrinks to the baseline day or flags the deadline (`CapacityRemedy`). Built.
- **R4. Reminders only at times the person set.** A time the app works out (for example a usual logging time) becomes a reminder only after the person confirms it. To build: no medication reminders exist yet.
- **R5. No booster, catch-up or late-day prompts.** A dose that passes without a log gets no prompt; its row just says "Not logged". To build with reminders.
- **R6. Taken means tapped.** A dose is logged only by a deliberate action: a button, Log all, the Action button, Siri or Shortcuts (`UserGesture`). Snooze, dismiss or ignore never logs. Built for current paths; To build for notification actions.
- **R7. Log all logs only what is set for about now.** "About now" means planned from 90 minutes before to 60 minutes after the current time. Older unlogged doses are never swept in. To build: `AppModel.dueDoses` has no lower bound today.
- **R8. Double-dose guard.** A second log of the same medication inside its relog interval shows the earlier time and needs a 1.2 second hold to add another; cancelling saves nothing. Intervals: All day 8 h, Short-acting 2 h, Wind-down 12 h, Something else 6 h. Built (`DoseLog`, `LogDoseSheet`, `HoldToConfirmButton`).
- **R9. One person, one log.** No logging for anyone else, no sharing, gifting, trading or ordering of medicine. Built (no such feature).
- **R10. No safety judgements.** Never "safe", "unsafe", "prevents overdose" or "OK to take". Built in fixed copy; enforced by the banned words scan.
- **R11. No health alerts tied to medication.** No heart rate, sleep or mood alert that mentions a medicine or a condition. Apple Health sleep (To build, read only) is shown on Rhythm, stays on the iPhone, and is never linked to medication or used for an alert.
- **R12. No example doses.** Starter content and placeholders never show a real medicine name with a strength. To build: `MedicationFile.starter()` ships Vyvanse 50 mg, Dexamfetamine 5 mg and Melatonin 2 mg, and the editor placeholders say "e.g. Vyvanse" and "e.g. 50 mg". Ship an empty list and the placeholders "Name, as on your label" and "Strength, as on your label".
- **R13. Medication-free days are never missed.** A kind of day with no doses plans from routine with no warning. Built (`dayLineRoutine`, test `unmedicatedDayStillProducesAPlan`).

## 2. Wording rules

### 2.1 Banned words and what to say instead

| Never say | Say instead | Scan covers |
|---|---|---|
| due, dose due, next dose | set for 8:10, planned for | UI, notifications, Siri, email |
| onset, kicks in | working well after (the person's own slider) | UI, AI output |
| wear off, wears off, crash, rebound, coverage | stops helping after, focus lightens | UI, AI output |
| booster, top up (as a prompt) | Short-acting (a kind, never an instruction) | UI, AI output |
| predicts, prediction (about medicine) | usually, from your check-ins | UI, App Store |
| optimal, optimise (medicine, dose, timing) | best focus (the person's focus only) | everywhere |
| effectiveness, how well it works, is it working | focus, focused right now | UI, check-ins |
| safe, unsafe, safe to take | the fact: "Already logged at 7:42" | everywhere |
| pharmacokinetic, half-life, blood level, peak, dose window, medication window | focus window, focus pattern | everywhere |
| sleep medication, sleeping pill, sleep aid, sedative, helps you sleep | wind-down | everywhere |
| treat, manage, reduce symptoms, improve ADHD, cure, clinically proven | plans your day, your routine written down | everywhere |
| calculates, measures, monitors, controls (medicine) | records what you log | everywhere |
| AI health coach, ask our AI about your meds | Apple Intelligence writes your five priorities | App Store, UI |
| 100% private, never leaves your phone, never shared, fully anonymous, stays in Australia | encrypted; processed on your iPhone where possible | everywhere |
| no refunds, we are not responsible (as a blanket line) | Refunds are handled by Apple. This doesn't limit your rights under the Australian Consumer Law. | UI, Terms |
| missed, failed, behind, overdue, streak, broken | not logged yet, resting, paused | UI, notifications |
| study hack, focus pill, think you have ADHD? | nothing | marketing |
| take, skip, double, increase, reduce, stop (as instructions about medicine) | past-tense questions only: "When did you take it?" | everywhere |

- Built: `docs/copy/merge.py` checks Copy.json for dashes, placeholders, lengths and banned words; `PriorityFacts.clean` rejects medication words in the five priorities; `SafetyGate` has the dose, timing, amount, effect, device, safety and treatment patterns.
- To build: one shared banned list used by merge.py, a unit test over every string literal in the app, `SafetyGate`, notification templates, emails and the App Store metadata file.
- Allowed: "Best focus", "Warming up" and "Lighter focus", because they describe the person's focus, not a medicine.
- The medication sliders keep the owner's names ("Working well after", "Stops helping after", "You can usually sleep after") and always sit above "These are your own experience, written down. They don't change what you take or when." Built.
- Check-ins ask about the person, never the medicine: "Focused right now?" with Yes, Partly, No. To build (check-ins are not collected yet).

### 2.2 Where a condition may be named

- Allowed: in-app audience references with no outcome claim, such as the greeting and the trial message ("ADHD takes time to understand, and so does knowing whether an app helps"). Built.
- Never: notifications, Lock Screen, widgets, Live Activities, Control Center, calendar titles, email subjects and bodies, the App Store name and subtitle, the social message draft, anything sent to the person's own AI.
- To build: the honest bit says "ADHD or any other condition"; change it to "any health condition". `ExternalAI.ask` sends "someone with ADHD" in its system prompt; replace it (2.4).

### 2.3 Fixed lines

Fixed lines never rotate, never joke, and change only through legal review.

| Line | Exact text | Where | Status |
|---|---|---|---|
| Referral | That's one for your prescriber or pharmacist. | guard sheet, `SafetyGate.referral`, your own AI replies about medication, support replies | Built (guard, gate, AI replies); To build (support) |
| Medication screens | Not medical advice. Follow your prescription and check with your doctor or pharmacist. | log sheet; Medication page, medication editor, kind of day editor, reminder setup | Built (log sheet); To build (the rest) |
| Guard | Already logged. [time], [n] ago. Logging again adds a second dose to today's record. | log sheet | Built |
| Late note | Your prescriber or pharmacist can advise how late is appropriate for your medication. | once, when a reminder or a logged dose falls after the person's usual sleep time | To build |
| Crisis, Australia | In an emergency, call 000. To talk to someone now, call Lifeline on 13 11 14. | honest bit, Get support | Built (align honest bit wording) |
| Crisis, US | In an emergency, call 911. To talk to someone now, call or text 988. | same, when the device region is US | To build (reviewer verifies) |
| AI labels | Written on your iPhone by Apple Intelligence. / From your own AI, not from Focus. | five priorities source line, Ask sheet | Built |
| Discreet labels | All day, Short-acting, Wind-down, Something else | every glance surface | Built (bottom bar); To build (widgets, notifications) |

- The copy deck's serious-tone slots (`accountBody`, `coachMeds`, `medsNothingDue`, `medsNone`, `dayLineRoutine`, `detailWindow`, `rhythmFooter`) currently rotate like the rest. To build: pin each serious slot to one reviewed line so it never rotates, as the owner decided.
- Buttons and labels are compiled strings outside the deck, so they never rotate. Built.

### 2.4 Text sent to other systems

- Your own AI, new system prompt (To build): "You help someone plan their day. Keep answers short and kind. Do not give medical or medication advice. If asked, reply: That's one for your prescriber or pharmacist." No condition, medicine or health words.
- Social message drafts (`socialMessage` slot) never mention medicine, focus windows, health or a condition. The person edits and sends it themselves (Built: `ShareLink`); validator rule To build.
- Calendars: Focus writes nothing to calendars today. Any future written block has a neutral title and no medicine name.
- Emails: section 9.

## 3. Crisis routing

- Get support is a static screen bundled in the app: no network, no AI, the same for everyone, and opening it is not recorded. Built (`GetSupportView`).
- Numbers follow the device's current region (`Locale.current.region`), not the account country, so travellers see local lines. To build (Australian lines are hard-coded today).

| Region | Emergency | Talk to someone | Status |
|---|---|---|---|
| Australia | 000 | Lifeline 13 11 14; text 0477 13 11 14; chat at lifeline.org.au | Built (call); To build (text and chat links) |
| United States | 911 | 988, call or text; chat at 988lifeline.org | To build |
| Anywhere else | "Call your local emergency number" | no number until the clinical reviewer verifies one | To build |

- Links: `tel:` for calls, `sms:` for texts, `https:` for chat. The screen works offline because it is bundled.
- Entry points, each at most 3 taps away: the honest bit (Built), You page 2 "If things feel like too much" (Built, removable in Customise), Settings, Safety and legal (Built, never removable), the Medication page footer (To build), the Ask your AI sheet (To build), the brain weather Low answer (To build).
- Get support is never behind the Apple Intelligence gate. To build: after onboarding the gate must not block the app (07, T06).
- Deterministic keyword route (To build): free text the person types (Ask your AI question, task titles) is checked on the iPhone against a crisis list the clinical reviewer maintains ("suicide", "kill myself", "end it all", "self harm", "overdose", "don't want to be here" and variants). A match shows "If things feel like too much, you don't have to handle it alone." with a Get support button, and the text is not sent to any AI. Works offline and with Apple Intelligence off.
- The same route catches medication questions and taking more than prescribed ("should I take", "how much", "extra dose", "not prescribed") and answers with the referral line plus "A GP or pharmacist can help, without judgement." Never harm-reduction dosing advice. To build.
- No model ever judges urgency or decides whether something is a crisis.
- Persistent low days: after 5 Low brain weather answers in 7 days, show the support card once, then not again for 7 days. Signposting only. To build; threshold confirmed by the clinical reviewer.

## 4. The 18+ gate

- The account step has "I'm 18 or older"; the sign-in buttons stay disabled until it is on, with "Focus is for adults for now." Built (`AccountView`, `@AppStorage("confirmedAdult")`).
- Store only the time the person confirmed: `adultConfirmedAt: Date`, sent with sign-up (02-backend.md). Never a date of birth. To build: today only a local flag is kept.
- No account and no data exist before the gate passes. Built.
- App Store age rating 18+ (09, release checklist).
- No child or teen features and no parent accounts. A 16 and 17 tier is not planned; review it after the Children's Online Privacy Code is registered (due by 10 Dec 2026). Later.
- If the US opens: check state app store age laws and use Apple's Declared Age Range API where a state requires an age signal. Later.

## 5. Consent

### 5.1 The honest bit (notice acceptance)

- Order: device check, start animation, greeting, the honest bit, account. It cannot be skipped and has one button, "I understand". Built.
- Content today: a planner, not a medical device; doesn't diagnose, treat, monitor or prevent; never says what, how much or when; talk to your doctor or pharmacist; 000 and Lifeline. Built.
- To build: say "any health condition" instead of naming ADHD; add "Take your medication as prescribed and follow the label." and "Keep seeing your doctor alongside Focus." (Apple 1.4.1); add links to Terms and Get support.
- Versioning: `@AppStorage("noticeAcceptedVersion")`, current version 1. Built. To build: also save `noticeAcceptedAt`; when the meaning changes, raise the version and at next launch show the new notice full screen before anything else, with a one-line "What changed" and the same single button.
- Accepting the notice is not consent to anything else.

### 5.2 Terms and Privacy Policy

- The account screen says "By continuing you agree to the Terms and the Privacy Policy." Built as plain text. To build: make both phrases links, and save `termsVersion`, `privacyVersion` and their times with the account.
- Material change: at next launch show a one-screen summary with both links and "Got it"; export and delete sit on the same screen.

### 5.3 Health information consent

- Separate and explicit, asked on the Medication page before anything is stored; the page stays disabled until "Yes, store them". Built (`@AppStorage("healthConsent")`).
- To build, new wording with no absolute promise: "Your medication details are health information. Focus keeps them on this iPhone, encrypted, and uses them only to plan your day. A copy is kept end to end encrypted on our server in Australia so you can move to a new phone. We can't read it, and we never sell it or use it for ads. Is it OK to store them?" Buttons "Yes, store them" and "Not now"; link "What leaves this phone".
- Covers: medication names and strengths, kinds of day with dose times, the dose log and its audit trail, check-ins, learned focus patterns and brain weather. Sleep read from Apple Health has its own iOS permission, stays on the iPhone and never goes into the encrypted backup.
- Gap to close (To build): the bottom bar Log button, Log all, the Action button and Siri can log before consent. Before consent they store nothing; the app opens the consent card and the intent replies "Open Focus to finish setting up your medication first."
- Consent record, stored in the protected store and synced end to end encrypted (To build):

```swift
struct ConsentRecord: Codable, Identifiable {
    enum Purpose: String, Codable { case notice, terms, privacy, health, calendar, ownAI, analytics, marketingEmail }
    let id: UUID
    let purpose: Purpose
    let version: Int          // wording version shown
    let grantedAt: Date
    var withdrawnAt: Date?
    let detail: String?       // provider for .ownAI, e.g. "Anthropic"
}
```

- Withdraw (To build): Settings, Privacy, "Health information". Sheet: "Stop storing medication details? Focus deletes your medications, doses, check-ins and learned patterns from this iPhone and from sync. Your plan keeps working without them." Buttons "Delete and stop" and "Keep".

### 5.4 Other consents, each separate

| Consent | Asked when | Default | Withdraw | Status |
|---|---|---|---|---|
| Calendar (full access) | first use in Personalise or Settings, after a one-screen explainer | off | iOS Settings; social suggestions toggle | Built (permission); To build (explainer) |
| Notifications | first reminder, or right after the trial starts, after an explainer | off | iOS Settings | Built (no explainer); To build |
| Your own AI | before the first connection, per provider | off | Settings, Your own AI, Disconnect | Built (`acceptedWarningAt`); To build (per provider) |
| Marketing email | separate unticked box after onboarding, never at sign-up | off | unsubscribe link, Settings | Later |
| Crash reports | once, after a crash, with equal Send and Don't send buttons | off | Settings, Privacy | To build |
| Usage counts | a quiet card after 7 days, never in onboarding | off | Settings, Privacy | Later |
| Apple Health (sleep only) | on the Sleep and done page, after an explainer | off | Health app | To build |

- Paid features never depend on any consent (Apple 5.1.1). Built: Plus only lifts the day type and category limits.

## 6. Privacy law

### 6.1 Australia

- Focus complies fully with the Privacy Act and the Australian Privacy Principles from day one, whatever the turnover, because it holds health information.
- Health information is sensitive information: collect it only with consent and only what planning needs (APP 3). No date of birth, diagnosis, prescription proof or prescriber details. Built.
- APP 1: the Privacy Policy at focus.adhdslayer.au/privacy covers what is collected and why, where it is held (iPhone; Australian server as ciphertext), overseas recipients, access, correction and complaints.
- APP 1 from 10 Dec 2026: the policy also says what the planner decides by itself (placing tasks, picking today's kind of day, the five priorities, social suggestions), which data it uses, and that it never decides anything about medication.
- APP 5: a short collection notice where data is collected: account screen, health consent card, AI warning. Built (wording To build).
- APP 6 and 7: use data only to plan; no marketing from health information; no secondary use; no model training.
- APP 8: check and contract each overseas recipient (Apple, Google when chosen, the email provider if outside Australia, any support tool). Your own AI is sent by the person, from their iPhone, to a provider they chose, with their key; the policy and warning say so.
- APP 10 and 13: edit or delete any dose (edit and undo exist in `DoseLog`, UI To build); view and reset learned patterns (Patterns page, Built); edit medication details (Built).
- APP 11: protect data (file protection, Keychain, end to end encrypted sync) and delete it when no longer needed (section 12).
- APP 12: access through the in-app export (To build: full export) and by email, free, answered within 30 days.
- Complaints: acknowledge within 7 days, answer within 30, then tell the person they can complain to the OAIC.
- The statutory tort for serious invasions of privacy makes leaks of stimulant use actionable by the person; minimise and protect accordingly.

### 6.2 Notifiable Data Breaches scheme

- An eligible data breach is unauthorised access to, disclosure of, or loss of personal information likely to result in serious harm. Treat any breach touching health information, account emails or sign-in tokens as likely serious until assessed.
- Plan (written document in 09):
  - Contain within hours and keep the evidence.
  - Assess within 30 days at most; aim for 72 hours.
  - Notify the OAIC with the statement (who we are and how to reach us, what happened, the kinds of information, what people should do) and notify affected people as soon as practicable, by email and an in-app card.
  - Record every incident, notifiable or not, in a breach register.
- Scenarios to rehearse: server compromise (ciphertext, but emails and timing exposed), a mis-sent email, an email provider leak, a crash log or support email holding a medicine name, an SDK added by mistake.

### 6.3 If the EU or UK opens (Later)

- Explicit consent for health data (GDPR Article 9); the health consent card and record qualify when they name the purposes.
- Privacy notice (Articles 13 and 14); access, correction, deletion, restriction, objection and portability answered within one month.
- Breaches: the supervisory authority within 72 hours; people without undue delay when the risk is high.
- A data protection impact assessment before launch; EU and UK representatives if there is no office there; a processor agreement with every processor; a transfer mechanism for data sent to Australia.
- Tell people when they deal with AI (EU AI Act Article 50); labels already exist.
- Marketing email only with consent (ePrivacy, UK PECR).

### 6.4 If the US opens (Later)

- Washington My Health My Data Act: separate consent to collect and to share consumer health data; a separate Consumer Health Data Privacy Policy linked from the website home page; access and deletion (including archives and backups) within 45 days; no sale; people can sue.
- Nevada and Connecticut consumer health data rules carry similar consent and policy duties; recheck other states at the time.
- FTC Health Breach Notification Rule: unauthorised sharing is a breach; notify people within 60 calendar days, the FTC as well if 500 or more are affected, and the media if 500 or more in one state.
- Privacy claims must match what the app does (FTC Act section 5).

## 7. App Store Review Guidelines that apply

| Guideline | What it needs | How Focus meets it | Status |
|---|---|---|---|
| 1.4.1 | Remind people to see a doctor; no unsupported accuracy claims | honest bit, medication screen line, no accuracy numbers | Built / To build (lines) |
| 1.4.2 | No dosage calculators | no dose maths anywhere (R2) | Built |
| 1.4.3 | No help obtaining controlled substances | no ordering, sharing or trading (R9) | Built |
| 2.1 | Complete app, no demo content, working demo account | remove seeded data; review account | To build |
| 2.3 | Accurate metadata and screenshots | real screens, kind labels not brand names, device requirement stated | To build |
| 3.1.1, 3.1.2 | Digital features only via in-app purchase; clear subscription terms | StoreKit 2 only; paywall terms, Terms and Privacy links | Built |
| 4.5.4 | Push not required, nothing sensitive in pushes | no pushes today; silent backstop carries no content | Built / To build |
| 4.8 | A privacy-friendly login beside Google | Sign in with Apple offered first | Built (UI); To build (capability) |
| 5.1.1(i) | Privacy policy in app and App Store Connect | links in paywall and Settings | Built / To build (ASC) |
| 5.1.1(ii) | Consent; paid features never need data access | separate consents; Plus unaffected | Built |
| 5.1.1(v) | In-app account deletion; login only when justified | delete in Settings; sync justifies account | Built (UI); To build (server) |
| 5.1.1(ix) | Health apps submitted by a legal entity | Pty Ltd publisher | Owner (09) |
| 5.1.2(i) | Disclose sharing with third-party AI and get permission first | Your own AI warning and toggle | Built |
| 5.1.3(i) | No health data for ads, marketing or data mining | no SDKs, no marketing use | Built |
| 5.1.3(ii) | No personal health information in iCloud; no false Health data | backup exclusion, own encrypted sync | To build |

### 7.1 Account first (5.1.1(v))

- Risk: Apple may say the app does not need an account to work.
- Mitigation: the account powers end to end encrypted backup and moving phones; Sign in with Apple takes one tap; deletion is in Settings, Account and Focus Plus, "Delete my account"; review notes explain all three (09).
- Fallback, ready before submission (To build): "Continue without an account" on the account screen behind a remote flag, keeping everything on the iPhone. Settings already handles "Not signed in. Your plan stays on this phone only." (Built).

### 7.2 Sign in with Apple and deletion

- Sign in with Apple sits beside Google and email, which satisfies 4.8. Built (UI); capability `com.apple.developer.applesignin`, server token validation and credential state checks are To build.
- Deletion (To build on the server): delete the account, sync data and backups; revoke the Apple token through Apple's revoke endpoint; wipe the iPhone; say the subscription continues until cancelled with Apple (Built text) and offer "Manage subscription" in the same dialog.

### 7.3 Health data and iCloud (5.1.3(ii))

- No personal health information in iCloud, including iCloud Backup.
  - Built: `medication.json` is written with `.completeFileProtection` and `isExcludedFromBackup` after every save; `LogMedicationIntent` has `authenticationPolicy = .requiresAuthentication`, so a locked phone asks for Face ID first.
  - To build: the same protection and exclusion for the ledger, check-ins and learned state, checked at every launch.
  - To build: move health-derived values out of UserDefaults: `Tuning.windowOverride`, `Tuning.mealRuleMinutes` and the Personalise windows measured from the first dose.
  - No iCloud capability at all: no CloudKit, iCloud Drive or key-value store.
- Keychain items are this-device-only, so they never sync or back up. Built.
- Apple Health is read only (sleep, To build); Focus never writes to Health.

### 7.4 AI features

- Focus's own AI is Apple's on-device model only; outputs are labelled; the five priorities pass `PriorityFacts.clean`. Built.
- Your own AI replies pass `SafetyGate.screen`; dose talk becomes the referral line. Built. To build: notification templates and any future parser output pass it too.
- Third-party AI: opt-in per provider with a warning naming what is sent (Built); add the provider's country and the endpoint host to the warning (To build).
- Follow Apple's acceptable use requirements for Foundation Models: nothing medical, nothing that fosters dependency, nothing about self-harm.

### 7.5 Subscriptions and trials (3.1.2 and Schedule 2)

- Before purchase the paywall shows: plan, length and price from StoreKit, trial length from StoreKit, the price after the trial, auto-renewal, cancelling at least 24 hours before the trial ends, the 2-day reminder, Restore purchases, Terms and Privacy. Built (`TrialOfferView`).
- To build: after purchase show "Free until 30 Oct, then A$59.99 a year" from `expirationDate`; put the Terms (EULA) and Privacy links in the App Store description too.

## 8. Subscriptions and the Australian Consumer Law

- Products: `au.adhdslayer.focus.plus.monthly` and `au.adhdslayer.focus.plus.yearly`, one group "Focus Plus", a free 1-month introductory offer on both. `Products.storekit` uses A$7.99 and A$59.99 as test values; the owner sets real prices.
- Apple's trial is 1 calendar month (28 to 31 days), not 31 days. Copy says "a month"; lengths and dates come from StoreKit (`trialLength`, `expirationDate`). Built.
- Free plan: 3 kinds of day and 5 categories; everything else is free, including logging, the guard, Get support, export and deletion. Built.
- Consumer guarantees cannot be excluded. The Terms limit liability only "to the extent permitted by law". Never "no refunds".
- No misleading claims about price or benefits: "free" always sits beside the price after the trial. Built.
- Cancelling is as easy as starting: Settings, Account and Focus Plus, "Manage subscription" opens Apple's sheet. Built. "Cancel any time" is used only while this stays true.
- Trial reminder 2 days before conversion at 10:00 local. Built for purchases made in the app. To build: schedule it whenever the app sees an active trial without a pending reminder; if notifications are off, show an in-app card from 2 days before.
- No dark patterns: "Not now, use the free plan" is as visible as the buy button, and the preselected yearly card shows the full yearly price. Built.
- Refunds: Apple decides. To build: "Request a refund" using Apple's refund sheet, with "Refunds are handled by Apple. This doesn't limit your rights under the Australian Consumer Law."
- Unfair contract terms: the lawyer checks the Terms, including changes, renewal and termination clauses.
- Reviews and testimonials: genuine only; never paid or incentivised.
- Price rises: keep the current price for existing subscribers where Apple allows, and tell them in the app 30 days ahead.

## 9. Email and spam

- At launch Focus sends only transactional email: sign-in links, account deletion confirmation, replies to data requests, breach notices. None carries marketing.
- Subjects and bodies never name ADHD, a medicine or a condition. Sender name "Focus". Example subject: "Your sign-in link for Focus".
- Marketing email (Later) follows the Spam Act 2003: express consent through a separate unticked box; sender identified (Focus, the company name, ABN and contact details); a working unsubscribe honoured within 5 working days; consent records kept; no bought lists or harvested addresses.
- US (CAN-SPAM) and EU or UK (ePrivacy, PECR) rules apply if those markets open. Later.
- Sending setup (To build, 09): SPF, DKIM and DMARC for the sending domain; open and click tracking off; links only to focus.adhdslayer.au; the sending domain registered with Apple's Private Email Relay so people who hid their email still get links.

## 10. Privacy label and privacy manifest

### 10.1 App Store privacy label

| Data type | Collected by us | Linked | Tracking | Purpose |
|---|---|---|---|---|
| Email address | Yes (account) | Yes | No | App functionality |
| User ID | Yes (account id) | Yes | No | App functionality |
| Purchase history | Yes (App Store notifications with the account token) | Yes | No | App functionality |
| Health | Declare yes: medications, kinds of day, doses and check-ins are stored as ciphertext for backup | Yes | No | App functionality |
| Other user content | Declare yes: tasks and settings are stored as ciphertext for backup | Yes | No | App functionality |
| Crash data | Only once opt-in crash reports ship | No | No | App functionality |
| Product interaction | Only once opt-in usage counts ship | No | No | Analytics |
| Name, calendar, contacts, location, Health sleep | No (they stay on the iPhone) | n/a | No | n/a |

- Declaring ciphertext is the conservative choice; the lawyer confirms before submission.
- Data processed only on the iPhone (Apple Intelligence, calendar reading, Apple Health sleep, planning) is not collected.
- Your own AI is sent by the person with their own key and is not collected by Focus; the policy and warning describe it.
- No tracking, no App Tracking Transparency prompt, no ad or analytics SDKs. Built.
- Update the label whenever a new data flow ships (analytics, HealthKit, a crash reporter).

### 10.2 Privacy manifest (To build)

- Add `PrivacyInfo.xcprivacy` to the app target and to every extension:

```text
NSPrivacyTracking             false
NSPrivacyTrackingDomains      []
NSPrivacyCollectedDataTypes   EmailAddress, UserID, PurchaseHistory, Health, OtherUserContent
                              each: Linked true, Tracking false, Purposes [AppFunctionality]
                              CrashData, ProductInteraction only when those opt-ins ship: Linked false
NSPrivacyAccessedAPITypes
  UserDefaults     CA92.1 (app's own defaults); 1C8F.1 (App Group defaults shared with widgets)
  FileTimestamp    C617.1 (only if file dates are read, e.g. backup checks)
  SystemBootTime   35F9.1 (only if uptime measures timers)
  DiskSpace        E174.1 (only if free space is checked before writing an export)
```

- The app uses `UserDefaults` and `@AppStorage` today, so CA92.1 is required now. Declare only what the code uses and check Xcode's privacy report on every archive.
- No third-party SDKs today: Google sign-in uses Apple's web authentication session, not Google's SDK. Any SDK added later brings its own manifest and passes the SDK review in 09.

## 11. Marketing and App Store claims

### 11.1 May say

- "Plans your day around when you usually feel most focused."
- "Log your doses and see your own history."
- "Did I already log it? Check at a glance."
- "Reminders at the times you choose." (only once reminders ship)
- "A planner built with ADHD brains in mind." (audience only, no outcome)
- "Your medication details are encrypted. We don't sell data or show ads."
- "Free to use. Focus Plus adds unlimited kinds of day and categories. First month free."
- "Requires an iPhone with Apple Intelligence (iPhone 15 Pro or later)."

### 11.2 May not say

- Treats, manages, reduces or improves ADHD or symptoms; clinically proven; doctor recommended.
- Anything about dose timing, short-acting doses, optimising medicine, wear-off, onset or effectiveness.
- "Prevents double dosing", "safe".
- "Never leaves your phone", "100% private", "stays in Australia" (unless contracts guarantee where every copy lives).
- "Study hack", medicine as a productivity tool, or anything aimed at people without a diagnosis ("Think you have ADHD?").
- Prescription medicine brand names in ads, keywords or screenshots until the lawyer confirms; screenshots use kind labels ("All day", "Short-acting").
- Claims that features are proven (timers, habits, body doubling), and statistics from self-selected surveys.

### 11.3 Process

- A claims register lists every public claim, where it appears, who approved it and when. Reviewed before each release.
- The banned words scan runs on the App Store metadata, website pages, emails and creator briefs.
- Creator content is disclosed as advertising, claims are clinician reviewed, and nobody talks about medicine.
- App Store name and subtitle never include "ADHD Slayer"; keywords stay neutral (planner, focus, routine, day planner, ADHD as audience).

## 12. Retention

| Data | Where | Kept | Deleted by |
|---|---|---|---|
| Medications, kinds of day | iPhone (protected, no backup); sync ciphertext | until the person deletes them | edit, withdraw health consent, delete everything |
| Dose log and audit trail | iPhone; sync ciphertext | until the person deletes them; audit entries 24 months | edit, undo, delete everything |
| Check-ins, learned patterns | iPhone; sync ciphertext | raw check-ins 12 months, then only learned summaries | reset in Patterns, withdraw, delete |
| Tasks, plans, brain weather | iPhone; sync ciphertext | archived items 12 months | delete everything |
| Deleted records (tombstones for sync and undo) | iPhone; sync ciphertext | 90 days | automatic purge |
| Apple Health sleep | read on demand on the iPhone; derived values only | while the person uses the page | Health permission off, delete everything |
| Account record (id, method, email, versions) | Australian server | while the account exists | account deletion, live systems within 24 hours |
| Sync ciphertext and server backups | Sydney, with backup copies in Melbourne | newest 10 snapshots, none older than 30 days; backups 35 days | account deletion reaches backups within 35 days |
| Inactive accounts | server | 24 months without sign-in, then an email notice | server data deleted 30 days after the notice |
| Entitlement state | server | while the account exists | account deletion |
| Sign-in tokens | server | 15 minutes; spent tokens purged within 24 hours | automatic |
| Server logs | server | 30 days; never bodies, tokens, emails or IPs (IPs only in edge logs, 14 days) | automatic |
| Security audit log (sign-ins, devices, deletions, staff access) | server | 24 months | automatic |
| Crash reports (opt-in, never linked) | server | 90 days | automatic |
| Usage counts (opt-in, Later) | server | raw 30 days; aggregates 25 months | automatic |
| Deletion receipts | server | hashed account id and date, 24 months | automatic |
| Support email | support inbox | 24 months after the last message | automatic |
| Export files | iPhone temporary folder | until shared or the next launch | automatic (To build) |
| Your own AI requests | the person's provider | per the provider's terms | provider |

- Nothing is deleted because someone stopped using the app for a while; only the 24-month inactive rule applies, and only after a notice.
- Company financial records from App Store Connect reports are kept 5 years for tax; they hold no personal health information.
- Status: the retention rules are To build on the server (02-backend.md) and for the local ledger (03-data-model.md).
