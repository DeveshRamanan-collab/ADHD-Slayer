# FIGMA ANALYSIS — page "Today & Tasks" (node 10:1)
Analyst brief: fixture P00-scripts-figma · Written: 2026-10-01T14:30:00+1000 · Lock fingerprint: df824b03 · Page fingerprint: 0f513ca1
Cache read: docs/figma/raw/FIXTUREFILEKEY/today-and-tasks/nodes.json; docs/figma/raw/FIXTUREFILEKEY/get_design_context/10_3.txt
Id ranges: SCR/FRM/CMP/INT-2000–2999 (allocated by the orchestrator)
Scope tier of this page: MVP

## 1. Frame inventory (every top-level frame; count must equal the nodes.json depth-1 count)
| Id (SCR-/FRM-/CMP-) | Frame name | Node id | Kind | Platform | Size (w×h) | Flow membership | Variant axes present | Base variant? | States present | Prototype links out | Design context cached? |
|---|---|---|---|---|---|---|---|---|---|---|---|
| FRM-2001 | Core loop | 10:2 | section | n/a (section container only) | 1200×1000 | none | none | yes | none | none | no (sections are not read) |
| SCR-2002 | Today | 10:3 | screen | iPhone | 393×852 | none | light | yes | initial, loading | none | yes |
| SCR-2003 | Today / Dark | 10:9 | screen | iPhone | 393×852 | none | dark | no | initial | none | [NOT YET READ] |
| SCR-2004 | Today / Dark / Pro Max | 10:14 | screen | iPhone | 440×956 | none | dark, ProMax | no | initial | none | metadata-only-variant of SCR-2002 |
| FRM-2005 | Annotation | 10:12 | annotation | n/a (designer note) | 600×400 | none | none | yes | none | none | [NOT YET READ] |
| CMP-2006 | Chip | 10:20 | variant-set | iPhone | 200×100 | none | none | yes | initial, selected | none | [NOT YET READ] |
| SCR-2007 | Calendar month | 10:30 | screen | iPhone | 393×852 | none | none | yes | initial | none | [NOT YET READ] |
Frames in nodes.json: 7 · Rows above: 7 · Components/component sets: 3 · Instances: 2 · Text layers: 5 · Interaction candidates: 4

## 2. Per-frame analysis
### SCR-2002 | Today | 10:3 | docs/figma/raw/FIXTUREFILEKEY/get_design_context/10_3.txt | screen | iPhone | light
**A. Sees**
| State | Present? | Description | Variants |
|---|---|---|---|
| initial | 10:3 | Greeting, one task row, primary button | dark 10:9 |
| loading | 10:6 | Loading line under the greeting | none |
#### INT-3001 | Primary button | 10:5
**B. Does** — tap · logs the moment · no transition data · light haptic implied
**C. Logic** — local state: yes (log entry) · persistent storage: yes (log) · other categories: no
**D. Data** — LogEntry · loggedAt: Date · data class planned · internalOnly no
#### INT-2002 | Task row | 10:7
**B. Does** — tap · opens the task · route-source: inferred
**C. Logic** — local state: yes (selection) · other categories: no
**D. Data** — Task · title: String · data class planned
**Red-line scan of this frame's text layers**
| Text layer node id | Text (verbatim) | RL hit? | Don't-say / category hit? | Proposed replacement |
|---|---|---|---|---|
| 10:4 | `Good morning` | none | none | none |
| 10:6 | `Loading…` | none | none | none |
| 10:8 | `Write report / Due 3:00 pm` | none | none | none |
| I10:5;1:2 | `Log it` | none | none | none |

### CMP-2006 | Chip | 10:20 | not cached | variant-set | iPhone | none
NON-INTERACTIVE (component set definition; its instances carry the interaction) — node 10:20

### SCR-2007 | Calendar month | 10:30 | split into children | screen | iPhone | none
**Red-line scan of this frame's text layers**
| Text layer node id | Text (verbatim) | RL hit? | Don't-say / category hit? | Proposed replacement |
|---|---|---|---|---|

## 3. Page-level counts
frames: seven · components: 2 · component sets: 1 · variants: 2 · instances: 2 · text layers scanned: 5 · interaction candidates: 4 · INT rows: 3 · NON-INTERACTIVE rows: 1 · prototype starting points: 0 · variables referenced: 0 · metadata-only-variant rows: 1

## 4. Gaps, unverified, unread, defects
[NOT YET READ]: 10:9, 10:12, 10:20, 10:32 · layout ambiguous (requests a T12 screenshot): 10:3

## 5. Reconciliation notes for Phase 5
Document-only features touching this page: none in the fixture · Figma-only features: none · Contradictions noticed: none, etc.
TODO check the chip states

