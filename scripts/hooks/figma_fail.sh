#!/usr/bin/env bash
source "$(dirname "$0")/_lib.sh"; read_stdin
IFS='|' read -r num base < "$STATE/figma_last" 2>/dev/null || exit 0
err="$(jget error)"; [ -z "$err" ] && err="$(jget tool_response)"; errl="$(printf '%s' "$err" | tr 'A-Z' 'a-z' | head -c 400)"
cls=transport
echo "$errl" | grep -Eq 'rate limit|quota|too many|429|try again later|upgrade|month' && cls=rate-limit
echo "$errl" | grep -Eq '401|403|unauthenti|unauthori|token|sign in|seat|forbidden' && cls=auth
echo "$errl" | grep -Eq '404|not found|could not be accessed' && cls=not-found
echo "$errl" | grep -Eq 'month|upgrade' && cls=rate-limit-monthly   # monthly-limited seat: E3 immediately (Phase 1.4)
python3 - "$LEDGER" "$num" "error $cls: $(printf '%s' "$errl" | tr '|' '/' | head -c 120)" <<'PY'
import sys,re
p,num,res=sys.argv[1:4]
lines=open(p,encoding="utf-8").read().split("\n")
for i,l in enumerate(lines):
    if re.match(rf"\|\s*{num}\s*\|",l):
        cells=l.split("|"); cells[9]=f" {res} "; lines[i]="|".join(cells); break
open(p,"w",encoding="utf-8").write("\n".join(lines))
PY
case "$cls" in rate-limit|rate-limit-monthly) echo "LIMIT-HIT $(now_iso) $cls" >> "$LEDGER" ;; esac
echo "figma_fail: row $num error class $cls — classify per Phase 1.4 (rate-limit → stop reads, work the queue; auth → UA re-authenticate, hourly probe; transport → one retry after 60 s tagged retry)."
exit 0
