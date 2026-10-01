#!/usr/bin/env bash
# Common helpers for hooks. All hooks read the Claude Code hook JSON from stdin.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROGRESS="${PROGRESS_OVERRIDE:-$ROOT/docs/PROGRESS.md}"
LEDGER="${LEDGER_OVERRIDE:-$ROOT/docs/figma/read-ledger.md}"
INTENT="$ROOT/docs/figma/.intent"
STATE="$ROOT/.claude/hookstate"; mkdir -p "$STATE"
now_iso() { date +%Y-%m-%dT%H:%M:%S%z; }
now_epoch() { date +%s; }
mtime() { python3 -c 'import os,sys;print(int(os.path.getmtime(sys.argv[1])))' "$1" 2>/dev/null || echo 0; }   # portable (macOS and Linux)
read_stdin() { INPUT="$(cat)"; }
# jget <jsonpath> : print a field from $INPUT using python3 (always present with Xcode CLT). Empty string if absent.
jget() { python3 -c 'import json,sys
d=json.load(sys.stdin) if not sys.stdin.isatty() else {}
cur=d
for k in sys.argv[1].split("."):
    if isinstance(cur,dict) and k in cur: cur=cur[k]
    else: cur=""; break
print(cur if isinstance(cur,str) else json.dumps(cur))' "$1" <<<"$INPUT" 2>/dev/null; }
progress_field() { grep -m1 "^$1:" "$PROGRESS" 2>/dev/null | sed "s/^$1:[[:space:]]*//"; }
set_progress_field() { python3 - "$PROGRESS" "$1" "$2" <<'PY'
import sys,re,io
p,k,v=sys.argv[1:4]
s=open(p,encoding="utf-8").read()
s2,n=re.subn(rf"(?m)^{re.escape(k)}:.*$", f"{k}: {v}", s, count=1)
open(p,"w",encoding="utf-8").write(s2 if n else s.replace("\n","\n"+k+": "+v+"\n",1))
PY
}
append_progress_log() { python3 - "$PROGRESS" "$1" <<'PY'
import sys
p,line=sys.argv[1:3]
s=open(p,encoding="utf-8").read()
marker="## Log (newest first"
i=s.find(marker)
if i<0: s=s.rstrip()+"\n\n## Log (newest first; API_ERROR and COMPACTION lines appended by hooks)\n"+line+"\n"
else:
    j=s.find("\n",i)+1; s=s[:j]+line+"\n"+s[j:]
open(p,"w",encoding="utf-8").write(s)
PY
}
block() { echo "$1" >&2; exit 2; }
