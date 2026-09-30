# API and interface design

Companion to [system-design.md](system-design.md). Contracts come first; the Swift package in
`app/FocusCore` implements §2 and is tested against it.

There are five surfaces where one piece of code talks to another, each with its own consumer:

| # | Surface | Consumers | Stability promise |
|---|---|---|---|
| 1 | On-device module contracts (Swift protocols) | our own app, intents, extensions | internal, but the medication boundary is a hard invariant |
| 2 | App Intents | Siri, Shortcuts, Action button, Controls, widgets, Spotlight | public: users build Shortcuts on these, so treat as permanent (Hyrum's law) |
| 3 | AI structured outputs (`@Generable`) | Foundation Models, PCC, opt-in third-party models | internal, versioned with prompts |
| 4 | Sync relay REST API | our clients on every device and OS version in the wild | public-ish: old app versions stay in use for years |
| 5 | Shared-container state (GlanceSnapshot, Live Activity `ContentState`) | widget, Live Activity and Watch processes, possibly an older binary | versioned schema |

Conventions everywhere: camelCase fields, UPPER_SNAKE error codes, enums closed on the wire but
decoded with an `unknown` fallback, UUIDv7 ids, times as ISO-8601 with offset on the wire and
`Date` in Swift, durations in whole minutes.

---

## 1. Design rules specific to this product

1. **No medication action in any output type.** Planner, learner and model outputs are enums of
   *task* operations. If a type could express "take", "skip", "move dose" or "booster", it is a bug.
2. **Writes to medication data require a `UserGesture`.** The token can only be minted by a UI
   control or an explicitly invoked intent (§2.1).
3. **Every mutation returns an undo token** (`PlanRevisionID` or `DoseEventID`), because undo is a
   core feature, not a nice-to-have (§8.2 rule 8).
4. **Errors are values in Swift** (`throws(DomainError)` with typed throws) and **one JSON shape on
   the wire** (§5.3). No `nil`-means-error, no mixed patterns.
5. **Validate at the edges only:** App Intent parameters, parsed text/screenshots, HealthKit and
   EventKit reads (third-party data, possibly stale or re-persisted), and relay responses.

---

## 2. On-device module contracts (Swift)

### 2.1 Medication — the only write path

```swift
public struct ProductID: Hashable, Sendable, Codable { public let raw: UUID }
public struct DoseEventID: Hashable, Sendable, Codable { public let raw: UUID }

/// Proof that a person deliberately asked for this write. Lives in the `FocusMedication` target.
/// `FocusPlanning` (scheduler, learner, safety gate) and the AI interpreter do not depend on
/// `FocusMedication`, so they cannot even name this type — the package graph is the enforcement
/// (see app/FocusCore/Package.swift). Only surface code (buttons, intents) links it.
public struct UserGesture: Sendable {
    public enum Origin: Sendable { case button, watchButton, doubleTap, control, actionButton, siri, shortcut }
    public let origin: Origin
    public let at: Date
    public init(origin: Origin, at: Date = .now)
}

public struct DoseLogRequest: Sendable {
    public var product: ProductID
    public var takenAt: Date            // backdated if the person said "20 minutes ago"
    public var ateFirst: Bool?          // optional; nil = not asked / skipped
    public var isBooster: Bool
}

public enum DoseLogOutcome: Sendable {
    case logged(DoseEvent, undo: DoseEventID)
    /// Same product logged within the product's minimum re-log interval. Nothing was written.
    case needsDeliberateConfirm(previous: DoseEvent)
}

public protocol DoseLogging: Sendable {
    /// Guard runs first. A second log inside the interval returns `.needsDeliberateConfirm`.
    func record(_ request: DoseLogRequest, by gesture: UserGesture) async throws(DomainError) -> DoseLogOutcome
    /// Called only after the person press-and-holds "log another" on the guard sheet.
    func recordConfirmingDuplicate(_ request: DoseLogRequest, previous: DoseEventID,
                                   by gesture: UserGesture) async throws(DomainError) -> DoseEvent
    func undo(_ id: DoseEventID, by gesture: UserGesture) async throws(DomainError)
    func edit(_ id: DoseEventID, takenAt: Date, by gesture: UserGesture) async throws(DomainError) -> DoseEvent
}

/// What every other module sees. Read-only by construction.
public protocol DoseTimelineReading: Sendable {
    func doses(in interval: DateInterval) async -> [DoseEvent]
    func lastDose(of product: ProductID) async -> DoseEvent?
}
```

Snooze and dismiss on a reminder notification never call `record` (§8.2 rule 9): notification
actions map to `LogDoseIntent` only for an explicit "Taken" button.

### 2.2 Focus window

```swift
public enum Confidence: Sendable, Equatable {
    case starting                 // < 3 check-in days — stated estimate / label prior
    case early(days: Int)         // 3–7 days, wide interval
    case learned(checkIns: Int)   // 8+ days and both edges within ±30 min
    case manualOverride
}

public struct FocusWindow: Sendable, Equatable {
    public var dose: Date
    public var start: Date               // warm-up ends / best focus begins (posterior median)
    public var bestFocusEnd: Date
    public var end: Date
    public var startInterval80: DateInterval
    public var endInterval80: DateInterval
    public var confidence: Confidence
    /// E(t) in 0...1, the template curve at the posterior median. Used by the solver only.
    public func effect(at t: Date) -> Double
}

public protocol FocusWindowModeling: Sendable {
    func window(for dose: DoseEvent) async -> FocusWindow?          // nil for non-stimulants
    func ingest(_ checkIn: CheckIn) async -> WindowDelta            // how much the 80% interval moved
    func nextCheckInTime(after: Date, for dose: DoseEvent) async -> Date?   // least-certain edge
    func proposal() async -> StatedVersusLearnedProposal?           // "You said 7 h; check-ins say 5½"
    func reset(product: ProductID, reason: ResetReason) async
}
```

User-facing strings built from `FocusWindow` must say "your focus window / your usual focus".
Words like onset, wear-off, effectiveness, predicts or pharmacokinetic are banned in UI (§8.2 rule 4);
the `SafetyGate` lexicon includes them as a backstop.

### 2.3 Planning

```swift
public enum FocusDemand: String, Sendable, Codable { case deep, medium, light, body }

public struct PlanRequest: Sendable {
    public var day: DateInterval
    public var tasks: [TaskSnapshot]
    public var fixed: [FixedEvent]                 // calendar commitments, never moved
    public var window: FocusWindow?                // nil → unmedicated / baseline planning
    public var rules: RuleSet                      // hard rules, mode, lifestyle, approved prefs
    public var previous: Plan?                     // for the stability penalty
    public var freezeUntil: Date                   // default now + 2 h
    public var dayVersion: DayVersion              // .ideal or .baseline
}

public enum PlanChange: Sendable, Equatable {
    case place(TaskID, at: DateInterval, reason: ReasonCode)
    case move(TaskID, from: DateInterval, to: DateInterval, reason: ReasonCode)
    case shrink(TaskID, fromMinutes: Int, toMinutes: Int, reason: ReasonCode)
    case split(TaskID, parts: [DateInterval], reason: ReasonCode)
    case deferTo(TaskID, day: Date, reason: ReasonCode)
    case unplaced(TaskID, remedy: CapacityRemedy)
    // Intentionally no case that can reference a DoseEvent or a Product.
}

public enum ReasonCode: Sendable, Equatable, Codable {
    case bestFocusLongestFree, lighterFocusForMediumWork, outsideWindowBodyTask
    case mealRule(minutesAfterDose: Int), afterWindowBuffer(minutes: Int)
    case deadline(p80Minutes: Int), pinned, frozenHorizon, stabilityKeptPlace
    case fillCap(percent: Int), transitionBuffer(minutes: Int), userRequested
}

public enum CapacityRemedy: Sendable, Equatable { case split, shrinkToBaseline, deferToTomorrow, flagDeadlineRisk }

public struct PlanResult: Sendable {
    public var plan: Plan
    public var changes: [PlanChange]
    public var fillPercent: Int                     // "Fills 58% of free focus time"
    public var solveMilliseconds: Double
}

public protocol Scheduling: Sendable {
    /// Deterministic for identical inputs. Never mutates stores; returns a proposal.
    func solve(_ request: PlanRequest) throws(DomainError) -> PlanResult
}

public protocol PlanApplying: Sendable {
    /// Writes to the ledger and connectors, verifies, and returns an undo token.
    func apply(_ result: PlanResult, actor: Actor) async throws(DomainError) -> PlanRevisionID
    func undo(_ revision: PlanRevisionID) async throws(DomainError)
}
```

`Scheduling.solve` is pure, which is what makes previews, what-if scenarios and replayed
experiments (§9.7) cheap: they are just solves that nobody applies.

### 2.4 Safety gate

```swift
public enum GateVerdict: Sendable, Equatable {
    case allow(String)
    case replaced(with: String, matched: [String])   // → "That's one for your prescriber or pharmacist."
}

public protocol SafetyGating: Sendable {
    func screen(_ candidate: String, context: GateContext) -> GateVerdict
}
```

### 2.5 Errors

```swift
public enum DomainError: Error, Sendable, Equatable {
    case permissionDenied(Permission)                // calendar, reminders, health, notifications, alarms
    case notFound(entity: String)
    case conflict(ConflictKind)                      // e.g. external event edited since preview
    case validation(field: String, reason: String)
    case capacityExceeded(unplaced: Int)             // solver could not fit chosen work
    case connectorWriteFailed(pendingItems: Int)     // EventKit save/commit failed; nothing shown as moved
    case storageUnavailable                          // locked before first unlock
}
```

---

## 3. App Intents (public surface)

These are the intents users will wire into Shortcuts, the Action button and Controls. Parameter and
result shapes are permanent; additions are optional parameters only.

| Intent | Parameters | Runs | Result | Notes |
|---|---|---|---|---|
| `LogDoseIntent` (`LiveActivityIntent`) | `medication: MedicationEntity`, `takenAt: Date?`, `ateFirst: Bool?` | background | dialog "Logged 8:10" or guard snippet | Guard returns a `SnippetIntent` confirmation; no silent duplicate |
| `CheckInIntent` | `answer: CheckInAnswer (.yes/.partly/.no)` | background | none | Used by notification buttons and the Watch |
| `StartBlockIntent` / `DoneBlockIntent` / `DoneForNowIntent` | `block: BlockEntity?` (defaults to Now) | background | updated Now/Next | `DoneForNow` records minutes remaining (censored) |
| `ParkThoughtIntent` | `text: String?` | background | none | Inbox capture, never interrupts the block |
| `FixMyDayIntent` | `phrase: String?` | foreground (`.dynamic`) | preview sheet | Nothing written without Apply |
| `SetBrainWeatherIntent` | `level: .low/.okay/.good` | background | — | Low → baseline day + half budget |
| `SwitchLifestyleIntent` (v1) | `lifestyle: LifestyleEntity` | foreground | preview | Undoable |
| `WakeUpIntent` | — | background | — | For a Shortcuts "Wake Up" automation |

App Shortcuts phrases ship fixed and work on every device ("Log my morning dose in ⟨App⟩",
"Fix my day in ⟨App⟩"). On iOS 27, tasks and blocks are also exposed under the `.reminders` and
`.calendar` App Schemas so Siri AI can move them. **There is no medication schema and no intent that
suggests anything.** Free-form Siri requests about doses resolve to the fixed referral.

---

## 4. AI structured outputs

```swift
@Generable struct TaskDraft {
    @Guide(description: "Short imperative title, no medication names") var title: String
    @Guide(.range(5...240)) var roughMinutes: Int?
    var deadline: DateComponents?
    var demand: FocusDemandGuess?          // deep / medium / light / body
    @Guide(.count(0...5)) var firstSteps: [String]   // first one must be < 10 min and physical
}

@Generable struct FixRequest {
    var intent: FixIntent                  // .runningLate(minutes) .skip(block) .moveTo(block, time) .lighterDay .baseline
    var targetBlockTitle: String?
}

@Generable struct ShiftRow { var date: DateComponents; var start: String; var end: String; var role: String? }
```

Guarantees: none of these types has a field for medication; `firstSteps` is capped at 5
(Goblin-style "hit-or-miss" output is bounded); every draft is previewed before any write; the
solver validates feasibility; the `SafetyGate` screens every string field before display.

---

## 5. Sync relay REST API

Minimal, stateless service in `ap-southeast-2`. It stores **ciphertext only** and never sees
plaintext health, task or medication data (system-design §7).

### 5.1 Endpoint overview

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/v1/accounts` | device key (self-signed) | Create an account and register the first device |
| POST | `/v1/accounts/{accountId}/devices` | existing device signature + enrolment code | Register another device |
| DELETE | `/v1/accounts/{accountId}/devices/{deviceId}` | any device signature | Revoke a device (idempotent) |
| POST | `/v1/accounts/{accountId}/batches` | device signature | Upload one sealed event batch (idempotent by `deviceId`+`seq`) |
| GET | `/v1/accounts/{accountId}/batches` | device signature | Pull batches after a cursor |
| PUT | `/v1/accounts/{accountId}/devices/{deviceId}/push` | device signature | Register APNs tokens (silent backstop, LA push-to-start) |
| DELETE | `/v1/accounts/{accountId}` | device signature + confirm token | Delete everything (account, batches, backups). Irreversible |

No list-all-accounts, no admin read of batches, no search. There is nothing useful to read.

### 5.2 Types

```typescript
import { z } from "zod";

type Brand<T, B extends string> = T & { readonly __brand: B };
export type AccountId = Brand<string, "AccountId">;   // UUIDv7
export type DeviceId = Brand<string, "DeviceId">;     // UUIDv7
export type Cursor = Brand<string, "Cursor">;         // opaque, base64url

export const DevicePlatform = z.enum(["IOS", "WATCHOS", "MACOS", "IPADOS"]);

export const RegisterDeviceBody = z.object({
  deviceId: z.string().uuid(),
  platform: DevicePlatform,
  appVersion: z.string().max(32),
  signingPublicKey: z.string().max(200),        // P-256, base64url raw representation
  enrolmentCode: z.string().length(8).optional() // required for non-first devices
});

export const UploadBatchBody = z.object({
  deviceId: z.string().uuid(),
  seq: z.number().int().nonnegative(),          // per-device, strictly increasing
  schema: z.number().int().positive(),          // event schema version inside the ciphertext
  nonce: z.string().max(24),                    // AES-GCM nonce, base64url
  ciphertext: z.string().max(1_400_000),        // ≤ 1 MB raw, base64url
  aadHash: z.string().length(43),               // SHA-256 of accountId|deviceId|seq, base64url
});

export interface BatchEnvelope {
  cursor: Cursor;              // server position of this batch
  deviceId: DeviceId;
  seq: number;
  schema: number;
  nonce: string;
  ciphertext: string;
  receivedAt: string;          // ISO-8601, server clock
}

export interface PullBatchesResponse {
  data: BatchEnvelope[];
  nextCursor: Cursor | null;   // null → caught up
  hasMore: boolean;
}

export interface UploadBatchResponse {
  cursor: Cursor;
  duplicate: boolean;          // true when (deviceId, seq) already stored with identical aadHash
}
```

### 5.3 Error contract

```typescript
export enum ErrorCode {
  VALIDATION_ERROR = "VALIDATION_ERROR",
  UNAUTHENTICATED = "UNAUTHENTICATED",       // bad/missing signature, clock skew > 5 min
  DEVICE_REVOKED = "DEVICE_REVOKED",
  FORBIDDEN = "FORBIDDEN",                   // device not in this account
  NOT_FOUND = "NOT_FOUND",
  SEQ_CONFLICT = "SEQ_CONFLICT",             // same (deviceId, seq) with a different aadHash
  SEQ_GAP = "SEQ_GAP",                       // seq skipped; details.expectedSeq tells the client where to resume
  PAYLOAD_TOO_LARGE = "PAYLOAD_TOO_LARGE",
  RATE_LIMITED = "RATE_LIMITED",
  UNSUPPORTED_CLIENT = "UNSUPPORTED_CLIENT", // appVersion below minimum; client keeps working locally
  INTERNAL = "INTERNAL",
}

export interface ApiError {
  error: {
    code: ErrorCode;
    message: string;                          // developer-facing; never shown verbatim to users
    details?: Record<string, string[] | number | string>;
    retryAfterSeconds?: number;
  };
}
```

| Code | HTTP | When | Client behaviour |
|---|---|---|---|
| VALIDATION_ERROR | 422 | body fails schema | bug; report, don't retry |
| UNAUTHENTICATED | 401 | signature invalid or skewed | re-sync clock, retry once |
| DEVICE_REVOKED | 401 | device was revoked | stop syncing; offer re-enrolment |
| FORBIDDEN | 403 | device not in account | stop; show Connector health |
| NOT_FOUND | 404 | account deleted | local-only mode |
| SEQ_CONFLICT | 409 | reused seq with different content | re-seal under next seq |
| SEQ_GAP | 409 | missing earlier seq | re-upload from `expectedSeq` |
| PAYLOAD_TOO_LARGE | 413 | batch > 1 MB | split and retry |
| RATE_LIMITED | 429 | limits below | honour `retryAfterSeconds` |
| UNSUPPORTED_CLIENT | 426 | app too old | local-only + gentle update prompt |
| INTERNAL | 500 | server fault | backoff 2^n s, cap 6 h |

### 5.4 Authentication

Each request is signed by the device's Secure-Enclave P-256 key:

```
X-Device-Id: <deviceId>
X-Timestamp: 2026-10-14T09:41:00+11:00
X-Signature: base64url(ECDSA-P256-SHA256(method \n path \n timestamp \n sha256(body)))
```

No passwords, emails or OAuth; the account is the set of enrolled device keys. Adding a device
needs an 8-character enrolment code shown on an existing device (valid 10 minutes, single use), and
the data key itself travels through iCloud Keychain, never through the relay.

### 5.5 Pagination, rate limits, caching

- **Pagination:** cursor-based (append-only stream). `GET …/batches?after=<cursor>&limit=50`,
  default 50, max 200. Cursors are opaque and stable forever.
- **Rate limits (per device):** uploads 120/h, pulls 360/h, device registration 5/day,
  delete-account 3/day. Silent-push scheduling on the server is capped at 3/h per device to match
  Apple's throttling.
- **Caching:** all responses `Cache-Control: no-store` (ciphertext is per-account and cursors
  change); no CDN. Idempotency comes from `(deviceId, seq)`, so retries are always safe.

### 5.6 Example

```bash
curl -X POST https://sync.example.au/v1/accounts/0192a1b0-…/batches \
  -H "X-Device-Id: 0192a1b2-…" \
  -H "X-Timestamp: 2026-10-14T09:41:00+11:00" \
  -H "X-Signature: MEUCIQD…" \
  -H "Content-Type: application/json" \
  -d '{"deviceId":"0192a1b2-…","seq":1842,"schema":3,"nonce":"q1f…","ciphertext":"8Jz…","aadHash":"n4bQ…"}'
# 201 {"cursor":"AAAB9w","duplicate":false}
```

---

## 6. Shared-container state

### 6.1 GlanceSnapshot (App Group, JSON, < 4 KB)

```json
{
  "v": 1,
  "generatedAt": "2026-10-14T09:41:00+11:00",
  "discreet": true,
  "dose": { "label": "Morning ✓", "loggedAt": "2026-10-14T08:10:00+11:00" },
  "window": { "start": "…09:10…", "bestFocusEnd": "…15:20…", "end": "…17:10…", "confidence": "learned" },
  "now": { "title": "Essay drafting", "demand": "deep", "start": "…09:15…", "end": "…10:35…" },
  "next": { "title": "Case reading", "start": "…10:45…", "note": "10-min break first" },
  "lifestyle": "Term",
  "brainWeather": "okay"
}
```

Rules: readers must tolerate unknown keys and a newer `v` (render "Open the app to update");
medication names appear only when `discreet` is false; the file is written atomically
(`write(to:options:.atomic)`) after every replan.

### 6.2 Live Activity attributes

```swift
struct FocusActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {       // < 1 KB, well under the 4 KB cap
        var nowTitle: String
        var nowEnd: Date
        var nextTitle: String?
        var nextStart: Date?
        var windowEnd: Date
        var tone: Tone                               // .focus / .attention (wrap-up) / .body
    }
    var doseLabel: String                            // "Morning ✓" in discreet mode
    var loggedAt: Date
}
```

---

## 7. Versioning and evolution

- **Swift contracts:** additive changes only; new enum cases added behind `@unknown default`
  handling at every switch in surfaces.
- **App Intents:** never rename or remove an intent or parameter; deprecate by hiding from
  suggestions and keep `perform()` working.
- **Relay:** one version (`/v1`) as long as possible (one-version rule); new fields are optional;
  `schema` inside the ciphertext evolves independently and clients carry decoders for every schema
  they have ever written.
- **GlanceSnapshot / ContentState:** bump `v` for breaking changes; extensions shipped with an older
  binary must degrade gracefully rather than crash.
