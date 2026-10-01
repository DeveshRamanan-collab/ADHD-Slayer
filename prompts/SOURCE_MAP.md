# Source map for the planning run

Written on 1 Oct 2026 while preparing Devesh's Mac, before the planning run started. These are facts about this folder where it differs from what `prompts/01`–`06` expect. They are information, not new rules: every rule in `prompts/01_MASTER_PLANNING_PROMPT.md` still applies.

## Figma
- One design file, key `gLuoHFbiiUGajAUpluWXOW` (URLs in `prompts/figma_urls.md`). Devesh says the design is finished.
- It is not named "Planner · Design" and does not use the page list in K.1. Known pages and sections:
  - `83:2` "iPhone v4: complete build" (77 screens, components and tokens)
  - `114:2` "Build spec: everything needed to build Focus"
  - `94:1246` "Copy deck: 100 versions of every line"
  - `0:1` "Cover"
- On 1 Oct, `get_metadata` with no nodeId listed only "Cover", so start from the node ids above.
- No FigJam "Planner · Flows" board is known.
- Two Figma reads were used on 1 Oct during setup (the page list and `114:2`).

## Design-session documents
- The K.2 design-session outputs (`docs/design/*.md`, root `SPEC_CHECKLIST.md`) do not exist. The design sessions wrote these instead:
  - `docs/build-spec/01`–`11` plus `_context.md` and `_resume.md`: the latest product decisions, mirrored on the Figma "Build spec" page. `_context.md` § "Decisions already made" lists Devesh's decisions of 30 Sep.
  - `docs/copy/`: copy deck sources.
  - `docs/system-design.md`, `docs/api-design.md`, `docs/design-critique.md`.
  - `design/figma/README.md`, plus unpublished Figma shader and plugin sources.
  - `docs/research-notes/`: extraction notes from `research/`.
- `research/ADHD planner product design and research.pdf` is a PDF export (28 Sep 2026) of the main design document, the Claude Docs artefact named in K.2.

## How the product has moved on from `prompts/figma_design_prompt.md`
- Working name "Focus"; the folder is "ADHD Slayer"; bundle id prefix `au.adhdslayer.focus`.
- Dark mode first.
- Accounts: Sign in with Apple, Google or an email link.
- "Plus" subscription through StoreKit 2.
- Optional bring-your-own AI.
- End-to-end encrypted sync with Australian hosting (marked To build).
- Several of these conflict with K.5 defaults (local-only MVP, no third-party AI, pricing). K.3 says the Figma is newer than the design brief.

## Code
- `app/FocusApp` is a SwiftUI prototype. `app/FocusCore` is a Swift package with 31 passing tests.
- On 1 Oct Devesh had the unfinished backend, the iPhone backend client and the Live Activity / widget code removed. The app was restored to its 30 Sep 11:51 state.
  - The removed code is still in git history (commit `1261b39`, "Initial commit").
  - Its contract is kept as `docs/build-spec/11-backend-contract.md` (To build).
- `app/FocusApp/FocusApp/Copy.json` still has 15 lines using the banned word "peak". The Figma copy deck was corrected on 1 Oct; the app file was not.

## Git
- The repository already exists, with `origin` at `https://github.com/DeveshRamanan-collab/ADHD-Slayer` (private). It is not named `planner-app`.
- `.git/index.lock.stale-from-claude-check` is an empty leftover file from setup. Ignore it.
