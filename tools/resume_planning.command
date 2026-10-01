#!/bin/bash
# Double-click to restart the Claude Code planning run after it was closed, crashed, or the Mac restarted.
# It picks up where the last session stopped (prompts/03_RESUME_PROMPT.md, Variant B). It never starts over.
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"
cd "$HOME/ADHD Slayer" || { echo "Can't find the ADHD Slayer folder in your home folder."; read -r; exit 1; }
[ -f tools/resume_message.txt ] || { echo "Can't find tools/resume_message.txt."; read -r; exit 1; }

bash tools/check_mac.sh

echo "Restarting Claude Code in: $(pwd)"
echo "It will read where it got to and carry on. Leave this window open and don't type in it."
echo
exec caffeinate -is claude --dangerously-skip-permissions "$(cat tools/resume_message.txt)"
