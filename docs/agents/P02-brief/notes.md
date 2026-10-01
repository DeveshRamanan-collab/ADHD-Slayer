# P02-brief notes
- Inputs read in full, line counts logged [EV: docs/evidence/p00/p02-inputs-brief-P02-brief-20261001T142126.log]: prompts/figma_design_prompt.md 181, docs/design-critique.md 119, design/figma/README.md 38, docs/build-spec/_context.md 51, docs/build-spec/_resume.md 6.
- Rules read: docs/AGENT_RULES.md, prompts/01_MASTER_PLANNING_PROMPT.md (Phase 2, K.3, K.5), prompts/SOURCE_MAP.md.
- run_logged.sh wrote logs under docs/evidence/p00/ (its default directory), not docs/evidence/p02/.
- Validator excludes docs/parts/, so it reports 0 failures trivially [EV: docs/evidence/p00/p02-validate-brief-P02-brief-20261001T142615.log]; a self-check calling the validator's check() with docs/parts/ removed from the exclusions also reports 0 errors [EV: docs/evidence/p00/p02-selfcheck-brief-P02-brief-20261001T142615.log].
- Red-line tagging convention in the part: `[RED-LINE RL-n] guard` = a Phase 5 scan the source requires to prevent a breach (37 rows); bare `[RED-LINE RL-n]` = the source assertion itself would or may breach a red line (5 rows: critique "is it working yet?" framing RL-5; critique "Warm-up" zone label RL-2; _context medication sliders RL-2; _context bring-your-own-AI task egress RL-9; _context E2E ciphertext sync RL-9).
- Conflicts: 28 rows; rows 1 to 17 are _context.md "Decisions already made" against the brief, as the spawn message required.
<!-- END OF FILE -->
