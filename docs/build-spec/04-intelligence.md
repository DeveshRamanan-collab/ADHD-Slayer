# Focus: intelligence

Every use of Apple's on-device model, and every planning and learning algorithm. **Built** means it exists in `app/FocusApp` or `app/FocusCore`; **To build** means it doesn't yet. Screens are in `01-product-and-features.md`; platform details in `05-platform.md`.

## Principles

- The model interprets and words; deterministic code decides and computes. Every number the person sees comes from code; the model never computes, rounds or invents one.
- On the iPhone only: `SystemLanguageModel` (Foundation Models, iOS 26). No server model and no cloud tier. The person's own AI (optional) is separate and never receives medication data (`01`, Bring your own AI).
- Prompts never contain medication names, strengths, dose times, logged doses, check-ins, health data, the person's name or account. Plan items and calendar titles stay on the phone.
- Every model output is a `@Generable` type with no field that could express a medication action. Outputs are validated field by field and fall back to deterministic text.
- Learning is small Bayesian arithmetic in plain Swift, fully explainable, run on the phone. The person's own numbers come first and win until they choose otherwise.
- The type system is the first fence: `FocusPlanning` (scheduler, learner, safety gate) cannot import `FocusMedication`, so no plan, model or AI path can create, move or suggest a dose. `PlanChange` only has task cases. The `SafetyGate` is the second fence.
- Internal names in this file (onset, offset, formulation, template) never appear in the app. The person sees "focus window", "working well after", "stops helping after" and "your usual focus".

## Availability and the launch device check (Built)

| `SystemLanguageModel.default.availability` | At launch | Smart features |
|---|---|---|
| `.available` | Passes | Model used |
| `.unavailable(.deviceNotEligible)` | Blocks: "This iPhone can’t run Focus" | Not reachable |
| `.unavailable(.appleIntelligenceNotEnabled)` | Blocks: "Switch on Apple Intelligence", Open Settings, Check again | Not reachable |
| `.unavailable(.modelNotReady)` | Blocks with "Start anyway", which passes for this session | Fallbacks until ready |
| Any future case | Getting-ready screen; a tap re-checks | Fallbacks |

- Re-checked at every launch and on every return to the foreground (`willEnterForegroundNotification`); the gate isn't persisted, so a later launch with the model off blocks again.
- Each generation entry point checks `SystemLanguageModel.default.isAvailable` again and uses the fallback when false.
- There is no App Store device key for Apple Intelligence, so the gate is the only control; the App Store listing states the requirement (iPhone 15 Pro or newer).
- Simulator: the model is available only when the Mac itself runs Apple Intelligence. UI tests and CI launch with `-skipGate`, which also exercises every fallback path.
- To build: check `supportedLanguages` against the current locale (fallbacks if unsupported); confirm en-AU availability.

## Rules for every model call

- A new `LanguageModelSession` per request with fixed instructions; no transcript is reused, so each call starts near zero tokens.
- Guided generation only (`respond(to:generating:options:)`); free text is never parsed.
- Temperature 0 for classification, 0.2 for wording. `maximumResponseTokens` 200 for priorities (To build: 40 for the classifiers).
- Foreground only: generation runs while a screen is visible or just after launch, never from background tasks (background calls can be rate limited).
- Any thrown error (context overflow, guardrail, unsupported language, rate limit, cancellation, anything else) falls back silently; no model error ever reaches the screen. To build: count error kinds locally, with no content, for diagnostics; a 10 s timeout that falls back.
- Stale results are dropped: a result is used only if its input key still matches the latest.
- To build: a prompt regression set (20 days of plans, 50 task titles, 50 event titles) run on every iOS release; pass criteria are listed per use below.

## The context limit (4,096 tokens)

- On iOS 26 one session holds 4,096 tokens: instructions, prompt, schema and output together. Overflow throws `exceededContextWindowSize`, which falls back.
- Budgets keep every call below a quarter of the limit:

| Use | Instructions | Prompt | Schema and output | Worst case |
|---|---|---|---|---|
| Today, in five | about 110 | about 250 (3 header lines, 6 items) | about 350 | under 800 |
| Sort a task | about 20 | about 8 per category plus the title | about 30 | under 500 with 40 categories |
| Read an event | about 15 | the title | about 40 | under 150 |

- Guards (To build): titles cut to 80 characters before prompting; at most 40 categories per prompt (with more, keep the 40 whose keywords overlap the title most, then the rest in order); measure with `tokenCount(for:)` where available and trim items until the prompt is under 3,000 tokens.

## Use 1: Today, in five (Built, `Model/Priorities.swift`)

- Purpose: the five things that matter most today, worded as short actions.
- Inputs: today's plan blocks not done and ending after now, the tasks marked as a must, the focus window and the lighter-day switch.
- Candidates, ranked by code: 100 if happening now, plus 80 if a must, plus 70 for a calendar event, plus 60 deep work, 45 body, 35 lighter work, minus hours until it starts. The top 6 are kept. With fewer than 6 and the window still open, "Rest as focus fades" at the window's end is added; then fillers "Write tomorrow's first step", "Drink some water", "Go gently with yourself".
- Each item carries a title, a detail ("deep work, essential, happening now, until 10:55"), a "when" ("until 10:55", "at 11:05" or none) and a fallback sentence ("Finish essay drafting by 10:55.", "Case reading at 11:05.").
- Prompt (example):

```
Now: 9:41.
Best focus until 3:20.
It's a lighter day: essentials first.
1. Essay drafting: deep work, essential, happening now, until 10:55
2. Coffee with Maya: fixed appointment, 10:30
3. Case reading: deep work, 11:05
4. Lunch, even if you’re not hungry: body, essential, 1:00
5. Tutorial, Room 4.12: fixed appointment, 2:00
6. Email and plan tomorrow: lighter work, 3:20
```

- Instructions, verbatim: "You help someone with ADHD see what matters most today. You get today's remaining items, numbered. Choose the five that matter most, most important first: 1. whatever is happening now, 2. items marked essential, 3. fixed appointments, 4. deep work during best focus, 5. eating and looking after the body. Then write a short action for every item. Plain and calm. Never mention medication, doses, pills or health."
- Schema:

```swift
@Generable struct DayPriorities {
    @Guide(description: "The numbers of the five most important items, most important first. Use each number once.", .count(5))
    var ranking: [Int]
    @Guide(description: "For every item in the list, in the list's order: a short action of two to five words that starts with a verb, like 'Draft the essay' or 'Eat lunch'. No times, no numbers.", .count(6))
    var actions: [String]
}
```

- Options: temperature 0.2, at most 200 output tokens.
- Validation (`compose`, `clean`):
  - The ranking must be exactly 5 distinct numbers from 1 to 6, or the whole answer is rejected.
  - Each action is trimmed of spaces and punctuation, then must be 1 to 40 characters of letters, spaces, apostrophes and hyphens (no digits), 1 to 6 words, and must not match `(?i)medic|dose|dosage|pill|tablet|\bmg\b|stimulant|prescri|vyvanse|adderall|ritalin|concerta|elvanse|dexamph|\bai\b`. It gets a capital first letter.
  - A failed action uses that item's fallback sentence; if fewer than 3 actions pass, the whole list falls back.
  - Code appends the time: "Draft the essay until 10:55.", "Read the case at 11:05.", "Drink some water."
- Refresh key: lighter-day switch, brain weather, done count, open block ids and the hour. The same key never regenerates; while a new answer is pending the previous lines stay.
- To build: add the person's own medication names and strengths to the banned pattern at run time; pass each line through the `SafetyGate`.
- Accept: with the model off, the lines equal the ranked fallback; a duplicate rank falls back; "Take your meds" is rejected; every time on screen equals the plan's.

## Use 2: Sorting tasks into categories (Built, `OnDeviceReader.category`)

- When: after launch, for every task without a category (To build: also when a task is added or renamed).
- Instructions: "You sort someone's tasks into their own categories. Answer with a number only."
- Prompt: "Categories:" then "1. Deep study", "2. Admin" and so on, then "Task: Essay drafting".
- Schema: `@Generable struct CategoryPick { @Guide(description: "The number of the category that fits best, or 0 if none fits.") var choice: Int }`. Temperature 0. To build: `.range(0...count)` on the guide.
- Validation: 1 to the category count is used; 0 or out of range falls back.
- Fallback: the first category whose keywords appear in the lowercased title (Deep study: essay, reading, study, write, assignment, research, case; Admin: email, admin, forms, bills, plan tomorrow, reply; Prep: prep, prepare, revise, notes, tutorial; Movement: gym, run, walk, yoga, swim, training; Home stuff: clean, laundry, groceries, dishes, tidy, cook). No match: no category, so no preferred window.
- Stored in `taskCategories` (task id to category id). To build: a category the person picks by hand is never overwritten.
- Accept: "Gym, upper body" lands in Movement with the model off; a deleted category's tasks fall back to none.

## Use 3: Reading calendar events for plans with people (Built, `OnDeviceReader.read`)

- When: after the calendar loads, after each dose log, and when suggestions are switched on.
- Short cut: more than one attendee means "with other people" without the model. To build: pass the real attendee count (the code passes 0).
- Instructions: "You read calendar event titles. Never guess private details."
- Prompt: "Event title: Coffee with Maya".
- Schema: `@Generable struct EventRead { @Guide(description: "True if this plan involves meeting or talking with other people.") var withOtherPeople: Bool; @Guide(description: "The first name of the other person if the title gives one, otherwise an empty string.") var personName: String }`. Temperature 0.
- Validation: an empty name means none. To build: use the name only if it is one word of letters, at most 20 characters, and appears in the title (so the model can't invent a person); otherwise the draft says "there".
- Fallback: social if the title contains " with ", "coffee", "dinner", "drinks", "catch up", "catch-up", "party", "brunch", "date", "hang" or "call w"; the person is the word after " with ".
- The draft message is copy (`socialMessage`), never generated; the person edits and sends it themselves.
- Accept: "Dentist" is not social; "Dinner with Priya" gives Priya; nothing is sent automatically.

## Use 4: First steps (To build)

- Purpose: the "First step" line on the Now card and in Focus mode (a demo table today; default "Do the first two minutes").
- Schema: `@Generable struct FirstStep { @Guide(description: "One physical action that starts this task, under ten minutes, starting with a verb, at most eight words.") var action: String; @Guide(.range(1...10)) var minutes: Int }`.
- Prompt: the task title only. Validation: 60 characters and 8 words at most, no digits, the banned pattern and the `SafetyGate`; else the default. Cached per task; a step the person edits is never regenerated.

## Use 5: Reading a new task (To build)

- Fills only the blanks the person left: `@Generable struct TaskRead { var demand: Demand /* deep, medium, light, body */; @Guide(.range(5...240)) var roughMinutes: Int; @Guide(description: "Category number, or 0") var category: Int }`. Anything the person typed wins; the result is editable.

## The safety fence (Built, `FocusPlanning/SafetyGate.swift`)

- Eight patterns: dose actions (take, skip, double, increase, move, delay near dose, meds, tablet, pill), "booster", dose timing ("when" or "what time" near take or dose), amounts (mg, mcg), drug-effect words (wear off, onset, pharmacokinetic, half-life, effectiveness, kicks in), device words ("predicts" near dose or window), safety claims ("safe to take"), treatment claims ("reduces ADHD").
- Contexts: AI rewording and notification bodies are replaced by "That’s one for your prescriber or pharmacist."; parsed titles become "Untitled task".
- Used today on every answer from the person's own AI. To build: every generated line (priorities, first steps), every notification body and any parsed title.

## The day from a kind of day (Built, `DayType.schedule`)

- Automatic windows: for each dose of a medication that isn't a wind-down and whose "stops helping" exceeds "working well": from dose plus working-well minutes to dose plus stops-helping minutes. Windows merge when they overlap or the gap is under 20 min.
- Drawn windows ("Draw my own") replace them and merge only when overlapping.
- Wind-down: cut = earliest wind-down dose time minus the wind-down buffer (default 60 min). Windows are clipped to end by the cut; any left shorter than 15 min is dropped. If a window was cut, focus ends "for the wind-down".
- Low-focus gaps: between consecutive windows at least 20 min apart.
- Sleep usually possible: the latest of dose plus "sleep after" over doses that aren't wind-downs and have one set.
- Worked example (learning off): short-acting 7:00 (30 min, 4 h), all day 8:10 (1 h, 9 h), short-acting 18:00, wind-down 21:30 with a 1 h buffer. Windows 7:30 to 17:10 and 18:30 to 20:30 (cut at 20:30); a low-focus gap 17:10 to 18:30.

## Today's focus window (Built, `AppModel.planningWindow`)

- Needs today's schedule and a first planned dose that isn't a wind-down; otherwise it's a routine day (no window).
- If that first dose was logged, every window, gap and sleep time shifts by logged minus planned.
- The window uses fixed ramps of 20 min up and 60 min down: onset = start − dose − 20 (not below 0); offset = end − dose, at least onset + 95. Best focus runs from the window start to 60 min before its end; lighter focus from then to the end.
- The effect curve E(t) (`FocusCurve`): 0 before onset and after offset, otherwise min(1, (t − onset) ÷ ramp up, (offset − t) ÷ ramp down), in minutes after the dose.
- Zones: before the dose, warming up, best, lighter, after. They drive the Now line, the sky phase and the scheduler.
- The ± on each edge comes from the learning model. Confidence: "Your own setting" when the kind of day uses drawn windows or no learning all-day medication is planned today; otherwise the model's label.
- A learning all-day medication has its sliders replaced for planning: working well = learned onset + the model's ramp up; stops helping = learned offset.

## The focus window model (Built, `FocusPlanning/FocusWindowModel.swift`)

- One model per product. Non-window formulations (`nonStimulant`) have none.
- Grid: onset 0 to 180 min and offset 120 to 960 min, both in 15 min steps: 13 × 57 = 741 cells. A cell is valid only if it leaves at least 30 min at full effect (offset − ramp down > onset + ramp up + 30).
- Fixed ramps and label priors by formulation (template shapes only, never shown):

| Formulation (internal) | Ramp up | Ramp down | Prior onset | Prior offset |
|---|---|---|---|---|
| methylphenidateIR | 20 | 60 | 25 | 240 |
| methylphenidateLA | 30 | 90 | 30 | 450 |
| methylphenidateOROS | 60 | 120 | 45 | 600 |
| dexamfetamineIR | 30 | 60 | 30 | 300 |
| lisdexamfetamine | 45 | 110 | 45 | 480 |

- Kinds map to templates: All day uses lisdexamfetamine, Short-acting uses dexamfetamineIR, Wind-down and Something else have no window model.
- Prior (Gaussian on the grid, in log space): with the person's estimate, centred at onset = starts helping − ramp up ÷ 2 and offset = starts helping + helps for + ramp down ÷ 2, SD 25 and 75 min; without one, the label prior with SD 35 and 110 min. "Starts helping" and "stops helping" are read as the curve's 50% points.
- Check-in likelihood at m minutes after the logged dose: P(yes) = ε0 + (1 − ε0 − ε1) × E(m), with ε0 = ε1 = 0.1 (a "yes" while flat, a "no" while fine). Yes adds log P(yes); No adds log(1 − P(yes)); Partly adds half of each. The grid is renormalised after each answer (log-sum-exp).
- Summary: marginal 10th, 50th and 90th percentiles of onset and offset; each edge's ± is half the 80% range.
- Confidence: manual override set → "Your own setting"; at least 8 check-in days and both ± within 30 min → learned (count of check-ins); at least 3 days → early (days); otherwise starting.
- Manual override: a person's own window wins until released ("Use learned").
- Next check-in time: from the last prompt plus 45 min to 16 h, in 15 min steps, the minute whose expected P(yes) is closest to 0.5 (where an answer teaches the most).
- Proposal: once past "starting", with an estimate and no override, learned helps-for = (offset median − ramp down ÷ 2) − (onset median + ramp up ÷ 2); if it differs from the stated helps-for by 60 min or more, offer to use it.
- Speed: under 1 ms per update. Tests: learns a 6 h window from a stated 7 h to within 30 min in 10 days with 20% of prompts unanswered, and proposes the change.
- Prototype only: `AppModel.seededModel` fakes 9 days of answers from a fixed 45 min and 7 h estimate so screens have data.

## Check-ins (To build)

- One question, one tap: "Working now?" Yes, Partly, No, from a notification action or a Today card. Never asks the person to recall when something started.
- Learning phase: the first 5 to 7 days with a logged dose of a learning medication; 3 to 5 prompts a day at the next check-in time, inside the daily notification budget, never during a Focus mode or calendar event, and never before the day's dose is logged.
- Taper: once both edges are within ±30 min, about one prompt every 2 to 3 days.
- An unanswered prompt is missing, never "no"; an unlogged day is never "no dose".
- The model is built per medication from its sliders: starts helping = working well − ramp up ÷ 2; helps for = stops helping − ramp down ÷ 2 − starts helping.
- Relearn: changing a medication's kind, name or strength starts a new model from its sliders (old answers archived) and reopens the learning phase. "Start over" on Patterns also resets the learned state.
- Proposal card: "You said about 7 hours; your check-ins suggest about 5½. Use 5½ for planning?" with Accept, Keep mine and Ask later. Keep mine rests it for 30 days.
- Storage: answers and the grid live beside `medication.json`, with complete file protection and excluded from backup.

## The scheduler (Built, `FocusPlanning/Scheduler.swift`)

- Request: the day (7:00 to 22:00 local), tasks, calendar events, the window (none on a routine day), the previous plan, frozen-until, earliest start, full or lighter day, fill cap (0.6), transition (10 min), meal rule (the Eating start: 270 min by default), after-window buffer (20 min), at most 3 moves per replan, low-focus stretches.
- Steps:
  - A 5 min slot grid over the day.
  - Calendar events are fixed blocks, busy for the transition time before and after (10 min by default, 0 to 30 in Patterns).
  - A lighter day keeps only must tasks.
  - Pinned tasks keep their time; tasks whose previous block started before frozen-until keep it.
  - Everything before the earliest start is busy (work is never placed in the past).
  - With a window, the budget = (window minutes − minutes of events, kept blocks and low-focus stretches inside it) × fill cap. Tasks that aren't body tasks spend it; one that no longer fits is unplaced (split if 60 min or longer, else defer).
  - Order: deep work longest first, then medium, light and body in the person's order.
  - Each task goes to the free start with the lowest cost; no feasible start means unplaced (flag deadline risk when it has a deadline, else defer).
  - Local search: up to two passes that lift each task and re-place it if cheaper.
  - Stability: a task at its previous start gets a bonus of 0.6; if more than 3 existing blocks would move, the bonus triples and it solves again (up to 20).
  - Output: blocks with reason codes, changes (place, move, unplaced) and fill = used budget over free focus minutes.
- Cost terms (lower is better; earliness = slot index over slot count; the effect is sampled every 5 min):

| Task | With a window | Routine day |
|---|---|---|
| Deep | (1 − mean effect) × 10 + (1 − share in best focus) × 2 + earliness × 0.2 | earliness |
| Medium, light | share in best focus × 1.5 + (1 − share in window) × 3 + earliness × 0.2 | earliness × 0.5 |
| Meal (title has lunch, breakfast, dinner, meal, snack, eat) | not before dose + meal rule; then hours after that | earliness × 0.5 |
| Other body | share in window × 3 + 1 if between the dose and window end + buffer + 0.8 if before the dose + earliness × 0.1 | earliness × 0.5 |

- Added to every task: + 12 × share inside a low-focus stretch (not body tasks); + 4 × share outside its preferred window; not allowed to end after a deadline; − the stability bonus at its previous start.
- Reasons shown (`Explainer`): best focus "80 min in your best focus"; lighter "50 min in lighter focus"; meal rule "Your meal rule, 4 h after logging" (To build: show halves, "4½ h"); after window "60 min, after your focus window"; outside window; pinned "Pinned, so it won’t move"; frozen "staying put for now"; kept "kept in place"; routine day; calendar.
- Guarantees, all tested: the same inputs give the same plan; no overlaps; 10 min around calendar events; fill never above the cap; pinned never moves; the next 2 h stay put on automatic replans; nothing in the past; a lighter day keeps only musts; a routine day still gets a plan; work that doesn't fit is unplaced, never crammed; lunch after the meal rule; gym after the window and buffer; focus work avoids low-focus stretches; a preference pulls but never drops a task; a day solves in under 150 ms.

## What the app feeds the scheduler (Built, `AppModel.solve`)

- Estimates × the person's buffer for that task (Patterns card 07), unless pinned.
- Preferred windows from Personalise, counted from the anchor (first dose logged today, else first planned non-wind-down dose): meals use Eating; other tasks use their category's window. No anchor, no preferred windows (To build: anchor to 7:00).
- Tasks already done are pinned where they were done.
- Tuning: fill cap, transition, meal rule, after-window buffer and the person's window override.

## Replanning triggers (Built)

| Trigger | Frozen until | Earliest start |
|---|---|---|
| Launch | Nothing | None (To build: now, so a late launch never plans the past) |
| Dose logged | Now + 2 h | Now |
| Lighter day on or off (including brain weather Low) | Now + 2 h | Now |
| Personalise, Patterns, medication, kind of day, today's pick, calendar loaded | Now | Now |
| Fix my day preview | Now + 20 min | Now |
| Done for now | Now + 20 min | Now |

- Every replan first recomputes the window, stretches and sleep time. To build: replan on calendar changes (`EKEventStoreChanged`), on the first foreground of a day, and at midnight.

## Fix my day and Done for now (Built)

- Fix my day preview: the running task's estimate grows by the minutes over, then a solve against the current plan with the next 20 min frozen. The sheet lists the moves; Apply keeps the old plan for undo.
- Done for now: the estimate becomes the larger of 15 and the estimate minus the minutes spent; its block is lifted and the rest re-planned with 20 min frozen.
- Done: the task is pinned where it was done in every later solve.

## Product rules from the research (never dosing advice)

- The person's own experience is the starting point; learning only refines it when they switch it on, and a manual edit wins until released.
- Real durations are often much shorter than product labels, so learning must be able to shorten a window well below the sliders (the grid reaches down to 2 h).
- Formulation templates are shape priors only; they never produce a number the person sees.
- A short-acting dose taken after an all-day dose keeps its own curve; parameters are never shared between them.
- Food at logging is stored with the dose and shifts nothing today (To build, later: a per-medication shift learned from check-ins, never a rule shown as advice).
- Kinds without a window model (wind-down, something else) never get a learned window; a wind-down is never called sleep medication.
- A kind of day with no doses is a routine day, never "missed"; unlogged is never "not taken".
- Evening doses are allowed; morning dosing is never assumed.
- Heart rate and sleep never set or end a window and never trigger an alert about medication.
- The app never says when or how much to take, never suggests catching up, skipping or adding a dose, and never gives food, drink or interaction advice.

## Known gaps (from the learning and lifestyles check)

| ID | Gap | Status |
|---|---|---|
| LL-01, 05, 06, 21 | No check-ins are collected; the model is seeded | To build: check-ins above |
| LL-02 | One shared model for every learning medication | To build: one per medication |
| LL-04 | The proposal exists but isn't shown | To build: proposal card |
| LL-13 | "Start over" resets tuning, not what was learned | To build: reset learned state too |
| LL-18 | A new kind of day can't start as a copy | To build: "Start from a copy" |
| LL-24 | Learned state and check-ins aren't saved | To build: protected file, excluded from backup |
| LL-20 | Safety gate used only for your own AI | To build: every generated or notification string |
| LL-09, 11, 14, 19, 22, 26 | Durations from real start and stop times, trials of one, routine-change detection, holiday drift from Health sleep, lapse reasons, on-phone evaluation | Later |

- Fixed on 30 Sep: the confidence line now claims check-ins only when learning is on; `medication.json` has complete protection and is excluded from backup.
- Durations (Later): a Normal-Inverse-Gamma model on log(actual ÷ estimate) per category with a prior multiplier of about 1.5 worth 4 tasks, booking the median (80th percentile for deadline work), learned only from real start and stop times, shown as "Essay drafting usually takes 1.6× your estimate (13 sessions)". Today `learnedRatio` reads demo history.
