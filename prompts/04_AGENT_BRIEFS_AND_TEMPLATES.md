# AGENT BRIEFS AND TEMPLATES — copied by the orchestrator; never pasted by Devesh

Rules for using this file: the orchestrator copies a template verbatim and fills every field; a field with nothing to say gets `none`, never a blank (F5). Placeholders are `<angle brackets>`; none may survive into a written file. All timestamps ISO 8601 with offset from `date +%Y-%m-%dT%H:%M:%S%z`. Terms and id prefixes are defined in `prompts/01_MASTER_PLANNING_PROMPT.md` § GLOSSARY and are not redefined here. Templates: 04-T1 subagent work brief · 04-T2 independent reviewer brief · 04-T3 gate report · 04-T4 PROGRESS.md · 04-T5 DECISION_LOG entry · 04-T6 BLOCKERS entry · 04-T7 read-ledger · 04-T8 evidence naming · 04-T9 milestone report · 04-T10 USER ACTION REQUIRED callout · 04-T11 per-page Figma analysis · 04-T12 OPEN_QUESTIONS entry · 04-T13 USER_ACTIONS.md · 04-T14 MANIFEST.md and WORK_QUEUE.md rows.

---

## 04-T1 — Subagent work brief (every spawned agent receives exactly this, filled in)

```markdown
# BRIEF <BRIEF-id, e.g. P03-onboarding-analysis or MS03-impl-engine>
Spawned by: orchestrator, <ISO>. Phase/milestone: <Phase n | MS-nn>. Your role: <analyst | author | implementer | test author | researcher | reader>. Agent id for evidence names: <agent-id>.

## Goal (one sentence)
<What must exist when you finish, e.g. "docs/figma/analysis/onboarding.md containing the A–E analysis of every frame and interactive element on the Onboarding page, from the cache only.">

## Read first, in this order (nothing else is assumed known; you have no memory of any other conversation)
1. docs/AGENT_RULES.md — its contract, operating mode, register F1–F30 and red lines RL-1–RL-9 bind you.
2. <exact path> — <why>
3. <exact path> — <why>

## Inputs (exact; read only these Figma-derived sources — you may not call any Figma read tool)
- Cache: <docs/figma/raw/<fileKey>/<page-slug>/nodes.json>, <docs/figma/raw/<fileKey>/get_design_context/<nodeId>.*>
- Node ids in scope: <list or "all top-level frames in nodes.json">
- Documents: <paths>
- URLs you may fetch (save excerpts with scripts/fetch_excerpt.py): <list or "none">
- Id range allocated to you: SCR-<a>…<b>, FRM-<a>…<b>, CMP-<a>…<b>, INT-<a>…<b> (allocate sequentially; never reuse; never invent ids outside the range; on exhaustion report RANGE EXHAUSTED and stop allocating)

## Outputs (exact paths; required structure)
- <path> — structure: <template id or section list>; ends with `<!-- END OF FILE -->`
- docs/agents/<agent-id>/{decisions,blockers,questions,notes}.md — your own bookkeeping (the orchestrator merges)

## File ownership
- You may create or modify ONLY: <paths/globs> and docs/agents/<agent-id>/*
- You must not read-modify-write any other file. A change needed elsewhere is a PROPOSED CHANGE in your report; the orchestrator applies it.
- You never run git. You never write docs/figma/read-ledger.md, the cache, docs/PROGRESS.md, docs/DECISION_LOG.md, docs/BLOCKERS.md, docs/OPEN_QUESTIONS.md, docs/USER_ACTIONS.md, docs/MANIFEST.md, docs/FACT_REGISTER.md, docs/gates/*, CLAUDE.md, .claude/*.

## Rules (in addition to docs/AGENT_RULES.md)
1. Never call a Figma read tool. Never call AskUserQuestion. Never ask a question in prose; put it in your report as `OPEN: <question> → <default you adopted>` and continue using the default.
2. Every factual claim cites its source inline: `(node <id>, <cache path>)`, `(<URL>, verified <YYYY-MM-DD>, docs/evidence/sources/<id>.md)`, `(<file path>:<line>)`, or `(cmd: <command>, [EV: <log path>])`. Anything you cannot resolve is tagged `[UNVERIFIED]`. Never invent a node id, API, statute, tool capability or file.
3. Exhaustive means exhaustive: every frame, every element, every row. No "etc.", "and so on", "…", "similar to the above", "remaining items follow the same pattern", "for brevity". If the set is too large for you, write what you finished, mark the rest `[NOT YET ANALYSED: <list>]`, and say so in the report.
4. No placeholders (`TODO`, `TBD`, `lorem`, empty or dash-only cells). Unknown → `[UNVERIFIED]`, `[ASSUMPTION-nnn]` (with the Q text in your report), or `N/A (<reason of ≥3 words>)`.
5. Write long files in sections (≤400 lines per write); finish with `<!-- END OF FILE -->`; verify with `wc -l` and `tail -3` and quote both in your report. If you cannot finish, name the file `<name>.PARTIAL.md` with a last line `PARTIAL: resume at <heading>`.
6. Any command you run goes through `scripts/run_logged.sh <label> -- <command>`; cite `[EV: <path>]`; non-zero exits are reported, never hidden.
7. Red lines RL-1–RL-9 and the Say / Don't say table apply to every UI-facing string you write or propose.
8. Three attempts on any single item, then record it as BLOCKED in your report and move on.
9. Limit for this brief: <n> items or <n> minutes of work, whichever first; then report what is done and what is not.
10. Verbatim Figma copy, legislation and tool output go inside ```figma-copy, ```quote or ```output fences.
11. As your last action write the list of your output paths (repository-relative), one per line, to `docs/agents/<agent-id>/outputs.txt` — the SubagentStop hook checks exactly those files.

## Verification tags you must use
`[UNVERIFIED]` · `[ASSUMPTION-nnn]` · `[NOT YET READ]` · `[NOT YET ANALYSED: …]` · `[DESIGN-DOC-ONLY: …]` · `verified YYYY-MM-DD` · `FIGMA-GAP-nnn` (only when a brief-required state is absent from the cache)

## Report format (your final message; ≤ 20 lines; nothing else)
OUTPUTS: <path> (<lines> lines, end marker: yes/no/PARTIAL) ; …
IDS ALLOCATED: SCR-<a>…<b> (<n> used), FRM-…, CMP-…, INT-…
CLAIMS: <n> total; <n> cited; <n> [UNVERIFIED] (ids or lines)
GAPS: <FIGMA-GAP ids or none> ; NOT YET ANALYSED: <list or none>
OPEN: <question → default adopted> ; …
BLOCKED: <item → what you tried (3 attempts) → verbatim error> ; …
PROPOSED CHANGES OUTSIDE OWNERSHIP: <file: change> ; …
EVIDENCE: <log paths>
```

---

## 04-T2 — Independent reviewer brief (the reviewer never authored the artefact)

```markdown
# REVIEW BRIEF <REVIEW-id, e.g. R-PRODUCT_SPEC-1 or R-MS03-2> — loop <1|2|3> of 3
Spawned by: orchestrator, <ISO>. You did not write the artefact under review and have no memory of its authoring. Verdict is PASS or FAIL. FAIL needs file:line items. Do not fix anything; do not soften; do not praise.

## Artefact under review
- <path> (<lines> lines) — produced by <brief id> for <Phase n | MS-nn>
- Required structure (from the master prompt phase or the milestone plan): <section list or template id>

## Read first
1. docs/AGENT_RULES.md
2. <the artefact>
3. Upstream sources it must agree with: <paths, e.g. docs/PRODUCT_SPEC.md, docs/figma/raw/…>
4. <document-specific checklist if any>

## Generic checklist (answer every line PASS/FAIL with a one-line reason; FAIL lines need file:line)
1. File exists at the stated path; ends with `<!-- END OF FILE -->`; `scripts/run_logged.sh review-validate -- python3 scripts/validate_docs.py <path>` exits 0 (cite the log).
2. No truncation or placeholder markers outside ```figma-copy / ```quote / ```output fences and backticks (F3, F5 lists); no empty or dash-only cells.
3. Every required section is present and non-trivial (no section under three lines unless the brief allows `none`).
4. Ids: every id defined in this file is defined once; every id referenced resolves (in this file or the owning document); ids fall in the allocated range; formats conform.
5. Claim sampling: run `python3 scripts/claims.py <path>`; apply the deterministic rule (every index ≡ 0 mod ceil(N / max(10, N/10)), plus every claim on a line with a red-line term or a `LEGAL-` id). Resolve each sampled claim now: open the cache file and find the node id; open the saved excerpt or fetch the URL; open the path; re-run the command. Record `claim → source → RESOLVED | UNRESOLVED` in docs/evidence/reviews/<REVIEW-id>-claims.md. Any UNRESOLVED → FAIL.
6. Evidence: every sentence with a verification verb ends with `[EV: …]`; the file exists; it has the run_logged header and footer (or is a hook cache file or a sources excerpt); its content supports the claim (open it).
7. Red lines: scan every UI-facing string (proposed copy, acceptance criteria quoting UI, example notifications) for RL-2 terms, drug names in glanceable contexts, "missed"/streaks/red counts, Don't-say phrases. Internal engine/data names allowed only where marked internal.
8. Assumptions: every gap is `[ASSUMPTION-nnn]` with a matching `Q-nnn`; no plausible-sounding behaviour is presented as fact without a node id, document reference or assumption tag; every FEAT-/ENG-/DATA- row has a Source.
9. Consistency with upstream: check every `FACT-` key that appears in the artefact against docs/FACT_REGISTER.md and 10 further facts against the upstream sources listed; list every mismatch.
10. Time-sensitive facts carry `verified YYYY-MM-DD` with a URL and an excerpt file that contains the claimed value; timestamps parse as ISO 8601 with offset and seconds.
11. Terse and technical: no paragraph over 5 lines outside tables; no sentence begins with "I" or "We"; no preamble; Australian spelling.
12. Document-specific checks: <from the master prompt's phase text or the milestone plan — list them>.
13. (Build reviews only) The diff implements the plan's tasks and nothing else; no dependency or service absent from docs/ARCHITECTURE.md; no test disabled, skipped, deleted or weakened; no `TODO`/`fatalError`/placeholder in production paths; engine invariant and red-line tests present in the suite; file ownership respected; `.xcodeproj` not hand-edited.

## Report format (final message; nothing else)
VERDICT: PASS | FAIL
ITEMS: <n> checked; <n> FAIL
FAILURES (file:line → what is wrong → what would fix it): …
SAMPLE: <n> claims sampled of <n>; <n> resolved; UNRESOLVED: <list>
MISMATCHES WITH UPSTREAM: <list or none>
RED-LINE HITS: <list with line numbers, or none>
EVIDENCE: <log and claims-file paths>
```

---

## 04-T3 — Gate report `docs/gates/GATE-n.md` (planning) and `docs/gates/BG-nn.md` (build)

```markdown
# GATE <G0…G5 | BG-nn> — <phase range | milestone name>
Opened: <ISO> · Closed: <ISO> · Session: <n> · Loops run: <0–3>
Contract and docs/AGENT_RULES.md re-read at this gate (F17): YES, at <ISO>
Usage at gate: <what /usage shows, or "not checked">
Result: PASS | PASS_WITH_RESIDUALS | FAIL (loop <n> of 3) | HARD FAIL (E2)

## Checklist
| # | Check (from the master prompt's gate row / milestone plan) | Method (scripts/gate.py item / reviewer id / command) | Result | Evidence |
|---|---|---|---|---|
| 1 | <check> | <method> | PASS/FAIL | [EV: docs/evidence/<file>] |

## Failures found and fixes applied (per loop)
| Loop | Item # | Failure | Fix applied by | Re-check result | Evidence |
|---|---|---|---|---|---|

## Residuals (only if PASS_WITH_RESIDUALS; never a hard-fail class)
| RESIDUAL-nnn | Item | Reason it remains | Owner (build-phase / Devesh) | File#section | Risk if unfixed | What would fix it |
|---|---|---|---|---|---|---|

## Counts at this gate
Documents validated: <n> · Validator failures: <n> · Claims sampled: <n>, unresolved: <n> · [UNVERIFIED] in scope: <n> · [NOT YET READ]: <n> · metadata-only-variant rows: <n> · Open B-: <n> · Open UA-: <n> · QUESTIONS_ASKED_TO_USER: 0 · Figma reads this epoch: <n>/<cap>

## Next
<phase or milestone that now begins>

<!-- END OF FILE -->
```

---

## 04-T4 — `docs/PROGRESS.md`

```markdown
# PROGRESS — Planner
RUN_STATUS: RUNNING
RUN_STARTED: <ISO>
UPDATED: <ISO>
CURRENT_PHASE: <e.g. 1.2 | MS-03 step 4>
NEXT_ACTION: <one imperative sentence naming the file or node to act on next>
RETRY_AFTER: none
LOCK_FINGERPRINT: none
FIGMA_EPOCH_READS: 0/150
LAST_GATE: none
OPEN_BLOCKERS: 0
QUESTIONS_ASKED_TO_USER: 0
TURNS_ENDED_WAITING: 0
RUN-SURVIVAL: <OK | AT RISK (<which>)>
Run: PLANNING | BUILD · Session: <n> · Model: <as reported>

## Status by phase / milestone
| Phase or MS | Status (NOT STARTED / IN PROGRESS / DONE / DEFERRED / BLOCKED) | Started | Finished | Gate | Outputs (paths) | Evidence |
|---|---|---|---|---|---|---|

## Checkpoints (newest first; keep the last 30)
| Timestamp | Phase/MS | Step | Note |
|---|---|---|---|

## Sessions
| Session | Started | Ended | Reason (finished / usage limit / crash / read cap / compaction / Devesh closed) | Resumed by |
|---|---|---|---|---|

## Log (newest first; API_ERROR and COMPACTION lines appended by hooks)

## Deferred work (C-14 / E6)
| Item | Waiting on | Since | Return condition |
|---|---|---|---|

<!-- END OF FILE -->
```

---

## 04-T5 — `docs/DECISION_LOG.md` entry (append-only; never edit an earlier entry; supersede instead)

```markdown
## D-nnn — <short title>
Date: <ISO> · Phase/MS: <…> · Decided by: orchestrator (from <brief/reviewer id if any>) · Status: ADOPTED | SUPERSEDED BY D-mmm
Context: <the situation and the sources considered, with citations>
Decision: <one or two sentences, definite>
Alternatives rejected: (1) <alternative — why rejected> (2) <…>
Consequences: <files, ids and tasks affected; what must now be true>
Reversible: YES (<how>) | NO (<why>)
Related: Q-nnn | ASSUMPTION-nnn | B-nnn | FIGMA-GAP-nnn | FACT-nnn | none
Evidence: <path or none>
```

---

## 04-T6 — `docs/BLOCKERS.md` entry

```markdown
## B-nnn — <short title>
Opened: <ISO> · Phase/MS/step: <…> · Status: OPEN | RESOLVED <ISO> | USER ACTION REQUIRED (UA-nnn) | WONTFIX (<reason>)
Attempted (exact): <tool call or command with arguments; secrets masked>
Result (verbatim, first 10 lines, indented):
    <line 1>
    <line 2>
Error class (Figma): rate-limit | auth | not-found | transport | n/a
Why it blocks: <what cannot proceed>
Work continued without it: <what was done instead; what is deferred>
Fix in plain English (for Devesh if applicable): 1. <step> 2. <step> — success looks like: <…>
Retry log: <ISO> → <result> ; <ISO> → <result>
Effect on downstream work if never resolved: <…>
```

---

## 04-T7 — `docs/figma/read-ledger.md` (header once; epoch header per epoch; one row per read, written by the hooks)

```markdown
# FIGMA READ LEDGER — the only source of truth for reads used
Verified limit: <n>/day, <n>/min (source URL, verified <YYYY-MM-DD>) · Caps: 150 per rolling 24 h, ≤8 per rolling 60 s, ≥7 s apart · Rule: a cached node is never re-read except tagged lock-check / retry / delta-audit
Budget rule in force: <rolling-24h-from-first-read | observed-reset at HH:MM UTC>
EPOCH 1 | started <ISO> | cap 150 | reads 0 | first_limit_error none | observed_reset unknown
| # | Timestamp | Session/agent | Tool | File key | Node id | Intent (plan line / lock-check / retry / delta-audit) | Cache path | Result (pending / ok / truncated / error <class>: <text>) | Response bytes | Reads in last 24 h after this | Reads in this minute |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 2026-10-01T09:02:11+1000 | 1/orchestrator | get_metadata | <key> | 0:1 | lock-check | docs/figma/raw/<key>/get_metadata/0_1.txt | ok | 18211 | 1 | 1 |
LIMIT-HIT <ISO> / LIMIT-RESET-OBSERVED <ISO> lines are appended by the hooks between rows.
```
Row rules: a rate-limited read (429) is logged and counted; the next attempt at that node is ≥60 s later and tagged `retry`. A `recovered` note in Result marks rows reconstructed from the cache after a crash (03 Variant B).

---

## 04-T8 — Evidence naming convention (`docs/evidence/`)

```text
Planning:    docs/evidence/p<nn>/<label>-<agentid>-<ISO-compact>.log      e.g. p00/preflight-orchestrator-20261001T0902.log
Gates:       docs/evidence/g<n>/<label>-<agentid>-<ISO-compact>.log
Reviews:     docs/evidence/reviews/<REVIEW-id>-<topic>.md                  (claims files and reviewer notes; header "review:")
Spot-checks: docs/evidence/p<nn>/spotcheck-<brief-id>-<agentid>-<ISO-compact>.log
Sources:     docs/evidence/sources/<LEGAL-|IOS-|FACT-id>.md                (written only by scripts/fetch_excerpt.py)
Resume:      docs/evidence/resume/<ISO-compact>.log, docs/evidence/resume/resume-recovery-<ISO-compact>.log
Checkpoints: docs/evidence/checkpoints/PROGRESS-<ISO-compact>.md           (PreCompact hook)
Build:       docs/evidence/ms<nn>/<label>-<agentid>-<ISO-compact>.log      e.g. ms03/tests-run1-verifier7-20261105T1410.log
Features:    docs/evidence/features/<FEAT-id>/<variant>-<ISO-compact>.png  variants: light, dark, dyntype-xxxl, discreet, reduce-motion, offline, permission-denied, watch, widget-<size>
             docs/evidence/features/<FEAT-id>/verify.log                   (the executed manual script with per-step PASS/FAIL; tester = verifier brief id)
Release:     docs/evidence/release/<version>-<build>/REL-nnn.<ext>
Every command log is written only by scripts/run_logged.sh, which refuses to reuse a path, and begins with:
  # cmd: <exact command>   # cwd: <path>   # agent: <agent id>   # start: <ISO>
and ends with:
  # exit: <code>   # end: <ISO>
A claim cites the path with [EV: <path>]; the reviewer opens it and checks exit code and content.
```

---

## 04-T9 — Milestone report `docs/milestones/MS-nn-report.md` (build phase)

```markdown
# MILESTONE REPORT — MS-nn <name>
Opened: <ISO> · Closed: <ISO> · Branch: ms-nn-<slug> → merged into dev at <commit> · Tag: ms-nn-<slug>-done · Gate: BG-nn <PASS | PASS_WITH_RESIDUALS>
Objective (from IMPLEMENTATION_PLAN): <one sentence>
Figma lock re-check: <unchanged | delta audit run: pages …> (ledger row #<n>)

## Tasks
| TASK-id | Implements | Status (DONE / DEFERRED → MS-mm / OPEN) | Implementer brief | Commit(s) | Completion criterion met (quoted) |
|---|---|---|---|---|---|

## Tests
Run 1: <command> → <passed>/<total> [EV: <path>] · Run 2: <passed>/<total> [EV: <path>] · Flaky: <TEST-ids or none> · New tests: <TEST-ids> · Red-line and invariant tests present in run: YES
Build: <command> → success [EV: <path>] · Warnings introduced: <n> (fixed: <n>)

## Feature verification
| FEAT-id | Level | TEST-ids passed | Manual script run by | Variants exercised | Status (VERIFIED / PENDING-DEVESH / UNVERIFIED: reason) | Evidence folder |
|---|---|---|---|---|---|---|

## Review
Reviewer: <capability / brief id> · Loops: <n> · Final verdict: APPROVED | residuals: <list with file:line>

## Decisions I took (Q- defaults), blockers, user actions created
D-: <ids> · Q-: <ids with defaults> · B-: <ids> · UA-: <ids and the milestone each one blocks>

## Residuals carried forward
| RESIDUAL-nnn | Item | Reason | Owner | Target milestone |
|---|---|---|---|---|

## Next milestone
MS-mm <name> — first action: <…> — user actions it needs: <UA-ids or none>

<!-- END OF FILE -->
```

---

## 04-T10 — `USER ACTION REQUIRED` callout (placed where it arises AND appended to docs/USER_ACTIONS.md)

```markdown
> ## USER ACTION REQUIRED — UA-nnn: <short title>
> **Needed before:** <MS-nn <name> | Phase n | "none — do when convenient">
> **Blocking now?** NO — Claude Code continues with <what> and skips <what> until this is done | YES — every remaining milestone needs it
> **Why:** <one plain-English sentence>
> **Takes about:** <n> minutes
> **Steps:**
> 1. <Open X.> 2. <In the menu bar click Y → Z.> 3. <Type/select …>
> **You will know it worked when:** <what the screen shows>
> **If it fails:** <the one most likely cause and what to do; otherwise "write what you saw after Status: and Claude Code will pick it up on the next resume">
> **Status:** PENDING   ← Devesh changes this to DONE (or writes what happened)
> Created: <ISO> by <phase/milestone> · Also recorded in: <B-nnn if any>
```

---

## 04-T11 — Per-page Figma analysis `docs/figma/analysis/<page-slug>.md` (Phase 3; one file per page; cache only)

```markdown
# FIGMA ANALYSIS — page "<page name>" (node <page node id>)
Analyst brief: <brief id> · Written: <ISO> · Lock fingerprint: <root sha256 prefix> · Page fingerprint: <sha256>
Cache read: docs/figma/raw/<fileKey>/<page-slug>/nodes.json; docs/figma/raw/<fileKey>/get_design_context/<nodeId>.* × <n>; variables (Foundations, Components); docs/figma/raw/<fileKey>/get_figjam/<board>.*; motion context × <n>
Id ranges: SCR/FRM/CMP/INT-<a>…<b> (allocated by the orchestrator)
Scope tier of this page: MVP | v1 | Future | Foundations/Components | Prototype/Handoff

## 1. Frame inventory (every top-level frame; count must equal the nodes.json depth-1 count)
| Id (SCR-/FRM-/CMP-) | Frame name | Node id | Kind | Platform | Size (w×h) | Flow membership (Prototype flow name or none) | Variant axes present (light, dark, Calm, Spark, DynType-default, DynType-XXXL, Discreet, 375pt, ProMax) | Base variant? | States present (initial / empty / first-day / loading / error / success / disabled) | Prototype links out (target node ids) | Design context cached? (yes / [NOT YET READ] / metadata-only-variant of <id>) |
|---|---|---|---|---|---|---|---|---|---|---|---|
Frames in nodes.json: <n> · Rows above: <n> · Components/component sets: <n> · Instances: <n> · Text layers: <n> · Interaction candidates: <n>

## 2. Per-frame analysis (repeat 2.x for EVERY row above with design context cached; no frame may be omitted)
### SCR-nnnn | <frame name> | <node id> | <cache path> | <Kind> | <Platform> | <variant axes>
**A. Sees** (one row per state; a state the brief requires but the cache lacks is a FIGMA-GAP row)
| State | Present? (node id or FIGMA-GAP-nnn) | Description (layout, key elements; copy verbatim in ```figma-copy fences) | Variants |
|---|---|---|---|
#### INT-nnnn | <element name> | <node id>   (one block per candidate from `figma_reconcile.py --candidates <page>`; a non-interactive candidate gets one line `NON-INTERACTIVE (<reason>)`)
**B. Does** — trigger (tap / long press / swipe / drag / type / picker / toggle / system event) · result (navigation target node id / overlay / state change / data change) · transition/animation (from motion or prototype data; `route-source: inferred` if not directly readable) · haptic/notification implied
**C. Logic** — one line per category, each `yes (<what>)` or `no`: local state · persistent storage · server-side state · authentication · API request · notification scheduling · engine (scheduling | focus-window | personalisation | constraint | conflict | notification-planner | check-in | lifestyle | signpost) · background processing · calendar access · reminder access · HealthKit · watch data · location · push notification · widgets · Live Activities · Siri/App Intents · Shortcuts · CloudKit · analytics · sync · encryption · permissions · other (named) — candidates named without ids (ids are assigned in their owning phases)
**D. Data** — entity · fields (name: type) · data class (planned / observed / inferred / confirmed / external / recommendation) · internalOnly? · residency · candidate entity name (DATA- id assigned in Phase 7). Never 'stores medication information' — name every field, at least to this depth for medication: medication id, name, formulation, strength, units, user-set reminder time, logged instant, log state (logged / undone / edited — never 'skipped' or 'missed'), stated window offsets, learned window offsets (internalOnly), confidence, evidence counts, history snapshots
**E. Fails** — every applicable item from the Phase 3 failure list: scenario · effect on this element · mitigation · candidate test (named; TEST- id assigned in Phase 10/14) (`N/A (<reason>)` allowed; blank is not)
**Red-line scan of this frame's text layers**
| Text layer node id | Text (verbatim, ```figma-copy) | RL hit? (RL-n or none) | Don't-say / category hit? (Cn or none) | Proposed replacement (if hit) |
|---|---|---|---|---|

## 3. Page-level counts (consumed by scripts/figma_reconcile.py and validate_analysis.py)
frames: <n> · components: <n> · component sets: <n> · variants: <n> · instances: <n> · text layers scanned: <n> · interaction candidates: <n> · INT rows: <n> · NON-INTERACTIVE rows: <n> · prototype starting points: <n> · variables referenced: <n> · metadata-only-variant rows: <n>

## 4. Gaps, unverified, unread, defects
FIGMA-GAP-nnn: <required state/screen absent | defect: detached instance / dead-end link / "Copy"/"Old" frame> with node ids … · [NOT YET READ]: <node ids> · [UNVERIFIED]: <items> · layout ambiguous (requests a T12 screenshot): <frame ids or none>

## 5. Reconciliation notes for Phase 5
Document-only features touching this page (from docs/SOURCE_NOTES.md rows): <list> · Figma-only features: <named candidate features; FEAT- ids assigned in Phase 5> · Contradictions noticed: <list with source#heading and node ids>

<!-- END OF FILE -->
```

---

## 04-T12 — `docs/OPEN_QUESTIONS.md` entry (Devesh answers by editing the `ANSWER:` line; the pre-filled default stands if untouched)

```markdown
## Q-nnn — <question in one sentence, plain English>
Group: MUST ANSWER BEFORE CODING | CAN SAFELY USE RECOMMENDED DEFAULT | CAN DECIDE LATER
Raised in: <Phase n / MS-nn> · Related: ASSUMPTION-nnn · D-nnn (default adopted) · LEGAL-nnnn (if any)
Why it matters: <one or two sentences>
Options: A) <…> B) <…> C) <…>
Recommended default: <letter> — <one line why>
Consequence of each option: A) <files/tasks that change> B) <…> C) <…>
ANSWER: <letter or free text — pre-filled with the recommended default>
Status: DEFAULT ADOPTED | ANSWERED <ISO> (D-mmm)
```

---

## 04-T13 — `docs/USER_ACTIONS.md` (the one file Devesh checks; grouped by when it is needed)

```markdown
# USER ACTIONS — everything only Devesh can do, grouped by when it is needed
How to use: do the items in the earliest group first; change `Status: PENDING` to `Status: DONE` when finished (or write what happened); Claude Code re-reads this file on every resume and at every milestone. Nothing waits on these; Claude Code works around them until they are done.
Last updated: <ISO> · Pending: <n> · Done: <n>

## Before the build starts (MS-00)
<04-T10 callouts>

## Before MS-nn — <name>
<04-T10 callouts>

## Before public TestFlight / release (lawyer, entity, privacy policy hosting, trade mark, TGA self-assessment signature, crisis-number check)
<04-T10 callouts>

## Do when convenient (nothing waits on these)
<04-T10 callouts>

## Done
<moved here by Claude Code after it confirms the effect, with the confirming evidence path>

<!-- END OF FILE -->
```

---

## 04-T14 — `docs/MANIFEST.md` and `docs/WORK_QUEUE.md` rows

```markdown
# MANIFEST — every deliverable; the validator's scope
| Path | Owning phase/MS | Status (NOT STARTED / IN PROGRESS / DONE) | Author brief | Reviewer | Validated at gate |
|---|---|---|---|---|---|
| docs/PREFLIGHT.md | 0 | DONE | orchestrator | R-G0-1 | G0 |

# WORK QUEUE — tasks that need no unread Figma node (kept non-empty before each read epoch ends)
| Item | Phase | Inputs available (paths) | Owner (orchestrator / brief id) | Status |
|---|---|---|---|---|
```

<!-- END OF FILE -->
