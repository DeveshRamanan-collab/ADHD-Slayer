# Pharmacology research: build requirements extraction

Source: /Users/deveshramanan/Downloads/medication_pharmacology.md, read in full (570 lines, research date 28 September 2026). Citation tags in brackets name the source heading: [Scope note] (the scope note and source-access caveats at the top), [Q1 Formulation profiles], [Q1 Summary table], [Q2 New medicines 2023-2026], [Q3 Individual variability], [Q4 Wear-off and rebound], [Q5 Boosters], [Q6 Lab-school curves], [Q7 N-of-1, EMA and wearables], [Q8 Self-report validity], [Q9 Missed-dose guidance], [Q10 Australian specifics], [Priors for the app's model]. [Product brief] marks a rule that comes from the product description supplied with this task, not from the research document. "(derived)" marks a concrete value or rule proposed here so the research can be built. The source does not state it, so it needs product sign-off. Ranges use a plain hyphen (20-60 min). Unless stated otherwise, times are hours after the logged dose, for adults, fasted or after a light meal. Missed-dose and label texts below are summaries. The app must ship the licensed verbatim text.

## 1. User needs and pain points → the feature or behaviour that answers each

- Effect is not flat through the day (Ritalin LA can dip at about 4-4.5 h; Concerta feels weaker for the first 2-4 h and stronger later; Vyvanse is a broad plateau) → every product carries a curve shape, and the timeline draws that shape instead of a single on/off bar. [Q1 Formulation profiles]
- Long-acting products are slow to start (group-mean onset 1.5-2 h; Vyvanse about 1.5 h fasted, about 2.5 h after food) → the plan shows a "kicks in" point and a ramp before the productive window, and puts only low-effort items in the ramp (derived planner rule). [Q6 Lab-school curves; Priors for the app's model]
- Breakfast changes timing for some products and not others → a one-tap food choice on each dose log shifts that dose's forecast by the product's own food rule (Vyvanse +1 h; Adderall XR +2.5 h; Ritalin LA and Focalin XR variable lag with a weaker second phase; Concerta 0). [Q3 Individual variability]
- An afternoon booster feels weaker than the same tablet taken in the morning (acute tolerance: the second of two closely spaced doses gives a smaller gain) → a booster is learned as its own curve, separate from the same product taken in the morning. [Q5 Boosters]
- Late doses hurt sleep → the timeline shows the user's own sleep cut-off, or the product information timing rule (for example methylphenidate IR last dose before 6 p.m.), as a fixed boundary. The app never suggests a dose time. [Q5 Boosters]
- "I took it late or missed it, what now?" → the app shows only the stored product-information text for that exact product, plus an information-only projection of when the window would end relative to bedtime. It never prompts the user to take or skip. [Q9 Missed-dose guidance]
- Shortage-driven brand or generic switches change how the medication feels (the FDA found some Concerta generics released drug more slowly at 7-12 h) → the exact product and brand are recorded on every dose. A switch starts a new product curve that borrows partly from the old one, a "re-learning" state runs for about 1-2 weeks, and late-afternoon check-ins get extra weight. [Q10 Australian specifics]
- Some weeks the medication feels weaker, often before a period → an optional cycle-phase covariate (evidence strongest for amphetamines: follicular response greater than luteal) explains the variation. The app never suggests changing a dose. [Q3 Individual variability]
- After poor sleep, stimulants can make a person feel fine while masking the deficit → sleep hours are logged, a sleep-debt flag down-weights that day's focus ratings, and the app never presents "medication working" as "ready" or "rested". [Q3 Individual variability; Q8 Self-report validity]
- Some people become irritable or emotional as it wears off → an optional end-of-window mood or irritability check, with "rebound" kept separate from "wear-off". It is off by default because rebound is a minority pattern (3.4% on lisdexamfetamine in a paediatric trial). [Q4 Wear-off and rebound]
- People cannot recall when it kicked in → short momentary check-ins ("focus right now, 1 to 5") at jittered times replace recall. An optional 30-60 s objective task adds a less biased measure. [Q8 Self-report validity]
- Non-stimulant users have no daily window (atomoxetine, guanfacine XR, viloxazine, clonidine as maintenance; centanafadine unknown) → no kick-in or wear-off window is learned or shown for them. The app says the effect builds over weeks and allows optional notes on side-effect timing. [Q1 Formulation profiles]
- Imported (Section 19A) products and overseas users' products are missing from an AU list → an "Other or imported" product slot, plus optional US and UK entries. [Q2 New medicines 2023-2026]
- Some long-acting products are taken in the evening (Jornay PM), and some clinicians direct an extra evening dose (Ritalin LA at about 8 p.m. in some children) → any dose time is allowed and morning dosing is never assumed. [Priors for the app's model; Q5 Boosters]
- People need to know how far to trust the estimates → prior values carry the caption "typical for this formulation" and wide bands until the user's own check-ins override them. [Scope note; Priors for the app's model]
- The evening wind-down dose ends the useful day → a wind-down dose ends the productive window at its own kick-in time (clonidine IR onset 30-60 min). The UI never calls it a sleep medication. [Q1 Formulation profiles; Product brief]
- Apple Watch heart rate stays high all day on amphetamines (raised up to 24 h) → heart rate is used only as a weak onset or "dose taken" signal and never to declare that the medication has worn off. [Q7 N-of-1, EMA and wearables]
- Day-to-day noise hides the real pattern (only 29 of 86 completed N-of-1 trials showed a clear drug-over-placebo response; unblinded impressions and blinded data often disagree) → day types create repeated same-condition days, and learned results show their uncertainty. [Q7 N-of-1, EMA and wearables; Q8 Self-report validity]
- Amphetamine users are told that fruit juice, vitamin C and antacids matter but not by how much → optional one-tap flags ("acidic drink or vitamin C near dose", "antacid or PPI near dose") are logged as exploratory covariates, with no fixed shift and no advice. [Q3 Individual variability]
- A Concerta-type product is weakest early and strongest late, while higher-IR products are the reverse (COMACS) → the planner puts the hardest priorities where that person's curve is strongest, not just anywhere inside the window (derived planner rule). [Q6 Lab-school curves; Q1 Formulation profiles]

## 2. Features and behaviours (with acceptance criteria)

### 2.1 Medication catalogue

- AU default catalogue: methylphenidate IR (Ritalin 10, Artige), Ritalin LA, Concerta, OROS-type generics such as Methylphenidate-Teva XR as separate products, dexamfetamine IR (Aspen Dexamfetamine 5 mg), Vyvanse capsules (20, 30, 40, 50, 60, 70 mg), atomoxetine, guanfacine and clonidine (Catapres). AC: with region set to AU, the add-medication picker lists these first, and Concerta and each OROS generic are separate selectable products. [Q2 New medicines 2023-2026]
- "Other or imported" slot: the user enters name, brand, active ingredient and role (long-acting, short-acting or booster, wind-down, maintenance), then sets every slider. The model uses an "unknown shape" prior. AC: a Section 19A product such as Swiss Concerta can be added, logged and learned with no catalogue data. [Q2 New medicines 2023-2026; Q10 Australian specifics]
- Optional non-AU entries: US Ritalin and Methylin IR, Ritalin-SR, Focalin IR and XR, Dexedrine, Zenzedi, Vyvanse chewable, Adderall IR and XR, Mydayis, Jornay PM, Azstarys, Quillivant XR, Aptensio, Metadate CD, Strattera, Intuniv, Kapvay, Onyda XR, Qelbree, Simtriyo (centanafadine); UK Concerta XL, Medikinet XL, Equasym XL; Canada Biphentin. AC: hidden for AU users unless "Show products from other countries" is on (derived visibility rule). [Q1 Formulation profiles; Q2 New medicines 2023-2026; Q6 Lab-school curves]
- Products with no verified intraday data (centanafadine, Mydayis, Jornay PM, Azstarys, dexmethylphenidate IR, anything added as other or imported) have no default slider values. AC: their sliders open unset with the note "No typical values on file. Set your own." The product cannot join a day plan until Kicks in, Window and Lasts are set (derived). [Priors for the app's model; Q1 Formulation profiles]
- Every catalogue product shows provenance, because TGA PIs could not be opened and US FDA labels, the NZ Medsafe Concerta data sheet and Australian CMI text stand in for them. AC: the product detail screen has a Sources row naming the document, country and year behind every prior and every label text. [Scope note]

### 2.2 Medication page: add and edit

- Add flow: choose the product, choose a role (long-acting, short-acting or booster, wind-down, or maintenance for non-stimulants), enter the dose exactly as prescribed, then review sliders pre-filled with typical values. AC: the dose field starts empty and no screen proposes a dose. Strength chips from the catalogue may speed entry (derived). [Scope note; Product brief]
- Stimulant slider set: Kicks in, Productive window (start and end), Lasts, Can sleep after. Defaults, typical bands and bounds are in section 6.2. AC: each slider shades its typical band and shows the caption "Typical for this formulation" until personal data overrides it. [Priors for the app's model; Product brief]
- Slider ordering (derived): 0 ≤ Kicks in ≤ Window start < Window end ≤ Lasts, with a minimum window of 15 min. AC: dragging one handle past another pushes the neighbour along and an invalid order can never be saved. [Priors for the app's model]
- "Can sleep after" is never pre-filled, because the app must never suggest timing (derived). AC: it opens unset and shows the product's full wear-off band and any product-information timing rule as reference text. While it is unset, the plan uses the product rule, if one exists, as the boundary. [Q5 Boosters; Q9 Missed-dose guidance]
- Curve preview per product: IR single fast hump; Ritalin LA and Focalin XR two humps about 4 h apart with a "possible dip" marker (4-4.5 h and about 4 h); Concerta ascending (small early rise, strongest at 6-8 h); Vyvanse broad plateau with slow rise and fall; Adderall XR two pulses smoothed together; wind-down single hump. AC: the preview redraws live as sliders move and keeps the product's shape. [Q1 Formulation profiles; Q1 Summary table]
- Non-stimulant maintenance medications (atomoxetine, guanfacine XR, viloxazine, clonidine as maintenance, centanafadine until data exist) have no window sliders. AC: their screen says the effect builds over weeks (atomoxetine may take 2-3 months) and offers only dose logging and optional side-effect time notes (for example drowsiness around 5 h after guanfacine XR). [Q1 Formulation profiles; Priors for the app's model]
- Wind-down role: only "Kicks in" (clonidine IR default 45 min, typical 30-60 min) and "Lasts" (default 6 h, typical 4-8 h). AC: a string audit of every wind-down screen finds none of the banned terms in section 7. [Q1 Formulation profiles; Product brief]
- Learning never silently overwrites a value the user set by hand (derived). AC: when check-ins disagree with a hand-set value by 30 min or more (derived), the slider shows a second marker, for example "From your check-ins: 10 h 45 min", with Accept and Keep mine. [Priors for the app's model]
- Switching product (for example Concerta to Methylphenidate-Teva XR) creates a new medication record linked to the old one. AC: the old record stays read-only with its learned curve, the new one shows "Re-learning" (section 6.5), and history keeps the exact product on every log. [Q10 Australian specifics]

### 2.3 Dose logging

- A log captures the exact product and brand, the dose as entered, time taken (defaults to now, editable), time logged, role in the day, and a one-tap food choice: Nothing yet, Light snack, Meal, High-fat meal (derived option set). AC: a log saved without a food choice stores "not recorded" and gets no food shift. [Q3 Individual variability; Q10 Australian specifics]
- Food rule per logged dose (sliders hold fasted values). AC: Vyvanse at 07:00 with Meal forecasts kicks in 09:30 and window 11:30-19:00 (whole curve +1 h, derived); Concerta with High-fat meal is unchanged; Ritalin LA with High-fat meal keeps its times but widens the kicks-in band and draws the second hump at 75% height. [Q3 Individual variability; Priors for the app's model]
- Amphetamine products (dexamfetamine, lisdexamfetamine, mixed amphetamine salts) offer two optional flags: "Acidic drink or vitamin C near dose" and "Antacid or PPI near dose". AC: the flags appear only for amphetamine products, and ticking one never changes a forecast on its own (exploratory covariate, section 6.4). [Q3 Individual variability; Priors for the app's model]
- Any dose time is allowed, including evening. AC: logging a long-acting product at 19:00 saves with no text about morning dosing. [Priors for the app's model; Q5 Boosters]
- Late log (derived trigger): when dose time + Lasts, or dose time + Can sleep after if set, is later than the user's bedtime, show an information-only card with the projected window end and the bedtime. AC: Vyvanse logged at 13:00 (defaults, food not recorded) with bedtime 22:30 shows a window end around 00:00. The card has no Take, Skip or Remind action. [Q9 Missed-dose guidance]
- Possible duplicate: logging the same product and role again inside its relog interval (section 6.7) shows a neutral confirmation. AC: Vyvanse at 07:00 and again at 09:00 shows "Vyvanse is already logged at 07:00. Log another dose?" with Log it, Edit earlier log and Cancel. Dexamfetamine 5 mg at 07:00 and again at 16:30 shows nothing. [Q9 Missed-dose guidance; Q5 Boosters]
- Missed-dose information: each medication's menu has "What the product information says about missed doses", showing the stored text for that exact product with its source. AC: Vyvanse, dexamfetamine, atomoxetine and guanfacine XR show text. Ritalin IR, Ritalin LA, Focalin XR and Concerta show "No missed-dose text on file for this product" plus any stored timing rule. Nothing is generated. [Q9 Missed-dose guidance]
- "Mark this day as unusual" (derived) excludes a day's check-ins from learning (for example illness or an atypical meal or drink). AC: marked days stay visible in history and change no learned value. [Q3 Individual variability; Priors for the app's model]

### 2.4 Boosters and day types

- A booster is its own medication role with its own sliders and learned curve, even when it is the same product as a morning IR dose. AC: changing the booster's Lasts leaves the morning IR dose's Lasts unchanged. [Q5 Boosters; Priors for the app's model]
- The app uses only boosters the user entered as prescriber-authorised, at the times the user entered. AC: no screen, notification or generated priority list proposes adding, moving or removing a booster. [Q5 Boosters]
- Day types combine dose slots (for example "Uni day": dexamfetamine 5 mg, then Vyvanse, then a dexamfetamine 5 mg booster, then a wind-down dose) and compute productive windows and unproductive gaps with the rule in section 6.3. AC (defaults, Vyvanse fasted): dexamfetamine 07:00, Vyvanse 07:30, dexamfetamine booster 16:30 and clonidine IR wind-down 19:00 give one productive window from 08:15 to 19:45. With no wind-down slot it runs to 20:30. [Product brief; Q5 Boosters]
- Gap example. AC (defaults): Ritalin LA at 08:00 and a methylphenidate IR booster at 15:30 give productive 09:45-14:30, an unproductive gap 14:30-16:45, then productive 16:45-18:00. A "possible dip" marker sits at 12:00-12:30 and is not a gap until learned. [Q1 Formulation profiles; Q5 Boosters; Priors for the app's model]
- Wind-down truncation: a wind-down dose ends every productive window at wind-down time + its Kicks in. AC: moving the wind-down slot 30 min earlier moves the day's productive end 30 min earlier whenever the window would otherwise run past it. [Product brief; Q1 Formulation profiles]
- Dose-time boundary per slot: bedtime minus that medication's Can sleep after (captioned "Your sleep cut-off"). If that is unset, the product rule applies (methylphenidate IR 18:00; dexamfetamine IR bedtime minus 6 h). Qualitative rules (Vyvanse avoid afternoon or evening; Concerta, Ritalin LA, Focalin XR, Adderall XR morning dosing) show as attributed text with no line. AC: a methylphenidate IR slot at 18:30 with Can sleep after unset shows a line at 18:00 captioned "Product information: last dose before 6 p.m." and no prompt to move the slot. [Q5 Boosters; Q9 Missed-dose guidance]
- Planner placement (derived): priorities written by Foundation Models go inside productive windows. The highest-effort item goes where the curve is strongest, and never on a learned dip. AC: with Concerta at 07:00 and defaults, the first priority lands between 13:00 and 15:00 (6-8 h after the dose) when free time exists there. [Q1 Formulation profiles; Q6 Lab-school curves; Product brief]
- Ramp display (derived): the time between Kicks in and Window start is drawn as a ramp, not as a gap. AC: in the Ritalin LA example, 09:00-09:45 is drawn as a ramp and holds only low-effort items. [Priors for the app's model; Q6 Lab-school curves]

### 2.5 Check-ins and measurement

- Momentary check-in: one question, "Focus right now", 1 to 5, one tap, at jittered times around each dose's forecast anchors (section 6.6). AC: it can be answered from the notification or a widget without opening a form, and it never asks the user to recall when the effect started. [Q8 Self-report validity]
- Optional objective probe of 30-60 s (reaction time, or PERMP-like arithmetic), offered after a check-in. AC: the probe never runs past 60 s, and the check-in still counts if the probe is skipped. [Q8 Self-report validity; Q6 Lab-school curves]
- Optional end-of-window mood or irritability check, off by default, offered near the forecast window end. AC: stored apart from focus, and labelled rebound only when the rating is below the user's own baseline (derived). [Q4 Wear-off and rebound]
- After a product switch, add late-afternoon check-ins 7-12 h after a long-acting dose for the re-learning period. AC: during re-learning after a move between OROS products, at least one prompt lands 7-12 h after the dose on each dosing day (derived count). [Q10 Australian specifics]

### 2.6 Learning and display

- Forecasts start from catalogue priors captioned "Typical for this formulation" and switch to "Learned from your check-ins" once personal data overrides them (threshold in section 6.5). AC: the caption changes per product and role only after the threshold is met. [Priors for the app's model; Scope note]
- Learned durations may run past the catalogue's upper bound, because a study's "last significant time point" is often just the last time measured. AC: a learned Vyvanse Lasts of 16 h is accepted and drawn. [Q6 Lab-school curves; Priors for the app's model]
- Non-stimulants never show a learned daily window. AC: no window, ramp or gap is drawn for atomoxetine, guanfacine XR, viloxazine or clonidine maintenance, whatever the check-ins say. [Q1 Formulation profiles]
- Sleep-debt days are marked and down-weighted (section 6.4). AC: a flagged day shows a marker on its check-ins, and that day's plan copy contains no readiness claim. [Q3 Individual variability; Q8 Self-report validity]

### 2.7 Health signals (optional)

- Heart rate from Apple Watch, if the user allows it, is used only as a weak onset or dose-taken signal (a rise within about 1-3 h of a dose). AC: no UI or model path uses heart rate to end a window or to say a medication has worn off. [Q7 N-of-1, EMA and wearables]
- Sleep hours and cycle phase can come from Health or be typed in. AC: denying Health access leaves every feature usable with manual entry (derived). [Q3 Individual variability]

## 3. Data the app must store (entities, fields, retention)

### Product (catalogue, read-only in the app)

- Product identity: id, generic name, active moiety (methylphenidate, dexmethylphenidate, dexamfetamine, lisdexamfetamine, mixed amphetamine salts, atomoxetine, guanfacine, clonidine, viloxazine, centanafadine), brand, sponsor or generic maker (for example Teva), dosage form (tablet, scored tablet, capsule, chewable, suspension). [Q1 Formulation profiles; Q2 New medicines 2023-2026]
- Product strengths as listed in the source: Vyvanse AU capsules 20, 30, 40, 50, 60, 70 mg; Aspen dexamfetamine 5 mg scored tablets; Ritalin 10 mg; Concerta 18, 36, 54 mg (the doses used in the COMACS study); centanafadine 140, 210, 280 mg. Other strengths need confirming (section 11). [Q1 Formulation profiles; Q2 New medicines 2023-2026; Q6 Lab-school curves]
- Product availability: region (AU, US, UK, NZ, Canada), status (AU registered, not in AU, Section 19A import, shortage notice, approved but not dispensable) and a last-reviewed date. Example: centanafadine was FDA-approved on 24 Jul 2026 but, as of August 2026, could not be dispensed until the DEA assigns a schedule. [Q2 New medicines 2023-2026; Q10 Australian specifics]
- Release mechanism and IR:ER ratio: SODAS 50:50 (Ritalin LA, Focalin XR, Medikinet); OROS 22:78 (Concerta); Equasym XL 30:70; Biphentin 40:60; Metadate CD about 30% IR; Adderall XR two-pulse beads with d:l 3:1; lisdexamfetamine prodrug; centanafadine IR, ER and DR beads. [Q1 Formulation profiles; Q6 Lab-school curves]
- Curve shape enum: single fast hump, single broad hump, bimodal, ascending, broad plateau, two pulses smoothed, wind-down hump, no daily window, unknown. Plus hasIntradayWindow: false for atomoxetine, guanfacine XR, viloxazine and clonidine maintenance; unknown for centanafadine. [Q1 Formulation profiles; Q1 Summary table; Priors for the app's model]
- Product prior: low and high hours for onset, plateau start, wear-off start and full wear-off; dip range (Ritalin LA 4-4.5 h, Focalin XR about 4 h); peak times; second-peak factor after a high-fat meal (0.75 for Ritalin LA and Focalin XR); food shift in hours per food option; food-variability flag; half-life range (documentation only). [Priors for the app's model; Q3 Individual variability]
- Covariate flags: pH-sensitive (amphetamines), cycle-sensitive (strongest for amphetamines), CYP2D6 note (atomoxetine), alcohol dose-dumping note (Ritalin LA), weight and age clearance note (OROS). Flags shape the model and never produce advice. [Q3 Individual variability; Q1 Formulation profiles]
- Label timing rule as structured data: type (clock cut-off, hours before bedtime, dose spacing, qualitative), value, text and source. Examples: methylphenidate IR last dose before 18:00; dexamfetamine AU missed dose not later than 6 h before bedtime; Adderall IR doses 4-6 h apart and none late in the evening; Vyvanse avoid afternoon or evening; Concerta once daily in the morning. [Q5 Boosters; Q9 Missed-dose guidance]
- Missed-dose text: verbatim text, jurisdiction, document type (PI, CMI or FDA label), document year and retrieval date. Null where the label has none (Ritalin, Ritalin-SR, Ritalin LA, Focalin XR) or the AU text was not retrieved (Concerta, Ritalin LA, Ritalin 10). [Q9 Missed-dose guidance]
- Sources: document, jurisdiction, year and URL for every numeric value, plus catalogue version and research date (28 Sep 2026). [Scope note]

### UserMedication (the user's configured medication)

- id, productId or custom product, role (long-acting, morning short-acting, booster, wind-down, maintenance), dose as prescribed (number and unit, typed by the user, never suggested), and for boosters a "prescribed by my prescriber" confirmation (bool). [Q5 Boosters; Scope note]
- Slider values in minutes after dose: kicksIn, windowStart, windowEnd, lasts, canSleepAfter (nullable); each value's source (typical, user-set, learned, accepted-learned). [Priors for the app's model; Product brief]
- Lifecycle: started date, ended date, previousUserMedicationId (switch link), relearning start and end dates, daily dose count as scheduled (for example atomoxetine once or twice). [Q10 Australian specifics; Q1 Formulation profiles]

### DayType

- id, name (for example "Uni day"), ordered slots (userMedicationId, planned clock time, role), wake time, bedtime, and cached productive windows, ramps and gaps. [Product brief; Q5 Boosters]

### DoseLog

- id, userMedicationId, productId and brand at the time of the dose (captured on every log, never inferred), dose amount and unit, takenAt (UTC plus local time zone), loggedAt, entry source (manual, notification, widget), role, dayTypeId (nullable). [Q10 Australian specifics]
- Covariates: food (not recorded, nothing, light snack, meal, high-fat meal), acidic drink or vitamin C near dose (bool, amphetamines only), antacid or PPI near dose (bool, amphetamines only), free-text note. [Q3 Individual variability]
- Flags: lateLog (bool), duplicateConfirmed (bool), unusualDay (bool), edit history (timestamp and previous values). [Q9 Missed-dose guidance; Q3 Individual variability]

### Check-ins and measurements

- CheckIn: id, scheduledAt, jitter applied (minutes), deliveredAt, answeredAt, focus 1-5 or skipped, active doses with minutes since each, target anchor (kicks in, window start, mid-window, window end, lasts, late afternoon). [Q8 Self-report validity]
- ObjectiveProbe: checkInId, type (reaction time or arithmetic), duration in seconds (30-60), attempts, correct answers, median reaction time in ms. [Q8 Self-report validity]
- MoodCheck (optional rebound check): timestamp, irritability or mood 1-5, linked dose. [Q4 Wear-off and rebound]
- SideEffectNote (non-stimulants): timestamp, type (for example drowsy), linked dose. [Q1 Formulation profiles]

### DailyContext

- date, sleep hours (manual or Health), sleep-debt flag, cycle phase (optional: follicular, luteal or unknown; manual or Health), resting heart-rate summary (optional). [Q3 Individual variability; Q7 N-of-1, EMA and wearables]

### LearnedCurve

- user, product, role (booster separate from morning), parameters (lag, rise, one or two humps, plateau, decay) with uncertainty, learned food shift, covariate effects (pH, cycle, sleep debt), dosing days and check-in counts, status (typical, learning, personal, re-learning), borrowedFrom product and weight, updatedAt. [Priors for the app's model; Q5 Boosters]

### Retention

- The source sets no retention period. Derived: keep dose logs, check-ins and learned curves until the user deletes them, including records for products no longer taken, because partial borrowing after a switch needs them. Keep every catalogue version used, so past forecasts can be reproduced. Provide delete-all. [Q10 Australian specifics; Priors for the app's model]

## 4. Backend / services / integrations required

- A versioned product catalogue (priors, curve shapes, food rules, label timing rules, missed-dose texts, sources) that can be updated without an app release (derived). Availability changed repeatedly in 2023-2026: most Section 19A approvals lapsed on 31 Jan 2026 and Ritalin LA's ran to 30 Apr 2026; methylphenidate MR shortages were "largely resolved" by June 2026 but still patchy; one tracker still listed Concerta under a shortage notice to the end of 2026 and Rubifen LA to September 2026; a new approval (centanafadine) was waiting on scheduling. [Q10 Australian specifics; Q2 New medicines 2023-2026]
- Catalogue content workflow: every value cites a source and jurisdiction. When sources conflict, the label wins (Concerta IR overcoat 22%, not the secondary 25%; Ritalin LA onset from its IR-bead half, not the secondary "about 2 h"). [Q1 Formulation profiles]
- AU-first catalogue with its stand-in sources recorded (US FDA labels, NZ Medsafe Concerta data sheet, ACSQHC Medicine Finder CMI text in place of TGA PIs), and visible in provenance. [Scope note]
- Regional catalogue: AU by default, US and other markets optional, region chosen in settings. [Q2 New medicines 2023-2026]
- A product-information text store for missed-dose and timing text, with permission to reproduce CMI and label text verbatim (section 11). [Q9 Missed-dose guidance]
- Catalogue refresh triggers (derived): label updates, TGA or FDA approvals and scheduling, shortage notices and Section 19A changes. Each refresh bumps the catalogue version and research date. [Q10 Australian specifics]
- Nothing in this source needs server-side computation. The curve model and learning are small enough to run on device (derived). [Priors for the app's model]
- No integration with PBS, SafeScript NSW, prescribing systems or pharmacies. That part of the source is context for the catalogue and switch handling only (derived scope rule). [Q10 Australian specifics]
- Subscriptions, accounts and sync are not covered by this source. [Scope note]

## 5. Apple frameworks, capabilities, entitlements, Info.plist keys

- HealthKit read, optional: heart rate from Apple Watch, used only for the weak onset or dose-taken signal. Apple Watch had the lowest heart-rate error (2.0%) in a 60-person ECG comparison. Needs the HealthKit capability (com.apple.developer.healthkit) and NSHealthShareUsageDescription (derived mapping). [Q7 N-of-1, EMA and wearables]
- HealthKit read, optional: sleep analysis, for sleep hours and the sleep-debt flag (derived mapping). [Q3 Individual variability]
- HealthKit read, optional: menstrual cycle data, as one source for the cycle-phase covariate. Manual entry must also work (derived mapping). [Q3 Individual variability]
- Do not request or use active energy: every wrist device tested had 27-93% energy-expenditure error. Steps are not used for intraday learning in the first version, because step changes were only shown over weeks (derived). [Q7 N-of-1, EMA and wearables]
- NSHealthUpdateUsageDescription only if the app writes to Health. Nothing in this source needs writing (derived). [Q7 N-of-1, EMA and wearables]
- The HealthKit background-delivery entitlement (com.apple.developer.healthkit.background-delivery) is needed only if heart-rate onset detection runs in the background. Otherwise, read on next launch (derived). [Q7 N-of-1, EMA and wearables]
- UserNotifications: local, jittered check-in prompts scheduled when a dose is logged, answerable in one tap. No background mode is needed for this (derived mapping). [Q8 Self-report validity]
- WidgetKit and App Intents: an interactive 1-5 check-in and quick dose log without opening the app (derived mapping). [Q8 Self-report validity]
- Swift Charts for the curve preview and day timeline, with accessibility labels and Audio Graph support (derived mapping). [Q1 Formulation profiles]
- Foundation Models (from the brief) may take productive windows, gaps and curve strength as input for placing priorities. Its instructions and a post-generation filter must block any dose, dose-timing, missed-dose, interaction, food-timing, stopping or tapering content (derived from the never-generate rules). [Q9 Missed-dose guidance; Q5 Boosters; Scope note; Product brief]
- Frame-accurate timing for the optional reaction-time probe, for example CACurrentMediaTime timestamps rather than Date (derived). [Q8 Self-report validity]
- Whether to read or write medication and dose records through HealthKit, if the target iOS version offers it, is not covered by the source (section 11). [Q7 N-of-1, EMA and wearables]

## 6. Algorithms, parameters, defaults and thresholds (include a table of formulations with onset, peak, duration, ramp values, food effects, slider defaults and ranges)

### 6.1 Formulation table: evidence, priors, ramps, food

Ramp up = Window start default minus Kicks in default. Ramp down = Lasts default minus Window end default. "n.a." = not applicable.

| Formulation (AU brand; other markets) | Release and curve shape | Onset (evidence) | Peak or Tmax (evidence) | Duration (evidence) | Prior h: kicks in / window start / window end / lasts | Ramp up / ramp down | Food effect (evidence) | Food rule in model | Source |
|---|---|---|---|---|---|---|---|---|---|
| Methylphenidate IR (Ritalin 10, Artige; US Ritalin, Methylin) | IR tablet, racemic 1:1 d/l; single fast hump; half-life 2.5-3.5 h | 20-60 min | about 1-2 h; Tmax 1.9 h (0.3-4.4) in children, adults similar | 2-4 h (IR class 3-6 h) | 0.3-1 / 1-1.5 / 2.5-3 / 3-5 | 35 min / 75 min | High-fat meal: AUC up about 25%, Cmax up about 27%; median peak 2.5 h fed vs 3 h fasted | No time shift; exposure note only (derived) | [Q1 Formulation profiles; Priors for the app's model] |
| Methylphenidate IR as booster after a long-acting dose | Same product, own learned curve; overlaps the long-acting tail; acute tolerance may blunt it | 20-60 min | about 1-2 h | 2-4 h | 0.3-1 / 1-1.5 / about 2.5 / 3-4 | 35 min / 60 min | As above | As above | [Q5 Boosters; Priors for the app's model] |
| Dexamfetamine IR (Aspen Dexamfetamine 5 mg scored; US Dexedrine, Zenzedi), morning or booster | IR tablet; single hump; half-life 9-11 h (7-34 h by urine pH) yet effect much shorter | 20-60 min (one secondary source: 30-45 min) | about 3 h | 3-6 h | 0.3-1 / 1-1.5 / 3.5-4 / 4-6 | 35 min / 75 min | Not studied; acidifiers (vitamin C, fruit juice) lower levels, alkalinisers (sodium bicarbonate, antacids) raise them | No fixed shift; pH flags learned as exploratory | [Q1 Formulation profiles; Q3 Individual variability; Priors for the app's model] |
| Mixed amphetamine salts IR (US Adderall IR; not in AU) | IR d and l salts; half-life 9.77-11 h (d), 11.5-13.8 h (l) | Not given | about 3 h, both isomers | Not given | Reuse dexamfetamine IR row (derived) | 35 min / 75 min (derived) | Not studied | pH flags exploratory | [Q1 Formulation profiles] |
| Methylphenidate SR (US Ritalin-SR; not listed in AU 2026) | Wax-matrix tablet; single broad hump; swallowed whole | Not given | 4.7 h (1.3-8.2) in children | about 8 h | unknown / unknown / unknown / 8 (derived) | unknown | Not given | None | [Q1 Formulation profiles; Q1 Summary table] |
| Ritalin LA (AU and US; UK Medikinet XL similar 50:50) | SODAS beads 50% IR : 50% enteric-coated delayed; bimodal, peaks about 4 h apart; half-life about 3.5 h adults (1.3-7.7) | about 0.5-1 h expected from IR beads; one secondary source says about 2 h (conflict) | Peak 1 at 1-3 h; peak 2 at about 5-6 h; trough 4-4.5 h | 6-8 h | 0.5-1.5 / 1.5-2 / 6-7 / 7-9; possible dip 4-4.5 | 45 min / 90 min | High-fat meal: longer lag, variable peak delays, peak 2 about 25% lower; applesauce no effect; 40% alcohol released 98% of the dose in the first hour | High-fat: widen kicks-in band, draw hump 2 at 75% height, no fixed shift (derived) | [Q1 Formulation profiles; Q3 Individual variability; Priors for the app's model] |
| Concerta and OROS-type generics (AU Concerta, Methylphenidate-Teva XR; UK Concerta XL) | Osmotic pump with 22% IR overcoat (22:78); ascending: small early maximum at about 1-2 h, then rising to a late peak; half-life about 3.5 h; no accumulation | 1.5 h (SKAMP) | Early maximum about 1-2 h; Tmax 6-10 h (adults, 18 mg: 6.8 ± 1.8 h); NZ data sheet peak 6-8 h | 12 h (paediatric lab) | 1-2 / about 2 (moderate, strengthening to a peak at 6-8) / 10-11 / 12-14 | 30 min to window start, then gradual rise to peak at about 7 h / 150 min | None: fasted, normal breakfast and high-fat breakfast equal; alcohol up to 40% did not raise first-hour release | Shift 0 | [Q1 Formulation profiles; Q6 Lab-school curves; Priors for the app's model] |
| Dexmethylphenidate XR (US Focalin XR; not in AU) | SODAS 50:50; bimodal; half-life just over 3 h (2-4.5) | Not given | Peak 1 at 1.5 h (1-4); peak 2 at 6.5 h (4.5-7) | 12 h or more (paediatric lab) | 0.5-1.5 / about 1.5 / 10-11 / 12 or more; possible dip about 4 | 30 min / 150 min (using a derived 13 h Lasts default) | High-fat: variable delay of peak 1; peak 2 about 25% lower | As Ritalin LA (derived) | [Q1 Formulation profiles; Priors for the app's model] |
| Lisdexamfetamine (AU Vyvanse capsules 20-70 mg; US capsules and chewable) | Prodrug converted mainly by red blood cells, rate-limited; smooth single broad peak with a sustained plateau; d-amphetamine half-life 10-11.3 h adults | about 1.5-2 h (significant from 2 h in adults, 1.5 h in children) | d-amphetamine Tmax 3.8 h adults fasted; 4.4 h chewable; 4.6 h (2.5-8.4) in one healthy-adult study | 13-14 h (adults significant from 2 h to 14 h, the last time tested) | 1-2 fasted / 3-4 / 10-12 / 12-15 | 120 min / 150 min | Food delays Tmax about 1 h, AUC and Cmax unchanged (capsule); high-fat lowers chewable exposure 5-7% | Meal or high-fat meal: shift every anchor +1 h (derived) | [Q1 Formulation profiles; Q6 Lab-school curves; Priors for the app's model] |
| Mixed amphetamine salts XR (US Adderall XR; not in AU) | Two-pulse beads (IR plus delayed), d:l 3:1; pulses smoothed by long half-life (about 10 h d, 12-13 h l) | Not given | about 7 h (IR about 3 h) | Not given (XR class 8-12 h) | 1-2 fasted / 3-4 / 9-10 / 10-12 | 120 min / 90 min | Food delays Tmax 2.5 h (d) and 2.7 h (l) | Meal or high-fat meal: shift every anchor +2.5 h (derived) | [Q1 Formulation profiles; Priors for the app's model] |
| Clonidine IR as wind-down (AU Catapres, off-label; US Kapvay ER, Onyda XR) | Alpha-2 agonist; single hump; half-life 12-16 h | 30-60 min | 60-90 min | 4-8 h | 0.5-1 / n.a. / n.a. / 4-8; peak 1-1.5 | 30 min to peak / n.a. | Not given | None | [Q1 Formulation profiles] |
| Atomoxetine (AU generic, brand unverified; US Strattera) | NRI capsule; no daily window | Weeks (AU: may take 2-3 months) | 1-2 h | Continuous at steady state | None | n.a. | High-fat: Cmax 37% lower, Tmax 3 h later, AUC unchanged | None | [Q1 Formulation profiles; Q1 Summary table] |
| Guanfacine XR (AU guanfacine; US Intuniv) | Alpha-2A agonist ER tablet; no daily window; possible sedation near Tmax | Weeks (trials ran 5-15 weeks) | about 5 h (children and adolescents); half-life about 18 h | Continuous | None | n.a. | High-fat: Cmax up about 75%, AUC up about 40% | None | [Q1 Formulation profiles] |
| Viloxazine ER (US Qelbree; not in AU) | NRI modulator ER capsule; no daily window; half-life 7.02 ± 4.74 h; steady state in 2 days | Weeks | 5 h (3-9) | Continuous | None | n.a. | High-fat: Tmax about 2 h later, Cmax 9% lower | None | [Q1 Summary table; Q2 New medicines 2023-2026] |
| Centanafadine (US Simtriyo, FDA approved 24 Jul 2026; not in AU) | IR, ER and DR bead capsule; NDSRI; intraday effect unknown | Separation from placebo by week 1 | 5 h; half-life 5.2 h | Unknown | None: treat as unknown | n.a. | High-fat: Cmax up 29%, Tmax 1.5 h later, AUC unchanged | None | [Q2 New medicines 2023-2026; Priors for the app's model] |

- Lab-only windows for optional US methylphenidate entries (no priors row in the source): Quillivant XR (ER suspension) significant at 0.75, 2, 8, 10 and 12 h; Aptensio 1-12 h; multilayer-release methylphenidate in adults 1-16 h. Use them as typical bands only, with the other anchors set by the user (derived). [Q6 Lab-school curves]
- Early-strong versus late-strong: higher-IR products (Equasym XL 30:70; Metadate CD about 30% IR) give more effect at 0-4 h. Concerta (22:78) gives more at 8-12 h. In COMACS, Metadate CD was stronger at 1.5-4.5 h, equal at 6-7.5 h, and Concerta stronger at 12 h. This sets the display shape and planner placement. [Q6 Lab-school curves]
- Group-mean onset (1.5-2 h for long-acting products) is the first time point tested. Individual onset is probably earlier for bead products (IR fraction) and later after food. Keep kicks-in bands wide on the early side for bead products. [Q6 Lab-school curves]
- Half-life is not a duration prior for amphetamines: d-amphetamine half-life is about 10 h, yet IR effect lasts about 3-6 h, because of acute tolerance. [Q1 Formulation profiles]
- How the priors were built (the rule for adding new catalogue entries): onset is the first lab time point or reported onset, moved earlier for IR-bead fractions. Plateau start is about Tmax for IR products, the first peak for bead products, and about 3-4 h for lisdexamfetamine. Wear-off start is the reported duration minus about 1-2 h. Full wear-off is the reported duration plus an allowance for right-censoring. [Priors for the app's model]

### 6.2 Slider defaults and allowed ranges

Defaults are midpoints of the prior ranges, rounded to 5 min for Kicks in and 15 min for the other sliders (derived). Sliders hold fasted or light-meal values; food rules apply per logged dose.

| Formulation and role | Kicks in: default (typical band) | Window start: default (band) | Window end: default (band) | Lasts: default (band) | Extra markers | Can sleep after: never pre-filled; reference shown | Bounds class | Source |
|---|---|---|---|---|---|---|---|---|
| Methylphenidate IR, morning | 40 min (20-60 min) | 1 h 15 min (1 h-1 h 30 min) | 2 h 45 min (2 h 30 min-3 h) | 4 h (3-5 h) | None | Full wear-off 3-5 h; product rule: last dose before 6 p.m. | Short-acting | [Priors for the app's model; Q5 Boosters] |
| Methylphenidate IR, booster | 40 min (20-60 min) | 1 h 15 min (1 h-1 h 30 min) | 2 h 30 min (about 2 h 30 min) | 3 h 30 min (3-4 h) | None | 3-4 h; last dose before 6 p.m. | Short-acting | [Priors for the app's model; Q5 Boosters] |
| Dexamfetamine IR, morning or booster | 40 min (20-60 min) | 1 h 15 min (1 h-1 h 30 min) | 3 h 45 min (3 h 30 min-4 h) | 5 h (4-6 h) | None | 4-6 h; product rule: missed dose not later than 6 h before bedtime | Short-acting | [Priors for the app's model; Q5 Boosters; Q9 Missed-dose guidance] |
| Mixed amphetamine salts IR (US) | As dexamfetamine IR (derived) | As dexamfetamine IR | As dexamfetamine IR | As dexamfetamine IR | None | Product rule: doses 4-6 h apart, none late in the evening | Short-acting | [Q1 Formulation profiles; Q5 Boosters] |
| Ritalin LA | 1 h (30 min-1 h 30 min) | 1 h 45 min (1 h 30 min-2 h) | 6 h 30 min (6-7 h) | 8 h (7-9 h) | Possible dip 4 h-4 h 30 min | 7-9 h; morning dosing | Long-acting | [Priors for the app's model; Q1 Formulation profiles] |
| Focalin XR (US) | 1 h (30 min-1 h 30 min) | 1 h 30 min (about 1 h 30 min) | 10 h 30 min (10-11 h) | 13 h (12 h or more; derived default) | Possible dip about 4 h | 12 h or more; morning dosing | Long-acting | [Priors for the app's model] |
| Concerta and OROS generics | 1 h 30 min (1-2 h) | 2 h (about 2 h) | 10 h 30 min (10-11 h) | 13 h (12-14 h) | Strongest 6-8 h; peak marker 7 h | 12-14 h; once daily in the morning | Long-acting | [Priors for the app's model; Q6 Lab-school curves] |
| Vyvanse | 1 h 30 min fasted (1-2 h); 2 h 30 min after a meal | 3 h 30 min (3-4 h) | 11 h (10-12 h) | 13 h 30 min (12-15 h) | A meal shifts every anchor +1 h | 12-15 h; avoid afternoon or evening | Long-acting | [Priors for the app's model; Q9 Missed-dose guidance] |
| Adderall XR (US) | 1 h 30 min fasted (1-2 h); 4 h after a meal | 3 h 30 min (3-4 h) | 9 h 30 min (9-10 h) | 11 h (10-12 h) | A meal shifts every anchor +2 h 30 min | 10-12 h; morning dosing | Long-acting | [Priors for the app's model] |
| Ritalin-SR (US) | Unset | Unset | Unset | 8 h (about 8 h) | None | about 8 h | Long-acting | [Q1 Formulation profiles] |
| Clonidine IR, wind-down | 45 min (30-60 min) | n.a. | n.a. | 6 h (4-8 h) | Peak marker 1 h 15 min (1 h-1 h 30 min) | Not shown for wind-down | Wind-down | [Q1 Formulation profiles; Product brief] |
| Atomoxetine, guanfacine XR, viloxazine, clonidine maintenance | No sliders | No sliders | No sliders | No sliders | Optional side-effect time notes | Not shown | None | [Q1 Formulation profiles] |
| Centanafadine, Mydayis, Jornay PM, Azstarys, dexmethylphenidate IR, other or imported | Unset; user must set | Unset | Unset | Unset | None | Unset | By chosen role | [Priors for the app's model; Q2 New medicines 2023-2026] |

- Short-acting bounds (derived): Kicks in 0-2 h in 5 min steps; Window start 0-4 h; Window end 30 min-8 h; Lasts 1-8 h; 15 min steps. They cover onset 20-60 min, methylphenidate IR Tmax up to 4.4 h and durations of 2-6 h. [Q1 Formulation profiles; Priors for the app's model]
- Long-acting bounds (derived): Kicks in 0-5 h in 5 min steps; Window start 0-8 h; Window end 1-20 h; Lasts 2-20 h; 15 min steps. They cover Adderall XR onset of up to about 4.5 h after food, lisdexamfetamine effect right-censored at 14 h, and adult multilayer methylphenidate effect to 16 h. [Q1 Formulation profiles; Q6 Lab-school curves]
- Wind-down bounds (derived): Kicks in 0-3 h in 5 min steps; Lasts 1-12 h in 15 min steps. They cover clonidine IR onset 30-60 min and duration 4-8 h. [Q1 Formulation profiles]
- Can sleep after (derived): 0-24 h in 15 min steps for every stimulant role. No ordering constraint against Lasts, because a person may sleep before full wear-off. [Product brief; Q5 Boosters]

### 6.3 Curve model and how doses combine

- Structure from the source: a per-product parametric effect curve with lag, rise, one or two humps, plateau and decay, plus product-specific food shifts, an optional pH covariate for amphetamines, an optional menstrual-phase covariate, a sleep-debt flag, each brand or generic treated as a new product, the booster as a separately learned additive IR curve, and heart rate as a weak onset signal only. [Priors for the app's model]
- Planning curve per dose (derived): a trapezoid E(t) from that medication's values. E = 0 before Kicks in, rises linearly to 1.0 at Window start, holds 1.0 to Window end, and falls linearly to 0 at Lasts. Food shifts move every anchor. [Priors for the app's model; Q3 Individual variability]
- Display template (derived): the product shape is drawn inside the trapezoid. Bimodal products get a dip notch (Ritalin LA 4-4.5 h, Focalin XR about 4 h) and, after a high-fat meal, a second hump at 75% height. Concerta is ascending: drawn at about 60% at Window start, rising to 100% at about 7 h. The 60% figure is a visual default with no source number. Vyvanse is a flat broad plateau. [Q1 Formulation profiles; Q3 Individual variability]
- Combination rule (derived): E_total(t) = min(1, sum of every active dose's E(t)). Productive time is where the sum is at least 1.0. A single dose's productive window is therefore exactly its own window, and the tail of one dose plus the ramp of the next can bridge a gap, which matches the source's "additive IR curve added to the tail". [Q5 Boosters; Priors for the app's model]
- Gaps (derived): an unproductive gap is any stretch of at least 15 min between productive intervals within waking hours. Shorter stretches merge into the surrounding window. A dip marker becomes a gap only once learned (section 6.5). [Product brief; Q1 Formulation profiles]
- Wind-down (derived): productive intervals are cut at wind-down dose time + wind-down Kicks in (clonidine IR default 45 min). The planning curve ignores the wind-down dose's own E(t). [Product brief; Q1 Formulation profiles]
- Clipping (derived): productive intervals are clipped to the day type's wake time and bedtime. [Product brief]
- Worked check with defaults: dexamfetamine IR at 07:00 (window 08:15-10:45, Lasts 12:00) plus Vyvanse fasted at 07:30 (Kicks in 09:00, window 11:00-18:30) gives a sum of 1.875 at 10:45 and 1.8 at 11:00, so there is no gap. A dexamfetamine booster at 16:30 (window 17:45-20:15) keeps the window going to 20:30, where the falling booster and Vyvanse tails sum to 1.0. A clonidine IR dose at 19:00 cuts it at 19:45. [Q5 Boosters; Priors for the app's model]
- Rebound is not a default model component. It is kept as an optional separate rating (paediatric trial: rebound in 3.4% on lisdexamfetamine vs 9.7% on placebo; emotional lability scores 4.2-9.0 in rebounders vs 1.3-1.6 in responders). [Q4 Wear-off and rebound]

### 6.4 Covariates

- Food (logged on every dose): Vyvanse +1 h (capsule; AUC unchanged); Adderall XR +2.5 h (d), +2.7 h (l); Ritalin LA and Focalin XR variable lag with the second peak about 25% lower after a high-fat meal; Concerta 0. Derived mapping: shifts apply to Meal and High-fat meal; the bead-product rules apply to High-fat meal only; Nothing yet and Light snack are the baseline. [Q3 Individual variability; Priors for the app's model]
- Urinary and GI pH, amphetamines only: exploratory, with no fixed shift. Evidence: modelled amphetamine AUC 1,325 (alkaline) vs 692 (normal, pH 6.5) vs 361 (acidic) µg·h/L, about 3.7-fold; d-amphetamine half-life 7 h (acidic urine) to 34 h (alkaline); urinary recovery 1-75%. Derived: the learned coefficient starts at zero and is not used in forecasts until at least 5 flagged dosing days exist. [Q3 Individual variability]
- Cycle phase, optional: amphetamine subjective effect is greater in the follicular than the luteal phase (13 women and 7 men on 15 mg d-amphetamine; within the follicular phase, stimulation correlated with oestradiol r = +0.55 to +0.78 and inversely with progesterone r = -0.66 to -0.68). Expect weaker or shorter windows in the late luteal phase for some users. Methylphenidate evidence is thin, so its prior is centred on no effect (derived). [Q3 Individual variability]
- Sleep debt (derived threshold): flag a day when last night's sleep was under 6 h, or 1.5 h or more below the user's 14-day median. Flagged days' check-ins count at half weight in learning, and the day's copy makes no readiness claim. Basis: stimulants mimicked adequate-sleep brain signatures and masked sleep loss (5,795 children plus 5 adults). [Q3 Individual variability; Priors for the app's model]
- Heart rate, optional: weak onset or dose-taken signal only, meaning a rise within about 1-3 h of a dose. It is never an offset signal, because heart rate stayed raised up to 24 h after lisdexamfetamine or d-amphetamine (lag without tolerance). Starting medication raised heart rate by 5.43 bpm, then by 1.31 bpm per 4-week period, measured over weeks rather than hours. Apple Watch had the lowest error of the wrist devices (2.0%). Across devices, median error was 1.8% cycling and 5.5% walking, and error rose in males, at higher BMI, with darker skin and while walking. Derived: use only samples with no steps in the previous 10 min, and give heart rate low weight. [Q7 N-of-1, EMA and wearables]
- Weeks-level signals not used intraday (derived): in 176 adults starting medication, sleep onset moved about 10 min later per 4-weekly time point, activity rose by 99 steps per hour and rest-activity transitions fell. Expectancy effects are a caveat. [Q7 N-of-1, EMA and wearables]
- Methylphenidate heart rate may track the effect more closely (half-life about 3.5 h), but that is unverified, so no heart-rate offset for any product in the first version (derived). [Q7 N-of-1, EMA and wearables]
- No default term for caffeine, time of day, chronotype or chronic tolerance, because none has a quantified effect in the source. [Q3 Individual variability; Priors for the app's model]

### 6.5 Learning and update strategy

- Priors are deliberately wide, weakly informative, and updated quickly by the user's own check-ins. They show as "typical for this formulation" only until personal data overrides them. [Priors for the app's model]
- Prior strength (derived): the catalogue prior counts as 2 dosing days of data, so after 5 dosing days with check-ins personal data carries about 71% of the weight. [Priors for the app's model]
- Caption switch (derived): a product and role moves from "Typical for this formulation" to "Learned from your check-ins" after at least 5 dosing days with at least 3 answered check-ins each. [Priors for the app's model; Scope note]
- Model form: a stable personal baseline plus daily modifiers. Lisdexamfetamine within-person PK variability is under 8%, against under 25% between people, so personal curves stabilise once learned, while food, sleep and cycle still vary day to day. [Priors for the app's model; Q1 Formulation profiles]
- Learning target: felt and functional effect, not plasma level. Felt wear-off usually comes before plasma decline, especially for amphetamines, and that is correct for scheduling. [Q3 Individual variability; Q8 Self-report validity]
- Booster: learned per product and role, separate from the morning IR curve, because a second closely spaced dose gives a smaller acute gain. No fixed attenuation factor is applied (derived). [Q5 Boosters; Priors for the app's model]
- Pooling (derived): learn first from days of the same day type (repeated same-condition days, the N-of-1 idea), then pool across day types for the same product and role. [Q7 N-of-1, EMA and wearables]
- Product switch: a new product prior that borrows partly from the previous product, plus a re-learning flag for about 1-2 weeks. Derived: borrow 50% of the user's learned offsets (personal minus catalogue) when the active ingredient is the same, and nothing when it differs. Show "Re-learning" for at least 7 and at most 14 days, or until the caption threshold is met again. Switches between formulations of the same medicine are the common case: NSW continuation-prescriber GPs may switch formulations of the same medicine, such as methylphenidate IR and MR, but not between medicines. [Q10 Australian specifics; Q5 Boosters]
- Switching back to a product used before reuses its stored learned curve (derived). [Q10 Australian specifics]
- Learned dip (derived): a Ritalin LA or Focalin XR dip becomes an unproductive gap once, on at least 3 dosing days, the check-in nearest the dip time scores at least 1 point below check-ins on both sides of it within the window. [Q1 Formulation profiles]
- Right-censoring: learned Lasts may exceed the prior's upper bound up to the slider maximum (20 h for long-acting), because lab durations stop at the last time measured (14 h for lisdexamfetamine in adults, 12 h for Concerta). [Q6 Lab-school curves]
- Recency (derived): weight check-ins with a 60-day half-life so slow drift can show. Chronic tolerance is unquantified in the source. [Priors for the app's model; Q3 Individual variability]
- Self-report bias: expectancy inflates reports, and SKAMP (observer-rated) shows slightly larger placebo effects than PERMP (objective maths output). When an objective probe result exists, store it next to the rating and use it as a second observation (derived). [Q8 Self-report validity; Q6 Lab-school curves]
- Non-stimulants: never learn a daily onset or offset window. At most, record side-effect timing the user logs, such as sedation around Tmax for alpha-2 agonists. [Q1 Formulation profiles]

### 6.6 Check-in scheduling

- Anchors per stimulant dose (derived): Kicks in, Window start, mid-window, Window end and Lasts, each jittered by a uniform ±20 min. [Q8 Self-report validity]
- Load (derived): at most 6 prompts a day, none between bedtime and wake time. When the cap bites, Kicks in and Window end prompts come first, because onset and wear-off timing are what the model learns. [Q8 Self-report validity]
- Lab schedules for reference and QA: COMACS SKAMP at 0, 1.5, 3, 4.5, 6, 7.5 and 12 h; adult lisdexamfetamine PERMP before the dose and at 2, 4, 8, 10, 12 and 14 h; paediatric lisdexamfetamine at 1.5, 2.5, 5, 7.5, 10, 12 and 13 h. [Q6 Lab-school curves]
- Re-learning (derived count): at least one prompt 7-12 h after a long-acting dose on each dosing day. [Q10 Australian specifics]
- Rebound check, if enabled (derived): offered within 60 min after the forecast Window end. [Q4 Wear-off and rebound]
- Objective probe: 30-60 s, reaction time or PERMP-like arithmetic, always optional. [Q8 Self-report validity]

### 6.7 Relog and duplicate guard (all derived unless cited)

- Relog interval per product and role: the label's minimum spacing where one exists (mixed amphetamine salts IR: 4 h, from "4-6 h intervals"). Otherwise, for short-acting products, the lower bound of the typical duration (methylphenidate IR 2 h, dexamfetamine IR 3 h, clonidine IR wind-down 4 h). For once-daily long-acting and maintenance products, any second log between wake time and bedtime, or within 12 h. [Q5 Boosters; Q1 Formulation profiles]
- The guard respects the user's scheduled daily count: atomoxetine may be once daily or split morning and late afternoon; methylphenidate IR and dexamfetamine IR are taken 2-3 times a day. Logging more doses of a product than the day type has slots triggers the same confirmation. [Q1 Formulation profiles]
- Any product logged twice within 10 min gets a "looks like a double tap" confirmation. [Q9 Missed-dose guidance]
- Every confirmation is neutral and never blocks: Log it, Edit earlier log, Cancel. Evidence basis: Vyvanse AU CMI says do not double up; atomoxetine says never more than the prescribed total daily amount in any 24 h; dexamfetamine AU CMI says skip a missed dose if the next is almost due. [Q9 Missed-dose guidance]

### 6.8 Late-log projection

- Trigger (derived): dose time + Lasts, or dose time + Can sleep after if set, later than the user's bedtime. Content: projected window end and bedtime, information only, no actions. The source allows this projection "as information only" and forbids prompting to take or skip. [Q9 Missed-dose guidance]

### 6.9 Evidence values kept for rationale, QA and catalogue review

- Methylphenidate half-life is about 3.5 h in adults (1.3-7.7) and about 2.5 h in children (1.5-5.0). OROS CL/F is 58% higher in adolescents than in children, and heavier people may have lower exposure at the same dose. [Q3 Individual variability]
- Lisdexamfetamine PK is linear from 50 to 250 mg in adults. Adderall IR PK roughly tripled from 10 to 30 mg. [Q3 Individual variability]
- In healthy adults, lisdexamfetamine 100 mg vs d-amphetamine 40 mg: lag 0.6 ± 0.6 h longer, Tmax 4.6 vs 3.3 h, same peak subjective ratings, clockwise hysteresis (acute tolerance) for subjective effect. [Q6 Lab-school curves]
- Adult lisdexamfetamine workplace study: 127 randomised, 103 completed, 30-70 mg; significant at every time point from 2 h to 14 h (P ≤ .0017); sustained plateau rather than a sharp peak; LS-mean PERMP difference 23.4 (95% CI 15.6-31.2). [Q6 Lab-school curves]
- Atomoxetine CYP2D6 poor metabolisers (about 7% of Caucasians, about 2% of African Americans): about 10 times AUC, about 5 times Cmax, half-life 21.6 h vs 5.2 h. Viloxazine poor metabolisers: Cmax 21% and AUC 26% higher. [Q3 Individual variability]
- N-of-1 service: 108 trials requested, 86 completed, 29 showed stimulant better than placebo. Adherence to trial conclusions fell from 69% at 3 months to 60% at 12 months. [Q7 N-of-1, EMA and wearables; Q8 Self-report validity]

## 7. Content and copy rules (tone, words to avoid, must-say / never-say)

- Tone (derived): neutral, factual, attributed and calm. The app describes; it never instructs about medication. [Scope note; Q9 Missed-dose guidance]
- Never say: any recommendation, calculation or conversion of a dose. The label conversion (10 mg IR twice daily equals 20 mg LA once daily) and AADPA dose-equivalence tables must not appear in logic or copy. [Scope note; Q1 Formulation profiles; Q10 Australian specifics]
- Never say: when to take any dose, including boosters. Only show times the user entered. [Q5 Boosters]
- Never say: take it, skip it, or wait after a late or missed dose. Projections are captioned "information only". [Q9 Missed-dose guidance]
- Must say: missed-dose content only as stored product text with its attribution (for example "From the Vyvanse Consumer Medicine Information"). Never generate, paraphrase or summarise it, including through Foundation Models. [Q9 Missed-dose guidance]
- Must say: timing rules as attributed facts, for example "Product information: last dose before 6 p.m.", never as the app's own instruction ("Don't take after 6 p.m."). [Q5 Boosters; Q9 Missed-dose guidance]
- Must say: "Typical for this formulation" on every prior-based value until personal data overrides it. Never use "prediction", "will", "guaranteed" or "accurate" for these values. [Priors for the app's model; Scope note]
- Must say, in an "About these estimates" sheet: the numbers come from label and study figures, mostly single-dose, fasted or paediatric studies; they are starting points that the user's check-ins replace; they are not clinical guidance. [Scope note; Priors for the app's model]
- Word pair: "wear-off" means the effect fading back to baseline; "rebound" means symptoms worse than baseline. Never use one for the other. [Q4 Wear-off and rebound]
- Never say or imply that effect equals readiness, alertness or being rested ("you're good to go"), especially on sleep-debt days. [Q3 Individual variability; Q8 Self-report validity]
- Non-stimulants: say the effect "builds over weeks". Never say "kicks in" or "wears off" for today. [Q1 Formulation profiles]
- Wind-down words to avoid (derived list): "sleep medication", "sleeping pill", "sleep aid", "sedative", "sedating", "for sleep", "helps you sleep", "knocks you out". The source describes clonidine IR at bedtime as sedating and used for sleep onset, which is exactly the framing the UI must avoid. Use "wind-down". [Q1 Formulation profiles; Product brief]
- Never advise on interactions or intake conditions: food timing (for example the label's 30-45 min before meals for methylphenidate IR, or guanfacine not with a high-fat meal), alcohol (Ritalin LA dose dumping), vitamin C and fruit juice, antacids and PPIs, caffeine, CYP2D6 inhibitors with atomoxetine (fluoxetine, paroxetine, quinidine), CYP3A4 with guanfacine, CYP1A2 with viloxazine. [Q1 Formulation profiles; Q2 New medicines 2023-2026; Q3 Individual variability]
- Never advise on stopping or tapering. Guanfacine and clonidine carry a rebound hypertension risk on abrupt stop, and the guanfacine label's taper (no more than 1 mg every 3-7 days) is prescriber content that may appear only as stored product text. [Q1 Formulation profiles; Q9 Missed-dose guidance]
- Never suggest a dose change by cycle phase. Premenstrual 30-50% increases come from an uncontrolled 9-person case series. [Q3 Individual variability]
- Never put numbers on unquantified effects (acidic drinks, antacids, caffeine, time of day). Logging prompts are neutral past-tense questions, for example "Juice or vitamin C around this dose?" (derived wording). [Q3 Individual variability]
- Never say heart rate shows that a medication has kicked in or worn off. [Q7 N-of-1, EMA and wearables]
- Use "focus" or "felt effect" in the main UI, not "blood level", "plasma", "concentration" or "half-life" (derived). The model schedules for felt and functional effect. [Q3 Individual variability; Q8 Self-report validity]
- Brand-switch copy: "Re-learning your pattern for this product". Never claim that a generic is weaker or different. [Q10 Australian specifics]
- No imperative or future-tense instruction about taking medication (take, skip, double, increase, reduce, switch, stop, wait) outside attributed product text. Past-tense questions ("When did you take it?") are allowed (derived). [Scope note; Q5 Boosters; Q9 Missed-dose guidance]
- Missing-text fallback (derived wording): "No missed-dose text on file for this product. Your pharmacist or prescriber can help." [Q9 Missed-dose guidance]
- Rebound check copy is optional and plain, with no clinical terms such as "emotional lability" (derived). [Q4 Wear-off and rebound]

## 8. Accessibility and neurodivergent-design requirements

- Check-ins take one tap on a 1-5 scale, with no typing and no recall of past times. [Q8 Self-report validity]
- The objective probe is optional, capped at 60 s (30-60 s), and skippable without losing the check-in. [Q8 Self-report validity]
- Food is the only covariate asked on every dose (one tap, defaulting to "not recorded"). pH flags, cycle phase, sleep, heart rate and the rebound check are opt-in and off by default (derived). [Q3 Individual variability; Q4 Wear-off and rebound]
- Prompt load control (derived): a cap of 6 a day, quiet hours from bedtime to wake time, "pause for today", and jitter kept to ±20 min so prompts stay roughly predictable. [Q8 Self-report validity]
- Curves never rely on colour alone. Ramps, dips, gaps and wind-down cuts carry text labels or patterns (derived). [Q1 Formulation profiles]
- Each day plan has a VoiceOver summary (derived), for example "Productive 09:45 to 14:30. Gap 14:30 to 16:45. Productive 16:45 to 18:00. Possible dip around 12:00." [Q1 Formulation profiles; Q5 Boosters]
- Uncertainty is shown as a shaded band plus plain words ("typical range"), never as probabilities or percentages (derived). [Priors for the app's model]
- Late-dose, duplicate and re-learning messages are calm and one line long, with no red warning styling (derived). [Q9 Missed-dose guidance; Q10 Australian specifics]
- Sliders support the VoiceOver adjustable action in their step sizes (5 or 15 min) and speak values in hours and minutes (derived). [Priors for the app's model]
- Dynamic Type up to accessibility sizes for slider labels and times; Reduce Motion swaps curve animations for fades; times follow the device's 12 or 24 hour setting (derived). [Product brief]
- Logging needs as few steps as possible: time defaults to now and food is one tap (derived). Momentary ratings avoid the recall burden that retrospective onset questions create. [Q8 Self-report validity]

## 9. Privacy, security and safety requirements (build-relevant only)

- No dose recommendation, conversion or timing suggestion anywhere, including generated text. Enforce with Foundation Models instructions plus a post-generation filter that drops any output with dose amounts, dose times or medication actions. AC: a prompt test suite with medication context yields zero filtered-pattern matches in shipped output (derived). [Scope note; Q5 Boosters; Q9 Missed-dose guidance]
- Missed-dose and timing texts are immutable catalogue data with source and date, rendered unchanged, and changed only by a catalogue release. [Q9 Missed-dose guidance]
- The duplicate-log confirmation never blocks logging, because the log must reflect what happened (derived). [Q9 Missed-dose guidance]
- Heart rate never auto-logs a dose and never ends a window (derived). [Q7 N-of-1, EMA and wearables]
- Morning dosing is never assumed, and evening logs raise no warning (clinician-directed evening doses exist). [Priors for the app's model; Q5 Boosters]
- Unknown products get no fabricated defaults. [Priors for the app's model]
- Non-stimulants show no daily window, so the app never implies a same-day effect. [Q1 Formulation profiles]
- Sensitive data (derived): logs include Schedule 8 medicines (dexamfetamine, lisdexamfetamine and methylphenidate need prescriber authority in NSW), cycle phase, sleep and heart rate. Store on device with complete file protection, send no health or medication fields to analytics, and export only on explicit user action. [Q10 Australian specifics; Q3 Individual variability; Q7 N-of-1, EMA and wearables]
- HealthKit (derived): request only heart rate, sleep and cycle data, read-only, each optional, and keep the app fully usable without them. [Q7 N-of-1, EMA and wearables; Q3 Individual variability]
- Dose-entry typo check (derived; see section 11): if a typed dose is not a catalogue strength or a sum of strengths, ask "Check the dose you entered" without quoting any maximum. [Q1 Formulation profiles]
- Label and authority maxima (dexamfetamine AU CMI 40 mg a day in two divided doses; NSW specialist class authority up to dexamfetamine 50 mg, lisdexamfetamine 70 mg and methylphenidate 108 mg a day) are not used for warnings or advice unless product and clinical review approve (derived). [Q1 Formulation profiles; Q10 Australian specifics]

## 10. Edge cases, failure modes and their mitigations

- Brand or generic switch mid-course (for example Concerta to Methylphenidate-Teva XR, or OROS to Ritalin LA during a shortage) → new product record, 50% borrowing, "Re-learning" for 7-14 days, late-afternoon check-ins. [Q10 Australian specifics]
- A generic OROS product may differ at 7-12 h despite equal AUC and Cmax (FDA moved two generic Concerta products from AB to BX in Nov 2014) → brand on every log and curves learned per brand. [Q10 Australian specifics]
- Section 19A import or overseas product missing from the catalogue → "Other or imported" slot with an unknown shape and user-set values. [Q2 New medicines 2023-2026; Q10 Australian specifics]
- Long-acting dose logged late → information-only projection against bedtime; no prompt. [Q9 Missed-dose guidance]
- Evening long-acting dosing (Jornay PM) or a clinician-directed evening dose → allowed. Windows that cross midnight belong to the day of the dose (derived). [Priors for the app's model; Q5 Boosters]
- High-fat meal with a bead product → variable lag, so widen the kicks-in band and draw the second hump at 75% rather than shifting a fixed amount. [Q3 Individual variability]
- Sleep-deprived day → sleep-debt flag, half weight, no readiness copy. [Q3 Individual variability]
- Weaker window in the late luteal phase → optional covariate explains it; no advice. [Q3 Individual variability]
- Urinary pH extremes (d-amphetamine half-life 7-34 h; AUC about 3.7-fold) → amphetamine offsets vary widely, so keep Lasts bands wide and never use half-life as a duration prior. [Q3 Individual variability]
- Booster taken close to the morning dose → smaller gain from acute tolerance, handled by learning the booster separately. [Q5 Boosters]
- Same product taken more than once by design (atomoxetine split dose; IR 2-3 times a day) → the relog guard uses the scheduled count, not "once a day". [Q1 Formulation profiles]
- Accidental double tap → confirmation for any repeat within 10 min (derived). [Q9 Missed-dose guidance]
- Durations longer than the literature → learned Lasts may pass the prior band up to the slider maximum. [Q6 Lab-school curves]
- Conflicting sources (Ritalin LA onset; Concerta IR fraction) → the catalogue uses the label value and records the conflict in provenance. [Q1 Formulation profiles]
- Clonidine used as maintenance vs as an IR wind-down dose → the chosen role decides the model: no window for maintenance, a wind-down hump for the evening IR role. [Q1 Formulation profiles; Product brief]
- Non-stimulant user checks in anyway → check-ins are stored but no window is drawn. Only side-effect time notes are summarised. [Q1 Formulation profiles]
- No missed-dose text for a product → neutral fallback text, never generated text. [Q9 Missed-dose guidance]
- Vyvanse chewable vs capsule → separate products (d-amphetamine Tmax 4.4 h vs 3.8 h). AU has capsules only. [Q1 Formulation profiles]
- Vyvanse contents mixed into orange juice (the label allows yoghurt, water or orange juice) while the acidic-drink flag exists → the flag stays exploratory and no conflict message is shown (derived). [Q1 Formulation profiles; Q3 Individual variability]
- Alcohol near a Ritalin LA dose (98% released in the first hour at 40% alcohol) → no advice. The user can mark the day as unusual to keep it out of learning (derived). [Q1 Formulation profiles]
- Product approved but not dispensable (centanafadine as of August 2026) → catalogue status shown, curve unknown, user-set values. [Q2 New medicines 2023-2026]
- Heart rate raised all day on amphetamines → never an offset signal. Wrist heart-rate error is higher while walking (median 5.5% across devices) → use only resting samples (derived). [Q7 N-of-1, EMA and wearables]
- Few or no check-ins → the "Typical for this formulation" caption stays and learning is never claimed (derived). [Priors for the app's model]
- Expectancy or placebo inflation in self-report → optional objective probe, repeated same-condition days, uncertainty shown. [Q8 Self-report validity; Q7 N-of-1, EMA and wearables]
- Time-zone travel → doses stored with their time zone; clock-based product rules (18:00) use the current local time (derived). [Q5 Boosters]
- Users under 18 → the priors are adult. Children clear methylphenidate faster (half-life about 2.5 h) and adolescents have 58% higher OROS clearance than children. Whether to support this group is open (section 11). [Priors for the app's model; Q3 Individual variability]

## 11. Open questions / dependencies

- TGA PIs were not accessed (Ritalin LA, Concerta, Vyvanse, dexamfetamine, atomoxetine, Intuniv), so AU-specific wording and durations are unverified. Check them against the TGA PIs before launch. [Scope note; Q1 Formulation profiles]
- AU CMI missed-dose texts for Concerta, Ritalin LA and Ritalin 10 were not retrieved. [Q9 Missed-dose guidance]
- Permission to reproduce CMI and FDA label text verbatim in the app, and who maintains it (derived). [Q9 Missed-dose guidance]
- Ritalin LA onset is not in a primary label, and secondary sources conflict (IR beads imply 0.5-1 h; one source says about 2 h). [Q1 Formulation profiles]
- AU brand names and adult PBS status for atomoxetine and guanfacine are unverified. Full AU strength lists (Concerta beyond 18, 36, 54 mg; Ritalin LA; atomoxetine; guanfacine; clonidine) are needed for strength chips. [Q1 Formulation profiles]
- Mydayis adult duration (widely reported up to 16 h), Jornay PM and Azstarys PK are unverified, so these entries ship with no defaults. [Q1 Formulation profiles; Priors for the app's model]
- Centanafadine's intraday duration is unknown and its DEA scheduling was pending. [Q2 New medicines 2023-2026; Priors for the app's model]
- Whether AU generic OROS products (Methylphenidate-Teva XR and others) match Concerta over 7-12 h is unknown, and no TGA equivalent of the FDA action was found. [Q10 Australian specifics]
- There are no adult onset or duration studies for Ritalin LA, Concerta or dexamfetamine IR, so those priors lean on paediatric or PK data. [Q6 Lab-school curves; Priors for the app's model]
- Effects of caffeine, time of day, chronotype, chronic tolerance, acidic drinks at dose time, and PPIs or antacids on lisdexamfetamine are unquantified. Should the app log caffeine at all? [Q3 Individual variability; Priors for the app's model]
- No adult rebound prevalence or timing data exist in the source. [Q4 Wear-off and rebound]
- Self-reported timing has not been validated against objective measures in adults. Apple Watch heart rate or HRV has not been validated as a within-day marker. Within-day movement and phone-use proxies are unvalidated. The HRV meta-analysis was not opened. [Q7 N-of-1, EMA and wearables; Q8 Self-report validity]
- There is no AADPA booster guideline and no adult study of booster onset or overlap with long-acting tails. [Q5 Boosters]
- The TGA Vyvanse investigation pages were not opened, and new methylphenidate generics or strengths registered in 2023-2026 are unknown. [Q2 New medicines 2023-2026]
- UK SmPCs (Elvanse, Equasym XL, Medikinet XL) were not opened, so UK entries rest on ratios only. [Q1 Formulation profiles]
- Derived values that need sign-off: slider bounds and rounding; "Can sleep after" never pre-filled; productive threshold (sum of 1.0); 15 min minimum gap; food shift applied to every anchor rather than onset only; relog intervals; check-in cap and jitter; the 5-day by 3-check-in learning threshold; 50% borrowing; 7-14 day re-learning; sleep-debt threshold; 60-day recency; the 60% early Concerta display level. [Priors for the app's model]
- Should any dose plausibility check exist, and may label or authority maxima ever be referenced? [Q1 Formulation profiles; Q10 Australian specifics]
- Are dose reminders allowed, and how are they worded so they never prompt taking? Is a heart-rate "possible unlogged dose" prompt acceptable? [Q9 Missed-dose guidance; Q7 N-of-1, EMA and wearables]
- Should the app read or write medication and dose records through HealthKit, if the target iOS version supports it? (derived) [Q7 N-of-1, EMA and wearables]
- Age scope: the priors are adult, so are under-18 users supported, and if so with which priors? [Priors for the app's model; Q3 Individual variability]
- For people who take long-acting products in the evening, should the day boundary follow the wake and sleep cycle rather than midnight? (derived) [Priors for the app's model]
