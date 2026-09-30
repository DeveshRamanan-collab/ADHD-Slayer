# Problems and solutions

The risk register. Each row says what goes wrong, why it matters, the solution, and where the solution lives with its status: **Built**, **To build**, **Later** or **Owner** (a task outside the code, listed in 09-build-plan.md). Many rows come from reading the current code, so they name the file or type to change.

- Priority: rows in Technical, Scheduling, Data and Safety marked To build block the external beta (09, milestone M9).
- Rules referenced here are defined in 06-compliance-and-safety.md.

## Technical

| ID | What goes wrong | Why it matters | Solution | Where, status |
|---|---|---|---|---|
| T01 | Health files could land in iCloud Backup | Personal health information in iCloud breaks 5.1.3(ii) and the owner's rule | `medication.json` is written with complete protection and `isExcludedFromBackup` after every save (Built); the ledger, check-ins and learned state get the same, checked at every launch | `MedicationFile.save`; Built, To build (other files) |
| T02 | Health-derived values sit in UserDefaults (`Tuning.windowOverride`, `mealRuleMinutes`, Personalise windows from the first dose) | UserDefaults is backed up to iCloud | Move them into the protected store; UserDefaults keeps only look and feel | `AppModel.Tuning`, `Personalisation`; To build |
| T03 | The dose log lives only in memory (`DoseLog` actor) | Logs vanish on relaunch; the guard can't see earlier doses | Event-sourced SQLite ledger behind the same `DoseLogging` contract; existing tests reused | FocusMedication; To build |
| T04 | Demo data ships: seeded doses unless `-freshDay`, `seedDay` tasks and events, `LifeHistory.generate`, `seededModel` check-ins, starter medicines | People see a fake history and example doses; App Review 2.1 | Demo data only under DEBUG or a `-demo` argument; release starts empty | `AppModel`, `LifeHistory`; To build |
| T05 | An undecodable medication file falls back to `starter()` and the next save overwrites the real file | Silent loss of someone's setup after an update | Decode key by key like `CustomSettings`; versioned migrations; move a bad file aside as `.corrupt` and say so | `MedicationFile.load`; To build |
| T06 | After onboarding the Apple Intelligence gate blocks the whole app when Apple Intelligence is off or re-downloading | Logs, the guard and Get support become unreachable | Ineligible iPhones are always blocked; after onboarding, Apple Intelligence being off or downloading never blocks, and the plan-ranked fallbacks run; add a quiet banner | `RootView.gateBlocks`; Built (banner: To build) |
| T07 | Strings the app did not write reach the screen | A reply or imported text could carry dose advice | `SafetyGate.screen` runs on your own AI replies (Built); notification templates and any future parser output pass it too | `ExternalAI`, notifications; Built, To build (the rest) |
| T08 | Foundation Models errors: context over 4,096 tokens, guardrail refusal, unsupported language, model not ready | Priorities or event reading fail mid-day | Keep prompts small, check `tokenCount`, catch every error and show the plan-ranked list | `PriorityWriter`; Built (fallback), To build (token check) |
| T09 | Model output drifts with iOS updates | Priorities get longer or odder | 50-prompt regression set on every iOS beta; `compose()` validation keeps bad wording out | 04-intelligence; To build |
| T10 | One model session per task (`classifyTasks`) and per event (`refreshSocial`) at launch | Slow launch, battery, rate limits in the background | One batched session per launch, results cached by title hash, foreground only | `AppModel`; To build |
| T11 | No midnight rollover: `todaysDoses` never resets and the day is fixed to 07:00 to 22:00 | An app left open overnight shows yesterday; late risers can't plan | Day boundary at 04:00 (settable); react to day change and scene phase; day span from the kind of day | `AppModel.solve`; To build |
| T12 | Intents run while the phone is locked | With complete file protection a locked log would fail | `LogMedicationIntent` has `authenticationPolicy = .requiresAuthentication`, so iOS asks for Face ID first | `LogMedicationIntent`; Built |
| T13 | Widgets, controls and Live Activities can't read the app's container | Glanceables impossible | App Group `group.au.adhdslayer.focus` with a small glance snapshot, kind labels only in discreet mode | 05-platform; To build |
| T14 | `Store.start()` runs from a `.task` that can fire more than once | Duplicate `Transaction.updates` listeners | Start once, guarded, from app init | `Store`; To build |
| T15 | Saves fail silently (`try?` on every write) | The person thinks a change is saved | Surface a calm error, retry, keep the last good copy | stores; To build |
| T16 | There is no way to add, edit or delete a task; the plan runs on seeded tasks and today's calendar | A real person can't use the core loop | Quick add (title; optional rough duration, deadline, kind of work, "a must today"), edit, done, delete, stored in the ledger; a first step per task | Today, Plan; To build |

## Scheduling edge cases

| ID | What goes wrong | Why it matters | Solution | Where, status |
|---|---|---|---|---|
| S01 | Daylight saving: `ClockMinutes.date` adds minutes to the start of the day | On 4 Oct 2026 (NSW, VIC, ACT, TAS, SA) every time after 2 am shows an hour late; on 4 Apr 2027 an hour early | Wall-clock times from date components (`date(bySettingHour:minute:second:of:)`), minutes past 1,440 roll to the next day; tests for 23 and 25 hour days | `ClockMinutes`; To build |
| S02 | Time zone travel: kinds of day are local clock times | Every planned dose silently moves to local time | On zone change ask "Keep your usual times on home time, or switch to local time?" with "check with your prescriber before you travel"; store the home zone; never pick a time | `AppModel`, Settings; To build |
| S03 | Interstate trips into or out of QLD, WA and NT (no daylight saving) | Plans an hour out | Same prompt on any offset change | To build |
| S04 | Night shifts and doses after midnight | A 01:00 dose belongs to the previous shift day | Day boundary (T11) plus `MinuteRange` past 1,440 (Built); a shift kind of day starts at its first dose | To build |
| S05 | Log all sweeps up earlier doses (no lower bound on `dueDoses`) | At 21:00 it logs the 07:00 and 08:10 doses as taken now: a false record that looks like catching up | Due window: planned from 90 minutes before to 60 minutes after now; older ones show "Not logged" and log one at a time with a time | `AppModel.dueDoses`; To build |
| S06 | Late dose | Nothing notes a dose that runs past the usual sleep time | If "you can usually sleep after" lands after the kind of day's sleep time, show the late note once; never block | `LogDoseSheet`; To build |
| S07 | Past logging is limited to earlier today | Can't log last night's wind-down after midnight or fix yesterday | Date and time picker up to 7 days back; edits go through the audit trail | `LogDoseSheet`, `DoseLog.edit`; To build |
| S08 | No undo button after logging (`DoseLog.undo` exists) | A mistaken tap stays in the record | 10-second Undo toast after every log and Log all; history list with edit and delete | Today; To build |
| S09 | Two devices log before they sync | The guard can't see the other device | Both logs stay and show once with "Two logs close together, from two phones. Keep both?"; nothing is merged or dropped silently | 02-backend; To build |
| S10 | Overlapping date ranges on kinds of day | Unclear which applies | Shortest range wins, ties by list order (Built); the editor warns about overlaps | `todayDayType`; To build (warning) |
| S11 | Wind-down set earlier than the other doses | Every focus window is cut | Editor warns "Your wind-down is before your other doses" | `DayTypeEditor`; To build |
| S12 | All-day events are ignored | An exam day plans like any other | Show all-day events on Today; one tap marks them busy | `loadCalendar`; To build |
| S13 | Events keyed by `eventIdentifier` | Moving an event between calendars loses matches and dismissals | Key by `calendarItemExternalIdentifier` plus occurrence start | `AppModel`; To build |
| S14 | Fix my day assumes "running 40 min over" | The preview can be wrong | Ask first: 15, 30, 45, 60 minutes, or "just tidy the rest" | `FixMyDaySheet`; To build |
| S15 | Medication-free day or manual "today is a weekend" choice | Could read as missed or leak into tomorrow | Plans from routine with no warning; manual choice ends at midnight | Built |
| S16 | "Something else" medicines draw a focus window from their default sliders (30 min, 6 h) | A medicine with no daily window shapes the plan as if it had one | A "Shapes my focus day" switch per medication, off by default for Something else | `DayType.automaticWindows`; To build |

## Data

| ID | What goes wrong | Why it matters | Solution | Where, status |
|---|---|---|---|---|
| D01 | Sync conflicts between devices | A dose time change could be dropped | Snapshot merge: logged facts are unioned by id; other records take the newest change; a medication's strength, kind or dose times changed on two phones raises "This was changed on two phones. Check it's right." | 02-backend; To build |
| D02 | Lost sync key (iCloud Keychain off or reset) | The server holds only ciphertext | iCloud Keychain copy of the key (on by default), old-iPhone transfer, or the 24-character recovery key shown once; otherwise start fresh | 02-backend; To build |
| D03 | Lost or stolen phone | Someone else may open the app | Complete protection behind the passcode; revoke the device from another device; Face ID lock | To build, Later (lock) |
| D04 | New phone from iCloud Backup | Health files are excluded, so medication looks gone | Setup on a new phone finds the account and offers "Bring your medication and plans across", saying why backup doesn't carry them | Onboarding; To build |
| D05 | Restore brings back `onboarded` but not the this-device-only Keychain account | Sync silently off | Onboarded with no health store opens on "Welcome back. Sign in to bring your data back." | `RootView`; To build |
| D06 | Export is JSON only, today's doses only, no warning | Fails access rights and the "leave any time" promise | JSON and CSV of doses, kinds of day, check-ins, tasks and consents; "This file contains health information"; temp file deleted after sharing | `DataExport`; To build |
| D07 | Delete everything leaves pending notifications, temp files and memory state until relaunch | Reminders keep firing after a wipe | Cancel all notifications, delete temp files, reset state, return to the start without relaunch | `DataExport.wipe`; To build |
| D08 | Account deletion is local only (`LocalAuthBackend` does nothing) | Server copies survive; Apple token not revoked | Server delete including backups within 35 days, Apple revoke call, confirmation email | 02-backend; To build |
| D09 | Server breach | Emails and sync timing exposed even though payloads are ciphertext | Least metadata, emails in a separate table, breach plan (06) | 02-backend; To build |

## Payments

| ID | What goes wrong | Why it matters | Solution | Where, status |
|---|---|---|---|---|
| P01 | Trial abuse: take the free month, build many kinds of day, cancel | Lost revenue | Apple allows one introductory offer per Apple Account per group; accept the small cost | Apple; Built |
| P02 | Lapsing with kinds of day and categories above the free limit | Switching them off would change plans without warning | Nothing is deleted or switched off; extras keep working and stay editable; only adding more needs Plus | `Store`, Medication page; Built |
| P03 | Refunds | Plus must end after a refund | Revoked transactions are ignored (Built); "Request a refund" sheet; REFUND notification on the server | `Store`, 02-backend; To build |
| P04 | Family Sharing | Once on, it can never be switched off | Keep `familyShareable` off unless the owner decides before launch | Owner |
| P05 | Billing retry and grace period | People lose Plus over an expired card | Billing Grace Period 16 days; "Apple couldn't renew Plus. Update your payment details." linking to manage subscriptions | `Store`, Settings; To build |
| P06 | Offer codes for hardship and students | Codes must be tracked | Redeem sheet (Built); OFFER_REDEEMED on the server; one campaign per code set | Settings, 02-backend; To build |
| P07 | Price rises | Surprise charges cause anger | Keep existing subscribers' price where Apple allows; in-app notice 30 days ahead | Owner |
| P08 | Regional pricing and availability | Other storefronts open before crisis lines and privacy work are ready | Australia only at launch; add a country only with its crisis lines and privacy work | Owner |
| P09 | 1 month is not 31 days | A trial started 31 Jan ends 28 Feb | Copy says "a month"; dates from `expirationDate`; the reminder uses that date | `Store`, `Reminders`; Built |
| P10 | Trial reminder only follows an in-app purchase | Offer codes or other devices get no reminder | Schedule whenever `refresh()` sees a trial with no pending reminder; in-app card if notifications are off | `Store`; To build |
| P11 | Pending purchases (Ask to Buy, bank checks) | Unsure if it went through | "Waiting on Apple to approve that. You can keep going."; `Transaction.updates` grants later | Built |
| P12 | DEBUG demo purchase path ships | Fake purchases | `demoAllowed` is DEBUG only; release checklist checks | Built |
| P13 | Plus follows the Apple Account, not the Focus account | Confusing on shared Apple IDs | StoreKit stays the source of truth; the server links by `appAccountToken` for support | `Store`; Built, To build (server) |

## Accounts

| ID | What goes wrong | Why it matters | Solution | Where, status |
|---|---|---|---|---|
| A01 | Account required before use | App Review 5.1.1(v) risk | Review notes explain sync; one-tap Sign in with Apple; deletion in app; "Continue without an account" fallback behind a flag | Onboarding; To build (fallback) |
| A02 | No Sign in with Apple capability or entitlements file | Sign in with Apple fails on device | Add the capability; validate the identity token on the server; check credential state at launch | Xcode, 02-backend; To build |
| A03 | Google has no client ID | Button shows "isn't switched on in this build yet" | iOS OAuth client, `GIDClientID` and URL scheme; PKCE in Apple's web session; server verifies the token; hide until configured | `AccountStore`; To build |
| A04 | Email link is a stub ("I've tapped the link") | Nobody can sign in by email | Universal Link to focus.adhdslayer.au, single-use token for 15 minutes, 6-digit code fallback, 5 sends an hour per address | `AccountStore`, 02-backend; To build |
| A05 | Email typos or no inbox access | Stuck at sign-in | Show the address, "Change email", resend after 60 seconds, code fallback | `AccountView`; To build |
| A06 | Apple private relay addresses | Sign-in emails never arrive | Register the sending domain with Apple's Private Email Relay | Owner; To build |
| A07 | Apple ID credential revoked in iOS Settings | App still thinks it's signed in | `getCredentialState` at launch plus Apple's server notifications | `AccountStore`; To build |
| A08 | One person, two accounts (Apple, then Google) | Data split | "You already have an account with this email. Sign in the way you did before."; linking methods | To build, Later (merge) |
| A09 | Signing out on a shared phone leaves the data | The next person sees medication | Sign out offers "Keep this iPhone's data" (default) or "Remove it"; another account can't sign in while this data is on the phone | Settings; To build |
| A10 | Deleting the account while subscribed | Apple keeps billing | Dialog says so (Built) and offers "Manage subscription" | Settings; To build |

## Notifications

| ID | What goes wrong | Why it matters | Solution | Where, status |
|---|---|---|---|---|
| N01 | More than 64 pending notifications | iOS drops the rest silently | Rolling 48-hour window refilled on launch, logging and calendar change | 05-platform; To build |
| N02 | "At most five nudges a day" is promised but no budget exists | The promise must stay true | At most 5 delivered per day across all types; reminders the person set come first; lower ones are dropped, never piled up | scheduler (05-platform); To build |
| N03 | Snooze or dismiss logs a dose | False records drive double dosing | Only the explicit "Logged it" action logs, through the guard and after authentication | 05-platform; To build |
| N04 | Discreet mode resets every launch (`discreetMode` isn't saved) | A person's choice is lost | Save it; default on | `AppModel`; To build |
| N05 | Permission asked straight after paying | A surprise prompt | Explainer first: "Want a heads-up two days before your free month ends?" | `TrialOfferView`; To build |
| N06 | `.badge` permission requested | Red counts are banned | Request alert and sound only; never set a badge | `Reminders`; To build |
| N07 | Notifications switched off | Reminders never arrive | Everything still works; in-app cards carry the same facts | To build |
| N08 | Prompts fade with repetition | Ignored after a few weeks | Rotating deck wording for light templates; serious ones fixed | Copy; To build |

## Privacy

| ID | What goes wrong | Why it matters | Solution | Where, status |
|---|---|---|---|---|
| V01 | Lock Screen exposure | A medicine name tells everyone nearby | Every glance surface uses kind labels while discreet mode is on (default) | 05-platform; To build |
| V02 | App switcher snapshot and screen recording | The Medication page shows in the switcher | Blur overlay when the scene goes inactive, if discreet mode is on | App shell; To build |
| V03 | Screenshots of Today shared with friends | Medicine rows visible | Kind labels on Today when discreet mode is on; share features never include medication | `DoseRow`; To build |
| V04 | Shared devices and family members | Anyone holding the phone can open it | Optional Face ID lock for the app and the Medication page | Later |
| V05 | Calendar attendees and titles | Friends' plans are personal information | Read on the iPhone only; never write or edit other people's events | Built |
| V06 | Your own AI gets fixed event titles ("Coffee with Maya") when task names are allowed | A friend's name goes to a third party | Send events as "Appointment" unless a separate "Event titles" switch is on (off by default) | `contextForExternalAI`; To build |
| V07 | Your own AI system prompt names ADHD | Discloses a health condition | Neutral prompt (06, 2.4) | `ExternalAI.ask`; To build |
| V08 | Absolute wording: "Only on this iPhone", "Almost nothing", "None, ever", "never shares or sells them", "All of this stays on your iPhone" | False once sync ships | Rewrite to match the architecture; add to the banned list | `PrivacyDetailView`, Copy.json; To build |
| V09 | The domain contains "adhd" (focus.adhdslayer.au) | An email preview reveals a condition | Sender name "Focus", neutral subjects; consider a neutral sending domain | Owner |
| V10 | Crash reports or support messages with medicine names | An unagreed disclosure | Opt-in crash reports scrubbed on the phone and never linked to an account; the support form asks people to leave medication details out | 02-backend, Settings; To build |
| V11 | Apple Health sleep: a refused permission looks exactly like no data | The app might show zero or claim it is connected | Show "No sleep from Health yet", never zero or "connected"; ask only on the Sleep and done page | Rhythm (05-platform); To build |

## Safety

| ID | What goes wrong | Why it matters | Solution | Where, status |
|---|---|---|---|---|
| F01 | People ask an AI when or how much to take | That would be dose advice | Replies pass `SafetyGate` and dose talk becomes the referral line (Built); a keyword check answers medication questions before any request is sent | `ExternalAI`; Built, To build (keyword check) |
| F02 | Starter doses read as suggestions | "Vyvanse 50 mg" and "Melatonin 2 mg" look like recommendations | Empty start, neutral placeholders (06, R12) | `MedicationFile.starter`; To build |
| F03 | Crisis words typed into free text | Nobody notices someone in trouble | On-device keyword route to Get support | To build |
| F04 | Crisis lines hard-coded for Australia | A US user sees 000 and Lifeline | Region-based lines | `GetSupportView`; To build |
| F05 | Get support can be hidden in Customise (You page 2) | Help gets harder to find | Settings, Safety and legal always keeps it | Built |
| F06 | Minors tick "18 or older" | Adult-only app | Declared gate, 18+ rating, Terms; delete the account when told | Built |
| F07 | Wind-down described as a sleep medicine | Implies a treatment purpose | Banned words in the deck and code; starter drops "Melatonin" | copy tooling; To build |
| F08 | The guard nudges people to log again | It must stay neutral | Primary button is "Keep one log"; the hold is secondary | Built |
| F09 | A typo strength ("500 mg") | Tempting to warn | Never quote maximums; strength is the person's own record | Built |

## ADHD experience

| ID | What goes wrong | Why it matters | Solution | Where, status |
|---|---|---|---|---|
| X01 | Account and trial before any value | Drop-off at the start | One screen per beat, skippable coach marks, no setup wizard; measure drop-off per beat in TestFlight | Onboarding; Built |
| X02 | Clutter creeps in as features grow | Busy screens overwhelm | You tab rule (page 1 name plus two rows, page 3 four rows); controls one level deeper; stable navigation contract | `YouView`; Built |
| X03 | Novelty wears off after two to three weeks | The app quietly stops being opened | Rotating lines and the arrival page (Built); widgets and a welcome back after 3 days away with no backlog | To build |
| X04 | Shame after a bad week | Avoidance | No red counts, streaks or "missed"; "X of 7 days counted"; banned words scan | Built |
| X05 | Customisation becomes a hyperfixation | Hours lost in settings | The warning, categories one level deep, "Put everything back how it was" | Built |
| X06 | Rotation makes the app feel unstable | Anxious and autistic users lose their bearings | Only voice lines rotate; buttons, labels and layout never do | Built |
| X07 | A joke lands on a bad day | Feels mocking | On a Low brain weather day use straight lines only | `Copy.line`; To build |
| X08 | Coach marks skipped then missed | Features stay unknown | "Show the tour again" in Settings | Settings; To build |
| X09 | Five priorities feel like too many | Choice overload | Customise, Home page: 3 or 5 | Built |
| X10 | Haptics overwhelm | Sensory overload | Off switch and strength slider; every haptic has a visual | Built |
| X11 | Early learned numbers look wrong | One bad placement kills trust | The person's sliders win unless they opt in; check-ins are claimed only when learning is on (Built); proposal card and a reset of what was learned | Patterns, Today; Built, To build (proposal, reset) |

## Performance and battery

| ID | What goes wrong | Why it matters | Solution | Where, status |
|---|---|---|---|---|
| B01 | Live blur up to 30 on full-screen photos with grain | Dropped frames, battery | Pre-blurred photos (Built); cap live blur at 12; rasterise the backdrop once per appearance; test on iPhone 15 Pro | `SkyBackground`; To build |
| B02 | A 24-second drift animation on every page's own backdrop | Constant GPU work | One shared backdrop behind the tabs, paused when hidden; still motion stops it (Built) | `SkyBackground`; To build |
| B03 | Haptics engine left running | Battery | Stop after 30 seconds idle and on background | `Haptics`; To build |
| B04 | Widget reload budget (about 40 to 70 a day) | Stale widgets | Timeline dates; reload only on logging or plan change | 05-platform; To build |
| B05 | Solver time on the oldest supported iPhone | Slow replan after logging | Under 150 ms a day (test exists); measure on iPhone 15 Pro | FocusPlanning; Built |

## Accessibility

| ID | What goes wrong | Why it matters | Solution | Where, status |
|---|---|---|---|---|
| AX01 | Contrast in the darker dark mode: darkness 0 to 80% plus frost, blur and three backdrops | At 0% soft text can fall below 4.5:1; at 80% chart colours can fall below 3:1 | Automated test over darkness 0, 20, 50, 80%, frost 0 and 1, each backdrop, measuring the rendered background under text; clamp darkness or add a solid veil where a pair fails | `SkyBackground`, `Surfaces`; To build |
| AX02 | Increase Contrast and Reduce Transparency | Frosted cards wash out | Solid veils and stronger strokes (Built); snapshot every screen with both on | Built |
| AX03 | Fixed-size figures (`Font.figure`) and time chips capped at xxLarge | Numbers don't grow with Dynamic Type | Scale figures with `@ScaledMetric`; test at AX5 | `Typography`; To build |
| AX04 | Charts on Rhythm and Plan | VoiceOver users get nothing | Audio graphs (`AXChartDescriptor`) and a one-sentence summary per chart | Viz; To build |
| AX05 | Reel paging and page dots | Hard with VoiceOver and Switch Control | Accessibility scroll actions and "Page 2 of 3" labels | `Motion`; To build |
| AX06 | Small caption buttons ("Allow") | Missed taps | 44 by 44 point minimum | Settings and others; To build |
| AX07 | Colour-only meaning (medication dots, zone colours) | Lost for colour-blind people | Colour always paired with a symbol and a label | To build |
| AX08 | Hold to confirm | Hard for some motor needs | Named accessibility action (Built) | Built |

## Localisation

| ID | What goes wrong | Why it matters | Solution | Where, status |
|---|---|---|---|---|
| L01 | Strings outside the deck are hard-coded | Can't translate or review in one place | String Catalog for every fixed string | app; To build |
| L02 | Hand-made plurals ("1 dose", "4 hrs") | Breaks in other languages | String Catalog plural rules | app; To build |
| L03 | US and UK markets | Spelling, medicine names and crisis lines differ | en-US and en-GB catalogues, region crisis lines, privacy work (06) | Later |
| L04 | Region differs from language | An Australian using US English still needs 000 | Crisis lines follow region; copy follows language | `GetSupportView`; To build |

## App Review rejection risks

| ID | What goes wrong | Why it matters | Solution | Where, status |
|---|---|---|---|---|
| R01 | Account first, health-derived values in backed-up UserDefaults, demo content | Rejection under 5.1.1(v), 5.1.3(ii), 2.1 | A01, T02, T04 | To build |
| R02 | Broken buttons (Google not configured, email stub) | Rejected as incomplete | Configure or hide before submission | Onboarding; To build |
| R03 | Reviewer device lacks Apple Intelligence | "Doesn't work" | Description and review notes: iPhone 15 Pro or later, Apple Intelligence on, English | Owner |
| R04 | Data flows to a third-party AI before consent (5.1.2(i)) | Rejection | Warning and opt-in first (Built); add provider country | `ExternalAIView`; To build |
| R05 | Subscription terms missing from metadata (3.1.2) | Rejection | Terms of Use and Privacy links in the description; subscription review screenshot | Owner |
| R06 | Dead Terms or Privacy links | Rejection, invalid consent | Pages live before external TestFlight | Owner |
| R07 | Medical claims in screenshots or description (1.4.1, 2.3) | Rejection | Claims register and banned words scan on metadata | Owner |
| R08 | No app icon in the asset catalog | Upload fails; a pill icon would reveal the purpose on the Home Screen | A neutral icon with dark and tinted variants, no medical imagery | Assets; To build |

## Copy rotation

| ID | What goes wrong | Why it matters | Solution | Where, status |
|---|---|---|---|---|
| C01 | A variant slips in a dash or banned word | Breaks the voice or a rule | `merge.py` validator (Built) runs in CI on every deck change | docs/copy; To build (CI) |
| C02 | Serious lines rotate | Meaning drifts across 100 versions | Pin serious slots to one reviewed line | `Copy.line`; To build |
| C03 | A variant promises something the app no longer does | Misleading | Re-review the deck whenever architecture or features change | Copy.json; To build |
| C04 | A missing placeholder shows raw braces | Looks broken | Validator (Built); at runtime fall back to the slot's example | `Copy.line`; To build |
| C05 | Social message variants mention health | A friend learns about a condition | Deck rule: no health, medicine or focus words in `socialMessage` | docs/copy; To build |
| C06 | 100 variants per line in each new language | Cost and review load | New languages start with straight tone and 10 variants per slot | Later |

## Bring your own AI

| ID | What goes wrong | Why it matters | Solution | Where, status |
|---|---|---|---|---|
| AI01 | The key leaks | Someone runs up the person's bill | Keychain, this device only; never logged, synced or shown | Built |
| AI02 | A hostile or lookalike custom endpoint | Data goes somewhere unexpected | HTTPS only (Built); show the host in the warning; re-consent when it changes | `ExternalAIView`; To build |
| AI03 | Default model names retire | Requests fail | Pick from the provider's model list; clear "That model isn't available" message | `ExternalAI`; To build |
| AI04 | Medicine names inside task titles | Health information reaches the provider | Replace words matching the person's medication list with "a personal errand" before sending | `contextForExternalAI`; To build |
| AI05 | A reply gives dose advice | The app would show it | `SafetyGate`, then the referral line with "Your AI's answer talked about medication, so Focus didn't show it."; label "From your own AI, not from Focus" | `ExternalAI`, `AskAISheet`; Built |
| AI06 | Replies treated as instructions | Prompt injection through task titles | Replies are display only, never parsed into actions | Built |
| AI07 | Free plans that keep or train on data | People don't realise | The warning says so | Built |

## Social suggestions

| ID | What goes wrong | Why it matters | Solution | Where, status |
|---|---|---|---|---|
| SO01 | A medical visit read as social ("GP with Dr Lee") | Suggests moving a GP visit | Skip events with health words (GP, doctor, dentist, clinic, pharmacy, psych) | `OnDeviceReader`; To build |
| SO02 | Work meetings read as social; attendee counts are always 0 today | Asking to move a team meeting | Pass real attendee counts; skip events with more than 3 attendees or organised by someone else | `refreshSocial`; To build |
| SO03 | Wrong name ("Dinner with the team" gives "the") | Awkward message | Fall back to "there" (Built); drop articles and pronouns | `OnDeviceReader`; To build |
| SO04 | Too many suggestions | Nagging | At most one social line a day; dismissed events never return (Built) | Today; To build |
| SO05 | Social windows count from the first dose | Medication-free days have no anchor | Anchor to wake or 09:00 when there is no dose | `Personalisation`; To build |
| SO06 | A message sent for the person | Loss of control | Never; the person edits and sends through the share sheet; toggle in Personalise | Built |

## Support load

| ID | What goes wrong | Why it matters | Solution | Where, status |
|---|---|---|---|---|
| SU01 | Billing questions only Apple can answer | Inbox floods | "Payments, trials and refunds are all handled by Apple" in Settings (Built); canned replies with Apple links | Owner |
| SU02 | "My iPhone can't run Focus" | Frustration | Clear description and FAQ; the gate explains why (Built) | Owner |
| SU03 | Medication questions to support | Staff drawn into advice | Template with the referral line and Get support; never answer | Owner |
| SU04 | Crisis messages to the inbox | Someone at risk waits | Auto-reply with crisis lines; inbox checked daily; escalation steps | Owner |
| SU05 | Bug reports without context | Slow fixes | "Send feedback" in Settings attaches app version, iPhone model and iOS version, never health data | Settings; To build |

## Legal

| ID | What goes wrong | Why it matters | Solution | Where, status |
|---|---|---|---|---|
| LG01 | Wording not reviewed | Every fixed line carries risk | Lawyer sign-off before external TestFlight | Owner |
| LG02 | Publisher is a person | 5.1.1(ix) | A Pty Ltd publishes | Owner |
| LG03 | "ADHD Slayer" reads as beating ADHD | Claims risk | Keep it out of the App Store name, subtitle and ads; lawyer checks the seller name | Owner |
| LG04 | "Focus" is taken on the App Store and likely trademarked | Can't publish under the name | Reserve an available name early (for example "Focus: day planner"); trademark search | Owner |
| LG05 | Backdrop photographs | Unlicensed images | Confirm licences for the dusk façade and baroque interior photos; keep records | Owner |
| LG06 | Unfair terms in the Terms | ACL penalties | Lawyer drafts the Terms | Owner |
| LG07 | Law changes on 10 Dec 2026 (automated decisions, children's code) | Out-of-date policy | Review in November 2026; update before 10 Dec | Owner |
