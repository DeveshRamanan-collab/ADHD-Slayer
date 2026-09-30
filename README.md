# ADHD planner (working title "ADHD Slayer" — see the naming note in the critique)

An Apple-native planner that learns a person's own medication focus window from one-tap check-ins,
fills it with the work they choose, and survives bad days without shame. Source spec:
*ADHD planner: product design and research* (28 Sep 2026).

| Deliverable | Where |
|---|---|
| Figma design (tokens, 13 components, 10 iPhone screens, glanceables, 6 Watch screens, 2 motion studies) | https://www.figma.com/design/gLuoHFbiiUGajAUpluWXOW · notes in [design/figma/README.md](design/figma/README.md) |
| Figma shader (Focus Window Band) and plugin (Focus Day Generator) — source, ready to publish | [design/figma/shaders](design/figma/shaders) · [design/figma/plugins](design/figma/plugins) |
| System design | [docs/system-design.md](docs/system-design.md) |
| API and interface design | [docs/api-design.md](docs/api-design.md) |
| Design critique (with computed contrast) | [docs/design-critique.md](docs/design-critique.md) |
| Engine package: focus-window learner, scheduler, dose log + guard, safety gate (26 tests) | [app/FocusCore](app/FocusCore) |
| SwiftUI prototype: Today, Log dose + guard, Fix my day, Learned, You, Get support | [app/FocusApp](app/FocusApp) |

## Run it

```bash
cd app/FocusCore && swift test
```

```bash
open app/FocusApp/FocusApp.xcodeproj
```

In Xcode, run the `FocusApp` scheme on an iOS 26+ simulator. Add the launch argument
`-demoClock 09:41` to start the day at 9:41 like the Figma frames.

## Architecture in one paragraph

Local-first and event-sourced; deterministic engines with AI only at the edges. The medication
red line (never suggest when or how much to take) is enforced by the **package graph**:
`FocusPlanning` (scheduler, learner, safety gate) cannot import `FocusMedication` (the only code that
writes doses), and the planner's `PlanChange` type has no case that can reference a dose.

## Not built yet (honest list)

- Watch app, widgets, Live Activity and App Intents exist as Figma designs and contracts, not code.
- HealthKit, EventKit, AlarmKit and notification connectors; the SQLite ledger (the prototype uses
  in-memory stores); E2E sync relay.
- The shader and plugin are unpublished: both Figma teams on the account are View seats. The plugin's
  placement logic has been exercised in the design file; the shader has not been compiled.
- Legal review of the red lines and wording (spec §17, gate 1) — still the first real next step.
