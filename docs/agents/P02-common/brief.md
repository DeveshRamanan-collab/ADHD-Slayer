# BRIEF P02-source-notes-<slug> (common part; your specific inputs and part number are in your spawn message)
Phase: 2. Role: analyst. Project root: /Users/deveshramanan/ADHD Slayer (run commands from there).

## Goal
One part file docs/parts/SOURCE_NOTES/<nn>-<slug>.md listing, for every input document assigned to you, everything it asserts that the Figma design must be checked against (features, screens, states, rules, numbers, defaults, wording) — the denominator for the Phase 5 reconciliation.

## Read first
1. docs/AGENT_RULES.md — binding (contract, F1–F30, red lines RL-1–RL-9).
2. prompts/01_MASTER_PLANNING_PROMPT.md — grep "# PHASE 2" (Phase 2 text) and "## K.3", "## K.5" (conflict resolution; brief defaults).
3. prompts/SOURCE_MAP.md — how this folder differs from the prompt (product now "Focus"; docs/design/ does not exist; substitutes).
4. Your assigned inputs, every one IN FULL (no skimming; large files in chunks of ≤ 400 lines until the end).

## Output structure (exactly)
```
## <nn> — <group title>
Inputs read (path | lines):
| path | lines (wc -l) |
...
### <input path>
| Source (path#heading) | Assertion (≤40 words; quote wording where wording matters, inside backticks) | Scope tier (MVP / v1 / Future / unstated) | Check in Phase 5 (what to look for in the Figma) |
|---|---|---|---|
| docs/build-spec/01-product-and-features.md#First launch | ... | MVP | ... |
(one table per input; every heading of every input that asserts anything gets ≥1 row; headings that assert nothing are listed in one line "No checkable assertions: <headings>")
### Conflicts noticed between your inputs (optional)
| Source A | Source B | Conflict (quote both, ≤40 words each) |
<!-- END OF FILE -->
```
- No ids from the identifier scheme are defined here (no FEAT-/Q-/D- definitions). Scope tier comes from the source's own words; "unstated" if it has none.
- Assertions that would breach a red line (dose timing advice, pharmacology words in UI, streaks, "missed", Health→medication links, health data leaving the device) are still recorded faithfully and tagged `[RED-LINE RL-n]` in the Check column.
- Words quoted from a source go in backticks so the validator's phrase checks ignore them.

## Rules
- Never call a Figma tool or AskUserQuestion; never ask in prose (`OPEN: <q> → <default>` in your report). Never run git. Never edit any input.
- Write ONLY docs/parts/SOURCE_NOTES/<nn>-<slug>.md and docs/agents/P02-<slug>/* (notes.md, questions.md, outputs.txt).
- Log what you read: `CLAUDE_AGENT_ID=P02-<slug> scripts/run_logged.sh p02-inputs-<slug> -- wc -l <your input paths>` and cite it in notes.md.
- No "etc.", "and so on", ellipses, "similar to the above", "for brevity", TODO/TBD; no empty or dash-only cells (use `N/A (<reason of three words or more>)`).
- Write in sections of ≤ 400 lines per Write/append; finish with `<!-- END OF FILE -->`; run `python3 scripts/validate_docs.py docs/parts/SOURCE_NOTES/<nn>-<slug>.md` — note: the validator may report the part is outside the manifest; only PHRASE/PLACE/CELL/TIME/EV/IDFMT failures matter, fix all of those.
- If you cannot finish: rename to <nn>-<slug>.PARTIAL.md with last line `PARTIAL: resume at <heading>`.
- Last action: write your part path to docs/agents/P02-<slug>/outputs.txt.

## Report (final message, ≤ 15 lines)
OUTPUTS: <path> (<lines> lines, end marker yes/no) · ROWS: <n> per input · CONFLICTS: <n> · RED-LINE TAGS: <n> · OPEN: … · BLOCKED: … · EVIDENCE: <log path>
<!-- END OF FILE -->
