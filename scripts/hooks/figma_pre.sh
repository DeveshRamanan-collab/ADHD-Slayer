#!/usr/bin/env bash
source "$(dirname "$0")/_lib.sh"; read_stdin
tool="$(jget tool_name)"; short="${tool##*__}"
case "$short" in
  use_figma|create_new_file|upload_assets|generate_diagram|create_shader|update_shader|add_code_connect_map|send_code_connect_mappings|create_generative_plugin|update_generative_plugin|export_video|weave_*)
    block "BLOCKED by figma_pre: $short modifies Figma (C-3 NEVER list)." ;;
  download_assets|get_figma_skill)
    block "BLOCKED by figma_pre: $short is not needed in this run and would bypass the ledger." ;;
esac
[ -f "$LEDGER" ] || block "BLOCKED by figma_pre: docs/figma/read-ledger.md does not exist; create it from 04-T7 first."
key="$(jget tool_input.fileKey)"; node="$(jget tool_input.nodeId)"; node="${node//-/:}"; [ -z "$node" ] && node="root"
safe="${node//:/_}"; cache_dir="$ROOT/docs/figma/raw/${key:-unknown}/$short"; mkdir -p "$cache_dir"
intent="$(cat "$INTENT" 2>/dev/null | tr -d '[:space:]')"
# 1. Cache check
if ls "$cache_dir/$safe".* >/dev/null 2>&1 && ! ls "$cache_dir/$safe".TRUNCATED.* >/dev/null 2>&1; then
  case "$intent" in lock-check|retry|delta-audit) ;; *) block "BLOCKED by figma_pre: node $node already cached at $cache_dir/$safe.* — analyse the cache; re-reading needs docs/figma/.intent = lock-check | retry | delta-audit (C-9, F27)." ;; esac
fi
# 2. Budget: count counted rows in the last 24 h and last 60 s
cap="$(grep -oE '\| cap [0-9]+' "$LEDGER" | tail -1 | grep -oE '[0-9]+')"; cap="${cap:-150}"   # the most recent EPOCH header governs
nowe="$(now_epoch)"
read -r n24 n60 last <<<"$(python3 - "$LEDGER" "$nowe" <<'PY'
import sys,re,datetime
p,now=sys.argv[1],int(sys.argv[2]); n24=n60=0; last=0
for line in open(p,encoding="utf-8"):
    m=re.match(r"\|\s*\d+\s*\|\s*(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})([+-]\d{2}):?(\d{2})",line)
    if not m: continue
    dt=datetime.datetime.strptime(m.group(1)+m.group(2)+m.group(3),"%Y-%m-%dT%H:%M:%S%z"); e=int(dt.timestamp())
    if now-e<86400: n24+=1
    if now-e<60: n60+=1
    last=max(last,e)
print(n24,n60,last)
PY
)"
[ "$n24" -ge "$cap" ] && block "BLOCKED by figma_pre: epoch budget exhausted ($n24/$cap in 24 h). Work docs/WORK_QUEUE.md; if empty, set RUN_STATUS WAITING_FOR_FIGMA_RESET with RETRY_AFTER (E6)."
[ "$n60" -ge 8 ] && block "BLOCKED by figma_pre: 8 reads in the last 60 s; wait at least 60 s (C-9)."
# 3. Pacing: ≥7 s since the last read
gap=$((nowe-last)); [ "$gap" -lt 7 ] && sleep $((7-gap))
# 4. Ledger row (pending) and pointer for the post hook
num=$(( $(grep -cE '^\|\s*[0-9]+\s*\|' "$LEDGER") + 1 )); ts="$(now_iso)"
agent="${CLAUDE_AGENT_ID:-orchestrator}"
printf '| %s | %s | %s | %s | %s | %s | %s | %s | pending | 0 | %s | %s |\n' "$num" "$ts" "$agent" "$short" "${key:-unknown}" "$node" "${intent:-plan}" "$cache_dir/$safe.txt" "$((n24+1))" "$((n60+1))" >> "$LEDGER"
echo "$num|$cache_dir/$safe" > "$STATE/figma_last"
exit 0
