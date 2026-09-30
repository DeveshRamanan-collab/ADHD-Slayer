# Design critique: ADHD planner — Figma v0.1 + SwiftUI prototype

**Reviewed:** the Figma file (Cover, Foundations, Components, 10 iPhone screens, Glanceables, 6 Watch
screens, 2 motion studies) and the running SwiftUI build on iPhone 17 Pro (light, dark, AX5).
**Stage:** late exploration → early refinement. **Audience:** adults with ADHD, many at university,
often on stimulants; many also anxious or autistic (spec §3.1 comorbidity row).
**Contrast figures** are computed from the actual token values (WCAG 2.2 formulas), not eyeballed.

## Overall impression

The design does the hard things right: it is calm without being lifeless, it never shames, it
explains itself, and the medication boundary is visible in every word. The biggest opportunity is
**hierarchy at the point of performance** — the screen leads with *context* (the focus window) when
the person most needs *action* (what to do right now) — followed by a naming problem that undermines
the product's own principles.

---

## Usability

| # | Finding | Severity | Recommendation |
|---|---|---|---|
| U1 | **The working name "ADHD Slayer" contradicts the product.** It frames ADHD as an enemy to be killed (the deficit framing HCI reviews criticise, spec §4.2 principle 8), reads as a treatment claim ("slays ADHD" ≈ "treats ADHD", §8.2 rule 5; MHRA/TGA device language), and is aggressive next to "nothing punishes a miss". App Review and ad platforms are also sensitive to ADHD-adjacent claims after Done Global. | 🔴 Critical | Rename before any public artifact, domain or App Store record. Aim for names about time, rhythm or daylight rather than the diagnosis (e.g. working directions: "Tide", "Daylight", "Steady"). Run the shortlist past the claims register and a trademark search. |
| U2 | **Today leads with the focus window, not the Now card.** At 9:41 the eye lands on a chart; the answer to "what do I do now?" is the second card, and on smaller phones its actions sit near the fold. Barkley's point-of-performance principle (§4.2 #1) says the action comes first. | 🟡 Moderate | Make order state-dependent: *before logging* → dose prompt first; *after logging* → Now card first, focus window as a compact one-line band inside or under it ("Best focus until 3:20"). Keep the full card one tap away. |
| U3 | **Too many choices on the Now card** (Done, Done for now, Park, first-step, next). COGA asks for one primary action per screen (§4.2 #7). | 🟡 Moderate | Keep *Done* as the one primary; fold *Done for now* and *Park* into a single secondary "Not now ▾" menu on iPhone; keep *Park* as the Watch/Lock-Screen action where it's cheapest. |
| U4 | **"Done for now" leaves best focus empty.** In the build, stopping case reading at 9:41 yields "This gap is yours · Free until 11:05" — 84 min of best focus unused, with deep work waiting at 11:05. | 🟡 Moderate | When a gap ≥ 30 min opens inside best focus, offer one tap: "Start *Essay drafting* now instead?" (moves one block, respects the stability limit). Never auto-move it. |
| U5 | **The persistent Log action moved.** Figma shows a teal circle beside the tab bar; iOS reserves that detached slot for Search, so the build uses the tab-bar bottom accessory ("Morning ✓ 8:10 · Log"). The accessory is actually better — it doubles as the "did I already log it?" glance. | 🟢 Minor | Update the Figma Tab bar component to the accessory pattern so design and code agree. |
| U6 | **Brain weather is buried.** In Figma it's a chip; in the build it's a toolbar menu. The morning one-tap check-in is an MVP feature (§5.4) and it drives the baseline day. | 🟡 Moderate | Morning-only inline card ("How's your brain today? Low · Okay · Good") that collapses to the chip once answered; also offer it on the Watch and as a notification action. |
| U7 | **Watch Log button is a bare checkmark.** A giant check reads as "done", not "log". | 🟢 Minor | Label inside or under the button ("Log morning dose" / discreet: "Log"). Keep double-tap hint. |
| U8 | **"Fills 58% of free focus time" is jargon.** It is honest and useful, but "free focus time" isn't a concept users have been taught. | 🟢 Minor | "About 2 h of your focus time left open" — lead with room to spare, not utilisation. |
| U9 | **Press-and-hold has no visible progress in Figma.** The build fills the capsule while holding; the static design gives no cue that holding does something. | 🟢 Minor | Add the fill state to the Figma guard screen and a one-line "Hold for 1 second" helper. |

## Visual hierarchy

- **What draws the eye first:** the teal best-focus bar in the Focus window card. It is the most
  saturated element on screen. Correct for the *first* look after logging (it answers "is it
  working yet?"), wrong for every later look — see U2.
- **Reading flow:** title → context chips → focus card → Now card → day toggle → timeline. Clear
  and linear; the timeline's left time column with coloured kind bars scans well once the column
  width was fixed (the build initially had mis-aligned bars because "11:05 am" is wider than "7:30 am").
- **Emphasis:** good restraint — one teal primary per card, ochre reserved for decisions, no red.
  The ring's 44-pt numerals carry "time left" better than any text could.

## Consistency

| Element | Issue | Recommendation |
|---|---|---|
| Typography | Figma uses Inter as a stand-in for SF Pro (SF can't render in cloud previews). Inter runs ~5% wider, so Figma layouts are conservative; line breaks will differ slightly on device. | Keep styles bound (done); verify final layouts in the simulator or with SF installed locally before handoff. |
| Time formats | Mixed "9:41 am", "9:41", "09:41" in early builds. | Fixed: one `compactTime` style (no am/pm) inside cards and axes; full format only in prose. |
| Buttons | Figma "Small" buttons are 32 pt; SwiftUI `.controlSize(.small)` renders ~28 pt. | See accessibility A3. |
| Sheets | Figma sheets use custom option buttons; the build uses native `Form` + segmented pickers. | Adopt the native versions in Figma — they're accessible, localisable and match iOS 26. |
| Lifestyle cards | Term/Holidays cards differ in width in the Lifestyle sheet. | Equal-width grid. |
| Uncertainty | "Learned ±25" and "Early ±50" look almost identical in the Figma band (stacked translucent rects). The build and the shader use real feathered gradients, which read better. | Replace the Figma rects with the Focus Window Band shader once published; label the ± explicitly on the Early variant. |

## Accessibility

**Colour contrast (computed):**

| Pair | Light | Dark | Status |
|---|---|---|---|
| Secondary text on card (`ink/secondary` / `bg/surface`) | 6.51 | 7.39 | ✅ |
| Button label on primary (`ink/on-accent` / `action/primary`) | 5.94 | 7.22 | ✅ |
| **Required disclaimers in `ink/tertiary`** | **3.32** | **3.90** | ❌ → **fixed**: moved to `ink/secondary` in Figma and code |
| Focus / Fixed / Attention chips | 4.63 / 4.57 / 4.80 | 4.96 / 6.17 / 6.49 | ✅ (Focus and Fixed only just) |
| **Body chip (`body/strong` / `body/soft`)** | **3.89** | 5.65 | ❌ → **fixed**: `body/strong` Light #A0623F → #905838 (4.61) |
| **Upcoming status circle (non-text)** | **1.39** | **1.29** | ❌ → **fixed**: stroke now `ink/tertiary` (3.3) |
| Warm-up zone vs track (non-text) | 1.06 | 1.61 | ❌ open |
| Lighter-focus zone vs track (non-text) | 1.95 | 4.23 | ❌ open (light) |
| Light-task bar vs card (non-text) | 1.28 | 1.37 | ❌ open |

The open items are graphics that are *also* conveyed in text (legend labels, "Lighter focus" in
each row), so they don't strictly block WCAG 1.4.11 — but they matter for people with low contrast
sensitivity. **Fix:** darken `focus/soft` and `focus/mid` in Light mode one step and give the track a
hairline outline, or add a subtle hatch to warm-up (the shader already supports this via grain).

**Touch targets (A3):** Now-card actions and proposal buttons are below the 44 × 44 pt minimum
(32 pt in Figma, ~28 pt in SwiftUI small). People act on these one-handed while walking between
tasks. Use `.controlSize(.regular)` (or keep small visuals with `.contentShape` padding to 44 pt).

**Text readability:** body copy is 15–17 pt with generous leading; the build now reflows every
horizontal row to vertical at accessibility sizes (verified at AX5 — before the fix the card header
broke mid-word, "Logg/ed"). The focus band caps its tick labels at xLarge, which is the right call
for a time axis. **Reduce Motion:** both motion studies have explicit fallbacks, and the build honours
them (no ripple, instant colour change, no draw-in).

**VoiceOver:** the focus card is one element with a sentence label ("Focus window, 9:25 to 5:10…
Now you're in best focus"); the press-and-hold guard exposes a named action because holding is hard
with VoiceOver. Still to do: an audio-graph (`AXChartDescriptor`) for the Learned chart.

## What works well

- **Language that holds the red line without sounding legal.** "Your usual focus, from 23 check-ins",
  "Warm-up · Best focus · Lighter focus", "It never changes your medication" — neutral, human, and
  structurally backed by the type system (`PlanChange` has no medication case).
- **Honest uncertainty everywhere.** Confidence labels, ± edges, "Starting estimate from what you
  told us", and a Learned screen whose chart is drawn from the real posterior with the person's own
  answers as dots.
- **Shame-free recovery.** Welcome back never mentions the missed days; the baseline day calls three
  things "a win"; nothing is red; "Done" is a quiet check, never a strikethrough.
- **Glanceables as the product.** Lock Screen + Live Activity + Watch tell the whole day without
  opening the app, and discreet mode ("Morning ✓") is the default, not a setting.
- **Every move explained.** Fix my day shows each change with its reason and what won't move; the
  scheduler really does produce those reasons.

## Priority recommendations

1. **Rename the product (U1)** — it is the one issue that can't be fixed later without cost: it
   touches App Store review, marketing claims, the domain, and the product's tone. Decide before
   TestFlight.
2. **Put action before context on Today (U2 + U3)** — state-dependent order and one primary action on
   the Now card. This is the screen people see 20 times a day.
3. **Close the remaining contrast and target-size gaps (A3 + open rows)** — darken `focus/soft` and
   `focus/mid` one step, outline the track, move Now-card actions to regular size. Cheap, and the
   users most affected (tired, medicated, one-handed, low-contrast phones outdoors) are the core
   audience.

Fixed during this review: disclaimer contrast, Body chip contrast, upcoming-circle contrast, AX5
reflow, time-format consistency, a scheduler bug that could place re-planned work in the past, and
"Done for now" (previously marked tasks complete).
