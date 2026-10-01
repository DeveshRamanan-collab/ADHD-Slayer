# P02-spec-backend notes
- Inputs read in full: docs/build-spec/02-backend.md (459 lines), docs/build-spec/11-backend-contract.md (155 lines), docs/api-design.md (458 lines). Line counts logged [EV: docs/evidence/p00/p02-inputs-spec-backend-P02-spec-backend-20261001T142114.log] (run_logged.sh wrote the log under docs/evidence/p00/, not p02/).
- Validator result for the part: 0 failures [EV: docs/evidence/p00/p02-validate-spec-backend-P02-spec-backend-20261001T142722.log].
- Scope-tier mapping used: source words `at launch` → MVP; `Later` → Future; `after launch` → v1; `(v1)` → v1; status words `Built` / `To build` / `To decide` are not tiers, so those rows read `unstated (source says ...)`.
- RL-9 tag applied to every assertion that sends health or medication data off the device: encrypted snapshot backup and restore, sync batches (both designs), crash reports, usage analytics, support form free text, share-sheet export (exception (a), tagged for visibility) and bring-your-own-AI calls.
- Rows: 02-backend 203, 11-backend-contract 37, api-design 62; conflicts 13; red-line tags 59 total, 32 of them RL-9.
- Loop 1 fix (orchestrator spot-check): verification verbs on part lines 38, 220, 255, 256, 262 moved inside backticks; validate_parts.py SOURCE_NOTES reports 0 failures [EV: docs/evidence/p00/p02-validate-parts-spec-backend-P02-spec-backend-20261001T161610.log].
<!-- END OF FILE -->
