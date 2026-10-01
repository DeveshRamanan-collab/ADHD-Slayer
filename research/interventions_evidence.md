# Evidence-based non-drug interventions, behavioural techniques and digital-health design principles for adolescents (16+) and adults with ADHD — input to an iPhone/Apple Watch planning and self-management app

Evidence grading used throughout: **STRONG** = multiple RCTs or meta-analyses in ADHD adults/adolescents, or guideline-endorsed. **MODERATE** = at least one RCT or meta-analysis, but either not ADHD-specific or with methodological limits. **WEAK** = small, uncontrolled or observational studies, or ADHD-adjacent evidence only. **POPULAR-BUT-UNPROVEN** = widely recommended with no controlled evidence found.

Access notes: PubMed/PMC pages returned reCAPTCHA blocks, and the Europe PMC REST API rate-limited (HTTP 429). Several Wiley and ACM pages returned 403. Where a primary source could not be opened, a secondary summary that was opened is cited and labelled as secondary. Numbers are reported as they appear in the opened source.

---

## Q0. Overall: which techniques actually work (summary grading)

### Takeaway
For ADHD adults, the strongest evidence is for structured CBT and meta-cognitive skills programmes: planner/calendar and task-list systems, task decomposition, distractibility management, cognitive restructuring and procrastination work. Guidelines endorse these programmes, with CBT-vs-waitlist SMD about −0.84. The "externalise at the point of performance" principle (Barkley) supplies the theory for turning these skills into app features. Most app-native mechanics (gamification, streaks, body doubling, dopamine menus, Pomodoro) have weak, ADHD-adjacent or no ADHD-specific evidence. Digital ADHD interventions overall show small pooled effects (g ≈ −0.32), and engagement drops sharply after install.

### Cited Findings
- AADPA (Australian guideline) factsheet: "Cognitive-behavioural interventions should be offered to adolescents and adults with ADHD." The factsheet grades this evidence-based (strong). ADHD coaching "could be considered as part of a support plan" (conditional/emerging). The factsheet gives no specific recommendations on digital tools, cognitive training, neurofeedback or exercise for adolescents/adults — [AADPA factsheet](https://aadpa.com.au/wp-content/uploads/2024/02/ADHD-Guideline-Factsheet-Clinical-Treatment-Overview-C-AADPA.pdf)
- The AADPA guideline's non-pharmacological categories are lifestyle changes, cognitive-behavioural interventions, cognitive training, neurofeedback, ADHD coaching and adherence support — [AADPA guideline, non-pharmacological](https://adhdguideline.aadpa.com.au/non-pharmacological/)
- NICE NG87 recommendations:
  - 1.5.16: "Consider non-pharmacological treatment for adults with ADHD who have: made an informed choice not to have medication; difficulty adhering to medication; found medication to be ineffective or cannot tolerate it."
  - 1.5.17: consider it in combination with medication when symptoms still cause significant impairment.
  - 1.5.18: minimum is "a structured supportive psychological intervention focused on ADHD" plus "regular follow-up either in person or by phone"; "Treatment may involve elements of or a full course of CBT."
  - 1.5.15: medication is offered to adults "after environmental modifications have been implemented and reviewed."
  - [NICE NG87 (full text copy)](https://docs.bvsalud.org/biblioref/2022/02/1357854/attention-deficit-hyperactivity-disorder-diagnosis-and-managem_kempx2v.pdf)
- 2025 meta-analysis of digital mental-health interventions for ADHD: 23 RCTs, 1,472 participants, 33 samples; median participant age 9.96 years, so mostly children.
  - Pooled effects: overall symptoms g = −0.32 (95% CI −0.53 to −0.11); inattention g = −0.25; hyperactivity/impulsivity g = −0.18 (p = .050, not significant).
  - Therapist-guided and self-guided formats did not differ. Egger's test showed publication bias for hyperactivity/impulsivity.
  - [ScienceDirect 2025 meta-analysis](https://www.sciencedirect.com/science/article/pii/S2451958825001186)
- Grading at a glance, detailed in the sections below:
  - **STRONG:** CBT/meta-cognitive therapy skills (planner, task lists, decomposition, distraction delay, cognitive restructuring).
  - **MODERATE:** DBT-based skills groups; implementation intentions (general population d = 0.65; ADHD lab evidence in children); acute exercise before cognitive work (adults g ≈ 0.55 on inhibition); notification batching; temptation bundling (general population); JITAI/receptivity-timed prompts (general mHealth).
  - **WEAK:** ADHD coaching; time aids/visual timers; self-compassion interventions (correlational in ADHD); one sec-style friction (uncontrolled field data plus a preregistered experiment, general population); streak repair (consumer studies); easy-vs-hard-first (non-ADHD).
  - **POPULAR-BUT-UNPROVEN:** body doubling/Focusmate (surveys only); dopamine menu; "just start for 5 minutes"; Pomodoro for ADHD specifically; 66-day habit rule as a fixed target.

### Inferences
- The app's core should replicate the active ingredients of Safren/Solanto CBT: calendar plus task list, decomposition, distraction capture, reframing and self-reward. It should wrap these in point-of-performance delivery (Watch, widgets, Live Activities), because that is where Barkley argues skills fail.
- Given the small pooled digital effects and steep engagement decay, the app should be positioned as an adjunct to clinical care, consistent with NICE 1.5.18's "regular follow-up". It should not be marketed as a treatment.
- **App implementation:** Build around a CBT skill spine (plan → decompose → schedule → capture distractions → review/reframe). Treat every other mechanic as an optional, user-toggled layer.

### Gaps
- No RCTs were found (or could be opened) testing a consumer planner/self-management app against control in ADHD adults. Cerebral's claim of an 8-week Inflow RCT was not verified (see Q9).
- The full AADPA recommendation grades for digital tools, exercise and cognitive training for adults sit in sub-pages not retrieved.

---

## Q1. CBT (Safren), meta-cognitive therapy (Solanto), DBT-based skills and ADHD coaching: which specific skills have evidence and map to app features?

### Takeaway
**STRONG:** Individual CBT (Safren) and group meta-cognitive therapy (Solanto) roughly double responder rates versus active controls. Their shared skills (calendar plus task list, prioritisation, task decomposition, distractibility management, cognitive restructuring, self-reward) are directly app-translatable. **MODERATE:** DBT-based groups improve executive function and core symptoms (ES 0.64–1.01) but not emotion regulation versus TAU. **WEAK:** Coaching evidence is mostly small and uncontrolled.

### Cited Findings
- **Safren et al. 2010 (JAMA)**, medication-treated adults with persistent symptoms:
  - 86 participants; 12 individual CBT sessions vs relaxation plus educational support.
  - CBT modules: (1) organisation/planning — "use of calendar and task list system" plus problem-solving; (2) reducing distractibility — attention-span work and written distraction tracking; (3) cognitive restructuring. Optional modules covered procrastination and family involvement.
  - Outcomes: ADHD rating scale −4.63 points vs control (p = .02); CGI −0.53 (p = .03).
  - Responders: 67% vs 33% (rating scale) and 53% vs 23% (CGI).
  - Responders/partial responders maintained gains at 6 and 12 months.
  - [JAMA](https://jamanetwork.com/journals/jama/fullarticle/186469)
- **Solanto et al. 2010 (Am J Psychiatry)**, meta-cognitive therapy (MCT):
  - 88 adults; group MCT (n = 45) vs supportive therapy (n = 43) controlling for group support, therapist attention and psychoeducation.
  - Content: time management, organisation and planning, using "task decomposition, self-reward, and self-instruction cues". Progresses "hierarchically from basic skills (planner mechanics) to higher-order planning strategies".
  - AISRS inattention improved 5.0 vs 2.3 points (difference 2.7; 95% CI 0.9–4.6; effect ≈ 0.56 SD).
  - Responders: 42.2% vs 12% (AISRS); 53% vs 28% (CAARS inattention/memory). Odds of response 5.41×.
  - [AJP](https://psychiatryonline.org/doi/10.1176/appi.ajp.2009.09081123)
- **Cochrane review (Lopez et al. 2018)**, summarised by NIHR:
  - 14 RCTs, 700 adults, 8–15 weeks.
  - CBT vs waitlist: self-reported symptoms SMD −0.84.
  - CBT vs supportive therapy: clinician-rated SMD −0.56 (low quality); self-reported SMD −0.16 (not significant).
  - CBT plus medication vs medication alone: clinician-rated SMD −0.80 (very low quality).
  - Evidence quality "ranged from very low to moderate".
  - [NIHR Evidence summary of Cochrane review](http://evidence.nihr.ac.uk/alert/cognitive-behavioural-therapy-could-benefit-adults-with-attention-deficit-hyperactivity-disorder-adhd/)
- **ACCESS programme** (college students aged 18–30; relevant to young adult users):
  - 250 students; 8 weeks of 90-minute group CBT plus weekly 30-minute mentoring, then a maintenance semester; compared with delayed treatment.
  - Effects: inattention d = .50; total ADHD symptoms d = .39; global executive function d = .56; ADHD knowledge d = 1.21; behavioural strategy use d = .81.
  - Depression did not differ between groups. Anxiety held stable in ACCESS while it worsened in controls (d = .33).
  - Gains were stable through maintenance (5–7 months).
  - [ACCESS RCT PDF](https://libres.uncg.edu/ir/uncg/f/P_Silvia_Randomized_2021.pdf)
- **DBT-based group treatment, multicentre RCT (Norway, BMC Psychiatry 2022):**
  - 121 randomised (mean age 37); 14 weekly 2-hour groups with psychoeducation, acceptance, mindfulness and functional behavioural analysis, plus 15–20-minute individual coaching after each session; vs TAU.
  - BRIEF-A executive function: −12.8 vs −0.37 (p = .005; ES 0.64).
  - ASRS symptoms ES 1.01; quality of life ES 0.63; depression ES 0.58.
  - Emotion regulation (DERS) and anxiety did not differ from TAU. Gains persisted at 6 months.
  - [BMC Psychiatry](https://link.springer.com/article/10.1186/s12888-022-04356-6)
- **ADHD coaching:**
  - CHADD evidence review: 19 studies, of which 2 were RCTs; "majority of studies with n ≤ 10"; "majority lack control groups"; effect sizes often not reported. Only 2 studies were in (non-student) adults — [CHADD coaching evidence PDF](https://chadd.org/wp-content/uploads/2018/10/2B_Emerging_Evidence_for_the_Effectiveness_of_ADHD_Coaching_.pdf)
  - Prevatt college coaching: 148 clients, 8 weeks, single group with no control. Components were long-term goals, weekly objectives, rewards and consequences for short-term progress, and study skills. The "largest effect sizes were found for time management and concentration" — [Prevatt coaching PDF](https://lifeskillsadvocate.com/wp-content/uploads/2023/02/Coaching-for-College-Students-with-ADHD.pdf)
  - AADPA rates coaching conditional/emerging: "could be considered" — [AADPA factsheet](https://aadpa.com.au/wp-content/uploads/2024/02/ADHD-Guideline-Factsheet-Clinical-Treatment-Overview-C-AADPA.pdf)

### Inferences
- The most evidence-dense, app-translatable skills are:
  1. A single trusted calendar plus task list (Safren module 1; Solanto "planner mechanics").
  2. Task decomposition into next physical actions.
  3. Distraction capture and delay: write the distraction down, defer it, return to the task (Safren module 2).
  4. Cognitive restructuring for avoidance and procrastination thoughts.
  5. Self-reward after completion.
  6. Weekly review and planning (MCT's hierarchical planning).
- DBT's value in adults was on executive function and symptoms, not emotion regulation versus TAU. Emotion-regulation features should therefore not be sold as validated by DBT trials.
- Coaching's "weekly objectives plus check-in" structure is cheap to emulate in software, but its evidence is weak.
- **App implementation (CBT/MCT):**
  - One inbox feeding a calendar-anchored task list, with prioritisation (A/B/C).
  - A "break it down" step that requires a first physical action under 10 minutes.
  - A one-tap distraction parking lot on Watch/lock screen.
  - A guided weekly review.
  - A thought-reframe card offered when a task is repeatedly deferred.
- **App implementation (DBT):** Optional short mindfulness/acceptance and functional-analysis ("what got in the way?") prompts, framed as supportive rather than as emotion-regulation treatment.
- **App implementation (coaching):** An optional weekly check-in ritual (goals → obstacles → next week's 3 commitments). It can be shared with a human coach or clinician for accountability.

### Gaps
- Solanto et al. 2025 (World Psychiatry, "The efficacy of CBT for adults with ADHD") was located but returned 403, so its data could not be verified.
- The Liu et al. 2023 CBT meta-analysis (Psychology and Psychotherapy) also returned 403.
- No dismantling study was found that isolates which CBT module drives benefit.
- Adolescent-specific (16–17) CBT trials were not retrieved. AADPA endorses CBT for adolescents, but trial details were not opened.
- No RCT of a self-guided app-delivered Safren/Solanto protocol in adults was opened. The 2026 J Atten Disord review "Bridging the Gap: Digital CBT for Adults" (Antshel, McBride, Knouse) exists but was not opened.

---

## Q2. Barkley's "point of performance" principle; externalising time, information and motivation (visual timers, time-remaining displays)

### Takeaway
The principle is theoretically central and consistent with robust evidence of timing deficits and delay aversion in ADHD. Evidence that specific time aids (visual timers) improve outcomes is **WEAK** (small paediatric RCTs; results not verified). **Design rationale: STRONG. Direct efficacy of timers: WEAK.**

### Cited Findings
- **Barkley** (fact sheet):
  - "Clinicians should likely reject most approaches to intervention for people with EF deficits that do not involve helping patients with an active intervention at the point of performance."
  - "To 'externalize' information is to make it physical outside of the individual."
  - Recommends "making time itself more externally represented, by reducing or eliminating gaps in time among the components of a behavioral contingency."
  - Proposes "a step a day toward that eventual goal … with immediate feedback and incentives."
  - "Artificial means of creating external sources of motivation must be arranged at the point of performance."
  - [Barkley fact sheet](https://www.russellbarkley.org/factsheets/ADHD_EF_and_SR.pdf)
- **Time perception meta-analysis** (Marx, Cortese et al. 2021, JAACAP), summarised by ADHD Evidence project:
  - Time discrimination: 25 studies, n = 1,633, medium deficit.
  - Time estimation: 8 studies, n = 1,024, small-to-medium increase in absolute error.
  - Time production: 7 studies, n = 380, small deficit.
  - Time reproduction: 26 studies, n = 2,364, medium deficit.
  - Not stratified by adults vs children.
  - [ADHD Evidence summary](https://www.adhdevidence.org/blog/time-blindness-found-to-be-a-consistent-feature-of-adhd)
- **Delay aversion / impulsive choice meta-analysis** (Marx et al. 2021, J Atten Disord):
  - 37 comparisons, 3,763 participants; small-to-medium effects: people with ADHD choose small immediate over larger delayed rewards more often.
  - Real rewards nearly doubled the odds of the immediate choice compared with hypothetical rewards.
  - [J Atten Disord](https://journals.sagepub.com/doi/10.1177/1087054718772138)
- **Time aids RCT** (Janeslätt group, Swedish multicentre, children 8.6–16.1 years with ADHD):
  - 38 completers (19 intervention, 19 control).
  - Compensation component: "structuring the physical environment, and prescribing" time assistive devices (e.g. visual clocks). Remediation component: 20-minute daily time tasks with a coach.
  - Outcomes: time-processing ability (KaTid), parent- and self-rated daily time management.
  - The effect sizes were not in the opened excerpt.
  - [Eur Child Adolesc Psychiatry](https://link.springer.com/article/10.1007/s00787-017-1052-5)

### Inferences
- Time deficits are medium-sized and reliable, and delay aversion is real. Features that make time visible (a shrinking time-remaining ring, a "time until next commitment" countdown, travel/transition buffers) are strongly theory-justified even though outcome data are thin.
- Immediate, concrete rewards are more motivating for ADHD than distant or hypothetical ones (Marx 2021). This supports small immediate feedback at completion rather than distant milestone badges.
- **App implementation:**
  - Watch complication and Live Activity showing a depleting visual timer for the current block and a "leave in X min" countdown.
  - Automatic transition warnings (e.g. 10/5/1 min) before calendar events.
  - Estimated-vs-actual duration logging to calibrate the user's own time estimates.
  - Immediate completion feedback (haptic plus visual).

### Gaps
- Effect sizes from the Janeslätt ADHD RCT were not retrievable. No RCT of visual timers or time-remaining displays in adults with ADHD was found.
- Evidence that estimated-vs-actual feedback improves time estimation in ADHD adults was not found.

---

## Q3. Implementation intentions ("if-then" plans) in ADHD (Gawrilow et al.)

### Takeaway
**MODERATE.** There is strong general-population meta-analytic evidence (d = 0.65 for implementation intentions; g = 0.34 for mental contrasting plus implementation intentions). ADHD evidence is lab-based and in children: if-then plans normalised Go/No-Go inhibition to non-ADHD levels, and were additive with stimulants. Adult ADHD RCTs were not found.

### Cited Findings
- **Gawrilow & Gollwitzer 2008** (Cognitive Therapy and Research):
  - Children with ADHD who "furnished a suppression goal with implementation intentions improved inhibition of an unwanted response on a Go/No-Go task to the same level observed in children without ADHD."
  - Study 2: "a combination of implementation intentions and psychostimulant medication resulted in the highest level of suppression performance."
  - Plans took the form "If [cue], then [suppression response]."
  - [Springer](https://link.springer.com/article/10.1007/s10608-007-9150-1)
- **Meta-analyses:**
  - Gollwitzer & Sheeran 2006 found implementation intentions improve goal attainment with "Cohen's d = 0.65 (95% CI 0.6, 0.7)" (as cited in the MCII meta-analysis).
  - MCII meta-analysis: 21 studies, 24 effect sizes, 15,907 participants, g = 0.336. Experimenter-led g = 0.465 vs document-based g = 0.277.
  - [Frontiers in Psychology 2021](https://www.frontiersin.org/journals/psychology/articles/10.3389/fpsyg.2021.565202/full)

### Inferences
- If-then plans are cheap, well-evidenced in general and mechanistically suited to ADHD, since they shift control from effortful intention to cue-triggered automaticity.
- Guided, interactive plan formation (experimenter-led g ≈ 0.47) outperformed document-based formation (g ≈ 0.28) in the MCII meta-analysis. An interactive in-app wizard is likely better than a static tip.
- **App implementation:**
  - When scheduling any task, prompt "When/where will you start? If [cue: e.g. 'I sit at my desk after lunch'], then I will [first action]."
  - Attach the plan to a location/time trigger that fires the stated first action at the cue.
  - Offer an optional obstacle-planning step: "If I feel like checking my phone, then I will…"

### Gaps
- The Gawrilow et al. 2013 classroom MCII study in ADHD (link.springer.com/article/10.1007/s12402-013-0117-7) could not be opened: the proxy rate-limited it (HTTP 429).
- No adult ADHD RCT of implementation intentions was found.

---

## Q4. Body doubling / co-working (Focusmate) and accountability partners

### Takeaway
Body doubling is **POPULAR-BUT-UNPROVEN**. The evidence consists of surveys, qualitative work, theses and prototypes, with no controlled efficacy data for Focusmate found. Human-supported accountability has a plausible model (supportive accountability) with **MODERATE** general eHealth support for improving adherence.

### Cited Findings
- **Eagle et al. (ACM TACCESS; builds on ASSETS '23):**
  - Online survey of 220 respondents (193 neurodivergent), recruited via Twitter, Reddit and TikTok.
  - Reported mechanisms: accountability/social pressure, companionship ("a sense of togetherness"), reduced overwhelm, and help with task initiation, not only sustained focus.
  - Proposes a design space on two axes: space/time (synchronous co-located to asynchronous pre-recorded) and mutuality (high-accountability partner to ambient companionship). Commercial tools cluster in synchronous, high-mutuality designs.
  - Authors acknowledge a small, US/EU-skewed sample.
  - [TACCESS paper PDF](https://leyabreanna.com/papers/body_double_taccess.pdf)
- Wikipedia's article on body doubling states that "research on body doubling is lacking since it is a new area of study, with most being limited to master's theses," and that efficacy is "mainly promoted through personal anecdotes." Sources listed include a 2024 dissertation on accountability and body doubling (Born), a robot companion study (O'Connell et al., HRI '24) and an XR thesis — [Wikipedia: Body doubling](https://en.wikipedia.org/wiki/Body_doubling)
- Tan, Hegemann & Gerken (CHI '26 roadmap for mixed-reality body doubling):
  - There are "only a small number of papers and master's theses."
  - Ara et al. 2025 (VR: no double vs human double vs AI double) is "one of the few known empirical studies … specifically for adults with ADHD."
  - In O'Connell et al. 2024, "73% of their participants desired attention monitoring and distraction detection features."
  - [arXiv 2605.07851](https://arxiv.org/html/2605.07851)
- Supportive accountability model (Mohr et al. 2011):
  - "Human support increases adherence through accountability to a coach who is seen as trustworthy, benevolent, and having expertise."
  - Recommends process-oriented (not outcome-oriented) expectations set with the patient's involvement, and monitoring framed benevolently.
  - Reports that human support enhances adherence more than automated reminders.
  - [Mohr et al. 2011 PDF](https://research.vu.nl/ws/files/2936910/2011%20Mohr)

### Inferences
- The mechanism users describe (task initiation plus presence) overlaps with Barkley's externalised accountability. Real-time social presence costs little to prototype, but claims of efficacy should be avoided.
- The unfilled design space is asynchronous and low-mutuality presence ("others are working now") and ad-hoc sessions. These carry less social-anxiety cost than 1:1 video.
- **App implementation:**
  - An optional "work alongside" mode offering (a) an ambient presence counter or anonymous live co-working room, (b) scheduled sessions with a chosen partner, and (c) a Focusmate hand-off link.
  - A share-a-commitment feature that sends process-based check-ins ("did the first step?") to a trusted person or clinician, not outcome scores.

### Gaps
- No peer-reviewed controlled study of Focusmate or any video co-working service on productivity was found. The CHADD body-doubling article was not opened.
- The ASSETS 2025 EEG body-doubling study (dl.acm.org/doi/full/10.1145/3663547.3759743) was located but not opened; ACM pages returned 403.
- No data were found on accountability-partner apps (e.g. commitment contracts) in ADHD.

---

## Q5. Task chunking, "just start for 5 minutes", Pomodoro, time-boxing, easiest-first vs hardest-first

### Takeaway
- Task decomposition is part of evidence-based MCT/CBT (**STRONG** as a package component).
- Pomodoro: in neurotypical students, **MODERATE** evidence that fixed breaks reduce fatigue/distraction versus self-regulated breaks, but with no learning advantage and mixed subjective results. No ADHD data (**POPULAR-BUT-UNPROVEN** for ADHD).
- "Just start for 5 minutes": no evidence found (**UNPROVEN**).
- Easiest-first raises short-term throughput but harms long-term productivity in field data (**MODERATE**, non-ADHD).

### Cited Findings
- Solanto's MCT explicitly includes "task decomposition" and "self-reward" — [AJP](https://psychiatryonline.org/doi/10.1176/appi.ajp.2009.09081123)
- Barkley advises "a step a day toward that eventual goal" with "immediate feedback and incentives" — [Barkley fact sheet](https://www.russellbarkley.org/factsheets/ADHD_EF_and_SR.pdf)
- **Pomodoro vs self-regulated breaks:**
  - Biwer et al. 2023 compared self-regulated breaks, systematic long breaks (24 + 6 min) and systematic short breaks (12 + 3 min). "Systematic conditions reduced fatigue and distraction but showed no performance differences."
  - A 2026 replication/extension (n = 176 university students; 12 + 3 min vs self-regulated breaks) found no learning difference (Bayes factor ≈ 2.5 favouring the null). Self-regulated breaks produced higher energy (d = −0.36), concentration (d = −0.43) and motivation (d = −0.54) and lower distraction (d = 0.55), and were preferred.
  - Neither study mentions ADHD.
  - [Behavioral Sciences 2026 (MDPI)](https://www.mdpi.com/2076-328X/16/7/1158)
- **Easy vs hard first** (KC, Staats, Kouchaki & Gino 2020, Management Science):
  - 84 emergency physicians and more than 233,000 patients. Choosing easier cases raised short-term throughput. Physicians who took more difficult cases improved speed more over time and produced more RVUs per patient.
  - Each additional patient under care raised the likelihood of picking a lower-acuity case by 8%.
  - Lab: 76% of the high-workload group chose the easy task vs 64% of the low-workload group. "Less progress" and fatigue drove avoidance.
  - [Kellogg Insight summary](https://insight.kellogg.northwestern.edu/article/easy-or-hard-tasks-first)

### Inferences
- For ADHD, the main barrier is initiation, so an easy first task can serve as an on-ramp (momentum). Field data warn that habitually choosing easy tasks, especially under high load, erodes long-term performance.
  - A balanced rule is "warm-up micro-task, then the most important task". This is an inference, not a tested rule.
- Pomodoro should be offered as a configurable timer, not a mandated method. Self-regulated breaks were subjectively preferred, and fixed breaks reduced fatigue, so a hybrid (suggested break with user override) fits both findings.
- **App implementation:**
  - "Break it down" assistant: an optional on-device AI suggestion of steps, each under 15 minutes.
  - A flexible focus timer with presets (e.g. 12/3, 25/5, custom) and "suggest a break" nudges the user can override.
  - A "start tiny" button that launches a 5-minute timer on the first step, presented as a tool rather than an evidence claim.
  - A daily plan that flags when only low-priority/easy tasks were completed for several days.

### Gaps
- No studies were found on the "5-minute rule" or Pomodoro in ADHD samples.
- No ADHD-specific data were found on time-boxing (calendar-blocking tasks) vs to-do lists.

---

## Q6. Reward/motivation: token economies, gamification, variable rewards, "dopamine menu", temptation bundling

### Takeaway
- Gamification produces **small but real** effects in general mHealth (+489 steps/day; high certainty, "trivial"), and novelty effects decay.
- Temptation bundling: **MODERATE** (field RCTs, general population). Effects fade after disruptions but persist when taught as a strategy.
- Dopamine menu: **POPULAR-BUT-UNPROVEN**.
- Token economies and variable rewards for ADHD adults: no evidence found.
- Delay aversion evidence argues for immediate, concrete rewards.

### Cited Findings
- **Gamification meta-analysis (eClinicalMedicine):** 36 RCTs, 49 comparisons, 10,079 adults. Gamified apps produced "trivial increases in steps (489 steps/day [64 to 914])" with high certainty, plus body weight −0.70 kg. There was no effect on blood pressure, lipids or glycaemic control — [eClinicalMedicine meta-analysis](https://www.sciencedirect.com/science/article/pii/S2589537024003778)
- **Novelty decay (HeartSteps micro-randomised trial):** suggestion effects were +66% steps on day 1, then "diminished linearly over time at 2% per day" and vanished by about day 28. Participants said "suggestions became boring after 2–4 weeks" — [Ann Behav Med 2019](https://academic.oup.com/abm/article/53/6/573/5091257)
- **Temptation bundling (Milkman et al. 2014):**
  - Gym-only access to tempting audiobooks raised gym visits 51% (full treatment) and 29% (intermediate) vs control.
  - "Treatment effects declined over time (particularly following Thanksgiving)."
  - 61% then paid for gym-only access as a commitment device.
  - [Management Science abstract](https://ideas.repec.org/a/inm/ormnsc/v60y2014i2p283-299.html)
- **Temptation bundling taught at scale (Kirgios et al. 2020):** 6,792 gym members. Teaching bundling plus a free audiobook raised the likelihood of a weekly workout by 10–14%, with gains persisting up to 17 weeks after the intervention — [OBHDP](https://www.sciencedirect.com/science/article/pii/S074959782030385X)
- **Dopamine menu:**
  - Introduced by Jessica McCabe ("How to ADHD", 2020): appetisers (quick pleasures), mains, sides (paired with dull tasks) and desserts (limit).
  - The Conversation's review cites no direct studies. It cautions that novelty and sugary "short, sharp bursts" habituate quickly, and recommends "healthy main courses" such as exercise, socialising and music.
  - [The Conversation](https://theconversation.com/dopamine-menus-the-science-behind-the-trend-and-how-it-might-help-people-with-adhd-218970)
- **Reward timing in ADHD:** small-to-medium preference for immediate over delayed rewards; real rewards roughly doubled the odds relative to hypothetical ones — [Marx et al. 2021](https://journals.sagepub.com/doi/10.1177/1087054718772138)
- Barkley calls external rewards "motivational prostheses" at the point of performance — [Barkley fact sheet](https://www.russellbarkley.org/factsheets/ADHD_EF_and_SR.pdf)
- Solanto's MCT includes self-reward — [AJP](https://psychiatryonline.org/doi/10.1176/appi.ajp.2009.09081123)

### Inferences
- Gamification should be light and optional (small effects, novelty decay). It should rotate content or form to counter habituation, as JITAI guidance also recommends (Q8).
- Temptation bundling maps well to ADHD's need for immediate reward. The "sides" in the dopamine menu are essentially temptation bundles, which gives that component indirect support; the menu as a whole remains unproven.
- User-defined real rewards (e.g. "after this block: 15 min of game X") likely beat abstract points, given the real-vs-hypothetical finding.
- **App implementation:**
  - A user-built reward list ("menu") that lets the user pair a task with a bundle (a podcast or playlist that unlocks only during the task, via Shortcuts/Focus filters) and schedule a real reward after a block.
  - Optional, rotating micro-celebrations.
  - No points economy by default.

### Gaps
- No studies of token economies for adults with ADHD were found. Paediatric token-economy and behavioural parent training evidence was not retrieved.
- No studies of variable-ratio rewards in ADHD apps were found.
- The JMIR gamification meta-analysis (Mazeas et al. 2022) page rendered empty, so follow-up/durability data after gamification removal are unverified.

---

## Q7. Habit formation (Lally ~66 days, context cues), habit stacking; why streaks harm, and forgiving alternatives

### Takeaway
- Habit automaticity takes a median 66 days, with huge variability (18–254). A single missed day does not derail formation (**MODERATE**; small sample).
- Broken streaks cause disproportionate disengagement beyond the actual behaviour lost (**MODERATE**; 7 experiments, >4,000 participants, general population).
- Streak repair recovers most of the loss.
- Habit stacking and other context-cue methods are consistent with implementation-intention evidence. Direct ADHD evidence was not found.

### Cited Findings
- **Lally et al. 2010:**
  - 96 recruited, 82 analysed, only 39 fitted the model well.
  - Median 66 days to 95% of the automaticity plateau; range 18–254. Exercise took a median of 91 days vs 59–65 for eating/drinking.
  - "A single missed opportunity did not materially disrupt reported automaticity."
  - Limitations: more than half did not reach modelling criteria within 84 days; exercise estimates extrapolated beyond the window.
  - [The Behavioral Scientist summary](https://www.thebehavioralscientist.com/articles/how-long-to-form-a-habit)
- **Silverman & Barasch (J Consumer Research):**
  - Intact vs broken logged streaks changed engagement independently of past behaviour. Study 4 (language learning): 65.84% continued with an intact streak vs 47.98% with a broken one.
  - Field study with 980 employees in a fitness challenge: engagement was more likely on days with an intact streak (b = 0.38, p < .001).
  - Self-attributed breaks led to 28.87% continuing vs 42.00% for externally attributed breaks.
  - Repair option: 85.20% engagement vs 68.66% unrepairable vs 93.14% intact.
  - [Silverman & Barasch paper PDF](https://cdn.prod.website-files.com/685e7d4bd7a0cadecd02f0c9/686287d048dc9706f2d2d85f_Doc%203.pdf)
- INSEAD summary of the same work: 7 experiments, more than 4,000 participants. Recommendations are to avoid highlighting broken streaks in notifications, define streaks flexibly (weekly rather than daily; multiple activity types), provide repair (e.g. a streak freeze) and share responsibility for breaks — [INSEAD Knowledge](https://knowledge.insead.edu/marketing/consumer-streaks-are-motivating-key-keeping-them-alive)
- **Guilt and abandonment:** 16.2% of lapsed activity trackers and 8.9% of lapsed financial trackers reported guilt, "regret," "shame" or self-blame about abandoning tracking — [Epstein et al. CHI 2016](https://depstein.net/assets/pubs/depstein_chi16c.pdf)

### Inferences
- ADHD users face higher day-to-day variability (and, per Q10, high emotion dysregulation), so daily streaks are a predictable failure point. A break is self-attributed and shame-laden, which is the worst case in Silverman & Barasch.
- Lally's finding that a single miss is harmless contradicts the "don't break the chain" framing and supports forgiving metrics.
- **App implementation:**
  - No daily streaks by default.
  - Use "X of the last 7 days" or weekly-target consistency, with automatic grace days.
  - Treat misses as neutral data ("paused", not "broken"), with no broken-streak notifications.
  - Offer a one-tap "fresh start" or repair.
  - Anchor new habits to existing routines via an if-then habit-stack wizard ("After I [existing routine], I will [new tiny habit]").
  - Show a plain-language expectation: "habits take weeks to months; missing a day doesn't reset progress."

### Gaps
- The Lally primary article (Wiley) returned 403, so figures come from a secondary summary.
- No ADHD-specific habit-formation study was found.
- The fresh-start effect (Dai, Milkman & Riis) was not retrieved.

---

## Q8. JITAIs, micro-randomised trials, notification receptivity, timing/frequency, fatigue/habituation

### Takeaway
- JITAI design principles are well specified (decision points, tailoring variables, a "provide nothing" option, receptivity).
- Micro-randomised trials show that notifications produce small proximal effects: +3.9% engagement in 24 hours; a +14% step bump that habituates to zero within about 4 weeks.
- Batching notifications 3×/day improves attention and stress, while turning notifications off raises anxiety and FoMO.
- Receptivity-aware timing improves response by up to 36%.
- Overall: **MODERATE** (general mHealth; none ADHD-specific).

### Cited Findings
- **Nahum-Shani et al. 2018 (JITAI framework):**
  - Components: decision points, tailoring variables, intervention options, decision rules, proximal and distal outcomes.
  - Receptivity is "the individual's transient ability and/or willingness to receive, process, and utilize just-in-time support." "Providing support when the person is not receptive will not be beneficial and may even have negative implications on engagement."
  - Recommends a "provide nothing" option and "brief and clear" content. Proposes countering habituation by "varying of the form, presentation, and timing of content delivery" from a content bank, and supporting autonomy, relatedness and competence.
  - [Ann Behav Med](https://academic.oup.com/abm/article/52/6/446/4733473)
- **HeartSteps MRT:**
  - 37 participants, 6,061 decision points, 5 per day. Randomisation: 0.4 nothing / 0.3 walking suggestion / 0.3 anti-sedentary suggestion.
  - Suggestions overall: +14% steps (≈35 steps) in the next 30 minutes. Day 1: +66% (167 steps), declining about 2% per day to zero by day 28. Walking suggestions: +24%. Anti-sedentary suggestions: no significant effect.
  - [Ann Behav Med 2019](https://academic.oup.com/abm/article/53/6/573/5091257)
- **Bidargaddi et al. 2018 MRT:**
  - 1,255 users of a workplace wellbeing app over 89 days; 6 randomised time points per day.
  - Notifications raised 24-hour engagement by 3.9% (RR 1.039): weekend 8.7% vs weekday 2.5%; peak +11.8% at 12:30 pm on weekends.
  - The decline over time was not statistically significant.
  - [SAHMRI record of JMIR mHealth paper](https://research.sahmri.org.au/en/publications/to-prompt-or-not-to-prompt-a-microrandomized-trial-of-time-varyin)
- **Receptivity prediction (Mishra, Künzler et al., IMWUT 2021):** machine-learning models in a chatbot coach "improved receptivity by up to 36%" vs random timing, and the adaptive model improved over time — [Dartmouth Digital Commons](https://digitalcommons.dartmouth.edu/facoa/4323/)
- **In-the-wild receptivity preprint (2025):**
  - 70 students, 8,162 notifications over 2 weeks; ≈76% completion.
  - Evening (4–8 pm) completion ≈82% vs morning ≈70%; weekends lower.
  - Unlocked phone 85% vs locked ≈78%; walking ≈83%.
  - Notifications arriving while social/communication apps were in use had the lowest completion (≈65%).
  - [arXiv 2508.02817](https://arxiv.org/html/2508.02817v1)
- **Batching** (Fitz et al. 2019, Computers in Human Behavior):
  - 237 participants; conditions: as usual, batched 3×/day (9 am, 3 pm, 9 pm), hourly, or none.
  - 3×/day batching improved inattention (d = −0.65), productivity (d = 0.58), stress (d = 0.56), mood (d = 0.49) and phone control (d = 0.58), with fewer unlocks (d = −0.60).
  - No notifications increased anxiety (d = 0.56) via FoMO. Hourly batching made little difference.
  - [Academia.edu copy](https://www.academia.edu/79274590/Batching_smartphone_notifications_can_improve_well_being)
- **Pielot & Rello 2017:**
  - 30 workers spent 24 hours with no notifications. They felt more productive and less distracted, but worried about missing messages and felt less socially connected.
  - Two years later, 59.1% of those who intended to change their notification habits had maintained the change.
  - [arXiv 1612.02314](https://arxiv.org/pdf/1612.02314)
- A 2025 Annual Review of JITAIs highlights "generally suboptimal engagement of individuals in interventions that leverage digital technologies as currently implemented," people lacking capacity to engage at moments of need, and under-use of social relationships — [Annual Review of Psychology](https://www.annualreviews.org/content/journals/10.1146/annurev-psych-121024-044244)

### Inferences
- Proximal effects of a single prompt are small and habituate within weeks. The app must spend its notification budget carefully: few prompts, high-value moments, rotated content and a default "send nothing".
- Batch non-urgent nudges into 2–3 digests. Reserve real-time alerts for time-critical point-of-performance cues (leave now, transition warnings), which are the ones Barkley's principle justifies.
- Receptivity signals available on iOS/watchOS (phone unlocked, not in a social/communication app, walking, Focus mode, calendar busy/free, time of day) can gate delivery.
- **App implementation:**
  - A notification budget (user-set, e.g. ≤5 per day), with time-critical alerts on the Watch as haptics and everything else in a scheduled summary.
  - Respect Focus modes; suppress prompts during calendar events and while social apps are in the foreground where detectable.
  - Adaptive timing that learns the user's response windows (e.g. a Thompson-sampling bandit) and always includes a no-send arm.
  - A pool of message templates rotated to limit habituation.

### Gaps
- No micro-randomised trial or receptivity study in ADHD samples was found.
- Mehrotra et al. and Pielot's notification-volume studies were not opened.
- JMIR mHealth pages (Bidargaddi full text; the 2023 Drink Less MRT) rendered empty; only the SAHMRI abstract record was read.
- No data were found on Apple Watch haptic-vs-sound receptivity.

---

## Q9. Digital therapeutics for ADHD (EndeavorRx/EndeavorOTC, Inflow, other app RCTs/meta-analyses 2020–2026): outcomes, engagement, retention, commercial fate

### Takeaway
- EndeavorRx showed a statistically significant but small objective attention change (TOVA) in children.
- The adult trial was open-label with no control.
- The company collapsed commercially: about $1 billion valuation to about $34 million, with 2023 revenue of $1.7 million.
- Inflow (a CBT-based app) has only an uncontrolled feasibility study that opened: d = −0.71 in completers, about 53% retained at 7 weeks. It was acquired by Cerebral in March 2026.
- Pooled digital interventions for ADHD: g ≈ −0.32.
- **Evidence for ADHD apps overall: WEAK-to-MODERATE.**

### Cited Findings
- **EndeavorRx pivotal trial (STARS-ADHD), FDA De Novo review:**
  - 348 children (mean age 9.6), randomised to EndeavorRx (n = 180) or digital control (n = 168).
  - TOVA Attention Performance Index: 0.93 vs 0.03 (p = .006).
  - Three of five secondary measures (ADHD-RS total, ADHD-RS inattention, Impairment Rating Scale) "numerically favored" EndeavorRx. Of 11 response-rate outcomes, 3 were statistically significant.
  - Adverse events 6.7%, e.g. decreased frustration tolerance 2.8%.
  - Indication: "to improve attention function as measured by computer-based testing" in ages 8–12, "as part of a therapeutic program."
  - [FDA DEN200026](https://www.accessdata.fda.gov/cdrh_docs/reviews/DEN200026.pdf)
- **Adult STARS-ADHD-Adult (company press release):**
  - 221 adults; multicentre, open-label, no control; about 25 minutes/day, 5 days/week for 6 weeks.
  - TOVA ACS +6.46 (p < .0001); 32.7% achieved ≥30% ADHD-RS reduction; 45.8% had clinically meaningful quality-of-life improvement.
  - [Business Wire, May 2023](https://www.businesswire.com/news/home/20230503005295/en/Adults-with-ADHD-See-Significant-Improvements-in-Attention-ADHD-Symptoms-and-Quality-of-Life-in-Clinical-Trial-of-Akili%E2%80%99s-EndeavorRx%C2%AE-Video-Game-Based-Therapeutic)
- **Akili commercial fate:**
  - Sold to Virtual Therapeutics for about $34 million (43¢/share, closing Q3 2024).
  - 2023 revenue $1.7 million ($1.2 million OTC; $523,000 prescription); net loss $59.5 million.
  - Failed to secure payer coverage; pivoted away from prescription in September 2023.
  - Layoffs of about 30% (January 2023) and 46% (April 2024); Nasdaq delisting notice in October 2023.
  - [MedTech Dive](https://www.medtechdive.com/news/akili-sell-34m-virtual-therapeutics-digital/717570/)
- Further Akili detail (HLTH): launched at "an approximate $1 billion valuation"; revenue $538,000 (2021) and $323,000 (2022); EndeavorOTC priced at $129.99/year; Q1 2024 revenue $383,000 vs $749,000 in Q4 2023; about 96% value decline — [HLTH](https://hlth.com/insights/articles/game-over-insert-coin-to-continue-virtual-therapeutics-makes-move-to-purchase-akili-2024-06-07)
- **Inflow feasibility study (PLOS Digital Health 2022):**
  - 7-week open trial with no control: 241 recruited, 205 enrolled, 93 completed efficacy assessments.
  - Features: CBT modules (time management, organisation), daily audio/text exercises, 1- or 14-day challenges, community prompts, journal, live clinician Q&A.
  - Median 27 app opens over 7 weeks (3.43 per week); median session 3.40 minutes; "52.7% retention" at week 7.
  - Completers' effects: total symptoms d = −0.71; inattention d = −1.0; hyperactivity/impulsivity d = −0.41; functional impairment d = −0.46.
  - Authors note: "only one previous study has examined a CBT-based app for adults with ADHD."
  - [PLOS Digital Health](https://journals.plos.org/digitalhealth/article?id=10.1371%2Fjournal.pdig.0000083)
- **Cerebral acquires Inflow (24 March 2026):** Inflow "has been used by hundreds of thousands of people." The release cites "an 8-week randomized controlled trial" with significant improvement in ADHD symptoms and quality of life, and says higher engagement was associated with greater improvement. This is company-reported — [Business Wire](https://www.businesswire.com/news/home/20260324103905/en/Cerebral-Acquires-Leading-ADHD-Behavioral-App-Inflow-Expanding-Access-to-Continuous-Care)
- **Digital ADHD intervention meta-analysis:** 23 RCTs; g = −0.32 overall; guided = self-guided; median age about 10 — [ScienceDirect 2025](https://www.sciencedirect.com/science/article/pii/S2451958825001186)
- **Systematic review of ADHD apps (Frontiers in Public Health 2025):** 14 studies. FOCUS ADHD achieved high adoption but "did not significantly improve overall treatment adherence or knowledge"; "further study is required to validate their effectiveness over a long period"; apps work best as adjuncts — [Frontiers Public Health](https://www.frontiersin.org/journals/public-health/articles/10.3389/fpubh.2025.1483923/full)
- **Wider context: mental-health apps benchmark** (93 apps with ≥10,000 installs):
  - Median daily open rate 4.0%; 15-day retention 3.9%; 30-day retention 3.3%.
  - Peer-support apps had the highest open rate (17.0%). Breathing apps had 0.0% 30-day retention.
  - [Baumel et al. 2019, JMIR (repository PDF)](https://academicworks.medicine.hofstra.edu/cgi/viewcontent.cgi?article=6839&context=publications)

### Inferences
- Akili's collapse shows that regulatory clearance of a narrow neurocognitive endpoint (TOVA) did not produce payer uptake, consumer retention or meaningful functional change. A planner app should target function (tasks done, lateness) rather than lab attention scores.
- Inflow's use pattern (about 3.4 opens per week, sessions about 3.4 minutes) is a realistic engagement benchmark for an ADHD CBT app. Micro-sessions under 5 minutes should be the design unit.
- Inflow's 52.7% at 7 weeks is about 10× the typical mental-health-app 30-day retention (3.3%). This suggests an ADHD-specific CBT curriculum with community features retains better, though the waitlist-recruited sample was likely motivated.
- **App implementation:** Design for 1–3-minute interactions, several times a week. Measure functional outcomes (planned-vs-done, on-time rate, self-rated weekly functioning). Treat engagement as a means, not the goal.

### Gaps
- Kollins et al. 2020 (Lancet Digital Health) full text was not opened. Whether ADHD-RS/IRS differences were statistically significant is only described as "numerically favored" in the FDA document read.
- EndeavorOTC's June 2024 FDA authorisation was seen only as a search-result headline and not opened. Virtual Therapeutics' subsequent handling of Endeavor products (2025–26) was not verified.
- The Inflow RCT cited by Cerebral was not located or opened.
- Other adult ADHD app RCTs from 2020–2026 (internet-delivered CBT, e.g. Swedish trials) could not be searched after the web-search budget was exhausted.
- The "A one-stop shop" real-world app-use study (Internet Interventions 2025) was rate-limited (429) and not read.

---

## Q10. Emotional regulation tools usable in-app: self-compassion, reframing after missed plans, check-ins

### Takeaway
- Emotion dysregulation is large and near-core in adult ADHD (g = 1.17 vs controls; 34–70% prevalence).
- Low self-compassion predicts poorer quality of life in ADHD adults (correlational; **WEAK** as intervention evidence).
- Self-forgiveness after procrastination reduces subsequent procrastination in general students (**MODERATE**, longitudinal).
- DBT groups did not beat TAU on emotion regulation.
- Cognitive restructuring is part of **STRONG** CBT packages.

### Cited Findings
- **Beheshti et al. 2020 meta-analysis:** 13 studies, 2,535 participants. Adults with ADHD showed "significantly higher levels of general ED (Hedges' g = 1.17)" vs controls; ED correlated with symptom severity (r = 0.54) — [DOAJ record, BMC Psychiatry](https://doaj.org/article/559c71e475cc4cd2a6228b2e9c2f75a8)
- **PLOS One systematic review** (22 articles): emotion dysregulation affects "34–70% of affected adults" (citing Shaw et al.). Adults with ADHD use more suppression and less reappraisal — [PLOS One](https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0280131)
- **Paley et al. 2025** (n = 32 adults with ADHD): lowest scores on "common humanity" and highest on "overidentification"; self-compassion explained 32.3% of quality-of-life variance vs 28.2% for ADHD symptoms. Small volunteer sample — [Br J Occup Ther](https://journals.sagepub.com/doi/10.1177/03080226241296684)
- **Karaçul & Arslan 2025** (J Atten Disord; 442 Turkish college students; correlational): higher self-compassion was associated with better emotion regulation and partly mediated the link between adverse childhood experiences and ADHD symptoms — [ADDitude summary](https://www.additudemag.com/self-compassion-improves-emotional-regulation-adhd/)
- **Wohl, Pychyl & Bennett 2010** (134 first-year students, two exam periods): students who forgave themselves for procrastinating before the first exam "were less likely to procrastinate before the second round," mediated by reduced negative affect — [BPS Research Digest](https://www.bps.org.uk/research-digest/cure-procrastination-forgive-yourself)
- **DBT-based group:** no DERS difference vs TAU at 14 weeks, though both groups improved — [BMC Psychiatry](https://link.springer.com/article/10.1186/s12888-022-04356-6)
- **Safren CBT:** includes cognitive restructuring for "adaptive thinking" — [JAMA](https://jamanetwork.com/journals/jama/fullarticle/186469)

### Inferences
- Missed plans are the highest-risk emotional moment in a planner app. The self-forgiveness evidence and the overidentification pattern suggest the app's response to a miss should normalise it ("common humanity"), de-personalise it and move straight to a re-plan. This matches Silverman & Barasch's finding that self-attributed failures are most demotivating.
- **App implementation:**
  - A "missed it? re-plan" flow with neutral language: an auto-offered new slot plus an optional 20-second reframe ("Lots of people with ADHD hit this; what's one small next step?").
  - An optional 1-tap mood/energy check-in used to size the day's plan (fewer tasks on low-energy days).
  - An optional brief self-compassion or breathing exercise.
  - No red overdue counts or shame colours.

### Gaps
- No RCT of a self-compassion intervention in adults with ADHD was found. Beaton et al. 2022 (J Clin Psychol) returned 403.
- Mindfulness meta-analyses for adult ADHD were not retrieved.

---

## Q11. Environmental design: friction and distraction blocking (one sec, Opal)

### Takeaway
One sec-style friction (a brief forced delay with a choice to dismiss) reduced target-app opening attempts substantially in general-population users. Evidence comes from an uncontrolled 6-week field study, a preregistered dismantling experiment and a 1,039-user real-world log analysis. The effect plateaus after about 20 days and persists to about 13 weeks. **MODERATE** (general population; not ADHD-specific). Opal: no peer-reviewed evidence found.

### Cited Findings
- **Grüning, Riedel & Lorenz-Spreen 2023 (PNAS),** as summarised by a secondary review:
  - Field study (~280 participants, 6 weeks) plus a preregistered dismantling experiment (~500 participants).
  - "57% reduction in app openings" (a figure one sec cites); "approximately 36% of opening attempts were abandoned mid-pause."
  - The headline study "a field study without a control group, not a randomized trial." One author is the app's developer.
  - Dismantling result per this review: "the forced delay itself" was the active ingredient, and "a pure 'are you sure?' message without friction did nothing."
  - [finit review of one sec](https://getfinit.com/blog/one-sec-review)
- One sec's own page claims the app "reduces app usage by 57% and significantly improves life satisfaction" (company source) — [one sec research page](https://one-sec.app/max-planck-study/)
- **Haliburton et al. CHI 2024** (longitudinal in-the-wild study of one sec):
  - 1,039 users, averaging 13.4 weeks of historical data; 90% used the default 6-second breathing exercise.
  - Open attempts showed a significant negative exponential decline (τ = −0.772), plateauing after about 20 days. The share of attempts dismissed also declined over time, interpreted as remaining openings being more intentional.
  - 26.9% took breaks averaging 9.15 days, and effects recovered quickly on resumption.
  - The authors summarise Grüning et al. as finding that "offering the option to dismiss consumption has the strongest impact."
  - [CHI 2024 PDF](https://www.medien.ifi.lmu.de/pubdb/publications/pub/haliburton2024chi/haliburton2024chi.pdf)
- **Conflict:** the finit review attributes the effect to the forced delay itself, while Haliburton et al. attribute the strongest effect to the dismiss option. The primary PNAS paper could not be opened (PMC reCAPTCHA; PNAS 403), so this is unresolved.

### Inferences
- A short (about 6-second) delay with a clear "close / continue with intention" choice is a well-supported, low-annoyance friction pattern. On iOS it is implementable via the Screen Time API (FamilyControls/ManagedSettings shields) and Shortcuts automations.
- **App implementation:**
  - Optional "pause before" friction on user-chosen distracting apps during scheduled focus blocks: a 5–10-second breathing screen showing the current task and its first step, with buttons "back to [task]" and "open anyway (1 min)".
  - Should be off by default and scheduled to the plan, not always-on.

### Gaps
- No peer-reviewed study of Opal, or of hard app-blocking vs soft friction, was found.
- No ADHD-specific friction study was found.
- The primary PNAS numbers are unverified (secondary sources only).

---

## Q12. Acute exercise effects on executive function (meta-analyses): scheduling exercise near study

### Takeaway
**MODERATE.** In adults with ADHD, acute exercise improves inhibitory control moderately (g = 0.55; another meta-analysis gives SMD −0.65) and core symptoms slightly (g = 0.23). Chronic-exercise evidence is mixed or heterogeneous. NICE advises regular exercise as general health advice.

### Cited Findings
- **2026 systematic review/meta-analysis in adults with ADHD** (14 studies; 8 pooled): acute exercise improved inhibitory control (g = 0.55, 95% CI 0.32–0.79) and core symptoms (g = 0.23, 95% CI 0.03–0.43). Chronic exercise showed "mixed results" and could not be pooled; the authors call the evidence "preliminary" — [ScienceDirect 2026](https://www.sciencedirect.com/science/article/abs/pii/S1469029226000282)
- **JOGH 2025 meta-analysis** (8 articles, 14 studies, 373 adults with ADHD): overall inhibitory control SMD −1.14; acute −0.65 (95% CI −1.10 to −0.20); chronic −1.77. Modality estimates varied widely (Pilates −2.22, cycling −0.67, yoga 0.01) — [JOGH](https://jogh.org/2025/jogh-15-04025)
- **NICE 1.6.1:** "stress the value of a balanced diet, good nutrition and regular exercise" — [NICE NG87 copy](https://docs.bvsalud.org/biblioref/2022/02/1357854/attention-deficit-hyperactivity-disorder-diagnosis-and-managem_kempx2v.pdf)

### Inferences
- The two meta-analyses overlap (both roughly 8 articles/14 studies). The very large chronic and modality SMDs in JOGH suggest small-study inflation, so the conservative figure (acute g ≈ 0.55 on inhibition) should anchor claims.
- Acute benefits are short-term by design, which supports scheduling a brief bout (e.g. 10–20 minutes of moderate aerobic activity) immediately before demanding cognitive work.
- **App implementation:** Offer an optional "movement primer" block auto-suggested before scheduled study or deep-work blocks (using HealthKit workout detection to confirm). Frame it as "may help focus for the next session", not as a treatment claim.

### Gaps
- The time window of acute exercise benefits (minutes to hours after exercise) was not quantified in the sources opened. The Chang et al. 2012 general meta-analysis was not retrieved.
- Optimal intensity and duration for adults with ADHD were not established.

---

## Q13. Sleep interventions and wind-down routines (context only)

### Takeaway
Sleep and circadian problems are highly prevalent in adults with ADHD (insomnia up to 80%; delayed timing 73–78%). Chronotherapy RCT evidence is mixed: melatonin shifted the rhythm but did not advance sleep onset, while ADHD symptoms fell 14%. **Context only; app role limited to wind-down and consistent timing.**

### Cited Findings
- Frontiers in Psychiatry 2025 perspective: "insomnia and sleep disturbances affect up to 80% of adults with ADHD"; delayed sleep–wake timing in 73–78%; dim-light melatonin onset delayed about 90 minutes vs controls — [Frontiers in Psychiatry 2025](https://www.frontiersin.org/journals/psychiatry/articles/10.3389/fpsyt.2025.1697900/full)
- **van Andel et al. 2022 RCT:**
  - 49 adults with ADHD plus delayed sleep phase; 3 weeks of melatonin 0.5 mg, placebo, or melatonin plus 10,000-lux morning light. All arms received sleep-hygiene education and weekly coaching calls.
  - "Sleep onset and wake times had not significantly advanced in any group."
  - Melatonin reduced ADHD symptoms by 14% (33 → 27).
  - [J Biol Rhythms](https://journals.sagepub.com/doi/10.1177/07487304221124659)
- **NICE 1.8.17:** "Monitor changes in sleep pattern (for example, with a sleep diary)" — [NICE NG87 copy](https://docs.bvsalud.org/biblioref/2022/02/1357854/attention-deficit-hyperactivity-disorder-diagnosis-and-managem_kempx2v.pdf)

### Inferences
- **App implementation:**
  - An optional wind-down routine: a Watch reminder at a consistent time, a "tomorrow's first task" brain-dump to offload worry, and a screen-off cue.
  - Pull sleep duration from HealthKit rather than asking for manual logging.
  - Use sleep to size the next day's plan.
  - No medical sleep claims.

### Gaps
- No CBT-I trial in adults with ADHD was opened. The 2026 J Atten Disord sleep-treatment study (van der Ham et al.) was located but not opened.

---

## Q14. Self-monitoring: benefits and harms (over-tracking, anxiety, abandonment); minimum viable tracking

### Takeaway
Self-monitoring is an embedded component of effective CBT (e.g. distraction logging) and JITAI tailoring. The main harms are collection burden (the most common reason for abandoning tracking), discomfort with what the data reveal, and guilt after lapsing. **MODERATE** (HCI surveys; not ADHD-specific).

### Cited Findings
- **Epstein et al. CHI 2016** (193 survey respondents plus 12 interviews):
  - Six reasons for abandoning self-tracking: collection/integration burden (most common), data-sharing concerns, "discomfort with revealed information," data quality, "learned enough," and changed life circumstances.
  - 16.2% of physical-activity and 8.9% of finance trackers reported guilt about abandoning.
  - Recommends designing for "happy abandonment" and tailored re-engagement.
  - [CHI 2016 PDF](https://depstein.net/assets/pubs/depstein_chi16c.pdf)
- **JITAI guidance:** tailoring can use "passive assessments (minimal engagement required)" rather than active self-report, and "brief and clear" content to limit burden — [Ann Behav Med](https://academic.oup.com/abm/article/52/6/446/4733473)
- **Mental-health apps:** tracker apps had a 6.3% median daily open rate, vs 4.0% across all apps — [Baumel et al. 2019](https://academicworks.medicine.hofstra.edu/cgi/viewcontent.cgi?article=6839&context=publications)
- **CBT evidence base:** Safren's distractibility module used written distraction tracking — [JAMA](https://jamanetwork.com/journals/jama/fullarticle/186469)

### Inferences
- Minimum viable tracking for this app is (1) task done or not (captured implicitly when the user checks it off) and (2) an optional single weekly self-rating of functioning and mood. Everything else should be passive (HealthKit sleep/steps, calendar adherence) or opt-in.
- Show trends weekly, not daily, and never lead with deficits.
- **App implementation:** Default to zero mandatory logging. Offer a weekly "how did this week go?" slider and auto-derived stats (planned vs done, on-time rate). Include "graduation" messaging when routines are stable ("you may not need reminders for X any more").

### Gaps
- No ADHD-specific study of over-tracking harms or anxiety was found.

---

## Q15. Published HCI research on ADHD and technology; neurodivergent design guidelines (reading load, choice overload, predictability, personalisation, user control)

### Takeaway
HCI reviews criticise ADHD tech research as deficit-focused, child-centric and rarely participatory. They call for co-design, strengths-based framing and user agency. The W3C cognitive accessibility guidance (COGA) gives concrete patterns: plain language, focus support, not relying on memory, personalisation, error recovery and no timeouts. **Guideline/consensus level evidence.**

### Cited Findings
- **Spiel, Hornecker, Williams & Good, CHI 2022:**
  - "Technologies are largely used to 'mitigate' the experiences of ADHD which are perceived as disruptive to neurotypical standards of behaviour."
  - Minimal HCI work invites people with ADHD to co-create or shape research aims.
  - Calls for addressing the "epistemic imbalance in meaning making" and moving away from neuro-normative outcomes.
  - [UvA repository record](https://dare.uva.nl/personal/pure/en/publications/adhd-and-technology-research--investigated-by-neurodivergent-readers(b5158a6b-ee52-48a7-b4be-772d430bad4a).html)
- **Cibrian et al.-affiliated Frontiers in Digital Health 2022** ("Interdisciplinary Tensions"):
  - Of 51 studies identified, "only 12 reported RCTs examining DHI outcomes in children or adolescents with ADHD," and none reached implementation research.
  - Recommends co-design with people with ADHD, treating usability as equally important to efficacy, and standardised reporting.
  - [Frontiers in Digital Health](https://www.frontiersin.org/journals/digital-health/articles/10.3389/fdgth.2022.876039/full)
- **W3C "Making Content Usable for People with Cognitive and Learning Disabilities"** — 8 objectives:
  1. Help users understand what things are.
  2. Help them find what they need.
  3. Use clear content ("easy words, short sentences and blocks of text").
  4. Help them avoid and correct mistakes ("Ask the user only for what you need!").
  5. Help them focus ("Avoid distracting the user from their tasks").
  6. Ensure processes don't rely on memory.
  7. Provide help.
  8. Support adaptation and personalisation.

  Cross-cutting: involve users with cognitive disabilities in design, reduce cognitive load and choices, avoid time pressure and timeouts — [W3C COGA](https://www.w3.org/TR/coga-usable/)
- **Body-doubling HCI:** proposes a space/time × mutuality design space and notes gaps in asynchronous, low-pressure tools — [Eagle et al. TACCESS](https://leyabreanna.com/papers/body_double_taccess.pdf)
- **JITAI engagement** is linked to autonomy, relatedness and competence (user agency, optimal challenge) — [Ann Behav Med](https://academic.oup.com/abm/article/52/6/446/4733473)

### Inferences
- These principles combine into app requirements:
  - One primary action per screen.
  - Show only "Now / Next" by default, hiding the full backlog, to limit choice overload.
  - Predictable, consistent layouts.
  - Everything undoable.
  - No time-pressured dialogs.
  - Plain-language microcopy (short sentences, Year 7–8 reading level).
  - Deep personalisation (notification style, colour and sound, reward types, gamification on/off).
  - Strengths-based, non-normative framing ("works with your brain", not "fix your deficits").
- **App implementation:**
  - A "Now" screen with a single current task and its first step.
  - Progressive disclosure of lists.
  - Settings presets ("minimal", "gentle nudges", "high structure") to avoid configuration overload at onboarding.
  - A co-design/beta panel of ADHD users.

### Gaps
- The Cibrian et al. IDC 2022 review "Designing for Care Ecosystems" (ACM) returned 403.
- No quantitative study of choice overload or reading load specific to ADHD app users was found. The Chernev choice-overload meta-analysis was not retrieved.

---

## Q16. Why ADHD users abandon apps; what improves long-term retention

### Takeaway
- General mental-health apps retain only about 3% of users at 30 days.
- Reported abandonment drivers include tracking burden, lost novelty (habituation within 2–4 weeks), shame after lapses/broken streaks, and notification fatigue.
- Features associated with better retention are human/peer support (supportive accountability; peer-support apps have the highest open rates), ADHD-specific CBT curricula with micro-sessions (Inflow 52.7% at 7 weeks, uncontrolled), repairable or forgiving progress metrics, and receptivity-timed, sparse prompts.
- **MODERATE for general mHealth; WEAK for ADHD-specific.**

### Cited Findings
- **Retention benchmarks:** 15-day 3.9%, 30-day 3.3%; peer-support apps 17.0% daily open rate; breathing apps 0.0% 30-day retention — [Baumel et al. 2019](https://academicworks.medicine.hofstra.edu/cgi/viewcontent.cgi?article=6839&context=publications)
- **Inflow (ADHD, CBT):** 52.7% retention at week 7, median 3.43 uses/week, 3.40-minute sessions; community features plus daily exercises. Uncontrolled and waitlist-recruited — [PLOS Digital Health](https://journals.plos.org/digitalhealth/article?id=10.1371%2Fjournal.pdig.0000083)
- **Tracking abandonment:** burden was the top reason; others were discomfort with data and guilt — [Epstein et al. 2016](https://depstein.net/assets/pubs/depstein_chi16c.pdf)
- **Novelty decay:** "suggestions became boring after 2–4 weeks"; effect gone by day 28 — [HeartSteps](https://academic.oup.com/abm/article/53/6/573/5091257)
- **Broken streaks:** a break reduces continuation (65.84% → 47.98%); a repair option restores most of it (85.20% vs 68.66%) — [Silverman & Barasch](https://cdn.prod.website-files.com/685e7d4bd7a0cadecd02f0c9/686287d048dc9706f2d2d85f_Doc%203.pdf)
- **Human support:** increases adherence more than automated reminders — [Mohr et al. 2011](https://research.vu.nl/ws/files/2936910/2011%20Mohr)
- **Engagement is a field-wide problem:** "generally suboptimal engagement" with digital interventions as currently implemented — [Annual Review of Psychology 2025](https://www.annualreviews.org/content/journals/10.1146/annurev-psych-121024-044244)
- **Commercial failure:** Akili's collapse despite FDA clearance (revenue $1.7 million in 2023; sale for about $34 million) shows that regulatory status alone did not drive uptake — [MedTech Dive](https://www.medtechdive.com/news/akili-sell-34m-virtual-therapeutics-digital/717570/)
- **Friction retention:** one sec users taking breaks (26.9%) recovered effects quickly on return, suggesting that tools tolerant of lapses can be resumed without loss — [Haliburton et al. CHI 2024](https://www.medien.ifi.lmu.de/pubdb/publications/pub/haliburton2024chi/haliburton2024chi.pdf)

### Inferences
- Retention strategy for an ADHD planner should explicitly design for lapse and return: users will stop, and the app should make coming back shame-free.
  - Example: a "welcome back" flow that archives stale tasks, offers a 3-task restart and makes no reference to missed days.
- Build in a low-cost social/human layer (partner check-ins, clinician sharing, co-working presence), since support is the most consistent engagement lever across sources.
- Rotate content and vary prompts to counter 2–4-week habituation. Refresh reward options periodically.
- **App implementation:**
  - A lapse-tolerant re-entry flow.
  - An optional accountability partner or clinician share.
  - Content and prompt rotation.
  - Notifications capped and receptivity-timed.
  - Onboarding kept under 2 minutes, with defaults that work with no configuration.
  - A 1-tap capture everywhere (Watch, Siri, widget, share sheet) to minimise collection burden.

### Gaps
- No peer-reviewed study specifically on why adults with ADHD abandon planner/productivity apps was opened. The Internet Interventions 2025 real-world Inflow-type study was rate-limited.
- No ADHD-specific data compare retention across feature sets (e.g. with vs without social features).
