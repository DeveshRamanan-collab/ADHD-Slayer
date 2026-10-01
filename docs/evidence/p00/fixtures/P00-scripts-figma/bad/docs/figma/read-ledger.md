# FIGMA READ LEDGER — fixture for P00-scripts-figma (not a real ledger)
Verified limit: fixture · Caps: 150 per rolling 24 h
EPOCH 1 | started 2026-10-01T13:47:23+1000 | cap 36 | reads 6 | first_limit_error none | observed_reset unknown
| # | Timestamp | Session/agent | Tool | File key | Node id | Intent (plan line / lock-check / retry / delta-audit) | Cache path | Result (pending / ok / truncated / error <class>: <text>) | Response bytes | Reads in last 24 h after this | Reads in this minute |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 2026-10-01T13:50:45+1000 | orchestrator | get_metadata | FIXTUREFILEKEY | root | lock-check | docs/figma/raw/FIXTUREFILEKEY/get_metadata/root.txt | ok | 200 | 1 | 1 |
| 2 | 2026-10-01T13:51:00+1000 | orchestrator | get_metadata | FIXTUREFILEKEY | 10:1 | plan | docs/figma/raw/FIXTUREFILEKEY/get_metadata/10_1.txt | ok | 30000 | 2 | 2 |
| 3 | 2026-10-01T13:51:10+1000 | orchestrator | get_metadata | FIXTUREFILEKEY | 20:1 | plan | docs/figma/raw/FIXTUREFILEKEY/get_metadata/20_1.txt | ok | 900 | 3 | 3 |
| 4 | 2026-10-01T13:52:00+1000 | orchestrator | get_design_context | FIXTUREFILEKEY | 10:3 | plan | docs/figma/raw/FIXTUREFILEKEY/get_design_context/10_3.txt | ok | 2000 | 4 | 1 |
| 5 | 2026-10-01T13:52:10+1000 | orchestrator | get_design_context | FIXTUREFILEKEY | 20:2 | plan | docs/figma/raw/FIXTUREFILEKEY/get_design_context/20_2.TRUNCATED.txt | truncated | 150 | 5 | 2 |
| 6 | 2026-10-01T13:52 | orchestrator | get_design_context | FIXTUREFILEKEY | 10:31 | plan | docs/figma/raw/FIXTUREFILEKEY/get_design_context/10_31.txt | ok | 400 | 6 | 3 |
