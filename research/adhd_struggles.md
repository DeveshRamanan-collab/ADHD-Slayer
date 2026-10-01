# Day-to-day struggles of adolescents (16+) and adults with ADHD: catalogue for a medication-centred iPhone/Apple Watch planning app

Scope note: the research was run on 28 Sep 2026. PubMed/PMC pages were blocked by a reCAPTCHA and Europe PMC by robots.txt. Reddit was blocked by the fetch proxy. The Lancet Psychiatry, Wiley (Acta Psychiatr Scand), ACM DL and one BMC paper returned 403/429 errors. Findings below therefore come from journal pages that could be opened (Frontiers, PLOS, Springer/BMC, SAGE, ScienceDirect abstracts, arXiv), evidence-summary sites, and lived-experience/advocacy sources (ADDitude, ADHD UK, ADHD Australia, Understood, Healthline). Each section uses the headings Takeaway / Cited Findings / Inferences / Gaps. Within those: "Looks like" is (a), what the struggle looks like in daily life. "Evidence" is (b), how common or serious it is. "Tool failure" is (c), what current tools fail to do. "App implication" is (d). Tool failure and App implication are inferences unless they carry a citation. ADDitude reader surveys are self-selected, highly engaged samples, so treat their percentages as upper-bound signals of complaint salience, not population prevalence.

---

## 1. Executive-function deficits (time blindness, initiation, working memory, prospective memory, planning, switching, hyperfocus, waiting mode, duration estimation)

### Takeaway
Time processing is impaired across every timing paradigm studied. Planning, not remembering the plan, is where prospective-memory failures come from. Procrastination is moderately and robustly linked to ADHD symptoms. Hyperfocus is a real, measurable counterpart to distractibility. For the app, time has to be made external and visible, planning has to be scaffolded, and hyperfocus needs interrupting as much as low focus needs prompting.

### Cited Findings
**Time blindness / time perception (Barkley's construct; empirical support)**
- Meta-analysis of 55 studies (Marx, Cortese, Koelch, Hacker, *JAACAP*, published online 2021) found "significant deficits in individuals with ADHD across all timing paradigms": time discrimination (25 studies, n=1,633) medium deficit; time estimation (8 studies, n=1,024) small-to-medium increase in error; time production (7 studies, n=380) small increase in error; time reproduction (26 studies, n=2,364) medium increase in error. The authors propose that timing tasks be part of clinical assessment. Limitation: medication effects could not be assessed — [ADHD Evidence Project summary of Marx et al. 2021](https://www.adhdevidence.org/blog/time-blindness-found-to-be-a-consistent-feature-of-adhd)
- Lived experience (CSCW 2026 interview study, 22 adults with ADHD plus a 20-person speed-dating study) identified "time perception disorders: chronic misestimation of task duration; plans based on rare hyperfocus episodes". Quote from P5: *"Unless I pay special attention, my perception of time is as if I want to deliberately forget it."* — [Chen, Meng & Nie 2026, arXiv/CSCW](https://arxiv.org/html/2603.17258v1)

**Duration estimation / planning fallacy**
- Time-estimation and production tasks show small-to-medium error increases in ADHD (above) — [Marx et al. 2021 summary](https://www.adhdevidence.org/blog/time-blindness-found-to-be-a-consistent-feature-of-adhd)
- Adults with ADHD report building plans around rare hyperfocus episodes, which systematically under-budgets time — [Chen et al. 2026](https://arxiv.org/html/2603.17258v1)

**Task initiation / procrastination**
- Japan, n=490 adults: ADHD symptoms correlated r=0.42 with procrastination (p<0.001). The authors describe procrastination as "one of the most prevalent difficulties faced by adults with ADHD" and note that chronic procrastination is more frequent in ADHD regardless of gender — [Oguchi et al. 2021, *Frontiers in Psychology*](https://www.frontiersin.org/journals/psychology/articles/10.3389/fpsyg.2021.708579/full)
- "Task initiation paralysis": psychological inertia that blocks action despite motivation and understanding. P17: *"I obviously want to brush my teeth and wash my face, but I stay in bed all the time; there will be a big start-up difficulty."* Also "deadline addiction", an over-reliance on crisis-driven productivity — [Chen et al. 2026](https://arxiv.org/html/2603.17258v1)

**Prospective memory (PM) and planning**
- 45 adults with ADHD vs 45 matched controls on a complex (event-based) PM paradigm. **Task planning showed a large deficit (d=1.60)**. Plan recall after 40 min did not differ (~86.5% in both groups). Self-initiation was 40% (ADHD) vs 56% (controls), not significant. **Task switching showed a moderate deficit (d=0.94)**. Conclusion: "Impairments of prospective memory mainly emerged from deficient planning abilities". Once plans were made, retention and execution were largely intact — [Fuermaier et al. 2013, *PLOS ONE*](https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0058338) (foundational, pre-2018)

**Working memory**
- The Alderson et al. 2013 meta-analysis (*Clinical Psychology Review*) is rated "strong evidence" that verbal and visuospatial working-memory deficits persist into adulthood. Numeric effect sizes could not be extracted from the accessible summary — [Resistaa summary of Alderson et al. 2013](https://www.resistaa.com/en/adhd/research/alderson-working-memory-meta-analysis)

**Hyperfocus / getting stuck**
- Two samples (pilot n=251, replication n=372) found that higher ADHD symptoms go with more total, dispositional and frequent hyperfocus across school/work, hobbies and screen time. This supports hyperfocus as "a potentially separable feature of the ADHD syndrome" and introduced the Adult Hyperfocus Questionnaire — [Hupfeld, Abagis & Shah 2019, *ADHD Atten Def Hyp Disord*](https://link.springer.com/article/10.1007/s12402-018-0272-y)

**"Waiting mode"**
- Waiting mode is not a clinical term. It is "commonly reported anecdotally": people feel they cannot start other tasks when something is scheduled later, and fill the time with low-effort activity such as scrolling. "Clinical research hasn't investigated this phenomenon directly." Proposed explanations are compensation after repeated missed appointments and anxiety about forgetting. Suggested coping strategies include early-in-day appointments, backward time estimation, multiple alarms, and lists of small "side quests" — [Healthline](https://www.healthline.com/health/adhd/adhd-waiting-mode)

### Inferences
- **Tool failure:** Conventional reminders fire once at a clock time and are dismissed. They show no elapsed or remaining time, so they do nothing for the core deficits in duration discrimination and reproduction. To-do apps assume the user can plan and sequence, which is the largest deficit (d=1.60). They offer nothing for hyperfocus, where the problem is not stopping, and nothing for waiting mode, where an upcoming appointment "consumes" the whole preceding block.
- **App implication:** (i) make time ambient and visual: countdown rings, "leave-by" times, Live Activities, Watch complications and haptics. (ii) Put the effort into guided planning and the first step. Fuermaier suggests that once a plan exists, retention is fine. (iii) Learn a personal estimation multiplier from estimated vs actual durations. (iv) Give staged transition warnings, since task switching has d=0.94. (v) Run a waiting-mode protocol: a hard "leave-by" alarm with buffer, so the time before an appointment feels safe to use.

### Gaps
- No accessible meta-analytic numbers for adult working-memory effect sizes (PubMed/PMC blocked).
- No study found that directly measures the planning fallacy (task-duration underestimation in real life) in adult ADHD. Evidence is lab timing tasks plus qualitative reports.
- Waiting mode has no peer-reviewed research, per Healthline. Reddit threads on it could not be accessed.
- Barkley's primary texts were not opened. "Time blindness" is supported here via the Marx meta-analysis rather than Barkley directly.

---

## 2. Emotional dysregulation, RSD, shame spirals, all-or-nothing thinking, burnout, overwhelm/paralysis, boredom, novelty seeking, app abandonment

### Takeaway
Emotional dysregulation is large and common in adult ADHD: a pooled g of 1.17, with about 70% of adult patients reporting it. Boredom proneness is a moderate and consistent correlate (r=0.40). RSD is widely endorsed by patients but supported only by small qualitative studies. The generic pattern of app abandonment (about 4% of users still active at day 15 across mental-health apps) is likely to be worse for users who are novelty-seeking and averse to shame. Design must assume lapses and make coming back painless.

### Cited Findings
**Emotional dysregulation (ED)**
- Meta-analysis, 13 studies, N=2,535 adults. General ED vs controls **Hedges' g=1.17**. Emotional lability **g=1.20**. Negative emotional responses **g=1.12**. Emotion recognition **g=0.63**. Within the ADHD group, ED correlates with symptom severity (r=0.54). "About 70% of adult patients with ADHD report ED or emotional lability" — [Beheshti, Chavanon & Christiansen 2020, *BMC Psychiatry*](https://link.springer.com/article/10.1186/s12888-020-2442-7)
- Women aged 40–59 (ADDitude survey, n≈1,500) rated emotional dysregulation as "life-altering" in 56% of cases during perimenopause/menopause — [ADDitude 2022/2025](https://www.additudemag.com/menopause-symptoms-adhd-survey/)

**Rejection sensitive dysphoria (evidence status)**
- RSD is **not a DSM-5-TR diagnosis**. The term was popularised by psychiatrist William Dodson from the 1990s. Only **five qualitative studies** exist, with samples of 4–43. The largest, Ginapp et al. 2023 (n=43 young adults, 84% female), found 77% reported struggling with RSD. Others are Dodson et al. 2024 (n=4, "episodic attacks of physical and emotional pain, intense shame"), Sandland 2025 (n=7, self-silencing and avoidance) and Rowney-Smith et al. 2026 (n=5, withdrawal, masking, bodily sensations). There is no validated measure — [Psychology Today review, Apr 2026](https://www.psychologytoday.com/us/blog/if-i-be-waspish/202604/rejection-sensitivity-dysphoria-the-actual-research)

**Shame spirals, self-blame, all-or-nothing thinking**
- Interviewees described "pervasive self-blame" and "mood swings derailing productivity". The recommended designs were "mood-adaptive interfaces … to prevent failure spirals", "Emotionally Aware Pause Days", and "ideal vs baseline" plans with progress preserved across missed days — [Chen et al. 2026](https://arxiv.org/html/2603.17258v1)
- ADDitude writer on the ADHD tax: *"We can't fix the ADHD Tax. But we can stop blaming ourselves for paying it."* — [ADDitude](https://www.additudemag.com/adhd-tax-late-fees-fines-shame/)
- A commercial/opinion piece with no peer-reviewed data argues that streaks fail ADHD users. It gives three reasons: the streak becomes the goal; the break is inevitable and triggers all-or-nothing abandonment of both app and habit; and the external pressure is resisted. It proposes optional streaks, flexible frequency goals, "streak insurance" or grace periods, and percentage-based tracking — [Klarity Health](https://www.helloklarity.com/post/breaking-the-chain-why-streak-features-fail-adhd-users-and-how-to-design-better-alternatives/)

**Overwhelm / "ADHD paralysis"**
- 70% of the ADDitude menopause-survey respondents rated overwhelm as life-altering in their 40s–50s — [ADDitude](https://www.additudemag.com/menopause-symptoms-adhd-survey/)
- Task initiation paralysis despite motivation — [Chen et al. 2026](https://arxiv.org/html/2603.17258v1)

**Burnout**
- No peer-reviewed quantitative source on "ADHD burnout" was opened (see Gaps). The adjacent evidence is masking (Rowney-Smith 2026 via [Psychology Today](https://www.psychologytoday.com/us/blog/if-i-be-waspish/202604/rejection-sensitivity-dysphoria-the-actual-research)) and deadline-driven, unsustainable productivity patterns ([Chen et al. 2026](https://arxiv.org/html/2603.17258v1)).

**Boredom intolerance / novelty seeking**
- Meta-analysis, 18 studies, >22,000 participants: ADHD–boredom association **r=0.40**. All but one study was significant and there was no publication bias. Boredom is framed as a "bridge" between atypical brain function and long-term difficulties — [Muris, Otgaar & Donkers 2026 via ADHD Evidence Project](https://www.adhdevidence.org/blog/the-neurocognitive-roots-of-boredom-in-adhd-a-meta-analysis)

**App abandonment (base rates)**
- Across 93 mental-health apps, a median 4% of 30-day installers opened the app on any given day. **Day-15 retention was a median 3.9%** and **day-30 retention 3.3%**. Peer-support apps got a median 35 min/day of use, mindfulness apps 21 min, and most others under 10 min — [Baumel et al. 2019 (JMIR) via National Elf Service](https://www.nationalelfservice.net/mental-health/digital-mental-health-tool-ignore-trial-read-analytics/)
- "Tool abandonment": existing productivity systems were adopted and then seen as ineffective — [Chen et al. 2026](https://arxiv.org/html/2603.17258v1)
- ADDitude readers "struggle with consistently adopting *any* system" — [ADDitude planners article](https://www.additudemag.com/best-planners-adhd-brains-paper-digital/)

### Inferences
- **Tool failure:** Most planners punish lapses through red overdue counts, broken streaks and stacks of missed notifications. For a population where ED has g≈1.2 and self-blame is pervasive, this turns one missed day into app abandonment. Novelty wears off by around week 2, which is consistent with the 3.9% day-15 base rate and a boredom association of r=0.40. Nothing brings the user back without guilt.
- **App implication:** Treat lapses as the default path. Provide: an "overdue amnesty"/reset button; no destructive streaks (weekly percentages, pause days); a capacity check-in that shrinks the day to a "baseline plan"; compassionate microcopy; rotating optional novelty (themes, widgets); and a "welcome back" flow that restarts in under 30 seconds. RSD should inform tone (never scolding, no public comparison) but should not be framed as a diagnosis given the evidence.

### Gaps
- No peer-reviewed prevalence data on "ADHD burnout" were accessed. The qualitative work-stress study (PMC9714234) was blocked.
- No study found that measures app retention specifically in ADHD users (e.g., the Swedish psychoeducational app paper at ScienceDirect/PMC could not be opened). The ADHD-specific drop-off curve is therefore unknown and is assumed to be at least as steep as Baumel's.
- Reddit complaint threads ("every app stops working after 2 weeks") could not be accessed.

---

## 3. Sleep (delayed sleep phase, revenge bedtime procrastination, stimulant effects on sleep onset, morning wake difficulty)

### Takeaway
Circadian delay is the norm rather than the exception in ADHD: about 73–78% have a delayed sleep/wake cycle, and DLMO is roughly 90 minutes later in adults. Stimulants add insomnia risk (lisdexamfetamine 11–19% vs placebo 4–5%) and can act up to 14 hours after the dose, so a late morning dose carries into bedtime. Morning wake-up, dose timing and bedtime are one coupled system, and the app should model them together.

### Cited Findings
- "73–78% of children and adults with ADHD have a delayed sleep/wake cycle". Insomnia affects "up to 80% of adults with ADHD". DLMO is delayed about 45 min in children and **about 90 min in adults**. In adults, melatonin 0.5 mg advanced DLMO by 88 min with a 14% reduction in ADHD symptoms. Melatonin plus bright light gave about a 2 h phase advance — [Luu & Fabiano 2025, *Frontiers in Psychiatry*](https://www.frontiersin.org/journals/psychiatry/articles/10.3389/fpsyt.2025.1697900/full) (a review; primary sources not independently verified)
- "Many people with ADHD have a late chronotype ('eveningness')" and "ADHD and insomnia often co-occur" (citing Becker 2020, *Curr Opin Psychol*). Revenge bedtime procrastination criteria (Magalhães et al. 2020): bedtime is delayed, sleep is reduced, there is no external reason, and the person chooses it despite knowing the consequences. **No ADHD-specific prevalence figures for bedtime procrastination** are given — [Understood.org](https://www.understood.org/en/articles/is-revenge-bedtime-procrastination-a-sign-of-adhd)
- "Sleep problems are one of the most common side effects of stimulant medication" (Stein et al. 2012). ADHD is associated with delayed circadian rhythm (van Andel et al. 2021) and increased eveningness (Coogan et al. 2019) — [ADDitude](https://www.additudemag.com/revenge-bedtime-procrastination-sleep-problems-adhd/)
- Lisdexamfetamine in adult trials: **insomnia 11–19% vs placebo 4–5%**. Efficacy is demonstrated **up to 14 h post-dose**, with onset about 1.5 h after taking it — [Najib et al. 2017, SAGE review](https://journals.sagepub.com/doi/10.1177/1179573517728090)
- The Australian guideline recommends that clinicians assess sleep patterns and offer strategies or referral, because "Individuals with ADHD have high rates of comorbid sleep disorders" — [AADPA 2022 guideline summary, Psych Scene Hub](https://psychscenehub.com/psychinsights/australian-clinical-practice-guideline-adhd/)
- Caffeine (n=2,259 adults): ADHD symptoms were **not** associated with the amount of caffeine consumed, but were associated with caffeine-use-disorder symptoms (β=0.350). Caffeine-use disorder mediated lower well-being — [Ágoston et al. 2022, *Frontiers in Psychiatry*](https://www.frontiersin.org/articles/10.3389/fpsyt.2022.813545/full)

### Inferences
- **Tool failure:** Medication reminders are set to a fixed clock time, such as 8:00. If the user wakes at 10:30 (typical with delayed phase), the reminder has either fired uselessly or the dose is taken late and carries (up to 14 h) into bedtime. Sleep apps and planners don't talk to each other. Bedtime reminders are easily snoozed and do nothing about the "reclaiming my time" motive behind revenge bedtime procrastination.
- **App implication:** Anchor the dose reminder to detected wake (Watch sleep data, first unlock). Let the user or their clinician set a "latest dose time" cut-off that the app displays when a dose would be late; the app should not give dosing advice. Add a wind-down anchor that works backwards from the required wake time, a protected "me-time" block earlier in the evening to reduce the revenge motive, a caffeine log with a cut-off nudge, and a morning launch sequence on the Watch.

### Gaps
- No primary study of revenge bedtime procrastination prevalence in ADHD was found.
- No quantitative data on morning-wake difficulty (e.g., sleep inertia) in adult ADHD were accessed.
- The effect of stimulants on sleep-onset latency in minutes (e.g., actigraphy meta-analyses) could not be accessed because PMC was blocked.

---

## 4. Eating (appetite suppression, forgetting to eat, evening rebound hunger, hydration, interoception)

### Takeaway
Decreased appetite is the most common stimulant side effect (about 27–33% of adults on lisdexamfetamine vs 2–6% on placebo), and dry mouth is similarly common. Adults with ADHD also show reduced interoceptive accuracy. As a result, "eat when hungry" fails as a cue, and meals and water need to be tied to the medication timeline.

### Cited Findings
- Lisdexamfetamine vs placebo in adults: **decreased appetite 26.5–33% vs 2–6%**; **dry mouth 26–32% vs 1–8%**; headache 14–25% vs 3–17%; irritability/anxiety 5–11% vs 0–7% — [Najib et al. 2017](https://journals.sagepub.com/doi/10.1177/1179573517728090)
- Appetite suppression, sleep disturbance, weight loss, nausea and headache are among the side effects adolescents and adults cite as reasons for stopping — [McCarthy 2014, *Patient Preference and Adherence*](https://www.dovepress.com/pharmacological-interventions-for-adhd-hownbspdonbspadolescent-and-adu-peer-reviewed-fulltext-article-PPA)
- Interoception (30 adults with ADHD vs 57 controls, aged 16–35). Heartbeat-counting accuracy was **0.60 vs 0.70** (p=.039), confidence 0.32 vs 0.48 (p=.034), and self-reported interoceptive accuracy (IAS) **78.2 vs 88.4** (p=.039). Self-reported attention to the body did not differ — [Göz Tebrizcik et al. 2025, *Biological Psychology*](https://www.sciencedirect.com/science/article/pii/S0301051125001796)
- Rebound management advice includes high-protein snacks and scheduling activities around wear-off — [ADDitude](https://www.additudemag.com/adhd-medication-rebound/)

### Inferences
- **Tool failure:** Food, water and medication tracking live in separate apps with separate reminders. None of them knows that lunch falls during peak appetite suppression, or that an evening rebound (with appetite returning) is coming.
- **App implication:** Put meal and water prompts on the medication "coverage" timeline: eat before the dose, a scheduled lunch "even if not hungry", a pre-wear-off protein snack, and evening meal preparation. Default to low-effort logging (a single tap, "ate something?"), and offer optional HealthKit water logging. Give the dry-mouth rate, hydration reminders should be on by default.

### Gaps
- No quantitative study of evening "rebound hunger" or binge eating after wear-off in adults was accessed.
- No ADHD-specific hydration data were found.

---

## 5. Medication-related daily struggles

### Takeaway
Adherence is poor and the reasons are mostly practical. Nonadherence ranges from 13% to 64%, fewer than half of adults are "consistently medicated", and forgetting is the most common unintentional reason. Supply has been unreliable in the US, the UK and Australia since 2022–23. Wear-off rebound, late-dose insomnia, cycle-related changes in effectiveness and stigma add a daily cognitive load that no mainstream app models end to end.

### Cited Findings
**Forgetting doses / forgetting whether a dose was taken**
- Nonadherence to ADHD medication ranges from **13.2% to 64%**. **Forgetting is the most commonly cited unintentional reason among adults.** Cost and access barriers, side effects, the "loss of authentic self", stigma, the inconvenience of daily dosing, and drug holidays or as-needed use are other reasons — [McCarthy 2014](https://www.dovepress.com/pharmacological-interventions-for-adhd-hownbspdonbspadolescent-and-adu-peer-reviewed-fulltext-article-PPA)
- "Fewer than half of adult patients could be considered 'consistently medicated'" based on prescription renewals (a 2020 study cited by ADDitude). There are four reasons adults give up: poor psychoeducation, suboptimal dosing, practical obstacles such as refills requiring sustained mental effort, and unsupportive clinicians. Suggested fixes include a 1–10 effectiveness rating, pill counts and medication-tracking apps — [ADDitude](https://www.additudemag.com/medication-nonadherence-adhd-adults-solutions/)
- A psychiatrist quoted in a lived-experience blog: "Medication is the easiest treatment in that it only requires a prescription, a daily reminder, and some water." The same author reported that effectiveness waned: "Drinking cups of coffee these past few weeks have been more stimulating than my meds" (an anecdote illustrating tolerance worry) — [Adulting ADHD Substack](https://adultingadhd.substack.com/p/have-the-meds-kicked-in-yet)

**Wear-off crash / rebound irritability**
- Rebound is "a flare of ADHD symptoms at the time a stimulant medication wears off". It lasts about 60 minutes, typically in the mid-to-late afternoon, with irritability, tearfulness and anger. It happens with almost all short-acting stimulants and can happen with long-acting ones. Clinician-managed options include a small booster before wear-off — [ADDitude](https://www.additudemag.com/adhd-medication-rebound/); symptoms "usually last for only about an hour" — [Understood.org](https://www.understood.org/en/articles/adhd-medication-rebound-what-you-need-to-know)
- No prevalence statistics for rebound were given in either source.

**Timing doses with wake-up; late doses and sleep**
- Lisdexamfetamine acts for up to 14 h and insomnia is 11–19% vs 4–5% on placebo — [Najib et al. 2017](https://journals.sagepub.com/doi/10.1177/1179573517728090) (see §3)

**Supply: running out, refills, shortages**
- US: ADDitude survey, n=10,936, Sept 2023. **38%** had trouble filling prescriptions over the previous 13 months, 21% were still affected at the time of the survey, and at least 38 doses or formulations were short. Respondents reported calling pharmacies 3–16+ times a month and driving 3–50 miles, and described rationing within families. Quote: *"It feels ridiculous that the only solution is calling pharmacy after pharmacy in a 50-mile radius."* — [ADDitude](https://www.additudemag.com/adhd-medication-shortage-adderall-vyvanse/)
- UK: ADHD UK survey, n=1,054, 18–27 Nov 2023. **97% were affected**: 27% had no medication since the crisis began, 33% had long gaps and 25% short gaps. **70% rationed or skipped doses**, **68% called multiple pharmacies**, and 10% used expired medication. 91% were concerned about the impact on their job and 44% feared losing it. 75% were concerned about their relationships. **38% reported new or increased suicidal thoughts.** Adult waiting lists of "up to 10.5 years" were cited — [ADHD UK](https://adhduk.co.uk/adhd-medication-crisis-report/)
- **Australia:** shortages of methylphenidate (Concerta, Ritalin), lisdexamfetamine (Vyvanse) and dexamfetamine began in 2023 and were expected to last into late 2025. About 470,000 Australians received ADHD medication in 2022–23. From Jan 2024 to May 2025, prescriptions of dexamfetamine rose 60%, methylphenidate 88% and lisdexamfetamine 140%. **NSW paper prescriptions for controlled medicines historically had to be filled at the same pharmacy**, with temporary transfers now permitted. Patients are advised to check the TGA Medicine Shortage Reports Database, keep a list of pharmacies, and call mid-morning — [The Conversation, 2025](https://theconversation.com/cant-fill-your-adhd-script-heres-why-and-what-to-do-while-the-shortage-persists-259911)

**Cost (Australia)**
- The PBS general co-payment fell from **$31.60 to $25.00 from 1 Jan 2026**. The concession co-payment stays at **$7.70**. The Safety Net covers a calendar year and "resets every January" (2025 thresholds: $1,694 general, $277.20 concession) — [Find a Pharmacy (Pharmacy Guild)](https://findapharmacy.com.au/latest-updates/what-does-the-2026-pbs-price-drop-mean-for-your-wallet)
- Cost of access: one witness at the Senate inquiry cited an **$830 initial consultation** — [ABC News 2023](https://www.abc.net.au/news/2023-11-06/senate-inquiry-into-adhd-hands-down-report/103068988)

**Prescribing logistics (Australia)**
- NSW Stage 1 took effect on **1 Sept 2025**. Trained GPs can become "continuation prescribers" of psychostimulants for stable patients aged 6+. Stage 2 (early 2026) lets GPs diagnose and initiate treatment — [AH&MRC](https://www.ahmrc.org.au/nsw-adhd-prescribing-reforms-explained/)
- Rules differ between states and territories, and scripts written in one jurisdiction "cannot always be filled in another", which is a particular problem for border communities — [ABC News 2023](https://www.abc.net.au/news/2023-11-06/senate-inquiry-into-adhd-hands-down-report/103068988)

**Hormonal cycle and dose (see §12)**
- In stimulant-treated women, symptoms are worst during menstruation, and doses stayed fixed despite this variation — [Zaritsky et al. 2026 via PsyPost](https://www.psypost.org/menstruation-may-worsen-adhd-symptoms-in-medicated-adult-women-2026-03-20/)

**Stigma**
- Stigma and embarrassment are listed reasons for nonadherence — [McCarthy 2014](https://www.dovepress.com/pharmacological-interventions-for-adhd-hownbspdonbspadolescent-and-adu-peer-reviewed-fulltext-article-PPA). The Senate inquiry recommended a "neurodiversity-affirming public health campaign" — [The Conversation 2023](https://theconversation.com/a-senate-inquiry-says-australia-needs-a-national-adhd-framework-to-improve-diagnosis-and-reduce-costs-215798)

**Caffeine interaction**
- There is no evidence that people with ADHD consume more caffeine, but ADHD symptoms predict problematic (use-disorder) patterns — [Ágoston et al. 2022](https://www.frontiersin.org/articles/10.3389/fpsyt.2022.813545/full). No accessible source quantified caffeine–stimulant interaction effects.

### Inferences
- **Tool failure:** Generic pill reminders (Apple Health Medications, Medisafe) record "taken", but they do not: model onset and wear-off windows; plan the day around coverage; warn that a late dose will reach into bedtime; anticipate rebound; track the supply of a Schedule 8 controlled drug (repeats, script expiry, same-pharmacy rules, eScript tokens); handle shortages (which pharmacy has stock); or link cycle phase to perceived effectiveness. The "did I take it?" question needs an answer in under 2 seconds from the wrist. Nothing designs for it as a double-dose safeguard.
- **App implication:** A medication core with: one-tap logging (Watch, widget, NFC tag on the bottle); a "Taken 08:02 · 3 h ago" glance on the lock screen; a coverage curve; a pre-wear-off alert; a user- or clinician-set latest-dose cut-off; a supply countdown with refill lead time; a shortage mode (pharmacy call log); cycle overlay; a clinician report; and discreet notification wording. All of it should be framed as tracking and communication with the prescriber. It must never tell the user to change a dose.

### Gaps
- Lived-experience quotes on double-dosing fear and "did I take it" uncertainty could not be sourced (Reddit blocked). This is an obvious recurring complaint but remains unverified here.
- Danish, Norwegian and Lancet Psychiatry registry figures for 1-year discontinuation in adults were not accessible (403/CAPTCHA).
- No Australian consumer survey quantifying the shortage's impact (equivalent to ADHD UK's) was found. ADHD Australia's page gives no figures ([ADHD Australia](https://www.adhdaustralia.org.au/senate-inquiry-into-adhd/)).
- Tolerance: no systematic evidence was accessed.

---

## 6. Money ("ADHD tax", impulsive spending, bills)

### Takeaway
Financial harm from ADHD is large and is mostly caused by missed due-dates and impulse purchases, both of which an app can intercept. However, the most-quoted statistics are secondary.

### Cited Findings
- Figures ADDitude attributes to Reuters: **57%** of people with ADHD miss loan payments, **over 50%** have poor credit ratings, **71%** have not saved for retirement, and **62%** engage in impulsive shopping. The author gives anecdotes of a $300 overdraft fee and forgotten subscription renewals ("you forgot to cancel it") — [ADDitude](https://www.additudemag.com/adhd-tax-late-fees-fines-shame/). *These are secondary figures: the original Reuters survey methodology was not opened.*
- Societal cost in Australia: $20.42 bn per year, or **$25,071 per individual with ADHD per year** — [AADPA guideline via Psych Scene Hub](https://psychscenehub.com/psychinsights/australian-clinical-practice-guideline-adhd/); "more than A$20 billion every year" — [The Conversation 2023](https://theconversation.com/a-senate-inquiry-says-australia-needs-a-national-adhd-framework-to-improve-diagnosis-and-reduce-costs-215798)

### Inferences
- **Tool failure:** Banking apps notify after the charge. Subscription managers need manual setup, which requires sustained effort. Nothing inserts friction at the moment of an impulse purchase.
- **App implication:** Bill and subscription due-dates on the same visual timeline as everything else; free-trial expiry alerts timed before the charge; a 48–72 h "wishlist cool-off" capture via the share sheet; an optional ADHD-tax log that makes costs visible without shame.

### Gaps
- The 2026 BMC Psychiatry study "ADHD symptoms and financial debt among adults" could not be opened (rate-limited). Primary peer-reviewed debt figures are therefore missing, as is the Science Advances 2020 study on financial distress (not opened).

---

## 7. Household and admin (chores, laundry, paperwork, appointments, email, doom piles, clutter, losing items)

### Takeaway
Clinically significant hoarding is about 10 times more common in adults with ADHD and tracks inattention. Clutter and "doom piles" therefore have measurable weight. Admin tasks combine low interest, many steps and time-sensitivity, which is the worst case for ADHD executive function.

### Cited Findings
- **20% of adults with ADHD (clinic n=88) reported clinically significant hoarding symptoms vs 2% of controls**, replicated online (n=220). Hoarding is linked to inattention severity. Patients did not raise hoarding spontaneously but acknowledged it when asked — [The Conversation](https://theconversation.com/hoarding-people-with-adhd-are-more-likely-to-have-problems-new-research-176211) (article does not name authors)
- Brain fog/memory issues (70%), overwhelm (70%), time management (63%) and procrastination (63%) were rated "life-altering" in the ADDitude menopause survey — [ADDitude](https://www.additudemag.com/menopause-symptoms-adhd-survey/)
- A digital calendar "basically ceases to exist for my brain once closed". 61% of ADDitude readers prefer paper, sticky notes or handwritten lists — [ADDitude](https://www.additudemag.com/best-planners-adhd-brains-paper-digital/)

### Inferences
- **Tool failure:** Chore apps assume the user will open them. "Out of sight, out of mind" means a list inside an app is invisible. Recurring chores become guilt-inducing overdue items. Losing items is not addressed by planners at all.
- **App implication:** Persistent glanceable surfaces (widgets, Watch complications, Live Activities) that stand in for the sticky note. Timed "doom-pile sprints" of 10–15 minutes with body-doubling. Location- and departure-triggered reminders (e.g., "keys/wallet/meds?" on leaving home; Find My/AirTag hand-off). Paperwork templates with multi-step breakdown. Treat recurring chores as rhythms rather than deadlines.

### Gaps
- No quantitative data on lost items, laundry or email backlog in adult ADHD were found.

---

## 8. Study and work (deadlines, exam preparation, long assignments, reading, meetings, email, shift work)

### Takeaway
Deadline-driven "crisis productivity" and difficulty with initiation dominate. Medication disruption directly harms grades and jobs, and there is almost no research on ADHD with shift work.

### Cited Findings
- "Deadline addiction": over-reliance on crisis-driven productivity, which is unsustainable — [Chen et al. 2026](https://arxiv.org/html/2603.17258v1)
- Shortage quote: *"My son went three months without medication which had a devastating effect on his college grades"*. Others described graduate-school dropout — [ADDitude](https://www.additudemag.com/adhd-medication-shortage-adderall-vyvanse/)
- 91% were concerned about the impact on their job and 44% feared job loss during the UK shortage — [ADHD UK](https://adhduk.co.uk/adhd-medication-crisis-report/)
- Procrastination is strongly associated with ADHD symptoms (r=0.42) — [Oguchi et al. 2021](https://www.frontiersin.org/journals/psychology/articles/10.3389/fpsyg.2021.708579/full)
- Reading: 50–60% of people with ADHD have a learning disability, with dyslexia the most common. This is an unsourced clinician estimate — [ADDitude (Olivardia)](https://www.additudemag.com/adhd-dyslexia-connection/)

### Inferences
- **Tool failure:** Assignment trackers store a due date but do not break long assignments into dated milestones sized to the user's calibrated pace. They do not place hard cognitive work inside the medication coverage window, and they give no support for rotating shift patterns where "the day" does not start at midnight.
- **App implication:** A backward planner for assignments and exams, with milestones and buffer based on the user's estimation multiplier. "Deep work" blocks placed inside peak coverage. Meeting prep and follow-up capture. Semester, exam-period and break templates. Days anchored to wake time for shift workers.

### Gaps
- No quantitative data on academic outcomes in Australian university students with ADHD were retrieved.
- Shift work: the only paper opened ([Lancel et al. 2023, Frontiers](https://www.frontiersin.org/journals/psychiatry/articles/10.3389/fpsyt.2023.1233640/full)) covers sleep disorders in shift workers but **not ADHD**. There is no ADHD-specific evidence.

---

## 9. Relationships and social life (texting back, birthdays, lateness)

### Takeaway
Social maintenance fails through the same working-memory and prospective-memory mechanisms ("out of sight, out of mind"). The stakes are high: 75% of UK respondents feared relationship damage when unmedicated.

### Cited Findings
- Poor texting-back is attributed to executive dysfunction and "out of sight, out of mind". Suggested strategies: scheduled recurring check-ins, stacking texts onto existing routines, milestone prompts (birthdays), tracking others' important dates, and explaining the pattern to friends (*"I sometimes forget to text back … but I'm working on it"*). No survey data — [ADDitude](https://www.additudemag.com/bad-texter-how-to-keep-in-touch-with-friends-adhd/)
- 75% were concerned about their relationships and 28% worried a relationship might end during the medication shortage — [ADHD UK](https://adhduk.co.uk/adhd-medication-crisis-report/)
- Lateness: the time-perception deficits in §1 are the mechanism — [Marx et al. 2021](https://www.adhdevidence.org/blog/time-blindness-found-to-be-a-consistent-feature-of-adhd)
- Interviewees valued ADHD peer groups: *"Only in the ADHD group do I feel that I can tell the truth."* — [Chen et al. 2026](https://arxiv.org/html/2603.17258v1)

### Inferences
- **Tool failure:** Messaging apps mark a message as read, and it vanishes from attention. There is no "reply later" queue across iMessage, WhatsApp and email. Birthday reminders fire on the day, too late to buy a gift.
- **App implication:** A "reply-later" inbox fed from the share sheet or Shortcuts. Birthday lead-time reminders (7 days for a gift, 0 days to message). Check-in cadence per person. "Leave-by" alerts for social plans.

### Gaps
- No quantitative study of forgetting birthdays, reply latency or lateness frequency in adult ADHD was found.

---

## 10. Health and self-care (exercise, hygiene, dental, doctor appointments)

### Takeaway
Self-care fails at the start-up point: the evidence is qualitative, and dental harm is documented in children. Exercise is valued by users, but evidence on adult adherence was not retrieved.

### Cited Findings
- P17's quote about brushing teeth and "big start-up difficulty" — [Chen et al. 2026](https://arxiv.org/html/2603.17258v1)
- Children aged 6–14 with ADHD symptoms (Spain, n=3,402) had **more than twice the incidence of caries**, 60% more extractions and 75% more restorations (propensity-matched), independent of socioeconomic status, diet, brushing frequency and dental visits. This is paediatric evidence — [Fernández-Arce et al. 2025 via ADHD Evidence Project](https://www.adhdevidence.org/blog/study-finds-association-between-childhood-adhd-and-poor-dental-health)
- Exercise was rated effective by 37% of ADDitude menopause-survey respondents, compared with 40% for stimulants and 26% for HRT — [ADDitude](https://www.additudemag.com/menopause-symptoms-adhd-survey/)
- The Senate inquiry reported shorter life expectancy and higher rates of sleep disorders, anxiety, depression and suicide in people with ADHD — [ABC News 2023](https://www.abc.net.au/news/2023-11-06/senate-inquiry-into-adhd-hands-down-report/103068988)

### Inferences
- **Tool failure:** Habit trackers log completion but give no help getting started, and daily streaks punish missed showers or workouts, which feeds shame.
- **App implication:** Morning and evening launch sequences, with timed sub-steps on the Watch. Flexible-frequency goals (e.g., "exercise 3×/week" rather than daily). Appointment booking prompts (dentist and GP recall intervals). HealthKit workout detection that auto-credits exercise. Pair self-care with existing anchors such as the medication dose.

### Gaps
- No adult ADHD dental data and no evidence on adult exercise adherence were retrieved (the search budget was exhausted).
- No data on missed medical appointments in ADHD were found.

---

## 11. Digital distraction (phone use, doomscrolling, notification overload, context switching)

### Takeaway
People with ADHD are about 5 times more likely to meet criteria for social-media disorder, and they use social media for escape. The phone that hosts the planner is also the main source of distraction.

### Cited Findings
- Sweden, 100 young people with ADHD vs 400 controls: social-media disorder **15.0% vs 3.3% (OR 5.25)**. Mean screen time did not differ, but the ADHD group was over-represented at both ≤1 h and ≥6 h/day. Their motives were **escape** and social compensation. They engaged more with negative content. Social-media variables explained 40–46% of the variance in psychosocial outcomes — [Thorell et al. 2025, *Int J Ment Health Addict*](https://link.springer.com/article/10.1007/s11469-025-01582-3)
- Reader quote: *"Digital requires me to turn on a device, and down the rabbit hole I go."* — [ADDitude](https://www.additudemag.com/best-planners-adhd-brains-paper-digital/)
- Screen time is one of the hyperfocus contexts measured — [Hupfeld et al. 2019](https://link.springer.com/article/10.1007/s12402-018-0272-y)
- Task switching deficit d=0.94 — [Fuermaier et al. 2013](https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0058338)

### Inferences
- **Tool failure:** Planner apps send more notifications, which adds to overload, and opening the phone to check a plan invites a rabbit hole. Blockers (Screen Time, Opal) are separate from the plan and require setup.
- **App implication:** Watch-first interaction so the user can check the plan without unlocking the phone. A notification budget (a small daily maximum, bundling, and escalation only for dose and leave-by alerts). Screen Time API (FamilyControls) focus shields tied to planned blocks. An optional "what are you escaping from?" check-in when a scroll session is detected.

### Gaps
- No meta-analysis of problematic smartphone use in adult ADHD was opened. Search results were mostly student or adolescent samples.

---

## 12. Sex and gender differences (cycle effects, perimenopause/menopause, late diagnosis)

### Takeaway
In medicated women, symptoms and mood fluctuate with the menstrual cycle, and a small case series found that premenstrual dose increases helped. Perimenopause is reported as the peak-impairment period. Women are diagnosed about 5 years later than men. This is a large under-served design space.

### Cited Findings
- 30 women aged 18–40 on amphetamine salts, surveyed daily for 35 days. **The menstruation phase had the most severe ADHD symptoms and the mid-follicular phase the mildest.** Negative mood peaked during menstruation and the late luteal phase. A larger increase in negative mood went with a larger increase in attention problems. **Doses stayed constant despite this variation** — [Zaritsky, Reed & Evans 2026, *J Atten Disord*, via PsyPost](https://www.psypost.org/menstruation-may-worsen-adhd-symptoms-in-medicated-adult-women-2026-03-20/)
- 9 women aged 22–48 had stimulant doses **increased 30–50% in the premenstrual week**. All 9 reported improvement with "minimal adverse events" and all chose to continue (follow-up 6–24 months). This is a community case series — [de Jong et al. 2023, *Frontiers in Psychiatry*](https://www.frontiersin.org/articles/10.3389/fpsyt.2023.1306194)
- ADDitude survey (n≈1,500 women): **94%** said symptoms grew more severe in perimenopause/menopause, 83% experienced some symptoms for the first time, and over 50% of those aged 40–59 named menopause as the period of greatest impact. Mean age at diagnosis was **43**. 73% reported anxiety and 64% depression. Self-selected sample — [ADDitude](https://www.additudemag.com/menopause-symptoms-adhd-survey/)
- Spain, n=900 adults: mean age at diagnosis was **28.96 for women vs 24.13 for men**, despite similar symptom onset. Women had more severe symptoms and more depression and anxiety by the time of diagnosis — [Amoretti et al., *European Psychiatry*, via EurekAlert](https://www.eurekalert.org/news-releases/1101579)
- The AADPA guideline says females "may be less likely to be diagnosed or misdiagnosed" and advises considering hormonal factors in symptom fluctuation — [Psych Scene Hub](https://psychscenehub.com/psychinsights/australian-clinical-practice-guideline-adhd/)

### Inferences
- **Tool failure:** Cycle trackers (Apple Cycle Tracking, Clue) and medication or ADHD apps do not cross-reference, so women cannot show a prescriber evidence of phase-linked effectiveness.
- **App implication:** Optional HealthKit cycle import with daily 1-tap focus and mood ratings. A phase-overlay chart. An exportable clinician report. A perimenopause mode for tracking symptoms. Onboarding psychoeducation for late-diagnosed adults. **No dosing suggestions**: surface the pattern and prompt a conversation with the prescriber.

### Gaps
- There are no RCTs of cycle-based dosing (evidence is n=9 case series and n=30 observational). Evidence on hormonal contraception effects was not searched. Adolescent (16–18) cycle data were not found.

---

## 13. Comorbidities that affect app design (anxiety, depression, autism, dyslexia, substance use, sleep)

### Takeaway
Comorbidity is the rule: up to 80% of adults with ADHD have at least one other disorder. Anxiety (~50%), depression, learning disorders and autism all change what "good design" means: predictability, low reading load, low demand, sensory control and mood safety.

### Cited Findings
- "As many as **80%** of adults with ADHD have at least one coexisting psychiatric disorder". Anxiety rates approach **50%**. Depression ranges from **18.6% to 53.3%**, with major depressive disorder 3× more likely and any mood disorder more than 4× more likely. Bipolar ranges from 5.1% to 47.1%. Substance abuse or dependence is **2×** more likely. Personality disorders are reported in >50% (a high figure from clinical samples) — [Katzman et al. 2017, *BMC Psychiatry*](https://link.springer.com/article/10.1186/s12888-017-1463-3)
- Autism: in 3.5 million US Medicaid adults, **27% of autistic adults without intellectual disability had ADHD** (about 10× the general population), rising to 40% with intellectual disability — [Yerys et al. 2025, *JAMA Netw Open*, via CHOP](https://www.chop.edu/news/rates-adhd-remain-high-adulthood-among-patients-autism)
- Learning disabilities are estimated at 50–60% of people with ADHD, with dyslexia the most common. Unsourced clinician estimate — [ADDitude](https://www.additudemag.com/adhd-dyslexia-connection/)
- The AADPA guideline lists depressive, bipolar, anxiety, personality and substance use disorders as the most common adult comorbidities, and notes high rates of sleep disorders — [Psych Scene Hub](https://psychscenehub.com/psychinsights/australian-clinical-practice-guideline-adhd/)
- Caffeine-use-disorder symptoms rise with ADHD symptoms (β=0.35) — [Ágoston et al. 2022](https://www.frontiersin.org/articles/10.3389/fpsyt.2022.813545/full)

### Inferences
- **Tool failure:** Apps built for ADHD tend to maximise stimulation (confetti, sounds, frequent UI changes). That can overwhelm anxious or autistic users, who need predictability and sensory control. Imperative "Do X now!" copy can trigger demand avoidance. Text-heavy interfaces penalise dyslexic users.
- **App implication:** "Calm" and "Spark" presentation modes. No surprise layout changes. Customisable haptics and sounds. Invitational rather than commanding language. Icon- and colour-led UI with voice input and output. Mood check-ins with crisis signposting (not therapy). Discreet handling of substance and caffeine logging.

### Gaps
- The sensory-processing meta-analysis (*JAACAP* 2025) could not be opened (402).
- There is no research base on pathological demand avoidance in ADHD adults.
- The reverse prevalence (% of ADHD adults who are autistic) was not found.

---

## 14. Life transitions and context shifts (semester vs break, weekends, travel, time zones, shift changes)

### Takeaway
There is almost no direct research. The mechanisms are clear from the above: routines anchored to external structure collapse when that structure disappears, and the external structure (school timetable, work hours, pharmacy access, medication supply) is itself unstable.

### Cited Findings
- Interviewees wanted "time as rhythm": flexible "ideal vs baseline" plans, progress kept across missed days, and "Emotionally Aware Pause Days" (the most preferred concept) — [Chen et al. 2026](https://arxiv.org/html/2603.17258v1)
- Life-stage transitions change the burden: perimenopause is reported as peak impairment by over 50% of women aged 40–59 — [ADDitude](https://www.additudemag.com/menopause-symptoms-adhd-survey/)
- Structural transitions in Australia: the PBS Safety Net resets every January ([Find a Pharmacy](https://findapharmacy.com.au/latest-updates/what-does-the-2026-pbs-price-drop-mean-for-your-wallet)); prescribing rules differ across state borders ([ABC News 2023](https://www.abc.net.au/news/2023-11-06/senate-inquiry-into-adhd-hands-down-report/103068988)); NSW GP prescribing changed in Sept 2025 and early 2026 ([AH&MRC](https://www.ahmrc.org.au/nsw-adhd-prescribing-reforms-explained/)).
- Drug holidays and as-needed use are reported adherence patterns — [McCarthy 2014](https://www.dovepress.com/pharmacological-interventions-for-adhd-hownbspdonbspadolescent-and-adu-peer-reviewed-fulltext-article-PPA)
- Circadian delay (§3) means that removing external wake anchors (weekends, holidays) lets the sleep phase drift — [Luu & Fabiano 2025](https://www.frontiersin.org/journals/psychiatry/articles/10.3389/fpsyt.2025.1697900/full) (inference from mechanism)

### Inferences
- **Tool failure:** Planners have one weekly template. Recurring tasks fire identically in semester and in holidays. Reminders scheduled in the home time zone either follow device time silently or drift, and neither behaviour is explained to the user.
- **App implication:** Context "modes" (Semester / Exam / Break / Travel / Shift) with separate templates, switched automatically from calendar data. Weekend wake-anchor protection. A travel mode that asks whether dose reminders should follow home time or local time, and prompts the user to confirm a plan with their prescriber before a trip. Handling of pre-planned medication days off, so that they are not logged as "missed". January reminders about the Safety Net and new scripts.

### Gaps
- No studies of ADHD routine collapse across school or university holidays, weekends, travel or time-zone changes were found.
- No sourced guidance on dosing across time zones was opened. Search results were commercial blogs, so none is cited.
- Australian rules for travelling with Schedule 8 stimulants were not retrieved.

---

## 15. Accessibility and UX needs (reading fatigue, choice overload, visual/time-based displays, low-friction input, forgiveness)

### Takeaway
The evidence converges on the same set of needs: external and visible information (paper beats digital for 61% of ADDitude readers because it stays in view), low friction, forgiveness, social or relational scaffolding, and a support framing rather than a deficit framing. Digital interventions have only small effects on symptoms (g≈−0.32), so the value proposition should be functional support, not "treatment".

### Cited Findings
- **61% of ADDitude readers prefer paper** planners, sticky notes or lists. Reasons given: "A digital calendar basically ceases to exist for my brain once closed", handwriting aids retention, and devices lead to rabbit holes. Digital fans value always-with-me, shared family calendars and audible reminder cues. Hybrid use is common — [ADDitude](https://www.additudemag.com/best-planners-adhd-brains-paper-digital/)
- Scoping review of 46 papers (from 3,538; 63% published 2021–25): 20 on mobile apps, 5 on wearables. Most take "a therapeutic or intervention perspective instead of a more positive support perspective" and a deficit framing. The review found limited user-centred or participatory design and inconsistent usability evaluation. Needs identified: time management, planning, task completion, reminders, personalised scheduling, real-time executive-function scaffolding, and transition support via wearables — [Tan et al. 2025, arXiv](https://arxiv.org/html/2601.21791v1)
- Meta-analysis of 23 RCTs (n=1,472): digital interventions reduced overall ADHD symptoms by **g=−0.32** and inattention by **g=−0.25**. The effect on hyperactivity/impulsivity was not significant. mHealth and telehealth were comparable to combined interventions — [Kasturiratna et al. 2025, *Computers in Human Behavior Reports*](https://www.sciencedirect.com/science/article/pii/S2451958825001186)
- Preferred speculative concepts were "Brain Weather Visualization", "Social Presence AI" and "Emotionally Aware Pause Days". Principles: relational accountability ("companionship rather than surveillance"), mood-adaptive interfaces, co-regulation and body-doubling, and supporting multiple engagement modes — [Chen et al. 2026](https://arxiv.org/html/2603.17258v1)
- Body-doubling or passive-agent tools made up 4.35% of the assistive-technology literature — [Tan et al. 2025](https://arxiv.org/html/2601.21791v1)
- Base-rate retention of 3.9% at day 15 — [Baumel et al. 2019 via National Elf Service](https://www.nationalelfservice.net/mental-health/digital-mental-health-tool-ignore-trial-read-analytics/)

### Inferences
- **Tool failure:** Feature-rich planners (Notion, Todoist, TickTick) push the burden of setting up the system onto the user, and that setup is itself an executive-function task, which invites overload. Information hidden inside the app is invisible. Heavy text excludes dyslexic users.
- **App implication:** The widget, complication or Live Activity is the product. Opening the app is the exception. Capture must work in under 3 seconds by voice, the Action button or the Watch. Show at most 3 focus items. Use opinionated defaults instead of configuration screens. Use icons, colour and time-shaped visuals. Everything should be forgiving.

### Gaps
- No ADHD-specific usability studies of Apple Watch interventions were accessed. Tan et al. counted wearables (n=5 papers) but the details were not extracted.

---

## 16. Additional: Australian service context (launch market)

### Takeaway
About 800,000 Australians have ADHD. Access is costly and slow, rules vary by state, and supply was disrupted from 2023 to 2025. An app that reduces the admin of staying medicated (scripts, repeats, pharmacies, appointments) addresses a documented national pain point.

### Cited Findings
- About **800,000 Australians have ADHD**, costing ">A$20 billion every year". The 2023 Senate inquiry received >700 submissions and heard 79 witnesses. It made **15 recommendations**, including a national framework, implementing the AADPA guideline, GP and nurse-practitioner collaborative care, a review of Medicare/PBS, expanded telehealth and rural access, and a neurodiversity-affirming anti-stigma campaign — [The Conversation 2023](https://theconversation.com/a-senate-inquiry-says-australia-needs-a-national-adhd-framework-to-improve-diagnosis-and-reduce-costs-215798)
- Prevalence in Australia: 6–10% of children and adolescents, **2–6% of adults**. The AADPA guideline recommends CBT and psychoeducation for adults, and methylphenidate, dexamfetamine or lisdexamfetamine as first-line medication — [Psych Scene Hub](https://psychscenehub.com/psychinsights/australian-clinical-practice-guideline-adhd/)
- ADHD Australia collected more than 650 community survey responses for its submission. Its priorities: remove assessment barriers, training, treatment access, research, and NDIS access — [ADHD Australia](https://www.adhdaustralia.org.au/senate-inquiry-into-adhd/)
- Lived-experience testimony: *"I'm literally an inpatient … with trauma from growing up as an undiagnosed or untreated woman with ADHD"* — [ABC News 2023](https://www.abc.net.au/news/2023-11-06/senate-inquiry-into-adhd-hands-down-report/103068988)

### Inferences
- The app should support Australian specifics: eScript tokens and repeats, the rule for Schedule 8 paper scripts in NSW, TGA shortage links, PBS co-payment and Safety Net tracking, and continuity when care moves from a psychiatrist to a GP continuation prescriber (NSW reforms).

### Gaps
- The Senate report PDF itself was not opened. Figures came via The Conversation and ABC.
- NICE NG87 (UK) was not opened because the search budget was exhausted.
- No Australian survey of consumer app use was found.

---

## Implications for the app

Each feature is mapped to the struggle it addresses and the evidence behind it. Features are product ideas, not medical advice. Anything touching dose should record, visualise and prompt a conversation with the prescriber. It must never recommend a dose change.

| # | Feature | Struggle addressed | Evidence anchor |
|---|---|---|---|
| 1 | **One-tap dose log** from Watch complication, lock-screen widget, Action button or an NFC sticker on the pill bottle. The lock screen shows "Taken 08:02 · 3 h ago"; a second tap warns "already logged today". | Forgetting doses; not knowing whether a dose was taken (double-dose fear) | Forgetting is the top unintentional reason for nonadherence; 13–64% nonadherence ([McCarthy 2014](https://www.dovepress.com/pharmacological-interventions-for-adhd-hownbspdonbspadolescent-and-adu-peer-reviewed-fulltext-article-PPA)) |
| 2 | **Wake-anchored dose reminder** triggered by detected wake (Watch sleep data or first unlock), not a fixed clock time, with escalating haptics. | Timing doses with a variable wake time; delayed sleep phase | 73–78% delayed sleep/wake ([Luu & Fabiano 2025](https://www.frontiersin.org/journals/psychiatry/articles/10.3389/fpsyt.2025.1697900/full)) |
| 3 | **Latest-dose cut-off banner**. The user or clinician enters a cut-off time; after it, logging shows "this is later than your usual cut-off; consider checking with your prescriber". | Taking meds late and then not sleeping | LDX acts ~14 h; insomnia 11–19% vs 4–5% ([Najib 2017](https://journals.sagepub.com/doi/10.1177/1179573517728090)) |
| 4 | **Coverage curve on the day timeline**. Onset, peak and wear-off per formulation (user-entered), drawn behind calendar events so demanding tasks can be placed in coverage. | Planning around medication; wasted peak hours | Onset ~1.5 h, duration up to 14 h ([Najib 2017](https://journals.sagepub.com/doi/10.1177/1179573517728090)) |
| 5 | **Pre-wear-off "landing" alert** (e.g., 30 min before): wrap up, protein snack, low-stakes tasks, and a warning before scheduling hard conversations. | Rebound crash and irritability | Rebound ~60 min, mid-to-late afternoon ([ADDitude](https://www.additudemag.com/adhd-medication-rebound/); [Understood](https://www.understood.org/en/articles/adhd-medication-rebound-what-you-need-to-know)) |
| 6 | **Meal and water prompts anchored to the medication timeline** (eat before the dose, scheduled lunch even if not hungry, evening meal preparation), plus 1-tap "ate something?" logging. | Appetite suppression, forgetting to eat, dry mouth, poor hunger awareness | Decreased appetite 26.5–33%, dry mouth 26–32% ([Najib 2017](https://journals.sagepub.com/doi/10.1177/1179573517728090)); reduced interoceptive accuracy ([Göz Tebrizcik 2025](https://www.sciencedirect.com/science/article/pii/S0301051125001796)) |
| 7 | **Supply countdown and refill planner**. Auto-decrements on logging; forecasts run-out date; tracks repeats remaining, script expiry and the prescriber appointment needed; stores eScript tokens; notes rules such as a NSW paper Schedule 8 script needing the same pharmacy. | Running out; refill logistics | Refills need sustained effort ([ADDitude](https://www.additudemag.com/medication-nonadherence-adhd-adults-solutions/)); NSW rules ([The Conversation 2025](https://theconversation.com/cant-fill-your-adhd-script-heres-why-and-what-to-do-while-the-shortage-persists-259911)) |
| 8 | **Shortage mode**. Pharmacy call list with a stock-check log and call-back reminders, a link to the TGA Medicine Shortage Reports Database, and a prompt to contact the prescriber about alternatives. | Pharmacy stock shortages | 38% affected in the US ([ADDitude](https://www.additudemag.com/adhd-medication-shortage-adderall-vyvanse/)); 68% called multiple pharmacies in the UK ([ADHD UK](https://adhduk.co.uk/adhd-medication-crisis-report/)); Australian shortages 2023–25 ([The Conversation](https://theconversation.com/cant-fill-your-adhd-script-heres-why-and-what-to-do-while-the-shortage-persists-259911)) |
| 9 | **Cycle-phase overlay**. Optional HealthKit cycle import; daily 1-tap focus and mood rating; chart by phase; flags "menstruation/late-luteal weeks look harder" for discussion with the prescriber. | Hormonal fluctuation in symptoms and stimulant effect | Worst symptoms during menstruation, doses unchanged ([Zaritsky 2026](https://www.psypost.org/menstruation-may-worsen-adhd-symptoms-in-medicated-adult-women-2026-03-20/)); premenstrual dose increase helped in 9/9 ([de Jong 2023](https://www.frontiersin.org/articles/10.3389/fpsyt.2023.1306194)) |
| 10 | **Perimenopause tracking mode** covering brain fog, overwhelm, sleep and mood, with a clinician report. | Symptoms worsening in perimenopause and menopause | 94% reported worse symptoms ([ADDitude](https://www.additudemag.com/menopause-symptoms-adhd-survey/)) |
| 11 | **Clinician-ready report** (PDF): adherence, timing, side effects (appetite, sleep, rebound), 1–10 effectiveness ratings, cycle overlay. | Suboptimal dosing; short appointments; poor communication with the prescriber | Suboptimal dosing and 1–10 ratings ([ADDitude](https://www.additudemag.com/medication-nonadherence-adhd-adults-solutions/)) |
| 12 | **Visible countdowns**: time until next commitment and "leave by", shown as a shrinking ring in a Live Activity, Dynamic Island and Watch complication. | Time blindness | Deficits across all timing paradigms ([Marx 2021](https://www.adhdevidence.org/blog/time-blindness-found-to-be-a-consistent-feature-of-adhd)) |
| 13 | **Leave-by planner** working back from arrival time, with travel time plus a personal lateness buffer learned from history. | Lateness | Time reproduction and estimation errors ([Marx 2021](https://www.adhdevidence.org/blog/time-blindness-found-to-be-a-consistent-feature-of-adhd)) |
| 14 | **Estimate-vs-actual calibration**. The user guesses a duration, the app times the task, and it learns a personal multiplier ("you usually take 1.6× your guess"), then applies it to future plans. | Duration misestimation; plans built around hyperfocus | [Chen et al. 2026](https://arxiv.org/html/2603.17258v1); [Marx 2021](https://www.adhdevidence.org/blog/time-blindness-found-to-be-a-consistent-feature-of-adhd) |
| 15 | **Waiting-mode protocol**. For any appointment, set a hard "stop and go" alarm with buffer and offer "side quests" sized to fit the gap, so the time before is usable. | Waiting mode | Anecdotal but widely reported; suggested strategies ([Healthline](https://www.healthline.com/health/adhd/adhd-waiting-mode)) |
| 16 | **"First tiny step" starter**. AI or template breakdown into micro-steps, a 2-minute "just start" timer, and an optional body-double/social-presence session. | Task initiation paralysis; procrastination | r=0.42 ([Oguchi 2021](https://www.frontiersin.org/journals/psychology/articles/10.3389/fpsyg.2021.708579/full)); body-doubling and social presence preferred ([Chen 2026](https://arxiv.org/html/2603.17258v1); [Tan 2025](https://arxiv.org/html/2601.21791v1)) |
| 17 | **Guided planning ritual** (2–3 min, morning or evening). Pick at most 3 items, set an "ideal" and a "baseline" version of the day, and sequence them. | Planning and sequencing deficit | Planning d=1.60; plans once made are retained ([Fuermaier 2013](https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0058338)) |
| 18 | **Staged transition cues**: Watch haptics at 10, 5 and 1 minutes before a switch, plus a "park your thought" quick capture. | Task switching and transitions | Switching d=0.94 ([Fuermaier 2013](https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0058338)); wearable transition support ([Tan 2025](https://arxiv.org/html/2601.21791v1)) |
| 19 | **Hyperfocus guardrail**. During a focus block, the Watch taps at set intervals with elapsed time and escalates to "stand, drink, eat". Also detects long scroll sessions. | Hyperfocus and getting stuck; forgetting to eat | [Hupfeld 2019](https://link.springer.com/article/10.1007/s12402-018-0272-y) |
| 20 | **Context-triggered reminders** (arriving or leaving a location, connecting to CarPlay, Focus mode change), including "keys, wallet, meds?" on leaving home plus Find My hand-off. | Prospective memory; losing items | Event-based PM and planning ([Fuermaier 2013](https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0058338)); inattention linked to hoarding and clutter ([The Conversation](https://theconversation.com/hoarding-people-with-adhd-are-more-likely-to-have-problems-new-research-176211)) |
| 21 | **Three-second universal capture** via Siri, the Action button, Watch dictation or the share sheet into a single inbox, triaged later. | Working-memory loss; "out of sight, out of mind" | [Alderson 2013 summary](https://www.resistaa.com/en/adhd/research/alderson-working-memory-meta-analysis); [ADDitude](https://www.additudemag.com/bad-texter-how-to-keep-in-touch-with-friends-adhd/) |
| 22 | **Forgiving progress model**: no destructive streaks; weekly percentages; "pause days"; streak insurance; progress kept across missed days. | Shame spirals; all-or-nothing thinking; abandonment | [Chen 2026](https://arxiv.org/html/2603.17258v1); [Klarity (opinion)](https://www.helloklarity.com/post/breaking-the-chain-why-streak-features-fail-adhd-users-and-how-to-design-better-alternatives/) |
| 23 | **Overdue amnesty / reset day**. One tap reschedules or archives everything overdue, hides red counts, and uses kind microcopy. | Doom piles of tasks; shame; overwhelm | Overwhelm 70% ([ADDitude](https://www.additudemag.com/menopause-symptoms-adhd-survey/)); ED g=1.17 ([Beheshti 2020](https://link.springer.com/article/10.1186/s12888-020-2442-7)) |
| 24 | **"Brain weather" capacity check-in** (1 tap). Low capacity collapses the day to the baseline plan and reduces notifications. | Emotional dysregulation; overwhelm and paralysis | Most-preferred concept ([Chen 2026](https://arxiv.org/html/2603.17258v1)); ~70% of adult patients report ED ([Beheshti 2020](https://link.springer.com/article/10.1186/s12888-020-2442-7)) |
| 25 | **Designed-for-lapse re-engagement**. The app expects breaks of 1–3 weeks; a "welcome back" flow gets the user running again in under 30 seconds without backlog guilt; optional novelty rotation (themes, widget faces, reward variety). | Boredom intolerance; novelty-driven abandonment | Boredom r=0.40 ([Muris 2026](https://www.adhdevidence.org/blog/the-neurocognitive-roots-of-boredom-in-adhd-a-meta-analysis)); 3.9% day-15 retention ([Baumel 2019](https://www.nationalelfservice.net/mental-health/digital-mental-health-tool-ignore-trial-read-analytics/)) |
| 26 | **Wind-down and protected "me-time" block** worked back from the required wake time, with an earlier guilt-free leisure block to reduce the revenge-bedtime motive and a Screen Time shield at the cut-off. | Revenge bedtime procrastination; delayed phase | [Understood](https://www.understood.org/en/articles/is-revenge-bedtime-procrastination-a-sign-of-adhd); [Luu & Fabiano 2025](https://www.frontiersin.org/journals/psychiatry/articles/10.3389/fpsyt.2025.1697900/full) |
| 27 | **Morning launch sequence on the Watch**: timed sub-steps (dose, water, breakfast, hygiene, leave-by) with haptic progression. | Morning wake difficulty; hygiene start-up difficulty | P17 quote ([Chen 2026](https://arxiv.org/html/2603.17258v1)); DLMO ~90 min later in adults ([Luu & Fabiano 2025](https://www.frontiersin.org/journals/psychiatry/articles/10.3389/fpsyt.2025.1697900/full)) |
| 28 | **Caffeine log with a personal cut-off time** and a view of caffeine alongside sleep. | Caffeine overuse; sleep | Caffeine-use-disorder β=0.35 ([Ágoston 2022](https://www.frontiersin.org/articles/10.3389/fpsyt.2022.813545/full)) |
| 29 | **Bills and subscriptions on the timeline**: due dates, alerts before free trials convert, an autopay check, and an optional non-judgemental "ADHD tax" log. | Late fees; forgotten subscriptions | 57% miss loan payments (secondary) ([ADDitude](https://www.additudemag.com/adhd-tax-late-fees-fines-shame/)) |
| 30 | **Impulse-buy cool-off**: share a product to the app, it is held on a wishlist, and the app asks again in 48–72 h. | Impulsive spending | 62% impulsive shopping (secondary) ([ADDitude](https://www.additudemag.com/adhd-tax-late-fees-fines-shame/)) |
| 31 | **Doom-pile and admin sprints**: 10–15 min timed sprints with body-doubling, paperwork templates split into steps, and appointment booking prompts. | Household and admin; clutter | Hoarding 20% vs 2% ([The Conversation](https://theconversation.com/hoarding-people-with-adhd-are-more-likely-to-have-problems-new-research-176211)) |
| 32 | **Reply-later queue and birthday lead times**: messages saved from any app, with gentle batch reminders; birthdays from Contacts at 7 days (gift) and on the day; per-person check-in cadence. | Texting back; forgetting birthdays | "Out of sight, out of mind" ([ADDitude](https://www.additudemag.com/bad-texter-how-to-keep-in-touch-with-friends-adhd/)); 75% feared relationship harm ([ADHD UK](https://adhduk.co.uk/adhd-medication-crisis-report/)) |
| 33 | **Assignment and exam backward planner**: dated milestones with buffer from the calibration multiplier, and deep-work blocks placed inside medication coverage. | Deadlines; long assignments; deadline addiction | [Chen 2026](https://arxiv.org/html/2603.17258v1); grades hit by missed meds ([ADDitude](https://www.additudemag.com/adhd-medication-shortage-adderall-vyvanse/)) |
| 34 | **Context modes** (Semester / Exam / Break / Travel / Shift) with separate templates, auto-switched from calendar data. Travel mode asks "home time or local time?" for dose reminders and prompts a prescriber check. Planned medication breaks are not logged as "missed". | Routine collapse across transitions; time zones; drug holidays | Drug holidays ([McCarthy 2014](https://www.dovepress.com/pharmacological-interventions-for-adhd-hownbspdonbspadolescent-and-adu-peer-reviewed-fulltext-article-PPA)); "time as rhythm" ([Chen 2026](https://arxiv.org/html/2603.17258v1)); direct research gap |
| 35 | **Focus shields tied to plan blocks** using the Screen Time API during planned deep-work or coverage windows, with an optional "escaping something?" check-in on long scrolls. | Doomscrolling; problematic social-media use | Social-media disorder 15% vs 3.3%, escape motive ([Thorell 2025](https://link.springer.com/article/10.1007/s11469-025-01582-3)) |
| 36 | **Notification budget**: a daily cap, bundling, haptic-first on the Watch, and escalation only for dose and leave-by alerts. | Notification overload and habituation | Rabbit-hole effect of devices ([ADDitude](https://www.additudemag.com/best-planners-adhd-brains-paper-digital/)); inference |
| 37 | **Glanceable-first UI**: widgets and complications are the primary surface; at most 3 items visible; icon- and colour-led time shapes; voice input and output; dyslexia-friendly font option. | Reading fatigue; choice overload; "the app ceases to exist once closed" | 61% prefer paper for visibility ([ADDitude](https://www.additudemag.com/best-planners-adhd-brains-paper-digital/)); LD 50–60% (unsourced estimate) ([ADDitude](https://www.additudemag.com/adhd-dyslexia-connection/)) |
| 38 | **Calm vs Spark presentation modes**: predictable layouts, no surprise UI changes, adjustable sound and haptics, invitational (not commanding) copy. | Autistic ADHD adults' sensory needs and need for predictability; anxiety; demand avoidance | 27% of autistic adults have ADHD ([CHOP/Yerys 2025](https://www.chop.edu/news/rates-adhd-remain-high-adulthood-among-patients-autism)); anxiety ~50% ([Katzman 2017](https://link.springer.com/article/10.1186/s12888-017-1463-3)) |
| 39 | **Discreet mode**: neutral notification text ("Morning ✓" instead of the drug name), an alternate app icon, local-first or on-device health data, and a Face ID lock. | Medication stigma; privacy for a Schedule 8 medicine | Stigma is a reason for nonadherence ([McCarthy 2014](https://www.dovepress.com/pharmacological-interventions-for-adhd-hownbspdonbspadolescent-and-adu-peer-reviewed-fulltext-article-PPA)) |
| 40 | **Mood safety net**: persistently low check-ins trigger signposting to Australian crisis and support services and prompt contacting a GP. Signposting only, no therapy claims. | Depression comorbidity; distress during medication gaps | Depression 18.6–53.3% ([Katzman 2017](https://link.springer.com/article/10.1186/s12888-017-1463-3)); 38% new or increased suicidal thoughts during the UK shortage ([ADHD UK](https://adhduk.co.uk/adhd-medication-crisis-report/)) |
| 41 | **Micro-psychoeducation for late-diagnosed users**: 60-second cards on onset, wear-off, rebound, sleep and appetite, shown in context, supporting informed talks with the prescriber. | Late diagnosis; poor psychoeducation driving nonadherence | Women diagnosed ~5 years later ([Amoretti via EurekAlert](https://www.eurekalert.org/news-releases/1101579)); poor psychoeducation ([ADDitude](https://www.additudemag.com/medication-nonadherence-adhd-adults-solutions/)); AADPA recommends psychoeducation ([Psych Scene Hub](https://psychscenehub.com/psychinsights/australian-clinical-practice-guideline-adhd/)) |
| 42 | **Australian admin pack**: tracking toward the PBS Safety Net (resets 1 Jan), awareness of the $25 / $7.70 co-payments, state prescribing-rule notes (NSW continuation prescribers from 1 Sept 2025), and a "new script needed" appointment prompt. | Cost; refill logistics; cross-state rules | [Find a Pharmacy](https://findapharmacy.com.au/latest-updates/what-does-the-2026-pbs-price-drop-mean-for-your-wallet); [AH&MRC](https://www.ahmrc.org.au/nsw-adhd-prescribing-reforms-explained/); [ABC 2023](https://www.abc.net.au/news/2023-11-06/senate-inquiry-into-adhd-hands-down-report/103068988) |
| 43 | **Flexible-frequency self-care goals** ("3× a week", "every 2–3 days") with HealthKit auto-credit for workouts, plus recall reminders for dentist and GP. | Exercise consistency; hygiene; dental; doctor appointments | Exercise rated effective by 37% ([ADDitude](https://www.additudemag.com/menopause-symptoms-adhd-survey/)); caries >2× in children ([Fernández-Arce 2025](https://www.adhdevidence.org/blog/study-finds-association-between-childhood-adhd-and-poor-dental-health)) |
| 44 | **Optional accountability buddy / social presence**: share selected goals or "I'm starting now" pings with a trusted person or an AI companion, framed as companionship rather than surveillance. | Initiation; isolation; relational accountability | Social Presence AI concept preferred; "only in the ADHD group do I feel that I can tell the truth" ([Chen 2026](https://arxiv.org/html/2603.17258v1)) |

Positioning note, an inference from [Kasturiratna 2025](https://www.sciencedirect.com/science/article/pii/S2451958825001186) and [Tan 2025](https://arxiv.org/html/2601.21791v1): digital tools have small symptom effects (g≈−0.32), and the literature leans on deficit framing. Position the app as practical support for daily function and communication with the prescriber, not as a treatment. Co-design with adults with ADHD, which the literature says is under-done.
