# Tasks (fixture, failing)

| TASK id | type | milestone | description | depends on | implements | Figma reference | expected implementation | verified by | completion criterion | size | suggested agent/tool |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **TASK-0001** | ENG | MS-01 | Dose log engine | N/A (first task in graph) | FEAT-0001 | 83:101 | `DoseLog.swift` | TEST-0001 | "swift test passes DoseLogTests" | M | implementer |
| **TASK-0002** | UI | MS-02 | Discreet formatter | TASK-0001 | FEAT-0002 | 83:120 | `DiscreetFormatter.swift` | N/A (later) | "formatter test passes" | S | implementer |
| **TASK-0004** | UI | MS-02 | Settings screen | TASK-0001 | FEAT-0002 | 83:150 | `SettingsView.swift` | TEST-0042 | "settings test passes" | S | implementer |

<!-- END OF FILE -->
