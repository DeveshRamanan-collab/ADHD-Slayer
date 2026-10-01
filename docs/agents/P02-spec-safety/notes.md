# P02-spec-safety notes
- Inputs logged: cmd `wc -l` on both inputs, [EV: docs/evidence/p00/p02-inputs-spec-safety-P02-spec-safety-20261001T142116.log] (06: 382 lines, 07: 255 lines). run_logged.sh placed the log under docs/evidence/p00/ (its default), not docs/evidence/p02/.
- Both inputs were read in full with the Read tool (06 in one call of 383 displayed lines; 07 in one call of 256 displayed lines).
- Tier mapping: `Built` and `To build` → MVP; `Later` → Future; `Owner` → unstated; no status word → unstated. Basis: 06 intro defines `Later` as after launch.
- 07 risk ids such as `D01` and `B01` are kept in backticks because the validator reads bare `D01`/`B01` as malformed decision/blocker ids.
- Validator: docs/parts/ is in the validator's exclusion list, so the official run reports 0 failures trivially; a scratch copy was also run through `check()` directly with 0 PHRASE/PLACE/CELL/TIME/EV/IDFMT errors after rewording three lines.
- Rows: 06 = 170, 07 = 153, conflicts = 6, lines carrying a red-line tag = 17.
<!-- END OF FILE -->
