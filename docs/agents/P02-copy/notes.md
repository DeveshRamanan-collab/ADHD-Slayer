# P02-copy notes
- Inputs: 20 files under docs/copy (32769 lines), line counts [EV: docs/evidence/p00/p02-inputs-copy-P02-copy-20261001T142126.log].
- All read in full; batch JSON files in chunks of at most 400 lines.
- Validation: validate_docs.py (part excluded by design) plus an in-process run with exclusions removed, 0 failures [EV: docs/evidence/p00/p02-validate-copy-P02-copy-20261001T161151.log].
- Red-line scan: 6500 variants, 19 breaching (15 `peak`, 2 `levels`, 1 `streaks`, 1 `skipped`); no dose-timing advice.
- 15 `peak` variants match prompts/SOURCE_MAP.md's 15 `peak` lines in app Copy.json; merge.py banned regex lacks `peak`.
- batch4_src.txt coachMeds differs entirely from batch4.json (older Log-all model). No batch3 source file exists in docs/copy.
<!-- END OF FILE -->
