# TOOL CAPABILITY AUDIT — Phases 0.2–0.6
Generated: 2026-10-01T14:02:01+1000 by scripts/build_tool_audit.py from docs/evidence/p00/discovery-orchestrator-20261001T135656.log.
Items discovered: 160 · Tier A entries: 60 · Tier B rows: 100 · Tier A + Tier B = 160 (G0 check 2).
Harmless-call evidence for skills and agents = the installed definition file resolved and its frontmatter printed (read-only); for MCP servers = one read-only call. Nothing was uninstalled or reconfigured.

## Tier A — full entries

### general-purpose
- Name: `general-purpose` (discovery item `builtin-agent general-purpose`)
- Type: subagent type (native, all tools)
- What it can do for this project: Self-contained research, analysis and authoring briefs.
- When it is used: Every fan-out in Phases 2–25 (authors, analysts, researchers) and fresh reviewers
- What it must not be trusted to do automatically: Its own claims until the orchestrator's OM-3 sampling resolves them.
- Permissions/consequences: all tools within the brief's ownership
- Classification: PRIMARY — Default worker.
- Evidence: [EV: docs/evidence/p00/subagent-probe-orchestrator-20261001T135318.md]

### claude.ai Figma
- Name: `claude.ai Figma` (discovery item `mcp-server claude.ai Figma`)
- Type: MCP server (claude.ai connector, remote https://mcp.figma.com/mcp)
- What it can do for this project: Reads the Focus design file: page lists, node XML metadata, design context (reference code plus screenshot), variables, screenshots, motion keyframes, libraries, Code Connect map. Also exposes write tools that this run never calls.
- When it is used: Phases 0.7, 1, 3 (single reader: the orchestrator); build-phase lock checks before UI milestones
- What it must not be trusted to do automatically: Completeness of any single response (large frames truncate); prototype reactions; anything it does not return. Its write tools are blocked by scripts/hooks/figma_pre.sh.
- Permissions/consequences: read-only through the read tools; write tools would modify Figma (blocked); every read counts against 200/day
- Classification: PRIMARY — The only route to the design file; REST route absent (no FIGMA_TOKEN).
- Evidence: [EV: docs/evidence/p00/figma-tools/get_metadata-root-orchestrator-20261001T135045.md]

### xcode
- Name: `xcode` (discovery item `mcp-server xcode`)
- Type: MCP server (Apple xcode-tools via `xcrun mcpbridge`, stdio, local scope)
- What it can do for this project: 54 tools: BuildProject, RunAllTests, RunSomeTests, GetTestList, RenderPreview (preview snapshots), DeviceInteraction* (simulator/device driving), DocumentationSearch, AddEntitlement, AddInfoPlist, XcodeNewProject/XcodeNewTarget, build settings and String Catalog tools.
- When it is used: Phase 12 (DocumentationSearch for Apple API facts, compared with developer.apple.com JSON); build phase MS-00 onward (build, test, previews, simulator)
- What it must not be trusted to do automatically: Project-structure edits (XcodeWrite, XcodeRM, XcodeNewTarget) — the build uses XcodeGen and never hand-edits the project; documentation answers are compared with the Apple JSON route before citing.
- Permissions/consequences: builds, runs, edits project files (write tools used only in the build phase)
- Classification: PRIMARY — Apple's own server; preferred Route A in 0.8.
- Evidence: [EV: docs/evidence/p00/xcode-mcp-tools-orchestrator-20261001T135823.log]

### superpowers
- Name: `superpowers` (discovery item `plugin superpowers`)
- Type: plugin (skills: subagent-driven-development, using-git-worktrees, test-driven-development, verification-before-completion, executing-plans, dispatching-parallel-agents, systematic-debugging, writing-plans, brainstorming)
- What it can do for this project: A build workflow of planner → implementer subagents in worktrees → review → verification before completion, with TDD and debugging discipline; imposes no document set of its own.
- When it is used: Build phase spine (every milestone, D-006); planning phase uses dispatching-parallel-agents patterns for fan-outs
- What it must not be trusted to do automatically: Deciding scope or product behaviour; `brainstorming` asks the user questions and is not used unattended.
- Permissions/consequences: drives subagents that edit files and run commands
- Classification: PRIMARY — Chosen SDLC spine (0.6).
- Evidence: [EV: docs/evidence/p00/tierA-probe-orchestrator-20261001T135754.log]

### Explore
- Name: `Explore` (discovery item `builtin-agent Explore`)
- Type: subagent type (native, read-only)
- What it can do for this project: Broad read-only searches across files.
- When it is used: Source-note sweeps and reviewer look-ups
- What it must not be trusted to do automatically: Writing anything (it cannot).
- Permissions/consequences: read-only
- Classification: SECONDARY — Cheap fan-out searches.
- Evidence: [EV: docs/evidence/p00/discovery-orchestrator-20261001T135656.log]

### claude-code-guide
- Name: `claude-code-guide` (discovery item `builtin-agent claude-code-guide`)
- Type: subagent type (native)
- What it can do for this project: Answers Claude Code questions from its documentation.
- When it is used: Phase 20 cross-check of Claude Code features named in the handbook
- What it must not be trusted to do automatically: Facts without a fetched excerpt (F9).
- Permissions/consequences: read and web
- Classification: SECONDARY — Claude Code feature check.
- Evidence: [EV: docs/evidence/p00/discovery-orchestrator-20261001T135656.log]

### WebFetch
- Name: `WebFetch` (discovery item `builtin-tool WebFetch`)
- Type: native tool
- What it can do for this project: Fetches and summarises a URL with a small model.
- When it is used: Phases 11 and 12 when scripts/fetch_excerpt.py cannot read a page; the summary is saved with `--text-file`
- What it must not be trusted to do automatically: Verbatim quotation (it summarises) — excerpts must contain the phrase in the saved text.
- Permissions/consequences: external read
- Classification: SECONDARY — Fallback route.
- Evidence: [EV: docs/evidence/sources/FACT-hooks-events.md]

### WebSearch
- Name: `WebSearch` (discovery item `builtin-tool WebSearch`)
- Type: native tool
- What it can do for this project: Web search returning links.
- When it is used: Locating primary sources (0.11)
- What it must not be trusted to do automatically: Facts (snippets are not sources).
- Permissions/consequences: external read
- Classification: SECONDARY — Locator only.
- Evidence: [EV: docs/evidence/p00/websearch-probe-orchestrator-20261001T140000.md]

### claude.ai Claude Docs
- Name: `claude.ai Claude Docs` (discovery item `mcp-server claude.ai Claude Docs`)
- Type: MCP server (claude.ai connector)
- What it can do for this project: Reads and writes Claude Docs documents; the K.2 main design document is a Claude Docs or Artifact link.
- When it is used: Phase 2 (one read attempt of the main design document)
- What it must not be trusted to do automatically: Writing anything (no doc is created in this run); the PDF export in research/ is the fallback source.
- Permissions/consequences: read path only in this run; write tools exist
- Classification: SECONDARY — Only needed for one read; the PDF export covers the same content.
- Evidence: [EV: docs/evidence/p00/claude-docs-guide-orchestrator-20261001T135900.md]

### figma
- Name: `figma` (discovery item `plugin figma`)
- Type: plugin (skills: figma-design-to-code, figma-swiftui, figma-implement-motion, figma-use-motion, figma-code-connect and Figma write skills)
- What it can do for this project: Guidance for translating Figma nodes into SwiftUI and motion code; Code Connect mapping guidance.
- When it is used: Build phase MS-03 to MS-08 (UI); Phase 13 consults figma-swiftui for the implementation map vocabulary
- What it must not be trusted to do automatically: Writing to Figma (figma-use, figma-generate-* skills are never invoked; their tools are blocked).
- Permissions/consequences: read-only guidance; write skills would modify Figma
- Classification: SECONDARY — Design-to-code guidance supporting the PRIMARY Figma reads.
- Evidence: [EV: docs/evidence/p00/tierA-probe-orchestrator-20261001T135754.log]

### liquid-glass
- Name: `liquid-glass` (discovery item `plugin liquid-glass`)
- Type: plugin (skill)
- What it can do for this project: iOS 26+ Liquid Glass SwiftUI idioms (`glassEffect`, `GlassEffectContainer`).
- When it is used: Phase 13 (design-system mapping) and build MS-03
- What it must not be trusted to do automatically: API availability claims — each is re-sourced from Apple documentation (F9).
- Permissions/consequences: guidance only
- Classification: SECONDARY — Design-language idioms for the iOS 26 minimum.
- Evidence: [EV: docs/evidence/p00/tierA-probe-orchestrator-20261001T135754.log]

### privacy-legal
- Name: `privacy-legal` (discovery item `plugin privacy-legal`)
- Type: plugin (skills pia-generation, reg-gap-analysis, use-case-triage, dpa-review and others)
- What it can do for this project: Privacy impact assessment and regulatory gap structure.
- When it is used: Phase 11.3 (PIA structure; Privacy Act gap analysis)
- What it must not be trusted to do automatically: Legal conclusions.
- Permissions/consequences: guidance only
- Classification: SECONDARY — Structure for Phase 11 privacy work.
- Evidence: [EV: docs/evidence/p00/tierA-probe-orchestrator-20261001T135754.log]

### product-legal
- Name: `product-legal` (discovery item `plugin product-legal`)
- Type: plugin (skills feature-risk-assessment, marketing-claims-review, launch-review and others; agent launch-watcher)
- What it can do for this project: Structures feature risk and marketing-claims reviews.
- When it is used: Phase 11 structure (feature risk; marketing claims for App Store copy)
- What it must not be trusted to do automatically: Legal conclusions — every LEGAL row cites primary sources and NEEDS-LAWYER items stay with a lawyer.
- Permissions/consequences: guidance; its MCP connectors are not used
- Classification: SECONDARY — Structure for Phase 11.
- Evidence: [EV: docs/evidence/p00/tierA-probe-orchestrator-20261001T135754.log]

### swift-lsp
- Name: `swift-lsp` (discovery item `plugin swift-lsp`)
- Type: plugin (skill + language server)
- What it can do for this project: Swift symbol navigation and diagnostics after edits.
- When it is used: Build phase (implementers and reviewers)
- What it must not be trusted to do automatically: Correctness of logic; it reports compiler diagnostics only.
- Permissions/consequences: read-only analysis
- Classification: SECONDARY — Faster navigation; xcodebuild remains authoritative.
- Evidence: [EV: docs/evidence/p00/tierA-probe-orchestrator-20261001T135754.log]

### Plan
- Name: `Plan` (discovery item `builtin-agent Plan`)
- Type: subagent type (native, read-only)
- What it can do for this project: Implementation-plan design.
- When it is used: Phase 16 second opinion
- What it must not be trusted to do automatically: Writing files (it cannot).
- Permissions/consequences: read-only
- Classification: REVIEW — Independent plan check.
- Evidence: [EV: docs/evidence/p00/discovery-orchestrator-20261001T135656.log]

### agent-protocols
- Name: `agent-protocols` (discovery item `plugin agent-protocols`)
- Type: plugin (25 skills, 8 agents: code-reviewer, test-engineer, security-auditor, accessibility-specialist, spec-analyst, release-engineer, documentation-specialist, performance-engineer)
- What it can do for this project: Independent reviewer agents with distinct lenses and engineering protocol skills.
- When it is used: Phase reviews (spec-analyst on PRODUCT_SPEC, test-engineer on ENGINE_TEST_PLAN/TESTING_STRATEGY, security-auditor on ARCHITECTURE, accessibility-specialist on DESIGN_SYSTEM, release-engineer on RELEASE_CHECKLIST); build reviews
- What it must not be trusted to do automatically: Fixing the artefacts it reviews (reviewers never fix).
- Permissions/consequences: agents have all tools; briefs restrict them to read and report
- Classification: REVIEW — Distinct-lens reviewers satisfy C-11.
- Evidence: [EV: docs/evidence/p00/tierA-probe-orchestrator-20261001T135754.log]

### agentic-council
- Name: `agentic-council` (discovery item `plugin agentic-council`)
- Type: plugin (38 lens agents incl. council-skeptic, council-guardian, council-pathfinder, council-artisan, council-architect; 66 skills)
- What it can do for this project: Multi-lens critique: risk (Skeptic), compliance (Guardian), mobile (Pathfinder), visual design (Artisan), architecture (Architect).
- When it is used: Phase 19 (Skeptic failure-mode lens), Phase 11 (Guardian), Phase 12 (Pathfinder), Phase 13 (Artisan)
- What it must not be trusted to do automatically: Final decisions — lenses advise; the orchestrator decides.
- Permissions/consequences: agents have all tools; briefs restrict them
- Classification: REVIEW — Independent lenses for pre-mortem and compliance.
- Evidence: [EV: docs/evidence/p00/tierA-probe2-orchestrator-20261001T135809.log]

### backend-design
- Name: `backend-design` (discovery item `plugin backend-design`)
- Type: plugin (agents boring-tech-advisor, incident-thinker, schema-reviewer, security-reviewer, component-architect, incident-investigator)
- What it can do for this project: Challenges every new dependency against the boring alternative; schema review; incident enumeration.
- When it is used: Phase 8 (boring-tech-advisor writes the CHALLENGED lines, G3 item 6); Phase 7 (schema-reviewer on DATA_MODEL); Phase 19 (incident-thinker)
- What it must not be trusted to do automatically: Server-side assumptions for an on-device MVP.
- Permissions/consequences: read-oriented
- Classification: REVIEW — F8 enforcement.
- Evidence: [EV: docs/evidence/p00/tierA-probe-orchestrator-20261001T135754.log]

### claude-md-management
- Name: `claude-md-management` (discovery item `plugin claude-md-management`)
- Type: plugin (skill claude-md-improver, command)
- What it can do for this project: Audits and improves CLAUDE.md files.
- When it is used: Phase 21 review lens on CLAUDE.md
- What it must not be trusted to do automatically: Rewriting the bootstrap block (kept verbatim).
- Permissions/consequences: modifies CLAUDE.md if asked
- Classification: REVIEW — Second check on CLAUDE.md quality.
- Evidence: [EV: docs/evidence/p00/tierA-probe-orchestrator-20261001T135754.log]

### design
- Name: `design` (discovery item `plugin design`)
- Type: plugin (skills accessibility-review, design-handoff, design-system, design-critique, ux-copy, user-research, research-synthesis)
- What it can do for this project: Accessibility review, design-system and handoff review, UX copy critique.
- When it is used: Phase 11.6 (ux-copy lens on replacements), Phase 13 (design-system, accessibility-review)
- What it must not be trusted to do automatically: Brand or copy decisions that contradict the Say / Don't-say table.
- Permissions/consequences: guidance only
- Classification: REVIEW — Accessibility and copy lenses.
- Evidence: [EV: docs/evidence/p00/tierA-probe-orchestrator-20261001T135754.log]

### feature-dev
- Name: `feature-dev` (discovery item `plugin feature-dev`)
- Type: plugin (agents: code-reviewer, code-architect, code-explorer)
- What it can do for this project: Architecture blueprints and confidence-filtered reviews.
- When it is used: Phase 8 second opinion (code-architect); build reviews
- What it must not be trusted to do automatically: Choosing dependencies (boring-tech-advisor challenges those).
- Permissions/consequences: read-oriented tools
- Classification: REVIEW — Second architecture reviewer.
- Evidence: [EV: docs/evidence/p00/tierA-probe-orchestrator-20261001T135754.log]

### pr-review-toolkit
- Name: `pr-review-toolkit` (discovery item `plugin pr-review-toolkit`)
- Type: plugin (6 agents: code-reviewer, silent-failure-hunter, pr-test-analyzer, type-design-analyzer, comment-analyzer, code-simplifier)
- What it can do for this project: Specialised code review lenses.
- When it is used: Build phase (silent-failure-hunter on error handling, type-design-analyzer on DATA_MODEL types)
- What it must not be trusted to do automatically: Product decisions.
- Permissions/consequences: agents have all tools; briefs restrict them
- Classification: REVIEW — Complements review-council on Swift code.
- Evidence: [EV: docs/evidence/p00/tierA-probe-orchestrator-20261001T135754.log]

### review-council
- Name: `review-council` (discovery item `plugin review-council`)
- Type: plugin (6 reviewer agents: correctness, security, architecture, interface, test-evidence, policy-boundary)
- What it can do for this project: Read-only diff and document reviewers (tools: Read, Glob, Grep).
- When it is used: Build-phase diff reviews; planning gates for read-only checks (policy-boundary on CLAUDE.md and AGENT_RULES)
- What it must not be trusted to do automatically: Running commands (it cannot) — mechanical checks stay with scripts/gate.py.
- Permissions/consequences: read-only
- Classification: REVIEW — Read-only reviewers cannot alter what they review.
- Evidence: [EV: docs/evidence/p00/tierA-probe-orchestrator-20261001T135754.log]

### securitymaxxing
- Name: `securitymaxxing` (discovery item `plugin securitymaxxing`)
- Type: plugin (17 commands incl. threat-model, secrets, ship-check, vibe-check)
- What it can do for this project: Threat models, secret scans, pre-launch security gates.
- When it is used: Phase 8/11 (threat-model as a review lens), build MS-10 and MS-11 (secrets, ship-check)
- What it must not be trusted to do automatically: Legal conclusions.
- Permissions/consequences: read-mostly; fix commands modify code
- Classification: REVIEW — Security lens for ARCHITECTURE and release.
- Evidence: [EV: docs/evidence/p00/tierA-probe-orchestrator-20261001T135754.log]

### spec-drift
- Name: `spec-drift` (discovery item `plugin spec-drift`)
- Type: plugin (skills init, check, report, list, switch; hooks)
- What it can do for this project: Extracts a requirement checklist (SPEC_CHECKLIST.md) and reports dropped requirements.
- When it is used: Phase 0.16 init; G4 and Phase 25 report
- What it must not be trusted to do automatically: Judging whether a requirement is met by content quality (presence scan only).
- Permissions/consequences: writes SPEC_CHECKLIST.md
- Classification: REVIEW — Drift detection required by 0.16 item 5.
- Evidence: [EV: docs/evidence/p00/tierA-probe-orchestrator-20261001T135754.log]

### claude
- Name: `claude` (discovery item `builtin-agent claude`)
- Type: subagent type (native catch-all)
- What it can do for this project: General tasks.
- When it is used: Not used (general-purpose is used)
- What it must not be trusted to do automatically: N/A
- Permissions/consequences: all tools
- Classification: OPTIONAL — Duplicate of general-purpose.
- Evidence: [EV: docs/evidence/p00/discovery-orchestrator-20261001T135656.log]

### LSP
- Name: `LSP` (discovery item `builtin-tool LSP`)
- Type: native tool (deferred)
- What it can do for this project: Language-server queries.
- When it is used: Build phase
- What it must not be trusted to do automatically: N/A in planning
- Permissions/consequences: read-only
- Classification: OPTIONAL — No code in planning.
- Evidence: [EV: docs/evidence/p00/discovery-orchestrator-20261001T135656.log]

### Monitor
- Name: `Monitor` (discovery item `builtin-tool Monitor`)
- Type: native tool (deferred)
- What it can do for this project: Waits on a condition.
- When it is used: Polling background logs if needed
- What it must not be trusted to do automatically: N/A
- Permissions/consequences: read-only
- Classification: OPTIONAL — `tail -3` polling suffices.
- Evidence: [EV: docs/evidence/p00/discovery-orchestrator-20261001T135656.log]

### plugin:pdf-viewer:pdf
- Name: `plugin:pdf-viewer:pdf` (discovery item `mcp-server plugin:pdf-viewer:pdf`)
- Type: MCP server (stdio)
- What it can do for this project: Interactive PDF viewer and annotation.
- When it is used: Not needed: the Read tool reads the research PDF page ranges directly
- What it must not be trusted to do automatically: Annotating or signing documents.
- Permissions/consequences: reads PDFs; can write annotations
- Classification: OPTIONAL — Read tool covers PDF reading.
- Evidence: [EV: docs/evidence/p00/discovery-orchestrator-20261001T135656.log]

### agentic-sdlc
- Name: `agentic-sdlc` (discovery item `plugin agentic-sdlc`)
- Type: plugin (35 phase agents, reviewer ≠ author gates)
- What it can do for this project: A seven-phase lifecycle that writes its own FR/NFR/US/ADR documents and gates.
- When it is used: Not as spine; its design-reviewer agent may be used as a second architecture reviewer
- What it must not be trusted to do automatically: Writing its own requirement documents into this repository (would duplicate PRODUCT_SPEC and TASKS — F6).
- Permissions/consequences: modifies files
- Classification: OPTIONAL — Overlaps the master prompt's own document set; rejected as spine (D-006).
- Evidence: [EV: docs/evidence/p00/tierA-probe-orchestrator-20261001T135754.log]

### ai-governance-legal
- Name: `ai-governance-legal` (discovery item `plugin ai-governance-legal`)
- Type: plugin (skills ai-inventory, aia-generation, use-case-triage and others)
- What it can do for this project: AI use-case triage and impact assessment.
- When it is used: Phase 11 if the optional bring-your-own-AI feature (prompts/SOURCE_MAP.md) stays in scope
- What it must not be trusted to do automatically: Legal conclusions.
- Permissions/consequences: guidance only
- Classification: OPTIONAL — Only relevant to the optional AI feature.
- Evidence: [EV: docs/evidence/p00/discovery-orchestrator-20261001T135656.log]

### claude-code-setup
- Name: `claude-code-setup` (discovery item `plugin claude-code-setup`)
- Type: plugin (skill)
- What it can do for this project: Recommends Claude Code automations for a codebase.
- When it is used: Never (configuration is specified by prompts/05)
- What it must not be trusted to do automatically: Changing configuration.
- Permissions/consequences: suggests settings
- Classification: OPTIONAL — Not needed.
- Evidence: [EV: docs/evidence/p00/discovery-orchestrator-20261001T135656.log]

### claude-security
- Name: `claude-security` (discovery item `plugin claude-security`)
- Type: plugin (skill, 9 agents; hooks)
- What it can do for this project: Deep vulnerability scanning of code.
- When it is used: Build MS-10 hardening
- What it must not be trusted to do automatically: N/A in planning (no code).
- Permissions/consequences: reads code
- Classification: OPTIONAL — No production code in this run.
- Evidence: [EV: docs/evidence/p00/tierA-probe-orchestrator-20261001T135754.log]

### code-modernization
- Name: `code-modernization` (discovery item `plugin code-modernization`)
- Type: plugin (8 agents, 13 commands; hooks)
- What it can do for this project: Legacy codebase modernisation.
- When it is used: Never
- What it must not be trusted to do automatically: N/A
- Permissions/consequences: modifies code
- Classification: OPTIONAL — No legacy codebase in scope.
- Evidence: [EV: docs/evidence/p00/discovery-orchestrator-20261001T135656.log]

### code-review
- Name: `code-review` (discovery item `plugin code-review`)
- Type: plugin (command code-review)
- What it can do for this project: Multi-agent pull-request review.
- When it is used: Build phase PR reviews
- What it must not be trusted to do automatically: Approving merges alone.
- Permissions/consequences: reads PRs; may comment
- Classification: OPTIONAL — review-council covers diff review.
- Evidence: [EV: docs/evidence/p00/discovery-orchestrator-20261001T135656.log]

### code-simplifier
- Name: `code-simplifier` (discovery item `plugin code-simplifier`)
- Type: plugin (agent code-simplifier)
- What it can do for this project: Simplifies code after changes.
- When it is used: Build phase optional refactors
- What it must not be trusted to do automatically: Behaviour changes.
- Permissions/consequences: modifies code
- Classification: OPTIONAL — Not a reviewer.
- Evidence: [EV: docs/evidence/p00/tierA-probe-orchestrator-20261001T135754.log]

### engineering
- Name: `engineering` (discovery item `plugin engineering`)
- Type: plugin (10 skills incl. testing-strategy, system-design, architecture; MCP connectors)
- What it can do for this project: Testing-strategy and architecture guidance.
- When it is used: Phase 14 lens (testing-strategy)
- What it must not be trusted to do automatically: Its MCP connectors (Slack, Linear, Atlassian and others) are not used.
- Permissions/consequences: guidance; connectors external
- Classification: OPTIONAL — Lens only.
- Evidence: [EV: docs/evidence/p00/tierA-probe-orchestrator-20261001T135754.log]

### hookify
- Name: `hookify` (discovery item `plugin hookify`)
- Type: plugin (skill, agent, commands; hooks)
- What it can do for this project: Turns observed failure patterns into hooks.
- When it is used: Not needed: hooks are written directly from prompts/05
- What it must not be trusted to do automatically: Changing the enforcement hooks.
- Permissions/consequences: writes hook rules
- Classification: OPTIONAL — 05 already specifies every hook.
- Evidence: [EV: docs/evidence/p00/tierA-probe-orchestrator-20261001T135754.log]

### playwright
- Name: `playwright` (discovery item `plugin playwright`)
- Type: plugin (browser automation MCP)
- What it can do for this project: Drives a web browser.
- When it is used: Never (no web UI in scope)
- What it must not be trusted to do automatically: N/A
- Permissions/consequences: browser automation
- Classification: OPTIONAL — No web surface.
- Evidence: [EV: docs/evidence/p00/discovery-orchestrator-20261001T135656.log]

### security-guidance
- Name: `security-guidance` (discovery item `plugin security-guidance`)
- Type: plugin (hooks only)
- What it can do for this project: Pattern-based security reminders on code edits.
- When it is used: Build phase (passive)
- What it must not be trusted to do automatically: Replacing a security review.
- Permissions/consequences: hooks on edits
- Classification: OPTIONAL — Passive hook.
- Evidence: [EV: docs/evidence/p00/discovery-orchestrator-20261001T135656.log]

### serena
- Name: `serena` (discovery item `plugin serena`)
- Type: plugin (semantic code analysis MCP)
- What it can do for this project: Symbol-level code navigation.
- When it is used: Build phase alternative to swift-lsp
- What it must not be trusted to do automatically: N/A in planning
- Permissions/consequences: reads code
- Classification: OPTIONAL — swift-lsp preferred for Swift.
- Evidence: [EV: docs/evidence/p00/discovery-orchestrator-20261001T135656.log]

### swiftui-macos-skill
- Name: `swiftui-macos-skill` (discovery item `plugin swiftui-macos-skill`)
- Type: plugin (skill)
- What it can do for this project: SwiftUI guidance for macOS apps.
- When it is used: Future Mac menu-bar tier only
- What it must not be trusted to do automatically: iOS-specific behaviour.
- Permissions/consequences: guidance only
- Classification: OPTIONAL — Mac is a Future tier.
- Evidence: [EV: docs/evidence/p00/tierA-probe-orchestrator-20261001T135754.log]

### ux-superpowers
- Name: `ux-superpowers` (discovery item `plugin ux-superpowers`)
- Type: plugin (8 skills incl. ux-validate, jobs-to-be-done, user-journey)
- What it can do for this project: UX validation methods.
- When it is used: Phase 6 review lens (user journeys)
- What it must not be trusted to do automatically: Product scope.
- Permissions/consequences: guidance only
- Classification: OPTIONAL — Useful lens, not required.
- Evidence: [EV: docs/evidence/p00/tierA-probe-orchestrator-20261001T135754.log]

### wai-suite
- Name: `wai-suite` (discovery item `plugin wai-suite`)
- Type: plugin (13 skills incl. wai-mobile-release, wai-testing)
- What it can do for this project: Mobile release and testing checklists.
- When it is used: Phase 23 review lens on RELEASE_CHECKLIST
- What it must not be trusted to do automatically: Overriding the release gate.
- Permissions/consequences: guidance only
- Classification: OPTIONAL — Phase 23 has its own exhaustive row list.
- Evidence: [EV: docs/evidence/p00/tierA-probe-orchestrator-20261001T135754.log]

### statusline-setup
- Name: `statusline-setup` (discovery item `builtin-agent statusline-setup`)
- Type: subagent type (native)
- What it can do for this project: Configures the status line.
- When it is used: Never
- What it must not be trusted to do automatically: Changing user configuration.
- Permissions/consequences: edits settings
- Classification: NOT RECOMMENDED — Out of scope.
- Evidence: [EV: docs/evidence/p00/discovery-orchestrator-20261001T135656.log]

### Artifact
- Name: `Artifact` (discovery item `builtin-tool Artifact`)
- Type: native tool
- What it can do for this project: Publishes HTML pages to claude.ai.
- When it is used: Never (reports are repository files; publishing is outside the NEVER-list scope)
- What it must not be trusted to do automatically: Publishing.
- Permissions/consequences: publishes externally (private by default)
- Classification: NOT RECOMMENDED — Not needed; C-6.
- Evidence: [EV: docs/evidence/p00/discovery-orchestrator-20261001T135656.log]

### Workflow
- Name: `Workflow` (discovery item `builtin-tool Workflow`)
- Type: native tool (multi-agent workflow scripts)
- What it can do for this project: Deterministic orchestration of many subagents.
- When it is used: Never in this run: the tool requires the user's explicit opt-in in their own words, which this prompt does not give
- What it must not be trusted to do automatically: N/A
- Permissions/consequences: spawns many agents
- Classification: NOT RECOMMENDED — Opt-in rule of the tool; the Agent tool is used for fan-outs (D-006).
- Evidence: [EV: docs/evidence/p00/discovery-orchestrator-20261001T135656.log]

### plugin:context7:context7
- Name: `plugin:context7:context7` (discovery item `mcp-server plugin:context7:context7`)
- Type: MCP server (documentation lookup, needs authentication)
- What it can do for this project: Up-to-date library documentation lookup.
- When it is used: Never in this run
- What it must not be trusted to do automatically: Apple API facts (Apple's own documentation is primary).
- Permissions/consequences: external service
- Classification: NOT RECOMMENDED — Not authenticated; Apple JSON route and Xcode DocumentationSearch are primary sources.
- Evidence: [EV: docs/evidence/p00/discovery-orchestrator-20261001T135656.log]

### plugin:github:github
- Name: `plugin:github:github` (discovery item `mcp-server plugin:github:github`)
- Type: MCP server (GitHub, failed to connect: HTTP 400)
- What it can do for this project: Would expose repository, issue and PR tools.
- When it is used: Never in this run
- What it must not be trusted to do automatically: N/A (not connected)
- Permissions/consequences: remote GitHub writes
- Classification: NOT RECOMMENDED — Not connected; `gh` CLI is authenticated and covers every need.
- Evidence: [EV: docs/evidence/p00/discovery-orchestrator-20261001T135656.log]

### plugin:product-management:figma
- Name: `plugin:product-management:figma` (discovery item `mcp-server plugin:product-management:figma`)
- Type: MCP server (second Figma endpoint, needs authentication)
- What it can do for this project: Same Figma server as the claude.ai connector, through the product-management plugin.
- When it is used: Never
- What it must not be trusted to do automatically: Anything — a second Figma route would bypass the single-reader rule and the ledger.
- Permissions/consequences: would read Figma outside the ledger
- Classification: NOT RECOMMENDED — Duplicate of the PRIMARY connector; C-9 single reader.
- Evidence: [EV: docs/evidence/p00/discovery-orchestrator-20261001T135656.log]

### adversarial-review
- Name: `adversarial-review` (discovery item `plugin adversarial-review`)
- Type: plugin (skill + commands; second-model reviewer via Codex)
- What it can do for this project: Adversarial review by a different model.
- When it is used: Never in this run
- What it must not be trusted to do automatically: N/A — requires the `codex` CLI, which is not installed (docs/evidence/p00/tierA-probe-orchestrator-20261001T135754.log tail).
- Permissions/consequences: external CLI
- Classification: NOT RECOMMENDED — Dependency missing; independence comes from fresh subagents and plugin reviewers instead.
- Evidence: [EV: docs/evidence/p00/tierA-probe-orchestrator-20261001T135754.log]

### agent-handoff
- Name: `agent-handoff` (discovery item `plugin agent-handoff`)
- Type: plugin (skills plan, execute, verify, setup-handoff; hooks)
- What it can do for this project: A plan → execute → verify handoff workflow in .handoff/.
- When it is used: Never
- What it must not be trusted to do automatically: Writing a parallel plan file set (F6).
- Permissions/consequences: modifies files
- Classification: NOT RECOMMENDED — Duplicates the chosen spine and document set.
- Evidence: [EV: docs/evidence/p00/discovery-orchestrator-20261001T135656.log]

### ansight
- Name: `ansight` (discovery item `plugin ansight`)
- Type: plugin (27 skills, agent ansight-verifier)
- What it can do for this project: Runtime verification against a connected mobile app build.
- When it is used: Not used: the `ansight` CLI is not installed (session notice; docs/PREFLIGHT.md § 10)
- What it must not be trusted to do automatically: N/A (not installed)
- Permissions/consequences: drives a running app
- Classification: NOT RECOMMENDED — Missing CLI; Xcode MCP DeviceInteraction and XCUITest cover runtime verification.
- Evidence: [EV: docs/evidence/p00/tierA-probe-orchestrator-20261001T135754.log]

### commit-commands
- Name: `commit-commands` (discovery item `plugin commit-commands`)
- Type: plugin (commands commit, commit-push-pr, clean_gone)
- What it can do for this project: Git commit and PR helpers.
- When it is used: Never: clean_gone deletes branches (C-3)
- What it must not be trusted to do automatically: Branch deletion.
- Permissions/consequences: Git writes, branch deletion
- Classification: NOT RECOMMENDED — Only the orchestrator runs Git, with explicit commands.
- Evidence: [EV: docs/evidence/p00/discovery-orchestrator-20261001T135656.log]

### explanatory-output-style
- Name: `explanatory-output-style` (discovery item `plugin explanatory-output-style`)
- Type: plugin (hooks)
- What it can do for this project: Adds educational commentary to output.
- When it is used: Never
- What it must not be trusted to do automatically: Terse reporting (C-18, F21).
- Permissions/consequences: changes output style
- Classification: NOT RECOMMENDED — Conflicts with terse reporting.
- Evidence: [EV: docs/evidence/p00/discovery-orchestrator-20261001T135656.log]

### firebase
- Name: `firebase` (discovery item `plugin firebase`)
- Type: plugin (Firebase MCP)
- What it can do for this project: Firebase management.
- When it is used: Never (0.14: tools do not dictate architecture)
- What it must not be trusted to do automatically: Architecture choice.
- Permissions/consequences: external service
- Classification: NOT RECOMMENDED — No backend at MVP.
- Evidence: [EV: docs/evidence/p00/discovery-orchestrator-20261001T135656.log]

### github
- Name: `github` (discovery item `plugin github`)
- Type: plugin (GitHub MCP)
- What it can do for this project: GitHub repository tools (server failed to connect).
- When it is used: Never
- What it must not be trusted to do automatically: N/A
- Permissions/consequences: remote writes
- Classification: NOT RECOMMENDED — `gh` CLI is the route.
- Evidence: [EV: docs/evidence/p00/discovery-orchestrator-20261001T135656.log]

### learning-output-style
- Name: `learning-output-style` (discovery item `plugin learning-output-style`)
- Type: plugin (hooks)
- What it can do for this project: Requests user contributions during work.
- When it is used: Never
- What it must not be trusted to do automatically: Unattended operation (asks the user).
- Permissions/consequences: prompts the user
- Classification: NOT RECOMMENDED — Conflicts with OM-1.
- Evidence: [EV: docs/evidence/p00/discovery-orchestrator-20261001T135656.log]

### project-artifact
- Name: `project-artifact` (discovery item `plugin project-artifact`)
- Type: plugin (skill)
- What it can do for this project: Publishes a project status artefact.
- When it is used: Never (reports are files, C-6)
- What it must not be trusted to do automatically: Publishing (C-3).
- Permissions/consequences: publishes externally
- Classification: NOT RECOMMENDED — Publishing is out of scope.
- Evidence: [EV: docs/evidence/p00/discovery-orchestrator-20261001T135656.log]

### ralph-loop
- Name: `ralph-loop` (discovery item `plugin ralph-loop`)
- Type: plugin (commands; hooks)
- What it can do for this project: Self-referential continuous loops.
- When it is used: Never
- What it must not be trusted to do automatically: Anything: loops conflict with the Stop-hook and gate design (F19).
- Permissions/consequences: runs indefinitely
- Classification: NOT RECOMMENDED — Loop risk.
- Evidence: [EV: docs/evidence/p00/discovery-orchestrator-20261001T135656.log]

## Tier B — one row each (no harmless call)
| Name | Type | One-line capability | Why irrelevant here |
|---|---|---|---|
| claude.ai AccuWeather® | MCP server | MCP connector (claude.ai AccuWeather®) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| claude.ai Canva | MCP server | MCP connector (claude.ai Canva) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| claude.ai ElevenLabs | MCP server | MCP connector (claude.ai ElevenLabs) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| claude.ai Gmail | MCP server | MCP connector (claude.ai Gmail) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| claude.ai Google Calendar | MCP server | MCP connector (claude.ai Google Calendar) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| claude.ai Google Cloud BigQuery | MCP server | MCP connector (claude.ai Google Cloud BigQuery) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| claude.ai Indeed | MCP server | MCP connector (claude.ai Indeed) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| claude.ai Lawve AI | MCP server | MCP connector (claude.ai Lawve AI) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| claude.ai Notion | MCP server | MCP connector (claude.ai Notion) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:adobe-for-creativity:Adobe for creativity | MCP server | MCP connector (plugin:adobe-for-creativity:Adobe for creativity) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:atlan:atlan | MCP server | MCP connector (plugin:atlan:atlan) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:data:databricks | MCP server | MCP connector (plugin:data:databricks) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:data:definite | MCP server | MCP connector (plugin:data:definite) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:data:hex | MCP server | MCP connector (plugin:data:hex) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:data:snowflake | MCP server | MCP connector (plugin:data:snowflake) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:datadog:mcp | MCP server | MCP connector (plugin:datadog:mcp) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:design:gmail | MCP server | MCP connector (plugin:design:gmail) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:design:google calendar | MCP server | MCP connector (plugin:design:google calendar) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:engineering:atlassian | MCP server | MCP connector (plugin:engineering:atlassian) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:engineering:datadog | MCP server | MCP connector (plugin:engineering:datadog) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:engineering:gmail | MCP server | MCP connector (plugin:engineering:gmail) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:engineering:google calendar | MCP server | MCP connector (plugin:engineering:google calendar) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:engineering:linear | MCP server | MCP connector (plugin:engineering:linear) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:engineering:notion | MCP server | MCP connector (plugin:engineering:notion) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:engineering:slack | MCP server | MCP connector (plugin:engineering:slack) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:enterprise-search:gmail | MCP server | MCP connector (plugin:enterprise-search:gmail) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:enterprise-search:google calendar | MCP server | MCP connector (plugin:enterprise-search:google calendar) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:enterprise-search:guru | MCP server | MCP connector (plugin:enterprise-search:guru) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:finance:databricks | MCP server | MCP connector (plugin:finance:databricks) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:finance:gmail | MCP server | MCP connector (plugin:finance:gmail) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:finance:google calendar | MCP server | MCP connector (plugin:finance:google calendar) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:finance:snowflake | MCP server | MCP connector (plugin:finance:snowflake) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:legal:docusign | MCP server | MCP connector (plugin:legal:docusign) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:legal:egnyte | MCP server | MCP connector (plugin:legal:egnyte) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:legal:gmail | MCP server | MCP connector (plugin:legal:gmail) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:legal:google calendar | MCP server | MCP connector (plugin:legal:google calendar) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:product-legal:Asana | MCP server | MCP connector (plugin:product-legal:Asana) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:product-legal:Atlassian | MCP server | MCP connector (plugin:product-legal:Atlassian) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:product-legal:Google Drive | MCP server | MCP connector (plugin:product-legal:Google Drive) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:product-management:amplitude | MCP server | MCP connector (plugin:product-management:amplitude) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:product-management:amplitude-eu | MCP server | MCP connector (plugin:product-management:amplitude-eu) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:product-management:asana | MCP server | MCP connector (plugin:product-management:asana) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:product-management:clickup | MCP server | MCP connector (plugin:product-management:clickup) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:product-management:fireflies | MCP server | MCP connector (plugin:product-management:fireflies) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:product-management:gmail | MCP server | MCP connector (plugin:product-management:gmail) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:product-management:google calendar | MCP server | MCP connector (plugin:product-management:google calendar) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:product-management:intercom | MCP server | MCP connector (plugin:product-management:intercom) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:product-management:monday | MCP server | MCP connector (plugin:product-management:monday) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:product-management:pendo | MCP server | MCP connector (plugin:product-management:pendo) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:product-management:similarweb | MCP server | MCP connector (plugin:product-management:similarweb) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:productivity:gmail | MCP server | MCP connector (plugin:productivity:gmail) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:productivity:google calendar | MCP server | MCP connector (plugin:productivity:google calendar) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:tooljet-app-builder:tooljet | MCP server | MCP connector (plugin:tooljet-app-builder:tooljet) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:twelvelabs:twelvelabs-mcp | MCP server | MCP connector (plugin:twelvelabs:twelvelabs-mcp) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:upstash:upstash | MCP server | MCP connector (plugin:upstash:upstash) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| plugin:voicenter-mcp:voicenter | MCP server | MCP connector (plugin:voicenter-mcp:voicenter) | Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions) |
| 10x-Team | plugin | Team-role prompts for Cursor (no skills on disk) | Not a Claude Code capability used here |
| adobe-for-creativity | plugin | Adobe creative tools | Creative tooling; no marketing assets in scope |
| agent-sdk-dev | plugin | Claude Agent SDK development | No Agent SDK app is in scope |
| ai-firstify | plugin | AI-first project re-engineering | Not relevant to a planning run |
| ai-mentor | plugin | Claude Code feature tutorials | Teaching, not delivery |
| asana | plugin | Asana integration | No project-management service used |
| atlan | plugin | Atlan data catalogue | No data catalogue |
| base44 | plugin | Base44 app builder | Different stack |
| base44-sandbox | plugin | Base44 remote sandbox | Different stack |
| context7 | plugin | Upstash Context7 documentation MCP (plugin wrapper; server needs authentication) | Apple documentation is read from Apple directly; see the mcp-server context7 entry |
| cowork-plugin-management | plugin | Cowork plugin authoring | No plugin authoring |
| cwc-makers | plugin | Code-with-Claude makers onboarding | Not relevant |
| data | plugin | SQL and dataset analysis | No analytics data at MVP (RL-9) |
| datadog | plugin | Datadog observability | No third-party telemetry (RL-9) |
| discord | plugin | Discord messaging bridge | No messaging (C-3) |
| enterprise-search | plugin | Search across company tools | No company tools |
| example-plugin | plugin | Example plugin | Demonstration only |
| fakechat | plugin | Local web chat for testing | Not relevant |
| finance | plugin | Finance and accounting workflows | Finance out of scope |
| frontend-design | plugin | Web frontend design | No web UI |
| gitlab | plugin | GitLab integration | GitHub is the remote |
| imessage | plugin | iMessage bridge | No messaging (C-3) |
| laravel-boost | plugin | Laravel toolkit | Different stack |
| legal | plugin | Contract and NDA review | No contracts in scope; Phase 11 uses product-legal and privacy-legal |
| linear | plugin | Linear issue tracking | No tracker |
| math-olympiad | plugin | Competition mathematics | Not relevant |
| math-proof | plugin | Mathematical proofs | Not relevant |
| mcp-server-dev | plugin | Building MCP servers | No MCP server is in scope |
| mcp-tunnels | plugin | Private MCP tunnels | Not relevant |
| pdf-viewer | plugin | Interactive PDF viewer plugin (its MCP server has a Tier A entry) | The Read tool reads the research PDF; see the mcp-server pdf entry |
| pixeltable | plugin | Multimodal AI data pipelines | Not relevant |
| playground | plugin | Interactive HTML playgrounds | Not relevant |
| plugin-dev | plugin | Plugin development toolkit | No plugin authoring |
| product-management | plugin | Specs, roadmaps; product analytics connectors | Documents are specified by this prompt; analytics excluded (RL-9) |
| productivity | plugin | Task and memory management | State lives in docs/PROGRESS.md |
| skill-creator | plugin | Skill authoring | No skill authoring |
| telegram | plugin | Telegram bridge | No messaging (C-3) |
| terraform | plugin | Terraform infrastructure | No infrastructure |
| tooljet-app-builder | plugin | ToolJet low-code apps | Different stack |
| twelvelabs | plugin | Video AI | Not relevant |
| upstash | plugin | Upstash Redis and queues | No backend at MVP |
| voicenter-bot-builder | plugin | Voicenter telephony bots | Not relevant |
| voicenter-mcp | plugin | Voicenter telephony API | Not relevant |
| cherri | user skill | Cherri DSL for Apple Shortcuts | App Shortcuts are made with App Intents in Swift, not Cherri |

## 0.4 — Stage table (each row names at least one capability with harmless-call evidence)
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

## 0.5 — Complementary combinations
| Pairing | What A does | What B does | Why both | Authoritative for |
|---|---|---|---|---|
| Figma read tools + orchestrator reasoning | Return node data | Interprets intent, states, gaps | Node data omits behaviour and failure states | Figma: what exists; reasoning: what it implies (tagged inferred) |
| Implementer subagent + independent reviewer | Writes the artefact | Reviews it with the 04-T2 checklist | C-11 generator ≠ reviewer | Reviewer verdict decides PASS/FAIL |
| Apple documentation fetch + implementation agent | Supplies the sourced API fact with an excerpt | Uses it | Prevents stale API use (F9) | The excerpt |
| Git + review-council | Records the diff | Reviews the diff read-only | Reviews must see exactly what is committed | Git for content; reviewer for acceptance |
| Xcode MCP RenderPreview + XCUITest | Renders previews and widget/Live Activity states | Exercises real flows and accessibility audits | Previews cannot test navigation; XCUITest cannot render a widget timeline | XCUITest for behaviour; previews for static states |

## 0.6 — Duplication and conflicts
| Overlap | Primary | Reviewer | Avoided | Condition for switching |
|---|---|---|---|---|
| Figma access: claude.ai Figma connector vs product-management Figma server | claude.ai Figma | none | product-management:figma | Never (single reader, C-9) |
| SDLC workflow: superpowers vs agentic-sdlc vs agent-protocols vs agent-handoff vs wai-suite | superpowers (D-006) | agent-protocols reviewer agents | agentic-sdlc and agent-handoff as spines (they write parallel document sets) | If superpowers skills become unavailable: agent-protocols build/test/review skills |
| Code review: review-council vs pr-review-toolkit vs feature-dev vs code-review vs agent-protocols:code-reviewer | review-council | pr-review-toolkit for silent failures and types | code-review command (posts to PRs) | review-council unavailable → feature-dev:code-reviewer |
| Apple documentation: JSON route vs Xcode DocumentationSearch vs context7 | Apple JSON route with saved excerpt | Xcode DocumentationSearch cross-check | context7 (not authenticated) | JSON route blocked → Xcode DocumentationSearch with transcript saved as evidence |
| GitHub: gh CLI vs GitHub MCP | gh CLI | none | GitHub MCP (not connected) | Never in planning |
| Swift navigation: swift-lsp vs serena vs LSP tool | swift-lsp | none | serena | swift-lsp fails → LSP tool |
| Runtime verification: Xcode MCP vs ansight | Xcode MCP | XCUITest | ansight (CLI missing) | Never |
| Multi-agent orchestration: Agent tool vs Workflow tool | Agent tool | none | Workflow (needs explicit user opt-in) | Devesh writes "use a workflow" |

<!-- END OF FILE -->
