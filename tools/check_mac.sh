#!/bin/bash
# Mac readiness check for the Claude Code planning run.
# READ-ONLY: it only looks; it changes, installs and deletes nothing.
# Run it in Terminal with:   bash ~/"ADHD Slayer"/tools/check_mac.sh

P="$HOME/ADHD Slayer"
PROBLEMS=0
WARNINGS=0
G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; B=$'\033[1m'; N=$'\033[0m'
ok()   { printf '  %s✔%s %s\n' "$G" "$N" "$1"; }
bad()  { printf '  %s✘ %s%s\n      Fix: %s\n' "$R" "$1" "$N" "$2"; PROBLEMS=$((PROBLEMS+1)); }
warn() { printf '  %s! %s%s\n      %s\n' "$Y" "$1" "$N" "$2"; WARNINGS=$((WARNINGS+1)); }
have() { command -v "$1" >/dev/null 2>&1; }
head1() { head -n 1 | tr -d '\r'; }

# Claude Code's native installer puts the command here; add it for this check only.
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) PATH="$PATH:$HOME/.local/bin" ;; esac

echo
echo "${B}Mac readiness check for the planning run${N}  ($(date '+%a %d %b %Y, %H:%M'))"

echo
echo "${B}1. The Mac${N}"
v=$(sw_vers -productVersion 2>/dev/null)
maj=${v%%.*}; rest=${v#*.}; min=${rest%%.*}
maj=${maj:-0}; case "$min" in ''|*[!0-9]*) min=0 ;; esac
if [ "$maj" -gt 26 ] 2>/dev/null || { [ "$maj" -eq 26 ] && [ "$min" -ge 6 ]; } 2>/dev/null; then
  ok "macOS $v"
else
  bad "macOS ${v:-unknown} (needs 26.6 or later)" "System Settings → General → Software Update"
fi

if pmset -g batt 2>/dev/null | head1 | grep -q "AC Power"; then ok "Plugged in"
else bad "Running on battery" "Plug in the charger and leave it in for the whole run"; fi

auto=$(defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates 2>/dev/null)
if [ "$auto" = "1" ]; then
  bad "Automatic macOS updates are on (they can restart the Mac mid-run)" "System Settings → General → Software Update → ⓘ next to Automatic Updates → turn off \"Install macOS updates\""
elif [ "$auto" = "0" ]; then ok "Automatic macOS installs are off"
else warn "Couldn't tell whether automatic macOS updates are on" "Check: System Settings → General → Software Update → ⓘ next to Automatic Updates → \"Install macOS updates\" should be off"; fi

free=$(df -g / 2>/dev/null | awk 'NR==2{print $4}')
if [ -n "$free" ] && [ "$free" -ge 50 ] 2>/dev/null; then ok "${free} GB free"
else bad "Only ${free:-?} GB free (needs 50 GB)" "Free up space (Apple menu → System Settings → General → Storage)"; fi

if curl -sI --max-time 10 https://developer.apple.com >/dev/null 2>&1; then ok "Internet works"
else bad "Can't reach developer.apple.com" "Check Wi-Fi; avoid a phone hotspot"; fi

echo
echo "${B}2. Xcode${N}"
xp=$(xcode-select -p 2>/dev/null)
case "$xp" in
  *Xcode*.app*) ok "Command-line tools use Xcode" ;;
  *) bad "Command-line tools point at: ${xp:-nothing}" "Run:  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer   (type your Mac password; nothing shows as you type)" ;;
esac
xv=$(xcodebuild -version 2>&1 | head1)
case "$xv" in
  "Xcode 2"[7-9]*|"Xcode "[3-9][0-9]*) ok "$xv" ;;
  Xcode*) warn "$xv" "Xcode 27 is expected. Update Xcode from the App Store when convenient (not during a run)." ;;
  *) bad "Xcode isn't ready: $xv" "Run:  sudo xcodebuild -license accept   then   sudo xcodebuild -runFirstLaunch" ;;
esac
sv=$(swift --version 2>&1 | head1)
case "$sv" in *"Swift version"*) ok "$(echo "$sv" | sed 's/.*\(Swift version [0-9.]*\).*/\1/')" ;; *) bad "Swift not working" "Fix the Xcode lines above first" ;; esac
rt=$(xcrun simctl list runtimes 2>/dev/null)
if echo "$rt" | grep -q "^iOS 2[7-9]"; then ok "iOS simulator: $(echo "$rt" | grep '^iOS' | tail -1 | cut -d'(' -f1)"
else bad "No iOS 27 simulator" "Xcode → Settings → Components → Get next to iOS"; fi
if echo "$rt" | grep -q "^watchOS 2[7-9]"; then ok "watchOS simulator: $(echo "$rt" | grep '^watchOS' | tail -1 | cut -d'(' -f1)"
else warn "No watchOS 27 simulator" "Needed later for the Watch app: Xcode → Settings → Components → Get next to watchOS"; fi

echo
echo "${B}3. Git and GitHub${N}"
if have git; then ok "git installed"; else bad "git missing" "Fix the Xcode lines above (git comes with Xcode)"; fi
gn=$(git config --global user.name 2>/dev/null); ge=$(git config --global user.email 2>/dev/null)
if [ -n "$gn" ] && [ -n "$ge" ]; then ok "Git name and email set ($gn)"
else warn "Git name or email not set" "Run:  git config --global user.name \"Devesh Ramanan\"   and   git config --global user.email \"you@example.com\" (the email on your GitHub account)"; fi
if have brew; then ok "Homebrew installed"
else warn "Homebrew not installed" "Paste the one-line installer from https://brew.sh into Terminal, then run the 2 or 3 lines it prints at the end"; fi
if have gh; then
  gs=$(gh auth status 2>&1)
  if echo "$gs" | grep -qi "Logged in"; then
    if echo "$gs" | grep -q "'repo'" && echo "$gs" | grep -q "'workflow'"; then ok "GitHub command line logged in"
    else warn "GitHub command line logged in but missing permissions" "Run:  gh auth refresh -h github.com -s repo,read:org,gist,workflow"; fi
  else warn "GitHub command line not logged in (Claude Code can't upload backups without it)" "Run:  gh auth login   (choose GitHub.com → HTTPS → Yes → Login with a web browser), then  gh auth setup-git"; fi
else warn "GitHub command line (gh) not installed (Claude Code can't upload backups without it)" "After Homebrew:  brew install gh   then  gh auth login"; fi

echo
echo "${B}4. Claude Code${N}"
if have claude; then
  ok "Claude Code $(claude --version 2>/dev/null | head1)"
  if [ -n "$ANTHROPIC_API_KEY" ]; then bad "An API key is set (this bills every token and stops the free wait at usage limits)" "Remove the ANTHROPIC_API_KEY line from ~/.zshrc, then open a new Terminal window"
  else ok "No API key set (uses your Max plan)"; fi
  ml=$(claude mcp list 2>&1)
  if echo "$ml" | grep -i "figma" | grep -qiE "connected|✔"; then ok "Figma connected in Claude Code"
  elif echo "$ml" | grep -qi "figma"; then warn "Figma is listed but not connected" "In the project folder run  claude , type  /mcp , pick figma → Authenticate → Allow, then type  /exit"
  else bad "Figma not connected in Claude Code" "Run:  claude mcp add --scope user --transport http figma https://mcp.figma.com/mcp   then  claude , type  /mcp , pick figma → Authenticate → Allow, then  /exit"; fi
  if echo "$ml" | grep -i "xcode" | grep -qiE "connected|✔"; then ok "Xcode connected in Claude Code"
  else warn "Xcode not connected in Claude Code (optional for planning, needed for the build)" "See section 2, item 11 of prompts/00_README_DEVESH.md"; fi
else
  bad "Claude Code (the 'claude' command) isn't installed" "Run:  curl -fsSL https://claude.ai/install.sh | bash   then open a new Terminal window, run  claude  once and log in with your Claude account in the browser"
fi
others=$(pgrep -x claude 2>/dev/null | wc -l | tr -d ' ')
if [ "${others:-0}" -gt 0 ]; then warn "$others Claude Code session(s) already running" "Finish or close every other Claude Code session first, including the Code tab in the Claude app, so two don't edit the project at once"
else ok "No other Claude Code session running"; fi

echo
echo "${B}5. Project folder${N}"
if [ -d "$P" ]; then ok "Found $P"; else bad "Project folder not found at $P" "It should be in your home folder and named exactly: ADHD Slayer"; fi
missing=""
for f in prompts/01_MASTER_PLANNING_PROMPT.md prompts/02_BUILD_KICKOFF_PROMPT.md prompts/03_RESUME_PROMPT.md \
         prompts/04_AGENT_BRIEFS_AND_TEMPLATES.md prompts/05_SETTINGS_AND_HOOKS.md prompts/06_SCRIPT_SPECS.md \
         prompts/figma_urls.md prompts/figma_design_prompt.md prompts/SOURCE_MAP.md \
         research/adhd_struggles.md research/interventions_evidence.md research/medication_pharmacology.md \
         research/regulation_privacy_safety.md research/apple_platform.md research/learning_and_lifestyles.md \
         research/competitors_failure_modes.md; do
  [ -f "$P/$f" ] || missing="$missing $f"
done
if [ -z "$missing" ]; then ok "All planning files are in place"; else bad "Missing:$missing" "Ask Claude to put them back"; fi
if [ -f "$P/.git/index.lock" ]; then bad "Git is locked (.git/index.lock exists)" "Make sure no other app is using the project, then run:  rm \"$P/.git/index.lock\""
else ok "Git isn't locked"; fi

echo
if [ "$PROBLEMS" -eq 0 ]; then
  echo "${G}${B}Ready.${N} $WARNINGS warning(s) above can wait."
else
  echo "${R}${B}$PROBLEMS thing(s) to fix${N} (✘ above) and $WARNINGS warning(s). Fix the ✘ lines, then run this check again."
fi
echo
