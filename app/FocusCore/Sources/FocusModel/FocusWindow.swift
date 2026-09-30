import Foundation

/// How much evidence sits behind a focus window. Rendered as the card's subtitle (spec §7.5).
public enum Confidence: Sendable, Equatable, Codable {
    /// Fewer than 3 check-in days: "Starting estimate from what you told us".
    case starting
    /// 3–7 days, wide interval: "Early estimate from 5 days (±50 min)".
    case early(days: Int)
    /// 8+ days and both edges within ±30 min: "Your usual focus, from 23 check-ins (±25 min)".
    case learned(checkIns: Int)
    /// The person typed their own window; it wins until they release it.
    case manualOverride
}

/// A person's usual focus window after one logged dose. Internal name "effect window";
/// user-facing copy must only ever say "focus window" / "your usual focus" (§8.2 rule 4).
public struct FocusWindow: Sendable, Equatable, Codable {
    public var dose: Date
    /// Warm-up ends and best focus begins.
    public var start: Date
    /// Best focus ends and lighter focus begins.
    public var bestFocusEnd: Date
    public var end: Date
    /// Half-width of the 80% interval on each edge, in minutes.
    public var startUncertaintyMinutes: Int
    public var endUncertaintyMinutes: Int
    public var confidence: Confidence
    /// Minutes after the dose where the template curve starts rising and finishes falling.
    public var onsetMinutes: Int
    public var offsetMinutes: Int
    public var rampUpMinutes: Int
    public var rampDownMinutes: Int

    public init(dose: Date, onsetMinutes: Int, offsetMinutes: Int, rampUpMinutes: Int, rampDownMinutes: Int,
                startUncertaintyMinutes: Int, endUncertaintyMinutes: Int, confidence: Confidence) {
        self.dose = dose
        self.onsetMinutes = onsetMinutes
        self.offsetMinutes = offsetMinutes
        self.rampUpMinutes = rampUpMinutes
        self.rampDownMinutes = rampDownMinutes
        self.start = dose.addingTimeInterval(TimeInterval((onsetMinutes + rampUpMinutes) * 60))
        self.bestFocusEnd = dose.addingTimeInterval(TimeInterval((offsetMinutes - rampDownMinutes) * 60))
        self.end = dose.addingTimeInterval(TimeInterval(offsetMinutes * 60))
        self.startUncertaintyMinutes = startUncertaintyMinutes
        self.endUncertaintyMinutes = endUncertaintyMinutes
        self.confidence = confidence
    }

    /// E(t) in 0...1 at the posterior median — the template curve used by the scheduler.
    public func effect(at t: Date) -> Double {
        FocusCurve.effect(minutesAfterDose: t.timeIntervalSince(dose) / 60,
                          onset: Double(onsetMinutes), offset: Double(offsetMinutes),
                          rampUp: Double(rampUpMinutes), rampDown: Double(rampDownMinutes))
    }

    public enum Zone: String, Sendable { case before, warmUp, bestFocus, lighterFocus, after }

    public func zone(at t: Date) -> Zone {
        if t < dose { return .before }
        if t < start { return .warmUp }
        if t < bestFocusEnd { return .bestFocus }
        if t < end { return .lighterFocus }
        return .after
    }
}

/// The explainable template curve (spec §7.3): 0 until onset, linear ramp to 1, plateau,
/// linear ramp back to 0 at offset.
public enum FocusCurve {
    public static func effect(minutesAfterDose m: Double, onset: Double, offset: Double,
                              rampUp: Double, rampDown: Double) -> Double {
        guard m > onset, m < offset else { return 0 }
        let rising = (m - onset) / max(rampUp, 1)
        let falling = (offset - m) / max(rampDown, 1)
        return min(1, rising, falling)
    }
}
