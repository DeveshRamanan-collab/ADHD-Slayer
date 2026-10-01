# BLOCKERS — B-nnn entries (04-T6)

## B-001 — Design-session documents named in K.2 do not exist (docs/design/*, root SPEC_CHECKLIST.md)
Opened: 2026-10-01T13:54:12+1000 · Phase/MS/step: 0.1 item 2 · Status: WONTFIX (the documents were never written; prompts/SOURCE_MAP.md names the substitutes)
Attempted (exact): `bash scripts/preflight_probe.sh env` presence check; `python3 scripts/source_inventory.py`
Result (verbatim, first 10 lines, indented):
    missing: docs/design
    missing: SPEC_CHECKLIST.md
Error class (Figma): n/a
Why it blocks: Phases 1, 5 and 13 reference docs/design/handoff.md, figma-usage.md, decisions.md and DESIGN_SPEC.md by name; scripts/design_doc_xref.py reads two of them.
Work continued without it: The substitutes in prompts/SOURCE_MAP.md (docs/build-spec/01–11, _context.md, docs/copy/, docs/system-design.md, docs/api-design.md, docs/design-critique.md, design/figma/README.md, research/ADHD planner product design and research.pdf) are read in their place; design_doc_xref.py reads docs/build-spec/*.md instead (D-005).
Fix in plain English (for Devesh if applicable): none needed — success looks like: nothing to do.
Retry log: none (not retryable)
Effect on downstream work if never resolved: [DESIGN-DOC-ONLY] tags cite docs/build-spec paths instead of docs/design paths.

## B-002 — Free disk space below the 50 GB preflight threshold
Opened: 2026-10-01T13:54:12+1000 · Phase/MS/step: 0.1 item 7 · Status: USER ACTION REQUIRED (UA-001)
Attempted (exact): `df -h /`
Result (verbatim, first 10 lines, indented):
    Filesystem        Size    Used   Avail Capacity iused ifree %iused  Mounted on
    /dev/disk3s1s1   228Gi    13Gi    13Gi    51%    486k  132M    0%   /
Error class (Figma): n/a
Why it blocks: Nothing in the planning run; the build phase (Xcode DerivedData, simulator runtimes, archives) needs tens of GB.
Work continued without it: All planning work; no simulator runtime downloads attempted.
Fix in plain English (for Devesh if applicable): see UA-001 — success looks like: `df -h /` shows at least 50 GB in the Avail column.
Retry log: none yet
Effect on downstream work if never resolved: MS-00 builds may fail with "No space left on device".

## B-003 — tga.gov.au, accc.gov.au and austlii.edu.au refuse the scripted fetch route
Opened: 2026-10-01T13:54:12+1000 · Phase/MS/step: 0.1 item 10 · Status: OPEN
Attempted (exact): `python3 scripts/fetch_excerpt.py <url> FACT-route-tga|FACT-route-accc|FACT-route-austlii …`; `curl -A "Mozilla/5.0" …`; WebFetch of a tga.gov.au excluded-software page
Result (verbatim, first 10 lines, indented):
    tga 404
    accc 403
    austlii 403
    WebFetch: timeout of 60000ms exceeded
Error class (Figma): n/a
Why it blocks: Phase 11 needs TGA guidance text as a primary source.
Work continued without it: legislation.gov.au and oaic.gov.au return HTTP 200 (docs/evidence/sources/FACT-route-legislation.md, FACT-route-oaic.md); Phase 11 retries TGA through WebFetch/WebSearch on specific guidance and PDF URLs, and cites the Act and the Excluded Goods Determination on legislation.gov.au as the primary source.
Fix in plain English (for Devesh if applicable): none — success looks like: N/A (orchestrator retries in Phase 11).
Retry log: 2026-10-01T14:18:37+1000 resume retry (curl): tga 404, accc 403, austlii 403 — still OPEN [EV: docs/evidence/p00/b003-retry-orchestrator-20261001T141837.log]
Effect on downstream work if never resolved: TGA guidance claims are tagged [UNVERIFIED] and listed for lawyer review.

## B-004 — No FigJam flows board exists for this project
Opened: 2026-10-01T13:54:12+1000 · Phase/MS/step: 0.1 item 5 / 1.1 · Status: WONTFIX (prompts/figma_urls.md and prompts/SOURCE_MAP.md state no board is known)
Attempted (exact): key discovery in prompts/figma_urls.md (board URLs: none)
Result (verbatim, first 10 lines, indented):
    No FigJam flows board ("Planner · Flows") is known for this project.
Error class (Figma): n/a
Why it blocks: Phase 1.2 item 4 (one get_figjam read) and flow cross-checks.
Work continued without it: Flows are derived from the design file's own prototype data and the Build spec page; the get_figjam read is skipped (saves one read).
Fix in plain English (for Devesh if applicable): none — success looks like: N/A.
Retry log: none
Effect on downstream work if never resolved: Navigation routes are "inferred" where the design file carries no prototype reactions.

## B-005 — Figma REST route absent (no FIGMA_TOKEN)
Opened: 2026-10-01T16:12:51+1000 · Phase/MS/step: 0.1 item 5 · Status: USER ACTION REQUIRED (UA-007, optional)
Attempted (exact): environment presence check in `bash scripts/preflight_probe.sh env`
Result (verbatim, first 10 lines, indented):
    FIGMA_TOKEN: unset
Error class (Figma): n/a
Why it blocks: Nothing; the lock records structural fingerprints only (Phase 1.3 known limitation).
Work continued without it: The version lock uses node fingerprints from cached metadata [EV: docs/evidence/p00/preflight-env-orchestrator-20261001T135000.log].
Fix in plain English (for Devesh if applicable): see UA-007 — success looks like: PREFLIGHT says "REST route available".
Retry log: none (not retryable by the orchestrator)
Effect on downstream work if never resolved: Edits inside a frame between sessions go undetected by the lock.

## B-006 — No physical iPhone or Apple Watch visible to Xcode
Opened: 2026-10-01T16:12:51+1000 · Phase/MS/step: 0.1 item 13 · Status: USER ACTION REQUIRED (UA-003)
Attempted (exact): `xcrun devicectl list devices`
Result (verbatim, first 10 lines, indented):
    No devices found.
Error class (Figma): n/a
Why it blocks: Nothing in planning; on-device checks in MS-05 onward.
Work continued without it: Simulator-only planning [EV: docs/evidence/p00/preflight-devices-orchestrator-20261001T135104.log].
Fix in plain English (for Devesh if applicable): see UA-003 — success looks like: both devices listed in Xcode without a warning.
Retry log: none yet
Effect on downstream work if never resolved: Device-only checks (alarms, Lock Screen, Watch haptics) stay unverified.

## B-007 — xcodegen, swiftlint, swiftformat not installed
Opened: 2026-10-01T16:12:51+1000 · Phase/MS/step: 0.1 item 9 · Status: WONTFIX (by design: build-phase tasks, not installed in planning)
Attempted (exact): presence check in `bash scripts/preflight_probe.sh pkg`
Result (verbatim, first 10 lines, indented):
    xcodegen: absent; swiftlint: absent; swiftformat: absent
Error class (Figma): n/a
Why it blocks: Nothing in planning.
Work continued without it: MS-00 tasks install them [EV: docs/evidence/p00/preflight-pkg-orchestrator-20261001T135005.log].
Fix in plain English (for Devesh if applicable): none needed — success looks like: N/A (installed by the build).
Retry log: none (not retryable)
Effect on downstream work if never resolved: none; MS-00 owns it.

## B-008 — Claude in Chrome and the browser tool not connected
Opened: 2026-10-01T16:12:51+1000 · Phase/MS/step: 0.1 item 10 · Status: WONTFIX (not needed: WebFetch and fetch_excerpt.py are the research routes)
Attempted (exact): tool-list inspection in `bash scripts/preflight_probe.sh config`
Result (verbatim, first 10 lines, indented):
    no browser tools in the tool list
Error class (Figma): n/a
Why it blocks: Only sites that need JavaScript rendering (see B-003).
Work continued without it: WebFetch, WebSearch and scripts/fetch_excerpt.py [EV: docs/evidence/p00/preflight-config-orchestrator-20261001T135005.log].
Fix in plain English (for Devesh if applicable): none needed — success looks like: N/A.
Retry log: none (not retryable)
Effect on downstream work if never resolved: TGA pages may stay [UNVERIFIED] (B-003).

## B-009 — GitHub MCP server failed to connect
Opened: 2026-10-01T16:12:51+1000 · Phase/MS/step: 0.1 item 12 · Status: WONTFIX (gh CLI is the GitHub route)
Attempted (exact): MCP connection status in `bash scripts/preflight_probe.sh config`
Result (verbatim, first 10 lines, indented):
    plugin:github:github — failed to connect (Authorization header is badly formatted)
Error class (Figma): n/a
Why it blocks: Nothing; gh is authenticated with repo scope.
Work continued without it: gh CLI for every GitHub operation [EV: docs/evidence/p00/preflight-config-orchestrator-20261001T135005.log].
Fix in plain English (for Devesh if applicable): none needed — success looks like: N/A.
Retry log: none
Effect on downstream work if never resolved: none.

## B-010 — ansight runtime-verification CLI not on PATH
Opened: 2026-10-01T16:12:51+1000 · Phase/MS/step: 0.1 item 12 · Status: WONTFIX (Xcode MCP and XCUITest are the primary runtime verifiers)
Attempted (exact): `command -v ansight` in `bash scripts/preflight_probe.sh pkg`
Result (verbatim, first 10 lines, indented):
    ansight: absent
Error class (Figma): n/a
Why it blocks: Nothing.
Work continued without it: Xcode MCP simulator tools and XCUITest in the build [EV: docs/evidence/p00/preflight-pkg-orchestrator-20261001T135005.log].
Fix in plain English (for Devesh if applicable): none needed — success looks like: N/A.
Retry log: none
Effect on downstream work if never resolved: none.

<!-- END OF FILE -->
