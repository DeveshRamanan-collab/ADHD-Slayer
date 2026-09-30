import Foundation

public enum FocusDemand: String, Sendable, Codable, CaseIterable {
    case deep, medium, light, body
}

public struct TaskSnapshot: Sendable, Codable, Hashable, Identifiable {
    public var id: TaskID
    public var title: String
    public var estimateMinutes: Int
    public var demand: FocusDemand
    public var deadline: Date?
    /// Part of the "baseline day" — the 1–3 things that keep the week on track.
    public var isBaseline: Bool
    /// Pinned or user-placed blocks never move (spec §13 risk 4).
    public var pinnedInterval: DateInterval?
    /// When the person likes doing this kind of thing (from their category timing). A soft preference:
    /// the scheduler leans towards it but will still place the task elsewhere rather than drop it.
    public var preferredWindow: DateInterval?

    public init(id: TaskID, title: String, estimateMinutes: Int, demand: FocusDemand,
                deadline: Date? = nil, isBaseline: Bool = false, pinnedInterval: DateInterval? = nil,
                preferredWindow: DateInterval? = nil) {
        self.id = id
        self.title = title
        self.estimateMinutes = estimateMinutes
        self.demand = demand
        self.deadline = deadline
        self.isBaseline = isBaseline
        self.pinnedInterval = pinnedInterval
        self.preferredWindow = preferredWindow
    }
}

/// A commitment from the calendar. The scheduler never moves these.
public struct FixedEvent: Sendable, Codable, Hashable, Identifiable {
    public var id: String
    public var title: String
    public var interval: DateInterval
    public init(id: String, title: String, interval: DateInterval) {
        self.id = id
        self.title = title
        self.interval = interval
    }
}

public enum DayVersion: String, Sendable, Codable { case ideal, baseline }

/// Why a block sits where it does. Explanations are templates over these codes; a language
/// model may rephrase them but never invents numbers (spec §9.8, §12.5).
public enum ReasonCode: Sendable, Equatable, Codable, Hashable {
    case bestFocusLongestFree
    case lighterFocusForMediumWork
    case outsideWindowBodyTask
    case mealRule(minutesAfterDose: Int)
    case afterWindowBuffer(minutes: Int)
    case pinned
    case frozenHorizon
    case stabilityKeptPlace
    case noFocusWindowRoutineDay
    case fixedCommitment
}

public enum CapacityRemedy: Sendable, Equatable, Codable { case split, shrinkToBaseline, deferToTomorrow, flagDeadlineRisk }

public struct Block: Sendable, Codable, Hashable, Identifiable {
    public enum Kind: String, Sendable, Codable { case task, fixed }
    public var id: String
    public var taskID: TaskID?
    public var title: String
    public var interval: DateInterval
    public var demand: FocusDemand?
    public var kind: Kind
    public var reason: ReasonCode

    public init(id: String, taskID: TaskID?, title: String, interval: DateInterval,
                demand: FocusDemand?, kind: Kind, reason: ReasonCode) {
        self.id = id
        self.taskID = taskID
        self.title = title
        self.interval = interval
        self.demand = demand
        self.kind = kind
        self.reason = reason
    }
}

public struct Plan: Sendable, Codable, Hashable {
    public var blocks: [Block]
    public init(blocks: [Block]) { self.blocks = blocks.sorted { $0.interval.start < $1.interval.start } }
    public func block(for task: TaskID) -> Block? { blocks.first { $0.taskID == task } }
}

/// Everything the planner can do. There is intentionally no case that references a dose,
/// a product or a medication time: when capacity is short, tasks change — never medication.
public enum PlanChange: Sendable, Equatable {
    case place(TaskID, at: DateInterval, reason: ReasonCode)
    case move(TaskID, from: DateInterval, to: DateInterval, reason: ReasonCode)
    case unplaced(TaskID, remedy: CapacityRemedy)
}

public enum DomainError: Error, Sendable, Equatable {
    case validation(field: String, reason: String)
    case notFound(entity: String)
    case capacityExceeded(unplaced: Int)
    case storageUnavailable
}
