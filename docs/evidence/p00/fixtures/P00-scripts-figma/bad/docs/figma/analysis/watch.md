# FIGMA ANALYSIS — page "Watch" (node 20:1)
Analyst brief: fixture P00-scripts-figma · Written: 2026-10-01T14:30:00+1000 · Lock fingerprint: df824b03 · Page fingerprint: af2d828c
Id ranges: SCR/FRM/CMP/INT-6000–6999 (allocated by the orchestrator)
Scope tier of this page: MVP

## 1. Frame inventory
| Id (SCR-/FRM-/CMP-) | Frame name | Node id | Kind | Platform | Size (w×h) | Flow membership | Variant axes present | Base variant? | States present | Prototype links out | Design context cached? |
|---|---|---|---|---|---|---|---|---|---|---|---|
| SCR-6001 | Watch face | 20:2 | watch | iPhone | 198×242 | none | none | yes | initial | 20:5 | [NOT YET READ] (TRUNCATED) |
| FRM-6002 | Complication ring | 20:5 | other | Watch | 100×100 | none | none | yes | initial | none | [NOT YET READ] |
Frames in nodes.json: 2 · Rows above: 2 · Components/component sets: 0 · Instances: 1 · Text layers: 0 · Interaction candidates: 1

## 2. Per-frame analysis
### SCR-6001 | Watch face | 20:2 | get_design_context/20_2.TRUNCATED.txt | watch | Watch | none
#### INT-6001 | Log button | 20:4
**B. Does** — tap · navigates to 20:5 (prototype reaction in metadata)
**C. Logic** — watch data: yes (log via WatchConnectivity) · other categories: no
**D. Data** — LogEntry · loggedAt: Date · sourceDevice: String · data class planned
**E. Fails** — Apple Watch disconnected · log queued · shows "will sync"

## 3. Page-level counts
frames: 2 · components: 0 · component sets: 0 · variants: 0 · instances: 1 · text layers scanned: 0 · interaction candidates: 1 · INT rows: 1 · NON-INTERACTIVE rows: 0 · prototype starting points: 0 · variables referenced: 0 · metadata-only-variant rows: 0

## 4. Gaps, unverified, unread, defects
[NOT YET READ]: 20:2 (TRUNCATED), 20:5 · layout ambiguous (requests a T12 screenshot): none

## 5. Reconciliation notes for Phase 5
none

<!-- END OF FILE -->
