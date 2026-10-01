# Claude Code prompt: design the ADHD planner in Figma

**Before running:** run Claude Code from an empty project folder with auto mode on and paste everything below the line. Your Figma Education team already gives you edit access to all files. Figma's connection may still label your seat "View", which is expected on Education teams.

---

## Role and outcome

You are the design lead and orchestrator for an Apple-native ADHD planner (working name **"Planner"**; use it as a placeholder everywhere and log the name as an open decision). Produce a production-quality design in Figma: a FigJam board for flows, a design-system library, full-fidelity iPhone, Apple Watch and glanceable-surface screens, a clickable core-loop prototype, and developer handoff notes for a native SwiftUI build. Use the installed plugins, skills and agents mapped below. Work autonomously; don't ask me for permission between steps.

Stop and ask me only if: (a) Figma isn't authenticated, (b) the step 0 access smoke test fails, or (c) this brief contradicts itself. For everything else, take the documented default, record it in `docs/design/decisions.md`, and continue.

## Step 0: environment checks (in order)

1. **Inventory.** List the skills, plugins and agent types available in this session. Match the names in the skill map below against them (match on the part after the colon if a prefix differs). Log anything missing in `decisions.md` and substitute the closest installed equivalent. Ignore unrelated plugins (backend, finance, security, data, Adobe, ToolJet, Base44, Voicenter, TwelveLabs and similar).
2. **Figma access.** Call `whoami`.
   - Work only in the team **"ramanan.devesh's team"** (`team::1686304428269511457`, Education tier). Create every file there, never in Drafts: rate limits attach to the team that owns the file.
   - `whoami` may report my seat as "View" with tier "student". That's expected on Education teams: I'm the admin and have edit access to all folders and files, so don't stop on it.
   - Rate limits apply to **read** tools (`get_screenshot`, `get_metadata`, `get_design_context`, `search_design_system`, `get_variable_defs` and so on); `use_figma`, `create_new_file` and `whoami` are exempt. Figma documents Education plans at 200 reads a day and 10 a minute.
   - **Access smoke test:** create the FigJam file, make one small `use_figma` write, then make one `get_metadata` read on it. If the write fails with a permission error, or the read returns a rate-limit or "upgrade" error, stop and report the exact message. Otherwise continue.
   - Keep a running count of reads in `docs/design/figma-usage.md`. Budget: at most 120 reads a day. Verify visually with one `get_screenshot` per finished frame group, not per frame. If you hit a limit, save state and stop cleanly.
3. **Sources.** If the Claude Docs connector is available, read the main design doc `https://claude.ai/code/artifact/3b1b63f2-fca1-45ca-b096-209254c7e970` (sections 2, 4.2, 5, 7.4 to 7.6, 8.2 to 8.3, 10.9, 11.1, 17.1 and 18). Also read `docs/research/*.md` if present. Otherwise this brief is authoritative, and where the two conflict, this brief wins.
4. **Requirement lock.** Run `spec-drift:init` on this brief to create `SPEC_CHECKLIST.md` before any design work.

## Product brief

**What it is.** An Apple-native planner that learns each user's own **focus window** (the hours after a logged dose when they report they can do demanding work) from one-tap check-ins. It fills that window with the work they choose and keeps body, social and admin tasks outside it. It survives bad days without shame, and it lets the user flip their whole learned routine between Lifestyles (e.g. "Term" and "Holidays") in one tap.

**Core loop.** Log a dose (Watch, widget, Control Center, Siri, Action button) → see your usual focus window and its confidence → the planner places chosen deep work inside it → outcomes feed learning → the window and task durations sharpen over time.

**Users and platforms.** Adults 18+ with ADHD, on or off medication; university students first. iPhone first, then Apple Watch; Mac menu bar and iPad later. iOS 26 minimum (Liquid Glass design language), iOS 27 current. Australia first, so all copy is in Australian English.

**The glanceables are the product.** Widgets, Watch face, Lock Screen and Live Activities carry the day, and the app itself is opened mainly to plan. Design the glanceables with the same care as the app screens.

### Red lines (non-negotiable; breaching them turns the app into a regulated medical device)

- Never suggest when or how much to take, boosters included. The app logs doses, learns a self-reported focus pattern and moves **tasks**, never doses.
- Users never see "onset", "peak", "wear-off", "predicts", "optimal" or other pharmacology language. They see "focus window" and "your focus pattern, from what you've logged".
- Discreet mode: no drug names on the Lock Screen or in notifications, widgets, Live Activities or calendar titles.
- No red overdue counts, no daily streaks, no "missed" language. Planned medication breaks read as "planned", never "missed".

### Wording rules (apply to every text layer)

| Say | Don't say |
|---|---|
| "Log your doses and see your own history" | "Tracks how well your medication is working" |
| "Reminders at the times you choose" | "Smart dose reminders" / "We'll tell you when your next dose is due" |
| "Plan your day around when you usually feel most focused" | "Optimises your medication" / "Find your optimal dose timing" |
| "Your focus pattern, from what you've logged" | "Predicts when your dose wears off" |
| "Schedules your hardest tasks into your best focus hours" | "Know exactly when to take your booster" |
| "A planner designed with ADHD brains in mind" | "Reduces ADHD symptoms" / "Clinically proven" |
| "Did I already log it? Check at a glance" | "Prevents double-dosing" / "Tells you if it's safe" |
| "Export your log to show your doctor if you choose" | "Helps your psychiatrist adjust your dose" |
| "AI turns screenshots and messages into tasks" | "Ask our AI about your meds" |
| "Health details are processed on your device where possible" | "Your data never leaves your phone" |

### Design principles

1. **Point of performance:** cues arrive where the task happens (Watch haptic, Lock Screen, Dynamic Island).
2. **Micro-sessions:** every interaction takes under 3 minutes, with one primary action per screen.
3. **Nothing punishes a miss:** amnesty, a baseline day, forgiving progress ("5 of the last 7 days") and 30-second re-entry.
4. **Sparse interruptions:** real-time alerts only for leave-now, transitions and medication moments; everything else is batched.
5. **Minimum viable tracking:** check-ins ask one question; passive data comes first.
6. **Cognitive accessibility (W3C COGA):** plain words, nothing that relies on memory, no timeouts.
7. **Calm by default:** predictable layout, muted colour, no confetti. "Spark" is an opt-in theme with rotating accents and light celebrations.
8. **Show the evidence:** every learned number shows what it's based on, and standing changes need the user's approval.

### Focus-window display states (design every one)

| Evidence | What the user sees |
|---|---|
| Under 3 check-in days | "Starting estimate from what you told us: focus about 0:45 to 7:00 after logging" |
| 3 to 7 days | "Early estimate (5 days): 0:50 to 6:20, ±50 min" |
| 8+ days, tight interval | "Your usual focus: 0:55 to 6:30 after logging (23 check-ins, ±25 min)" |
| Stated and learned disagree | "You said about 7 hours; your check-ins suggest about 5.5. Use 5.5 for planning?" → Accept / Keep mine / Ask later |

Check-in prompt: one question, "Working now?" → Yes / Partly / No, on the Watch or Lock Screen. It appears 3 to 5 times a day while the app is learning, then tapers off.

### Lifestyle switch (v1)

It lives in Control Center, on a widget and at the top of Today, and can be renamed ("Term" / "Holidays"). Tapping it shows a one-screen preview before anything changes, e.g. "Wake anchor 9:30 instead of 7:15 · study blocks move to afternoons · 6 term-only routines paused". Routines are paused, never deleted; external calendar events are left alone; undo is one tap.

## Scope

**MVP (full fidelity)**
- **Onboarding:** welcome; 18+ age gate; setup preset (Minimal / Gentle nudges / High structure); medication setup using the user's own duration estimate and an optional latest-dose cut-off set by them or their prescriber; Health permission (sleep and workouts only); opt-in app-owned wake alarm; Discreet mode choice; notification budget (default 5 a day).
- **Today:** Now/Next with a shrinking time ring; timeline with the focus-window band and its confidence label; ideal vs baseline day toggle; brain-weather check-in (low / okay / good, where low collapses the day to baseline); dose-log button.
- **Dose log:** one-tap log; double-dose guard sheet ("Already logged 08:02, 3 h ago", with a deliberate confirm); undo; a neutral note for logs after the user's own cut-off ("Later than the cut-off you set. Your prescriber's instructions apply.").
- **Focus window detail:** evidence, where each number came from, and the disagreement card.
- **Tasks:** add with duration and deadline; first-step breakdown (a first action under 10 minutes); start-tiny timer; distraction parking lot.
- **Recovery:** "Fix my day" (fixed phrases); overdue amnesty; welcome-back flow (after 3+ days away: archive stale items, pick 3, back in under 30 seconds); neutral re-plan after a miss; waiting-mode card ("You're free until 1:40. Leave-by alarm is set." plus 2 to 3 side quests).
- **Support:** persistently low check-ins surface Lifeline (13 11 14) and a "talk to your GP" prompt. Signposting only.
- **Settings:** notification budget, Calm/Spark, Discreet mode, Face ID lock, privacy and consent, log export (PDF preview).
- **Watch:** dose-glance complication, log dose, check-in, Now/Next ring, transition haptics at 10, 5 and 1 minutes (annotated), parking-lot capture.
- **Glanceables:** Home Screen widgets (small, medium, large); Lock Screen widgets; a Control Center control to log a dose; a Live Activity on the Lock Screen and in the Dynamic Island (compact, minimal, expanded) reading "Logged 08:02 · 3 h ago · usual focus to ~5:40 pm".

**v1 (full fidelity).** Lifestyle switch and preview sheet; end-of-focus "landing" alert; supply, repeats and script tracker; shortage mode; leave-by with learned lateness; hyperfocus guardrail; morning launch on the Watch; if-then plans; Spark theme; paywall (free core plus paid learning, 21 to 30-day trial, student price; flag it as a pending decision).

**Future (low fidelity, "Future" page).** Mac menu bar, iPad, Simple mode (Assistive Access: Now, Next, Log), Focus shields, cycle overlay.

**Every full-fidelity screen** needs light and dark, the Calm theme (Spark on key screens only), default and largest accessibility Dynamic Type on key screens, and empty, first-day, loading and error states where they apply. Anything that shows medication also needs a Discreet mode variant.

## Figma structure

- **FigJam "Planner · Flows":** information architecture, the core loop, and journeys for first run, the daily loop, dose log with the double-dose guard, check-in learning, lapse and welcome-back, and the Lifestyle switch.
- **Design file "Planner · Design":** pages `Cover` · `Foundations` · `Components` · `Onboarding` · `Today & Tasks` · `Medication & Focus window` · `Recovery & Support` · `Glanceables` · `Watch` · `Settings & Privacy` · `Lifestyles (v1)` · `v1 features` · `Future` · `Prototype` · `Handoff`.
- **Frames:** current iPhone Pro size, with layout checks at 375 pt and Pro Max widths for Today and onboarding. Use current Apple device frames, SF Pro, SF Symbols and iOS 26 Liquid Glass materials.

## Workflow: skills and agents by phase

Start with a task list built with `agent-protocols:planning-and-task-breakdown` (or `superpowers:writing-plans`). Run `spec-drift:check` at the end of each phase.

**Phase 1: Discovery and spec (no Figma writes)**
- `ux-superpowers:ux-discover`, `ux-superpowers:persona-builder` and `ux-superpowers:jobs-to-be-done`: build personas, jobs to be done and success metrics from this brief and the design doc, not from new interviews.
- `superpowers:brainstorming`, then `agentic-council:brainstorm` (Architect / Advocate / Skeptic gut check) on the information architecture. Answer their questions from this brief instead of asking me.
- `ux-superpowers:user-journey` and `agentic-council:advocate-journey-mapping`; `agentic-council:pathfinder-navigation-design`; `agentic-council:advocate-interaction-design` (a state matrix for every component); `agentic-council:pathfinder-device-integration` (Health, AlarmKit and notification permission flows); `agentic-council:skeptic-edge-case-enumeration` (missing states).
- Output `docs/design/DESIGN_SPEC.md`: information architecture, screen inventory with states, component inventory and copy deck.

**Phase 2: Flows (FigJam)**
- `figma:figma-use-figjam`, plus `figma:figma-generate-diagram` before every `generate_diagram` call.

**Phase 3: Design system (the orchestrator is the only writer)**
- `agentic-council:artisan-design-system-architecture`: primitive, semantic and component tokens, with light/dark × Calm/Spark modes.
- `liquid-glass:liquid-glass` for iOS 26 materials and idioms; `design:design-system` for naming and documentation.
- `figma:figma-create-new-file` before `create_new_file`; `figma:figma-use` before **every** `use_figma` call; `figma:figma-generate-library` for variables, styles and components with variants.
- **Required components:** Now/Next card, time ring, focus-window band (all 4 confidence states), check-in control (Yes/Partly/No), dose-log button and guard sheet, baseline/ideal toggle, brain-weather picker, task row, first-step card, amnesty sheet, Lifestyle chip and preview sheet, widget templates, Live Activity layouts, Watch complication templates, empty states.
- Freeze the library before Phase 4. After the freeze, only the orchestrator adds tokens or components.

**Phase 4: Screens (parallel)**
- Use `superpowers:dispatching-parallel-agents` and `superpowers:subagent-driven-development` with `general-purpose` subagents, one per page.
- Each subagent writes **only its own page**, loads `figma:figma-use` and `figma:figma-generate-design` first, and uses library instances only: no detached instances, no raw hex values, no new styles.
- Run at most 3 Figma writers at once. If a write conflicts or errors, fall back to working sequentially.
- Copy: `design:ux-copy` for all microcopy (checked against the wording rules); `agentic-council:herald-messaging-strategy` for onboarding; `agentic-council:herald-monetization-design` for the v1 paywall only; `agentic-council:advocate-i18n-review` for Australian English and local date, time and phone formats.

**Phase 5: Motion and prototype**
- `agentic-council:artisan-motion-design` for transition specs, including Reduce Motion alternatives.
- `figma:figma-use-motion` for ring depletion and the check-in and Lifestyle transitions. Annotate every haptic moment.
- Wire a clickable prototype of the core loop: log dose → Today → check-in → task starts → end-of-focus landing.
- `figma:figma-shaders` only for optional Spark backgrounds. Skip the generative-plugin and Weave tools unless a concrete need comes up.

**Phase 6: Independent review (fresh-context agents that didn't build the screens; run them in parallel)**
- `agentic-council:Artisan` with `design:design-critique` and `agentic-council:artisan-visual-audit`: hierarchy, consistency, one primary action per screen.
- `agent-protocols:accessibility-specialist` with `design:accessibility-review` and `agentic-council:advocate-a11y-audit`: WCAG 2.2 AA and COGA; contrast of 4.5:1 for text and 3:1 for UI; 44 × 44 pt targets; Dynamic Type; VoiceOver labels noted.
- `agentic-council:Pathfinder` with `agentic-council:pathfinder-platform-audit`: Apple HIG for iOS 26 and watchOS 26, widgets, Live Activities and Controls.
- `agentic-council:Guardian` with `product-legal:marketing-claims-review` and `agentic-council:guardian-compliance-review`: extract every text layer with `use_figma` and check it against the "Don't say" list, pharmacology terms and drug names on glanceables. Zero hits required.
- `agentic-council:Advocate` with `ux-superpowers:ux-validate`: shame-free tone, and re-entry in under 30 seconds.
- Fix the findings and re-review until nothing blocking remains.

**Phase 7: Handoff**
- `design:design-handoff`: write `docs/design/handoff.md` for SwiftUI, covering tokens, component props, states, spacing, motion and edge cases.
- `figma:figma-swiftui`: map tokens and components to SwiftUI equivalents inside the handoff doc. Don't run `figma:figma-code-connect`, `figma:figma-design-to-code` or `figma:figma-implement-motion` yet; no Swift code exists.
- `ux-superpowers:telemetry-designer`: write `docs/design/metrics.md` covering planned vs done, on-time rate and weekly self-rated functioning. Measure function, not engagement.
- `design:user-research`: write `docs/design/usability-test-plan.md` for 5 to 8 participants with ADHD, testing the core loop, the recovery flows and the Lifestyle switch.
- Finish with `spec-drift:report`, `superpowers:verification-before-completion`, then `agentic-council:handover` to save the session's state for the next run.

## Defaults for open decisions (log them in `decisions.md`; don't ask)

- **Age and naming:** minimum age 18+; the window is called "focus window".
- **Templates:** my own routine is one template among several presets, not the default.
- **Pricing (design only; flag it):** free core plus paid learning, with a 21 to 30-day trial and a student price.
- **Sync:** MVP is local-only; show no sync UI beyond "on this device".
- **AI and data:** no third-party AI at launch; importing doses from Health is optional; Health data at launch is sleep and workouts only.
- **First audience:** university students.

## Definition of done

- Every MVP and v1 screen exists at full fidelity in all required modes and states, and the Future page has low-fidelity frames.
- Every screen is built from library instances, with all colour, type and spacing bound to variables.
- The copy scan finds zero banned terms, no drug names on glanceables in Discreet mode, and no red counts or streak language anywhere.
- The accessibility, HIG and compliance reviewers report nothing blocking.
- The core-loop prototype clicks through end to end.
- `SPEC_CHECKLIST.md` is fully ticked.
- `docs/design/` contains `DESIGN_SPEC.md`, `decisions.md`, `figma-usage.md`, `handoff.md`, `metrics.md` and `usability-test-plan.md`.

## Final report (keep it short)

- Links to both Figma files.
- Screen and component counts.
- Defaults taken and unresolved issues.
- Reads used against the budget.
- The three decisions you most need from me next.
