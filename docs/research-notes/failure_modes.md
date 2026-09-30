# Failure modes and build lessons (product-agnostic)

Source: internal research dated 28 Sep 2026 (review mining, subscription benchmarks, platform documentation, market data). All company, app and vendor names are removed. Untagged items are stated or inferred in the source. Items tagged (proposed) are defaults or inferences added in this extraction; validate them before they become spec. IDs F1 to F28 are referenced from later sections.

## 1. Failure modes → cause → build requirement / mitigation

- **F1. Novelty decay and abandonment**
  - Why it happens: ADHD users repeatedly download new apps (the "shiny object" pattern), and any value that requires opening the app fades once novelty wears off. Mental-health apps: median retention 3.9% at day 15 and 3.3% at day 30; on a given day a median 4% of 30-day installers open the app, for a median 13 minutes.
  - Shows up as: a cliff after week 1; the plan goes stale because nobody opens the app.
  - Build requirement: deliver the plan where the user already looks, without opening the app: Home Screen and Lock Screen widgets, a Live Activity for the current block, plan blocks written to the system calendar, and a glanceable status such as "Peak focus until 1:40 pm". Guilt-free re-entry (F2). Instrument D1, D7 and D30 cohorts from launch day (section 7).

- **F2. Shame spiral on return (overdue pile-up, broken streaks)**
  - Why it happens: missed days accumulate into overdue lists and reset counters, so reopening the app means facing a record of failure. The source prescribes a "fresh start" re-entry with no overdue pile-up. It contains no streak data, so the streak rules here are (proposed).
  - Shows up as: red overdue badges, "you missed" copy, streaks reset to zero, then avoidance of the app after a bad week.
  - Build requirement: no overdue counter or badge anywhere; unfinished items from past days move to a neutral "Parked" list and never flood today (proposed); after 2 or more days away the app opens on a "Fresh start" screen that plans today only (proposed threshold); no counter that resets to zero (proposed); banned copy: "missed", "failed", "behind", "overdue", "streak lost" (proposed). Details in section 4.

- **F3. Setup burden before first value (onboarding drop-off)**
  - Why it happens: heavy configuration and manual data entry before the first useful plan. Review themes: lengthy initial setup, steep onboarding, settings that feel clever rather than intuitive, and data entry that feels like a full-time job.
  - Shows up as: drop-off before the first plan; users never reach the learning payoff.
  - Build requirement: first plan in under 3 minutes from first launch; import existing events from the system calendar and dose events from the system health store so nothing is typed twice; default the effect window to the population curve for the chosen formulation; reveal settings progressively; capture tasks by a free-text brain dump parsed on device. Details in section 2.

- **F4. Feature overload and customisation burden**
  - Why it happens: ADHD users describe apps as either too simple or so complex that they get overwhelmed and distracted; feature overload is a recurring review theme. Heavy customisation magnifies the risk.
  - Shows up as: users stall in settings, tinker instead of planning, or cannot find the core actions.
  - Build requirement: zero configuration is a valid, fully working state and every option has a default (proposed); customisation lives behind a single Settings entry and never interrupts the daily flow (proposed); "Reset to defaults" per settings group (proposed); advanced options appear only after the related feature has been used (progressive disclosure).

- **F5. Over-packed days and calendar clutter**
  - Why it happens: schedulers that maximise utilisation fill every free slot and skip transitions.
  - Shows up as: days with no breathing room; a calendar booked every hour that users call overwhelming.
  - Build requirement: hard capacity cap, automatic scheduling fills at most about 60% of free time; mandatory buffers and transition time between blocks (proposed default: 10 minutes); an overcommitment warning when manual planning exceeds the cap; all app blocks live in a separate app-owned calendar that can be hidden in one tap.

- **F6. Trust collapse after one visible AI mistake**
  - Why it happens: algorithm aversion. People lose confidence in an algorithm faster than in a human after seeing the same mistake, then avoid it even when it performs better. Combined with ADHD sensitivity to overload, silently moving tasks or over-filling the day is the most likely trust-killer.
  - Shows up as: users switch off automatic planning or churn after a single bad placement.
  - Build requirement: "suggest, then confirm" is the default for the first 2 weeks; one-tap undo on every automatic change; a plain-language reason on every placement (for example "Placed here: 2 h after your dose, your peak"); never move user-created or pinned items; prefer a conservative, explainable scheduler over a maximally autonomous one.

- **F7. Loss of control from silent automatic changes**
  - Why it happens: automatic rescheduling without consent. Rescheduling struggles are a top review theme (25 mentions in one review set).
  - Shows up as: tasks are not where the user left them; the day becomes unpredictable.
  - Build requirement: rate-limit automatic moves to at most N per day (proposed N = 3); report moves in one daily "What moved" digest, never one alert per move; a "Lock this day" control that freezes all placements; floating tasks with no fixed time.

- **F8. Rigid minute-by-minute structure**
  - Why it happens: time-blocking every minute does not match ADHD days. Users ask for unscheduled, duration-only tasks, week and month overviews, and easier routine editing.
  - Shows up as: the timeline breaks by mid-morning and gets abandoned.
  - Build requirement: three task timing modes (fixed time, duration-only floating, untimed); day, week and month views; routines editable inline from the day view (proposed: in 2 taps or fewer).

- **F9. Day-type switching misfires or pollutes learning**
  - Why it happens: a mode toggle (for example term time vs holidays) that users must remember to flip, or one learned model shared across very different day patterns.
  - Shows up as: a term-time plan on the first day of holidays; holiday behaviour degrading term-time suggestions; extra complexity.
  - Build requirement: auto-suggest a day-type switch from imported academic session dates; switch in one tap from a system control (Control Centre or Lock Screen) or a widget; learned patterns stored per day type so one type never contaminates another.

- **F10. Calendar sync breakage, duplicates and double-booking**
  - Why it happens: two-way sync that edits events the app does not own, non-idempotent writes, and many account types behind the system calendar. Review themes: poor calendar integration (26 mentions in one review set), double-booked meetings, sync bugs.
  - Shows up as: duplicate events, changes to other people's events, conflicts ignored.
  - Build requirement: write only to an app-owned calendar and an app-owned reminders list; store every created identifier and upsert by identifier so sync is idempotent; never edit or delete third-party events; run a reconciliation pass on every launch; QA against every account type the system calendar can hold (platform cloud account, third-party mail accounts added in Settings, corporate mail-server accounts, on-device calendars). Full rules in section 6.

- **F11. Permission refusal at the calendar and health prompts**
  - Why it happens: reading existing events to plan around them needs full calendar access; write-only access cannot see conflicts; reminders are full-access only; each needs its own usage string. Health medication access is authorised per medication, and each newly added medication triggers a new choice.
  - Shows up as: denied prompts leave the scheduler blind to conflicts; users distrust broad access requests.
  - Build requirement: a pre-permission explainer screen before each system prompt; separate usage strings for calendar and reminders; a degraded write-only mode where the user marks busy times manually; per-calendar exclusion of sensitive calendars; the app stays usable with every permission denied (proposed).

- **F12. Population medication curve wrong for the individual**
  - Why it happens: effect-window tools rely on population kinetics or a manual "metabolic rate" setting, while individual onset and wear-off vary. Narrow formulation coverage (as few as 9 medications) also excludes users; broader libraries cover 50+ formulations with release-type-aware kinetics (immediate release, extended release, osmotic, prodrug).
  - Shows up as: demanding tasks placed after the medication has worn off, then trust loss (F6).
  - Build requirement: one-tap "Kicked in" and "Wearing off" logging; per-user curve updated from those taps; a visible uncertainty band on the curve; explicit confirmation before the curve is relied on for high-stakes blocks such as exams; a formulation library of 50+ formulations with release-type-aware kinetics; calibration stored per formulation and dose so a dose change does not corrupt the learned curve (proposed).

- **F13. Irregular dosing and shortages break the plan**
  - Why it happens: 71.5% of US adults taking stimulants reported difficulty filling prescriptions because of shortages, so skipped, late and partial doses are common.
  - Shows up as: a plan built around a dose that never happened, experienced as a failed day.
  - Build requirement: explicit "No meds today", "Late dose" and "Half dose" states that re-plan instantly; every plan stays usable with no medication; skipped is a neutral logged status with no warning styling (proposed).

- **F14. Medical-device classification, liability and claims risk**
  - Why it happens: medication-timing features can fall under software-as-medical-device rules; regulators and ad platforms have acted hard against ADHD-medication businesses (criminal convictions, settlements, ad bans); prescription and reimbursement-dependent ADHD therapeutics collapsed; over half (52%) of the most-viewed short ADHD videos were misleading, so the topic carries misinformation risk.
  - Shows up as: store rejection, regulatory action, ad bans, reputational damage.
  - Build requirement: never recommend a dose, a dose time or a medication change; schedule tasks only around doses the user logs; an in-app disclaimer that the app is a planning tool, not medical advice or a medical device; no "treats ADHD" claims and nothing that promotes stimulant use; clinician review of any medication education copy; legal review of medical-device software rules in each launch market (AU first, then US and UK) before launch; no prescribing or telehealth tie-ins.

- **F15. Health-data privacy breach or loss of trust**
  - Why it happens: medication data is highly sensitive, and on-device, no-account designs are marketed as a trust advantage in this category.
  - Shows up as: users refuse health permissions or leave; breach exposure.
  - Build requirement: health data stays on device by default; no ad or analytics SDK can read health data; any cloud AI call gets only de-identified, minimal context; a plain-English privacy page; graceful handling of per-medication authorisation, revocation and newly added medications; medication names hidden in Lock Screen notification previews by default (proposed).

- **F16. Hallucinated or low-quality AI output**
  - Why it happens: generative models invent items and over-generate action lists; task-breakdown quality is described as hit-or-miss.
  - Shows up as: too many action items, infeasible or wrong plans, then F6.
  - Build requirement: validate every structured AI output against a schema; the model proposes and a deterministic solver checks feasibility; preview before any write to the calendar; cap subtasks per breakdown (proposed cap: 5).

- **F17. AI running cost exceeds revenue**
  - Why it happens: cloud model costs scale with heavy users and every free user is pure cost; one tool in the category had to add a paid tier to cover running costs. Estimate for a heavy user (about 525K input and 105K output tokens a month: 1 daily plan at 4K in and 0.8K out, about 5 parses a day at 1.5K in and 0.3K out, about 2 replans a day at 3K in and 0.6K out): about US$1.05 a month on a small cloud model (US$0.75 with prompt caching), about US$2.10 on a mid-tier model, about US$0.10 on the cheapest tier, US$0 on device. A light user costs about US$0.35. Store commission is 15% under US$1M annual proceeds and 30% above, so on an about A$10 a month plan a mid-tier model can take a double-digit share of net revenue for heavy users.
  - Shows up as: shrinking margins, then pressure to paywall features that were free (F20).
  - Build requirement: on-device model for parsing, task breakdown and priorities (free, offline, private); a deterministic constraint solver for core scheduling; any cloud model limited to weekly planning or explanations, with prompt caching; zero cloud AI calls on the free tier (proposed); a deterministic fallback wherever the on-device model is unavailable (it needs a capable device with system AI enabled on iOS 26 or later, and availability varies by region and language).

- **F18. AI-positioned products churn faster**
  - Why it happens: AI apps retain 36% worse over 12 months, despite a 41% higher year-1 LTV (US$30.16 vs US$21.37).
  - Shows up as: curiosity sign-ups followed by fast churn.
  - Build requirement: design and market around the medication-aware day plan and daily habits, not a chatbot; AI is invisible infrastructure (proposed: no chat screen as a primary tab).

- **F19. Trial too short for value to appear**
  - Why it happens: behavioural learning needs weeks of data, so a 3 to 7 day trial ends before the main value shows; reviewers call a one-week trial too short. Trials of 17 to 32 days convert 42.5% vs 25.5% for trials under 4 days; 55.4% of 3-day-trial cancellations happen on day 0.
  - Shows up as: cancellation before the payoff, much of it on day 0.
  - Build requirement: a 14 to 30 day trial, or a free core with learning insights unlocked after 2 weeks of data; a "What I've learned about you" summary shown before any upgrade prompt. Rules in section 5.

- **F20. Subscription resentment and billing backlash ("ADHD tax")**
  - Why it happens: surprise renewals (users report being charged a full year in advance), refused refunds, accidental annual purchases, trials offered only on annual plans while monthly is charged immediately, card-required trials, content locked during the trial, and repeated price increases.
  - Shows up as: 1-star billing reviews and refund requests (Health and Fitness refund rate 4.71%, among the highest of any category).
  - Build requirement: trial-end reminder notification 2 days before conversion; one-tap route to cancel plus plain cancel instructions; never hide the charge behind "Try free"; trial on every plan length; nothing in the paid tier locked during the trial; student and hardship pricing; an opt-in lifetime option; existing subscribers keep their price when prices rise (proposed). Rules in section 5.

- **F21. Involuntary churn from billing failures**
  - Why it happens: failed renewals cause 14% of store subscription cancellations.
  - Shows up as: paying users lose access without choosing to leave.
  - Build requirement: enable the store's billing grace period (proposed); detect billing-retry state from subscription status and show a calm "Update payment method" banner that deep-links to subscription management (proposed); keep paid features and all learned data through grace and retry (proposed).

- **F22. Notifications too weak, inconsistent or too many**
  - Why it happens: a single short chime is easy to miss with ADHD; delivery is inconsistent; alerts are weak; and too many prompts train users to ignore them. Some tools escalate to alarms or screen locks.
  - Shows up as: missed doses and transitions, or notification fatigue and muting.
  - Build requirement: Time-Sensitive notifications with a distinct sound and haptic per event type (dose, wear-off, transition); user-tunable escalation per type; the app learns which prompts get ignored and sends fewer of them. Limits and tone in section 3.

- **F23. UI churn and regressions disorient users**
  - Why it happens: frequent layout and feature changes, and updates that break working features (reviews describe one step forward and two steps back), unsettle neurodivergent users.
  - Shows up as: confusion, lost muscle memory, reviews about disruptive updates.
  - Build requirement: a stable navigation contract (tab order and the position of primary actions stay fixed between releases, proposed specifics); new features ship behind opt-in toggles; in-app changelog; pre-release beta channel; a regression suite for widgets, timers, notifications and sync before every release (proposed).

- **F24. Glance surfaces and companion devices fail**
  - Why it happens: companion surfaces that depend on a live sign-in session or on the phone. Review themes: random sign-outs on the watch mid-routine, widget access problems, timer glitches.
  - Shows up as: blank widgets, a signed-out watch, timers that stop.
  - Build requirement: widgets, Live Activities and any watch app run offline from local data with no sign-in dependency; watch complications never need the phone; no silent sign-outs (proposed); timers based on absolute end times so they survive app suspension (proposed).

- **F25. Missing basics that dominate reviews**
  - Why it happens: gaps in expected basics: week and month overview, notes on tasks, easy routine editing, offline use (an internet-only assistant is criticised), reminders on the free plan (a free tier without reminders is criticised), native system calendar support, and phone apps that feel like a cut-down afterthought.
  - Shows up as: "lacks X" reviews and switching to another app.
  - Build requirement: v1 includes week and month views, notes on tasks, inline routine editing, offline operation of every core flow, reminders in the free tier, and native system calendar and reminders integration as a first-class feature.

- **F26. Service shutdown, platform overlap and stranded data**
  - Why it happens: a decade-old scheduling service shut down with one week's notice after an acqui-hire; the platform's own health app already logs medications with reminders and interaction warnings, and now shares dose data with apps.
  - Shows up as: users lose plans and history; basic medication logging becomes redundant.
  - Build requirement: local-first data that keeps working with no server; full data export at any time (proposed: on every tier); build on platform data rather than competing with it (read dose events from the health store, write blocks to the calendar); differentiate on ADHD-specific effect modelling and learning; a published minimum shutdown notice (proposed: 90 days); adopt current platform surfaces to earn store editorial featuring.

- **F27. Stale maintenance and unanswered complaints**
  - Why it happens: small teams stall; several tools in the category show last updates 2 or more years old; one vendor replied to only 11% of negative reviews.
  - Shows up as: users and store editors read silence as abandonment; complaints compound.
  - Build requirement: in-app "Send feedback" reachable in 2 taps from Settings (proposed); in-app changelog; reply to every negative review (proposed target: 100%); a steady, visible release cadence (proposed: at least monthly).

- **F28. Small launch market and late localisation**
  - Why it happens: about 600K people were dispensed ADHD medication in AU in 2023 to 2024, AU store rating counts run at about 7% to 9% of US counts, and 1% paid conversion of 600K is about 6K subscribers. The US has about 5.2M adults on stimulants and the UK about 1.9M adults with ADHD. The same molecule is sold under different brand names per country, and academic terms differ.
  - Shows up as: a growth ceiling and costly retrofitted localisation.
  - Build requirement: localisation from v1: AU, UK and US spelling; per-country formulation brand names mapped to one molecule and release type; per-country academic term structures; the first market treated as the beta market.

## 2. Onboarding and activation rules

- Time from first launch to first accepted plan is under 3 minutes at the median (F3).
- Order: see a plan first, grant permissions just in time, create an account and see pricing last (proposed).
- Ask at most 4 things before the first plan: wake and sleep times, medication or "Not taking any" or "Set up later", calendar access, and a brain dump of today's tasks (proposed).
- Before each system prompt (calendar, reminders, health, notifications) show a one-screen explainer: what is read, what is written, and that events outside the app's own calendar are never edited.
- Every calendar outcome leads somewhere useful: full access plans around existing events; write-only lets the user mark busy times manually; denied falls back to manual planning with no calendar writes (denied path proposed).
- Offer sensitive-calendar exclusion at the calendar step and again in Settings.
- Import dose events from the system health store when the user already logs medications there, so doses are never logged twice; handle partial, per-medication authorisation.
- Medication step: pick from a 50+ formulation library with localised brand names; default the effect window to the population curve for that formulation; show the uncertainty band from day 1; skipping is allowed and still leads to full planning without medication.
- Write for people new to medication: adults are about half of new ADHD medication starts in AU and 55.9% of US adults with ADHD were diagnosed in adulthood, so onboarding avoids pharmacology jargon and explains the effect window in one sentence (proposed).
- Non-stimulant path: psychostimulants are 87% of AU ADHD prescriptions, so about 13% of users need a setup that does not assume a same-day onset, peak and wear-off curve (proposed).
- Task capture is a free-text brain dump parsed on device into tasks; only a title is required (proposed).
- The first plan runs in "suggest, then confirm" mode and shows the reason for each placement (F6).
- Customisation and day types are not part of onboarding; they are revealed after first use (proposed timing), and day-type switching is suggested later from imported academic dates (F9).
- Account creation is optional until a feature needs it (backup, multi-device sync); the free core works without an account (proposed).
- No paywall before the first plan is shown (proposed). When the trial is offered, the screen states trial length, price after trial, billing period, total annual charge, first charge date and how to cancel.
- Request notification permission in context, when the user first sets a dose reminder or accepts a plan with transitions (proposed).
- Activation event (proposed): within 24 hours of install the user accepts a first plan and logs a first dose or selects "No meds today". Track the activation rate per onboarding variant.
- After 2 weeks of data, show "What I've learned about you" before any upgrade prompt (F19).

## 3. Notification and nudge rules (limits, timing, tone)

- Event types: dose reminder, estimated wear-off, transition to the next block, daily "What moved" digest, trial-end reminder. Each has its own toggle and a preview on one Notifications settings screen (layout proposed).
- Dose, wear-off and transition alerts use the Time-Sensitive interruption level with a distinct sound and haptic per type; all other nudges use a lower level (split proposed).
- Escalation is user-tunable per type (off, single, repeat). Proposed default for dose reminders: repeat every 5 minutes, up to 3 times, until logged or dismissed (proposed).
- Opt-in alarm-grade dose alerts through the system alarm framework on iOS 26 for users who say a normal alert is not enough (proposed; confirm eligibility and review rules).
- Budget: at most 5 app-initiated notifications a day; reminders the user set explicitly do not count (proposed).
- Automatic moves never trigger individual notifications; they are summarised once a day in the "What moved" digest at a user-chosen time (digest from source, timing proposed).
- Ignore learning: if a nudge type is ignored 3 times in a row, halve its frequency and offer a one-tap "Fewer of these" choice (thresholds proposed; learning to reduce ignored prompts is from source).
- Reliability: every reminder is scheduled locally on device so delivery never depends on the network or a server (proposed).
- Wear-off alerts fire at the start of the personal estimated window and state it as a range, for example "Estimated wear-off from about 3:10 to 3:40 pm" (wording proposed).
- Tone: estimates are phrased as estimates; no notification ever suggests taking, skipping, delaying or changing a dose (F14).
- Tone: no guilt. Banned in any notification: "missed", "failed", "behind", "overdue", "don't break your streak" (proposed).
- Privacy: medication names are hidden in Lock Screen previews by default (proposed).
- Quiet: respect the system Focus state; no non-critical nudges inside the user's sleep window (proposed).
- Trial end: exactly one reminder 2 days before the trial converts, stating the price, the charge date and the cancel path.
- Re-engagement: at most one re-engagement notification per 7 days of inactivity, framed as a fresh start and never listing what was missed (proposed).

## 4. Retention without shame (streaks, recovery, resets)

- Passive value first: widgets, the Live Activity, system calendar blocks and a glanceable peak-window status keep the plan useful on days the app is never opened, so not opening the app is never a failure state (F1).
- No overdue pile-up: past unfinished items go to a neutral "Parked" list; nothing is auto-carried into today and no count of undone items is shown anywhere (principle from source, mechanics proposed).
- Fresh start: after 2 or more days away, open on a "Fresh start" screen offering "Plan today" or "Look at parked items", with no recap of missed days (principle from source, threshold proposed).
- Streaks: none that reset to zero. Any consistency figure is cumulative and never decreases, for example "12 days planned this month" (proposed; the source has no streak evidence).
- Medication states: "No meds today", "Late dose" and "Half dose" are neutral, first-class choices that re-plan instantly, and the plan stays usable without medication (F13).
- Recovery after a hard day: remaining tasks are re-offered in the next low-demand slots as suggestions, never as a red backlog (proposed).
- Realistic days: the 60% capacity cap and mandatory buffers leave slack so a plan can actually be finished (F5).
- Control lowers anxiety: "Lock this day", floating tasks, one-tap undo, and pinned or user-created items are never moved (F6, F7).
- Resets: the user can reset learned patterns per day type and reset the personal curve to the population default, each with undo (proposed); each day type keeps separate learning (F9).
- Lapse without loss: when a subscription ends, the free core and all data remain, and the paid learning state is kept and restored on resubscribe (proposed).
- Stable home: navigation and layout stay the same across releases so a returning user finds everything where it was (F23).
- Ignored nudges become fewer, never louder or more guilt-laden (section 3).
- Insight tone: "What I've learned about you" is written as observations, never as scores, grades or percent complete (proposed).
- Any weekly review is optional and skipping it has no consequence (proposed).

## 5. Monetisation, trial and paywall rules

- Tier shape: a free core with medication logging, the effect window, manual planning and reminders; the paid tier adds automatic scheduling and behavioural learning. The free core must not feel like an "ADHD tax".
- Free-core contract: a feature that ships free stays free and is never moved behind the paywall later (proposed; mirrors a public promise that users reward in this category).
- Paywall model trade-off: hard paywalls convert 10.7% vs 2.1% for freemium by day 35 and earn US$3.09 vs US$0.38 per install by day 60, but year-1 retention of annual subscribers is about the same (27% vs 28%), and ADHD users visibly reward non-punitive pricing (scholarships, free cores, lifetime). Default: free core plus a long trial of the paid tier, with no hard paywall before first value (proposed).
- Trial length: 14 to 30 days. Trials of 17 to 32 days convert 42.5% vs 25.5% for trials under 4 days; 55.4% of 3-day-trial cancellations happen on day 0; reviewers say one week is too short.
- Trial scope: offered on monthly and annual plans (a trial only on annual, with monthly charged at once, draws complaints); everything in the paid tier is unlocked during the trial.
- Paywall placement: after the first plan, ideally after 2 weeks of data, and preceded by "What I've learned about you".
- Price disclosure on the paywall and its button: trial length, price after trial, billing period, total annual charge next to any per-month equivalent, first charge date and how to cancel. A button that says only "Try free" is not allowed (principle from source, specifics proposed).
- Accidental annual purchase: plan choice is explicit and the selected option shows the full annual charge (proposed).
- Trial-end reminder notification 2 days before conversion.
- Cancel: an in-app "Manage subscription" row that opens the system subscription sheet, plus plain-language cancel steps.
- Refunds: an in-app "Request a refund" entry point using the store's refund flow (proposed). Health and Fitness refund rate is 4.71%, among the highest of any category.
- Plan lengths: monthly and annual. Annual plans are 67% of Health and Fitness subscriptions sold and 61% of category revenue; high-priced annual plans earn about 4 times the LTV of low-priced ones. Reference price: premium ADHD planners cluster around US$10 a month; the working assumption is about A$10 a month.
- Free-tier limit references: category free tiers cap the scheduling horizon (1 to 2 weeks), connected calendars (1), recurring auto-scheduled tasks (3) or tracked medications (2, with ads), and a free tier without reminders is criticised. If the free tier must be capped, cap the automatic-scheduling horizon, never logging or reminders (proposed).
- Student price at launch (university audience); category student discounts range from 25% to 50%.
- Hardship: a scholarship or pay-what-you-can path on request (proposed implementation: store offer codes).
- Lifetime: opt-in only, with a cap on cloud AI usage.
- Funded purchases: some UK students can get specialist software funded through a disability allowance (up to £27,783 a year), so support code redemption or bulk purchase (proposed; the source did not confirm ADHD eligibility).
- Churn to design against: about 72% of annual subscribers cancel within year 1 and 35% of annual cancellations happen in month 1; first renewal is 59.2%, second 45.1%. The first paid month must surface a visible new insight (proposed).
- Involuntary churn: billing failures cause 14% of cancellations; handle grace and retry (F21).
- Price changes: repeated price increases draw complaints; grandfather existing subscribers (proposed).
- AI cost guardrails: zero cloud AI cost on the free tier (proposed); cloud AI spend below 10% of net revenue per paying user (proposed); lifetime cap as above.
- Store commission: 15% under US$1M annual proceeds, 30% above; enrol in the reduced small-developer rate (proposed).
- Never paywall safety-relevant or ownership features: dose logging, the effect window, reminders and data export stay free (export proposed).

## 6. Reliability, data safety and sync rules

- Write scope: write only to one app-owned calendar and one app-owned reminders list; never edit or delete third-party events or reminders.
- Idempotency: persist the identifier of every created event and reminder; every write is an upsert keyed by that identifier.
- Reconciliation on every launch: detect duplicates (merge), app events the user deleted (respect the deletion, do not recreate) and app events the user moved (treat as pinned) (reconciliation pass from source, handling rules proposed).
- QA matrix covers every account type the system calendar can hold: platform cloud account, third-party mail accounts added in Settings, corporate mail-server accounts, on-device calendars.
- Change safety: preview before any calendar write; one-tap undo for every automatic change; at most N automatic moves per day (F7).
- Offline-first: planning, dose logging, reminders, widgets and Live Activities work with no network.
- No sign-in dependency: local use and all glance surfaces work signed out; the app never signs a user out silently (proposed).
- Health store: access is read-only (apps cannot write dose events) and authorised per medication; dose events carry status (taken, skipped, snoozed), scheduled and logged timestamps, and quantities. The app's own log is the write path; de-duplicate against health-store events for the same medication (proposed window: within 30 minutes).
- Health data stays on device by default; no ad or analytics SDK may read it; cloud AI calls get de-identified, minimal context only.
- AI output: schema validation for every structured result; the deterministic solver verifies feasibility before anything is shown or written.
- On-device model fallback: every AI-assisted feature has a deterministic path for devices, regions or languages without the on-device model.
- Export: full export at any time of tasks, plans, dose log, curve calibration and day types in open formats (proposed formats: CSV, JSON and a calendar file).
- Continuity: local data keeps working if servers disappear; a published minimum shutdown notice (proposed: 90 days).
- Sync conflicts: merge per record; when both sides changed, keep both and flag the conflict, never drop data silently (proposed).
- Learned state durability: personal curve calibration and per-day-type patterns survive reinstall and device migration (proposed: via account backup or encrypted device backup).
- Account deletion: available in-app, deletes server copies, and offers export first (proposed).
- Releases: beta channel before release; regression suite for widgets, timers, notifications, sync and any watch app; phased rollout (rollout proposed).
- Timers store absolute end times so they survive suspension and relaunch (proposed).

## 7. Metrics to watch (privacy-preserving) and thresholds

- Privacy rule for all metrics: first-party, aggregated event counts only; no medication names, doses, dose times, task text or calendar content leaves the device; anything derived from medication data is computed and shown on device only (proposed; consistent with the no-SDK-on-health-data rule).
- Retention: D1, D7 and D30 cohorts from launch day. Floor benchmarks for mental-health apps: 3.9% at day 15 and 3.3% at day 30. A D30 at or below 3.3% means the passive surfaces are not delivering (interpretation proposed).
- Daily use: benchmark is 4% of 30-day installers opening per day, median 13 minutes a day; also count sessions started from widgets, Live Activities and notifications (proposed).
- Onboarding: median time to first plan under 3 minutes; drop-off per step (proposed).
- Activation rate: first plan accepted plus first dose or "No meds today" within 24 hours (definition proposed).
- Permission outcomes: share granting full calendar access, write-only or none; health authorisation granted or not (proposed).
- AI trust: suggestion acceptance rate, undo rate on automatic moves, and share of users who switch automatic scheduling off (the source has no benchmark, so measure from day 1). Alarm if undo rate is above 20% or acceptance is below 50% in weeks 1 and 2 (thresholds proposed).
- Capacity: share of automatically planned days above 60% of free time; target 0.
- Notifications: ignore rate and opt-out rate per type; count of automatic reductions triggered (proposed).
- Funnel benchmarks (Health and Fitness): install-to-trial 11.2% (North America 14.5%); trial-to-paid median 39.9% (top decile 68.3%), and 42.2% in a second benchmark for weekly plans with trials; 17 to 32 day trials 42.5%; install-to-paid about 3.7%.
- Day-0 trial cancellations: benchmark 55.4% for 3-day trials; with a 14 to 30 day trial the share should be far lower (expectation proposed).
- Paywall comparison: day-35 conversion 10.7% hard paywall vs 2.1% freemium; revenue per install at day 60 US$3.09 vs US$0.38.
- Renewal and churn: first renewal 59.2%, second 45.1%; about 72% of annual subscribers cancel within year 1, 35% of those cancellations in month 1; billing failures are 14% of cancellations; refund rate benchmark 4.71%.
- AI-app benchmark: 12-month retention 36% worse than non-AI apps; year-1 LTV US$30.16 (AI) vs US$21.37 (non-AI).
- AI cost per active user per month: heavy about US$1.05 on a small cloud model (US$0.75 with caching), about US$2.10 mid-tier; light about US$0.35; on device US$0. Alert if cloud AI spend passes 10% of net revenue per paying user or any free-tier cloud cost appears (thresholds proposed).
- Reliability: duplicates and repairs found by the launch reconciliation per 1,000 active users, target 0 (proposed).
- Reviews: tag every review by theme (alert strength, sync and duplicates, UI changes, billing and refunds, setup, AI quality, widget or watch reliability); reply to 100% of negative reviews (proposed; one category vendor replied to 11%).

## 8. Open questions

- Paywall model: freemium core plus long trial (the source's recommendation) or a hard paywall (about 5 times the day-35 conversion)? The owner must choose.
- Trial mechanics: a store-managed introductory free trial (auto-converts and needs a payment method on file), an app-managed no-commitment trial, or a free core with an unlock after 2 weeks? The category rewards no-card trials.
- Exact trial length within 14 to 30 days, and does it start at install or when the user opts in?
- Free vs paid split: are on-device AI priorities (zero marginal cost) and day types free or paid?
- Is any cloud model used at all, given on-device AI priorities? If yes, for which features and with what per-user cap?
- Lifetime tier: offered or not, at what price, with what cloud AI cap?
- Student and hardship pricing: how is eligibility verified, and is it delivered by offer codes or on request?
- Regulatory position of medication-timing-aware scheduling under AU, US and UK medical-device software rules, and health-information duties under AU privacy law: the source could not read the regulator guidance, so legal review is launch-critical.
- Can the free core run with no account at all?
- Is a watch companion in v1? The source's one-tap calibration logging assumes one.
- Is a clinician-shareable report (dose times, perceived onset and wear-off, task completion by window) in v1? The source sees it as a referral channel and a trust signal.
- Exact values: automatic-move cap N per day, capacity cap (the source says about 60%), buffer length.
- Streaks: confirm there are none that reset (the source has no evidence either way).
- Day-type auto-suggest: which academic calendar source (user-entered dates, an imported calendar file, institution feeds)?
- Non-stimulant users: what does the effect window show for them?
- v1 localisation scope and market order (AU as beta, then US and UK).
- Refund promise: refunds are store-controlled; does the app promise anything beyond the store flow (the category offers 30-day money-back guarantees on web)?
- Funded purchases (disability allowances, institutions): support codes at launch?
- Alarm-grade alerts: confirm dose reminders qualify on iOS 26.
- Minimum OS for reading medication dose events from the health store (believed iOS 26, not confirmed in the source).
- Peer support shows the highest daily use among mental-health apps (median 35 minutes a day); is any social or body-doubling feature in scope?
- Source gaps: no ADHD-specific retention or willingness-to-pay data, no data on how many users switch off auto-rescheduling after a bad move, no hallucination-rate or latency benchmarks, no AU conversion benchmarks; the 72% annual-cancellation figure conflicts with 27% to 28% year-1 retention (likely different cohorts), so which one drives the forecast?
