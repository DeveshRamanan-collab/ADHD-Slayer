# Spec Checklist — 2026-10-01T14:10:02+1000
Task: planning-run-v3

## Original request
"Requirement source: the file prompts/01_MASTER_PLANNING_PROMPT.md in this project (read it in full). Extract an explicit checklist covering every phase 0–25, every gate G0–G5 and every named deliverable path. Task slug: planning-run-v3."

Requirement source read in full: `prompts/01_MASTER_PLANNING_PROMPT.md` (978 lines; v3, 1 October 2026). Item ids: `Pnn-mm` = Phase nn; `GATE-Gn-mm` = gate; `CTR-mm` = contract and operating mode; `DLV-mm` = final deliverable tree.

## Extracted checklist

### Contract, operating mode and exit rules (cross-cutting)
- [ ] **CTR-01** No question is asked of Devesh and AskUserQuestion is never called; every product question is a `Q-nnn` with an adopted default and `[ASSUMPTION-nnn]` tags (C-2, OM-1.6); `QUESTIONS_ASKED_TO_USER` and `TURNS_ENDED_WAITING` stay 0 in `docs/PROGRESS.md`.
- [ ] **CTR-02** NEVER list honoured for the whole run: no Figma modification, no force-push or history rewrite, no branch/tag deletion, no publish/deploy/submit/purchase, nothing outside the project folder, no `sudo` or terminal-reading command, no secret printed, no production code outside `/poc` (C-3, OM-1).
- [ ] **CTR-03** Every deliverable is listed in `docs/MANIFEST.md`, ends with `<!-- END OF FILE -->` and passes `scripts/validate_docs.py` (C-6, F4).
- [ ] **CTR-04** Every verification verb carries `[EV: docs/evidence/<path>]` to a `run_logged.sh`/hook/`fetch_excerpt.py` artefact with header and footer (C-7, F2).
- [ ] **CTR-05** Every fact is cited from this session (node id + cache path; URL + `verified YYYY-MM-DD` + excerpt; file:line; command + log) or tagged `[UNVERIFIED]` (C-8, F1, F9).
- [ ] **CTR-06** Figma reads only by the orchestrator or the designated reader, cached and ledgered by hooks; cap 150 per rolling 24 h, ≤8 per 60 s, ≥7 s apart; no cached node re-read except `lock-check`/`retry`/`delta-audit`; no rate-limited retry within 60 s (C-9, F27).
- [ ] **CTR-07** Work fanned out to subagents with explicit file ownership; no two agents write one file; only the orchestrator writes shared state files, merges and runs Git; every brief is self-contained (04-T1) and includes `docs/AGENT_RULES.md` (C-10, OM-3, F11).
- [ ] **CTR-08** Generator ≠ reviewer for every document and gate, using deterministic claim sampling; every subagent output spot-checked and logged under `docs/evidence/` before integration (C-11, OM-3, F16).
- [ ] **CTR-09** Gate loop author→review→fix at most 3 times, then `RESIDUAL-nnn`; hard-fail classes never become residuals and trigger E2 (C-12, OM-4).
- [ ] **CTR-10** `docs/PROGRESS.md` header (all 13 keys) updated at every phase boundary, gate, subagent merge, Figma budget event and before ending any turn; `docs/DECISION_LOG.md` and `docs/BLOCKERS.md` append-only above the end marker; resume protocol run on every session start (C-13, OM-5).
- [ ] **CTR-11** Anything only Devesh can do is a `UA-nnn` (04-T10) in `docs/USER_ACTIONS.md` written before the step needing it; nothing waits (C-14).
- [ ] **CTR-12** Timestamps from the system clock, ISO 8601 with offset and seconds, Australia/Sydney; durations from instants (C-15, F18).
- [ ] **CTR-13** Three attempts per item then `B-nnn`; no tool call waits longer than 10 minutes; commands over 2 minutes run via `run_logged.sh --background` (C-16, OM-2, F19).
- [ ] **CTR-14** Red lines RL-1–RL-9 enforced as invariants in every spec, engine, data-model marking, copy rule and test; register F1–F30 binds every agent (C-17, K.4).
- [ ] **CTR-15** No deliverable shortened, sampled or summarised; banned phrases (`etc.`, `and so on`, ellipsis, `similar to the above`, `follow the same pattern`, `for brevity`) absent outside exempt fences; long documents written as parts ≤400 lines per write and assembled by `scripts/assemble_docs.py` (C-5, OM-2, F3).
- [ ] **CTR-16** No placeholders (`TODO`, `TBD`, `FIXME`, `lorem`, empty or dash-only cells); unknowns use `[UNVERIFIED]`, `[ASSUMPTION-nnn]` or `N/A (<reason ≥3 words>)` (F5).
- [ ] **CTR-17** Reporting is one or two lines per phase boundary and gate; no narrative, no praise; every report to Devesh is also a file (C-18, OM-6).
- [ ] **CTR-18** Legitimate stops are only E1–E6; each stop writes `RUN_STATUS`, `RETRY_AFTER`, `NEXT_ACTION`, commits and ends cleanly (C-20); the Stop hook blocks any other end of turn (OM-1.9).
- [ ] **CTR-19** Permission mode verified as `bypassPermissions` (or acceptable `dontAsk`); otherwise E4 with the RELAUNCH REQUIRED block printed verbatim (OM-1.5).
- [ ] **CTR-20** Usage limits handled per OM-7: no `/usage-credits`, `/model`, `/login`, `/config`, no model switch, no edits to `~/.claude/settings.json`; each gate file records "Usage at gate".
- [ ] **CTR-21** Identifier scheme enforced: each id defined exactly once in its owning document, every reference resolves, malformed look-alikes rejected, tasks always `TASK-nnnn`, per-page id ranges respected (Glossary, F20).
- [ ] **CTR-22** No time or effort estimates anywhere (size S/M/L only); no entity/engine/module name collides with a Swift/Foundation/Apple framework type (F30).
- [ ] **CTR-23** Documents are terse: no paragraph over 5 lines outside tables, no sentence begins with "I" or "We", no preamble (F21).
- [ ] **CTR-24** Immutable inputs under `research/`, `docs/design/`, `prompts/` (originals) and the design-session `SPEC_CHECKLIST.md` are never edited, moved or updated (K.3).
- [ ] **CTR-25** Conflicts between sources resolved by the K.3 procedure (identify, quote both, intended behaviour, `Q-nnn` if ambiguous, decide, `D-nnn` + changelog row); no feature silently discarded.
- [ ] **CTR-26** K.5 design-brief defaults carried forward and each logged as `D-nnn` (18+ `confirmedAdult` only; "focus window"; local-only MVP; no third-party AI at launch; Health = sleep and workouts only, dose import off and read-only; university-student audience; notification budget 5 a day; pricing pending; Devesh's routine one preset among several).
- [ ] **CTR-27** Development principles 1–18 applied (specification before code, logic before UI, one source of truth, user-confirmed vs inferred data never blurred, no over-engineering, tools do not dictate architecture).

### Phase 0 — Bootstrap, preflight, tool audit, enforcement and state
- [ ] **P00-01** 0.0a: `prompts/01_MASTER_PLANNING_PROMPT.md` exists and its first and last 20 lines match the given prompt.
- [ ] **P00-02** 0.0b: bootstrap `CLAUDE.md` (≤60 lines) at the repo root with state pointer, never-ask rule, Figma hook rule, the NEVER list and RL-1–RL-9 one line each.
- [ ] **P00-03** 0.0c: `.claude/settings.json` merged from `prompts/05_SETTINGS_AND_HOOKS.md` (deny list; all hooks: SessionStart, PreCompact, Stop, StopFailure, PreToolUse Bash/Figma/Write-Edit/all, PostToolUse and PostToolUseFailure Figma, Elicitation, SubagentStop) with no `defaultMode`; hook field names confirmed against https://code.claude.com/docs/en/hooks.
- [ ] **P00-04** 0.0d: `scripts/run_logged.sh`, `scripts/fetch_excerpt.py`, `scripts/validate_docs.py` written from `prompts/06_SCRIPT_SPECS.md`.
- [ ] **P00-05** 0.0e: state files initialised: `docs/PROGRESS.md` (RUN_STATUS: RUNNING), `docs/MANIFEST.md` (every RUN ORDER deliverable, pattern paths expanded per page), `docs/DECISION_LOG.md`, `docs/BLOCKERS.md`, `docs/USER_ACTIONS.md`, `docs/OPEN_QUESTIONS.md`, `docs/WORK_QUEUE.md`, `docs/figma/read-ledger.md`, `docs/figma/.intent`, `docs/gates/`, `docs/evidence/p00/`, `docs/agents/`.
- [ ] **P00-06** 0.0f–g: every hook tested with a harmless call (`docs/evidence/p00/hooks-<ISO>.log`) and bootstrap recorded in `docs/evidence/p00/bootstrap-<ISO>.log`.
- [ ] **P00-07** 0.1: `docs/PREFLIGHT.md` table (capability | status | evidence | fix) covering all 15 items: working directory, source inventory, harness/version/login/continuation, Claude Code configuration, Figma MCP (`whoami` + one root `get_metadata` tagged `lock-check`), Git/GitHub, Apple toolchain gate, Xcode MCP server, package managers, web access routes, subagents/teams, optional connectors, Devesh-only actions, one-time prompts triggered, `RUN-SURVIVAL` first line.
- [ ] **P00-08** 0.1 item 2: `docs/SOURCE_INVENTORY.md` lists every file under `docs/design/`, `research/`, `prompts/` and root `*.md` with path, size, lines, SHA-256, description and present/missing against K.2.
- [ ] **P00-09** 0.1: every MISSING/NOT OK row is a `B-nnn`, and a `UA-nnn` where only Devesh can fix it; `XCODE_MAJOR` recorded as a `FACT-`.
- [ ] **P00-10** 0.2: environment enumerated by observation (plugins, MCP servers, skills, slash commands, agent types, hooks, settings) into `docs/evidence/p00/discovery-*.log`; every Appendix A candidate checked; nothing uninstalled or reconfigured.
- [ ] **P00-11** 0.3: `docs/TOOL_CAPABILITY_AUDIT.md` with Tier A full entries (all eight headings, harmless-call `[EV:` for PRIMARY/SECONDARY/REVIEW) and Tier B one-line rows; Tier A + Tier B = items discovered.
- [ ] **P00-12** 0.4: every Tier A item classified PRIMARY / SECONDARY / REVIEW-VERIFICATION / OPTIONAL / NOT RECOMMENDED; 16-row stage table each naming ≥1 confirmed capability.
- [ ] **P00-13** 0.5–0.6: complementary pairings documented; overlaps resolved (primary, reviewer, avoided, switch condition); one planning/SDLC spine chosen with a `D-nnn`.
- [ ] **P00-14** 0.7: `docs/figma/TOOL_COVERAGE.md` records which Figma read tools exist, which are counted, which attributes each exposes, the rate-limit page figures as `FACT-`, variable scope, transport and REST route.
- [ ] **P00-15** 0.8–0.11: Xcode/Apple routes (A vs B), Git/GitHub capabilities, testing/review capabilities and research routes recorded with evidence.
- [ ] **P00-16** 0.12–0.13: `docs/TOOL_STRATEGY.md` with division of labour and the multi-agent operating plan (fan-outs, file-ownership map covering every manifest entry, reviewer per document, designated reader, model policy, agent-team usage); tools carried forward into later documents.
- [ ] **P00-17** 0.14–0.15: tools do not dictate architecture; only read paths of dual-path tools used during planning.
- [ ] **P00-18** 0.16 item 1: `docs/AGENT_RULES.md` = CONTRACT + OM-1–OM-7 + F1–F30 + RL-1–RL-9 + 04-T1 rules block + ID scheme, verbatim.
- [ ] **P00-19** 0.16 item 2: all scripts written (`validate_docs.py`, `validate_analysis.py`, `figma_reconcile.py`, `figma_fingerprint.py`, `figma_read_plan.py`, `extract_text.py`, `copy_scan.py`, `au_spelling.py`, `claims.py`, `check_facts.py`, `check_names.py`, `check_tasks.py`, `trace.py`, `design_doc_xref.py`, `assemble_docs.py`, `gate.py`, `check_scope.sh`, `secret_scan.sh`, `run_logged.sh`, `fetch_excerpt.py`, `run_planning.sh`), each with `--help`, non-zero on failure, `file:line:RULE: message`, each proven on a fixture with `[EV:`.
- [ ] **P00-20** 0.16 items 3–4: quoting convention applied; `.gitignore` before first commit; `scripts/secret_scan.sh` as pre-commit hook.
- [ ] **P00-21** 0.16 item 5: spec-drift tool used: design-session `SPEC_CHECKLIST.md` preserved first (or its absence recorded), `init` run on this prompt, ≥1 item per phase 0–25 verified, else `NOT USABLE FOR THIS PROMPT`.
- [ ] **P00-22** 0.16 item 6: Git bootstrap non-interactive (existing work committed, never reset); Phase 0 commit; private GitHub repo created if `gh` authenticated (else `UA-nnn`); `git push --dry-run`.
- [ ] **P00-23** 0.16 item 7: `prompts/04_AGENT_BRIEFS_AND_TEMPLATES.md` read in full.
- [ ] **P00-24** 0.17: First report (8 items, ≤40 lines) printed and written to `docs/FIRST_REPORT.md` after G0; work continues into Phase 1 in the same turn.

### Gate G0
- [ ] **GATE-G0-01** `docs/PREFLIGHT.md` every row status ∈ {OK, MISSING, UNVERIFIABLE} with an existing `[EV:` path; `RUN-SURVIVAL` line present.
- [ ] **GATE-G0-02** Tier A entries + Tier B rows = items in `docs/evidence/p00/discovery-*.log`; every PRIMARY/SECONDARY/REVIEW entry has a harmless-call `[EV:`.
- [ ] **GATE-G0-03** `docs/TOOL_STRATEGY.md` names ≥1 capability per stage-table row and has the ownership map covering every manifest file.
- [ ] **GATE-G0-04** Every hook script in `prompts/05_SETTINGS_AND_HOOKS.md` has a test log in `docs/evidence/p00/hooks-*.log` (fixtures and override env vars, never real files).
- [ ] **GATE-G0-05** `scripts/validate_docs.py --manifest` exits 0.
- [ ] **GATE-G0-06** `git log` shows the Phase 0 commit; `git status --porcelain` empty.
- [ ] **GATE-G0-07** Every MISSING row has a `B-nnn`.
- [ ] **GATE-G0-08** `docs/SOURCE_INVENTORY.md` lists every K.2 expected input as present or missing with SHA-256.
- [ ] **GATE-G0-09** `docs/gates/GATE-0.md` written (04-T3) with PASS/FAIL per item, evidence, loops, residuals and "Contract and docs/AGENT_RULES.md re-read at this gate: YES <ISO>".

### Phase 1 — Figma version check and lock
- [ ] **P01-01** Design inputs read in full before 1.1: `prompts/figma_design_prompt.md`, `docs/design/figma-usage.md`, `docs/design/decisions.md`, `docs/design/handoff.md`, `docs/design/DESIGN_SPEC.md`.
- [ ] **P01-02** 1.1: every candidate file key found (figma_urls, regex over docs/design, prompts, research, root md, `git log -p`) and recorded with location; none found → E4.
- [ ] **P01-03** 1.1: authoritative file decided by the listed criteria with a `D-nnn`; key, name, team, branch and URL recorded for design file and FigJam board.
- [ ] **P01-04** 1.2: root and per-page `get_metadata` cached; `docs/figma/raw/<fileKey>/<page-slug>/nodes.json` written from the cached response.
- [ ] **P01-05** 1.2: two `get_variable_defs` reads (Foundations, Components) compared; one `get_figjam` of the flows board; REST route calls only if `FIGMA_TOKEN` exists (≤3/day, ≥60 s apart); no screenshots.
- [ ] **P01-06** `docs/figma/FIGMA_STATE_REPORT.md`: staleness indicators as `FIGMA-GAP-nnn` kind `defect`; definition-of-done items present/absent/partial with node ids; absences as `FIGMA-GAP-nnn` kind `missing` (F28).
- [ ] **P01-07** 1.3: `docs/FIGMA_VERSION_LOCK.md` with keys, canonical fingerprints (root and every page via `scripts/figma_fingerprint.py`), page list and counts, variables as observed, flow starting points, interactions readability, MCP identity, verified limits, epoch header, verbatim known-limitation paragraph, audit date.
- [ ] **P01-08** Lock rules applied: Figma-derived documents cite the root fingerprint prefix; `lock-check` read at each later session start; delta audit on change, listed in the read plan first.
- [ ] **P01-09** 1.4: read-budget caps, epoch header, error classification (rate limit, monthly, auth, not found, transport) and per-frame read granularity (>400 descendants → children; TRUNCATED handling) followed.
- [ ] **P01-10** 1.4: `docs/figma/read-plan.md` generated by `scripts/figma_read_plan.py` with tiers T1–T12, totals per tier and epoch, cap at top; variant policy (`metadata-only-variant`) explicit.
- [ ] **P01-11** 1.4: `docs/WORK_QUEUE.md` kept non-empty before each epoch ends; `docs/figma/id-ranges.md` written before any analysis agent starts.

### Phase 2 — Source notes
- [ ] **P02-01** Every remaining input read in full (`research/*`, Claude Docs design document if reachable), each logged with line count to `docs/evidence/p02/inputs-<ISO>.log`.
- [ ] **P02-02** `docs/SOURCE_NOTES.md` rows `source path#heading | assertion (≤40 words) | scope tier | check in Phase 5` for every checkable assertion of every document.
- [ ] **P02-03** Claude Docs design artefact unreachable → `B-nnn` and proceed from local documents.

### Phase 3 — Reverse-engineer the Figma prototype
- [ ] **P03-01** One analysis subagent per page from the cache only, each owning exactly `docs/figma/analysis/<page-slug>.md` (04-T11).
- [ ] **P03-02** Every top-level frame has one `SCR-`/`FRM-`/`CMP-` block with Kind, Platform, size and variant axes; Watch-page frames Platform = Watch; Glanceables frames use a glanceable platform.
- [ ] **P03-03** Every interactive-element candidate from `scripts/figma_reconcile.py --candidates <page>` has an `INT-` block or a `NON-INTERACTIVE (<reason>)` row.
- [ ] **P03-04** Every `INT-` block has sub-headings A Sees, B Does, C Logic (all categories yes/no), D Data (fields named to the medication depth listed), E Fails (every item of the failure list considered).
- [ ] **P03-05** Navigation routes (or `route-source: inferred`), animations (`kind: animation`) and inputs (`kind: input`) enumerated per the mechanical definitions.
- [ ] **P03-06** `docs/figma/text-layers.csv` built by `scripts/extract_text.py`; `docs/figma/text-layers.NOT-EXTRACTED.md` lists metadata-only frames with reasons.
- [ ] **P03-07** `docs/figma/drug-names.md` built; `docs/figma/copy-scan.md` from `scripts/copy_scan.py` reports rows scanned = CSV lines, frames not extracted, hits with node ids and category.
- [ ] **P03-08** `scripts/validate_analysis.py <page>` passes for every page (run by subagent and by orchestrator); oversized pages split with disjoint id sub-ranges.

### Phase 4 — Figma feature inventory
- [ ] **P04-01** `docs/FIGMA_AUDIT.md` assembled by `scripts/assemble_docs.py` from per-page analyses in page order plus generated summary table, never retyped.
- [ ] **P04-02** Inventory maps screen → feature → interaction → system → data → Apple framework/backend → failure modes → tests, with Platform column and cache path on every row.
- [ ] **P04-03** Candidate features, rules, entities and tests named without ids; ids assigned only in their owning phases.

### Gate G1
- [ ] **GATE-G1-01** `docs/FIGMA_VERSION_LOCK.md` has canonical fingerprints for root and every page; `LOCK_FINGERPRINT` in PROGRESS matches.
- [ ] **GATE-G1-02** `scripts/figma_reconcile.py` reports 0 missing ids both directions for pages, frames, components, component sets, variants; interactions reconciled against `docs/figma/TOOL_COVERAGE.md`.
- [ ] **GATE-G1-03** No `[NOT YET READ]` row except `metadata-only-variant` rows naming an existing base frame.
- [ ] **GATE-G1-04** `scripts/validate_docs.py` exits 0.
- [ ] **GATE-G1-05** Ledger vs cache reconciliation clean (no untagged double reads; every `ok` row has a cache file; no non-designated reader).
- [ ] **GATE-G1-06** `docs/figma/text-layers.csv` row count > 0; NOT-EXTRACTED lists only `metadata-only-variant` frames.
- [ ] **GATE-G1-07** Every `docs/figma/analysis/<page>.md` passed `scripts/validate_analysis.py`; `docs/gates/GATE-1.md` written.

### Phase 5 — Reconcile the Figma against the documents
- [ ] **P05-01** `docs/RECONCILIATION.md` with all sections: Features in both; Changed features; Figma-only features; Document-only features (fixed disposition list + `D-`/`Q-`); Contradictions; Missing states; Design-document claims; Red-line scan summary.
- [ ] **P05-02** Missing states include every `FIGMA-GAP-nnn` plus the twelve listed undesigned states (zero medication history through Live Activity expired).
- [ ] **P05-03** Design-document claims section from `scripts/design_doc_xref.py`; unresolved claims tagged `[DESIGN-DOC-ONLY]`.
- [ ] **P05-04** `docs/CHANGELOG_FROM_ORIGINAL_SPEC.md` one row per material difference with disposition and `D-`/`Q-`, quoting original rationale where reversed.
- [ ] **P05-05** `docs/PROPOSALS.md` holds every sourceless idea as `PROP-nnn` (rationale, cost, needs).
- [ ] **P05-06** Initial `docs/PRODUCT_SPEC.md` § 4 feature list: every `FEAT-nnnn` with Source, Tier and Platform.

### Gate G2
- [ ] **GATE-G2-01** Every required RECONCILIATION section present; every Document-only feature dispositioned; every Figma-only and in-both feature has a `FEAT-` row with Source.
- [ ] **GATE-G2-02** Contradictions ≥1 row, or `NONE FOUND` with `[EV:` to the comparison log with pair list and count.
- [ ] **GATE-G2-03** Every `FIGMA-GAP-` id appears in Missing states.
- [ ] **GATE-G2-04** `docs/figma/copy-scan.md` rows scanned = rows in `text-layers.csv`; every hit has a node id.
- [ ] **GATE-G2-05** `docs/CHANGELOG_FROM_ORIGINAL_SPEC.md` ≥1 row per Changed/Figma-only/Document-only feature.
- [ ] **GATE-G2-06** `scripts/design_doc_xref.py` output attached; every `[DESIGN-DOC-ONLY]` item listed; `docs/gates/GATE-2.md` written.

### Phase 6 — Master product specification
- [ ] **P06-01** `docs/PRODUCT_SPEC.md` contains all 37 sections (product purpose through red lines with implied engine invariants).
- [ ] **P06-02** Every `FEAT-` row has Source ∈ {`FIGMA:`, `DOC:`, `ASSUMPTION-`}, Tier, Platform, Legal ref where required, and acceptance criteria each traceable and each with `TEST-` or `N/A (manual: FVC row …)`.
- [ ] **P06-03** No vague requirements: inputs, constraints, no-solution behaviour and user-visible copy (quoted from Figma) stated.
- [ ] **P06-04** Platform-derived requirements carry `[PLATFORM-nnn]` citing `IOS-` rows: Live Activity lifetime, widget freshness, notification budget, alarms (AlarmKit), Health, Calendar, Watch sync, Controls/Action button, Siri/Shortcuts, Assistive Access.
- [ ] **P06-05** § 37 red lines RL-1–RL-9 carried verbatim (byte-identical copy).

### Phase 7 — Data model
- [ ] **P07-01** `docs/DATA_MODEL.md`: every `DATA-nnnn` entity with all listed columns (fields, relationships, ownership, persistence, sensitivity, source, residency, `internalOnly` per field, source of truth, sync, validation, deletion, migration).
- [ ] **P07-02** Pharmacology-style fields and medication class `internalOnly: yes`; every 8.1.3 field `residency: device-only`; planned/predicted/observed/confirmed/inferred/recommended/external data distinguished; inferred values only with evidence counts.
- [ ] **P07-03** Decisions 1–4 recorded as `DATA-` + `D-nnn`: store technology (GRDB in App Group; SwiftData only via `/poc`), protection class per file, backup position with toggle, `GlanceState` snapshot.
- [ ] **P07-04** Decisions 5–8: delete-everything contract (exhaustive list, two-step, offline, tested), export contract (JSON + PDF, Discreet, labelled self-reported), identity and time (UUID; UTC + IANA zone + offset; clock-change detection), consent and age records.
- [ ] **P07-05** Decision 9: `docs/RESERVED_NAMES.md` seeded with at least the 26 listed names; domain-qualified names chosen; each chosen name a `FACT-` row.

### Phase 8 — Architecture
- [ ] **P08-01** `docs/ARCHITECTURE.md` with Mermaid diagram drawing process boundaries; decisions taken, rejected alternatives as `D-nnn`.
- [ ] **P08-02** Every dependency/service/backend has a "boring alternative it beat" paragraph and a `CHALLENGED: accepted|rejected` reviewer line.
- [ ] **P08-03** 8.1: every major system state classified against options O1–O7 with the decision rules (residency per entity; `HealthBoundary` sole egress with allow-list test; non-O1 needs `D-nnn`; backup never described as sync).
- [ ] **P08-04** 8.1.3 never-leave-device data list carried and bound to O3–O7 and any AI feature.
- [ ] **P08-05** 8.2 targets and packages: XcodeGen `project.yml`, four targets, five local packages, bundle ids, two App Groups, entitlements, Info.plist keys, `PrivacyInfo.xcprivacy`, signing.
- [ ] **P08-06** 8.2 language and concurrency: Swift 6 mode, strict concurrency, MainActor default isolation for UI targets, nonisolated domain/persistence, `@Observable` view models, typed routes and `planner://` deep links, injected clock/calendar with `Date()`/`Calendar.current`/`TimeZone.current` banned in `PlannerDomain`.
- [ ] **P08-07** 8.2 dependency allow-list (GRDB runtime; SwiftLint, SwiftFormat, XcodeGen dev) and rejected list; process boundaries; module boundaries, background tasks, logging (`os.Logger` `.private`), feature flags, migrations, secrets and testing boundaries documented.

### Phase 9 — Core engines and personalisation
- [ ] **P09-01** `docs/ENGINE_SPEC.md`: every `ENG-nnnn` row states inputs, outputs, constraints, invariants, algorithm, precedence, conflict resolution, fallbacks, confidence, explainability, persistence, safety boundaries and Source; engines pure and deterministic.
- [ ] **P09-02** Invariant aliases `INV-RL1`, `INV-RL2`, `INV-RL6`, `INV-RL7`, `INV-RL8` defined, each with a `TEST-`.
- [ ] **P09-03** EN-1 FocusWindowEstimator specified with the fixed method (30-min bins, 21-day half-life decay, n₀ = 6 prior, Beta 80% interval, evidence levels, disagreement rule, per-Lifestyle snapshots with `inputsHash`) and its invariants.
- [ ] **P09-04** EN-2 Scheduler specified (greedy + ≤200 local-search moves, horizon today + 6 days, 9-level precedence, `Plan` output with reasons, invariants incl. no dose creation and no "missed"/"overdue" reason).
- [ ] **P09-05** EN-3 NotificationPlanner, EN-4 CheckInScheduler, EN-5 DiscreetFormatter/CopyLint, EN-6 LifestyleSwitcher, EN-7 SupportSignpost specified as written.
- [ ] **P09-06** Date and time rules for all engines, with NSW DST fixtures verified against the NSW Government table this session and cited.
- [ ] **P09-07** `docs/PERSONALISATION_DESIGN.md`: no ML/Core ML/Foundation Models/LLM at MVP; observations, confidence, decay, Lifestyle scoping, manual correction, cold start, rollback, transparency; later AI use cases with the full listed attributes.

### Phase 10 — Engine test plan
- [ ] **P10-01** `docs/ENGINE_TEST_PLAN.md` with `TEST-nnnn` rows partitioning the namespace with `docs/TESTING_STRATEGY.md`; rule "the engine is not connected to production UI until its core suite passes" stated.
- [ ] **P10-02** Determinism tests; ≥30 golden JSON fixtures including scenario 1; fixture change requires `D-nnn`.
- [ ] **P10-03** DST and time-zone suites over every listed instant and scenario (repeated hour, missing hour, 2027-04-04, 01:30 dose, Sydney → Perth, cross-transition reminder).
- [ ] **P10-04** Red-line invariant tests, estimator behaviour tests, seeded SplitMix64 property tests, budget tests, invalid-input tests (with exit tests), performance bound (<50 ms for 100 tasks over 7 days), migration fixtures; fixture format and golden-update procedure.

### Phase 11 — Security, privacy, medical safety and Australian law
- [ ] **P11-01** One research subagent per topic T1–T22, each with primary source, URL, verified date, exact wording, classification, confidence; excerpts in `docs/evidence/sources/LEGAL-nnnn.md`; fetch blocks recorded in BLOCKERS.
- [ ] **P11-02** Every topic row T1–T22 yields ≥1 `LEGAL-nnnn`; dated research input re-verified; cloud/backend material moved to a v2+ appendix.
- [ ] **P11-03** 11.2: every `LEGAL-` row has exactly one class (LEGAL/PLATFORM/PRACTICE/DESIGN/NEEDS-LAWYER) decided in order, a confidence, and all nine columns with no empty cell.
- [ ] **P11-04** 11.3: `docs/LEGAL_PRIVACY_SAFETY.md` has all 12 sections including the SaMD tip-over checklist and privacy policy skeleton marked DRAFT.
- [ ] **P11-05** 11.4: `LEGAL-DH-01` to `LEGAL-DH-20` present and cited by Phase 8 where implemented.
- [ ] **P11-06** 11.5: `LEGAL-SAFE-01` to `LEGAL-SAFE-11` present with the given wording as the control.
- [ ] **P11-07** 11.6: `docs/COPY_REVIEW.md` covers every text layer plus every other listed surface, reports per surface, uses the `COPY-nnnn` columns and categories C1–C20; replacements obey F29 and pass `copy_scan.py --replacements`.
- [ ] **P11-08** 11.7: `Q-L1` to `Q-L18` each recorded with its conservative default adopted; the listed must-not-conclude items always NEEDS-LAWYER.
- [ ] **P11-09** 11.8 evidence: `docs/evidence/p11/sources-<ISO>.log`, `docs/evidence/p11/tga-self-assessment.md`, `docs/evidence/p11/copy-scan-<ISO>.log`, `docs/evidence/reviews/p11-review-<id>.md`.
- [ ] **P11-10** Red lines carried verbatim into `docs/COPY_REVIEW.md` and `docs/LEGAL_PRIVACY_SAFETY.md`; document never reads as legal advice.

### Phase 12 — Apple platform feasibility review
- [ ] **P12-01** `docs/APPLE_PLATFORM_PLAN.md`: one research subagent per framework; excerpts saved to `docs/evidence/sources/IOS-nnnn.md`.
- [ ] **P12-02** Every `IOS-nnnn` row has all 14 columns including Simulator support with manual device step, fallback, buildable-as-designed, `verified 2026-MM-DD` and an `[EV:` excerpt containing the claimed version or limit.
- [ ] **P12-03** One row per MVP framework in the exhaustive list (SwiftUI/Liquid Glass through `ImageRenderer`) and one "not used, why" row per out-of-MVP framework.
- [ ] **P12-04** Every known cannot-be-built-as-designed item disposed with a substitute (plus any found by the audit); Control Center Lifestyle switch decision logged.
- [ ] **P12-05** Current iOS/watchOS/Xcode/Swift versions as `FACT-` rows from Apple release pages; Personal Team capability question, `xcrun simctl ui` value names and Health-sheet automation recorded.

### Phase 13 — Implementation map, design system and fact register
- [ ] **P13-01** `docs/FIGMA_IMPLEMENTATION_MAP.md`: `UI-nnnn` rows with all listed columns (view, component, view model, engine, `DATA-` deps, animations with Reduce Motion, accessibility and Dynamic Type, route, errors, `TEST-`, backend, Platform); values from the cache only.
- [ ] **P13-02** `docs/DESIGN_SYSTEM.md`: typography, spacing, colour roles (light/dark × Calm/Spark), radii, effects, SF Symbols, motion, component states, each token citing a cached variable or node; Discreet variants; no red count token.
- [ ] **P13-03** Design system cross-checked against `docs/design/handoff.md` via `scripts/design_doc_xref.py`; differences logged; cache wins; contrast 4.5:1 / 3:1 under Reduce Transparency.
- [ ] **P13-04** `docs/FACT_REGISTER.md` complete for every mandatory key (name, bundle/App Group ids, minimum and current versions, `XCODE_MAJOR`, engine/module/target/entity names, permissions, storage, protection, backup, sync, AI choice, notification budget, minimum age, lock fingerprint, read limits, DST dates); `scripts/check_facts.py` enforces.

### Gate G3
- [ ] **GATE-G3-01** Every `FEAT-` row has Source and each acceptance criterion cites `SCR-`/`INT-`, `DOC:` or `ASSUMPTION-` and has a defined `TEST-` or allowed N/A.
- [ ] **GATE-G3-02** Every `SCR-` has ≥1 `UI-` row; every `UI-` names its `DATA-` dependencies; every `DATA-` entity has every Phase 7 column, pharmacology fields `internalOnly: yes`, 23.3-class fields `residency: device-only`.
- [ ] **GATE-G3-03** `INV-RL1`, `INV-RL2`, `INV-RL6`, `INV-RL7`, `INV-RL8` exist each with a `TEST-`.
- [ ] **GATE-G3-04** Every `IOS-` row complete with `verified 2026-` and an excerpt containing the claimed version.
- [ ] **GATE-G3-05** `scripts/check_facts.py` 0 mismatches.
- [ ] **GATE-G3-06** Every ARCHITECTURE dependency has a boring-alternative paragraph and `CHALLENGED:` line.
- [ ] **GATE-G3-07** DESIGN_SYSTEM tokens each cite a cached variable or node; differences from handoff listed.
- [ ] **GATE-G3-08** `scripts/check_names.py` 0 collisions.
- [ ] **GATE-G3-09** Every `LEGAL-` row has all 11.2 columns and its "Enforced in" id resolves; REDLINE seven-copy identity check passes; `docs/gates/GATE-3.md` written.

### Phase 14 — Testing strategy and feature verification checklist
- [ ] **P14-01** `docs/TESTING_STRATEGY.md` automation matrix with one row per required category (domain/persistence Swift Testing, XCTest/XCUITest with accessibility audit, snapshot policy without third-party library, widgets/Live Activities/Controls, Watch, notifications, permissions via fakes, migration, timezone/DST, performance, flake detection, red-line/copy, offline, battery/background, TestFlight) and all columns.
- [ ] **P14-02** Feature verification protocol Levels A–D defined with exact commands (`swift test`, `xcodebuild test … -resultBundlePath`, `xcresulttool get test-results summary`, `simctl io` with explicit UDID) and the Level D manual script list.
- [ ] **P14-03** `docs/FEATURE_VERIFICATION_CHECKLIST.md` with the full schema per `FEAT-`; VERIFIED only with a path to real output; regression suite (run twice, order domain → persistence → UI → red-line/copy → device) defined.
- [ ] **P14-04** Every `N/A (UI test: TESTING_STRATEGY, Phase 14)` placeholder in PRODUCT_SPEC resolved to a real `TEST-` id.

### Phase 15 — Git workflow
- [ ] **P15-01** `docs/GIT_WORKFLOW.md` beginner paragraphs with "what you will see" for all 15 concepts (repository through worktree).
- [ ] **P15-02** Binding workflow: protected `main`, `dev`, `ms-nn-<slug>` branches, worktrees, `<MS-nn>/<TASK-nnnn>: <what>` messages, merge commits, `ms-nn-<slug>-done` tags, ≥ every 30 minutes commit, orchestrator-only Git, secret-scan pre-commit.
- [ ] **P15-03** Recovery instructions with exact commands and success signs for all seven listed scenarios, including committed secret (rotate then remove; no shared-history rewrite without `D-nnn` + `UA-nnn`).

### Phase 16 — Implementation plan
- [ ] **P16-01** `docs/IMPLEMENTATION_PLAN.md` with each `MS-nn` stating objective, entry `UA-nnn`, files/modules, dependencies, `TASK-`/`TEST-` lists, owned `FEAT-` rows with verification level, evidence-backed completion criteria, Git tag, `BG-nn` gate, agents/tools per part.
- [ ] **P16-02** Milestone ladder MS-00 to MS-11 covered with the listed exit criteria and tags (MS-00 scaffold incl. App Groups; MS-11 `testflight-ready` without `-exportArchive`).
- [ ] **P16-03** No time estimates; dependency order only; development order principle followed.

### Phase 17 — Task database
- [ ] **P17-01** `docs/TASKS.md` every `TASK-nnnn` row with all 12 columns; size S/M/L; no time or effort estimates.
- [ ] **P17-02** Dependency graph acyclic per `scripts/check_tasks.py`.
- [ ] **P17-03** All seed tasks present (`TASK-0001` XcodeGen project; capabilities; privacy manifests; device-capabilities cleanup; BG task identifiers; Time Sensitive; `NSSupportsLiveActivities`; `WKCompanionAppBundleIdentifier`; `ITSAppUsesNonExemptEncryption`; Xcode 27 test plan; launch test; `HealthBoundary` allow-list test; `GlanceState`; `DiscreetFormatter` copy-lint; `scripts/release_check.sh`; `/poc` archive).

### Phase 18 — Requirements traceability matrix
- [ ] **P18-01** `docs/TRACEABILITY_MATRIX.md` maps `FEAT-` → `SCR-`/`INT-` → `ARCH-`/`ENG-`/`DATA-`/`IOS-`/`UI-` → `TASK-` → `TEST-` → FVC row → evidence slot with no empty cells.
- [ ] **P18-02** `scripts/trace.py` reports 0 orphan `TEST-`, 0 `FEAT-` without task, 0 task without `TEST-` or reasoned N/A, 0 `SCR-` without `UI-`.

### Phase 19 — Failure-mode analysis
- [ ] **P19-01** `docs/FAILURE_MODES.md` `RISK-nnnn` rows with risk, likelihood, impact, prevention, detection, recovery.
- [ ] **P19-02** Every listed pre-mortem item enumerated, including each App Store guideline from T15, every F1–F30 row as it would manifest, Figma change after lock, Devesh editing files, Mac sleeping, usage-limit pauses mid-fan-out.

### Phase 20 — Claude Code handbook
- [ ] **P20-01** `docs/CLAUDE_CODE_INSTRUCTIONS.md` operating mode by reference to `docs/AGENT_RULES.md` plus the build NEVER list additions.
- [ ] **P20-02** Multi-agent build protocol (planner → implementers + test author → reviewer → verifier → orchestrator), Figma lock-check before UI work, verification Levels A–D and regression suite.
- [ ] **P20-03** Canonical commands (`generate_project.sh`, `build_all.sh`, `test_all.sh`, `lint.sh`) referenced, architecture rules, source-of-truth documents, mandatory behaviour list, Definition of Done including "the engine is not connected to production UI until its core suite passes"; red lines verbatim.

### Phase 21 — CLAUDE.md
- [ ] **P21-01** Expanded `CLAUDE.md` keeps the Phase 0.0 bootstrap block verbatim at the top.
- [ ] **P21-02** Strict rules on every listed topic (architecture, XcodeGen, code style, testing, Git, dependencies, concurrency, state ownership, logging, safety, privacy, Apple APIs, design system, Figma lock, engine isolation).
- [ ] **P21-03** Red lines RL-1–RL-9 verbatim, the NEVER list, and the line "Read `docs/AGENT_RULES.md` before any work; its rules bind you." (no register copy); prohibited shortcuts listed.

### Phase 22 — Devesh's build guide and user actions
- [ ] **P22-01** `docs/DEVESH_BUILD_GUIDE.md` written for a non-developer with click-level steps and a "what you should see" line per numbered step, using the installed `XCODE_MAJOR` vocabulary (Device Hub on Xcode 27).
- [ ] **P22-02** Each development stage states what Claude Code does, what Devesh does, why, where to click, success, failure and recovery; what not to do manually.
- [ ] **P22-03** Every listed topic covered (keeping the Mac alive, first-run dialogs, usage limits and money, Figma sign-in, `FIGMA-GAP-` fixing, Xcode project, Git/GitHub, capabilities, secrets, no backend, Simulator, tests, approvals, Developer Program, pairing, permissions, widgets/Controls/complications, TestFlight and App Store Connect actions only he does, beta, release).
- [ ] **P22-04** `docs/USER_ACTIONS.md` grouped by milestone; batched manual-actions appendix; Phase 11.7 lawyer/entity/policy/trade-mark/TGA/crisis-number batch; answering-open-questions instructions.

### Phase 23 — Release checklist
- [ ] **P23-01** `docs/RELEASE_CHECKLIST.md` columns `REL-nnn | check | source | class | applies | evidence path | blocks release`; Blocks rows gate release on evidence under `docs/evidence/release/<version>-<build>/` (fixture data only).
- [ ] **P23-02** All engineering rows present (functionality through review notes attached).
- [ ] **P23-03** REL-001 to REL-034 privacy, legal and App Store rows present as written.
- [ ] **P23-04** App Review notes template included; `scripts/release_check.sh` checks specified.

### Phase 24 — Open questions
- [ ] **P24-01** `docs/OPEN_QUESTIONS.md` entries per 04-T12 in three groups (Must answer before coding; Can safely use recommended default; Can decide later), each with question, why, lettered options, recommended default, consequences, pre-filled `ANSWER:` line, status.
- [ ] **P24-02** Includes every `Q-L` item, `Q-001` (name), bundle id, pricing, Reminders scope, dark/Spark theme scope and every `[ASSUMPTION-nnn]` raised.

### Gate G4
- [ ] **GATE-G4-01** `scripts/validate_docs.py --manifest` exits 0.
- [ ] **GATE-G4-02** `scripts/check_facts.py` 0 mismatches.
- [ ] **GATE-G4-03** `scripts/check_tasks.py`: graph acyclic, all Phase 17 columns, no time estimates.
- [ ] **GATE-G4-04** `scripts/trace.py` clean; no empty cells; no `N/A (UI test: TESTING_STRATEGY, Phase 14)` left in PRODUCT_SPEC.
- [ ] **GATE-G4-05** `CLAUDE.md`, `docs/PROGRESS.md`, `docs/DEVESH_BUILD_GUIDE.md` exist, end with the marker and validate.
- [ ] **GATE-G4-06** Every numbered build-guide step has a "what you should see" line.
- [ ] **GATE-G4-07** Every verification verb has `[EV:`.
- [ ] **GATE-G4-08** Spec-drift (or manual) report attached with every prompt requirement ticked or `RESIDUAL-`.
- [ ] **GATE-G4-09** `CLAUDE.md` keeps the bootstrap block verbatim and includes red lines and the NEVER list.
- [ ] **GATE-G4-10** `scripts/check_scope.sh` passes (no `.swift`, `.xcodeproj`, `.xcworkspace`, `Package.swift` outside `/poc`).
- [ ] **GATE-G4-11** `scripts/au_spelling.py` 0 failures in UI strings.
- [ ] **GATE-G4-12** Every `REL-` Blocks row names an evidence path pattern; every 11.7 `Q-L` item is in OPEN_QUESTIONS; `docs/gates/GATE-4.md` written.

### Phase 25 — Independent completeness audit
- [ ] **P25-01** `docs/gates/G5-checklist.md` written from items 1–12 before spawning fresh reviewers who did not author the documents; `docs/COMPLETENESS_AUDIT.md` reports numbers, not adjectives.
- [ ] **P25-02** Item 1 Figma coverage: `scripts/figma_reconcile.py` zero gaps; `metadata-only-variant` count reported.
- [ ] **P25-03** Item 2 traceability via `scripts/trace.py`; item 3 reconciliation completeness (dispositions, Figma-only in spec, contradictions with `D-`/`Q-`, gaps in Missing states, `[DESIGN-DOC-ONLY]` listed).
- [ ] **P25-04** Item 4 red lines: copy scan 100% of text layers and every surface; `INV-RL1/2/6/7/8` with tests; no UI binding of `internalOnly` fields; seven red-line copies byte-identical.
- [ ] **P25-05** Item 5 consistency (`check_facts.py`, `check_names.py` 0); item 6 evidence resolution; item 7 validator and `check_scope.sh` output attached.
- [ ] **P25-06** Item 8 resume test: fresh subagent from `CLAUDE.md` answers next action = `NEXT_ACTION`, three `D-` headings, fingerprint = `LOCK_FINGERPRINT`; transcript attached.
- [ ] **P25-07** Item 9 beginner test: 0 LOST on `docs/DEVESH_BUILD_GUIDE.md` from install Xcode to run on Simulator (or account-dependent `RESIDUAL-` owned by Devesh); output attached.
- [ ] **P25-08** Item 10 drift report: this spec-drift checklist reported with every requirement ticked or `RESIDUAL-` with reason.
- [ ] **P25-09** Item 11 legal and release: LEGAL columns and enforcement ids, REL evidence patterns, `Q-L` items with defaults and assumptions, 8.1.3 fields device-only, no verified fact older than 90 days without re-verification date.
- [ ] **P25-10** Item 12 final completeness assertions, each with evidence path (tool rows, classifications, stage capabilities, every frame/candidate/route/animation/input enumerated, data sources named, features dispositioned, rules tested, denied/offline states, legal classified, platform substitutes, PROPOSALS for sourceless ideas, tools per milestone, destructive separated, `QUESTIONS_ASKED_TO_USER = 0`).
- [ ] **P25-11** FAIL loop back to owning author up to 3 times, then `RESIDUAL-nnn` (never a hard-fail class).
- [ ] **P25-12** E1: `RUN_STATUS: COMPLETE` or `COMPLETE_WITH_RESIDUALS`, tag `planning-complete`, push, `docs/WHAT_I_DO_NEXT.md` (first 5–10 plain-English actions) printed verbatim as the final message.

### Gate G5
- [ ] **GATE-G5-01** `docs/COMPLETENESS_AUDIT.md` items 1–12 each PASS, or each FAIL a `RESIDUAL-nnn` with reason, file#section and owner; no residual in a hard-fail class.
- [ ] **GATE-G5-02** `docs/gates/GATE-5.md` written with the contract re-read line and usage line.

### Final deliverable tree (named paths)
- [ ] **DLV-01** `prompts/`: `01_MASTER_PLANNING_PROMPT.md`, `02_BUILD_KICKOFF_PROMPT.md`, `03_RESUME_PROMPT.md`, `04_AGENT_BRIEFS_AND_TEMPLATES.md`, `05_SETTINGS_AND_HOOKS.md`, `06_SCRIPT_SPECS.md`, `00_README_DEVESH.md`, `figma_urls.md`, `figma_design_prompt.md` present.
- [ ] **DLV-02** State and bookkeeping: `docs/PROGRESS.md`, `docs/DECISION_LOG.md`, `docs/BLOCKERS.md`, `docs/USER_ACTIONS.md`, `docs/OPEN_QUESTIONS.md`, `docs/AGENT_RULES.md`, `docs/MANIFEST.md`, `docs/WORK_QUEUE.md`, `docs/FACT_REGISTER.md`, `docs/RESERVED_NAMES.md`, `docs/PROPOSALS.md`, `docs/POC_REGISTER.md`, `docs/FIRST_REPORT.md`, `docs/WHAT_I_DO_NEXT.md`.
- [ ] **DLV-03** Phase outputs (part 1): `docs/PREFLIGHT.md`, `docs/SOURCE_INVENTORY.md`, `docs/SOURCE_NOTES.md`, `docs/TOOL_CAPABILITY_AUDIT.md`, `docs/TOOL_STRATEGY.md`, `docs/FIGMA_VERSION_LOCK.md`, `docs/FIGMA_AUDIT.md`, `docs/RECONCILIATION.md`, `docs/CHANGELOG_FROM_ORIGINAL_SPEC.md`, `docs/PRODUCT_SPEC.md`, `docs/DATA_MODEL.md`, `docs/ARCHITECTURE.md`, `docs/ENGINE_SPEC.md`, `docs/PERSONALISATION_DESIGN.md`, `docs/ENGINE_TEST_PLAN.md`.
- [ ] **DLV-04** Phase outputs (part 2): `docs/LEGAL_PRIVACY_SAFETY.md`, `docs/COPY_REVIEW.md`, `docs/APPLE_PLATFORM_PLAN.md`, `docs/FIGMA_IMPLEMENTATION_MAP.md`, `docs/DESIGN_SYSTEM.md`, `docs/TESTING_STRATEGY.md`, `docs/FEATURE_VERIFICATION_CHECKLIST.md`, `docs/GIT_WORKFLOW.md`, `docs/IMPLEMENTATION_PLAN.md`, `docs/TASKS.md`, `docs/TRACEABILITY_MATRIX.md`, `docs/FAILURE_MODES.md`, `docs/CLAUDE_CODE_INSTRUCTIONS.md`, `docs/DEVESH_BUILD_GUIDE.md`, `docs/RELEASE_CHECKLIST.md`, `docs/COMPLETENESS_AUDIT.md`, `CLAUDE.md`.
- [ ] **DLV-05** Figma: `docs/figma/FIGMA_STATE_REPORT.md`, `TOOL_COVERAGE.md`, `read-plan.md`, `read-ledger.md`, `id-ranges.md`, `text-layers.csv`, `text-layers.NOT-EXTRACTED.md`, `copy-scan.md`, `drug-names.md`, `variables-observed.md`, `.intent`, `raw/<fileKey>/<tool>/<nodeId>.*`, `raw/<fileKey>/<page-slug>/nodes.json`, `analysis/<page-slug>.md` for every page.
- [ ] **DLV-06** Gates and evidence: `docs/gates/GATE-0.md` to `GATE-5.md`, `docs/gates/G5-checklist.md`; `docs/evidence/p00` to `p25`, `docs/evidence/sources/<id>.md`, `docs/evidence/checkpoints/`, `docs/evidence/reviews/`; `docs/agents/<agent-id>/`; `docs/parts/<DOC>/`.
- [ ] **DLV-07** Scripts: every script in `scripts/` listed in the tree and every hook in `scripts/hooks/` (`session_start.sh`, `pre_compact.sh`, `stop_guard.sh`, `stop_failure.sh`, `guard_bash.sh`, `guard_write.sh`, `decline_elicitation.sh`, `figma_pre.sh`, `figma_post.sh`, `figma_fail.sh`, `subagent_stop.sh`, `progress_nag.sh`).
- [ ] **DLV-08** `.claude/settings.json` (deny rules and hooks only, never `defaultMode`); `/poc/<name>/README.md` only if a PoC was needed; `/logs` git-ignored; any deviation from the tree is a `D-nnn`.

## Open questions (max 3)
- Q1: OPEN: The prompt's 0.16 item 5 says to preserve the design session's root `SPEC_CHECKLIST.md` first, but no such file exists at init time. → Default adopted: record its absence (no archive or index needed; single-task project) and create a fresh checklist.
- Q2: OPEN: G3 item 2 refers to "every 23.3-class field" while the never-leave-device list is section 8.1.3. → Default adopted: treat "23.3-class" as the 8.1.3 list (consistent with Phase 25 item 11).

## Current implementation status
Not yet assessed. All items above are unchecked at creation; `/spec-drift:check` (mid-run estimate) and `/spec-drift:report` (authoritative, at G4 and Phase 25) write this section.
