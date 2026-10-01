#!/usr/bin/env bash
source "$(dirname "$0")/_lib.sh"; read_stdin
IFS='|' read -r num base < "$STATE/figma_last" 2>/dev/null || exit 0
resp="$(jget tool_response)"
bytes=${#resp}
trunc=no
printf '%s' "$resp" | python3 -c 'import sys
s=sys.stdin.read().rstrip()
bad = s.count("{")>s.count("}")+2 or s.count("[")>s.count("]")+2 or s.count("<")>s.count(">")+20 or "truncated" in s[-400:].lower() or "output too large" in s.lower()
sys.exit(1 if bad else 0)' || trunc=yes
if [ "$trunc" = yes ]; then out="$base.TRUNCATED.txt"; result="truncated"; else out="$base.txt"; result="ok"; fi
HOOK_WRITER=figma_post printf '%s' "$resp" > "$out"
python3 - "$LEDGER" "$num" "$result" "$bytes" "$out" <<'PY'
import sys,re
p,num,res,b,out=sys.argv[1:6]
lines=open(p,encoding="utf-8").read().split("\n")
for i,l in enumerate(lines):
    if re.match(rf"\|\s*{num}\s*\|",l):
        cells=l.split("|"); cells[8]=f" {out} "; cells[9]=f" {res} "; cells[10]=f" {b} "; lines[i]="|".join(cells); break
open(p,"w",encoding="utf-8").write("\n".join(lines))
PY
: > "$INTENT"   # clear the intent after a tagged read
echo "figma_post: cached $out ($bytes bytes, $result)"
exit 0
