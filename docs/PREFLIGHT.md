RUN-SURVIVAL: AT RISK (automatic continue at usage limit not readable from settings — UA-005; free disk 13 GB below 50 GB — UA-001; one optional software update pending — UA-006) · sleep prevention OK · claude.ai subscription login OK · Figma sign-in OK · permission mode bypassPermissions OK

# PREFLIGHT — Phase 0.1 (planning run, session 1)
Written: 2026-10-01T13:56:00+1000 · Orchestrator: main Claude Code session · Statuses: OK / MISSING / UNVERIFIABLE. Anything MISSING is also a `B-` entry and, where only Devesh can fix it, a `UA-` entry. The run did not stop for any row (none is an E4 cause).

## 1. Working directory and inputs
| Capability | Status | Evidence | Fix in plain English |
|---|---|---|---|
| Absolute path `/Users/deveshramanan/ADHD Slayer`, not under Desktop, Documents, Downloads or iCloud Drive | OK | [EV: docs/evidence/p00/preflight-env-orchestrator-20261001T135000.log] | N/A (nothing to fix) |
| `prompts/` present with 01–06, `figma_design_prompt.md`, `figma_urls.md`, `SOURCE_MAP.md` | OK | [EV: docs/evidence/p00/preflight-env-orchestrator-20261001T135000.log] | N/A (nothing to fix) |
| `research/` present (7 Markdown files and the design-document PDF) | OK | [EV: docs/evidence/p00/source-inventory-orchestrator-20261001T135339.log] | N/A (nothing to fix) |
| `docs/design/` (K.2 design-session outputs) | MISSING | [EV: docs/evidence/p00/preflight-env-orchestrator-20261001T135000.log] | None needed: substitutes per `prompts/SOURCE_MAP.md` are used (B-001) |
| Root `SPEC_CHECKLIST.md` | MISSING | [EV: docs/evidence/p00/preflight-env-orchestrator-20261001T135000.log] | None needed (B-001); Phase 0.16 creates a new checklist |
| `.git` present; `origin` = private GitHub repository `DeveshRamanan-collab/ADHD-Slayer` | OK | [EV: docs/evidence/p00/preflight-git-orchestrator-20261001T135000.log] | N/A (nothing to fix) |
| Existing Xcode project `app/FocusApp/FocusApp.xcodeproj` and Swift package `app/FocusCore/Package.swift` (pre-existing prototype, read-only input, D-003) | OK | [EV: docs/evidence/p00/preflight-env-orchestrator-20261001T135000.log] | N/A (nothing to fix) |
| Source inventory written to `docs/SOURCE_INVENTORY.md` with SHA-256 per file | OK | [EV: docs/evidence/p00/source-inventory-orchestrator-20261001T135339.log] | N/A (nothing to fix) |

## 2. Harness, login and continuation
| Capability | Status | Evidence | Fix in plain English |
|---|---|---|---|
| Claude Code version `2.1.286 (Claude Code)` | OK | [EV: docs/evidence/p00/preflight-env-orchestrator-20261001T135000.log] | N/A (nothing to fix) |
| Permission mode `bypassPermissions` (34 transcript entries, no other mode) | OK | [EV: docs/evidence/p00/permission-mode-orchestrator-20261001T135513.log] | N/A (nothing to fix) |
| `ANTHROPIC_API_KEY` unset | OK | [EV: docs/evidence/p00/preflight-env-orchestrator-20261001T135000.log] | N/A (nothing to fix) |
| Login: claude.ai account with `billingType` `stripe_subscription` (no credentials recorded) | OK | [EV: docs/evidence/p00/login-type-orchestrator-20261001T135518.log] | N/A (nothing to fix) |
| Automatic wait-and-continue at usage limit exists from v2.1.234 (installed 2.1.286), per code.claude.com costs page, verified 2026-10-01 | OK | [EV: docs/evidence/sources/FACT-cc-autocontinue.md] | N/A (nothing to fix) |
| Whether automatic continue is switched on for this account | UNVERIFIABLE | [EV: docs/evidence/p00/preflight-config-orchestrator-20261001T135005.log] | UA-005: check `/config` |
| `AskUserQuestion` absent from the tool list after `.claude/settings.json` was written (deny rule picked up by the file watcher) | OK | [EV: docs/evidence/p00/hooks-orchestrator-20261001T134902.log] | N/A (nothing to fix) |
| Agent teams (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`) unset — ordinary subagents are used | OK | [EV: docs/evidence/p00/preflight-env-orchestrator-20261001T135000.log] | N/A (not required) |
| Model in use `claude-opus-5-5` (session header; not changed) | OK | [EV: docs/evidence/p00/permission-mode-orchestrator-20261001T135513.log] | N/A (nothing to fix) |

## 3. Claude Code configuration (names only; full discovery in docs/TOOL_CAPABILITY_AUDIT.md)
| Capability | Status | Evidence | Fix in plain English |
|---|---|---|---|
| User settings keys: `agentPushNotifEnabled`, `enableWorkflows`, `inputNeededNotifEnabled`, `skipDangerousModePermissionPrompt`, `theme`, `tui`; no user hooks | OK | [EV: docs/evidence/p00/preflight-config-orchestrator-20261001T135005.log] | N/A (nothing to fix) |
| Project settings `.claude/settings.json`: 23 deny rules, 9 hook events | OK | [EV: docs/evidence/p00/preflight-config-orchestrator-20261001T135005.log] | N/A (nothing to fix) |
| MCP servers listed by `claude mcp list` (connected, needs-auth and failed states recorded) | OK | [EV: docs/evidence/p00/preflight-config-orchestrator-20261001T135005.log] | N/A (nothing to fix) |
| Hooks installed and every hook script exercised with fixtures (24 checks, 0 failures) | OK | [EV: docs/evidence/p00/hooks-orchestrator-20261001T134902.log] | N/A (nothing to fix) |

## 4. Figma MCP
| Capability | Status | Evidence | Fix in plain English |
|---|---|---|---|
| `whoami`: handle Devesh, team `team::1686304428269511457` "ramanan.devesh's team", seat View, tier student (expected per K.1) | OK | [EV: docs/evidence/p00/figma-tools/whoami-orchestrator-20261001T135040.md] | N/A (nothing to fix) |
| Transport: claude.ai connector, remote `https://mcp.figma.com/mcp` (no desktop app needed) | OK | [EV: docs/evidence/p00/preflight-config-orchestrator-20261001T135005.log] | N/A (nothing to fix) |
| Provisional design file key `gLuoHFbiiUGajAUpluWXOW` (prompts/figma_urls.md); one root `get_metadata` read tagged lock-check, ledgered (row 1) and cached by the hooks | OK | [EV: docs/evidence/p00/figma-tools/get_metadata-root-orchestrator-20261001T135045.md] | N/A (nothing to fix) |
| Rate limits page: Education plans 200 tool calls per day, 10 per minute; exempt `add_code_connect_map`, `create_new_file`, `whoami`, verified 2026-10-01 | OK | [EV: docs/evidence/sources/FACT-figma-rate-limits.md] | N/A (nothing to fix) |
| REST route (`FIGMA_TOKEN`) | MISSING | [EV: docs/evidence/p00/preflight-env-orchestrator-20261001T135000.log] | Optional — UA-007; B-005 |
| FigJam flows board | MISSING | [EV: docs/evidence/p00/preflight-env-orchestrator-20261001T135000.log] | None needed (B-004) |

## 5. Git and GitHub
| Capability | Status | Evidence | Fix in plain English |
|---|---|---|---|
| `git version 2.54.0 (Apple Git-157)`; `user.name` and `user.email` already set | OK | [EV: docs/evidence/p00/preflight-git-orchestrator-20261001T135000.log] | N/A (nothing to fix) |
| `gh version 2.102.0`; logged in as `DeveshRamanan-collab`; token scopes include `repo` (token masked) | OK | [EV: docs/evidence/p00/preflight-git-orchestrator-20261001T135000.log] | N/A (nothing to fix) |
| `git push --dry-run` after the Phase 0 commit | OK | [EV: docs/evidence/p00/push-dry-run-orchestrator-20261001T141127.log] | N/A (nothing to fix) |

## 6. Apple toolchain
| Capability | Status | Evidence | Fix in plain English |
|---|---|---|---|
| `xcode-select -p` = `/Applications/Xcode.app/Contents/Developer` | OK | [EV: docs/evidence/p00/preflight-apple-orchestrator-20261001T135002.log] | N/A (nothing to fix) |
| `Xcode 27.0` build `27A266a` (≥ 26.5; preferred major); `XCODE_MAJOR` = 27 → Device Hub vocabulary | OK | [EV: docs/evidence/p00/preflight-apple-orchestrator-20261001T135002.log] | N/A (nothing to fix) |
| `xcodebuild -checkFirstLaunchStatus` exit 0 (no licence or first-launch prompt) | OK | [EV: docs/evidence/p00/preflight-apple-orchestrator-20261001T135002.log] | N/A (nothing to fix) |
| SDKs iOS 27.0, iOS Simulator 27.0, watchOS 27.0, watchOS Simulator 27.0 | OK | [EV: docs/evidence/p00/preflight-apple-orchestrator-20261001T135002.log] | N/A (nothing to fix) |
| `Apple Swift version 6.4`; macOS 27.2 (build 26B5091g) | OK | [EV: docs/evidence/p00/preflight-apple-orchestrator-20261001T135002.log] | N/A (nothing to fix) |
| Free disk ≥ 50 GB (13 GB available) | MISSING | [EV: docs/evidence/p00/preflight-apple-orchestrator-20261001T135002.log] | UA-001 (B-002) |
| AC power; `PreventUserIdleSystemSleep` held by `caffeinate` on behalf of claude | OK | [EV: docs/evidence/p00/preflight-apple-orchestrator-20261001T135002.log] | N/A (nothing to fix) |
| No pending macOS or Xcode update (one optional "Pro Video Formats 3.2" pending) | OK | [EV: docs/evidence/p00/preflight-swupdate-orchestrator-20261001T135104.log] | UA-006 (keep automatic installs off) |
| Simulator runtimes Ready: iOS 26.5, iOS 27.0, watchOS 27.0 | OK | [EV: docs/evidence/p00/preflight-sims-orchestrator-20261001T135104.log] | N/A (nothing to fix) |
| iPhone Pro-class simulator (iPhone 17 Pro) and paired Watch simulators (Series 12 46 mm, Series 12 42 mm, Ultra 4) | OK | [EV: docs/evidence/p00/preflight-sims-orchestrator-20261001T135104.log] | N/A (nothing to fix) |
| Code-signing identity "Apple Development" with team W8V95U7AXJ (paid or Personal Team not readable) | UNVERIFIABLE | [EV: docs/evidence/p00/preflight-apple-orchestrator-20261001T135002.log] | UA-002 |
| Physical iPhone and Apple Watch visible to `xcrun devicectl` | MISSING | [EV: docs/evidence/p00/preflight-devices-orchestrator-20261001T135104.log] | UA-003; B-006 |

## 7. Xcode MCP server
| Capability | Status | Evidence | Fix in plain English |
|---|---|---|---|
| Apple Xcode MCP added (`claude mcp add --transport stdio xcode -- xcrun mcpbridge`, local scope) and connected | OK | [EV: docs/evidence/p00/xcode-mcp-get-orchestrator-20261001T135307.log] | N/A (nothing to fix) |
| `xcrun mcp-server status`: Permission enabled, server not running (starts on demand) | OK | [EV: docs/evidence/p00/preflight-devices-orchestrator-20261001T135104.log] | N/A (nothing to fix) |

## 8. Package managers and planning tooling
| Capability | Status | Evidence | Fix in plain English |
|---|---|---|---|
| Homebrew 7.0.7, npm 11.13.0, node v24.16.0, Python 3.9.6, `jq-1.7.1-apple` | OK | [EV: docs/evidence/p00/preflight-pkg-orchestrator-20261001T135005.log] | N/A (nothing to fix) |
| `xcodegen`, `swiftlint`, `swiftformat` not installed (build-phase tasks; not installed now) | MISSING | [EV: docs/evidence/p00/preflight-pkg-orchestrator-20261001T135005.log] | None now: installed in MS-00 by TASK rows; B-007 |

## 9. Web research routes (one fetch each, saved with scripts/fetch_excerpt.py)
| Route | Status | Evidence | Fix in plain English |
|---|---|---|---|
| developer.apple.com HTML page (JavaScript-rendered; no body text) — JSON route `developer.apple.com/tutorials/data/documentation/<path>.json` returns the text | OK | [EV: docs/evidence/sources/FACT-route-apple-json.md] | N/A (JSON route adopted) |
| App Store Review Guidelines (text contains `1.4.2`) | OK | [EV: docs/evidence/sources/FACT-route-asrg.md] | N/A (nothing to fix) |
| legislation.gov.au (HTTP 200; page chrome only through urllib — WebFetch or the austlii fallback used for section text in Phase 11) | OK | [EV: docs/evidence/sources/FACT-route-legislation.md] | N/A (nothing to fix) |
| austlii.edu.au (HTTP 403 to scripted fetch) | UNVERIFIABLE | [EV: docs/evidence/sources/FACT-route-austlii.md] | None (B-003) |
| oaic.gov.au (HTTP 200, phrase found) | OK | [EV: docs/evidence/sources/FACT-route-oaic.md] | N/A (nothing to fix) |
| tga.gov.au (HTTP 404 for the guessed path; WebFetch timeout) | UNVERIFIABLE | [EV: docs/evidence/sources/FACT-route-tga.md] | None (B-003) |
| accc.gov.au (HTTP 403) | UNVERIFIABLE | [EV: docs/evidence/sources/FACT-route-accc.md] | None (B-003) |
| code.claude.com docs (HTTP 200) | OK | [EV: docs/evidence/sources/FACT-route-claude-docs.md] | N/A (nothing to fix) |
| developers.figma.com (HTTP 200) | OK | [EV: docs/evidence/sources/FACT-figma-rate-limits.md] | N/A (nothing to fix) |
| Claude in Chrome / built-in browser: not connected in this session (no browser tools in the tool list) | MISSING | [EV: docs/evidence/p00/preflight-config-orchestrator-20261001T135005.log] | None needed; B-008 |

## 10. Subagents, connectors and one-time prompts
| Capability | Status | Evidence | Fix in plain English |
|---|---|---|---|
| One trivial subagent spawned and returned `SUBAGENT-OK` | OK | [EV: docs/evidence/p00/subagent-probe-orchestrator-20261001T135318.md] | N/A (nothing to fix) |
| Claude Docs connector "claude.ai Claude Docs" connected (main design document read attempted in Phase 2) | OK | [EV: docs/evidence/p00/preflight-config-orchestrator-20261001T135005.log] | N/A (nothing to fix) |
| GitHub MCP (`plugin:engineering:github`) failed to connect; `gh` CLI is the GitHub route | MISSING | [EV: docs/evidence/p00/preflight-config-orchestrator-20261001T135005.log] | None needed; B-009 |
| iOS runtime verification tool `ansight`: CLI not on PATH | MISSING | [EV: docs/evidence/p00/preflight-pkg-orchestrator-20261001T135005.log] | None needed (Xcode MCP and XCUITest are primary); B-010 |
| One-time prompts deliberately triggered (read of `~/.claude/settings.json` keys, WebFetch of new domains, subagent spawn, Figma `whoami`, `git push --dry-run`): no dialog appeared | OK | [EV: docs/evidence/p00/preflight-config-orchestrator-20261001T135005.log] | N/A (nothing to fix) |

## 11. Things only Devesh can do (status as observed)
| Item | Status | Evidence | Fix in plain English |
|---|---|---|---|
| Apple Account signed into Xcode with a development identity | OK | [EV: docs/evidence/p00/preflight-apple-orchestrator-20261001T135002.log] | N/A (nothing to fix) |
| Apple Developer Program membership type | UNVERIFIABLE | [EV: docs/evidence/p00/preflight-apple-orchestrator-20261001T135002.log] | UA-002 (needed by MS-11) |
| iPhone and Watch paired, trusted, Developer Mode on | MISSING | [EV: docs/evidence/p00/preflight-devices-orchestrator-20261001T135104.log] | UA-003 (needed by MS-05); B-006 |
| One prior signed Run to the device (keychain "Always Allow") | UNVERIFIABLE | [EV: docs/evidence/p00/preflight-devices-orchestrator-20261001T135104.log] | Covered by UA-003 |
| App Store Connect agreements accepted | UNVERIFIABLE | [EV: docs/evidence/p00/preflight-git-orchestrator-20261001T135000.log] | UA-004 (needed by MS-11) |
| Usage-credits decision (`hasExtraUsageEnabled` key exists; value not recorded) | UNVERIFIABLE | [EV: docs/evidence/p00/login-type-orchestrator-20261001T135518.log] | Devesh decides billing; nothing to do for this run |
| Figma sign-in valid | OK | [EV: docs/evidence/p00/figma-tools/whoami-orchestrator-20261001T135040.md] | N/A (nothing to fix) |

<!-- END OF FILE -->
