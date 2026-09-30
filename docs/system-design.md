# System design

Source spec: *ADHD planner: product design and research* (28 Sep 2026, 80 pp.). Section numbers
in brackets (§7.3) point into that spec. This document decides **how** the MVP and v1 are built:
components, data flow, storage, sync, the scheduling and learning engines, and where each of the
spec's red lines is enforced in code rather than by convention.

Design stance in one line: **local-first, event-sourced, deterministic core; AI at the edges; the
medication boundary enforced by module structure.**

---

## 1. Requirements

### 1.1 Functional (MVP → v1, from §17.1)

| # | Capability | Phase |
|---|---|---|
| F1 | One-tap dose log from app, Watch, widget, Control, Action button, Siri; backdating; "ate first?"; double-dose guard; undo; edit/delete with local audit trail | MVP |
| F2 | Personal focus window learned from 3–5 check-ins/day, tapering; confidence labels; stated-vs-learned proposal | MVP |
| F3 | Today: Now/Next, time ring, focus window card, Live Activity (chained past 8 h), Watch complication, app-owned wake alarm | MVP |
| F4 | Tasks (title, rough duration, deadline; everything else inferred); solver places deep work in best focus; app-owned calendar; identity map | MVP |
| F5 | Fix my day (fixed phrases), baseline day, amnesty, welcome-back, notification budget | MVP |
| F6 | Calm theme, setup presets, static support screen, consent flows | MVP |
| F7 | Lifestyles with frozen dormant snapshots, forgotten-toggle detection | v1 |
| F8 | End-to-end encrypted sync to Mac/iPad | v1 |
| F9 | Supply tracker, shortage mode, log export PDF, leave-by with learned lateness | v1 |

### 1.2 Non-functional

| Area | Target | Why |
|---|---|---|
| Solve latency | Re-plan today in **< 150 ms**, a full week in **< 1 s** on iPhone 11 (A13) | Gate 1 (§17.2); replans run inside App Intents and on unlock |
| Log latency | Dose log → Live Activity updated in **< 1 s**, fully offline | Point of performance (§4.2) |
| Offline | Every MVP flow works with no network; Watch logs with the phone out of range | Local-first; Watch logout complaints (Tiimo) |
| Privacy | Medication, check-in and Health data never leave the device except as E2E ciphertext or to Apple PCC | §8.2 rule 13, §15 |
| Calendar integrity | Zero duplicate or orphaned app events across moves, recurring edits, Exchange; never edits third-party events without confirm | Risk 15 (§13) |
| Battery | No periodic background work we control; event-driven upkeep only | iOS gives none (§11.2) |
| Accessibility | Dynamic Type to AX5, VoiceOver, Reduce Motion, Assistive Access scene | COGA (§4.2 principle 7) |
| Stability | Solver moves ≤ 3 flexible blocks per replan unless the user asks for more | Trust (§13 risk 4) |
| Server | 99.5% monthly for sync relay; app fully functional when relay is down | Relay is a convenience, never a dependency |

### 1.3 Constraints

One full-time builder; iOS 26 minimum, iOS 27 features behind `#available`; Swift 6 strict
concurrency; Apple limits from §11 (read-only Health doses, no Sleep Schedule API, 64 pending
notifications, 4 KB Live Activity state, 8 h + 4 h Live Activity lifetime, 40–70 widget reloads a
day, 20 geofences, 4 K on-device model context on iOS 26); App Review 5.1.3(ii) (no personal health
information in iCloud).

---

## 2. Architecture

```
 SURFACES (thin; no business logic)
 ┌───────────┬────────────┬───────────────┬──────────────┬────────────┬───────────┐
 │ iPhone app│ Watch app  │ Widgets / Live│ App Intents  │ Controls / │ Mac (v1)  │
 │ SwiftUI   │ SwiftUI    │ Activity / DI │ Siri,Shortcuts│ Action btn │ menu bar  │
 └─────┬─────┴─────┬──────┴───────┬───────┴──────┬───────┴─────┬──────┴─────┬─────┘
       │           │ WatchConn.   │ GlanceSnapshot (App Group, ≤4 KB)       │
       ▼           ▼              ▲              ▼             ▼            ▼
 ┌──────────────────────────────────────────────────────────────────────────────┐
 │ APP CORE  (Swift package `FocusCore`, runs in app + intent + extension procs) │
 │                                                                              │
 │  Interaction   IntentRouter: Grammar → Foundation Models → PCC → (opt-in 3P)  │
 │                Resolver (references), Preview/Confirm                         │
 │  Policy        SafetyGate (compiled) → HardRules → Mode → Lifestyle → Learned │
 │  Planning      Solver (greedy + LNS, deterministic) · Explainer · Forecaster  │
 │  Learning      FocusWindowModel · DurationModel · CompletionModel ·           │
 │                RoutineModel · ChangeDetector · LifestyleManager · NotifPolicy │
 │  Ledger        Event log (append-only) · PlanRevision (undo/restore)          │
 │  Medication    DoseLog (the ONLY write path) · Products · Supply              │
 │  Store         SQLite (GRDB), file protection; App Group copy for glances     │
 │  Connectors    CalendarMirror · RemindersMirror · HealthReader · AlarmClock ·  │
 │                NotificationScheduler (rolling 48 h) · LiveActivities · Places │
 │  Sync (v1)     E2E crypto (CryptoKit) · RelayClient                           │
 └──────────────────────────────────────────────────────────────────────────────┘
       ▲ read-only            ▲ read/write app calendar      │ ciphertext only
 ┌─────┴──────┐        ┌──────┴────────┐              ┌──────▼──────────────────┐
 │ HealthKit  │        │ EventKit      │              │ SERVER (AU, ap-southeast-2)│
 │ doses,sleep│        │ Calendar,     │              │ Sync relay (opaque blobs) │
 │ workouts   │        │ Reminders     │              │ Push backstop (≤3/h)      │
 └────────────┘        └───────────────┘              │ LA push-to-start          │
                                                      └───────────────────────────┘
```

**Why this shape.** The spec's chain — *the LLM interprets, the rules engine constrains, the solver
solves, the connectors execute, the behaviour engine learns* (§12) — maps one-to-one onto layers,
and each layer only depends downward. Surfaces are thin so that the same core runs inside the app,
inside App Intent `perform()`, and (read-only) inside widget and Live Activity extensions.

### 2.1 Module boundaries enforce the medication red line

The single most important architectural decision. Rules 1–3 and 10–12 of §8.2 ("never suggest,
calculate or prompt a dose"; "dose time is a fixed input"; "AI outputs structurally cannot contain
medication advice") are enforced by **what each module can import**, not by reviewer vigilance:

| Module | May read doses | May write doses | Can produce text shown to user |
|---|---|---|---|
| `Medication` | ✅ | ✅ — only via `DoseLog.record(_:by: UserGesture)` | fixed strings only |
| `Planning`, `Learning` | ✅ via `DoseTimelineReading` (read-only protocol) | ❌ no symbol available | reason codes only |
| `Interaction` (AI) | ❌ (receives a *derived* `DayContext` with no medication names) | ❌ | only through `@Generable` schemas with no medication-action field |
| Surfaces | via view models | via `LogDoseIntent` (requires a user gesture token) | yes |

- `UserGesture` is a token type that lives in the `FocusMedication` package target; surfaces obtain
  one from a button action or an App Intent that ran from explicit invocation. `FocusPlanning`
  (scheduler, learner, safety gate) and the AI interpreter don't depend on that target, so they
  cannot name the type or call the write API — no code path lets the scheduler, the learner or a
  model output create, move or suggest a dose. (Implemented: `app/FocusCore/Package.swift`.)
- The planner's output type `PlanChange` is an enum over *task* operations (`place`, `move`,
  `shrink`, `split`, `defer`, `archive`). There is no case that touches medication, so "change
  tasks, never medication" (§8.2 rule 3) is a property of the type system.
- A `SafetyGate` runs over every user-visible string that did not come from a compiled table
  (AI rephrasings, parsed titles): a deterministic lexicon filter for dose/timing/booster language
  (§8.4) that replaces the output with the fixed referral "That's one for your prescriber or
  pharmacist." It is a second fence, not the first.

---

## 3. Key flows

### 3.1 Dose logged on the Watch, phone out of range

```
Watch tap ─▶ DoseLog(watch replica).record ──▶ guard check against last 36 h replica
   │                 │ (already logged within min interval → show guard, stop)
   │                 ▼
   │         local event appended (id = UUIDv7, hlc, source=.watch)
   │                 │
   │         complication + Watch Now view update from local plan snapshot shifted by Δt
   ▼
WCSession.transferUserInfo (queued, guaranteed delivery)
   … later, phone reachable …
Phone: Ledger.ingest(event) ─▶ idempotent by event id
   ─▶ FocusWindowModel.window(for: dose) ─▶ Solver.replan(reason: .doseLogged, freeze: next 2 h)
   ─▶ PlanRevision saved ─▶ Connectors: LiveActivity.startOrUpdate, NotificationScheduler.refill,
      CalendarMirror.apply(diff) ─▶ Verifier re-reads writes ─▶ GlanceSnapshot written
```

The Watch never needs the phone to log, see the guard, or see its own updated Now view. The guard
works offline because the Watch keeps a 36-hour replica of dose events and the per-medication
minimum re-log interval.

### 3.2 Check-in answered from a notification

`CheckInIntent(answer:)` runs in the background without opening the app: append `CheckIn`, update
the grid posterior (≈740 cells, < 1 ms), and replan **only if** the window's 80% interval moved by
more than 15 minutes, using the stability penalty (§5.3). The next check-in time is chosen where
the posterior is least certain (§7.4) and fed to the notification budget.

### 3.3 Calendar changed outside the app

`EKEventStoreChanged` (after launch, or on next foreground) → `CalendarMirror.reconcile(horizon: 7d)`:
diff app-owned events by UUID in the event URL, adopt moved events, list unmatched items in
"Needs review" (never delete), and flag clashes with third-party events. Clashes become **one**
"Fix my day?" card, not a notification stream.

### 3.4 Fix my day

`interpret → apply rules → update estimates → solve(minimal change) → preview → execute → verify →
explain` (§12.1). The 20 most common phrasings are handled by the deterministic grammar; the model
path only fills the same `FixRequest` struct. Nothing is written until the user taps Apply.
Execution uses EventKit batched saves with `commit:false` then one `commit()`; every write is
re-read; failures roll back from the `PlanRevision` and list what could not be undone.

### 3.5 Nightly learning

There is no reliable nightly run on iOS, so "nightly" means **the first unlock after 03:00**, a
`BGProcessingTask` if granted, or the next foreground — whichever comes first. The job is idempotent
over a watermark in the ledger, so running it twice is harmless and skipping a night only delays
updates.

### 3.6 Event-driven upkeep

| Trigger | Work done |
|---|---|
| Foreground launch | reconcile calendar, refill notifications (48 h), rebuild glance snapshot, catch-up learning |
| App Intent (log, check-in, done, fix) | targeted replan, Live Activity update, snapshot |
| HealthKit observer (sleep ended, workout saved) | wake anchor / movement credit, then replan |
| `BGAppRefreshTask` (when iOS grants) | refill notifications, snapshot |
| Silent push backstop (≤ 3/h, server-scheduled around predicted transitions) | refill notifications, chain Live Activity near the 8 h mark |
| Wake alarm dismissed / Shortcuts "Wake Up" | wake event → dose reminder anchored to actual wake |

---

## 4. Data model

Storage is **SQLite via GRDB** in the app's container (`NSFileProtectionCompleteUntilFirstUserAuthentication`
so intents and extensions can run on a locked phone after first unlock), plus a small read-only
copy in the App Group for widgets and extensions.

> Spec §16.2 proposes SwiftData. I recommend SQLite/GRDB instead: the ledger is append-heavy and
> queried by time range; migrations must be explicit and testable; extensions (Screen Time monitor,
> 6 MB limit) need a tiny footprint; and sync needs byte-exact control over what is serialised.
> SwiftData remains fine for UI-only preferences if wanted.

### 4.1 Event-sourced ledger

Everything that happened is an immutable event; everything else is derived and can be recomputed.

```
events(id UUIDv7 PK, hlc INTEGER, device TEXT, type TEXT, lifestyle TEXT, mode TEXT,
       occurred_at INTEGER, payload BLOB, schema INTEGER)
       INDEX(type, occurred_at), INDEX(hlc)
```

| Event type | Payload (key fields) |
|---|---|
| `dose.logged` | productId, takenAt, loggedAt, source (app/watch/intent/health), ateFirst?, isBooster, healthUUID? |
| `dose.edited` / `dose.deleted` | doseEventId, before, after (audit trail, rule 8) |
| `checkin.answered` | at, answer (yes/partly/no/none), energy?, prompted (bool), propensity |
| `task.created/updated/archived` | taskId, fields changed (LWW per field) |
| `block.outcome` | blockId, outcome (done/partial/notStarted/blocked/noAnswer), reason code, elapsed, source |
| `plan.revised` | revisionId, actor (user/solver/import), rule ids, diff, undo token |
| `lifestyle.switched` | from, to, effectiveFrom (supports "switch since Monday" replay) |
| `consent.changed` | category, scope, provider, country, version |

Derived tables (rebuildable): `tasks`, `blocks` (the plan), `dose_events` (materialised view),
`focus_window_posterior` (per product), `duration_stats` (per category × lifestyle),
`routine_anchors`, `external_links` (identity map), `learned_patterns`.

Why event sourcing here: learning needs raw history with reason codes and propensities (§9.3, §9.7);
undo and "restore this morning's plan" need revisions; "switch since Monday" is a replay; and sync
becomes "exchange immutable events", which is far simpler than syncing mutable rows.

### 4.2 Identity map (calendar and reminders)

```
external_links(app_uuid PK, kind (event|reminder), calendar_id, external_id,
               occurrence_start, event_identifier, sync_state (pending|seen1|verified|needsReview),
               last_seen_hash, tombstoned_at)
```

Match order: UUID in `EKEvent.url` (`focusplanner://block/<uuid>`) → `calendarItemExternalIdentifier`
+ occurrence start → give up and list in *Needs review*. Items stay `pending` until seen on two
consecutive reads (sync lag). Tombstones last 30 days for undo.

---

## 5. Engines

### 5.1 Focus window model (§7.3)

- Template curve per formulation: 0 → 1 over a fixed ramp from onset, plateau, 1 → 0 over a fixed
  ramp to offset. Only **onset** (0–180 min, 15-min steps) and **offset** (2–16 h, 15-min steps)
  are learned: 13 × 57 ≈ 740 cells.
- Likelihood of a check-in: `P(yes at t) = ε0 + (1 − ε0 − ε1)·E(t − t_dose)`, ε ≈ 0.1; *partly*
  is scored as a half-yes; boosters add curves with separate parameters, capped at 1.
- Prior: label range (build-time table) combined with the user's stated estimate at the weight of
  about 3 days of check-ins; manual edit = hard override until released.
- Posterior kept as a `[Float]` of 740 log-probabilities per product (≈3 KB). Update is O(cells)
  per check-in. Summary = 80% credible intervals for onset/offset → the confidence label shown in
  UI ("Learned" when both edges are within ±30 min).
- Reset triggers: product, dose or brand change; change detector fires.

### 5.2 Other learners (§9)

| Model | Method | Cost |
|---|---|---|
| Durations | Normal-Inverse-Gamma on log(actual/estimate), population → user → category, κ = 4 | O(1) per outcome |
| Completion by time/context | Bayesian logistic regression, Laplace approximation, ~12 features incl. predicted E(t) | nightly, < 50 ms |
| Routine anchors | NIG per weekday type per lifestyle, forgetting 0.97–0.98 | O(1) |
| Notification timing | Thompson sampling with "send nothing" arm, p ∈ [0.1, 0.8], fatigue term | v1 |
| Change detection | BOCPD + CUSUM on wake, sleep midpoint, first activity, duration ratios | nightly |
| Lifestyle | Separate parameter snapshots; dormant frozen; sticky 2-state HMM for forgotten toggle | v1 |

All learners expose `evidenceCount`, an interval, `lastChanged` and `reset()` — the Learned screen
is a direct rendering of these, which keeps "every learned number shows its evidence" true by
construction.

### 5.3 Solver

**Formulation.** Horizon = today (tactical) plus 6 days (forecast). Time in 5-minute slots from the
wake anchor to the wind-down anchor (~190 slots/day).

- Hard: fixed events and 10-min transitions around them; pinned and user-created blocks never move;
  deadlines (P80 duration); availability and opening hours; meal and movement policies' hard parts;
  the frozen horizon (next 2 h); the fill cap (flexible work ≤ 60% of free focus time, §13 risk 3).
- Soft cost per placement:
  `w1·demandMismatch(E(t), task.demand) + w2·(1 − P(complete | t, context)) + w3·movedFromLastPlan +
   w4·fragmentation + w5·preferenceViolation + w6·deadlineSlackPenalty`
  where `demandMismatch` is `−log E(t)` for deep work and the reverse for body tasks.

**Algorithm.** Deterministic greedy construction (deep work longest-first into the highest-E free
slots; then medium/light; then body/meal outside the window; then errands) followed by **large
neighbourhood search** for a fixed time budget (80 ms today / 600 ms week): repeatedly unassign
2–4 blocks near the worst cost and reinsert optimally by exhaustive search over their candidate
slots. Seeded RNG, so the same inputs always produce the same plan (testable, explainable).

**Why not OR-Tools CP-SAT (yet).** It is the spec's first suggestion, and it will find better optima
for dense weeks, but it adds ~15–25 MB of C++ to the binary and makes explanations harder to extract.
A student's week is ~20–60 flexible blocks, which greedy + LNS handles comfortably. Keep CP-SAT as the
Gate 1 spike comparator: if LNS is > 5% worse on the fixture weeks, switch.

**Explainer.** Every placement records the binding constraint or dominant cost term as a
`ReasonCode` (`.bestFocusLongestFree`, `.mealRule(hoursAfterDose: 5)`, `.afterWindowBuffer`,
`.pinned`, `.deadline(p80:)`, `.stabilityKeptPlace`). Explanations are template strings over these
codes; the language model may only rephrase them and never introduces numbers.

**Capacity shortfall.** When chosen work does not fit, the solver returns ranked task-side remedies
(split, shrink to baseline, defer, flag deadline risk) — never anything about medication.

### 5.4 Notification budget (§5.7)

Rolling 48-hour schedule under iOS's 64-pending cap, refilled on every upkeep trigger. Classes:
*exempt* (user-set medication reminder, leave-now, transition taps), *budgeted* (default 5/day), and
*digest* (2–3 per day). Time-Sensitive only for exempt classes; AlarmKit only for the opt-in wake
alarm, a user-marked "hard" dose reminder and leave-now. Brain-weather *Low* halves the budget.
Lock-Screen text is neutral in discreet mode ("Morning ✓", "Quick check-in").

### 5.5 AI interpreter (§8.4, §15.4)

```
input text/screenshot ─▶ Grammar (≈20 phrase families, offline, all devices)
        │ no match
        ▼
   SystemLanguageModel (on-device, 4 K/8 K ctx, @Generable output)   if available
        │ too long / unavailable / low confidence
        ▼
   Private Cloud Compute model (iOS 27, 32 K, free under SBP quota)  if entitled & quota
        │ user opted in AND content class is non-health
        ▼
   Third-party model (Claude) — de-identified productivity text only
```

Every tier fills the **same** `@Generable` structs (`TaskDraft`, `FixRequest`, `ShiftRow`), none of
which has a medication-action field. Parsed content is data: it can create tasks and calendar
drafts only behind a confirm, and can never create or change a medication entry or reminder
(OWASP LLM01). Medication, check-ins and Health data are only ever given to tiers 0–2.

---

## 6. Glanceables and cross-process state

- **GlanceSnapshot** — a versioned JSON blob (< 4 KB) written atomically to the App Group after every
  replan: now/next blocks, focus window summary, dose glance ("Morning ✓ 8:10"), discreet-mode flag.
  Widgets, complications and Controls read only this, so they never open the database and never
  hold medication names unless discreet mode is off.
- **Live Activity** — started from `LogDoseIntent` (a `LiveActivityIntent`, so it works from the
  Action button and Control Center while backgrounded). `ContentState` is the snapshot subset
  (< 1 KB). Countdowns use `Text(timerInterval:)`, not updates. A second activity is scheduled near
  the 8-hour mark (scheduled start with `AlertConfiguration`, or server push-to-start as backup).
- **Watch** — WatchConnectivity `updateApplicationContext` pushes the day plan snapshot;
  `transferUserInfo` carries Watch-originated events back. The Watch app has no account, no login,
  and a local 36-hour dose replica for the guard.

---

## 7. Sync (v1): end-to-end encrypted relay

**Goal.** Mac/iPad parity without storing personal health information in iCloud (5.1.3(ii)) and
without the server ever being able to read it.

- **Keys.** On first device, generate a random 256-bit *account data key* (ADK). Store it in iCloud
  Keychain as a synchronizable item (Keychain is end-to-end encrypted by Apple and holds a key, not
  health information). Each device also has a Secure-Enclave P-256 *device signing key* registered
  with the relay.
- **Payload.** Batches of ledger events, serialised and sealed with `AES.GCM` under the ADK; the
  associated data binds `accountId`, `deviceId` and `seq`, so the server cannot splice batches.
- **Ordering and conflicts.** Hybrid logical clocks on every event. Events are immutable, so most
  "conflicts" vanish; mutable projections (task fields) are last-writer-wins per field by HLC, with
  high-risk fields (deadline, pinned) raising a review card when two devices changed them.
- **Server** stores `(accountId, deviceId, seq) → ciphertext` with a per-account monotonically
  increasing cursor; clients pull `since cursor`. It sees sizes and timing, which the privacy page
  discloses. API contract: [api-design.md §5](api-design.md#5-sync-relay-rest-api).
- **Key loss.** If iCloud Keychain is off or wiped, the user can export an encrypted recovery file,
  or start fresh from the local device's data. No server-side recovery is possible by design.

**Load estimate.** 50 k users × 3 devices × ~200 events/day × ~300 B sealed ≈ 9 GB/month ingest,
~1.5 M requests/day at one pull per foreground + push. One small Node service with Postgres
(ap-southeast-2) and S3 for batches > 64 KB handles this with room to spare; horizontal scaling is
stateless if it's ever needed.

---

## 8. Reliability and failure handling

| Failure | Behaviour |
|---|---|
| EventKit write fails or sync server rejects later | block stays `pending`; never shown as moved; compensating rollback from `PlanRevision`; listed in Connector health |
| Calendar permission write-only or denied | degraded mode: user marks busy times; app calendar write-only; explained once |
| Health permission silently denied | treated as "no data seen since …", never zero; features fall back to taps |
| Foundation Models unavailable (older iPhone, not ready) | grammar + manual forms; no feature disappears |
| Relay down / offline | local-only continues; outbound queue with exponential backoff (max 6 h) |
| Live Activity ended early or not permitted | complication + widget + notification carry the glance |
| Duplicate dose events (Watch + Health import) | idempotent by event id; Health imports de-duplicated by HealthKit UUID then by (product, ±10 min) with a confirm |
| Solver time budget exceeded | return best-so-far greedy plan (always feasible) and log metric |
| Corrupted local DB | integrity check on launch; restore from last snapshot in `Application Support/Backups` (encrypted) |

---

## 9. Observability without surveillance

- On-device metrics power the Learned screen and gate criteria (§17.2): calibration of P50/P80
  durations, Brier score for completion, blocks done within 30 min of plan, reschedules per day.
- Product analytics are **opt-in**, aggregated, and never emitted from medication or Health screens;
  crash logs are scrubbed of medicine names. What leaves the phone is listed on the
  "What leaves this phone" page, generated from the same registry that the network layer uses, so
  the page can't drift from reality.
- Server: request counts, error rates, p95 latency; no payload logging (payloads are ciphertext anyway).

---

## 10. Testing strategy (what proves the design)

| Layer | Test |
|---|---|
| Safety | Property tests: for random inputs, no `PlanChange` references a dose; `SafetyGate` blocks a 500-prompt red-team set; snapshot test that no Lock-Screen string contains a product name in discreet mode |
| Solver | Deterministic fixtures (the founder's regime as fixture #1, §2); invariants: no overlap, pinned untouched, fill cap respected, ≤ 3 moves per replan; latency benchmark on A13 |
| Focus model | Synthetic users with known onset/offset → posterior 80% interval covers truth ≥ 80% of the time; convergence within 10 days at 3 check-ins/day |
| Calendar mirror | Integration tests against iCloud, Google-via-iOS and Exchange accounts: move between calendars, recurring edits, deletions, offline edits |
| Sync | Two simulated devices with random interleavings converge to identical projections |
| UX | Dynamic Type AX5 snapshots of every screen; VoiceOver rotor order; Reduce Motion variants |

---

## 11. Key trade-offs

| Decision | Chosen | Alternative | Why |
|---|---|---|---|
| Source of truth | App's own ledger | Apple Calendar/Reminders | Apple stores can't hold task structure, reason codes or learning data (§11.1) |
| Persistence | SQLite/GRDB, event log | SwiftData (spec) | Append-heavy ledger, explicit migrations, extension memory, sync control |
| Solver | Greedy + LNS in Swift | OR-Tools CP-SAT | Binary size, explainability, adequate for ≤ 60 blocks; CP-SAT stays as a benchmark |
| Learning | Conjugate Bayes / grid posteriors | ML model, LLM | Explainable, tiny data, runs in ms, honest uncertainty |
| MVP sync | None (iPhone + Watch only) | CloudKit | 5.1.3(ii) risk; relay built in v1 |
| AI | On-device → PCC → opt-in third-party | Cloud LLM first | Cost ≈ 0, privacy, provider terms (§8.4) |
| Medication safety | Module boundary + type system + gate | Content moderation only | Structural guarantees survive refactors and new features |

## 12. What to revisit as it grows

1. **Solver** — if users routinely plan > 100 blocks/week or multi-person constraints arrive, move
   to CP-SAT or a MaxSAT core behind the same `Scheduling` protocol.
2. **Sync** — if shared plans (buddy, coach, family) arrive, per-share keys and MLS-style group
   keying replace the single ADK.
3. **Android** — the core is Swift; the engines (focus model, solver) would be ported to Kotlin
   against the same fixture suite, or shared via a Rust core if the port is serious.
4. **Regulatory** — if the TGA removes the digital mental-health exclusion (§8.1), re-audit every
   surface against the claims register before the change takes effect.
5. **Notification learning** — Thompson sampling needs ~4 weeks of data per user; revisit priors
   with cohort data after the pilot.
