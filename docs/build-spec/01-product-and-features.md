# Focus: product and features

Every screen and behaviour of the iPhone app. **Built** means it exists in the prototype (`app/FocusApp`); **To build** means it doesn't yet, or the code still differs from the decision. Algorithms and prompts: `04-intelligence.md`. Apple integrations, haptic patterns and Info.plist: `05-platform.md`.

## Product principles

- It plans each day around the person's own medication rhythm and preferences, and never suggests, calculates or prompts what to take, how much or when. Dose times are fixed inputs: when a day is too full, tasks change, never medication.
- One idea per page. Pages snap like reels; a tab's first page is its most useful one.
- Quiet and elegant: dark first, New York serif headings, small type, lots of space, left aligned, frosted photo backdrops, Liquid Glass only on chrome and controls.
- Everything smart runs on the iPhone with Apple Intelligence; iPhones that can't run it can't use the app. Every smart feature has a deterministic fallback.
- Nothing punishes a miss: no red counts, no streaks, no "overdue". Lighter days count.
- The person decides: the app proposes, previews and explains; nothing changes the plan without a tap; change sets have one-tap undo.
- Voice: a warm, slightly funny friend with ADHD. Serious, legal, safety, money and button text never jokes and never rotates.
- Touch everywhere: every meaningful moment has a designed vibration paired with a visual, with an off switch and a strength slider.
- Logging is one thumb away: the bottom bar on every tab, the Action button, Back Tap and Siri.
- Offline first: everything works offline except sign-in, purchases and the person's own AI.
- Free: everything, with up to 3 kinds of day and 5 activity categories. Plus: unlimited. When Plus ends nothing is deleted or switched off; only adding more is limited.

## Navigation map

### Root flow

- Every launch: the device check, which blocks until Apple Intelligence is available.
- First launch: start animation, greeting, the honest bit, account, trial offer, then Today with coach marks.
- Later: the daily arrival page on the first open of each day, then the tabs (Built: every cold launch; To build: store the last arrival date).

### Tabs (Built)

| Tab | Symbol | Can hide | Pages by default, in order (extras, off by default, in brackets) |
|---|---|---|---|
| Today | sun.horizon | No | Today, in five; Now (locked); Your focus window; Rest of today; Today in shapes; If today changes; [Tiny wins]; [One minute of breathing] |
| Plan | calendar | Yes | The day; The shape of the day; Waiting for you; This week |
| Rhythm | waveform.path | Yes | Four weeks of you; Planned and done; Brain weather; When things get done; Your focus window, learned; How long things take; Sleep and done; When you log; Your patterns, your call |
| You | person.crop.circle | No | You (locked); Support; The fiddly bits (locked) |

- Glass tab bar in the person's order and names; a selection tick on change; a tab opens on its first page.

### Pages (Built)

- One screen tall. A flick (velocity over 0.3) moves exactly one page; a slow drag settles on the nearest; a page taller than the screen scrolls inside and snaps only at its edges. A soft tap plays on each page change.
- Fixed header: weekday eyebrow and "30 September" in serif, with the tab's glass buttons on the right (Today: brain weather; Rhythm: edit patterns).
- Page markers on the trailing edge: dots, numbers or hidden; tap to jump; VoiceOver "Page 2 of 7", adjustable.
- Content reveals as it scrolls in (fade, 0.98 scale, 18 pt rise, 3 pt blur, 0.6 s). Locked pages can move but can't be removed.

### Bottom bar: the medication glance (Built)

- Above the tab bar on every tab: a status icon (all logged, none, some; bounces on each log), one line, and a plain "Log" capsule that opens the logging sheet (no glass on glass).
- Lines: "Nothing logged yet", "Logged today", "All 4 logged", "2 of 4 logged. Next 6:00", "2 of 4 logged". Collapsed with the tab bar: the first logged time or "Log".
- Customise can switch it to What's next: "Case reading at 11:05".

### Routes and test switches (Built)

- `AppModel.Route` (medication, personalise, customise, settings, actionButton, ai) switches to You and pushes that page; used by coach marks, "Add medication" buttons and the Open my medication intent.
- Launch arguments: `-skipGate`, `-demoClock 09:41`, `-freshDay`, `-skipArrival`, `-name Sam`, `-plus`, `-tab rhythm`.

## First launch

### Device check (Built)

- Purpose: Focus needs Apple Intelligence; say so kindly, first.
- Layout: night sky, eyebrow "Apple Intelligence", serif title, one paragraph, buttons.
  - Not eligible: "This iPhone can’t run Focus": it needs "an iPhone 15 Pro or newer. Sorry, we know that’s annoying." No buttons.
  - Switched off: "Switch on Apple Intelligence", with "Open Settings" and "Check again".
  - Downloading: "Apple Intelligence is still getting ready", with "Start anyway"; smart parts use fallbacks until ready.
- Rules: checked on every launch and every return to the foreground; clears itself when the model is available. Fixed text; 0.6 s cross-fade.
- Accept: an iPhone 15 shows the not-eligible screen and nothing else; switching Apple Intelligence on and returning clears it with no tap; "Start anyway" works only while downloading.

### Start animation (Built)

- A 96 pt ring, "Focus" (44 pt serif) and the tagline on the night sky. The ring draws over 1.4 s (warm, best, honey gradient); a point of light settles in at 1.35 s with a glow; a bloom at 1.6 s; the name writes in over 1.0 s; the tagline rises at 2.3 s; it moves on at 3.6 s. A tap skips.
- Calm motion: shown still, moves on after 1.2 s, no vibration. Feel: `splash`. Copy: `splashTagline`.

### Greeting (Built)

- A 40 pt serif hello written in over 1.0 s, one or two sentences fading in at 0.8 s, "Let’s go" at the bottom; dawn sky. Steps change with a 0.7 s fade and 24 pt rise (fade only when calm).
- Feel: `land`, then `tap`. Copy: `greetingTitle`, `greetingBody`.

### The honest bit (Built)

- Purpose: say plainly what Focus is and isn't, once before sign-up and always from Settings, Safety and legal.
- Layout: eyebrow "Before we start", title "The honest bit", five icon rows 0.12 s apart, "I understand":
  - "Focus is a planner. It is not a medical device."
  - "It doesn’t diagnose, treat, monitor or prevent ADHD or any other condition."
  - "It never tells you what medication to take, how much, or when. Your prescriber decides that. The app only plans your day around what you tell it."
  - "If you’re unsure about your medication or how you’re feeling, talk to your doctor or pharmacist."
  - "If you’re in danger or crisis, call 000. You can also call Lifeline on 13 11 14, any time."
- Rules: accepting stores `noticeAcceptedVersion` = 1; in Settings the button becomes "You agreed to this when you started." To build: show it again when the version rises.
- Feel: `nudge`, then `acknowledge`. Fixed legal text. Accept: can't be skipped on first launch; the Settings copy is identical.

### Account (Built with a local backend)

- Purpose: plans follow the person to a new phone (end-to-end encrypted) and the subscription is tied to them. Required.
- Layout: eyebrow "Your account"; title; one serious sentence; "I’m 18 or older" (off); Sign in with Apple ("Continue"; white on dark, black on light; 48 pt capsule); "Continue with Google"; "Continue with email" (field, "Send link", then "Check your inbox. The link signs you straight in."); "By continuing you agree to the Terms and the Privacy Policy. You can delete your account any time in Settings."
- Rules: sign-in is disabled (45% opacity) until 18+ is on, with "Focus is for adults for now." Apple asks for name and email. Google runs in Apple's secure web sheet with PKCE and needs `GIDClientID` ("Google sign-in isn’t switched on in this build yet." without it). Email is a one-tap magic link. The account record is in the Keychain (this device only); server exchange sits behind `AuthBackend`. To build: the real backend and the universal link that finishes email sign-in.
- States: working (disabled); cancelled (silent); error (one inline line, e.g. "That email doesn’t look quite right."); offline (same line, nothing lost).
- Feel: `toggle`, `success`, `caution` on error. Copy: `accountTitle`, `accountBody`.
- Accept: no sign-in starts with 18+ off; a cancelled Apple sheet shows no error; success goes straight to the trial offer.
- Known risk: account-first carries an App Review 5.1.1(v) risk; mitigation: it powers encrypted backup and moving phones, it's fast, and deletion is in the app.

### Trial offer (Built)

- Purpose: offer Plus first, with an honest reason and an easy way out.
- Layout: eyebrow "Focus Plus"; title; the why; badge "Free for 1 month" (period from StoreKit) with a slow shimmer; benefits (kinds of day, categories, "Everything else stays free, forever"); cards Yearly (selected) and Monthly with Apple's price; "Start my free month" ("Get Plus" when not eligible); terms; "Restore purchases", "Terms", "Privacy"; "Not now, use the free plan".
- Terms: "Free for 1 month, then {price} a year. Renews automatically until you cancel. Cancel any time in Settings, at least 24 hours before the trial ends, and you won’t be charged. We’ll remind you two days before it ends. Payment is handled by Apple."
- Rules: prices, periods and trial length always come from StoreKit. A started trial schedules the reminder. The same view is the upsell, with the reason above and "Not now".
- States: loading ("…"); no products (primary disabled; debug builds walk through); pending ("Waiting on Apple to approve that. You can keep going."); failed (message and `caution`); cancelled (nothing).
- Feel: `choose` on cards, `success` on purchase. Copy: `trialTitle` (never states a length), `trialWhy`.
- Accept: never shows a trial length other than StoreKit's; "Not now" always works.

### Coach marks (Built)

- Purpose: point at three things, then get out of the way. Not a guided setup.
- Rules: 0.9 s after Today first appears a toast; 1.6 s later the tour, unless done. Steps: priorities, medication, page markers, set up, done. Each dims to 50% black around a rounded 18 pt hole with a 1.5 pt accent ring; the glass bubble (max 300 pt) sits below the target when 190 pt fit, else above.
- Buttons: "Next", "Skip, I’ll explore"; set up has "Take me there" (You, Medication) and "Later"; the last "Got it". Tapping the dim advances. `welcomed` and `coachDone` stop it ever repeating.
- Feel: `nudge` per bubble. Copy: `welcomeHome`, `coachPriorities`, `coachMeds`, `coachDots`, `coachSetup`, `coachDone`.

## Daily arrival page (Built)

- Purpose: one gentle question before the day.
- Layout, low on the screen: weekday; the date (38 pt, written in); "Good morning, *Sam*." ("Good morning." with no name); "How’s your brain today?"; glass answers Low, Okay, Good; "Not now".
- Rules: the sky settles from night to the current phase over 1.8 s; lines arrive at 0.35, 1.1 and 1.6 s. An answer morphs the others away and opens Today 0.55 s later. Low switches today to the lighter day; "Not now" records nothing. Greeting by hour: before 12, before 17, else evening.
- Feel: `arrival`, `choose`. Copy: `arrivalMorning`, `arrivalAfternoon`, `arrivalEvening`, `arrivalQuestion` (To build: wire the slot; fixed today).
- Accept: Low gives the lighter plan before Today appears; calm motion shows everything at once.

## Today

- Paged; refreshes every 30 s. The header's glass button sets brain weather at any time ("Low, so a lighter day", "Okay", "Good"). Low switches on the lighter day; moving off Low leaves that switch to the person.

### Today, in five (Built)

- Layout: eyebrow; numbered serif lines (5, or 3 in Customise), such as "Draft the essay until 10:55."; caption "Written on this iPhone by Apple Intelligence" or "Ranked from your plan"; then today's medication.
- Rules: ranked lines show at once and the on-device wording replaces them when ready (0.6 s cross-fade); times are added by code, never by the model. Regenerates when the lighter-day switch, brain weather, done count, open blocks or hour changes.
- States: model unavailable or failed → ranked lines; empty plan → gentle fillers ("Drink a glass of water."). Copy: `fiveThingsEyebrow`.
- Accept: never more lines than the Customise count; no line mentions medication; every time equals the plan's.

### Today's medication (Built)

- Purpose: "did I log it?", and one tap to log what's set for now, in one slim row (about a fifth of the height of the earlier block; owner's instruction).
- Layout: one row, 40 pt tall, no eyebrow: two medication buttons (glass capsules: a colour dot, or a tick once logged, and the medicine's first name; times appear only when the same medicine fills both) and a round more button ("+N" when more doses exist today, otherwise "…").
- Rules:
  - Which two: from two different medicines where possible, the next doses still to log, then the latest logged; sorted by time. Everything else sits behind more.
  - A dose set for about now (unlogged and planned no more than 60 min ahead; To build: and no more than 3 h ago) shows in the accent colour.
  - Tap an unlogged button: logs that dose now, through the double-dose guard. Tap a logged one, or press and hold any: the logging sheet opens on that medication (another time, ate first, log another).
  - More opens every dose for today (sheet): "Log all N" at the top when anything is set for about now (each through the guard; stopped ones are skipped and reported, never logged twice), otherwise a status caption (`medsAllLogged`, `medsNothingDue` with the next time, or "2 of 4 logged"); then one row per dose, tap to log that one.
  - A logged dose matches the nearest planned dose of the same medication within 4 h.
- States: no medication → one wide "Add medication" button (opens You, Medication); a kind of day with no doses → one wide "Log a dose" button; already logged inside the guard window → toast "Already logged at 8:10. Press and hold to log another."; save error → toast "Couldn’t save that. Nothing was changed."
- Feel: one pattern per action (`logged` for one, `logAll` for several). Celebration: a champagne line draws round the row (0.5 s), a glow blooms (0.25 s in, 0.8 s out), eight sparks drift out, all fade after 0.7 s; off in Customise or when calm.
- Copy: `medsLoggedToast`, `medsAllLogged`, `medsNothingDue`, `medsNone` (in the sheet), `coachMeds` (the coach mark on this row).
- Accept:
  - Doses at 7:00, 8:10, 18:00 and 21:30 at 9:00 show Dexamfetamine and Vyvanse plus "+2"; the row is one line, 40 pt tall.
  - Tapping Vyvanse logs it; the row then shows Dexamfetamine (accent) and Melatonin plus "+2".
  - Log all in the sheet at 9:00 logs 7:00 and 8:10; a dose logged an hour earlier is skipped and the toast says so.

### Now (Built)

- Layout: eyebrow; the status line (26 pt serif); the Now card or the gap; "Then {task} at {time}."
  - Card: a depleting 72 pt ring with minutes left; kind eyebrow (Deep work, Lighter work, Body, Calendar; "Wrap up" in the last 5 min); title; "9:15 to 10:35"; "First step" (if on); "Done", a "Not now" menu (Done for now, Fix my day) and an expand button for Focus mode.
  - Gap: `nowGap` and "Free until 11:05."
- Rules: status line: no window `dayLineRoutine`; in a low-focus stretch "Low-focus stretch until 1:30."; before or warming `dayLineWarming`; best `dayLineBest`; lighter `dayLineLighter`; after `dayLineAfter`. Done for now cuts the estimate by the minutes spent (never below 15) and re-plans from 20 min ahead.
- Feel: `complete` and `focusDoneCheer` on Done; at 5 min left the ring turns honey with two ripples and a warning tap; zoom into Focus mode.
- Accept: the ring's fraction is time left over block length; Done for now keeps the task in today.

### Your focus window (Built)

- Layout: eyebrow; "9:10 to 5:10"; the confidence line; a sky band (warm-up, best, lighter, feathered by the uncertainty) with a legend; "One low-focus stretch in between. Lighter things go there."
- Confidence: learned "Your usual focus, from 23 check-ins, give or take 25 min"; early "An early guess from 5 days, give or take 50 min"; starting "A first guess from what you told us". When the window comes from the sliders or drawn windows (learning off): "Your own setting"; check-ins are only claimed when learning is on.
- States: no doses today → "A routine day". The band draws out from the dose when half visible and after each log. VoiceOver reads one sentence.

### Rest of today (Built)

- Layout: headline; the first 3 remaining blocks (time range, title, colour dot; VoiceOver hint gives the reason); "Show 4 more" or "Show less"; the unplaced note; one social chip that opens its suggestion card.
- Copy: `restHeadline`, `restOneLeft`, `restUnplaced`, `emptyPlan`, `socialLine`.

### Today in shapes (Built)

- `shapesHeadline` ("2 of 6 done"); a 132 pt ring chart (deep work, lighter work, body, calendar, open) with "58%" and "planned" in the centre; a legend with durations. Open = window minus low-focus stretches minus planned focus work. Sweeps in over 1.0 s.

### If today changes (Built)

- "Fix my day"; "Switch to a lighter day" or "Back to the full day"; `changeFootnote`. The lighter (baseline) day keeps only tasks marked as a must; switching re-plans at once and is reversible.

### Tiny wins and One minute of breathing (Built, extras)

- Tiny wins: `tinyWinsTitle` (or `tinyWinsEmpty` when nothing is done or logged); a tick per finished block, "Logged your medication" or "Logged 3 doses", and "Opened the app and looked at the day".
- Breathing: `breatheIntro`; a 200 pt circle; "Start a minute". In for 4 s (the circle grows from 42% to full), out for 6 s, six rounds, then it stops. `breatheIn` and `breatheOut` each round; calm motion changes the circle instantly; VoiceOver says "Breathe in" and "Breathe out".

## Plan (Built on demo history; To build: real history from the event ledger)

- The day: one of the last 7 days with arrows (never past today); "To-do 4 tasks" today or "Done 62% of plan" before, and "Focus 8h window" or "None"; a strip from 7 am to 10 pm with the window glowing.
- The shape of the day: a vertical river with the window as a band of light, blocks beside it, done ticked, a line at now; past days show a dot per finish.
- Waiting for you (today): tasks with kind ("Deep, a must today") and estimate or "Done". How it went (past): logged time or "Medication-free", sleep, brain weather, planned, done.
- This week: seven beads, filled when the must-dos got done; `planWeekHeadline`, `planWeekExplainer`.
- Feel: `choose` on arrows; beads pop in with `land`. Patterns, never scores.

## Rhythm and the Patterns editor

### Rhythm pages (Built on demo history; To build: real data)

- One pattern per page: a headline worked out from the person's data, a chart that grows in, a one-line explainer.
- Pages: Four weeks of you (`rhythmIntro`); Planned and done ("41 hours of real work in two weeks", `detailPlanDone`); Brain weather (`detailBrain`); When things get done (`detailHours`); Your focus window, learned (curve, certainty band, check-in dots, `detailWindow`); How long things take ("Things take about 1.5× your first guess", `detailEstimates`); Sleep and done (`detailSleep`); When you log (`detailLogs`); Your patterns, your call (`rhythmTuneTitle`, `rhythmTuneBody`, "Edit your patterns", `rhythmFooter`).

### Patterns editor (Built)

- The workshop under the hood, from the header button or the last page. Every change re-plans today at once; nothing here touches medication. Numbered cards on a faint blueprint grid:
  - 01 Focus window: drag start and end handles over your curve and the learned one (dashed) with check-in dots; "Starts helping", "Helps for", "Today 9:10 to 5:10"; "Use learned". VoiceOver: steppers of 5 min.
  - 02 Eat by: 3 to 7 h after logging, steps of 30 min.
  - 03 How full: 40% to 80% of focus time planned, steps of 5 (default 60%).
  - 04 Between things: 0 to 30 min, steps of 5 (default 10).
  - 05 How sure: rings for check-ins (of 40), certainty, yours or learned.
  - 06 Your day, as learned: a 24 h dial of sleep, window, finishes, eat-by, now.
  - 07 How long things take: a buffer per task, ×1.0 to ×2.0 in steps of 0.1, with "Learned ×1.6".
  - 08 After focus: 0 to 60 min, steps of 5 (default 20).
  - 09 Start over: resets every pattern (confirm).
- Rules: the window keeps at least 60 min beyond its ramps and ends by 13 h after logging. To build: window edits apply even when the medication isn't learning. Feel: a tick every 15 min of handle travel.

## Focus mode (Built)

- Full screen from the Now card (zoom transition, no tab bar): "Close"; kind eyebrow; the task (34 pt, written in); "Then Case reading at 11:05"; a 150 pt ring, centred on the screen (the bar and number styles stay left aligned); rows Time, Session (High focus or Light focus), First step; "Done" and "Done for now".
- The minutes and "min left" inside the ring are centred optically as one block (cap height to baseline), not by their line boxes. The same rule holds for every label inside a circle.
- Rules: updates every 15 s; nothing running → `nowGap`. Timer style from Customise: Ring, Bar or Just the number (Built); the first step row hides when switched off. Wrap-up ripples and a warning tap at 5 min.

## Fix my day (Built)

- Sheet: "You still have room", "One small change" or `fixHeadline`; `fixSubtitle`; each move with its reason ("80 min in your best focus") and "10:45 → 11:30"; "Won’t move: …"; "Apply 2 changes" (or "Keep today as it is") and "Baseline day instead"; "You can undo with one tap for the rest of the day."
- Rules: nothing is written until Apply. The preview adds the overrun to the running block and re-plans with the next 20 min frozen, pinned and calendar items fixed, at most 3 moves. Apply keeps an undo copy.
- To build: minutes over from the real overrun (the prototype uses 40); the real "won't move" list; an "Undo" toast after Apply.
- Accept: Cancel leaves the plan identical; Undo restores the exact previous plan.

## You (decided 30 Sep; Built)

- Page 1, You (locked): the nickname or name, large ("Hello" if neither); a name field only when neither exists; two calm rows, Medication ("2 medications, 3 kinds of day" or "Add what you take") and Personalise ("When you like to do things"). Nothing else.
- Page 2, Support: "If things feel like too much", "You don’t have to handle it alone", "Get support". The support page is fixed, never generated: Lifeline 13 11 14 (text 0477 13 11 14), Emergency 000, your GP; tap to call; "This page is the same for everyone. It isn’t generated by AI, and opening it isn’t recorded anywhere."
- Page 3, The fiddly bits (locked, last): four quiet rows and nothing else: One-press logging, Customise, Settings, Your own AI.
- Every complicated control lives one level deeper; this page can't be removed, so Settings is always reachable.

## Medication page and editors (Built)

### Page, top to bottom

- "Your medication, your rhythm"; "Nothing here tells you what to take. It’s your routine, written down, so your day can fit around it."
- Consent card until agreed: "Your medication details are health information. Focus keeps them on this iPhone, encrypted, and never shares or sells them. Is it OK to store them?" with "Yes, store them" and "What leaves this phone". Everything below is disabled at 40% until yes.
- Today card: the kind of day and "Change" (each kind, then "Use the usual for today"); a timeline from 5 am to 1 am (windows glow, gaps hatched "low focus", dose dots, a moon where sleep is usually possible, a now line); one sentence ("Productive 8:10 to 6:30. Low focus 12:10 to 1:40.").
- What you take: a row per medication ("All day. Working well after 1 hr, helps for about 9 hrs. Sleep usually 12 hrs after."); "Add a medication".
- Kinds of day: `dayTypesIntro`; a card each (symbol, name, "Today" badge, small timeline, "Weekdays, 4 doses"); "Add a kind of day", "2 of 3 on the free plan".
- The one-press card (after the pitch); footer "Your prescriber decides your medication. This page only helps your day fit around it."
- To build: a new person starts with no medications (the prototype seeds examples). Never pre-fill a medicine name, strength or time.

### Medication editor

- Name (needed to save), Strength (free text), kind (All day, Short-acting, Wind-down, Something else, each with a one-line explainer), colour (6), a live 16 h curve preview.

| Slider | Kinds | Range | Step | Defaults (All day, Short-acting, Something else) |
|---|---|---|---|---|
| Working well after | not Wind-down | 0 to 4 h | 5 min | 1 h, 30 min, 30 min |
| Stops helping after | not Wind-down | 1 to 16 h | 15 min | 8 h, 4 h, 6 h |
| You can usually sleep after | not Wind-down | 1 to 20 h | 15 min | 12 h, 6 h, 8 h |
| Starts working after | Wind-down only | 0 to 2 h | 5 min | 30 min |

- "Fine-tune from my check-ins" (All day only, off for new ones): the first two sliders disable and the plan follows what check-ins learned. To build: collecting check-ins; a learned line that reads as a span.
- Changing kind resets the sliders to its defaults while the medication is new or untouched. "These are your own experience, written down. They don’t change what you take or when."
- Remove confirms: "Doses you’ve already logged stay in your history." Feel: `choose`, `tick` per slider step, `success` on Save.

### Kind of day editor

- Name ("Name it anything: Uni day, Night shift, Holidays"), symbol (10), a live timeline and summary.
- Doses, in order: a medication and a time each (4:00 am to 3:00 am next day, steps of 5 min); "Add a dose" (7:00, then 3 h after the last); "Leave a day empty for a medication-free day."
- Productive windows: automatic from each medication's timing, or "Draw my own" (5:00 am to 2:00 am, steps of 15 min, at least 30 min, add or remove). Gaps of 20 min or more between windows are low-focus.
- Wind-down (only with a Wind-down dose): "Wrap up focus before it", 0 to 3 h, steps of 15 min, default 1 h. Never called sleep medication.
- Switches on by itself: weekday circles and "Only between dates" (defaults to the next 14 days) for school holidays, exam weeks or a trip; "If two kinds of day match, the one with the shortest date range wins. You can always switch today by hand."

### Today's kind of day and the free limit

- Choice order: the person's pick for today (until midnight), else the matching date range with the shortest span, else the first kind whose weekdays match with no dates, else the first kind. Accept: a 10-day "Exam week" beats a 4-month "Semester".
- A fourth kind on the free plan plays `caution` and opens the trial offer with `dayTypesLimit`. Existing kinds always keep working.

### One-press pitch

- After the first medication is ever saved, 0.6 s later, once (`actionButtonSuggested`): a medium sheet with a phone whose side button presses three times, `actionButtonPitch`, "Press it and everything you’ve set for about now gets logged, with the same double-dose check as the app.", "Show me how" and "Maybe later". `nudge`.

## Logging sheet and double-dose guard (Built)

- Layout (full sheet, Cancel): medication chips when there are several (glass, the chosen one tinted and morphing); the medication; the time taken (40 pt, digits roll); "When did you take it?" "Just now", "20 min ago", "Earlier…" (wheel picker, never in the future); a folded "Ate something first?" (Yes, No, Skip; "Food can shift when your focus starts. It’s only used to plan your day."); "Log at 9:41"; "Not medical advice. Follow your prescription and check with your doctor or pharmacist."
- Opens on the tapped row's medication, else the first set for now, else the first.
- Guard: if the same medication was logged within its re-log interval (All day 8 h, Short-acting 2 h, Wind-down 12 h, Something else 6 h) either side of the time taken, nothing is written. It shows "Already logged", the earlier time, "1h 30m ago, from your iPhone. Logging again adds a second dose to today’s record.", "Keep one log" (primary), "Hold to log another" (1.2 s hold; a honey fill and a swelling vibration; VoiceOver named action) and "Focus records what you log. It never tells you whether to take a dose. That’s one for your prescriber or pharmacist."
- Rules: times more than 60 s ahead are refused; every write, confirmed duplicate, undo and edit is audited locally; Log all never confirms a duplicate. To build: `caution` when the guard appears; "Undo" on the logged toast; edit and delete from a logged row.
- States: error → "Not saved" and "Couldn’t save that log. Nothing was changed."
- Accept: a second All day log an hour later always shows the guard; letting go early writes nothing.

## One-press logging (Built)

- Page: "Log with the Action button"; an animated phone; four steps (Settings, Action Button, Shortcut, "Log my meds", then "Press and hold the Action button. Everything you’ve set for about now gets logged, and your phone taps twice."); "Open Settings" and "Try it now"; "No Action button?" with Back Tap steps (Accessibility, Touch, Back Tap, Double Tap) and "Or just say “Log my meds in Focus” to Siri."
- Rules: the intent runs exactly the Log all path and guard, answering in one neutral sentence that never names a medicine ("Logged 2 doses. One was already logged, so I left it."). On a locked phone it asks for Face ID first (medication data is fully protected while locked). Reached from the pitch, the Medication page, the top of Settings and The fiddly bits.
- Accept: with the app closed, a press logs what's set for now and the next open shows the ticks.

## Personalise (Built)

- Purpose: when the person likes doing things, in hours after their first dose, so the plan leans that way.
- Layout: "Your timing"; `personaliseIntro`; a rhythm chart (every category and window on one 0 to 16 h axis with today's clock times); Your categories (icon, name, "1 to 5 h after your first dose, 9:10 to 1:10 today", task count), "Add a category", "3 of 5 on the free plan", "Your iPhone sorts tasks into these on its own, using Apple Intelligence on the phone."; Your day: Eating (4½ to 6 h), Being around people (7 to 12 h), Time on your own (0 to 3 h), each a 0 to 16 h range in quarter hours (at least 30 min) with "Today that’s 12:40 to 2:10."; Plans with people: "Suggest better times" (on), `socialIntro`, a calendar request when needed, then cards or "Nothing to suggest today. Your plans with people all land at good times."
- Categories: starters Deep study (1 to 5 h), Admin (5½ to 7½), Prep (5 to 8), Movement (9 to 11), Home stuff (8 to 10). Editor: name, 12 symbols, 6 colours, window. A sixth on the free plan opens the trial offer with `categoriesLimit` and `caution`.
- Rules: the anchor is the first dose logged today, else the first planned dose that isn't a wind-down; Eating's start is also the meal rule. To build: with no doses, anchor to 7:00.
- Social suggestions: each coming calendar event that reads as a plan with people and starts outside the social window, or inside alone time, gets the first free slot of the same length in the social window (15 min steps, clear of other events). Card: "10:30 now. It’s outside the time you like being around people. How about 3:30?", the draft message, "Send it" (share sheet; the person edits and sends) and "Leave it" (never again for that event). Nothing is ever sent for the person.
- Copy: `personaliseIntro`, `categoriesLimit`, `socialIntro`, `socialLine`, `socialMessage`. Accept: moving Eating moves today's lunch.

## Customise (Built; decided 30 Sep)

- First screen: "Your app, your rules"; `customiseIntro`; `hyperfixationWarning` on a honey veil (`nudge`); eight quiet rows, each opening its own page (the list scrolls); "Put everything back how it was" (confirm: "Your plan, medication and history stay exactly as they are.").
- Stored as one versioned JSON blob, decoded key by key so new options never wipe old choices; missing locked pages are re-added.

| Category | Option | Values | Default |
|---|---|---|---|
| Pages | Per tab: reorder, remove, add | That tab's pages; the first is where it opens | As in the tabs table |
| Tabs | Names | Any text; blank is the default | Today, Plan, Rhythm, You |
| Tabs | Show | Plan, Rhythm (Today and You locked) | Shown |
| Tabs | Order | Reorder (Built: swap Plan and Rhythm; To build: drag) | Today, Plan, Rhythm, You |
| Look | Light or dark | Dark, Light, Match iPhone | Dark |
| Look | Background when dark | Dusk façade, Baroque interior, Plain | Dusk façade |
| Look | Darkness when dark | 0 to 80%, steps of 5 | 50% |
| Look | Background when light | Dusk façade, Baroque interior, Plain | Baroque interior |
| Look | Extra blur | 0 to 30, steps of 1 | 0 |
| Look | Mist | 0 to 100%, steps of 5 | 0% |
| Look | Grain | 0 to 100%, steps of 5 | 50% |
| Look | Accent | Espresso, Champagne, Rose, Sage, Slate | Espresso |
| Look | Headings | Serif, Sans, Rounded | Serif |
| Look | Text size | Match iPhone, Smaller, Bigger, Biggest | Match iPhone |
| Look | Roundness | 0.5× to 1.4×, steps of 0.05 | 1× |
| Look | Page markers | Dots, Numbers, Hidden | Dots |
| Voice | Humour | Straight, A little, Lots | A little |
| Voice | New words every day | On, off | On |
| Voice | Call me | Nickname | Empty |
| Feel | Vibrations | On, off | On |
| Feel | Strength | 30% to 130%, steps of 5 | 100% |
| Feel | Ticks on sliders | On, off | On |
| Feel | Celebrate logging | On, off | On |
| Feel | Still motion | On, off | Off |
| Home page | Priorities | 3, 5 | 5 |
| Home page | Say who wrote the priorities | On, off | On |
| Home page | Bottom bar shows | Medication, What’s next | Medication |
| Focus mode | Timer | Ring, Bar, Just the number | Ring |
| Focus mode | Show the first step | On, off | On |
| Lock Screen and Dynamic Island | Focus mode | On, off | On |
| Lock Screen and Dynamic Island | Your day | On, off | Off |
| Lock Screen and Dynamic Island | Your day shows | Both, Stretch only, Next only (only while Your day is on) | Both |
| Lock Screen and Dynamic Island | Log button | On, off | On |
| Lock Screen and Dynamic Island | Hide task names on the Lock Screen | On, off | Off |

- Accept: nothing can hide Today, You, Now or The fiddly bits; every accent keeps button text at 4.5:1 or more in both themes.

## Settings (Built; grouping as decided)

- First screen: `settingsIntro`; the "Log with one press" card first, on purpose; a short list of categories, one quiet row each with a status line; "Focus 1.0, made in Australia".
- Categories, each its own page:
  - Account: signed in with, email, Backup and moving phones (last backup time; opens Figma 12.1), Sign out (To build: back to the account step, data stays), Delete my account (confirm: "This removes your account, your synced data and everything on this iPhone. It can’t be undone. A subscription keeps running until you cancel it in Settings, because Apple handles billing.").
  - Focus Plus: plan ("Free trial until 30 Oct", "Plus, renews 12 Mar", "Free (Plus ended)"), See Plus (free only), Manage subscription, Restore purchases ("Checked with Apple."), Redeem a code; "Payments, trials and refunds are all handled by Apple."
  - Look: Light or dark; "Everything else in Customise".
  - Privacy: Discreet mode (on by default: "No medicine names on the Lock Screen, in notifications, widgets or calendar titles."; To build: persist it), What leaves this phone, Your own AI.
  - Permissions: Calendar and Notifications ("On" or "Allow"); "At most five nudges a day, never naming a condition or a medicine." To build: Health (sleep); "Open Settings" after a refusal.
  - Your data: Export everything (readable JSON, share sheet); Delete everything on this iPhone (confirm).
  - Safety and legal: Not a medical device (the honest bit), Terms, Privacy policy.
  - Contact us: its own row on the Settings list ("A real person replies within 2 business days"), opening the form (Figma 12.11). Server Built; the app screen is To build.
  - Support: Get support stays in Safety and legal.
  - Built today: Account and Plus share a page; Get support sits in Safety and legal.
- What leaves this phone ("Almost nothing"): medication, doses, check-ins and the focus pattern stay on this iPhone; Health read only; calendar read here, never uploaded; Apple Intelligence on the phone; moving phones end-to-end encrypted; your own AI only what you allow; no ads or trackers.
- Accept: account deletion is two taps from Settings; nothing destructive happens without a confirm.

## Live Activities and the Dynamic Island

- Two optional Live Activities, local only: Focus mode (the task and time left; on by default) and Your day (the stretch you're in and what's next; off by default). Full spec: 10-live-activities.md. Figma 6.5 to 6.11, components 11.4, Customise page 10.13 and 10.14.
- Today shows a one-time offer card after the first log of the first day: eyebrow "Quick one", "Want your day in the Dynamic Island?", "See which stretch you're in without opening Focus.", "Show it" and "Not now". Fixed wording (it appears once).
- The Action button result appears as the expanded Dynamic Island ("Focus", "Logged two doses."), drawn in Figma 6.1.

## Account, backup and moving phones

- Figma section 12 draws every screen the backend powers. Server: Built (backend/). iPhone client library: Built (app/FocusCore, FocusSync). App screens: the email code step is Built; the rest are To build and follow the Figma notes.
- Email sign-in (12.0): "Check your email." "We sent a link to {email}. Tap it on this iPhone and you're in." Six code boxes as the fallback; a new link after 60 seconds; "Use a different email".
- Backup and moving phones (12.1): last backup, Back up now, recovery key, the iCloud Keychain copy switch, Devices (12.3), Scan a new iPhone, Restore an earlier backup, Delete my backup.
- Recovery key (12.2): shown once, never stored; Copy and Save as PDF to Files; "I've saved it".
- New iPhone (12.4 to 12.9): Welcome back with three ways in (old iPhone by QR with a matching code on both phones, the recovery key, or Start fresh), then "All here. Welcome back." with calendar and notifications asked again.
- Two phones (12.10): "Two logs, two phones. Keep both?" and "This was changed on two phones. Check it's right."
- Contact us (12.11), Delete my account (12.12), the email link web page (12.13) and the quiet lines and one-time asks (12.14): all fixed wording, because they are about accounts, safety and data.

## Bring your own AI (Built)

- Optional, off by default; nothing in Focus depends on it.
- Page: "Bring the AI you already use"; "Use my own AI" (first time opens the warning); provider OpenAI, Anthropic, or Something else (OpenAI-style, HTTPS only), never Gemini; model; key (Keychain only, "Remove"); What it may see: Task names (on), Times (on), "Never: medication, doses, check-ins, health data, your name or your account."; "Test it", "Ask it something"; "Disconnect and forget my key".
- Warning, factual: the provider isn't part of Focus and their terms apply; we can't stand behind its answers; exactly what is sent; some free plans train on it; everything works without it. "I understand, connect it" or "Not now". `caution`.
- Ask sheet: one question plus allowed lines ("9:15 to 10:35: Essay drafting"); the answer; "From your own AI, not from Focus."
- Errors: "Add your key first.", "That address doesn’t look like an API endpoint.", "Your provider didn’t accept that key.", "Your provider said no (error 500).", "Your provider answered, but not in a way we could read."
- Every answer passes the safety screen; one that strays into doses or treatment claims is replaced by "That’s one for your prescriber or pharmacist. Your AI’s answer talked about medication, so Focus didn’t show it."
- Accept: with both toggles off the request holds no plan at all; no request ever holds medication data.

## Notifications (mechanics in 05)

- Built: the trial reminder. To build: reminders at times the person sets for doses, one-tap check-ins while learning, a quiet wrap-up cue. At most five a day; never a condition or medicine name; never "take", "skip", "due" or "catch up"; asked for in context, never at launch.

## Accessibility

- Dynamic Type everywhere plus Customise text size; at accessibility sizes action rows stack, pages scroll inside, titles wrap to four lines and scale to 80% at most.
- VoiceOver: headings on serif titles and the date; rows combined; page markers and sliders adjustable in their own steps; charts summarised; hold-to-confirm has a named action; decoration hidden.
- Reduce Motion or Still motion: fades, no loops, ripples or celebration. Reduce Transparency: solid veils, no grain. Increase Contrast: 1 pt hairlines. Targets 44 pt; colour never the only signal; text 4.5:1 or more.
- To build: an Assistive Access scene with Now, Next and Log.

## The copy system (Built)

- Every sentence with a voice is a slot in `Model/Copy.swift` (tone, placeholders, character limit, context, example). `Copy.json` holds 100 hand-written variants for each of the 65 slots as `{t, f}` (text, funny): 8 first launch, 5 coach, 22 Today, 4 arrival, 13 Plan and Rhythm, 9 setup, 4 moments.
- Tones: serious (all plain), light (about 30 gently funny), playful (about 60 funny).
- Daily rotation: variant = |day ordinal × 7919 + slot salt| mod pool size (salt: a hash of the slot name). Stable all day, new after local midnight, independent per slot.
- Humour: Straight uses plain variants; A little uses all; Lots uses funny ones when a slot has 10 or more. New words every day off: always the first. A missing deck falls back to the slot's example.
- Checked by `docs/copy/merge.py`: no em or en dashes or spaced hyphens; within the limit; each placeholder exactly once, no others; typographic apostrophes; none of "due", "onset", "wear off", "booster", "predict", "optimal"; serious slots never funny.
- Never rotates: buttons, labels, legal and safety text, the guard, notifications, errors, spoken intent results.
- To build: "kinds of day" everywhere the person reads it (some strings still say "day types").

## Tasks and calendar input (To build)

- The prototype seeds a demo day. Needed: quick add with a title, rough minutes, an optional deadline and "a must today"; kind (deep, medium, light, body) and category read on the phone, editable; today's calendar events as fixed blocks; pin a block so it never moves; done and done for now.
- Accept: adding a task re-plans today within a second and never moves a pinned or calendar item.
