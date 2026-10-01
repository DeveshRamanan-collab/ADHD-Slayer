#!/usr/bin/env bash
source "$(dirname "$0")/_lib.sh"; read_stdin
ts="$(now_iso)"; ELICIT="${ELICIT_OVERRIDE:-$ROOT/docs/agents/hooks/elicitations.md}"; mkdir -p "$(dirname "$ELICIT")"
printf '\n### Elicitation %s — MCP server asked for user input (unattended run; declined)\nRequest (verbatim, first 10 lines):\n%s\n' "$ts" "$(printf '%s' "$INPUT" | head -10 | sed 's/^/    /')" >> "$ELICIT"
block "Elicitation declined: unattended run (OM-1). Recorded in docs/agents/hooks/elicitations.md; the orchestrator merges it into docs/BLOCKERS.md as a B-nnn entry. Continue with other work."
