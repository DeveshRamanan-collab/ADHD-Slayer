#!/usr/bin/env bash
source "$(dirname "$0")/_lib.sh"; read_stdin
agent="$(jget agent_id)"; [ -z "$agent" ] && agent="$(jget session_id)"; agent="${agent:-unknown}"
countf="$STATE/subagent_${agent}"; count="$(cat "$countf" 2>/dev/null || echo 0)"
# The stopping subagent's own list: from its transcript if the hook input provides one (field name confirmed in Phase 0.0c), else the newest list.
tp="$(jget agent_transcript_path)"; [ -z "$tp" ] && tp="$(jget transcript_path)"
list=""; [ -n "$tp" ] && [ -f "$tp" ] && list="$(grep -oE 'docs/agents/[A-Za-z0-9_.-]+/outputs\.txt' "$tp" 2>/dev/null | tail -1)" && [ -n "$list" ] && list="$ROOT/$list"
[ -z "$list" ] && list="${OUTPUTS_OVERRIDE:-$(ls -t "$ROOT"/docs/agents/*/outputs.txt 2>/dev/null | head -1)}"   # written by the subagent as its last action (04-T1 rule 11)
if [ -z "$list" ] || [ "$(( $(now_epoch) - $(mtime "$list") ))" -ge 600 ]; then rm -f "$countf"; exit 0; fi
offenders="$(while IFS= read -r f; do [ -z "$f" ] && continue; case "$f" in (*.PARTIAL.md) continue;; esac; [ -f "$ROOT/$f" ] || { echo "$f (missing)"; continue; }; tail -c 400 "$ROOT/$f" | grep -q '<!-- END OF FILE -->' || echo "$f"; done < "$list")"
if [ -n "$offenders" ] && [ "$count" -lt 2 ]; then
  echo $((count+1)) > "$countf"
  block "Subagent output incomplete — these outputs listed in your outputs.txt are missing or lack <!-- END OF FILE --> (finish them, or rename to <name>.PARTIAL.md with a final line 'PARTIAL: resume at <heading>' and update outputs.txt): $(echo "$offenders" | tr '\n' ' ')"
fi
rm -f "$countf"; exit 0
