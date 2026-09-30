import Foundation

/// Release profile of a product. Picks the day-one curve shape (spec §6.1–6.2); never shown to users.
public enum Formulation: String, Sendable, Codable, CaseIterable {
    case methylphenidateIR, methylphenidateLA, methylphenidateOROS, dexamfetamineIR, lisdexamfetamine, nonStimulant

    /// Minutes for the template curve to rise from 0 to full, and to fall from full to 0.
    /// Only onset and offset are learned per person; ramps are fixed per formulation (§7.3).
    public var ramps: (up: Int, down: Int)? {
        switch self {
        case .methylphenidateIR: (20, 60)
        case .methylphenidateLA: (30, 90)
        case .methylphenidateOROS: (60, 120)
        case .dexamfetamineIR: (30, 60)
        case .lisdexamfetamine: (45, 110)
        case .nonStimulant: nil // builds over weeks; no daily window (§6.7)
        }
    }

    /// Day-one prior centre (minutes after logging) for where effect starts rising and where it ends.
    /// Deliberately shorter than label durations: 57% of lisdexamfetamine users report ≤ 7 h (§6).
    public var labelPrior: (onset: Int, offset: Int)? {
        switch self {
        case .methylphenidateIR: (25, 240)
        case .methylphenidateLA: (30, 450)
        case .methylphenidateOROS: (45, 600)
        case .dexamfetamineIR: (30, 300)
        case .lisdexamfetamine: (45, 480)
        case .nonStimulant: nil
        }
    }
}

public struct Product: Sendable, Codable, Hashable, Identifiable {
    public var id: ProductID
    /// Shown only in-app and only when discreet mode is off.
    public var displayName: String
    public var formulation: Formulation
    /// A second log of the same product inside this interval triggers the deliberate-confirm guard.
    public var minimumRelogInterval: TimeInterval

    public init(id: ProductID = ProductID(), displayName: String, formulation: Formulation,
                minimumRelogInterval: TimeInterval = 6 * 3600) {
        self.id = id
        self.displayName = displayName
        self.formulation = formulation
        self.minimumRelogInterval = minimumRelogInterval
    }
}

public enum DoseSource: String, Sendable, Codable { case app, watch, intent, healthImport }

public struct DoseEvent: Sendable, Codable, Hashable, Identifiable {
    public var id: DoseEventID
    public var product: ProductID
    public var takenAt: Date
    public var loggedAt: Date
    public var source: DoseSource
    public var ateFirst: Bool?
    public var isBooster: Bool

    public init(id: DoseEventID = DoseEventID(), product: ProductID, takenAt: Date, loggedAt: Date = .now,
                source: DoseSource, ateFirst: Bool? = nil, isBooster: Bool = false) {
        self.id = id
        self.product = product
        self.takenAt = takenAt
        self.loggedAt = loggedAt
        self.source = source
        self.ateFirst = ateFirst
        self.isBooster = isBooster
    }
}

public enum CheckInAnswer: String, Sendable, Codable { case yes, partly, no }

/// One tap on "Working now? Yes / Partly / No". Feeds the focus-window posterior only.
public struct CheckIn: Sendable, Codable, Hashable {
    public var at: Date
    public var answer: CheckInAnswer
    public var dose: DoseEventID

    public init(at: Date, answer: CheckInAnswer, dose: DoseEventID) {
        self.at = at
        self.answer = answer
        self.dose = dose
    }
}

/// The read-only view of the dose log that every non-medication module receives.
public protocol DoseTimelineReading: Sendable {
    func doses(in interval: DateInterval) async -> [DoseEvent]
    func lastDose(of product: ProductID) async -> DoseEvent?
}
