# FIGMA TOOL COVERAGE — Phase 0.7
Read `docs/AGENT_RULES.md` before any work; its rules bind you.
Written: 2026-10-01T14:18:00+1000 · Author: orchestrator · Session 2 (resume)
File key in scope: `gLuoHFbiiUGajAUpluWXOW` (prompts/figma_urls.md; key discovery [EV: docs/evidence/p00/figma-key-discovery-orchestrator-20261001T141201.log])

## Transport and routes
| Item | Value | Source |
|---|---|---|
| MCP transport | claude.ai connector "claude.ai Figma", remote `https://mcp.figma.com/mcp`; no desktop app needed | [EV: docs/evidence/p00/preflight-config-orchestrator-20261001T135005.log] |
| Seat | `View`, tier `student`, team `team::1686304428269511457` (expected; not a stop condition, K.1) | docs/evidence/p00/figma-tools/whoami-orchestrator-20261001T135040.md |
| REST route | absent: `FIGMA_TOKEN` not set; the lock uses node fingerprints only (UA-007 optional) | [EV: docs/evidence/p00/preflight-env-orchestrator-20261001T135000.log] |
| Second Figma endpoint | `plugin:product-management:figma` exists but is never used (single reader, C-9) | docs/TOOL_CAPABILITY_AUDIT.md § plugin:product-management:figma |

## Rate limits (FACT, dated 2026-10-01)
Education plans: up to 200 tool calls per day and 10 per minute for tools that read data from Figma; exempt tools include `add_code_connect_map`, `create_new_file`, `whoami` (https://developers.figma.com/docs/figma-mcp-server/rate-limits-access/, verified 2026-10-01, [EV: docs/evidence/sources/FACT-figma-rate-limits.md]). Run caps (C-9): 150 counted calls per rolling 24 h, at most 8 per rolling 60 s, at least 7 s apart.

## Read tools present and how this run treats them
Tool names come from the session tool list (docs/evidence/p00/figma-tools/tool-list-orchestrator-20261001T141727.md); one-line purposes come from Figma's tool index (https://developers.figma.com/docs/figma-mcp-server/tools-and-prompts/, verified 2026-10-01, [EV: docs/evidence/sources/FACT-figma-tools.md] and the per-tool excerpts named below).

| Tool | Figma's description | Counted against the limit | Used in this run | Hook coverage | Excerpt |
|---|---|---|---|---|---|
| tool `get_metadata` | Sparse XML outline of a selection | YES (reads data; not on the exempt list) | YES — T1 root and per-page or per-section outlines | figma_pre / figma_post / figma_fail | docs/evidence/sources/FACT-figma-tool-get_metadata.md |
| tool `get_design_context` | Design context for a layer or selection | YES | YES — T5, T7–T10 per top-level frame | figma_pre / figma_post / figma_fail | docs/evidence/sources/FACT-figma-tool-get_design_context.md |
| tool `get_variable_defs` | Variables and styles used in a selection | YES | YES — T2, two reads | figma_pre / figma_post / figma_fail | docs/evidence/sources/FACT-figma-tools.md |
| tool `get_screenshot` | Screenshot of a selection | YES | Only T12, at most 40, only for `layout ambiguous` frames | figma_pre / figma_post / figma_fail | docs/evidence/sources/FACT-figma-tool-get_screenshot.md |
| tool `get_motion_context` | Keyframe animation data and code snippets | YES | YES — T6 | figma_pre / figma_post / figma_fail | docs/evidence/sources/FACT-figma-tool-get_motion_context.md |
| tool `get_figjam` | Converts FigJam diagrams to XML | YES | NO — no FigJam board exists (B-004) | figma_pre / figma_post / figma_fail | docs/evidence/sources/FACT-figma-tool-get_figjam.md |
| tool `get_libraries` | Lists subscribed and available libraries | YES | T4 — one read at most | figma_pre / figma_post / figma_fail | docs/evidence/sources/FACT-figma-tool-get_libraries.md |
| tool `search_design_system` | Searches libraries for components, variables, styles | YES | T4 alternative to `get_libraries` — one read at most | figma_pre / figma_post / figma_fail | docs/evidence/sources/FACT-figma-tool-search_design_system.md |
| tool `get_code_connect_map` | Retrieves node ID to code component mappings | YES | NO — no code components exist to map in the planning run | figma_pre / figma_post / figma_fail | docs/evidence/sources/FACT-figma-tool-get_code_connect_map.md |
| tool `whoami` | Identity and plans of the authenticated user | NO (exempt) | YES — preflight only | not hooked (free) | docs/evidence/sources/FACT-figma-rate-limits.md |
| named `get_figma_skill`, `download_assets`, `export_video` | skill text, asset export, video export | treated as counted | NO — blocked by `scripts/hooks/figma_pre.sh` | figma_pre (block) | `.claude/settings.json` PreToolUse matcher |
| named `get_code_connect_suggestions`, `get_context_for_code_connect`, `list_file_components_for_code_connect`, `get_shader`, `list_file_shaders`, `list_shaders`, `get_generative_plugin`, `list_generative_plugins` | Code Connect, shader and generative-plugin reads | treated as counted | NO — outside the planning run's needs; never called | not hooked; never called (D-013) | docs/evidence/sources/FACT-figma-tools.md |
| Write tools (`use_figma`, `create_new_file`, `upload_assets`, `generate_diagram`, `create_shader`, `update_shader`, `add_code_connect_map`, `send_code_connect_mappings`, `create_generative_plugin`, `update_generative_plugin`, `weave_*`) | modify Figma or run models | N/A (never called) | NEVER (C-3) | figma_pre (block, exit 2) | `.claude/settings.json` PreToolUse matcher |

## Attributes and which tool exposes them
Observed so far: one `get_metadata` call without a node id returned only the top-level page list (`0:1: Cover`) as plain text inside a JSON text item, not XML (ledger row 1; docs/figma/raw/gLuoHFbiiUGajAUpluWXOW/get_metadata/root.txt). Every other cell below is Figma's documented purpose and is `[UNVERIFIED]` until the first Phase 1.2 read of that tool is cached; Phase 1.2 rewrites each row to `observed (node <id>, <cache path>)` or `not readable`.

| Attribute | Expected source | Status |
|---|---|---|
| Pages | `get_metadata` (no node id) | observed: page list only, one page `0:1` Cover listed (root.txt) |
| Node hierarchy, frames, sections | `get_metadata` with a page or section id (`83:2`, `114:2`, `94:1246` per prompts/SOURCE_MAP.md) | [UNVERIFIED] |
| Component definitions, instances, variants, component properties | `get_metadata` (types) and `get_design_context` (properties) | [UNVERIFIED] |
| Variables, design tokens, modes | tool `get_variable_defs` | [UNVERIFIED]; file-wide versus node-scoped decided by comparing the two T2 reads |
| Colour values, typography, spacing, Auto Layout, constraints, effects | tool `get_design_context` | [UNVERIFIED] |
| Text content | tool `get_design_context` | [UNVERIFIED] |
| Prototype reactions, navigation targets, transitions | none documented in the tool index | [UNVERIFIED]; if no read exposes them the lock records `interactions: not directly readable` and Phase 3 uses the inferred route |
| Animation properties | tool `get_motion_context` | [UNVERIFIED] |
| Screenshots | tool `get_screenshot` | not used before T12 |
| Exportable assets | tool `download_assets` | not readable in this run (blocked by hook) |
| Code Connect information | tool `get_code_connect_map` | not used in this run |
| Dev Mode annotations | tool `get_design_context` | [UNVERIFIED] |
| Version and last-modified | REST only | not readable (no `FIGMA_TOKEN`); the lock uses fingerprints (Phase 1.3 known limitation) |

## Notes for Phase 1
- The K.1 page list does not apply: the file's real pages and sections are in prompts/SOURCE_MAP.md (`83:2`, `114:2`, `94:1246`, `0:1`); the read plan starts from those ids. The `Foundations`/`Components` pair for the T2 comparison is replaced by the nodes that hold tokens and components inside `83:2`, chosen from its cached metadata (decision logged in Phase 1.2).
- `114:2` was read once during setup with no cache; it is a normal planned read (D-009).

<!-- END OF FILE -->
