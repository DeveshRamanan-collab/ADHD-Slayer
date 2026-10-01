# ADHD medication pharmacokinetics and pharmacodynamics for a personalised "medication effect window" model

Scope note: product-design reference only; the app never recommends doses. Numbers are label or study figures, mostly from single-dose, fasted or paediatric studies, so they are starting priors, not predictions for any one person. Research date: 28 September 2026.

Source-access caveats (apply to the whole note): TGA eBS PI PDFs, the TGA shortage pages (robots/timeouts), PubMed/PMC abstract pages (reCAPTCHA), NICE NG87 (403) and two ACSQHC CMI pages (Concerta, Ritalin LA) could not be opened. Wherever possible, US FDA labels, the NZ Medsafe Concerta data sheet (same sponsor as in Australia) and Australian CMI text via the ACSQHC Medicine Finder stand in for TGA PIs. The session's shared web-search budget ran out partway through, and the Europe PMC API began rate-limiting, so a few planned lookups (Mydayis adult data, caffeine interaction studies, adult rebound prevalence, chronotype) are listed as gaps instead.

Shorthand: EPMC = Europe PMC REST record for PMIDs 10511066, 16740846, 23407278 and 17701403 (abstracts read via https://www.ebi.ac.uk/europepmc/webservices/rest/search?query=EXT_ID:10511066%20OR%20EXT_ID:16740846%20OR%20EXT_ID:23407278%20OR%20EXT_ID:17701403&format=json&resultType=core).

---

## Q1. Formulation profiles: names, brands, release mechanism, onset, Tmax, duration, curve shape

### Takeaway
Short-acting stimulants such as methylphenidate IR (onset 20–60 min, 2–4 h) and dexamfetamine IR (onset 20–60 min, 3–6 h) give a single hump that switches on fast. Long-acting products differ in curve shape as well as length. Ritalin LA and Focalin XR (50:50 beads) give two peaks about 4 h apart and last about 6–8 h or up to 12 h. Concerta (22% IR overcoat, osmotic core) peaks early at about 1–2 h, keeps rising to a Tmax of 6–10 h and is labelled for 12 h. Lisdexamfetamine is a prodrug: effect is measurable from about 1.5–2 h and has been shown up to 14 h in adults. Atomoxetine, guanfacine and clonidine do not produce a daily "window" that could be scheduled around, because their effect builds over weeks.

### Cited Findings

**Methylphenidate IR (AU: Ritalin 10, Artige; US: Ritalin, Methylin)**
- Listed in Australia as IR methylphenidate under the brands Ritalin and Artige, taken 2–3 times daily, PBS-listed with no age restriction (jurisdictional rules apply) — [Australian Prescriber, 10 Feb 2026](https://australianprescriber.tg.org.au/articles/pharmacological-management-of-attention-deficit-hyperactivity-disorder-in-adults.html)
- Tmax in children 1.9 h (range 0.3–4.4 h), adults similar. Label advises dosing 2–3 times daily, 30–45 min before meals, with the last dose before 6 p.m. to avoid insomnia — [FDA Ritalin/Ritalin-SR label 2019](https://www.accessdata.fda.gov/drugsatfda_docs/label/2019/010187s071s082,018029s041s051lbl.pdf)
- Food effect as reported in the label: a high-fat meal increased AUC by about 25% and Cmax by about 27%. Median peak was 2.5 h fed versus 3 h fasted in that comparison — [FDA Ritalin label 2019](https://www.accessdata.fda.gov/drugsatfda_docs/label/2019/010187s071s082,018029s041s051lbl.pdf)
- Onset 20–60 min, peak about 1–2 h, duration 2–4 h, 1:1 d/l racemate, half-life 2.5–3.5 h — [Psych Scene Hub](https://psychscenehub.com/psychbytes/methylphenidate-mechanism-of-action-side-effects-and-dosing/)
- IR stimulants in general last 3–6 h and sustained-release products 8–12 h — [Univ. Washington stimulant management handout](https://depts.washington.edu/dbpeds/13StimulantMedicationManage.pdf)

**Methylphenidate SR (US: Ritalin-SR; matrix tablet)**
- Tmax 4.7 h (1.3–8.2 h) in children. Provides about 8 h of effect and may replace IR when the 8-hour dosages correspond. Must be swallowed whole — [FDA Ritalin/Ritalin-SR label](https://www.accessdata.fda.gov/drugsatfda_docs/label/2019/010187s071s082,018029s041s051lbl.pdf)
- Not among the MPH products Australian Prescriber lists for Australia in 2026 (Ritalin, Artige, Ritalin LA, Concerta) — [Australian Prescriber 2026](https://australianprescriber.tg.org.au/articles/pharmacological-management-of-attention-deficit-hyperactivity-disorder-in-adults.html)

**Methylphenidate LA (AU/US: Ritalin LA; SODAS beads, 50% IR : 50% enteric-coated delayed-release)**
- Half the dose is in IR beads and half in enteric-coated beads, giving two peaks about 4 h apart:
  - Cmax1 at 1–3 h
  - Cmax2 at about 5–6 h
  - interpeak minimum at about 4–4.5 h
- Half-life about 3.5 h in adults (range 1.3–7.7 h) and about 2.5 h in children.
- Conversion: 10 mg IR bd equals 20 mg LA once daily.
- Capsule may be sprinkled on cold applesauce.
- Source for this group: [FDA Ritalin LA label 2025](https://www.accessdata.fda.gov/drugsatfda_docs/label/2025/021284s050lbl.pdf)
- Food: a high-fat meal gives a "longer lag time until absorption began and variable delays" in peak times, and the second peak is about 25% lower. Applesauce made no difference. Alcohol at 40% released 98% of the dose in the first hour (dose dumping) — [FDA Ritalin LA label 2025](https://www.accessdata.fda.gov/drugsatfda_docs/label/2025/021284s050lbl.pdf)
- Duration 6–8 h and peaks at about 2 h and 6 h. The same source gives onset as "~2 hrs", which conflicts with the IR-bead half of the dose (Cmax1 at 1–3 h per the FDA label) — [Psych Scene Hub](https://psychscenehub.com/psychbytes/methylphenidate-mechanism-of-action-side-effects-and-dosing/)
- AU PBS: Ritalin LA is PBS-listed for adults, whether diagnosed in childhood or retrospectively in adulthood, once response to IR has been shown — [Australian Prescriber 2026](https://australianprescriber.tg.org.au/articles/pharmacological-management-of-attention-deficit-hyperactivity-disorder-in-adults.html)
- IR:ER ratio 50:50 for both Ritalin LA and Focalin XR (SODAS) — [Head-to-head review, PMC3852277](https://pmc.ncbi.nlm.nih.gov/articles/PMC3852277/)

**Methylphenidate OROS (AU: Concerta, plus generics such as Methylphenidate-Teva XR; US: Concerta; UK: Concerta XL)**
- The osmotic trilayer core sits under an IR drug overcoat holding about 22% of the dose. Plasma levels reach an initial maximum at about 1 h, then rise gradually over the next 5–9 h, with mean Tmax at 6–10 h.
- Single dose of 18 mg in adults: Cmax 3.7 ± 1.0 ng/mL, Tmax 6.8 ± 1.8 h, t½ 3.5 ± 0.4 h. No accumulation.
- Food: a high-fat breakfast did not change PK or pharmacodynamic performance.
- Alcohol up to 40% did not increase release in the first hour.
- Effect was maintained through 12 h in paediatric laboratory classroom studies.
- CL/F was 58% higher in adolescents than in children, and heavier people may have lower exposure at the same dose.
- Source for this group: [FDA Concerta label 2023](https://www.accessdata.fda.gov/drugsatfda_docs/label/2023/021121s049lbl.pdf)
- NZ data sheet (same sponsor): initial maximum at about 1–2 h, peak at about 6–8 h, t½ about 3.5 h in adults. SKAMP "onset of efficacy was estimated to be 1.5 hours and duration continued through to 12 hours". No PK or PD difference fasted, after a normal breakfast or after a high-fat breakfast — [Medsafe Concerta data sheet](https://www.medsafe.govt.nz/profs/datasheet/c/concertatab.pdf)
- A secondary source gives the ratio as "25% immediate / 75% gradual", which conflicts with the label's 22% overcoat, and a duration of 10–12 h — [Psych Scene Hub](https://psychscenehub.com/psychbytes/methylphenidate-mechanism-of-action-side-effects-and-dosing/); contradicted by the [FDA Concerta label](https://www.accessdata.fda.gov/drugsatfda_docs/label/2023/021121s049lbl.pdf)
- AU PBS: Concerta is subsidised only for ages 6–18 diagnosed in childhood — [Australian Prescriber 2026](https://australianprescriber.tg.org.au/articles/pharmacological-management-of-attention-deficit-hyperactivity-disorder-in-adults.html)
- Other MPH-ER ratios (mostly UK/Canada): Equasym XL 30:70 (Diffucaps), Medikinet retard 50:50, Biphentin 40:60, Concerta 22:78 — [PMC3852277](https://pmc.ncbi.nlm.nih.gov/articles/PMC3852277/)

**Dexmethylphenidate (US: Focalin IR, Focalin XR; not listed as available in AU)**
- Focalin XR: 50% IR beads and 50% enteric-coated beads. First peak about 1.5 h (range 1–4 h), second peak about 6.5 h (range 4.5–7 h), roughly 4 h apart.
- t½ just over 3 h in adults (typically 2–4.5 h).
- A high-fat breakfast delays the first peak by a variable amount and lowers the second peak by about 25%.
- Effect seen at all time points through 12 h in paediatric classroom studies.
- Source for this group: [FDA Focalin XR label 2017](https://www.accessdata.fda.gov/drugsatfda_docs/label/2017/021802s033lbl.pdf)
- Not in Australian Prescriber's 2026 list of medicines available in Australia — [Australian Prescriber 2026](https://australianprescriber.tg.org.au/articles/pharmacological-management-of-attention-deficit-hyperactivity-disorder-in-adults.html)

**Dexamfetamine IR (AU: Aspen Dexamfetamine 5 mg; US: Dexedrine/Zenzedi)**
- In Australia it is taken 2–3 times daily and PBS-listed with no age restriction — [Australian Prescriber 2026](https://australianprescriber.tg.org.au/articles/pharmacological-management-of-attention-deficit-hyperactivity-disorder-in-adults.html)
- AU CMI: 5 mg scored tablets, taken early in the day, avoiding late evening. Maximum 40 mg for ADHD, in two divided doses. Acidifying agents (vitamin C, fruit juices) and alkalinising agents change absorption and excretion — [ACSQHC Medicine Finder, Aspen Dexamfetamine](https://www.safetyandquality.gov.au/medicine-finder/aspen-dexamfetamine)
- Onset 20–60 min and duration 3–6 h — [Psych Scene Hub, dexamphetamine/LDX](https://psychscenehub.com/psychbytes/dexamphetamine-and-lisdexamfetamine-mechanism-of-action-side-effects-and-dosing/)
- IR onset 30–45 min, Tmax about 3 h for IR (about 7 h for XR), and IR duration 3–6 h. t½ 9–11 h at normal urinary pH, ranging from 7 h (acidic urine) to 34 h (alkaline urine) — [Wikipedia, Dextroamphetamine](https://en.wikipedia.org/wiki/Dextroamphetamine) (secondary source)
- Adderall IR (d/l salts): Tmax about 3 h for both isomers. t½ 9.77–11 h (d-isomer) and 11.5–13.8 h (l-isomer). Food effect not studied. Doses are taken on waking and then at 4–6 h intervals, avoiding late evening — [FDA Adderall label 2017](https://www.accessdata.fda.gov/drugsatfda_docs/label/2017/011522s043lbl.pdf)

**Lisdexamfetamine (AU: Vyvanse capsules 20/30/40/50/60/70 mg; US: Vyvanse capsules and chewables; UK brand not verified)**
- The prodrug is hydrolysed to d-amphetamine, mainly by red blood cells.
- Fasted capsule: LDX Tmax about 1 h. d-amphetamine Tmax about 3.5 h in children aged 6–12 and about 3.8 h in adults.
- Chewable: d-amphetamine Tmax about 4.4 h.
- Food delays Tmax by about 1 h with no change in AUC or Cmax (capsule). A high-fat meal lowers d-amphetamine exposure from the chewable by 5–7%.
- d-amphetamine t½ 10–11.3 h in adults and 8.6–9.5 h in children.
- Low variability: under 25% between subjects and under 8% within subjects. PK is linear from 50 to 250 mg in adults.
- Capsule contents can be mixed into yoghurt, water or orange juice.
- The label says to avoid afternoon doses because of insomnia.
- Source for this group: [FDA Vyvanse label 2023](https://www.accessdata.fda.gov/drugsatfda_docs/label/2023/021977s050,208510s007lbl.pdf)
- Adult workplace study (PERMP, dose 30–70 mg): effect significant at every post-dose time point from 2 h to 14 h (the last one tested) — [FDA Vyvanse label](https://www.accessdata.fda.gov/drugsatfda_docs/label/2023/021977s050,208510s007lbl.pdf); [Wigal et al. 2010](https://link.springer.com/article/10.1186/1744-9081-6-34)
- In healthy adults given LDX 100 mg versus d-amphetamine 40 mg (equimolar): d-amphetamine Tmax was 4.6 h (range 2.5–8.4 h) after LDX versus 3.3 h (0.9–5.9 h) after d-amphetamine. LDX had a lag time 0.6 ± 0.6 h longer. Peak subjective ratings did not differ between the two — [Frontiers in Pharmacology 2017](https://www.frontiersin.org/journals/pharmacology/articles/10.3389/fphar.2017.00617/full)
- AU CMI: capsules once daily in the morning with or without food. The AU CMI lists capsules only (20–70 mg), so there is no chewable in Australia — [ACSQHC Medicine Finder, Vyvanse](https://www.safetyandquality.gov.au/medicine-finder/vyvanse)
- Onset about 90 min and duration "13 plus hours" (1.5–13 h in children, 2–14 h in adults) — [Psych Scene Hub](https://psychscenehub.com/psychbytes/dexamphetamine-and-lisdexamfetamine-mechanism-of-action-side-effects-and-dosing/)

**Mixed amphetamine salts (US: Adderall IR, Adderall XR, Mydayis; not TGA-registered)**
- Adderall XR: two bead types (IR plus delayed release), d:l ratio 3:1.
- Tmax about 7 h (versus about 3 h for IR). Food delays Tmax by 2.5 h (d-isomer) and 2.7 h (l-isomer).
- Adult t½ about 10 h (d) and 12–13 h (l), each about 1–2 h shorter in children.
- Urinary recovery of amphetamine ranges from 1% to 75% depending on urinary pH.
- CYP2D6 forms 4-hydroxy-amphetamine.
- Source for this group: [FDA Adderall XR label 2015](https://www.accessdata.fda.gov/drugsatfda_docs/label/2015/021303s031lbl.pdf)
- Adderall is not available in Australia; manufacturers did not apply rather than being rejected — [ADHD Mums, "medications Australia doesn't have"](https://adhdmums.com.au/adhd-medications-not-available-australia/)
- An adult workplace study of SHP465 (Mydayis) exists (Wigal 2018) — [Frontiers lab-school mini-review](https://www.frontiersin.org/journals/psychology/articles/10.3389/fpsyg.2019.01796/full)

**Atomoxetine (AU: atomoxetine; brand not verified; US: Strattera)**
- Tmax 1–2 h. A high-fat meal lowers Cmax by 37% and delays Tmax by 3 h, with no change in AUC.
- t½ 5.2 h in extensive metabolisers and 21.6 h in CYP2D6 poor metabolisers.
- Can be given once daily or as two doses (morning and late afternoon).
- Source for this group: [FDA Strattera label 2022](https://www.accessdata.fda.gov/drugsatfda_docs/label/2022/021411s050lbl.pdf)
- AU: onset may take 2–3 months. PBS covers only ages 6–18 with contraindication or intolerance to stimulants, prescribed by a psychiatrist or paediatrician — [Australian Prescriber 2026](https://australianprescriber.tg.org.au/articles/pharmacological-management-of-attention-deficit-hyperactivity-disorder-in-adults.html)

**Guanfacine XR (AU: guanfacine available; US: Intuniv)**
- Tmax about 5 h in children and adolescents, t½ about 18 h.
- A high-fat meal raises Cmax by about 75% and AUC by about 40%; do not take with a high-fat meal.
- May be taken morning or evening.
- Improvement is gradual, and trials ran 5–15 weeks.
- CYP3A4 substrate.
- Source for this group: [FDA Intuniv label 2019](https://www.accessdata.fda.gov/drugsatfda_docs/label/2019/022037s018lbl.pdf)
- Guanfacine is listed as available in Australia — [ADHD Mums](https://adhdmums.com.au/adhd-medications-not-available-australia/)

**Clonidine (AU: Catapres IR, S4, used off-label; US: Kapvay ER, Onyda XR)**
- IR onset 30–60 min, peak 60–90 min, duration 4–8 h, t½ 12–16 h. Sedating; IR at bedtime is used for sleep onset. Abrupt stop risks rebound hypertension — [Wikipedia, Clonidine](https://en.wikipedia.org/wiki/Clonidine) (secondary source)
- Onyda XR is not available in Australia — [ADHD Mums](https://adhdmums.com.au/adhd-medications-not-available-australia/)

#### Summary table (label and study derived; "—" means not found)

| Medication / formulation | AU brand (US / UK) | Release mechanism | Onset | Tmax | Duration of effect | Curve shape | Food effect | Source |
|---|---|---|---|---|---|---|---|---|
| Methylphenidate IR | Ritalin 10, Artige (Ritalin, Methylin) | IR tablet, racemic | 20–60 min | 1.9 h (0.3–4.4) children | 2–4 h (IR class 3–6 h) | Single fast hump; t½ 2.5–3.5 h | High-fat: AUC +25%, Cmax +27% | [FDA Ritalin](https://www.accessdata.fda.gov/drugsatfda_docs/label/2019/010187s071s082,018029s041s051lbl.pdf), [PSH](https://psychscenehub.com/psychbytes/methylphenidate-mechanism-of-action-side-effects-and-dosing/) |
| Methylphenidate SR | not listed in AU 2026 (Ritalin-SR) | Wax-matrix tablet | — | 4.7 h (1.3–8.2) | ~8 h | Single broad hump | — | [FDA Ritalin-SR](https://www.accessdata.fda.gov/drugsatfda_docs/label/2019/010187s071s082,018029s041s051lbl.pdf) |
| Methylphenidate LA | Ritalin LA (Ritalin LA; UK Medikinet XL similar 50:50) | SODAS beads 50 IR : 50 delayed | ~0.5–1 h expected; one source says "~2 h" (conflict) | Peak 1: 1–3 h; peak 2: 5–6 h; trough 4–4.5 h | 6–8 h | Bimodal, peaks ~4 h apart | High-fat: longer lag, variable delay, peak 2 −25%; alcohol dose-dumps | [FDA Ritalin LA](https://www.accessdata.fda.gov/drugsatfda_docs/label/2025/021284s050lbl.pdf), [PSH](https://psychscenehub.com/psychbytes/methylphenidate-mechanism-of-action-side-effects-and-dosing/) |
| Methylphenidate OROS | Concerta, Methylphenidate-Teva XR (generic) (Concerta; UK Concerta XL) | Osmotic pump + 22% IR overcoat | 1.5 h (SKAMP) | Initial max ~1–2 h; Tmax 6–10 h (18 mg adults 6.8 ± 1.8 h) | 12 h | Ascending (22:78): small early peak then rise to late peak | None (fasted = normal = high-fat) | [FDA Concerta](https://www.accessdata.fda.gov/drugsatfda_docs/label/2023/021121s049lbl.pdf), [Medsafe](https://www.medsafe.govt.nz/profs/datasheet/c/concertatab.pdf) |
| Dexmethylphenidate XR | not in AU (Focalin XR) | SODAS 50:50 | — | Peak 1: 1.5 h (1–4); peak 2: 6.5 h (4.5–7) | ≥12 h (paediatric classroom) | Bimodal | High-fat: variable delay of peak 1; peak 2 −25% | [FDA Focalin XR](https://www.accessdata.fda.gov/drugsatfda_docs/label/2017/021802s033lbl.pdf) |
| Dexamfetamine IR | Aspen Dexamfetamine 5 mg (Dexedrine, Zenzedi) | IR tablet | 20–60 min | ~3 h | 3–6 h | Single hump; long t½ (9–11 h, 7–34 h by urine pH) but shorter effect | Not studied; GI/urinary acidifiers lower levels, alkalinisers raise them | [ACSQHC](https://www.safetyandquality.gov.au/medicine-finder/aspen-dexamfetamine), [PSH](https://psychscenehub.com/psychbytes/dexamphetamine-and-lisdexamfetamine-mechanism-of-action-side-effects-and-dosing/), [Adderall IR label](https://www.accessdata.fda.gov/drugsatfda_docs/label/2017/011522s043lbl.pdf) |
| Lisdexamfetamine | Vyvanse capsules 20–70 mg (Vyvanse caps + chewable) | Prodrug, RBC hydrolysis (rate-limited conversion) | ~1.5–2 h (sig. at 2 h adults, 1.5 h children) | d-amph 3.8 h adults fasted; 4.4 h chewable; 4.6 h in one healthy-adult study | 13–14 h (adults sig. to 14 h, last tested) | Smooth single broad peak; slow rise and fall | +~1 h Tmax, no AUC change | [FDA Vyvanse](https://www.accessdata.fda.gov/drugsatfda_docs/label/2023/021977s050,208510s007lbl.pdf), [Wigal 2010](https://link.springer.com/article/10.1186/1744-9081-6-34) |
| Mixed amphetamine salts XR | not in AU (Adderall XR) | Two-pulse beads, d:l 3:1 | — | ~7 h (IR ~3 h) | — (XR class 8–12 h) | Two pulses, smoothed by long t½ | +2.5 h Tmax (d), +2.7 h (l) | [FDA Adderall XR](https://www.accessdata.fda.gov/drugsatfda_docs/label/2015/021303s031lbl.pdf) |
| Atomoxetine | atomoxetine (Strattera) | NRI, IR capsule | Weeks (2–3 months) | 1–2 h | Continuous once at steady state | No daily window | High-fat: Cmax −37%, Tmax +3 h | [FDA Strattera](https://www.accessdata.fda.gov/drugsatfda_docs/label/2022/021411s050lbl.pdf), [Aust Prescr](https://australianprescriber.tg.org.au/articles/pharmacological-management-of-attention-deficit-hyperactivity-disorder-in-adults.html) |
| Guanfacine XR | guanfacine (Intuniv) | α2A agonist ER tablet | Weeks | ~5 h | Continuous; t½ ~18 h | No daily window; possible sedation near Tmax | High-fat: Cmax +75%, AUC +40% | [FDA Intuniv](https://www.accessdata.fda.gov/drugsatfda_docs/label/2019/022037s018lbl.pdf) |
| Clonidine IR | Catapres (off-label) (Kapvay, Onyda XR) | α2 agonist | 30–60 min | 60–90 min | 4–8 h | Sedation hump | — | [Wikipedia](https://en.wikipedia.org/wiki/Clonidine) |
| Centanafadine | not in AU (Simtriyo, FDA 24 Jul 2026) | IR + ER + DR bead capsule; NDSRI | Separation from placebo by week 1 | 5 h | — | — | High-fat: Cmax +29%, Tmax +1.5 h | [PEF](https://psychiatryeducationforum.com/centanafadine/), [Psychopharm Inst](https://psychopharmacologyinstitute.com/publication/2026-august-update-centanafadine-oveporexton-and-new-guidance-on-ocd-lithium-and-insomnia/) |
| Viloxazine ER | not in AU (Qelbree) | NRI-modulator ER capsule | Weeks | 5 h (3–9) | Continuous; t½ 7 h | No daily window | High-fat: Tmax +2 h, Cmax −9% | [FDA Qelbree 2021](https://www.accessdata.fda.gov/drugsatfda_docs/label/2021/211964s000lbl.pdf) |

### Inferences
- Treat curve shape, not just duration, as a per-product property. A Ritalin LA user may report a dip at about 4–4.5 h. A Concerta user may feel a weaker first 2–4 h and stronger late effect, which is the COMACS pattern (see Q6).
- Plasma half-life is a poor proxy for duration of effect with amphetamines. d-amphetamine t½ is about 10 h, yet IR effect lasts about 3–6 h, which fits acute tolerance (see Q3 and Q6).
- For atomoxetine, guanfacine, viloxazine, centanafadine and clonidine taken as maintenance, the app should not try to learn a daily onset/offset window. At most it could note time-of-day side effects (for example sedation around Tmax for α2 agonists) where the user logs them.

### Gaps
- TGA PIs for Ritalin LA, Concerta, Vyvanse, dexamfetamine, atomoxetine and Intuniv could not be opened (eBS blocked), so FDA labels and the Medsafe data sheet stand in. AU-specific wording (for example Vyvanse AU clinical-study durations) is unverified.
- The AU brand names for atomoxetine (Strattera plus generics) and guanfacine (Intuniv) and their current PBS status for adults were not verified beyond the "available" statement.
- The Ritalin LA onset time (first significant effect) was not found in a primary label, and secondary sources conflict.
- Mydayis adult duration (widely reported as up to 16 h) and Jornay PM (evening-dosed delayed-release MPH) PK could not be verified: PMC5771548 was blocked by reCAPTCHA and the search budget ran out.
- UK SmPCs (for example Elvanse, Equasym XL, Medikinet XL) were not opened.

---

## Q2. New ADHD medicines 2023–2026 (TGA/PBS and US)

### Takeaway
I found no evidence that a new ADHD active ingredient was registered in Australia in 2023–2026. The FDA approved centanafadine (Simtriyo) on 24 July 2026 as the first NDSRI for ADHD, but it was not dispensable pending DEA scheduling as of August 2026. Viloxazine (Qelbree), Jornay PM, Azstarys, Onyda XR and Adderall remain unavailable in Australia because sponsors have not applied.

### Cited Findings
- Centanafadine (Simtriyo, Otsuka) was FDA-approved on 24 July 2026 for ages 6+ weighing at least 20 kg:
  - once-daily ER capsules of 140/210/280 mg; adults start at 210 mg and may go to 280 mg
  - separation from placebo appeared at week 1
  - small effect sizes in adults (Cohen's d 0.24–0.40), no head-to-head trials
  - cannot be dispensed until the DEA assigns a schedule
  - Source: [Psychopharmacology Institute, Aug 2026 update](https://psychopharmacologyinstitute.com/publication/2026-august-update-centanafadine-oveporexton-and-new-guidance-on-ocd-lithium-and-insomnia/)
- Centanafadine PK:
  - capsule mixes IR, ER and DR beads
  - Tmax 5 h, t½ 5.2 h
  - high-fat meal raises Cmax by 29% and delays Tmax by 1.5 h, with no AUC change
  - morning once-daily dosing
  - Source: [Psychiatry Education Forum](https://psychiatryeducationforum.com/centanafadine/)
- Not TGA-registered: Qelbree (viloxazine), Jornay PM, Onyda XR, Azstarys, Adderall and Simtriyo. "None of these medications were assessed and knocked back in Australia. They were never brought forward." — [ADHD Mums](https://adhdmums.com.au/adhd-medications-not-available-australia/)
- Viloxazine ER PK:
  - Tmax about 5 h (3–9 h), t½ 7.02 ± 4.74 h, steady state in 2 days
  - high-fat meal delays Tmax by about 2 h
  - strong CYP1A2 inhibitor and weak CYP2D6 inhibitor
  - the 2021 label covers ages 6–17 only
  - Source: [FDA Qelbree label 2021](https://www.accessdata.fda.gov/drugsatfda_docs/label/2021/211964s000lbl.pdf)
- The only lisdexamfetamine change in Australia is the one in Q10 (adult PBS extension and extra strengths, now 20–70 mg) — [ADHD Australia](https://www.adhdaustralia.org.au/success-in-changing-the-pbs-for-adhd-medications/); [ACSQHC Vyvanse](https://www.safetyandquality.gov.au/medicine-finder/vyvanse)
- Section 19A imports (for example Swiss-registered Concerta through Medsurge) filled shortage gaps. They were temporary substitutes, not new registrations — [AADPA shortages](https://aadpa.com.au/adhd-medication-shortages/)

### Inferences
- The app's AU formulation catalogue for 2026 should cover:
  - MPH IR (Ritalin 10, Artige)
  - Ritalin LA
  - Concerta and OROS-type generics
  - dexamfetamine IR
  - Vyvanse capsules
  - atomoxetine, guanfacine and clonidine
  - an "other/imported" slot for Section 19A products and overseas users, with US formulations as optional entries
- Viloxazine's strong CYP1A2 inhibition matters for caffeine users, since caffeine is a CYP1A2 substrate. That relevance is my inference, not a label statement I verified.

### Gaps
- Search results suggest a TGA investigation of Vyvanse (titles "Update on Vyvanse investigation" and "Testing of Vyvanse capsules"), but the pages were not opened, so no claims are made about them.
- I could not check whether a new MPH generic or new strength was ARTG-registered in 2023–2026, because the TGA pages were inaccessible.

---

## Q3. Individual variability in onset and duration

### Takeaway
The biggest modifiers with numbers attached are:
- **Food:** timing shift that depends on the formulation (+1 h LDX; +2.5 h Adderall XR; variable for bead MPH; none for Concerta).
- **Urinary pH for amphetamines:** up to about 3.7-fold AUC difference, t½ 7–34 h.
- **CYP2D6 for atomoxetine:** 10-fold AUC.
- **Menstrual-cycle phase for amphetamine response:** follicular greater than luteal, tracking oestradiol up and progesterone down.
- **Acute tolerance:** subjective effect fades faster than plasma levels.
- **Age and weight:** higher clearance.

Sleep deprivation may be masked by stimulants. Caffeine, time of day and long-term tolerance lack good quantitative sources in this note.

### Cited Findings

**Food**
- Concerta: no PK or PD difference fasted, after a normal breakfast or after a high-fat breakfast — [Medsafe Concerta](https://www.medsafe.govt.nz/profs/datasheet/c/concertatab.pdf)
- Ritalin LA and Focalin XR: a high-fat meal lengthens the absorption lag, delays peaks by a variable amount and lowers peak 2 by about 25% — [FDA Ritalin LA](https://www.accessdata.fda.gov/drugsatfda_docs/label/2025/021284s050lbl.pdf); [FDA Focalin XR](https://www.accessdata.fda.gov/drugsatfda_docs/label/2017/021802s033lbl.pdf)
- Vyvanse: Tmax about 1 h later with food, same AUC and Cmax — [FDA Vyvanse](https://www.accessdata.fda.gov/drugsatfda_docs/label/2023/021977s050,208510s007lbl.pdf)
- Adderall XR: Tmax 2.5 h later (d) and 2.7 h later (l) with food — [FDA Adderall XR](https://www.accessdata.fda.gov/drugsatfda_docs/label/2015/021303s031lbl.pdf)
- Atomoxetine: Tmax 3 h later and Cmax 37% lower with a high-fat meal — [FDA Strattera](https://www.accessdata.fda.gov/drugsatfda_docs/label/2022/021411s050lbl.pdf)
- Guanfacine XR: Cmax +75% and AUC +40% with a high-fat meal — [FDA Intuniv](https://www.accessdata.fda.gov/drugsatfda_docs/label/2019/022037s018lbl.pdf)
- MPH IR: AUC +25% and Cmax +27% with a high-fat meal — [FDA Ritalin](https://www.accessdata.fda.gov/drugsatfda_docs/label/2019/010187s071s082,018029s041s051lbl.pdf)

**Gastric and urinary pH (amphetamines)**
- GI acidifying agents (ascorbic acid, fruit juices) lower amphetamine blood levels and efficacy. Alkalinising agents (sodium bicarbonate) raise levels and potentiate the effect — [FDA Adderall IR](https://www.accessdata.fda.gov/drugsatfda_docs/label/2017/011522s043lbl.pdf); [FDA Adderall XR](https://www.accessdata.fda.gov/drugsatfda_docs/label/2015/021303s031lbl.pdf)
- Vyvanse: acidifying agents lower blood levels and alkalinising agents raise them — [FDA Vyvanse](https://www.accessdata.fda.gov/drugsatfda_docs/label/2023/021977s050,208510s007lbl.pdf)
- AU dexamfetamine CMI flags vitamin C and fruit juices (acidifying) and alkalinising agents — [ACSQHC Aspen Dexamfetamine](https://www.safetyandquality.gov.au/medicine-finder/aspen-dexamfetamine)
- Urinary recovery of unchanged amphetamine is 1–75% depending on urinary pH — [FDA Adderall XR](https://www.accessdata.fda.gov/drugsatfda_docs/label/2015/021303s031lbl.pdf)
- PBPK model of amphetamine AUC0–∞ by urine type: alkaline 1,325, normal (pH 6.5) 692, acidic 361 µg·h/L (about 3.7-fold). Alkaline urine lowered urinary excretion by 91% (observed) and acidic urine raised it by 75% (observed) — [PBPK urine-pH study, PMC7250368](https://pmc.ncbi.nlm.nih.gov/articles/PMC7250368/)
- d-amphetamine t½ is 9–11 h normally and ranges from 7 h (acidic urine) to 34 h (alkaline urine) — [Wikipedia, Dextroamphetamine](https://en.wikipedia.org/wiki/Dextroamphetamine) (secondary source)

**CYP2D6 and other genetics**
- Atomoxetine in CYP2D6 poor metabolisers: about 10× AUC, about 5× Cmax, t½ 21.6 h versus 5.2 h. About 7% of Caucasians and about 2% of African Americans are poor metabolisers. Fluoxetine, paroxetine and quinidine raise levels in extensive metabolisers — [FDA Strattera](https://www.accessdata.fda.gov/drugsatfda_docs/label/2022/021411s050lbl.pdf)
- Amphetamine: CYP2D6 forms 4-hydroxy-amphetamine — [FDA Adderall XR](https://www.accessdata.fda.gov/drugsatfda_docs/label/2015/021303s031lbl.pdf). LDX PK variability is under 25% between subjects and under 8% within subjects — [FDA Vyvanse](https://www.accessdata.fda.gov/drugsatfda_docs/label/2023/021977s050,208510s007lbl.pdf)
- Methylphenidate is metabolised mainly by de-esterification to PPAA (about 80% of urinary radioactivity) — [FDA Concerta](https://www.accessdata.fda.gov/drugsatfda_docs/label/2023/021121s049lbl.pdf)
- Viloxazine: Cmax 21% and AUC 26% higher in CYP2D6 poor metabolisers — [FDA Qelbree](https://www.accessdata.fda.gov/drugsatfda_docs/label/2021/211964s000lbl.pdf)

**Age, weight and dose**
- OROS MPH CL/F is 58% higher in adolescents than children, partly explained by weight, and heavier people may have lower exposure — [FDA Concerta](https://www.accessdata.fda.gov/drugsatfda_docs/label/2023/021121s049lbl.pdf)
- MPH t½ is about 3.5 h in adults (1.3–7.7 h) and about 2.5 h in children (1.5–5.0 h) — [FDA Ritalin LA](https://www.accessdata.fda.gov/drugsatfda_docs/label/2025/021284s050lbl.pdf)
- LDX is dose-proportional from 50 to 250 mg in adults — [FDA Vyvanse](https://www.accessdata.fda.gov/drugsatfda_docs/label/2023/021977s050,208510s007lbl.pdf)
- Adderall IR PK roughly tripled from 10 to 30 mg — [FDA Adderall IR](https://www.accessdata.fda.gov/drugsatfda_docs/label/2017/011522s043lbl.pdf)

**Hormonal cycle**
- 13 healthy women (plus 7 men) given d-amphetamine 15 mg reported greater subjective stimulation in the follicular than the luteal phase. Within the follicular phase, stimulation correlated with oestradiol (r = +.55 to +.78) and inversely with progesterone (r = −.66 to −.68). Men reported more stimulation than women in the luteal phase — [White et al. 2002, PubMed 12213517](https://pubmed.ncbi.nlm.nih.gov/12213517/?dopt=Abstract)
- Justice & de Wit 1999 (n = 16) found a greater d-amphetamine effect in the follicular phase that correlated with oestrogen. Roberts 2018 linked lower oestrogen with higher progesterone or testosterone to more ADHD symptoms. PMS affected 45.4% of women with ADHD in Dorani 2021 — [review, Prog Neuropsychopharmacol Biol Psychiatry 2025](https://www.sciencedirect.com/science/article/pii/S0278584625000156)
- Case series (n = 9, Dutch clinic): premenstrual stimulant dose increases of 30–50% improved ADHD and mood symptoms in all nine women. There was no control group and participants had comorbidities — [de Jong et al. 2023, Frontiers in Psychiatry](https://www.frontiersin.org/journals/psychiatry/articles/10.3389/fpsyt.2023.1306194/full)

**Acute tolerance and hysteresis**
- A flat (constant) MPH regimen lost efficacy across the day, and the second of two closely spaced doses produced a smaller acute gain. A tolerance term was needed to model the data. This finding motivated ascending-profile formulations such as Concerta — [Swanson et al. 1999, Clin Pharmacol Ther (EPMC)](https://www.ebi.ac.uk/europepmc/webservices/rest/search?query=EXT_ID:10511066%20OR%20EXT_ID:16740846%20OR%20EXT_ID:23407278%20OR%20EXT_ID:17701403&format=json&resultType=core)
- LDX and d-amphetamine showed clockwise hysteresis (acute tolerance) for subjective and blood-pressure effects, which returned to baseline faster than plasma levels. Heart rate showed counter-clockwise hysteresis and stayed raised up to 24 h — [Frontiers in Pharmacology 2017](https://www.frontiersin.org/journals/pharmacology/articles/10.3389/fphar.2017.00617/full)

**Sleep deprivation**
- In 5,795 ABCD children plus 5 adults, stimulant brain signatures mimicked adequate sleep and erased the brain and cognitive signatures of sleep loss. The authors warn this masking does not remove the harm of chronic sleep deficit (Kay & Dosenbach, Cell, Dec 2025) — [WashU Medicine news](https://medicine.washu.edu/news/stimulant-adhd-medications-work-differently-than-thought/)

**Caffeine**
- A US clinical handout lists "restrict or eliminate caffeine" as a way to manage stimulant-related sleep problems — [UW handout](https://depts.washington.edu/dbpeds/13StimulantMedicationManage.pdf)

### Inferences
- Food at the dose time should be a logged covariate with formulation-specific priors:
  - LDX: onset about +1 h
  - Adderall XR: +2.5 h
  - Ritalin LA and Focalin XR: variable lag, possibly weaker second phase
  - Concerta: about 0
- For amphetamine users, logging "acidic drink or vitamin C near dose" and "antacid or PPI" is justified by the label wording but has no quantified effect size. Treat it as an exploratory covariate, not a fixed shift.
- An optional cycle-phase covariate is supported for amphetamine subjective effect (follicular greater than luteal). Evidence for methylphenidate is thin. Expect the effect to show up as weaker or shorter perceived windows in the late luteal phase for some users.
- Sleep deprivation may make a dose seem to "work" while masking deficits. The app could log sleep hours but should not infer that effect equals readiness.
- Because perceived effect has acute tolerance, the learned "felt" wear-off will usually come earlier than plasma decline, especially for amphetamines. This is correct for scheduling but means plasma t½ is a poor prior for offset.

### Gaps
- There are no quantitative sources here on caffeine–stimulant PK or PD interaction, or on time-of-day or chronotype effects on onset or duration. The planned searches could not run once the budget was exhausted.
- No source gives a numeric effect of acidic drinks on onset or duration at the dose time, for IR dexamfetamine or LDX.
- No verified source on long-term (chronic) tolerance prevalence: PMC9332474 was blocked.
- No PK data on whether PPIs or antacids change LDX absorption. The note that LDX is absorbed as an intact prodrug is unverified here.

---

## Q4. Wear-off and rebound: prevalence, timing, measurement

### Takeaway
Measured rebound in a controlled paediatric LDX trial was uncommon: 3.4% on LDX versus 9.7% on placebo, rated by parents at points through the day. Wear-off timing follows each formulation's duration (about 3–6 h for IR, 8–12 h for SR/LA, 12–14 h for OROS and LDX). Adult prevalence data were not found.

### Cited Findings
- In a 4-week RCT in children aged 6–12, parents rated symptoms at several points through the day. Rebound occurred in 7 of 207 on LDX (3.4%) and 7 on placebo (9.7%). Emotional lability scores were higher in LDX rebounders (4.2–9.0) than responders (1.3–1.6) — [López et al. 2017, J Atten Disord (EPMC)](https://www.ebi.ac.uk/europepmc/webservices/rest/search?query=EXT_ID:10511066%20OR%20EXT_ID:16740846%20OR%20EXT_ID:23407278%20OR%20EXT_ID:17701403&format=json&resultType=core)
- Clinical handout: "behavioural rebound" is a common side effect. Management options are a sustained-release stimulant or "add reduced dose in late afternoon" — [UW handout](https://depts.washington.edu/dbpeds/13StimulantMedicationManage.pdf)
- The advice to make sure MPH "works all day long" is framed as reducing rebound once MPH wears off — [Psych Scene Hub](https://psychscenehub.com/psychbytes/methylphenidate-mechanism-of-action-side-effects-and-dosing/)
- Acute tolerance means subjective effects decline before plasma levels do — [Frontiers in Pharmacology 2017](https://www.frontiersin.org/journals/pharmacology/articles/10.3389/fphar.2017.00617/full); [Swanson 1999 (EPMC)](https://www.ebi.ac.uk/europepmc/webservices/rest/search?query=EXT_ID:10511066%20OR%20EXT_ID:16740846%20OR%20EXT_ID:23407278%20OR%20EXT_ID:17701403&format=json&resultType=core)
- Laboratory classroom measures (SKAMP and PERMP at fixed hourly points) are the standard way to measure time course. PERMP (objective maths output) shows minimal placebo response — [Frontiers lab-school mini-review](https://www.frontiersin.org/journals/psychology/articles/10.3389/fpsyg.2019.01796/full)

### Inferences
- The app should keep "wear-off" (effect fading back to baseline) separate from "rebound" (symptoms worse than baseline, often irritability or emotional lability). An optional end-of-window mood or irritability check could capture rebound for the users who have it.
- Rebound is likely a minority phenomenon, so it should not be a default model component.

### Gaps
- No adult rebound prevalence or timing study was opened.
- The Cambridge abstract on a mid-afternoon MPH-IR add-on to Concerta XL could not be fetched (URL too long for the fetch proxy).

---

## Q5. Boosters (short-acting afternoon dose after a long-acting morning dose)

### Takeaway
A "booster" or "top-up" is a prescriber-authorised, usually smaller, IR dose later in the day to extend coverage after a long-acting morning dose wears off. Guideline support is thin: NICE makes no recommendation on combinations because of limited evidence. Label timing limits against insomnia are the main external rules:
- MPH IR: last dose before 6 p.m.
- Adderall IR: doses 4–6 h apart, no late-evening dosing
- AU dexamfetamine CMI: a missed dose no later than 6 h before bedtime

### Cited Findings
- Some formulations "may need second dose or regular methylphenidate dose in the afternoon", specifically Ritalin SR and Ritalin LA. For rebound: "add reduced dose in late afternoon". For sleep problems: "reduce or eliminate afternoon dose; move dosing regimen to earlier time" — [UW handout](https://depts.washington.edu/dbpeds/13StimulantMedicationManage.pdf)
- UK commissioning guidance: "NICE has no recommendations with regards to the combination of ADHD drugs due to a lack of evidence base." It mentions "a PRN extra dose of dexamfetamine for specific events" as an alternative to combination therapy — [BSW Together guidance](https://bswtogether.org.uk/medicines/documents/guidance-on-adhd-medication-requests-for-combination-drugs-for-adults-with-adhd/)
- MPH IR: last dose before 6 p.m. — [FDA Ritalin](https://www.accessdata.fda.gov/drugsatfda_docs/label/2019/010187s071s082,018029s041s051lbl.pdf)
- Amphetamine IR: first dose on waking, then 1–2 more at 4–6 h intervals, avoiding late evening — [FDA Adderall IR](https://www.accessdata.fda.gov/drugsatfda_docs/label/2017/011522s043lbl.pdf)
- AU dexamfetamine CMI: a missed dose may be taken "not later than 6 hours before bedtime" — [ACSQHC Aspen Dexamfetamine](https://www.safetyandquality.gov.au/medicine-finder/aspen-dexamfetamine)
- Onset and duration of the IR booster itself: MPH IR onset 20–60 min, peak about 1–2 h, duration 2–4 h — [Psych Scene Hub MPH](https://psychscenehub.com/psychbytes/methylphenidate-mechanism-of-action-side-effects-and-dosing/). Dexamfetamine IR onset 20–60 min, duration 3–6 h — [Psych Scene Hub dex/LDX](https://psychscenehub.com/psychbytes/dexamphetamine-and-lisdexamfetamine-mechanism-of-action-side-effects-and-dosing/)
- For Ritalin LA in some children, "an additional dose at about 8.00 p.m. may help" evening sleeplessness. This is a clinician-directed edge case and contrary to the general label advice — [Psych Scene Hub MPH](https://psychscenehub.com/psychbytes/methylphenidate-mechanism-of-action-side-effects-and-dosing/)
- Acute tolerance: the second of two closely spaced MPH doses had a reduced acute effect — [Swanson 1999 (EPMC)](https://www.ebi.ac.uk/europepmc/webservices/rest/search?query=EXT_ID:10511066%20OR%20EXT_ID:16740846%20OR%20EXT_ID:23407278%20OR%20EXT_ID:17701403&format=json&resultType=core)
- NSW continuation-prescriber GPs may switch between formulations of the same medicine (for example MPH IR and MR) but not between different medicines — [ACI NSW FAQ](https://aci.health.nsw.gov.au/projects/adhd-in-general-practice/clinicians/frequently-asked-questions)

### Inferences
- Model the booster as its own IR curve (onset 20–60 min, duration 2–4 h for MPH, 3–6 h for dex) added to the tail of the long-acting curve. Because of acute tolerance, the booster's perceived gain may be smaller than the same dose taken alone in the morning, so learn the booster curve separately from any morning IR curve.
- For scheduling, the app should only use booster time and dose already entered as prescriber-authorised. It can show the user's own entered sleep cut-off, or the PI rule for that product, as a hard boundary. It must never suggest timing.

### Gaps
- No AADPA guideline text on boosters was opened; the guideline URL was not retrieved before the search budget ran out.
- No controlled study quantifying adult booster onset or overlap with LA tails was opened.

---

## Q6. Laboratory classroom and workplace effect-time curves (SKAMP, PERMP)

### Takeaway
The adult workplace data give LDX a significant effect from 2 h to 14 h, the last time tested. In children, LDX is significant from about 1.5–2 h to 12–13 h, and Concerta from 1.5 h to 12 h. Head-to-head, the ratio of immediate to delayed release determines when in the day a product is stronger. COMACS showed that a higher IR fraction wins in the morning and Concerta's 22:78 ascending profile wins at 12 h.

### Cited Findings
- LDX in adults, simulated workplace study (n = 127 randomised, 103 completed, 30–70 mg):
  - PERMP measured pre-dose and at 2, 4, 8, 10, 12 and 14 h
  - significant from the first point (2 h) to the last (14 h), P ≤ .0017 at each
  - sustained plateau rather than a sharp peak
  - LS-mean PERMP difference 23.4 (95% CI 15.6–31.2)
  - Source: [Wigal et al. 2010, Behav Brain Funct](https://link.springer.com/article/10.1186/1744-9081-6-34)
- LDX paediatric classroom study (n = 129): effect significant from 2 to 12 h in one analysis; time points 1.5, 2.5, 5, 7.5, 10, 12 and 13 h in another — [FDA Vyvanse](https://www.accessdata.fda.gov/drugsatfda_docs/label/2023/021977s050,208510s007lbl.pdf)
- Concerta: SKAMP onset about 1.5 h, lasting through 12 h (paediatric) — [Medsafe Concerta](https://www.medsafe.govt.nz/profs/datasheet/c/concertatab.pdf); [FDA Concerta](https://www.accessdata.fda.gov/drugsatfda_docs/label/2023/021121s049lbl.pdf)
- COMACS (crossover of Metadate CD, Concerta and placebo; n = 184 screened, 157 completed; SKAMP at 0, 1.5, 3, 4.5, 6, 7.5 and 12 h; dose pairs 20/18, 40/36, 60/54 mg):
  - Metadate CD (about 30% IR) was superior at 1.5–4.5 h
  - the two were equal at 6–7.5 h
  - Concerta was superior at 12 h
  - Source: [COMACS secondary analysis, BMC Psychiatry 2004](https://link.springer.com/article/10.1186/1471-244X-4-28)
- Across head-to-head MPH studies, higher-IR products (for example Equasym XL 30:70) give higher plasma MPH and more effect early (0–4 h), and Concerta gives more at 8–12 h. "No formulation is clearly superior" — [PMC3852277](https://pmc.ncbi.nlm.nih.gov/articles/PMC3852277/)
- Focalin XR: effect at all time points through 12 h in paediatric classroom studies, with adult superiority at several time points — [FDA Focalin XR](https://www.accessdata.fda.gov/drugsatfda_docs/label/2017/021802s033lbl.pdf)
- Other lab-school windows:
  - Quillivant XR (MPH ER suspension): significant at 0.75, 2, 8, 10 and 12 h
  - Aptensio: 1–12 h
  - multilayer-release MPH in adults (Wigal 2016): 1–16 h
  - SHP465 (Mydayis) adult workplace study (Wigal 2018): results not detailed in the source
  - SKAMP shows slightly larger placebo effects than PERMP
  - Source: [Frontiers lab-school mini-review 2019](https://www.frontiersin.org/journals/psychology/articles/10.3389/fpsyg.2019.01796/full)
- Healthy adults, LDX 100 mg versus d-amphetamine 40 mg: LDX lag 0.6 ± 0.6 h longer; Tmax 4.6 versus 3.3 h; same peak subjective ratings; clockwise hysteresis for subjective effect — [Frontiers in Pharmacology 2017](https://www.frontiersin.org/journals/pharmacology/articles/10.3389/fphar.2017.00617/full)

### Inferences
- The "last significant time point" in these studies is often simply the last time measured (14 h for LDX adults, 12 h for Concerta). True duration may be longer for some people and is right-censored in the priors.
- Group-mean onset (1.5–2 h for long-acting products) is the first time point tested. Individual onset is probably earlier for bead products (IR fraction) and could be later with food.

### Gaps
- Adult laboratory data for Concerta, Ritalin LA and dexamfetamine IR specifically were not retrieved.
- The Mydayis adult duration figure was not verified.

---

## Q7. Prior work on personalised / N-of-1 tracking, EMA and wearables

### Takeaway
Australia has a precedent for N-of-1 stimulant trials. Nikles et al. (UQ) ran them as a clinical service, and only about a third of completed trials showed a clear drug-over-placebo response. Wearables reliably pick up a stimulant heart-rate increase at the level of weeks (+5.4 bpm), but heart rate stays raised up to 24 h after amphetamine dosing. That makes HR a weak marker of when the effect switches off within the day.

### Cited Findings
- Nikles et al. 2006 (Pediatrics), a national service in which 45 Australian doctors requested 108 N-of-1 trials and 86 were completed:
  - 29 children responded better to stimulant than placebo
  - 19 of 25 drug-versus-placebo responders stayed on the same stimulant
  - 13 of 24 non-responders stopped or switched
  - management changed for 28 of 64 children
  - Source: [EPMC](https://www.ebi.ac.uk/europepmc/webservices/rest/search?query=EXT_ID:10511066%20OR%20EXT_ID:16740846%20OR%20EXT_ID:23407278%20OR%20EXT_ID:17701403&format=json&resultType=core)
- Nikles et al. 2007 (Eur J Clin Pharmacol), n = 76:
  - management changed for 46%, 48% and 51% at 3, 6 and 12 months
  - 57% of responders versus 37% of non-responders were on the same stimulant at 12 months
  - congruence with trial results fell from 69% at 3 months to 60% at 12 months
  - Source: [EPMC](https://www.ebi.ac.uk/europepmc/webservices/rest/search?query=EXT_ID:10511066%20OR%20EXT_ID:16740846%20OR%20EXT_ID:23407278%20OR%20EXT_ID:17701403&format=json&resultType=core)
- Remote monitoring of 176 adults starting ADHD medication (UK and Spain; EmbracePlus wristband plus 4-weekly smartphone assessments; 91.3% stimulants):
  - HR +5.43 bpm on initiation, then +1.31 bpm per 4-week period
  - sleep onset delayed about 10 min per time point
  - activity +99 steps/h
  - fewer rest-activity transitions
  - expectancy effects are a caveat
  - Source: [Translational Psychiatry 2025](https://www.nature.com/articles/s41398-025-03764-y)
- Heart rate after LDX or d-amphetamine rose slowly, showed counter-clockwise hysteresis (lag without tolerance) and stayed high up to 24 h. Diastolic BP returned to baseline faster than plasma levels — [Frontiers in Pharmacology 2017](https://www.frontiersin.org/journals/pharmacology/articles/10.3389/fphar.2017.00617/full)
- Wrist-worn HR accuracy (n = 60, ECG reference): Apple Watch had the lowest error (2.0%). Median error was 1.8% for cycling and 5.5% for walking. Errors rose in males, at higher BMI, with darker skin and during walking. Energy-expenditure estimates were poor on every device (27–93% error) — [Shcherbina et al. 2017, J Pers Med](https://www.mdpi.com/2075-4426/7/2/3)
- In a paediatric study with a Garmin smartwatch, stimulant use was associated with higher average and resting HR. Dose details were unavailable, which limits inference — [ScienceDirect 2026, PCIT smartwatch study](https://www.sciencedirect.com/science/article/pii/S2949732926000803)
- A meta-analysis of MPH effects on HRV in children (Gianini et al. 2026) exists, but only its title and DOI were seen: [doi:10.1177/10783903261456725](https://doi.org/10.1177/10783903261456725) (not opened)

### Inferences
- Passive HR could serve as an adherence or "dose taken" weak signal (a rise within about 1–3 h). It should not be the offset detector, because amphetamine HR stays raised long after the felt effect fades. For methylphenidate (t½ about 3.5 h), HR may track more closely, but that is unverified.
- Movement (steps, fidgeting) and phone-use proxies changed in the remote-monitoring study, but the analysis was over weeks, not hours. Validation within a day is an open research question.
- The Nikles service is a useful Australian design precedent: structured, blinded, repeated crossover periods beat unstructured impressions. The app's learning could borrow the idea of repeated same-condition days to separate drug effect from day-to-day noise.

### Gaps
- No published app that learns individual intraday stimulant effect curves was found in the sources opened.
- No study validating Apple Watch HR or HRV as a within-day marker of stimulant onset or offset was found.
- The HRV meta-analysis was not opened.

---

## Q8. Validity of subjective "is it working now?" self-report

### Takeaway
No study directly validating adults' self-reported onset or offset times against objective measures was found. Indirect evidence says self-report is useful but biased in two ways. Expectancy and placebo effects inflate reports, and perceived stimulant effects show acute tolerance, fading faster than plasma levels. Pairing self-report with a brief objective probe is advisable.

### Cited Findings
- Observer-rated SKAMP shows slightly larger placebo effects than objective PERMP output. "Both SKAMP and PERMP measures of the placebo group always move in the opposite direction from the medicated group" — [Frontiers lab-school mini-review](https://www.frontiersin.org/journals/psychology/articles/10.3389/fpsyg.2019.01796/full)
- In the remote-monitoring study, expectancy effects from waiting-list recruitment "may inflate self-reported improvements" — [Translational Psychiatry 2025](https://www.nature.com/articles/s41398-025-03764-y)
- Subjective drug effects (liking, stimulation) after LDX or d-amphetamine show clockwise hysteresis (acute tolerance) and decline before plasma levels — [Frontiers in Pharmacology 2017](https://www.frontiersin.org/journals/pharmacology/articles/10.3389/fphar.2017.00617/full)
- Stimulants can mask the signatures of sleep deprivation — [WashU / Cell 2025](https://medicine.washu.edu/news/stimulant-adhd-medications-work-differently-than-thought/)
- In N-of-1 trials, only about a third of completed trials (29 of 86) showed stimulant better than placebo, and 12-month adherence to trial conclusions was 60%. Unblinded impressions and blinded data often disagree — [Nikles 2006/2007 (EPMC)](https://www.ebi.ac.uk/europepmc/webservices/rest/search?query=EXT_ID:10511066%20OR%20EXT_ID:16740846%20OR%20EXT_ID:23407278%20OR%20EXT_ID:17701403&format=json&resultType=core)

### Inferences
- Use short, repeated check-ins (for example "focus now 1–5") at jittered times rather than asking users to recall onset retrospectively.
- Optionally add a 30–60 s objective task (reaction time, or PERMP-like arithmetic). PERMP is the lab analogue with minimal placebo response.
- Expect self-reported offset to lead plasma decline. That is acceptable, because the app schedules for felt and functional effect.

### Gaps
- No direct validation study (self-reported timing versus SKAMP, PERMP or CPT) in adults was found in the sources opened.

---

## Q9. Missed-dose guidance in product information

### Takeaway
PI and CMI wording varies by product and should be stored as data per product, never generated.
- **Vyvanse (AU CMI):** skip and take the next morning; do not double; avoid afternoon or evening.
- **AU dexamfetamine CMI:** take when remembered but not later than 6 h before bedtime; skip if close to the next dose.
- **Atomoxetine:** take as soon as possible, but do not exceed the total daily dose in 24 h.
- **Guanfacine XR:** if 2 or more consecutive doses are missed, the prescriber may re-titrate.
- **Most stimulant labels:** avoid late-day dosing because of insomnia.

### Cited Findings
- Vyvanse (AU CMI): "If you miss a dose, take it the next morning as usual… Avoid taking VYVANSE in the afternoon or evening as it can cause an inability to sleep"; do not double up — [ACSQHC Vyvanse](https://www.safetyandquality.gov.au/medicine-finder/vyvanse)
- Aspen Dexamfetamine (AU CMI): "take the missed dose as soon as you remember, but not later than 6 hours before bedtime. If it is almost time for your next dose, skip the dose you missed" — [ACSQHC Aspen Dexamfetamine](https://www.safetyandquality.gov.au/medicine-finder/aspen-dexamfetamine)
- Strattera: "take it as soon as possible, but should not take more than the prescribed total daily amount… in any 24-hour period" — [FDA Strattera](https://www.accessdata.fda.gov/drugsatfda_docs/label/2022/021411s050lbl.pdf)
- Intuniv: "If two or more missed consecutive doses occur, consider titration based on patient tolerability". Do not stop abruptly (rebound hypertension); taper by no more than 1 mg every 3–7 days — [FDA Intuniv](https://www.accessdata.fda.gov/drugsatfda_docs/label/2019/022037s018lbl.pdf)
- Ritalin/Ritalin-SR: no explicit missed-dose text; last dose before 6 p.m. — [FDA Ritalin](https://www.accessdata.fda.gov/drugsatfda_docs/label/2019/010187s071s082,018029s041s051lbl.pdf)
- Ritalin LA and Focalin XR US labels: no explicit missed-dose guidance; morning dosing — [FDA Ritalin LA](https://www.accessdata.fda.gov/drugsatfda_docs/label/2025/021284s050lbl.pdf); [FDA Focalin XR](https://www.accessdata.fda.gov/drugsatfda_docs/label/2017/021802s033lbl.pdf)
- Vyvanse US: "avoid afternoon doses because of the potential for insomnia" — [FDA Vyvanse](https://www.accessdata.fda.gov/drugsatfda_docs/label/2023/021977s050,208510s007lbl.pdf)
- Adderall IR: avoid late-evening doses — [FDA Adderall IR](https://www.accessdata.fda.gov/drugsatfda_docs/label/2017/011522s043lbl.pdf)
- Adderall XR: morning dosing to prevent insomnia — [FDA Adderall XR](https://www.accessdata.fda.gov/drugsatfda_docs/label/2015/021303s031lbl.pdf)
- Concerta: once daily in the morning — [Medsafe Concerta](https://www.medsafe.govt.nz/profs/datasheet/c/concertatab.pdf)
- Qelbree label: "talk to your healthcare provider" — [FDA Qelbree](https://www.accessdata.fda.gov/drugsatfda_docs/label/2021/211964s000lbl.pdf)

### Inferences
- If a long-acting stimulant is logged late, the app could show a projected window end relative to the user's bedtime as information only. It must not prompt the user to take or skip.

### Gaps
- The AU CMI texts for Concerta, Ritalin LA and Ritalin 10 could not be retrieved (ACSQHC pages blocked).

---

## Q10. Australian specifics: PBS, S8 prescribing (NSW), SafeScript, shortages, generic switches

### Takeaway
Current PBS adult coverage:
- Vyvanse: adults, including diagnosis in adulthood (extended 1 Feb, after the PBAC March 2020 recommendation)
- Ritalin LA: adults, once IR response is shown
- IR MPH and dexamfetamine: no age limit
- Concerta: ages 6–18 diagnosed in childhood only

NSW prescribing changes:
- Specialists have held a class authority since 13 Nov 2023.
- Trained GPs have been able to act as "continuation prescribers" since 1 Sep 2025.
- GP diagnosis and initiation ("endorsed prescribers") has training in 2026, with services from early 2027.

The 2023–2025 methylphenidate shortages (Concerta, Teva XR, Ritalin IR, Artige) had "largely resolved" by June 2026. In the US, FDA found some Concerta generics released drug more slowly at 7–12 h.

### Cited Findings

**PBS**
- PBAC recommended extending lisdexamfetamine to people diagnosed after 18 in March 2020, and three new strengths in July 2019 — [ADHD Australia](https://www.adhdaustralia.org.au/success-in-changing-the-pbs-for-adhd-medications/)
- Listing took effect "On 1 February". Co-payment $41.30, or $6.60 concessional. About 20,000 patients were expected to benefit — [Health Minister media release](https://www.health.gov.au/ministers/the-hon-greg-hunt-mp/media/greater-access-to-life-changing-medicine-for-australians-with-adhd)
- PBS status for adults as of Feb 2026:
  - Ritalin/Artige IR and dexamfetamine IR: no age restriction
  - Ritalin LA: adults with IR response shown first
  - Concerta: ages 6–18 diagnosed in childhood only
  - Vyvanse: adults diagnosed in childhood or retrospectively
  - atomoxetine: ages 6–18 with stimulant contraindication, specialist-prescribed
  - Source: [Australian Prescriber 2026](https://australianprescriber.tg.org.au/articles/pharmacological-management-of-attention-deficit-hyperactivity-disorder-in-adults.html)

**NSW S8 authority**
- An authority is required for dexamfetamine, lisdexamfetamine and methylphenidate. Since 13 Nov 2023, psychiatrists, paediatricians and neurologists have held a class authority up to dexamfetamine 50 mg, LDX 70 mg and MPH 108 mg per day. Continuation-prescriber GPs from 1 Sep 2025. Page updated Feb 2026 — [AADPA regulations](https://aadpa.com.au/adhd-stimulant-prescribing-regulations-in-australia-new-zealand/)
- 3 July 2025 announcement: GP resupply without a specialist arrangement from September 2025, with training for GP diagnosis and initiation to start "by end of 2025" — [NSW Health news](https://www.health.nsw.gov.au/news/Pages/20250703_00.aspx)
- Current ACI timeline:
  - continuation prescribers (ages 6+, stable dose, prior specialist diagnosis; minor dose changes; can switch formulations of the same medicine) from 1 Sep 2025
  - first endorsed-prescriber cohort trained March 2026, second round expected Nov 2026
  - assessment services from early 2027, with up to 2,500 funded assessments
  - SafeScript NSW review mandatory for these prescribers
  - Source: [ACI FAQ](https://aci.health.nsw.gov.au/projects/adhd-in-general-practice/clinicians/frequently-asked-questions)
- By 24 Nov 2025 there were 560 GP general authorities, 2,953 people prescribed and 6,373 scripts filled, with 40% of practices outside metropolitan Sydney — [ACI reforms update PDF](https://aci.health.nsw.gov.au/__data/assets/pdf_file/0018/1035621/ADHD-reforms-update-2025-11-24.pdf)

**SafeScript NSW**
- Real-time prescription monitoring. Rolled out Nov 2021 (HNE/CC), Mar 2022 (NSLHD/NBM) and May 2022 (statewide). Administration moved to the Ministry's Pharmaceutical Services Unit in June 2024 — [eHealth NSW](https://www.ehealth.nsw.gov.au/solutions/clinical-care/electronic-medical-records/safescript)
- Monitored medicines include psychostimulants (Poisons and Therapeutic Goods Regulation 2008, Appendix E). SafeScript was not mandatory in NSW as of May 2023, whereas Victoria's SafeScript has been mandatory since April 2020 — [Hall & Wilcox, May 2023](https://hallandwilcox.com.au/thinking/safescript-nsw-a-push-for-prescription-oversight-of-monitored-medications/)
- It is mandatory for GP continuation prescribers under the reform — [ACI FAQ](https://aci.health.nsw.gov.au/projects/adhd-in-general-practice/clinicians/frequently-asked-questions)

**Shortages 2023–2026**
- Concerta, Teva XR, Ritalin IR and Artige were in shortage, expected to last to Dec 2025 (as of June 2025). Section 19A Swiss Concerta through Medsurge cost more than $200 per 30 tablets with about 2-month delays — [AADPA shortages, updated 18 June 2025](https://aadpa.com.au/adhd-medication-shortages/)
- August 2026 update:
  - TGA's June 2026 assessment found MR methylphenidate shortages "largely resolved", though supply of particular strengths and locations is patchy
  - most Section 19A approvals lapsed on 31 Jan 2026; Ritalin LA's ran to 30 Apr 2026
  - Source: [ADHD Mums shortage tracker, 19 Aug 2026](https://adhdmums.com.au/adhd-medication-shortage/)
- A separate page says Concerta is under a shortage notification to the end of 2026 and "Rubifen LA" to September 2026. This partly conflicts with "largely resolved" — [ADHD Mums, not-available page](https://adhdmums.com.au/adhd-medications-not-available-australia/)

**Generic switches and effect curves**
- FDA (Nov 2014) changed Mallinckrodt and Kudco generic Concerta from AB to BX, because "in some individuals… [they] may deliver drug in the body at a slower rate during the 7- to 12-hour range". In Oct–Nov 2016 FDA proposed withdrawing approval after the sponsors neither withdrew nor supplied new bioequivalence data — [FDA](https://www.fda.gov/drugs/drug-safety-and-availability/methylphenidate-hydrochloride-extended-release-tablets-generic-concerta-made-mallinckrodt-and-kudco)
- AADPA's prescribing guide includes a dose-equivalence table for switching MPH formulations — [AADPA shortages](https://aadpa.com.au/adhd-medication-shortages/)

### Inferences
- Shortage-driven switches (Concerta to Teva XR or a Section 19A product; OROS to Ritalin LA) change curve shape. The app should record the exact product and brand at each dose and treat a switch as a new formulation with its own prior, borrowing partially from the previous product. It should flag "curve re-learning" for about 1–2 weeks.
- The US generic-OROS precedent shows that equal AUC and Cmax can still hide late-day (7–12 h) differences. A brand field and late-afternoon check-ins are the most useful signals after a switch.
- The PBS adult listing year for Vyvanse is very probably 2021 (PBAC March 2020 plus 6–9 months to implement), but the release excerpt did not show the year.

### Gaps
- The TGA shortage database and TGA shortage pages could not be opened directly (robots/timeouts), so shortage status relies on AADPA and ADHD Mums.
- No PBAC or PBS changes for ADHD medicines in 2025–2026 (for example Concerta for adults, guanfacine for adults) were verified.
- Whether AU generic OROS/XR MPH products (Methylphenidate-Teva XR etc.) match Concerta's release profile over 7–12 h was not found. No TGA equivalent of the FDA action was found.
- No date when SafeScript NSW checks became mandatory for all prescribers (if they have) was found.

---

## Priors for the app's model (label-derived starting estimates, to be replaced by the user's own data)

### Takeaway
The priors below are derived from the label and study figures cited above. Times are hours after the logged dose, for adults, fasted or with a light meal unless stated. They are deliberately wide and should be treated as weakly informative, updated quickly by the user's own check-ins. They are not clinical guidance, and the app should show them as "typical for this formulation" only until personal data overrides them.

### Cited Findings (basis for each row; see Q1–Q6 for the full citations)

| Formulation (AU) | Default onset (first noticeable) | Plateau start | Wear-off start | Full wear-off | Main modifiers | Basis |
|---|---|---|---|---|---|---|
| MPH IR (Ritalin 10, Artige) | 0.3–1 h | ~1–1.5 h | ~2.5–3 h | 3–5 h | High-fat meal (↑ exposure ~25%); acute tolerance on repeat doses; weight/age (clearance) | [FDA Ritalin](https://www.accessdata.fda.gov/drugsatfda_docs/label/2019/010187s071s082,018029s041s051lbl.pdf); [PSH](https://psychscenehub.com/psychbytes/methylphenidate-mechanism-of-action-side-effects-and-dosing/); [UW](https://depts.washington.edu/dbpeds/13StimulantMedicationManage.pdf) |
| MPH IR as booster (after LA) | 0.3–1 h | ~1–1.5 h | ~2.5 h | 3–4 h (overlaps LA tail) | Acute tolerance may blunt it; label last-dose rules (before 6 p.m.) | [FDA Ritalin](https://www.accessdata.fda.gov/drugsatfda_docs/label/2019/010187s071s082,018029s041s051lbl.pdf); [Swanson 1999](https://www.ebi.ac.uk/europepmc/webservices/rest/search?query=EXT_ID:10511066%20OR%20EXT_ID:16740846%20OR%20EXT_ID:23407278%20OR%20EXT_ID:17701403&format=json&resultType=core) |
| Ritalin LA (50:50 beads) | 0.5–1.5 h (longer after high-fat meal) | ~1.5–2 h | Possible dip ~4–4.5 h; main wear-off ~6–7 h | 7–9 h | High-fat meal: variable lag, second peak −25%; alcohol dose-dumping | [FDA Ritalin LA](https://www.accessdata.fda.gov/drugsatfda_docs/label/2025/021284s050lbl.pdf); [PSH](https://psychscenehub.com/psychbytes/methylphenidate-mechanism-of-action-side-effects-and-dosing/) |
| Concerta / OROS MPH (incl. generics as separate product) | 1–2 h (SKAMP 1.5 h) | ~2 h (moderate), strengthening toward 6–8 h | ~10–11 h | 12–14 h | Food ≈ none; weight (↑ clearance); product/brand switch (generic late-day release); acute tolerance | [FDA Concerta](https://www.accessdata.fda.gov/drugsatfda_docs/label/2023/021121s049lbl.pdf); [Medsafe](https://www.medsafe.govt.nz/profs/datasheet/c/concertatab.pdf); [COMACS](https://link.springer.com/article/10.1186/1471-244X-4-28); [FDA generics](https://www.fda.gov/drugs/drug-safety-and-availability/methylphenidate-hydrochloride-extended-release-tablets-generic-concerta-made-mallinckrodt-and-kudco) |
| Dexamfetamine IR (Aspen) | 0.3–1 h | ~1–1.5 h | ~3.5–4 h | 4–6 h | Urinary/GI pH (vitamin C, fruit juice ↓; antacids/bicarbonate ↑); cycle phase (luteal ↓ subjective effect); acute tolerance | [PSH](https://psychscenehub.com/psychbytes/dexamphetamine-and-lisdexamfetamine-mechanism-of-action-side-effects-and-dosing/); [Adderall IR label](https://www.accessdata.fda.gov/drugsatfda_docs/label/2017/011522s043lbl.pdf); [ACSQHC](https://www.safetyandquality.gov.au/medicine-finder/aspen-dexamfetamine); [White 2002](https://pubmed.ncbi.nlm.nih.gov/12213517/?dopt=Abstract) |
| Lisdexamfetamine (Vyvanse caps) | 1–2 h fasted; +~1 h with food | ~3–4 h | ~10–12 h | 12–15 h (adult data significant to 14 h, the last point tested) | Food (+1 h); urinary pH; cycle phase; sleep debt (masking); acute tolerance for subjective effect | [FDA Vyvanse](https://www.accessdata.fda.gov/drugsatfda_docs/label/2023/021977s050,208510s007lbl.pdf); [Wigal 2010](https://link.springer.com/article/10.1186/1744-9081-6-34); [Frontiers 2017](https://www.frontiersin.org/journals/pharmacology/articles/10.3389/fphar.2017.00617/full) |
| Focalin XR (US) | 0.5–1.5 h | ~1.5 h | ~10–11 h (dip possible ~4 h) | 12+ h | High-fat meal: delayed peak 1, peak 2 −25% | [FDA Focalin XR](https://www.accessdata.fda.gov/drugsatfda_docs/label/2017/021802s033lbl.pdf) |
| Adderall XR (US) | ~1–2 h fasted; +2.5 h with food | ~3–4 h | ~9–10 h | 10–12 h | Food (+2.5 h Tmax); GI/urinary pH; cycle phase | [FDA Adderall XR](https://www.accessdata.fda.gov/drugsatfda_docs/label/2015/021303s031lbl.pdf); [Wikipedia](https://en.wikipedia.org/wiki/Dextroamphetamine) |
| Atomoxetine / guanfacine XR / viloxazine / centanafadine* / clonidine (maintenance) | No intraday window; therapeutic onset over weeks (atomoxetine 2–3 months) | n/a | n/a | n/a | CYP2D6 (atomoxetine 10× AUC in PMs); high-fat meal (guanfacine +75% Cmax); CYP3A4 (guanfacine); CYP1A2 (viloxazine) | [FDA Strattera](https://www.accessdata.fda.gov/drugsatfda_docs/label/2022/021411s050lbl.pdf); [FDA Intuniv](https://www.accessdata.fda.gov/drugsatfda_docs/label/2019/022037s018lbl.pdf); [FDA Qelbree](https://www.accessdata.fda.gov/drugsatfda_docs/label/2021/211964s000lbl.pdf); [Aust Prescr](https://australianprescriber.tg.org.au/articles/pharmacological-management-of-attention-deficit-hyperactivity-disorder-in-adults.html) |

\*Centanafadine (Tmax 5 h, t½ 5.2 h, once-daily ER) may have some intraday variation, but no duration-of-effect data were found. Treat it as unknown — [PEF](https://psychiatryeducationforum.com/centanafadine/).

### Inferences
**How the priors were derived**
- Onset is taken from the first lab time point or reported onset, extended earlier for IR-bead fractions.
- Plateau start is the rough time at which the curve nears effect-equivalent levels: about Tmax for IR products, the first peak for bead products, and about 3–4 h for LDX.
- Wear-off start comes from the reported duration minus about 1–2 h.
- Full wear-off is the reported duration plus a right-censoring allowance (the lab "last significant point" is often the last point measured).

**Model structure implied by the evidence**
- Use a per-product parametric effect curve: lag, rise, one or two humps, plateau, decay.
- Use product-specific food shifts: LDX +1 h; Adderall XR +2.5 h; Ritalin LA and Focalin XR variable with a weaker second phase; Concerta about 0.
- Add an optional amphetamine urinary/GI pH covariate (unquantified at the dose time).
- Add an optional menstrual-phase covariate (strongest evidence for amphetamine).
- Include a sleep-debt flag that down-weights self-reported effect as a readiness signal.
- Treat each brand or generic switch as a new product.
- Model the booster as an additive IR curve that is learned separately (acute tolerance).
- Use HR only as a weak onset or adherence signal; it is not a good offset signal for amphetamines.

**Update strategy**
- Priors are wide and variability within a person is expected. The LDX label reports under 8% intra-subject PK variability, which is much smaller than between people (under 25%). That suggests personal curves become stable once they have been learned, while day-to-day PD modifiers (food, sleep, cycle) remain.

### Gaps
- There are no adult-specific onset or duration studies for Ritalin LA, Concerta or dexamfetamine IR among the opened sources, so those rows lean on paediatric or PK data plus secondary summaries.
- Effect sizes for caffeine, time of day and chronic tolerance are unquantified.
- Jornay PM (evening-dosed DR/ER MPH, US) was not characterised, so the model should not assume morning dosing for all long-acting products.
