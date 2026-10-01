review: R-G0-1
Claim sample per 04-T2 item 5, from `python3 scripts/claims.py <file> --sample` run 2026-10-01T16:18+1000. PREFLIGHT 17 claims (step 2, 8 sampled); TOOL_STRATEGY 7 claims (step 1, 7 sampled); TOOL_COVERAGE 11 claims (step 2, 5 sampled). Total 20 sampled of 35.

| file:line | claim | source opened | result |
|---|---|---|---|
| docs/PREFLIGHT.md:4 | Every MISSING row is also a `B-` entry | docs/PREFLIGHT.md MISSING rows 12, 13, 46, 47, 64, 70, 82, 96, 103, 104, 112 vs docs/BLOCKERS.md headings B-001 to B-010 | RESOLVED |
| docs/PREFLIGHT.md:21 | Claude Code version `2.1.286` | docs/evidence/p00/preflight-env-orchestrator-20261001T135000.log:24 | RESOLVED |
| docs/PREFLIGHT.md:43 | Figma transport is the claude.ai connector at `https://mcp.figma.com/mcp` | docs/evidence/p00/preflight-config-orchestrator-20261001T135005.log:33 | RESOLVED |
| docs/PREFLIGHT.md:52 | `git version 2.54.0 (Apple Git-157)`; user.name and user.email set | docs/evidence/p00/preflight-git-orchestrator-20261001T135000.log:7,25,26 | RESOLVED |
| docs/PREFLIGHT.md:60 | Xcode 27.0 build 27A266a | docs/evidence/p00/preflight-apple-orchestrator-20261001T135002.log:10-11 | RESOLVED |
| docs/PREFLIGHT.md:63 | Swift 6.4; macOS 27.2 build 26B5091g | docs/evidence/p00/preflight-apple-orchestrator-20261001T135002.log:50,55,56 | RESOLVED |
| docs/PREFLIGHT.md:67 | Runtimes iOS 26.5, iOS 27.0, watchOS 27.0 | docs/evidence/p00/preflight-sims-orchestrator-20261001T135104.log:8-10 | RESOLVED |
| docs/PREFLIGHT.md:88 | App Store Review Guidelines text contains `1.4.2` | docs/evidence/sources/FACT-route-asrg.md (http 200, phrase 1.4.2, found True) | RESOLVED |
| docs/TOOL_STRATEGY.md:1 | Document is Phase 0.12 output (division of labour, multi-agent plan, ownership) | prompts/01_MASTER_PLANNING_PROMPT.md § 0.12 | RESOLVED |
| docs/TOOL_STRATEGY.md:2 | Capabilities sourced from docs/TOOL_CAPABILITY_AUDIT.md | docs/TOOL_CAPABILITY_AUDIT.md Tier A entries; note: names `agentic-council:council-*` used at lines 13, 32, 55, 57, 59, 60, 62 match definition file names, not the callable agent types (`agentic-council:Guardian` etc.; agent frontmatter `name: "Guardian"`) — recorded as a FAIL under 04-T2 item 4, the sourcing claim itself resolves | RESOLVED |
| docs/TOOL_STRATEGY.md:15 | spec-drift init in Phase 0.16, report at G4 and Phase 25 | prompts/01_MASTER_PLANNING_PROMPT.md:465 (0.16 item 5) | RESOLVED |
| docs/TOOL_STRATEGY.md:17 | Stage table has the same rows as docs/TOOL_CAPABILITY_AUDIT.md § 0.4 | diff of first column, docs/TOOL_STRATEGY.md:20-35 vs docs/TOOL_CAPABILITY_AUDIT.md:712-731 (identical, 16 rows) | RESOLVED |
| docs/TOOL_STRATEGY.md:40 | Fan-outs ordered most reasoning-heavy first per OM-7.9 | docs/AGENT_RULES.md § OM-7 item 9 | RESOLVED |
| docs/TOOL_STRATEGY.md:43 | Subagents inherit session model `claude-opus-5-5`; never switched for limits | docs/PREFLIGHT.md:29; docs/AGENT_RULES.md:79 and OM-7 item 7 | RESOLVED |
| docs/TOOL_STRATEGY.md:64 | Beginner test is Phase 25.9 | prompts/01_MASTER_PLANNING_PROMPT.md:228 (G4 row: beginner tests at Phase 25 items 8–9) | RESOLVED |
| docs/figma/TOOL_COVERAGE.md:3 | Written 2026-10-01T14:18:13+1000 by orchestrator, session 2 | docs/DECISION_LOG.md D-013 (2026-10-01T14:18:32+1000, Phase 0.7) and docs/evidence/p00/figma-tools/tool-list-orchestrator-20261001T141727.md timestamp | RESOLVED |
| docs/figma/TOOL_COVERAGE.md:15 | Education plans 200 per day, 10 per minute; exempt `add_code_connect_map`, `create_new_file`, `whoami` | docs/evidence/sources/FACT-figma-rate-limits.md:10 | RESOLVED |
| docs/figma/TOOL_COVERAGE.md:37 | Root `get_metadata` returned only page list `0:1: Cover` as text inside a JSON text item | docs/figma/raw/gLuoHFbiiUGajAUpluWXOW/get_metadata/root.txt; docs/figma/read-ledger.md row 1 | RESOLVED |
| docs/figma/TOOL_COVERAGE.md:42 | Section ids `83:2`, `114:2`, `94:1246` per prompts/SOURCE_MAP.md | prompts/SOURCE_MAP.md:8-10 | RESOLVED |
| docs/figma/TOOL_COVERAGE.md:56 | Real pages/sections are `83:2`, `114:2`, `94:1246`, `0:1` | prompts/SOURCE_MAP.md:8-11; root.txt lists only `0:1` as a page, so the other three are sections inside it, consistent with SOURCE_MAP | RESOLVED |

Sampled 20 · RESOLVED 20 · UNRESOLVED 0.

Non-sampled claims found unsupported while checking evidence (reported as 04-T2 item 6 failures, not part of the deterministic sample):
| file:line | claim | source opened | result |
|---|---|---|---|
| docs/PREFLIGHT.md:105 | One-time prompts (WebFetch, subagent spawn, whoami, `git push --dry-run`) triggered with no dialog | docs/evidence/p00/preflight-config-orchestrator-20261001T135005.log (97 lines; started 13:50:05, before the 14:11 push dry run; contains only settings keys, MCP list, project settings) | UNRESOLVED |
| docs/PREFLIGHT.md:104 | `ansight` CLI not on PATH | docs/evidence/p00/preflight-pkg-orchestrator-20261001T135005.log (no `ansight` string) | UNRESOLVED |
| docs/PREFLIGHT.md:96 | No browser tools in the tool list | docs/evidence/p00/preflight-config-orchestrator-20261001T135005.log (no `browser`/`chrome` string) | UNRESOLVED |
| docs/PREFLIGHT.md:37 | Hooks test: 24 checks, 0 failures | docs/evidence/p00/hooks-orchestrator-20261001T134902.log (23 `[PASS]` lines, 0 `[FAIL]`) | UNRESOLVED |
| docs/PREFLIGHT.md:27 | `AskUserQuestion` absent from the tool list | docs/evidence/p00/hooks-orchestrator-20261001T134902.log:5 shows only the deny-rule count, not the tool list | UNRESOLVED |

<!-- END OF FILE -->
