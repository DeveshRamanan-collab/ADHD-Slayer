#!/usr/bin/env bash
source "$(dirname "$0")/_lib.sh"; read_stdin
[ -f "$PROGRESS" ] || exit 0
age=$(( $(now_epoch) - $(mtime "$PROGRESS") ))
[ "$age" -gt 1800 ] && echo "progress_nag: docs/PROGRESS.md is $((age/60)) minutes old — update the header (UPDATED, CURRENT_PHASE, NEXT_ACTION) and commit a checkpoint (C-13)."
exit 0
