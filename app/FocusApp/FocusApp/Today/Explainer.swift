import SwiftUI
import FocusModel

/// Plain-language reasons from the scheduler's reason codes (spec §12.5): numbers come from the
/// solver record; nothing here is generated, so nothing here can drift into medication advice.
enum Explainer {
    static func meta(for block: Block) -> String {
        let minutes = Int(block.interval.duration / 60)
        switch block.reason {
        case .bestFocusLongestFree: return "\(minutes) min in your best focus"
        case .lighterFocusForMediumWork: return "\(minutes) min in lighter focus"
        case .mealRule(let m): return "Your meal rule, \(m / 60) h after logging"
        case .afterWindowBuffer: return "\(minutes) min, after your focus window"
        case .outsideWindowBodyTask: return "\(minutes) min, outside your focus window"
        case .pinned: return "Pinned, so it won’t move"
        case .frozenHorizon: return "\(minutes) min, staying put for now"
        case .stabilityKeptPlace: return "\(minutes) min, kept in place"
        case .noFocusWindowRoutineDay: return "\(minutes) min on a routine day"
        case .fixedCommitment: return "Calendar"
        }
    }

    static func tint(for block: Block) -> Color {
        Kind.color(demand: block.demand?.rawValue, fixed: block.kind == .fixed)
    }

    static func demandWord(for block: Block) -> String {
        if block.kind == .fixed { return "Calendar" }
        switch block.demand {
        case .deep: return "Deep work"
        case .medium, .light: return "Lighter work"
        case .body: return "Body"
        case nil: return "Now"
        }
    }

    /// If-then first steps ("When I [cue], I will [first action]", spec §5.3).
    static func firstStep(for block: Block) -> String {
        switch block.taskID?.raw {
        case "essay": "Reread your last paragraph"
        case "reading": "Open case 3 and read the headnote"
        case "prep": "List three tutorial questions"
        case "email": "Clear the top three emails first"
        default: "Do the first two minutes"
        }
    }
}
