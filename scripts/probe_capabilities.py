#!/usr/bin/env python3
"""probe_capabilities.py <plugin:item> ... — harmless-call evidence for Tier A skills and agents (Phase 0.3, F26).
For each <plugin>:<skill-or-agent> it locates the installed definition file (SKILL.md, agents/<name>.md or commands/<name>.md),
prints its path (home shortened to ~), its frontmatter name/description and the first tool list, and PRESENT/ABSENT.
Read-only. Exit 1 if any requested item is absent."""
import pathlib, re, sys
if len(sys.argv) < 2 or "--help" in sys.argv: print(__doc__); sys.exit(0)
HOME = pathlib.Path.home()
ROOTS = [HOME/".claude/plugins/synced", HOME/".claude/plugins/marketplaces", HOME/".claude/plugins/data", HOME/".claude/plugins/cache"]
def plugin_dirs(name):
    out = []
    for r in ROOTS:
        if not r.exists(): continue
        for pj in r.rglob("plugin.json"):
            if "node_modules" in pj.parts: continue
            t = pj.read_text(errors="replace")
            if re.search(r'"name"\s*:\s*"%s"' % re.escape(name), t):
                out.append(pj.parent.parent if pj.parent.name == ".claude-plugin" else pj.parent)
    return out
bad = 0
for arg in sys.argv[1:]:
    plug, _, item = arg.partition(":")
    found = None
    for d in plugin_dirs(plug):
        cands = [d/"skills"/item/"SKILL.md", d/"agents"/f"{item}.md", d/"commands"/f"{item}.md"] + list(d.rglob(f"{item}/SKILL.md"))
        for c in cands:
            if c.exists(): found = c; break
        if found: break
    if not found:
        print(f"ABSENT  {arg}"); bad += 1; continue
    txt = found.read_text(errors="replace")
    fm = re.search(r"^---\n(.*?)\n---", txt, re.S)
    head = fm.group(1) if fm else txt[:300]
    name = re.search(r"^name:\s*(.*)$", head, re.M); desc = re.search(r"^description:\s*(.*)$", head, re.M); tools = re.search(r"^tools:\s*(.*)$", head, re.M)
    print(f"PRESENT {arg} | {str(found).replace(str(HOME), '~')}")
    print(f"        name: {name.group(1).strip() if name else 'N/A (no name field)'} | tools: {tools.group(1).strip()[:80] if tools else 'inherited'}")
    print(f"        description: {(desc.group(1).strip() if desc else head.splitlines()[0])[:220]}")
sys.exit(1 if bad else 0)
