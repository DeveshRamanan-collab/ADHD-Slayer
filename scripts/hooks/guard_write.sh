#!/usr/bin/env bash
source "$(dirname "$0")/_lib.sh"; read_stdin
path="$(jget tool_input.file_path)"; [ -z "$path" ] && path="$(jget tool_input.notebook_path)"
[ -z "$path" ] && exit 0
rel="${path#$ROOT/}"
case "$rel" in
  docs/design/*|research/*|prompts/figma_design_prompt.md|prompts/01_MASTER_PLANNING_PROMPT.md|prompts/0[2-6]_*.md|prompts/SOURCE_MAP.md|prompts/figma_urls.md|docs/build-spec/*|docs/copy/*|docs/research-notes/*|docs/system-design.md|docs/api-design.md|docs/design-critique.md|design/*|app/*)
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
