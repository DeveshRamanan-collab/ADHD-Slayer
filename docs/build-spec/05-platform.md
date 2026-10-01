# Focus: Apple platform

Every Apple integration with its exact requirements. **Built** means it exists in `app/FocusApp`; **To build** means it doesn't yet. Screens: `01-product-and-features.md`; models and planning: `04-intelligence.md`; server side (accounts, App Store Server Notifications, sync): `02-backend.md`.

## Targets and baseline

- App target `FocusApp`: bundle id `au.adhdslayer.focus`, display name "Focus", iOS 26.0 minimum, iPhone only, portrait only, SwiftUI, Swift 6 language mode with default `MainActor` isolation. iOS 27 features only behind `if #available(iOS 27, *)` with a working iOS 26 path.
- Local package `FocusCore` (iOS 26, macOS 26, watchOS 26): `FocusModel` (shared types), `FocusMedication` (the only code that can write doses), `FocusPlanning` (learning, scheduler, safety gate; cannot import `FocusMedication`). 31 tests pass.
- Device floor: Apple Intelligence (iPhone 15 Pro or newer). There is no App Store device key for it, so the launch check (`04-intelligence.md`) is the control; the listing states the requirement.
- To build: a widget extension `FocusWidgets` (bundle id `au.adhdslayer.focus.widgets`) for the Live Activities, widgets and the Control Center control; later a watchOS app.

## StoreKit 2

### Products and group (Built in `Model/Store.swift` and `Products.storekit`)

| Product id | Period | Local test price (AUD) | Introductory offer | Family Sharing |
|---|---|---|---|---|
| `au.adhdslayer.focus.plus.monthly` | 1 month | 7.99 | Free trial, 1 month, 1 period | Off |
| `au.adhdslayer.focus.plus.yearly` | 1 year | 59.99 | Free trial, 1 month, 1 period | Off |

- One subscription group, "Focus Plus", both products at the same level; display names "Focus Plus, monthly" and "Focus Plus, yearly"; description "Unlimited kinds of day and activity categories."
- Apple's trial periods are fixed, so the trial is 1 month, not 31 days; copy says "a month" and always reads the period from StoreKit (`Store.trialLength`, "1 month").
- Plus unlocks unlimited kinds of day and activity categories (free: 3 and 5, `Store.freeDayTypes`, `Store.freeCategories`). Everything else is free. Starting a trial or buying never requires Health, calendar, notifications or your own AI.
- Real prices are set in App Store Connect; the local file's prices are placeholders.

### Loading, eligibility and purchase (Built)

- `Store.start()` runs at app start: a `Transaction.updates` listener (finish each verified transaction, then refresh) and a first `refresh()`.
- `refresh()`: `Product.products(for:)` sorted by price (monthly first); `loadFailed` when empty or thrown; intro eligibility from `subscription.isEligibleForIntroOffer` (group level); then entitlements from `Transaction.currentEntitlements`.
- Eligible people see "Start my free month" and "Free for 1 month, then {price}…"; people who used a trial see "Get Plus" and the price terms only.
- `purchase(_:account:)` passes `Product.PurchaseOption.appAccountToken(accountID)` (the server account UUID) so App Store Server Notifications V2 map to the account; unlocks only on a `.verified` transaction, then `finish()` and refresh.
- Outcomes: `.purchased` (`success` haptic, schedule the trial reminder when in trial); `.pending` for Ask to Buy or extra authentication ("Waiting on Apple to approve that. You can keep going."; the update arrives later through `Transaction.updates`); `.userCancelled` (nothing); unverified ("Apple couldn’t verify that purchase."); thrown ("That didn’t go through. Nothing was charged.").
- Paywall disclosures on screen: price and period from StoreKit, trial length and what follows, auto-renewal, how and when to cancel (at least 24 hours before the trial ends), the 2-day reminder, Apple handling payment, working Terms and Privacy links, and Restore purchases.

### Entitlement states

| Apple state | Focus status | Plus | What the person sees (Settings, Focus Plus) |
|---|---|---|---|
| Never subscribed | `free` | No | "Free" |
| Subscribed in the intro offer | `trial(until:)` | Yes | "Free trial until 30 Oct" |
| Subscribed | `plus(renews:)` | Yes | "Plus, renews 12 Mar" (To build: "Plus, ends 12 Mar" when auto-renew is off) |
| In grace period | `plus` | Yes | To build: a calm line, "Apple couldn’t take the last payment. Update it in your Apple account to keep Plus." |
| In billing retry | `lapsed` | No | To build: the same line |
| Expired | `lapsed` | No | "Free (Plus ended)" |
| Revoked (refund) | `lapsed` | No | "Free (Plus ended)" |

- Built: status comes from `Transaction.currentEntitlements` (verified, one of the two products, no `revocationDate`); trial when `transaction.offer?.paymentMode == .freeTrial`; losing an active Plus becomes `lapsed`.
- To build: read `Product.SubscriptionInfo.status` for the group to tell grace period, billing retry and auto-renew off apart; switch on Billing Grace Period (16 days) in App Store Connect.
- Lapse behaviour: nothing is deleted or switched off; extra kinds of day and categories keep working; only adding beyond the free limit opens the upsell.
- The `-plus` launch argument forces Plus for demos and UI tests only.

### Restore, offer codes, refunds, management (Built unless marked)

- Restore purchases (paywall and Settings): `AppStore.sync()` then refresh; toast "Checked with Apple."
- Redeem a code (Settings): `.offerCodeRedemption(isPresented:)`; the redeemed transaction arrives through `Transaction.updates`. Offer codes are created in App Store Connect (for example for the co-design panel).
- Manage subscription (Settings): `.manageSubscriptionsSheet(isPresented:)`. The route to cancel is never hidden or moved.
- Refunds: Apple decides; the app never promises one. A refund arrives as a revoked transaction and Plus ends quietly. To build: "Request a refund" through `.refundRequestSheet(for:isPresented:)` on the latest transaction.
- Family Sharing is off: Plus is personal.
- Account deletion doesn't cancel the subscription; the confirm text says so.

### Trial reminder (Built, `Model/Reminders.swift`)

- After a purchase that starts a trial: ask notification permission, then schedule one local notification, id `trial-ending`, at 10:00 two days before the trial's expiry (60 s from now if that's past), interruption level passive.
- Title "Your free month ends Friday" (weekday of the end date); body "Keep Plus, or let it lapse and carry on free. Both are completely fine. You can change it in Settings."
- To build: re-schedule on every refresh (same id, so never duplicated) and remove it when no longer in a trial.

### Local testing and App Store Connect

- `app/FocusApp/Products.storekit`: group "Focus Plus", both products and offers above, storefront AUS, locale en_AU, Family Sharing off, no failure injection.
- The shared scheme `FocusApp` (`xcshareddata/xcschemes/FocusApp.xcscheme`) references the file in its Launch action (`StoreKitConfigurationFileReference`), so every run uses local StoreKit. Test renewals, grace period, billing retry, refunds, Ask to Buy and offer codes with Xcode's Transaction Manager; sandbox testers for TestFlight. UI tests use `SKTestSession` (To build).
- App Store Connect (To build): Paid Apps agreement, Small Business Program, the group and both products with the ids above, the 1 month free trial for new subscribers in every storefront, en-AU localisations, review screenshot and notes, Billing Grace Period, Family Sharing off, and the App Store Server Notifications V2 URL (`02-backend.md`).

## App Intents and App Shortcuts (Built, `Model/Intents.swift`)

| Intent | Opens the app | Authentication | Does |
|---|---|---|---|
| `LogMedicationIntent` "Log my medication" | No | Required (Face ID on a locked phone) | Runs the Log all path with the double-dose guard; replies in one spoken sentence |
| `OpenMedicationIntent` "Open my medication" | Yes | None | Opens You, Medication |

- `AppModel` is registered with `AppDependencyManager` in the app's `init`, so intents log through the same model, dose log and guard as the app.
- Spoken replies never name a medicine: "Logged one dose.", "Logged 2 doses.", "One was already logged, so I left it.", "Nothing to log right now.", "Couldn’t save that. Nothing was changed."
- `FocusShortcuts` (App Shortcuts, available at install): "Log my meds in Focus", "Log my medication in Focus", "Focus log meds" (short title "Log my meds", symbol checkmark.circle); "Open my medication in Focus" ("Medication", pills). Tile colour grey brown.
- Why authentication: `medication.json` has complete file protection, so a locked phone must be unlocked to read or write it; it also stops anyone else logging on a locked phone.
- To build: conform `LogMedicationIntent` to `LiveActivityIntent` (runs in the app process from controls and widgets, and can start the Live Activity); record the real origin (Siri, Shortcuts, Action button) instead of always `actionButton`; `CheckInIntent(answer:)` for notification buttons; `LogDoseIntent(medication:takenAt:)` with a `MedicationEntity` shown by its kind name in discreet mode.
- Intents are permanent public surface: never rename or remove an intent or parameter; add only optional parameters.
- There is no medication domain in Siri's app schemas; medication stays on these fixed phrases, which work on every supported iPhone without Siri AI.

## Action button, Back Tap and Siri (Built)

- Action button: Settings, Action Button, Shortcut, "Log my meds". Every Apple Intelligence iPhone has one. When the control exists it can be picked directly (To build).
- Back Tap, for people using the Action button for something else: Settings, Accessibility, Touch, Back Tap, Double Tap (or Triple Tap), "Log my meds".
- Siri: "Log my meds in Focus". Works through AirPods and hands free.
- Every path logs "everything set for about now" through the same guard, and the next app open shows the ticks, the bounce and the updated bottom bar.
- The setup page and the pitch after the first medication save are described in `01-product-and-features.md`.

## Control Center control (To build)

- Needs the widget extension. A `ControlWidget` of kind `au.adhdslayer.focus.log` with `ControlWidgetButton(action: LogMedicationIntent())`, label "Log my meds", symbol checkmark.circle. Placeable in Control Center, on the Lock Screen and on the Action button.
- The intent source is a member of both targets and conforms to `LiveActivityIntent`, so it runs in the app process with `AppModel`.
- After a press the label reads "Logged 8:10" (from the shared snapshot); never a medicine name. Controls are template-only: no custom styling.

## Widgets (To build)

- In `FocusWidgets`:
  - Lock Screen rectangular: "2 of 4 logged" and "Next 6:00"; circular: a ring of logged over planned; inline: "All 4 logged".
  - Home Screen small: the current block and time left; medium: Now and Next, time left, and a Log button (`Button(intent: LogMedicationIntent())`, which asks to unlock on a locked phone).
- Data: a `GlanceSnapshot` JSON file of at most 4 KB in the App Group container (`group.au.adhdslayer.focus`), written atomically after every replan and log. It holds counts, times, now and next titles, window times and the discreet flag; never a medicine name while discreet mode is on. Readers ignore unknown keys and treat a newer version as "Open Focus to update".
- The snapshot uses `completeUntilFirstUserAuthentication` so the Lock Screen can read it; medication data itself stays under complete protection.
- Reloads: `WidgetCenter.shared.reloadAllTimelines()` only after a log or replan; timeline entries at block edges; countdowns with `Text(timerInterval:)`, never minute-by-minute reloads (the daily budget is about 40 to 70). Higher `TimelineEntryRelevance` around planned dose times and block starts.

## Live Activities (To build; spec in 10-live-activities.md)

- Two local Live Activities from the `FocusWidgets` extension: Focus mode (task, time left, Done and +5 min) and Your day (the stretch you're in, the next 8 hours as one bar, what's next, an optional Log button).
- Suggested shape: shared types in a `FocusGlance` package target (`FocusActivityAttributes`, `ContentState`, the stretch palette); a `LiveActivityController` in the app starts, updates and ends them; buttons are `LiveActivityIntent`s.
- Presentations: Lock Screen, Dynamic Island compact, minimal and expanded, StandBy, and `.supplementalActivityFamilies([.small, .medium])` for the Watch Smart Stack and CarPlay (buttons are hidden there).
- Info.plist `NSSupportsLiveActivities` YES; no push updates. If the person turns Live Activities off in iOS Settings, the Customise page says so and the bottom bar carries the same glance.

## Apple Watch (To build, after the iPhone launch)

- A watchOS 26 app and complication: one Log button with `.handGestureShortcut(.primaryAction)` (double tap), the day's glance, wrap-up taps.
- Logs are written on the Watch first (source `watch`, which `DoseEvent` already has) with its own guard over a 36 h copy of dose events and re-log intervals; sent with WatchConnectivity `transferUserInfo`, de-duplicated by event id on the phone; the day snapshot comes back with `updateApplicationContext`. No login on the Watch.
- The Live Activities appear in the Watch Smart Stack automatically once they are built.

## EventKit (Built: read today)

- Access: full access through `requestFullAccessToEvents()`, asked only from Personalise ("Let Focus read your calendar") or Settings, Permissions ("Allow"); never at launch.
- `NSCalendarsFullAccessUsageDescription`: "Focus reads today’s events so your plan fits around them, and spots plans with other people. Nothing is uploaded."
- Read: every calendar's events from local midnight for 24 h, all-day events excluded; per event the identifier (block id `cal-{eventIdentifier}`), title ("Busy" if none), start and end. They become fixed blocks and feed plans-with-people suggestions.
- Never written unless the person asks. To build: an explicit "Add to my calendar" per block, writing to a Focus-owned calendar with neutral titles and the app's block id in the event URL; third-party events are never edited or deleted. Calendars aren't end-to-end encrypted, so nothing about medication is ever written there.
- To build: attendee counts for social detection; per-calendar exclusion in Settings; a 7-day horizon for Plan; reload and replan on `EKEventStoreChanged` and on foreground; when access was refused, "Allow" opens iOS Settings (the prompt never shows twice).
- Denied: planning works without a calendar; suggestions show the request text instead.

## HealthKit (To build; read only: sleep)

- Capability HealthKit (`com.apple.developer.healthkit`); `NSHealthShareUsageDescription`: "Focus reads your sleep so your rhythm pages can show how sleep and your days travel together. It never writes to Health."
- Read only `HKCategoryType(.sleepAnalysis)`: last night's asleep samples (core, deep, REM, unspecified), falling back to in bed. Used on Rhythm, Sleep and done. No writes (`toShare` empty); no medication types at launch.
- Asked on the Sleep page with an explanation first, never at launch. Read in the foreground only (the store is unreadable while locked); no background delivery.
- A denied permission looks like no data: show "No sleep from Health yet", never "connected" and never zero.
- Sleep never sets a window, never triggers an alert, and is never linked to medication. Health data is never stored in iCloud and never used for ads.

## Notifications

| Type | When | Interruption level | Status |
|---|---|---|---|
| Trial ending | 10:00, two days before the trial ends | Passive | Built |
| Reminder you set | Only at times the person turns on, per dose slot | Active; time sensitive only if they switch on "Let this through Focus" | To build |
| Check-in "Working now?" | Learning phase, at the model's next check-in time | Active | To build |
| Wrap-up | 5 min before a block ends when something fixed follows | Active | To build |

- Budget: at most 5 delivered per local day across all types. Priority: reminders the person set, then wrap-ups, check-ins, account notices; lower ones are dropped, never piled up for later. The reminder editor allows at most 5 reminder times a day. On a Low brain-weather day check-ins and wrap-ups are halved.
- Wording: titles and bodies never name a condition or a medicine and never say "take", "skip", "due", "catch up" or give timing advice. Reminders read "Reminder you set: Morning". Every template passes the `SafetyGate` notification context. No images, no badges: request `.alert` and `.sound` only (the code also asks for `.badge`; drop it).
- Actions: a reminder offers "Logged it" (runs the logging intent for that slot through the guard; needs authentication) and "Open"; snooze and dismiss never log. A check-in offers Yes, Partly and No, answered in the background.
- Scheduling: a rolling 48 h window of local notifications, never more than 64 pending; refilled on launch, foreground, every replan and every log; ids per type, slot and day; thread identifiers by type. No push notifications at launch.
- Time sensitive needs the Time Sensitive Notifications capability and is used only for reminders the person marked. Never critical alerts; AlarmKit only later, opt in.
- Permission is asked in context (a trial starting, the first reminder, or Settings, Permissions), never at launch.

## Core Haptics (Built, `Design/Haptics.swift`)

- Patterns are lists of events: time (s), intensity, sharpness, duration (0 means a tap; above 0 a continuous hum). Intensity is multiplied by the Strength setting (0.3 to 1.3) and capped at 1. With Vibrations off (`hapticsEnabled`), nothing plays, including system feedback. Slider ticks respect "Ticks on sliders" and play at most once per 35 ms.

| Moment | When it plays | Pattern: time, intensity, sharpness, duration | Fallback |
|---|---|---|---|
| `arrival` | Daily arrival page appears | 0, .12, .05, 1.1 hum; .35, .35, .2; .62, .45, .25; .95, .6, .3 | Soft impact .6 |
| `splash` | Start animation begins | 0, .08, .05, 1.6 hum; .9, .3, .15; 1.3, .45, .2; 1.65, .8, .35; 1.72, .25, .1, .5 hum | Soft impact .6 |
| `land` | Greeting appears; Plan beads appear; your AI answers | 0, .35, .2 | Selection |
| `logged` | One dose logged; the one-press illustration presses | 0, .45, .3; .13, .75, .45; .2, .18, .1, .35 hum | Success |
| `logAll` | Several doses logged at once | 0, .4, .3; .12, .55, .38; .24, .7, .45; .36, .9, .55; .44, .22, .1, .5 hum | Success |
| `complete` | A block marked done | 0, .35, .25; .09, .5, .35; .18, .75, .5 | Success |
| `choose` | Picking an answer, chip, kind, colour, symbol, weekday, plan card, row | 0, .5, .4 | Selection |
| `tap` | Any other button | 0, .35, .5 | Light impact |
| `toggle` | A switch flipped | 0, .5, .6; .06, .25, .3 | Selection |
| `tick` | A slider passes a step; a page is reordered | 0, .28, .7 | Selection |
| `acknowledge` | "I understand"; "Yes, store them"; destructive confirms; connecting or disconnecting your AI | 0, .7, .6; .16, .9, .7 | Rigid impact |
| `success` | Signed in; purchase; medication, kind of day or category saved; page added | 0, .3, .2; .1, .55, .3; .22, .85, .4; .3, .2, .1, .6 hum | Success |
| `nudge` | Coach bubble; the honest bit; Customise warning; one-press pitch | 0, .25, .15; .18, .35, .2 | Light impact |
| `caution` | Plan limit reached; sign-in or purchase error; Log all failure; your-AI warning; To build: the double-dose guard | 0, .6, .8; .12, .6, .8 | Warning |
| `breatheIn` | Each breath in (4 s) | 0, .05, .05, 4.0 hum; 1.0, .12, .08; 2.0, .2, .1; 3.0, .3, .12 | Soft impact .6 |
| `breatheOut` | Each breath out (6 s) | 0, .3, .12; 1.5, .2, .1; 3.0, .12, .08; 4.5, .06, .05 | Soft impact .6 |
| Hold ramp | While holding "Hold to log another" | One 1.2 s hum, sharpness .3, intensity rising from .08 to .8 | None |

- System feedback alongside: a selection tick on tab change, a soft impact (0.5) on page change, a warning when the time ring enters wrap-up, a selection tick per 15 min of Patterns handle travel.
- Engine: one `CHHapticEngine`, created lazily with auto shutdown, rebuilt after a reset or stop, guarded by a lock; when the hardware has no haptics (Simulator) the fallback `UIFeedbackGenerator` plays instead.
- Every haptic moment has a visual equivalent.

## Liquid Glass and motion

- System chrome is glass already (tab bar, navigation bars, toolbars, sheets); never add glass on top.
- Glass only on controls: primary `.buttonStyle(.glassProminent)` filled with the accent and `.onAccent` text; secondary `.buttonStyle(.glass)`; chips `.glassEffect(.regular.interactive(), in: .capsule)`, tinted with the accent when selected; `GlassEffectContainer` (spacing 8 to 10) around groups; `glassEffectID` morphs for chips; the coach bubble, toast and slider thumbs (28 pt, 1.18× while dragging) are glass.
- Content is never on glass: cards are veils (translucent film, 0.5 pt hairline, radius 22 × roundness, faint shadow). Nothing glass sits on glass: controls inside the bottom accessory are plain.
- Backdrop, bottom to top: the pre-blurred photo (dark Dusk façade or Baroque, light Baroque or façade, or plain), extra blur, mist (black or white at 30% of Mist), the phase tint in soft light (dawn E7A99A, day E3C48E, dusk A98FB5, night 7F8FA8; 16% dark, 22% light), a diagonal sheen, Darkness (black at the Darkness value, dark only, default 50%), grain (a tiled noise texture at 16% dark, 12% light, times Grain). The phase follows the focus window (dawn before and while warming, day in best focus, dusk in lighter focus, night after) or the clock without one (before 10, 17, 20).
- Accents (dark, light), all at least 4.5:1 with their text (1B1714 on dark, F8F4EE on light): Espresso E9E1D4, 2A231F; Champagne D8BC88, 6B5128; Rose D9A497, 7E4338; Sage A9BBA0, 43533D; Slate A6B4C6, 3A4A5E.
- Motion: every custom animation goes through `Animation.gentle(calm, …)`, which returns nil when `motionIsCalm` (Reduce Motion or Still motion). Calm means no repeating animations (trial shimmer, sky drift, one-press pulse), fades instead of movement for reveals and steps, glyph reveals shown at once, no celebration and no ripples.
- Durations: default smooth 0.55 s; onboarding steps 0.7 s; root transitions 0.6 to 0.9 s; reveals 0.6 s; the sky drifts over 24 s (scale 1.03 to 1.08, 12 pt).
- Reduce Transparency: veils use the solid colour, grain is removed, the hold button is solid; system glass adapts on its own. Increase Contrast: 1 pt hairlines.

## Accessibility hooks

- Dynamic Type through text styles, `@ScaledMetric` for display type and Customise's text size (`dynamicTypeSize` small, xLarge, xxxLarge). Caps where layout needs them: the time ring and log chips at xxLarge, arrival answers at xxxLarge.
- VoiceOver: `.isHeader` on titles and the date; `accessibilityAdjustableAction` on page markers and sliders; `accessibilityRepresentation` steppers for the Patterns window chart; a named action for hold-to-confirm; charts carry a one-sentence label.
- Reads `accessibilityReduceMotion`, `accessibilityReduceTransparency` and `colorSchemeContrast`.
- To build: an `AssistiveAccess` scene (Now, Next, Log); verify whether `UISupportsAssistiveAccess` is needed.

## Localisation

- Launch: English (Australia) only. Development region en; String Catalogs (`LOCALIZATION_PREFERS_STRING_CATALOGS`); the copy deck `Copy.json` is en-AU; Australian spelling (colour, personalise, customise).
- Times through `FormatStyle` with the current locale; `compactTime` gives "h:mm" in 12-hour locales and "HH:mm" in 24-hour ones; dates "30 September"; prices from StoreKit's `displayPrice`.
- Crisis numbers are Australian (000, Lifeline 13 11 14, text 0477 13 11 14); 988 is added for the US when it launches.
- Foundation Models language support is checked before generating (`04-intelligence.md`).
- To build for new markets: a copy deck per locale (100 variants per slot), local crisis lines, US and UK spelling.

## Background work

- Built: none. Work happens in the foreground and inside App Intents.
- To build: `BGAppRefreshTask` `au.adhdslayer.focus.refresh` (about 30 s when the system allows: reload today's calendar, replan, refill the 48 h notification window, write the widget snapshot, reload widgets), with `UIBackgroundModes` fetch and `BGTaskSchedulerPermittedIdentifiers`.
- Learning updates run on the first foreground after 3:00 each day and are safe to run twice. No model generation in the background.
- Later, with sync: the remote-notification background mode and a silent push backstop of at most 3 an hour (`02-backend.md`).

## Storage, protection and the Keychain

- `medication.json` (medications, kinds of day, today's pick) in Application Support: complete file protection and excluded from backup, so it never reaches iCloud (Built). Learned state and check-ins will sit beside it with the same protection (To build).
- UserDefaults holds only non-health settings: Customise, Personalise, Patterns tuning, flags, your-AI settings (never the key).
- Keychain: service `au.adhdslayer.focus`, items `account` and `externalAIKey`, `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`, never synced.
- The export file is written with complete protection to the temporary folder and shared only by the person.
- Delete everything removes `medication.json`, the app's UserDefaults domain and both Keychain items.

## Info.plist keys

| Key | Value | Status |
|---|---|---|
| `CFBundleDisplayName` | Focus | Built (generated) |
| `UILaunchScreen` | `UIColorName` LaunchBackground | Built |
| `UIApplicationSceneManifest` | Generated | Built |
| `UIApplicationSupportsIndirectInputEvents` | YES | Built |
| `UISupportedInterfaceOrientations` (iPhone) | Portrait | Built |
| `NSCalendarsFullAccessUsageDescription` | Text above | Built |
| `NSHealthShareUsageDescription` | Text above | To build |
| `NSSupportsLiveActivities` | YES | To build |
| `GIDClientID` | Google OAuth client id | To build |
| `CFBundleURLTypes` | Reversed Google client id scheme | To build |
| `BGTaskSchedulerPermittedIdentifiers` | `au.adhdslayer.focus.refresh` | To build |
| `UIBackgroundModes` | fetch (later remote-notification) | To build |
| `ITSAppUsesNonExemptEncryption` | NO until end-to-end sync ships, then answer export compliance | To build |

- Not used: `NSSiriUsageDescription` (App Shortcuts don't need it), `NSHealthUpdateUsageDescription` (no writes), location, contacts, photos, microphone.
- The widget extension's own Info.plist declares `NSExtensionPointIdentifier` `com.apple.widgetkit-extension`.
- To build: `PrivacyInfo.xcprivacy` with tracking off, no tracking domains, and required-reason entries (UserDefaults CA92.1, plus any others Xcode's report lists).

## Entitlements and capabilities

| Capability | Entitlement | Targets | Status |
|---|---|---|---|
| Sign in with Apple | `com.apple.developer.applesignin` (Default) | App | To build (needs a team and signing) |
| In-App Purchase | Capability only | App | Local config Built; App Store Connect To build |
| App Groups | `com.apple.security.application-groups`: `group.au.adhdslayer.focus` | App, widgets | To build |
| HealthKit | `com.apple.developer.healthkit` | App | To build |
| Time Sensitive Notifications | `com.apple.developer.usernotifications.time-sensitive` | App | To build |
| Associated Domains | `applinks:focus.adhdslayer.au` (email sign-in link) | App | To build |
| Background Modes | `UIBackgroundModes` fetch | App | To build |
| Push Notifications | `aps-environment` | App | Later, with sync |
| Keychain Sharing | `keychain-access-groups` | App, widgets | Only if an extension ever needs the account |

- Not needed: Siri (App Intents don't use it), Family Controls, Critical Alerts, iCloud (health data never goes there).
- Google sign-in needs a client id from Google Cloud; Sign in with Apple needs the capability, a signing team and server-side token revocation on account deletion (`02-backend.md`).

## Launch arguments for tests and demos (Built)

- `-skipGate`: skip the device check. `-demoClock 09:41`: start the day at 9:41. `-freshDay`: no doses logged. `-skipArrival`: open straight on the tabs. `-name Sam`: set a name. `-plus`: force Plus. `-tab rhythm`: open on a tab.
