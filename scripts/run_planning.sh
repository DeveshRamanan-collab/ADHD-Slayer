#!/usr/bin/env bash
# run_planning.sh — optional unattended runner (spec: prompts/05_SETTINGS_AND_HOOKS.md "Optional runner").
# Devesh may launch it from a Terminal in the project folder; the orchestrator never launches it.
#
# Usage: bash scripts/run_planning.sh [--help]
#
# Loop: start
#   claude --dangerously-skip-permissions --continue -p "Read prompts/03_RESUME_PROMPT.md and follow Variant B."
# with output appended to logs/run-<YYYY-MM-DD>.log; when it exits, read RUN_STATUS from docs/PROGRESS.md:
#   COMPLETE | COMPLETE_WITH_RESIDUALS | HALTED_USER_ACTION_REQUIRED | HALTED_HARD_FAIL  -> exit 0 (terminal)
#   WAITING_FOR_FIGMA_RESET -> sleep until RETRY_AFTER (ISO 8601 with offset), then relaunch
#   STALLED                 -> relaunch once; if STALLED again, exit 3 with a message
#   anything else           -> sleep 15 minutes and relaunch
# At most 96 launches (exit 4 when reached). `-p` runs do not auto-wait at usage limits; the 15-minute
# back-off covers that. Exit codes: 0 terminal status reached, 2 usage error, 3 stalled twice,
# 4 launch limit reached, 127 `claude` not on PATH.
set -u

usage() { sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; }

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
  "") : ;;
  *) echo "run_planning.sh: unknown argument '$1' (try --help)" >&2; exit 2 ;;
esac

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 2
PROGRESS="$ROOT/docs/PROGRESS.md"
PROMPT="Read prompts/03_RESUME_PROMPT.md and follow Variant B."
MAX_LAUNCHES=96
BACKOFF=900

command -v claude >/dev/null 2>&1 || { echo "run_planning.sh: 'claude' is not on PATH" >&2; exit 127; }
mkdir -p "$ROOT/logs"

field() { grep -m1 "^$1:" "$PROGRESS" 2>/dev/null | sed "s/^$1:[[:space:]]*//"; }
stamp() { date +%Y-%m-%dT%H:%M:%S%z; }
# Seconds from now until an ISO 8601 timestamp with offset (0 if past or unparsable).
secs_until() {
  python3 - "$1" <<'PY'
import sys, datetime
v = sys.argv[1].strip()
try:
    t = datetime.datetime.strptime(v.replace("Z", "+0000"), "%Y-%m-%dT%H:%M:%S%z")
    print(max(0, int(t.timestamp() - datetime.datetime.now(datetime.timezone.utc).timestamp())))
except ValueError:
    print(0)
PY
}

launches=0
stalled_relaunched=0
while [ "$launches" -lt "$MAX_LAUNCHES" ]; do
  launches=$((launches + 1))
  log="$ROOT/logs/run-$(date +%Y-%m-%d).log"
  echo "=== $(stamp) launch $launches/$MAX_LAUNCHES ===" >> "$log"
  claude --dangerously-skip-permissions --continue -p "$PROMPT" >> "$log" 2>&1
  code=$?
  status="$(field RUN_STATUS)"
  echo "=== $(stamp) claude exited $code; RUN_STATUS: ${status:-unset} ===" >> "$log"
  case "$status" in
    COMPLETE|COMPLETE_WITH_RESIDUALS|HALTED_USER_ACTION_REQUIRED|HALTED_HARD_FAIL)
      echo "run_planning.sh: terminal RUN_STATUS $status after $launches launch(es); see $log"
      exit 0 ;;
    WAITING_FOR_FIGMA_RESET)
      retry="$(field RETRY_AFTER)"
      wait_s="$(secs_until "${retry:-none}")"
      [ "$wait_s" -gt 0 ] || wait_s=$BACKOFF
      echo "=== $(stamp) WAITING_FOR_FIGMA_RESET; sleeping ${wait_s}s until ${retry:-unset} ===" >> "$log"
      sleep "$wait_s" ;;
    STALLED)
      if [ "$stalled_relaunched" -eq 1 ]; then
        echo "run_planning.sh: RUN_STATUS STALLED again after one relaunch; stopping. Paste prompts/03_RESUME_PROMPT.md Variant B into a fresh session." >&2
        exit 3
      fi
      stalled_relaunched=1
      echo "=== $(stamp) STALLED; relaunching once ===" >> "$log" ;;
    *)
      echo "=== $(stamp) RUN_STATUS ${status:-unset}; sleeping ${BACKOFF}s before relaunch ===" >> "$log"
      sleep "$BACKOFF" ;;
  esac
done
echo "run_planning.sh: launch limit $MAX_LAUNCHES reached without a terminal RUN_STATUS" >&2
exit 4
# <!-- END OF FILE -->
