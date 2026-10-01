# SETTINGS AND HOOKS — the mechanical enforcement of the operating mode

Written by the orchestrator in Phase 0.0 (planning) and kept through the build. Everything here is enforcement that does not depend on the model remembering a rule: deny rules remove or block tools; hooks block actions, do the Figma bookkeeping, re-orient the session after compaction and refuse to let a turn end early.

**Before relying on any of it, the orchestrator fetches https://code.claude.com/docs/en/hooks and https://code.claude.com/docs/en/permissions this session and confirms:** the hook event names used below exist (`SessionStart`, `PreCompact`, `Stop`, `StopFailure`, `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `Elicitation`, `SubagentStop`), the stdin JSON field names (`tool_name`, `tool_input`, `tool_response`, `stop_hook_active`, `hook_event_name`), the exit-code semantics (exit 2 blocks and feeds stderr to the model; exit 0 passes and, for `SessionStart`, stdout enters context), the matcher syntax (regex on the tool name), and the permission-rule syntax (`Bash(prefix:*)` prefix form). Any difference is adapted and logged as `D-nnn`; an event that does not exist is dropped and the loss recorded as `B-nnn`. Project-level settings never set `defaultMode` (Claude Code ignores `bypassPermissions` there; the mode comes only from the launch flag).

## `.claude/settings.json` (merge into any existing file; never overwrite other keys)

```json
{
  "permissions": {
    "deny": [
      "AskUserQuestion",
      "Bash(sudo:*)", "Bash(sudo *)",
      "Bash(su:*)", "Bash(su *)",
      "Bash(git push --force:*)", "Bash(git push --force *)", "Bash(git push -f:*)", "Bash(git push -f *)",
      "Bash(git push --delete:*)", "Bash(git push --delete *)",
      "Bash(git reset --hard:*)", "Bash(git reset --hard *)",
      "Bash(git filter-branch:*)", "Bash(git filter-branch *)",
      "Bash(git branch -D:*)", "Bash(git branch -D *)",
      "Bash(git tag -d:*)", "Bash(git tag -d *)",
      "Bash(xcrun altool:*)", "Bash(xcrun altool *)",
      "Bash(xcodebuild -exportArchive:*)", "Bash(xcodebuild -exportArchive *)"
    ]
  },
  "hooks": {
    "SessionStart": [
      { "matcher": "startup|resume|compact", "hooks": [ { "type": "command", "command": "bash scripts/hooks/session_start.sh" } ] }
    ],
    "PreCompact": [
      { "hooks": [ { "type": "command", "command": "bash scripts/hooks/pre_compact.sh" } ] }
    ],
    "Stop": [
      { "hooks": [ { "type": "command", "command": "bash scripts/hooks/stop_guard.sh" } ] }
    ],
    "StopFailure": [
      { "hooks": [ { "type": "command", "command": "bash scripts/hooks/stop_failure.sh" } ] }
    ],
    "SubagentStop": [
      { "hooks": [ { "type": "command", "command": "bash scripts/hooks/subagent_stop.sh" } ] }
    ],
    "Elicitation": [
      { "hooks": [ { "type": "command", "command": "bash scripts/hooks/decline_elicitation.sh" } ] }
    ],
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [ { "type": "command", "command": "bash scripts/hooks/guard_bash.sh" } ] },
      { "matcher": "Write|Edit|MultiEdit|NotebookEdit", "hooks": [ { "type": "command", "command": "bash scripts/hooks/guard_write.sh" } ] },
      { "matcher": "^mcp__.*__(get_metadata|get_design_context|get_screenshot|get_variable_defs|get_figjam|get_motion_context|get_libraries|search_design_system|get_code_connect_map|get_figma_skill|use_figma|create_new_file|upload_assets|download_assets|generate_diagram|create_shader|update_shader|add_code_connect_map|send_code_connect_mappings|create_generative_plugin|update_generative_plugin|export_video|weave_.*)$", "hooks": [ { "type": "command", "command": "bash scripts/hooks/figma_pre.sh" } ] },
      { "matcher": ".*", "hooks": [ { "type": "command", "command": "bash scripts/hooks/progress_nag.sh" } ] }
    ],
    "PostToolUse": [
      { "matcher": "^mcp__.*__(get_metadata|get_design_context|get_screenshot|get_variable_defs|get_figjam|get_motion_context|get_libraries|search_design_system|get_code_connect_map)$", "hooks": [ { "type": "command", "command": "bash scripts/hooks/figma_post.sh" } ] }
    ],
    "PostToolUseFailure": [
      { "matcher": "^mcp__.*__(get_metadata|get_design_context|get_screenshot|get_variable_defs|get_figjam|get_motion_context|get_libraries|search_design_system|get_code_connect_map)$", "hooks": [ { "type": "command", "command": "bash scripts/hooks/figma_fail.sh" } ] }
    ]
  }
}
```
Notes: the deny list is belt; `guard_bash.sh` is braces (prefix rules cannot catch every spelling, e.g. `git push origin main --force`). `AskUserQuestion` as a bare name removes the tool from the model's context entirely. The Figma matcher is adjusted to the actual server prefix found in Phase 0.1 item 4 if the server name contains characters the regex does not cover.

## Shared helper — `scripts/hooks/_lib.sh` (sourced by every hook)

```bash
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
```

## `scripts/hooks/session_start.sh` — re-orientation after startup, resume or compaction

```bash
#!/usr/bin/env bash
source "$(dirname "$0")/_lib.sh"; read_stdin
[ -f "$PROGRESS" ] || { echo "No docs/PROGRESS.md yet: begin at Phase 0.0 of prompts/01_MASTER_PLANNING_PROMPT.md."; exit 0; }
echo "=== RUN STATE (from docs/PROGRESS.md) ==="
for k in RUN_STATUS CURRENT_PHASE NEXT_ACTION RETRY_AFTER LOCK_FINGERPRINT FIGMA_EPOCH_READS LAST_GATE OPEN_BLOCKERS; do echo "$k: $(progress_field "$k")"; done
src="$(jget source)"; [ -n "$src" ] && echo "SessionStart source: $src"
echo "Before acting: run the OM-5 resume protocol — re-read docs/PROGRESS.md, docs/AGENT_RULES.md and the CURRENT_PHASE section of prompts/01_MASTER_PLANNING_PROMPT.md (or prompts/02_BUILD_KICKOFF_PROMPT.md for a BUILD run). Do not rely on any compaction summary for a rule, id, path or number. Do not ask questions. Do not restart."
exit 0
```

## `scripts/hooks/pre_compact.sh` — checkpoint before context compaction

```bash
#!/usr/bin/env bash
source "$(dirname "$0")/_lib.sh"; read_stdin
[ -f "$PROGRESS" ] || exit 0
ts="$(now_iso)"; mkdir -p "$ROOT/docs/evidence/checkpoints"
cp "$PROGRESS" "$ROOT/docs/evidence/checkpoints/PROGRESS-${ts//[:+]/}.md"
append_progress_log "- $ts COMPACTION (trigger: $(jget trigger)) — state snapshot saved to docs/evidence/checkpoints/"
exit 0
```

## `scripts/hooks/stop_guard.sh` — a turn may not end until the run is terminal (with a stall detector)

```bash
#!/usr/bin/env bash
source "$(dirname "$0")/_lib.sh"; read_stdin
[ -f "$PROGRESS" ] || exit 0                      # nothing to guard yet
status="$(progress_field RUN_STATUS)"
case "$status" in
  COMPLETE|COMPLETE_WITH_RESIDUALS|HALTED_USER_ACTION_REQUIRED|HALTED_HARD_FAIL|WAITING_FOR_FIGMA_RESET|STALLED) exit 0 ;;
esac
hash="$(shasum -a 256 "$PROGRESS" | cut -c1-16)"
prev="$(cat "$STATE/stop_hash" 2>/dev/null || true)"
count="$(cat "$STATE/stop_count" 2>/dev/null || echo 0)"
if [ "$hash" = "$prev" ]; then count=$((count+1)); else count=1; fi
echo "$hash" > "$STATE/stop_hash"; echo "$count" > "$STATE/stop_count"
active="$(jget stop_hook_active)"
if [ "$count" -ge 5 ]; then   # five consecutive blocked stops with PROGRESS.md unchanged ($active is logged only)
  set_progress_field RUN_STATUS STALLED
  append_progress_log "- $(now_iso) STALL DETECTED by stop_guard: $count consecutive stop attempts with no change to PROGRESS.md; RUN_STATUS set to STALLED. Devesh: paste prompts/03_RESUME_PROMPT.md Variant B."
  exit 0
fi
block "Run is not complete (RUN_STATUS: ${status:-unset}). Do not end the turn. Re-read docs/PROGRESS.md and continue from NEXT_ACTION: $(progress_field NEXT_ACTION). If you are legitimately stopping, set RUN_STATUS to one of COMPLETE | COMPLETE_WITH_RESIDUALS | HALTED_USER_ACTION_REQUIRED | HALTED_HARD_FAIL | WAITING_FOR_FIGMA_RESET first (exit rules E1–E6), commit, then stop. (stop_guard attempt $count/5)"
```

## `scripts/hooks/stop_failure.sh` — record why a turn ended on an API error

```bash
#!/usr/bin/env bash
source "$(dirname "$0")/_lib.sh"; read_stdin
[ -f "$PROGRESS" ] || exit 0
append_progress_log "- $(now_iso) API_ERROR: $(jget error | head -c 300 | tr '\n' ' ')"
exit 0
```

## `scripts/hooks/guard_bash.sh` — block destructive and interactive commands regardless of spelling

```bash
#!/usr/bin/env bash
source "$(dirname "$0")/_lib.sh"; read_stdin
cmd="$(jget tool_input.command)"
deny='(^|[;&|[:space:]])(sudo|su)([[:space:]]|$)|git[[:space:]]+push\b.*(--force|-f\b|--force-with-lease|--delete|:refs)|git[[:space:]]+(reset[[:space:]]+--hard|filter-branch|rebase[[:space:]]+-i|branch[[:space:]]+-D|tag[[:space:]]+-d|push[[:space:]]+--mirror)|rm[[:space:]]+-[a-zA-Z]*r[a-zA-Z]*[[:space:]]+(/|~|\$HOME|\.\.)([[:space:]]|$)|xcrun[[:space:]]+altool|xcodebuild[[:space:]].*-exportArchive|xcodebuild[[:space:]]+-license|gh[[:space:]]+auth[[:space:]]+login|curl[^|]*\|[[:space:]]*(ba)?sh|claude[[:space:]]+.*--dangerously-skip-permissions'
if printf '%s' "$cmd" | grep -Eq "$deny"; then
  block "BLOCKED by guard_bash (NEVER list / interactive command): $cmd — record a B-nnn or UA-nnn and continue with other work."
fi
# Figma desktop-app transport check is the reader's job; hooks do not run pgrep here.
exit 0
```

## `scripts/hooks/guard_write.sh` — protect inputs; keep placeholders out of deliverables

```bash
#!/usr/bin/env bash
source "$(dirname "$0")/_lib.sh"; read_stdin
path="$(jget tool_input.file_path)"; [ -z "$path" ] && path="$(jget tool_input.notebook_path)"
[ -z "$path" ] && exit 0
rel="${path#$ROOT/}"
case "$rel" in
  docs/design/*|research/*|prompts/figma_design_prompt.md|SPEC_CHECKLIST.md|prompts/01_MASTER_PLANNING_PROMPT.md|prompts/0[2-6]_*.md)
    block "BLOCKED by guard_write: $rel is an immutable input (K.3). Write your output elsewhere." ;;
  docs/figma/raw/*/*/nodes.json) : ;;   # normalised index written by the orchestrator (Phase 1.2); raw responses stay hook-only
  docs/figma/raw/*|docs/figma/read-ledger.md)
    [ "${HOOK_WRITER:-}" = "figma_post" ] || block "BLOCKED by guard_write: the cache and ledger are written only by the Figma hooks (C-9)." ;;
esac
# Placeholder check for manifest deliverables (docs/*.md and docs/figma/analysis/*.md, excluding evidence/agents/parts)
case "$rel" in
  docs/AGENT_RULES.md) exit 0 ;;   # verbatim rules quote the markers by design
  docs/evidence/*|docs/agents/*|docs/parts/*|docs/figma/raw/*|logs/*) exit 0 ;;
  docs/*.md|CLAUDE.md)
    content="$(jget tool_input.content)"; [ -z "$content" ] && content="$(jget tool_input.new_string)"
    stripped="$(printf '%s' "$content" | python3 -c 'import sys,re
s=sys.stdin.read()
F="`"*3
s=re.sub(F+r"(figma-copy|quote|output)[\s\S]*?"+F,"",s)
s=re.sub(r"`[^`\n]*`","",s)
print(s)')"
    if printf '%s' "$stripped" | grep -Eq '\bTODO\b|\bTBD\b|\bFIXME\b|\bXXX\b|lorem ipsum|<placeholder>'; then
      block "BLOCKED by guard_write: placeholder marker in a deliverable ($rel). Use [UNVERIFIED], [ASSUMPTION-nnn] or N/A (<reason>) instead (F5)."
    fi ;;
esac
exit 0
```

## `scripts/hooks/figma_pre.sh` — write tools are blocked; reads are cached-or-counted, paced and ledgered

```bash
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
```

## `scripts/hooks/figma_post.sh` — cache the verbatim response and complete the ledger row

```bash
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
```

## `scripts/hooks/figma_fail.sh` — classify the error, complete the row, mark limit hits

```bash
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
```

## `scripts/hooks/decline_elicitation.sh` — an MCP server asking for user input is declined and logged

```bash
#!/usr/bin/env bash
source "$(dirname "$0")/_lib.sh"; read_stdin
ts="$(now_iso)"; ELICIT="${ELICIT_OVERRIDE:-$ROOT/docs/agents/hooks/elicitations.md}"; mkdir -p "$(dirname "$ELICIT")"
printf '\n### Elicitation %s — MCP server asked for user input (unattended run; declined)\nRequest (verbatim, first 10 lines):\n%s\n' "$ts" "$(printf '%s' "$INPUT" | head -10 | sed 's/^/    /')" >> "$ELICIT"
block "Elicitation declined: unattended run (OM-1). Recorded in docs/agents/hooks/elicitations.md; the orchestrator merges it into docs/BLOCKERS.md as a B-nnn entry. Continue with other work."
```

## `scripts/hooks/subagent_stop.sh` — a subagent may not finish leaving half-written deliverables

```bash
#!/usr/bin/env bash
source "$(dirname "$0")/_lib.sh"; read_stdin
agent="$(jget agent_id)"; [ -z "$agent" ] && agent="$(jget session_id)"; agent="${agent:-unknown}"
countf="$STATE/subagent_${agent}"; count="$(cat "$countf" 2>/dev/null || echo 0)"
# The stopping subagent's own list: from its transcript if the hook input provides one (field name confirmed in Phase 0.0c), else the newest list.
tp="$(jget agent_transcript_path)"; [ -z "$tp" ] && tp="$(jget transcript_path)"
list=""; [ -n "$tp" ] && [ -f "$tp" ] && list="$(grep -oE 'docs/agents/[A-Za-z0-9_.-]+/outputs\.txt' "$tp" 2>/dev/null | tail -1)" && [ -n "$list" ] && list="$ROOT/$list"
[ -z "$list" ] && list="${OUTPUTS_OVERRIDE:-$(ls -t "$ROOT"/docs/agents/*/outputs.txt 2>/dev/null | head -1)}"   # written by the subagent as its last action (04-T1 rule 11)
if [ -z "$list" ] || [ "$(( $(now_epoch) - $(mtime "$list") ))" -ge 600 ]; then rm -f "$countf"; exit 0; fi
offenders="$(while IFS= read -r f; do [ -z "$f" ] && continue; case "$f" in *.PARTIAL.md) continue;; esac; [ -f "$ROOT/$f" ] || { echo "$f (missing)"; continue; }; tail -c 400 "$ROOT/$f" | grep -q '<!-- END OF FILE -->' || echo "$f"; done < "$list")"
if [ -n "$offenders" ] && [ "$count" -lt 2 ]; then
  echo $((count+1)) > "$countf"
  block "Subagent output incomplete — these outputs listed in your outputs.txt are missing or lack <!-- END OF FILE --> (finish them, or rename to <name>.PARTIAL.md with a final line 'PARTIAL: resume at <heading>' and update outputs.txt): $(echo "$offenders" | tr '\n' ' ')"
fi
rm -f "$countf"; exit 0
```

## `scripts/hooks/progress_nag.sh` — remind, never block

```bash
#!/usr/bin/env bash
source "$(dirname "$0")/_lib.sh"; read_stdin
[ -f "$PROGRESS" ] || exit 0
age=$(( $(now_epoch) - $(mtime "$PROGRESS") ))
[ "$age" -gt 1800 ] && echo "progress_nag: docs/PROGRESS.md is $((age/60)) minutes old — update the header (UPDATED, CURRENT_PHASE, NEXT_ACTION) and commit a checkpoint (C-13)."
exit 0
```

## Installation and test (Phase 0.0 f)
`chmod +x scripts/hooks/*.sh`; then with evidence: (1) `echo '{"tool_name":"Bash","tool_input":{"command":"sudo -n true"}}' | bash scripts/hooks/guard_bash.sh; echo "exit=$?"` → exit 2; (2) the same with `git status` → exit 0; (3) `echo '{"tool_name":"Write","tool_input":{"file_path":"'"$PWD"'/docs/design/probe.md","content":"x"}}' | bash scripts/hooks/guard_write.sh; echo $?` → exit 2; (4) `echo '{"stop_hook_active":false}' | bash scripts/hooks/stop_guard.sh; echo $?` with `RUN_STATUS: RUNNING` → exit 2, and with `RUN_STATUS: COMPLETE` → exit 0; (5) one real Figma `whoami` (not matched — no row) and the single root `get_metadata` of Phase 0.1 (matched — a ledger row appears and a cache file is written). (6) every other hook (`session_start`, `pre_compact`, `stop_failure`, `figma_fail`, `decline_elicitation`, `subagent_stop`, `progress_nag`) by a dry run with a fixture JSON on stdin and `PROGRESS_OVERRIDE`/`LEDGER_OVERRIDE`/`ELICIT_OVERRIDE`/`OUTPUTS_OVERRIDE` pointing at copies under `docs/evidence/p00/fixtures/` (never the real files), recording exit code and side effect. Record each result in `docs/evidence/p00/hooks-<ISO>.log`. The Figma matcher's server prefix is corrected if the ledger row does not appear.

## Optional runner — `scripts/run_planning.sh` (Devesh may launch it; the orchestrator never does)
Relaunches Claude Code after a crash or a stop and keeps the run alive unattended. Because current Claude Code versions signed in with a claude.ai subscription wait and continue at usage limits by themselves in an interactive session (verify in Phase 0.1 as a `FACT-`), the runner is only needed when the session process ends. Logic: loop — start `claude --dangerously-skip-permissions --continue -p "Read prompts/03_RESUME_PROMPT.md and follow Variant B."` with output appended to `logs/run-<date>.log`; when it exits, read `RUN_STATUS`: terminal → exit; `WAITING_FOR_FIGMA_RESET` → sleep until `RETRY_AFTER` then relaunch; `STALLED` → relaunch once, then exit with a message; anything else → sleep 15 min and relaunch, at most 96 times. `-p` runs do not auto-wait at usage limits; the runner's 15-minute back-off covers that. Written to spec by the orchestrator in Phase 0.16; never started by it.

<!-- END OF FILE -->
