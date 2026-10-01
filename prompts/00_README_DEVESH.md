# READ ME FIRST — how to run the Planner planning and build with Claude Code

This folder holds everything Claude Code needs to (1) plan the Planner app from your Figma and documents and (2) build it, on its own, while you are away. You do the one-time setup below, paste one line, and check a few files now and then. The only things you ever fill in are in angle brackets, like `<your project folder>`.

Plain-English words used here: **Terminal** — the Mac app where you type commands; Claude Code runs inside it. **MCP server** — a connector that lets Claude Code talk to another product (Figma, Xcode). **Simulator** — a fake iPhone or Watch that runs on the Mac. **Usage limit** — the cap on how much Claude you can use in a 5-hour block and in a week. **Read (Figma)** — one request by Claude Code for something from your Figma file; Figma counts these and allows 200 a day.

## 1. What each file is

| File | Who reads it | When | What it does |
|---|---|---|---|
| `00_README_DEVESH.md` | You | Now | This guide. Never paste it into Claude Code. |
| `01_MASTER_PLANNING_PROMPT.md` | Claude Code (from disk) | Once, to start planning | Audits its tools, locks the Figma version, reverse-engineers every screen, reconciles the old documents, and writes the full planning package under `docs/`. Ends by tagging `planning-complete`. |
| `02_BUILD_KICKOFF_PROMPT.md` | Claude Code | Once, after planning and the checkpoint in section 5 | Builds the app milestone by milestone with independent reviews, tests and evidence until a TestFlight-ready build exists, or documents exactly why it stopped. |
| `03_RESUME_PROMPT.md` | Claude Code | Any time a session ends before finishing | Restores where it was from the files on disk and continues. Variant A for a clean stop, Variant B after a crash or usage limit. |
| `04_AGENT_BRIEFS_AND_TEMPLATES.md`, `05_SETTINGS_AND_HOOKS.md`, `06_SCRIPT_SPECS.md` | Claude Code (from disk) | Automatically | Templates for its helper agents and progress files; the settings and hooks that stop it asking or ending early; the checking scripts it writes. You never paste these. |
| `figma_urls.md` | Claude Code | Automatically | **You create this** (section 2, item 17). |

Everything Claude Code produces goes into `docs/` inside your project folder. It never edits your Figma, never publishes anything, never force-pushes, and never submits to Apple.

## 2. One-time setup — do all of this BEFORE you launch (30–60 minutes the first time)

Each item: **Do** → **Success looks like** → **Why**. Items marked ★ need your password or your Apple account and cannot be done by Claude Code.

**A. The Mac**
1. ★ **Update macOS, then stop automatic restarts.** System Settings → General → Software Update: install what is offered (Xcode 27 needs macOS 26.6 or later). Then click ⓘ next to "Automatic updates" and turn **off** "Install macOS updates"; in the App Store app → Settings turn **off** "Automatic Updates". *Success:* Software Update says up to date; `sw_vers` in Terminal shows 26.6 or higher. *Why:* an update that installs mid-run reboots the Mac or swaps Xcode under a build.
2. **Power, lid, no sleep.** Plug in the charger; keep the lid open (or attach an external display and keyboard). System Settings → Battery → Options… → "Prevent automatic sleeping on power adapter when the display is off" **on**; Low Power Mode **off**. Just before launching, open a **second** Terminal window and run `caffeinate -is` — leave it open for the whole run (it prints nothing). *Success:* `pmset -g assertions` in a third window lists `PreventUserIdleSystemSleep`; `pmset -g batt` says AC Power. *Why:* a sleeping Mac turns an automatic resume into one that waits for you.
3. **50 GB free disk** (About This Mac → Storage, or `df -h /`). *Why:* Xcode, simulator runtimes, build caches, Git history and the Figma cache.
4. **Stable internet** (`ping -c 3 developer.apple.com` replies). Not a hotspot.
5. **Project folder location.** Use the same folder the Figma design session used (it contains `docs/design/`, `research/`, `prompts/`, `SPEC_CHECKLIST.md`). If it is inside Desktop, Documents, Downloads or iCloud Drive, move it to `~/Developer/` (Finder → Go → Home → create or open "Developer" → drag the folder in), or grant Terminal Full Disk Access (System Settings → Privacy & Security → Full Disk Access → Terminal on). *Why:* macOS pops up a "Terminal would like to access…" dialog the first time, and iCloud Drive can evict files.
6. **Focus on, hands off.** Control Centre → Focus → Do Not Disturb. Never type into the Claude Code window while it runs (Esc interrupts; Ctrl+C twice exits).

**B. Xcode and the Apple toolchain**
7. ★ **Install Xcode 27 from the App Store and open it once.** If a sheet asks which platforms to install, tick iOS and watchOS. *Success:* the Welcome window appears with no "install components" prompt left; `xcodebuild -version` prints Xcode 27.x.
8. **Download the iOS 27 and watchOS 27 simulator runtimes.** Xcode → Settings → Components → Get next to iOS and watchOS; wait for both. *Success:* `xcrun simctl list runtimes` lists iOS 27.x and watchOS 27.x as Ready.
9. ★ **Point the command-line tools at Xcode, accept the licence, finish first-launch tasks.** In Terminal (enter your Mac password when asked): `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer` then `sudo xcodebuild -license accept` then `sudo xcodebuild -runFirstLaunch`. *Success:* `xcode-select -p` prints the Xcode path; `xcodebuild -version` prints a version instead of a licence error; `swift --version` prints Swift 6.4. *Why:* Claude Code cannot type your password; an unaccepted licence fails every build.
10. ★ **Sign your Apple Account into Xcode.** Xcode → Settings → Accounts → + → Apple Account → sign in. *Success:* your name is listed with a team ("Personal Team" until you join the paid program).
11. ★ **Allow Xcode to work with Claude Code.** Xcode → Settings → Intelligence → turn on "Allow external agents to use Xcode tools". On Xcode 27 also run in Terminal: `sudo xcrun mcp-server enable --unsafe-always-allow-all-agents` (it lets Claude Code use Xcode without asking each time; turn it off later with `sudo xcrun mcp-server disable`). Then in the project folder run: `claude mcp add --transport stdio xcode -- xcrun mcpbridge`. *Success:* `claude mcp list` shows `xcode … ✔ Connected` (on Xcode 26 the project must be open in Xcode).
12. ★ **Apple Developer Program — enrol now, needed before the first on-device milestone and for TestFlight.** The fee is US$99 a year (shown in AUD at checkout). Enrol in the Apple Developer app on your iPhone or at developer.apple.com/programs/enroll with two-factor on; if you do not pay with your own card Apple asks for photo ID, which delays approval; Apple confirms within about 24 hours. Simulator-only work does not need it; running on your own phone works on the free Personal Team but the app stops opening after 7 days until re-run from Xcode; TestFlight and the App Store require membership. *Success:* Xcode → Settings → Accounts shows your team without "(Personal Team)". Then log in once at appstoreconnect.apple.com and accept any agreement banner.

**C. iPhone and Apple Watch**
13. ★ **iPhone:** update to iOS 27; plug into the Mac; tap **Trust** on the phone; in Xcode open Device Hub (Xcode → Open Developer Tool → Device Hub) and click **Pair** if offered; on the iPhone: Settings → Privacy & Security → Developer Mode → on → Restart → Enable. *Success:* the iPhone shows as available in Device Hub with no warning. Then do one manual Run of any tiny app to the phone (Xcode → File → New → Project → iOS App → choose your iPhone as destination → Run) and click **Always Allow** on the "codesign wants to sign using key…" keychain prompt; on the phone, Settings → General → VPN & Device Management → trust the developer if asked. *Why:* these prompts can only be answered by you; once answered they never interrupt the run.
14. ★ **Apple Watch:** with the iPhone paired, select the Watch under it in Device Hub; tap **Trust** on the iPhone **and** on the Watch; on the Watch: Settings → Privacy & Security → Developer Mode → Turn On. *Success:* the Watch appears as available.

**D. Tools on the Mac**
15. ★ **Homebrew.** Paste the one-liner from https://brew.sh into Terminal, enter your password, then run the two or three "add to PATH" lines it prints, and open a new Terminal window. *Success:* `brew --version` prints a version.
16. ★ **Git identity and GitHub.** `git config --global user.name "Your Name"` and `git config --global user.email "<the email on your GitHub account>"`. Create a free GitHub account if needed, then `brew install gh`, `gh auth login` (GitHub.com → HTTPS → Yes to authenticate Git → Login with a web browser → paste the code), then `gh auth refresh -h github.com -s repo,read:org,gist,workflow` (approve in the browser) and `gh auth setup-git`. *Success:* `gh auth status` says logged in with scopes including `repo` and `workflow`. Claude Code will create a **private** repository named `planner-app` and push to it; you do not create anything on github.com.

**E. Figma**
17. **Create `prompts/figma_urls.md`.** Open Figma in the browser, open "Planner · Design", copy the address bar URL; do the same for the FigJam board "Planner · Flows". Create a plain-text file `prompts/figma_urls.md` in the project folder (TextEdit → Format → Make Plain Text) containing the two URLs, one per line, and any earlier attempt files marked "old". *Why:* Figma has no "list my files" tool for Claude Code; without this file the run cannot find the prototype and will stop immediately asking for it.
18. **Figma connected in Claude Code.** In Terminal from the project folder: `claude mcp add --scope user --transport http figma https://mcp.figma.com/mcp`; start `claude`, type `/mcp`, select figma → Authenticate → Allow Access in the browser; type `/exit`. *Success:* `claude mcp list` shows `figma … ✔ Connected`. (If Figma is already connected through claude.ai connectors it appears automatically; do not configure both.) Prefer this remote server; the desktop-app local server needs the Figma app open with the file active the whole time. A seat label of "View"/"student" is expected on your Education team — do not try to fix it.
19. **Optional — a Figma personal access token** (strengthens the version lock by exposing last-modified and version history). Figma → account menu → Settings → Security → Personal access tokens → Generate new token → scopes `file_content:read`, `file_metadata:read`, `file_versions:read`. In the **same Terminal window you will launch Claude Code from**, run `export FIGMA_TOKEN=<paste>` and clear your clipboard. Never paste the token into chat or a file. Claude Code only ever refers to the variable name. Skip this if in doubt; the run works without it.

**F. Claude Code**
20. **Latest version, logged in with your Max subscription, no API key.** `claude --version` (`claude update` if it says an update is available); start `claude` in the project folder, type `/status` and `/login` if needed using your claude.ai account; `echo $ANTHROPIC_API_KEY` must print an empty line; if `/config` shows a setting for continuing automatically at a usage limit, turn it on. *Why:* only a subscription login waits and continues after a usage limit; an API key bills every token and removes the wait.
21. ★ **The permission mode and its one-time dialog.** The run uses `claude --dangerously-skip-permissions` — the only mode that never stops to ask. The first time, Claude Code shows a warning dialog; accept it once and it is never shown again. (Anthropic documents this mode as intended for isolated machines; the deny rules and hooks Claude Code installs in Phase 0 are what keep it inside your project folder and off destructive commands. Never run it with `sudo`.) Also accept the "Do you trust the files in this folder?" dialog for the project folder. Leave the model at its default; do not switch to a Fable model unless you have already enabled usage credits and accepted its one-time consent.
22. **Usage credits — decide now.** Off (recommended for planning): the run pauses at each limit and continues by itself after the reset, free; a weekly limit can pause it for days. On (claude.ai → Settings → Usage → Usage credits → Enable, with a monthly cap): it keeps going and bills the extra at API rates. Record your choice.
23. **Dry run (10 minutes, attended).** In the project folder: `claude --dangerously-skip-permissions`, then paste: *Preflight only: run whoami on Figma, git status, gh auth status, xcodebuild -version, xcrun simctl list runtimes, fetch https://developer.apple.com/documentation/ with WebFetch, and spawn one trivial subagent that replies "ok". Report results as a table. Do not read any Figma node. Then stop.* Answer every dialog that appears; type `/exit`. *Success:* all rows OK and no dialog you had not already seen.

## 3. The exact order to paste prompts

**Step 1 — start planning.** In Terminal:
```
cd <your project folder>
claude --dangerously-skip-permissions
```
When the prompt appears, paste exactly this one line and press Enter:
```
Read prompts/01_MASTER_PLANNING_PROMPT.md in full and execute it from Phase 0.0.
```
Stay about 15 minutes until you see the First report (eight numbered items) in the window; answer any dialog that appears. Then walk away.

**Step 2 — wait.** Planning takes many hours and will span two or three days because Figma allows 200 reads a day. The run pauses itself when the day's reads are used and continues with other work; when nothing else is left it stops cleanly with `RUN_STATUS: WAITING_FOR_FIGMA_RESET` and `RETRY_AFTER: <time>` at the top of `docs/PROGRESS.md` — see section 6.

**Step 3 — the one checkpoint (planning → build).** When the final message ends with `WHAT I DO NEXT` (and `docs/COMPLETENESS_AUDIT.md` exists), do section 5.

**Step 4 — start the build.** Same launch command in a fresh session, then paste the **entire contents** of `prompts/02_BUILD_KICKOFF_PROMPT.md` (so your answers in its ANSWERS block are included). Walk away.

**Step 5 — any restart.** Same launch command; paste Variant A or Variant B from `prompts/03_RESUME_PROMPT.md`.

## 4. How to tell it is working while you are away

Glance at these files in Finder/Preview or a second Terminal (`tail -15 docs/PROGRESS.md`). Never edit them while it runs.

| Look at | Healthy | Worrying |
|---|---|---|
| `docs/PROGRESS.md` (top lines) | `UPDATED` within the last hour; `CURRENT_PHASE` advances over the day; `NEXT_ACTION` changes; `RUN_STATUS: RUNNING` or `WAITING_FOR_FIGMA_RESET` with a `RETRY_AFTER` time | `UPDATED` older than two hours with no activity in the Terminal; `RUN_STATUS: STALLED` |
| Terminal window | Tool calls scrolling; one-line phase reports; or a footer "Usage limit reached · continuing automatically at …" | A question waiting for you; a permission dialog; a shell prompt (`%`) instead of Claude Code |
| `docs/BLOCKERS.md` and `docs/USER_ACTIONS.md` | Entries RESOLVED, or `UA-nnn` items with "Needed before" a milestone still ahead | An item marked "Blocking now? YES" |
| `docs/gates/` | `GATE-0.md`, `GATE-1.md` … appearing, each PASS or PASS_WITH_RESIDUALS | A gate at FAIL for hours |
| `docs/figma/read-ledger.md` (last lines) | Count below 150 for the day; `LIMIT-RESET-OBSERVED` after a pause | Repeated `error auth` rows (re-authenticate Figma: in the session type `/mcp` → figma → Authenticate — only when it is not mid-task) |
| During the build: `docs/milestones/` | `MS-00-report.md`, `MS-01-report.md` … each listing tests run and features VERIFIED | Reports with many UNVERIFIED rows |

Silence in the chat for long stretches is normal. Working vs stuck: working if `UPDATED` is under 30 minutes old, or tool calls are scrolling, or the footer shows a usage-limit wait; waiting for you if a dialog is visible; stuck only if none of those for over 60 minutes — then section 6.

**What not to do while it runs:** type in its Terminal window; close the window, quit Terminal, log out, restart or close the lid; edit, rename or delete anything in the project folder; open the project in Xcode and press Run/Build while it is building (reading is fine); edit the Figma files or sign out of Figma; start a second `claude` in the same folder; install macOS/Xcode updates; change usage credits, model or settings unless section 6 says so.

## 5. The single checkpoint between planning and building

1. Open `docs/OPEN_QUESTIONS.md`. The group **Must answer before coding** has a handful of questions, each with options, a recommended default and a line `ANSWER:` pre-filled with the default. Change an `ANSWER:` line only if you disagree (TextEdit in plain-text mode). Doing nothing accepts every default.
2. Open `docs/USER_ACTIONS.md`. Do the items in "Before the build starts (MS-00)" and write `DONE` after `Status:` for each.
3. Read `docs/WHAT_I_DO_NEXT.md` (the planning run's final report) — it repeats the above and names the first milestone.
4. Paste `02_BUILD_KICKOFF_PROMPT.md` (section 3, step 4). You may also type answers into its ANSWERS block (`- Q-004: B`) instead of editing the file.

## 6. What to do if it stops

| What you see | What it means | What to do |
|---|---|---|
| Final report with `WHAT I DO NEXT` | Planning finished | Section 5 |
| A message that the build is TestFlight-ready, or `docs/STOP_REPORT.md` exists | Build finished, or stopped for a documented reason | Read the report; do any `UA-nnn`; if stopped, paste Variant A after doing them |
| `Usage limit reached · continuing automatically at 3:45pm` | Your plan's limit for now | Nothing. Do not press Esc, Ctrl+C or type. Leave the window open; the Mac must not sleep |
| `Your usage limit has reset · press enter to continue` | The Mac slept | Click into the window, press Enter once, fix the sleep setting (section 2, item 2) |
| `Automatic continue stopped after repeated usage-limit hits · /rate-limit-options to try again` | Three limits in a row | Type `/rate-limit-options` → choose "Wait here, then continue automatically" |
| `You've hit your weekly limit · resets Mon 12:00am` (more than 24 h away) | Weekly cap | Free option: wait until after the reset, then paste Variant B. Paid option: type `/usage-credits`, enable credits with a cap in the browser, return — it continues by itself |
| `RETRY_AFTER: <time>` at the top of `docs/PROGRESS.md`, session ended cleanly | Today's Figma reads are used and nothing else is left | After that time, relaunch and paste Variant A |
| A dialog **Resume from summary / Resume full session as-is** | You are reopening an old session | Choose **Resume full session as-is** |
| Terminal closed, Mac rebooted, a shell prompt, or nothing changed for over an hour | Crash, sleep or stall | Relaunch (same folder, same flag) and paste Variant B |
| A permission dialog | You launched without `--dangerously-skip-permissions` | Approve it, `/exit`, relaunch with the flag, paste Variant A |
| It asked you a question in prose | It should not | Reply exactly: `Do not ask. Adopt the recommended default, log it in docs/OPEN_QUESTIONS.md and docs/DECISION_LOG.md, and continue (contract rule C-2).` |

Nothing is lost by restarting: all state is in `docs/` and in Git. A restart never starts over.

## 7. Manual actions during the build, batched by milestone

Claude Code lists each batch in `docs/USER_ACTIONS.md` **before** the milestone that needs it; nothing waits on you — a milestone that needs an undone item is skipped and returned to. Expect, roughly: **before MS-00** — Developer Program approved, Xcode account shows the paid team, iPhone and Watch paired with Developer Mode on, one manual signed Run done (section 2 items 12–14), a Watch simulator created in Device Hub; **first on-device milestone** — keep the iPhone unlocked and on Wi-Fi, tap Allow on Notifications, Calendar (Full Access) and Health (sleep and workouts) sheets; **glanceables** — add the Home Screen and Lock Screen widgets, the Control Center control and the Action button assignment by hand, start a Live Activity when asked and photograph the Lock Screen; **Watch** — install the Watch app if it does not auto-install, add the complication to a face, wear the Watch for haptics; **Siri** — say the phrases it lists and report; **TestFlight** — you create the App Store Connect record with the exact values it gives you, host the privacy policy it writes (a GitHub Pages page is enough), answer the App Privacy and export-compliance questions from `docs/RELEASE_CHECKLIST.md`, add yourself as an internal tester, and press Upload/Distribute yourself (Claude Code prepares the archive and the clicks; it never submits); **release** — age rating, pricing, screenshots check, review notes (drafted by it, entered by you), Submit for Review; and before public release, the lawyer/entity/trade-mark/TGA-self-assessment batch listed in `docs/USER_ACTIONS.md`.

## 8. If you want to see the app early
After the first UI milestone its report says so and leaves a `UA-nnn` telling you how to open the project in Xcode and press Run to see it in the Simulator. `docs/DEVESH_BUILD_GUIDE.md` has the full beginner's guide from Simulator to TestFlight.

<!-- END OF FILE -->
