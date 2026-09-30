import Foundation
import SwiftUI
import FocusModel

// MARK: - Medications

/// What a medication is for, in the person's own words. Only picks defaults and icons; the app never
/// suggests doses, timing changes or combinations.
enum MedKind: String, Codable, CaseIterable, Identifiable {
    case longActing, booster, windDown, other
    var id: Self { self }

    var label: String {
        switch self {
        case .longActing: "All day"
        case .booster: "Short-acting"
        case .windDown: "Wind-down"
        case .other: "Something else"
        }
    }

    var explainer: String {
        switch self {
        case .longActing: "The one that carries most of your day."
        case .booster: "A shorter one, like a top-up you take during the day."
        case .windDown: "Something you take in the evening to help you slow down."
        case .other: "Anything else you want to keep track of."
        }
    }

    var symbol: String {
        switch self {
        case .longActing: "sun.max"
        case .booster: "bolt"
        case .windDown: "moon.stars"
        case .other: "circle.hexagongrid"
        }
    }

    /// Starting values for the sliders. The person changes them to match their own experience.
    var defaults: (kicksIn: Int, lasts: Int, sleepAfter: Int, relogGuardHours: Double) {
        switch self {
        case .longActing: (60, 480, 720, 8)
        case .booster: (30, 240, 360, 2)
        case .windDown: (30, 0, 0, 12)
        case .other: (30, 360, 480, 6)
        }
    }

    /// Curve shape used only for learning; never shown.
    var formulation: Formulation {
        switch self {
        case .longActing: .lisdexamfetamine
        case .booster: .dexamfetamineIR
        case .windDown, .other: .nonStimulant
        }
    }
}

struct Medication: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var strength: String
    var kind: MedKind
    var tint: Int = 0
    /// Minutes after taking it until it's working well for them.
    var kicksInMinutes: Int
    /// Minutes after taking it until it has stopped helping.
    var lastsMinutes: Int
    /// Minutes after taking it until they can usually fall asleep.
    var sleepAfterMinutes: Int
    /// Follow what check-ins learn instead of the sliders (only the main all-day medication learns).
    var learns = false
    var productID = ProductID()

    init(name: String, strength: String, kind: MedKind, tint: Int = 0, learns: Bool = false) {
        self.name = name
        self.strength = strength
        self.kind = kind
        self.tint = tint
        let d = kind.defaults
        kicksInMinutes = d.kicksIn
        lastsMinutes = d.lasts
        sleepAfterMinutes = d.sleepAfter
        self.learns = learns
    }

    var title: String { strength.isEmpty ? name : "\(name) \(strength)" }

    /// The name to show, respecting discreet mode ("Booster", "All day").
    func shownName(discreet: Bool) -> String { discreet ? kind.label : title }

    var product: Product {
        Product(id: productID, displayName: title, formulation: kind.formulation,
                minimumRelogInterval: kind.defaults.relogGuardHours * 3600)
    }

    static let tints: [Color] = [.zoneBest, .zoneWarm, .zoneLight, .sage, .slate, .honey]
    var color: Color { Self.tints[tint % Self.tints.count] }
}

// MARK: - Day types

/// A span of the day in minutes from local midnight. Values past 1440 run into the next morning
/// (for late nights and shift work).
struct MinuteRange: Codable, Hashable {
    var start: Int
    var end: Int
    var length: Int { max(0, end - start) }
    func contains(_ minute: Int) -> Bool { minute >= start && minute < end }
}

struct DoseSlot: Codable, Identifiable, Hashable {
    var id = UUID()
    var medicationID: UUID
    /// Minutes from local midnight.
    var minute: Int
}

/// When a day type switches on by itself. Empty weekdays means any day; a date range is for things
/// like school holidays or exam weeks.
struct AppliesWhen: Codable, Hashable {
    var weekdays: Set<Int> = []          // Calendar weekday numbers, 1 = Sunday
    var from: Date?
    var to: Date?

    func matches(_ date: Date, calendar: Calendar) -> Bool {
        if let from, date < calendar.startOfDay(for: from) { return false }
        if let to, date >= calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: to))! { return false }
        return weekdays.isEmpty || weekdays.contains(calendar.component(.weekday, from: date))
    }

    var hasDateRange: Bool { from != nil || to != nil }
}

/// A kind of day the person has, with its own medication rhythm: "Uni day", "Weekend", "School
/// holidays", "Night shift". Each one names its doses, its productive windows and the gaps between
/// them, and an optional wind-down that brings the productive part of the evening to a close.
struct DayType: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var symbol: String = "sun.horizon"
    var doses: [DoseSlot] = []
    /// false: windows come from each medication's own timing. true: the person drew their own.
    var usesOwnWindows = false
    var windows: [MinuteRange] = []
    /// Focus wraps up this long before a wind-down dose.
    var windDownBufferMinutes = 60
    var appliesWhen = AppliesWhen()

    var sortedDoses: [DoseSlot] { doses.sorted { $0.minute < $1.minute } }
}

/// Everything a day type works out to, once its medications are known.
struct DaySchedule: Equatable {
    var windows: [MinuteRange]
    var gaps: [MinuteRange]
    var windDownAt: Int?
    var focusEndsFor: FocusEnd?
    var sleepReadyAt: Int?

    enum FocusEnd: Equatable { case windDown, lastDose }

    var span: MinuteRange? {
        guard let first = windows.first, let last = windows.last else { return nil }
        return MinuteRange(start: first.start, end: last.end)
    }
    var productiveMinutes: Int { windows.reduce(0) { $0 + $1.length } }
}

extension DayType {
    /// Productive windows from each dose's own timing, merged where they overlap or nearly touch.
    func automaticWindows(_ meds: [UUID: Medication]) -> [MinuteRange] {
        let ranges = doses.compactMap { dose -> MinuteRange? in
            guard let med = meds[dose.medicationID], med.kind != .windDown, med.lastsMinutes > med.kicksInMinutes else { return nil }
            return MinuteRange(start: dose.minute + med.kicksInMinutes, end: dose.minute + med.lastsMinutes)
        }
        return Self.merge(ranges, joiningGapsUnder: 20)
    }

    func schedule(_ meds: [UUID: Medication]) -> DaySchedule {
        var windows = usesOwnWindows ? Self.merge(windows, joiningGapsUnder: 0) : automaticWindows(meds)
        let windDown = doses.filter { meds[$0.medicationID]?.kind == .windDown }.map(\.minute).min()
        var endReason: DaySchedule.FocusEnd? = windows.isEmpty ? nil : .lastDose
        if let windDown {
            let cut = windDown - windDownBufferMinutes
            if windows.contains(where: { $0.end > cut }) { endReason = .windDown }
            windows = windows.compactMap { w in
                let clipped = MinuteRange(start: w.start, end: min(w.end, cut))
                return clipped.length >= 15 ? clipped : nil
            }
        }
        var gaps: [MinuteRange] = []
        for (a, b) in zip(windows, windows.dropFirst()) where b.start - a.end >= 20 {
            gaps.append(MinuteRange(start: a.end, end: b.start))
        }
        let sleep = doses.compactMap { dose -> Int? in
            guard let med = meds[dose.medicationID], med.kind != .windDown, med.sleepAfterMinutes > 0 else { return nil }
            return dose.minute + med.sleepAfterMinutes
        }.max()
        return DaySchedule(windows: windows, gaps: gaps, windDownAt: windDown, focusEndsFor: endReason, sleepReadyAt: sleep)
    }

    static func merge(_ ranges: [MinuteRange], joiningGapsUnder gap: Int) -> [MinuteRange] {
        var out: [MinuteRange] = []
        for r in ranges.filter({ $0.length > 0 }).sorted(by: { $0.start < $1.start }) {
            if let last = out.last, r.start <= last.end + gap {
                out[out.count - 1].end = max(last.end, r.end)
            } else {
                out.append(r)
            }
        }
        return out
    }
}

// MARK: - Time helpers

enum ClockMinutes {
    static func date(_ minute: Int, on day: Date, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: day).addingTimeInterval(TimeInterval(minute * 60))
    }

    static func minute(of date: Date, calendar: Calendar = .current) -> Int {
        let c = calendar.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    /// "8:10", "6 pm", "1:30 am" depending on locale, wrapping past midnight.
    static func text(_ minute: Int, compact: Bool = false) -> String {
        let date = Calendar.current.startOfDay(for: .now).addingTimeInterval(TimeInterval(minute * 60))
        return compact ? date.formatted(.compactTime) : date.formatted(date: .omitted, time: .shortened)
    }

    /// "8 h 5 min", "45 min".
    /// "30 min", "1 hr", "4 hrs", "1 hr 30 min". Written out, no abbreviations with full stops.
    static func duration(_ minutes: Int) -> String {
        let h = minutes / 60, m = minutes % 60
        if h == 0 { return "\(m) min" }
        if m == 0 { return h == 1 ? "1 hr" : "\(h) hrs" }
        return "\(h) hr \(m) min"
    }
}

// MARK: - Storage

/// Medications and day types are health data: they live on this iPhone in a protected file and are
/// never put in iCloud (App Store rule 5.1.3(ii)). Moving to a new phone uses the app's own
/// end-to-end encrypted sync, where the server only ever holds ciphertext (see the backend spec).
struct MedicationFile: Codable {
    var version = 1
    var medications: [Medication]
    var dayTypes: [DayType]
    var manualChoice: ManualChoice?
    var actionButtonSuggested = false

    /// "Today is a weekend, whatever the calendar says."
    struct ManualChoice: Codable { var date: Date; var dayTypeID: UUID }

    static var url: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("medication.json")
    }

    static func load() -> MedicationFile? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(MedicationFile.self, from: data)
    }

    /// Health data: complete file protection, and kept out of device backups so it never reaches
    /// iCloud. Moving to a new phone goes through the end-to-end encrypted sync instead.
    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        var url = Self.url
        try? data.write(to: url, options: [.atomic, .completeFileProtection])
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? url.setResourceValues(values)
    }

    /// The example set a brand new person sees, so the page isn't empty: a uni day with a morning
    /// booster, the all-day dose and an afternoon booster, a weekend, and school holidays.
    static func starter(calendar: Calendar = .current) -> MedicationFile {
        var booster = Medication(name: "Dexamfetamine", strength: "5 mg", kind: .booster, tint: 1)
        booster.lastsMinutes = 240
        var allDay = Medication(name: "Vyvanse", strength: "50 mg", kind: .longActing, tint: 0, learns: true)
        allDay.kicksInMinutes = 60
        allDay.lastsMinutes = 540
        var windDown = Medication(name: "Melatonin", strength: "2 mg", kind: .windDown, tint: 2)
        windDown.kicksInMinutes = 30
        booster.sleepAfterMinutes = 300

        var uni = DayType(name: "Uni day", symbol: "graduationcap")
        uni.doses = [DoseSlot(medicationID: booster.id, minute: 7 * 60),
                     DoseSlot(medicationID: allDay.id, minute: 8 * 60 + 10),
                     DoseSlot(medicationID: booster.id, minute: 18 * 60),
                     DoseSlot(medicationID: windDown.id, minute: 21 * 60 + 30)]
        uni.appliesWhen.weekdays = [2, 3, 4, 5, 6]

        var weekend = DayType(name: "Weekend", symbol: "cup.and.saucer")
        weekend.doses = [DoseSlot(medicationID: allDay.id, minute: 9 * 60 + 30)]
        weekend.appliesWhen.weekdays = [1, 7]

        var holidays = DayType(name: "School holidays", symbol: "sun.max")
        let year = calendar.component(.year, from: .now)
        holidays.appliesWhen.from = calendar.date(from: DateComponents(year: year, month: 12, day: 19))
        holidays.appliesWhen.to = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 31))

        return MedicationFile(medications: [booster, allDay, windDown], dayTypes: [uni, weekend, holidays])
    }
}
