#!/usr/bin/env python3
"""mcp_list_tools.py <command...> — speaks MCP over stdio (initialize, notifications/initialized, tools/list) to a local server and prints tool names.
Read-only harmless call used for Phase 0.8 evidence. Times out after 60 s."""
import json, subprocess, sys, time, select
if len(sys.argv) < 2 or sys.argv[1] == "--help": print(__doc__); sys.exit(0)
p = subprocess.Popen(sys.argv[1:], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, bufsize=1)
def send(o): p.stdin.write(json.dumps(o) + "\n"); p.stdin.flush()
def recv(want, t=60):
    end = time.time() + t
    while time.time() < end:
        r, _, _ = select.select([p.stdout], [], [], 1)
        if not r: continue
        line = p.stdout.readline()
        if not line: break
        try: m = json.loads(line)
        except Exception: continue
        if m.get("id") == want: return m
    return None
send({"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"planning-preflight","version":"1"}}})
init = recv(1)
print("initialize:", json.dumps((init or {}).get("result",{}).get("serverInfo", init))[:300])
send({"jsonrpc":"2.0","method":"notifications/initialized"})
send({"jsonrpc":"2.0","id":2,"method":"tools/list"})
tl = recv(2)
tools = ((tl or {}).get("result") or {}).get("tools") or []
print(f"tools: {len(tools)}")
for t in tools: print(" -", t.get("name"), "|", (t.get("description") or "").replace("\n"," ")[:120])
if not tools: print("raw:", json.dumps(tl)[:500])
p.terminate()
try: err = p.stderr.read()[:400]
except Exception: err = ""
if err: print("stderr:", err.replace("\n"," "))
sys.exit(0 if tools else 1)
