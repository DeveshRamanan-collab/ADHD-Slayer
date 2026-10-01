#!/usr/bin/env bash
source "$(dirname "$0")/_lib.sh"; read_stdin
[ -f "$PROGRESS" ] || exit 0
append_progress_log "- $(now_iso) API_ERROR: $(jget error | head -c 300 | tr '\n' ' ')"
exit 0
