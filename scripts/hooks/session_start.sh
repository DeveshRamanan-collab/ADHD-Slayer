#!/usr/bin/env bash
source "$(dirname "$0")/_lib.sh"; read_stdin
[ -f "$PROGRESS" ] || { echo "No docs/PROGRESS.md yet: begin at Phase 0.0 of prompts/01_MASTER_PLANNING_PROMPT.md."; exit 0; }
echo "=== RUN STATE (from docs/PROGRESS.md) ==="
for k in RUN_STATUS CURRENT_PHASE NEXT_ACTION RETRY_AFTER LOCK_FINGERPRINT FIGMA_EPOCH_READS LAST_GATE OPEN_BLOCKERS; do echo "$k: $(progress_field "$k")"; done
src="$(jget source)"; [ -n "$src" ] && echo "SessionStart source: $src"
echo "Before acting: run the OM-5 resume protocol — re-read docs/PROGRESS.md, docs/AGENT_RULES.md and the CURRENT_PHASE section of prompts/01_MASTER_PLANNING_PROMPT.md (or prompts/02_BUILD_KICKOFF_PROMPT.md for a BUILD run). Do not rely on any compaction summary for a rule, id, path or number. Do not ask questions. Do not restart."
exit 0
