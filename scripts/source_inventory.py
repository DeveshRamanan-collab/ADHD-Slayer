#!/usr/bin/env python3
"""source_inventory.py — writes docs/SOURCE_INVENTORY.md (Phase 0.1 item 2): every input file with size, lines, SHA-256,
first heading as description, and present/missing against the K.2 expected list plus the SOURCE_MAP substitutes."""
import hashlib, pathlib, sys, datetime, re
if "--help" in sys.argv: print(__doc__); sys.exit(0)
R = pathlib.Path(".")
EXPECTED = ["docs/design/DESIGN_SPEC.md","docs/design/decisions.md","docs/design/figma-usage.md","docs/design/handoff.md","docs/design/metrics.md",
 "docs/design/usability-test-plan.md","SPEC_CHECKLIST.md","research/adhd_struggles.md","research/interventions_evidence.md","research/medication_pharmacology.md",
 "research/regulation_privacy_safety.md","research/apple_platform.md","research/learning_and_lifestyles.md","research/competitors_failure_modes.md",
 "prompts/figma_design_prompt.md","prompts/figma_urls.md","prompts/01_MASTER_PLANNING_PROMPT.md","prompts/02_BUILD_KICKOFF_PROMPT.md","prompts/03_RESUME_PROMPT.md",
 "prompts/04_AGENT_BRIEFS_AND_TEMPLATES.md","prompts/05_SETTINGS_AND_HOOKS.md","prompts/06_SCRIPT_SPECS.md"]
globs = ["research/*","prompts/*","*.md","docs/build-spec/*","docs/copy/**/*","docs/research-notes/**/*","docs/system-design.md","docs/api-design.md","docs/design-critique.md","design/**/*"]
files = sorted({p for g in globs for p in R.glob(g) if p.is_file() and p.name != ".DS_Store" and p.name != "CLAUDE.md"})
def desc(p):
    if p.suffix not in (".md",".txt",".json",".js",".glsl",".frag"): return f"binary/{p.suffix or 'none'} file"
    for l in p.read_text(encoding="utf-8", errors="replace").split("\n")[:40]:
        l=l.strip()
        if l.startswith("#"): return l.lstrip("# ").replace("|","/")[:110]
        if l and not l.startswith(("<!--","{","//","---")): return l.replace("|","/")[:110]
    return "N/A (no heading in first 40 lines)"
now = datetime.datetime.now().astimezone().strftime("%Y-%m-%dT%H:%M:%S%z")
out = ["# SOURCE INVENTORY — every input document (Phase 0.1 item 2)", f"Generated: {now} by scripts/source_inventory.py · Inputs are immutable (K.3).", "",
 "## Expected inputs (K.2) — present or missing", "| Expected path | Status | SHA-256 (first 16) | Substitute per prompts/SOURCE_MAP.md |", "|---|---|---|---|"]
subs = {"docs/design/":"docs/build-spec/01–11, docs/copy/, docs/system-design.md, docs/api-design.md, docs/design-critique.md, design/figma/README.md (B-001)", "SPEC_CHECKLIST.md":"N/A (no substitute; spec-drift init writes a new one, D-nnn in Phase 0.16) (B-001)"}
for e in EXPECTED:
    p = R/e
    st = "present" if p.exists() else "MISSING"
    h = hashlib.sha256(p.read_bytes()).hexdigest()[:16] if p.exists() else "N/A (file absent)"
    sub = next((v for k,v in subs.items() if e.startswith(k) or e==k), "N/A (present, no substitute needed)" if p.exists() else "none")
    out.append(f"| {e} | {st} | {h} | {sub} |")
out += ["", "## Every file found under the input folders", "| Path | Bytes | Lines | SHA-256 | Description (first heading or line) |", "|---|---|---|---|---|"]
for p in files:
    b = p.read_bytes(); lines = b.count(b"\n")
    out.append(f"| {p.as_posix()} | {len(b)} | {lines} | {hashlib.sha256(b).hexdigest()} | {desc(p)} |")
out += ["", f"Files listed: {len(files)} · Expected missing: {sum(1 for e in EXPECTED if not (R/e).exists())}", "", "Prototype code under app/ is listed in docs/PREFLIGHT.md and D-003, not here (it is code, not a document).", "", "<!-- END OF FILE -->", ""]
pathlib.Path("docs/SOURCE_INVENTORY.md").write_text("\n".join(out), encoding="utf-8")
print(f"source_inventory: {len(files)} files")
