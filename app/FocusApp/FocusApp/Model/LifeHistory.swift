import Foundation

/// Four weeks of the person's own history, used by the Rhythm and Plan visualisations.
/// In the prototype this is generated deterministically; in the product it is a projection of the
/// event ledger (system-design §4). Nothing here is shown as a score — only as patterns.
struct LifeHistory: Sendable {
    struct Day: Identifiable, Sendable {
        let id: Int                 // 0 = oldest
        let date: Date
        let wake: Date
        let sleepHours: Double
        let logged: Date?           // nil = planned medication-free day or no log
        let windowStart: Date?
        let windowEnd: Date?
        let brain: Int              // 0 low · 1 okay · 2 good
        let plannedMinutes: Int
        let doneMinutes: Int
        let baselineHit: Bool
        let completionHours: [Int]  // hour of day of each finished block
        var isToday = false

        var donePercent: Double { plannedMinutes == 0 ? 0 : Double(doneMinutes) / Double(plannedMinutes) }
    }

    struct Estimate: Identifiable, Sendable {
        let id: String
        let guessMinutes: Int
        let actualMinutes: Int
        let sessions: Int
    }

    let days: [Day]
    let estimates: [Estimate]

    var lastWeek: [Day] { Array(days.suffix(7)) }
    var lastFortnight: [Day] { Array(days.suffix(14)) }

    static func generate(endingOn today: Date, calendar: Calendar = .current) -> LifeHistory {
        var rng = Seeded(seed: 2026)
        var days: [Day] = []
        let startOfToday = calendar.startOfDay(for: today)
        for offset in stride(from: 27, through: 0, by: -1) {
            let day = calendar.date(byAdding: .day, value: -offset, to: startOfToday)!
            let weekday = calendar.component(.weekday, from: day) // 1 Sun … 7 Sat
            let weekend = weekday == 1 || weekday == 7
            func at(_ minutes: Double) -> Date { day.addingTimeInterval(minutes * 60) }

            let sleep = (weekend ? 7.8 : 7.0) + rng.normal() * 0.8
            let wakeMinute = (weekend ? 8.6 : 7.3) * 60 + rng.normal() * 22
            let medicationFree = weekend && rng.uniform() < 0.5
            let logMinute = wakeMinute + 35 + abs(rng.normal()) * 20
            let logged = medicationFree ? nil : at(logMinute)
            let windowStart = logged.map { $0.addingTimeInterval((60 + rng.normal() * 8) * 60) }
            let windowEnd = logged.map { $0.addingTimeInterval((540 + rng.normal() * 25) * 60) }

            // Brain weather leans on sleep, with a low patch mid-fortnight.
            let lowPatch = (10...12).contains(27 - offset)
            let brainScore = (sleep - 6.2) * 0.8 + rng.normal() * 0.6 - (lowPatch ? 1.2 : 0)
            let brain = brainScore < 0 ? 0 : brainScore < 1.3 ? 1 : 2

            let planned = weekend ? Int(120 + rng.uniform() * 90) : Int(300 + rng.uniform() * 120)
            let doneShare = min(1, max(0.25, 0.45 + (sleep - 6.5) * 0.12 + Double(brain) * 0.1 + rng.normal() * 0.1))
            let done = Int(Double(planned) * doneShare)

            // Completions cluster in the morning inside the window, a few after lunch.
            var hours: [Int] = []
            let blocks = max(1, done / 50)
            for _ in 0..<blocks {
                let morning = rng.uniform() < 0.62
                let hour = morning ? 9 + Int(rng.uniform() * 3.5) : 13 + Int(rng.uniform() * 5)
                hours.append(min(21, max(7, hour + (weekend ? 1 : 0))))
            }
            days.append(Day(id: 27 - offset, date: day, wake: at(wakeMinute), sleepHours: sleep, logged: logged,
                            windowStart: windowStart, windowEnd: windowEnd, brain: brain, plannedMinutes: planned,
                            doneMinutes: done, baselineHit: doneShare > 0.4, completionHours: hours,
                            isToday: offset == 0))
        }
        let estimates = [
            Estimate(id: "Essay drafting", guessMinutes: 60, actualMinutes: 96, sessions: 14),
            Estimate(id: "Case reading", guessMinutes: 70, actualMinutes: 91, sessions: 5),
            Estimate(id: "Tutorial prep", guessMinutes: 40, actualMinutes: 52, sessions: 8),
            Estimate(id: "Admin & email", guessMinutes: 20, actualMinutes: 28, sessions: 21),
            Estimate(id: "Getting out the door", guessMinutes: 10, actualMinutes: 18, sessions: 31),
        ]
        return LifeHistory(days: days, estimates: estimates)
    }
}

/// SplitMix64 + Box–Muller: deterministic, so every run of the prototype shows the same life.
struct Seeded: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
    mutating func uniform() -> Double { Double(next() >> 11) / Double(1 << 53) }
    mutating func normal() -> Double {
        let u1 = max(uniform(), 1e-9), u2 = uniform()
        return sqrt(-2 * log(u1)) * cos(2 * .pi * u2)
    }
}
