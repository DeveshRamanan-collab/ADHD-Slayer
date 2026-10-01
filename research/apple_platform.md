# Apple platform frameworks for an ADHD planning and medication-window app (iPhone, Watch, Mac, iPad), as of late Sept 2026

Scope note: research done 28 Sep 2026. Primary sources are developer.apple.com docs (the `.md` renderings of doc pages), WWDC25/WWDC26 session pages, Apple Support, and Apple Developer Forums. Secondary sources (MacRumors, Macworld, AppleInsider, 9to5Mac, Engadget, Wikipedia, dev blogs) are used only for "what shipped when" and are flagged where they conflict. The session's web-search budget ran out partway through, so a few items are listed under Gaps instead of being verified.

---

## 1. Platform status: have iOS 27 / watchOS 27 / macOS 27 shipped, and what matters from WWDC26?

### Takeaway
iOS 27, iPadOS 27, watchOS 27 and macOS 27 all shipped on 14 Sep 2026. The main developer changes are: the Foundation Models framework now includes a Private Cloud Compute (PCC) model and third-party providers; App Intents got "App Schemas" (including Calendar and Reminders domains); and Siri AI launched with in-app actions and on-screen awareness. Nothing from WWDC26 lets third-party apps write medication doses to Health. The redesigned Health app is still in beta (iOS 27.2).

### Cited Findings
- iOS 27 was released on 14 Sep 2026. It needs an A13 or later iPhone (iPhone 11 onward). Apple Intelligence features need A17 Pro (iPhone 15 Pro) or later — [Wikipedia iOS 27](https://en.wikipedia.org/wiki/IOS_27)
- Per MacRumors, citing Apple's website: "iPadOS 27, macOS 27, watchOS 27, tvOS 27, and visionOS 27 will also be released on Monday, September 14". iOS 27 supports "the exact same iPhone models as iOS 26". Siri AI needs "the iPhone 15 Pro and newer" — [MacRumors, 9 Sep 2026](https://www.macrumors.com/2026/09/09/apple-announces-ios-27-release-date/)
  - CONFLICT: the Wikipedia macOS 27 ("Golden Gate") page still says it "will be released in late 2026", and the Wikipedia watchOS 27 page says "late 2026". Both look stale compared with MacRumors. Wikipedia also says macOS 27 requires Apple silicon (M1 or later; Intel dropped) — [Wikipedia macOS 27](https://en.wikipedia.org/wiki/MacOS_27); [Wikipedia watchOS 27](https://en.wikipedia.org/wiki/WatchOS_27)
  - The watchOS 27 Wikipedia page contradicts itself on compatibility: it says Series 6/7/8/Ultra 1/SE 2 were dropped, and also that "all devices supporting watchOS 26 are compatible". Treat Watch compatibility as UNVERIFIED — [Wikipedia watchOS 27](https://en.wikipedia.org/wiki/WatchOS_27)
- What shipped at launch vs later:
  - At launch: "Siri AI with personal context and onscreen awareness" and "in-app actions".
  - Delayed: the "Redesigned Health app with AI insights".
  - Siri AI is "unavailable in the EU and China at launch" and English-only at first. More languages arrive in iOS 27.1 (October) — [Macworld](https://www.macworld.com/article/2986799/ios-27-new-iphone-features-release-date-beta-compatiblity-apple-intelligence-siri.html)
- The redesigned Health app (Insights and Longevity tabs, expert commentary) went into the iOS 27.2 developer beta on 16 Sep 2026. Apple says "later this year" — [Engadget](https://www.engadget.com/2260794/apple-s-redesigned-health-app-is-available-now-in-the-ios-27-2-developer-beta/)
- AppleInsider: "Health seemingly didn't get much of an update this time around. Notably, Cycle Tracking adds notifications for perimenopause patterns" — [AppleInsider](https://appleinsider.com/articles/26/09/09/ios-27-arrives-on-september-14-heres-what-youll-get)
- WWDC26 Platforms State of the Union announcements:
  - Free PCC Foundation Models for developers with <2M first-time downloads.
  - Image input.
  - Third-party models such as Claude and Gemini "through the same Swift API".
  - Dynamic Profiles.
  - A new Core AI framework for custom on-device models.
  - New App Intents entity/intent schemas that feed Spotlight's semantic index.
  - A "View Annotations API" so Siri can act on on-screen content.
  — [MacRumors, 9 Jun 2026](https://www.macrumors.com/2026/06/09/apple-outlines-major-ai-and-developer-tool-updates/)
- Gemini:
  - Joint Apple/Google statement, 12 Jan 2026: "Apple determined that Google's AI technology provides the most capable foundation for Apple Foundation Models" — [Android Authority](https://www.androidauthority.com/apple-siri-google-gemini-deal-3631890/)
  - Google Cloud (22 Apr 2026): "next generation of Apple Foundation Models based on Gemini technology".
  - iOS 26.4 did NOT ship personalised Siri (Apple "ran into issues with accuracy").
  - It "continues to be unclear if the new Siri and Gemini-powered Apple Intelligence features will use Private Cloud Compute or will run on Google's servers."
  — [MacRumors, 22 Apr 2026](https://www.macrumors.com/2026/04/22/google-gemini-powered-siri-2026/)

### Inferences
- Target iOS 26 as the minimum OS: it has the Medications API, Foundation Models, AlarmKit, BGContinuedProcessingTask and RecognizeDocumentsRequest. Treat iOS 27 features (PCC model, 8K context, App Schemas / Siri AI, FM image input) as progressive enhancements behind `if #available`.
- Siri AI is gated to iPhone 15 Pro and later and to English at launch. Voice features must degrade to plain App Shortcuts on older devices.

### Gaps
- I could not confirm from a primary Apple source whether Siri AI or Apple Intelligence is enabled in Australia with en-AU at iOS 27 launch. Macworld names only EU/China exclusions.
- The MacRumors April article's claim (via summary) that Siri AI launched "behind a waitlist" could not be verified. The article predates launch, so treat the claim as unreliable.
- Final watchOS 27 device compatibility is unverified.

---

## 2. HealthKit Medications API (WWDC25 / iOS 26) — can we read the med list and doses, and can we write doses?

### Takeaway
Third parties can READ, with per-object (per-medication) authorisation:
- the user's Health-app medication list (`HKUserAnnotatedMedication` / `HKMedicationConcept`)
- the dose events logged in Health (`HKMedicationDoseEvent`)

Third parties CANNOT WRITE doses or medications. An Apple DTS engineer confirmed: "Medication data is read-only in HealthKit." The app must keep its own dose log (including boosters). Health can only be an optional import source.

### Cited Findings
- Types (iOS/iPadOS/macOS/Mac Catalyst/visionOS/watchOS 26.0+):
  - `HKUserAnnotatedMedication`: properties `hasSchedule`, `isArchived`, `medication: HKMedicationConcept`, `nickname: String?` — [Apple docs](https://developer.apple.com/documentation/healthkit/hkuserannotatedmedication.md)
  - `HKMedicationDoseEvent` (subclass of `HKSample`): properties `doseQuantity: Double?`, `logStatus: HKMedicationDoseEvent.LogStatus`, `medicationConceptIdentifier: HKHealthConceptIdentifier`, `medicationDoseEventType`, `scheduleType: HKMedicationDoseEvent.ScheduleType`, `scheduledDate: Date?`, `scheduledDoseQuantity: Double?`, `unit: HKUnit` — [Apple docs](https://developer.apple.com/documentation/healthkit/hkmedicationdoseevent.md)
- From the WWDC25 session:
  - `HKMedicationConcept` has `identifier`, `displayText`, `generalForm`, and `relatedCodings` (RxNorm codes).
  - Medications are queried with `HKUserAnnotatedMedicationQueryDescriptor` (predicates on `isArchived` / `hasSchedule`).
  - Dose events are queried with the normal `HKSampleQuery` / `HKAnchoredObjectQuery` / `HKObserverQuery`, filterable by medication, log status and date.
  - Authorising a medication automatically grants read access to that medication's dose events.
  - When the user adds a new medication in Health, Health itself prompts them to share it with already-authorised apps.
  - "Only the Health App can persist dose events."
  - Apple warns that dose events "may be logged for days in the past, deleted and re-persisted when editing, or may be saved for reminders that were never interacted with". Use anchored queries and handle deletions.
  — [WWDC25 session 321](https://developer.apple.com/videos/play/wwdc2025/321/)
- DTS answer (Ziqiao Chen): "No, that isn't allowed. Medication data is read-only in HealthKit." This was in reply to `requestAuthorization(toShare: [doseType]...)` — [Apple Developer Forums 803954](https://developer.apple.com/forums/thread/803954)
- Authorisation call: `healthStore.requestPerObjectReadAuthorization(for: medicationType)` — [dev.to WWDC25 notes](https://dev.to/arshtechpro/wwdc-2025-meet-the-healthkit-medications-api-1d23)
- Apple docs for `requestPerObjectReadAuthorization(for:predicate:)`:
  - "Using the `requestAuthorization(toShare:read:)` method to request read access to any data types that require per-object authorization fails with an `errorInvalidArgument` error."
  - "The system always asks for permission, regardless of whether they previously granted it."
  — [Apple docs](https://developer.apple.com/documentation/healthkit/hkhealthstore/requestperobjectreadauthorization(for:predicate:completion:).md)
- One open-source developer reports a crash, "Authorization to read the following types is disallowed: HKMedicationDoseEventTypeIdentifierMedicationDoseEvent, HKDataTypeUserAnnotatedMedicationConcept". They suspect a gated entitlement — [GitHub GutCheck #435](https://github.com/eyeMNaughtReal/GutCheck/issues/435). CONFLICT/uncertain: no Apple source mentions a special entitlement. The Apple doc above suggests this error comes from using `requestAuthorization(toShare:read:)` instead of the per-object API.
- The WWDC26 HealthKit session (207) covers workout zones only. There is no mention of medication write support — [WWDC26 session 207](https://developer.apple.com/videos/play/wwdc2026/207/). A dev-blog summary of new iOS 27 HealthKit types lists workout zones and `menopausalState` / `bleedingAfterMenopause`, with "no medications API changes" — [blakecrosley.com](https://blakecrosley.com/blog/healthkit-ios-27-workout-zones)

### Inferences
- Architecture: the app's own store is the source of truth for doses and boosters (it can log with one tap from Watch, widgets or Siri). Optionally, users can link medications from Health so that doses they log in Apple's Medications UI (iPhone/Watch) are imported via `HKAnchoredObjectQuery`.
- De-duplicate imported events by HealthKit UUID and handle their deletion and re-persistence. There is no way to push our logs back to Health.
- Use `HKMedicationConcept.relatedCodings` (RxNorm) to identify stimulant class (methylphenidate vs amphetamine, IR vs XR) as a prior for the effect-window model.
- Watch: the types exist on watchOS 26. Whether a watchOS app gets reliable medication read authorisation is untested.

### Gaps
- Enum cases of `LogStatus` and `ScheduleType`: the WWDC summary says taken/skipped/snoozed/not interacted; exact doc cases were not retrieved.
- Whether `HKMedicationDoseEvent` supports `enableBackgroundDelivery`.
- Whether any entitlement beyond the standard HealthKit capability is required (GutCheck issue unresolved).
- Whether Apple plans write support.

---

## 3. HealthKit in general: sleep, workouts, HR/HRV, State of Mind, cycle, daylight, background delivery, lock-state protection, sleep schedule

### Takeaway
All the needed signals can be read, but with important caveats:
- Background wakes are capped (hourly on iOS for many types; 4 per hour on watchOS, shared with app refresh, and only with a complication on the face).
- The Health store is encrypted and unreadable while the iPhone is locked.
- Apps cannot tell whether read permission was denied.
- There is no API for the user's Sleep Schedule or wake alarm.

### Cited Findings
- Sleep:
  - `HKCategoryValueSleepAnalysis` has `inBed`, `awake`, `asleepCore`, `asleepDeep`, `asleepREM` and `asleepUnspecified` (the old `asleep` is deprecated). Stage samples overlap `inBed` but not each other.
  - "Samples recorded by Apple Watch only include awake samples that occur between two sleep samples."
  — [Apple docs](https://developer.apple.com/documentation/healthkit/hkcategoryvaluesleepanalysis.md)
- State of Mind: `HKStateOfMind` (iOS 18 / watchOS 11 / macOS 15+) is an `HKSample` with `kind`, `valence`, `valenceClassification`, `labels` and `associations`. It has a public initialiser, so apps can write it as well as read it — [Apple docs](https://developer.apple.com/documentation/healthkit/hkstateofmind.md)
- `timeInDaylight` quantity type: iOS 17 / watchOS 10 / macOS 14 — [Apple docs](https://developer.apple.com/documentation/healthkit/hkquantitytypeidentifier/timeindaylight.md)
- Cycle types include:
  - `menstrualFlow`, `intermenstrualBleeding`, `infrequentMenstrualCycles`, `irregularMenstrualCycles`, `persistentIntermenstrualBleeding`, `prolongedMenstrualPeriods`
  - `cervicalMucusQuality`, `ovulationTestResult`, `progesteroneTestResult`, `contraceptive`, `pregnancy`, `lactation`
  - new: `menopausalState`, `bleedingAfterMenopause`
  - also `hypertensionEvent`, `mindfulSession`, `sleepAnalysis`, and high/low HR and irregular-rhythm events
  — [Apple docs HKCategoryTypeIdentifier](https://developer.apple.com/documentation/healthkit/hkcategorytypeidentifier.md)
- Workouts:
  - `HKWorkoutSession` is available on iOS/iPadOS 17+ as well as watchOS.
  - "Collecting heart rate data on iPhone or iPad requires pairing with an external heart rate sensor."
  - Apple Watch runs one workout session at a time.
  — [Apple docs](https://developer.apple.com/documentation/healthkit/hkworkoutsession.md)
  - iOS 27 / watchOS 27 add `HKWorkoutZoneGroup`, `HKWorkoutZoneConfiguration`, `HKLiveWorkoutZoneUpdate` and related types — [WWDC26 session 207](https://developer.apple.com/videos/play/wwdc2026/207/)
- Background delivery (`enableBackgroundDelivery(for:frequency:)`):
  - Requires the `com.apple.developer.healthkit.background-delivery` entitlement (iOS 15+ / watchOS 8+).
  - "Some sample types have a maximum frequency of `HKUpdateFrequency.hourly`" (e.g. `stepCount` on iOS).
  - On watchOS, most types are hourly-max, and "Your app can receive four updates (or background app refresh tasks) an hour, as long as it has a complication on the active watch face".
  - Observer queries must be set up in `didFinishLaunching`, and you must call the completion handler: "If your app fails to respond three times, HealthKit assumes your app can't receive data and stops sending background updates."
  - `HKCorrelationType` is not supported.
  — [Apple docs](https://developer.apple.com/documentation/healthkit/hkhealthstore/enablebackgrounddelivery(for:frequency:withcompletion:).md)
- Locked device and privacy:
  - "the device encrypts the HealthKit store when the user locks the device… your app may not be able to read data from the store when it runs in the background. However, your app can still write to the store."
  - "an app isn't aware when the user denies permission to read data. From the app's point of view, no data of that type exists."
  - HealthKit data must not be used for advertising or sold, and a privacy policy is required.
  — [Apple docs, Protecting user privacy](https://developer.apple.com/documentation/healthkit/protecting-user-privacy.md)
- Platforms:
  - "HealthKit data is also available to iPads running iPadOS 17 or later."
  - On macOS 13+ the framework exists "but your app can't read or write HealthKit data" (`isHealthDataAvailable()` returns false).
  — [Apple docs](https://developer.apple.com/documentation/healthkit/hkhealthstore/ishealthdataavailable().md)
- Sleep schedule: asked whether bedtime/wake-up times from Sleep Schedule can be read, a forum reply says no (it isn't available through HealthKit) and suggests Shortcuts automations that "trigger at bedtime/wakeup" — [Apple Developer Forums 725203](https://developer.apple.com/forums/thread/725203)
- Workaround signal for the Watch Smart Stack: WidgetKit `RelevantContext.sleep(_:)` lets the system surface a widget based on the person's sleep schedule. It requires `sleepAnalysis` permission. The app gets relevance, not the schedule itself — [Apple docs, Smart Stacks](https://developer.apple.com/documentation/widgetkit/widget-suggestions-in-smart-stacks.md)

### Inferences
- Heavy "learn my effect window" processing should run when the app is foregrounded or unlocked, not rely on background reads, because the store is locked.
- Last night's sleep can be inferred from `sleepAnalysis` samples. Scheduled wake time cannot be read: ask the user for it, or let the user build a Shortcuts "Wake Up" automation that calls an App Intent.
- Heart rate after a dose (stimulant tachycardia) is readable through `heartRate` / `restingHeartRate` / HRV samples. Watch-to-iPhone sync latency affects freshness.

### Gaps
- Exact identifiers and availability for HRV (`heartRateVariabilitySDNN`) and resting HR were not re-verified this session; they are long-standing types.
- Apple Watch to iPhone HealthKit sync latency: no reliable source was found (search budget exhausted).
- Whether menopausal and cycle types trigger the sensitive-data review is unknown.

---

## 4. EventKit: Calendar and Reminders access, change detection, identifiers, limits

### Takeaway
Scheduling tasks into the user's Calendar and detecting external edits requires FULL access. Write-only apps cannot even read back their own events. `EKEventStoreChanged` gives no diff. Identifiers are unstable across calendar moves, Exchange and duplicates, so keep your own mapping. Reminders via EventKit still lacks subtasks, flags, sections and tags.

### Cited Findings
- iOS 17 / macOS 14 / watchOS 10 access levels:
  - Write-only apps "can create and write calendar events. However, your app can't read or delete any events from the user's calendars, including the ones it creates."
  - Keys: `NSCalendarsWriteOnlyAccessUsageDescription`, `NSCalendarsFullAccessUsageDescription`, `NSRemindersFullAccessUsageDescription` (Reminders is full-access only).
  - With write-only access, `sources` returns a single virtual source and `defaultCalendarForNewEvents` a single virtual calendar.
  - Upgrading from write-only to full: calling read APIs implicitly prompts once. If the user declines, "any further calls don't prompt… again".
  - On watchOS, the access level "matches its companion app".
  — [TN3153](https://developer.apple.com/documentation/technotes/tn3153-adopting-api-changes-for-eventkit-in-ios-macos-and-watchos.md)
- `EKEventStoreChanged`: "Individual changes are not described. When you receive this notification, you should refetch all EKEvent and EKReminder objects you have accessed". You can call `refresh()` on an object you are editing. It is posted on the main actor — [Apple docs](https://developer.apple.com/documentation/foundation/nsnotification/name-swift.struct/ekeventstorechanged.md)
- `eventIdentifier`: "If the calendar of an event changes, its identifier most likely changes as well." — [Apple docs](https://developer.apple.com/documentation/eventkit/ekevent/eventidentifier.md)
- `calendarItemExternalIdentifier`:
  - Stable across devices, but duplicates can exist (ICS imports, shared calendars plus invitations, delegates, subscribed calendars).
  - "Recurring event identifiers are the same for all occurrences… use the start date."
  - "For Exchange servers, the identifier is different between iOS and macOS and different between devices for reminders."
  — [Apple docs](https://developer.apple.com/documentation/eventkit/ekcalendaritem/calendaritemexternalidentifier.md)
- Reminders limits: there is no EventKit property for subtasks/nesting or flagged status, and Apple DTS pointed developers back to the docs — [Apple Developer Forums 655905](https://developer.apple.com/forums/thread/655905). The iOS 27 Reminders changes are user-facing only (natural-language entry, an inline editor with Tag/Flag/Urgent), with "no developer or API-related information" — [9to5Mac](https://9to5mac.com/2026/08/26/heres-everything-new-for-reminders-in-ios-27/)
- iOS 27 system features:
  - Calendar natural-language entry.
  - Siri creates events and recurring or multi-event schedules from emails and messages.
  - "Visual Intelligence: Supports batch-importing multiple events by photographing schedules".
  - New Shortcuts Reminders actions, "Create/Delete Groups, Lists, and Sections".
  — [MacRumors iOS 27 Calendar & Reminders guide](https://www.macrumors.com/guide/ios-27-calendar-reminders/)
- Visual Intelligence writes into system stores (EventKit, Contacts, HealthKit) that apps can then read — [WWDC26 session 297](https://developer.apple.com/videos/play/wwdc2026/297/)
- ADP does not cover calendars: "Contacts and calendars are built on industry standards (CalDAV and CardDAV) that do not provide built-in support for end-to-end encryption." — [Apple Support 102651](https://support.apple.com/en-us/102651)

### Inferences
- Identity: give every app-created event or reminder an app UUID stored in the event `url` (e.g. `myapp://block/<uuid>`) or in `notes`. Keep a local map of uuid → (calendarItemExternalIdentifier, calendarIdentifier, occurrence start date). On `EKEventStoreChanged`, refetch the planning horizon and diff. Treat missing items as moved or deleted and re-match by URL/UUID.
- Recurring edits: EKSpan `.thisEvent` vs `.futureEvents` creates detached occurrences whose identifiers need occurrence-date handling (inference from the recurring-identifier note).
- Put app-managed blocks on a dedicated app-created calendar so users can hide it and move detection is simpler. Remember calendars are not E2E-encrypted, so avoid putting medication names in event titles on shared or Exchange calendars (inference).
- Roster screenshots: two routes. (a) Parse them in-app with Vision/FM (see Q8). (b) Encourage iOS 27's Visual Intelligence "photograph schedule → add events", then pick those events up via EventKit full access.
- Google/Exchange: EventKit sees them if the account is added in Settings. Sync lag and identifier differences apply (Exchange external IDs differ by platform).

### Gaps
- Whether iOS 26/27 SDKs added any EKReminder properties (subtasks, sections, tags, early alerts) could not be confirmed: no WWDC26 EventKit session was found. Assume no.
- iCloud Calendar sync latency figures: none found.

---

## 5. App Intents, Siri, Apple Intelligence, Spotlight, Action button, Controls, Focus filters, Visual Intelligence

### Takeaway
App Intents is the single integration layer behind Siri, Shortcuts, Spotlight, the Action button, Controls, interactive widgets, Live Activity buttons and Focus filters. iOS 27 Siri AI can drive apps through App Schemas. Calendar and Reminders domains exist, but there is no health or medication domain, and Journaling is Shortcuts-only. Dose-logging voice commands therefore rely on custom App Shortcuts phrases plus Siri AI's general on-screen and in-app action understanding.

### Cited Findings
- App Schema domains (iOS 27 docs):
  - Primary: Audio, Calendar, Camera, Clock, Mail, Maps, Messages, Notes, Phone, Photos, Reminders, and System/in-app search.
  - Single-purpose: Assistant (Japan side button) and Visual intelligence.
  - Shortcuts-only (not discoverable by Siri AI): Books, Browser, Files, Journaling, Presentation, Reader, Spreadsheet, Whiteboard, Word processor.
  - Macros: `@AppIntent(schema:)`, `@AppEntity(schema:)`, `@AppEnum(schema:)`.
  — [Apple docs, App schema domains](https://developer.apple.com/documentation/appintents/app-schema-domains.md)
- Reminders domain schemas: `createList`, `createReminder`, `createSection`, `deleteReminders`, `updateReminder`; entities `reminder`, `list`, `section`, `group`, `locationTrigger` — [Apple docs](https://developer.apple.com/documentation/appintents/app-schema-domain-reminders.md)
- Calendar domain schemas: `createEvent`, `deleteEvent`, `updateEvent`; entities `event`, `calendar`, `attendee` — [Apple docs](https://developer.apple.com/documentation/appintents/app-schema-domain-calendar.md)
- Siri AI integration model: index entities (Spotlight semantic index), make entities `Transferable`, adopt schemas, associate entities with views, donate actions — [Apple docs, Apple Intelligence and Siri AI](https://developer.apple.com/documentation/appintents/apple-intelligence-and-siri-ai.md)
- On-screen awareness:
  - `NSUserActivity` for a single primary item; `.appEntityIdentifier(EntityIdentifier(for:identifier:))` view annotations for lists.
  - `IndexedEntity` with `@Property(indexingKey:)`, and `EntityStringQuery` for data that can't be indexed.
  — [WWDC26 session 240](https://developer.apple.com/videos/play/wwdc2026/240/)
- WWDC26 advanced features:
  - `IntentDonationManager` donations ("excessive donations are ignored").
  - `appEntityIdentifiers` on `UNMutableNotificationContent`, so Siri can act on announced notifications.
  - `appEntityIdentifier` on AlarmKit `AlarmConfiguration`, so "snooze it" works.
  - `OwnershipProvidingEntity`; collection annotations.
  — [WWDC26 session 343](https://developer.apple.com/videos/play/wwdc2026/343/)
- iOS 26 App Intents:
  - `SnippetIntent` interactive snippets (result and confirmation) and `requestChoice`.
  - `supportedModes` (`.background`, `.foreground(.dynamic)` etc.) and `UndoableIntent`.
  - `@DeferredProperty` / `@ComputedProperty`, `onAppIntentExecution`, and `AppIntentsPackage`.
  - Visual Intelligence via `IntentValueQuery` over `SemanticContentDescriptor` (gives a `pixelBuffer`) with `@UnionValue` results.
  — [WWDC25 session 275](https://developer.apple.com/videos/play/wwdc2025/275/)
- Visual Intelligence gives apps only "raw pixel buffer" input from camera or screenshots, on iOS, iPadOS and macOS. Results show about 3 lines plus a thumbnail — [WWDC26 session 297](https://developer.apple.com/videos/play/wwdc2026/297/)
- App Shortcuts (`AppShortcutsProvider`, iOS 16 / watchOS 9 / macOS 13) are available immediately on install. `SiriTipView` / `ShortcutsLink` promote them — [Apple docs](https://developer.apple.com/documentation/appintents/app-shortcuts.md); [AppShortcutsProvider](https://developer.apple.com/documentation/appintents/appshortcutsprovider.md)
- Controls: `ControlWidget` appears in "Control Center, the Lock Screen, and the Action Button". Available on iOS 18 / macOS 26 / watchOS 26 — [Apple docs](https://developer.apple.com/documentation/swiftui/controlwidget.md)
- Focus filters: `SetFocusFilterIntent` (iOS 16 / watchOS 9 / macOS 13) with `static var current`, `suggestedFocusFilters(for:)` and `appContext: FocusFilterAppContext` — [Apple docs](https://developer.apple.com/documentation/appintents/setfocusfilterintent.md)

### Inferences
- Voice logging: define `LogDoseIntent(medication:, kind: .primary/.booster)` and `StartFocusBlockIntent` as App Shortcuts, e.g. "Log my booster in <AppName>". They work on all devices, including Watch and through AirPods.
- Also expose the app's tasks and time-blocks as entities under the `.reminders` / `.calendar` schemas, so Siri AI can "move this block to tomorrow" on iOS 27 English devices.
- There is no medication schema, so free-form Siri AI requests about doses depend on general intent matching. Test these; don't promise them.
- Focus filters let the app know when the user enters a "Work"/"Study" Focus (via the filter's parameters). That can auto-start a focus block or a Screen Time shield. The app cannot see arbitrary Focus state outside filters it is configured in (inference).
- Action button and Control Center: a "Log dose" control is the fastest non-Watch logging path (one press).

### Gaps
- Numeric limits (maximum App Shortcuts per app, phrase count) were not stated in the fetched docs.
- The Australian English Siri AI availability date is unconfirmed.

---

## 6. Foundation Models framework (on-device LLM), Private Cloud Compute, third-party LLMs; Vision OCR for rosters

### Takeaway
On-device, the model is small and context-limited:
- 4,096 tokens per session on iOS 26.x; 8,192 on iOS 27 with newer devices.
- It needs an Apple Intelligence-capable device.
- It is rate-limited in the background.

It supports `@Generable` guided generation and tool calling. iOS 27 adds image input and built-in OCR tools. iOS 27 also opens Apple's PCC model to third-party apps: 32K context, reasoning, free to the developer if under 2M downloads, with per-user daily quotas. Claude and Gemini can be plugged in behind the same `LanguageModelSession` API. For roster screenshots, Vision's `RecognizeDocumentsRequest` (iOS 26) extracts tables on-device.

### Cited Findings
- `SystemLanguageModel` (iOS/iPadOS/macOS/visionOS 26+; no watchOS listed):
  - Check `availability`, which can return `.unavailable(.deviceNotEligible)`, `.unavailable(.modelNotReady)` and other cases.
  - Model versions change with the OS: "26.0 - 26.3", "26.4", "27.0". Retest prompts per version.
  - Other APIs: `contextSize`, `supportedLanguages`, `tokenCount(for:)`, use cases (e.g. `contentTagging`).
  — [Apple docs](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel.md)
- TN3193:
  - "context window of 4096 tokens per language model session".
  - Everything counts: instructions, prompts, tool schemas, `Generable` schemas, outputs.
  - The limit throws `.exceededContextWindowSize`.
  - Recommends "a maximum of 3–5 tools" and splitting tasks across sessions.
  - Updated 31 Mar 2026 for the 26.4 APIs.
  — [TN3193](https://developer.apple.com/documentation/technotes/tn3193-managing-the-on-device-foundation-model-s-context-window.md)
  - InfoQ: `contextSize` and `tokenCount(for:)` are `@backDeployed` — [InfoQ](https://infoq.com/news/2026/03/apple-foundation-models-context)
- iOS 27 context size: "4096 on 26.0, 8192 on 27.0 (newer devices)"; `PrivateCloudComputeLanguageModel().contextSize` is 32768 — [WWDC26 session 319](https://developer.apple.com/videos/play/wwdc2026/319/). Session 241 shows `print(model.contextSize) // 8192` — [WWDC26 session 241](https://developer.apple.com/videos/play/wwdc2026/241/)
- Background limit: `GenerationError.rateLimited` "will only happen if your app is running in the background and exceeds the system defined rate limit" — [Apple docs](https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/ratelimited(_:).md)
- WWDC26 / iOS 27 on-device additions:
  - A rebuilt model with better tool calling.
  - Image `Attachment` input.
  - System tools `OCRTool`, `BarcodeReaderTool` and a Spotlight search (RAG) tool.
  - `DynamicProfile` for switching instructions, tools and models mid-session.
  - Usage accounting via `response.usage`.
  - A `LanguageModel` protocol, so `LanguageModelSession(model:)` can take `SystemLanguageModel`, `PrivateCloudComputeLanguageModel`, or Anthropic/Google Swift packages. Third-party providers need OAuth, Keychain token storage and per-token billing.
  - The core framework is open-sourced.
  — [WWDC26 session 241](https://developer.apple.com/videos/play/wwdc2026/241/)
  - CONFLICT: the session-241 summary table claims the on-device model is on watchOS 27, but the `SystemLanguageModel` docs list no watchOS. Treat on-device FM on Watch as unconfirmed. PCC from watchOS is explicitly stated ("you can even call Private Cloud Compute from watchOS") — [WWDC26 session 319](https://developer.apple.com/videos/play/wwdc2026/319/)
- PCC for third parties:
  - No token costs to the developer, with a per-user, per-iCloud-account daily limit (higher with iCloud+).
  - Quota APIs: `quotaUsage.isLimitReached` and `limitIncreaseSuggestion`.
  - Needs an internet connection and an Apple Intelligence-capable device.
  - Reasoning via `ContextOptions(reasoningLevel:)`.
  — [WWDC26 session 319](https://developer.apple.com/videos/play/wwdc2026/319/)
  - Eligibility per Apple's WWDC26 guide: "If you're enrolled in the App Store Small Business Program and your app has fewer than 2 million total first-time App Store downloads" — [WWDC26 Apple Intelligence guide](https://developer.apple.com/wwdc26/guides/apple-intelligence/). MacRumors mentions only the <2M downloads criterion — [MacRumors](https://www.macrumors.com/2026/06/09/apple-outlines-major-ai-and-developer-tool-updates/). Session 241 says PCC "Requires entitlement" — [WWDC26 session 241](https://developer.apple.com/videos/play/wwdc2026/241/)
  - Minor CONFLICT: session 241 lists reasoning levels `.light` and `.deep`; the session-319 summary lists `.light`, `.moderate` and `.deep`.
- Vision `RecognizeDocumentsRequest` (iOS/iPadOS/macOS/tvOS/visionOS 26+): returns `DocumentObservation` with words, lines, paragraphs, "tables and lists", plus barcodes. `supportedRecognitionLanguages` is available — [Apple docs](https://developer.apple.com/documentation/vision/recognizedocumentsrequest.md)
- App Review 5.1.2(i): "You must clearly disclose where personal data will be shared with third parties, including with third-party AI, and obtain explicit permission before doing so." — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

### Inferences
- Roster pipeline:
  1. Import the screenshot via share sheet, Photos picker or Visual Intelligence `IntentValueQuery` (`pixelBuffer`).
  2. Run `RecognizeDocumentsRequest` to get the table structure.
  3. Normalise the table deterministically to rows and cells.
  4. Use the on-device FM with a small `@Generable struct Shift {date, start, end, role}` to fix ambiguous cells. Chunk to fit the 4K context.
  5. Show a user confirmation UI.
  6. Write to EventKit.
  - Fall back to PCC (32K) for messy rosters on iOS 27. Use third-party (Claude) only with explicit consent under 5.1.2(i).
- Run LLM jobs while the app is foregrounded, or inside a user-initiated `BGContinuedProcessingTask`. Background FM calls can be rate-limited.
- Effect-window "learning" should be classical statistics or Bayesian updating on the app's own logs, not an LLM. Use the LLM only for natural-language summaries and planning suggestions (inference). Devices without Apple Intelligence (e.g. iPhone 11–15 non-Pro) need a non-LLM path.

### Gaps
- On-device model parameter count: not re-verified this session.
- Exact PCC entitlement name and request form, per-user quota sizes, and PCC regional or language availability (e.g. Australia).
- Whether the iOS 27 rebuilt on-device model's 8K context applies to all Apple Intelligence devices or only newer ones (session 319 says "newer devices").

---

## 7. WidgetKit, interactive widgets, Smart Stack relevance, Live Activities (limits), Watch/Mac/CarPlay

### Takeaway
A Live Activity is the natural "medication window" surface, with hard constraints:
- Maximum 8 hours active, plus up to 4 more hours on the Lock Screen (12 hours total).
- 4 KB payload.
- No network or location access inside it.
- It must be started from the foreground, a `LiveActivityIntent`, or a push-to-start.

Widgets get about 40–70 reloads per day. Widget and Live Activity buttons don't run on a locked device until the user unlocks. Live Activities automatically mirror to the Watch Smart Stack, the Mac menu bar and CarPlay.

### Cited Findings
- Live Activity lifetime and size:
  - "A Live Activity can be active for up to eight hours… After the eight-hour limit, the system automatically ends the Live Activity… remains on the Lock Screen… for up to four additional hours… a maximum of 12 hours."
  - "Static and dynamic data… can't exceed a combined size of 4 KB."
  - "unlike a widget — it can't access the network or receive location updates."
  - Truncation above 160 pt height.
  — [Apple docs, Displaying live data with Live Activities](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities.md)
- Starting and scheduling:
  - Start "while the app is in the foreground". Starting from the background is possible "by using an app intent that conforms to `LiveActivityIntent`" (e.g. a Control Center control).
  - A future start can be scheduled with `request(attributes:content:pushType:style:alertConfiguration:startDate:)`, which must include an `AlertConfiguration`.
  - Scheduled activities count towards the concurrent limit.
  - `staleDate` and `relevanceScore` are available.
  - Transient style is `.transient`.
  — [Apple docs](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities.md)
- Push:
  - Push-to-start via `pushToStartTokenUpdates` (not possible on iOS 17.1 and earlier).
  - Priority 10 counts toward an hourly budget; priority 5 doesn't.
  - `NSSupportsLiveActivitiesFrequentUpdates` is available, and users can turn frequent updates off.
  - `dismissal-date` and `stale-date` keys.
  — [Apple docs](https://developer.apple.com/documentation/activitykit/starting-and-updating-live-activities-with-activitykit-push-notifications.md)
- Other devices:
  - "On Apple Watch, Live Activities automatically appear in the Smart Stack… In CarPlay… using the compact presentation." Declare `.supplementalActivityFamilies([.small, .medium])`.
  - They also "automatically appear in the Menu bar of a paired Mac".
  — [Apple docs](https://developer.apple.com/documentation/activitykit/creating-custom-views-for-live-activities.md)
  - "Buttons and toggles on Live Activities don't perform actions in CarPlay." — [Apple docs](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities.md)
- Widget reload budget: "a daily budget typically includes from 40 to 70 refreshes… every 15 to 60 minutes". Timeline entries should be at least about 5 minutes apart. App-intent interactions, foreground app time and animations don't count against the budget. WidgetKit push notifications also exist — [Apple docs](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date.md)
- Interactivity:
  - "On a locked device, buttons and toggles are inactive and the system doesn't perform actions unless a person authenticates and unlocks their device."
  - Interactive families: system small to extra-large plus accessoryCircular/Rectangular on iPhone and iPad.
  - `AppIntent` runs in the widget-extension process; `LiveActivityIntent` / `openAppWhenRun` run in the app process.
  - Interactions with iPhone widgets on a Mac round-trip to the iPhone.
  — [Apple docs](https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities.md)
- Smart Stack relevance:
  - iOS/iPadOS: `TimelineEntryRelevance` (score, duration) and donated `PredictableIntent`s.
  - watchOS: `relevance()` plus `RelevantIntentManager`, or `RelevanceConfiguration` + `RelevanceEntriesProvider` (watchOS only). `RelevantContext` covers date, location (inferred), fitness and sleep.
  — [Apple docs](https://developer.apple.com/documentation/widgetkit/widget-suggestions-in-smart-stacks.md)

### Inferences
- Medication window Live Activity:
  - Start it from the dose-logging intent. `LiveActivityIntent` works from a Control, the Action button or Siri, even when the app is backgrounded.
  - Show onset, peak and wear-off with `Text(timerInterval:)` / progress, and set `staleDate` to the predicted wear-off.
  - An extended-release dose whose effect lasts more than 8 hours will outlive a single Live Activity. Chain a second activity near the 8-hour mark: a scheduled start (with alert) or a push-to-start from a server.
  - The 4 KB limit rules out embedding task lists. Pass IDs and a short state only.
- Widgets can't count down minute-by-minute via reloads. Use dynamic date text for countdowns and reserve timeline reloads for state changes.
- Lock Screen dose logging via widget or Live Activity button requires an unlock (documented). Watch or AlarmKit/notification actions are the lower-friction alternatives.

### Gaps
- The concurrent Live Activity cap per app (documented only as "may depend on a variety of factors").
- The exact push budget per hour.

---

## 8. AlarmKit and notifications (time-sensitive, critical, 64-pending limit, Focus)

### Takeaway
AlarmKit (iOS/iPadOS 26) is the only third-party way to get alarm-grade alerts that "break through the silent mode and the current focus" without the critical-alerts entitlement. It suits "booster due" or "take meds now" moments. Local notifications keep only the soonest 64 pending. Time-sensitive delivery breaks through notification controls (entitlement required). Critical alerts need Apple approval.

### Cited Findings
- AlarmKit availability: iOS 26, iPadOS 26, Mac Catalyst 26 only (no native watchOS or macOS). Types: `AlarmManager`, `Alarm`, `AlarmButton`, `AlarmPresentation`, `AlarmAttributes`, `AlarmMetadata` — [Apple docs](https://developer.apple.com/documentation/alarmkit.md)
- AlarmKit behaviour:
  - "When it fires, the alert breaks through the silent mode and the current focus."
  - Needs `NSAlarmKitUsageDescription`, with authorisation via `AlarmManager.shared` (auto-requested on first alarm).
  - `Alarm.Schedule.fixed(date)` or `.relative` with weekly recurrence (timezone-aware).
  - `Alarm.CountdownDuration(preAlert:postAlert:)`; "If your alarm supports countdown functionality, your app is required to implement it using a Live Activity."
  - Custom secondary-button intents are supported.
  - Alarms appear on Apple Watch "if it's paired to iPhone when the alarm fires".
  - No numeric limit stated.
  — [WWDC25 session 230](https://developer.apple.com/videos/play/wwdc2025/230/)
- Local notification cap: "the system keeps the soonest-firing 64 notifications (with automatically rescheduled notifications counting as a single notification) and discards the rest." This is stated on the legacy `UILocalNotification` doc — [Apple docs](https://developer.apple.com/documentation/uikit/uilocalnotification.md). The current UserNotifications article doesn't restate it — [Apple docs](https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app.md)
- Interruption levels:
  - `passive`
  - `active`
  - `timeSensitive`: "breaks through system notification controls"
  - `critical`: "bypasses the mute switch"
  (iOS 15+ / watchOS 8+) — [Apple docs](https://developer.apple.com/documentation/usernotifications/unnotificationinterruptionlevel.md)
- Critical Alerts entitlement `com.apple.developer.usernotifications.critical-alerts`: plays sound "even when the app is locked, muted, or a person uses Do Not Disturb focus"; request via Apple's form — [Apple docs](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.usernotifications.critical-alerts.md)
- App Review 4.5.4: push notifications "must not be required for the app to function, and should not be used to send sensitive personal or confidential information." — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

### Inferences
- Use AlarmKit sparingly, for user-opted "hard" medication alarms, because it overrides Focus. Use time-sensitive notifications for task nudges and passive for low-priority items. Use Focus filters to downgrade nudges during study Focus.
- With the 64-notification cap, schedule a rolling window (next 24–48 hours) and replenish on app launch, background refresh or `EKEventStoreChanged`.
- Don't put drug names in notification bodies that may show on the Lock Screen or be announced by Siri (4.5.4 spirit; inference).
- Critical alerts are unlikely to be approved for ADHD stimulant reminders (a non-emergency). This is not verified (see Gaps).

### Gaps
- The critical-alerts approval criteria sit behind Apple login and could not be read.
- The time-sensitive entitlement doc page returned 404 in the `.md` form, so its exact requirement text was not captured.
- AlarmKit maximum alarm count.

---

## 9. Screen Time API (FamilyControls, ManagedSettings, DeviceActivity) for focus and distraction blocking

### Takeaway
Self-blocking works on iPhone and iPad through `.individual` authorisation, shields and DeviceActivity schedules. The costs:
- An Apple-approved distribution entitlement, requested for the app AND each extension.
- Opaque tokens.
- Tiny extension memory (6 MB reported for the monitor extension).
- A report extension sandboxed from the network and the app.
- Known threshold-firing bugs (iOS 26.2).
- It is not available on macOS.

iOS 27 did not change these developer APIs.

### Cited Findings
- Entitlement and authorisation:
  - The `com.apple.developer.family-controls` entitlement must be requested before App Store submission.
  - Individual authorisation "requires approval from the owner of the device" with biometric confirmation.
  - `FamilyActivityPicker` returns selections "without revealing their choices to the app".
  — [Apple docs, Family Controls](https://developer.apple.com/documentation/familycontrols.md)
  - Request at the Family Controls distribution form. "If your app includes a Screen Time API app extension such as Device Activity Monitor, Device Activity Report, Shield Action, or Shield Configuration, submit the same request for the extension." — [Apple docs](https://developer.apple.com/documentation/familycontrols/requesting-the-family-controls-entitlement.md)
- DeviceActivityReport (iOS/iPadOS 16, Mac Catalyst): "your extension runs in a sandbox. This sandbox prevents your extension from making network requests or moving sensitive content outside the extension's address space." — [Apple docs](https://developer.apple.com/documentation/deviceactivity/deviceactivityreport.md)
- `DeviceActivityCenter.MonitoringError` has `excessiveActivities`, `intervalTooLong`, `intervalTooShort`, `invalidDateComponents` and `unauthorized`. No numbers are given — [Apple docs](https://developer.apple.com/documentation/deviceactivity/deviceactivitycenter/monitoringerror.md)
- `ManagedSettingsStore`:
  - Available on iOS/iPadOS 15+ and tvOS 26; not macOS.
  - Named stores; `shield`, `application` and `webContent` settings.
  - "The system doesn't guarantee that the settings you specify govern the device's behavior."
  - A newer token-expiry API: `TokenExpiryMessage` and `refresh(_:)` for expired tokens.
  — [Apple docs](https://developer.apple.com/documentation/managedsettings/managedsettingsstore.md)
- Monitor extension memory: crash log "limit=6 MB". A forum poster says there is no way to increase it — [Apple Developer Forums 735454](https://developer.apple.com/forums/thread/735454)
- Bug: `eventDidReachThreshold` fires with 0 minutes of usage on iOS 26.2 (about 50% of days in the reporter's test). FB21450954 — [Apple Developer Forums 811305](https://developer.apple.com/forums/thread/811305)
- Production gotchas:
  - Tokens have "no display name. No bundle identifier" and can't be persisted server-side.
  - Extensions must be "dumb, fast, and stateless".
  - "Roughly 35 percent of installs granted Screen Time permission and then never selected a single app" (one developer's data).
  — [Habit Doom](https://habitdoom.com/blog/shipping-familycontrols-ios)
- iOS 27: new parental features (Time Allowances, Schedule, Ask to Browse / PermissionKit). "Existing FamilyControls and ManagedSettings frameworks unchanged". The self-imposed "Ignore Limit" button remains — [Habit Doom, iOS 27](https://habitdoom.com/blog/ios-27-screen-time-changes)

### Inferences
- Design:
  - Main app: picker + `ManagedSettingsStore(named: .focusBlock)`.
  - `DeviceActivityMonitor` extension applies and removes shields at calendar-block boundaries.
  - `ShieldConfiguration` extension for ADHD-friendly shield copy; `ShieldAction` to "open app to extend".
  - Keep all logic in App Group `UserDefaults`, not SwiftData, inside the extensions (6 MB).
- Shield schedules can be derived from the app's time-blocks, but DeviceActivity schedules have undocumented count and interval limits. Register only the next few blocks and re-register on app launch.
- Mac has no equivalent API. Mac distraction blocking would be out of scope or need a different technique.

### Gaps
- Numeric limits (minimum interval, maximum monitored activities, maximum tokens per shield) are not in Apple docs.
- Entitlement approval turnaround time.
- How Opal, one sec and Jomo implement blocking: one sec's site gives no technical detail — [one sec](https://one-sec.app/). Not verified.

---

## 10. Background execution: BGTaskScheduler, BGContinuedProcessingTask, silent push

### Takeaway
There is no reliable periodic background runtime on iOS. `BGAppRefreshTask` gets up to about 30 seconds when the system chooses. Silent pushes are throttled above 3 per hour. The iOS 26 `BGContinuedProcessingTask` only continues work the user started in the foreground, and it is killed if the user swipes the app away. Continuous "maintenance" must therefore be event-driven. Use HealthKit background delivery, `EKEventStoreChanged` on launch, CLMonitor relaunches, notification actions and App Intents, with a scheduled server push as backup.

### Cited Findings
- `BGAppRefreshTask`: "The system decides the best time… provides your app up to 30 seconds of background runtime". Background pushes: `content-available: 1`, `apns-priority` 5, `apns-push-type: background`, up to 30 seconds. "If you send background pushes more frequently than three times per hour, the system imposes rate limitations." `BGProcessingTask` is for deferrable heavy work — [Apple docs](https://developer.apple.com/documentation/backgroundtasks/choosing-background-strategies-for-your-app.md)
- `BGContinuedProcessingTask` (iOS/iPadOS 26):
  - "starts in the foreground… your app needs to run the task only in response to someone's action".
  - Progress is shown in a system Live Activity and the user can cancel.
  - GPU use requires the `com.apple.developer.background-tasks.continued-processing.gpu` entitlement.
  - The `.fail` / `.queue` strategies exist.
  - "The system cancels any running tasks if a person closes the app in the app switcher".
  — [Apple docs](https://developer.apple.com/documentation/backgroundtasks/performing-long-running-tasks-on-ios-and-ipados.md); [BGContinuedProcessingTask](https://developer.apple.com/documentation/backgroundtasks/bgcontinuedprocessingtask.md)
- HealthKit background delivery caps and the 3-strike rule: see Q3 — [Apple docs](https://developer.apple.com/documentation/healthkit/hkhealthstore/enablebackgrounddelivery(for:frequency:withcompletion:).md)
- Foundation Models are rate-limited in the background — [Apple docs](https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/ratelimited(_:).md)
- SwiftData/CloudKit sync relies on the Remote notifications background mode (silent pushes) — [Apple docs](https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices.md)

### Inferences
- "Background maintenance" (re-planning the day, rolling notifications, rescheduling shields) should run:
  - on every foreground launch
  - in App Intent `perform()` (e.g. after a dose log)
  - in HealthKit observer callbacks
  - in `BGAppRefreshTask` when granted
  - optionally from a server-scheduled silent push at most about 3 per hour
- Use `BGContinuedProcessingTask` for a user-tapped "Re-plan my week" or a roster import, not for autonomous jobs.

### Gaps
- Real-world frequency of `BGAppRefreshTask` for a moderately used app: no primary data found.

---

## 11. Location: CLMonitor, region limits, visits; MapKit ETA/transit; opening hours

### Takeaway
Geofenced errand surfacing is limited to 20 monitored conditions per app, including relaunch-on-trigger. MapKit gives ETA and transit transport types but exposes NO opening hours programmatically. The place-card view controller shows place details, but the app can't read them. Google Places provides hours, but its terms forbid showing its data on a non-Google map and forbid caching anything except place IDs.

### Cited Findings
- Condition monitoring:
  - "Core Location prevents any single app from monitoring more than 20 conditions of any type simultaneously."
  - "If an iOS app isn't running when a condition is satisfied, the system tries to launch it… recreate the monitor with the same identifier."
  - "monitoring can only occur after the user unlocks the device after a reboot."
  - "In macOS, condition monitoring works only while the app is running… The system doesn't launch Mac apps."
  — [Apple docs](https://developer.apple.com/documentation/corelocation/monitoring-the-user-s-proximity-to-geographic-regions.md)
- `CLMonitor` (WWDC23): an actor keyed by name with `CircularGeographicCondition` / `BeaconIdentityCondition` and an `events` async sequence. "You must instantiate only one at time for a given name." The system relaunches the app "as long as it is authorized to receive user location" — [WWDC23 session 10147](https://developer.apple.com/videos/play/wwdc2023/10147/)
- MapKit data: `MKMapItem` exposes `name`, `phoneNumber`, `url`, `pointOfInterestCategory`, `timeZone`, `identifier`/`alternateIdentifiers`, `address`/`addressRepresentations` and `location`. There is no opening-hours property — [Apple docs](https://developer.apple.com/documentation/mapkit/mkmapitem.md)
- `MKMapItemDetailViewController` (iOS 18 / macOS 15): "displays place information such as addresses and phone numbers". Its view hierarchy is private — [Apple docs](https://developer.apple.com/documentation/mapkit/mkmapitemdetailviewcontroller.md)
- `MKDirectionsTransportType` has `automobile`, `walking`, `transit`, `cycling` and `any` — [Apple docs](https://developer.apple.com/documentation/mapkit/mkdirectionstransporttype.md). `calculateETA()` is lighter than full directions. Only one request per `MKDirections` can be in flight — [Apple docs](https://developer.apple.com/documentation/mapkit/mkdirections/calculateeta(completionhandler:).md)
- Google Places policies:
  - "Places API results displayed on a map must be shown on a Google Map, with proper attribution".
  - Only place IDs may be stored indefinitely; other content can't be cached beyond what the terms permit.
  — [Google Places policies](https://developers.google.com/maps/documentation/places/web-service/policies)

### Inferences
- Errand surfacing:
  - Keep at most 20 geofences. Prioritise the nearest or most urgent errands and rotate on significant location change or app launch.
  - Alternatively, create EKReminders with location alarms and let Apple Reminders handle geofencing (no 20-cap on our side; inference).
  - Opening hours:
    - MapKit alone can't answer "is it open?"
    - Options: Google Places (Google Map + attribution, no caching of hours), user-entered hours, or opening a MapKit place card for the user to check.
- ETA: use `calculateETA` with `.transit` for Sydney. Test transit coverage for Sydney before relying on it (see Gaps).

### Gaps
- Apple Maps transit ETA coverage for Sydney via `MKDirections` is not verified.
- `startMonitoringVisits` / significant-change behaviour was not re-fetched (search budget).
- Whether iOS 26/27 added any MapKit hours API: none appears in the current `MKMapItem` symbol list.

---

## 12. watchOS: complications/widgets, Smart Stack, double tap, controls, background limits, quick logging

### Takeaway
Watch quick-logging should use:
- a WidgetKit accessory widget or complication (which also buys 4 background refreshes per hour)
- a watchOS 26 Control
- an App Shortcut (Siri)
- a `.handGestureShortcut(.primaryAction)` button for double tap

Live Activities from iPhone appear automatically in the Smart Stack. The watch app inherits the iPhone app's Calendar access level. Long-running watch sessions are restricted to specific use cases.

### Cited Findings
- Double tap: `handGestureShortcut(_:isEnabled:)` (watchOS 11+) makes double tap perform the control's primary action while the control is in the frontmost scene — [Apple docs](https://developer.apple.com/documentation/swiftui/view/handgestureshortcut(_:isenabled:).md)
- `ControlWidget` on watchOS 26 — [Apple docs](https://developer.apple.com/documentation/swiftui/controlwidget.md)
- Smart Stack on watchOS: `RelevanceConfiguration` / `RelevanceEntriesProvider`; `RelevantContext` clues (time, location, workout, sleep schedule). Widgets that use `RelevanceConfiguration` can't be pinned by users — [Apple docs](https://developer.apple.com/documentation/widgetkit/widget-suggestions-in-smart-stacks.md)
- Live Activities appear in the Watch Smart Stack and as alerts; use `.small` family layouts — [Apple docs](https://developer.apple.com/documentation/activitykit/creating-custom-views-for-live-activities.md)
- Background: 4 HealthKit/app-refresh wakes per hour with an active complication — [Apple docs](https://developer.apple.com/documentation/healthkit/hkhealthstore/enablebackgrounddelivery(for:frequency:withcompletion:).md)
- `WKExtendedRuntimeSession` session types:
  - Self care: frontmost, 10 minutes.
  - Mindfulness: frontmost, 1 hour.
  - Physical therapy: background, 1 hour.
  - Smart alarm: background, 30 minutes, schedulable within 36 hours, must play a haptic.
  - One type per app; start only while active.
  — [Apple docs](https://developer.apple.com/documentation/watchkit/using-extended-runtime-sessions.md); [WKExtendedRuntimeSession](https://developer.apple.com/documentation/watchkit/wkextendedruntimesession.md)
- Calendar access on watchOS matches the companion app — [TN3153](https://developer.apple.com/documentation/technotes/tn3153-adopting-api-changes-for-eventkit-in-ios-macos-and-watchos.md)
- PCC Foundation Models are callable from watchOS 27 — [WWDC26 session 319](https://developer.apple.com/videos/play/wwdc2026/319/)
- watchOS 27: "index-and-thumb widget control" in Smart Stack; Cycle Tracking perimenopause logging (Wikipedia; see the reliability caveat in Q1) — [Wikipedia watchOS 27](https://en.wikipedia.org/wiki/WatchOS_27)

### Inferences
- Watch dose logs should write to local storage and sync to iPhone (WatchConnectivity `transferUserInfo`, or shared CloudKit). Show optimistic UI, because the iPhone may be locked and HealthKit unreadable.
- A "smart alarm" extended session is only appropriate for wake-up use. Don't misuse it for medication timers; use AlarmKit on iPhone, which mirrors to Watch.

### Gaps
- Automatic workout-detection APIs for third parties: not researched in depth.
- Watch↔iPhone HealthKit sync latency.

---

## 13. Data, sync and security: SwiftData + CloudKit, encryption, ADP, App Groups, and the App Review "no health data in iCloud" rule

### Takeaway
SwiftData + CloudKit works with a constrained schema: no unique constraints, all relationships optional, no `.deny` delete rule, additive-only production schema. Mark sensitive fields with `.allowsCloudEncryption` so they become CloudKit encrypted fields, which are E2E-encrypted only when the user has ADP on. App Review 5.1.3(ii) says apps "may not store personal health information in iCloud". This directly threatens syncing dose logs via CloudKit and needs a deliberate compliance decision.

### Cited Findings
- SwiftData sync requires the iCloud and Background Modes (remote notifications) capabilities. CloudKit can't enforce `.unique`; "CloudKit requires all relationships to be optional"; the `.deny` delete rule is unsupported; "CloudKit schemas are additive only"; sync uses the private database via `ModelConfiguration(cloudKitDatabase: .private(...))` — [Apple docs](https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices.md)
- `Schema.Attribute.Option.allowsCloudEncryption` (iOS 17 / watchOS 10 / macOS 14): "Stores the property's value in an encrypted form." — [Apple docs](https://developer.apple.com/documentation/swiftdata/schema/attribute/option/allowscloudencryption.md)
- `CKRecord.encryptedValues`:
  - Encrypted fields can't be indexed or queried.
  - They can only be added as new fields, and not in the public database.
  - "When you enable Advanced Data Protection, the encryption keys are available exclusively to the record's owner".
  — [Apple docs](https://developer.apple.com/documentation/cloudkit/ckrecord/encryptedvalues.md)
- iCloud encryption:
  - Health data, Screen Time and Journal are E2E by default.
  - Reminders and Notes are E2E only with ADP; calendars are never E2E.
  - "Third-party app data stored in iCloud is always encrypted in transit and on server."
  — [Apple Support 102651](https://support.apple.com/en-us/102651)
- App Review:
  - 5.1.3(ii): "Apps must not write false or inaccurate data into HealthKit… and may not store personal health information in iCloud."
  - 5.1.3(i) forbids using health data for ads or data mining.
  - 5.1.2(vi) covers HealthKit data use.
  — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

### Inferences
- Options for dose logs:
  - (a) Local-only on iPhone, with Watch and Mac synced peer-to-peer or through the iPhone.
  - (b) CloudKit private database with `allowsCloudEncryption` on all dose, medication and health fields. This is still "in iCloud", so there is review risk. Get explicit user opt-in and state it in the privacy policy.
  - (c) Your own E2E-encrypted sync (keys in iCloud Keychain).
  - The guideline is ambiguous on whether user-entered medication logs (not read from HealthKit) count. The conservative choice is to never copy HealthKit-sourced data into CloudKit.
- Put data shared with widgets, Live Activities, Screen Time extensions and intents in an App Group container, with file protection `completeUntilFirstUserAuthentication`. Plain `complete` protection would block extensions and background tasks while locked (inference; not re-verified).

### Gaps
- Apple's current interpretation of 5.1.3(ii) for user-entered medication logs (no reviewer statement found).
- Exact file-protection class behaviour for App Group containers was not re-fetched.

---

## 14. Mac and iPad: SwiftUI multiplatform vs Catalyst, MenuBarExtra, which features exist on Mac

### Takeaway
Build SwiftUI multiplatform (native macOS target), with a `MenuBarExtra` "now / next / meds window" item. On Mac, several pillars are missing or degraded:
- No HealthKit data.
- No Screen Time shields.
- AlarmKit only via Catalyst.
- Geofence callbacks only while the app runs.

The Mac gets iPhone Live Activities in the menu bar for free. iPad has HealthKit (iPadOS 17+) and Screen Time.

### Cited Findings
- `MenuBarExtra` (macOS 13+): `.window` style for rich content. Set `LSUIElement` to hide the Dock icon. A menu-bar-only app terminates if the user removes the extra — [Apple docs](https://developer.apple.com/documentation/swiftui/menubarextra.md)
- HealthKit on macOS: framework present but no data — [Apple docs](https://developer.apple.com/documentation/healthkit/hkhealthstore/ishealthdataavailable().md)
- `ManagedSettingsStore` is not available on macOS — [Apple docs](https://developer.apple.com/documentation/managedsettings/managedsettingsstore.md)
- AlarmKit: iOS, iPadOS and Mac Catalyst only — [Apple docs](https://developer.apple.com/documentation/alarmkit.md)
- CLMonitor on macOS: no relaunch — [Apple docs](https://developer.apple.com/documentation/corelocation/monitoring-the-user-s-proximity-to-geographic-regions.md)
- Live Activities appear in the Mac menu bar via iPhone Mirroring — [Apple docs](https://developer.apple.com/documentation/activitykit/creating-custom-views-for-live-activities.md)
- Controls on macOS 26 — [Apple docs](https://developer.apple.com/documentation/swiftui/controlwidget.md)
- macOS 27 is Apple-silicon only (Wikipedia) — [Wikipedia macOS 27](https://en.wikipedia.org/wiki/MacOS_27)

### Inferences
- The Mac app is a planning console: calendar, task blocks and roster import. Its medication state comes from synced app data, not HealthKit.
- Catalyst would add AlarmKit on Mac, but at the cost of Mac-native UX. Native SwiftUI is preferred (inference).

### Gaps
- There was no direct Apple guidance comparing Catalyst and SwiftUI multiplatform in 2026.

---

## 15. Accessibility features relevant to ADHD/cognition; Journaling Suggestions

### Takeaway
Developers can:
- Support Assistive Access with a dedicated SwiftUI scene (iOS 26+).
- Honour Reduce Motion and Dynamic Type.
- Integrate the Journaling Suggestions picker (entitlement-gated; the app only receives what the user picks).

Background Sounds and Vocal Shortcuts are user-level system features with no developer API found. They integrate indirectly: Vocal Shortcuts can trigger App Shortcuts (unverified).

### Cited Findings
- `AssistiveAccess` scene: "A scene that presents an interface appropriate for Assistive Access on iOS and iPadOS", iOS 26+ — [Apple docs](https://developer.apple.com/documentation/swiftui/assistiveaccess.md)
- `accessibilityReduceMotion`: "UI should avoid large animations" — [Apple docs](https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion.md)
- Journaling Suggestions:
  - iOS 17.2+, iPadOS 26+.
  - `JournalingSuggestionsPicker` requires the `com.apple.developer.journal.allow` entitlement.
  - "your app can't access the details for a suggestion until after a person chooses to share them".
  - Catalyst ignores it.
  — [Apple docs](https://developer.apple.com/documentation/journalingsuggestions.md)
- The App Intents Journaling schema domain is Shortcuts-only (not Siri AI) — [Apple docs](https://developer.apple.com/documentation/appintents/app-schema-domains.md)

### Inferences
- An "Assistive Access" simplified scene (big Log Dose / Now / Next buttons) doubles as a low-cognitive-load mode for ADHD users.
- The Journaling Suggestions picker could seed an end-of-day reflection. It is optional and picker-only, so there is no passive data.

### Gaps
- Vocal Shortcuts and Background Sounds developer hooks: the Apple Support page fetched didn't cover them, so they are unverified.

---

## 16. App Store Review rules: HealthKit, medications, Screen Time entitlement, AI

### Takeaway
The main review risks are:
- 1.4.2: drug dosage calculators must come from approved entities.
- 1.4.1: medical claims need validated accuracy.
- 5.1.3(ii): no personal health information in iCloud.
- 5.1.2(i): explicit consent before sending data to third-party AI.
- The separately approved Family Controls entitlement.

The app must present its medication-window feature as self-tracking and reflection, not dosing advice.

### Cited Findings
- 1.4.1: accuracy claims need disclosed methodology. Apps "should remind users to check with a doctor… before making medical decisions."
- 1.4.2: "Drug dosage calculators must come from the drug manufacturer, a hospital, university, health insurance company, pharmacy or other approved entity, or receive approval by the FDA or one of its international counterparts."
- 5.1.1: privacy policy, consent, and account deletion.
- 5.1.2(i): third-party AI disclosure and permission.
- 5.1.3(i)/(ii): health data use limits; no false data in HealthKit; no personal health information in iCloud.
- 4.5.4: push notifications.
— [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- The Family Controls distribution entitlement requires Apple review of the app and each extension — [Apple docs](https://developer.apple.com/documentation/familycontrols/requesting-the-family-controls-entitlement.md)
- HealthKit apps must not use HealthKit data for ads, must not disclose it to third parties without permission, and need a privacy policy — [Apple docs](https://developer.apple.com/documentation/healthkit/protecting-user-privacy.md)

### Inferences
- A booster feature that says "take X mg at 13:00" risks 1.4.2. Framing it as "your logged booster usually happens around…" plus a clinician-set plan the user enters is safer (inference).
- Effect-window charts should carry "not medical advice / check with your doctor" copy (1.4.1).
- Australian regulation (TGA software-as-a-medical-device) is out of scope here but relevant. Flag it to the report writer.

### Gaps
- The fetched guideline excerpt had no explicit Screen Time-specific guideline text.
- Critical-alerts approval criteria (login-gated).

---

## 17. Capability matrix (summary)

### Takeaway
This table condenses the findings above; sources are in the relevant sections.

### Cited Findings

| Capability | Framework / API | Min OS | Permission / entitlement | Hard limits / gotchas | Design recommendation |
|---|---|---|---|---|---|
| Read Health med list and doses | HealthKit `HKUserAnnotatedMedication`, `HKMedicationDoseEvent`, `HKUserAnnotatedMedicationQueryDescriptor`, `HKAnchoredObjectQuery` | iOS/iPadOS/watchOS/macOS 26 (no data on Mac) | HealthKit capability; `requestPerObjectReadAuthorization(for:predicate:)`; `NSHealthShareUsageDescription` | READ-ONLY: third parties can't write doses. Per-medication user selection. Events may be back-dated, deleted or re-saved. Using `requestAuthorization(toShare:read:)` fails. | Own dose log is the source of truth. Optional Health import with anchor and delete handling. Use RxNorm codes to classify stimulants. |
| Sleep, HR/HRV, workouts, State of Mind, cycle, daylight | HealthKit `sleepAnalysis` (stages), `HKStateOfMind`, `timeInDaylight`, `menstrualFlow` etc., `HKWorkoutSession` | iOS 16 (stages) / 17 (daylight, iPhone workouts) / 18 (State of Mind); 27 adds menopause types and workout zones | Per-type read; background-delivery entitlement | Store locked when device locked; read denial invisible; background delivery hourly-max for many types (iOS), 4/hr on watch with complication; 3 missed completions stop delivery; no data on Mac | Compute features on foreground/unlock; observer queries in `didFinishLaunching`; treat "no data" as unknown, not zero |
| Sleep schedule / wake alarm | None (Shortcuts automations; WidgetKit `RelevantContext.sleep` for watch relevance) | — | — | No API to read bedtime or wake time | Ask the user, or offer a Shortcuts "Wake Up" automation that calls an App Intent |
| Calendar scheduling and edit detection | EventKit `EKEventStore`, `EKEvent`, `EKEventStoreChanged` | iOS 17 access model | Full access (`NSCalendarsFullAccessUsageDescription`); write-only can't read its own events | Change notification has no diff; `eventIdentifier` changes when calendar changes; external ID shared by all occurrences, differs by platform on Exchange; duplicates; calendars not E2E even with ADP | App UUID in event `url`/notes plus local map; full refetch and diff of horizon; dedicated app calendar; neutral titles |
| Reminders | EventKit `EKReminder` | iOS 17 | Full access (`NSRemindersFullAccessUsageDescription`) | No subtasks, flags, sections or tags via API | Use Reminders only for simple items and location alarms; keep rich task structure in app |
| Siri / voice / Shortcuts / Spotlight | App Intents, `AppShortcutsProvider`, App Schemas (`.calendar`, `.reminders`), `IndexedEntity`, `.appEntityIdentifier` | iOS 16 (App Shortcuts); iOS 27 (Siri AI schemas) | None (Siri AI needs iPhone 15 Pro+, English, not EU/China at launch) | No health or medication schema; Journaling schema Shortcuts-only; excessive donations ignored | "Log dose / booster" App Shortcuts; entities for tasks and blocks under reminders/calendar schemas; donate real interactions |
| Action button / Control Center / Lock Screen controls | `ControlWidget` + `LiveActivityIntent` | iOS 18; macOS/watchOS 26 | — | Template-based UI only | One-press "Log dose" control that also starts the medication-window Live Activity |
| On-device LLM | Foundation Models `SystemLanguageModel`, `LanguageModelSession`, `@Generable`, `Tool` | iOS/iPadOS/macOS 26 (no watchOS on-device per docs) | None; needs Apple Intelligence device and enabled | 4,096 tokens (26.x), 8,192 (27, newer devices); `rateLimited` in background; model changes per OS version; 3–5 tools advised | Structured extraction and summaries only; chunk inputs; non-LLM fallback for ineligible devices |
| Cloud LLM | `PrivateCloudComputeLanguageModel`; third-party `LanguageModel` packages (Claude, Gemini) | iOS 27 (also watchOS 27) | PCC entitlement; Small Business Program and <2M downloads for free use; explicit consent for third-party AI (5.1.2(i)) | Per-user daily quota (`quotaUsage`); internet required; 32K context | Escalate hard parses (messy rosters, weekly planning) to PCC; Claude only with opt-in |
| Roster screenshot OCR | Vision `RecognizeDocumentsRequest` (tables); FM `OCRTool` (iOS 27); Visual Intelligence `IntentValueQuery` | iOS 26 | Photos picker / share sheet (no library permission needed with picker) | Visual Intelligence gives only a pixel buffer; results UI about 3 lines | Vision table extraction → deterministic parse → FM clean-up → user confirm → EventKit |
| Widgets | WidgetKit timelines, interactive `Button(intent:)` / `Toggle` | iOS 17 (interactive) | — | 40–70 reloads/day; entries ≥ ~5 min apart; buttons inactive while locked | Dynamic date text for countdowns; reload on state change only; relevance scores for Smart Stack |
| Medication-window live display | ActivityKit Live Activities (Dynamic Island, Lock Screen, Watch Smart Stack, CarPlay, Mac menu bar) | iOS 16.1+; push-to-start 17.2+; scheduled start with `startDate` | `NSSupportsLiveActivities`; user can disable | 8 h active + 4 h Lock Screen (12 h max); 4 KB state; no network or location; start from foreground, `LiveActivityIntent` or push; no CarPlay button actions; concurrency cap unspecified | Start from dose-log intent; `staleDate` = predicted wear-off; chain a second activity for XR doses over 8 h |
| Break-through alerts | AlarmKit `AlarmManager`, `Alarm.Schedule`, countdown + Live Activity | iOS/iPadOS 26 (Catalyst) | `NSAlarmKitUsageDescription` + user authorisation | Overrides Silent and Focus (use sparingly); countdown needs a Live Activity; no native watch or macOS API | Opt-in "hard" med alarms and booster-due alerts only |
| Notifications | UserNotifications, interruption levels, critical alerts | iOS 15 (levels) | Time-sensitive entitlement; critical alerts need Apple-approved entitlement | 64 soonest pending local notifications kept; push must not carry sensitive info | Rolling 24–48 h schedule refilled on launch and events; no drug names on Lock Screen |
| Focus integration | `SetFocusFilterIntent` | iOS 16 / watchOS 9 / macOS 13 | — | App only learns the filter values it's configured with | Auto-enter study mode; suppress non-critical nudges |
| Distraction blocking | FamilyControls (`.individual`), ManagedSettings shields, DeviceActivity monitor, report, shield extensions | iOS 16 (individual); not macOS | Family Controls distribution entitlement for app AND each extension; Face ID/Touch ID consent | Opaque, expiring tokens; monitor extension 6 MB RAM; report extension can't export data; undocumented schedule and activity caps; threshold false positives (iOS 26.2); user can revoke | Shield during calendar focus blocks; stateless extensions using App Group defaults; re-register the next few schedules on launch |
| Background upkeep | `BGAppRefreshTask`, `BGProcessingTask`, `BGContinuedProcessingTask`, silent push | iOS 13 / iOS 26 (continued) | Background Modes; GPU entitlement for continued-processing GPU | Refresh ≈ ≤30 s at system discretion; silent push throttled above 3/hr; continued task must be user-initiated and dies on app-switcher close | Event-driven design; server push as backstop; user-tapped re-plan via continued task |
| Location errands | CoreLocation `CLMonitor` (`CircularGeographicCondition`) | iOS 17 | Location ("Always" for background relaunch) | 20 conditions per app; no monitoring before first unlock after reboot; no Mac relaunch | Rotate the nearest 20 errands; or use EKReminder location alarms |
| ETA and hours | MapKit `MKDirections.calculateETA`, `.transit`; `MKMapItemDetailViewController`; Google Places API | iOS 7 (ETA); iOS 18 (place card) | — / Google API key | No opening-hours property in MapKit; Google data must sit on a Google Map with attribution and can't be cached | ETA via MapKit; hours via Google Places (compliant UI) or user-entered |
| Watch quick log | WidgetKit complications, watchOS Controls, `handGestureShortcut`, App Shortcuts, `WKExtendedRuntimeSession` | watchOS 10/11/26 | Calendar access inherits from iPhone | 4 background wakes/hr with complication; extended sessions limited to 4 purpose types | Complication + control + double-tap button; local write then sync |
| Sync and storage | SwiftData + CloudKit (private DB), `.allowsCloudEncryption`, `CKRecord.encryptedValues`, App Groups | iOS 17 | iCloud + Remote notifications capabilities | No unique constraints; optional relationships; additive schema; E2E only with ADP; App Review 5.1.3(ii) "may not store personal health information in iCloud" | Encrypt all health fields; opt-in cloud sync or local plus device sync; never mirror HealthKit data to iCloud |
| Mac | SwiftUI multiplatform, `MenuBarExtra`, Controls | macOS 13 (MenuBarExtra); macOS 27 Apple silicon only | — | No HealthKit data; no Screen Time; AlarmKit only via Catalyst | Planning console plus menu-bar "meds window / next block" |
| Cognitive accessibility | `AssistiveAccess` scene, `accessibilityReduceMotion`, Dynamic Type | iOS 26 (AssistiveAccess) | — | — | Simplified "Now / Next / Log" scene; honour Reduce Motion |
| Journaling prompts | JournalingSuggestions `JournalingSuggestionsPicker` | iOS 17.2 / iPadOS 26 | `com.apple.developer.journal.allow` | Picker-only; the app sees only what the user selects | Optional evening reflection |

### Inferences
- Design-breaking constraints to escalate to the report writer:
  1. The app cannot write doses to Apple Health.
  2. Live Activities cap at 8 hours active (12 hours visible), and widget or Live Activity buttons need an unlock.
  3. There is no API for the Sleep Schedule or wake alarm.
  4. There is no reliable periodic background execution.
  5. Screen Time needs a separately approved entitlement and is iPhone/iPad-only.
  6. MapKit exposes no opening hours.
  7. App Review 1.4.2 (dosage calculators) and 5.1.3(ii) (health data in iCloud) constrain the booster feature and the sync design.
  8. Siri AI and the on-device LLM exclude pre-iPhone-15-Pro devices and, at launch, non-English locales and the EU and China.

### Gaps
- See the per-section Gaps. The biggest unknowns are:
  - whether a special entitlement is needed for medication reads
  - numeric Screen Time limits
  - critical-alert approval criteria
  - Apple Maps transit coverage in Sydney
  - Siri AI availability in Australia
  - how App Review interprets 5.1.3(ii) for user-entered medication logs
