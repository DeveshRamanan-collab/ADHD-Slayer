# P00-scripts-gate — notes (Phase 0.16 item 2: scripts/gate.py, scripts/run_planning.sh)
Agent: P00-scripts-gate · Written: 2026-10-01T14:28:00+1000 · Specs: prompts/06_SCRIPT_SPECS.md (gate.py, run_planning.sh), docs/AGENT_RULES.md OM-4, prompts/04 04-T3, prompts/05 (hook list, optional runner).

## Outputs
- `scripts/gate.py` — Python 3 standard library only; `--help`; exit 0 all PASS, 1 any FAIL, 2 usage error; last line `# <!-- END OF FILE -->`.
- `scripts/run_planning.sh` — proven with `bash -n` and `--help` only; never launched; last line `# <!-- END OF FILE -->`.
- Fixture: `docs/evidence/p00/fixtures/P00-scripts-gate/redline/` (AGENT_RULES reference table, identical PRODUCT_SPEC, ENGINE_SPEC with RL-4 "daily streaks" changed to "weekly streaks", MANIFEST giving each file its gate).

## Command line
`python3 scripts/gate.py G<n> [--loop n] [--root DIR] [--items 1,3,C,REDLINE] [--file-key KEY] [--regenerate]`.
Output: a header line, the 04-T3 Checklist table (`| # | Check | Method | Result | Evidence |`), then `## Failures` with one `file:line:RULE: [item n] message` line per failure (suffix `[HARD-FAIL]` for an OM-4 hard-fail class), then a summary line. Result cell is `PASS`, `FAIL` or `FAIL (HARD-FAIL class)`. The Evidence cell lists the inputs and counts examined; the reviewer adds the run_logged log path. An item that raises an exception reports `scripts/gate.py:0:GATEERR` instead of crashing the gate. A missing sibling script reports `scripts/<name>:0:SCRIPT: script missing`.
Hard-fail flag: rules END, PHRASE, SRC, NOTYETREAD, NOSOURCE, HARDFAIL, and MISSING only when the path is a `docs/MANIFEST.md` deliverable.

## What each item checks and how
Every gate also runs item **C** (PROGRESS header: the 13 OM-5 keys present; `QUESTIONS_ASKED_TO_USER` and `TURNS_ENDED_WAITING` equal 0; `RUN_STATUS` a defined value; `UPDATED` with seconds and offset; `FIGMA_EPOCH_READS` `n/cap`; from G1 `LOCK_FINGERPRINT` holds a hex fingerprint). G3, G4 and G5 also run **REDLINE**.

| Gate.item | Check | Method |
|---|---|---|
| G0.1 | PREFLIGHT statuses and evidence | Every table needs a Status column; each row's status is OK, MISSING or UNVERIFIABLE; each row carries `[EV: docs/evidence/...]` and the path exists; a line starting `RUN-SURVIVAL:` exists |
| G0.2 | Audit counts and harmless calls | `### ` entries under `## Tier A` plus table rows under `## Tier B` must equal the unique `ITEM ...` keys in `docs/evidence/p00/discovery-*.log`; every PRIMARY, SECONDARY or REVIEW entry's Evidence line needs an existing `[EV:` that is not a discovery log |
| G0.3 | Strategy coverage | For each of the 16 Phase 0.4 stages a TOOL_STRATEGY table row whose first cell is the stage and that has a non-empty capability cell; a heading containing "multi-agent"; every MANIFEST path (first cell starting `docs/`, `CLAUDE.md` or `scripts/`) is a first cell of the ownership-map section (a `<...>` segment in the map matches one path segment) |
| G0.4 | Hook tests | Hook names = `scripts/hooks/<name>.sh` mentioned in prompts/05 (minus `_lib`); each script exists; the newest `hooks-*.log` (by its timestamp) that has a `[PASS]`/`[FAIL] <name>` line must have at least one PASS and no FAIL for it and a run_logged header and footer |
| G0.5 | Validator | `scripts/validate_docs.py --manifest`; its `file:line:RULE` lines are passed through |
| G0.6 | Git state | Read-only `git log --format=%h %s` must contain a subject starting `Phase 0` (followed by `:`, space or end); `git status --porcelain` must be empty (first 40 paths listed) |
| G0.7 | MISSING rows have B- | A B-nnn on the row must be a `## B-nnn` heading in BLOCKERS; a row without one is covered only if a BLOCKERS entry contains a UA-nnn, backticked token (4+ characters) or `docs/`/`research/`/`prompts/`/`scripts/` path from the row |
| G0.8 | Source inventory | Expected list = backticked `.md`/`.pdf` paths in prompts/01 § K.2 plus `prompts/0[1-6]_*.md`; each needs a row in a table with a Status column; `present` rows need a SHA-256 prefix equal to the file's current SHA-256; `missing` rows need the file absent, or created after the inventory's `Generated:` time (reported as a note) |
| G1.1 | Lock fingerprints | A 64-hex value on a lock line naming root; every `docs/figma/raw/<key>/*/nodes.json` `fingerprint` appears in the lock; PROGRESS `LOCK_FINGERPRINT` matches the root |
| G1.2 | Reconcile | `figma_reconcile.py <key> --strict` (key = the raw folder holding most nodes.json, or `--file-key`) |
| G1.3 | NOT YET READ rule | In FIGMA_AUDIT and `docs/figma/analysis/*.md`: a `[NOT YET READ]` line without `metadata-only-variant` is NOTYETREAD; with it, the line must name an SCR-/FRM-/CMP- id other than its own that is defined in those files |
| G1.4 | Validator | `validate_docs.py --manifest` |
| G1.5 | Ledger vs cache | Ledger rows (FIXTUREKEY rows skipped): `ok` rows need the cache file; a second ok/truncated/pending read of the same tool, key and node needs intent lock-check, retry or delta-audit; the agent must be the designated reader parsed from TOOL_STRATEGY (orchestrator) |
| G1.6 | Text layers | `extract_text.py` must exist (run first only with `--regenerate`); `text-layers.csv` has data rows; every NOT-EXTRACTED line with a node id says `metadata-only-variant` |
| G1.7 | Page analyses | `validate_analysis.py <slug>` for every `docs/figma/analysis/<slug>.md`; none present fails |
| G2.1 | Reconciliation sections | The eight Phase 5 section headings; Document-only rows carry a fixed-list disposition and a D-/Q- id; Figma-only and in-both rows cite a FEAT- defined in PRODUCT_SPEC whose row has a Source |
| G2.2 | Contradictions | At least one row; a NONE FOUND row needs an existing `[EV:` |
| G2.3 | Missing states | Every FIGMA-GAP- id in `docs/figma/*.md` appears in the Missing states section |
| G2.4 | Copy scan | `copy_scan.py` must exist (run first only with `--regenerate`); `rows scanned` count equals text-layers.csv data rows; every row of a table with a Category column has a node id |
| G2.5 | Changelog | Each Changed/Figma-only/Document-only row's FEAT- id (else first cell) occurs in CHANGELOG_FROM_ORIGINAL_SPEC |
| G2.6 | Design-doc xref | `design_doc_xref.py` exits 0; every row of its output tables marked no/not found/unfound/false/missing is named on a `[DESIGN-DOC-ONLY]` line of the Design-document claims section |
| G3.1 | FEAT rows | Source in `FIGMA:n:n`, `DOC:path#heading` or `ASSUMPTION-nnn` form (NOSOURCE, hard); criteria from an Acceptance column (split on `<br>`, `;`) or lines naming the FEAT in an "Acceptance criteria" section; each cites SCR-/INT-, DOC: or ASSUMPTION- and has a TEST- defined in ENGINE_TEST_PLAN or one of the two N/A forms |
| G3.2 | UI, DATA | Each SCR- defined in FIGMA_AUDIT is named (by id or node id) in a UI- row; each UI- row has a DATA- id or `N/A (` in its DATA column; each DATA- entity (table row or heading block) has the 14 Phase 7 attributes non-empty; field lines with pharmacology terms need `internalOnly: yes`; a residency other than device-only on a line naming an 8.1.3 category fails |
| G3.3 | Red-line invariants | INV-RL1/2/6/7/8 defined (heading, bold or first cell) in ENGINE_SPEC; each on a line with a TEST- id in ENGINE_TEST_PLAN or ENGINE_SPEC |
| G3.4 | IOS rows | Framework, Permission, Minimum iOS, watchOS (N/A (iPhone-only) accepted), Simulator, Fallback columns non-empty; `verified 2026-MM-DD`; `[EV: docs/evidence/sources/<id>.md]` exists and its Excerpt contains the minimum-iOS number unless the row says `[UNVERIFIED]` |
| G3.5 | Facts | `check_facts.py` |
| G3.6 | Dependencies | Each entry (subheading, else table row) of the Dependencies section has "boring alternative" and `CHALLENGED: accepted` or `rejected` |
| G3.7 | Design tokens | Each row of a table with a Token column cites a node id or `docs/figma/raw/`; a heading naming handoff exists |
| G3.8 | Names | `check_names.py` |
| G3.9 | LEGAL rows | ID, Item, Class, Confidence, Source, Verified, Applies, Enforced, Test columns non-empty; Class in the 11.2 scheme; Confidence High/Medium/Low; verified date; every id in Enforced in is defined in some deliverable |
| G4.1 / G4.7 | Validator | `--manifest`; item 7 reports only EV and EVLOG lines |
| G4.2 / G4.3 / G4.10 | Scripts | `check_facts.py`, `check_tasks.py`, `check_scope.sh` |
| G4.4 | Trace | `trace.py`; no `N/A (UI test: TESTING_STRATEGY, Phase 14)` left in PRODUCT_SPEC |
| G4.5 | Core files | CLAUDE.md, PROGRESS.md, DEVESH_BUILD_GUIDE.md exist, end marker in the last 400 characters, `validate_docs.py` on the three |
| G4.6 | Guide steps | Every numbered list item block (to the next item or heading) contains "what you should see" |
| G4.8 | Drift | Every `- [ ]` item in SPEC_CHECKLIST.md is ticked or names a RESIDUAL-; a `docs/evidence/**/*drift*report*` file exists |
| G4.9 | CLAUDE.md | Starts with the CLAUDE.md of the Phase 0 commit (read-only `git show`; falls back to the oldest commit of CLAUDE.md), end marker removed; RL-1..RL-9 present; a heading containing NEVER |
| G4.11 | Spelling | `au_spelling.py` over existing manifest documents (non-strict); `--strict` over `poc/**/*.xcstrings`/`*.strings` when present |
| G4.12 | Release, Q-L | REL- rows with a Blocks cell starting "yes" name `docs/evidence/release/` in the evidence cell; every Q-L id in prompts/01 § 11.7 appears in OPEN_QUESTIONS |
| G5.1 | Completeness audit | Items 1–12 found (table rows with a Result column, or `## n` headings with a `Result:` line); a FAIL needs a RESIDUAL- with a row in COMPLETENESS_AUDIT or `docs/gates/GATE-5.md`: no empty cell, owner build-phase or Devesh, a `file.md#section`, and no hard-fail wording (HARDFAIL) |
| REDLINE | Red-line identity | For each of the seven K.4 documents present and due by this gate (due = highest gate in its MANIFEST "Validated at gate" cell; AGENT_RULES G0, CLAUDE.md and CLAUDE_CODE_INSTRUCTIONS G4, the rest G3): lines from the first starting `\| RL-1` to the first starting `\| RL-9`; SHA-256; a document whose hash differs from docs/AGENT_RULES.md gets `file:<first differing line>:REDLINE`; a due document without the table fails |

## Real G0 result observed (second run, [EV: docs/evidence/p00/gate-G0-dryrun-P00-scripts-gate-20261001T142714.log])
| Item | Result | Cause |
|---|---|---|
| 1 | PASS | 68 rows, all statuses valid, all evidence paths exist, RUN-SURVIVAL present |
| 2 | FAIL | Counts match (Tier A 60 + Tier B 100 = 160 discovery items); `Explore` and `claude-code-guide` (SECONDARY) and `Plan` (REVIEW) cite only the discovery log (docs/TOOL_CAPABILITY_AUDIT.md:56, :66, :156) |
| 3 | FAIL | 15 of 16 Phase 0.4 stages have no row in docs/TOOL_STRATEGY.md (the stage table is docs/TOOL_CAPABILITY_AUDIT.md:715–730; only "Drift detection" matches a TOOL_STRATEGY row); multi-agent plan and ownership map (all 61 MANIFEST paths) pass |
| 4 | FAIL | `figma_post.sh` has no test line in any hooks log (its real-read evidence is ledger row 1 and the cache file, not a hooks log); the other 11 hooks pass in hooks-orchestrator-20261001T140728.log |
| 5 | FAIL (HARD-FAIL class) | validate_docs: EV at docs/PROGRESS.md and docs/DECISION_LOG.md:127, :146, :148; PHRASE (ellipsis character) at docs/DECISION_LOG.md:156 — a truncation marker is a hard-fail class |
| 6 | FAIL | No commit subject starts "Phase 0" (only checkpoint commits); `git status --porcelain` lists 66 entries (parallel agents' evidence and outputs, this agent's files) |
| 7 | FAIL | Seven MISSING rows without a B-nnn: docs/PREFLIGHT.md:46 (REST route), :70 (physical devices), :82 (xcodegen/swiftlint/swiftformat), :96 (browser tools), :103 (GitHub MCP), :104 (ansight), :112 (iPhone and Watch pairing; UA-003 is not referenced in BLOCKERS) |
| 8 | PASS | 22 expected inputs; SHA-256 prefixes match; SPEC_CHECKLIST.md is listed missing and was created after the inventory (note, not a failure) |
| C | PASS | Header complete; counters 0 |

## Other proofs
- `--help`: [EV: docs/evidence/p00/gate-help-P00-scripts-gate-20261001T142710.log]
- REDLINE fixture catches the RL-4 change at docs/ENGINE_SPEC.md:10 and passes the identical PRODUCT_SPEC: [EV: docs/evidence/p00/gate-G3-redline-fixture-P00-scripts-gate-20261001T142710.log] (exit 1)
- `bash -n scripts/run_planning.sh`: [EV: docs/evidence/p00/run-planning-syntax-P00-scripts-gate-20261001T142710.log]; `--help`: [EV: docs/evidence/p00/run-planning-help-P00-scripts-gate-20261001T142710.log]
- The first G0 run (docs/evidence/p00/gate-G0-dryrun-P00-scripts-gate-20261001T142710.log) gave the same item results.
- G1–G5 were also run on the real repository without evidence logs to confirm no item raises; every item reports PASS/FAIL (all documents for those gates are not written yet).

## run_planning.sh behaviour
Loop of at most 96 launches of `claude --dangerously-skip-permissions --continue -p "Read prompts/03_RESUME_PROMPT.md and follow Variant B."`, output appended to `logs/run-<YYYY-MM-DD>.log`. After each exit it reads RUN_STATUS: terminal (COMPLETE, COMPLETE_WITH_RESIDUALS, HALTED_USER_ACTION_REQUIRED, HALTED_HARD_FAIL) exits 0; WAITING_FOR_FIGMA_RESET sleeps until RETRY_AFTER (parsed by python3; 15 minutes if unparsable or past); STALLED relaunches once, then exits 3; anything else sleeps 15 minutes. Exit 127 if `claude` is not on PATH; exit 4 at the launch limit. `--help` exits before any side effect.

## Decisions taken (OPEN items, default adopted)
- OPEN: G0.3 — accept the 0.4 stage table only inside docs/TOOL_STRATEGY.md (OM-4 wording) or also in docs/TOOL_CAPABILITY_AUDIT.md § 0.4? → strict: TOOL_STRATEGY.md only; the failure line points at the audit row.
- OPEN: G0.4 — figma_post.sh evidence from the real ledger row instead of a hooks log? → strict: a hooks-*.log line is required.
- OPEN: G0.6 — what counts as "the Phase 0 commit"? → a subject starting `Phase 0` (0.16 item 6 message "Phase 0: bootstrap, preflight, tool audit, enforcement tooling").
- OPEN: G1.6 and G2.4 — should the gate regenerate text-layers/copy-scan? → no by default (the gate never modifies the tree); `--regenerate` runs the script first; the script must exist either way.
- OPEN: REDLINE scope — CLAUDE.md is present from Phase 0 with one-line red lines → compare a document only from the highest gate in its MANIFEST "Validated at gate" cell (CLAUDE.md and CLAUDE_CODE_INSTRUCTIONS from G4).
- OPEN: G3.2 "23.3-class field" → read as the Phase 8.1.3 list; checked as "no non-device residency on a line naming an 8.1.3 category".
- OPEN: G4.11 — which files are "UI strings" in the planning phase → documents non-strict; `/poc` string catalogues `--strict`.

## Proposed changes outside ownership (for the orchestrator)
1. docs/TOOL_STRATEGY.md: add the 16-row 0.4 stage table (or rows naming the capability per stage) — clears G0.3.
2. docs/TOOL_CAPABILITY_AUDIT.md: harmless-call evidence for `Explore`, `claude-code-guide` and `Plan`, or reclassify them OPTIONAL — clears G0.2.
3. scripts/test_hooks.sh: add a figma_post.sh dry run (fixture JSON, `LEDGER_OVERRIDE`, a `.claude/hookstate/figma_last` pointing at a fixture row) and re-run into a new hooks log — clears G0.4.
4. docs/DECISION_LOG.md:156 replace the ellipsis character; add `[EV:` to docs/DECISION_LOG.md:127, :146, :148 and the PROGRESS log line — clears G0.5.
5. docs/BLOCKERS.md: B-nnn entries (or B- ids on the rows) for the seven MISSING PREFLIGHT rows — clears G0.7.
6. Commit "Phase 0: bootstrap, preflight, tool audit, enforcement tooling" with a clean tree before re-running G0 — clears G0.6.
7. scripts/hooks/guard_bash.sh: prompts/06 says guard_bash blocks run_planning.sh, but its pattern only matches a `claude ... --dangerously-skip-permissions` command line, not `bash scripts/run_planning.sh`; consider adding `run_planning\.sh([[:space:]]*$|[[:space:]]+[^-])` so the runner itself is blocked while `--help` still passes.

<!-- END OF FILE -->
