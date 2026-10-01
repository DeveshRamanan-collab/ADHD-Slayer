review: R-G0-2
Claim sample per 04-T2 item 5 (Gate G0, loop 2 of 3), PREFLIGHT only, from `python3 scripts/claims.py docs/PREFLIGHT.md --sample` run 2026-10-01T16:24:14+1000 [EV: docs/evidence/p00/review-claims-PREFLIGHT-R-G0-2-20261001T162414.log]. 16 claims, step 2, 8 sampled. Each source was opened again in this loop; nothing was carried over from R-G0-1.

| file:line | claim | source opened | result |
|---|---|---|---|
| docs/PREFLIGHT.md:4 | Every MISSING row is also a `B-` entry | 11 MISSING rows in docs/PREFLIGHT.md (12, 13, 46, 47, 64, 70, 82, 96, 103, 104, 112); 0 without a B- id; ids used B-001, B-002, B-004 to B-010; all are headings in docs/BLOCKERS.md (B-001 to B-010) | RESOLVED |
| docs/PREFLIGHT.md:21 | Claude Code version `2.1.286 (Claude Code)` | docs/evidence/p00/preflight-env-orchestrator-20261001T135000.log:24 | RESOLVED |
| docs/PREFLIGHT.md:43 | Figma transport is the claude.ai connector at `https://mcp.figma.com/mcp` | docs/evidence/p00/preflight-config-orchestrator-20261001T135005.log:33 ("claude.ai Figma: https://mcp.figma.com/mcp - Connected") | RESOLVED |
| docs/PREFLIGHT.md:52 | `git version 2.54.0 (Apple Git-157)`; user.name and user.email set | docs/evidence/p00/preflight-git-orchestrator-20261001T135000.log:7,25,26 | RESOLVED |
| docs/PREFLIGHT.md:60 | Xcode 27.0 build 27A266a | docs/evidence/p00/preflight-apple-orchestrator-20261001T135002.log:10-11 | RESOLVED |
| docs/PREFLIGHT.md:63 | Apple Swift version 6.4; macOS 27.2 build 26B5091g | docs/evidence/p00/preflight-apple-orchestrator-20261001T135002.log:50,55,56 | RESOLVED |
| docs/PREFLIGHT.md:67 | Simulator runtimes iOS 26.5, iOS 27.0, watchOS 27.0 | docs/evidence/p00/preflight-sims-orchestrator-20261001T135104.log:8-10 | RESOLVED |
| docs/PREFLIGHT.md:88 | App Store Review Guidelines text contains `1.4.2` | docs/evidence/sources/FACT-route-asrg.md:6-7,10 (phrase 1.4.2, found True, excerpt quotes guideline 1.4.2) | RESOLVED |

Sampled 8 of 16 · RESOLVED 8 · UNRESOLVED 0.

Claims outside the sample that I checked while re-checking the loop-1 failures (04-T2 item 6; not part of the deterministic sample):
| file:line | claim | source opened | result |
|---|---|---|---|
| docs/PREFLIGHT.md:27 | `AskUserQuestion` absent from the tool list | docs/evidence/p00/session-tool-list-orchestrator-20261001T162108.md:7. This is the orchestrator's own transcription of its tool list. My own session's tool and deferred-tool lists also have no AskUserQuestion | RESOLVED |
| docs/PREFLIGHT.md:37 | Hooks test: 28 checks, 0 failures | docs/evidence/p00/hooks-orchestrator-20261001T161219.log (28 `[PASS]`, 0 `[FAIL]`, "TOTAL FAILS: 0") | RESOLVED |
| docs/PREFLIGHT.md:96 | No browser tools in the tool list | docs/evidence/p00/session-tool-list-orchestrator-20261001T162108.md:8. My own session has no chrome/browser tools either | RESOLVED |
| docs/PREFLIGHT.md:104 | `ansight` CLI not on PATH | docs/evidence/p00/ansight-presence-orchestrator-20261001T162100.log:5 | RESOLVED |
| docs/PREFLIGHT.md:105 | One-time prompts: settings read, WebFetch of new domains, subagent spawn, whoami, push dry run produced no dialog | Settings, subagent, whoami and push dry run (…T161534.log, after commit 558feb3 at 16:15:33) all have evidence. The WebFetch part cites only docs/evidence/p00/websearch-probe-orchestrator-20261001T140000.md, which records a WebSearch call, not WebFetch; no file under docs/evidence contains a WebFetch call record | UNRESOLVED (WebFetch part) |
| docs/PREFLIGHT.md:54 | `git push --dry-run` after the Phase 0 commit | docs/evidence/p00/push-dry-run-orchestrator-20261001T141127.log:6 pushes `828a14f..84e8771`; Phase 0 commit 558feb3 is dated 16:15:33, so this dry run came before it. The later docs/evidence/p00/push-dry-run-orchestrator-20261001T161534.log (`84e8771..07651e4`) does support the claim but is not cited here | UNRESOLVED |
| docs/FACT_REGISTER.md:9 | FACT-004 run read cap 150, evidence FACT-figma-rate-limits.md | docs/evidence/sources/FACT-figma-rate-limits.md has no "150" (the cap is the run's own C-9 rule, not a Figma figure) | UNRESOLVED (wrong evidence cited; value correct per C-9) |

<!-- END OF FILE -->
