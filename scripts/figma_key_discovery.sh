#!/usr/bin/env bash
# Phase 1.1 item 1: list every distinct Figma file key in the inputs and git history, with where it was found. Read-only.
[ "${1:-}" = "--help" ] && { sed -n '2p' "$0"; exit 0; }
cd "$(dirname "$0")/.."
re='figma\.com/(design|board|file|proto|make|slides)/([A-Za-z0-9]{10,})'
echo "## files"; grep -rEo "$re" prompts docs/build-spec docs/copy docs/research-notes docs/system-design.md docs/api-design.md docs/design-critique.md design research ./*.md app tools 2>/dev/null | sort | uniq -c
echo "## git log -p"; git log -p --all 2>/dev/null | grep -Eo "$re" | sort | uniq -c
echo "## distinct keys"; { grep -rEoh "$re" prompts docs/build-spec docs/copy docs/research-notes docs/*.md design research ./*.md app tools 2>/dev/null; git log -p --all | grep -Eo "$re"; } | sed -E 's#.*/##' | sort | uniq -c
