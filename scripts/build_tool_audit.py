#!/usr/bin/env python3
"""build_tool_audit.py — writes docs/TOOL_CAPABILITY_AUDIT.md (Phase 0.3–0.6) from the newest docs/evidence/p00/discovery-*.log
plus the classification data below. Every ITEM in the discovery log becomes exactly one Tier A entry or one Tier B row;
the script exits 1 if any discovered item is unclassified or any classified item was not discovered (G0 check 2)."""
import glob, os, re, sys, datetime
if "--help" in sys.argv: print(__doc__); sys.exit(0)
DISC = sorted(glob.glob("docs/evidence/p00/discovery-*.log"), key=os.path.getmtime)[-1]
P1 = "docs/evidence/p00/tierA-probe-orchestrator-20261001T135754.log"
P2 = "docs/evidence/p00/tierA-probe2-orchestrator-20261001T135809.log"
SUB = "docs/evidence/p00/subagent-probe-orchestrator-20261001T135318.md"
items = [l[5:].split(" | ")[0].strip() for l in open(DISC, encoding="utf-8") if l.startswith("ITEM ")]
# Tier A: key -> (type, can, when, notrust, perms, cls, reason, ev)
A = {
"mcp-server claude.ai Figma": ("MCP server (claude.ai connector, remote https://mcp.figma.com/mcp)", "Reads the Focus design file: page lists, node XML metadata, design context (reference code plus screenshot), variables, screenshots, motion keyframes, libraries, Code Connect map. Also exposes write tools that this run never calls.", "Phases 0.7, 1, 3 (single reader: the orchestrator); build-phase lock checks before UI milestones", "Completeness of any single response (large frames truncate); prototype reactions; anything it does not return. Its write tools are blocked by scripts/hooks/figma_pre.sh.", "read-only through the read tools; write tools would modify Figma (blocked); every read counts against 200/day", "PRIMARY", "The only route to the design file; REST route absent (no FIGMA_TOKEN).", "docs/evidence/p00/figma-tools/get_metadata-root-orchestrator-20261001T135045.md"),
"mcp-server xcode": ("MCP server (Apple xcode-tools via `xcrun mcpbridge`, stdio, local scope)", "54 tools: BuildProject, RunAllTests, RunSomeTests, GetTestList, RenderPreview (preview snapshots), DeviceInteraction* (simulator/device driving), DocumentationSearch, AddEntitlement, AddInfoPlist, XcodeNewProject/XcodeNewTarget, build settings and String Catalog tools.", "Phase 12 (DocumentationSearch for Apple API facts, compared with developer.apple.com JSON); build phase MS-00 onward (build, test, previews, simulator)", "Project-structure edits (XcodeWrite, XcodeRM, XcodeNewTarget) — the build uses XcodeGen and never hand-edits the project; documentation answers are compared with the Apple JSON route before citing.", "builds, runs, edits project files (write tools used only in the build phase)", "PRIMARY", "Apple's own server; preferred Route A in 0.8.", "docs/evidence/p00/xcode-mcp-tools-orchestrator-20261001T135823.log"),
"mcp-server claude.ai Claude Docs": ("MCP server (claude.ai connector)", "Reads and writes Claude Docs documents; the K.2 main design document is a Claude Docs or Artifact link.", "Phase 2 (one read attempt of the main design document)", "Writing anything (no doc is created in this run); the PDF export in research/ is the fallback source.", "read path only in this run; write tools exist", "SECONDARY", "Only needed for one read; the PDF export covers the same content.", "docs/evidence/p00/claude-docs-guide-orchestrator-20261001T135900.md"),
"mcp-server plugin:pdf-viewer:pdf": ("MCP server (stdio)", "Interactive PDF viewer and annotation.", "Not needed: the Read tool reads the research PDF page ranges directly", "Annotating or signing documents.", "reads PDFs; can write annotations", "OPTIONAL", "Read tool covers PDF reading.", DISC),
"mcp-server plugin:product-management:figma": ("MCP server (second Figma endpoint, needs authentication)", "Same Figma server as the claude.ai connector, through the product-management plugin.", "Never", "Anything — a second Figma route would bypass the single-reader rule and the ledger.", "would read Figma outside the ledger", "NOT RECOMMENDED", "Duplicate of the PRIMARY connector; C-9 single reader.", DISC),
"mcp-server plugin:github:github": ("MCP server (GitHub, failed to connect: HTTP 400)", "Would expose repository, issue and PR tools.", "Never in this run", "N/A (not connected)", "remote GitHub writes", "NOT RECOMMENDED", "Not connected; `gh` CLI is authenticated and covers every need.", DISC),
"mcp-server plugin:context7:context7": ("MCP server (documentation lookup, needs authentication)", "Up-to-date library documentation lookup.", "Never in this run", "Apple API facts (Apple's own documentation is primary).", "external service", "NOT RECOMMENDED", "Not authenticated; Apple JSON route and Xcode DocumentationSearch are primary sources.", DISC),
"plugin figma": ("plugin (skills: figma-design-to-code, figma-swiftui, figma-implement-motion, figma-use-motion, figma-code-connect and Figma write skills)", "Guidance for translating Figma nodes into SwiftUI and motion code; Code Connect mapping guidance.", "Build phase MS-03 to MS-08 (UI); Phase 13 consults figma-swiftui for the implementation map vocabulary", "Writing to Figma (figma-use, figma-generate-* skills are never invoked; their tools are blocked).", "read-only guidance; write skills would modify Figma", "SECONDARY", "Design-to-code guidance supporting the PRIMARY Figma reads.", P1),
"plugin swift-lsp": ("plugin (skill + language server)", "Swift symbol navigation and diagnostics after edits.", "Build phase (implementers and reviewers)", "Correctness of logic; it reports compiler diagnostics only.", "read-only analysis", "SECONDARY", "Faster navigation; xcodebuild remains authoritative.", P1),
"plugin liquid-glass": ("plugin (skill)", "iOS 26+ Liquid Glass SwiftUI idioms (`glassEffect`, `GlassEffectContainer`).", "Phase 13 (design-system mapping) and build MS-03", "API availability claims — each is re-sourced from Apple documentation (F9).", "guidance only", "SECONDARY", "Design-language idioms for the iOS 26 minimum.", P1),
"plugin swiftui-macos-skill": ("plugin (skill)", "SwiftUI guidance for macOS apps.", "Future Mac menu-bar tier only", "iOS-specific behaviour.", "guidance only", "OPTIONAL", "Mac is a Future tier.", P1),
"plugin superpowers": ("plugin (skills: subagent-driven-development, using-git-worktrees, test-driven-development, verification-before-completion, executing-plans, dispatching-parallel-agents, systematic-debugging, writing-plans, brainstorming)", "A build workflow of planner → implementer subagents in worktrees → review → verification before completion, with TDD and debugging discipline; imposes no document set of its own.", "Build phase spine (every milestone, D-006); planning phase uses dispatching-parallel-agents patterns for fan-outs", "Deciding scope or product behaviour; `brainstorming` asks the user questions and is not used unattended.", "drives subagents that edit files and run commands", "PRIMARY", "Chosen SDLC spine (0.6).", P1),
"plugin agentic-sdlc": ("plugin (35 phase agents, reviewer ≠ author gates)", "A seven-phase lifecycle that writes its own FR/NFR/US/ADR documents and gates.", "Not as spine; its design-reviewer agent may be used as a second architecture reviewer", "Writing its own requirement documents into this repository (would duplicate PRODUCT_SPEC and TASKS — F6).", "modifies files", "OPTIONAL", "Overlaps the master prompt's own document set; rejected as spine (D-006).", P1),
"plugin agent-protocols": ("plugin (25 skills, 8 agents: code-reviewer, test-engineer, security-auditor, accessibility-specialist, spec-analyst, release-engineer, documentation-specialist, performance-engineer)", "Independent reviewer agents with distinct lenses and engineering protocol skills.", "Phase reviews (spec-analyst on PRODUCT_SPEC, test-engineer on ENGINE_TEST_PLAN/TESTING_STRATEGY, security-auditor on ARCHITECTURE, accessibility-specialist on DESIGN_SYSTEM, release-engineer on RELEASE_CHECKLIST); build reviews", "Fixing the artefacts it reviews (reviewers never fix).", "agents have all tools; briefs restrict them to read and report", "REVIEW", "Distinct-lens reviewers satisfy C-11.", P1),
"plugin review-council": ("plugin (6 reviewer agents: correctness, security, architecture, interface, test-evidence, policy-boundary)", "Read-only diff and document reviewers (tools: Read, Glob, Grep).", "Build-phase diff reviews; planning gates for read-only checks (policy-boundary on CLAUDE.md and AGENT_RULES)", "Running commands (it cannot) — mechanical checks stay with scripts/gate.py.", "read-only", "REVIEW", "Read-only reviewers cannot alter what they review.", P1),
"plugin pr-review-toolkit": ("plugin (6 agents: code-reviewer, silent-failure-hunter, pr-test-analyzer, type-design-analyzer, comment-analyzer, code-simplifier)", "Specialised code review lenses.", "Build phase (silent-failure-hunter on error handling, type-design-analyzer on DATA_MODEL types)", "Product decisions.", "agents have all tools; briefs restrict them", "REVIEW", "Complements review-council on Swift code.", P1),
"plugin feature-dev": ("plugin (agents: code-reviewer, code-architect, code-explorer)", "Architecture blueprints and confidence-filtered reviews.", "Phase 8 second opinion (code-architect); build reviews", "Choosing dependencies (boring-tech-advisor challenges those).", "read-oriented tools", "REVIEW", "Second architecture reviewer.", P1),
"plugin adversarial-review": ("plugin (skill + commands; second-model reviewer via Codex)", "Adversarial review by a different model.", "Never in this run", "N/A — requires the `codex` CLI, which is not installed (docs/evidence/p00/tierA-probe-orchestrator-20261001T135754.log tail).", "external CLI", "NOT RECOMMENDED", "Dependency missing; independence comes from fresh subagents and plugin reviewers instead.", P1),
"plugin spec-drift": ("plugin (skills init, check, report, list, switch; hooks)", "Extracts a requirement checklist (SPEC_CHECKLIST.md) and reports dropped requirements.", "Phase 0.16 init; G4 and Phase 25 report", "Judging whether a requirement is met by content quality (presence scan only).", "writes SPEC_CHECKLIST.md", "REVIEW", "Drift detection required by 0.16 item 5.", P1),
"plugin securitymaxxing": ("plugin (17 commands incl. threat-model, secrets, ship-check, vibe-check)", "Threat models, secret scans, pre-launch security gates.", "Phase 8/11 (threat-model as a review lens), build MS-10 and MS-11 (secrets, ship-check)", "Legal conclusions.", "read-mostly; fix commands modify code", "REVIEW", "Security lens for ARCHITECTURE and release.", P1),
"plugin backend-design": ("plugin (agents boring-tech-advisor, incident-thinker, schema-reviewer, security-reviewer, component-architect, incident-investigator)", "Challenges every new dependency against the boring alternative; schema review; incident enumeration.", "Phase 8 (boring-tech-advisor writes the CHALLENGED lines, G3 item 6); Phase 7 (schema-reviewer on DATA_MODEL); Phase 19 (incident-thinker)", "Server-side assumptions for an on-device MVP.", "read-oriented", "REVIEW", "F8 enforcement.", P1),
"plugin hookify": ("plugin (skill, agent, commands; hooks)", "Turns observed failure patterns into hooks.", "Not needed: hooks are written directly from prompts/05", "Changing the enforcement hooks.", "writes hook rules", "OPTIONAL", "05 already specifies every hook.", P1),
"plugin claude-md-management": ("plugin (skill claude-md-improver, command)", "Audits and improves CLAUDE.md files.", "Phase 21 review lens on CLAUDE.md", "Rewriting the bootstrap block (kept verbatim).", "modifies CLAUDE.md if asked", "REVIEW", "Second check on CLAUDE.md quality.", P1),
"plugin agentic-council": ("plugin (38 lens agents incl. council-skeptic, council-guardian, council-pathfinder, council-artisan, council-architect; 66 skills)", "Multi-lens critique: risk (Skeptic), compliance (Guardian), mobile (Pathfinder), visual design (Artisan), architecture (Architect).", "Phase 19 (Skeptic failure-mode lens), Phase 11 (Guardian), Phase 12 (Pathfinder), Phase 13 (Artisan)", "Final decisions — lenses advise; the orchestrator decides.", "agents have all tools; briefs restrict them", "REVIEW", "Independent lenses for pre-mortem and compliance.", P2),
"plugin design": ("plugin (skills accessibility-review, design-handoff, design-system, design-critique, ux-copy, user-research, research-synthesis)", "Accessibility review, design-system and handoff review, UX copy critique.", "Phase 11.6 (ux-copy lens on replacements), Phase 13 (design-system, accessibility-review)", "Brand or copy decisions that contradict the Say / Don't-say table.", "guidance only", "REVIEW", "Accessibility and copy lenses.", P1),
"plugin product-legal": ("plugin (skills feature-risk-assessment, marketing-claims-review, launch-review and others; agent launch-watcher)", "Structures feature risk and marketing-claims reviews.", "Phase 11 structure (feature risk; marketing claims for App Store copy)", "Legal conclusions — every LEGAL row cites primary sources and NEEDS-LAWYER items stay with a lawyer.", "guidance; its MCP connectors are not used", "SECONDARY", "Structure for Phase 11.", P1),
"plugin privacy-legal": ("plugin (skills pia-generation, reg-gap-analysis, use-case-triage, dpa-review and others)", "Privacy impact assessment and regulatory gap structure.", "Phase 11.3 (PIA structure; Privacy Act gap analysis)", "Legal conclusions.", "guidance only", "SECONDARY", "Structure for Phase 11 privacy work.", P1),
"plugin ai-governance-legal": ("plugin (skills ai-inventory, aia-generation, use-case-triage and others)", "AI use-case triage and impact assessment.", "Phase 11 if the optional bring-your-own-AI feature (prompts/SOURCE_MAP.md) stays in scope", "Legal conclusions.", "guidance only", "OPTIONAL", "Only relevant to the optional AI feature.", DISC),
"plugin ansight": ("plugin (27 skills, agent ansight-verifier)", "Runtime verification against a connected mobile app build.", "Not used: the `ansight` CLI is not installed (session notice; docs/PREFLIGHT.md § 10)", "N/A (not installed)", "drives a running app", "NOT RECOMMENDED", "Missing CLI; Xcode MCP DeviceInteraction and XCUITest cover runtime verification.", P1),
"plugin wai-suite": ("plugin (13 skills incl. wai-mobile-release, wai-testing)", "Mobile release and testing checklists.", "Phase 23 review lens on RELEASE_CHECKLIST", "Overriding the release gate.", "guidance only", "OPTIONAL", "Phase 23 has its own exhaustive row list.", P1),
"plugin ux-superpowers": ("plugin (8 skills incl. ux-validate, jobs-to-be-done, user-journey)", "UX validation methods.", "Phase 6 review lens (user journeys)", "Product scope.", "guidance only", "OPTIONAL", "Useful lens, not required.", P1),
"plugin engineering": ("plugin (10 skills incl. testing-strategy, system-design, architecture; MCP connectors)", "Testing-strategy and architecture guidance.", "Phase 14 lens (testing-strategy)", "Its MCP connectors (Slack, Linear, Atlassian and others) are not used.", "guidance; connectors external", "OPTIONAL", "Lens only.", P1),
"plugin claude-security": ("plugin (skill, 9 agents; hooks)", "Deep vulnerability scanning of code.", "Build MS-10 hardening", "N/A in planning (no code).", "reads code", "OPTIONAL", "No production code in this run.", P1),
"plugin security-guidance": ("plugin (hooks only)", "Pattern-based security reminders on code edits.", "Build phase (passive)", "Replacing a security review.", "hooks on edits", "OPTIONAL", "Passive hook.", DISC),
"plugin code-simplifier": ("plugin (agent code-simplifier)", "Simplifies code after changes.", "Build phase optional refactors", "Behaviour changes.", "modifies code", "OPTIONAL", "Not a reviewer.", P1),
"plugin code-review": ("plugin (command code-review)", "Multi-agent pull-request review.", "Build phase PR reviews", "Approving merges alone.", "reads PRs; may comment", "OPTIONAL", "review-council covers diff review.", DISC),
"plugin commit-commands": ("plugin (commands commit, commit-push-pr, clean_gone)", "Git commit and PR helpers.", "Never: clean_gone deletes branches (C-3)", "Branch deletion.", "Git writes, branch deletion", "NOT RECOMMENDED", "Only the orchestrator runs Git, with explicit commands.", DISC),
"plugin agent-handoff": ("plugin (skills plan, execute, verify, setup-handoff; hooks)", "A plan → execute → verify handoff workflow in .handoff/.", "Never", "Writing a parallel plan file set (F6).", "modifies files", "NOT RECOMMENDED", "Duplicates the chosen spine and document set.", DISC),
"plugin ralph-loop": ("plugin (commands; hooks)", "Self-referential continuous loops.", "Never", "Anything: loops conflict with the Stop-hook and gate design (F19).", "runs indefinitely", "NOT RECOMMENDED", "Loop risk.", DISC),
"plugin explanatory-output-style": ("plugin (hooks)", "Adds educational commentary to output.", "Never", "Terse reporting (C-18, F21).", "changes output style", "NOT RECOMMENDED", "Conflicts with terse reporting.", DISC),
"plugin learning-output-style": ("plugin (hooks)", "Requests user contributions during work.", "Never", "Unattended operation (asks the user).", "prompts the user", "NOT RECOMMENDED", "Conflicts with OM-1.", DISC),
"plugin playwright": ("plugin (browser automation MCP)", "Drives a web browser.", "Never (no web UI in scope)", "N/A", "browser automation", "OPTIONAL", "No web surface.", DISC),
"plugin serena": ("plugin (semantic code analysis MCP)", "Symbol-level code navigation.", "Build phase alternative to swift-lsp", "N/A in planning", "reads code", "OPTIONAL", "swift-lsp preferred for Swift.", DISC),
"plugin firebase": ("plugin (Firebase MCP)", "Firebase management.", "Never (0.14: tools do not dictate architecture)", "Architecture choice.", "external service", "NOT RECOMMENDED", "No backend at MVP.", DISC),
"plugin github": ("plugin (GitHub MCP)", "GitHub repository tools (server failed to connect).", "Never", "N/A", "remote writes", "NOT RECOMMENDED", "`gh` CLI is the route.", DISC),
"plugin claude-code-setup": ("plugin (skill)", "Recommends Claude Code automations for a codebase.", "Never (configuration is specified by prompts/05)", "Changing configuration.", "suggests settings", "OPTIONAL", "Not needed.", DISC),
"plugin code-modernization": ("plugin (8 agents, 13 commands; hooks)", "Legacy codebase modernisation.", "Never", "N/A", "modifies code", "OPTIONAL", "No legacy codebase in scope.", DISC),
"plugin project-artifact": ("plugin (skill)", "Publishes a project status artefact.", "Never (reports are files, C-6)", "Publishing (C-3).", "publishes externally", "NOT RECOMMENDED", "Publishing is out of scope.", DISC),
"builtin-agent general-purpose": ("subagent type (native, all tools)", "Self-contained research, analysis and authoring briefs.", "Every fan-out in Phases 2–25 (authors, analysts, researchers) and fresh reviewers", "Its own claims until the orchestrator's OM-3 sampling resolves them.", "all tools within the brief's ownership", "PRIMARY", "Default worker.", SUB),
"builtin-agent Explore": ("subagent type (native, read-only)", "Broad read-only searches across files.", "Source-note sweeps and reviewer look-ups", "Writing anything (it cannot).", "read-only", "SECONDARY", "Cheap fan-out searches.", DISC),
"builtin-agent Plan": ("subagent type (native, read-only)", "Implementation-plan design.", "Phase 16 second opinion", "Writing files (it cannot).", "read-only", "REVIEW", "Independent plan check.", DISC),
"builtin-agent claude": ("subagent type (native catch-all)", "General tasks.", "Not used (general-purpose is used)", "N/A", "all tools", "OPTIONAL", "Duplicate of general-purpose.", DISC),
"builtin-agent claude-code-guide": ("subagent type (native)", "Answers Claude Code questions from its documentation.", "Phase 20 cross-check of Claude Code features named in the handbook", "Facts without a fetched excerpt (F9).", "read and web", "SECONDARY", "Claude Code feature check.", DISC),
"builtin-agent statusline-setup": ("subagent type (native)", "Configures the status line.", "Never", "Changing user configuration.", "edits settings", "NOT RECOMMENDED", "Out of scope.", DISC),
"builtin-tool Workflow": ("native tool (multi-agent workflow scripts)", "Deterministic orchestration of many subagents.", "Never in this run: the tool requires the user's explicit opt-in in their own words, which this prompt does not give", "N/A", "spawns many agents", "NOT RECOMMENDED", "Opt-in rule of the tool; the Agent tool is used for fan-outs (D-006).", DISC),
"builtin-tool WebFetch": ("native tool", "Fetches and summarises a URL with a small model.", "Phases 11 and 12 when scripts/fetch_excerpt.py cannot read a page; the summary is saved with `--text-file`", "Verbatim quotation (it summarises) — excerpts must contain the phrase in the saved text.", "external read", "SECONDARY", "Fallback route.", "docs/evidence/sources/FACT-hooks-events.md"),
"builtin-tool WebSearch": ("native tool", "Web search returning links.", "Locating primary sources (0.11)", "Facts (snippets are not sources).", "external read", "SECONDARY", "Locator only.", "docs/evidence/p00/websearch-probe-orchestrator-20261001T140000.md"),
"builtin-tool Artifact": ("native tool", "Publishes HTML pages to claude.ai.", "Never (reports are repository files; publishing is outside the NEVER-list scope)", "Publishing.", "publishes externally (private by default)", "NOT RECOMMENDED", "Not needed; C-6.", DISC),
"builtin-tool LSP": ("native tool (deferred)", "Language-server queries.", "Build phase", "N/A in planning", "read-only", "OPTIONAL", "No code in planning.", DISC),
"builtin-tool Monitor": ("native tool (deferred)", "Waits on a condition.", "Polling background logs if needed", "N/A", "read-only", "OPTIONAL", "`tail -3` polling suffices.", DISC),
}
B = {  # key -> (type, capability, why irrelevant)
}
B_REASON = {
 "plugin": "plugin", "mcp-server": "MCP server", "user-skill": "user skill", "builtin-agent": "subagent type", "builtin-tool": "native tool"}
B_TEXT = {
"plugin 10x-Team": ("Team-role prompts for Cursor (no skills on disk)", "Not a Claude Code capability used here"),
"plugin adobe-for-creativity": ("Adobe creative tools", "Creative tooling; no marketing assets in scope"),
"plugin agent-sdk-dev": ("Claude Agent SDK development", "No Agent SDK app is in scope"),
"plugin ai-firstify": ("AI-first project re-engineering", "Not relevant to a planning run"),
"plugin ai-mentor": ("Claude Code feature tutorials", "Teaching, not delivery"),
"plugin asana": ("Asana integration", "No project-management service used"),
"plugin atlan": ("Atlan data catalogue", "No data catalogue"),
"plugin base44": ("Base44 app builder", "Different stack"),
"plugin base44-sandbox": ("Base44 remote sandbox", "Different stack"),
"plugin cowork-plugin-management": ("Cowork plugin authoring", "No plugin authoring"),
"plugin cwc-makers": ("Code-with-Claude makers onboarding", "Not relevant"),
"plugin data": ("SQL and dataset analysis", "No analytics data at MVP (RL-9)"),
"plugin datadog": ("Datadog observability", "No third-party telemetry (RL-9)"),
"plugin discord": ("Discord messaging bridge", "No messaging (C-3)"),
"plugin enterprise-search": ("Search across company tools", "No company tools"),
"plugin example-plugin": ("Example plugin", "Demonstration only"),
"plugin fakechat": ("Local web chat for testing", "Not relevant"),
"plugin finance": ("Finance and accounting workflows", "Finance out of scope"),
"plugin frontend-design": ("Web frontend design", "No web UI"),
"plugin gitlab": ("GitLab integration", "GitHub is the remote"),
"plugin imessage": ("iMessage bridge", "No messaging (C-3)"),
"plugin laravel-boost": ("Laravel toolkit", "Different stack"),
"plugin legal": ("Contract and NDA review", "No contracts in scope; Phase 11 uses product-legal and privacy-legal"),
"plugin linear": ("Linear issue tracking", "No tracker"),
"plugin math-olympiad": ("Competition mathematics", "Not relevant"),
"plugin math-proof": ("Mathematical proofs", "Not relevant"),
"plugin mcp-server-dev": ("Building MCP servers", "No MCP server is in scope"),
"plugin mcp-tunnels": ("Private MCP tunnels", "Not relevant"),
"plugin pixeltable": ("Multimodal AI data pipelines", "Not relevant"),
"plugin playground": ("Interactive HTML playgrounds", "Not relevant"),
"plugin plugin-dev": ("Plugin development toolkit", "No plugin authoring"),
"plugin product-management": ("Specs, roadmaps; product analytics connectors", "Documents are specified by this prompt; analytics excluded (RL-9)"),
"plugin productivity": ("Task and memory management", "State lives in docs/PROGRESS.md"),
"plugin skill-creator": ("Skill authoring", "No skill authoring"),
"plugin telegram": ("Telegram bridge", "No messaging (C-3)"),
"plugin terraform": ("Terraform infrastructure", "No infrastructure"),
"plugin tooljet-app-builder": ("ToolJet low-code apps", "Different stack"),
"plugin twelvelabs": ("Video AI", "Not relevant"),
"plugin upstash": ("Upstash Redis and queues", "No backend at MVP"),
"plugin voicenter-bot-builder": ("Voicenter telephony bots", "Not relevant"),
"plugin voicenter-mcp": ("Voicenter telephony API", "Not relevant"),
"plugin context7": ("Upstash Context7 documentation MCP (plugin wrapper; server needs authentication)", "Apple documentation is read from Apple directly; see the mcp-server context7 entry"),
"plugin pdf-viewer": ("Interactive PDF viewer plugin (its MCP server has a Tier A entry)", "The Read tool reads the research PDF; see the mcp-server pdf entry"),
"user-skill cherri": ("Cherri DSL for Apple Shortcuts", "App Shortcuts are made with App Intents in Swift, not Cherri"),
}
for k in items:
    if k.startswith("mcp-server ") and k not in A and k not in B_TEXT:
        n = k[len("mcp-server "):]
        B_TEXT[k] = (f"MCP connector ({n})", "Service unrelated to building an on-device iOS planner; never called (C-3 forbids email, calendar and messaging actions)")
missing = [k for k in items if k not in A and k not in B_TEXT]
extra = [k for k in list(A) + list(B_TEXT) if k not in items]
if missing or extra:
    for k in missing: print(f"docs/TOOL_CAPABILITY_AUDIT.md:0:UNCLASSIFIED: {k}")
    for k in extra: print(f"docs/TOOL_CAPABILITY_AUDIT.md:0:NOT-DISCOVERED: {k}")
    sys.exit(1)
now = datetime.datetime.now().astimezone().strftime("%Y-%m-%dT%H:%M:%S%z")
o = ["# TOOL CAPABILITY AUDIT — Phases 0.2–0.6", f"Generated: {now} by scripts/build_tool_audit.py from {DISC}.",
     f"Items discovered: {len(items)} · Tier A entries: {len(A)} · Tier B rows: {len(B_TEXT)} · Tier A + Tier B = {len(A)+len(B_TEXT)} (G0 check 2).",
     "Harmless-call evidence for skills and agents = the installed definition file resolved and its frontmatter printed (read-only); for MCP servers = one read-only call. Nothing was uninstalled or reconfigured.", "",
     "## Tier A — full entries", ""]
order = {"PRIMARY":0,"SECONDARY":1,"REVIEW":2,"OPTIONAL":3,"NOT RECOMMENDED":4}
for k in sorted(A, key=lambda x: (order[A[x][5]], x)):
    t, can, when, nt, perm, cls, why, ev = A[k]
    o += [f"### {k.split(' ',1)[1]}", f"- Name: `{k.split(' ',1)[1]}` (discovery item `{k}`)", f"- Type: {t}", f"- What it can do for this project: {can}",
          f"- When it is used: {when}", f"- What it must not be trusted to do automatically: {nt}", f"- Permissions/consequences: {perm}",
          f"- Classification: {cls} — {why}", f"- Evidence: [EV: {ev}]", ""]
o += ["## Tier B — one row each (no harmless call)", "| Name | Type | One-line capability | Why irrelevant here |", "|---|---|---|---|"]
for k in sorted(B_TEXT):
    kind, name = k.split(" ", 1)
    o.append(f"| {name} | {B_REASON[kind]} | {B_TEXT[k][0]} | {B_TEXT[k][1]} |")
o += ["", "## 0.4 — Stage table (each row names at least one capability with harmless-call evidence)", "| Stage | Primary capability | Supporting / reviewer |", "|---|---|---|",
"| Inspect Figma | claude.ai Figma MCP read tools (orchestrator as single reader) | general-purpose analysts working from the cache |",
"| Extract design system | Figma `get_variable_defs` and `get_design_context` cache | figma plugin (figma-swiftui), liquid-glass; design:design-system as reviewer |",
"| Audit interactions | Figma metadata and design-context cache; `get_motion_context` | general-purpose analysts; Phase 3 inferred-route rules |",
"| Research Apple API feasibility | Apple documentation JSON route (scripts/fetch_excerpt.py) | Xcode MCP DocumentationSearch; WebSearch as locator |",
"| Define architecture | orchestrator reasoning plus general-purpose authors | backend-design:boring-tech-advisor, feature-dev:code-architect, agent-protocols:security-auditor |",
"| Write Swift | general-purpose implementers under the superpowers spine (build phase) | swift-lsp, liquid-glass, figma-swiftui |",
"| Build engine tests | `swift test` (Swift Testing) via scripts/run_logged.sh | agent-protocols:test-engineer as reviewer |",
"| Run Xcode builds | Xcode MCP BuildProject / RunAllTests | `xcodebuild` + `xcrun xcresulttool` (Route B) |",
"| Runtime verification on Simulator/device | Xcode MCP DeviceInteraction and RenderPreview | XCUITest + `xcrun simctl` |",
"| Git operations | `git` and `gh` CLI (orchestrator only) | none |",
"| Review diffs | review-council (6 read-only reviewers) | pr-review-toolkit, feature-dev:code-reviewer |",
"| Security audit | securitymaxxing (threat-model, secrets, ship-check) | agent-protocols:security-auditor, review-council:security-reviewer |",
"| Privacy/legal research | scripts/fetch_excerpt.py on legislation.gov.au and oaic.gov.au; WebFetch fallback | privacy-legal, product-legal, agentic-council:council-guardian |",
"| Accessibility review | design:accessibility-review | agent-protocols:accessibility-specialist |",
"| Drift detection | spec-drift (init, check, report) | scripts/validate_docs.py, scripts/trace.py |",
"| TestFlight preparation | Devesh in App Store Connect (UA-004) with docs/RELEASE_CHECKLIST.md | agent-protocols:release-engineer, wai-suite:wai-mobile-release |",
"", "## 0.5 — Complementary combinations", "| Pairing | What A does | What B does | Why both | Authoritative for |", "|---|---|---|---|---|",
"| Figma read tools + orchestrator reasoning | Return node data | Interprets intent, states, gaps | Node data omits behaviour and failure states | Figma: what exists; reasoning: what it implies (tagged inferred) |",
"| Implementer subagent + independent reviewer | Writes the artefact | Reviews it with the 04-T2 checklist | C-11 generator ≠ reviewer | Reviewer verdict decides PASS/FAIL |",
"| Apple documentation fetch + implementation agent | Supplies the sourced API fact with an excerpt | Uses it | Prevents stale API use (F9) | The excerpt |",
"| Git + review-council | Records the diff | Reviews the diff read-only | Reviews must see exactly what is committed | Git for content; reviewer for acceptance |",
"| Xcode MCP RenderPreview + XCUITest | Renders previews and widget/Live Activity states | Exercises real flows and accessibility audits | Previews cannot test navigation; XCUITest cannot render a widget timeline | XCUITest for behaviour; previews for static states |",
"", "## 0.6 — Duplication and conflicts", "| Overlap | Primary | Reviewer | Avoided | Condition for switching |", "|---|---|---|---|---|",
"| Figma access: claude.ai Figma connector vs product-management Figma server | claude.ai Figma | none | product-management:figma | Never (single reader, C-9) |",
"| SDLC workflow: superpowers vs agentic-sdlc vs agent-protocols vs agent-handoff vs wai-suite | superpowers (D-006) | agent-protocols reviewer agents | agentic-sdlc and agent-handoff as spines (they write parallel document sets) | If superpowers skills become unavailable: agent-protocols build/test/review skills |",
"| Code review: review-council vs pr-review-toolkit vs feature-dev vs code-review vs agent-protocols:code-reviewer | review-council | pr-review-toolkit for silent failures and types | code-review command (posts to PRs) | review-council unavailable → feature-dev:code-reviewer |",
"| Apple documentation: JSON route vs Xcode DocumentationSearch vs context7 | Apple JSON route with saved excerpt | Xcode DocumentationSearch cross-check | context7 (not authenticated) | JSON route blocked → Xcode DocumentationSearch with transcript saved as evidence |",
"| GitHub: gh CLI vs GitHub MCP | gh CLI | none | GitHub MCP (not connected) | Never in planning |",
"| Swift navigation: swift-lsp vs serena vs LSP tool | swift-lsp | none | serena | swift-lsp fails → LSP tool |",
"| Runtime verification: Xcode MCP vs ansight | Xcode MCP | XCUITest | ansight (CLI missing) | Never |",
"| Multi-agent orchestration: Agent tool vs Workflow tool | Agent tool | none | Workflow (needs explicit user opt-in) | Devesh writes \"use a workflow\" |",
"", "<!-- END OF FILE -->", ""]
open("docs/TOOL_CAPABILITY_AUDIT.md", "w", encoding="utf-8").write("\n".join(o))
print(f"build_tool_audit: items={len(items)} tierA={len(A)} tierB={len(B_TEXT)}")
