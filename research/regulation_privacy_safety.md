# Regulation, privacy, safety and App Store constraints for an ADHD medication-aware planner (iPhone/Apple Watch, AU → US/UK/NZ/EU)

Scope note: research current to 28 September 2026. This is not legal advice. Items marked **[LAWYER]** need a lawyer or regulatory consultant (TGA/FDA/MHRA/EU MDR and privacy) to confirm before launch. Source-access limits in this pass: most tga.gov.au pages refused automated fetching (robots.txt failures), so exact TGA exclusion wording for the "health self-management" and "digital mental health tool" exclusions comes from secondary sources. Europe PMC and one FDA stimulant-safety page were rate-limited (HTTP 429) and could not be read. The session's web-search budget ran out partway through, so later sources came from direct fetches of known URLs.

Product features assessed: (a) dose and booster logging; (b) learning a personal "effect window" (onset and wear-off) from check-ins; (c) scheduling tasks and calendar events around that window; (d) Apple Health inputs (sleep, workouts, heart rate); (e) cloud LLMs (OpenAI, Anthropic, Google) for natural language and screenshot parsing.

---

## 1. Australia (TGA): where the SaMD line sits, which exclusions apply, and whether learning or scheduling around a medication effect window makes the app a medical device

### Takeaway
The TGA regulates by intended purpose, and claims set that purpose. It does not regulate "health and lifestyle apps", and it excludes consumer self-management software that gives no "specific treatment or treatment suggestions". Dose logging plus scheduling framed around the user's own focus pattern is very likely outside regulation. Any output that tells the user when to take a dose or booster, or that predicts wear-off in order to guide treatment, crosses into "treatment suggestion" territory and probably makes the app a medical device. The digital mental health tool exclusion is itself under active review (2025–2026), so the app should not rely on it.

### Cited Findings
- TGA software guidance (v. last updated 14 Aug 2025): "Many mobile apps are simply sources of information, or tools to manage a healthy lifestyle. We do not regulate health and lifestyle apps or other software that does not meet the definition of a medical device." Software is a medical device when it meets s41BD of the *Therapeutic Goods Act 1989*, e.g. it is intended to "inform, drive or replace clinical decisions" or "directly provide therapy". — [TGA "Understanding regulation of software-based medical devices" (PDF mirror, generated 27 Aug 2025)](https://cmcmedicaldevices.com/wp-content/uploads/2025/08/understanding-regulation-of-software-based-medical-devices-tga-27082025.pdf)
- The same guidance shows that presentation does not settle the question. "Baby movement apps" are medical devices because they are "intended to prevent foetal harm through monitoring foetal movement" even though they are "presented as diaries". — [same TGA PDF](https://cmcmedicaldevices.com/wp-content/uploads/2025/08/understanding-regulation-of-software-based-medical-devices-tga-27082025.pdf)
- LLM position (TGA): "When LLMs have a medical purpose and are supplied to Australians, they may be subject to medical device regulations"; "where a developer adapts, builds on or incorporates a LLM into their product ... the developer is deemed the manufacturer"; but "where there are no medical purpose or claims associated with the product using the LLM ... it is unlikely to be a medical device." — [same TGA PDF](https://cmcmedicaldevices.com/wp-content/uploads/2025/08/understanding-regulation-of-software-based-medical-devices-tga-27082025.pdf)
- General health/wellness exclusion conditions: software "intended by its manufacturer to be used by a consumer to promote or facilitate general health or wellness by measuring or monitoring (through non-invasive means) a physical parameter" and "not intended by its manufacturer to be used: in clinical practice; or treatment, or making a recommendation or decision about the treatment, of a serious disease or a serious condition, ailment or defect." A fitness tracker with heart-rate warnings for users with chronic heart conditions is **not** excluded, and diabetes is given as a serious condition needing professional intervention. — [TGA: Understanding the general health or wellness software exclusion](https://www.tga.gov.au/resources/guidance/understanding-general-health-or-wellness-software-exclusion)
- 2021 reforms: consumer health products were excluded as "prevention, management and follow up devices that do not provide specific treatment or treatment suggestions". This covers software for "self-management of an existing disease" and to "improve general health or wellness by coaching". Uses related to "diagnosis or treatment of diseases" fall outside the exclusions. — [Herbert Smith Freehills, 21 Jun 2021](https://www.hsfkramer.com/insights/2021-06/regulatory-reform-for-software-based-consumer-health-can-rules-keep-up-with-reality)
- Secondary summary (Mar 2026): "health self-management software, may also be excluded when they support users without providing direct medical intervention"; digital mental health tools "may be excluded if they do not perform clinical diagnosis or therapeutic intervention". — [Regulatory Affairs News, 21 Mar 2026](https://www.regulatoryaffairsnews.com/post/tga-med-dev-guidance-software-exclusions-from-medical-device-regulations)
- The digital mental health tool (DMHT) exclusion has four conditions, summarised as "focused on mental health intent, reliance on established guidelines, in-software referencing, and user accessibility of those guidelines". The guideline may come from "a hospital or a recognized individual expert". — [MedEnvoy, 5 May 2026](https://medenvoyglobal.com/blog/tga-clarifies-exclusion-for-digital-mental-health-software/)
- The TGA AI review (report published Aug 2025) found the DMHT exclusion "no longer appropriate", particularly for consumer-supplied tools without clinical oversight, and recommended urgent review. It also flagged that some wellness apps "may inadvertently meet the medical device definition", with enforcement expected. — [MinterEllison, 6 Aug 2025](https://www.minterellison.com/articles/tga-publishes-findings-on-ai-and-medical-devices); corroborated by [IBA](https://www.ibanet.org/ai-mental-health-services)
- TGA presentation (July 2026) on status:
  - DMHT exclusion review is ongoing: 62% of consultation respondents said it is "no longer appropriate"; a 20-member Expert Group has held three workshops; a "public consultation on modification/removal options [is] expected soon".
  - A health chatbot review is in scoping.
  - Digital scribes cross into device territory when they suggest "treatment or intervention options independently".
  - Enforcement tools range "from education through criminal prosecution".
  - The software transition period ended 1 Nov 2024.
  
  — [TGA, "Software and AI compliance and reforms" (Jul 2026)](https://www.tga.gov.au/sites/default/files/2026-07/software-and-ai-compliance-and-reforms.pdf)
- The same TGA deck cites LLM safety research: "In 51.6% of cases where someone needed hospital immediately, the platform said stay home". When users consulted LLMs, the "correct course of action was chosen in less than 44%". — [TGA Jul 2026 PDF](https://www.tga.gov.au/sites/default/files/2026-07/software-and-ai-compliance-and-reforms.pdf)
- A TGA DMHT regulatory-environment survey ran 7 Oct 2025 – 13 Feb 2026. Responses "will not be used for conducting compliance or enforcement activities." — [TGA Consultation Hub](https://consultations.tga.gov.au/tga/digital-mental-health-tools-regulatory-environment/)

### Inferences
- **Logging doses and boosters** that the user enters, as a diary, is the lowest-risk function. It performs no action on data beyond storage and display and gives no treatment suggestion. It is very likely not a medical device, or at worst sits inside the self-management exclusion. **[LAWYER]**
- **Learning an "effect window"** from check-ins is borderline. It is *monitoring an individual's response to a prescription drug*, and the baby-movement-app precedent shows that diary framing does not save a function whose real purpose is medical. Two framings reduce risk: describing the output as "your usual focus/energy pattern from your check-ins", and never labelling it as drug onset or wear-off. Using it only to arrange tasks also helps. **[LAWYER]**
- **Scheduling tasks around the window** is productivity, not treatment, as long as the dose time is treated as a fixed, user-supplied input. The app must never propose moving the dose. Suggesting when to take a dose or booster ("take your booster at 1:40 pm to cover your 3 pm lecture") is a "specific treatment suggestion". That removes the self-management exclusion and probably meets the device definition (informing a treatment decision).
- **Whether ADHD is a "serious" condition** in TGA terms is unresolved here. The wellness page treats conditions needing professional intervention (e.g. diabetes) as serious, and ADHD diagnosis and stimulant prescribing need specialists. That makes it risky to rely on exclusions that require a "not serious" condition. The safer basis is that the app has no medical purpose at all. **[LAWYER]**
- **The DMHT exclusion should not be the compliance basis.** It is under review with removal on the table, and an ADHD productivity app is not delivering guideline-based psychological therapy anyway.
- **Claims drive classification** (see the Claims language table in section 10). Marketing, App Store text, onboarding copy, push notifications and LLM outputs all count as evidence of intended purpose.

### Gaps
- I could not fetch the exact TGA text of the "health self-management" and "digital mental health tool" exclusions, the Excluded Goods Determination 2018 Schedule 1 item 14, or the TGA "Is my software regulated?" tool (tga.gov.au blocked automated fetches). The wording above is from secondary sources. **[LAWYER]** to confirm the exact conditions.
- I could not confirm which TGA classification rule would apply if the app did give dose-timing suggestions to consumers (likely Class IIa or higher under the software rules), or whether TGA has a medication-reminder example equivalent to FDA's.
- TGA advertising rules on naming Schedule 8 prescription medicines (e.g. brand names) in consumer-facing app marketing were not verified. **[LAWYER]**
- Whether the DMHT public consultation opened after July 2026 was not verified.

---

## 2. United States (FDA): device software functions, General Wellness (2026), Mobile Medical Applications policy, CDS, and medication reminders

### Takeaway
FDA explicitly exercises enforcement discretion for software that tracks medications and gives *user-configured* reminders, and for self-management "without providing specific treatment suggestions". Patient-facing decision support cannot qualify as non-device CDS. So a learned, app-generated recommendation about dose or booster timing is the part most likely to be a regulated device function. The January 2026 General Wellness revision widened room for wearable metrics, but it still bars disease references and treatment recommendations.

### Cited Findings
- FDA intends to exercise enforcement discretion for software functions that "Help patients/users self-manage their disease or condition without providing specific treatment suggestions". Governing guidance: "Policy for Device Software Functions and Mobile Medical Applications" (2013, updated 2015, 2019, 2022). Page updated 27 May 2026. — [FDA: Device Software Functions Including MMAs](https://www.fda.gov/medical-devices/digital-health-center-excellence/device-software-functions-including-mobile-medical-applications)
- Enforcement-discretion examples:
  - item 11: "Software functions that keep track of medications and provide user-configured reminders for improved medication adherence";
  - item 1: functions that "help patients with diagnosed psychiatric conditions (for example, PTSD, depression, anxiety, OCD) maintain their behavioral coping skills";
  - item 12: "historical trending and comparison of vital signs (for example ... heart rate ...)".
  
  FDA notes these "may meet the definition of medical device" but pose lower risk. — [FDA enforcement-discretion examples](https://www.fda.gov/medical-devices/device-software-functions-including-mobile-medical-applications/examples-software-functions-which-fda-will-exercise-enforcement-discretion)
- Not devices: software that "Generate[s] reminders for scheduled medical appointments", and functions to "log, record, track, evaluate, or make decisions or behavioral suggestions related to developing or maintaining general fitness, health or wellness". — [FDA: examples not medical devices](https://www.fda.gov/medical-devices/device-software-functions-including-mobile-medical-applications/examples-software-functions-are-not-medical-devices)
- Regulated examples centre on software that "analyzes patient-specific ... information" to provide recommendations or predictions, e.g. analysing "daily heart rate, SpO2, blood pressure, or other output from wearable product" to predict heart-failure hospitalisation. — [FDA: examples of device software functions FDA regulates](https://www.fda.gov/medical-devices/device-software-functions-including-mobile-medical-applications/examples-device-software-functions-fda-regulates)
- Revised General Wellness guidance (6 Jan 2026):
  - Allows non-invasive wearables measuring parameters such as heart rate variability and blood pressure for wellness.
  - Notifications must "avoid naming diseases or conditions" and exclude "clinical thresholds, diagnoses, or treatment recommendations".
  - Values that "mimic those used clinically" must be validated.
  
  — [Covington, Jan 2026](https://www.cov.com/en/news-and-insights/insights/2026/01/fda-issues-revised-guidance-on-general-wellness-products)
- Under the 2026 guidance, wellness products cannot be "intended to manage" conditions, and claims must "avoid references to disease". For CDS, criterion 3 requires supporting "*health care professional* decision-making", so "Patient- or caregiver-facing decision support cannot qualify as non-device CDS". Software relying on "real-time or near-term predictions" generally stays under oversight. — [Faegre Drinker, Jan 2026](https://www.faegredrinker.com/en/insights/publications/2026/1/key-updates-in-fdas-2026-general-wellness-and-clinical-decision-support-software-guidance)

### Inferences
- **Dose/booster log plus user-set reminders** maps directly to enforcement-discretion item 11. Low risk.
- **App-computed reminders** ("your booster is due in 20 min", set by the model rather than the user) move away from "user-configured". They look like patient-facing treatment timing, which is not non-device CDS. Keep every medication-time reminder user-configured, and have the user confirm each schedule the app infers.
- **Using the learned window only to place tasks**, with no medication suggestion, is best argued as general wellness/productivity. The disease-reference restrictions mean US marketing should not claim to manage ADHD. **[LAWYER]**
- **Apple Health heart rate, sleep and workouts** used for "energy/focus" context fit the 2026 wellness expansion. Any alert tying HR to stimulant effects (e.g. "your heart rate is high for your dose") would be a disease/treatment-linked notification and should be avoided.

### Gaps
- I did not read the full text of the Jan 2026 General Wellness or CDS guidance PDFs. Findings rely on law-firm summaries plus FDA example pages.
- I found no FDA example specifically covering "learning a drug-effect curve from self-reports". **[LAWYER]** / FDA Digital Health Center (digitalhealth@fda.hhs.gov) pre-submission question if US launch includes that feature.

---

## 3. US privacy and enforcement (FTC HBNR, Cerebral, BetterHelp, GoodRx, Washington MHMDA) and the Cerebral/Done ADHD stimulant cases

### Takeaway
Outside HIPAA, a US consumer app that logs medications and syncs Apple Health is squarely a "vendor of personal health records" under the amended FTC Health Breach Notification Rule. Unauthorised *sharing* counts as a breach, not just hacking. The FTC's GoodRx, BetterHelp and Cerebral orders set the norm: no health data for advertising, no pixels, affirmative express consent, and retention limits. Washington's MHMDA adds opt-in consent, a signed authorisation for any sale, and a private right of action. The Done and Cerebral criminal and regulatory history shows the reputational cost of frictionless stimulant-related design.

### Cited Findings
- The amended HBNR took effect **29 July 2024**. "Health care services or supplies" include "websites, mobile applications, or internet-connected devices" tracking health conditions, medications, fitness, sleep or mental health. "Breach of security includes an unauthorized acquisition that occurs as a result of a data breach or an unauthorized disclosure." Apps with "technical capacity to draw information from multiple sources" are covered whether or not users enable the integration. — [Federal Register, 30 May 2024](https://www.federalregister.gov/documents/2024/05/30/2024-10855/health-breach-notification-rule)
- The FTC gives a fitness app that syncs with wearables as "likely a vendor of personal health records". Notice timing and penalties:
  - individuals: "without unreasonable delay" and within 60 calendar days;
  - FTC: within the same 60 days for 500+ people;
  - media: required if 500+ residents of a state are affected;
  - penalties: "up to $53,088 per violation" (as of Jan 2025).
  
  — [FTC: Complying with the HBNR](https://www.ftc.gov/business-guidance/resources/complying-ftcs-health-breach-notification-rule-0)
- **GoodRx** (1 Feb 2023) was the first HBNR action, with a $1.5M civil penalty. It shared prescription and medication data with Facebook, Google, Criteo, Branch and Twilio despite promising it "would never share personal health information with advertisers". The order permanently bans sharing health data for advertising. — [FTC GoodRx](https://www.ftc.gov/news-events/news/press-releases/2023/02/ftc-enforcement-action-bar-goodrx-sharing-consumers-sensitive-health-info-advertising)
- **BetterHelp** (final order 14 Jul 2023) paid $7.8M. It had shared "email addresses, IP addresses, and health questionnaire information to Facebook, Snapchat, Criteo, and Pinterest". The order requires "affirmative express consent before disclosing personal information to certain third parties" and retention limits. — [FTC BetterHelp](https://www.ftc.gov/news-events/news/press-releases/2023/07/ftc-gives-final-approval-order-banning-betterhelp-sharing-sensitive-health-data-advertising)
- **Cerebral** (15 Apr 2024):
  - about 3.2M consumers affected; tracking tools shared health information with LinkedIn, Snapchat and TikTok;
  - postcards revealing diagnoses went to 6,000+ patients;
  - former employees kept data access;
  - a cancellation button was removed after cancellations rose.
  
  The order permanently bans using health data for advertising, requires retention schedules and deletion mechanisms, and imposes $5.1M refunds plus a $10M civil penalty ($2M due, $8M suspended). — [FTC Cerebral](https://www.ftc.gov/news-events/news/press-releases/2024/04/proposed-ftc-order-will-prohibit-telehealth-firm-cerebral-using-or-disclosing-sensitive-data)
- Cerebral (DOJ): the investigation began in 2022 into prescribing of controlled substances "such as Adderall". The company ceased most controlled-substance prescribing in 2022 and in November 2024 "agreed to pay $3.65 million to resolve the DOJ probe". — [Wikipedia: Cerebral (company)](https://en.wikipedia.org/wiki/Cerebral_(company)) (secondary source; DOJ primary not opened)
- **Done Global** (current status):
  - Founder/CEO Ruthia He and clinical president David Brody were convicted in **November 2025** and sentenced on **7 July 2026**: He to 72 months plus a $1M fine, Brody to 24 months plus a $1M fine.
  - The scheme distributed 37M+ Adderall pills and defrauded insurers of $12.3M.
  - Design features at issue: deceptive social-media ads; shortened assessments; an auto-refill platform ("30 seconds per refill"); clinician pay incentives.
  - He was also convicted of conspiracy to obstruct.
  - The DOJ URL slug says "8 years" but the release text says 72 and 24 months.
  
  — [DOJ Office of Public Affairs](https://www.justice.gov/opa/pr/founderceo-and-clinical-president-digital-health-company-sentenced-8-years-90-million-scheme)
- **Washington My Health My Data Act**:
  - covers "past, present, or future physical or mental health status", including data "derived or extrapolated from nonhealth data";
  - requires separate consent for collection and for sharing;
  - "It is unlawful for anyone to sell or offer to sell consumer health data without first obtaining valid authorization";
  - deletion must extend to "archived or backup systems";
  - no revenue threshold; enforceable by the AG and through private action;
  - core sections applied from 31 Mar 2024 (30 Jun 2024 for small businesses).
  
  — [Washington AG](https://www.atg.wa.gov/protecting-washingtonians-personal-health-data-and-privacy)

### Inferences
- **HBNR coverage.** The app is very likely a PHR vendor under the HBNR because it combines user-entered medication logs with Apple Health data. Any SDK that transmits identifiable health data without authorisation (analytics, attribution, crash logs containing medication names, or LLM calls not disclosed) could be a notifiable "breach". **[LAWYER]**
- **MHMDA reach.** An inferred "effect window" or focus curve is health data under MHMDA, since it is derived and extrapolated. MHMDA-style opt-in consent should be the global baseline, because it also satisfies Apple 5.1.2(i) and AU/EU consent standards.
- **Reputational lesson from Done and Cerebral.** Features that make stimulant-taking frictionless or push more medication can be framed as facilitating misuse or diversion. Examples: auto-refill nudges, "take more to focus" prompts, and growth marketing aimed at people without a diagnosis. The app should stay adherence-neutral and prescriber-deferential.

### Gaps
- Other US state consumer-health-data laws (e.g. Nevada, Connecticut) and state comprehensive privacy laws were not reviewed.
- Whether the Done defendants have appealed was not verified.

---

## 4. UK (MHRA) and EU (MDR, AI Act, GDPR): classifying a scheduling assistant that uses health data

### Takeaway
UK MHRA guidance is the most explicit. Medication *reminders* are not devices, but software "intended to influence the actual treatment - dose, size of implant, **time of treatment** etc." is "most likely to be a device". In the EU, MDCG 2019-11 rev.1 (June 2025) excludes wellness apps but places medication-adherence monitoring that influences treatment, and dose recommendations to patients, inside MDSW (Rule 11, usually Class IIa+). If the app stays non-device, the EU AI Act's high-risk regime does not apply. Article 50 AI transparency still applies, and health data needs GDPR Art 9 explicit consent (UK GDPR equivalent).

### Cited Findings
- MHRA guidance (v1.10f, July 2023; GOV.UK page last updated 1 July 2023):
  - not a device: "Apps and software that are intended to remind users that medicines are taken";
  - a device: those "which calculate medicine doses for you to take";
  - decision support is "most likely to be a device if: It is intended to influence the actual treatment - dose, size of implant, time of treatment etc.";
  - apps that "simply replace a written diary/log of symptoms" are unlikely to be devices;
  - monitoring apps "may qualify ... if the output is intended to affect the treatment of an individual";
  - indicative device words include "Calculates", "Help/help with", "Measures, Predicts", "Pharmacokinetic", "Controls".
  
  — [MHRA "Medical device stand-alone software including apps" PDF](https://assets.publishing.service.gov.uk/media/64a7d22d7a4c230013bba33c/Medical_device_stand-alone_software_including_apps__including_IVDMDs_.pdf); [GOV.UK landing page](https://www.gov.uk/government/publications/medical-devices-software-applications-apps)
- MDCG 2019-11 rev.1 (June 2025):
  - Step 3: software is potentially MDSW if it performs "an action beyond storage, archival, communication, simple search, lossless compression";
  - Step 4: "is the action for the benefit of individual patients?";
  - "wellness or fitness apps, do not qualify as MDSW";
  - MDSW examples include "MDSW intended to monitor medication adherence (e.g. to inhaled medication) ... and influences the use of the medical device" and "MDSW that provides insulin dose recommendations to a patient";
  - Rule 11: software providing "information which is used to take decisions with diagnosis or therapeutic purposes is classified as class IIa" (higher if serious deterioration or death is possible).
  
  — [MDCG 2019-11 rev.1 PDF](https://health.ec.europa.eu/document/download/b45335c5-1679-4c71-a91c-fc7a4d37f12b_en?filename=mdcg_2019_11_en.pdf); revision/date confirmed on [EC MDCG guidance index](https://health.ec.europa.eu/medical-devices-sector/new-regulations/guidance-mdcg-endorsed-documents-and-other-guidance_en)
- MDCG 2025-6 (June 2025): an AI system is high-risk under AI Act Art 6(1) only if it is a medical device or safety component **and** needs notified-body conformity assessment. Class I non-sterile, non-measuring MDSW is not high-risk. "Article 50 AIA transparency requirements apply independently of MDR/IVDR classification." — [MDCG 2025-6 PDF](https://health.ec.europa.eu/document/download/b78a17d7-e3cd-4943-851d-e02a2f22bbb4_en?filename=mdcg_2025-6_en.pdf)
- EU AI Act dates (tracker page updated 31 Aug 2026):
  - prohibitions and AI literacy: 2 Feb 2025;
  - GPAI obligations: 2 Aug 2025;
  - Art 50: 2 Dec 2026 listed for certain synthetic-content providers already on the market before 2 Aug 2026;
  - Annex III high-risk: **2 Dec 2027**;
  - Annex I high-risk (incl. MDR-linked): **2 Aug 2028**.
  
  — [artificialintelligenceact.eu implementation timeline](https://artificialintelligenceact.eu/implementation-timeline/). *Conflict:* the page shows the postponed dates yet states "No changes from Digital Omnibus are reflected". MDCG 2025-6 (pre-omnibus) gave 2 Aug 2027 for high-risk MDAI. **[LAWYER]** to confirm which dates are law.
- GDPR Art 9(1) prohibits processing "data concerning health" unless an exception applies. Art 9(2)(a) is "explicit consent ... for one or more specified purposes". — [GDPR Art 9](https://gdpr-info.eu/art-9-gdpr/)
- UK ICO: health data includes inferences where you "intend to make an inference about health" or treat someone differently based on it. Large-scale special-category processing typically requires a DPIA. — [ICO special category data](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/lawful-basis/special-category-data/what-is-special-category-data/)

### Inferences
- **UK line.** "Time of treatment" squarely covers booster-timing or dose-timing suggestions. That feature must not ship in the UK without UKCA/CE device conformity. The learned window used only for task placement is arguably "lifestyle/diary" and not a device. **[LAWYER]**
- **EU line.** Learning an effect window acts on data beyond storage (Step 3) for an individual (Step 4). Whether it qualifies as MDSW depends on intended purpose, i.e. whether it supports therapeutic decisions. Keep it framed and engineered as scheduling-only.
- **AI Act.** As a non-device, the scheduling assistant is not Annex I high-risk. Annex III lists no scheduling or productivity use case. The Art 50 duty to inform users they are interacting with AI still applies to the chat/NL features, and should be adopted globally anyway (Anthropic and Apple rules require it too).
- **GDPR/UK GDPR.** Explicit, granular consent is needed for health data, including the inferred window. A DPIA is prudent before EU/UK launch. EU Gemini API use must be on Paid Services (section 8).

### Gaps
- MHRA's 2025–2026 changes (e.g. post-market surveillance regulations, any new digital mental health technology guidance) were not verified. The GOV.UK software page showed no update after July 2023.
- EU Digital Omnibus legislative status (adopted vs proposed) was not independently confirmed.

---

## 5. Australian privacy law (Privacy Act/APPs, POLA Act 2024, Children's Online Privacy Code, NDB, APP 8 and US LLMs, 16–17-year-olds, social media minimum age), plus NZ

### Takeaway
The app handles health information, which is sensitive information, so collection needs consent. The app is likely a "health service" (it "records" health), so the small-business exemption probably does not apply. Sending prompts containing medication or health data to US LLM providers is a cross-border disclosure under APP 8 unless the app keeps "effective control". OAIC best-practice guidance advises against putting sensitive information into public generative AI tools. POLA Act 2024 obligations are live or imminent: the privacy tort is in force, ADM transparency starts 10 Dec 2026, and the Children's Code must be registered by 10 Dec 2026. The under-16 social media ban does not apply to a health-support planner.

### Cited Findings
- Definitions and consent:
  - "health information" includes "Information or an opinion about the health or a disability of an individual, or a health service provided";
  - it is sensitive information;
  - "health service" includes an activity "intended or claimed to assess, record, maintain or improve the individual's health";
  - valid consent must be informed, voluntary, "current and specific" and given with capacity;
  - entities may "presume that an individual aged 15 or over has capacity to consent, unless there is something to suggest otherwise".
  
  — [OAIC APP Guidelines Chapter B](https://www.oaic.gov.au/privacy/australian-privacy-principles/australian-privacy-principles-guidelines/chapter-b-key-concepts)
- "Regardless of turnover, the Privacy Act covers any business that is: a [health service provider]", and small businesses that "trade in personal information". — [OAIC small business](https://www.oaic.gov.au/privacy/privacy-guidance-for-organisations-and-government-agencies/organisations/small-business)
- APP 8:
  - before disclosing overseas, an entity "must take such steps as are reasonable in the circumstances to ensure that the recipient does not breach the APPs";
  - under s16C the entity "is accountable for any acts or practices of the overseas recipient";
  - exceptions: a substantially similar law with enforcement mechanisms, or informed consent after the entity "expressly informs the individual that if they consent to the disclosure, this principle will not apply";
  - a cloud arrangement may be a "use" not a "disclosure" where the entity retains "effective control".
  
  — [OAIC APP Guidelines Chapter 8](https://www.oaic.gov.au/privacy/australian-privacy-principles/australian-privacy-principles-guidelines/chapter-8-app-8-cross-border-disclosure-of-personal-information)
- OAIC AI guidance (21 Oct 2024, updated 17 Jan 2025):
  - "Privacy obligations will apply to any personal information input into an AI system, as well as the output data";
  - AI-generated or inferred personal information is a collection under APP 3;
  - APP 6 secondary-use limits apply;
  - "Consent goes beyond just a line in your Privacy Policy";
  - vendor due diligence should cover retention, server location and access to inputs;
  - APP 10 accuracy applies because AI produces "inaccurate or false results";
  - "The OAIC recommends that organisations do not enter personal information, and particularly sensitive information, into publicly available generative AI tools."
  
  — [OAIC guidance on commercially available AI products](https://www.oaic.gov.au/privacy/privacy-guidance-for-organisations-and-government-agencies/guidance-on-privacy-and-the-use-of-commercially-available-ai-products)
- Privacy and Other Legislation Amendment Act 2024 (No. 128, Royal Assent 10 Dec 2024):
  - Sch 1 Parts 1–7, including Part 4 (Children's Online Privacy Code), commenced 11 Dec 2024;
  - Sch 1 Part 15 (automated decisions) commences **10 Dec 2026**, after which privacy policies must disclose "the kinds of personal information used in the operation of such computer programs" and the kinds of decisions made "solely by the operation of such computer programs" where decisions "could reasonably be expected to significantly affect the rights or interests" of individuals;
  - Sch 2 (serious invasions of privacy tort) commenced by proclamation with a 6-month backstop.
  
  — [Legislation.gov.au C2024A00128 (PDF as made)](https://www.legislation.gov.au/C2024A00128/asmade/2024-12-10/text/original/pdf); [TOC/metadata](https://www.legislation.gov.au/C2024A00128/asmade/text)
- Children's Online Privacy Code:
  - applies to social media, relevant electronic services and designated internet services "likely to be accessed by children", **"excluding health service providers"**;
  - "The final Code must be registered by 10 December 2026";
  - Phase 3 consultation concluded June 2026 and a Regulatory Impact Analysis is under way (as of Aug 2026).
  
  — [OAIC COPC page](https://www.oaic.gov.au/privacy/privacy-registers/privacy-codes/childrens-online-privacy-code)
- NDB scheme: notify affected individuals and the OAIC when a breach "is likely to result in serious harm", with individuals notified "as soon as practicable". — [OAIC NDB](https://www.oaic.gov.au/privacy/notifiable-data-breaches/about-the-notifiable-data-breaches-scheme). In 2025 there were 1,205 notifications (a record), with health service providers the top sector at 225 (19%). — [OAIC, 6 Jul 2026](https://www.oaic.gov.au/news/media-centre/data-breach-notifications-increase-to-all-time-high-in-2025,-new-ndb-stats-show)
- Enforcement trend: in June 2026 determinations against telehealth provider **Medmate** and **Monash IVF** ([2026] AICmr 41 and 40), the Commissioner held that "website providers must obtain consent where they're using tracking pixels to collect sensitive information, such as data on health". The release notes "9 in 10 Australians consider it neither fair nor reasonable to be targeted on the basis of their sensitive health data." — [OAIC, 24 Jun 2026](https://www.oaic.gov.au/news/media-centre/privacy-commissioner-finds-privacy-breaches-in-third-party-tracking-pixel-investigation)
- Social media minimum age: platforms must take "reasonable steps to prevent Australians under 16 from having a social media account" (penalties up to A$49.5M). Under-16s keep access to "messaging apps, online gaming, professional networking ... and services that are primarily for the purposes of education and health support". — [Dept of Infrastructure](https://www.infrastructure.gov.au/media-communications/internet/online-safety/social-media-minimum-age)
- NZ: the Health Information Privacy Code 2020 covers "health information ... collected, used, held, and disclosed by health agencies", including "all agencies providing personal or public health or disability services". The page does not address apps specifically. — [NZ OPC HIPC 2020](https://www.privacy.org.nz/privacy-principles/codes-of-practice/hipc2020/)

### Inferences
- **Health service provider status.** Recording medication doses and effect check-ins likely fits "record ... the individual's health". Treat the app as a health service provider: full APP compliance from day one regardless of turnover, NDB coverage, and possibly the COPC carve-out for health service providers. **[LAWYER]**
- **APP 8 and LLMs.** Unless the LLM contract gives effective control (DPA, zero data retention, no training, deletion, security terms), sending prompts with medication or health context to OpenAI, Anthropic or Google in the US is an APP 8 disclosure. The app stays accountable under s16C. Practical path:
  1. Minimise: strip identifiers and medication names before any cloud call, or keep health-context reasoning on device.
  2. Contract: ZDR/DPA; prefer Australian-region processing where available.
  3. Obtain specific, express consent that names the providers and countries; do not rely on the APP 8.2(b) "consent to non-application" alone for sensitive data.
- **16–17-year-olds.** The OAIC presumes capacity to consent at 15+. However, Gemini API terms bar apps "likely to be accessed by individuals under the age of 18" (section 8), and Anthropic requires age verification and safeguards for products serving minors. Recommend **18+ at launch**, enforced through the App Store age rating plus a declared-age gate. Revisit once the COPC is registered (by 10 Dec 2026).
- **ADM transparency (from 10 Dec 2026).** The auto-scheduler makes decisions about a user's calendar, which are unlikely to "significantly affect rights or interests". Still, disclosing in the privacy policy what data drives automated scheduling is cheap insurance.
- **Statutory tort.** Serious invasions of privacy (e.g. leaking stimulant-use data) now carry private litigation risk on top of OAIC enforcement.
- **Social media minimum age.** Not applicable. The app has no social-interaction purpose and would sit in the "health support" carve-out even if it added sharing features.

### Gaps
- **Tranche 2 Privacy Act reform status (2025–2026)** could not be verified: the AGD and OAIC reform pages were unreachable and search budget was exhausted. **[LAWYER]** to confirm whether the "fair and reasonable" test, removal of the small-business exemption, or direct-marketing and targeting rules have been introduced.
- Statutory tort commencement date: the Act sets proclamation or a 6-month backstop, which by calculation gives 10 June 2025. The actual date was not confirmed from a primary commencement notice.
- NZ: whether the HIPC applies to a consumer app, and NZ's medical-device regime for software (post-2024 Therapeutic Products Act repeal), were not verified. The Medsafe pages fetched returned 404.
- OAIC's statement on whether health information breaches are presumptively "serious harm" was not captured.

---

## 6. Apple App Store Review Guidelines and HealthKit rules (1.4.1, 5.1.1, 5.1.2 incl. third-party AI, 5.1.3, HealthKit entitlement, controlled substances)

### Takeaway
Apple's rules are strict and binding. Health apps needing sensitive data should be submitted by a **legal entity, not an individual**. Sharing personal data with third-party AI needs explicit disclosure and permission (added 13 Nov 2025). HealthKit data may not be used for advertising, may be shared with third parties only with express permission and only if they "also provide a health or fitness service to the user", and **personal health information may not be stored in iCloud**. Medical apps must remind users to consult a doctor. Dosage calculators must come from approved entities.

### Cited Findings
- **1.4.1 (exact):** "Apps must clearly disclose data and methodology to support accuracy claims relating to health measurements, and if the level of accuracy or methodology cannot be validated, we will reject your app. ... Apps should remind users to check with a doctor in addition to using the app and before making medical decisions. If your medical app has received regulatory clearance, please submit a link to that documentation with your app." — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- **1.4.2 (exact):** "Drug dosage calculators must come from the drug manufacturer, a hospital, university, health insurance company, pharmacy or other approved entity, or receive approval by the FDA or one of its international counterparts." — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- **1.4.3 (exact, part):** "Apps that encourage consumption of tobacco and vape products, illegal drugs, or excessive amounts of alcohol are not permitted. ... Facilitating the sale of controlled substances (except for licensed pharmacies and licensed or otherwise legal cannabis dispensaries), or tobacco is not allowed." — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- **5.1.1(ix) (exact):** "Apps that provide services in highly regulated fields (such as banking and financial services, healthcare, gambling, legal cannabis use, air travel and crypto exchanges) or that require sensitive user information should be submitted by a legal entity that provides the services, and not by an individual developer." — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- **5.1.1 (permission, exact):** "Apps that collect user or usage data must secure user consent for the collection ... Paid functionality must not be dependent on or require a user to grant access to this data. Apps must also provide the customer with an easily accessible and understandable way to withdraw consent." **5.1.1(v):** "If your app supports account creation, you must also offer account deletion within the app." The privacy policy must "Explain its data retention/deletion policies and describe how a user can revoke consent and/or request deletion". — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- **5.1.2(i) (exact):** "Unless otherwise permitted by law, you may not use, transmit, or share someone's personal data without first obtaining their permission. You must provide access to information about how and where the data will be used. You must clearly disclose where personal data will be shared with third parties, including with third-party AI, and obtain explicit permission before doing so." — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/). The third-party-AI wording was added in the **13 Nov 2025** update. — [Apple Developer News](https://developer.apple.com/news/)
- **5.1.2 (exact):** "Data collected for one purpose may not be repurposed without further consent" and "Data gathered from the HomeKit API, HealthKit, Clinical Health Records API ... may not be used for marketing, advertising or use-based data mining, including by third parties." — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- **5.1.3(i) (exact):** "Apps may not use or disclose to third parties data gathered in the health, fitness, and medical research context—including from the Clinical Health Records API, HealthKit API, Motion and Fitness, MovementDisorder APIs, or health-related human subject research—for advertising, marketing, or other use-based data mining purposes other than improving health management, or for the purpose of health research, and then only with permission. ... You must disclose the specific health data that you are collecting from the device." — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- **5.1.3(ii) (exact):** "Apps must not write false or inaccurate data into HealthKit or any other medical research or health management apps, and may not store personal health information in iCloud." — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- **2.5.1:** "HealthKit should be used for health and fitness purposes and integrate with the Health app." — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- HealthKit developer rules (exact):
  - "your app must not access the HealthKit APIs unless the use is for health or fitness purposes and this usage is clear in both your marketing text and your user interface";
  - "You must not disclose any information gained through HealthKit to a third party without express permission from the user. Even with permission, you can only share information to a third party if they also provide a health or fitness service to the user";
  - "You can't sell information gained through HealthKit to advertising platforms, data brokers, or information resellers";
  - a privacy policy is mandatory;
  - read denials are invisible ("an app isn't aware when the user denies permission to read data");
  - usage-description keys (NSHealthShareUsageDescription / NSHealthUpdateUsageDescription) are required;
  - HealthKit data is encrypted when the device is locked, so background reads may fail.
  
  — [Apple: Protecting user privacy (HealthKit)](https://developer.apple.com/documentation/healthkit/protecting-user-privacy.md)
- HealthKit medications API: `HKMedicationDoseEvent` (iOS/watchOS 26+) exposes `logStatus`, `scheduleType`, `scheduledDate`, `doseQuantity` and `medicationConceptIdentifier`. `HKUserAnnotatedMedication` (iOS 26+) exposes the medication, nickname, `hasSchedule` and `isArchived`. — [HKMedicationDoseEvent](https://developer.apple.com/documentation/healthkit/hkmedicationdoseevent.md); [HKUserAnnotatedMedication](https://developer.apple.com/documentation/healthkit/hkuserannotatedmedication.md)
- The DPLA defines HealthKit APIs and covers them in s3.3.3(H), but the full text was truncated in the fetch. — [Apple DPLA](https://developer.apple.com/support/terms/apple-developer-program-license-agreement/). The June 2026 DPLA update created a new AI/ML section 3.3.11 ("Updated requirements for use of Foundation Models framework" at 3.3.11(A)) and added s7.9 on "protection of end users who are minors". App Review Guidelines revised "kid and teen safety guidance". — [Apple News, Jun 2026](https://developer.apple.com/news/?id=a233fmpw)
- New age-rating questionnaire responses were required by **31 Jan 2026**. — [Apple upcoming requirements](https://developer.apple.com/news/upcoming-requirements/)

### Inferences
- **Publish under a company** (e.g. an Australian Pty Ltd), not a personal developer account, to satisfy 5.1.1(ix). This also helps liability ring-fencing (section 9).
- **iCloud / CloudKit.** Do not use CloudKit or iCloud Drive to sync medication logs or the learned effect window. Use on-device storage plus the app's own encrypted backend, or HealthKit itself as the store where appropriate. Whether a CloudKit private database counts as "store ... in iCloud" is an interpretive question to confirm with Apple App Review. **[LAWYER/Apple]**
- **HealthKit data to LLMs.** Sending HealthKit-derived data (sleep, HR, workouts) to a cloud LLM is a third-party disclosure. It needs express permission, and the recipient must "also provide a health or fitness service to the user", which is a poor fit for a general LLM API acting as a processor. Safest design: process HealthKit data on device (or via Apple PCC) and send cloud LLMs only non-health text. **[LAWYER/Apple]**
- **Writing to HealthKit.** If the app writes doses to Apple Health, 5.1.3(ii) bans "false or inaccurate data". Undo and edit must propagate, so a mistaken dose must be deletable from HealthKit too.
- **Dose timing and 1.4.2.** Any feature that computes when or how much to take could be treated by App Review as a dosage calculator under 1.4.2, which a student-founded company cannot satisfy. That is another reason to prohibit such features.
- **Required "check with a doctor" copy.** 1.4.1 expects the medical-app reminder text. Include it in onboarding and on medication screens.

### Gaps
- The full DPLA s3.3.3(H) HealthKit text and the new s3.3.11 AI terms were not read (truncated).
- I could not confirm whether third-party apps can *write* `HKMedicationDoseEvent` samples (the docs fetched show read properties only).
- Apple's own Medications feature UI details (follow-up reminders, interaction warnings, logging edits) could not be fetched from Apple Support.

---

## 7. Medication safety design (double-dose prevention, undo, late-dose nudging, misuse/diversion, self-medication, no dose-change suggestions, wording, crisis signposting)

### Takeaway
Stimulant labels already set the rules. Take them in the morning, avoid late-afternoon or evening doses because of insomnia, never double a missed dose, never share, and track remaining quantity. The app must reflect this conservatively. It must never generate a suggestion to take, move, add or skip a dose. Non-medical stimulant use among Australian university students is a minority behaviour but a real one (4.4% past year in a 2015 survey). The app must not become a tool that makes non-prescribed use or booster escalation easier.

### Cited Findings
- Lisdexamfetamine should be taken "once a day in the morning". Avoid "late afternoon or evening because it may cause difficulty falling asleep or staying asleep". For a missed dose, "if it is almost time for the next dose, skip the missed dose", with no doubling. "Do not sell, give away, or let anyone else take your medication" because it "may harm others and is against the law." It "can be habit-forming". — [MedlinePlus: Lisdexamfetamine](https://medlineplus.gov/druginfo/meds/a607047.html)
- Methylphenidate: "Talk to your doctor or pharmacist about how late in the day you should take a missed dose"; "Do not take a double dose to make up for a missed one"; keep "track of how much medication is left so you will know if any is missing"; store it "in a safe place so no one else can take it accidentally or on purpose". — [MedlinePlus: Methylphenidate](https://medlineplus.gov/druginfo/meds/a682188.html)
- Australian university students (internet survey of 1,136 students at three universities, 2015): non-medical prescription stimulant use for study was **6.5% lifetime and 4.4% past year**, against 41.4% using coffee and 23.6% energy drinks for study. Correlates were male gender, prior stimulant prescription, social connections with users and previous illicit recreational drug use. — [Lucke et al., BMC Public Health 2018](https://link.springer.com/article/10.1186/s12889-018-6212-0); listing via [PubMed search](https://pubmed.ncbi.nlm.nih.gov/?term=non-medical+prescription+stimulant+use+Australian+university+students)
- FDA's low-risk bucket is "user-configured reminders" for adherence. — [FDA enforcement-discretion examples](https://www.fda.gov/medical-devices/device-software-functions-including-mobile-medical-applications/examples-software-functions-which-fda-will-exercise-enforcement-discretion). MHRA treats influencing "time of treatment" as device territory. — [MHRA PDF](https://assets.publishing.service.gov.uk/media/64a7d22d7a4c230013bba33c/Medical_device_stand-alone_software_including_apps__including_IVDMDs_.pdf)
- HealthKit dose events carry a `logStatus` and `scheduleType` (scheduled vs other), which gives the app a structured status to mirror. — [HKMedicationDoseEvent](https://developer.apple.com/documentation/healthkit/hkmedicationdoseevent.md)
- Done Global's harms included an "auto-refill" design and advertising that persuaded people "without genuine ADHD" they had it. — [DOJ](https://www.justice.gov/opa/pr/founderceo-and-clinical-president-digital-health-company-sentenced-8-years-90-million-scheme)
- Apple's on-device model rules prohibit uses that "Enables dependency or spiraling user interactions detrimental to a user's mental health" and "Facilitates, promotes, or glamorizes any form of suicide or self harm". — [Apple Foundation Models acceptable use](https://developer.apple.com/apple-intelligence/acceptable-use-requirements-for-the-foundation-models-framework/)
- Crisis lines:
  - Australia (Lifeline): phone 13 11 14, text 0477 13 11 14, 24/7 chat; "call Triple Zero (000)" for life-threatening emergencies. — [Lifeline](https://www.lifeline.org.au/)
  - US: call or text 988, or chat, "available 24/7/365". — [988 Lifeline](https://988lifeline.org/)

### Inferences (design requirements)
- **Double-dose guard.**
  - When logging, show the last logged dose of the same medication with its time.
  - If a same-medication log falls inside a user-defined minimum interval, require an explicit confirmation ("You logged Medication X at 7:42 am. Log another dose?").
  - Use neutral wording, never "safe to take".
  - Provide an "Already taken?" lookup on Apple Watch and a Lock Screen widget so the user can check without opening the app.
- **Undo and edit.** Offer an immediate undo (e.g. a 10-second toast), full edit and delete with an audit trail kept locally, and propagate deletions to HealthKit if the app writes there (5.1.3(ii) accuracy).
- **No auto-logging** from notifications without an explicit tap. "Snooze" must never count as "taken".
- **No late-dose nudging.**
  - Reminders fire only at user-configured times.
  - The app never generates booster prompts or "catch-up" prompts.
  - If a user configures a reminder late in the day, show at most a neutral, label-derived note: "Your prescriber or pharmacist can advise how late is appropriate for your medication."
  - Never schedule demanding tasks late in the day in a way that implies taking more medication.
- **The scheduler treats medication as a fixed input.** It adapts tasks to the window and never adapts the window by suggesting dose changes. Any "focus window is shorter than your task load" state should suggest *task* changes: split, reschedule, break.
- **Misuse and diversion.**
  - Do not support logging medication "for someone else".
  - Do not include inventory-sharing or "friends" features.
  - Do not market to undiagnosed users ("think you have ADHD?").
  - Do not allow anonymous, free-text drug naming to be combined with "study hack" framing.
  - A pill-count or "refill due" view is acceptable but should be neutral (MedlinePlus advises tracking quantity to detect missing medication).
- **Self-medicating users** (non-prescribed or off-label use).
  - Do not ask for or require prescription proof: that collects more sensitive data and is not the app's role.
  - Onboarding should state the app is for people using medication as prescribed.
  - If the user's messages indicate non-prescribed use or escalating doses, the LLM layer should give a fixed, non-judgemental response signposting a GP or pharmacist and, in Australia, a crisis line where relevant. It should never give harm-reduction dosing advice.
- **Wellbeing and crisis signposting.** Include a static "Get support" screen with country-appropriate lines (AU: Lifeline 13 11 14 and 000; US: 988; others per launch market), and deterministic, non-LLM routing when self-harm or crisis keywords appear in check-ins or chat.
- **Wording.** Say "you logged", "your check-ins", "focus pattern", "reminder you set". Avoid "dose due", "optimal time", "wear-off prediction", "booster recommended". See the table in section 10.

### Gaps
- I could not fetch primary material on how Medisafe or Apple Health Medications handle duplicate logging, follow-up reminders or critical alerts (the Medisafe homepage lacked feature detail; Apple Support pages returned only a table of contents).
- The FDA 2023 prescription-stimulant boxed-warning page could not be read (404 then HTTP 429). Figures on diversion sources (e.g. friends and family) are therefore unsourced here.
- More recent Australian prevalence data (post-2015, post-telehealth expansion) was not found in this pass.
- UK (Samaritans), NZ (1737) and EU crisis numbers were not verified from primary pages in this pass.

---

## 8. LLM risks and provider policies (hallucinated advice, prompt injection via screenshots/emails, retention/training, ZDR, AU residency, Apple on-device and Private Cloud Compute)

### Takeaway
The three main cloud providers do not train on API data by default and keep API data for about 30 days unless zero data retention is approved. Their usage terms add hard constraints:
- **Google's Gemini API terms bar medical advice and any app likely to be used by under-18s.**
- OpenAI bars tailored medical advice without a licensed professional.
- Anthropic's high-risk healthcare rules require professional review and AI disclosure.

Screenshots and emails are indirect prompt-injection vectors. Apple's 2026 Foundation Models framework now supports on-device image understanding and developer access to Private Cloud Compute (iOS 27+). That gives a privacy-preserving path for health-context parsing.

### Cited Findings
- **OpenAI:**
  - API data "isn't used for training our models" by default (since 1 Mar 2023);
  - inputs and outputs may be retained "for up to 30 days to provide the services and to identify abuse";
  - zero data retention (ZDR) is available "for eligible endpoints if you have a qualifying use-case";
  - BAAs are available (updated 8 Jan 2026).
  
  — [OpenAI enterprise privacy](https://openai.com/enterprise-privacy/)
- OpenAI data controls:
  - abuse-monitoring logs are "retained for up to 30 days";
  - ZDR and Modified Abuse Monitoring "require prior OpenAI approval";
  - data-residency *storage* regions include **Australia** (also the US, EU, UK and others), but the fetched summary said processing occurs "in the US and EU only" (verify);
  - image inputs are scanned for CSAM and flagged images are retained "even if Zero Data Retention ... is enabled".
  
  — [OpenAI "Your data"](https://developers.openai.com/api/docs/guides/your-data)
- OpenAI usage policies (29 Oct 2025) prohibit "provision of tailored advice that requires a license, such as legal or medical advice, without appropriate involvement by a licensed professional". — [OpenAI usage policies](https://openai.com/policies/usage-policies/)
- **Anthropic:**
  - "For Anthropic API users, we automatically delete inputs and outputs on our backend within 30 days";
  - ZDR is available by agreement;
  - flagged content is retained "for up to 2 years" and classifier scores for up to 7 years.
  
  — [Anthropic privacy center](https://privacy.claude.com/en/articles/7996866-how-long-do-you-store-my-organization-s-data). Commercial Terms (17 Jun 2025): "Anthropic may not train models on Customer Content from Services." — [Anthropic Commercial Terms](https://www.anthropic.com/legal/commercial-terms)
- Anthropic Usage Policy (15 Sep 2025): for high-risk healthcare use cases, "a qualified professional in that field must review the content or decision prior to dissemination or finalization", and "you must disclose to them that you are using AI". — [Anthropic AUP](https://www.anthropic.com/legal/aup). For products serving minors, requirements include "Age verification systems", "Content moderation and filtering", and disclosure "that they are interacting with an AI system rather than a human". — [Anthropic minors guidelines](https://support.claude.com/en/articles/9307344-responsible-use-of-anthropic-s-models-guidelines-for-organizations-serving-minors)
- **Google Gemini API terms (effective 23 Mar 2026), exact:**
  - "You may not use the Services in clinical practice, to provide medical advice, or in any manner that is overseen by or requires clearance or approval from a medical device regulatory agency";
  - "You also will not use the Services as part of a website, application, or other service ... that is directed towards or is likely to be accessed by individuals under the age of 18";
  - unpaid-tier content is used to improve products with human reviewers ("Do not submit sensitive, confidential, or personal information to the Unpaid Services");
  - "You may use only Paid Services when making API Clients available to users in the European Economic Area, Switzerland, or the United Kingdom."
  
  — [Gemini API Additional Terms](https://ai.google.dev/gemini-api/terms)
- **Amazon Bedrock** (a route to Claude models under AWS terms):
  - model providers "don't have access to Amazon Bedrock logs or to customer prompts and completions";
  - a `none` retention mode means "Zero data retention";
  - retention is per-Region, and with cross-region inference, retained data is stored where processed.
  
  — [Bedrock data protection](https://docs.aws.amazon.com/bedrock/latest/userguide/data-protection.html); [Bedrock data retention](https://docs.aws.amazon.com/bedrock/latest/userguide/data-retention.html)
- **Prompt injection** (OWASP LLM01:2025): indirect injection arises when "External sources (websites, files, documents) contain content that ... causes unintended behavioral changes". Attackers can "embed hidden instructions within images". Mitigations: constrain behaviour, validate output formats, filter inputs and outputs, least privilege, "Require human approval for high-risk actions", segregate external content, adversarial testing. — [OWASP GenAI](https://genai.owasp.org/llmrisk/llm01-prompt-injection/)
- **Hallucination** (OAIC): "AI systems are known to produce inaccurate or false results", which engages APP 10 accuracy. — [OAIC AI guidance](https://www.oaic.gov.au/privacy/privacy-guidance-for-organisations-and-government-agencies/guidance-on-privacy-and-the-use-of-commercially-available-ai-products). TGA cites research where LLM users chose the correct course "in less than 44%" of cases. — [TGA Jul 2026](https://www.tga.gov.au/sites/default/files/2026-07/software-and-ai-compliance-and-reforms.pdf)
- **Apple Foundation Models (2026):**
  - on-device models handle "text and image understanding";
  - `PrivateCloudComputeLanguageModel` offers a "32K-token context" versus 4K on device, runs on iOS/watchOS 27+, requires a "managed entitlement" with eligibility requirements, and has per-person daily limits (iCloud+ for more);
  - images can be attached to prompts, and the Vision `OCRTool` can be added as a tool;
  - "Perform image analysis with the on-device model first".
  
  — [Foundation Models overview](https://developer.apple.com/documentation/foundationmodels.md); [PCC for developers](https://developer.apple.com/documentation/foundationmodels/adding-server-side-intelligence-with-private-cloud-compute.md); [Multimodal prompting](https://developer.apple.com/documentation/foundationmodels/analyzing-images-with-multimodal-prompting.md)
- PCC guarantees: personal data stays on nodes "only until the response is returned"; no privileged runtime access; non-targetability; verifiable transparency via published builds. — [Apple Security Research, 10 Jun 2024](https://security.apple.com/blog/private-cloud-compute/)
- Apple's Foundation Models acceptable use prohibits outputs that are "inaccurate or dangerous ... or makes decisions without human supervision that have a material impact on individual rights, in high-risk domains, including ... medical". — [Apple acceptable use](https://developer.apple.com/apple-intelligence/acceptable-use-requirements-for-the-foundation-models-framework/)

### Inferences
- **Routing architecture.**
  1. Anything touching medication, doses, check-ins or HealthKit goes to on-device Foundation Models first, with PCC (iOS 27+, entitlement) as the escalation.
  2. Cloud LLMs (OpenAI, Anthropic, or Claude via Bedrock) receive only de-identified productivity text (task titles, email and calendar content the user chose to parse), with medication references stripped.
  3. Use ZDR and a DPA; disclose each provider under Apple 5.1.2(i) and APP 8.
- **Gemini.** It is effectively unusable for this app's medication-adjacent features (medical-advice bar), and for any under-18 user. If used at all, restrict it to generic task parsing, paid tier only, 18+ users.
- **Output constraints.** Hard-code them so no LLM path can emit dose, timing or booster advice:
  - structured output schemas (e.g. `@Generable`) that have no field for medication actions;
  - a deterministic post-filter;
  - refusal templates that route to "ask your prescriber or pharmacist".
  
  This also keeps the app outside the Anthropic/OpenAI "tailored medical advice" rules and the Gemini medical-advice ban.
- **Prompt injection via screenshots and emails.** Treat parsed content as data, never instructions. Extract into fixed schemas (event title, time, location). Require user confirmation before any calendar write, and never let parsed content create or modify medication entries or reminders.
- **AU data residency.** OpenAI offers Australian data storage, but whether *inference* stays in Australia is unclear. Bedrock is per-region, but AU availability of specific Claude models was not confirmed. Do not promise "your data stays in Australia" unless contractually confirmed. **[LAWYER]**

### Gaps
- Google Vertex AI Gemini Australian-region residency and training terms were not verified (doc pages returned 404).
- Anthropic first-party API data-residency options (e.g. an AU region) in 2026 were not verified.
- AWS Bedrock AU-scoped cross-region inference availability for Claude models was not confirmed.
- PCC developer entitlement eligibility criteria (for example, whether health apps qualify) were not read.

---

## 9. Liability, disclaimers and terms norms for health-adjacent apps

### Takeaway
Disclaimers help show intended purpose but do not override behaviour or claims, and in Australia they cannot exclude the consumer guarantees. The strongest liability controls are design-level: no treatment suggestions, accurate claims, honest privacy promises, and a corporate entity as publisher.

### Cited Findings
- ACL: "Businesses can't take away a consumer's rights"; "no refunds" signs or disclaimers of responsibility breach consumer law. Services come with guarantees of "Due care and skill" and fitness for purpose. — [ACCC consumer guarantees](https://www.accc.gov.au/consumers/buying-products-and-services/consumer-rights-and-guarantees)
- Apple requires medical apps to "remind users to check with a doctor in addition to using the app and before making medical decisions". — [App Review Guidelines 1.4.1](https://developer.apple.com/app-store/review/guidelines/)
- The TGA looks through presentation: diary-framed baby-movement apps are devices because of their real intended purpose. — [TGA software guidance PDF](https://cmcmedicaldevices.com/wp-content/uploads/2025/08/understanding-regulation-of-software-based-medical-devices-tga-27082025.pdf)
- Privacy promises create liability when broken. GoodRx "deceptively promised its users that it would never share personal health information with advertisers" and was penalised. — [FTC GoodRx](https://www.ftc.gov/news-events/news/press-releases/2023/02/ftc-enforcement-action-bar-goodrx-sharing-consumers-sensitive-health-info-advertising). Cerebral misrepresented "cancel anytime". — [FTC Cerebral](https://www.ftc.gov/news-events/news/press-releases/2024/04/proposed-ftc-order-will-prohibit-telehealth-firm-cerebral-using-or-disclosing-sensitive-data)
- 5.1.1(ix) requires a legal entity to submit healthcare or sensitive-data apps. — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

### Inferences
- **Terms should state:**
  - the app is a personal organisation tool, not medical advice, diagnosis or treatment, and not a substitute for a prescriber or pharmacist;
  - it does not tell users when or how much medication to take;
  - users must follow their prescription and label;
  - an emergency and crisis clause.
  
  Draft limitation-of-liability clauses to be ACL-compliant ("to the extent permitted by law") and avoid unfair-contract-terms problems.
- **Operate through a Pty Ltd** with appropriate insurance (professional indemnity / cyber); the cover type is **[LAWYER/broker]**.
- **Privacy wording.** Avoid absolute promises ("never shared", "fully anonymous", "data never leaves your device") unless architecture guarantees them.

### Gaps
- ACCC unfair contract terms guidance (penalties since 9 Nov 2023) could not be fetched (404). Australian case law on health-app liability and typical insurer requirements were not researched.
- US product-liability and state consumer-protection exposure for wellness apps was not researched.

---

## 10. Synthesis: Product rules (must / must-never) and claims language

### Takeaway
The app can legally and commercially log doses, learn a user's self-reported focus pattern and schedule tasks around it, provided that:
- it never produces a medication action (take, move, add, skip, change);
- it never makes disease or treatment claims;
- it handles all health data under opt-in consent and minimisation;
- it routes health context away from third-party cloud LLMs.

Everything below should be confirmed by an Australian health-regulatory and privacy lawyer before launch, and by US/UK/EU counsel before those launches.

### Cited Findings

#### Product rules

| # | Rule | Motivating source |
|---|---|---|
| 1 | **MUST NEVER** suggest, calculate or prompt taking, moving, adding, skipping or changing a dose or booster, including "take your booster now to cover X". | [MHRA: "time of treatment" → device](https://assets.publishing.service.gov.uk/media/64a7d22d7a4c230013bba33c/Medical_device_stand-alone_software_including_apps__including_IVDMDs_.pdf); [HSF on TGA "treatment suggestions"](https://www.hsfkramer.com/insights/2021-06/regulatory-reform-for-software-based-consumer-health-can-rules-keep-up-with-reality); [FDA self-manage "without ... specific treatment suggestions"](https://www.fda.gov/medical-devices/digital-health-center-excellence/device-software-functions-including-mobile-medical-applications) |
| 2 | **MUST** keep every medication reminder user-configured (user picks the time), and require confirmation of any schedule the app infers. | [FDA item 11 "user-configured reminders"](https://www.fda.gov/medical-devices/device-software-functions-including-mobile-medical-applications/examples-software-functions-which-fda-will-exercise-enforcement-discretion) |
| 3 | **MUST** treat the dose time as a fixed input to the scheduler; when capacity is short, adjust tasks, never medication. | [MHRA](https://assets.publishing.service.gov.uk/media/64a7d22d7a4c230013bba33c/Medical_device_stand-alone_software_including_apps__including_IVDMDs_.pdf); [MDCG 2019-11 Rule 11](https://health.ec.europa.eu/document/download/b45335c5-1679-4c71-a91c-fc7a4d37f12b_en?filename=mdcg_2019_11_en.pdf) |
| 4 | **MUST** present the learned window as "your focus/energy pattern from your check-ins", not as drug onset or wear-off, pharmacokinetics or effectiveness. | [TGA: intended purpose / diary precedent](https://cmcmedicaldevices.com/wp-content/uploads/2025/08/understanding-regulation-of-software-based-medical-devices-tga-27082025.pdf); [MHRA indicative words "Predicts", "Pharmacokinetic"](https://assets.publishing.service.gov.uk/media/64a7d22d7a4c230013bba33c/Medical_device_stand-alone_software_including_apps__including_IVDMDs_.pdf) |
| 5 | **MUST NEVER** claim to treat, manage, improve or reduce ADHD symptoms, or reference disease thresholds, in marketing, App Store text or notifications. | [FDA 2026 wellness: avoid disease references / "intended to manage"](https://www.faegredrinker.com/en/insights/publications/2026/1/key-updates-in-fdas-2026-general-wellness-and-clinical-decision-support-software-guidance); [TGA wellness exclusion](https://www.tga.gov.au/resources/guidance/understanding-general-health-or-wellness-software-exclusion) |
| 6 | **MUST NEVER** generate HR/sleep alerts tied to medication or a condition (e.g. "heart rate high for your dose"). | [Covington: notifications must avoid naming conditions / treatment recommendations](https://www.cov.com/en/news-and-insights/insights/2026/01/fda-issues-revised-guidance-on-general-wellness-products); [TGA wellness exclusion example](https://www.tga.gov.au/resources/guidance/understanding-general-health-or-wellness-software-exclusion) |
| 7 | **MUST** show the last same-medication log and require explicit confirmation before logging a second dose inside a user-set interval, in neutral wording (never "safe to take"). | [MedlinePlus: "Do not take a double dose"](https://medlineplus.gov/druginfo/meds/a682188.html) |
| 8 | **MUST** provide immediate undo plus edit and delete of any log, and propagate corrections to HealthKit if written there. | [Apple 5.1.3(ii) no false/inaccurate HealthKit data](https://developer.apple.com/app-store/review/guidelines/) |
| 9 | **MUST NEVER** auto-log a dose from a notification without an explicit "taken" action; snooze or dismiss ≠ taken. | [MedlinePlus double-dose warnings](https://medlineplus.gov/druginfo/meds/a607047.html) (inference: false "taken" or "not taken" records drive double-dosing) |
| 10 | **MUST NEVER** create booster, catch-up or late-afternoon medication prompts; if a user sets a late reminder, show at most a neutral "ask your prescriber/pharmacist how late is appropriate" note. | [MedlinePlus lisdexamfetamine: avoid late afternoon/evening](https://medlineplus.gov/druginfo/meds/a607047.html); [methylphenidate: ask doctor/pharmacist](https://medlineplus.gov/druginfo/meds/a682188.html) |
| 11 | **MUST NEVER** include features enabling sharing, gifting, trading or logging medication for others, or marketing to undiagnosed people. | [MedlinePlus "Do not sell, give away..."](https://medlineplus.gov/druginfo/meds/a607047.html); [Lucke 2018 AU NMPS 4.4%](https://link.springer.com/article/10.1186/s12889-018-6212-0); [DOJ Done Global](https://www.justice.gov/opa/pr/founderceo-and-clinical-president-digital-health-company-sentenced-8-years-90-million-scheme); [Apple 1.4.3](https://developer.apple.com/app-store/review/guidelines/) |
| 12 | **MUST** hard-block LLM outputs from giving medication or dosing advice (schema with no medication-action fields, deterministic filter, fixed referral template). | [OpenAI usage policies](https://openai.com/policies/usage-policies/); [Gemini API terms](https://ai.google.dev/gemini-api/terms); [Apple FM acceptable use](https://developer.apple.com/apple-intelligence/acceptable-use-requirements-for-the-foundation-models-framework/); [TGA: LLM with medical purpose → developer is manufacturer](https://cmcmedicaldevices.com/wp-content/uploads/2025/08/understanding-regulation-of-software-based-medical-devices-tga-27082025.pdf) |
| 13 | **MUST** process medication, check-in and HealthKit data on device (Foundation Models) or via Apple PCC; send cloud LLMs only de-identified, non-health text. | [OAIC: don't enter sensitive info into public gen-AI](https://www.oaic.gov.au/privacy/privacy-guidance-for-organisations-and-government-agencies/guidance-on-privacy-and-the-use-of-commercially-available-ai-products); [HealthKit third-party rule](https://developer.apple.com/documentation/healthkit/protecting-user-privacy.md); [Apple PCC](https://developer.apple.com/documentation/foundationmodels/adding-server-side-intelligence-with-private-cloud-compute.md) |
| 14 | **MUST** disclose each third-party AI provider (name, data sent, country) and obtain explicit opt-in before first use; the app must work without it. | [Apple 5.1.2(i) exact text](https://developer.apple.com/app-store/review/guidelines/); [Apple 5.1.1 paid functionality not conditional on data access](https://developer.apple.com/app-store/review/guidelines/) |
| 15 | **MUST** use enterprise/API tiers with no training, ZDR where approved, and a DPA; **MUST NEVER** use free or unpaid LLM tiers. | [OpenAI enterprise privacy](https://openai.com/enterprise-privacy/); [Anthropic Commercial Terms](https://www.anthropic.com/legal/commercial-terms); [Gemini unpaid-tier warning](https://ai.google.dev/gemini-api/terms) |
| 16 | **MUST** do APP 8 due diligence and contract for effective control over overseas LLM or cloud processing; the app remains accountable under s16C. | [OAIC APP 8 guidelines](https://www.oaic.gov.au/privacy/australian-privacy-principles/australian-privacy-principles-guidelines/chapter-8-app-8-cross-border-disclosure-of-personal-information) |
| 17 | **MUST** get express, specific, withdrawable consent for health data (including the inferred focus window) before collection; **MUST NEVER** rely on the privacy policy alone. | [OAIC Chapter B consent](https://www.oaic.gov.au/privacy/australian-privacy-principles/australian-privacy-principles-guidelines/chapter-b-key-concepts); [OAIC AI guidance "Consent goes beyond just a line in your Privacy Policy"](https://www.oaic.gov.au/privacy/privacy-guidance-for-organisations-and-government-agencies/guidance-on-privacy-and-the-use-of-commercially-available-ai-products); [GDPR Art 9(2)(a)](https://gdpr-info.eu/art-9-gdpr/); [WA MHMDA](https://www.atg.wa.gov/protecting-washingtonians-personal-health-data-and-privacy) |
| 18 | **MUST NEVER** embed ad or attribution pixels or SDKs that receive health-screen events; **MUST NEVER** use health data for advertising or marketing. | [OAIC Medmate/Monash IVF pixel determinations](https://www.oaic.gov.au/news/media-centre/privacy-commissioner-finds-privacy-breaches-in-third-party-tracking-pixel-investigation); [FTC Cerebral](https://www.ftc.gov/news-events/news/press-releases/2024/04/proposed-ftc-order-will-prohibit-telehealth-firm-cerebral-using-or-disclosing-sensitive-data); [FTC BetterHelp](https://www.ftc.gov/news-events/news/press-releases/2023/07/ftc-gives-final-approval-order-banning-betterhelp-sharing-sensitive-health-data-advertising); [Apple 5.1.3(i)](https://developer.apple.com/app-store/review/guidelines/) |
| 19 | **MUST NEVER** sell or license health data, including de-identified "insights", or share HealthKit data with non-health third parties. | [HealthKit: can't sell to ad platforms/data brokers](https://developer.apple.com/documentation/healthkit/protecting-user-privacy.md); [WA MHMDA sale authorisation](https://www.atg.wa.gov/protecting-washingtonians-personal-health-data-and-privacy) |
| 20 | **MUST NEVER** store personal health information in iCloud (CloudKit/iCloud Drive sync of logs); use on-device plus own encrypted backend. | [Apple 5.1.3(ii)](https://developer.apple.com/app-store/review/guidelines/) |
| 21 | **MUST** publish through a legal entity (e.g. Pty Ltd), not a personal developer account. | [Apple 5.1.1(ix)](https://developer.apple.com/app-store/review/guidelines/) |
| 22 | **MUST** offer in-app account deletion, a retention schedule, and deletion that covers backups and processors. | [Apple 5.1.1(v)](https://developer.apple.com/app-store/review/guidelines/); [FTC Cerebral retention/deletion](https://www.ftc.gov/news-events/news/press-releases/2024/04/proposed-ftc-order-will-prohibit-telehealth-firm-cerebral-using-or-disclosing-sensitive-data); [WA MHMDA backups](https://www.atg.wa.gov/protecting-washingtonians-personal-health-data-and-privacy) |
| 23 | **MUST** have a breach-response plan covering the AU NDB ("likely serious harm", notify "as soon as practicable") and the US HBNR (60 days; unauthorised *sharing* counts). | [OAIC NDB](https://www.oaic.gov.au/privacy/notifiable-data-breaches/about-the-notifiable-data-breaches-scheme); [FTC HBNR](https://www.ftc.gov/business-guidance/resources/complying-ftcs-health-breach-notification-rule-0); [Federal Register](https://www.federalregister.gov/documents/2024/05/30/2024-10855/health-breach-notification-rule) |
| 24 | **MUST** launch 18+ only (age rating plus declared-age gate) until a minors design (COPC, Anthropic minors rules) is complete; **MUST NEVER** route under-18 users to the Gemini API. | [Gemini API under-18 bar](https://ai.google.dev/gemini-api/terms); [Anthropic minors guidelines](https://support.claude.com/en/articles/9307344-responsible-use-of-anthropic-s-models-guidelines-for-organizations-serving-minors); [OAIC COPC](https://www.oaic.gov.au/privacy/privacy-registers/privacy-codes/childrens-online-privacy-code); [OAIC 15+ capacity](https://www.oaic.gov.au/privacy/australian-privacy-principles/australian-privacy-principles-guidelines/chapter-b-key-concepts) |
| 25 | **MUST** treat screenshot, email and calendar content as untrusted data: extract only to fixed schemas, require user confirmation before calendar writes, and never let parsed content touch medication entries or reminders. | [OWASP LLM01:2025](https://genai.owasp.org/llmrisk/llm01-prompt-injection/) |
| 26 | **MUST** tell users when they are interacting with AI and label AI-generated schedules and suggestions. | [MDCG 2025-6 on AI Act Art 50](https://health.ec.europa.eu/document/download/b78a17d7-e3cd-4943-851d-e02a2f22bbb4_en?filename=mdcg_2025-6_en.pdf); [Anthropic AUP](https://www.anthropic.com/legal/aup) |
| 27 | **MUST** show "check with your doctor/pharmacist before making medication decisions" in onboarding and on medication screens. | [Apple 1.4.1](https://developer.apple.com/app-store/review/guidelines/) |
| 28 | **MUST** provide a static, non-LLM "Get support" screen and deterministic crisis routing (AU Lifeline 13 11 14 and 000; US 988). | [Lifeline](https://www.lifeline.org.au/); [988](https://988lifeline.org/); [Apple FM: no self-harm facilitation, no spiralling dependency](https://developer.apple.com/apple-intelligence/acceptable-use-requirements-for-the-foundation-models-framework/) |
| 29 | **MUST NEVER** make absolute privacy promises ("never shared", "data never leaves your phone") unless architecture guarantees them; keep cancellation simple. | [FTC GoodRx](https://www.ftc.gov/news-events/news/press-releases/2023/02/ftc-enforcement-action-bar-goodrx-sharing-consumers-sensitive-health-info-advertising); [FTC Cerebral cancellation findings](https://www.ftc.gov/news-events/news/press-releases/2024/04/proposed-ftc-order-will-prohibit-telehealth-firm-cerebral-using-or-disclosing-sensitive-data) |
| 30 | **MUST NEVER** rely on disclaimers to exclude ACL consumer guarantees; scope limitation clauses "to the extent permitted by law". | [ACCC consumer guarantees](https://www.accc.gov.au/consumers/buying-products-and-services/consumer-rights-and-guarantees) |
| 31 | **MUST** request only the HealthKit types needed (sleep, workouts, HR), write clear usage descriptions, and degrade gracefully when access is denied (denials are invisible). | [HealthKit privacy doc](https://developer.apple.com/documentation/healthkit/protecting-user-privacy.md); [Apple 5.1.1 data minimisation](https://developer.apple.com/app-store/review/guidelines/) |
| 32 | **MUST** disclose automated-scheduling logic and the data it uses in the privacy policy before 10 Dec 2026. | [POLA Act 2024 Sch 1 Pt 15](https://www.legislation.gov.au/C2024A00128/asmade/2024-12-10/text/original/pdf) |

#### Claims language

| Acceptable (productivity / self-record framing) | Risks device classification or regulator/App Review action | Why |
|---|---|---|
| "Log your doses and see your own history" | "Tracks how well your medication is working" | Diary vs monitoring treatment effect ([MHRA](https://assets.publishing.service.gov.uk/media/64a7d22d7a4c230013bba33c/Medical_device_stand-alone_software_including_apps__including_IVDMDs_.pdf); [TGA diary precedent](https://cmcmedicaldevices.com/wp-content/uploads/2025/08/understanding-regulation-of-software-based-medical-devices-tga-27082025.pdf)) |
| "Reminders at the times you choose" | "We'll tell you when your next dose is due" / "Smart dose reminders" | User-configured vs app-determined timing ([FDA item 11](https://www.fda.gov/medical-devices/device-software-functions-including-mobile-medical-applications/examples-software-functions-which-fda-will-exercise-enforcement-discretion)) |
| "Plan your day around when you usually feel most focused, based on your check-ins" | "Optimises your medication" / "Find your optimal dose timing" | Influences "time of treatment" ([MHRA](https://assets.publishing.service.gov.uk/media/64a7d22d7a4c230013bba33c/Medical_device_stand-alone_software_including_apps__including_IVDMDs_.pdf)) |
| "Your focus pattern (from what you've logged)" | "Tells you when your dose wears off" / "Predicts your medication wear-off" / "Personal pharmacokinetic curve" | "Predicts", "Pharmacokinetic" are MHRA indicative words; prediction for treatment ([MHRA](https://assets.publishing.service.gov.uk/media/64a7d22d7a4c230013bba33c/Medical_device_stand-alone_software_including_apps__including_IVDMDs_.pdf)) |
| "Schedules your hardest tasks into your best focus hours" | "Know exactly when to take your booster" / "Booster recommendations" | Specific treatment suggestion ([HSF/TGA](https://www.hsfkramer.com/insights/2021-06/regulatory-reform-for-software-based-consumer-health-can-rules-keep-up-with-reality); [MDCG dose-recommendation examples](https://health.ec.europa.eu/document/download/b45335c5-1679-4c71-a91c-fc7a4d37f12b_en?filename=mdcg_2019_11_en.pdf)) |
| "A planner designed with ADHD brains in mind" (amber: audience reference, no symptom claim) | "Treats / manages / reduces ADHD symptoms", "Clinically proven for ADHD" | Disease/treatment claim ([FDA 2026 wellness](https://www.faegredrinker.com/en/insights/publications/2026/1/key-updates-in-fdas-2026-general-wellness-and-clinical-decision-support-software-guidance); [Apple 1.4.1 validation](https://developer.apple.com/app-store/review/guidelines/)) |
| "See your sleep and activity next to your plan" | "Detects medication crashes / rebound" / "Alerts you if your heart rate is too high on your meds" | Detects/alerts tied to condition or treatment ([Covington](https://www.cov.com/en/news-and-insights/insights/2026/01/fda-issues-revised-guidance-on-general-wellness-products); [TGA wellness](https://www.tga.gov.au/resources/guidance/understanding-general-health-or-wellness-software-exclusion)) |
| "Did I already log it? Check your last entry at a glance" | "Prevents overdose" / "Tells you if it's safe to take another" | Safety/treatment decision claim (inference; [MedlinePlus](https://medlineplus.gov/druginfo/meds/a682188.html)) |
| "Export your log to share with your doctor if you choose" (amber) | "Doctor-ready medication effectiveness report" / "Helps your psychiatrist adjust your dose" | Clinical-use intent removes wellness exclusion ([TGA wellness "clinical practice"](https://www.tga.gov.au/resources/guidance/understanding-general-health-or-wellness-software-exclusion); [FDA CDS](https://www.faegredrinker.com/en/insights/publications/2026/1/key-updates-in-fdas-2026-general-wellness-and-clinical-decision-support-software-guidance)) |
| "AI helps turn screenshots and messages into tasks" | "AI health coach for your medication" / "Ask our AI about your meds" | LLM with medical purpose → developer is manufacturer; provider bans ([TGA](https://cmcmedicaldevices.com/wp-content/uploads/2025/08/understanding-regulation-of-software-based-medical-devices-tga-27082025.pdf); [Gemini terms](https://ai.google.dev/gemini-api/terms); [OpenAI policy](https://openai.com/policies/usage-policies/)) |
| "Your data is encrypted; health details are processed on your device where possible" | "100% private — your data never leaves your phone" (if any cloud call exists) | Deceptive privacy promise ([FTC GoodRx](https://www.ftc.gov/news-events/news/press-releases/2023/02/ftc-enforcement-action-bar-goodrx-sharing-consumers-sensitive-health-info-advertising)) |
| "Not medical advice — follow your prescription and ask your doctor or pharmacist" | "Use instead of checking with your doctor" | Apple 1.4.1 ([App Review](https://developer.apple.com/app-store/review/guidelines/)) |

### Inferences
- The app has one "red line" feature to hold back from any market: learned **dose/booster timing suggestions**. That feature alone moves the product from wellness/productivity into SaMD in AU, US, UK and EU. It would need TGA ARTG inclusion, FDA clearance, UKCA/CE marking and, under the Gemini terms, is barred outright. It would also likely fail App Review under 1.4.2.
- The inferred focus window is health data under MHMDA, GDPR and ICO inference rules, and likely under the Privacy Act definition of health information. Treat it with the same consent and minimisation as the dose log.
- Launch order AU → US → UK/NZ → EU works if the build is compliant with the strictest element of each rule set from day one. That means MHMDA-style opt-in, GDPR explicit consent, Apple 5.1.2(i), and on-device processing of health context.

### Gaps
- All rules above need jurisdiction-specific legal review. The exact TGA exclusion wording and Tranche 2 status are the main Australian unknowns.
- No regulator pre-submission or advisory opinion exists for a "self-reported medication-effect-window scheduler"; the classification line here is reasoned from analogous guidance.
