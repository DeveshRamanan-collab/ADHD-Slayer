# TOOL STRATEGY — Phase 0.12 (division of labour, multi-agent operating plan, file ownership)
Written: 2026-10-01T14:08:00+1000 · Source of capabilities: docs/TOOL_CAPABILITY_AUDIT.md (only items with harmless-call evidence are named as PRIMARY, SECONDARY or REVIEW). Tools do not dictate architecture (0.14).

## 1. Division of labour
| Area | Primary | Supporting | Independent review |
|---|---|---|---|
| Product and Figma audit | Orchestrator as the designated Figma reader (claude.ai Figma MCP read tools, hooks cache and ledger every read) | general-purpose analysts per page, from the cache only | Fresh general-purpose reviewer per page analysis (04-T2) plus scripts/validate_analysis.py and scripts/figma_reconcile.py |
| Architecture | Orchestrator plus general-purpose author for docs/ARCHITECTURE.md | feature-dev:code-architect (second opinion) | backend-design:boring-tech-advisor writes every `CHALLENGED:` line; agent-protocols:security-auditor; securitymaxxing threat-model lens |
| Implementation (build phase) | general-purpose implementers following the superpowers spine (D-006) | swift-lsp, liquid-glass, figma:figma-swiftui, Xcode MCP | review-council reviewers; verifier ≠ implementer |
| Git | Orchestrator only (`git`, `gh` CLI) | none | review-council reviews each milestone diff before merge (build) |
| Independent code review (build) | review-council (correctness, security, architecture, interface, test-evidence, policy-boundary) | pr-review-toolkit (silent-failure-hunter, type-design-analyzer), feature-dev:code-reviewer | Orchestrator spot-check |
| Runtime verification (build) | Xcode MCP (BuildProject, RunAllTests, RenderPreview, DeviceInteraction tools) | XCUITest + `xcrun simctl` with explicit UDIDs | Verifier subagent, never the implementer |
| Legal and privacy research | general-purpose researchers per topic using scripts/fetch_excerpt.py on legislation.gov.au and oaic.gov.au; WebFetch fallback saved with `--text-file`; WebSearch only to locate primary sources | privacy-legal (PIA structure), product-legal (feature risk, marketing claims) | agentic-council:council-guardian lens plus fresh reviewer with claim sampling |
| Apple platform research | general-purpose researchers per framework using the Apple documentation JSON route | Xcode MCP DocumentationSearch cross-check | Fresh reviewer opens every `IOS-` excerpt (G3 item 4) |
| Drift detection | spec-drift (init in Phase 0.16, report at G4 and Phase 25) | scripts/validate_docs.py, scripts/trace.py, scripts/check_facts.py | Phase 25 fresh auditors |

## 1a. Stage table (0.4; same rows as docs/TOOL_CAPABILITY_AUDIT.md § 0.4, every row names at least one capability classified in the audit)
| Stage | Primary capability | Supporting / reviewer |
|---|---|---|
| Inspect Figma | claude.ai Figma MCP read tools (orchestrator as single reader) | general-purpose analysts working from the cache |
| Extract design system | Figma `get_variable_defs` and `get_design_context` cache | figma plugin (figma-swiftui), liquid-glass; design:design-system as reviewer |
| Audit interactions | Figma metadata and design-context cache; `get_motion_context` | general-purpose analysts; Phase 3 inferred-route rules |
| Research Apple API feasibility | Apple documentation JSON route (scripts/fetch_excerpt.py) | Xcode MCP DocumentationSearch; WebSearch as locator |
| Define architecture | orchestrator reasoning plus general-purpose authors | backend-design:boring-tech-advisor, feature-dev:code-architect, agent-protocols:security-auditor |
| Write Swift | general-purpose implementers under the superpowers spine (build phase) | swift-lsp, liquid-glass, figma-swiftui |
| Build engine tests | `swift test` (Swift Testing) via scripts/run_logged.sh | agent-protocols:test-engineer as reviewer |
| Run Xcode builds | Xcode MCP BuildProject / RunAllTests | `xcodebuild` + `xcrun xcresulttool` (Route B) |
| Runtime verification on Simulator/device | Xcode MCP DeviceInteraction and RenderPreview | XCUITest + `xcrun simctl` |
| Git operations | `git` and `gh` CLI (orchestrator only) | none |
| Review diffs | review-council (6 read-only reviewers) | pr-review-toolkit, feature-dev:code-reviewer |
| Security audit | securitymaxxing (threat-model, secrets, ship-check) | agent-protocols:security-auditor, review-council:security-reviewer |
| Privacy/legal research | scripts/fetch_excerpt.py on legislation.gov.au and oaic.gov.au; WebFetch fallback | privacy-legal, product-legal, agentic-council:council-guardian |
| Accessibility review | design:accessibility-review | agent-protocols:accessibility-specialist |
| Drift detection | spec-drift (init, check, report) | scripts/validate_docs.py, scripts/trace.py |
| TestFlight preparation | Devesh in App Store Connect (UA-004) with docs/RELEASE_CHECKLIST.md | agent-protocols:release-engineer, wai-suite:wai-mobile-release |

## 2. Multi-agent operating plan
- **Orchestrator** (main session): owns the plan, docs/MANIFEST.md, docs/figma/.intent, every shared state file, merges (scripts/assemble_docs.py or file moves only), gates and Git. Writes briefs from 04-T1 and reviews from 04-T2.
- **Designated Figma reader:** the orchestrator. No subagent calls a Figma tool (C-9). Analysts receive cache paths.
- **Fan-outs (independent, parallel, most reasoning-heavy first per OM-7.9):** Phase 2 source notes per source group; Phase 3 per-page analysis; Phase 11 per legal topic; Phase 12 per Apple framework group; Phases 6–24 per document part under docs/parts/<DOC>/; per-document reviews.
- **Sequential chain:** inventory (Phase 4) → reconciliation (5) → spec (6) → data model (7) → architecture (8) → engines (9) → test plan (10) → plans (14–18).
- **Agent types:** general-purpose for authors, analysts and researchers; fresh general-purpose for reviewers that must run scripts; review-council and agent-protocols agents for read-only lens reviews; Explore for broad read-only sweeps. Agent teams are not enabled (docs/PREFLIGHT.md § 2), so none are used. The Workflow tool is not used (D-006).
- **Model policy:** subagents inherit the session model (`claude-opus-5-5`); trivial probes may use a smaller model. Models are never switched to avoid a usage limit (OM-7.7).
- **Gates:** `scripts/gate.py Gn` runs the mechanical items; a fresh reviewer that authored none of the gated documents completes the REVIEWER rows and samples claims; up to 3 loops; residuals per 04-T3.
- **Spot-checks:** before any merge the orchestrator runs scripts/validate_docs.py (or scripts/validate_analysis.py) and the deterministic claim sample (scripts/claims.py --sample) and logs `docs/evidence/<phase>/spotcheck-<brief-id>-<agent-id>-<ISO-compact>.log`.

## 3. Reviewer per document
| Document | Reviewer capability |
|---|---|
| docs/figma/analysis/<page>.md, docs/FIGMA_AUDIT.md | Fresh general-purpose reviewer (opens cache files for sampled node ids) |
| docs/SOURCE_NOTES.md, docs/RECONCILIATION.md, docs/CHANGELOG_FROM_ORIGINAL_SPEC.md, docs/PROPOSALS.md | agent-protocols:spec-analyst plus fresh reviewer for claim sampling |
| docs/PRODUCT_SPEC.md | agent-protocols:spec-analyst |
| docs/DATA_MODEL.md, docs/RESERVED_NAMES.md | backend-design:schema-reviewer and pr-review-toolkit:type-design-analyzer |
| docs/ARCHITECTURE.md | backend-design:boring-tech-advisor (CHALLENGED lines) and agent-protocols:security-auditor |
| docs/ENGINE_SPEC.md, docs/PERSONALISATION_DESIGN.md | Fresh general-purpose reviewer with the red-line construction attempt (RL-1) and agentic-council:council-skeptic |
| docs/ENGINE_TEST_PLAN.md, docs/TESTING_STRATEGY.md, docs/FEATURE_VERIFICATION_CHECKLIST.md | agent-protocols:test-engineer |
| docs/LEGAL_PRIVACY_SAFETY.md | Fresh general-purpose reviewer (claim sampling on every LEGAL- line) and agentic-council:council-guardian |
| docs/COPY_REVIEW.md | design:ux-copy lens via a fresh reviewer plus scripts/copy_scan.py --replacements |
| docs/APPLE_PLATFORM_PLAN.md | Fresh general-purpose reviewer opening every IOS- excerpt; agentic-council:council-pathfinder lens |
| docs/FIGMA_IMPLEMENTATION_MAP.md, docs/DESIGN_SYSTEM.md | agent-protocols:accessibility-specialist and agentic-council:council-artisan |
| docs/GIT_WORKFLOW.md, docs/IMPLEMENTATION_PLAN.md, docs/TASKS.md, docs/TRACEABILITY_MATRIX.md | Plan agent (read-only) plus scripts/check_tasks.py and scripts/trace.py |
| docs/FAILURE_MODES.md | agentic-council:council-skeptic and backend-design:incident-thinker |
| docs/CLAUDE_CODE_INSTRUCTIONS.md, CLAUDE.md | review-council:policy-boundary-reviewer and claude-md-management:claude-md-improver (report only) |
| docs/DEVESH_BUILD_GUIDE.md | Fresh beginner-test agent (Phase 25.9) |
| docs/RELEASE_CHECKLIST.md | agent-protocols:release-engineer |
| Phase 0 documents and every gate file | Fresh general-purpose gate reviewer |

## 4. File-ownership map (every docs/MANIFEST.md entry)
| Path | Writer (only this agent writes it) | Reviewer |
|---|---|---|
| docs/PREFLIGHT.md | orchestrator | G0 gate reviewer |
| docs/SOURCE_INVENTORY.md | orchestrator (scripts/source_inventory.py) | G0 gate reviewer |
| docs/TOOL_CAPABILITY_AUDIT.md | orchestrator (scripts/build_tool_audit.py) | G0 gate reviewer |
| docs/TOOL_STRATEGY.md | orchestrator | G0 gate reviewer |
| docs/AGENT_RULES.md | orchestrator (verbatim copy script) | gate.py REDLINE identity check |
| docs/MANIFEST.md | orchestrator | gate.py |
| docs/PROGRESS.md | orchestrator; hooks append log lines | gate.py counters |
| docs/DECISION_LOG.md | orchestrator (merges subagent decisions files) | gate reviewers |
| docs/BLOCKERS.md | orchestrator | gate reviewers |
| docs/USER_ACTIONS.md | orchestrator | Phase 22 reviewer |
| docs/OPEN_QUESTIONS.md | orchestrator | G4 reviewer |
| docs/WORK_QUEUE.md | orchestrator | none (bookkeeping) |
| docs/FIRST_REPORT.md | orchestrator | G0 gate reviewer |
| docs/gates/GATE-0.md | orchestrator from gate.py output and reviewer report | none (it is the review record) |
| CLAUDE.md | orchestrator | review-council:policy-boundary-reviewer |
| docs/FIGMA_VERSION_LOCK.md | orchestrator (scripts/figma_fingerprint.py) | G1 gate reviewer |
| docs/figma/FIGMA_STATE_REPORT.md | orchestrator | G1 gate reviewer |
| docs/figma/TOOL_COVERAGE.md | orchestrator | G1 gate reviewer |
| docs/figma/read-plan.md | orchestrator (scripts/figma_read_plan.py) | gate.py |
| docs/figma/id-ranges.md | orchestrator | gate.py |
| docs/SOURCE_NOTES.md | Phase 2 author subagents (parts), assembled by orchestrator | agent-protocols:spec-analyst |
| docs/figma/copy-scan.md | orchestrator (scripts/copy_scan.py) | G2 gate reviewer |
| docs/figma/text-layers.NOT-EXTRACTED.md | orchestrator (scripts/extract_text.py) | G1 gate reviewer |
| docs/figma/drug-names.md | orchestrator | Phase 11 copy reviewer |
| docs/figma/variables-observed.md | orchestrator | G1 gate reviewer |
| docs/figma/analysis/<page-slug>.md (one per page) | one Phase 3 analyst subagent per page | fresh per-page reviewer |
| docs/FIGMA_AUDIT.md | orchestrator (scripts/assemble_docs.py over the page analyses) | G1 gate reviewer |
| docs/gates/GATE-1.md | orchestrator | none (review record) |
| docs/RECONCILIATION.md | Phase 5 author subagent | agent-protocols:spec-analyst |
| docs/CHANGELOG_FROM_ORIGINAL_SPEC.md | Phase 5 author subagent | agent-protocols:spec-analyst |
| docs/PROPOSALS.md | Phase 5 author subagent | agent-protocols:spec-analyst |
| docs/gates/GATE-2.md | orchestrator | none (review record) |
| docs/PRODUCT_SPEC.md | Phase 6 author subagents (parts) | agent-protocols:spec-analyst |
| docs/DATA_MODEL.md | Phase 7 author subagent | backend-design:schema-reviewer |
| docs/RESERVED_NAMES.md | Phase 7 author subagent | scripts/check_names.py |
| docs/ARCHITECTURE.md | Phase 8 author subagent | backend-design:boring-tech-advisor |
| docs/ENGINE_SPEC.md | Phase 9 author subagents (one part per engine EN-1–EN-7) | fresh reviewer + council-skeptic |
| docs/PERSONALISATION_DESIGN.md | Phase 9 author subagent | fresh reviewer |
| docs/ENGINE_TEST_PLAN.md | Phase 10 author subagents (parts per engine) | agent-protocols:test-engineer |
| docs/LEGAL_PRIVACY_SAFETY.md | Phase 11 researcher subagents (parts per topic) | fresh reviewer + council-guardian |
| docs/COPY_REVIEW.md | Phase 11 copy author subagent | fresh reviewer + copy_scan.py --replacements |
| docs/APPLE_PLATFORM_PLAN.md | Phase 12 researcher subagents (parts per framework group) | fresh reviewer + council-pathfinder |
| docs/FIGMA_IMPLEMENTATION_MAP.md | Phase 13 author subagent | agent-protocols:accessibility-specialist |
| docs/DESIGN_SYSTEM.md | Phase 13 author subagent | council-artisan |
| docs/FACT_REGISTER.md | orchestrator | scripts/check_facts.py |
| docs/POC_REGISTER.md | orchestrator | G3 gate reviewer |
| docs/gates/GATE-3.md | orchestrator | none (review record) |
| docs/TESTING_STRATEGY.md | Phase 14 author subagent | agent-protocols:test-engineer |
| docs/FEATURE_VERIFICATION_CHECKLIST.md | Phase 14 author subagent | agent-protocols:test-engineer |
| docs/GIT_WORKFLOW.md | Phase 15 author subagent | Plan agent |
| docs/IMPLEMENTATION_PLAN.md | Phase 16 author subagent | Plan agent |
| docs/TASKS.md | Phase 17 author subagents (parts per milestone) | scripts/check_tasks.py + Plan agent |
| docs/TRACEABILITY_MATRIX.md | Phase 18 author subagent | scripts/trace.py |
| docs/FAILURE_MODES.md | Phase 19 author subagent | council-skeptic + incident-thinker |
| docs/CLAUDE_CODE_INSTRUCTIONS.md | Phase 20 author subagent | review-council:policy-boundary-reviewer |
| docs/DEVESH_BUILD_GUIDE.md | Phase 22 author subagent | beginner-test agent |
| docs/RELEASE_CHECKLIST.md | Phase 23 author subagent | agent-protocols:release-engineer |
| docs/gates/GATE-4.md | orchestrator | none (review record) |
| docs/gates/G5-checklist.md | orchestrator | none (input to auditors) |
| docs/COMPLETENESS_AUDIT.md | Phase 25 fresh auditor subagents (parts per item group) | orchestrator spot-check |
| docs/gates/GATE-5.md | orchestrator | none (review record) |
| docs/WHAT_I_DO_NEXT.md | orchestrator | G5 reviewer |

Two agents never own the same path; a subagent that needs a change elsewhere reports a PROPOSED CHANGE and the orchestrator applies it.

<!-- END OF FILE -->
