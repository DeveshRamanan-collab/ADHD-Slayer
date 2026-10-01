#!/bin/bash
# Double-click to start the Claude Code planning run for ADHD Slayer.
# It runs the read-only readiness check, then starts Claude Code with the planning message.
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"
cd "$HOME/ADHD Slayer" || { echo "Can't find the ADHD Slayer folder in your home folder."; read -r; exit 1; }

bash tools/check_mac.sh

echo "Starting Claude Code in: $(pwd)"
echo "First time only: when it shows the 'Bypass Permissions' warning, use the arrow keys to pick 'Yes, I accept' and press Enter."
echo "Then watch until the First report (8 numbered points) appears, and leave this window open."
echo
exec caffeinate -is claude --dangerously-skip-permissions "Read prompts/SOURCE_MAP.md first, then read prompts/01_MASTER_PLANNING_PROMPT.md in full and execute it from Phase 0.0."
