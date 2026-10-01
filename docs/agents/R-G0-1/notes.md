review: R-G0-1 notes (Gate G0, loop 1 of 3)

Gate run: [EV: docs/evidence/p00/review-gate-G0-R-G0-1-20261001T161547.log] (8 PASS, 1 FAIL item 6).
Validator runs: docs/evidence/p00/review-validate-PREFLIGHT-R-G0-1-20261001T161736.log, docs/evidence/p00/review-validate-TOOL_STRATEGY-R-G0-1-20261001T161736.log, docs/evidence/p00/review-validate-TOOL_COVERAGE-R-G0-1-20261001T161736.log (all exit 0).

Independent re-checks:
- Item 1: all 27 distinct PREFLIGHT `[EV:` paths exist; statuses only OK/MISSING/UNVERIFIABLE; RUN-SURVIVAL on line 1.
- Item 2: discovery log 160 unique ITEM lines; Tier A 60 headings + Tier B 100 rows; name sets identical (comm empty). Harmless-call method for skills/agents is a definition-file read (disclosed at docs/TOOL_CAPABILITY_AUDIT.md:4). That probe reported the callable names `agentic-council:Guardian/Skeptic/Pathfinder/Artisan/Architect` as ABSENT (docs/evidence/p00/tierA-probe-orchestrator-20261001T135754.log:153-157) and the re-probe used file names `council-*`, which are not spawnable subagent types.
- Item 3: 16 stage rows, multi-agent plan § 2, ownership map covers all 61 MANIFEST paths.
- Item 4: 12 hooks plus `_lib.sh` exist and are executable; newest log hooks-orchestrator-20261001T161219.log 28 PASS, 0 FAIL. Hook drift from 05 is limited to subagent_stop (D-001), guard_write (D-010, D-011), guard_bash runner block (D-017). D-017 says 29 PASS; the log has 28.
- Item 6: tree dirty (evidence logs, scripts/validate_parts.py untracked; P02 parts and notes modified by concurrent subagents).
- Item 7: 11 MISSING rows each carry a B- id; B-001 to B-010 exist in docs/BLOCKERS.md.
- Item 8: 22 expected rows; SHA-256 prefixes recomputed and equal for all 16 present files. K.2 bullet 4 (main design document, Claude Docs artefact 3b1b63f2-fca1-45ca-b096-209254c7e970) is not listed. SPEC_CHECKLIST.md is listed MISSING but now exists (spec-drift output, D-011).

Document-specific: CLAUDE.md keeps the 0.0b bootstrap text, C-3 and the NEVER list, RL-1 to RL-9 (33 lines). .claude/settings.json has no `defaultMode` (settings.local.json neither), denies AskUserQuestion, sudo, destructive git; byte-equal to prompts/05 JSON block.

Observation (no verdict impact): 20 scripts under scripts/ lack the executable bit (invoked as `python3`/`bash`, so they still run).
<!-- END OF FILE -->
