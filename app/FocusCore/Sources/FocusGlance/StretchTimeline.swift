import Foundation

/// Where the day's stretches fall, worked out from the focus window's edges and the low-focus
/// stretches between windows. Pure and clock-free: the app passes in its own times (so `-demoClock`
/// works) and moves the result onto the real clock before sending it to the Lock Screen.
public struct StretchTimeline: Hashable, Sendable {
    /// The time the window is measured from (warming up starts here).
    public var windowOpens: Date
    /// Best focus.
    public var bestStart: Date
    public var bestEnd: Date
    /// Lighter focus runs from `bestEnd` to here; winding down starts here.
    public var windowEnd: Date
    /// Winding down ends here, and with it the day.
    public var windDownEnd: Date
    /// Gaps between windows.
    public var lowFocus: [DateInterval]

    public init(windowOpens: Date, bestStart: Date, bestEnd: Date, windowEnd: Date, windDownEnd: Date, lowFocus: [DateInterval]) {
        self.windowOpens = windowOpens
        self.bestStart = bestStart
        self.bestEnd = max(bestStart, bestEnd)
        self.windowEnd = max(self.bestEnd, windowEnd)
        self.windDownEnd = max(self.windowEnd, windDownEnd)
        self.lowFocus = lowFocus.filter { $0.duration > 0 }
    }

    /// The stretch at a moment, or nil once winding down is over and the day is done.
    public func stretch(at t: Date) -> Stretch? {
        if t >= windDownEnd { return nil }
        if lowFocus.contains(where: { $0.start <= t && t < $0.end }) { return .lowFocus }
        if t < bestStart { return .open }
        if t < bestEnd { return .best }
        if t < windowEnd { return .lighter }
        return .windDown
    }

    /// Every moment the stretch can change, in order.
    public var edges: [Date] {
        var all = [windowOpens, bestStart, bestEnd, windowEnd, windDownEnd]
        for gap in lowFocus { all += [gap.start, gap.end] }
        return Array(Set(all)).sorted()
    }

    /// The stretch now and when it ends; nil once the day is done.
    public func current(at now: Date) -> (stretch: Stretch, endsAt: Date)? {
        guard let here = stretch(at: now) else { return nil }
        for edge in edges where edge > now && stretch(at: edge) != here {
            return (here, edge)
        }
        return (here, windDownEnd)
    }

    /// The next `hours` as one run of segments, neighbours of the same stretch merged, at most `limit`
    /// of them. Time after winding down reads as open time.
    public func segments(from now: Date, hours: Double = 8, limit: Int = FocusActivityAttributes.ContentState.segmentLimit) -> [Segment] {
        let horizon = now.addingTimeInterval(hours * 3600)
        let cuts = [now] + edges.filter { $0 > now && $0 < horizon } + [horizon]
        var out: [Segment] = []
        for (a, b) in zip(cuts, cuts.dropFirst()) where b > a {
            let kind = stretch(at: a) ?? .open
            if let last = out.last, last.stretch == kind {
                out[out.count - 1].end = b
            } else {
                out.append(Segment(start: a, end: b, stretch: kind))
            }
        }
        return Array(out.prefix(limit))
    }
}
