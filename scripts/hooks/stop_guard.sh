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
