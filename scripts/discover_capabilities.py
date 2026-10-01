#!/usr/bin/env python3
"""discover_capabilities.py — Phase 0.2 discovery: lists every installed plugin (name, version, skill/agent/command counts and names),
every user skill, and every MCP server reported by `claude mcp list` (name, transport, state; query strings masked).
Output lines are prefixed ITEM <kind> <name> so docs/TOOL_CAPABILITY_AUDIT.md can be reconciled (G0 check 2). Never prints credentials."""
import json, os, pathlib, re, subprocess, sys
if "--help" in sys.argv: print(__doc__); sys.exit(0)
HOME = pathlib.Path.home()
roots = [HOME/".claude/plugins/synced", HOME/".claude/plugins/marketplaces", HOME/".claude/plugins/data"]
seen = {}
for r in roots:
    if not r.exists(): continue
    for pj in r.rglob("plugin.json"):
        if "node_modules" in pj.parts: continue
        try: d = json.loads(pj.read_text())
        except Exception: continue
        base = pj.parent.parent if pj.parent.name == ".claude-plugin" else pj.parent
        name = d.get("name") or base.name
        if name in seen: continue
        skills = sorted({p.parent.name for p in base.rglob("SKILL.md") if "node_modules" not in p.parts})
        agents = sorted({p.stem for p in (base/"agents").glob("*.md")}) if (base/"agents").exists() else []
        cmds = sorted({p.stem for p in (base/"commands").glob("*.md")}) if (base/"commands").exists() else []
        mcp = []
        mj = base/".mcp.json"
        if mj.exists():
            try: mcp = sorted((json.loads(mj.read_text()).get("mcpServers") or {}).keys())
            except Exception: mcp = ["(unparsed .mcp.json)"]
        if "mcpServers" in d and isinstance(d["mcpServers"], dict): mcp = sorted(set(mcp) | set(d["mcpServers"].keys()))
        hooks = (base/"hooks").exists() or "hooks" in d
        seen[name] = dict(version=d.get("version","unversioned"), desc=(d.get("description") or "").replace("\n"," ")[:140], skills=skills, agents=agents, cmds=cmds, mcp=mcp, hooks=hooks, path=str(base).replace(str(HOME),"~"))
print(f"# plugins discovered: {len(seen)}")
for n in sorted(seen):
    v = seen[n]
    print(f"ITEM plugin {n} | version {v['version']} | skills {len(v['skills'])} | agents {len(v['agents'])} | commands {len(v['cmds'])} | mcp {len(v['mcp'])} | hooks {'yes' if v['hooks'] else 'no'} | {v['desc']}")
    if v["skills"]: print(f"    skills: {', '.join(v['skills'])}")
    if v["agents"]: print(f"    agents: {', '.join(v['agents'])}")
    if v["cmds"]: print(f"    commands: {', '.join(v['cmds'])}")
    if v["mcp"]: print(f"    mcp: {', '.join(v['mcp'])}")
us = HOME/".claude/skills"
user_skills = sorted(p.name for p in us.iterdir() if p.is_dir() and p.name != "synced") if us.exists() else []
print(f"# user skills: {len(user_skills)}")
for s in user_skills: print(f"ITEM user-skill {s}")
out = subprocess.run(["claude","mcp","list"], capture_output=True, text=True, timeout=180).stdout
n = 0
for line in out.split("\n"):
    m = re.match(r"^(.+?): (.*?) - (✔ Connected|! Needs authentication|✘ Failed to connect.*|- Not configured)\s*$", line)
    if not m: continue
    n += 1
    url = re.sub(r"\?\S*", "?<masked>", m.group(2))
    print(f"ITEM mcp-server {m.group(1)} | {url[:90]} | {m.group(3)[:80]}")
print(f"# mcp servers: {n}")
print("# built-in agent types (from the Agent tool description in this session): claude, claude-code-guide, Explore, general-purpose, Plan, statusline-setup")
for a in ["claude","claude-code-guide","Explore","general-purpose","Plan","statusline-setup"]: print(f"ITEM builtin-agent {a}")
print("# built-in tools relevant here: Bash, Read, Write, Edit, Agent, Workflow, WebFetch, WebSearch, Skill, ToolSearch, Artifact, SendMessage, ScheduleWakeup, Monitor, LSP")
for t in ["Workflow","WebFetch","WebSearch","Artifact","LSP","Monitor"]: print(f"ITEM builtin-tool {t}")
