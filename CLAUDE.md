<!-- BOOTSTRAP BLOCK (Phase 0.0b) — kept verbatim at the top of this file by Phase 21 -->
# CLAUDE.md — bootstrap

You are executing `prompts/01_MASTER_PLANNING_PROMPT.md` autonomously.

- Rules: `docs/AGENT_RULES.md` (once it exists; until then the CONTRACT, OPERATING MODE and register in the prompt).
- State: `docs/PROGRESS.md` — read it first, continue from `NEXT_ACTION`, never restart.
- Never ask; never end the turn before `RUN_STATUS` is terminal.
- Figma reads only through the hooks; cached nodes are never re-read.
- Source facts specific to this folder: `prompts/SOURCE_MAP.md`.

## NEVER list
- C-3: NEVER modify any Figma file; force-push or rewrite Git history; delete branches or tags; publish, deploy, submit, or purchase; touch files or personal data outside the project folder; run `sudo` or any command that reads from the terminal; print a secret; write production application code (only `/poc`).
- No `use_figma`, `create_new_file`, `upload_assets`, `generate_diagram`, shader, generative-plugin, Code Connect write or Weave tool.
- No `git push --force`/`-f`/`--force-with-lease`/`--delete`, no `reset --hard`, `filter-branch`, `rebase -i`, no deleting branches or tags, no deleting files outside the project folder.
- No `xcrun altool`, no `xcodebuild -exportArchive`, no TestFlight or App Store submission, no App Store Connect records, no paid infrastructure, no purchases, no account-setting changes.
- No email or messages, no calendar or reminders changes, no personal data outside the project folder.
- Never expose secrets, tokens, API keys or private configuration values in any file, log or message.
- Never uninstall or reconfigure any existing plugin, MCP server or skill. Never call `/usage-credits`, `/model`, `/login`, `/config`, or edit `~/.claude/settings.json`.

## Product red lines (one line each; the full table lives in docs/AGENT_RULES.md)
- RL-1: Never suggest when or how much to take, boosters included. Tasks move; doses never do.
- RL-2: No pharmacology language in the UI; users see "focus window" and "your focus pattern, from what you've logged".
- RL-3: Discreet mode: no drug names on the Lock Screen, notifications, widgets, Live Activities, Control Center controls, Siri responses, complications or calendar titles/notes.
- RL-4: No red overdue counts, no daily streaks, no "missed" language; planned breaks read as "planned".
- RL-5: The Say / Don't-say table applies to every user-facing string on every surface.
- RL-6: Reminders fire only at times the user set; the app never computes, proposes or moves a medication reminder time, and never sends a catch-up or booster prompt.
- RL-7: No screening, diagnosis, symptom scoring or condition inference; the persistently-low-check-ins feature signposts, never labels.
- RL-8: No alerts, insights or copy that tie Health data (sleep, workouts, heart rate) to medication or to a condition.
- RL-9: No health data leaves the device except a user-initiated share-sheet export, the OS device backup, and on-device HealthKit reads; no analytics or crash payload contains health data; no third-party SDK at MVP.
<!-- END BOOTSTRAP BLOCK -->

<!-- END OF FILE -->
