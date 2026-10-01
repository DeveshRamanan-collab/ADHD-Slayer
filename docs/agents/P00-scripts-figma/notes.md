# P00-scripts-figma — notes (Phase 0.16 item 2)
Fixture root: `docs/evidence/p00/fixtures/P00-scripts-figma` (good tree, fake key `FIXTUREFILEKEY`, pages `today-and-tasks` 10:1 from an XML response with 441 nodes incl. a 423-descendant frame, `watch` 20:1 from a JSON response with a prototype reaction). Deliberately failing tree: `<fixture root>/bad` (same index plus defects, and key `BROKENKEY` with a malformed index, an unrecognised response and a page folder without `nodes.json`). Every proof ran twice; the logs below are the second runs. Shared parsing lives in `figma_fingerprint.py` and `figma_reconcile.py`; the other scripts import them (standard library only, Python 3.9).

## scripts/figma_fingerprint.py
- Does: per-page SHA-256 over the sorted `(id, name, type, parentId, width, height)` list (banned-substring fields dropped first; canonical JSON `sort_keys`, no spaces, UTF-8 with `ensure_ascii=False`); root = SHA-256 of page hex digests joined with `\n` in page order (order of the cached root listing, then slug). Writes `fingerprint` into each `nodes.json` only when changed; prints the lock table. `--build <slug>=<pageId>` writes `nodes.json` from the cached `get_metadata` response (MCP wrapper around JSON trees or XML node lists; `UNRECOGNISED` exit 2 otherwise). `--check` reports `DRIFT` without writing.
- Fixture: `python3 scripts/figma_fingerprint.py FIXTUREFILEKEY --root <fixture> --build today-and-tasks=10:1 --build watch=20:1` [EV: docs/evidence/p00/fingerprint-fixture-P00-scripts-figma-20261001T161219.log]
- Failing: malformed index, exit 1 [EV: docs/evidence/p00/fingerprint-fail-index-P00-scripts-figma-20261001T161220.log]; unrecognised response, exit 2 [EV: docs/evidence/p00/fingerprint-fail-format-P00-scripts-figma-20261001T161221.log]
- Help: [EV: docs/evidence/p00/help-figma_fingerprint-P00-scripts-figma-20261001T161235.log]
- Clauses not implemented: none. The real per-page `get_metadata` format is not yet cached (only the root listing, which parses); the XML tag-to-type mapping is `[UNVERIFIED]` against a real page response.

## scripts/figma_reconcile.py
- Does: top-level frames (FRAME/COMPONENT/COMPONENT_SET/INSTANCE under the page or a chain of SECTIONs), sections, component sets, standalone components (variants inside a set are covered by the set row) and interaction candidates (reaction, INSTANCE main-component name, or node name against the Phase 3 regex) versus `SCR-/FRM-/CMP-/INT-` rows and `NON-INTERACTIVE` lines from `docs/FIGMA_AUDIT.md` or `docs/figma/analysis/*.md`; per-page counts, missing ids both sides, Watch/Glanceables Platform checks; `--candidates` in 04-T11 block order; `--strict` exit 1; exit 2 for a page folder with raw text and no `nodes.json`.
- Fixture: `--strict` pass [EV: docs/evidence/p00/reconcile-fixture-P00-scripts-figma-20261001T161222.log]; `--candidates today-and-tasks` [EV: docs/evidence/p00/reconcile-candidates-P00-scripts-figma-20261001T161223.log]
- Failing: MISSING-INT and PLATFORM, exit 1 [EV: docs/evidence/p00/reconcile-fail-strict-P00-scripts-figma-20261001T161225.log]; NONODES, exit 2 [EV: docs/evidence/p00/reconcile-fail-nonodes-P00-scripts-figma-20261001T161226.log]
- Help: [EV: docs/evidence/p00/help-figma_reconcile-P00-scripts-figma-20261001T161235.log]
- Interpretation: depth-1 SECTIONs also need an FRM row (Kind `section`) so that the 04-T11 rule "row count = depth-1 count" and this script agree. A `NON-INTERACTIVE` line must carry the node id on the same line. The regex is applied literally (no word boundaries), so names such as "Arrow" or "Table" become candidates.

## scripts/figma_read_plan.py
- Does: writes `docs/figma/read-plan.md` with tiers T1–T12, statuses from the ledger (`ok` = done, latest `truncated`/`error` = failed), T10 variants as `skipped-variant` unless `--include-variants`, > 400-descendant frames and truncated frames expanded to direct children, epochs filled at cap minus reserve (default 30), per-tier/per-epoch/per-status totals, tools marked unavailable in `TOOL_COVERAGE.md` omitted and listed.
- Fixture: [EV: docs/evidence/p00/readplan-fixture-P00-scripts-figma-20261001T161227.log]
- Failing: ledger timestamp without seconds/offset, TIME, exit 1 (plan still written; cap 36 shows epochs 2 and 3) [EV: docs/evidence/p00/readplan-fail-ledger-P00-scripts-figma-20261001T161228.log]
- Help: [EV: docs/evidence/p00/help-figma_read_plan-P00-scripts-figma-20261001T161235.log]
- Interpretation: page categories come from page-name patterns (MVP order of Phase 1.4); pages matching no known name (the real file's "iPhone v4: complete build", "Build spec", "Copy deck", "Cover") are planned in T5 after the MVP pages. T2 falls back to the page(s) with the most components when no Foundations/Components page exists. T3 needs `--figjam KEY:NODE` because no board is in `nodes.json`. T11 plans only device-sized Future frames whose name matches an MVP page pattern. Kind is a heuristic from type, size and name.

## scripts/extract_text.py
- Does: parses every cached `get_design_context` response (data-node-id markup or JSON TEXT nodes) into `docs/figma/text-layers.csv` (node_id, page, frame_id, frame_name, text, style_token, is_placeholder_guess) and lists unextracted top-level frames in `docs/figma/text-layers.NOT-EXTRACTED.md` with TRUNCATED / metadata-only-variant (from `read-plan.md` `skipped-variant`) / `[NOT YET READ]`; a frame split into children counts as extracted only when every child is.
- Fixture: 5 text rows, 7 frames not extracted [EV: docs/evidence/p00/extracttext-fixture-P00-scripts-figma-20261001T161230.log]
- Failing: FORMAT and ORPHAN, exit 1 [EV: docs/evidence/p00/extracttext-fail-P00-scripts-figma-20261001T161231.log]
- Help: [EV: docs/evidence/p00/help-extract_text-P00-scripts-figma-20261001T161235.log]
- Interpretation: the "mode-sample pattern" is defined as `{token}`, `[token]`, sample/example, XX, 00:00, John/Jane Doe. The markup parser targets the React/Tailwind output of `get_design_context` as `[UNVERIFIED]` until a real response is cached.

## scripts/validate_analysis.py
- Does: COUNT, CAND, BLOCK (A–E per cached `###` block), INTBLOCK (B–E per `#### INT-` block), REDLINE, COUNTS (section 3 numeric and consistent with the file and `nodes.json`), RANGE (`docs/figma/id-ranges.md`), END, PHRASE/PLACE (imports `validate_docs.exempt_mask`, `PHRASES`, `PLACE`).
- Fixture: [EV: docs/evidence/p00/validateanalysis-fixture-today-P00-scripts-figma-20261001T161232.log] and [EV: docs/evidence/p00/validateanalysis-fixture-watch-P00-scripts-figma-20261001T161233.log]
- Failing: 13 failures across CAND, BLOCK, INTBLOCK, RANGE, REDLINE, COUNTS, PHRASE, PLACE, END, exit 1 [EV: docs/evidence/p00/validateanalysis-fail-P00-scripts-figma-20261001T161234.log]
- Help: [EV: docs/evidence/p00/help-validate_analysis-P00-scripts-figma-20261001T161235.log]
- Interpretation: the expected section-1 count is depth-1 nodes plus top-level frames inside SECTIONs. A block counts as cached when a non-TRUNCATED cache file exists or section 1 says `yes`.
- Template conflict: the 04-T11 line `Id ranges: SCR/FRM/CMP/INT-<a>…<b>` contains `…`, which PHRASE rejects; fixtures use an en dash. Proposed: change the template to `<a>–<b>`.

<!-- END OF FILE -->
