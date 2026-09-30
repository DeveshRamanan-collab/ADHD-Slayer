# Research requirements

Every requirement the research implies for building Focus, grouped by source, with how the product meets it and a status. **Built** means it is in the app code today; **To build** means it is part of the launch product and not yet coded; **Later** means after launch. Where a research idea conflicts with an owner decision or a safety rule, the row states the product's version of it. Sources are the extraction notes in `docs/research-notes/`; competitor material is left out and medication research appears only as product rules.

## ADHD struggles

The source covers executive function, emotion, sleep, eating, medication, life admin, distraction, comorbidity, life transitions and the Australian context.

| ID | Requirement | How Focus meets it | Status |
|---|---|---|---|
| AS-01 | Keep time visible without opening the app | Now card with a shrinking ring and Focus mode (Built); widgets and controls | To build |
| AS-02 | Log a dose in one action without opening the app | "Log my meds" App Intent: Action button, Back Tap, Siri, Shortcuts | Built |
| AS-03 | Answer "did I take it?" at a glance | Bottom bar "2 of 4 logged. Next 18:00" (Built); Lock Screen widget | To build |
| AS-04 | Warn on a second log and save only after a deliberate confirm | Double-dose guard with "Hold to log another" | Built |
| AS-05 | Never block a late dose or suggest another time | Late note shown once, no actions (06, 2.3) | To build |
| AS-06 | Plan demanding work inside the person's own productive hours | Kinds of day with doses and sliders; scheduler puts deep work in best focus | Built |
| AS-07 | Eat even when not hungry: lunch on the medication timeline | Personalise eating window in hours after the first dose; lunch lands in it | Built |
| AS-08 | One-tap water and "ate something?" logs | Not at launch | Later |
| AS-09 | Planned medication-free days are never "missed" | A kind of day with no doses plans from routine | Built |
| AS-10 | Supply countdown, refill planner, shortage mode, eScript tokens | Not at launch; the app never names alternatives | Later |
| AS-11 | Take your own history to a clinician if you choose | Export of raw entries (JSON, CSV), no interpretation | To build |
| AS-12 | Discreet mode: no medicine names on shared surfaces | On by default with kind labels (Built for the bar); saved setting, widgets, notifications | To build |
| AS-13 | Face ID lock and a neutral icon | The name "Focus" is neutral; an app icon with no pill or medical imagery (none exists yet); optional app lock Later | To build |
| AS-14 | No red counts, destructive streaks or pile-ups after a lapse | "X of 7 days counted", no badges, banned words | Built |
| AS-15 | One-tap capacity check-in that lightens the day | Brain weather on the arrival page and Today; Low gives the baseline day | Built |
| AS-16 | An ideal and a baseline version of every day | Day version switch; the baseline keeps the musts | Built |
| AS-17 | Back in under 30 seconds after 1 to 3 weeks away, no backlog | Welcome back after 3 days away with a 3-thing restart | To build |
| AS-18 | Rotating novelty before week 2 | 100 daily variants per line, backdrops, accents | Built |
| AS-19 | Small notification budget; only time-critical items break through | At most 5 a day across all types, reminders the person set first | To build |
| AS-20 | Calm, predictable screens with adjustable haptics | Calm look, still motion, haptics switch and strength | Built |
| AS-21 | Invitational words, never commands | Voice rules; instructions about medicine banned | Built |
| AS-22 | Low reading load and a dyslexia-friendly option | Short lines and text size choices (Built); dyslexia font | Later |
| AS-23 | Persistently low days signpost crisis lines and a GP | Support card after 5 Low days in 7 | To build |
| AS-24 | Travel asks "home time or local time?" and suggests a prescriber check | Time zone prompt (07, S02) | To build |
| AS-25 | Shift work: the day starts at wake, not midnight | Day boundary and shift kinds of day (07, S04) | To build |
| AS-26 | Routines switch with term, exams and holidays | Kinds of day with weekdays and date ranges | Built |
| AS-27 | Never recommend a dose change, extra dose, skip or other medicine | Red lines R1 to R5 and the package boundary | Built |
| AS-28 | A reminder before the app's own free trial converts | Notification 2 days before at 10:00 | Built |
| AS-29 | Waiting mode, leave-by, transition cues, hyperfocus guardrail, morning launch | Not at launch | Later |
| AS-30 | Bills, impulse cool-off, reply-later, birthdays, chores as rhythms | Not in scope for launch | Later |

## Interventions and evidence

The source covers CBT-based skills, time aids, implementation intentions, rewards, habits, notifications, friction, exercise, sleep and design guidelines.

| ID | Requirement | How Focus meets it | Status |
|---|---|---|---|
| IE-01 | The core loop: plan, break down, schedule, park distractions, review | Priorities, planner and Fix my day (Built); quick add and capture | To build |
| IE-02 | Add a task with only a title | Quick add with optional duration, deadline and kind of work | To build |
| IE-03 | Every task shows a physical first step under 10 minutes | "First step" on Now and in Focus mode (fixed text today); written or suggested per task | To build |
| IE-04 | Park a stray thought without leaving the task | One-tap capture from Focus mode and Siri | To build |
| IE-05 | Time left is always visible | Ring, bar or number (Customise, Focus mode) | Built |
| IE-06 | Immediate visual and haptic feedback on completion | Done tick with haptic; logging celebration with an off switch | Built |
| IE-07 | No daily streaks; "X of the last 7 days"; misses are neutral | "X of 7 days counted" on Plan | Built |
| IE-08 | A missed block gets a new slot with no red and no scolding | Fix my day preview with reasons and undo | Built |
| IE-09 | Low energy shrinks the plan | Brain weather Low switches to the baseline day | Built |
| IE-10 | Capped notifications and "send nothing" as a real option | At most 5 a day; nothing sent unless the person turns it on | To build |
| IE-11 | No timeouts; every action undoable | Undo for Fix my day (Built); undo toast for logs | To build |
| IE-12 | One primary action per screen; Now and Next first | Paged screens, one idea per page | Built |
| IE-13 | Onboarding under 2 minutes with working defaults | Five short beats, then home with skippable coach marks | Built |
| IE-14 | Ask for permissions just in time | Calendar from Personalise or Settings; notifications at the trial | Built |
| IE-15 | Plain language at a Year 7 to 8 reading level | Deck rules (Built); readability check in the validator | To build |
| IE-16 | Strengths-based framing, never deficit framing | Voice rules and banned words | Built |
| IE-17 | Everything works with medication features off | No medication: planning from routine | Built |
| IE-18 | Welcome back archives stale tasks and offers 3 things | Welcome back flow | To build |
| IE-19 | Show estimated against actual durations | Patterns "How long things take" (demo history today); real timings | To build |
| IE-20 | Weekly review with 3 commitments and "how did this week go?" | Not at launch | Later |
| IE-21 | If-then plans, reward menu, movement primer, wind-down routine | Not at launch | Later |
| IE-22 | Work alongside and accountability partners | Not at launch; never sharing medication | Later |
| IE-23 | Support alongside care, never treatment; no efficacy claims | Honest bit and claims rules (06) | Built |
| IE-24 | Co-design with adults with ADHD before copy and defaults freeze | Paid panel of 8 to 12 in the beta (09) | To build |

## Medication and pharmacology (as product rules)

The source covers how formulations behave. Focus turns it into rules only; it ships no catalogue, no priors and no product text.

| ID | Requirement | How Focus meets it | Status |
|---|---|---|---|
| MP-01 | Never propose a dose, dose time, extra dose or cut-off | Every value is typed by the person | Built |
| MP-02 | No dose calculations, conversions or equivalence in logic or copy | None exist; strength is free text | Built |
| MP-03 | Never generate or paraphrase missed-dose or label text | No product text is stored or shown | Built |
| MP-04 | Any dose time is allowed; morning dosing is never assumed | Slots at any minute, past midnight allowed | Built |
| MP-05 | A short-acting dose has its own timing, separate from the all-day one | Each medication has its own sliders | Built |
| MP-06 | The wind-down is never called a sleep medicine | Kind "Wind-down"; banned words | Built |
| MP-07 | A wind-down ends focus earlier by a buffer | Kind of day wind-down buffer, 60 minutes by default | Built |
| MP-08 | Overlapping helpful stretches merge; gaps become low-focus stretches | `automaticWindows` joins gaps under 20 minutes; gaps of 20+ are shown | Built |
| MP-09 | Uncertainty in plain words, never percentages | "first guess", "early", "learned" | Built |
| MP-10 | "You can usually sleep after" is never pre-filled as advice | Opens unset for a new medication | To build |
| MP-11 | Learning never silently overwrites what the person set | "Fine-tune from my check-ins" is opt-in | Built |
| MP-12 | A brand or generic switch re-learns | Editing a medication restarts its learning (LL-13) | To build |
| MP-13 | Mark a day as unusual so it stays out of learning | Not at launch | Later |
| MP-14 | The guard respects the planned count and a relog interval per kind | All day 8 h, Short-acting 2 h, Wind-down 12 h, Something else 6 h | Built |
| MP-15 | Confirmations never block; the log reflects what happened | "Keep one log" or hold to log another | Built |
| MP-16 | Heart rate never ends a window or confirms a dose | No Health data read | Built |
| MP-17 | Medicines without a daily window draw no focus window | "Something else" still makes a window from its sliders; add "Shapes my focus day" off by default | To build |
| MP-18 | Food may shift timing: optional one-tap "ate first?" | "Ate something first?" on the log sheet (stored, not yet used) | Built |
| MP-19 | Never advise on food, drinks, alcohol or interactions | No such content | Built |
| MP-20 | Values are the person's own experience, never facts about a medicine | Line under the sliders | Built |
| MP-21 | Learned values replace starting values only with enough data | 5 or more dosing days with 3 or more check-ins (LL-06, LL-07) | To build |

## Regulation, privacy and safety (rules only)

The source sets 32 product rules plus claims language. Each rule's product form is in 06-compliance-and-safety.md.

| ID | Requirement | How Focus meets it | Status |
|---|---|---|---|
| RP-01 | Never suggest, calculate or prompt a dose action (rule 1) | R1, package boundary, `PlanChange` | Built |
| RP-02 | Reminders only at times the person set; inferred times confirmed (rule 2) | R4 | To build |
| RP-03 | Dose time is fixed; change tasks when short (rule 3) | `CapacityRemedy` | Built |
| RP-04 | The learned window is the person's focus pattern (rule 4) | "Your focus window, learned" from check-ins | Built |
| RP-05 | No treatment or disease claims anywhere (rule 5) | Claims rules (Built); scan on every surface | To build |
| RP-06 | No heart rate or sleep alerts tied to medication (rule 6) | None exist | Built |
| RP-07 | Show the last log and require a deliberate confirm (rule 7) | Guard | Built |
| RP-08 | Undo, edit and delete with an audit trail (rule 8) | `DoseLog` undo, edit and audit (Built); screens | To build |
| RP-09 | Taken only from an explicit tap (rule 9) | R6 | Built |
| RP-10 | No booster, catch-up or late prompts; a neutral late note (rule 10) | R5 and the late note | To build |
| RP-11 | No logging for others, sharing, gifting, or marketing to the undiagnosed (rule 11) | R9 and claims rules | Built |
| RP-12 | AI output cannot hold medication advice (rule 12) | `@Generable` types with no medication field, `PriorityFacts.clean`, `SafetyGate` on your own AI replies | Built |
| RP-13 | Health context stays on the iPhone; cloud AI gets no health text (rule 13) | Apple's on-device model; your own AI gets task names and times only | Built |
| RP-14 | Each third-party AI disclosed and opted into first (rule 14) | Your own AI warning and toggle | Built |
| RP-15 | Paid AI tiers only (rule 15) | Focus pays for no cloud AI; the warning covers free plans | Built |
| RP-16 | Overseas recipients checked and contracted (rule 16) | Owner's due diligence file (09) | To build |
| RP-17 | Express, specific, withdrawable health consent first (rule 17) | Consent card (Built); record and withdrawal | To build |
| RP-18 | No ad or analytics SDKs near health data (rule 18) | None in the app | Built |
| RP-19 | Never sell or license health data (rule 19) | Architecture and policy | Built |
| RP-20 | No personal health information in iCloud (rule 20) | `medication.json` fully protected and excluded from backup (Built); other health files and own encrypted sync | To build |
| RP-21 | Publish through a legal entity (rule 21) | Pty Ltd (09) | To build |
| RP-22 | In-app deletion reaching backups and processors; retention schedule (rule 22) | Delete on the iPhone (Built); server deletion and retention (06, 12) | To build |
| RP-23 | A breach plan for the NDB scheme (rule 23) | Plan written before launch (09) | To build |
| RP-24 | 18+ only: rating plus declared-age gate (rule 24) | Toggle on the account step | Built |
| RP-25 | Parsed content is untrusted and never touches medication (rule 25) | Calendar titles fill fixed fields only; no writes | Built |
| RP-26 | Say when AI wrote something (rule 26) | Priorities source line; "From your own AI, not from Focus" | Built |
| RP-27 | Doctor or pharmacist line in onboarding and medication screens (rule 27) | Honest bit and log sheet (Built); Medication page and editors | To build |
| RP-28 | Static Get support and deterministic crisis routing (rule 28) | Australian page (Built); region lines and keyword route | To build |
| RP-29 | No absolute privacy promises; simple cancellation (rule 29) | Cancel in 2 taps (Built); rewrite privacy lines | To build |
| RP-30 | No disclaimers that remove consumer guarantees (rule 30) | Terms "to the extent permitted by law" (09) | To build |
| RP-31 | Only the Health types needed, with graceful denial (rule 31) | Sleep only, asked on the Sleep and done page; a refusal shows "No sleep from Health yet" | To build |
| RP-32 | The privacy policy describes automated scheduling before 10 Dec 2026 (rule 32) | Policy section (06, 6.1) | To build |
| RP-33 | Notifications never name a condition or a medicine | Trial reminder is neutral (Built); every template scanned | To build |

## Apple platform

The source covers the iOS 26 and 27 frameworks, extensions, background limits, HealthKit, EventKit, Foundation Models and accessibility.

| ID | Requirement | How Focus meets it | Status |
|---|---|---|---|
| AP-01 | iOS 26 minimum; iOS 27 features behind availability checks | Deployment target 26.0, iPhone only | Built |
| AP-02 | A runtime gate for Apple Intelligence (no App Store device key) | `DeviceGateView` for not eligible, switched off and not ready | Built |
| AP-03 | Check model availability before generating; deterministic fallback | `PriorityWriter` and `OnDeviceReader` fall back to plan order and keywords | Built |
| AP-04 | Prompts sized for 4,096 tokens; context, guardrail and language errors caught | Small prompts and catch-all fallback (Built); token check | To build |
| AP-05 | Generate in the foreground only | Priorities refresh from visible views | Built |
| AP-06 | The dose log is the app's own store, not Apple Health | `DoseLog` in memory; persistent ledger | To build |
| AP-07 | One App Group for the app, widgets, controls and intents | Glance snapshot | To build |
| AP-08 | Control Center control and Action button through App Intents | "Log my meds" intent (Built); `ControlWidget` in a widget extension | To build |
| AP-09 | Fixed-phrase App Shortcuts that work on every supported iPhone | "Log my meds in Focus", "Open my medication in Focus" | Built |
| AP-10 | Widgets use timeline dates and reload only on change | Widget extension | To build |
| AP-11 | Live Activity within 8 hours, 4 KB and no network | After launch | Later |
| AP-12 | At most 64 pending notifications: rolling window | Notification scheduler | To build |
| AP-13 | No medicine names in notifications or Siri announcements | Discreet mode rules | To build |
| AP-14 | Secrets in the Keychain, this device only | `Keychain` for the account and your AI key | Built |
| AP-15 | No personal health information in iCloud | `medication.json` excluded from backup (Built); ledger, check-ins and own sync | To build |
| AP-16 | Full calendar access with a clear purpose; plans work if denied | Usage string set; planning works without it | Built |
| AP-17 | Never write to or edit other people's calendar events | Read only | Built |
| AP-18 | Calendar identity by external identifier and occurrence date | Keyed by `eventIdentifier` today | To build |
| AP-19 | Every usage string names its purpose | Calendar string (Built); others as features ship | Built |
| AP-20 | Respect Reduce Motion and Reduce Transparency | Still motion, solid veils, grain off | Built |
| AP-21 | Liquid Glass on the control layer only; `.glassProminent` for primary actions | Tab bar, accessory and buttons | Built |
| AP-22 | StoreKit 2: verified transactions, listener, restore, intro eligibility, account token | `Store` | Built |
| AP-23 | Manage subscription, offer codes and refunds in the app | Manage and redeem (Built); refund sheet | To build |
| AP-24 | Sign in with Apple capability and credential checks | Button (Built); capability and server | To build |
| AP-25 | Privacy manifest with required reason APIs | `PrivacyInfo.xcprivacy` (06, 10.2) | To build |
| AP-26 | Assistive Access scene for a simple mode | After launch | Later |
| AP-27 | Apple Watch quick logging and complications | After launch | Later |
| AP-28 | HealthKit sleep, read only, asked in context, foreground reads | Sleep and done page (05-platform) | To build |
| AP-29 | HealthKit medication import with per-medication authorisation from an explicit action | After launch | Later |

## Learning and lifestyles

The source covers learning from one person's sparse data, kinds of day and holidays, and explaining, protecting and checking what is learned.

| ID | Requirement | How Focus meets it | Status |
|---|---|---|---|
| LL-01 | Learn from a few days, starting from the person's own guess | FocusWindowModel (FocusPlanning): grid, cautious prior | Built |
| LL-02 | Keep a separate learned curve for each medication | A FocusWindowModel per medication, from its sliders | To build |
| LL-03 | The person's numbers and window win unless they opt in | Fine-tune from my check-ins toggle; Patterns: Use learned | Built |
| LL-04 | Offer, never impose, a learned time 60 min or more off | FocusWindowModel.proposal card; a no rests it 30 days | To build |
| LL-05 | Ask one thing in one tap; never nag or name a medicine | Passive check-in: Yes, Partly, No; quiet in Focus modes | To build |
| LL-06 | Ask 3 to 5 a day for 5 to 7 dose days, then every 2 to 3 days | nextCheckInMinute; taper once edges are within 30 min | To build |
| LL-07 | Show each learned value with count, range and label | Confidence: first guess, early, learned; Today, Patterns | Built |
| LL-08 | Keep slack in the day; let the person pad estimates | Patterns: How full, Between things, How long things take | Built |
| LL-09 | Learn durations only from real start and stop times | Learned task durations, shown beside each new estimate | Later |
| LL-10 | Plan around the person's stated timing first | Personalise: category, eating, social and alone windows | Built |
| LL-11 | Change timing only on strong evidence and with a yes | Learned timing, trials of one; a no rests it 30 days | Later |
| LL-12 | Never experiment on the plan; doses, pins and calendar stay | Scheduler: deterministic; no way to change a dose | Built |
| LL-13 | Restart learning on a medication change; reset on request | Medication editor save; Patterns: reset to first guess | To build |
| LL-14 | Spot routine shifts or a missed switch; suggest, never act | Change and forgotten switch detectors; undo, since Monday | Later |
| LL-15 | Each kind of day has its own doses; learned timing is shared | DayType per kind; one curve counted from the logged dose | Built |
| LL-16 | Switch automatically by date range, then by weekday | Kinds of day: applies when; shortest date range wins | Built |
| LL-17 | Allow a today-only choice and an easy way back | Medication page: Change, Use the usual for today | Built |
| LL-18 | Let a new kind of day start from an existing one | Kinds of day: start from a copy, e.g. of Weekend | To build |
| LL-19 | Expect holiday drift and a slow return to the usual routine | Learned wake times per kind of day, from Health sleep | Later |
| LL-20 | Explain using code-made numbers; never give dose advice | Explainer reason codes; Priorities add times; fixed copy | Built |
| LL-21 | Never read silence as a no or as a medication-free day | FocusWindowModel: answers only; Kinds of day: no doses | Built |
| LL-22 | Don't let skips, gaps or passive signals skew learning | Lapse reasons, logging coverage, Health data as hints | Later |
| LL-23 | Learn on the phone; never share check-ins with any AI | FocusWindowModel in plain Swift; your AI sees tasks only | Built |
| LL-24 | Keep learned state and check-ins on the phone, protected | Protected file beside medication data, never in iCloud | To build |
| LL-25 | Test learning on simulated people before each release | FocusWindowModelTests: 10 days, 20% missed, within 30 min | Built |
| LL-26 | Measure on the phone whether learning improves plans | Range coverage, realism rating, replay before new models | Later |

### Findings from the code check (fix or decide when resuming)

- LL-01, LL-07 and LL-21 are built in the learning model only. No screen or notification collects a check-in yet; `AppModel.seededModel` fakes 9 days of answers with a fixed 45 min and 7 hr estimate instead of the medication's sliders.
- Labelling bug: Today's confidence line reads the model's confidence even when the medication isn't learning and the window comes from the sliders, so it can wrongly say "from N check-ins". Focus window edits on Patterns only reach the plan when learning is on.
- LL-04: `FocusWindowModel.proposal` exists and is tested, but `AppModel.proposalDismissed` is unused and nothing shows the proposal.
- LL-24: learned state and check-ins aren't saved yet. `medication.json` uses `completeFileProtectionUntilFirstUserAuthentication` and isn't excluded from device backup, which conflicts with "never in iCloud" (set `isExcludedFromBackup`, use complete protection).
- LL-02: only the All day kind can learn; decide whether short-acting ones should.
- LL-13: "Start over" on Patterns resets the person's own adjustments, not what the model learned.
- LL-20: `SafetyGate` (FocusPlanning/SafetyGate.swift) is tested but never called in the app. The medication editor's learned line calls the time until the curve ends "helping for", which reads as a length of time.
- Two small points from the original source folded in: a "median error versus the raw guess" measure (LL-26) and blinding of self-rated outcomes in trials of one (LL-11).
- Update after this check (30 Sep 2026): the confidence label now claims check-ins only when learning is on; `SafetyGate` now screens your own AI replies; `medication.json` now has complete protection and is excluded from backup. The other findings stand.

## Failure modes

The source covers why apps in this space lose people: novelty decay, shame, setup burden, overload, trust, billing and reliability. No products are named.

| ID | Requirement | How Focus meets it | Status |
|---|---|---|---|
| FM-01 | Deliver value where people already look | Bottom bar glance (Built); widgets | To build |
| FM-02 | No overdue pile-up; a fresh start after days away | No overdue lists (Built); welcome back | To build |
| FM-03 | A useful first plan within minutes | Home right after onboarding (Built); quick add for real tasks | To build |
| FM-04 | Zero configuration works; customisation behind one entry | Customise and Settings sit on You page 3 | Built |
| FM-05 | Never over-pack: capacity cap and buffers | Fill cap 60%, 10-minute transitions | Built |
| FM-06 | Suggest, then confirm; undo; a reason on every placement | Fix my day preview, undo and reasons | Built |
| FM-07 | Pinned and person-made items never move | Scheduler test `pinnedBlocksNeverMove` | Built |
| FM-08 | Day types switch without the person remembering | Date ranges and weekdays pick today's kind of day | Built |
| FM-09 | Write only to an app-owned calendar; never edit others | No calendar writes at launch | Built |
| FM-10 | An explainer before each permission prompt | Calendar and notification explainers | To build |
| FM-11 | The person's own curve, not a population curve | Own sliders; optional learning | Built |
| FM-12 | "No meds today" and late days re-plan instantly | Medication-free kind of day; a late log shifts the day | Built |
| FM-13 | Health data stays on the device; no SDK reads it | On-device store; no SDKs | Built |
| FM-14 | Validate AI output against a schema | `@Generable` types and `compose()` checks | Built |
| FM-15 | No cloud AI cost for the company | Apple's on-device model; your own AI on the person's key | Built |
| FM-16 | A planner, not a chatbot | No chat tab; your own AI is an optional sheet | Built |
| FM-17 | A trial long enough to see value | Free month | Built |
| FM-18 | A reminder before the trial ends and a one-tap route to cancel | Reminder 2 days before; Manage subscription | Built |
| FM-19 | Safety and ownership features never paywalled | Logging, guard, support, export and deletion are free | Built |
| FM-20 | Billing grace period and a calm billing message | 07, P05 | To build |
| FM-21 | Strong alerts only where the person chose them | Reminders at times the person set | To build |
| FM-22 | A stable navigation contract; new features opt-in | Tab and page order change only when the person changes them | Built |
| FM-23 | Glanceables work offline with no sign-in dependency | Glance snapshot from local data | To build |
| FM-24 | Full export any time and a published shutdown notice | Export (To build); 90-day notice in the Terms | To build |
| FM-25 | In-app feedback and a steady release cadence | "Send feedback"; monthly releases | To build |
| FM-26 | Localisation groundwork from the first version | String Catalog | To build |

## PDF pages 1 to 20

Executive summary, scope, problem space, design principles, the feature tables and the day-one estimates.

| ID | Requirement | How Focus meets it | Status |
|---|---|---|---|
| PA-01 | Core loop: log a dose, plan around the person's window, survive a bad day | Logging, kinds of day, planner, baseline and Fix my day | Built |
| PA-02 | Glanceable surfaces carry the day | In-app glance (Built); widgets and controls | To build |
| PA-03 | Guard shows the first log's time and hours since | Guard sheet | Built |
| PA-04 | Dose glance with logged times | Bottom bar and dose rows | Built |
| PA-05 | A personal cut-off note that never blocks | Late note (06) | To build |
| PA-06 | Planned breaks are never missed and stay out of learning | Kind of day with no doses | Built |
| PA-07 | Lunch on the medication timeline "even if not hungry" | Eating window from the first dose | Built |
| PA-08 | No drug names on the Lock Screen or in calendar titles | Kind labels (Built for the bar); saved setting and surfaces | To build |
| PA-09 | Now and Next with a shrinking ring | Now card and Focus mode | Built |
| PA-10 | A physical first step under 10 minutes for each task | Fixed first-step text today | To build |
| PA-11 | Brain weather Low collapses the day to baseline | Arrival page and Today menu | Built |
| PA-12 | Baseline days count as a win | "X of 7 days counted" | Built |
| PA-13 | Amnesty and welcome back without mentioning missed days | Welcome back | To build |
| PA-14 | Safety signposting: Lifeline and "talk to your GP" | Get support page | Built |
| PA-15 | A notification budget of 5 a day | Budget across all types (05-platform) | To build |
| PA-16 | Calm by default; livelier options are optional | Calm look; humour level, accents, backdrops | Built |
| PA-17 | Setup presets (Minimal, Gentle nudges, High structure) | Working defaults now; presets after launch | Later |
| PA-18 | Date-ranged modes for exams and holidays | Kinds of day with "applies when" | Built |
| PA-19 | Learned changes need the person's approval | Sliders win; learning opt-in (Built); proposal card | To build |
| PA-20 | Medicines without a daily window create none | "Shapes my focus day" switch (MP-17) | To build |
| PA-21 | An Australian formulation catalogue | Free-text names at launch | Later |
| PA-22 | Lawyer review of the red lines before the build ships | Owner task (09) | To build |
| PA-23 | Wake-anchored prompts, supply, shortage mode, cycle overlay, leave-by | After launch | Later |

## PDF pages 21 to 40

What shifts the window, boosters, non-stimulants, the dose-log event, check-ins, safety red lines, AI guardrails, age, the learning system and lifestyles.

| ID | Requirement | How Focus meets it | Status |
|---|---|---|---|
| PB-01 | The person enters every medication value; the app proposes none | Medication editor | Built |
| PB-02 | Stated experience is the starting estimate | The sliders are the person's experience | Built |
| PB-03 | A manual window edit overrides until released | `Tuning.windowOverride`, `setManualOverride` | Built |
| PB-04 | Backdated logging ("20 minutes ago", a set time) | Just now, 20 min ago, Earlier | Built |
| PB-05 | "Ate first?" on the log | "Ate something first?" | Built |
| PB-06 | Duplicate guard in neutral words, never "safe" | Guard | Built |
| PB-07 | Taken means tapped | R6 | Built |
| PB-08 | Undo, edit and delete with a local audit trail | Audit in `DoseLog` (Built); screens | To build |
| PB-09 | Replan after every log and say what moved | Replan on log (Built); "what moved" line | To build |
| PB-10 | One-question check-ins, 3 to 5 a day while learning, then taper | LL-05, LL-06 | To build |
| PB-11 | Focus pattern labels: starting, early, learned | Confidence labels | Built |
| PB-12 | Stated versus learned: Accept, Keep mine, Ask later | Proposal card (LL-04) | To build |
| PB-13 | A capacity shortfall changes tasks, never medication | `CapacityRemedy` | Built |
| PB-14 | No log: one reminder, then "Plan today without medication?" | Reminder and offer | To build |
| PB-15 | A time zone change asks home or local; never picks a dose time | 07, S02 | To build |
| PB-16 | Get support with 000, Lifeline and 988 | Australia (Built); 988 by region | To build |
| PB-17 | 18+ only | Gate | Built |
| PB-18 | Screenshots and messages parsed into fixed fields, writes confirmed | No parsing at launch | Later |
| PB-19 | Medication questions to AI get the referral line | Keyword route and `SafetyGate` | To build |
| PB-20 | The model never computes a number | Priorities add times in code | Built |
| PB-21 | "What the app has learned" with a reset per item | Patterns page; "Start over" resets adjustments only | To build |
| PB-22 | Separately learned lifestyles with a one-tap switch | Kinds of day switch by date (Built); per-lifestyle learning | Later |
| PB-23 | A heads-up the evening before a scheduled switch | Date ranges switch silently today | Later |
| PB-24 | Publisher is a legal entity | Owner task (09) | To build |

## PDF pages 41 to 60

Apple platform integration, the review of the original feature inventory, and the first eight failure risks.

| ID | Requirement | How Focus meets it | Status |
|---|---|---|---|
| PC-01 | Onboarding under 3 minutes; permissions in context | Five beats; calendar asked on first use | Built |
| PC-02 | Fill about 60% of free focus time, with transitions | Fill cap 0.6, 10-minute transitions | Built |
| PC-03 | The baseline day one tap from Today | Toggle on the "If today changes" page | Built |
| PC-04 | A reason on every placement | Explainer lines on blocks | Built |
| PC-05 | Pinned and person-made items never move | Scheduler | Built |
| PC-06 | One-tap undo for every change set | Fix my day undo | Built |
| PC-07 | Suggest, then confirm | Nothing applies until Apply | Built |
| PC-08 | Fixed-phrase shortcuts that work without Siri AI | "Log my meds", "Open my medication" | Built |
| PC-09 | Fix my day previews the smallest change with reasons | Preview sheet | Built |
| PC-10 | Running late shifts flexible blocks by the real delay | Ask the minutes first (07, S14) | To build |
| PC-11 | Quick task entry: title, rough duration, deadline | Quick add | To build |
| PC-12 | A short daily briefing with priorities first | "Today, in five" | Built |
| PC-13 | End-of-day review with at most 3 one-tap questions | After launch | Later |
| PC-14 | Diagnostics say "no data seen since", never "connected" | Settings, Permissions shows On or Allow | To build |
| PC-15 | Export JSON and CSV, warn first, keep the file local until shared | Export | To build |
| PC-16 | Missing Health data means unknown, never zero | "No sleep from Health yet" on the Sleep and done page | To build |
| PC-17 | Rolling 48-hour notification window under 64 | Scheduler | To build |
| PC-18 | No drug names on the Lock Screen; neutral calendar titles | Discreet rules | To build |
| PC-19 | Never show an unwritten change as done | No external writes at launch | Built |
| PC-20 | A stable navigation contract | Fixed order unless the person changes it | Built |
| PC-21 | Event-driven upkeep: replan on launch, intents and calendar change | Launch and log (Built); calendar change observer | To build |
| PC-22 | Every AI feature has a non-AI path | Plan-ranked priorities and keyword categories (Built); test with Apple Intelligence off | To build |

## PDF pages 61 to 80

Risk register, pricing, privacy and data governance, architecture, roadmap, gates and open decisions.

| ID | Requirement | How Focus meets it | Status |
|---|---|---|---|
| PD-01 | Medication records are only ever edited by the person | Only the editor writes medications | Built |
| PD-02 | Specific opt-in consent at first medication setup, withdrawable there | Consent card (Built); withdrawal | To build |
| PD-03 | Never cut the guard, undo, baseline day or amnesty | Guard and baseline (Built); undo toast and welcome back | To build |
| PD-04 | Apple Health dose import keyed by Health's id | After launch | Later |
| PD-05 | High-stakes blocks never rest on an early estimate | After launch | Later |
| PD-06 | App-owned calendar with an identity map | No calendar writes at launch | Later |
| PD-07 | "What leaves this phone" lists every destination | Page exists (Built); wording fix | To build |
| PD-08 | Delete everything, including server copies and backups | iPhone (Built); server | To build |
| PD-09 | Optional Face ID lock | After launch | Later |
| PD-10 | Consent records with category, provider, country and version | `ConsentRecord` (06, 5.3) | To build |
| PD-11 | Server in Australia holds ciphertext only; keys stay on devices | Encrypted sync (02) | To build |
| PD-12 | No ad or analytics SDKs; crash logs free of medicine names | None; Apple crash reports only | Built |
| PD-13 | Third-party AI opt-in, no health content, provider and country named | Your own AI (Built); country | To build |
| PD-14 | Gemini excluded | OpenAI, Anthropic and custom endpoints only | Built |
| PD-15 | Safety rules compiled in; nothing overrides them | Package boundary and fixed referral | Built |
| PD-16 | Independent security test before launch, no high findings | Owner task (09) | To build |
| PD-17 | A written breach plan | 06 and 09 | To build |
| PD-18 | A claims register reviewed before each release | 06, 11.3 | To build |
| PD-19 | A trial with a reminder 2 days before and clear cancel steps | 1 calendar month (Apple's fixed period) and the reminder | Built |
| PD-20 | Enrol in the App Store Small Business Program | Owner task (09) | To build |
| PD-21 | A 500-prompt red-team test finds no medication advice | Test plan (09) | To build |
| PD-22 | Beta gates: 40% of testers active at day 14; day-30 retention target 20% | TestFlight gates (09) | To build |
| PD-23 | Paid co-design panel of 8 to 12 and a pilot of 20 to 40 adults | Beta plan (09) | To build |
| PD-24 | Australia first; the US and UK after localisation, crisis lines and legal review | Launch scope | Later |
