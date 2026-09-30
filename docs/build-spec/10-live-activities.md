# Live Activities and the Dynamic Island

## Summary

- Two Live Activities, both optional and both local: no push, no server. They're started, updated and ended by the app on the phone.
- **Focus mode** shows the task you're on and the time left. On by default.
- **Your day** shows the stretch you're in (best focus, lighter focus, a low-focus stretch or winding down) and what's next. Off by default; offered once, after the first medication is logged.
- They show in the Dynamic Island (compact, minimal, expanded), on the Lock Screen, in StandBy and in the Apple Watch Smart Stack. On iPhone 16e (a notch, no Dynamic Island) they show on the Lock Screen and as banners only.
- Words follow the compliance rules: never name a medicine in discreet mode, never say what, how much or when to take anything, and never use "due", "onset", "wear off", "booster", "predicts" or "optimal".

## Where the code lives

- Shared types: `app/FocusCore/Sources/FocusGlance` (`FocusActivityAttributes`), linked by the app and the widget extension.
- Extension: `app/FocusApp/FocusWidgets` target `FocusWidgets`, bundle id `au.adhdslayer.focus.widgets`, `ActivityConfiguration(for: FocusActivityAttributes.self)`.
- App: `Model/LiveActivities.swift` (`LiveActivityController`: start, update, end, restore on launch) and the Customise page.
- Info.plist: `NSSupportsLiveActivities` YES on the app. No `NSSupportsLiveActivitiesFrequentUpdates` (updates come from the app, not push).

## Data

```
FocusActivityAttributes: ActivityAttributes
  kind            focusSession | day                    fixed for the activity's life
  startedAt       Date

  ContentState: Codable, Hashable
    discreet      Bool                                   from Settings, Privacy, Discreet mode
    // focusSession
    title         String?                               the task, 60 characters at most
    firstStep     String?                               only if "Show the first step" is on
    startsAt      Date?                                 for the ring and bar
    endsAt        Date?                                 Text(timerInterval:) counts to this
    pausedLeft    TimeInterval?                         set while paused; the timer stops
    cheer         String?                               today's focusDoneCheer line, for time up
    // day
    stretch       best | lighter | lowFocus | windDown | open   shown as "Best focus", "Lighter focus",
                                                           "Low-focus stretch", "Winding down", "Open time"
    stretchEndsAt Date?
    nextTitle     String?                               the next plan item
    nextAt        Date?
    segments      [Segment] (at most 8)                  start, end, stretch: the next 8 hours
    showLog       Bool                                   Customise, and something set for about now
```

- `staleDate`: the session end plus 1 minute for Focus mode; `stretchEndsAt` for Your day. When stale, the views read "Open Focus to catch up" instead of a stretch.
- `relevanceScore`: Focus mode 100, Your day 50, so Focus mode takes the Dynamic Island when both run.
- Discreet mode never shows medicine names; there are none in the data at all, only stretch names and task titles.

## When they start, change and end

| Event | Focus mode | Your day |
|---|---|---|
| Start | opening Focus mode on a task, if on in Customise | the first log of the day, or opening the app during a planned day, if on |
| Update | pause, resume, +5 min, a new first step | at each stretch edge while the app runs, on a log, on replan, on background refresh |
| End | Done, closing Focus mode, or 15 minutes after the time is up | end of winding down, a Lighter day with no windows, or after 8 hours (restarted next time the app opens) |
| Dismissal | 2 minutes after ending | at once |

- The app restores its handles from `Activity<FocusActivityAttributes>.activities` at launch and ends any duplicate.
- `ActivityAuthorizationInfo().areActivitiesEnabled` false (switched off in iOS Settings): the Customise page says "Live Activities are off for Focus in iOS Settings." with an "Open Settings" button, and the switches are dimmed.
- Buttons run App Intents that conform to `LiveActivityIntent` (they run in the app's process): `EndFocusSessionIntent`, `ExtendFocusSessionIntent` (+5 minutes), and the existing `LogMedicationIntent`, which asks for Face ID on a locked phone.

## Presentations

### Focus mode

| Presentation | Content |
|---|---|
| Compact leading | a 20 pt progress ring in the accent colour |
| Compact trailing | time left, `Text(timerInterval:)`, monospaced digits, accent colour, up to 44 pt wide |
| Minimal | the ring alone; time left shows as the ring filling |
| Expanded, leading | the ring, 44 pt |
| Expanded, trailing | time left, 28 pt monospaced |
| Expanded, centre | the task title, serif 17 pt, one line |
| Expanded, bottom | the first step (if on), then "Done" (glass prominent) and "+5 min" (glass) |
| Lock Screen | ring 40 pt, title, first step, time left 28 pt on the right, a hairline progress bar, then Done and +5 min; under 160 pt tall |

- Paused: the ring dims and the time shows the minutes left, still, with "Paused".
- Time up: shown when the activity goes stale (staleDate is the session end plus 1 minute), so it works with the app closed: "Time's up." and the day's rotating `focusDoneCheer` line (passed in as `cheer`), for 15 minutes, then it ends.
- Discreet mode doesn't change Focus mode (tasks aren't health data), unless "Hide task names on the Lock Screen" is on, which shows "Focus" as the title.

### Your day

| Presentation | Content |
|---|---|
| Compact leading | a 12 pt dot in the stretch colour (best: accent gold, lighter: lilac, low focus: slate, winding down: dusk rose, open: tertiary ink) |
| Compact trailing | the stretch end time, "1:40" |
| Minimal | the dot |
| Expanded, leading | the stretch name, "Best focus" |
| Expanded, trailing | "until 1:40" |
| Expanded, bottom | the next 8 hours as one bar of stretch segments with a now marker, then "Next: Essay drafting at 11:25", and a Log button if on |
| Lock Screen | the same, with the stretch line in serif 20 pt from the copy slot: "Best focus until 1:40." |

- Stretch lines come from the rotating copy slots already used on Today (`dayLineBest`, `dayLineLighter`, `dayLineWarming`, `dayLineAfter`), picked once when the stretch starts.
- The Log button reads "Log" with a checkmark, never a pill icon or a medicine name, and only shows when something is set for about now. It records a log; it never suggests taking anything.

## Customise, Lock Screen and Dynamic Island

A category on the Customise list, "Lock Screen and Dynamic Island" (symbol `platter.filled.top.iphone`), with:

| Setting | Default | Notes |
|---|---|---|
| Focus mode | on | "Shows the task and the time left while you're in Focus mode." |
| Your day | off | "Shows the stretch you're in and what's next." |
| Your day shows | Both | Stretch only, Next only, Both |
| Log button | on | "Adds Log when something's set for about now. Asks for Face ID first." |
| Hide task names on the Lock Screen | off | shows "Focus" instead of the task |

- Stored in `CustomSettings` as `liveFocusMode`, `liveDay`, `liveDayShows`, `liveLogButton`, `liveHideTaskNames`, with tolerant decoding.
- One-time offer after the first log of the first day: a quiet card on Today, "Want your day in the Dynamic Island? You can see what stretch you're in without opening Focus." with "Show it" and "Not now". "Not now" never asks again.

## Acceptance

- Both activities render in every presentation in light and dark, at the largest text size, with no clipped text and nothing under the camera.
- Discreet mode on: no medicine name anywhere, in any presentation.
- With Live Activities off in iOS Settings, nothing starts and the Customise page explains why.
- Ending Focus mode from the Lock Screen ends the session in the app too.
- The Log button on a locked phone asks for Face ID and then uses the same double-dose check as the app.
