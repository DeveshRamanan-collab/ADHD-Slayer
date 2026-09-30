import Foundation
import ActivityKit
import Observation
import UIKit
import FocusModel
import FocusGlance

/// Starts, updates and ends the two Live Activities: Focus mode (the task and the time left) and
/// Your day (the stretch you're in and what's next). Everything is local, with no push and no
/// server; the widget extension only draws what's sent from here.
///
/// Times: the app's clock can be moved with `-demoClock`, so sessions and stretches are worked out
/// on `AppModel.now` and moved onto the real clock only when they're sent. That keeps the ring and
/// `Text(timerInterval:)` on the Lock Screen honest.
///
/// ActivityKit's `Activity` isn't `Sendable`, so this keeps only ids and does each ActivityKit call
/// in a small helper that looks the activity up by id.
@MainActor @Observable
final class LiveActivityController {
    static let shared = LiveActivityController()

    /// A Focus mode session, shared by the room and the Lock Screen. Times are on the app's clock.
    struct FocusSession: Equatable {
        var blockID: String
        var title: String
        var firstStep: String?
        var startsAt: Date
        var endsAt: Date
        /// Set while paused: the time left, standing still.
        var pausedLeft: TimeInterval?

        var isPaused: Bool { pausedLeft != nil }
        var length: TimeInterval { max(1, endsAt.timeIntervalSince(startsAt)) }
        func remaining(at now: Date) -> TimeInterval { pausedLeft ?? max(0, endsAt.timeIntervalSince(now)) }
        func fraction(at now: Date) -> Double { min(1, max(0, remaining(at: now) / length)) }
        func isTimeUp(at now: Date) -> Bool { !isPaused && now >= endsAt }
    }

    // MARK: What the screens read

    /// The running Focus mode session; nil when Focus mode is closed.
    private(set) var focusSession: FocusSession?
    /// Bumped when Done is pressed on the Lock Screen or in the Dynamic Island, so the room closes too.
    private(set) var focusEndedOutside = 0
    /// Live Activities are allowed for Focus in iOS Settings.
    private(set) var areActivitiesEnabled = ActivityAuthorizationInfo().areActivitiesEnabled
    /// Your day is on the Lock Screen right now.
    private(set) var isShowingDay = false

    // MARK: Rules from the spec

    /// Focus mode shows "Time's up." this long, then ends.
    private static let timeUpLinger: TimeInterval = 15 * 60
    /// An ended Focus mode stays on the Lock Screen this long.
    private static let focusDismissal: TimeInterval = 2 * 60
    /// iOS ends a Live Activity after 8 hours; Your day is restarted when the app next opens.
    private static let dayLifetime: TimeInterval = 8 * 3600
    private static let sessionKey = "liveFocusSession"

    // MARK: Private state

    @ObservationIgnored private var model: AppModel?
    @ObservationIgnored private var launched = false
    @ObservationIgnored private var focusActivityID: String?
    @ObservationIgnored private var dayActivityID: String?
    @ObservationIgnored private var dayStartedAt: Date?
    @ObservationIgnored private var sentFocus: GlanceState?
    @ObservationIgnored private var sentDay: GlanceState?
    /// The stretch line is picked once, when the stretch starts, and kept while it lasts.
    @ObservationIgnored private var pickedLine: (stretch: Stretch, endsAt: Date, line: String)?
    /// Activities this controller is ending, so their dismissal isn't mistaken for the person's.
    @ObservationIgnored private var endingIDs: Set<String> = []
    /// Swiped away on the Lock Screen: Your day stays away until tomorrow, Focus mode for this task.
    @ObservationIgnored private var dayDismissedOn: Date?
    @ObservationIgnored private var focusDismissedBlock: String?
    @ObservationIgnored private var lastSettings: LiveSettings?
    @ObservationIgnored private var focusTimer: Task<Void, Never>?
    @ObservationIgnored private var dayTimer: Task<Void, Never>?
    @ObservationIgnored private var pendingRefresh: Task<Void, Never>?
    @ObservationIgnored private var observers: [NSObjectProtocol] = []
    #if DEBUG
    @ObservationIgnored private var demo = Demo()
    #endif

    private init() {}

    // MARK: Launch

    /// Called once from `FocusApp.init`: picks up the activities from the last run and ends any
    /// duplicate, and lets the Live Activity buttons reach this model (their intents run in the app's
    /// process). Nothing new starts until the app is active.
    func launch(model: AppModel) {
        guard !launched else { return }
        launched = true
        self.model = model
        GlanceActions.handler = self
        lastSettings = .current
        #if DEBUG
        demo = Demo(arguments: ProcessInfo.processInfo.arguments)
        #endif
        restore()
        observe()
    }

    private func restore() {
        let live = Activity<FocusActivityAttributes>.activities.filter { $0.activityState == .active || $0.activityState == .stale }
        #if DEBUG
        if demo.isOn {
            // A clean slate for screenshots.
            for activity in live { end(activity.id, content: nil, .immediate) }
            return
        }
        #endif
        for kind in [FocusActivityAttributes.Kind.focusSession, .day] {
            let mine = live.filter { $0.attributes.kind == kind }.sorted { $0.attributes.startedAt > $1.attributes.startedAt }
            guard let keep = mine.first else { continue }
            for duplicate in mine.dropFirst() { end(duplicate.id, content: nil, .immediate) }
            watchState(of: keep)
            switch kind {
            case .focusSession:
                focusActivityID = keep.id
                sentFocus = keep.content.state
                focusSession = restoredSession(keep.id, keep.content.state)
                if focusSession == nil { end(keep.id, content: nil, .immediate); focusActivityID = nil; sentFocus = nil }
            case .day:
                dayActivityID = keep.id
                dayStartedAt = keep.attributes.startedAt
                sentDay = keep.content.state
                isShowingDay = true
            }
        }
    }

    private func restoredSession(_ activityID: String, _ state: GlanceState) -> FocusSession? {
        guard let starts = state.startsAt, let ends = state.endsAt else { return nil }
        let saved = UserDefaults.standard.data(forKey: Self.sessionKey).flatMap { try? JSONDecoder().decode(SavedSession.self, from: $0) }
        let mine = saved?.activityID == activityID ? saved : nil
        return FocusSession(blockID: mine?.blockID ?? "", title: mine?.title ?? state.title ?? "Focus",
                            firstStep: mine?.firstStep ?? state.firstStep,
                            startsAt: appTime(starts), endsAt: appTime(ends), pausedLeft: state.pausedLeft)
    }

    private func observe() {
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.appBecameActive() }
        })
        // Customise writes its settings straight to UserDefaults, wherever they're changed from.
        observers.append(center.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.settingsMayHaveChanged() }
        })
        Task { [weak self] in
            for await enabled in ActivityAuthorizationInfo().activityEnablementUpdates {
                self?.authorizationChanged(enabled)
            }
        }
    }

    private func appBecameActive() {
        areActivitiesEnabled = ActivityAuthorizationInfo().areActivitiesEnabled
        #if DEBUG
        startDemoOnce()
        #endif
        checkFocusTime()
        refreshDay()
    }

    private func settingsMayHaveChanged() {
        let now = LiveSettings.current
        guard now != lastSettings else { return }
        lastSettings = now
        scheduleRefresh()
    }

    private func authorizationChanged(_ enabled: Bool) {
        areActivitiesEnabled = enabled
        if enabled {
            refreshAll()
        } else {
            // iOS takes them away itself; forget the handles so nothing tries to update them.
            focusActivityID = nil
            sentFocus = nil
            dayActivityID = nil
            sentDay = nil
            isShowingDay = false
        }
    }

    // MARK: Hooks from the model

    /// A log, a replan, a task done or discreet mode changed: bring both activities up to date.
    /// Several changes in a row are sent as one update.
    func modelDidChange() {
        guard launched else { return }
        scheduleRefresh()
    }

    private func scheduleRefresh() {
        pendingRefresh?.cancel()
        pendingRefresh = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }
            self?.refreshAll()
        }
    }

    private func refreshAll() {
        publishFocus()
        refreshDay()
    }

    // MARK: Focus mode

    /// The task the room should show: the session's own task while its time runs (it may run past
    /// the plan after +5 min), otherwise whatever is on now.
    func focusBlock(in model: AppModel) -> Block? {
        if let s = focusSession, !s.isTimeUp(at: model.now),
           let block = model.plan.blocks.first(where: { $0.id == s.blockID }), !model.isDone(block) {
            return block
        }
        return model.nowBlock
    }

    /// Focus mode opened on a task, or moved on to the next one: start its session, or keep the one
    /// it already has (with any pause or +5 min).
    func focusOpened(on block: Block) {
        if let s = focusSession, s.blockID == block.id {
            publishFocus()
            return
        }
        if focusSession != nil { finishFocus(.movedOn) }
        focusSession = FocusSession(blockID: block.id, title: block.title, firstStep: Explainer.firstStep(for: block),
                                    startsAt: block.interval.start, endsAt: block.interval.end)
        focusDismissedBlock = nil
        publishFocus()
    }

    /// Focus mode closed without Done.
    func focusClosed() {
        guard focusSession != nil || focusActivityID != nil else { return }
        finishFocus(.closed)
    }

    /// Done in the room (the room marks the task done itself).
    func focusDone() { finishFocus(.done) }

    func pauseFocus() {
        guard let model, var s = focusSession, !s.isPaused, !s.isTimeUp(at: model.now) else { return }
        s.pausedLeft = s.remaining(at: model.now)
        focusSession = s
        publishFocus()
    }

    func resumeFocus() {
        guard let model, var s = focusSession, let left = s.pausedLeft else { return }
        let length = s.length
        s.endsAt = model.now.addingTimeInterval(left)
        s.startsAt = s.endsAt.addingTimeInterval(-length)
        s.pausedLeft = nil
        focusSession = s
        publishFocus()
    }

    /// +5 min. After the time is up it starts five fresh minutes.
    func extendFocus(minutes: Int = 5) {
        guard let model, var s = focusSession else { return }
        let extra = TimeInterval(minutes * 60)
        if let left = s.pausedLeft {
            s.pausedLeft = left + extra
            s.endsAt = s.endsAt.addingTimeInterval(extra)
        } else if s.endsAt <= model.now {
            s.startsAt = model.now
            s.endsAt = model.now.addingTimeInterval(extra)
        } else {
            s.endsAt = s.endsAt.addingTimeInterval(extra)
        }
        focusSession = s
        publishFocus()
    }

    private enum FocusEnd { case done, closed, timeUp, movedOn }

    private func finishFocus(_ reason: FocusEnd) {
        focusTimer?.cancel()
        focusTimer = nil
        focusSession = nil
        UserDefaults.standard.removeObject(forKey: Self.sessionKey)
        guard let id = focusActivityID else { return }
        focusActivityID = nil
        var final = sentFocus ?? GlanceState(discreet: model?.discreetMode ?? true, title: "Focus", cheer: Copy.line(.focusDoneCheer))
        sentFocus = nil
        switch reason {
        case .done, .closed:
            // No timing left: it reads "Time's up." and the cheer for its last two minutes.
            final.startsAt = nil
            final.endsAt = nil
            final.pausedLeft = nil
            end(id, content: ActivityContent(state: final, staleDate: nil, relevanceScore: 100), .after(.now.addingTimeInterval(Self.focusDismissal)))
        case .timeUp:
            end(id, content: ActivityContent(state: final, staleDate: nil, relevanceScore: 100), .after(.now.addingTimeInterval(Self.focusDismissal)))
        case .movedOn:
            end(id, content: nil, .immediate)
        }
    }

    /// Sends the session to the Lock Screen: starts the activity, updates it, or ends it when it's
    /// switched off in Customise or iOS Settings.
    private func publishFocus(force: Bool = false) {
        sendFocus(force: force)
        scheduleFocusTimer()
    }

    private func sendFocus(force: Bool = false) {
        guard let model, let session = focusSession else { return }
        let settings = LiveSettings.current
        var on = settings.focusMode
        #if DEBUG
        on = on || demo.focus
        #endif
        guard on, areActivitiesEnabled, focusDismissedBlock != session.blockID else {
            if let id = focusActivityID {
                focusActivityID = nil
                sentFocus = nil
                end(id, content: nil, .immediate)
            }
            return
        }
        let state = focusState(session, settings, model)
        let staleDate = session.isPaused ? nil : realTime(session.endsAt).addingTimeInterval(60)
        let content = ActivityContent(state: state, staleDate: staleDate, relevanceScore: 100)
        if let id = focusActivityID {
            if force || state != sentFocus { update(id, content) }
        } else if let id = request(.focusSession, content) {
            focusActivityID = id
            saveSession()
        }
        sentFocus = state
    }

    private func focusState(_ s: FocusSession, _ settings: LiveSettings, _ model: AppModel) -> GlanceState {
        let hide = settings.hideTaskNames
        let title = hide ? "Focus" : scrub(s.title, model) ?? "Focus"
        let step = hide || !settings.showFirstStep ? nil : s.firstStep.flatMap { scrub($0, model) }
        // The cheer rides along with every update, so "Time's up." has its line even if the app is
        // asleep when the time runs out.
        return GlanceState(discreet: model.discreetMode, title: title, firstStep: step,
                           startsAt: realTime(s.startsAt), endsAt: realTime(s.endsAt), pausedLeft: s.pausedLeft,
                           cheer: Copy.line(.focusDoneCheer))
    }

    /// Redraws at the end ("Time's up."), then ends 15 minutes later, while the app runs.
    /// If it's asleep, the activity goes stale (which reads the same) and ends when the app opens.
    private func scheduleFocusTimer() {
        focusTimer?.cancel()
        focusTimer = nil
        guard let model, let s = focusSession, !s.isPaused else { return }
        let upIn = s.endsAt.timeIntervalSince(model.now)
        let endIn = upIn + Self.timeUpLinger
        focusTimer = Task { [weak self] in
            if upIn > 0 {
                try? await Task.sleep(for: .seconds(upIn + 1))
                guard !Task.isCancelled else { return }
                self?.sendFocus(force: true)
            }
            try? await Task.sleep(for: .seconds(max(1, endIn - max(0, upIn + 1))))
            guard !Task.isCancelled else { return }
            self?.checkFocusTime()
        }
    }

    private func checkFocusTime() {
        guard let model, let s = focusSession, !s.isPaused else { return }
        if model.now >= s.endsAt.addingTimeInterval(Self.timeUpLinger) { finishFocus(.timeUp) }
    }

    private struct SavedSession: Codable {
        var activityID: String
        var blockID: String
        var title: String
        var firstStep: String?
    }

    /// Remembers which task a Focus mode activity belongs to, so Done on the Lock Screen still marks
    /// the right task after the app was closed. Task titles only; nothing medical.
    private func saveSession() {
        guard let s = focusSession, let id = focusActivityID,
              let data = try? JSONEncoder().encode(SavedSession(activityID: id, blockID: s.blockID, title: s.title, firstStep: s.firstStep)) else { return }
        UserDefaults.standard.set(data, forKey: Self.sessionKey)
    }

    // MARK: Your day

    /// Starts, updates or ends Your day. Runs when the app opens, on a log or replan, at each stretch
    /// edge while the app runs, and from background refresh once that exists.
    func refreshDay(force: Bool = false) {
        guard let model else { return }
        let settings = LiveSettings.current
        var on = settings.day
        #if DEBUG
        on = on || demo.day
        #endif
        let today = Calendar.current.startOfDay(for: .now)
        if let dismissed = dayDismissedOn, dismissed < today { dayDismissedOn = nil }
        guard on, areActivitiesEnabled, dayDismissedOn == nil, let plan = dayPlan(model, settings) else {
            endDay()
            return
        }
        // Eight hours is the most iOS allows: end it and start a fresh one.
        if let started = dayStartedAt, Date.now.timeIntervalSince(started) >= Self.dayLifetime - 60 { endDay() }
        let content = ActivityContent(state: plan.state, staleDate: plan.staleDate, relevanceScore: 50)
        if let id = dayActivityID {
            if force || plan.state != sentDay { update(id, content) }
        } else if let id = request(.day, content) {
            dayActivityID = id
            dayStartedAt = .now
        }
        sentDay = dayActivityID == nil ? nil : plan.state
        isShowingDay = dayActivityID != nil
        var edge = plan.nextEdge
        if let started = dayStartedAt { edge = min(edge, appTime(started.addingTimeInterval(Self.dayLifetime))) }
        scheduleDayTimer(at: edge)
    }

    private func endDay() {
        dayTimer?.cancel()
        dayTimer = nil
        isShowingDay = false
        guard let id = dayActivityID else { return }
        dayActivityID = nil
        dayStartedAt = nil
        sentDay = nil
        end(id, content: nil, .immediate)
    }

    private func scheduleDayTimer(at edge: Date) {
        dayTimer?.cancel()
        guard let model, dayActivityID != nil else { dayTimer = nil; return }
        let wait = max(1, edge.timeIntervalSince(model.now) + 1)
        dayTimer = Task { [weak self] in
            try? await Task.sleep(for: .seconds(wait))
            guard !Task.isCancelled else { return }
            self?.refreshDay()
        }
    }

    private struct DayPlan {
        var state: GlanceState
        var staleDate: Date?
        /// When it next needs redrawing, on the app's clock.
        var nextEdge: Date
    }

    /// Where the day is: the stretch now and when it ends, the next 8 hours, what's next, and whether
    /// Log belongs on it. Nil when there's no day to show: no focus window today (a lighter day with
    /// no windows), or winding down is over.
    private func dayPlan(_ model: AppModel, _ settings: LiveSettings) -> DayPlan? {
        guard let window = model.window else { return nil }
        let now = model.now
        let timeline = StretchTimeline(windowOpens: window.dose, bestStart: window.start, bestEnd: window.bestFocusEnd,
                                   windowEnd: window.end, windDownEnd: windDownEnd(model, window),
                                   lowFocus: model.lowFocusStretches)
        guard let current = timeline.current(at: now) else { return nil }
        let next = model.nextBlock
        var shows = settings.dayShows
        // Nothing left on the plan: show the stretch rather than an empty Next.
        if shows == .next && next == nil { shows = .stretch }
        let segments = timeline.segments(from: now).map { Segment(start: realTime($0.start), end: realTime($0.end), stretch: $0.stretch) }
        let state = GlanceState(discreet: model.discreetMode,
                                stretch: current.stretch, stretchEndsAt: realTime(current.endsAt),
                                stretchLine: stretchLine(current.stretch, endsAt: current.endsAt),
                                dayShows: shows,
                                nextTitle: next.map { scrub($0.title, model) ?? "Something planned" },
                                nextAt: next.map { realTime($0.interval.start) },
                                segments: segments,
                                showLog: settings.logButton && somethingSetForAboutNow(model))
        var edges = [current.endsAt]
        if let start = next?.interval.start, start > now { edges.append(start) }
        edges += aboutNowEdges(model).filter { $0 > now }
        return DayPlan(state: state, staleDate: shows == .next ? state.nextAt : state.stretchEndsAt, nextEdge: edges.min() ?? current.endsAt)
    }

    /// Winding down runs from the end of the focus window to when the person can usually sleep, or
    /// two hours when that isn't known.
    private func windDownEnd(_ model: AppModel, _ window: FocusWindow) -> Date {
        guard let ready = model.sleepReadyAt, ready > window.end.addingTimeInterval(30 * 60) else {
            return window.end.addingTimeInterval(2 * 3600)
        }
        return min(ready, window.end.addingTimeInterval(5 * 3600))
    }

    /// The line from Today's copy slots, picked once when the stretch starts ("Best focus until 1:40.").
    private func stretchLine(_ stretch: Stretch, endsAt: Date) -> String {
        if let picked = pickedLine, picked.stretch == stretch, picked.endsAt == endsAt { return picked.line }
        let time = GlanceFormat.time(realTime(endsAt))
        let line = switch stretch {
        case .best: Copy.line(.dayLineBest, ["time": time])
        case .lighter: Copy.line(.dayLineLighter, ["time": time])
        case .open: Copy.line(.dayLineWarming, ["time": time])
        case .windDown: Copy.line(.dayLineAfter)
        case .lowFocus: "Low-focus stretch until \(time)."
        }
        pickedLine = (stretch, endsAt, line)
        return line
    }

    /// Something set for about now and not logged yet: planned from 90 minutes before to 60 minutes
    /// after now, the compliance rule for "about now" (06, R7).
    private func somethingSetForAboutNow(_ model: AppModel) -> Bool {
        let now = model.now
        return model.plannedDoses.contains {
            !$0.isLogged && $0.planned >= now.addingTimeInterval(-90 * 60) && $0.planned <= now.addingTimeInterval(60 * 60)
        }
    }

    /// When "about now" starts and stops covering an unlogged dose, so Log appears and leaves on time.
    private func aboutNowEdges(_ model: AppModel) -> [Date] {
        model.plannedDoses.filter { !$0.isLogged }.flatMap {
            [$0.planned.addingTimeInterval(-60 * 60), $0.planned.addingTimeInterval(90 * 60)]
        }
    }

    // MARK: Words

    /// Discreet mode: a title that happens to contain a medicine's name never reaches the Lock
    /// Screen. Returns nil when it would have.
    private func scrub(_ text: String, _ model: AppModel) -> String? {
        guard model.discreetMode else { return text }
        let names = model.medications.map { $0.name.trimmingCharacters(in: .whitespaces) }.filter { $0.count >= 3 }
        return names.contains { text.localizedCaseInsensitiveContains($0) } ? nil : text
    }

    // MARK: Clocks

    /// The app's clock (which `-demoClock` moves) to the real one, and back.
    private func realTime(_ date: Date) -> Date { date.addingTimeInterval(-(model?.clockOffset ?? 0)) }
    private func appTime(_ date: Date) -> Date { date.addingTimeInterval(model?.clockOffset ?? 0) }

    // MARK: ActivityKit

    /// Returns the new activity's id, or nil when iOS won't start one right now (switched off, the app
    /// in the background outside an intent, or the system's limit reached). The next refresh tries again.
    private func request(_ kind: FocusActivityAttributes.Kind, _ content: ActivityContent<GlanceState>) -> String? {
        do {
            let activity = try Activity.request(attributes: FocusActivityAttributes(kind: kind, startedAt: .now), content: content, pushType: nil)
            watchState(of: activity)
            return activity.id
        } catch {
            return nil
        }
    }

    private func update(_ id: String, _ content: ActivityContent<GlanceState>) {
        Task { await Self.update(id: id, content) }
    }

    private func end(_ id: String, content: ActivityContent<GlanceState>?, _ dismissal: ActivityUIDismissalPolicy) {
        endingIDs.insert(id)
        Task { await Self.end(id: id, content, dismissal) }
    }

    private nonisolated static func update(id: String, _ content: ActivityContent<GlanceState>) async {
        guard let activity = Activity<FocusActivityAttributes>.activities.first(where: { $0.id == id }) else { return }
        await activity.update(content)
    }

    private nonisolated static func end(id: String, _ content: ActivityContent<GlanceState>?, _ dismissal: ActivityUIDismissalPolicy) async {
        guard let activity = Activity<FocusActivityAttributes>.activities.first(where: { $0.id == id }) else { return }
        await activity.end(content, dismissalPolicy: dismissal)
    }

    /// Notices when an activity ends or is swiped away.
    private func watchState(of activity: Activity<FocusActivityAttributes>) {
        let id = activity.id
        let updates = activity.activityStateUpdates
        Task { [weak self] in
            for await state in updates {
                self?.activity(id, changedTo: state)
                if state == .ended || state == .dismissed { break }
            }
        }
    }

    private func activity(_ id: String, changedTo state: ActivityState) {
        guard state == .ended || state == .dismissed else { return }
        let ours = endingIDs.remove(id) != nil
        if id == dayActivityID {
            dayActivityID = nil
            dayStartedAt = nil
            sentDay = nil
            isShowingDay = false
            dayTimer?.cancel()
            // Swiped away by the person: leave it for today. Ended by iOS after 8 hours: it comes
            // back the next time the app opens.
            if !ours && state == .dismissed { dayDismissedOn = Calendar.current.startOfDay(for: .now) }
        }
        if id == focusActivityID {
            focusActivityID = nil
            sentFocus = nil
            if !ours, let s = focusSession { focusDismissedBlock = s.blockID }
        }
    }

    // MARK: Settings

    /// The Customise options the activities follow.
    private struct LiveSettings: Equatable {
        var focusMode: Bool
        var day: Bool
        var dayShows: DayShows
        var logButton: Bool
        var hideTaskNames: Bool
        var showFirstStep: Bool

        init(_ s: CustomSettings) {
            focusMode = s.liveFocusMode
            day = s.liveDay
            dayShows = s.liveDayShows
            logButton = s.liveLogButton
            hideTaskNames = s.liveHideTaskNames
            showFirstStep = s.showFirstStep
        }

        static var current: LiveSettings { LiveSettings(.saved) }
    }
}

// MARK: - The Live Activity buttons

extension LiveActivityController: GlanceActionHandling {
    /// Done on the Lock Screen or in the Dynamic Island: the same as Done in the room.
    func endFocusSession() async {
        if let model, let s = focusSession, let block = model.plan.blocks.first(where: { $0.id == s.blockID }),
           block.kind == .task, !model.isDone(block) {
            model.markDone(block)
        }
        finishFocus(.done)
        focusEndedOutside += 1
    }

    func extendFocusSession(byMinutes minutes: Int) async {
        extendFocus(minutes: minutes)
    }

    /// Log on Your day (after Face ID on a locked phone): the same Log all path, with the same
    /// double-dose guard, as the app and the Action button.
    func logEverythingSetForNow() async -> String {
        guard let model else { return "Couldn’t save that. Nothing was changed." }
        let outcome = await model.logAllDue(origin: .actionButton)
        refreshDay(force: true)
        return outcome.spoken
    }
}

typealias GlanceState = FocusActivityAttributes.ContentState

// MARK: - Demo

#if DEBUG
extension LiveActivityController {
    /// `-liveDemo focus|day|both` starts the Live Activities with realistic content for screenshots,
    /// whatever Customise says. Debug builds only.
    fileprivate struct Demo {
        var focus = false
        var day = false
        var started = false
        var isOn: Bool { focus || day }

        init(arguments: [String] = []) {
            guard let i = arguments.firstIndex(of: "-liveDemo"), i + 1 < arguments.count else { return }
            let which = arguments[i + 1]
            focus = which == "focus" || which == "both"
            day = which == "day" || which == "both"
        }
    }

    fileprivate func startDemoOnce() {
        guard demo.isOn, !demo.started, let model else { return }
        demo.started = true
        guard demo.focus else { return }
        let tasks = model.plan.blocks.filter { $0.kind == .task && !model.isDone($0) }
        guard let block = model.nowBlock ?? tasks.first(where: { $0.interval.start > model.now }) ?? tasks.first else { return }
        // Twenty-five minutes in, fifty-five to go.
        focusSession = FocusSession(blockID: block.id, title: block.title, firstStep: Explainer.firstStep(for: block),
                                    startsAt: model.now.addingTimeInterval(-25 * 60), endsAt: model.now.addingTimeInterval(55 * 60))
        publishFocus()
    }
}
#endif
