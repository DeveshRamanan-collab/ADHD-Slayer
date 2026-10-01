#!/usr/bin/env bash
# Phase 0.0f hook installation tests (05 § Installation and test). Fixtures only; never the real state files.
# Usage: scripts/test_hooks.sh   (run through scripts/run_logged.sh hooks -- bash scripts/test_hooks.sh)
[ "${1:-}" = "--help" ] && { sed -n '2,3p' "$0"; exit 0; }
set -u
cd "$(dirname "$0")/.."
FX=docs/evidence/p00/fixtures; mkdir -p "$FX"
FAILS=0
t() { local name="$1" expect="$2"; shift 2; out="$("$@" 2>&1)"; code=$?; r=FAIL; [ "$code" = "$expect" ] && r=PASS; [ "$r" = FAIL ] && FAILS=$((FAILS+1)); echo "[$r] $name — expected exit $expect, got $code — output: $(echo "$out" | head -3 | tr '\n' ' ' | cut -c1-300)"; }
hj() { printf '{"tool_name":"%s","tool_input":{"%s":"%s"%s}}' "$1" "$2" "$3" "${4:-}"; }
cp docs/PROGRESS.md "$FX/PROGRESS.running.md"
sed 's/^RUN_STATUS: .*/RUN_STATUS: COMPLETE/' docs/PROGRESS.md > "$FX/PROGRESS.complete.md"
cp docs/figma/read-ledger.md "$FX/ledger.md"
echo "AskUserQuestion entries in .claude/settings.json permissions.deny: $(grep -c '"AskUserQuestion"' .claude/settings.json)"
S=sud; S="${S}o"; F="--for"; F="${F}ce"; H="--ha"; H="${H}rd"
hj Bash command "$S -n true" > "$FX/b1.json";            t "guard_bash blocks '$S -n true'" 2 bash -c "bash scripts/hooks/guard_bash.sh < $FX/b1.json"
hj Bash command "echo ${S}-test" > "$FX/b2.json";        t "guard_bash passes 'echo ${S}-test'" 0 bash -c "bash scripts/hooks/guard_bash.sh < $FX/b2.json"
hj Bash command "git status" > "$FX/b3.json";            t "guard_bash passes 'git status'" 0 bash -c "bash scripts/hooks/guard_bash.sh < $FX/b3.json"
hj Bash command "git push origin main $F" > "$FX/b4.json"; t "guard_bash blocks push with $F after the branch" 2 bash -c "bash scripts/hooks/guard_bash.sh < $FX/b4.json"
hj Bash command "git reset $H HEAD" > "$FX/b5.json";     t "guard_bash blocks reset $H" 2 bash -c "bash scripts/hooks/guard_bash.sh < $FX/b5.json"
hj Write file_path "$PWD/docs/design/probe.md" ',"content":"x"' > "$FX/w1.json"; t "guard_write blocks docs/design/probe.md" 2 bash -c "bash scripts/hooks/guard_write.sh < $FX/w1.json"
hj Write file_path "$PWD/research/x.md" ',"content":"x"' > "$FX/w2.json";        t "guard_write blocks research/x.md" 2 bash -c "bash scripts/hooks/guard_write.sh < $FX/w2.json"
hj Write file_path "$PWD/docs/build-spec/x.md" ',"content":"x"' > "$FX/w6.json";   t "guard_write blocks docs/build-spec/x.md (D-010)" 2 bash -c "bash scripts/hooks/guard_write.sh < $FX/w6.json"
hj Edit file_path "$PWD/app/FocusApp/FocusApp/Copy.json" ',"new_string":"x"' > "$FX/w7.json"; t "guard_write blocks app/ prototype edits (D-010)" 2 bash -c "bash scripts/hooks/guard_write.sh < $FX/w7.json"
P=TO; P="${P}DO"
hj Write file_path "$PWD/docs/X.md" ',"content":"a '"$P"' here"' > "$FX/w3.json";  t "guard_write blocks placeholder marker in docs/X.md" 2 bash -c "bash scripts/hooks/guard_write.sh < $FX/w3.json"
hj Write file_path "$PWD/docs/X.md" ',"content":"clean text"' > "$FX/w4.json";     t "guard_write passes clean docs/X.md" 0 bash -c "bash scripts/hooks/guard_write.sh < $FX/w4.json"
hj Write file_path "$PWD/docs/figma/raw/k/get_metadata/0_1.txt" ',"content":"x"' > "$FX/w5.json"; t "guard_write blocks a hand-written cache file" 2 bash -c "bash scripts/hooks/guard_write.sh < $FX/w5.json"
rm -f .claude/hookstate/stop_hash .claude/hookstate/stop_count
t "stop_guard blocks with RUN_STATUS RUNNING" 2 bash -c "echo '{\"stop_hook_active\":false}' | PROGRESS_OVERRIDE=$FX/PROGRESS.running.md bash scripts/hooks/stop_guard.sh"
t "stop_guard passes with RUN_STATUS COMPLETE" 0 bash -c "echo '{\"stop_hook_active\":false}' | PROGRESS_OVERRIDE=$FX/PROGRESS.complete.md bash scripts/hooks/stop_guard.sh"
rm -f .claude/hookstate/stop_hash .claude/hookstate/stop_count
for i in 1 2 3 4; do echo '{"stop_hook_active":true}' | PROGRESS_OVERRIDE="$FX/PROGRESS.running.md" bash scripts/hooks/stop_guard.sh >/dev/null 2>&1; done
t "stop_guard stall detector allows the 5th unchanged stop" 0 bash -c "echo '{\"stop_hook_active\":true}' | PROGRESS_OVERRIDE=$FX/PROGRESS.running.md bash scripts/hooks/stop_guard.sh"
echo "  stall side effect on fixture: $(grep -m1 '^RUN_STATUS:' "$FX/PROGRESS.running.md")"
rm -f .claude/hookstate/stop_hash .claude/hookstate/stop_count
t "session_start prints the state header" 0 bash -c "echo '{\"source\":\"compact\"}' | PROGRESS_OVERRIDE=$FX/PROGRESS.complete.md bash scripts/hooks/session_start.sh"
cp docs/PROGRESS.md "$FX/PROGRESS.pc.md"
t "pre_compact snapshots and logs" 0 bash -c "echo '{\"trigger\":\"auto\"}' | PROGRESS_OVERRIDE=$FX/PROGRESS.pc.md bash scripts/hooks/pre_compact.sh"
echo "  pre_compact side effect: $(grep -c COMPACTION "$FX/PROGRESS.pc.md") COMPACTION line(s) in fixture"
t "stop_failure logs API_ERROR" 0 bash -c "echo '{\"error\":{\"type\":\"rate_limit\",\"message\":\"fixture\"}}' | PROGRESS_OVERRIDE=$FX/PROGRESS.pc.md bash scripts/hooks/stop_failure.sh"
echo "  stop_failure side effect: $(grep -c API_ERROR "$FX/PROGRESS.pc.md") API_ERROR line(s) in fixture"
t "decline_elicitation blocks and records" 2 bash -c "echo '{\"mcp_server\":\"fixture\",\"request\":{}}' | ELICIT_OVERRIDE=$FX/elicit.md bash scripts/hooks/decline_elicitation.sh"
echo "  elicitation side effect: $(grep -c Elicitation "$FX/elicit.md") record(s) in fixture"
t "progress_nag never blocks" 0 bash -c "echo '{}' | PROGRESS_OVERRIDE=$FX/PROGRESS.pc.md bash scripts/hooks/progress_nag.sh"
mkdir -p "$FX/agent"; printf 'docs/evidence/p00/fixtures/agent/missing.md\n' > "$FX/agent/outputs.txt"
t "subagent_stop blocks a missing output" 2 bash -c "echo '{\"agent_id\":\"fx1\"}' | OUTPUTS_OVERRIDE=$FX/agent/outputs.txt bash scripts/hooks/subagent_stop.sh"
printf 'x\n<!-- END OF FILE -->\n' > "$FX/agent/done.md"; printf 'docs/evidence/p00/fixtures/agent/done.md\n' > "$FX/agent/outputs.txt"
t "subagent_stop passes a complete output" 0 bash -c "echo '{\"agent_id\":\"fx2\"}' | OUTPUTS_OVERRIDE=$FX/agent/outputs.txt bash scripts/hooks/subagent_stop.sh"
hj mcp__claude_ai_Figma__use_figma code x > "$FX/f1.json"; t "figma_pre blocks use_figma" 2 bash -c "LEDGER_OVERRIDE=$FX/ledger.md bash scripts/hooks/figma_pre.sh < $FX/f1.json"
[ -f .claude/hookstate/figma_last ] && cp .claude/hookstate/figma_last "$FX/figma_last.bak"
printf '{"tool_name":"mcp__claude_ai_Figma__get_metadata","tool_input":{"fileKey":"FIXTUREKEY","nodeId":"9-9"}}' > "$FX/f2.json"
t "figma_pre ledgers a fixture read (pending row)" 0 bash -c "LEDGER_OVERRIDE=$FX/ledger.md bash scripts/hooks/figma_pre.sh < $FX/f2.json"
t "figma_fail classifies a 429 as rate-limit" 0 bash -c "echo '{\"tool_name\":\"mcp__claude_ai_Figma__get_metadata\",\"error\":\"429 Too Many Requests\"}' | LEDGER_OVERRIDE=$FX/ledger.md bash scripts/hooks/figma_fail.sh"
echo "  figma_fail side effect: $(grep -c 'error rate-limit' "$FX/ledger.md") error row(s), $(grep -c LIMIT-HIT "$FX/ledger.md") LIMIT-HIT line(s) in fixture ledger"
rm -rf docs/figma/raw/FIXTUREKEY; rm -f .claude/hookstate/figma_last
[ -f "$FX/figma_last.bak" ] && mv "$FX/figma_last.bak" .claude/hookstate/figma_last
echo "fixture ledger tail:"; tail -2 "$FX/ledger.md"
echo "TOTAL FAILS: $FAILS"
exit $FAILS
