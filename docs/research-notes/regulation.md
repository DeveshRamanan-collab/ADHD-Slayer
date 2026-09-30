# Regulation, privacy and safety: build requirements

Source: /Users/deveshramanan/Downloads/regulation_privacy_safety.md (research current to 28 Sep 2026; the source says it is not legal advice).

Citation key: §1 TGA (Australia) · §2 FDA (US) · §3 US privacy and enforcement · §4 UK MHRA and EU · §5 Australian privacy law and NZ · §6 App Store and HealthKit · §7 Medication safety design · §8 LLM risks and provider policies · §9 Liability, disclaimers and terms · §10 Synthesis (Product rules #1 to #32, Claims language). "Cited Findings" means a quoted rule or fact; "Inferences" means the source's own reasoning; "Derived" means this file combines the cited points rather than the source stating it outright; "Not covered in source" means a gap. [LAWYER] marks items the source says a lawyer must confirm.

## 1. The "not a medical device" screen: required content, forbidden content, placement, acknowledgement, plus a draft of the exact on-screen text

**Required content**

- States the purpose in one plain sentence: the app plans the day around the hours the person usually feels most focused, based on their own check-ins. Test: the sentence mentions check-ins and contains no medication-effect words. [§10 Synthesis, Product rules #4 and Claims language; §1 TGA, Takeaway]
- States that the app is not a medical device, gives no medical advice, diagnosis or treatment, and does not replace a doctor, prescriber or pharmacist. [§9 Liability, Inferences]
- States that the app never tells anyone when or how much medication to take. [§9 Liability, Inferences]
- Tells the person to take medication as prescribed and follow the label; this also satisfies the requirement that onboarding says the app is for people using medication as prescribed. [§9 Liability, Inferences; §7 Medication safety, Inferences]
- Carries Apple's 1.4.1 reminder with both parts: keep seeing a doctor alongside the app, and check with a doctor or pharmacist before making medication decisions. [§6 App Store and HealthKit, Cited Findings (1.4.1); §10 Synthesis, Product rules #27]
- Includes an emergency and crisis pointer localised by device region: Australia shows 000 and Lifeline 13 11 14; the US shows 988 (call or text); any other region shows a "Get support" link until its numbers are verified. [§7 Medication safety, Cited Findings and Gaps; §9 Liability, Inferences (emergency and crisis clause)]
- Links to the full Terms and to the "Get support" screen. [Derived from §9 Liability, Inferences; §7 Medication safety, Inferences]

**Forbidden content**

- No claim or hint that the app treats, manages, improves or reduces ADHD or its symptoms, and no "clinically proven". [§10 Synthesis, Product rules #5 and Claims language]
- Do not name ADHD or any other condition on this screen: US 2026 wellness guidance says claims must avoid disease references, and even audience references ("designed with ADHD brains in mind") are rated amber. [Derived from §2 FDA, Cited Findings; §10 Synthesis, Claims language]
- No medication-effect vocabulary: onset, wear-off, peak effect, crash, rebound, coverage, level, pharmacokinetic, predicts, optimal time, dose due, booster, safe to take. [§7 Medication safety, Inferences (Wording); §10 Synthesis, Claims language]
- None of the MHRA indicative device words in a medication context: calculates, help or help with, measures, predicts, pharmacokinetic, controls. Test: a string scan of the screen returns zero hits. [§4 UK MHRA and EU, Cited Findings]
- Nothing that invites using the app instead of a doctor (for example "use instead of checking with your doctor"). [§10 Synthesis, Claims language]
- No absolute privacy promises ("never shared", "fully anonymous", "data never leaves your phone"): the app has accounts, a backend and optional cloud AI, so these would be false. [§9 Liability, Inferences; §10 Synthesis, Product rules #29]
- No blanket liability lines such as "we are not responsible" or "no refunds": in Australia they cannot remove consumer guarantees and can themselves breach consumer law. [§9 Liability, Cited Findings; §10 Synthesis, Product rules #30]
- No claim or hint of regulatory approval, clearance or registration; the app has none. [Derived from §6 App Store and HealthKit, Cited Findings (1.4.1)]
- No prescription stimulant brand names until the TGA rules on naming Schedule 8 medicines in consumer marketing are confirmed. [LAWYER] [§1 TGA, Gaps]

**Placement**

- Shown after the greeting and before sign-up, so it comes before any account, personal data or health data exists; it cannot be skipped or swiped away. [Derived from §6 App Store and HealthKit, Inferences (include in onboarding); §10 Synthesis, Product rules #17 (consent before collection)]
- A one-line version ("Check with your doctor or pharmacist before making medication decisions.") also appears on every medication screen: the Medication page, dose logging and reminder setup. [§6 App Store and HealthKit, Inferences; §10 Synthesis, Product rules #27]
- The same message stays consistent in the App Store description, website, notifications and AI refusal text, because every one of these counts as evidence of intended purpose. [§1 TGA, Inferences (claims drive classification)]
- The full text stays reachable after onboarding (for example Settings, About). [Derived from §6 App Store and HealthKit, Inferences]

**Acknowledgement**

- The source does not require a ticked or signed acknowledgement. Disclaimers only help show intended purpose and do not override behaviour or claims, so every behavioural rule in section 3 must ship regardless of this screen. [§9 Liability, Takeaway]
- If an "I understand" tap is used (sensible as a record), it is one explicit action and must not double as consent to health data, third-party AI, analytics or marketing; each of those needs its own specific consent, and nothing is pre-ticked. [Derived from §3 US privacy and enforcement, Cited Findings (MHMDA separate consents; BetterHelp affirmative express consent); §5 Australian privacy law, Cited Findings (consent must be current and specific)]

**Draft on-screen text (Australian default)**

- Title: "A planner, not a medical device" [Draft built from §9 Liability, Inferences]
- Line 1: "[App] plans your day around the hours you usually feel most focused, based on your own check-ins." [Draft built from §10 Synthesis, Claims language]
- Line 2: "It doesn't give medical advice, and it will never tell you when or how much medication to take." [Draft built from §9 Liability, Inferences]
- Line 3: "Take your medication as prescribed and follow the label. Keep seeing your doctor, and check with them or your pharmacist before making any medication decisions." [Draft built from §6 App Store and HealthKit, Cited Findings (1.4.1); §7 Medication safety, Inferences; §9 Liability, Inferences]
- Footer: "In an emergency, call 000. To talk to someone now, call Lifeline on 13 11 14." [Draft built from §7 Medication safety, Cited Findings]
- US footer: "To talk to someone now, call or text 988." (The US emergency number is not in the source; confirm before use.) [Draft built from §7 Medication safety, Cited Findings]
- Controls: primary button "I understand"; text links "Terms" and "Get support". [Derived from §9 Liability, Inferences; §7 Medication safety, Inferences]

## 2. Claims and wording rules (app, App Store listing, notifications, AI output)

**Intended purpose**

- Adopt one intended-purpose statement and use it as the anchor for every surface. Draft: "[App] is a personal planning tool. It arranges your tasks and calendar around the times you say you feel most focused, and keeps a personal log of the medication doses you choose to enter. It does not diagnose, treat or manage any condition, does not measure how well any medication works, and never tells you when or how much medication to take." [Derived from §1 TGA, Takeaway and Inferences; §9 Liability, Inferences; §10 Synthesis, Takeaway]
- Claims set intended purpose in every market: marketing, App Store text (name, subtitle, description, keywords, screenshots, promotional text), onboarding, notifications and AI output all count as evidence and all follow these rules. Test: each surface passes the banned-terms scan below before release. [§1 TGA, Inferences]

**Banned terms (scan every surface)**

- Keep a banned-terms list and scan UI strings, notification templates, App Store metadata, the website and the AI output filter against it. Minimum list: treats or manages (ADHD or symptoms), reduces or improves symptoms, clinically proven, optimise or optimal (medication, dose, timing), dose due, next dose, smart dose reminders, booster recommended, take your booster, wear-off, wears off, onset, pharmacokinetic, predicts or prediction (medication), crash, rebound, effectiveness, how well your medication is working, safe to take, prevents overdose, calculates, measures, controls, help with (in a medication or symptom context), AI health coach, ask our AI about your meds, 100% private, never leaves your phone, never shared, fully anonymous, stays in Australia, no refunds, study hack, think you have ADHD. [§10 Synthesis, Claims language; §7 Medication safety, Inferences (Wording); §4 UK MHRA and EU, Cited Findings (MHRA indicative words); §9 Liability, Inferences]

**Swap table (use the first phrase, never the second)**

- "Log your doses and see your own history", never "Tracks how well your medication is working". [§10 Synthesis, Claims language]
- "Reminders at the times you choose", never "We'll tell you when your next dose is due" or "Smart dose reminders". [§10 Synthesis, Claims language]
- "Plan your day around when you usually feel most focused, based on your check-ins", never "Optimises your medication" or "Find your optimal dose timing". [§10 Synthesis, Claims language]
- "Your focus pattern (from what you've logged)", never "Tells you when your dose wears off", "Predicts your medication wear-off" or "Personal pharmacokinetic curve". [§10 Synthesis, Claims language]
- "Schedules your hardest tasks into your best focus hours", never "Know exactly when to take your booster" or "Booster recommendations". [§10 Synthesis, Claims language]
- "A planner designed with ADHD brains in mind" is amber: an audience reference only, with no symptom or outcome claim attached. [§10 Synthesis, Claims language]
- "See your sleep and activity next to your plan", never "Detects medication crashes or rebound" or "Alerts you if your heart rate is too high on your meds". [§10 Synthesis, Claims language]
- "Did I already log it? Check your last entry at a glance", never "Prevents overdose" or "Tells you if it's safe to take another". [§10 Synthesis, Claims language]
- "Export your log to share with your doctor if you choose" is amber, never "Doctor-ready medication effectiveness report" or "Helps your psychiatrist adjust your dose". [§10 Synthesis, Claims language]
- "AI helps turn screenshots and messages into tasks", never "AI health coach for your medication" or "Ask our AI about your meds". [§10 Synthesis, Claims language]
- "Your data is encrypted; health details are processed on your device where possible", never "100% private, your data never leaves your phone" while any cloud call exists. [§10 Synthesis, Claims language]
- "Not medical advice. Follow your prescription and ask your doctor or pharmacist", never "Use instead of checking with your doctor". [§10 Synthesis, Claims language]

**In-app wording**

- Use "you logged", "your check-ins", "focus pattern", "reminder you set"; never "dose due", "optimal time", "wear-off prediction", "booster recommended". [§7 Medication safety, Inferences (Wording)]
- Call the learned window a focus pattern (or focus hours) everywhere; never "medication window", "dose window", "effect window", or a drug onset, peak, level or wear-off curve. Test: no UI string pairs "window" or "curve" with medication or dose. [§10 Synthesis, Product rules #4; §1 TGA, Inferences]
- Never attribute the focus pattern to a medication (for example "[Medication] works from 8 to 2" or "kicks in 45 minutes after your dose"); show usual focus hours as plain clock times. [Derived from §10 Synthesis, Product rules #4; §1 TGA, Inferences]
- No live countdowns or alerts about the focus pattern ending ("focus ends in 20 minutes"), since near-term predictions and "due in 20 min" style prompts read as wear-off and treatment timing. [Derived from §2 FDA, Cited Findings (real-time or near-term predictions) and Inferences; §10 Synthesis, Claims language]
- Check-in prompts ask how focused or energetic the person feels; never "Is your medication working?" or side-effect tracking, because monitoring a treatment's effect is the device line. [Derived from §10 Synthesis, Product rules #4 and Claims language]
- Never use "safe" in any medication context, including the duplicate-dose confirmation. [§7 Medication safety, Inferences (Double-dose guard)]
- Duplicate-log confirmation reads like: "You logged [Medication] at 7:42 am. Log another dose?" [§7 Medication safety, Inferences]
- Late-reminder note reads like: "Your prescriber or pharmacist can advise how late is appropriate for your medication." [§7 Medication safety, Inferences]
- Medication screens carry "Check with your doctor or pharmacist before making medication decisions." [§10 Synthesis, Product rules #27]
- No accuracy or validation claims for the focus pattern or any health figure (for example "95% accurate"): Apple rejects accuracy claims whose data and methodology are not disclosed and validated. [§6 App Store and HealthKit, Cited Findings (1.4.1)]
- Do not present values that look clinical (clinical heart-rate thresholds, clinical-style scores); US wellness guidance requires validation for values that mimic clinical ones. [§2 FDA, Cited Findings]
- Do not position the app as therapy, coping-skills treatment or a digital mental health tool; that exclusion is under review and is not the compliance basis. [§1 TGA, Inferences]

**Notifications**

- No notification names ADHD or any disease or condition, or contains clinical thresholds, diagnoses or treatment recommendations. Test: every notification template passes the banned-terms scan plus the word "ADHD". [§2 FDA, Cited Findings (2026 General Wellness)]
- Medication notifications only restate the user's own reminder (for example "Reminder you set: [nickname]"); never "dose due", "time for your booster", "catch up" or "take now". [§7 Medication safety, Inferences; §10 Synthesis, Claims language]
- No heart-rate or sleep notifications tied to medication or a condition (for example "heart rate high for your dose"). [§10 Synthesis, Product rules #6; §2 FDA, Inferences]

**Marketing and App Store listing**

- No claims to treat or manage ADHD in any market; US marketing in particular must not claim to manage ADHD. [§10 Synthesis, Product rules #5; §2 FDA, Inferences]
- No marketing to undiagnosed people ("Think you have ADHD?") and no growth campaigns aimed at people without a diagnosis. [§7 Medication safety, Inferences; §3 US privacy and enforcement, Inferences]
- No "study hack" framing anywhere near medication. [§7 Medication safety, Inferences]
- Copy stays adherence-neutral and prescriber-deferential: no "take more to focus", no refill pushes. [§3 US privacy and enforcement, Inferences]
- The listing and the UI make clear why Apple Health data (sleep, workouts, heart rate) is read and that the purpose is health or fitness. [§6 App Store and HealthKit, Cited Findings (HealthKit developer rules)]
- No promise that data stays in Australia unless contracts confirm Australian processing. [§8 LLM risks, Inferences]
- "Cancel anytime" appears only if cancelling is genuinely simple. [§9 Liability, Cited Findings; §10 Synthesis, Product rules #29]
- Privacy claims match the architecture exactly; a broken privacy promise is itself the violation (GoodRx). [§9 Liability, Cited Findings and Inferences]

**AI output**

- No AI path may emit dose, timing, booster, skip or change advice; blocked output is replaced by a fixed referral to the prescriber or pharmacist. [§8 LLM risks, Inferences (Output constraints); §10 Synthesis, Product rules #12]
- AI never gives harm-reduction dosing advice, including when a user reports non-prescribed use. [§7 Medication safety, Inferences]
- AI-generated schedules, priorities and suggestions are labelled as AI, and users are told when they are interacting with AI. [§10 Synthesis, Product rules #26; §4 UK MHRA and EU, Inferences (AI Act Art 50)]
- On-device model output stays within Apple's acceptable use: nothing inaccurate or dangerous, no unsupervised decisions with material impact in medical areas, nothing that fosters dependency or spiralling, nothing that facilitates self-harm. [§8 LLM risks, Cited Findings; §7 Medication safety, Cited Findings]

## 3. Features and behaviours required for compliance (with acceptance criteria)

**Global baseline**

- Build every market to the strictest rule from day one: MHMDA-style opt-in consent, GDPR explicit consent, Apple 5.1.2(i) AI disclosure and on-device processing of health context. Acceptance: there is no weaker regional consent or AI path. [§10 Synthesis, Inferences; §3 US privacy and enforcement, Inferences]
- Red line in every market and tier: the app never suggests, calculates or prompts taking, moving, adding, skipping or changing a dose or booster (for example "take your booster now to cover X"). Acceptance: no screen, notification, scheduler output or AI output contains a medication action. [§10 Synthesis, Product rules #1 and Inferences]

**Onboarding**

- Order is greeting, "not a medical device" screen (section 1), age gate (section 8), then sign-up. Acceptance: no account or data exists before both screens are passed. [Derived from §10 Synthesis, Product rules #17 and #24]
- Onboarding states the app is for people using medication as prescribed. [§7 Medication safety, Inferences]
- No prescription proof and no diagnosis is requested anywhere. Acceptance: no field asks for either. [§7 Medication safety, Inferences (prescription proof); diagnosis derived from the same minimisation reasoning]

**Dose log**

- The dose log is a diary: it stores and shows what the user entered and performs no treatment action on it. [§1 TGA, Inferences]
- Logging shows the last logged dose of the same medication with its time. Acceptance: the logging sheet always displays the last logged time for that medication. [§7 Medication safety, Inferences; §10 Synthesis, Product rules #7]
- Duplicate guard: a same-medication log inside the user-set minimum interval requires an explicit confirmation. Acceptance: a second log within the interval opens a confirm step showing the previous time; cancelling saves nothing. [§7 Medication safety, Inferences; §10 Synthesis, Product rules #7]
- Immediate undo after every log (about 10 seconds), plus full edit and delete. Acceptance: undo inside the window removes the entry and any Apple Health sample the app wrote. [§7 Medication safety, Inferences; §10 Synthesis, Product rules #8]
- Every edit and delete is kept in a local audit trail. [§7 Medication safety, Inferences]
- Corrections propagate to Apple Health when the app wrote the dose there. Acceptance: after a delete, no matching sample remains in Health. [§6 App Store and HealthKit, Inferences; §10 Synthesis, Product rules #8]
- "Already taken?" glance on a Lock Screen widget (and on Apple Watch if a Watch app ships). Acceptance: the last logged time is visible without opening the app. [§7 Medication safety, Inferences]
- Logging is only for the account holder: no "for someone else", no dependants, no sharing, gifting, trading, inventory-sharing or friends features. Acceptance: no data model or UI exists for another person's medication. [§7 Medication safety, Inferences; §10 Synthesis, Product rules #11]
- A pill count or "refill due" view, if included, is neutral: no auto-refill nudges and no ordering or purchasing of controlled substances. [§7 Medication safety, Inferences; §3 US privacy and enforcement, Inferences; §6 App Store and HealthKit, Cited Findings (1.4.3)]
- No dosage calculator of any kind (how much or when). [§6 App Store and HealthKit, Inferences (1.4.2)]

**Reminders and notifications**

- Medication reminders fire only at times the user set; any time the app infers becomes a reminder only after the user confirms it. Acceptance: every active reminder has a user-set or user-confirmed time. [§2 FDA, Inferences; §10 Synthesis, Product rules #2]
- Notifications log "taken" only from an explicit tap on a "Taken" action; snooze, dismiss or ignore never records "taken". Acceptance: snooze then dismiss leaves no taken entry. [§7 Medication safety, Inferences; §10 Synthesis, Product rules #9]
- The app never creates booster, catch-up or late-afternoon medication prompts. Acceptance: the notification template inventory contains none. [§7 Medication safety, Inferences; §10 Synthesis, Product rules #10]
- A reminder set late in the day triggers only the neutral prescriber-or-pharmacist note; the app never blocks the time or proposes another. Acceptance: the note appears after the agreed threshold (still to be set, section 13). [§7 Medication safety, Inferences; §10 Synthesis, Product rules #10]

**Medication page and day types**

- The Medication page carries the doctor-or-pharmacist line and a link to Get support. [§10 Synthesis, Product rules #27 and #28]
- Day types are picked by the user and only change how tasks are planned; the app never proposes a day type that implies skipping, adding or moving medication. Acceptance: no day-type suggestion or label references a dose change. [Derived from §10 Synthesis, Product rules #1 and #3]

**Scheduler and focus pattern**

- The scheduler takes the dose time as a fixed user input and adapts tasks, never medication. [§10 Synthesis, Product rules #3]
- When focus hours are shorter than the task load, it offers only task changes: split, reschedule, add a break. Acceptance: an over-capacity test day yields only task suggestions. [§7 Medication safety, Inferences; §10 Synthesis, Product rules #3]
- It never schedules demanding tasks late in the day in a way that implies taking more medication. [§7 Medication safety, Inferences]
- The learned pattern is shown as "your focus/energy pattern from your check-ins", never as drug onset, wear-off, pharmacokinetics or effectiveness, and it is used only to arrange tasks. [§10 Synthesis, Product rules #4; §1 TGA, Inferences]
- The user can view, correct and reset the learned pattern, because inferred and AI data can be wrong and accuracy duties apply. [Derived from §5 Australian privacy law, Cited Findings (OAIC AI guidance, APP 10)]

**Health data**

- Request only sleep, workouts and heart rate from Apple Health, with clear usage descriptions, and keep working when access is denied. [§10 Synthesis, Product rules #31]
- No heart-rate or sleep alerts tied to medication or a condition. [§10 Synthesis, Product rules #6]

**Consent and privacy controls**

- Express, specific, withdrawable consent before any health data is collected, covering dose logs, check-ins and the inferred focus pattern; the privacy policy alone never counts. Acceptance: nothing health-related is stored before a consent record exists. [§10 Synthesis, Product rules #17]
- Separate consent for collecting health data and for sharing it. [§3 US privacy and enforcement, Cited Findings (MHMDA)]
- An easy, understandable in-app way to withdraw each consent (for example Settings, Privacy). Acceptance: every consent can be withdrawn in-app without contacting support. [§6 App Store and HealthKit, Cited Findings (5.1.1)]
- An in-app "how your data is used" page stating how and where data is used and who receives it. [§6 App Store and HealthKit, Cited Findings (5.1.2(i))]
- Data collected for one purpose is never reused for another without new consent (for example check-ins are never used for marketing or model training). [§6 App Store and HealthKit, Cited Findings (5.1.2); §5 Australian privacy law, Cited Findings (APP 6)]
- Usage analytics, even non-health, are collected only with consent. [§6 App Store and HealthKit, Cited Findings (5.1.1, user or usage data)]

**AI features**

- Medication, check-in and Apple Health data are processed on device (Foundation Models); cloud models receive only de-identified, non-health text with medication references stripped. Acceptance: outbound payload tests show no health fields or medication strings. [§10 Synthesis, Product rules #13; §8 LLM risks, Inferences]
- Screenshots are read on device first (on-device image understanding or OCR); only filtered text, never the raw image, may go to a cloud model. [Derived from §8 LLM risks, Cited Findings (analyse images on device first) and Inferences (cloud gets only de-identified text)]
- Every third-party AI provider is disclosed (name, data sent, country) with explicit opt-in before first use, and the app works fully without it. [§10 Synthesis, Product rules #14]
- Output guard on every AI path: structured output types (for example @Generable) with no medication-action fields, a deterministic post-filter and a fixed referral template. Acceptance: a red-team prompt set about doses and boosters returns only the referral template on every path. [§8 LLM risks, Inferences; §10 Synthesis, Product rules #12]
- Screenshots, emails and calendar content are untrusted data: extracted only into fixed fields (title, time, location), never followed as instructions, and never allowed to create or change medication entries or reminders. [§8 LLM risks, Inferences; §10 Synthesis, Product rules #25]
- Any calendar write needs the user's confirmation. Acceptance: no event is created or edited without a confirm tap. [§10 Synthesis, Product rules #25]
- Social-plan detection from the calendar follows the same untrusted-data rules and never produces medication suggestions. [Derived from §10 Synthesis, Product rules #1 and #25]
- Daily priorities from the on-device model are labelled as AI, editable and dismissible, and contain no medication actions. [Derived from §10 Synthesis, Product rules #12 and #26; §8 LLM risks, Cited Findings (Apple acceptable use, human supervision)]

**Commerce and misuse**

- No purchase, ordering or trading of medication anywhere in the app. [§6 App Store and HealthKit, Cited Findings (1.4.3)]

## 4. Data the app must store or must not store (entities, fields, retention, deletion)

**Classification**

- Treat dose logs, check-ins, the focus pattern and anything read from Apple Health as health or sensitive data in every market (Australian sensitive information; Washington MHMDA covers data derived or extrapolated from non-health data; GDPR Art 9; the ICO counts health inferences). [§5 Australian privacy law, Cited Findings; §3 US privacy and enforcement, Cited Findings and Inferences; §4 UK MHRA and EU, Cited Findings; §10 Synthesis, Inferences]
- Inferred or AI-generated personal information (focus pattern, AI summaries) is a new collection, and privacy rules apply to AI inputs and outputs alike. [§5 Australian privacy law, Cited Findings (OAIC AI guidance)]

**Entities and fields**

- Medication: user nickname (display label), name, archived flag, user-set minimum interval for the duplicate check, optional neutral pill count. If read from Apple Health, map from HKUserAnnotatedMedication (medication, nickname, hasSchedule, isArchived). [§7 Medication safety, Inferences; §6 App Store and HealthKit, Cited Findings]
- Dose log entry: medication, time logged, optional quantity, status, source (in app, notification "Taken" action, widget), created and edited times, linked Health sample id if written. Mirror HKMedicationDoseEvent fields (logStatus, scheduleType, scheduledDate, doseQuantity, medicationConceptIdentifier). [§6 App Store and HealthKit, Cited Findings; §7 Medication safety, Cited Findings]
- Status values separate taken from snoozed, dismissed and not logged; snooze or dismiss never maps to taken. [§10 Synthesis, Product rules #9]
- Reminder: time(s) and days set by the user, origin (user-set or app-suggested) and a user-confirmed timestamp for anything app-suggested; unconfirmed suggestions are never active. [§10 Synthesis, Product rules #2]
- Check-in: self-rated focus or energy, time, optional free text (scanned on device for crisis keywords, section 10). [§7 Medication safety, Inferences; §5 Australian privacy law, Cited Findings]
- Focus pattern: derived from check-ins, stored and labelled as a focus pattern, under the same consent and minimisation as the dose log, never labelled as drug onset or wear-off. [§10 Synthesis, Inferences and Product rules #4]
- Day type: user-chosen label per date; affects task planning only. [Derived from §10 Synthesis, Product rules #3]
- Calendar-derived items and social plans: only fixed fields (title, time, location), stored only after user confirmation. [§8 LLM risks, Inferences]
- Consent record: purpose, wording version, provider (for AI), granted time, withdrawn time. [Derived from §3 US privacy and enforcement, Cited Findings (affirmative express consent; MHMDA separate consents); §10 Synthesis, Product rules #17]
- Local audit trail of dose-log edits and deletes. [§7 Medication safety, Inferences]
- Age: store only "confirmed 18 or over" and when, not date of birth. [Derived from §5 Australian privacy law, Inferences (declared-age gate); §10 Synthesis, Product rules #31 (data minimisation)]

**Must not store or collect**

- Personal health information in iCloud: no CloudKit or iCloud Drive sync of medication logs, check-ins, the focus pattern or Health-derived data. Test: the release build has no iCloud sync on health stores. [§6 App Store and HealthKit, Cited Findings (5.1.3(ii)) and Inferences; §10 Synthesis, Product rules #20]
- Prescription proof. [§7 Medication safety, Inferences]
- Diagnosis. [Derived from §7 Medication safety, Inferences (same reasoning as prescription proof)]
- Any other person's medication data. [§7 Medication safety, Inferences; §10 Synthesis, Product rules #11]
- Apple Health types beyond sleep, workouts and heart rate. [§10 Synthesis, Product rules #31]
- Medication names or health fields in analytics events, crash logs or server logs. [§3 US privacy and enforcement, Inferences]
- Health data used for advertising, marketing or data mining, or sold or licensed in any form, including de-identified "insights". [§6 App Store and HealthKit, Cited Findings (5.1.2, 5.1.3(i)); §10 Synthesis, Product rules #18 and #19]
- Health data sent to any LLM provider, whether company-paid or the user's own key. [§10 Synthesis, Product rules #13; §6 App Store and HealthKit, Inferences]
- False or inaccurate data written to Apple Health. [§6 App Store and HealthKit, Cited Findings (5.1.3(ii))]

**Retention and deletion**

- A written retention schedule per entity, enforced by deletion jobs. [§3 US privacy and enforcement, Cited Findings (Cerebral and BetterHelp orders); §10 Synthesis, Product rules #22]
- In-app account deletion reaches the live database, archives and backups, and every processor. [§10 Synthesis, Product rules #22; §3 US privacy and enforcement, Cited Findings (MHMDA)]
- Undo, edit and delete propagate to any Apple Health samples the app wrote. [§6 App Store and HealthKit, Inferences]
- Withdrawing a consent stops that processing. [Derived from §6 App Store and HealthKit, Cited Findings (5.1.1)]
- Provider retention is part of the schedule and the policy: OpenAI keeps API data up to 30 days (zero retention needs approval; flagged images are kept even under zero retention); Anthropic deletes within 30 days but keeps flagged content up to 2 years and classifier scores up to 7 years; Bedrock can run with no retention. [§8 LLM risks, Cited Findings]

## 5. Backend / services / integrations required (auth, storage, encryption, logging, DSAR, breach response)

**Auth**

- The source sets no rules for Sign in with Apple, Google or email beyond in-app account deletion and minimised sign-up data; see section 13. [Not covered in source]

**Storage and encryption**

- Health entities sync through the company's own encrypted backend (or live in Apple Health where that fits), never iCloud. [§6 App Store and HealthKit, Inferences; §10 Synthesis, Product rules #20]
- "Your data is encrypted" is claimed only once every copy (device, backend, backups) is encrypted. [Derived from §10 Synthesis, Claims language; §9 Liability, Inferences]
- Apple Health data is encrypted while the device is locked, so background Health reads can fail; nothing server-side depends on them. [§6 App Store and HealthKit, Cited Findings]

**Access control**

- Least-privilege staff access to user data, revoked the day someone leaves (Cerebral: former employees kept access). [§3 US privacy and enforcement, Cited Findings]
- Serious invasions of privacy (for example leaking stimulant use) now carry private lawsuits in Australia on top of regulator action, so access control is a litigation control too. [§5 Australian privacy law, Inferences]

**Logging, analytics and SDKs**

- No advertising or attribution pixels or SDKs that receive health-screen events. [§10 Synthesis, Product rules #18]
- Keep an inventory of every SDK and outbound endpoint; any that sends identifiable health data without authorisation (analytics, attribution, crash logs with medication names, undisclosed AI calls) can be a notifiable breach under the US Health Breach Notification Rule. [§3 US privacy and enforcement, Inferences]
- Crash reporting and server logs scrub medication names, check-in text and AI prompts. [§3 US privacy and enforcement, Inferences]
- Never upload user emails, IP addresses or identifiers to ad platforms (BetterHelp shared emails and IPs with ad platforms; GoodRx shared medication data with ad and messaging vendors). [Derived from §3 US privacy and enforcement, Cited Findings]
- Website tracking pixels need consent wherever pages collect health information (OAIC Medmate and Monash IVF determinations). [§5 Australian privacy law, Cited Findings]

**AI services**

- Routing order: anything touching medication, doses, check-ins or Apple Health goes to on-device Foundation Models; Private Cloud Compute only as an escalation where available; cloud models get only de-identified productivity text. [§8 LLM risks, Inferences (Routing architecture)]
- Private Cloud Compute needs iOS 27 or later plus a managed entitlement, so on iOS 26 devices there is no escalation path and health-context features must work with the on-device model alone. [Derived from §8 LLM risks, Cited Findings]
- Company-paid AI calls use enterprise or API tiers with no training, zero data retention where approved, and a DPA; never free or unpaid tiers. [§10 Synthesis, Product rules #15]
- APP 8 due diligence on each provider (retention, server location, access to inputs) and contracts that give effective control; the company stays accountable for the overseas recipient. [§10 Synthesis, Product rules #16; §5 Australian privacy law, Cited Findings]
- Strip identifiers and medication names before any cloud call. [§5 Australian privacy law, Inferences (APP 8 path)]
- Prefer Australian-region processing where offered: OpenAI stores data in Australia but inference location is unclear; Bedrock is per region and cross-region inference stores data where it is processed. [§5 Australian privacy law, Inferences; §8 LLM risks, Cited Findings and Inferences]
- Claude via Amazon Bedrock: model providers cannot see prompts or logs, and a "none" retention mode gives zero retention. [§8 LLM risks, Cited Findings]
- OpenAI: zero retention and modified abuse monitoring need prior approval; images are scanned for CSAM and flagged ones are kept even under zero retention. [§8 LLM risks, Cited Findings]
- Gemini, if used at all: generic task parsing only, paid tier, adults only; users in the EEA, Switzerland and the UK may only be served through paid services. [§8 LLM risks, Cited Findings and Inferences]

**Deletion, consent and DSAR**

- Deletion pipeline covering primary data, backups, archives and processors, triggered by in-app account deletion. [§10 Synthesis, Product rules #22; §3 US privacy and enforcement, Cited Findings (MHMDA)]
- Consent service storing grant and withdrawal records per purpose and per AI provider. [Derived from §10 Synthesis, Product rules #17; §3 US privacy and enforcement, Cited Findings]
- Access and portability requests are not covered by the source (only deletion and consent withdrawal); see section 13. [Not covered in source]

**Breach response**

- Australia: notify affected people and the OAIC when a breach is likely to cause serious harm, and notify people as soon as practicable. [§5 Australian privacy law, Cited Findings; §10 Synthesis, Product rules #23]
- US: unauthorised sharing counts as a breach, not only hacking; notify people without unreasonable delay and within 60 calendar days, the FTC within the same 60 days if 500 or more people are affected, and the media if 500 or more residents of one state are affected; penalties reach $53,088 per violation. [§3 US privacy and enforcement, Cited Findings; §10 Synthesis, Product rules #23]
- The US rule applies because the app can draw from several sources, whether or not a user turns integrations on. [§3 US privacy and enforcement, Cited Findings]

**Jurisdiction baseline**

- Australia: full Privacy Act compliance from day one regardless of turnover (health service providers are covered), including breach notification. [§5 Australian privacy law, Cited Findings and Inferences]
- Australia: from 10 Dec 2026 the privacy policy must describe what personal information the automated scheduler uses and what decisions it makes on its own. [§5 Australian privacy law, Cited Findings; §10 Synthesis, Product rules #32]
- Washington (US): separate consents to collect and to share, signed authorisation before any sale (so never sell), deletion reaching backups, private lawsuits possible, no size threshold. [§3 US privacy and enforcement, Cited Findings]
- EU and UK: explicit consent for health data including inferences, and a DPIA before launch. [§4 UK MHRA and EU, Cited Findings and Inferences]
- EU: tell users they are interacting with AI (AI Act Art 50) regardless of device classification; adopt this globally. [§4 UK MHRA and EU, Cited Findings and Inferences]
- NZ: the Health Information Privacy Code 2020 may apply; unverified for consumer apps. [LAWYER] [§5 Australian privacy law, Cited Findings and Gaps]

**Safety services**

- Crisis keyword detection runs on device and needs neither the network nor any AI model. [Derived from §7 Medication safety, Inferences; §10 Synthesis, Product rules #13 and #28]

## 6. Apple App Store and platform rules that apply (with guideline numbers where given)

- 1.4.1: any accuracy claim about a health measurement needs disclosed data and methodology or the app is rejected; the app must remind users to check with a doctor alongside the app and before medical decisions. Build: no accuracy claims; the reminder sits in onboarding and on medication screens. [§6 App Store and HealthKit, Cited Findings and Inferences]
- 1.4.1: regulatory clearance documentation is only submitted by apps that have clearance; this app has none and must not imply any. [§6 App Store and HealthKit, Cited Findings]
- 1.4.2: drug dosage calculators must come from approved bodies or carry regulator approval, so any when-or-how-much feature risks rejection. [§6 App Store and HealthKit, Cited Findings and Inferences]
- 1.4.3: no encouraging illegal drug use and no facilitating the sale of controlled substances; no medication marketplace, sharing or trading. [§6 App Store and HealthKit, Cited Findings; §10 Synthesis, Product rules #11]
- 2.5.1: HealthKit is used only for health and fitness purposes and integrates with the Health app. [§6 App Store and HealthKit, Cited Findings]
- 5.1.1: consent before collecting user or usage data; paid functionality cannot depend on granting data access; an easy, understandable way to withdraw consent. [§6 App Store and HealthKit, Cited Findings]
- 5.1.1(v): apps that support account creation must offer account deletion inside the app. [§6 App Store and HealthKit, Cited Findings]
- 5.1.1 privacy policy: explains retention and deletion, and how to revoke consent or request deletion. [§6 App Store and HealthKit, Cited Findings]
- 5.1.1(ix): healthcare or sensitive-data apps are submitted by a legal entity, not an individual developer account; publish through the company (for example an Australian Pty Ltd). [§6 App Store and HealthKit, Cited Findings and Inferences; §10 Synthesis, Product rules #21]
- 5.1.1: request only the data needed (data minimisation). [§10 Synthesis, Product rules #31]
- 5.1.2(i): no use, transmission or sharing of personal data without permission; say how and where data is used; clearly disclose sharing with third parties including third-party AI, and get explicit permission first (AI wording added 13 Nov 2025). [§6 App Store and HealthKit, Cited Findings]
- 5.1.2: data is not repurposed without new consent; HealthKit and similar data are never used for marketing, advertising or use-based data mining, including by third parties. [§6 App Store and HealthKit, Cited Findings]
- 5.1.3(i): health data is never used or disclosed for advertising, marketing or data mining beyond improving health management or research (and then only with permission); the specific health data collected from the device must be disclosed. [§6 App Store and HealthKit, Cited Findings]
- 5.1.3(ii): never write false or inaccurate data into HealthKit, and never store personal health information in iCloud. [§6 App Store and HealthKit, Cited Findings]
- HealthKit rules: access only for health or fitness purposes, and that purpose must be clear in both marketing text and the UI. [§6 App Store and HealthKit, Cited Findings]
- HealthKit rules: no disclosure to a third party without express permission, and even then only to a party that also provides a health or fitness service to the user, so no HealthKit data goes to LLM providers. [§6 App Store and HealthKit, Cited Findings and Inferences]
- HealthKit rules: HealthKit data is never sold to ad platforms, data brokers or resellers. [§6 App Store and HealthKit, Cited Findings]
- HealthKit rules: a privacy policy is mandatory. [§6 App Store and HealthKit, Cited Findings]
- HealthKit rules: read denials are invisible to the app, so the UI cannot depend on knowing whether access was denied. [§6 App Store and HealthKit, Cited Findings]
- HealthKit rules: NSHealthShareUsageDescription and NSHealthUpdateUsageDescription strings are required. [§6 App Store and HealthKit, Cited Findings]
- HealthKit medications API (iOS 26): HKMedicationDoseEvent and HKUserAnnotatedMedication are readable; whether third-party apps can write dose events is unconfirmed. [§6 App Store and HealthKit, Cited Findings and Gaps]
- CloudKit private database: whether it counts as storing in iCloud must be confirmed with App Review before any use; default is not to use it for health data. [§6 App Store and HealthKit, Inferences]
- Developer Program License Agreement: HealthKit terms (s3.3.3(H)), Foundation Models requirements (s3.3.11(A), June 2026) and protection of minors (s7.9) must be read before submission. [§6 App Store and HealthKit, Cited Findings and Gaps]
- Age rating: new questionnaire answers were required by 31 Jan 2026; answer for an 18+ rating in line with the launch age gate; kid and teen safety guidance was revised in June 2026. [§6 App Store and HealthKit, Cited Findings; §5 Australian privacy law, Inferences]
- Foundation Models acceptable use: no inaccurate or dangerous output, no unsupervised decisions with material impact in medical areas, nothing that fosters dependency or spiralling, nothing that facilitates or glamorises self-harm. [§8 LLM risks, Cited Findings; §7 Medication safety, Cited Findings]
- Foundation Models: the on-device model has about 4K tokens of context; Private Cloud Compute (32K) needs iOS 27 or later and a managed entitlement, and has per-person daily limits. [§8 LLM risks, Cited Findings]
- Foundation Models: analyse images with the on-device model first; the Vision OCR tool can be attached. [§8 LLM risks, Cited Findings]
- Guidelines on sign-in, subscriptions, trials and App Store privacy labels are not in the source; see section 13. [Not covered in source]

## 7. Subscriptions, trials and paywall disclosure requirements

- The source says almost nothing about StoreKit, trials or paywall disclosure; the bullets below are all it supports, and the gaps are listed in section 13. [Not covered in source]
- Starting the trial, subscribing or using any paid feature never requires granting Apple Health, calendar, health-data consent, analytics or third-party AI. Acceptance: purchase and every paid feature work with all optional permissions denied. [§6 App Store and HealthKit, Cited Findings (5.1.1); §10 Synthesis, Product rules #14]
- A visible in-app route to manage or cancel the subscription that is never removed or hidden (Cerebral removed its cancel button when cancellations rose). [§3 US privacy and enforcement, Cited Findings; §10 Synthesis, Product rules #29]
- "Cancel anytime" appears only if cancelling really is simple (Cerebral misrepresented it). [§9 Liability, Cited Findings]
- No "no refunds" or responsibility-disclaimer wording on the paywall or in the Terms; Australian consumer guarantees cannot be removed. [§9 Liability, Cited Findings; §10 Synthesis, Product rules #30]
- Paywall and trial copy follow the claims rules: no ADHD outcome claims, no medication optimisation, no absolute privacy claims. [§10 Synthesis, Product rules #5 and #29 and Claims language]
- No paid tier may include dose or booster timing; that feature is off limits in every market. [§10 Synthesis, Inferences]
- Health data never drives upsell or paywall targeting (for example showing an offer because of check-in scores or dose logs), because that is a marketing use of health data. [Derived from §6 App Store and HealthKit, Cited Findings (5.1.2, 5.1.3(i)); §10 Synthesis, Product rules #18]
- Paywall and purchase events are never sent to advertising or attribution SDKs alongside health-screen events. [§10 Synthesis, Product rules #18]

## 8. Accounts: creation, deletion, data export, age gating

**Creation**

- Order: greeting, "not a medical device" screen, age gate, then sign-up. Acceptance: no account or personal data is created before the age gate passes. [Derived from §10 Synthesis, Product rules #17 and #24]
- Sign-up collects only what the account needs; no health data, diagnosis or prescription details at sign-up. [Derived from §10 Synthesis, Product rules #31; §7 Medication safety, Inferences]
- Health-data consent is asked at the first moment health data would be collected, separate from sign-up and from accepting the Terms. [Derived from §5 Australian privacy law, Cited Findings (consent current and specific; more than a line in the privacy policy); §3 US privacy and enforcement, Cited Findings (MHMDA)]
- Accounts are held by the company as publisher (a legal entity), which is the accountable party for privacy. [§6 App Store and HealthKit, Inferences; §9 Liability, Inferences]

**Age gating**

- Launch 18+ only: App Store age rating plus a declared-age gate in onboarding. [§5 Australian privacy law, Inferences; §10 Synthesis, Product rules #24]
- A user who declares under 18 cannot continue, and no account or health data is created. [Derived from §10 Synthesis, Product rules #24]
- Under-18 users are never routed to the Gemini API. [§10 Synthesis, Product rules #24]
- Any future minors support needs the Children's Online Privacy Code outcome (to be registered by 10 Dec 2026) and Anthropic's minors requirements: age verification, content moderation and filtering, and AI disclosure. [§5 Australian privacy law, Cited Findings and Inferences; §8 LLM risks, Cited Findings]
- Australian law presumes capacity to consent from 15, but provider terms (Gemini's under-18 bar, Anthropic's minors rules) set the practical floor at 18. [§5 Australian privacy law, Cited Findings and Inferences]
- The under-16 social media ban does not apply (health support, no social purpose); keep it that way by shipping no social or sharing features. [§5 Australian privacy law, Cited Findings and Inferences; §7 Medication safety, Inferences]
- The children's privacy code excludes health service providers; confirm the app counts as one. [LAWYER] [§5 Australian privacy law, Cited Findings and Inferences]

**Deletion**

- In-app account deletion. Acceptance: reachable from Settings without contacting support. [§6 App Store and HealthKit, Cited Findings (5.1.1(v)); §10 Synthesis, Product rules #22]
- Deletion covers backups, archives and processors, per the retention schedule. [§10 Synthesis, Product rules #22; §3 US privacy and enforcement, Cited Findings]
- The privacy policy explains how to delete the account and how to revoke consent. [§6 App Store and HealthKit, Cited Findings]

**Export**

- Export is the user's own log, offered as "Export your log to share with your doctor if you choose" (amber). Acceptance: the export contains raw entries only, with no effectiveness analysis, dose-change framing or "doctor-ready report" branding. [§10 Synthesis, Claims language]
- Access and portability rights are not covered by the source; see section 13. [Not covered in source]

## 9. Third-party AI ("bring your own AI") rules and the warning text

**Rules**

- The source does not discuss user-supplied keys; these bullets apply its third-party AI rules to them, because the app still sends the data. [Derived from §6 App Store and HealthKit, Cited Findings (5.1.2(i)); §10 Synthesis, Product rules #13 and #14]
- Off by default; explicit opt-in per provider before first use, naming the provider, what is sent and the country of processing. Acceptance: no request leaves the device before the opt-in record exists. [§10 Synthesis, Product rules #14; §6 App Store and HealthKit, Cited Findings (5.1.2(i))]
- The app works fully without it, and no paid feature depends on it. [§10 Synthesis, Product rules #14; §6 App Store and HealthKit, Cited Findings (5.1.1)]
- Never sent, even with consent: medication names, doses, reminders, check-ins, the focus pattern, anything from Apple Health. Acceptance: outbound payload tests find none. [§10 Synthesis, Product rules #13; §6 App Store and HealthKit, Inferences (HealthKit data to LLMs); §5 Australian privacy law, Cited Findings (OAIC)]
- Identifiers and medication references are stripped before sending, and screenshots are read on device so only filtered text goes out. [§5 Australian privacy law, Inferences (APP 8 path); §8 LLM risks, Inferences]
- Replies from the user's provider pass through the same output guard (no medication-action fields, deterministic filter, referral template). [§10 Synthesis, Product rules #12]
- Replies and parsed inputs are untrusted: fixed fields only, confirmation before calendar writes, no effect on medication entries or reminders. [§10 Synthesis, Product rules #25]
- Content produced this way is labelled as AI and names the provider. [§10 Synthesis, Product rules #26]
- Conflict to resolve: the source says never use free or unpaid tiers, yet a user's own key may be free, and Gemini's unpaid tier uses content with human reviewers; the warning must say this, and free-tier keys may need to be refused. [§10 Synthesis, Product rules #15; §8 LLM risks, Cited Findings]
- Gemini keys: its terms bar medical advice and apps likely used by under-18s, and require paid services for EEA, Swiss and UK users; either exclude Gemini or limit it to task parsing for adults outside those regions unless a paid tier is confirmed. [§8 LLM risks, Cited Findings and Inferences; §10 Synthesis, Product rules #24]
- OpenAI and Anthropic policies bar tailored medical advice or require professional review for high-risk health use, so medication content stays out whoever holds the key. [§8 LLM risks, Cited Findings]
- Providers may keep content: about 30 days by default, flagged content longer (Anthropic up to 2 years), and OpenAI keeps flagged images even under zero retention; the warning must not promise deletion. [§8 LLM risks, Cited Findings]
- The "not responsible" message is factual (their terms apply; we do not control their handling) rather than a blanket exclusion; liability limits go in the Terms "to the extent permitted by law". [§9 Liability, Cited Findings and Inferences; §10 Synthesis, Product rules #30]
- The user can switch it off and remove the key at any time from Settings. [§6 App Store and HealthKit, Cited Findings (5.1.1 withdrawal)]
- The privacy policy lists every provider the app can call, the data sent and the country. [§10 Synthesis, Product rules #14]
- No claim that processing stays in Australia. [§8 LLM risks, Inferences]
- Adults only. [§10 Synthesis, Product rules #24]

**Draft warning text (per provider, before first use; assumes calls go straight from the phone)**

- Title: "Use your own AI" [Draft built from §6 App Store and HealthKit, Cited Findings (5.1.2(i))]
- Line 1: "When this is on, the text you choose to send, like tasks, messages or words from a screenshot, goes from your phone to [Provider] in [country], using your own [Provider] account." [Draft built from §10 Synthesis, Product rules #14]
- Line 2: "We never send your medication, check-ins, focus pattern or Health data." [Draft built from §10 Synthesis, Product rules #13]
- Line 3: "[Provider]'s terms and privacy policy cover what you send. We don't control how they store or use it. Some free plans let providers keep your content, have people review it, or use it to train their AI." [Draft built from §8 LLM risks, Cited Findings; §9 Liability, Cited Findings]
- Line 4: "AI can get things wrong, so you'll always check changes before they're saved." [Draft built from §5 Australian privacy law, Cited Findings (APP 10); §10 Synthesis, Product rules #25]
- Controls: primary "Turn on [Provider]", secondary "Not now"; afterwards Settings shows "Your own AI: [Provider]. Turn off any time." [Draft built from §6 App Store and HealthKit, Cited Findings (5.1.1 withdrawal)]

## 10. Safety and crisis routing requirements

- A static "Get support" screen with no AI behind it, bundled in the app so it also works offline. [§7 Medication safety, Inferences; §10 Synthesis, Product rules #28; offline requirement derived]
- Australia: Lifeline call 13 11 14, text 0477 13 11 14, 24/7 online chat; Triple Zero (000) for life-threatening emergencies. [§7 Medication safety, Cited Findings]
- US: call or text 988, or chat, available around the clock. [§7 Medication safety, Cited Findings]
- Other regions (UK Samaritans, NZ 1737, EU) are unverified; verify before those launches and meanwhile show a generic "call your local emergency number". [§7 Medication safety, Gaps]
- Lines follow the current device region, not the sign-up country. [Derived from §7 Medication safety, Inferences (country-appropriate lines)]
- Deterministic crisis routing: self-harm or crisis keywords in check-ins or chat open the support screen with no model involved. Acceptance: a keyword test set triggers routing with AI disabled and the device offline. [§7 Medication safety, Inferences]
- Never let a model judge urgency: research cited by the TGA found a platform told 51.6% of people who needed hospital to stay home, and LLM users chose the right course in under 44% of cases. [§1 TGA, Cited Findings; §8 LLM risks, Cited Findings]
- If a user mentions non-prescribed use or escalating doses, reply with a fixed, non-judgemental message pointing to a GP or pharmacist and, in Australia, a crisis line where relevant; never harm-reduction dosing advice. [§7 Medication safety, Inferences]
- Any medication question to AI gets the fixed referral to ask the prescriber or pharmacist. [§8 LLM risks, Inferences]
- Get support is reachable from onboarding, the Medication page, check-ins, any AI chat and Settings. [Derived from §7 Medication safety, Inferences; §10 Synthesis, Product rules #28]
- The app mirrors label rules conservatively: no doubling a missed dose, no late-day dose prompts, no sharing, neutral tracking of remaining quantity. [§7 Medication safety, Takeaway and Cited Findings]
- No wording that implies safety judgements ("safe to take another", "prevents overdose"). [§10 Synthesis, Claims language]
- No design that makes stimulant use frictionless or pushes more medication (auto-refill nudges, "take more to focus"). [§3 US privacy and enforcement, Inferences; §7 Medication safety, Cited Findings (Done auto-refill)]
- On-device model features must not foster dependency or spiralling and must never facilitate self-harm. [§7 Medication safety, Cited Findings; §8 LLM risks, Cited Findings]
- The Terms include an emergency and crisis clause. [§9 Liability, Inferences]

## 11. Edge cases, failure modes and mitigations

- Duplicate tap or double log: confirm step with the previous time; cancelling saves nothing. [§7 Medication safety, Inferences]
- Wrong entry: undo, edit or delete, with the local audit trail and Apple Health propagation. [§7 Medication safety, Inferences; §6 App Store and HealthKit, Inferences]
- Snoozed, dismissed or ignored reminder: no "taken" record, because false taken or not-taken records drive double dosing. [§10 Synthesis, Product rules #9]
- Missed dose: no catch-up, double or "take it now" prompt; labels say never double. [§7 Medication safety, Cited Findings; §10 Synthesis, Product rules #10]
- User sets a late reminder: neutral note only; no block and no alternative time. [§7 Medication safety, Inferences]
- Focus hours shorter than the task load: split, reschedule or add breaks; never a medication suggestion. [§7 Medication safety, Inferences]
- App infers a regular dose time from logs: it may offer it as a reminder, but it stays inactive until the user confirms. [§2 FDA, Inferences; §10 Synthesis, Product rules #2]
- User picks a day type such as a no-medication day: tasks adapt; the app never suggests the day type or comments on the medication choice. [Derived from §10 Synthesis, Product rules #1 and #3]
- Social plan detected (for example evening drinks): the app may move tasks but never comments on medication, timing or combining substances. [Derived from §10 Synthesis, Product rules #1 and #12]
- Apple Health access denied: the app cannot tell "denied" from "no data", so show a neutral empty state, keep features working, and never nag or gate features. [§6 App Store and HealthKit, Cited Findings; §10 Synthesis, Product rules #31]
- Device locked: background Health reads can fail; plan with what is available. [§6 App Store and HealthKit, Cited Findings]
- On-device model unavailable (unsupported device, Apple Intelligence off, iOS 26 device without Private Cloud Compute): health-context features fall back to deterministic logic or pause, and never fall back to a cloud or user-key model. [Derived from §8 LLM risks, Inferences (routing) and Cited Findings (PCC needs iOS 27+)]
- On-device context is small (about 4K tokens): keep health-context prompts short. [§8 LLM risks, Cited Findings]
- Hidden instructions in a screenshot, email or calendar event: treated as data; only fixed fields extracted; no calendar write without confirmation; no medication changes. [§8 LLM risks, Cited Findings (OWASP LLM01) and Inferences]
- A model emits dose advice despite prompting: the output type has no field for it, the post-filter swaps in the referral, and adversarial testing runs before each release. [§8 LLM risks, Cited Findings (OWASP mitigations) and Inferences]
- User asks "should I take my booster now?": fixed referral template. [§8 LLM risks, Inferences; §10 Synthesis, Product rules #12]
- User mentions non-prescribed use or taking more: fixed response per section 10. [§7 Medication safety, Inferences]
- Crisis keywords while offline or with AI off: the static support screen still opens. [§7 Medication safety, Inferences]
- User declares under 18: onboarding stops. [§10 Synthesis, Product rules #24]
- User withdraws health-data consent: collection and processing stop; paid features stay available in reduced form. [§6 App Store and HealthKit, Cited Findings (5.1.1)]
- User declines third-party AI: every core feature still works. [§10 Synthesis, Product rules #14]
- User's own key is free tier, or a Gemini key is used from the EEA, Switzerland or UK: warn or refuse (section 9). [§8 LLM risks, Cited Findings; §10 Synthesis, Product rules #15]
- A screenshot sent to OpenAI is flagged by CSAM scanning: it is kept even under zero retention, so raw images are not sent and retention is disclosed. [§8 LLM risks, Cited Findings]
- A crash report contains a medication name: possible notifiable US breach; scrub before sending. [§3 US privacy and enforcement, Inferences]
- A new SDK starts receiving health-screen events: blocked by the SDK inventory review. [§3 US privacy and enforcement, Inferences; §10 Synthesis, Product rules #18]
- A departing staff member keeps data access: revoke on exit. [§3 US privacy and enforcement, Cited Findings]
- Account deleted but backups remain: deletion must reach backups and processors. [§3 US privacy and enforcement, Cited Findings; §10 Synthesis, Product rules #22]
- A Lock Screen widget or notification preview shows a stimulant name to anyone nearby: default to the user's nickname and offer hiding names on the Lock Screen (Cerebral's postcards revealed diagnoses; leaking stimulant use is now actionable in Australia). [Derived from §3 US privacy and enforcement, Cited Findings; §5 Australian privacy law, Inferences]
- Emails or other messages from the company: no subject lines or content that reveal medication or condition. [Derived from §3 US privacy and enforcement, Cited Findings (Cerebral postcards)]
- User travels: support lines follow the current device region. [Derived from §7 Medication safety, Inferences]
- User tries to log for a partner or child: not supported. [§7 Medication safety, Inferences]
- Pill count shows a shortfall: neutral statement only (tracking quantity helps spot missing medication). [§7 Medication safety, Cited Findings and Inferences]
- Export taken to a clinic: raw log only, no effectiveness analysis. [§10 Synthesis, Claims language]
- A persistence framework or project template quietly enables iCloud sync: a release check confirms health stores never sync to iCloud. [Derived from §6 App Store and HealthKit, Inferences; §10 Synthesis, Product rules #20]
- A heart-rate value looks clinical: do not present it that way, since clinical-looking values need validation. [§2 FDA, Cited Findings]
- Rules change: re-review at the children's privacy code registration (by 10 Dec 2026), the automated-decision disclosure start (10 Dec 2026), the outcome of the TGA digital mental health exclusion review and the EU AI Act high-risk dates. [§5 Australian privacy law, Cited Findings; §1 TGA, Cited Findings; §4 UK MHRA and EU, Cited Findings]

## 12. Documents the company must produce (privacy policy, terms, DPIA, records) and what each must contain

**Privacy policy must contain**

- It exists and is linked from the app and the listing (mandatory for HealthKit). [§6 App Store and HealthKit, Cited Findings]
- Retention and deletion policies, and how to revoke consent and request deletion. [§6 App Store and HealthKit, Cited Findings (5.1.1)]
- The specific Apple Health data collected (sleep, workouts, heart rate) and why. [§6 App Store and HealthKit, Cited Findings (5.1.3(i))]
- How and where data is used, and every third party that receives it, including each AI provider with the data sent and the country. [§6 App Store and HealthKit, Cited Findings (5.1.2(i)); §10 Synthesis, Product rules #14]
- Overseas disclosures and the consent basis relied on for them, without resting only on "consent to non-application" for sensitive data. [§5 Australian privacy law, Inferences (APP 8)]
- From 10 Dec 2026: what personal information the automated scheduler uses and what decisions it makes on its own. [§5 Australian privacy law, Cited Findings; §10 Synthesis, Product rules #32]
- That health data is never sold, licensed or used for advertising or marketing. [§10 Synthesis, Product rules #18 and #19]
- Provider retention realities (30-day defaults; longer for flagged content). [§8 LLM risks, Cited Findings]
- That deletion reaches backups and processors. [§3 US privacy and enforcement, Cited Findings; §10 Synthesis, Product rules #22]
- No absolute promises; every statement matches the architecture. [§9 Liability, Inferences; §10 Synthesis, Product rules #29]
- It is not the consent mechanism; consent is collected in the app. [§5 Australian privacy law, Cited Findings (OAIC)]

**Terms of use must contain**

- The app is a personal organisation tool, not medical advice, diagnosis or treatment, and not a substitute for a prescriber or pharmacist. [§9 Liability, Inferences]
- It does not tell users when or how much medication to take. [§9 Liability, Inferences]
- Users must follow their prescription and the label. [§9 Liability, Inferences]
- An emergency and crisis clause. [§9 Liability, Inferences]
- Liability limits written "to the extent permitted by law", compliant with Australian Consumer Law and free of unfair contract terms; no clause removing consumer guarantees or saying "no refunds". [§9 Liability, Cited Findings and Inferences; §10 Synthesis, Product rules #30]
- For the account holder's own use, with medication taken as prescribed; no logging for others. [Derived from §7 Medication safety, Inferences]
- Bring-your-own AI: the user's provider terms govern that relationship, framed within the same consumer law limits. [Derived from §9 Liability, Cited Findings; §10 Synthesis, Product rules #14]
- Subscription and cancellation terms that match reality. [§9 Liability, Cited Findings (Cerebral "cancel anytime")]

**Other documents and records**

- Intended-purpose statement (section 2) signed off and used as the anchor for all copy. [§1 TGA, Takeaway and Inferences]
- Claims review checklist applied to marketing, App Store text, onboarding, notifications and AI outputs before each release. [§1 TGA, Inferences; §10 Synthesis, Claims language]
- Retention schedule. [§3 US privacy and enforcement, Cited Findings; §10 Synthesis, Product rules #22]
- Breach response plan covering the Australian scheme and the US rule. [§10 Synthesis, Product rules #23]
- DPIA before any EU or UK launch. [§4 UK MHRA and EU, Cited Findings (ICO) and Inferences]
- APP 8 due diligence file per AI or cloud provider (retention, location, access to inputs, training, zero retention, DPA). [§5 Australian privacy law, Cited Findings; §10 Synthesis, Product rules #16]
- Signed DPAs and zero-retention approvals with each company-paid AI provider. [§10 Synthesis, Product rules #15; §8 LLM risks, Cited Findings]
- Consent records per user, purpose and provider. [Derived from §3 US privacy and enforcement, Cited Findings; §10 Synthesis, Product rules #17]
- SDK and data-flow inventory. [Derived from §3 US privacy and enforcement, Inferences]
- Staff access and offboarding procedure. [Derived from §3 US privacy and enforcement, Cited Findings (Cerebral)]
- Company registration (for example Pty Ltd) as the App Store publisher. [§10 Synthesis, Product rules #21]
- Insurance: professional indemnity and cyber, exact cover set with a broker. [LAWYER] [§9 Liability, Inferences]
- App Store age rating questionnaire answers (18+). [§6 App Store and HealthKit, Cited Findings]
- Legal sign-off: an Australian health-regulatory and privacy lawyer before launch; US, UK and EU counsel before those launches. [§10 Synthesis, Takeaway]
- Optional FDA pre-submission question (digitalhealth@fda.hhs.gov) if a US launch includes learning a drug-effect curve. [§2 FDA, Gaps]
- Written question to Apple App Review on whether a CloudKit private database counts as iCloud storage. [§6 App Store and HealthKit, Inferences]

## 13. Open questions / dependencies

**Flagged by the source for a lawyer or regulator**

- Exact TGA wording of the health self-management and digital mental health exclusions, and whether ADHD counts as a "serious" condition. [LAWYER] [§1 TGA, Inferences and Gaps]
- Whether the learned focus pattern stays outside device rules in each market when framed and engineered as scheduling only (TGA, FDA, MHRA, EU). [LAWYER] [§1 TGA, Inferences; §2 FDA, Inferences; §4 UK MHRA and EU, Inferences]
- Whether TGA advertising rules allow naming Schedule 8 stimulants (brand names) in marketing. [LAWYER] [§1 TGA, Gaps]
- Health service provider status, and the children's code carve-out that follows from it. [LAWYER] [§5 Australian privacy law, Inferences]
- Tranche 2 Privacy Act reform status (fair and reasonable test, small business exemption, direct marketing and targeting rules). [LAWYER] [§5 Australian privacy law, Gaps]
- Statutory privacy tort commencement date (calculated as 10 June 2025, not confirmed). [§5 Australian privacy law, Gaps]
- Whether the OAIC treats health-data breaches as presumptively serious harm. [§5 Australian privacy law, Gaps]
- Whether NZ's Health Information Privacy Code covers a consumer app, and NZ's device regime for software. [§5 Australian privacy law, Gaps]
- Other US state health and privacy laws (for example Nevada, Connecticut, comprehensive state laws). [§3 US privacy and enforcement, Gaps]
- EU AI Act dates after the Digital Omnibus (sources conflict). [LAWYER] [§4 UK MHRA and EU, Cited Findings and Gaps]
- MHRA changes in 2025 to 2026 were not verified. [§4 UK MHRA and EU, Gaps]
- Status of the TGA digital mental health tool consultation. [§1 TGA, Gaps]
- Insurance cover type. [LAWYER] [§9 Liability, Inferences]
- ACCC unfair contract terms guidance was not read. [§9 Liability, Gaps]

**Apple and provider unknowns**

- Does a CloudKit private database count as storing health information in iCloud? [§6 App Store and HealthKit, Inferences]
- Does iCloud device backup of the app's local health data count as "storing in iCloud", and should health stores be excluded from device backup? [Not covered in source]
- Can third-party apps write HKMedicationDoseEvent samples? [§6 App Store and HealthKit, Gaps]
- Full DPLA text for HealthKit (s3.3.3(H)) and Foundation Models (s3.3.11). [§6 App Store and HealthKit, Gaps]
- Private Cloud Compute entitlement eligibility for health apps, and its iOS 27 requirement against the iOS 26 target. [§8 LLM risks, Gaps and Cited Findings]
- Australian data residency for OpenAI inference, Anthropic's first-party API, Bedrock Claude models and Vertex AI. [§8 LLM risks, Gaps]
- UK, NZ and EU crisis numbers (and the US emergency number) need verifying from primary sources. [§7 Medication safety, Gaps]

**Not covered by the source (needs separate research)**

- Sign-in: Apple's login-services guideline (Google sign-in offered alongside Sign in with Apple), token handling when an account is deleted, and email sign-up security. [Not covered in source]
- Whether an account can be mandatory at first launch under Apple's rules on requiring login. [Not covered in source]
- StoreKit subscriptions and the 1-month trial: Apple's in-app purchase and subscription guidelines, required price, renewal and trial disclosures, the trial-then-free-plan flow, and consumer auto-renewal and cancellation laws in each market. [Not covered in source]
- App Store privacy label answers. [Not covered in source]
- Access, correction and portability requests (Australian Privacy Principles, GDPR, Washington) and their response times. [Not covered in source]
- GDPR and UK GDPR breach notification timing, and any EU or UK representative duty. [Not covered in source]
- Encryption standards and key management; where user-supplied AI keys are stored (for example Keychain) and a guarantee that they never reach logs or the backend. [Not covered in source]
- Retention periods for each entity (the source requires a schedule but gives no durations). [§3 US privacy and enforcement, Cited Findings]
- Whether bring-your-own AI calls count as the company's overseas disclosure under APP 8, and whether calls go straight from the device or through the backend. [Derived from §5 Australian privacy law, Cited Findings; otherwise not covered in source]
- Whether Washington's law needs a separate consumer health data privacy policy. [Not covered in source]
- Data flows of the Google sign-in SDK checked against the no-tracking-SDK rule. [Not covered in source]
- Consent rules for marketing emails. [Not covered in source]

**Product decisions needed**

- What counts as "late in the day" for the neutral reminder note. [§7 Medication safety, Inferences]
- Default for the duplicate-check minimum interval (the source says user-defined; decide whether setup requires it). [§7 Medication safety, Inferences]
- Whether an Apple Watch app ships (the source expects an "Already taken?" check there). [§7 Medication safety, Inferences]
- Whether the app writes doses to Apple Health. [§6 App Store and HealthKit, Inferences]
- Which user-key providers to support, and whether to refuse free-tier and Gemini keys. [§8 LLM risks, Cited Findings; §10 Synthesis, Product rules #15]
- The list of day types and their wording. [Derived from §10 Synthesis, Product rules #1 and #3]
- Whether the age gate is a separate control on the disclaimer screen or its own screen. [§5 Australian privacy law, Inferences]
- Whether any UI may state focus timing relative to the dose (for example "about an hour after you log"), which edges toward "onset". [LAWYER] [Derived from §10 Synthesis, Product rules #4; §1 TGA, Inferences]
- App name: if the store name contains "ADHD" or implies beating it (the working folder is "ADHD Slayer"), counsel should check it against the no-treatment-claims rule. [Derived from §10 Synthesis, Product rules #5 and Claims language]
