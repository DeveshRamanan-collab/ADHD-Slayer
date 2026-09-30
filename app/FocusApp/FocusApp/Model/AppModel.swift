import Foundation
import Observation
import EventKit
import FocusModel
import FocusMedication
import FocusPlanning

/// App state. Surfaces read from here; every medication write goes through `DoseLog` with a
/// `UserGesture`, and every plan comes from the deterministic `Scheduler`.
///
/// Where today's focus window comes from, in order:
/// 1. Today's day type (chosen by hand, or matched by date range, then weekday).
/// 2. Its doses, each with the person's own timing, or what check-ins learned for the main one.
/// 3. The day type's own drawn windows, if the person drew them instead.
/// A wind-down dose cuts the evening short; gaps between windows are unproductive stretches.
@Observable
final class AppModel {
    // MARK: Clock
    /// Launch with `-demoClock 09:41` to start the day at 9:41; time then flows normally.
    let clockOffset: TimeInterval
    var now: Date { Date().addingTimeInterval(clockOffset) }

    // MARK: Medication
    let doseLog: DoseLog
    private(set) var medications: [Medication]
    private(set) var dayTypes: [DayType]
    private(set) var manualChoice: MedicationFile.ManualChoice?
    var actionButtonSuggested: Bool { didSet { persistMedication() } }
    /// Every dose logged today, oldest first.
    private(set) var todaysDoses: [DoseEvent] = []
    var discreetMode = true {
        didSet { if discreetMode != oldValue { LiveActivityController.shared.modelDidChange() } }
    }
    /// Bumped whenever a dose is logged, so animations can replay.
    private(set) var doseLoggedSequence = 0
    /// The medications logged by the most recent Log all, for the celebration.
    private(set) var lastLoggedMedications: Set<UUID> = []

    // MARK: Learning + planning
    private(set) var focusModel: FocusWindowModel
    struct CheckInPoint: Identifiable { let id = UUID(); let minute: Int; let answer: CheckInAnswer }
    private(set) var checkInPoints: [CheckInPoint] = []
    var proposalDismissed = false
    private(set) var window: FocusWindow?
    private(set) var lowFocusStretches: [DateInterval] = []
    private(set) var sleepReadyAt: Date?
    private(set) var plan = Plan(blocks: [])
    private(set) var fillPercent = 0
    private(set) var unplaced: [TaskID] = []
    var dayVersion: DayVersion = .ideal { didSet { replan(reason: .dayVersionChanged) } }
    var brainWeather: BrainWeather = .okay {
        didSet { if brainWeather == .low { dayVersion = .baseline } }
    }
    private(set) var tasks: [TaskSnapshot] = []
    private(set) var fixed: [FixedEvent] = []
    private(set) var completed: Set<TaskID> = []

    // MARK: Personal timing
    var personalisation = Personalisation.load() {
        didSet {
            guard personalisation != oldValue else { return }
            personalisation.save()
            tuning.mealRuleMinutes = Int(personalisation.eating.from * 60)
            replan(reason: .tuningChanged)
        }
    }
    private(set) var socialSuggestions: [SocialSuggestion] = []
    private let calendarStore = EKEventStore()
    private(set) var calendarAccess = EKEventStore.authorizationStatus(for: .event)

    // MARK: Life + presentation
    let history: LifeHistory
    var hasArrived: Bool
    var userName: String
    /// Where the app should go next (from an App Intent, a coach mark or a deep link).
    var route: Route?

    enum Route: Hashable { case medication, personalise, customise, settings, actionButton, ai }

    private let scheduler = Scheduler()
    let calendar = Calendar.current

    enum BrainWeather: String, CaseIterable, Identifiable { case low, okay, good; var id: Self { self } }
    enum ReplanReason { case launch, doseLogged, dayVersionChanged, fixMyDay, tuningChanged }

    // MARK: Tuning: the learned patterns, as the person has chosen to adjust them

    struct Tuning: Codable, Equatable {
        /// Your own curve for the main medication (onset, offset in minutes after logging); nil = learned.
        var windowOverride: [Int]?
        var mealRuleMinutes = 270
        var fillCap = 0.6
        var transitionMinutes = 10
        var afterWindowBufferMinutes = 20
        var estimateBuffers: [String: Double] = [:]

        static let key = "tuning"
        static func load() -> Tuning {
            guard let data = UserDefaults.standard.data(forKey: key),
                  let tuning = try? JSONDecoder().decode(Tuning.self, from: data) else { return Tuning() }
            return tuning
        }
        func save() {
            if let data = try? JSONEncoder().encode(self) { UserDefaults.standard.set(data, forKey: Self.key) }
        }
    }

    var tuning = Tuning.load() {
        didSet {
            guard tuning != oldValue else { return }
            tuning.save()
            applyWindowOverride()
            replan(reason: .tuningChanged)
        }
    }

    var learnedWindow: (onset: Int, offset: Int) {
        let s = focusModel.summary
        return (s.onsetMedian, s.offsetMedian)
    }

    func learnedRatio(for task: TaskID) -> Double? {
        let names = ["essay": "Essay drafting", "reading": "Case reading", "prep": "Tutorial prep", "email": "Admin & email"]
        guard let name = names[task.raw], let estimate = history.estimates.first(where: { $0.id == name }) else { return nil }
        return Double(estimate.actualMinutes) / Double(estimate.guessMinutes)
    }

    private func applyWindowOverride() {
        if let o = tuning.windowOverride, o.count == 2 {
            focusModel.setManualOverride(onset: o[0], offset: o[1])
        } else {
            focusModel.releaseManualOverride()
        }
    }

    // MARK: Init

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        let calendar = Calendar.current
        if let i = arguments.firstIndex(of: "-demoClock"), i + 1 < arguments.count {
            let parts = arguments[i + 1].split(separator: ":").compactMap { Int($0) }
            let demo = calendar.date(bySettingHour: parts.first ?? 9, minute: parts.dropFirst().first ?? 41, second: 0, of: Date())!
            clockOffset = demo.timeIntervalSinceNow
        } else {
            clockOffset = 0
        }
        let start = Date().addingTimeInterval(clockOffset)
        let file = MedicationFile.load() ?? MedicationFile.starter()
        medications = file.medications
        dayTypes = file.dayTypes
        manualChoice = file.manualChoice
        actionButtonSuggested = file.actionButtonSuggested

        // Demo: this morning's booster and all-day dose are already logged, unless -freshDay.
        var seeded: [DoseEvent] = []
        if !arguments.contains("-freshDay") {
            for (hour, minute, kind) in [(7, 0, MedKind.booster), (8, 10, MedKind.longActing)] {
                guard let med = file.medications.first(where: { $0.kind == kind }) else { continue }
                let at = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: start)!
                seeded.append(DoseEvent(product: med.productID, takenAt: at, loggedAt: at, source: .watch, ateFirst: true,
                                        isBooster: kind == .booster))
            }
        }
        doseLog = DoseLog(products: file.medications.map(\.product), events: seeded)
        todaysDoses = seeded
        (focusModel, checkInPoints) = Self.seededModel(for: .lisdexamfetamine)
        history = LifeHistory.generate(endingOn: start)
        hasArrived = arguments.contains("-skipArrival")
        if let i = arguments.firstIndex(of: "-name"), i + 1 < arguments.count { userName = arguments[i + 1] }
        else { userName = UserDefaults.standard.string(forKey: "userName") ?? "" }
        applyWindowOverride()
        seedDay(start: start)
        replan(reason: .launch)
        Task { await self.afterLaunch() }
    }

    private func afterLaunch() async {
        await loadCalendar()
        await classifyTasks()
        await refreshSocial()
    }

    // MARK: Today's medication

    var medicationsByID: [UUID: Medication] { Dictionary(uniqueKeysWithValues: medications.map { ($0.id, $0) }) }

    /// Medications with learning switched on follow what check-ins learned about them.
    private func effectiveMedications() -> [UUID: Medication] {
        var meds = medicationsByID
        for (id, med) in meds where med.learns && med.kind == .longActing {
            let learned = focusModel.window(forDoseAt: calendar.startOfDay(for: now))
            var m = med
            m.kicksInMinutes = Int(learned.start.timeIntervalSince(learned.dose) / 60)
            m.lastsMinutes = Int(learned.end.timeIntervalSince(learned.dose) / 60)
            meds[id] = m
        }
        return meds
    }

    /// Which day type today is: the person's pick for today, else a matching date range (shortest
    /// wins, so "Exam week" beats "Semester"), else a matching weekday, else the first one.
    var todayDayType: DayType? {
        if let choice = manualChoice, calendar.isDate(choice.date, inSameDayAs: now),
           let picked = dayTypes.first(where: { $0.id == choice.dayTypeID }) { return picked }
        let ranged = dayTypes.filter { $0.appliesWhen.hasDateRange && $0.appliesWhen.matches(now, calendar: calendar) }
            .sorted { span($0) < span($1) }
        if let first = ranged.first { return first }
        if let weekday = dayTypes.first(where: { !$0.appliesWhen.hasDateRange && !$0.appliesWhen.weekdays.isEmpty && $0.appliesWhen.matches(now, calendar: calendar) }) {
            return weekday
        }
        return dayTypes.first
    }

    private func span(_ dayType: DayType) -> TimeInterval {
        guard let from = dayType.appliesWhen.from, let to = dayType.appliesWhen.to else { return .greatestFiniteMagnitude }
        return to.timeIntervalSince(from)
    }

    var todaySchedule: DaySchedule? { todayDayType?.schedule(effectiveMedications()) }

    struct PlannedDose: Identifiable, Equatable {
        let id: UUID
        let medication: Medication
        let planned: Date
        let logged: DoseEvent?
        var isLogged: Bool { logged != nil }
    }

    /// Today's doses from the day type, each matched to a logged dose of the same medication if there is one.
    var plannedDoses: [PlannedDose] {
        guard let dayType = todayDayType else { return [] }
        var unmatched = todaysDoses
        let meds = medicationsByID
        return dayType.sortedDoses.compactMap { slot in
            guard let med = meds[slot.medicationID] else { return nil }
            let planned = ClockMinutes.date(slot.minute, on: now, calendar: calendar)
            let candidates = unmatched.enumerated().filter { $0.element.product == med.productID && abs($0.element.takenAt.timeIntervalSince(planned)) < 4 * 3600 }
            let best = candidates.min { abs($0.element.takenAt.timeIntervalSince(planned)) < abs($1.element.takenAt.timeIntervalSince(planned)) }
            if let best { unmatched.remove(at: best.offset) }
            return PlannedDose(id: slot.id, medication: med, planned: planned, logged: best?.element)
        }
    }

    /// Due now: not logged yet and planned for no later than an hour from now.
    var dueDoses: [PlannedDose] { plannedDoses.filter { !$0.isLogged && $0.planned <= now.addingTimeInterval(3600) } }
    var nextDose: PlannedDose? { plannedDoses.first { !$0.isLogged && $0.planned > now.addingTimeInterval(3600) } }

    /// The first dose today (logged or planned): the anchor for "hours after your first dose".
    var doseAnchor: Date? { todaysDoses.first?.takenAt ?? plannedDoses.first(where: { $0.medication.kind != .windDown })?.planned }

    var todaysDose: DoseEvent? { todaysDoses.first }

    // MARK: Derived

    var nowBlock: Block? { plan.blocks.first { $0.kind == .task && $0.interval.contains(now) && !isDone($0) } }
    var nextBlock: Block? { plan.blocks.first { $0.interval.start > now && !isDone($0) } }
    var restOfToday: [Block] { plan.blocks.filter { $0 != nowBlock } }
    func isDone(_ block: Block) -> Bool { block.taskID.map(completed.contains) ?? false }

    var skyPhase: SkyPhase { SkyPhase.at(now, window: window) }

    /// One short sentence about where the day is.
    var dayLine: String {
        guard let window else { return Copy.line(.dayLineRoutine) }
        let t = Date.FormatStyle(date: .omitted, time: .shortened)
        if let gap = lowFocusStretches.first(where: { $0.contains(now) }) {
            return "Low-focus stretch until \(gap.end.formatted(t))."
        }
        switch window.zone(at: now) {
        case .before, .warmUp: return Copy.line(.dayLineWarming, ["time": window.start.formatted(t)])
        case .bestFocus: return Copy.line(.dayLineBest, ["time": window.bestFocusEnd.formatted(t)])
        case .lighterFocus: return Copy.line(.dayLineLighter, ["time": window.end.formatted(t)])
        case .after: return Copy.line(.dayLineAfter)
        }
    }

    var greeting: String {
        let hour = calendar.component(.hour, from: now)
        let slot: CopySlot = hour < 12 ? .arrivalMorning : hour < 17 ? .arrivalAfternoon : .arrivalEvening
        return Copy.line(slot, ["name": userName.isEmpty ? "you" : userName])
    }

    var todaySlices: [DayShapes.Slice] {
        var deep = 0.0, lighter = 0.0, body = 0.0, fixedMinutes = 0.0
        for block in plan.blocks {
            let m = block.interval.duration / 60
            if block.kind == .fixed { fixedMinutes += m; continue }
            switch block.demand {
            case .deep: deep += m
            case .medium, .light: lighter += m
            case .body: body += m
            case nil: break
            }
        }
        let windowMinutes = window.map { $0.end.timeIntervalSince($0.start) / 60 } ?? 0
        let gapMinutes = lowFocusStretches.reduce(0) { $0 + $1.duration / 60 }
        let open = max(0, windowMinutes - gapMinutes - deep - lighter)
        return [
            .init(id: "Deep work", minutes: deep, color: .zoneBest),
            .init(id: "Lighter work", minutes: lighter, color: .zoneLight),
            .init(id: "Body", minutes: body, color: .sage),
            .init(id: "Calendar", minutes: fixedMinutes, color: .slate),
            .init(id: "Open", minutes: max(open, 1), color: .track),
        ]
    }

    var doneCount: Int { plan.blocks.filter { $0.kind == .task && isDone($0) }.count }
    var taskCount: Int { plan.blocks.filter { $0.kind == .task }.count }

    /// The bottom bar's line: how today's medication is going, without naming anything.
    var doseGlance: String {
        let doses = plannedDoses
        guard !doses.isEmpty else { return todaysDoses.isEmpty ? "Nothing logged yet" : "Logged today" }
        let logged = doses.filter(\.isLogged).count
        if logged == doses.count { return "All \(doses.count) logged" }
        if let next = nextDose ?? dueDoses.first {
            return "\(logged) of \(doses.count) logged. Next \(next.planned.formatted(.compactTime))"
        }
        return "\(logged) of \(doses.count) logged"
    }

    // MARK: Logging

    enum LogResult: Equatable {
        case logged(at: Date)
        case alreadyLogged(previous: DoseEvent)
        case failed(String)
    }

    func logDose(_ medication: Medication, takenAt: Date, ateFirst: Bool?, gesture: UserGesture) async -> LogResult {
        do {
            let request = DoseLogRequest(product: medication.productID, takenAt: takenAt, ateFirst: ateFirst,
                                         isBooster: medication.kind == .booster, source: gesture.origin == .actionButton ? .intent : .app)
            switch try await doseLog.record(request, by: gesture) {
            case .logged(let event):
                didLog([event], medications: [medication.id])
                return .logged(at: event.takenAt)
            case .needsDeliberateConfirm(let previous):
                return .alreadyLogged(previous: previous)
            }
        } catch {
            return .failed("Couldn’t save that log. Nothing was changed.")
        }
    }

    func confirmSecondDose(_ medication: Medication, takenAt: Date, previous: DoseEvent, gesture: UserGesture) async -> LogResult {
        do {
            let event = try await doseLog.recordConfirmingDuplicate(DoseLogRequest(product: medication.productID, takenAt: takenAt,
                                                                                   isBooster: medication.kind == .booster),
                                                                    previous: previous.id, by: gesture)
            didLog([event], medications: [medication.id])
            return .logged(at: event.takenAt)
        } catch {
            return .failed("Couldn’t save that log. Nothing was changed.")
        }
    }

    struct LogAllOutcome {
        var logged: [Medication] = []
        var skipped: [Medication] = []
        var failed = false

        var spoken: String {
            if failed { return "Couldn’t save that. Nothing was changed." }
            if logged.isEmpty && skipped.isEmpty { return "Nothing to log right now." }
            var parts: [String] = []
            if !logged.isEmpty { parts.append("Logged \(logged.count == 1 ? "one dose" : "\(logged.count) doses").") }
            if !skipped.isEmpty { parts.append("\(skipped.count == 1 ? "One was" : "\(skipped.count) were") already logged, so I left \(skipped.count == 1 ? "it" : "them").") }
            return parts.joined(separator: " ")
        }
    }

    /// Logs every dose that's due, each through the double-dose guard. Anything the guard stops is
    /// skipped and reported, never logged twice by accident.
    func logAllDue(origin: UserGesture.Origin = .button) async -> LogAllOutcome {
        var outcome = LogAllOutcome()
        var events: [DoseEvent] = []
        for dose in dueDoses {
            let gesture = UserGesture(origin: origin, at: now)
            let request = DoseLogRequest(product: dose.medication.productID, takenAt: now, isBooster: dose.medication.kind == .booster,
                                         source: origin == .button ? .app : .intent)
            do {
                switch try await doseLog.record(request, by: gesture) {
                case .logged(let event): events.append(event); outcome.logged.append(dose.medication)
                case .needsDeliberateConfirm: outcome.skipped.append(dose.medication)
                }
            } catch {
                outcome.failed = true
            }
        }
        if !events.isEmpty { didLog(events, medications: Set(outcome.logged.map(\.id))) }
        return outcome
    }

    // MARK: Editing medication and day types

    func save(_ medication: Medication) {
        if let i = medications.firstIndex(where: { $0.id == medication.id }) { medications[i] = medication } else { medications.append(medication) }
        Task { await doseLog.register(medication.product) }
        persistMedication()
        replan(reason: .tuningChanged)
    }

    func delete(_ medication: Medication) {
        medications.removeAll { $0.id == medication.id }
        for i in dayTypes.indices { dayTypes[i].doses.removeAll { $0.medicationID == medication.id } }
        persistMedication()
        replan(reason: .tuningChanged)
    }

    func save(_ dayType: DayType) {
        if let i = dayTypes.firstIndex(where: { $0.id == dayType.id }) { dayTypes[i] = dayType } else { dayTypes.append(dayType) }
        persistMedication()
        replan(reason: .tuningChanged)
    }

    func delete(_ dayType: DayType) {
        dayTypes.removeAll { $0.id == dayType.id }
        if manualChoice?.dayTypeID == dayType.id { manualChoice = nil }
        persistMedication()
        replan(reason: .tuningChanged)
    }

    func moveDayTypes(from source: IndexSet, to destination: Int) {
        dayTypes.move(fromOffsets: source, toOffset: destination)
        persistMedication()
    }

    /// "Today is a weekend, whatever the calendar says." Lasts until midnight.
    func chooseToday(_ dayType: DayType?) {
        manualChoice = dayType.map { MedicationFile.ManualChoice(date: now, dayTypeID: $0.id) }
        persistMedication()
        replan(reason: .tuningChanged)
    }

    private func persistMedication() {
        MedicationFile(medications: medications, dayTypes: dayTypes, manualChoice: manualChoice,
                       actionButtonSuggested: actionButtonSuggested).save()
    }

    // MARK: Tasks

    func markDone(_ block: Block) {
        guard let id = block.taskID else { return }
        completed.insert(id)
        Haptics.shared.play(.complete)
        LiveActivityController.shared.modelDidChange()
    }

    func markDoneForNow(_ block: Block) {
        guard let id = block.taskID, let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        let spent = Int(max(0, now.timeIntervalSince(block.interval.start)) / 60)
        tasks[index].estimateMinutes = max(15, tasks[index].estimateMinutes - spent)
        var previous = plan
        previous.blocks.removeAll { $0.taskID == id }
        apply(solve(previous: previous, freezeUntil: now.addingTimeInterval(20 * 60)))
    }

    func previewFixMyDay(runningLateMinutes: Int = 0) -> PlanResult {
        var shiftedTasks = tasks
        if runningLateMinutes > 0, let current = nowBlock, let id = current.taskID,
           let index = shiftedTasks.firstIndex(where: { $0.id == id }) {
            shiftedTasks[index].estimateMinutes += runningLateMinutes
        }
        return solve(previous: plan, freezeUntil: now.addingTimeInterval(20 * 60), tasks: shiftedTasks)
    }

    private(set) var undoPlan: Plan?

    func applyFix(_ result: PlanResult) {
        undoPlan = plan
        apply(result)
    }

    func undoFix() {
        guard let undoPlan else { return }
        plan = undoPlan
        self.undoPlan = nil
        LiveActivityController.shared.modelDidChange()
    }

    /// Task names and times only: the most your own AI is ever sent, and only if you allowed it.
    func contextForExternalAI(names: Bool, times: Bool) -> String {
        guard names || times else { return "" }
        return plan.blocks.filter { $0.kind == .task || $0.kind == .fixed }.map { block in
            let name = names ? block.title : (block.kind == .fixed ? "Appointment" : "Task")
            return times ? "\(block.interval.start.formatted(.compactTime)) to \(block.interval.end.formatted(.compactTime)): \(name)" : name
        }.joined(separator: "\n")
    }

    // MARK: Calendar and social plans

    func requestCalendarAccess() async {
        _ = try? await calendarStore.requestFullAccessToEvents()
        calendarAccess = EKEventStore.authorizationStatus(for: .event)
        await loadCalendar()
        await refreshSocial()
    }

    private func loadCalendar() async {
        guard calendarAccess == .fullAccess else { return }
        let start = calendar.startOfDay(for: now), end = start.addingTimeInterval(86400)
        let events = calendarStore.events(matching: calendarStore.predicateForEvents(withStart: start, end: end, calendars: nil))
        let imported = events.filter { !$0.isAllDay }.map { FixedEvent(id: "cal-\($0.eventIdentifier ?? UUID().uuidString)", title: $0.title ?? "Busy",
                                                                            interval: DateInterval(start: $0.startDate, end: $0.endDate)) }
        fixed.removeAll { $0.id.hasPrefix("cal-") }
        fixed += imported
        replan(reason: .tuningChanged)
    }

    /// Plans with other people that land outside the time the person likes being social (or inside
    /// their alone time), each with the first free time inside their social window.
    func refreshSocial() async {
        guard personalisation.socialSuggestions, let anchor = doseAnchor else { socialSuggestions = []; return }
        let socialWindow = personalisation.social.interval(after: anchor)
        let aloneWindow = personalisation.alone.interval(after: anchor)
        var found: [SocialSuggestion] = []
        for event in fixed where event.interval.start > now && !personalisation.dismissedSuggestions.contains(event.id) {
            let read = await OnDeviceReader.read(event: event.title, attendees: 0)
            guard read.social else { continue }
            let outside = !socialWindow.contains(event.interval.start) || aloneWindow.contains(event.interval.start)
            guard outside, let slot = freeSlot(inside: socialWindow, length: event.interval.duration, ignoring: event.id) else { continue }
            let why = aloneWindow.contains(event.interval.start) ? "It’s in the time you like to yourself." : "It’s outside the time you like being around people."
            found.append(SocialSuggestion(id: event.id, eventTitle: event.title, person: read.person, current: event.interval, proposed: slot, why: why))
        }
        socialSuggestions = found
    }

    func dismissSuggestion(_ suggestion: SocialSuggestion) {
        personalisation.dismissedSuggestions.insert(suggestion.id)
        socialSuggestions.removeAll { $0.id == suggestion.id }
    }

    private func freeSlot(inside window: DateInterval, length: TimeInterval, ignoring id: String) -> Date? {
        let busy = plan.blocks.filter { $0.id != "fixed-\(id)" && $0.kind == .fixed }.map(\.interval)
        var start = max(window.start, now)
        let step: TimeInterval = 15 * 60
        start = Date(timeIntervalSinceReferenceDate: (start.timeIntervalSinceReferenceDate / step).rounded(.up) * step)
        while start.addingTimeInterval(length) <= window.end {
            let candidate = DateInterval(start: start, duration: length)
            if !busy.contains(where: { $0.intersects(candidate) && $0.intersection(with: candidate)!.duration > 0 }) { return start }
            start = start.addingTimeInterval(step)
        }
        return nil
    }

    /// Puts each task into one of the person's categories, on the phone.
    private func classifyTasks() async {
        var map = personalisation.taskCategories
        for task in tasks where map[task.id.raw] == nil {
            if let category = await OnDeviceReader.category(for: task.title, among: personalisation.categories) {
                map[task.id.raw] = category
            }
        }
        if map != personalisation.taskCategories { personalisation.taskCategories = map }
    }

    // MARK: Private

    private func didLog(_ events: [DoseEvent], medications: Set<UUID>) {
        Haptics.shared.play(events.count > 1 ? .logAll : .logged)
        todaysDoses.append(contentsOf: events)
        todaysDoses.sort { $0.takenAt < $1.takenAt }
        lastLoggedMedications = medications
        doseLoggedSequence += 1
        replan(reason: .doseLogged)
        Task { await refreshSocial() }
    }

    private func replan(reason: ReplanReason) {
        (window, lowFocusStretches, sleepReadyAt) = planningWindow()
        let freeze: Date? = switch reason {
        case .launch: nil
        case .tuningChanged: now
        default: now.addingTimeInterval(2 * 3600)
        }
        apply(solve(previous: reason == .launch ? nil : plan, freezeUntil: freeze))
    }

    /// Today's day type, turned into the scheduler's terms. If the first dose was logged at a
    /// different time from planned, the whole day shifts with it.
    private func planningWindow() -> (FocusWindow?, [DateInterval], Date?) {
        guard let schedule = todaySchedule, let span = schedule.span,
              let firstPlanned = plannedDoses.first(where: { $0.medication.kind != .windDown }) else { return (nil, [], nil) }
        let shift = (firstPlanned.logged?.takenAt ?? firstPlanned.planned).timeIntervalSince(firstPlanned.planned)
        let date = { (minute: Int) in ClockMinutes.date(minute, on: self.now, calendar: self.calendar).addingTimeInterval(shift) }
        let dose = firstPlanned.logged?.takenAt ?? firstPlanned.planned
        let rampUp = 20, rampDown = 60
        let start = date(span.start), end = date(span.end)
        let onset = max(0, Int(start.timeIntervalSince(dose) / 60) - rampUp)
        let offset = max(onset + rampUp + rampDown + 15, Int(end.timeIntervalSince(dose) / 60))
        let summary = focusModel.summary
        let window = FocusWindow(dose: dose, onsetMinutes: onset, offsetMinutes: offset, rampUpMinutes: rampUp, rampDownMinutes: rampDown,
                                 startUncertaintyMinutes: summary.startUncertainty, endUncertaintyMinutes: summary.endUncertainty,
                                 confidence: confidence(learning: plannedDoses.contains { $0.medication.learns && $0.medication.kind == .longActing }, summary: summary))
        let gaps = schedule.gaps.map { DateInterval(start: date($0.start), end: date($0.end)) }
        return (window, gaps, schedule.sleepReadyAt.map(date))
    }

    /// Only claim check-ins when the window really comes from them. Sliders or own windows are the
    /// person's own setting.
    private func confidence(learning: Bool, summary: FocusWindowModel.Summary) -> Confidence {
        if todayDayType?.usesOwnWindows == true || !learning { return .manualOverride }
        return summary.confidence
    }

    private func solve(previous: Plan?, freezeUntil: Date?, tasks override: [TaskSnapshot]? = nil) -> PlanResult {
        let start = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: now)!
        let end = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: now)!
        let anchor = doseAnchor
        let open = (override ?? tasks).map { task -> TaskSnapshot in
            guard completed.contains(task.id), task.pinnedInterval == nil, let done = plan.block(for: task.id) else {
                var t = task
                if task.pinnedInterval == nil, let buffer = tuning.estimateBuffers[task.id.raw] {
                    t.estimateMinutes = Int((Double(task.estimateMinutes) * buffer).rounded())
                }
                if let anchor, t.pinnedInterval == nil {
                    if isMeal(t) {
                        t.preferredWindow = personalisation.eating.interval(after: anchor)
                    } else if let category = personalisation.category(for: t) {
                        t.preferredWindow = category.window.interval(after: anchor)
                    }
                }
                return t
            }
            var pinned = task
            pinned.pinnedInterval = done.interval
            return pinned
        }
        return scheduler.solve(PlanRequest(day: DateInterval(start: start, end: end), tasks: open, fixed: fixed,
                                           window: window, previous: previous, freezeUntil: freezeUntil,
                                           earliestStart: previous == nil ? nil : now, dayVersion: dayVersion,
                                           fillCap: tuning.fillCap, transitionMinutes: tuning.transitionMinutes,
                                           mealRuleMinutesAfterDose: tuning.mealRuleMinutes,
                                           afterWindowBufferMinutes: tuning.afterWindowBufferMinutes,
                                           lowFocusStretches: lowFocusStretches))
    }

    private func isMeal(_ task: TaskSnapshot) -> Bool {
        let t = task.title.lowercased()
        return ["lunch", "breakfast", "dinner", "meal", "snack", "eat"].contains { t.contains($0) }
    }

    private func apply(_ result: PlanResult) {
        plan = result.plan
        fillPercent = result.fillPercent
        unplaced = result.changes.compactMap { if case .unplaced(let id, _) = $0 { id } else { nil } }
        // Every replan and every log lands here: keep Your day and Focus mode on the Lock Screen in step.
        LiveActivityController.shared.modelDidChange()
    }

    private func seedDay(start: Date) {
        func at(_ h: Int, _ m: Int) -> Date { calendar.date(bySettingHour: h, minute: m, second: 0, of: start)! }
        fixed = [FixedEvent(id: "tutorial", title: "Tutorial, Room 4.12", interval: DateInterval(start: at(14, 0), end: at(15, 0))),
                 FixedEvent(id: "coffee-maya", title: "Coffee with Maya", interval: DateInterval(start: at(10, 30), end: at(11, 15)))]
        tasks = [
            TaskSnapshot(id: TaskID("launch"), title: "Morning launch", estimateMinutes: 40, demand: .body,
                         pinnedInterval: DateInterval(start: at(7, 30), end: at(8, 10))),
            TaskSnapshot(id: TaskID("essay"), title: "Essay drafting", estimateMinutes: 80, demand: .deep, isBaseline: true),
            TaskSnapshot(id: TaskID("reading"), title: "Case reading", estimateMinutes: 90, demand: .deep),
            TaskSnapshot(id: TaskID("prep"), title: "Tutorial prep for Thursday", estimateMinutes: 50, demand: .medium),
            TaskSnapshot(id: TaskID("email"), title: "Email and plan tomorrow", estimateMinutes: 30, demand: .light),
            TaskSnapshot(id: TaskID("lunch"), title: "Lunch, even if you’re not hungry", estimateMinutes: 40, demand: .body, isBaseline: true),
            TaskSnapshot(id: TaskID("gym"), title: "Gym, upper body", estimateMinutes: 60, demand: .body),
        ]
        completed = [TaskID("launch")]
    }

    /// Nine days of simulated one-tap check-ins so the prototype opens on a learned window.
    private static func seededModel(for formulation: Formulation) -> (FocusWindowModel, [CheckInPoint]) {
        var points: [CheckInPoint] = []
        var model = FocusWindowModel(formulation: formulation, stated: .init(startsHelpingAfter: 45, helpsFor: 420))!
        var state: UInt64 = 7
        func random() -> Double {
            state &+= 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return Double((z ^ (z >> 31)) >> 11) / Double(1 << 53)
        }
        for day in 0..<9 {
            var last = 0
            for _ in 0..<4 {
                let minute = model.nextCheckInMinute(after: last) ?? 120
                last = minute
                let e = FocusCurve.effect(minutesAfterDose: Double(minute), onset: 15, offset: 540, rampUp: 45, rampDown: 110)
                let answer: CheckInAnswer = random() < 0.08 + 0.84 * e ? .yes : .no
                model.ingest(answer, minutesAfterDose: Double(minute), day: DateComponents(year: 2026, month: 10, day: 1 + day))
                points.append(CheckInPoint(minute: minute, answer: answer))
            }
        }
        return (model, points)
    }
}
