# REVIEW BRIEF R-G0-1 — Gate G0 (Phase 0) — loop 1 of 3
Spawned by: orchestrator. You did not write any Phase 0 artefact and have no memory of its authoring. Verdict is PASS or FAIL. FAIL needs file:line items. Do not fix anything; do not soften; do not praise.
Project root: /Users/deveshramanan/ADHD Slayer. Agent id for evidence names: R-G0-1.

## Artefacts under review
docs/PREFLIGHT.md, docs/SOURCE_INVENTORY.md, docs/TOOL_CAPABILITY_AUDIT.md, docs/TOOL_STRATEGY.md, docs/MANIFEST.md, docs/figma/TOOL_COVERAGE.md, CLAUDE.md, .claude/settings.json, scripts/hooks/*, scripts/*.

## Read first
1. docs/AGENT_RULES.md — OM-4 row G0 (eight mechanical items) and the generic rules.
2. prompts/01_MASTER_PLANNING_PROMPT.md lines 373–471 (Phase 0) — the document-specific requirements.
3. prompts/04_AGENT_BRIEFS_AND_TEMPLATES.md 04-T2 generic checklist.

## What to do
1. Run `CLAUDE_AGENT_ID=R-G0-1 scripts/run_logged.sh review-gate-G0 -- python3 scripts/gate.py G0` and record each item's result; then independently re-check items 1, 2, 3, 7 and 8 by opening the files (do not trust gate.py alone).
2. Apply the 04-T2 generic checklist items 1–11 to docs/PREFLIGHT.md, docs/TOOL_STRATEGY.md and docs/figma/TOOL_COVERAGE.md. Claim sampling (item 5): run `python3 scripts/claims.py <file> --sample` for each of those three files and resolve every sampled claim by opening the cited evidence/excerpt; write docs/evidence/reviews/R-G0-1-claims.md (first line `review: R-G0-1`; one row per claim: file:line | claim | source opened | RESOLVED/UNRESOLVED; end with `<!-- END OF FILE -->`).
3. Document-specific: CLAUDE.md keeps the bootstrap text and the NEVER list and red lines RL-1–RL-9; .claude/settings.json has no `defaultMode` and denies AskUserQuestion, sudo, destructive git; every hook named in prompts/05_SETTINGS_AND_HOOKS.md exists, is executable and has a docs/evidence/p00/hooks-*.log test.

## Rules
Never call a Figma tool or AskUserQuestion; never run git write commands; never edit any file except docs/evidence/reviews/R-G0-1-claims.md and docs/agents/R-G0-1/notes.md. As your last action write those two paths to docs/agents/R-G0-1/outputs.txt.

## Report format (final message; nothing else)
VERDICT: PASS | FAIL
ITEMS: <n> checked; <n> FAIL
GATE ITEMS 1–8: <PASS/FAIL each with one-line reason>
FAILURES (file:line → what is wrong → what would fix it): …
SAMPLE: <n> claims sampled of <n>; <n> resolved; UNRESOLVED: <list>
RED-LINE HITS: <list or none>
EVIDENCE: <log and claims-file paths>
<!-- END OF FILE -->
