import Foundation
import Testing
import FocusModel
@testable import FocusPlanning

/// Fixture #1 is the spec's own worked example (§7.6): logged 8:10, usual focus 1:00–9:00 after
/// logging, lunch no earlier than 5 h after the dose, a 2 pm tutorial, gym after the window.
enum Fixture {
    static let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Australia/Sydney")!
        return c
    }()
    static func at(_ h: Int, _ m: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 14, hour: h, minute: m))!
    }
    static let day = DateInterval(start: at(7, 0), end: at(22, 0))
    // Lisdexamfetamine ramps 45 up / 110 down: onset 15 → best focus from 9:10; offset 540 → ends 17:10.
    static let window = FocusWindow(dose: at(8, 10), onsetMinutes: 15, offsetMinutes: 540, rampUpMinutes: 45,
                                    rampDownMinutes: 110, startUncertaintyMinutes: 25, endUncertaintyMinutes: 25,
                                    confidence: .learned(checkIns: 23))
    static let tutorial = FixedEvent(id: "tut", title: "Tutorial · Room 4.12", interval: DateInterval(start: at(14, 0), end: at(15, 0)))
    static let tasks: [TaskSnapshot] = [
        TaskSnapshot(id: TaskID("essay"), title: "Essay drafting", estimateMinutes: 80, demand: .deep, isBaseline: true),
        TaskSnapshot(id: TaskID("reading"), title: "Case reading", estimateMinutes: 90, demand: .deep),
        TaskSnapshot(id: TaskID("prep"), title: "Tutorial prep for Thursday", estimateMinutes: 50, demand: .medium),
        TaskSnapshot(id: TaskID("email"), title: "Email + plan tomorrow", estimateMinutes: 30, demand: .light),
        TaskSnapshot(id: TaskID("lunch"), title: "Lunch", estimateMinutes: 40, demand: .body, isBaseline: true),
        TaskSnapshot(id: TaskID("gym"), title: "Gym — upper body", estimateMinutes: 60, demand: .body),
    ]
    static func request(tasks: [TaskSnapshot] = tasks, previous: Plan? = nil, freezeUntil: Date? = nil,
                        dayVersion: DayVersion = .ideal) -> PlanRequest {
        PlanRequest(day: day, tasks: tasks, fixed: [tutorial], window: window, previous: previous,
                    freezeUntil: freezeUntil, dayVersion: dayVersion)
    }
}

@Suite("Scheduler — worked example and invariants (spec §7.6, §13)")
struct SchedulerTests {
    let scheduler = Scheduler()

    @Test func deepWorkLandsInBestFocus() throws {
        let result = scheduler.solve(Fixture.request())
        for id in ["essay", "reading"] {
            let b = try #require(result.plan.block(for: TaskID(id)))
            #expect(b.interval.start >= Fixture.window.start && b.interval.end <= Fixture.window.bestFocusEnd,
                    "\(id) at \(b.interval) should sit inside best focus")
            #expect(b.reason == .bestFocusLongestFree)
        }
    }

    @Test func lunchFollowsThePersonalMealRuleAndGymWaitsForTheWindowToEnd() throws {
        let result = scheduler.solve(Fixture.request())
        let lunch = try #require(result.plan.block(for: TaskID("lunch")))
        #expect(lunch.interval.start >= Fixture.at(13, 10))
        #expect(lunch.reason == .mealRule(minutesAfterDose: 300))
        let gym = try #require(result.plan.block(for: TaskID("gym")))
        #expect(gym.interval.start >= Fixture.window.end.addingTimeInterval(20 * 60))
    }

    @Test func mediumAndLightWorkUseLighterFocusNotBestFocus() throws {
        let result = scheduler.solve(Fixture.request())
        for id in ["prep", "email"] {
            let b = try #require(result.plan.block(for: TaskID(id)))
            #expect(b.interval.start >= Fixture.window.start, "\(id) should be inside the window")
            #expect(Fixture.window.zone(at: b.interval.start) != .bestFocus || b.interval.start >= Fixture.tutorial.interval.end,
                    "\(id) at \(b.interval.start) took best focus that deep work could use")
        }
    }

    @Test func blocksNeverOverlapAndKeepTenMinuteTransitionsAroundFixedEvents() {
        let result = scheduler.solve(Fixture.request())
        let blocks = result.plan.blocks
        for (i, a) in blocks.enumerated() {
            for b in blocks[(i + 1)...] {
                #expect(a.interval.end <= b.interval.start || b.interval.end <= a.interval.start,
                        "\(a.title) overlaps \(b.title)")
            }
            if a.kind == .task {
                let gapBefore = Fixture.tutorial.interval.start.timeIntervalSince(a.interval.end)
                let gapAfter = a.interval.start.timeIntervalSince(Fixture.tutorial.interval.end)
                #expect(gapBefore >= 600 || gapAfter >= 600, "\(a.title) crowds the tutorial")
            }
        }
    }

    @Test func respectsTheFillCap() {
        let result = scheduler.solve(Fixture.request())
        #expect(result.fillPercent <= 60)
        #expect(result.fillPercent > 30)
    }

    @Test func isDeterministic() {
        let a = scheduler.solve(Fixture.request()).plan
        let b = scheduler.solve(Fixture.request()).plan
        #expect(a == b)
    }

    @Test func pinnedBlocksNeverMove() throws {
        var tasks = Fixture.tasks
        let pin = DateInterval(start: Fixture.at(9, 0), duration: 80 * 60)
        tasks[0].pinnedInterval = pin
        let result = scheduler.solve(Fixture.request(tasks: tasks))
        #expect(try #require(result.plan.block(for: TaskID("essay"))).interval == pin)
    }

    @Test func frozenHorizonKeepsTheNextTwoHoursAndReplansMoveFewBlocks() throws {
        let first = scheduler.solve(Fixture.request()).plan
        // Running 40 min late: a replan at 9:40 with a new 30-min task must not reshuffle the day.
        var tasks = Fixture.tasks
        tasks.append(TaskSnapshot(id: TaskID("call"), title: "Call pharmacy", estimateMinutes: 15, demand: .light))
        let replan = scheduler.solve(Fixture.request(tasks: tasks, previous: first, freezeUntil: Fixture.at(11, 40)))
        let moves = replan.changes.filter { if case .move = $0 { true } else { false } }
        #expect(moves.count <= 3)
        for block in first.blocks where block.kind == .task && block.interval.start < Fixture.at(11, 40) {
            #expect(replan.plan.block(for: block.taskID!)?.interval == block.interval)
        }
    }

    @Test func replansNeverPlaceWorkInThePast() {
        let first = scheduler.solve(Fixture.request()).plan
        var request = Fixture.request(previous: first, freezeUntil: Fixture.at(10, 0))
        request.earliestStart = Fixture.at(9, 41)
        var tasks = Fixture.tasks
        tasks.append(TaskSnapshot(id: TaskID("call"), title: "Call pharmacy", estimateMinutes: 15, demand: .light))
        request.tasks = tasks
        let replan = scheduler.solve(request)
        for block in replan.plan.blocks where block.kind == .task {
            let wasFrozen = first.block(for: block.taskID!)?.interval.start ?? .distantFuture < Fixture.at(10, 0)
            #expect(wasFrozen || block.interval.start >= Fixture.at(9, 41), "\(block.title) placed at \(block.interval.start), before now")
        }
    }

    @Test func baselineDayKeepsOnlyTheThingsThatKeepTheWeekOnTrack() {
        let result = scheduler.solve(Fixture.request(dayVersion: .baseline))
        let ids = Set(result.plan.blocks.compactMap(\.taskID?.raw))
        #expect(ids == ["essay", "lunch"])
    }

    @Test func unmedicatedDayStillProducesAPlan() {
        var request = Fixture.request()
        request.window = nil
        let result = scheduler.solve(request)
        #expect(result.plan.blocks.filter { $0.kind == .task }.count == Fixture.tasks.count)
        #expect(result.plan.blocks.filter { $0.kind == .task }.allSatisfy { $0.reason == .noFocusWindowRoutineDay })
    }

    @Test func whenWorkDoesNotFitTasksChangeNeverMedication() {
        let tooMuch = (0..<12).map { TaskSnapshot(id: TaskID("deep\($0)"), title: "Deep \($0)", estimateMinutes: 90, demand: .deep) }
        let result = scheduler.solve(Fixture.request(tasks: tooMuch))
        let unplaced = result.changes.filter { if case .unplaced = $0 { true } else { false } }
        #expect(!unplaced.isEmpty)
        #expect(result.fillPercent <= 60)
    }

    @Test func solvesADayWellInsideTheLatencyBudget() {
        let result = scheduler.solve(Fixture.request())
        // Gate 1 target is 150 ms for a day on an A13; a debug build on a Mac should be far below.
        #expect(result.solveMilliseconds < 150, "took \(result.solveMilliseconds) ms")
    }
}

@Suite("Safety gate (spec §8.4)")
struct SafetyGateTests {
    let gate = SafetyGate()

    @Test(arguments: [
        "Take your booster now to cover your 3 pm lecture",
        "You could skip your dose today",
        "Try 30 mg instead",
        "Your meds wear off at 3:20",
        "It's safe to take another one",
        "When should I take my medication tomorrow?",
        "This app reduces ADHD symptoms",
    ])
    func blocksMedicationAdvice(_ text: String) {
        #expect(gate.screen(text, context: .aiRephrase) == .replaced(with: SafetyGate.referral, matched: gate.matches(text)))
    }

    @Test(arguments: [
        "Essay moved to 9:15, inside your focus window",
        "Lunch at 1:10 — your meal rule",
        "Gym after your focus window ends",
        "Case reading, 90 minutes, best focus",
    ])
    func allowsPlanningExplanations(_ text: String) {
        #expect(gate.screen(text, context: .aiRephrase) == .allow(text))
    }
}

extension SafetyGate {
    func matches(_ text: String) -> [String] {
        if case .replaced(_, let m) = screen(text, context: .aiRephrase) { return m }
        return []
    }
}

@Suite("Scheduler: day types and personal timing")
struct DayTypeSchedulingTests {
    let scheduler = Scheduler()

    /// A booster wears off at 11:30 and the long-acting dose isn't taken until 12:30: that hour is
    /// unproductive, so no focus work goes there.
    @Test func focusWorkAvoidsAnUnproductiveStretch() throws {
        let gap = DateInterval(start: Fixture.at(11, 30), end: Fixture.at(12, 30))
        var request = Fixture.request()
        request.lowFocusStretches = [gap]
        let result = scheduler.solve(request)
        for block in result.plan.blocks where block.kind == .task && block.demand != .body {
            #expect(block.interval.intersection(with: gap).map { $0.duration } ?? 0 == 0,
                    "\(block.title) at \(block.interval) overlaps the unproductive stretch")
        }
    }

    /// An unproductive stretch is not free focus time: planned focus work stays within the fill cap of
    /// what's left after commitments and the stretch are taken out.
    @Test func unproductiveStretchesShrinkTheBudget() {
        let gap = DateInterval(start: Fixture.at(10, 0), end: Fixture.at(12, 0))
        var request = Fixture.request()
        request.lowFocusStretches = [gap]
        let result = scheduler.solve(request)
        let w = Fixture.window
        let windowMinutes = w.end.timeIntervalSince(w.start) / 60
        let committed = (Fixture.tutorial.interval.duration + gap.duration) / 60
        let focusMinutes = result.plan.blocks
            .filter { $0.kind == .task && $0.demand != .body }
            .reduce(0.0) { $0 + $1.interval.duration / 60 }
        #expect(focusMinutes <= (windowMinutes - committed) * request.fillCap + 1)
        #expect(result.changes.contains { if case .unplaced = $0 { true } else { false } })
    }

    /// Someone who likes admin late in the afternoon gets it there when there is room.
    @Test func aPreferredWindowPullsTheTaskIntoIt() throws {
        let preferred = DateInterval(start: Fixture.at(16, 0), end: Fixture.at(17, 10))
        let tasks = Fixture.tasks.map { task -> TaskSnapshot in
            var t = task
            if t.id == TaskID("email") { t.preferredWindow = preferred }
            return t
        }
        let result = scheduler.solve(Fixture.request(tasks: tasks))
        let email = try #require(result.plan.block(for: TaskID("email")))
        #expect(email.interval.start >= preferred.start && email.interval.end <= preferred.end,
                "email at \(email.interval) should sit in \(preferred)")
    }

    /// A preference never drops a task: if the preferred window is full, it still gets placed.
    @Test func aPreferenceNeverDropsATask() throws {
        let tiny = DateInterval(start: Fixture.at(14, 0), end: Fixture.at(14, 30))   // the tutorial is here
        let tasks = Fixture.tasks.map { task -> TaskSnapshot in
            var t = task
            if t.id == TaskID("prep") { t.preferredWindow = tiny }
            return t
        }
        let result = scheduler.solve(Fixture.request(tasks: tasks))
        #expect(result.plan.block(for: TaskID("prep")) != nil)
    }
}
