# FACT REGISTER — every cross-document fact (F6)
Read `docs/AGENT_RULES.md` before any work; its rules bind you. Started in Phase 0 (G0 loop 2); completed in Phase 13. Columns read by `scripts/check_facts.py`: id, key, canonical value, owning document, synonyms. The last column names the evidence.

| FACT | Key | Canonical value | Owning document | Synonyms | Evidence |
|---|---|---|---|---|---|
| **FACT-001** | Figma daily read limit | 200 | docs/figma/TOOL_COVERAGE.md | Education read limit per day | [EV: docs/evidence/sources/FACT-figma-rate-limits.md] |
| **FACT-002** | Figma per-minute read limit | 10 | docs/figma/TOOL_COVERAGE.md | Education read limit per minute | [EV: docs/evidence/sources/FACT-figma-rate-limits.md] |
| **FACT-003** | Figma rate-limit exempt tools | add_code_connect_map, create_new_file, whoami | docs/figma/TOOL_COVERAGE.md | exempt tools | [EV: docs/evidence/sources/FACT-figma-rate-limits.md] |
| **FACT-004** | run read cap | 150 | docs/figma/TOOL_COVERAGE.md | read cap per rolling 24 h | docs/AGENT_RULES.md C-9 (run rule, not a Figma figure) |
| **FACT-005** | Figma design file key | gLuoHFbiiUGajAUpluWXOW | docs/figma/TOOL_COVERAGE.md | design file key | [EV: docs/evidence/p00/figma-key-discovery-orchestrator-20261001T141201.log] |
| **FACT-006** | Figma tool index | developers.figma.com tools-and-prompts page lists the read tools used | docs/figma/TOOL_COVERAGE.md | Figma tool list | [EV: docs/evidence/sources/FACT-figma-tools.md] |
| **FACT-007** | Claude Code installed version | 2.1.286 | docs/PREFLIGHT.md | claude --version | [EV: docs/evidence/p00/preflight-env-orchestrator-20261001T135000.log] |
| **FACT-008** | automatic continue minimum version | 2.1.234 | docs/PREFLIGHT.md | wait-and-continue minimum | [EV: docs/evidence/sources/FACT-cc-autocontinue.md] |
| **FACT-009** | hook events used | SessionStart, PreCompact, Stop, StopFailure, PreToolUse, PostToolUse, PostToolUseFailure, Elicitation, SubagentStop | docs/PREFLIGHT.md | hook event names | [EV: docs/evidence/sources/FACT-hooks-events.md] |
| **FACT-010** | legislation.gov.au route | HTTP 200 | docs/PREFLIGHT.md | legislation route | [EV: docs/evidence/sources/FACT-route-legislation.md] |
| **FACT-011** | oaic.gov.au route | HTTP 200 | docs/PREFLIGHT.md | OAIC route | [EV: docs/evidence/sources/FACT-route-oaic.md] |
| **FACT-012** | tga.gov.au route | refused (404 scripted) | docs/PREFLIGHT.md | TGA route | [EV: docs/evidence/sources/FACT-route-tga.md] |
| **FACT-013** | accc.gov.au route | refused (403) | docs/PREFLIGHT.md | ACCC route | [EV: docs/evidence/sources/FACT-route-accc.md] |
| **FACT-014** | austlii.edu.au route | refused (403) | docs/PREFLIGHT.md | AustLII route | [EV: docs/evidence/sources/FACT-route-austlii.md] |
| **FACT-015** | Apple documentation route | JSON route developer.apple.com/tutorials/data/documentation | docs/PREFLIGHT.md | Apple docs JSON route | [EV: docs/evidence/sources/FACT-route-apple-json.md] |
| **FACT-016** | App Store Review Guidelines route | HTTP 200 with section 1.4.2 text | docs/PREFLIGHT.md | ASRG route | [EV: docs/evidence/sources/FACT-route-asrg.md] |
| **FACT-017** | code.claude.com route | HTTP 200 | docs/PREFLIGHT.md | Claude Code docs route | [EV: docs/evidence/sources/FACT-route-claude-docs.md] |
| **FACT-018** | product working name | Focus | docs/DECISION_LOG.md | working name | D-007 |
| **FACT-019** | GitHub repository | DeveshRamanan-collab/ADHD-Slayer (private) | docs/DECISION_LOG.md | repository name | D-007 |
| **FACT-020** | bundle identifier prefix | au.adhdslayer.focus | docs/DECISION_LOG.md | bundle prefix | D-007 |

<!-- END OF FILE -->
