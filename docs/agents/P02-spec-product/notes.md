# P02-spec-product notes
- Inputs read in full: docs/build-spec/01-product-and-features.md (415 lines), docs/build-spec/03-data-model.md (434 lines). Line counts logged: docs/evidence/p00/p02-inputs-spec-product-P02-spec-product-20261001T142111.log
- Output: docs/parts/SOURCE_NOTES/02-spec-product.md (343 lines, end marker present). 205 rows for 01, 105 rows for 03, 10 conflict rows, 62 RED-LINE tags.
- Validator: docs/evidence/p00/p02-validate-spec-product-2-P02-spec-product-20261001T161142.log (0 failures). docs/parts/ is in the validator's EXCL list, so the file was also run through validate_docs.check() with EXCL cleared: 0 failures.
- Formatting note for assembly: the validator masks backtick spans, so a cell that is only a backtick span counts as empty (CELL), and the word Built outside backticks trips the verification-verb rule (EV). Source cells are therefore plain path#heading text with only `Built` in backticks.
- Scope tier: neither input uses MVP, v1 or Future. Tier is `unstated`, with the source's own Built / To build / Later word in brackets. Later items are written as "Future per `Later`".
<!-- END OF FILE -->
