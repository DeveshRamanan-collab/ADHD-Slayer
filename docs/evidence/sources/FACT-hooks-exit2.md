# FACT-hooks-exit2
url: https://code.claude.com/docs/en/hooks
retrieved: 2026-10-01T13:49:11+1000
http: 200
sha256: 528546ac0ce3cde1bd119de6e3535a1831d4ed1889bef64d13fad8eb55329e32
phrase: Exit 2 means a blocking error
found: True

## Excerpt
surface a warning to Claude from a PostToolUse or PostToolUseFailure hook, exit 2 instead so Claude sees the stderr even though the tool already ran. ​ Exit code 2 Exit 2 means a blocking error. On events that can block , exit 2 blocks whether or not you print JSON: even a JSON permissionDecision of "allow" can’t override it. Claude Code still reads any valid JSON output on stdout. On Elicitation and ElicitationResult , an exit-2 hook’s hookSpecificOutput is ignored.
