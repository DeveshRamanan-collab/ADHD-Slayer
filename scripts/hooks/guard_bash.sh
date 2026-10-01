#!/usr/bin/env bash
source "$(dirname "$0")/_lib.sh"; read_stdin
cmd="$(jget tool_input.command)"
deny='(^|[;&|[:space:]])(sudo|su)([[:space:]]|$)|git[[:space:]]+push\b.*(--force|-f\b|--force-with-lease|--delete|:refs)|git[[:space:]]+(reset[[:space:]]+--hard|filter-branch|rebase[[:space:]]+-i|branch[[:space:]]+-D|tag[[:space:]]+-d|push[[:space:]]+--mirror)|rm[[:space:]]+-[a-zA-Z]*r[a-zA-Z]*[[:space:]]+(/|~|\$HOME|\.\.)([[:space:]]|$)|xcrun[[:space:]]+altool|xcodebuild[[:space:]].*-exportArchive|xcodebuild[[:space:]]+-license|gh[[:space:]]+auth[[:space:]]+login|curl[^|]*\|[[:space:]]*(ba)?sh|claude[[:space:]]+.*--dangerously-skip-permissions'
if printf '%s' "$cmd" | grep -Eq "$deny"; then
  block "BLOCKED by guard_bash (NEVER list / interactive command): $cmd — record a B-nnn or UA-nnn and continue with other work."
fi
# Figma desktop-app transport check is the reader's job; hooks do not run pgrep here.
exit 0
