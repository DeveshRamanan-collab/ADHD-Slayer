# FIGMA READ LEDGER — the only source of truth for reads used
Verified limit: 200/day, 10/min (https://developers.figma.com/docs/figma-mcp-server/rate-limits-access/, verified 2026-09-30 per K.1; re-verification in Phase 0.7) · Caps: 150 per rolling 24 h, ≤8 per rolling 60 s, ≥7 s apart · Rule: a cached node is never re-read except tagged lock-check / retry / delta-audit
Budget rule in force: rolling-24h-from-first-read
Note: two setup reads were made on 2026-10-01 before this run (prompts/SOURCE_MAP.md; get_metadata root and 114:2); they are not in this ledger and are counted against the epoch conservatively by lowering nothing — the cap of 150 leaves 50 of the Education limit of 200 as margin.
EPOCH 1 | started 2026-10-01T13:47:23+1000 | cap 150 | reads 0 | first_limit_error none | observed_reset unknown
| # | Timestamp | Session/agent | Tool | File key | Node id | Intent (plan line / lock-check / retry / delta-audit) | Cache path | Result (pending / ok / truncated / error <class>: <text>) | Response bytes | Reads in last 24 h after this | Reads in this minute |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 2026-10-01T13:50:45+1000 | orchestrator | get_metadata | gLuoHFbiiUGajAUpluWXOW | root | lock-check | /Users/deveshramanan/ADHD Slayer/docs/figma/raw/gLuoHFbiiUGajAUpluWXOW/get_metadata/root.txt | ok | 273 | 1 | 1 |
| 2 | 2026-10-01T14:07:30+1000 | orchestrator | get_metadata | FIXTUREKEY | 9:9 | plan | /Users/deveshramanan/ADHD Slayer/docs/figma/raw/FIXTUREKEY/get_metadata/9_9.txt | error rate-limit: 429 too many requests | 0 | 2 | 1 |
LIMIT-HIT 2026-10-01T14:07:30+1000 rate-limit
