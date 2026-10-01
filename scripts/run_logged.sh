#!/usr/bin/env bash
# Usage: scripts/run_logged.sh [--background] <label> -- <command...>
# Writes docs/evidence/<phase>/<label>-<agent>-<ISO-compact>.log with header/footer; refuses to reuse a path.
set -u
BG=0; [ "${1:-}" = "--background" ] && { BG=1; shift; }
label="$1"; shift; [ "${1:-}" = "--" ] && shift
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
phase="$(grep -m1 '^CURRENT_PHASE:' "$ROOT/docs/PROGRESS.md" 2>/dev/null | sed 's/^CURRENT_PHASE:[[:space:]]*//' | tr -c 'A-Za-z0-9.-' '_' | sed 's/_*$//')"
case "$phase" in MS-*|ms-*) dir="ms${phase#*-}"; dir="ms$(echo "$dir" | grep -oE '^[0-9]+')" ;; *) dir="p$(printf '%02d' "$(echo "${phase:-0}" | grep -oE '^[0-9]+' || echo 0)")" ;; esac
agent="${CLAUDE_AGENT_ID:-orchestrator}"; ts="$(date +%Y%m%dT%H%M%S)"
out="$ROOT/docs/evidence/$dir/${label}-${agent}-${ts}.log"; mkdir -p "$(dirname "$out")"
[ -e "$out" ] && { echo "run_logged: refusing to reuse $out" >&2; exit 97; }
{ echo "# cmd: $*"; echo "# cwd: $PWD"; echo "# agent: $agent"; echo "# start: $(date +%Y-%m-%dT%H:%M:%S%z)"; } > "$out"
run() { "$@" >> "$out" 2>&1; code=$?; { echo "# exit: $code"; echo "# end: $(date +%Y-%m-%dT%H:%M:%S%z)"; } >> "$out"; return $code; }
if [ "$BG" = 1 ]; then nohup bash -c "out=$(printf '%q' "$out"); $(declare -f run); run $(printf '%q ' "$@")" >/dev/null 2>&1 & echo "$out"; exit 0; fi
run "$@"; code=$?; echo "$out"; exit $code
