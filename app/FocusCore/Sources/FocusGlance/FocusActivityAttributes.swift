import Foundation

/// The two Live Activities: Focus mode (the task you're on and the time left) and Your day (the
/// stretch you're in and what's next). Both are local: the app starts, updates and ends them on the
/// phone, and the widget extension only draws what it's sent. There are no medicine names in here
/// at all, only task titles and stretch names.
public struct FocusActivityAttributes: Codable, Hashable, Sendable {
    public enum Kind: String, Codable, Hashable, Sendable {
        case focusSession, day
    }

    /// Fixed for the activity's life.
    public var kind: Kind
    public var startedAt: Date

    public init(kind: Kind, startedAt: Date = .now) {
        self.kind = kind
        self.startedAt = startedAt
    }

    public struct ContentState: Codable, Hashable, Sendable {
        /// Settings, Privacy, Discreet mode.
        public var discreet: Bool

        // MARK: Focus mode

        /// The task, 60 characters at most ("Focus" when task names are hidden on the Lock Screen).
        public var title: String?
        /// Only when "Show the first step" is on.
        public var firstStep: String?
        /// The ring and the bar run from `startsAt` to `endsAt`, and `Text(timerInterval:)` counts to
        /// `endsAt`. Both are nil once the session has ended.
        public var startsAt: Date?
        public var endsAt: Date?
        /// Set while paused: the time left, standing still.
        public var pausedLeft: TimeInterval?
        /// The line under "Time's up.", from the app's rotating `focusDoneCheer` copy slot ("Done.
        /// Nicely handled."). Sent with every update so the time's-up view works without the app.
        public var cheer: String?

        // MARK: Your day

        public var stretch: Stretch
        public var stretchEndsAt: Date?
        /// The stretch line from the day's copy slot, picked by the app when the stretch starts
        /// ("Best focus until 1:40."). The extension can't read the copy deck, so the line travels here.
        public var stretchLine: String?
        /// Customise, "Your day shows".
        public var dayShows: DayShows
        /// The next plan item.
        public var nextTitle: String?
        public var nextAt: Date?
        /// The next 8 hours, at most 8 segments.
        public var segments: [Segment]
        /// Customise, and something set for about now.
        public var showLog: Bool

        public static let titleLimit = 60
        public static let segmentLimit = 8

        public init(discreet: Bool, title: String? = nil, firstStep: String? = nil, startsAt: Date? = nil,
                    endsAt: Date? = nil, pausedLeft: TimeInterval? = nil, cheer: String? = nil, stretch: Stretch = .open,
                    stretchEndsAt: Date? = nil, stretchLine: String? = nil, dayShows: DayShows = .both,
                    nextTitle: String? = nil, nextAt: Date? = nil, segments: [Segment] = [], showLog: Bool = false) {
            self.discreet = discreet
            self.title = Self.clip(title)
            self.firstStep = Self.clip(firstStep, to: 90)
            self.startsAt = startsAt
            self.endsAt = endsAt
            self.pausedLeft = pausedLeft
            self.cheer = Self.clip(cheer, to: 90)
            self.stretch = stretch
            self.stretchEndsAt = stretchEndsAt
            self.stretchLine = stretchLine
            self.dayShows = dayShows
            self.nextTitle = Self.clip(nextTitle)
            self.nextAt = nextAt
            self.segments = Array(segments.prefix(Self.segmentLimit))
            self.showLog = showLog
        }

        /// Takes whatever a saved or older payload has, key by key, so a restored activity never fails
        /// to decode after an update.
        public init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            func take<T: Decodable>(_ key: CodingKeys) -> T? { (try? c.decodeIfPresent(T.self, forKey: key)) ?? nil }
            discreet = take(.discreet) ?? true
            title = take(.title)
            firstStep = take(.firstStep)
            startsAt = take(.startsAt)
            endsAt = take(.endsAt)
            pausedLeft = take(.pausedLeft)
            cheer = take(.cheer)
            stretch = take(.stretch) ?? .open
            stretchEndsAt = take(.stretchEndsAt)
            stretchLine = take(.stretchLine)
            dayShows = take(.dayShows) ?? .both
            nextTitle = take(.nextTitle)
            nextAt = take(.nextAt)
            segments = take(.segments) ?? []
            showLog = take(.showLog) ?? false
        }

        /// Trims and shortens a title so the payload stays small and nothing wraps badly.
        public static func clip(_ text: String?, to limit: Int = titleLimit) -> String? {
            guard let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else { return nil }
            guard trimmed.count > limit else { return trimmed }
            return String(trimmed.prefix(limit - 1)).trimmingCharacters(in: .whitespaces) + "…"
        }
    }
}

// MARK: - Your day

/// The stretch of the day you're in. Names describe the person's focus, never a medicine.
public enum Stretch: String, Codable, Hashable, Sendable, CaseIterable {
    case best, lighter, lowFocus, windDown, open

    public var displayName: String {
        switch self {
        case .best: "Best focus"
        case .lighter: "Lighter focus"
        case .lowFocus: "Low-focus stretch"
        case .windDown: "Winding down"
        case .open: "Open time"
        }
    }
}

/// One piece of the Your day bar.
public struct Segment: Codable, Hashable, Sendable {
    public var start: Date
    public var end: Date
    public var stretch: Stretch

    public init(start: Date, end: Date, stretch: Stretch) {
        self.start = start
        self.end = end
        self.stretch = stretch
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        start = try c.decode(Date.self, forKey: .start)
        end = try c.decode(Date.self, forKey: .end)
        stretch = (try? c.decodeIfPresent(Stretch.self, forKey: .stretch)) ?? .open
    }

    public var duration: TimeInterval { max(0, end.timeIntervalSince(start)) }
}

/// Customise, Lock Screen and Dynamic Island, "Your day shows".
public enum DayShows: String, Codable, Hashable, Sendable, CaseIterable, Identifiable {
    case stretch, next, both
    public var id: Self { self }

    public var label: String {
        switch self {
        case .stretch: "Stretch only"
        case .next: "Next only"
        case .both: "Both"
        }
    }

    public var showsStretch: Bool { self != .next }
    public var showsNext: Bool { self != .stretch }
}

// MARK: - Reading the state

extension FocusActivityAttributes.ContentState {
    /// Where a Focus mode session is, as the views draw it.
    public enum FocusPhase: Hashable, Sendable {
        /// Counting down: the ring and `Text(timerInterval:)` run over this interval.
        case running(ClosedRange<Date>)
        /// Standing still with this much left; `fraction` is the ring's fill.
        case paused(left: TimeInterval, fraction: Double)
        /// The time is up (or the activity went stale a minute after it): "Time's up." and the cheer,
        /// until the app ends it.
        case timeUp
        /// The app ended the session (Done, or Focus mode closed): drawn like time's up, without buttons.
        case ended
    }

    /// `isStale` comes from the activity: Focus mode goes stale a minute after the time is up.
    public func focusPhase(at now: Date, isStale: Bool) -> FocusPhase {
        if let left = pausedLeft {
            let total = startsAt.flatMap { s in endsAt.map { $0.timeIntervalSince(s) } } ?? left
            return .paused(left: max(0, left), fraction: total > 0 ? min(1, max(0, left / total)) : 1)
        }
        guard let start = startsAt, let end = endsAt else { return .ended }
        if isStale || end <= now { return .timeUp }
        return .running(min(start, end)...end)
    }

    /// The ring's fill right now: time left over the session's length.
    public func focusFraction(at now: Date) -> Double {
        switch focusPhase(at: now, isStale: false) {
        case .running(let range):
            let total = range.upperBound.timeIntervalSince(range.lowerBound)
            return total > 0 ? min(1, max(0, range.upperBound.timeIntervalSince(now) / total)) : 0
        case .paused(_, let fraction): return fraction
        case .timeUp, .ended: return 0
        }
    }

    /// "Best focus until 1:40." when the app didn't send a line of its own.
    public func stretchSentence(time: (Date) -> String) -> String {
        if let stretchLine, !stretchLine.isEmpty { return stretchLine }
        guard let end = stretchEndsAt else { return stretch.displayName + "." }
        return "\(stretch.displayName) until \(time(end))."
    }
}

// MARK: - ActivityKit

// ActivityKit ships in the macOS SDK too, but `ActivityAttributes` is iPhone only, so the
// conformance is iOS only and `swift test` on a Mac still builds this package.
#if canImport(ActivityKit) && os(iOS)
import ActivityKit

extension FocusActivityAttributes: ActivityAttributes {}
#endif
