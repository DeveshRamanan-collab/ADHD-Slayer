# ADHD planner / medication-tracking / AI-scheduling apps: competitive landscape, gaps, failure modes and mitigations (research date 28 Sep 2026)

Scope note: covers the competitive and failure-mode side for a new iPhone/Apple Watch ADHD app (medication-window tracking, AI auto-scheduling into Apple Calendar/Reminders, behavioural learning, term-time vs holiday "Lifestyle" toggle), launching in Australia and then the US/UK. Ratings come from Apple's iTunes Lookup API (AU and US storefronts, fetched 28 Sep 2026) unless stated otherwise. Prices are USD unless marked A$. No AUD conversion rate was sourced, so USD figures are not converted.

Pages that could not be read (so their claims are NOT used): Europe PMC search for ADHD-app engagement studies (proxy 429 rate-limit); Reddit r/ADHD search (site blocked); NICE CKS ADHD prevalence (403); Macquarie University Accessibility Services page (403); TGA software-as-medical-device guidance (robots block); FTC Cerebral press release (404); the full JMIR/PMC text of Baumel et al. 2019 (empty/captcha, so a secondary summary is cited); App Store AU web pages for Structured and Llama Life (429/404; the Lookup API was used instead); iTunes Search API (robots). The shared session web-search budget ran out partway through, so later verification relied on direct fetches of known URLs.

---

## 1. Competitors: what each does, pricing, ratings, complaints, medication awareness

### Takeaway
The market is crowded at the "visual planner" layer (Tiimo, Structured, Finch, Routinery) and at the "AI auto-scheduler" layer (Motion, Reclaim, Sunsama, Akiflow, Morgen, FlowSavvy, Lifestack). **None of the planners or AI schedulers found models medication timing.** Tiimo, the 2025 iPhone App of the Year, is the most direct ADHD-branded competitor. Structured is the scale leader on iPhone (500K+ Pro subscribers claimed). Several major AI schedulers do not support Apple/iCloud Calendar at all (Reclaim, and Sunsama as listed).

### Cited Findings

**Tiimo (Copenhagen, ADHD/neurodivergent visual planner)**
- Won iPhone App of the Year in the 2025 App Store Awards. Tiimo's own page dates the announcement to 19 Nov 2025 — [Tiimo](https://www.tiimoapp.com/resource-hub/tiimo-winner-2025-app-store-awards). Wikipedia records the win as December 2025 — [Wikipedia](https://en.wikipedia.org/wiki/Tiimo). The date conflict is minor; the Nov date may be the finalist announcement. It was also a 2024 Apple Design Awards finalist — [Wikipedia](https://en.wikipedia.org/wiki/Tiimo).
- Features: AI Co-Planner for task breakdown and prioritisation, colour-coded visual timeline, calendar and Reminders sync, focus timer, widgets and Live Activities, Apple Watch app, Siri, photo-to-task, family profile sharing (up to 5), mood tracking — [App Store AU](https://apps.apple.com/au/app/tiimo-adhd-planner-focus/id1480220328); [Tiimo](https://www.tiimoapp.com/resource-hub/tiimo-winner-2025-app-store-awards).
- AI planner "considers effort, focus, and transitions" and suggests schedules that reflect "your real capacity". Learning of recurring patterns and energy-level adjustment over time are listed as **future** features. The page does not confirm that mood or medication feed the planner — [Tiimo AI planner](https://www.tiimoapp.com/resource-hub/ai-planner).
- Medication: not mentioned in the award page or the App Store listing — [Tiimo](https://www.tiimoapp.com/resource-hub/tiimo-winner-2025-app-store-awards); [App Store AU](https://apps.apple.com/au/app/tiimo-adhd-planner-focus/id1480220328).
- Pricing: free tier plus Pro. AU in-app purchases range A$9.00–A$66.00 — [App Store AU](https://apps.apple.com/au/app/tiimo-adhd-planner-focus/id1480220328). US in-app purchases range US$7–54 (Pro US$54) — [App Store US](https://apps.apple.com/us/app/tiimo-adhd-planner-focus/id1480220328). Premium is about US$10/month — [Wikipedia](https://en.wikipedia.org/wiki/Tiimo). The 7-day trial applies to annual plans only; monthly plans are charged immediately — [Tiimo pricing FAQ](https://www.tiimoapp.com/pricing).
- Ratings: AU 4.42 from 1,588 ratings; version 3.66.0 released 21 Sep 2026 — [iTunes Lookup AU](https://itunes.apple.com/lookup?id=1480220328,1499198946,1528183849,1628994767,1541078407,6746717689,1516036620,952895165&country=au). US 4.59 from 20,231 ratings — [iTunes Lookup US](https://itunes.apple.com/lookup?id=6454469750,6449003064,1480220328,1499198946&country=us).
- Funding and traction: US$4.8M total pre-Series A (US$3.2M seed in 2022, US$1.6M in Aug 2024). 500K+ free users and 50K+ paying subscribers as of Aug 2024. "More than 3 out of 4" paying subscribers identify as neurodivergent — [Tiimo](https://www.tiimoapp.com/resource-hub/tiimo-raises-4-8m-neurodivergent-planner). Founded 2015 — [Wikipedia](https://en.wikipedia.org/wiki/Tiimo).
- Complaints:
  - AU: "layout and features change OFTEN which can be unsettling and confusing"; users want a week/month overview; better routine editing requested — [App Store AU](https://apps.apple.com/au/app/tiimo-adhd-planner-focus/id1480220328).
  - US: notification "quick ding isn't enough"; minute-by-minute structure too rigid (users want unscheduled, duration-only tasks); "Tiimo likes to log me out of the app on my Apple Watch randomly"; updates described as "one step forward and two steps back"; widget access problems — [App Store US](https://apps.apple.com/us/app/tiimo-adhd-planner-focus/id1480220328).
  - Timer glitches, sync issues, no note storage — [Saner.ai (competitor blog)](https://www.saner.ai/blogs/best-adhd-apps).

**Structured (unorderly GmbH, visual day timeline)**
- Ratings: AU 4.74 from 14,796; US 4.79 from 166,591 via the API — [iTunes Lookup AU](https://itunes.apple.com/lookup?id=1480220328,1499198946,1528183849,1628994767,1541078407,6746717689,1516036620,952895165&country=au); [iTunes Lookup US](https://itunes.apple.com/lookup?id=6454469750,6449003064,1480220328,1499198946&country=us). The US web listing showed "25.3K" ratings, a different count basis — [App Store US](https://apps.apple.com/us/app/structured-daily-planner/id1499198946).
- Claims 15M+ downloads, 500K+ Pro subscribers, 1M+ active planners, 30+ languages, a team of about 11 — [Structured](https://www.structured.app/).
- Pro features: AI natural-language task entry, integration with all calendars, reminder customisation, recurring tasks. Also available: monthly, yearly and lifetime Pro; a "scholarship" option praised by a reviewer as an alternative to subscription paywalls; VoiceOver and dyslexia-friendly font. No medication features — [App Store US](https://apps.apple.com/us/app/structured-daily-planner/id1499198946).
- Exact AUD/USD Pro prices were not captured (see Gaps).

**Inflow (UK; CBT-based ADHD programme)**
- CBT modules, AI companion "Quinn" for task breakdown, live body doubling, community — [App Store US](https://apps.apple.com/us/app/inflow-manage-your-adhd/id1528183849).
- US in-app purchases: US$29.99/month; US$22.49/month without coaching; US$199.99 for 6 months with coaching; US$95.99–199.99/year — [App Store US](https://apps.apple.com/us/app/inflow-manage-your-adhd/id1528183849). ChoosingTherapy lists US$47.99/month or US$199.99/year, older and conflicting — [ChoosingTherapy](https://www.choosingtherapy.com/best-adhd-apps/).
- Ratings: AU 4.24 from 417; US 4.37 from 5,621 — [Lookup AU](https://itunes.apple.com/lookup?id=1480220328,1499198946,1528183849,1628994767,1541078407,6746717689,1516036620,952895165&country=au); [Lookup US](https://itunes.apple.com/lookup?id=1628994767,1528183849,1541078407,573916946,1482581097,1528595748,572688855&country=us).
- Medication: explicitly excluded ("not a medical device") — [App Store US](https://apps.apple.com/us/app/inflow-manage-your-adhd/id1528183849).
- Complaints: accidental purchase of an annual subscription; "one week is not enough time" for the trial; library locked during the trial — [App Store US](https://apps.apple.com/us/app/inflow-manage-your-adhd/id1528183849).

**Numo (Mindist, Inc.; "Cringe-Free ADHD App" / "ADHD Brain Dump")**
- Gamified tasks ("Brain"), "Squad" community with points, coping-skills content. Multiple monthly and annual subscription SKUs — [App Store PK](https://apps.apple.com/pk/app/id1628994767).
- Ratings: AU 4.07 from 128; US 4.37 from 1,071 — [Lookup AU](https://itunes.apple.com/lookup?id=1480220328,1499198946,1528183849,1628994767,1541078407,6746717689,1516036620,952895165&country=au); [Lookup US](https://itunes.apple.com/lookup?id=1628994767,1528183849,1541078407,573916946,1482581097,1528595748,572688855&country=us). No medication features.

**Focus Bear (Focus Bear Pty Ltd — an Australian company)**
- Routines, distraction blocking ("AI-powered blocking"), Pomodoro, meeting detection. Runs on Mac, Windows and iOS; Android is waitlisted. Essentials tier is free; Pro is US$9.99/month with a 7-day no-card trial. No medication features — [Focus Bear](https://www.focusbear.io/pricing).

**Llama Life (Llama Life Pty Ltd — Australian founder Marie Ng)**
- One-task-at-a-time timed lists ("attention management"). Raised a A$950K pre-seed in Apr 2022 (Black Sheep Capital, Jason Calacanis/LAUNCH) — [Startup Daily](https://www.startupdaily.net/topic/funding/jason-calacanis-backs-australian-productivity-startup-llama-life-in-950000-pre-seed-raise/).
- iOS app "ADHD Organizer: Llama Life" released 7 Feb 2024. AU 4.97 from 31; US 4.50 from 117 — [Lookup AU](https://itunes.apple.com/lookup?id=6454469750,6449003064&country=au); [Lookup US](https://itunes.apple.com/lookup?id=6454469750,6449003064,1480220328,1499198946&country=us). Pricing not captured.

**Goblin Tools (Bram De Buyser / Skyhook)**
- AI micro-tools: Magic ToDo (task breakdown), Formalizer, Judge, Estimator, Compiler (brain dump to actions), Taskmaster, and others — [goblin.tools](https://goblin.tools/).
- Website free with no ads. Mobile apps are one-off purchases (A$2.99 AU; US$1.99 US). Pro subscription added "due to running costs"; existing free features "will never be locked behind a paywall" — [goblin.tools About](https://goblin.tools/About); [Lookup AU](https://itunes.apple.com/lookup?id=6454469750,6449003064&country=au).
- Ratings: AU 4.52 from 226; US 4.76 from 3,014 — [Lookup AU](https://itunes.apple.com/lookup?id=6454469750,6449003064&country=au); [Lookup US](https://itunes.apple.com/lookup?id=6454469750,6449003064,1480220328,1499198946&country=us). Results described as "hit-or-miss" — [Saner.ai](https://www.saner.ai/blogs/best-adhd-apps).

**Routinery (Riffmax, Korea)**
- Routine timer, habit stacking, audio guidance, watch support, MCP connection to ChatGPT/Claude. Claims 5M+ downloads; lifetime plan offered at 50% off — [Routinery](https://routinery.app/).
- US$4.19/month or US$30/year. Cons: "inconsistent notifications, lengthy initial setup" — [ChoosingTherapy](https://www.choosingtherapy.com/best-adhd-apps/). App Store rating not captured.

**Finch (self-care virtual pet)**
- Ratings: US 4.95 from 756,731; AU 30K+ ratings. AU in-app purchases A$8.49–99.99 — [Lookup US](https://itunes.apple.com/lookup?id=1628994767,1528183849,1541078407,573916946,1482581097,1528595748,572688855&country=us); [App Store AU](https://apps.apple.com/au/app/finch-self-care-pet/id1528595748).
- A reviewer values that it "doesn't have the kind of thing most apps do where you can only use for limited time then pay" — [App Store AU](https://apps.apple.com/au/app/finch-self-care-pet/id1528595748). Cons: feature overload, weak notifications — [Saner.ai](https://www.saner.ai/blogs/best-adhd-apps).

**Brili (Brili GmbH; adult and family routine apps)**
- "Dynamic routines" that adapt through the day; 30-day trial; price not shown. Blog activity runs only to Jul 2024, so maintenance cadence is uncertain — [Brili](https://brili.com/). No medication features.

**Lunatask (encrypted all-in-one)**
- Free tier; Premium US$6/month (annual) or US$8 (monthly); US$300 lifetime (not on the app stores); 50% student/teacher discount. Tracks mood, energy and stress; habits; WIP limits; auto-prioritisation — [Lunatask](https://lunatask.app/pricing). No medication-aware scheduling.

**Amazing Marvin**
- US$12/month or US$96/year — [Zapier](https://zapier.com/blog/adhd-to-do-list/). 14-day trial with no card, 50% student discount, "pay what you can" on request, no refunds — [Amazing Marvin](https://amazingmarvin.com/pricing/).

**Todoist**
- AU 4.74 from 10,992 — [Lookup AU](https://itunes.apple.com/lookup?id=572688855,573916946,1482581097&country=au). Pro about US$4/month; "no reminders on free plan" — [Saner.ai](https://www.saner.ai/blogs/best-adhd-apps). "Lacks ADHD-specific features" — [ChoosingTherapy](https://www.choosingtherapy.com/best-adhd-apps/).

**Sunsama (guided daily planning)**
- US$25/month or US$20/month annual; 14-day trial with no card. Integrations listed are Google Calendar and Outlook; iCloud is not listed — [Sunsama pricing](https://www.sunsama.com/pricing); [Sunsama](https://www.sunsama.com/). "Setup complexity" noted — [Saner.ai](https://www.saner.ai/blogs/best-adhd-apps).

**Motion (AI auto-scheduler, now "AI employees"/project management)**
- The current pricing page lists Pro AI at US$19/seat/month (7,500 credits) and Business AI at US$29/seat/month; annual billing "save 33%"; Apple Calendar not mentioned — [Motion pricing](https://www.usemotion.com/pricing).
- This **conflicts** with Saner.ai's 2026 review: US$49/month monthly or US$29/month annual, no free plan, 7-day trial that auto-converts — [Saner.ai Motion review](https://www.saner.ai/blogs/motion-reviews). Saner is a competitor.
- Complaints:
  - Days packed with "no breathing room"; "double-booked meetings" and "calendar sync issues"; "janky/crusty/clunky" UI; mobile app "a stripped-down afterthought"; "pricing has increased a few times" — [Saner.ai Motion review](https://www.saner.ai/blogs/motion-reviews).
  - Trustpilot 3.7/5 from 578 reviews. Themes: charges after cancelling or after trials ("charged a whole year in advance"), refund refusals, "The AI hallucinates a lot and give you too many action items", "a full-time job just adding data into the system". The company replied to only 11% of negative reviews — [Trustpilot](https://www.trustpilot.com/review/www.usemotion.com).

**Reclaim.ai (AI habits/focus-time defender)**
- Lite tier is free (1-week scheduling range, 1 calendar). Starter US$10/month annual (US$12 monthly); Business US$15/US$18; Enterprise US$22. Supports Google and Outlook only; **no Apple/iCloud** — [Reclaim pricing](https://reclaim.ai/pricing).
- G2 4.8 from 144 reviews. Cons: no mobile app; "poor calendar integration" (26 mentions); rescheduling struggles (25 mentions); "Kind of overwhelming seeing my calendar all booked with something every hour"; "a lot of settings; it's more sophisticated than intuitive" — [G2](https://www.g2.com/products/reclaim-ai/reviews).

**Akiflow**
- US$34/month or US$19/month annual; no free plan; 7-day trial requires a card. 40% lifetime student discount. AI assistant "Aki" plus MCP; AI meeting assistant is a US$19/month add-on — [Akiflow](https://akiflow.com/pricing).

**Morgen**
- US$30/month or US$15/month annual; 14-day no-card trial; 30-day money-back guarantee; 25% student discount. **Supports iCloud** as well as Google, Outlook and Fastmail — [Morgen](https://www.morgen.so/pricing).

**FlowSavvy**
- Free forever tier (2-week horizon, 3 repeating auto-scheduled tasks). Pro US$14/month or US$10/month annual. Two-way sync with Google, Outlook and **iCloud**; web, iOS and Android apps. Pro includes "unlimited scheduling hours profiles", overcommitment warnings and buffer/travel time — [FlowSavvy](https://flowsavvy.app/pricing).

**Lifestack**
- Energy-based scheduling ("Energy Zones") that "reads your sleep, recovery, and focus" from Apple Health, WHOOP and Oura. Runs on iPhone, Mac, Android and Chrome; pricing not shown; no medication input — [Lifestack](https://lifestack.ai/).

**Saner.ai**
- AI notes/tasks/inbox assistant for web and Chrome. Free; Starter US$8/month (US$6 annual); Standard US$16 (US$12 annual) — [Saner.ai](https://www.saner.ai/blogs/best-adhd-apps).

**Clockwise — shut down**
- Clockwise (a 10-year-old AI calendar assistant) was acqui-hired by Salesforce and shut down on 27 Mar 2026, with one week's notice announced 20 Mar 2026. The CEO apologised for the "short notice" — [The Stack](https://www.thestack.technology/clockwises-team-joins-salesforce-sunsetting-platform-as-they-go/).

**Shimmer (human ADHD coaching)**
- US$45/week for the first 4 weeks, then US$60/week billed every 4 weeks (about US$240/month). Weekly 30-minute 1:1 sessions, daily body doubling, 30-day money-back guarantee. Claims 83% report better ADHD management in 6 weeks (self-reported, unaudited) — [Shimmer](https://www.shimmer.care/cost).

**EndeavorOTC (Akili)**
- US$24.99/month or US$129.99/year; no free trial — [ChoosingTherapy](https://www.choosingtherapy.com/best-adhd-apps/).

**Newer AI entrants (2024–2026)**
- Carly AI (email-based AI assistant, US$35+/month, 2026) is the only 2026 launch found in the vendor's own list. That list states: "None of the tools discussed reference medication timing or energy-level adaptation" — [Carly (vendor)](https://www.usecarly.com/blog/best-ai-personal-assistant-adhd/).
- Saner.ai's 2026 test of 44 apps: "No apps discuss prescription medication integration" — [Saner.ai](https://www.saner.ai/blogs/best-adhd-apps).
- The search budget ran out before a wider scan of new AI ADHD assistants (e.g. neurolist on Google Play, seen only as a search result) could be completed.

### Comparison table

| App | Category | Platforms | Price (captured) | Rating (store, count) | Medication-aware? | Learns from user? | Key complaint |
|---|---|---|---|---|---|---|---|
| Tiimo | ADHD visual planner + AI co-planner | iOS, watchOS, Android, web | Free; Pro A$9–66 IAP (AU); ~US$10/mo; trial annual-only | AU 4.42 (1,588); US 4.59 (20,231) | No | Partial (capacity-aware suggestions; pattern learning "future") | Frequent UI changes; Watch logout; weak alerts; rigid minute blocks |
| Structured | Visual timeline planner | iOS, watchOS, web | Free; Pro monthly/yearly/lifetime (prices not captured); scholarship | AU 4.74 (14,796); US 4.79 (166,591) | No | No evidence (AI = NL parsing) | None visible in listing |
| Inflow | CBT programme + AI companion + body doubling | iOS, Android | US$29.99/mo; US$95.99–199.99/yr | AU 4.24 (417); US 4.37 (5,621) | No (explicit disclaimer) | No evidence | Cost; 1-week trial too short; accidental annual purchase |
| Numo | ADHD community/gamified tasks | iOS, Android | Subscriptions (AUD not captured) | AU 4.07 (128); US 4.37 (1,071) | No | No evidence | Not captured |
| Focus Bear (AU) | Routines + blocking | Mac, Win, iOS (Android waitlist) | Free; Pro US$9.99/mo | Not captured | No | "AI-powered blocking" | Not captured |
| Llama Life (AU) | One-task timer list | Web, iOS, Android | Not captured | AU 4.97 (31); US 4.50 (117) | No | No | Not captured |
| Goblin Tools | AI micro-tools (task breakdown) | Web, iOS, Android | Web free; app A$2.99 one-off; Pro sub | AU 4.52 (226); US 4.76 (3,014) | No | No | "Hit-or-miss" output |
| Routinery | Routine timer | iOS, Android, watch | US$4.19/mo or US$30/yr; lifetime | Not captured (5M+ downloads) | No | No | Inconsistent notifications; long setup |
| Finch | Self-care pet/habits | iOS, Android | Free; Plus A$8.49–99.99 IAP | US 4.95 (756,731); AU 4.9 (30K+) | No | No | Weak notifications; feature overload |
| Brili | Adult/family routines | iOS, Android | 30-day trial; price not shown | Not captured | No | "Dynamic" routines | Maintenance uncertain |
| Lunatask | Encrypted all-in-one (mood/energy) | Win, mac, Linux, iOS, Android | Free; US$6–8/mo; US$300 lifetime | Not captured | No (tracks energy, not meds) | No evidence | Not captured |
| Amazing Marvin | Customisable ADHD-friendly tasks | Multi | US$12/mo or US$96/yr | Not captured | No | No | Not captured |
| Todoist | General to-do | All | Free; Pro ~US$4/mo | AU 4.74 (10,992) | No | No | Not ADHD-specific; no reminders on free plan |
| Sunsama | Guided daily planning | Web, desktop, iOS | US$25/mo; US$20/mo annual | Not captured | No | No | Setup complexity; iCloud not listed |
| Motion | AI auto-scheduler / PM | Web, desktop, mobile | US$19–29/seat/mo (pricing page) vs US$49/mo (Saner) | Trustpilot 3.7 (578) | No | Auto-reschedules; no personal learning shown | Overpacked days; billing/auto-renew; hallucinations; weak mobile |
| Reclaim.ai | AI habits/focus defender | Google/Outlook; no mobile app | Free; US$10–22/mo | G2 4.8 (144) | No | Adaptive habit placement | No mobile app; calendar clutter; no iCloud |
| Akiflow | Inbox + time-blocking | Desktop, mobile | US$34/mo; US$19/mo annual; no free plan | Not captured | No | No | Not captured (no free plan) |
| Morgen | Calendar + AI planner | Desktop, mobile; iCloud supported | US$30/mo; US$15/mo annual | Not captured | No | No evidence | Not captured |
| FlowSavvy | Auto-scheduler | Web, iOS, Android; iCloud supported | Free; Pro US$10–14/mo | Not captured | No | No | Not captured |
| Lifestack | Energy/wearable-based scheduling | iPhone, Mac, Android, Chrome | Not shown | Not captured | No (sleep/recovery, not meds) | Yes (energy from wearables) | Not captured |
| Saner.ai | AI notes/tasks assistant | Web, Chrome | Free; US$6–16/mo | Not captured | No | "Proactive" | Requires internet |
| Clockwise | AI calendar optimiser | — | Shut down 27 Mar 2026 | — | — | — | 1-week shutdown notice |
| Shimmer | Human ADHD coaching | App + video | ~US$240/4 weeks | Not captured | No | Human coach | Cost |
| Apple Health Medications | Med log/reminders | iOS 16+, watchOS | Free (built in) | n/a | Logs doses; no effect window | No | No effect-curve modelling |
| Medisafe | Med reminders | iOS, Android | Free (2 meds, ads); Premium US$4.99/mo | AU 4.63 (6,907); US 4.71 (101,395) | Reminders only | No | Not captured |
| MyTherapy | Med reminders + vitals | iOS, Android | Free (ads) | AU 4.66 (636) | Reminders only | No | Not captured |
| Bearable | Symptom/mood tracker | iOS, Android | US$6.99/mo; US$34.99/yr | AU 4.72 (442); US 4.77 (6,380) | Logging (correlation features unverified) | Unverified | Not captured |
| Daylio | Mood journal | iOS, Android | Free + IAP | AU 4.68 (6,888) | No | No | Not captured |
| Theraview | ADHD med onset/wear-off visualiser | iOS, Android | Free, no IAP | AU 4.96 (52); US 4.90 (328) | **Yes** (curve + wear-off alerts) | Manual "metabolic rate" setting | Last iOS update Aug 2023; 9 meds only |
| Pillr | ADHD med tracker | iOS | Free; Premium US$14.99 | AU 5.0 (5) | **Yes** (opening/active/fading; wear-off alerts) | No | Tiny user base |
| Medly | ADHD meds + mood | iOS | US$3.99/wk; US$24.99/yr | No ratings yet | **Yes** (effect curve) | Weekly trends | Update cadence unclear |
| FocusCurve | ADHD med + caffeine PK curves | iOS 17+ | Plus monthly/annual/lifetime (prices not shown) | Not captured | **Yes** (50+ formulations) | No (population kinetics) | Not captured |
| EndeavorOTC | Digital-therapeutic game | iOS, Android | US$24.99/mo; US$129.99/yr | ChoosingTherapy 4/5 | No | — | No trial |

### Inferences
- Tiimo is the direct threat: it is ADHD-branded, Apple-favoured, and already has AI co-planning, Watch support and Reminders sync. Its "learning" roadmap (patterns, energy) overlaps the planned behavioural learning. Medication is the clearest point of difference.
- Among the AI schedulers, native Apple Calendar/Reminders support is uneven. Reclaim is Google/Outlook-only, Sunsama lists no iCloud, and Motion does not state it. That leaves an Apple-native, Watch-first niche; Morgen, FlowSavvy, Structured and Tiimo partly contest it.
- The AU store is small. AU rating counts are about 7–9% of US counts for Tiimo (1,588 vs 20,231) and Structured (14,796 vs 166,591), so AU-only traction will look thin.

### Gaps
- Exact AUD prices for Structured Pro, Llama Life, Routinery, Numo and Focus Bear (AU web listings rate-limited).
- App Store ratings for Routinery, Focus Bear, Sunsama, Motion, Akiflow, Morgen, FlowSavvy, Lifestack, Lunatask, Marvin and Round Health (IDs not found once the search budget ran out).
- Round Health status and pricing (its site returned an empty page).
- Reddit complaint mining (blocked).

---

## 2. Gaps nobody fills, especially medication-aware scheduling

### Takeaway
Two separate product classes exist, and nothing found joins them:
- **ADHD medication-effect trackers** (Theraview, Pillr, Medly, FocusCurve) visualise onset, peak and wear-off, but none schedules tasks or writes to a calendar.
- **Planners/AI schedulers** schedule tasks but ignore medication.

Apple's WWDC25 HealthKit Medications API now lets a third-party app read dose events that users log in Apple Health. The "log once in Health, then auto-plan around the effect window" loop is technically newly feasible.

### Cited Findings
- **Theraview** visualises when stimulants "kick in and wear off", with customisable metabolic rate, wear-off notifications, sleep-time estimates, side-effect/mood notes and a parent mode. It supports 9 medications. Latest iOS version is 5, dated 20 Aug 2023 — [App Store US](https://apps.apple.com/us/app/theraview-track-adhd-meds/id1541078407); [Lookup AU](https://itunes.apple.com/lookup?id=1480220328,1499198946,1528183849,1628994767,1541078407,6746717689,1516036620,952895165&country=au).
- **Pillr** shows an "estimated stimulant window" (opening, active, fading), optional wear-off alerts, a 24-hour med timeline, appointment prep and transcription. On-device, no account; Premium US$14.99. AU 5.0 from 5 ratings; last update 14 Sep 2026 — [App Store US](https://apps.apple.com/us/app/pillr-adhd-medication-tracker/id6746717689); [Lookup AU](https://itunes.apple.com/lookup?id=1480220328,1499198946,1528183849,1628994767,1541078407,6746717689,1516036620,952895165&country=au).
- **Medly** tracks an effect curve (builds, peaks, wears off) plus a 4-question mood check-in and weekly trends; US$3.99/week or US$24.99/year — [App Store CA](https://apps.apple.com/ca/app/medly-adhd-meds-mood-tracker/id6758928146). The listing's release/update dates (Mar/Jun 2024) look inconsistent with the app ID range, so treat them as unverified.
- **FocusCurve** (iOS 17+) supports 50+ formulations with "formulation-aware kinetics" (IR/XR/OROS/prodrug), overlays caffeine, and helps users "anticipate the afternoon dip" and plan bedtime around clearance. It also has refill alerts and a clinician PDF export, and is 100% on-device. It does **not** schedule tasks; it visualises after manual logging — [FocusCurve](https://focuscurve.app/).
- Generic med apps (Medisafe, MyTherapy, Pillo, Dosecast, Round Health) do not track effect. Only Theraview does, according to a vendor-written comparison. That vendor, Pause Moment, is itself an Android app that locks the screen for reminders — [Pause Moment (vendor)](https://pause-moment.com/best-adhd-medication-reminder-apps-2026/).
- **Apple Health Medications** (iOS 16+, iPhone and Watch) tracks medicines, sets reminders and warns of interactions — [Wikipedia](https://en.wikipedia.org/wiki/Health_(Apple)).
- **HealthKit Medications API** (WWDC25) gives read-only access to `HKUserAnnotatedMedication` and to `HKMedicationDoseEvent`. Dose events carry log status (taken/skipped/snoozed), scheduled and logged timestamps, and quantities. Authorisation is per medication; new medications prompt users to choose which apps can see them. Apps cannot write — [Apple WWDC25 session 321](https://developer.apple.com/videos/play/wwdc2025/321/).
- **Energy-aware scheduling** exists without medication. Lifestack uses sleep and recovery from Apple Health, WHOOP and Oura — [Lifestack](https://lifestack.ai/). Lunatask tracks energy and stress — [Lunatask](https://lunatask.app/pricing).
- **Schedule "profiles"** (closest analogue to a term-time/holiday Lifestyle toggle): FlowSavvy Pro offers "unlimited scheduling hours profiles" — [FlowSavvy](https://flowsavvy.app/pricing). No competitor was found with an explicit term/holiday mode.
- Vendor round-ups in 2026 found no medication integration in any ADHD planner or AI assistant — [Saner.ai](https://www.saner.ai/blogs/best-adhd-apps); [Carly](https://www.usecarly.com/blog/best-ai-personal-assistant-adhd/).

### Inferences
- The defensible gap is medication-window-aware auto-scheduling with a personalised curve. Users would log onset and wear-off with Watch taps; the population PK curve (as in FocusCurve) would be updated from those taps; then demanding tasks would be placed in the peak window and admin or low-demand tasks in the tail.
- HealthKit dose events could remove duplicate logging for users who already use Apple Health Medications. This is a real friction reducer that none of the specialist trackers appears to use.
- Other unfilled niches: an academic-calendar-aware Lifestyle toggle (term vs holidays), and Apple-native write-back to Calendar and Reminders with Watch-first interaction.

### Gaps
- Whether any app already combines HealthKit dose events with scheduling. None was found, but the search budget ran out before an exhaustive App Store scan.
- The iOS version required by the Medications API (believed to be iOS 26, not confirmed in the fetched transcript).

---

## 3. Retention, conversion and subscription evidence

### Takeaway
Median real-world 30-day retention for mental-health apps is about 3%. AI apps churn faster than non-AI apps. Hard paywalls convert about 5× better than freemium. Longer trials (17–32 days) convert far better than short ones. Health & Fitness users prefer annual plans but refund more.

### Cited Findings
- Baumel et al. 2019 (JMIR; 93 mental-health apps, panel data): median 4% of 30-day installers open the app on a given day; median 13 minutes/day. **Median retention is 3.9% at day 15 and 3.3% at day 30.** Peer-support apps show the highest daily use (35 min) — [National Elf Service summary](https://www.nationalelfservice.net/mental-health/digital-mental-health-tool-ignore-trial-read-analytics/). Original: [JMIR](https://www.jmir.org/2019/9/e14567/) (full text did not render; figures come from the summary).
- RevenueCat 2026 (115K+ apps, US$16B revenue):
  - Day-35 conversion: hard paywall median 10.7% vs freemium 2.1%. Revenue per install at day 60: US$3.09 vs US$0.38.
  - Trials of 17–32 days convert 42.5% vs 25.5% for trials under 4 days. 55.4% of 3-day-trial cancellations happen on Day 0.
  - About 72% of annual subscribers cancel within year 1 (up from 56% in 2025); 35% of annual cancellations happen in month 1.
  - **AI apps retain 36% worse over 12 months** but show a 41% higher year-1 LTV (US$30.16 vs US$21.37).
  - Billing failures cause 14% of App Store cancellations.
  - Source: [RevenueCat 2026](https://www.revenuecat.com/blog/growth/subscription-app-trends-benchmarks-2026).
  - Contradiction: the same source shows year-1 retention of annual subscribers at 27% (hard paywall) vs 28% (freemium), which does not fit a simple "72% cancel" reading. The two figures likely use different cohorts.
- RevenueCat 2025, Health & Fitness: median trial conversion 39.9% (top decile 68.3%); refund rate 4.71% ("among the highest"); annual plans are 67% of subscriptions sold. There is no AU-specific cut — [RevenueCat 2025](https://www.revenuecat.com/state-of-subscription-apps-2025).
- Adapty 2026, Health & Fitness: install-to-trial 11.2% (North America 14.5%); trial-to-paid 42.2% (weekly plans with trials); install-to-paid about 3.7%; first renewal 59.2%, second 45.1%. Annual plans were 61% of H&F revenue in 2025. High-priced annual plans generate about 4× the LTV of low-priced ones — [Adapty](https://adapty.io/blog/health-fitness-app-subscription-benchmarks/).
- ADHD-user signals on subscriptions (sourced from reviews and pricing pages, not Reddit):
  - Finch reviewer praises not being time-limited then paywalled — [App Store AU](https://apps.apple.com/au/app/finch-self-care-pet/id1528595748).
  - Structured reviewer contrasts the scholarship with other apps' paywalls — [App Store US](https://apps.apple.com/us/app/structured-daily-planner/id1499198946).
  - Inflow reviewer says a 1-week trial is too short — [App Store US](https://apps.apple.com/us/app/inflow-manage-your-adhd/id1528183849).
  - Motion billing complaints — [Trustpilot](https://www.trustpilot.com/review/www.usemotion.com).
  - Sliding-scale schemes: Bearable Heroes sponsorship — [Bearable](https://bearable.app/pricing/); Marvin "pay what you can" — [Amazing Marvin](https://amazingmarvin.com/pricing/).
- ADHD users show "shiny object syndrome" (repeatedly downloading new apps); apps are either too simple or so complex "we get overwhelmed and distracted" — [Zapier](https://zapier.com/blog/adhd-to-do-list/).

### Inferences
- Expect D30 retention in the low single digits unless value is delivered passively (Watch complications, Live Activities, calendar entries), so it does not depend on opening the app.
- Behavioural learning needs weeks of data. A 3–7-day trial will end before the app's main value appears. RevenueCat's trial-length data supports a 14–30-day trial.

### Gaps
- ADHD-specific app retention and abandonment studies (Europe PMC search was rate-limited).
- Direct Reddit/r/ADHD quotes on the "ADHD tax" and subscriptions (Reddit blocked).
- Australian conversion and pricing benchmarks (not broken out in RevenueCat or Adapty).

---

## 4. Failure modes of AI auto-schedulers and LLM assistants, and LLM cost per user

### Takeaway
Documented failures cluster into four groups:
1. Over-packed calendars and clutter.
2. Sync and double-booking bugs.
3. Complexity and setup burden.
4. AI hallucination.

Algorithm-aversion research predicts that one visible bad move damages trust out of proportion. LLM cost per active user is small on cheap models, around US$0.10–1/month, but material on mid-tier models (about US$2) relative to an A$10-ish subscription. On-device Apple Foundation Models inference is free.

### Cited Findings
- Motion packs days with "no breathing room"; "double-booked meetings", "calendar sync issues", steep onboarding, weak mobile app — [Saner.ai](https://www.saner.ai/blogs/motion-reviews). "The AI hallucinates a lot and give you too many action items" — [Trustpilot](https://www.trustpilot.com/review/www.usemotion.com).
- Reclaim: "overwhelming seeing my calendar all booked with something every hour"; 26 reviews cite poor calendar integration and 25 cite rescheduling struggles; settings complexity — [G2](https://www.g2.com/products/reclaim-ai/reviews).
- Tiimo users object to rigid minute-by-minute planning and want unscheduled, duration-only tasks — [App Store US](https://apps.apple.com/us/app/tiimo-adhd-planner-focus/id1480220328).
- Algorithm aversion: people "more quickly lose confidence in algorithmic than human forecasters after seeing them make the same mistake", and so avoid a superior algorithm — Dietvorst, Simmons & Massey 2015, *J Exp Psych: General* — [Europe PMC record](https://www.ebi.ac.uk/europepmc/webservices/rest/search?query=DOI:10.1037/xge0000033&resultType=core&format=json) (DOI 10.1037/xge0000033).
- Platform risk: Clockwise shut down with one week's notice after its Salesforce acqui-hire — [The Stack](https://www.thestack.technology/clockwises-team-joins-salesforce-sunsetting-platform-as-they-go/).
- Apple Calendar/Reminders constraints (EventKit, iOS 17+):
  - Events offer full access or write-only access; **reading existing events to schedule around them requires full access**.
  - Reminders offer full access only.
  - Separate Info.plist usage strings are required for each.
  - Source: [Create with Swift](https://www.createwithswift.com/getting-access-to-the-users-calendar/).
- LLM prices (Sep 2026, per 1M tokens):
  - Claude Haiku 4.5: US$1 in / US$5 out. Sonnet 5: US$2 / US$10. Opus 5.5: US$4 / US$20.
  - Cache reads at 0.1× input; Batch API 50% off.
  - Source: [Anthropic pricing](https://platform.claude.com/docs/en/about-claude/pricing).
  - OpenAI: GPT-6 Luna US$0.10 in / US$0.50 out ($0.01 cached); GPT-6 Sol US$2 / US$10; GPT-6 Astra US$10 / US$50 — [OpenAI pricing](https://developers.openai.com/api/docs/pricing).
- Apple Foundation Models framework: an on-device ~3B-parameter model with "AI inference that is free of cost", working offline and privately. It requires an Apple Intelligence-capable device with Apple Intelligence enabled on iOS 26+; availability varies by region and language. Already used by Stuff, Streaks and OmniFocus — [Apple Newsroom](https://www.apple.com/newsroom/2025/09/apples-foundation-models-framework-unlocks-new-intelligent-app-experiences/).
- Goblin Tools added a paid Pro tier because of running costs — [goblin.tools About](https://goblin.tools/About).

### Inferences
**LLM cost per active user per month.** These are my own assumptions, not sourced.

Usage model for a heavy user:
- 1 daily plan call at about 4K tokens in / 0.8K out.
- About 5 brain-dump or parse calls per day at 1.5K in / 0.3K out.
- About 2 replans per day at 3K in / 0.6K out.
- Total: about 525K input and 105K output tokens per month.

| Model | Heavy-user cost/month | Notes |
|---|---|---|
| Claude Haiku 4.5 | ≈ US$1.05 | ≈ US$0.75 with system-prompt caching |
| Claude Sonnet 5 / GPT-6 Sol | ≈ US$2.10 | |
| GPT-6 Luna | ≈ US$0.10 | |
| On-device Foundation Models | US$0 | |

A light user (about one third of the heavy volume) costs roughly US$0.35 on Haiku.

Against the revenue side: Apple takes 15% under the Small Business Program. On a ~A$10/month plan, a mid-tier model could consume a double-digit share of net revenue for heavy users, and every free-tier user is pure cost. Hybrid design follows from this: on-device parsing, deterministic scheduling, and cloud LLM calls only for weekly planning or explanations.

**Trust.** The combination of algorithm aversion and ADHD users' sensitivity to overload means that silently moving tasks, or over-filling the day, is the most likely trust-killer.

### Gaps
- Quantitative data on how many auto-scheduler users disable auto-rescheduling.
- LLM latency benchmarks (not fetched).
- An empirical hallucination rate for scheduling tasks.

---

## 5. Business failure and cautionary case studies

### Takeaway
Prescription and reimbursement-dependent ADHD digital therapeutics collapsed (Akili). ADHD telehealth-plus-medication businesses brought criminal and regulatory fallout (Done, Cerebral). Consumer ADHD planners survive with modest capital and slow growth: Tiimo took about 9 years to reach 50K paid subscribers.

### Cited Findings
- **Akili (EndeavorRx):**
  - FDA-cleared in 2020 as a video game for paediatric ADHD. SPAC listing at about US$1B in 2022; sold to Virtual Therapeutics for US$34M.
  - Failed to build a sustainable model from prescriptions; the pivot to direct-to-consumer did not work; commercial operations wound down in Apr 2024 in favour of a Shionogi licensing deal — [STAT](https://www.statnews.com/2024/05/29/virtual-therapeutics-acquire-akili-video-games-adhd/).
  - Deal completed 2 Jul 2024 at US$0.434/share. Layoffs of 30% (Jan 2023) and about 40% later in 2023; field sales and market access teams eliminated — [MassDevice](https://www.massdevice.com/virtual-therapeutics-acquires-akili/).
  - EndeavorOTC is priced at US$24.99/month — [ChoosingTherapy](https://www.choosingtherapy.com/best-adhd-apps/).
- **Done Global:**
  - Subscription telehealth with auto-refilled Adderall. Founder/CEO Ruthia He was sentenced on 7 Jul 2026 to 6 years plus a US$1M fine; clinical president David Brody to 2 years.
  - Scale: 37M+ pills; a US$90M scheme; US$40M+ spent on "deceptive" social-media advertising; clinicians paid up to US$60K/month — [US DOJ](https://www.justice.gov/opa/pr/founderceo-and-clinical-president-digital-health-company-sentenced-8-years-90-million-scheme).
  - CVS and Walmart stopped filling Done prescriptions in May 2022; Google and TikTok banned its ads in mid-2024; convictions on 18 Nov 2025 — [Wikipedia](https://en.wikipedia.org/wiki/Done_Global).
- **Cerebral:** stopped most controlled-substance prescribing to new patients in May 2022 amid Controlled Substances Act investigation; paid US$3.65M to resolve a DOJ probe in Nov 2024; two layoff rounds in 2022 — [Wikipedia](https://en.wikipedia.org/wiki/Cerebral_(company)). The FTC data-sharing settlement could not be verified (FTC page 404).
- **Tiimo:** founded 2015; €4.3M total funding by Aug 2024; 50K paid subscribers by Aug 2024 — [Wikipedia](https://en.wikipedia.org/wiki/Tiimo); [Tiimo](https://www.tiimoapp.com/resource-hub/tiimo-raises-4-8m-neurodivergent-planner).
- **Llama Life:** A$950K pre-seed (2022) — [Startup Daily](https://www.startupdaily.net/topic/funding/jason-calacanis-backs-australian-productivity-startup-llama-life-in-950000-pre-seed-raise/).
- **Clockwise:** a decade-old scheduler shut down with one week's notice after an acqui-hire — [The Stack](https://www.thestack.technology/clockwises-team-joins-salesforce-sunsetting-platform-as-they-go/).
- **Theraview and Medly:** effectively stalled update cadence (last iOS updates in 2023 and possibly 2024) — [Lookup AU](https://itunes.apple.com/lookup?id=1480220328,1499198946,1528183849,1628994767,1541078407,6746717689,1516036620,952895165&country=au); [App Store CA](https://apps.apple.com/ca/app/medly-adhd-meds-mood-tracker/id6758928146).

### Inferences
- Stay a consumer productivity tool. Avoid prescribing, telehealth tie-ins and "treatment" claims, which also sidesteps reimbursement dependence.
- Medication-adjacent marketing must avoid any appearance of promoting stimulant use, given the Done/Cerebral backlash and platform ad bans.

### Gaps
- Inflow and Sunsama funding and financials (not fetched).
- Pear Therapeutics bankruptcy details (Wikipedia fetch failed: "cache-only").
- ADHD app startups that shut down in 2022–2026 beyond Clockwise, Akili and Done (search budget exhausted).

---

## 6. Market size: Australia, US, UK

### Takeaway
- **Australia:** about 600K people dispensed ADHD medication in 2023–24, and the medicated population is growing fast, with adults now about half of new starts. That is a meaningful but small TAM.
- **US:** 15.5M adults with current ADHD, a third on stimulants.
- **UK:** about 1.9M adults (charity estimate).

### Cited Findings
- **AU (AIHW):** 2023–24 had 4.6M+ PBS/RPBS ADHD prescriptions for nearly 600,000 patients (22 per 1,000 people, up from 2 per 1,000 in 2004–05). The rate rose from 8 to 22 per 1,000 between 2018–19 and 2023–24. Psychostimulants are 87% of scripts. Adult females now exceed males in the 18–24 and 25–44 age groups. Use is 2.5× higher in the least vs most disadvantaged quintile — [AIHW](https://www.aihw.gov.au/mental-health/topic-areas/mental-health-prescriptions/adhd-medications-dispensed-overtime).
- **AU (PBS DUSC Sep 2023):**
  - Prescription growth averaged just under 18%/yr from 2013–14, and just over 25%/yr from 2019–20 to 2022–23.
  - Adults were 49.9% of newly initiated patients in 2022–23 (32.8% in 2019–20) and 44.6% of prevalent patients.
  - Adult lisdexamfetamine patients went from 10,195 (2019–20) to 59,308 (2021–22) after the Feb 2021 listing.
  - Source: [PBS DUSC](https://www.pbs.gov.au/industry/listing/participants/public-release-docs/2023-09/Lisdexamfetamine-review-DUSC-PRD-2023-09).
- **AU prevalence:** about 814,500 people with ADHD, of whom about 533,300 are adults aged 20+. Annual cost A$20.4B, 81% of the financial cost being productivity losses (Deloitte 2019, for AADPA) — [Deloitte](https://www.deloitte.com/au/en/services/economics/perspectives/social-economic-costs-adhd-Australia.html).
- **AU Senate inquiry:** report released 7 Nov 2023 with 15 recommendations; 701 submissions — [ADHD Australia](https://www.adhdaustralia.org.au/senate-inquiry-into-adhd/). About 800K Australians have ADHD; barriers include waits and cost; recommendations include expanding GP and nurse-practitioner roles and telehealth — [The Conversation](https://theconversation.com/a-senate-inquiry-says-australia-needs-a-national-adhd-framework-to-improve-diagnosis-and-reduce-costs-215798).
- **US (CDC MMWR 2024; data Oct–Nov 2023):**
  - 15.5M adults (6.0%) have current ADHD; 55.9% were diagnosed in adulthood.
  - 33.4% took stimulants in the past year; **71.5% of those had difficulty filling prescriptions due to shortage**.
  - 30.5% obtained prescriptions via telehealth.
  - Source: [CDC](https://www.cdc.gov/mmwr/volumes/73/wr/mm7340a1.htm).
- **UK:** about 2.6M people with ADHD (1.9M adults, 694K children); adult prevalence 3–4% per NICE — [ADHD UK](https://adhduk.co.uk/about-adhd/). NHS England's ADHD taskforce launched Mar 2024 and published its report in two parts (Jun 2025 and 6 Nov 2025); "waiting lists and times have grown" — [NHS England](https://www.england.nhs.uk/mental-health/adhd/).

### Inferences
- US adults on stimulants ≈ 15.5M × 33.4% ≈ 5.2M. That is roughly 9× Australia's total ADHD-medicated population (about 600K, all ages).
- AU iPhone share, and the share willing to pay, are unknown. Even so, a 1% paid conversion of 600K patients would give about 6K subscribers. This supports an early US/UK plan.
- Recurrent medication shortages (US 71.5%) mean irregular dosing is common. The scheduler must handle "no meds today".

### Gaps
- An ADHD-app market-size estimate (no reliable source fetched; commercial market reports are generally low quality).
- PBS 2024–25 ADHD-specific figures.
- The UK NHS England official prevalence figure (NICE CKS returned 403).
- Australian stimulant shortage data (the Janetzki 2025 paper was not opened).

---

## 7. Distribution channels

### Takeaway
Apple editorial featuring is proven in this category (Tiimo). TikTok reaches huge ADHD audiences but is misinformation-heavy. UK Disabled Students' Allowance funds specialist software. Evidence on clinician referral, university partnerships in AU, and employer benefits was not found.

### Cited Findings
- Tiimo was named iPhone App of the Year 2025 and was a 2024 Apple Design Awards finalist — [Wikipedia](https://en.wikipedia.org/wiki/Tiimo).
- The 100 most popular TikTok ADHD videos had 283M views (average 2.8M each). **52% were misleading**, 27% personal experience and 21% useful. Healthcare providers posted 11 of the 100 and were far more often useful (63.6% vs 15.7%) — Yeung, Ng & Abi-Jaoude 2022, *Can J Psychiatry* — [SAGE](https://journals.sagepub.com/doi/10.1177/07067437221082854).
- Done spent US$40M+ on "deceptive" social advertising; Google and TikTok later banned its ads — [DOJ](https://www.justice.gov/opa/pr/founderceo-and-clinical-president-digital-health-company-sentenced-8-years-90-million-scheme); [Wikipedia](https://en.wikipedia.org/wiki/Done_Global).
- UK DSA covers "specialist equipment", non-medical helpers and more, up to £27,783/year; students pay the first £200 on a computer. ADHD is not named on the page — [GOV.UK](https://www.gov.uk/disabled-students-allowance-dsa).
- Clinician-facing hooks already exist: FocusCurve has a "clinician-ready PDF export" — [FocusCurve](https://focuscurve.app/); Pillr has appointment prep and transcription — [App Store US](https://apps.apple.com/us/app/pillr-adhd-medication-tracker/id6746717689). Shimmer claims to be "recommended by clinicians" — [Shimmer](https://www.shimmer.care/cost).
- Two Australian ADHD-adjacent startups (Focus Bear, Llama Life) show a local founder ecosystem and investors (Black Sheep Capital) — [Focus Bear](https://www.focusbear.io/pricing); [Startup Daily](https://www.startupdaily.net/topic/funding/jason-calacanis-backs-australian-productivity-startup-llama-life-in-950000-pre-seed-raise/).

### Inferences
- A clinician-shareable medication-effect report (dose times, perceived onset and wear-off, task completion by window) is a natural referral wedge for GPs and psychiatrists. It also strengthens the privacy and safety positioning.
- Pairing lived-experience TikTok creators with clinician review would counter the 52%-misleading reputation problem.

### Gaps
- Macquarie University Accessibility Services offering (page returned 403).
- AU equivalents of DSA-funded software (NDIS/university assistive technology).
- Evidence on employer-benefit channels for ADHD apps.
- Clinician-referral conversion data.

---

## 8. Pricing models and ADHD users' attitudes

### Takeaway
The category mixes freemium subscriptions (Tiimo, Structured, Todoist, FlowSavvy, Reclaim), hard paywalls (Motion, Akiflow), one-off purchases (Goblin Tools app), lifetime options (Structured, Lunatask, Routinery, FocusCurve), and hardship or student schemes. Benchmarks favour hard paywalls or long trials for conversion. ADHD users visibly reward non-punitive pricing (scholarships, free cores, lifetime).

### Cited Findings
- **Lifetime or one-off:**
  - Structured lifetime — [App Store US](https://apps.apple.com/us/app/structured-daily-planner/id1499198946).
  - Lunatask US$300 — [Lunatask](https://lunatask.app/pricing).
  - Routinery lifetime at 50% off — [Routinery](https://routinery.app/).
  - FocusCurve lifetime — [FocusCurve](https://focuscurve.app/).
  - Goblin Tools A$2.99 app — [Lookup AU](https://itunes.apple.com/lookup?id=6454469750,6449003064&country=au).
- **Student discounts:**
  - Akiflow 40% — [Akiflow](https://akiflow.com/pricing).
  - Marvin 50% and pay-what-you-can — [Amazing Marvin](https://amazingmarvin.com/pricing/).
  - Lunatask 50% — [Lunatask](https://lunatask.app/pricing).
  - Morgen 25% — [Morgen](https://www.morgen.so/pricing).
- **Hardship schemes:**
  - Structured scholarship — [App Store US](https://apps.apple.com/us/app/structured-daily-planner/id1499198946).
  - Bearable Heroes — [Bearable](https://bearable.app/pricing/).
- **Trial design:** Tiimo's trial is annual-only and monthly plans are charged immediately — [Tiimo](https://www.tiimoapp.com/pricing). Akiflow's trial requires a card — [Akiflow](https://akiflow.com/pricing). Sunsama and Morgen run 14-day no-card trials — [Sunsama](https://www.sunsama.com/pricing); [Morgen](https://www.morgen.so/pricing).
- **Conversion benchmarks:** hard paywall 10.7% vs freemium 2.1% at day 35; 17–32-day trials 42.5% vs 25.5% for trials under 4 days — [RevenueCat 2026](https://www.revenuecat.com/blog/growth/subscription-app-trends-benchmarks-2026).
- **Health & Fitness pricing:** annual plans are 61% of revenue; high-priced plans earn about 4× the LTV — [Adapty](https://adapty.io/blog/health-fitness-app-subscription-benchmarks/).
- **Apple commission:** 15% under US$1M annual proceeds, 30% above — [Apple](https://developer.apple.com/app-store/small-business-program/).
- **Backlash against dark patterns:** "charged a whole year in advance"; refusals to refund — [Trustpilot Motion](https://www.trustpilot.com/review/www.usemotion.com). Accidental annual purchase on Inflow — [App Store US](https://apps.apple.com/us/app/inflow-manage-your-adhd/id1528183849).

### Inferences
Recommended shape for the new app:
- A free core covering medication logging, the effect window and manual planning, so that it does not feel like an "ADHD tax".
- A paid tier for AI auto-scheduling and behavioural learning.
- Annual pricing plus a student price (the university launch audience).
- A 14–30-day trial so that the learning has time to show value.
- An opt-in lifetime tier with a cap on cloud-AI usage.
- An automatic "trial ends in 2 days" reminder to prevent billing backlash.

### Gaps
- Willingness-to-pay data specific to ADHD users.
- Australian student price sensitivity.
- Reddit "ADHD tax" sentiment (blocked).

---

## 9. Failure modes and mitigations (at least 15)

### Takeaway
The biggest risks, in order:
1. Abandonment (D30 around 3%).
2. Trust collapse from an over-eager scheduler.
3. Wrong medication-curve assumptions and the regulatory exposure that comes with them.
4. LLM cost and latency.
5. Subscription resentment.
6. Platform dependency.

Each has documented precedent in this category.

### Cited Findings (failure mode → evidence → mitigation)

1. **Novelty decay and abandonment.**
   - Evidence: mental-health app median D30 retention is 3.3% — [Baumel via Elf](https://www.nationalelfservice.net/mental-health/digital-mental-health-tool-ignore-trial-read-analytics/). ADHD "shiny object syndrome" — [Zapier](https://zapier.com/blog/adhd-to-do-list/).
   - Mitigation: deliver value without the user opening the app (Watch complication showing "peak focus until 1:40pm", Live Activities, calendar blocks). Design a guilt-free re-entry ("fresh start", no overdue pile-up). Track D1/D7/D30 cohorts from launch.

2. **Setup burden before first value.**
   - Evidence: Routinery "lengthy initial setup" — [ChoosingTherapy](https://www.choosingtherapy.com/best-adhd-apps/); Motion steep onboarding — [Saner](https://www.saner.ai/blogs/motion-reviews); Reclaim "more sophisticated than intuitive" — [G2](https://www.g2.com/products/reclaim-ai/reviews).
   - Mitigation: onboarding under 3 minutes. Import events via EventKit and doses via the HealthKit Medications API; default to the population curve for the user's formulation; reveal settings progressively.

3. **The scheduler over-packs the day and clutters the calendar.**
   - Evidence: "no breathing room" (Motion) — [Saner](https://www.saner.ai/blogs/motion-reviews); "overwhelming seeing my calendar all booked" (Reclaim) — [G2](https://www.g2.com/products/reclaim-ai/reviews).
   - Mitigation: a hard capacity cap (e.g. fill at most about 60% of free time); mandatory buffers and transitions; put schedule blocks in a separate, hideable app-owned calendar.

4. **Trust collapse after one visibly bad move.**
   - Evidence: algorithm aversion — [Dietvorst et al. 2015](https://www.ebi.ac.uk/europepmc/webservices/rest/search?query=DOI:10.1037/xge0000033&resultType=core&format=json).
   - Mitigation: a "suggest, then confirm" default for the first 2 weeks; a one-tap undo; a plain-language reason for every placement ("placed here: 2h after dose, your peak"); never move user-created or pinned items.

5. **Loss of control from too many silent reschedules.**
   - Evidence: Reclaim reviews cite rescheduling struggles (25 reviews) — [G2](https://www.g2.com/products/reclaim-ai/reviews); Tiimo users want unscheduled, flexible tasks — [App Store US](https://apps.apple.com/us/app/tiimo-adhd-planner-focus/id1480220328).
   - Mitigation: rate-limit automatic moves (e.g. at most N per day); send a daily "what moved" digest; support "floating" tasks with no fixed time; let the user lock a day.

6. **Calendar sync breakage, duplicates and double-booking.**
   - Evidence: Motion "double-booked meetings", "calendar sync issues" — [Saner](https://www.saner.ai/blogs/motion-reviews); Reclaim "syncing problems/bugs" — [G2](https://www.g2.com/products/reclaim-ai/reviews).
   - Mitigation: write only to an app-owned calendar and Reminders list; store identifiers so sync is idempotent; never edit third-party events; add a reconciliation pass on launch; QA against iCloud, Google-via-iOS and Exchange accounts.

7. **Permission refusal or distrust at the EventKit prompt.**
   - Evidence: reading events needs full access; write-only cannot see conflicts; Reminders is full access only — [Create with Swift](https://www.createwithswift.com/getting-access-to-the-users-calendar/).
   - Mitigation: a pre-permission explainer screen; a degraded write-only mode (the user marks busy times manually); let users exclude sensitive calendars.

8. **The population medication curve is wrong for the individual.**
   - Evidence: trackers rely on population kinetics or a manual "metabolic rate" — [FocusCurve](https://focuscurve.app/); [Theraview](https://apps.apple.com/us/app/theraview-track-adhd-meds/id1541078407).
   - Mitigation: one-tap "kicked in" and "wearing off" logging on the Watch; update the curve per user; show an uncertainty band; ask for confirmation before relying on it for high-stakes blocks (exams).

9. **Irregular dosing and shortages break the plan.**
   - Evidence: 71.5% of US adults on stimulants had difficulty filling prescriptions — [CDC](https://www.cdc.gov/mmwr/volumes/73/wr/mm7340a1.htm).
   - Mitigation: explicit "no meds today", "late dose" and "half dose" modes that re-plan instantly; plans must remain usable without medication.

10. **Regulatory classification or liability for medication features.**
    - Evidence: regulators and platforms have acted hard against ADHD-medication businesses (Done convictions and ad bans; Cerebral's DOJ settlement) — [DOJ](https://www.justice.gov/opa/pr/founderceo-and-clinical-president-digital-health-company-sentenced-8-years-90-million-scheme); [Wikipedia Done](https://en.wikipedia.org/wiki/Done_Global); [Wikipedia Cerebral](https://en.wikipedia.org/wiki/Cerebral_(company)). Inflow disclaims medical-device status — [App Store US](https://apps.apple.com/us/app/inflow-manage-your-adhd/id1528183849).
    - Mitigation: never recommend dose, timing or medication changes; schedule tasks around doses the user logs; add disclaimers; get legal review of the TGA software-as-medical-device rules before launch (the TGA page was unreadable, so this remains an open item), and later the FDA and MHRA equivalents.

11. **Health-data privacy breach or loss of trust.**
    - Evidence: on-device and no-account designs are a marketed differentiator for competitors — [FocusCurve](https://focuscurve.app/); [Pillr](https://apps.apple.com/us/app/pillr-adhd-medication-tracker/id6746717689). HealthKit per-medication authorisation — [Apple WWDC25](https://developer.apple.com/videos/play/wwdc2025/321/).
    - Mitigation: keep health data on device by default; no ad or analytics SDKs that touch health data; send only de-identified, minimal context to any cloud LLM; publish a plain-English privacy page.

12. **LLM cost exceeds revenue (free tier and heavy users).**
    - Evidence: Haiku 4.5 costs US$1/US$5 per 1M tokens — [Anthropic](https://platform.claude.com/docs/en/about-claude/pricing); Goblin Tools added a paid tier because of running costs — [goblin.tools](https://goblin.tools/About); the estimate in section 4 is about US$1/heavy user/month on Haiku and about US$2 on mid-tier models.
    - Mitigation: use the on-device Foundation Models (free) for parsing and task breakdown — [Apple](https://www.apple.com/newsroom/2025/09/apples-foundation-models-framework-unlocks-new-intelligent-app-experiences/); make the core scheduler a deterministic constraint solver; call the cloud LLM only for weekly plans; cache prompts; cap free-tier calls.

13. **Hallucinated or low-quality AI output.**
    - Evidence: "The AI hallucinates a lot and give you too many action items" — [Trustpilot](https://www.trustpilot.com/review/www.usemotion.com); Goblin Tools "hit-or-miss" — [Saner](https://www.saner.ai/blogs/best-adhd-apps).
    - Mitigation: validate structured output against a schema; the LLM proposes but the solver verifies feasibility; preview before any write to Calendar; cap how many subtasks a breakdown can generate.

14. **AI features churn faster.**
    - Evidence: AI apps retain 36% worse over 12 months — [RevenueCat 2026](https://www.revenuecat.com/blog/growth/subscription-app-trends-benchmarks-2026).
    - Mitigation: position the app around the medication-window planner and Watch habits rather than as a "chatbot"; AI stays invisible infrastructure.

15. **Trial too short for behavioural learning to show value.**
    - Evidence: Inflow reviewer says "one week is not enough" — [App Store US](https://apps.apple.com/us/app/inflow-manage-your-adhd/id1528183849); 17–32-day trials convert 42.5% vs 25.5% for short ones; 55% of 3-day-trial cancellations happen on Day 0 — [RevenueCat 2026](https://www.revenuecat.com/blog/growth/subscription-app-trends-benchmarks-2026).
    - Mitigation: a 14–30-day trial, or a free core with learning insights unlocked after 2 weeks of data; show "what I've learned about you" before the paywall.

16. **Subscription resentment and billing backlash ("ADHD tax").**
    - Evidence: Motion auto-renew and refund complaints (Trustpilot 3.7) — [Trustpilot](https://www.trustpilot.com/review/www.usemotion.com); accidental annual purchase on Inflow — [App Store US](https://apps.apple.com/us/app/inflow-manage-your-adhd/id1528183849); users praise non-paywalled Finch and Structured's scholarship — [App Store AU Finch](https://apps.apple.com/au/app/finch-self-care-pet/id1528595748); [App Store US Structured](https://apps.apple.com/us/app/structured-daily-planner/id1499198946).
    - Mitigation: send a trial-end reminder notification; one-tap cancel instructions; student and hardship pricing; a lifetime option; never hide charges behind "Try free".

17. **UI churn disorients neurodivergent users.**
    - Evidence: Tiimo "layout and features change OFTEN which can be unsettling and confusing"; "one step forward and two steps back" — [App Store AU](https://apps.apple.com/au/app/tiimo-adhd-planner-focus/id1480220328); [App Store US](https://apps.apple.com/us/app/tiimo-adhd-planner-focus/id1480220328).
    - Mitigation: a stable navigation contract; opt-in "new features" toggles; in-app changelogs; beta via TestFlight.

18. **Notifications too weak, or too many.**
    - Evidence: Tiimo "quick ding isn't enough" — [App Store US](https://apps.apple.com/us/app/tiimo-adhd-planner-focus/id1480220328); Routinery "inconsistent notifications" — [ChoosingTherapy](https://www.choosingtherapy.com/best-adhd-apps/); Finch "weak notifications" — [Saner](https://www.saner.ai/blogs/best-adhd-apps); competitors escalate alarms or lock screens — [Pause Moment](https://pause-moment.com/best-adhd-medication-reminder-apps-2026/).
    - Mitigation: Time-Sensitive notifications plus distinct Watch haptics per event type (dose, wear-off, transition); user-tunable escalation; learn which prompts get ignored and reduce them.

19. **Apple Watch reliability.**
    - Evidence: Tiimo users logged out on Watch mid-routine — [App Store US](https://apps.apple.com/us/app/tiimo-adhd-planner-focus/id1480220328).
    - Mitigation: the Watch app should work offline with no auth dependency; local-first data; complications that never require the phone.

20. **Sherlocking and platform dependency.**
    - Evidence: Apple Health already has Medications with reminders and interaction warnings — [Wikipedia](https://en.wikipedia.org/wiki/Health_(Apple)); Apple opened med data to apps — [WWDC25](https://developer.apple.com/videos/play/wwdc2025/321/); Clockwise shows a mature scheduler can vanish within a week — [The Stack](https://www.thestack.technology/clockwises-team-joins-salesforce-sunsetting-platform-as-they-go/).
    - Mitigation: build on Apple's data rather than competing with it (read HealthKit, write EventKit); differentiate on ADHD-specific effect modelling and learning; pursue Apple featuring; offer data export so users never get stranded.

21. **Direct competitor response (Tiimo adds medication).**
    - Evidence: Tiimo already has AI co-planning and Reminders/Watch support, and roadmaps "energy-level adjustments over time" — [Tiimo AI planner](https://www.tiimoapp.com/resource-hub/ai-planner); it has 50K+ paying users and funding — [Tiimo](https://www.tiimoapp.com/resource-hub/tiimo-raises-4-8m-neurodivergent-planner).
    - Mitigation: move fast on the personalised curve plus Watch-tap calibration; build the clinician report and student/academic-calendar integrations as moats.

22. **Australia-only scale ceiling.**
    - Evidence: AU rating counts are about 7–9% of US counts for Tiimo and Structured — [Lookup AU](https://itunes.apple.com/lookup?id=1480220328,1499198946,1528183849,1628994767,1541078407,6746717689,1516036620,952895165&country=au); [Lookup US](https://itunes.apple.com/lookup?id=6454469750,6449003064,1480220328,1499198946&country=us). About 600K AU medicated patients — [AIHW](https://www.aihw.gov.au/mental-health/topic-areas/mental-health-prescriptions/adhd-medications-dispensed-overtime) vs about 5.2M US adults on stimulants (inferred from [CDC](https://www.cdc.gov/mmwr/volumes/73/wr/mm7340a1.htm)).
    - Mitigation: build US/UK localisation (spelling, formulations such as Vyvanse vs Elvanse naming, term structures) from v1; use AU as the beta market.

23. **Misinformation and reputational marketing risk.**
    - Evidence: 52% of top TikTok ADHD videos were misleading — [SAGE](https://journals.sagepub.com/doi/10.1177/07067437221082854); Done's "deceptive" social ads led to ad bans — [DOJ](https://www.justice.gov/opa/pr/founderceo-and-clinical-president-digital-health-company-sentenced-8-years-90-million-scheme); [Wikipedia](https://en.wikipedia.org/wiki/Done_Global).
    - Mitigation: clinician-reviewed claims; no medication promotion; creator partnerships with a disclosure policy; avoid "treats ADHD" language.

24. **Chasing the reimbursement or digital-therapeutic route.**
    - Evidence: Akili went from about US$1B to US$34M after its prescription and direct-to-consumer models failed — [STAT](https://www.statnews.com/2024/05/29/virtual-therapeutics-acquire-akili-video-games-adhd/); [MassDevice](https://www.massdevice.com/virtual-therapeutics-acquires-akili/).
    - Mitigation: remain a consumer productivity app; treat clinicians as a referral channel, not as payers.

25. **Lifestyle toggle (term vs holidays) misfires or adds complexity.**
    - Evidence: the closest analogue is paid "scheduling hours profiles" (FlowSavvy Pro) — [FlowSavvy](https://flowsavvy.app/pricing); users complain about rigidity (Tiimo) — [App Store US](https://apps.apple.com/us/app/tiimo-adhd-planner-focus/id1480220328).
    - Mitigation: auto-suggest switching from imported academic session dates; switching via a single Watch or Control Centre control; per-profile learned patterns (holiday behaviour must not contaminate the term-time model).

### Inferences
- The most dangerous early-life failures (numbers 1–6) are UX and trust failures, not feature gaps. They argue for a conservative, explainable scheduler rather than a maximally autonomous one.
- Medication awareness is the moat, and it is also the main regulatory and reputational exposure (numbers 8–10, 23). Framing and legal review are launch-critical.

### Gaps
- Australian regulatory position on medication-timing-aware scheduling apps (TGA guidance unreadable). Privacy Act 1988 health-information obligations were not fetched.
- Quantitative evidence of how many users abandon auto-schedulers after a bad reschedule. The algorithm-aversion lab evidence is the proxy used.
