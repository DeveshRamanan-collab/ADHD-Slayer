import Foundation
import FocusModel

public struct PlanRequest: Sendable {
    public var day: DateInterval
    public var tasks: [TaskSnapshot]
    public var fixed: [FixedEvent]
    /// nil → unmedicated or non-stimulant day: plan from routine and energy (§7.7).
    public var window: FocusWindow?
    public var previous: Plan?
    /// Blocks in the previous plan that start before this instant never move (default: now + 2 h).
    public var freezeUntil: Date?
    /// Replans never place flexible work before this instant (normally "now").
    public var earliestStart: Date?
    public var dayVersion: DayVersion
    /// Flexible work may use at most this share of the free focus-window minutes (§13 risk 3).
    public var fillCap: Double
    public var transitionMinutes: Int
    public var mealRuleMinutesAfterDose: Int
    public var afterWindowBufferMinutes: Int
    /// Replans that aren't user-requested move at most this many existing blocks (§13 risk 4).
    public var maxMovesPerReplan: Int
    /// Stretches the person has marked as unproductive (e.g. the gap between a morning booster wearing
    /// off and the next dose). Focus work avoids them and they don't count as free focus time.
    public var lowFocusStretches: [DateInterval]

    public init(day: DateInterval, tasks: [TaskSnapshot], fixed: [FixedEvent] = [], window: FocusWindow?,
                previous: Plan? = nil, freezeUntil: Date? = nil, earliestStart: Date? = nil, dayVersion: DayVersion = .ideal,
                fillCap: Double = 0.6, transitionMinutes: Int = 10, mealRuleMinutesAfterDose: Int = 300,
                afterWindowBufferMinutes: Int = 20, maxMovesPerReplan: Int = 3, lowFocusStretches: [DateInterval] = []) {
        self.day = day
        self.tasks = tasks
        self.fixed = fixed
        self.window = window
        self.previous = previous
        self.freezeUntil = freezeUntil
        self.earliestStart = earliestStart
        self.dayVersion = dayVersion
        self.fillCap = fillCap
        self.transitionMinutes = transitionMinutes
        self.mealRuleMinutesAfterDose = mealRuleMinutesAfterDose
        self.afterWindowBufferMinutes = afterWindowBufferMinutes
        self.maxMovesPerReplan = maxMovesPerReplan
        self.lowFocusStretches = lowFocusStretches
    }
}

public struct PlanResult: Sendable {
    public var plan: Plan
    public var changes: [PlanChange]
    /// "Fills 58% of free focus time"
    public var fillPercent: Int
    public var solveMilliseconds: Double
}

/// Deterministic scheduler: greedy construction (deep work longest-first into best focus, then
/// medium/light into lighter focus, then body and meals outside the window) followed by a
/// reinsertion local search. Same inputs → same plan, so previews and explanations are stable.
/// It changes tasks only; it has no way to express a medication change.
public struct Scheduler: Sendable {
    public init() {}

    static let slot = 5 // minutes

    public func solve(_ request: PlanRequest) -> PlanResult {
        let clock = ContinuousClock()
        let started = clock.now
        var stabilityBonus = 0.6
        var result = run(request, stabilityBonus: stabilityBonus)
        // Stability contract: if an automatic replan would move too many blocks, prefer staying put.
        while moveCount(result.changes) > request.maxMovesPerReplan && stabilityBonus < 20 {
            stabilityBonus *= 3
            result = run(request, stabilityBonus: stabilityBonus)
        }
        let elapsed = clock.now - started
        result.solveMilliseconds = Double(elapsed.components.attoseconds) / 1e15 + Double(elapsed.components.seconds) * 1000
        return result
    }

    private func moveCount(_ changes: [PlanChange]) -> Int {
        changes.reduce(0) { if case .move = $1 { $0 + 1 } else { $0 } }
    }

    // MARK: Core

    private struct Grid {
        let origin: Date
        let count: Int
        var busy: [Bool]
        func minute(_ date: Date) -> Int { Int((date.timeIntervalSince(origin) / 60).rounded()) }
        func date(_ minute: Int) -> Date { origin.addingTimeInterval(TimeInterval(minute * 60)) }
        func slotIndex(_ minute: Int) -> Int { minute / Scheduler.slot }
        func isFree(from startSlot: Int, slots: Int) -> Bool {
            guard startSlot >= 0, startSlot + slots <= count else { return false }
            return !busy[startSlot..<(startSlot + slots)].contains(true)
        }
        mutating func mark(fromMinute: Int, toMinute: Int, _ value: Bool = true) {
            let a = max(0, fromMinute / Scheduler.slot)
            let b = min(count, Int((Double(toMinute) / Double(Scheduler.slot)).rounded(.up)))
            guard a < b else { return }
            for i in a..<b { busy[i] = value }
        }
    }

    private struct Placement { var task: TaskSnapshot; var startSlot: Int; var reason: ReasonCode }

    private func run(_ r: PlanRequest, stabilityBonus: Double) -> PlanResult {
        let totalMinutes = Int(r.day.duration / 60)
        var grid = Grid(origin: r.day.start, count: totalMinutes / Self.slot, busy: Array(repeating: false, count: totalMinutes / Self.slot))
        var blocks: [Block] = []
        let trans = r.transitionMinutes

        for f in r.fixed {
            grid.mark(fromMinute: grid.minute(f.interval.start) - trans, toMinute: grid.minute(f.interval.end) + trans)
            blocks.append(Block(id: "fixed-\(f.id)", taskID: nil, title: f.title, interval: f.interval,
                                demand: nil, kind: .fixed, reason: .fixedCommitment))
        }

        var remaining = r.tasks
        if r.dayVersion == .baseline { remaining = remaining.filter(\.isBaseline) }

        // Pinned and frozen blocks never move.
        var placed: [Placement] = []
        for task in remaining {
            if let pin = task.pinnedInterval {
                grid.mark(fromMinute: grid.minute(pin.start), toMinute: grid.minute(pin.end) + trans)
                blocks.append(Block(id: task.id.raw, taskID: task.id, title: task.title, interval: pin,
                                    demand: task.demand, kind: .task, reason: .pinned))
            } else if let freeze = r.freezeUntil, let prev = r.previous?.block(for: task.id), prev.interval.start < freeze {
                grid.mark(fromMinute: grid.minute(prev.interval.start), toMinute: grid.minute(prev.interval.end) + trans)
                blocks.append(Block(id: task.id.raw, taskID: task.id, title: task.title, interval: prev.interval,
                                    demand: task.demand, kind: .task, reason: .frozenHorizon))
            }
        }
        let fixedIDs = Set(blocks.compactMap(\.taskID))
        remaining.removeAll { fixedIDs.contains($0.id) }
        // The past is not free time: flexible work can't be placed before `earliestStart`.
        if let earliest = r.earliestStart { grid.mark(fromMinute: 0, toMinute: grid.minute(earliest)) }

        // Budget for flexible focus work inside the window.
        // "Free focus time" = window minutes minus the commitments themselves (not their transition padding).
        var budget = Double.infinity
        if let w = r.window {
            let windowMinutes = w.end.timeIntervalSince(w.start) / 60
            let committed = (r.fixed.map(\.interval) + blocks.filter { $0.kind == .task }.map(\.interval) + r.lowFocusStretches)
                .reduce(0.0) { acc, iv in
                    let overlap = min(iv.end, w.end).timeIntervalSince(max(iv.start, w.start)) / 60
                    return acc + max(0, overlap)
                }
            budget = max(0, windowMinutes - committed) * r.fillCap
        }
        let budgetStart = budget

        let order: [FocusDemand] = [.deep, .medium, .light, .body]
        // Deep work longest-first (ties by id); everything else keeps the person's own order.
        let ordered = order.flatMap { demand -> [TaskSnapshot] in
            let group = remaining.filter { $0.demand == demand }
            guard demand == .deep else { return group }
            return group.sorted { ($0.estimateMinutes, $1.id.raw) > ($1.estimateMinutes, $0.id.raw) }
        }
        var unplaced: [(TaskSnapshot, CapacityRemedy)] = []

        for task in ordered {
            let slots = Int((Double(task.estimateMinutes) / Double(Self.slot)).rounded(.up))
            let countsAgainstBudget = r.window != nil && task.demand != .body
            if countsAgainstBudget && Double(task.estimateMinutes) > budget {
                unplaced.append((task, task.estimateMinutes >= 60 ? .split : .deferToTomorrow))
                continue
            }
            guard let best = bestStart(for: task, slots: slots, grid: grid, request: r, stabilityBonus: stabilityBonus) else {
                unplaced.append((task, task.deadline != nil ? .flagDeadlineRisk : .deferToTomorrow))
                continue
            }
            let startMinute = best.slot * Self.slot
            grid.mark(fromMinute: startMinute - trans, toMinute: startMinute + task.estimateMinutes + trans)
            if countsAgainstBudget { budget -= Double(task.estimateMinutes) }
            placed.append(Placement(task: task, startSlot: best.slot, reason: best.reason))
        }

        // Reinsertion local search: lift each flexible block and re-place it where it costs least.
        for _ in 0..<2 {
            var improved = false
            for idx in placed.indices {
                let p = placed[idx]
                let slots = Int((Double(p.task.estimateMinutes) / Double(Self.slot)).rounded(.up))
                let startMinute = p.startSlot * Self.slot
                var trial = grid
                trial.mark(fromMinute: startMinute - trans, toMinute: startMinute + p.task.estimateMinutes + trans, false)
                // Re-mark neighbours whose transition padding overlapped the lifted block.
                for (k, other) in placed.enumerated() where k != idx {
                    let s = other.startSlot * Self.slot
                    trial.mark(fromMinute: s - trans, toMinute: s + other.task.estimateMinutes + trans)
                }
                for f in r.fixed { trial.mark(fromMinute: trial.minute(f.interval.start) - trans, toMinute: trial.minute(f.interval.end) + trans) }
                for b in blocks where b.kind == .task { trial.mark(fromMinute: trial.minute(b.interval.start), toMinute: trial.minute(b.interval.end) + trans) }
                if let earliest = r.earliestStart { trial.mark(fromMinute: 0, toMinute: trial.minute(earliest)) }
                let current = cost(p.task, startSlot: p.startSlot, slots: slots, grid: trial, request: r, stabilityBonus: stabilityBonus).value
                if let best = bestStart(for: p.task, slots: slots, grid: trial, request: r, stabilityBonus: stabilityBonus),
                   best.cost < current - 1e-9, best.slot != p.startSlot {
                    trial.mark(fromMinute: best.slot * Self.slot - trans, toMinute: best.slot * Self.slot + p.task.estimateMinutes + trans)
                    grid = trial
                    placed[idx].startSlot = best.slot
                    placed[idx].reason = best.reason
                    improved = true
                }
            }
            if !improved { break }
        }

        for p in placed {
            let start = grid.date(p.startSlot * Self.slot)
            blocks.append(Block(id: p.task.id.raw, taskID: p.task.id, title: p.task.title,
                                interval: DateInterval(start: start, duration: TimeInterval(p.task.estimateMinutes * 60)),
                                demand: p.task.demand, kind: .task, reason: p.reason))
        }
        let plan = Plan(blocks: blocks)

        var changes: [PlanChange] = []
        for b in plan.blocks where b.kind == .task {
            guard let id = b.taskID else { continue }
            if let prev = r.previous?.block(for: id) {
                if prev.interval != b.interval { changes.append(.move(id, from: prev.interval, to: b.interval, reason: b.reason)) }
            } else {
                changes.append(.place(id, at: b.interval, reason: b.reason))
            }
        }
        changes += unplaced.map { .unplaced($0.0.id, remedy: $0.1) }

        let used = budgetStart.isFinite ? (budgetStart - budget) / (budgetStart / r.fillCap) : 0
        return PlanResult(plan: plan, changes: changes, fillPercent: Int((used * 100).rounded()), solveMilliseconds: 0)
    }

    // MARK: Cost model

    private func bestStart(for task: TaskSnapshot, slots: Int, grid: Grid, request r: PlanRequest,
                           stabilityBonus: Double) -> (slot: Int, cost: Double, reason: ReasonCode)? {
        var best: (slot: Int, cost: Double, reason: ReasonCode)?
        for s in 0...(max(0, grid.count - slots)) where grid.isFree(from: s, slots: slots) {
            let c = cost(task, startSlot: s, slots: slots, grid: grid, request: r, stabilityBonus: stabilityBonus)
            guard c.value.isFinite else { continue }
            if best == nil || c.value < best!.cost - 1e-9 { best = (s, c.value, c.reason) }
        }
        return best
    }

    private func isMeal(_ task: TaskSnapshot) -> Bool {
        let t = task.title.lowercased()
        return ["lunch", "breakfast", "dinner", "meal", "snack", "eat"].contains { t.contains($0) }
    }

    private func cost(_ task: TaskSnapshot, startSlot s: Int, slots: Int, grid: Grid, request r: PlanRequest,
                      stabilityBonus: Double) -> (value: Double, reason: ReasonCode) {
        let startMinute = s * Self.slot
        let start = grid.date(startMinute)
        let end = start.addingTimeInterval(TimeInterval(task.estimateMinutes * 60))
        if let deadline = task.deadline, end > deadline { return (.infinity, .bestFocusLongestFree) }
        let earliness = Double(s) / Double(max(grid.count, 1))
        var value: Double
        var reason: ReasonCode

        if let w = r.window {
            // Sample the block every 5 min.
            var effectSum = 0.0, inBest = 0.0, inWindow = 0.0
            for k in 0..<slots {
                let t = start.addingTimeInterval(TimeInterval((k * Self.slot + 2) * 60))
                effectSum += w.effect(at: t)
                let zone = w.zone(at: t)
                if zone == .bestFocus { inBest += 1 }
                if zone == .bestFocus || zone == .lighterFocus { inWindow += 1 }
            }
            let n = Double(max(slots, 1))
            switch task.demand {
            case .deep:
                value = (1 - effectSum / n) * 10 + (1 - inBest / n) * 2 + earliness * 0.2
                reason = .bestFocusLongestFree
            case .medium, .light:
                // Keep best focus free for deep work; prefer the lighter-focus tail of the window.
                value = (inBest / n) * 1.5 + (1 - inWindow / n) * 3 + earliness * 0.2
                reason = .lighterFocusForMediumWork
            case .body:
                if isMeal(task) {
                    let earliest = w.dose.addingTimeInterval(TimeInterval(r.mealRuleMinutesAfterDose * 60))
                    guard start >= earliest else { return (.infinity, .mealRule(minutesAfterDose: r.mealRuleMinutesAfterDose)) }
                    value = start.timeIntervalSince(earliest) / 3600
                    reason = .mealRule(minutesAfterDose: r.mealRuleMinutesAfterDose)
                } else {
                    // Movement, errands and social plans go after the window (plus a buffer). The time before
                    // logging is the on-ramp (shower, breakfast, commute), so it is only a fallback.
                    let buffered = w.end.addingTimeInterval(TimeInterval(r.afterWindowBufferMinutes * 60))
                    value = (inWindow / n) * 3 + (start < buffered && start >= w.dose ? 1 : 0)
                        + (start < w.dose ? 0.8 : 0) + earliness * 0.1
                    reason = start >= buffered ? .afterWindowBuffer(minutes: r.afterWindowBufferMinutes) : .outsideWindowBodyTask
                }
            }
        } else {
            // Routine day: demanding work earlier, body tasks anywhere, lighter load overall.
            value = task.demand == .deep ? earliness : earliness * 0.5
            reason = .noFocusWindowRoutineDay
        }

        // Unproductive stretches: focus work stays out of them; body tasks may use them.
        if task.demand != .body, !r.lowFocusStretches.isEmpty {
            let inLow = r.lowFocusStretches.reduce(0.0) { acc, low in
                acc + max(0, min(end, low.end).timeIntervalSince(max(start, low.start)))
            } / max(1, end.timeIntervalSince(start))
            value += inLow * 12
        }
        // The person's own timing for this kind of task: a soft pull towards their preferred window.
        if let preferred = task.preferredWindow {
            let inside = max(0, min(end, preferred.end).timeIntervalSince(max(start, preferred.start)))
            value += (1 - inside / max(1, end.timeIntervalSince(start))) * 4
        }

        if let prev = r.previous?.block(for: task.id), grid.minute(prev.interval.start) == startMinute {
            value -= stabilityBonus
            reason = .stabilityKeptPlace
        }
        return (value, reason)
    }
}
