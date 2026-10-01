# DECISION LOG — append-only (insert new entries immediately above the end marker; supersede, never edit)

## D-001 — Fix bash 3.2 syntax in scripts/hooks/subagent_stop.sh
Date: 2026-10-01T13:49:35+1000 · Phase/MS: 0.0 · Decided by: orchestrator · Status: ADOPTED
Context: The reference implementation in prompts/05_SETTINGS_AND_HOOKS.md uses `case "$f" in *.PARTIAL.md) …` inside a command substitution; macOS /bin/bash 3.2 fails to parse it (first hook test run, docs/evidence/p00/hooks-orchestrator-20261001T134848.log).
Decision: Use the POSIX leading-parenthesis pattern form `(*.PARTIAL.md)`; behaviour is otherwise identical.
Alternatives rejected: (1) Keep verbatim — the hook would always exit 2 on syntax error and block every subagent. (2) Rewrite the hook — unnecessary for a one-character fix.
Consequences: scripts/hooks/subagent_stop.sh differs from 05 by one character; re-test passed [EV: docs/evidence/p00/hooks-orchestrator-20261001T134902.log].
Reversible: YES (revert the character)
Related: none
Evidence: docs/evidence/p00/hooks-orchestrator-20261001T134902.log

## D-002 — Hook documentation differences adopted from code.claude.com (fetched 2026-10-01)
Date: 2026-10-01T13:49:35+1000 · Phase/MS: 0.0c · Decided by: orchestrator · Status: ADOPTED
Context: https://code.claude.com/docs/en/hooks (docs/evidence/sources/FACT-hooks-events.md, FACT-hooks-exit2.md, FACT-hooks-filewatch.md) confirms every event used by 05 exists, the field names tool_name/tool_input/tool_response/stop_hook_active, PostToolUseFailure field `error`, exit-2 blocking semantics and regex matchers on tool_name; settings edits are picked up mid-session by the file watcher. Differences: StopFailure `error` is an object {type, message} (stop_failure.sh logs its JSON form, which is acceptable); subagents are identified by the JSON field `agent_id`, not an environment variable `CLAUDE_AGENT_ID` (hooks fall back to "orchestrator"; subagent evidence names use the agent id given in each brief).
Decision: Keep the 05 hooks unchanged apart from D-001; record the two differences here.
Alternatives rejected: (1) Rewrite stop_failure.sh to extract error.message — the JSON form is more complete. (2) Parse agent_id in figma_pre.sh — only the orchestrator reads Figma (C-9), so the label is always correct.
Consequences: Ledger rows label every read "orchestrator"; a read by a subagent is detected by its transcript, not the ledger label.
Reversible: YES
Related: none
Evidence: docs/evidence/sources/FACT-hooks-events.md

## D-003 — Existing prototype code under app/ is an immutable pre-existing input, excluded from check_scope.sh
Date: 2026-10-01T13:49:35+1000 · Phase/MS: 0.0 · Decided by: orchestrator · Status: ADOPTED
Context: prompts/SOURCE_MAP.md records app/FocusApp (SwiftUI prototype) and app/FocusCore (Swift package, 31 tests) committed before this run. The 06 reference check_scope.sh fails on any .swift file outside /poc, which would fail G4 on code this run did not write and must not delete (C-3, OM-1 "never discard existing work").
Decision: check_scope.sh additionally excludes ./app/* and treats it as a read-only prototype input; no file under app/ is modified by this run. The build phase decides its fate in MS-00 (archive or reuse), recorded as a task.
Alternatives rejected: (1) Move app/ into /poc — modifies existing work and its git paths. (2) Delete it — forbidden. (3) Accept a permanent G4 FAIL — hides real violations.
Consequences: scripts/check_scope.sh differs from 06 by one exclusion; Phase 17 adds a task for the prototype's disposition; Phase 2 reads it as a source.
Reversible: YES
Related: none
Evidence: none

## D-004 — Fix background mode of scripts/run_logged.sh (log path not handed to the child shell)
Date: 2026-10-01T13:54:12+1000 · Phase/MS: 0.1 · Decided by: orchestrator · Status: ADOPTED
Context: The 06 reference implementation's `--background` branch runs `bash -c "$(declare -f run); run …"`; the function appends to `$out`, which is not defined in the child shell, so background logs received no output and no footer (docs/evidence/p00/preflight-*-20261001T135025.ABORTED-bg-bug.txt).
Decision: Prefix the child script with `out=<quoted path>;`. Foreground behaviour is unchanged. The three aborted logs were renamed with the suffix .ABORTED-bg-bug.txt (kept, not deleted) and the probes re-run.
Alternatives rejected: (1) Export `out` — also works but leaks into the caller's environment. (2) Avoid background mode — 06 requires it for commands over 2 minutes.
Consequences: scripts/run_logged.sh differs from 06 in one line; background logs now carry header, output and footer (docs/evidence/p00/preflight-sims-orchestrator-20261001T135104.log).
Reversible: YES
Related: none
Evidence: docs/evidence/p00/preflight-sims-orchestrator-20261001T135104.log

## D-005 — Design-session substitutes replace the missing docs/design/* inputs
Date: 2026-10-01T14:07:03+1000 · Phase/MS: 0.1 · Decided by: orchestrator · Status: ADOPTED
Context: B-001 (docs/design/ and SPEC_CHECKLIST.md absent). prompts/SOURCE_MAP.md § "Design-session documents" names what the design sessions wrote instead: docs/build-spec/01–11 with _context.md and _resume.md, docs/copy/, docs/system-design.md, docs/api-design.md, docs/design-critique.md, design/figma/README.md, docs/research-notes/, and research/ADHD planner product design and research.pdf.
Decision: Every instruction naming docs/design/handoff.md, figma-usage.md, decisions.md or DESIGN_SPEC.md reads the substitutes; [DESIGN-DOC-ONLY: <path>#<heading>] tags cite docs/build-spec/* paths; scripts/design_doc_xref.py reads docs/build-spec/*.md and design/figma/README.md. The substitutes are immutable inputs like docs/design/ (K.3); scripts/hooks/guard_write.sh is extended in D-010 to protect them.
Alternatives rejected: (1) Treat the run as missing its design inputs — loses the newest product decisions (30 Sep). (2) Re-create docs/design/* from the substitutes — invents documents (F7).
Consequences: Phases 1, 2, 5 and 13 cite the substitutes; G2 item 6 attaches design_doc_xref.py output over the substitutes.
Reversible: YES
Related: B-001
Evidence: docs/evidence/p00/source-inventory-orchestrator-20261001T135339.log

## D-006 — Build-phase SDLC spine is superpowers; fan-outs use the Agent tool; the Workflow tool is not used
Date: 2026-10-01T14:07:03+1000 · Phase/MS: 0.6 · Decided by: orchestrator · Status: ADOPTED
Context: Overlapping workflow plugins are installed (docs/TOOL_CAPABILITY_AUDIT.md § 0.6): superpowers, agentic-sdlc, agent-protocols, agent-handoff, wai-suite. The master prompt prescribes its own documents (PRODUCT_SPEC, TASKS, IMPLEMENTATION_PLAN) and a milestone protocol planner → implementers in worktrees → independent reviewer → verifier.
Decision: superpowers (subagent-driven-development, using-git-worktrees, test-driven-development, verification-before-completion, systematic-debugging) is the build-phase spine because it adds discipline without a parallel document set. agent-protocols, review-council, pr-review-toolkit, backend-design and agentic-council supply reviewer agents only. The Workflow tool requires the user's explicit opt-in in the user's own words, which the run prompt does not contain, so fan-outs use ordinary Agent-tool subagents.
Alternatives rejected: (1) agentic-sdlc as spine — writes FR/NFR/US/ADR files that duplicate PRODUCT_SPEC and TASKS (F6). (2) agent-handoff — a second plan file set. (3) Workflow scripts — not opted into.
Consequences: docs/TOOL_STRATEGY.md, docs/IMPLEMENTATION_PLAN.md and docs/CLAUDE_CODE_INSTRUCTIONS.md name superpowers skills per milestone step.
Reversible: YES (switch spine at a milestone boundary with a new D- entry)
Related: none
Evidence: docs/evidence/p00/tierA-probe-orchestrator-20261001T135754.log

## D-007 — Working name "Focus", existing repository ADHD-Slayer, bundle prefix au.adhdslayer.focus
Date: 2026-10-01T14:07:03+1000 · Phase/MS: 0.16 · Decided by: orchestrator · Status: ADOPTED
Context: OM-1.7 defaults are repository planner-app, bundle au.<login>.planner and name "Planner". prompts/SOURCE_MAP.md and docs/build-spec/_context.md (Decisions already made) record the newer working name "Focus", the existing private remote https://github.com/DeveshRamanan-collab/ADHD-Slayer (docs/evidence/p00/preflight-git-orchestrator-20261001T135000.log) and StoreKit product ids au.adhdslayer.focus.plus.monthly and .yearly. K.3: the Figma and the design sessions are newer than the brief.
Decision: Keep the existing repository and remote (never create a second); working name "Focus" (Q-001 keeps the name question open with "Focus" as default); bundle id prefix au.adhdslayer.focus (app au.adhdslayer.focus, extensions au.adhdslayer.focus.<target>).
Alternatives rejected: (1) Create planner-app — splits history across two repositories. (2) au.deveshramanan-collab.planner — contradicts the product ids already written in docs/build-spec and app/FocusApp/Products.storekit.
Consequences: FACT register entries for product name, bundle prefix and repository; every document uses "Focus".
Reversible: YES (bundle ids are fixed only once an App Store Connect record exists)
Related: Q-001
Evidence: docs/evidence/p00/preflight-git-orchestrator-20261001T135000.log

## D-008 — Figma-format scripts are written after the first page metadata is cached
Date: 2026-10-01T14:07:03+1000 · Phase/MS: 0.16 · Decided by: orchestrator · Status: ADOPTED
Context: figma_fingerprint.py, figma_reconcile.py, figma_read_plan.py, extract_text.py and validate_analysis.py parse cached Figma responses. Only the root page list (docs/figma/raw/gLuoHFbiiUGajAUpluWXOW/get_metadata/root.txt) exists; the XML node format and the design-context format are not yet observed. Writing parsers before seeing the format would guess (F1).
Decision: Generic scripts are written in Phase 0.16 (subagent brief P00-scripts-generic); the five Figma-format scripts are written in Phase 1.2 immediately after the first page get_metadata response is cached, and each is proven on that real cache before any analysis agent starts.
Alternatives rejected: (1) Write them now against an assumed format — F1 risk. (2) Spend a Figma read in Phase 0 — 0.7 forbids reads beyond the root.
Consequences: G0 covers the generic scripts; G1 item 7 and G1 item 2 depend on the Phase 1.2 scripts.
Reversible: YES
Related: none
Evidence: docs/evidence/p00/figma-tools/get_metadata-root-orchestrator-20261001T135045.md

## D-009 — Figma read epoch accounting includes two pre-run setup reads only as margin
Date: 2026-10-01T14:07:03+1000 · Phase/MS: 0.1 · Decided by: orchestrator · Status: ADOPTED
Context: prompts/SOURCE_MAP.md records two Figma reads on 1 Oct during setup (root page list and 114:2) that are not in the ledger. The Education limit is 200 per day and 10 per minute, verified 2026-10-01 [EV: docs/evidence/sources/FACT-figma-rate-limits.md]; the run cap is 150 per rolling 24 h.
Decision: Keep the 150 cap; the 50-call margin under the 200 limit absorbs the two setup reads. The 114:2 setup read's output was not saved, so 114:2 is read again as a normal planned read.
Alternatives rejected: (1) Lower the cap to 148 — no practical gain. (2) Treat 114:2 as cached — nothing is on disk.
Consequences: read-plan totals use cap 150.
Reversible: YES
Related: none
Evidence: docs/evidence/sources/FACT-figma-rate-limits.md

## D-010 — guard_write.sh also protects the design-session substitutes, SOURCE_MAP, figma_urls and the app/ prototype
Date: 2026-10-01T14:07:19+1000 · Phase/MS: 0.0c · Decided by: orchestrator · Status: ADOPTED
Context: D-005 makes docs/build-spec/, docs/copy/, docs/research-notes/, docs/system-design.md, docs/api-design.md, docs/design-critique.md and design/ immutable inputs in place of docs/design/; D-003 makes app/ a read-only prototype; prompts/SOURCE_MAP.md and prompts/figma_urls.md are Devesh-supplied inputs.
Decision: Add those paths to the immutable-input case of scripts/hooks/guard_write.sh (Write/Edit tools). Shell writes are not covered by this hook; no shell command in this run writes to them.
Alternatives rejected: (1) Rely on discipline only — F11 risk with many subagents.
Consequences: Any subagent Write/Edit to those paths is blocked with exit 2; the hook test is re-run [EV: docs/evidence/p00/hooks-orchestrator-20261001T134902.log] for the original cases and a new case is added in the G0 re-run.
Reversible: YES
Related: D-003, D-005
Evidence: none

## D-011 — Root SPEC_CHECKLIST.md is written by spec-drift (the design-session original never existed)
Date: 2026-10-01T14:08:44+1000 · Phase/MS: 0.16 item 5 · Decided by: orchestrator · Status: ADOPTED
Context: 0.16 item 5 preserves the design session's root SPEC_CHECKLIST.md before running spec-drift init; that file does not exist (B-001), so nothing needs archiving. scripts/hooks/guard_write.sh listed SPEC_CHECKLIST.md as immutable, which would block spec-drift's own write.
Decision: Remove SPEC_CHECKLIST.md from the immutable list; spec-drift init writes a new root SPEC_CHECKLIST.md from prompts/01_MASTER_PLANNING_PROMPT.md through a subagent whose only task is the init (brief P00-specdrift-init).
Alternatives rejected: (1) Keep the guard and skip spec-drift — Phase 25 item 10 then needs the manual checklist only. (2) Write the checklist to another path — the tool's report command reads the root file.
Consequences: SPEC_CHECKLIST.md becomes a planning artefact (not a manifest deliverable; it is a tool file); Phase 25 item 10 uses spec-drift report.
Reversible: YES
Related: B-001, D-005
Evidence: none

## D-012 — agentic-sdlc plugin disabled for this folder by Devesh (settings.local.json); its git-confirmation hook is not used
Date: 2026-10-01T14:11:22+1000 · Phase/MS: 0.16 · Decided by: Devesh (recorded by orchestrator) · Status: ADOPTED
Context: tools/resume_message.txt (written by Devesh at 2026-10-01T14:08:00+1000, read in full before this entry) states that the user-level plugin agentic-sdlc (id agentic-sdlc@synced) has a PreToolUse hook that asks for a human "Yes" before every git commit, tag and push even in bypassPermissions mode, and that it is turned off for this folder only in .claude/settings.local.json ("enabledPlugins": {"agentic-sdlc@synced": false}); it asks for the file to be left as it is.
Decision: Leave .claude/settings.local.json untouched (it is git-ignored per Phase 0.16 item 4, so it is not committed); agentic-sdlc stays OPTIONAL and unused (D-006); tools/resume_message.txt and tools/resume_planning.command are Devesh's inputs and are committed unchanged.
Alternatives rejected: (1) Re-enable the plugin — its confirmation prompt would stall unattended Git operations (OM-1.9).
Consequences: No Git step waits for confirmation; the resume launcher uses prompts/03_RESUME_PROMPT.md Variant B.
Reversible: YES (Devesh edits .claude/settings.local.json)
Related: D-006
Evidence: none

<!-- END OF FILE -->
