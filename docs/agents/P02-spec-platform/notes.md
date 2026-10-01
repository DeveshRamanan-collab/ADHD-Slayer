# P02-spec-platform notes
- Inputs read in full: docs/build-spec/04-intelligence.md (271 lines), docs/build-spec/05-platform.md (267), docs/build-spec/10-live-activities.md (123). Line counts: [EV: docs/evidence/p00/p02-inputs-spec-platform-P02-spec-platform-20261001T142122.log]
- Rules read: docs/AGENT_RULES.md, prompts/01_MASTER_PLANNING_PROMPT.md Phase 2, K.3, K.5, prompts/SOURCE_MAP.md.
- Validator: `scripts/validate_docs.py` skips docs/parts/ (exit 0, [EV: docs/evidence/p00/p02-validate-spec-platform-P02-spec-platform-20261001T142754.log]); a run with the exclusion list emptied reports 0 errors [EV: docs/evidence/p00/p02-validate-spec-platform-noexcl-P02-spec-platform-20261001T142812.log]. Both logs landed under docs/evidence/p00/ because run_logged.sh chooses the folder.
- Scope-tier convention: the inputs never say MVP, v1 or Future; tier records "MVP" only for `at launch` or `Launch`, "Future" for `Later` or `after the iPhone launch`, otherwise "unstated" plus the source status word.
- Rows: 04-intelligence 132, 05-platform 128, 10-live-activities 49; conflicts 9; red-line tags 21.
<!-- END OF FILE -->
