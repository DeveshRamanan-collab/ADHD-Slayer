# USER ACTIONS — everything only Devesh can do, grouped by when it is needed
How to use: do the items in the earliest group first; change `Status: PENDING` to `Status: DONE` when finished (or write what happened); Claude Code re-reads this file on every resume and at every milestone. Nothing waits on these; Claude Code works around them until they are done.
Last updated: 2026-10-01T13:54:46+1000 · Pending: 7 · Done: 0

## Before the build starts (MS-00)

> ## USER ACTION REQUIRED — UA-001: Free up disk space to at least 50 GB
> **Needed before:** MS-00 Scaffold
> **Blocking now?** NO — the planning run needs little space; the build needs much more
> **Why:** The Mac has 13 GB free and Xcode builds, simulators and archives need tens of GB.
> **Takes about:** 15 minutes
> **Steps:**
> 1. Click the Apple menu (top-left) → System Settings.
> 2. Click General → Storage.
> 3. Wait for the bars to load, then use the Recommendations (for example Empty Trash Automatically, Review Large Files) to delete files you no longer need.
> 4. Open Finder, choose `Go → Go to Folder…`, type `~/Library/Developer/Xcode/DerivedData` and press Return; you may delete everything inside that folder (Xcode rebuilds it).
> **You will know it worked when:** System Settings → General → Storage shows at least 50 GB available.
> **If it fails:** Write what you saw after Status: and Claude Code will pick it up on the next resume.
> **Status:** PENDING   ← Devesh changes this to DONE (or writes what happened)
> Created: 2026-10-01T13:54:46+1000 by Phase 0.1 · Also recorded in: B-002

> ## USER ACTION REQUIRED — UA-002: Confirm whether your Apple Developer account is the paid Apple Developer Program or a free Personal Team
> **Needed before:** MS-00 Scaffold (free team is enough for the Simulator); MS-07 Glanceables (device features); MS-11 TestFlight (paid required)
> **Blocking now?** NO — Claude Code builds for the Simulator either way
> **Why:** A code-signing identity exists on this Mac (Apple Development, team W8V95U7AXJ) but its membership type cannot be read from Terminal; TestFlight and some capabilities need the paid programme.
> **Takes about:** 5 minutes
> **Steps:**
> 1. Open Xcode.
> 2. In the menu bar click `Xcode → Settings…`.
> 3. Click Accounts at the top.
> 4. Select your Apple Account on the left and look at the Team list on the right: it says either "(Personal Team)" or shows a role such as "Admin" or "Account Holder".
> **You will know it worked when:** You can write either "Personal Team" or "paid programme" after Status:.
> **If it fails:** If no account is listed, click + at the bottom-left, choose Apple Account and sign in, then repeat step 4.
> **Status:** PENDING   ← Devesh changes this to DONE (or writes what happened)
> Created: 2026-10-01T13:54:46+1000 by Phase 0.1 · Also recorded in: none

## Before MS-05 — Dose log and focus window

> ## USER ACTION REQUIRED — UA-003: Connect and prepare your iPhone and Apple Watch for development
> **Needed before:** MS-05 Dose log and focus window (on-device checks, Level C)
> **Blocking now?** NO — Simulator testing continues; device-only checks wait
> **Why:** No physical iPhone or Apple Watch was visible to Xcode on 2026-10-01; device checks (alarms, Lock Screen, Watch haptics) need them.
> **Takes about:** 20 minutes
> **Steps:**
> 1. On the iPhone open Settings → Privacy & Security → scroll to Developer Mode → turn it on and restart when asked.
> 2. Connect the iPhone to the Mac with a cable (first time) and tap Trust on the phone, entering the passcode.
> 3. In Xcode click Window → Devices and Simulators (Xcode 27 also offers Xcode → Open Developer Tool → Device Hub) and check the iPhone appears with no warning.
> 4. On the Apple Watch open Settings → Privacy & Security → Developer Mode → turn it on; keep it paired with the iPhone and near the Mac.
> **You will know it worked when:** The iPhone and the Watch both appear in the Xcode device list without a yellow warning.
> **If it fails:** If the phone shows "Untrusted Developer" after the first install, open Settings → General → VPN & Device Management and trust your developer certificate.
> **Status:** PENDING   ← Devesh changes this to DONE (or writes what happened)
> Created: 2026-10-01T13:54:46+1000 by Phase 0.1 · Also recorded in: none

## Before public TestFlight / release (lawyer, entity, privacy policy hosting, trade mark, TGA self-assessment signature, crisis-number check)

> ## USER ACTION REQUIRED — UA-004: Accept the App Store Connect agreements
> **Needed before:** MS-11 TestFlight candidate
> **Blocking now?** NO — nothing before MS-11 needs it
> **Why:** TestFlight uploads fail until the current agreements are accepted.
> **Takes about:** 5 minutes
> **Steps:**
> 1. Open https://appstoreconnect.apple.com in Safari and sign in.
> 2. If a banner asks you to review an agreement, click it and accept.
> 3. Click Business (or Agreements, Tax, and Banking) and check the Free Apps agreement shows Active.
> **You will know it worked when:** The Free Apps agreement shows Active.
> **If it fails:** If you only have a Personal Team (UA-002), App Store Connect will not let you in — this is expected until you join the paid programme.
> **Status:** PENDING   ← Devesh changes this to DONE (or writes what happened)
> Created: 2026-10-01T13:54:46+1000 by Phase 0.1 · Also recorded in: none

## Do when convenient (nothing waits on these)

> ## USER ACTION REQUIRED — UA-005: Turn on automatic continue at usage limits in Claude Code
> **Needed before:** none — do when convenient
> **Blocking now?** NO
> **Why:** If Claude Code hits a usage limit while you are away, it can wait and continue by itself (Claude Code v2.1.234 or later; this Mac has v2.1.286) — whether it is switched on could not be read.
> **Takes about:** 2 minutes
> **Steps:**
> 1. In the Claude Code window type /config and press Return.
> 2. Find the setting about continuing automatically at the usage limit and make sure it is on.
> 3. Press Escape to close.
> **You will know it worked when:** The setting shows as on.
> **If it fails:** If you cannot find it, do nothing: if the session stops at a limit, paste the text of prompts/03_RESUME_PROMPT.md into Claude Code after the reset time shown.
> **Status:** PENDING   ← Devesh changes this to DONE (or writes what happened)
> Created: 2026-10-01T13:54:46+1000 by Phase 0.1 · Also recorded in: none

> ## USER ACTION REQUIRED — UA-006: Do not install macOS or Xcode updates while a run is in progress
> **Needed before:** none — do when convenient
> **Blocking now?** NO
> **Why:** An update restart would end the session mid-run; one optional update (Pro Video Formats 3.2) is waiting.
> **Takes about:** 2 minutes
> **Steps:**
> 1. Click the Apple menu → System Settings → General → Software Update.
> 2. Click the (i) next to Automatic Updates and turn off "Install macOS updates" and "Install application updates from the App Store" until the build is finished.
> **You will know it worked when:** Automatic installs are off; you install updates yourself between runs.
> **If it fails:** Nothing to fix; leave updates for later.
> **Status:** PENDING   ← Devesh changes this to DONE (or writes what happened)
> Created: 2026-10-01T13:54:46+1000 by Phase 0.1 · Also recorded in: none

> ## USER ACTION REQUIRED — UA-007: Optional: a Figma personal access token for stronger version locking
> **Needed before:** none — do when convenient
> **Blocking now?** NO — the lock uses node fingerprints without it
> **Why:** With a token, Claude Code can read the Figma file's official version number and last-modified time.
> **Takes about:** 5 minutes
> **Steps:**
> 1. In Figma click your profile picture → Settings → Security → Personal access tokens → Generate new token, with read-only file access.
> 2. Copy the token. Never paste it into a file in the project.
> 3. Before starting Claude Code next time, in Terminal type: export FIGMA_TOKEN=<your token> and press Return, then start Claude Code in the same window.
> **You will know it worked when:** docs/PREFLIGHT.md on the next run says "REST route available".
> **If it fails:** Skip this; it is optional.
> **Status:** PENDING   ← Devesh changes this to DONE (or writes what happened)
> Created: 2026-10-01T13:54:46+1000 by Phase 0.1 · Also recorded in: none

## Done

none yet

<!-- END OF FILE -->
