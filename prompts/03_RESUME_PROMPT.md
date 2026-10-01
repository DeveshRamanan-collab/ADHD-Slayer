# RESUME PROMPTS — paste one variant into a fresh Claude Code session started in the project folder with `claude --dangerously-skip-permissions`

Both variants work for the planning run and the build run because the state files are the same. Use Variant A after a clean stop (finished a Figma epoch and the `RETRY_AFTER` time in `docs/PROGRESS.md` has passed, or you closed it). Use Variant B after anything abrupt (usage limit that did not auto-continue, crash, Mac slept or rebooted, Terminal closed, `STALLED`).

---

## VARIANT A — normal restart

```
Resume. You are the ORCHESTRATOR continuing an autonomous run in this project folder. Devesh is away. Do not ask anything; do not wait for a reply; do not call AskUserQuestion. Do not restart from the beginning.

1. Read, in order: docs/PROGRESS.md, docs/AGENT_RULES.md (its contract, operating mode OM-1–OM-7 and register F1–F30 bind you), the last 40 lines of docs/DECISION_LOG.md, all of docs/BLOCKERS.md, docs/agents/hooks/elicitations.md if it exists (merge it into docs/BLOCKERS.md as B-nnn entries, then rename it elicitations.merged-<ISO-compact>.md), docs/USER_ACTIONS.md, docs/OPEN_QUESTIONS.md, the epoch header and last 10 rows of docs/figma/read-ledger.md, and CLAUDE.md. Log the files read to docs/evidence/resume/<ISO-compact>.log via scripts/run_logged.sh.
2. Determine the run from docs/PROGRESS.md: PLANNING (prompts/01_MASTER_PLANNING_PROMPT.md governs) or BUILD (prompts/02_BUILD_KICKOFF_PROMPT.md governs). Read that prompt file from disk in full now; its contract applies; re-read the section for CURRENT_PHASE (or the current milestone step).
3. If RUN_STATUS is WAITING_FOR_FIGMA_RESET and RETRY_AFTER has not passed: do only work in docs/WORK_QUEUE.md; if the queue is empty, update PROGRESS and end cleanly (the Stop hook permits this status). If RETRY_AFTER has passed: write `retry` to docs/figma/.intent, probe with the next needed read from docs/figma/read-plan.md, and on success set RUN_STATUS RUNNING and log LIMIT-RESET-OBSERVED.
4. Verify state before continuing: every artefact PROGRESS lists as DONE exists, ends with <!-- END OF FILE --> and passes scripts/validate_docs.py; any that does not is re-opened as the current step; any *.PARTIAL.md is finished first. `git status` is clean or shows only work described in PROGRESS; `git log -3` matches PROGRESS's last checkpoint. Every ledger `ok` row has a cache file; every cache file has a ledger row (add `recovered` rows if not); reads in the last 24 h are counted against the cap.
5. Apply anything Devesh changed: edited `ANSWER:` lines in docs/OPEN_QUESTIONS.md (log D-nnn; update [ASSUMPTION-nnn] and dependent tasks); `Status: DONE` in docs/USER_ACTIONS.md (unblock the deferred steps that listed them). Retry every OPEN B-nnn once; record the result.
6. Re-check the Figma lock if the next action is Figma-derived or a UI milestone (write lock-check to docs/figma/.intent; one get_metadata of the root; fingerprint compare; delta audit if changed).
7. Set RUN_STATUS RUNNING (unless step 3 says otherwise), update the PROGRESS header, and continue from NEXT_ACTION. Do not re-read cached nodes. Do not re-ask anything answered in DECISION_LOG or OPEN_QUESTIONS. Do not redo passed gates. Report in one line: "Resumed at <phase or milestone>/<step>; next: <action>." Then continue in the same turn.
```

---

## VARIANT B — after a crash, usage limit, lost context, sleep, or STALLED

```
Resume after an abrupt stop. You are the ORCHESTRATOR continuing an autonomous run that ended without a clean checkpoint. Devesh is away. Do not ask anything; do not wait for a reply; do not call AskUserQuestion. Do not restart from the beginning. Assume the last minutes of work before the interruption may be incomplete or unrecorded.

1. Do Variant A steps 1–2 first.
2. Recover, logging every finding to docs/evidence/resume/resume-recovery-<ISO-compact>.log:
   a. `git status`, `git stash list`, `git worktree list`, `git branch --show-current`, `git log -5`. Uncommitted changes: inspect the diff; if they belong to the step PROGRESS names as in progress, commit them as "WIP recovered <ISO>: <step>" on the current branch; if unexplained, move them to a branch recovered-<ISO date> and log B-nnn. Never discard changes; never reset --hard.
   b. Half-written files: every path that docs/MANIFEST.md lists as IN PROGRESS or DONE, every file under docs/parts/ and docs/figma/analysis/, and every output named in an un-merged brief (docs/agents/*/outputs.txt), that lacks <!-- END OF FILE --> is INCOMPLETE. Keep it, note its last complete section, rename it <name>.PARTIAL.md with a final line "PARTIAL: resume at <heading>", and set the current step to completing it. Never assume the missing part was written elsewhere. Never rename, edit or recreate docs/figma/read-ledger.md, anything under docs/figma/raw/ or docs/evidence/, docs/figma/.intent, docs/figma/*.csv or any nodes.json.
   c. Ledger vs cache: a cache file with no ledger row → append the row marked `recovered`; a ledger row marked `pending` with no cache file → the read is lost: mark the node [NOT YET READ] in the read plan and re-read it later within the cap (tag retry). Count reads in the last 24 h; at or above the cap, do only non-Figma work.
   d. Subagents and worktrees: any worktree with uncommitted work is treated as in (a); any subagent output file not yet spot-checked by the orchestrator is untrusted — spot-check it (C-11) before integrating; re-dispatch any brief whose owned files are missing or PARTIAL.
   e. Gates: if PROGRESS shows a gate IN PROGRESS, re-run the gate from its first item; do not trust a partial docs/gates/ file.
   f. STALLED: read the stop_guard log line in PROGRESS; the cause is usually a turn that ended with RUN_STATUS RUNNING and nothing changing — identify the item that was looping, record it as B-nnn with what was tried, and set NEXT_ACTION to the next independent item.
   g. Usage limit or context loss: nothing else to recover; PROGRESS's NEXT_ACTION stands.
3. Add a row to the Sessions table in docs/PROGRESS.md: previous session ended abruptly at approximately <timestamp of the newest file or commit>; recovered items; current step. Clear .claude/hookstate/stop_count.
4. Continue with Variant A steps 3–7.
```

---

## If the Terminal shows a prose question instead of working
Reply with exactly: `Do not ask. Adopt the recommended default, log it in docs/OPEN_QUESTIONS.md and docs/DECISION_LOG.md, and continue (contract rule C-2).`

<!-- END OF FILE -->
