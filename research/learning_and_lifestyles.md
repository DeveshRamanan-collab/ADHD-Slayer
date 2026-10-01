# Learning from one user with small data, plus the "Lifestyle 2" regime toggle (ADHD planner, iPhone/Apple Watch)

Research notes, 28 Sep 2026. Scope: ML/statistics/product techniques for (1) task-duration estimation, (2) time-of-day completion, (3) medication effect window, (4) routine anchors, (5) notification receptivity, and the Lifestyle 1/Lifestyle 2 toggle.

How the research went: WebSearch hit the session-wide search limit (200/200) partway through, so later sources were reached by fetching known URLs directly. PubMed/PMC often returned reCAPTCHA pages, and JAACAP, Taylor & Francis, Wiley, ACM DL and Cell returned 403. Springer returned a rate-limit (429) and I did not retry it. Where I cite a secondary summary instead of the primary paper, I say so. Formulas under "Inferences" are standard results derived from the cited sources, or are my design recommendations. They are marked as inferences, not findings.

---

## 1. Small-data personal learning: partial pooling, conjugate models, shrinkage, planning-fallacy correction, ADHD evidence

### Takeaway
Use conjugate Bayesian models with population (or "outside view") priors and personal posteriors, i.e. partial pooling. The personal data outweighs the prior once the observation count n exceeds the prior's pseudo-sample-size κ₀, so κ₀ should be about 3–6 for most parameters. The planning-fallacy literature says the fix is to use the user's own logged actuals (the outside view), not their recollection. Lab studies of ADHD timing show more variable estimates, not only biased ones, so the model has to learn a personal spread as well as a personal bias.

### Cited Findings
- **Normal-Inverse-Gamma (NIG) conjugate update** (unknown mean and variance). Prior NIG(m₀,V₀,a₀,b₀) = N(µ|m₀,σ²V₀)·IG(σ²|a₀,b₀). Posterior: V_n⁻¹ = V₀⁻¹ + n; m_n/V_n = V₀⁻¹m₀ + n·x̄; a_n = a₀ + n/2; b_n = b₀ + ½[m₀²V₀⁻¹ + Σx_i² − m_n²V_n⁻¹]. Posterior predictive: Student-t with 2a_n degrees of freedom, location m_n, scale² b_n(1+V_n)/a_n — [Murphy, "Conjugate Bayesian analysis of the Gaussian distribution"](https://www.cs.ubc.ca/~murphyk/Papers/bayesGauss.pdf)
- **Partial pooling vs no/complete pooling.** Complete pooling gives every unit the same success chance. No pooling treats units as unrelated. Partial pooling lets "the data for all of the observed items inform the estimates for each item". On the Efron & Morris baseball data (18 players, 45 at-bats each), held-out log predictive density was −97.2 for no pooling, −74.3 for partial pooling (beta) and −71.6 for partial pooling (logit). Shrinkage gave better predictions — [Stan case study, Carpenter, "Hierarchical Partial Pooling for Repeated Binary Trials"](https://mc-stan.org/learn-stan/case-studies/pool-binary-trials.html)
- **Priors from population data, applied in a deployed mHealth personaliser (HeartSteps V2).** For features significant in a population GEE, prior mean = the population point estimate and prior SD = the SD of person-specific estimates across 37 V1 participants. For non-significant features, prior mean = 0 and SD = half that SD. Noise variance σ² was fixed from V1 residuals "for algorithm stability" and not updated. Posteriors were updated nightly — [Liao, Greenewald, Klasnja & Murphy 2019, "Personalized HeartSteps", arXiv:1909.03539 (PDF)](https://arxiv.org/pdf/1909.03539)
- **Planning fallacy, base data.** Honours-thesis students predicted 33.9 days on average against 55.5 days actual. Only 29.7% finished by their "best estimate". Even their pessimistic ("worst case") prediction of 48.6 days was beaten by only 48.7%. In other studies 37.1–43.6% finished within predicted time. Only 7% of think-aloud content referred to relevant past experiences (74% was future scenarios) — [Buehler, Griffin & Ross 1994, JPSP 67(3)](https://web.mit.edu/curhan/www/docs/Articles/biases/67_J_Personality_and_Social_Psychology_366,_1994.pdf)
- **Linking to past experience removed the bias.** In Study 4, participants told to relate relevant past experiences to their prediction predicted 7.0 days against 7.0 actual (bias −0.1 day), and 60.0% finished on time against 29.3% in the control condition — [Buehler et al. 1994](https://web.mit.edu/curhan/www/docs/Articles/biases/67_J_Personality_and_Social_Psychology_366,_1994.pdf)
- **Memory bias as a cause.** Roy et al. argue people "systematically underestimate the duration of those past events", so recalled experience is itself biased. Remedies listed: reference-class forecasting, segmentation/unpacking into subtasks, implementation intentions. Another cited study found only 13% of students finished by their 50%-probability estimate, 19% by their 75% estimate and 45% by their 99% estimate — [Wikipedia, "Planning fallacy" (secondary; primary psycnet page blocked by robots.txt)](https://en.wikipedia.org/wiki/Planning_fallacy)
- **Reference class forecasting (Kahneman/Tversky "outside view", Flyvbjerg).** Three steps: (1) identify a reference class "broad enough to be statistically meaningful but narrow enough to be truly comparable"; (2) establish its empirical probability distribution; (3) place the case within it. Uplifts depend on accepted risk. Roads: +15% at 50% acceptable overrun risk, +32% at 20% risk (80% confidence). Rail: +40% and +57%. The road data came from 172 projects — [Flyvbjerg, "From Nobel Prize to Project Management: Getting Risks Right", arXiv:1302.3642](https://arxiv.org/pdf/1302.3642)
- **ADHD timing meta-analysis** (Marx, Cortese, Koelch & Hacker, JAACAP 2021). Time estimation: 8 studies, n = 1,024, small-to-medium increase in absolute error. Time reproduction: 26 studies, n = 2,364, medium. Time production: 7 studies, n = 380, small. Duration discrimination: 25 studies, n = 1,633, medium deficit. People with ADHD "show greater variability in time estimates of several seconds". The effect of medication could not be assessed — [ADHD Evidence blog summary (secondary; the JAACAP primary returned 403)](https://www.adhdevidence.org/blog/time-blindness-found-to-be-a-consistent-feature-of-adhd)
- **Thompson-sampling practice.** Scaling posterior variance down (α < 1, e.g. α = 0.5) "decrease[s] the amount of exploration and often result[s] in lower regret". Thompson sampling copes with delayed or batched feedback better than UCB — [Chapelle & Li 2011, "An Empirical Evaluation of Thompson Sampling", NeurIPS](https://papers.nips.cc/paper_files/paper/2011/file/e53a0a2978c28872a4505bdb51db06dc-Paper.pdf)

### Inferences
- **How fast personal data takes over.** From Murphy's update, the posterior mean is m_n = (κ₀m₀ + n·x̄)/(κ₀ + n) with κ₀ = V₀⁻¹. The weight on the user's own data is w = n/(n+κ₀), so personal estimates "dominate" (w > 0.5) once n > κ₀. Suggested κ₀ (prior pseudo-observations):
  - duration multiplier per category: 3–5
  - completion probability per slot: 4–6
  - wake/sleep anchor mean: 3 days
  - medication onset/offset: weak prior from label data, equivalent to about 2–3 check-in days

  With κ₀ = 4: w = 0.5 at 4 observations, 0.71 at 10 and 0.86 at 25. Set κ₀ = σ²/τ², where τ² is the between-person variance of the parameter (the HeartSteps recipe: prior SD = SD of person-specific estimates).
- **Precision needed before a personal estimate is shown as "confident".** If the SD of log(actual/estimate) within a category is about 0.5, the SE of the mean log-ratio is 0.5/√n. Reaching ±20% (about ±0.18 on the log scale, 95%) needs n ≈ 30. Reaching ±40% needs n ≈ 7. Recommended ladder: show "early estimate" at n ≥ 3, "learned" at n ≥ 8, "confident" when the 80% predictive interval of the multiplier is narrower than ×1.5.
- **Empirical Bayes path.** At launch, set m₀ and τ² from literature or pilot data. Later, set them from population data collected with privacy protection (see §11). HeartSteps shows population-fitted priors are workable in production.
- **Use Buehler's result in the interface.** When the user types an estimate, show their own logged actuals for the reference class, e.g. "your last 6 'essay drafting' sessions: 1.4×–2.3× your estimate". Buehler Study 4 suggests linking to past experience is itself a debiasing intervention. Because Roy et al. find memories of past durations are biased short, the app should rely on logged actuals, never recalled ones.
- **Model the spread, not just the bias.** The ADHD meta-analysis reports greater absolute error and variability, not a uniform underestimate. The model therefore needs a per-category σ (NIG gives this) as well as a per-category mean bias.

### Gaps
- I found no study that measures planning-fallacy multipliers on real multi-hour tasks for adults with ADHD. The meta-analyses cover seconds-scale lab tasks, and the search limit stopped further searching. An ADHD-specific default multiplier therefore has to be set from pilot data.
- I could not open Roy, Christenfeld & McKenzie (2005) directly (psycnet robots.txt), so the memory-bias claim rests on the Wikipedia summary.
- There is no published between-person variance (τ²) of duration multipliers in ADHD populations. κ₀ values above are design suggestions and need to be checked by simulation.

---

## 2. Duration estimation: log-normal durations, P50/P80 buffers, combining user estimate with history, censoring, cold start

### Takeaway
Model y = log(actual/user_estimate) per (category, context) with an NIG prior. The multiplier is then log-normal. Schedule individual blocks at P50 or P80 of the Student-t predictive, and size day-level buffers from the sum of means (means add; medians and quantiles don't). Abandoned or partly done tasks are right-censored and enter the likelihood through the survival function (1−CDF), not as completed durations.

### Cited Findings
- **Estimate-vs-actual data are log-normal.** In an estimate-vs-actual dataset, the median blowup factor was exactly 1×, the mean 1.81×, the 99th percentile 32× and the 99.99th percentile an extreme value. "Means add, but medians do not." In a 7-task example, one high-uncertainty task (σ = 2) takes about half the expected total time. The fitted model was a Student-t on the log scale with σ drawn from an inverse-Gamma, i.e. heavy tails — [Bernhardsson 2019, "Why software projects take longer than you think" (blog; dataset of real estimates)](https://erikbern.com/2019/04/15/why-software-projects-take-longer-than-you-think-a-statistical-model.html)
- **Quantile-based uplift, P50 vs P80.** Uplifts come from the empirical distribution of overruns and differ by acceptable risk (roads +15% at P50, +32% at P80) — [Flyvbjerg arXiv:1302.3642](https://arxiv.org/pdf/1302.3642)
- **Pessimistic predictions still fell short.** Even students' "worst case" predictions (48.6 days vs 55.5 actual) were met by only 48.7% — [Buehler et al. 1994](https://web.mit.edu/curhan/www/docs/Articles/biases/67_J_Personality_and_Social_Psychology_366,_1994.pdf)
- **Right-censoring.** A censored observation contributes its tail probability, i.e. the log complementary CDF (normal_lccdf(U|µ,σ)). Censored values can be integrated out analytically, which is more efficient than imputing them as parameters — [Stan User's Guide, "Truncated or censored data"](https://mc-stan.org/docs/stan-users-guide/truncation-censoring.html)
- **Posterior predictive for NIG is Student-t** t_{2a_n}(m_n, b_n(1+V_n)/a_n), which gives heavy-tailed quantiles at small n — [Murphy](https://www.cs.ubc.ca/~murphyk/Papers/bayesGauss.pdf)

### Inferences
- **Core model (per category c; optionally per lifestyle, see §6).**
  - y_i = log(A_i / E_i), where A_i is the actual and E_i the user's estimate. For tasks with no estimate, use y_i = log(A_i) in a separate NIG.
  - y ~ N(µ_c, σ_c²), with (µ_c, σ_c²) ~ NIG(m₀, 1/κ₀, a₀, b₀).
  - Predicted multiplier quantile q: M_q = exp(m_n + t_{2a_n}⁻¹(q)·s_n), with s_n = √(b_n(1+V_n)/a_n).
  - Block length = E × M_0.5 (median) or E × M_0.8 (P80, for deadline-critical work).
  - Expected minutes (for adding up a day) = E × exp(m_n + s_n²/2) (log-normal mean, approximate under the t).
- **Default cold-start prior (inference; tune with pilot data).** m₀ = log(1.4) to log(1.6): Buehler's thesis ratio is 55.5/33.9 = 1.64 and the software mean blowup is 1.81 with median 1.0. Set a₀ = 2–3 so the variance prior is weak but proper, and b₀ so the prior-mean σ ≈ 0.5–0.6. κ₀ = 3–4.
- **Hierarchy across categories.** Categories share a user-level global multiplier: µ_c = µ_user + δ_c with δ_c ~ N(0, τ_c²). A new category (e.g. "lab report") therefore starts at the user's overall multiplier, not the population one. This is two-level partial pooling (population → user → category), done by updating the user-level NIG with all tasks and using its posterior as the m₀ of each new category.
- **Context covariates.** Use Bayesian linear regression on y with features such as time of day, medicated vs not (from §4), lifestyle, day-of-week, whether the user split the task into subtasks (unpacking effect), and task size bucket. Keep the conjugate Normal–Inverse-Gamma regression form. Keep features to 5 or fewer until n > 50 to avoid overfitting.
- **Censoring rules.**
  1. Abandoned after c minutes with no completion: right-censored, y > log(c/E). Update by grid or Laplace approximation, or with a moment-matched pseudo-observation: E[y | y > ℓ] = µ + σ·φ(α)/(1−Φ(α)), α = (ℓ−µ)/σ, with extra variance.
  2. Partly done (user says fraction f is done after t minutes): pseudo-actual A ≈ t/f, flagged as a noisy observation (σ inflated ×1.5).
  3. Skipped by a hard rule (clash, exam, cancelled): no duration information, so exclude it.
  4. Timer left running or implausible value (A > 6E and > 4 h): ask for confirmation or winsorise.
- **Day-level buffer.** Don't sum per-task P80s (too conservative). Sum per-task means, or Monte-Carlo the sum of log-normal draws on-device (1,000 draws is trivial), and reserve the difference between the total's P80 and the sum of medians as a floating buffer block. The Bernhardsson "means add" point shows one high-σ task dominates, so flag high-σ categories explicitly.

### Gaps
- I found no peer-reviewed data on the σ of personal task-duration log-ratios for students or ADHD adults. The Bernhardsson dataset is software tasks (blog analysis).
- The search limit stopped me finding PERT/lognormal activity-time papers (e.g. Trietsch et al.).

---

## 3. Time-of-day preference/completion modelling and notification receptivity: logistic models, Thompson sampling, safe exploration, MRTs/JITAI, N-of-1 trials

### Takeaway
Predict P(complete | slot, context) with an online Bayesian logistic regression (Laplace/diagonal-Gaussian posterior, updated nightly), shrunk toward population or stated-preference priors. Choose among *eligible* slots and notification times by Thompson sampling, with randomisation probabilities clipped to about [0.1, 0.8]. Exploration must never touch protected items (exams, near deadlines), which is an availability gate like the one in HeartSteps. Formal questions such as "90 vs 60-minute blocks" should be run as blocked, randomised N-of-1 comparisons analysed in a Bayesian way.

### Cited Findings
- **JITAI components.** Distal outcome, proximal outcomes, decision points, tailoring variables, intervention options and decision rules. "Receptivity" is "the individual's transient ability and/or willingness to receive, process, and utilize just-in-time support", driven by internal and contextual factors. Intervention fatigue and habituation are named risks. The micro-randomised trial (MRT) is "a sequential factorial design" with random assignment at many decision points — [Nahum-Shani et al. 2018, Ann Behav Med (PMC5364076)](https://pmc.ncbi.nlm.nih.gov/articles/PMC5364076/)
- **MRT definition.** Treatments are "sequentially randomized … with each participant randomized at the 100s or 1000s of occasions". The paper gives a sample-size calculator for proximal effects — [Liao, Klasnja, Tewari & Murphy, "Sample size calculations for micro-randomized trials in mHealth", arXiv:1504.00238](https://arxiv.org/abs/1504.00238)
- **HeartSteps V2 algorithm details.**
  - Five decision points per day.
  - Reward difference modelled as f(s)ᵀβ with β ~ N(µ_d, Σ_d), updated nightly.
  - Action-centred working model R_t = g(S_t)ᵀα₀ + π_t f(S_t)ᵀα₁ + (A_t − π_t) f(S_t)ᵀβ + ε.
  - Randomisation probability clipped with φ(π) = min(1−ε₀, max(π, ε₁)), ε₀ = 0.2 and ε₁ = 0.1, so π ∈ [0.1, 0.8].
  - Burden/"dosage" variable X_{t+1} = λX_t + 1{E_{t+1}} with λ = 0.95.
  - An availability indicator blocks treatment in unsafe contexts ("if sensors indicate that the participant might be driving a car, then A=0 is enforced").
  
  — [Liao et al. 2019, arXiv:1909.03539](https://arxiv.org/pdf/1909.03539)
- **Online Bayesian logistic regression for Thompson sampling.** Uses a diagonal-Gaussian Laplace approximation. The posterior mean is the mode, and precisions are updated as q_i ← q_i + Σ_j x_ij² p_j(1−p_j), in batches. Thompson sampling handles delayed/batched feedback better than UCB. Posterior scaling α = 0.5 reduced regret — [Chapelle & Li 2011](https://papers.nips.cc/paper_files/paper/2011/file/e53a0a2978c28872a4505bdb51db06dc-Paper.pdf)
- **Conservative (safe) exploration.** Conservative bandits explore "whilst simultaneously maintaining their revenue above a fixed baseline, uniformly over time", with near-optimal regret — [Wu, Shariff, Lattimore & Szepesvári 2016, arXiv:1602.04282](https://arxiv.org/abs/1602.04282)
- **Non-stationarity.** Discounting the prior parameters of Thompson sampling "systematically reduce[s] the effect of past observations" — [Raj & Kalyani 2017, arXiv:1707.09727](https://arxiv.org/abs/1707.09727)
- **N-of-1 design guidance (AHRQ user's guide).**
  - Assign treatments within blocks of two periods, using randomisation or counterbalancing.
  - Trade the number of periods against measurements per period (precision vs burden).
  - Handle carryover with washout, or by discarding/down-weighting early-period observations.
  - Blind where outcomes are subjective.
  - Analyse separate outcomes separately. Bayesian analysis is recommended because it gives "the full posterior probability distribution of the treatment effect".
  - Suits "rapid onset/offset" treatments and stable conditions.
  
  — [AHRQ, "Design and Implementation of N-of-1 Trials: A User's Guide"](https://effectivehealthcare.ahrq.gov/products/n-1-trials/research-2014-1)

### Inferences
- **Completion model.** logit P(complete) = βᵀx, with features:
  - hour-of-day harmonics: sin(2πh/24), cos(2πh/24), sin(4πh/24), cos(4πh/24)
  - weekday/free-day
  - lifestyle ID
  - predicted medication effect E(t) from §4
  - hours since wake (from §4 anchors)
  - sleep-debt proxy
  - task category
  - calendar density
  - reminder sent (yes/no)

  Prior mean from population values or the user's stated preferred times. Prior SD = between-person SD (HeartSteps recipe). Update nightly with Chapelle–Li Algorithm 3. On-device cost is negligible (about 20 features).
- **Slot choice.** Build candidate slots from hard constraints (the rules layer), then draw β̃ from the posterior and pick the argmax of P(complete)·value. Log the implied propensity. Use α ≈ 0.5 posterior scaling to limit experimentation, since users feel exploration as "weird suggestions".
- **Safety rules for exploration (inference, following the conservative-bandit and HeartSteps availability logic).**
  - Exploit only (no randomisation) for: exams, assessments due within 48 h, medication reminders, P1/fixed items, and anything the user marked "protected".
  - Exploration is allowed only for flexible, low-stakes items (habits, errands, optional study blocks).
  - Cap exploratory moves at about 1–2 per day.
  - Never move an item outside the user-approved window.
- **Notification receptivity.**
  - Use about 3–6 decision points per day, gated by availability: Focus/Do-Not-Disturb, in class, driving, asleep, Apple Watch workout, medication off-window if the user chooses.
  - Randomise send/no-send or timing with π ∈ [0.1, 0.8].
  - Proximal outcome = acted on within 30 min.
  - Include a burden variable X_{t+1} = 0.95X_t + 1{sent} as a covariate, to learn habituation.
  - This is an "MRT of one". Randomising with logged propensities is what makes the later off-policy evaluation in §12 possible.
- **"90 vs 60-minute blocks" N-of-1 (inference).**
  - Blocks of 2 study days (one each arm, order randomised within the block), for 6–8 blocks (12–16 study days).
  - Outcomes: completed pomodoro-equivalents, self-rated focus (1–5), overrun minutes.
  - Drop the first block of each lifestyle switch (carryover or adaptation).
  - Bayesian model: y = µ + θ·arm + block effect.
  - Report P(θ > 0) and the posterior median. Adopt the change if P > 0.8 and the effect is at least the smallest worthwhile difference. Always let the user approve.

### Gaps
- I did not open HeartSteps efficacy results (Klasnja 2019) or empirical receptivity studies (e.g. Künzler 2019; Mehrotra 2016) because PMC/ACM were blocked and the search limit was reached. No measured receptivity base rates are reported here.
- I found no study of ADHD-specific notification habituation rates.

---

## 4. Medication effect-curve estimation from sparse check-ins and dose logs

### Takeaway
Model the subjective "is it working?" signal as a noisy binary or ordinal observation of a latent dose-driven effect curve. The latent curve is either (a) a four-parameter onset–plateau–offset template, or (b) a one-compartment first-order absorption (Bateman) curve with a lag, with multiple doses superimposed. Fit it exactly on a small parameter grid on-device, with formulation-specific priors from label data. Label durations differ markedly from real-world self-reports, so priors must be wide. Use a few one-tap check-ins placed where the curve is most uncertain, then taper them off. Treat Watch heart rate as weak evidence only (about +6 bpm average).

### Cited Findings
- **Bateman function.** C(t) = A(e^{−k_e t} − e^{−k_a t}), with mean absorption time MAT = 1/k_a. Across individuals it estimates population AUC robustly, but it "failed in evaluating MAT" and individual estimates were "highly biased" without IV reference data. The paper does not discuss absorption lag — [PMC10547630, "Is the One-Compartment Model with First Order Absorption a Useful Approximation?"](https://pmc.ncbi.nlm.nih.gov/articles/PMC10547630/)
- **Concerta (OROS methylphenidate) label pharmacokinetics.** Concentrations "increase rapidly reaching an initial maximum at about 1 hour", then "gradual ascending concentrations over the next 5 to 9 hours". Mean peak at 6–10 h, half-life about 3.5 h. No PK/PD difference after a high-fat breakfast — [FDA Concerta label (2007)](https://www.accessdata.fda.gov/drugsatfda_docs/label/2007/021121s014lbl.pdf)
- **Lisdexamfetamine in adults** (simulated-workplace crossover, n = 103 completers, 30/50/70 mg). PERMP was better than placebo "at all postdose time points from 2 to 14 h" — [Wigal et al. 2010, Behav Brain Funct 6:34](https://link.springer.com/article/10.1186/1744-9081-6-34)
- **Real-world self-reported durations are shorter than label claims** (ADxS, a German patient-information site; secondary and self-selected survey data):
  - Methylphenidate IR: typical 3–4 h, as short as 1 h (survey mean 3.06 h, n ≈ 20–28).
  - Concerta: 10.2 h (IQR 7.5–11.5).
  - Ritalin LA/Medikinet retard: 4.6 h (IQR 3.4–6.0), against a manufacturer claim of 6–8 h.
  - Lisdexamfetamine: 57.3% of 1,327 users reported 7 h or less, against the 13–14 h claim. Peak dextroamphetamine at 4.4 h in 21 adults.
  
  — [ADxS.org, "Efficacy and duration of action of ADHD medications"](https://www.adxs.org/en/page/434/efficacy-and-duration-of-action-of-adhd-medications)
- **Heart-rate signal.** In adults, stimulants raised resting heart rate by +5.7 bpm (95% CI 3.6–7.8) versus placebo and systolic BP by +2.0 mmHg (10 RCTs, n = 2,665; mostly long-acting preparations) — [Mick et al. meta-analysis, PMC3488604](https://pmc.ncbi.nlm.nih.gov/articles/PMC3488604/)
- **Burden of check-ins (EMA).**
  - Wrzus & Neubauer (477 articles, N = 677,536): average compliance 79%. "The number of assessments did not predict compliance or dropout rates". Financial incentives raised compliance (about 82% vs 76%) — [Wrzus & Neubauer 2023, Assessment](https://journals.sagepub.com/doi/10.1177/10731911211067538)
  - Eisele et al. (163 students, 3/6/9 prompts per day × 30/60 items, 14 days): "increased burden and compromised data quantity and quality with longer questionnaires, but not with increased sampling frequency" — [Eisele et al. 2022, Assessment (Tilburg portal abstract)](https://research.tilburguniversity.edu/en/publications/the-effects-of-sampling-frequency-and-questionnaire-length-on-per/)
- **Gaussian-process option.** Exact GP regression costs n³/6 for the Cholesky factorisation. Predictive mean = k*ᵀ(K+σ_n²I)⁻¹y — [Rasmussen & Williams, GPML ch. 2](http://gaussianprocess.org/gpml/chapters/RW2.pdf)

### Inferences
- **Recommended latent model A (explainable, default): template.**
  - Effect relative to a dose at time t_d: E(τ) with τ = t − t_d.
  - E rises linearly from 0 at τ = t_on to 1 at τ = t_on + r, stays at 1 until τ = t_off − f, then falls linearly to 0 at t_off.
  - Four parameters: onset t_on, rise r, offset t_off, fall f. Fix r and f per formulation (e.g. 30–60 min) to keep 2 free parameters.
  - Observation model: P(yes at t_j) = ε₀ + (1 − ε₀ − ε₁)·E(t_j), with lapse rates ε₀ ≈ 0.1 (says yes when off) and ε₁ ≈ 0.1 (says no when on).
  - Posterior: exact grid over t_on ∈ [0, 180] min in 15-min steps and t_off ∈ [2, 16] h in 15-min steps, about 13 × 57 ≈ 740 cells. Trivial in Swift and fully explainable ("works about 0:45–6:30 after dose; 80% CI ±40 min").
- **Model B (pharmacologically structured).** Driver C(t) = Σ_d D_d·A·(e^{−k_e(t−t_d−t_lag)} − e^{−k_a(t−t_d−t_lag)})·1[t > t_d + t_lag], i.e. linear superposition of booster doses. Effect via an Emax/Hill link E = C^h/(EC₅₀^h + C^h). Priors: k_e from the half-life (Concerta 3.5 h → k_e ≈ 0.2 h⁻¹); for OROS use a two-input release profile. Model B handles boosters naturally, but its parameters are poorly identified from sparse binary data (the PMC10547630 paper shows MAT is biased even with concentration data). Use it only as a structured prior shape, and put the individual learning into the 2–3 template parameters.
- **Boosters.** In model A, superpose templates, E_total = min(1, Σ E_d(t − t_d)), with the same personal parameters per formulation (IR booster vs ER morning dose have separate parameter sets).
- **Priors per formulation (wide; inference from the sources above).**
  - IR methylphenidate: t_on ~ 20–60 min; t_off mode ~3.5 h (range 1.5–5 h).
  - Concerta: t_on ~ 45–90 min; t_off mode ~10 h (range 7–12 h).
  - Lisdexamfetamine: t_on ~ 60–120 min (efficacy shown at 2 h in Wigal); t_off mode ~9–10 h, with a very wide range (6–14 h) given the ADxS reports.
- **Check-in design (active learning).**
  - Learning phase (first 5–7 medicated days): 3–5 one-tap prompts per day ("Working now? Yes / Partly / No"), placed at the times with maximum predictive entropy of P(yes). These usually fall around the uncertain onset and wear-off edges.
  - Taper to about 1 prompt every 2–3 days once the 80% CI of t_on and t_off is under ±30 min.
  - Keep single items only (Eisele: length, not frequency, drives burden).
  - Expect about 20% missing data (Wrzus: 79% compliance).
  - Re-open the learning phase on a dose/formulation change or a change-point flag (§5).
- **Passive signals.** Watch HR residual = HR − (same-activity, same-time-of-day unmedicated baseline). Include it as a low-weight likelihood term (e.g. Gaussian with an effect size of about 5 bpm and a large SD). The pooled +5.7 bpm is small relative to activity-, caffeine- and stress-driven swings, so HR alone should never set the window. Use it to fill gaps between check-ins and to detect a missed or late dose log (HR fails to rise when a dose is logged).
- **Timing is lifestyle-specific, response is global.** Dose clock time (and so the absolute window) moves with wake time in Lifestyle 2. The curve relative to dose should be shared across lifestyles (§6).
- **Safety and scope.** The app should present the learned window as a planning aid ("you usually report it working 0:45–6:30 after dose"), never as dosing advice, and keep dose reminders in the hard-rules layer.

### Gaps
- I could not open Swanson et al. 1999 (acute tolerance / clockwise hysteresis to methylphenidate; Wiley 403). How much effect lags or leads concentration is therefore unverified here, and it matters for model B.
- The ADxS duration survey is secondary and self-selected. I did not open a TGA/Australian PI for local formulations (e.g. Vyvanse, Ritalin LA, Concerta in Australia).
- I found no study validating smartwatch HR as a marker of stimulant on/off state at the individual level.
- I found no published sample-size figures for how many binary check-ins recover onset/offset within ±30 min. This needs simulation.

---

## 5. Concept drift and change detection

### Takeaway
Use Bayesian online change-point detection (BOCPD, Adams & MacKay) on key daily series (wake time, sleep midpoint, first-activity time, medication-window reports, duration log-ratios). Use a CUSUM on log-likelihood ratios for a cheap "switched lifestyle?" alarm. Add mild exponential forgetting for slow drift. Require persistence (3 or more days) and agreement across several signals before calling something a genuine shift.

### Cited Findings
- **BOCPD recursion.**
  - Growth: P(r_t = r_{t−1}+1, x_{1:t}) = P(r_{t−1}, x_{1:t−1})·π_t^{(r)}·(1 − H(r_{t−1})).
  - Change-point: P(r_t = 0, x_{1:t}) = Σ P(r_{t−1}, x_{1:t−1})·π_t^{(r)}·H(r_{t−1}).
  - Posterior P(r_t | x_{1:t}) = P(r_t, x_{1:t})/P(x_{1:t}).
  - With a geometric gap prior, the hazard is constant, H = 1/λ.
  - Conjugate-exponential updates: ν ← ν+1, χ ← χ + u(x_t).
  - Cost is linear in t. Pruning run lengths with probability < 10⁻⁴ makes the average cost roughly constant (about the expected run length).
  
  — [Adams & MacKay 2007, arXiv:0710.3742 (PDF)](https://arxiv.org/pdf/0710.3742)
- **CUSUM.** S_hi(i) = max(0, S_hi(i−1) + x_i − µ̂₀ − k); S_lo(i) = max(0, S_lo(i−1) + µ̂₀ − k − x_i). Signal when either exceeds h. Rule of thumb: k = δ/2 (half the shift to detect), h ≈ 4–5 (σ units). Efficient for shifts of 2σ or less — [NIST/SEMATECH e-Handbook §6.3.2.3](https://www.itl.nist.gov/div898/handbook/pmc/section3/pmc323.htm)
- **Drift taxonomy.** Sudden, gradual, incremental and reoccurring ("an old concept may reoccur after some time"). Detection families: error-rate-based, distribution-based, multiple-hypothesis. For recurring concepts, "preserving and reusing old models can save significant effort to retrain a new model" — [Lu et al. 2020, "Learning under Concept Drift: A Review", arXiv:2004.05785](https://arxiv.org/pdf/2004.05785)
- **Discounting for non-stationarity** (discounted Thompson sampling reduces the influence of old data) — [Raj & Kalyani 2017](https://arxiv.org/abs/1707.09727)

### Inferences
- **Exponential forgetting on sufficient statistics (per active day).** For NIG: κ ← λκ + (1−λ)κ_floor, a ← λa + (1−λ)a_floor, and matching sums. For Beta: α ← λα + (1−λ)α₀, β ← λβ + (1−λ)β₀. Effective memory ≈ 1/(1−λ) days.
  - Routines: λ = 0.97–0.98 (about 33–50 days).
  - Receptivity: λ = 0.95 (about 20 days).
  - Duration multipliers: λ = 0.99 or none (slow-changing trait).
- **BOCPD settings.** Hazard 1/60 per day for routine anchors (expect an intrinsic change every couple of months: semester boundaries, jobs). Student-t predictive from NIG, pruning at 10⁻⁴.
- **Genuine shift vs noise: flag a candidate change only when all of these hold.**
  1. P(r_t ≤ 3 days | data) > 0.8.
  2. The post-change mean differs by more than max(30 min, 1 SD of day-to-day variability).
  3. At least 2 independent signals agree (e.g. wake time and first-phone-use or first Watch activity).
  4. It persists 3 or more days.

  Known triggers — a dose/formulation change the user logged, a new calendar pattern (new job/timetable) — raise the hazard to about 1/7 for the next 14 days. The model then adapts quickly without the user saying anything.
- **Detecting a forgotten Lifestyle 2 toggle.** See §6 for the likelihood-ratio CUSUM between stored lifestyle models.
- **Response to a detected change.**
  - Medication/anchors: re-open learning (inflate variance, κ ← min(κ, 3)).
  - Durations: usually leave alone unless task-type content changed.
  - Always explain it ("Since Tuesday your wake time averages 9:10 vs 7:20; update routine?").

### Gaps
- I found no published application of BOCPD to personal-routine data from phones/wearables to calibrate hazard or false-alarm rates. These parameters need offline replay tuning (§12).

---

## 6. Regime/context switching for Lifestyle 1 vs Lifestyle 2: architecture

### Takeaway
Treat lifestyles as a small set of *user-labelled recurring regimes*. Each has its own frozen-when-dormant posterior snapshot for lifestyle-specific parameters, sitting inside a hierarchical model with shared global parameters. Switching is a pointer swap (instant). A new regime is warm-started from the old regime's posterior, shifted by population holiday priors and variance-inflated to about 3 pseudo-days, so it adapts in about 3–7 days. A recurring regime (last year's holidays) is reactivated from its stored snapshot with mild extra variance. A two-state sticky HMM filter or log-likelihood-ratio CUSUM over daily anchors detects a forgotten toggle and *suggests* (never forces) a switch. Heavy meta-learning (MAML) is unnecessary: hierarchical Bayes gives the same "learn a prior that adapts from few samples" behaviour analytically and on-device.

### Cited Findings
- **Recurring concepts.** Storing and reusing old models is recommended for reoccurring drift. Systems monitor for earlier patterns and reactivate stored models — [Lu et al. 2020](https://arxiv.org/pdf/2004.05785)
- **Sticky HDP-HMM.** A plain HDP-HMM "tends to over-segment … creating redundant states and rapidly switching among them". A self-transition bias fixes this — [Fox et al., sticky HDP-HMM, arXiv:0905.2592](https://arxiv.org/abs/0905.2592)
- **MAML.** Learns an initialisation such that "a small number of gradient steps with a small amount of training data from a new task will produce good generalization" — [Finn, Abbeel & Levine 2017, arXiv:1703.03400](https://arxiv.org/abs/1703.03400)
- **Population-to-person prior transfer, in production** (prior mean = population estimate; prior SD = between-person SD) — [Liao et al. 2019](https://arxiv.org/pdf/1909.03539)
- **BOCPD** for detecting an unlabelled regime change — [Adams & MacKay 2007](https://arxiv.org/pdf/0710.3742); **CUSUM** thresholds — [NIST](https://www.itl.nist.gov/div898/handbook/pmc/section3/pmc323.htm)
- **Holiday routines settle over about 2 weeks.** In a naturalistic actigraphy study of 146 Melbourne adolescents, vacation brought "an abrupt delay in sleep timing", "further linear delays throughout the vacation", and changes that "stabilized during the second vacation week" — [Bei et al. 2014, J Sleep Res (Monash abstract)](https://research.monash.edu/en/publications/actigraphy-assessed-sleep-during-school-and-vacation-periods-a-na/)

### Inferences — recommended Lifestyle-toggle design

**A. Which parameters are global vs lifestyle-specific**

| Parameter group | Storage | Rationale |
|---|---|---|
| Duration multiplier per category (µ_c, σ_c) | **Global**, plus a small lifestyle offset δ_L ~ N(0, 0.1²) on the log scale | Task difficulty is mostly a trait; holidays may change interruptions slightly |
| Medication effect curve *relative to dose* (t_on, t_off) | **Global** per formulation | Pharmacology doesn't change with the calendar |
| Dose clock time, booster habits | **Lifestyle-specific** | Follows wake time |
| Wake / sleep / meal anchors (mean and SD per weekday type) | **Lifestyle-specific** | Sleep timing shifts in holidays (§7) |
| Time-of-day completion curve (logistic β) | **Hierarchical**: β_L = β_global + Δ_L; harmonics and intercept lifestyle-specific, category effects global | Time-of-day pattern follows the anchors |
| Notification receptivity | **Lifestyle-specific** (class vs no class changes availability) | |
| Hard rules (exams, fixed events, meds reminders) | **Rules layer**, tagged per lifestyle, never learned | Keep separate from preferences |

**B. Stored state per lifestyle L.**
- Sufficient statistics: NIG (m, κ, a, b) per anchor; Beta (α, β) per slot bucket; Laplace mean/precision vectors for the logistic models.
- Last-active date and cumulative active days.
- A list of previous episodes (start/end dates).
- A "data log" of raw events tagged with lifestyle ID, so models can be rebuilt or replayed.

All of this is only a few kilobytes and sits in the app container (see §11).

**C. Freezing the dormant regime.** Updates and forgetting apply only to the **active** lifestyle's lifestyle-specific statistics, on active days. Global parameters keep updating under both. Switching back to L1 swaps which snapshot the planner reads: O(1), instant, with no relearning, because nothing in L1 decayed while dormant.

**D. First-ever activation of L2 (warm start with variance inflation).**
- For each lifestyle-specific parameter: m_L2 = m_L1 + Δ_pop, κ_L2 = min(κ_L1, κ_cap) with κ_cap ≈ 3 pseudo-days, and a, b scaled so the predictive SD is about 1.5× L1's.
- Δ_pop for anchors: use the user's own L1 *free-day* (weekend) mid-sleep and wake time as the L2 prior mean. This is personal and already observed. Otherwise shift wake by about +50–60 min (§7).
- Adaptation, with personal weight n/(n+3): 50% after 3 days, 70% after 7, 82% after 14. Bei et al. show holiday sleep keeps drifting through week 1, so for the first 14 days of an L2 episode use faster forgetting (λ = 0.90/day), then λ = 0.97.
- This is a tempered or "power" prior: the old posterior acts as a prior with only about 3 days of weight.

**E. Recurring activation (e.g. next summer holidays).** Restore L2's stored snapshot. Inflate its variance by a factor growing with time since the last L2 episode: κ ← κ/(1 + Δmonths/6), capped at κ ≤ 7 pseudo-days. This lets last year's pattern inform day 1 while this year's data dominates within about a week. This is the "store and reuse models for recurring concepts" pattern (Lu et al.).

**F. More than two lifestyles.** The same machinery works for K user-named lifestyles (e.g. term, holidays, exam period, placement). Cap K at about 4 and suggest merging two lifestyles whose predictive distributions overlap heavily (e.g. Hellinger distance < 0.2 on anchors).

**G. "You seem to be in holiday mode" detection.**
- *Both lifestyles learned:* run a 2-state HMM forward filter over daily feature vectors x_t (wake time, sleep midpoint, first-activity time, calendar class hours, campus-location visit yes/no if permitted, step pattern).
  - Emissions = each lifestyle's Student-t predictive.
  - Sticky transition matrix, P(stay) = 0.97 (Fox-style self-transition bias, so one late night doesn't flip it).
  - Prompt when P(other lifestyle | x_{1:t}) > 0.9 for 2 consecutive days.
  - Equivalent cheap form: CUSUM S_t = max(0, S_{t−1} + log p(x_t|L2) − log p(x_t|L1)), prompting when S_t > h ≈ 3 (odds of about 20:1).
- *L2 never learned:* use BOCPD on the anchors (§5), plus priors from the academic calendar (e.g. university session/recess dates entered or imported once). Raise the hazard around those dates.
- *Always* suggest with an explanation and one-tap accept/undo: "Last 3 days: up at 9:40 (term avg 7:15), no classes. Switch to Holidays? Your holiday settings from July are ready." Never auto-switch, because a user-controlled toggle is a stated requirement.
- *Mistaken or late toggle:* when the user confirms a switch "since Monday", re-attribute the logged days since Monday to L2 by replaying events. This is possible because raw events are kept.

**H. Why not MAML or other meta-learning.** MAML's aim, an initialisation that adapts from a few examples, is what the hierarchical prior already provides in closed form for these low-dimensional conjugate models. Gradient-based meta-learning needs many users' data and neural models. It fits only as a possible future population-level tool (e.g. with federated learning, §11), not for on-device one-user learning.

### Gaps
- I found no published evaluation of warm-start-with-variance-inflation schedules for personal routine models. κ_cap ≈ 3 and the forgetting schedules are design choices to tune by replay.
- I did not check switching state-space model papers (Ghahramani & Hinton) because of the search limit. The HMM/CUSUM design here follows from the sticky-HMM and BOCPD sources.

---

## 7. Evidence on students' sleep/wake and routine shifts during holidays/breaks (Lifestyle 2 priors)

### Takeaway
Without school/uni constraints, sleep timing is delayed at once (bedtimes about 50 min later on weekdays in one university sample). Sleep lengthens and becomes more variable, social jetlag falls, and the new pattern takes about 1–2 weeks to settle. The best personal prior for holiday anchors is the user's own term-time free-day (weekend) timing, with variance inflated.

### Cited Findings
- **Adolescents, Melbourne** (n = 146, age 16.2 ± 1.0). At vacation start there was "an abrupt delay in sleep timing and increase in sleep duration". Bedtime and rise time "further linear delays throughout the vacation". Sleep onset latency peaked mid-week-2 and changes "stabilized during the second vacation week". Vacation sleep had "later timing, longer duration, lower quality and greater variability". Eveningness and older age went with later timing — [Bei et al. 2014, J Sleep Res (Monash research portal abstract)](https://research.monash.edu/en/publications/actigraphy-assessed-sleep-during-school-and-vacation-periods-a-na/)
- **University students when constraints were removed** (COVID stay-at-home; n = 139, CU Boulder; Wright et al. 2020, Current Biology):
  - Weekday sleep +30 min; weekday bedtime about 50 min later, with later waking.
  - Weekend sleep +24 min; weekend bedtime about 25 min later.
  - Less social jetlag and more regular sleep/wake times.
  - 92% achieved at least 7 h.
  
  — [University of Colorado news release summarising Wright et al. 2020 (primary at Cell returned 403)](https://www.colorado.edu/today/2020/06/11/one-silver-lining-sleep-improving-under-stay-home-orders)
- **Irregular sleep delays the circadian clock** (Harvard undergraduates, n = 61, about 30 days of diaries). Sleep Regularity Index: 52 ± 10 (irregular) vs 84 ± 2 (regular). Melatonin onset (DLMO) was 2 h 36 min later in irregular sleepers (00:08 vs 21:32). SRI correlated with GPA (r = 0.37) — [Phillips et al. 2017, Sci Rep](https://www.nature.com/articles/s41598-017-03171-4)
- **Social jetlag.** Defined as the difference between mid-sleep on workdays and on free days. Coined by Wittmann, Dinich, Merrow & Roenneberg (2006). Reported as affecting over 70% of people by at least 1 h, citing Roenneberg et al. 2012 — [Wikipedia, "Social jetlag" (secondary; Cell and PubMed primaries blocked)](https://en.wikipedia.org/wiki/Social_jetlag)
- **HealthKit sleep data** exposes inBed, asleepCore, asleepDeep, asleepREM, awake and asleepUnspecified. Apple Watch records only awake samples that fall between sleep samples, so the start and end of an in-bed sample may have no detailed stage — [Apple, HKCategoryValueSleepAnalysis](https://developer.apple.com/documentation/healthkit/hkcategoryvaluesleepanalysis.md)

### Inferences
- **Lifestyle 2 (holiday) prior for a uni student (inference).**
  - Wake time mean = user's term free-day wake time, or term weekday wake + 50–90 min if free-day data are sparse. Prior SD 1.5× the term SD.
  - Sleep midpoint = term free-day mid-sleep, i.e. assume social jetlag collapses.
  - Expect day-to-day variability to rise.
  - Expect continued drift over the first 1–2 weeks (Bei), hence the faster forgetting for 14 days in §6.
- **Anchor extraction.** Take wake = end of the last asleep* sample of the main sleep episode, and sleep onset = start of the first asleep* sample. Handle missing stage edges (the Apple note) by falling back to inBed bounds. Where no Watch sleep data exist, cross-check with first phone unlock or first Watch activity.
- **ADHD adds to the evening tilt.** The irregular-sleep–delayed-DLMO link (Phillips) suggests planning should not assume holiday wake times will "snap back" when term resumes. Give L1 re-entry an explicit re-adaptation period: variance inflation for the first 3–5 days back.

### Gaps
- I could not open (Springer rate-limited) a review of chronotype and circadian delay in ADHD (e.g. Coogan & McGowan 2017). An ADHD-specific eveningness prior is therefore unsourced here.
- The Wright 2020 figures come from a university press summary. The Bei 2014 abstract gives no numeric minutes of delay.
- I found no Australian university-student data on sleep shifts during the uni break specifically.

---

## 8. How planner/recommender products personalise (Reclaim, Motion, Sunsama, Google, Apple)

### Takeaway
Of the products checked, the public docs of the mainstream AI schedulers (Motion, Reclaim) describe rule/priority-based auto-scheduling with user-entered durations. They say nothing about learning personal duration multipliers. Sunsama records planned vs actual time but shows no predictive use of it. Google Time Insights is purely descriptive. Apple does do on-device behavioural personalisation (Siri Suggestions) and privacy-preserving population learning (local DP, federated evaluation/tuning). Personal Bayesian duration and medication-window learning would be a genuine differentiator.

### Cited Findings
- **Motion.** Schedules by user-defined duration, deadline, priority and availability, with optional chunking. It "reshuffles automatically" when the calendar changes. The documentation does not mention learning durations from history — [Motion Help: Auto-scheduling](https://www.usemotion.com/help/time-management/auto-scheduling)
- **Reclaim.** Habits use P1–P4 priorities; same-priority ordering is Smart Meetings, then Habits, then Tasks. Habits "will never overbook Scheduling Link meetings or non-Reclaim created event[s]". Adjustable "Time Defense" free/busy aggressiveness. No mention of behavioural learning on this page — [Reclaim Help: Prioritizing your Habits](https://help.reclaim.ai/en/articles/4129286-prioritizing-your-habits)
- **Sunsama.** Actual time can be logged manually or by timer, and "the planned time will count as actual time" if actual time isn't entered and the setting is on. The workload counter shows "Actual vs. planned". No estimation-improvement feature is documented — [Sunsama Manual: Planned and Actual Times](https://help.sunsama.com/docs/planned-and-actual-times)
- **Google Calendar Time Insights.** Shows a time breakdown (focus time, 1:1, group meetings) and top 5 people. "Time in meetings is calculated as an average" over the previous 3 weeks or 3 months. It is descriptive, not predictive — [Google Calendar Help](https://support.google.com/calendar/answer/10738043?hl=en)
- **Apple Siri Suggestions.** "uses local, on-device processing to learn how you use your devices and apps". Personalisation syncs across devices "using end-to-end encryption" via iCloud — [Apple Legal: Siri, Dictation & Privacy](https://www.apple.com/legal/privacy/data/en/ask-siri-dictation/)
- **Apple local differential privacy.** Count Mean Sketch, Hadamard CMS and Sequence Fragment Puzzle, with ε = 4 for emoji and Safari-domain use cases and daily per-use-case limits on submissions — [Apple ML Research, "Learning with Privacy at Scale"](https://machinelearning.apple.com/research/learning-with-privacy-at-scale)
- **Apple federated evaluation and tuning.** Federated evaluation and tuning of on-device ML systems, including tuning "hyperparameters of on-device personalization" — [Apple ML Research, "Federated Evaluation and Tuning for On-Device Personalization" (2022)](https://machinelearning.apple.com/research/federated-personalization)

### Inferences
- **Borrowable patterns.** Reclaim's priority tiers and "never overbook fixed events" are exactly the hard-rules-vs-preferences split. Sunsama's actual-time capture is the data source the duration model needs. The app should make actual-time capture near-effortless (Watch start/stop, auto-stop on next task) because the whole learning loop depends on it.
- **Differentiators.** Personal duration multipliers with confidence intervals, a learned medication window and lifestyle regimes. None of these appear in the reviewed docs.

### Gaps
- I did not check Clockwise, Todoist, Structured, Tiimo, or Apple Sleep/Screen Time personalisation internals because the search limit was reached. Product docs don't disclose model internals, so "no learning mentioned" means the feature is undocumented, not that it is proven absent.

---

## 9. Explainability and trust: confidence display, thresholds, approval loop, contradiction handling

### Takeaway
Every learned number should carry (a) its evidence count ("based on 13 comparable sessions"), (b) an interval, and (c) a maturity label, drawn from the posterior's effective sample size. Learned *rules* ("move reading to mornings") must pass evidence thresholds and need explicit user approval. Stated preferences stay as strong priors and constraints; behaviour can only suggest changes to them.

### Cited Findings
- Showing people their own past experience at the moment of estimating removed the optimistic bias in Buehler Study 4 (60% vs 29.3% on time) — [Buehler et al. 1994](https://web.mit.edu/curhan/www/docs/Articles/biases/67_J_Personality_and_Social_Psychology_366,_1994.pdf)
- Recall of past durations is itself biased short (memory-bias account), so displayed evidence should be logged data — [Wikipedia, Planning fallacy (secondary)](https://en.wikipedia.org/wiki/Planning_fallacy)
- The N-of-1 guide recommends Bayesian posteriors for individual decisions because they give probabilistic statements about effect size — [AHRQ N-of-1 guide](https://effectivehealthcare.ahrq.gov/products/n-1-trials/research-2014-1)
- Partial pooling automatically shrinks estimates with little data toward the population, protecting against over-reading 2 examples — [Stan partial pooling case study](https://mc-stan.org/learn-stan/case-studies/pool-binary-trials.html)
- On-device LLM via Apple's Foundation Models framework: guided generation (@Generable) and tool calling. Requires Apple-Intelligence-capable devices — [Apple Foundation Models docs](https://developer.apple.com/documentation/foundationmodels.md)

### Inferences
- **Maturity ladder (effective n = count of relevant observations after forgetting).**
  - n < 3: show the prior only ("typical for people like you: ×1.4").
  - 3 ≤ n < 8: "early estimate (n = 5)" with a wide interval.
  - n ≥ 8 and 80% interval narrower than ×1.5: "learned".
  - Learned *rule proposals* need n ≥ 10 comparable events in the current lifestyle, P(effect > minimum worthwhile difference) ≥ 0.9, a stable result over the last 2 weeks, and user approval.
- **Explanation template.** "Essay drafting usually takes 1.6× your estimate (13 sessions this term; 8 in 10 finished within 2.1×). Planned 90 min → booking 2 h 25 min." Generate the numbers deterministically and optionally phrase them with the on-device LLM. Never let the LLM compute the numbers.
- **Stated vs revealed preference.** Encode a stated preference ("I study best 9–11") as the prior mean with κ = 10–15 pseudo-observations (strong). If behaviour disagrees with P > 0.9 after n ≥ 10, *ask*: "You've finished 11 of 12 study blocks after 2 pm but 3 of 9 before 11 am; update your preferred time?" Accept, reject or snooze. A rejection sets a 30-day cool-off on that suggestion.
- **Hard rules never learned.** Rules are a separate constraint layer (exams, fixed classes, medication reminders, sleep window floor). Learned models only change soft costs in the scheduler's objective.
- **Undo and audit.** Keep a "what the app learned" screen listing each learned parameter, n, interval and last change, with reset-to-prior per item. This is cheap because the state is sufficient statistics.

### Gaps
- I could not open Kay et al. 2016 ("When (ish) is my bus?", CHI) on uncertainty displays: the author site was rate-limited and ACM returned 403. Evidence on the best visual format for intervals on a phone or Watch (quantile dotplots etc.) is therefore not included.
- I found no empirical study of approval-loop designs for learned scheduling rules.

---

## 10. Missing data and bias

### Takeaway
Record *why* a planned item didn't happen, and treat the reasons differently:
- rule-driven or availability skips → not failures
- chosen skips → failures
- abandoned → censored durations
- unlogged → missing, possibly not at random

Expect about 20% missing check-ins. Keep prompts to one item, and use passive signals (HealthKit sleep, Watch activity/HR, app open times) to impute or flag missing logs rather than silently assuming good days.

### Cited Findings
- EMA average compliance was 79%. The number of assessments per day did not predict compliance or dropout; incentives helped (about 82% vs 76%) — [Wrzus & Neubauer 2023](https://journals.sagepub.com/doi/10.1177/10731911211067538)
- Longer questionnaires, not more frequent prompts, increased burden and lowered data quality — [Eisele et al. 2022 abstract](https://research.tilburguniversity.edu/en/publications/the-effects-of-sampling-frequency-and-questionnaire-length-on-per/)
- Censored observations enter the likelihood via the CCDF and can be integrated out — [Stan User's Guide](https://mc-stan.org/docs/stan-users-guide/truncation-censoring.html)
- HeartSteps: decision points where the user is unavailable are excluded from randomisation, e.g. driving → A = 0 — [Liao et al. 2019](https://arxiv.org/pdf/1909.03539)
- Sunsama can default actual = planned when no actual is entered. Doing that would bias learning toward the plan — [Sunsama manual](https://help.sunsama.com/docs/planned-and-actual-times)

### Inferences
- **Reason codes** (one tap, shown only when an item lapses):
  1. *Blocked by rule/event* (clash, class ran over, exam) → unavailable; excluded from completion likelihood and duration model.
  2. *Chose not to / couldn't start* → completion failure for that slot/context.
  3. *Started, stopped* → censored duration at the elapsed time.
  4. *Did it but didn't log* → ask for the actual; else mark the duration missing, completion = success.
  5. *No response* → missing.
- **Never default actual = planned** for learning, even if the UI does so for display. That would pull multipliers toward 1 (the Sunsama default shows this risk).
- **Selection bias from logging only good days.** Track "logging coverage" per day: fraction of planned items with an outcome, plus whether any passive data exist. Weight days by inverse coverage probability, or exclude days with coverage under 30% from completion models, and show coverage in the interface. When passive signals show normal activity but the app wasn't opened, treat the day as MNAR-missing and do not count it as success or failure.
- **Survivorship / abandonment.** If a user stops logging for 3 or more days, freeze forgetting (don't decay toward the prior on empty days). On return, re-enter with a "welcome back" low-burden mode. Don't read the gap as a lifestyle change unless passive anchors say so.
- **Passive imputation.** Wake/sleep from HealthKit. Medication "on" from HR residual (weak). Task probably done from Screen Time / Focus mode / calendar attendance where permitted. Use these as priors for the missing value, not as ground truth.

### Gaps
- I did not open self-tracking abandonment studies (e.g. Epstein et al. "lived informatics"; ACM blocked, search limit reached).
- I found no ADHD-specific EMA compliance meta-analysis.

---

## 11. On-device ML on Apple: Core ML, updatable models, plain Swift Bayes, federated learning, differential privacy

### Takeaway
Nearly everything recommended here is closed-form or tiny-grid Bayesian arithmetic: NIG, Beta, Laplace-logistic, a grid over about 700 medication-curve cells, BOCPD with pruning, CUSUM. It should be written in plain Swift, with state as sufficient statistics in the app container. Core ML's MLUpdateTask (on-device updates of compiled updatable models) is only needed if a neural or kNN component is added later. Population priors can later be improved without collecting raw data, using Apple-style local DP or federated learning/tuning.

### Cited Findings
- **MLUpdateTask** is "a task that updates a model with additional training data" on the user's device. Available from iOS 13 / watchOS 6. Created from a compiled model URL plus an MLBatchProvider, with progress/completion handlers giving an MLUpdateContext — [Apple, MLUpdateTask](https://developer.apple.com/documentation/coreml/mlupdatetask.md)
- **Apple's personalisation sample.** On-device updates create "a personalized experience for the user while keeping their data private". An update task can only update a *compiled* (.mlmodelc) model. The updated model is written to disk and reloaded — [Apple, "Personalizing a Model with On-Device Updates"](https://developer.apple.com/documentation/coreml/personalizing-a-model-with-on-device-updates.md)
- **Local DP at Apple** (CMS/HCMS/SFP; ε = 4 in documented use cases; daily submission limits) — [Apple ML Research](https://machinelearning.apple.com/research/learning-with-privacy-at-scale)
- **Federated evaluation and tuning** of on-device personalisation hyperparameters — [Apple ML Research](https://machinelearning.apple.com/research/federated-personalization)
- **On-device LLM (Foundation Models framework)** for language tasks, with guided generation into Swift types and tool calling. Also has a Private Cloud Compute option — [Apple Foundation Models docs](https://developer.apple.com/documentation/foundationmodels.md)
- **GP regression cost** is O(n³) for training (n³/6 Cholesky). That is fine for n ≤ a few hundred check-ins but unnecessary given grid posteriors — [GPML ch. 2](http://gaussianprocess.org/gpml/chapters/RW2.pdf)
- **BOCPD** runs in average constant time per step with pruning — [Adams & MacKay](https://arxiv.org/pdf/0710.3742)

### Inferences
- **Implementation stack.**
  - Swift structs for the NIG, Beta and diagonal-Gaussian logistic states.
  - Nightly BGAppProcessingTask to run updates, change-point checks and the Lifestyle detector.
  - Watch collects taps and HR. The phone owns the model state and syncs it to the Watch.
  - For cross-device sync, use CloudKit private database / end-to-end-encrypted containers, mirroring Apple's own approach for Siri personalisation.
- **Hyperparameter learning without raw data (future).** Estimate population priors (m₀, τ², default multipliers, medication-window priors per formulation) by federated aggregation of per-user posterior summaries with DP noise, i.e. empirical Bayes across users. This follows Apple's FE&T idea of federated tuning of personalisation hyperparameters. Needs a server and consent; out of scope for v1.
- **Privacy benefit.** Medication and ADHD data are health data. Keeping raw logs on-device and exporting nothing by default strongly reduces privacy exposure (a legal/compliance review is outside this scope).

### Gaps
- I did not verify the current Create ML/Core ML updatable layer types (the MLUpdateTask docs page doesn't list them) or iOS 26-era changes to background-task limits.
- I did not check Apple's published federated learning with DP numbers (ε, cohort sizes) for personalisation.

---

## 12. Evaluation: does learning improve plans?

### Takeaway
Evaluate prequentially (predict, then observe, then update) on the user's own stream:
- calibration of duration quantiles (P50 hit ≈ 50%, P80 hit ≈ 80%)
- log score / pinball loss
- Brier score and reliability for completion probabilities
- behavioural outcomes: plan adherence, reschedules per day, overrun minutes, suggestion acceptance

Log randomisation propensities for every decision so notification and slot policies can be compared offline with unbiased replay.

### Cited Findings
- **Replay (off-policy) evaluation.** Logged data from a random or known logging policy can give "provably unbiased" offline evaluation by keeping events where the logged action matches the candidate policy's action. Validated against online bucket tests on Yahoo! Front Page data — [Li, Chu, Langford & Wang, arXiv:1003.5956](https://arxiv.org/abs/1003.5956)
- HeartSteps tuned algorithm hyperparameters (γ, w) by grid search on simulated rewards from V1 generative models, i.e. offline simulation before deployment — [Liao et al. 2019](https://arxiv.org/pdf/1909.03539)
- Reference-class uplifts are themselves calibrated quantiles of historical overrun (P50 vs P80) — [Flyvbjerg](https://arxiv.org/pdf/1302.3642)
- Planning-fallacy base rate to beat: about 30% of people finish within their "best guess" — [Buehler et al. 1994](https://web.mit.edu/curhan/www/docs/Articles/biases/67_J_Personality_and_Social_Psychology_366,_1994.pdf)

### Inferences
- **Duration metrics.**
  - Coverage: share of tasks with actual ≤ predicted P50 (target 0.5) and ≤ P80 (target 0.8), tracked over a rolling 30 tasks.
  - Pinball loss at q = 0.5 and 0.8.
  - Median |log(actual/predicted P50)|, compared against the raw-user-estimate baseline. The baseline's on-time rate is about 30% per Buehler.
- **Completion predictions.**
  - Brier = mean (p − outcome)².
  - Reliability diagram in about 5 bins.
  - Log loss, against baselines: the constant personal completion rate and the stated-preference-only model.
- **Plan-level.**
  - Plan adherence (share of blocks done within ±30 min of plan).
  - Reschedules/day.
  - End-of-day overrun minutes.
  - Share of days the plan was "realistic" (user rating).
  - Acceptance rate of learned-rule suggestions.
  - For receptivity: acted-on-within-30-min rate, with the burden variable as a covariate.
- **Offline replay.** Keep the raw event log with lifestyle labels and propensities (π clipped to [0.1, 0.8]). Before shipping a new model version, replay it over the user's history (or a consenting pilot cohort) and compare against the current model. Tune κ₀, forgetting λ, BOCPD hazard and the Lifestyle-detector threshold by maximising prequential log score and minimising false switch prompts.
- **Pilot N-of-1 at product level.** Randomise on/off days for "learned multiplier applied" vs "raw estimate" (in blocks of 2 days, per the AHRQ guide) for consenting pilot users. This gives a within-person causal estimate of whether learning improves adherence.

### Gaps
- I found no published benchmark of calibration or adherence gains from personal duration learning in planner apps; none of the reviewed product docs publish such metrics.
- I did not fetch a primary source for Brier-score definitions (the formula given is standard).
