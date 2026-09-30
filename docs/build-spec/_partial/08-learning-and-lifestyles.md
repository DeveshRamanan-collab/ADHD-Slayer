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

## Findings from the code check (fix or decide when resuming)

- LL-01, LL-07 and LL-21 are built in the learning model only. No screen or notification collects a check-in yet; `AppModel.seededModel` fakes 9 days of answers with a fixed 45 min and 7 hr estimate instead of the medication's sliders.
- Labelling bug: Today's confidence line reads the model's confidence even when the medication isn't learning and the window comes from the sliders, so it can wrongly say "from N check-ins". Focus window edits on Patterns only reach the plan when learning is on.
- LL-04: `FocusWindowModel.proposal` exists and is tested, but `AppModel.proposalDismissed` is unused and nothing shows the proposal.
- LL-24: learned state and check-ins aren't saved yet. `medication.json` uses `completeFileProtectionUntilFirstUserAuthentication` and isn't excluded from device backup, which conflicts with "never in iCloud" (set `isExcludedFromBackup`, use complete protection).
- LL-02: only the All day kind can learn; decide whether short-acting ones should.
- LL-13: "Start over" on Patterns resets the person's own adjustments, not what the model learned.
- LL-20: `SafetyGate` (FocusPlanning/SafetyGate.swift) is tested but never called in the app. The medication editor's learned line calls the time until the curve ends "helping for", which reads as a length of time.
- Two small points from the original source folded in: a "median error versus the raw guess" measure (LL-26) and blinding of self-rated outcomes in trials of one (LL-11).
