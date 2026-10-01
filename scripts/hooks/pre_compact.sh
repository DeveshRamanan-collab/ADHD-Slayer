#!/usr/bin/env bash
source "$(dirname "$0")/_lib.sh"; read_stdin
[ -f "$PROGRESS" ] || exit 0
ts="$(now_iso)"; mkdir -p "$ROOT/docs/evidence/checkpoints"
cp "$PROGRESS" "$ROOT/docs/evidence/checkpoints/PROGRESS-${ts//[:+]/}.md"
append_progress_log "- $ts COMPACTION (trigger: $(jget trigger)) — state snapshot saved to docs/evidence/checkpoints/"
exit 0
