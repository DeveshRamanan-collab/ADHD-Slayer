#!/usr/bin/env bash
# Phase 0.1 preflight probes. Usage: scripts/preflight_probe.sh <section>
# Sections: env | git | apple | sims | pkg | devices | config | swupdate. Never prints secrets (env values are reported set/unset only).
[ "${1:-}" = "--help" ] && { sed -n '2,3p' "$0"; exit 0; }
set -u
cd "$(dirname "$0")/.."
sec="${1:-env}"
h() { echo; echo "## $*"; }
case "$sec" in
env)
  h pwd; pwd
  case "$PWD" in "$HOME/Desktop"*|"$HOME/Documents"*|"$HOME/Downloads"*|"$HOME/Library/Mobile Documents"*) echo "LOCATION: protected/iCloud folder";; *) echo "LOCATION: not under Desktop/Documents/Downloads/iCloud Drive";; esac
  h presence; for p in docs/design research prompts SPEC_CHECKLIST.md prompts/figma_urls.md .git; do [ -e "$p" ] && echo "present: $p" || echo "missing: $p"; done
  echo "xcode projects:"; find . -name '*.xcodeproj' -not -path './.git/*' 2>/dev/null; echo "swift packages:"; find . -name Package.swift -not -path './.git/*' 2>/dev/null
  h claude; command -v claude; claude --version 2>&1
  h env-vars; for v in ANTHROPIC_API_KEY CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS FIGMA_TOKEN CLAUDECODE CLAUDE_CODE_ENTRYPOINT; do if [ -n "${!v:-}" ]; then if [ "$v" = CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS ] || [ "$v" = CLAUDECODE ] || [ "$v" = CLAUDE_CODE_ENTRYPOINT ]; then echo "$v=${!v}"; else echo "$v: SET (value not printed)"; fi; else echo "$v: unset"; fi; done
  h date; date +%Y-%m-%dT%H:%M:%S%z; date -u +%Y-%m-%dT%H:%M:%SZ; ls -l /etc/localtime | sed 's/.*zoneinfo\///'
  ;;
git)
  h git; git --version; git status --porcelain; echo "user.name: $(git config user.name)"; echo "user.email set: $([ -n "$(git config user.email)" ] && echo yes || echo no)"; git remote -v; git log --oneline -5; git branch -a
  h gh; gh --version; gh auth status 2>&1 | sed -E 's/(gho_|ghp_|github_pat_)[A-Za-z0-9_]+/\1****/g'; echo "login: $(gh api user -q .login 2>&1)"; gh repo view --json name,visibility,url 2>&1
  ;;
apple)
  h xcode-select; xcode-select -p
  h xcodebuild-version; xcodebuild -version 2>&1
  h checkFirstLaunch; xcodebuild -checkFirstLaunchStatus; echo "checkFirstLaunchStatus exit: $?"
  h sdks; xcodebuild -showsdks 2>&1
  h swift; swift --version 2>&1
  h sw_vers; sw_vers
  h disk; df -h /
  h power; pmset -g batt; pmset -g assertions | grep -E 'PreventUserIdleSystemSleep|PreventSystemSleep|caffeinate'
  h signing; security find-identity -v -p codesigning 2>&1 | sed -E 's/[0-9A-F]{40}/<sha1>/'
  ;;
sims)
  h runtimes; xcrun simctl list runtimes 2>&1
  h devices-available; xcrun simctl list devices available 2>&1
  h pairs; xcrun simctl list pairs 2>&1
  ;;
devices)
  h devicectl; xcrun devicectl list devices 2>&1 | head -30
  h xcode-mcp; xcrun mcpbridge --help 2>&1 | head -15; xcrun mcp-server status 2>&1 | head -10
  ;;
pkg)
  h tools; for t in brew npm node python3 jq xcodegen swiftlint swiftformat gh; do printf '%s: ' "$t"; if command -v "$t" >/dev/null; then "$t" --version 2>&1 | head -1; else echo "not installed"; fi; done
  ;;
config)
  h user-settings-keys; python3 -c 'import json,os;p=os.path.expanduser("~/.claude/settings.json");d=json.load(open(p)) if os.path.exists(p) else {};print("top-level keys:",sorted(d.keys()));print("enabledPlugins count:",len(d.get("enabledPlugins",{}) or {}));print("hooks events:",sorted((d.get("hooks") or {}).keys()))'
  h project-settings-keys; python3 -c 'import json;d=json.load(open(".claude/settings.json"));print(sorted(d.keys()), "deny rules:", len(d["permissions"]["deny"]), "hook events:", sorted(d["hooks"].keys()))'
  h plugins; ls ~/.claude/plugins 2>&1; python3 -c 'import json,os
p=os.path.expanduser("~/.claude/plugins/installed_plugins.json")
d=json.load(open(p)) if os.path.exists(p) else {}
pl=d.get("plugins",d)
for k in sorted(pl): print("plugin:",k)' 2>&1
  h skills-user; ls ~/.claude/skills 2>&1
  h agents-user; ls ~/.claude/agents 2>&1
  h mcp-list; claude mcp list 2>&1 | sed -E 's#(https?://[^ ]*)\?[^ ]*#\1?<query masked>#g'
  ;;
swupdate)
  h softwareupdate; softwareupdate -l 2>&1 | head -20
  ;;
esac
exit 0
