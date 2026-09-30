import Foundation
import FocusModel

/// Learns one person's focus window for one product from one-tap check-ins (spec §7.3–7.5).
///
/// Exact Bayesian posterior on a grid: onset 0–180 min × offset 2–16 h in 15-min steps
/// (13 × 57 = 741 cells). Each check-in is a noisy yes / partly / no with lapse rates ε0, ε1 ≈ 0.1:
///
///     P(yes at t) = ε0 + (1 − ε0 − ε1) · E(t − t_dose)
///
/// Everything is plain arithmetic that runs in well under a millisecond and can always be
/// explained in numbers — no black box.
public struct FocusWindowModel: Sendable {
    public struct StatedEstimate: Sendable, Equatable {
        /// "It starts helping after about…" (minutes from logging to noticeable effect).
        public var startsHelpingAfter: Int
        /// "…and helps for about" (minutes of useful focus).
        public var helpsFor: Int
        public init(startsHelpingAfter: Int, helpsFor: Int) {
            self.startsHelpingAfter = startsHelpingAfter
            self.helpsFor = helpsFor
        }
    }

    public static let onsetGrid: [Int] = Array(stride(from: 0, through: 180, by: 15))
    public static let offsetGrid: [Int] = Array(stride(from: 120, through: 960, by: 15))
    static let lapseYesWhenFlat = 0.1   // ε0: taps "yes" while flat
    static let lapseNoWhenFine = 0.1    // ε1: taps "no" while fine

    public let formulation: Formulation
    public let rampUp: Int
    public let rampDown: Int
    public private(set) var stated: StatedEstimate?
    public private(set) var manualOverride: (onset: Int, offset: Int)?
    /// log-posterior, row-major [onsetIndex][offsetIndex]
    private var logPosterior: [Double]
    private var checkInDays: Set<DateComponents> = []
    public private(set) var checkInCount = 0

    /// Returns nil for non-stimulants: they build over weeks and have no daily window (§6.7).
    public init?(formulation: Formulation, stated: StatedEstimate? = nil) {
        guard let ramps = formulation.ramps, let label = formulation.labelPrior else { return nil }
        self.formulation = formulation
        self.rampUp = ramps.up
        self.rampDown = ramps.down
        self.stated = stated
        let on = Self.onsetGrid, off = Self.offsetGrid
        var prior = [Double](repeating: -.infinity, count: on.count * off.count)
        // The person's own estimate beats label data (§7.1): narrower prior centred on what they said.
        let centreOnset: Double, centreOffset: Double, sdOnset: Double, sdOffset: Double
        // "Starts helping" / "stops helping" are read as the curve's 50% crossings.
        if let s = stated {
            centreOnset = Double(max(0, s.startsHelpingAfter - ramps.up / 2))
            centreOffset = Double(s.startsHelpingAfter + s.helpsFor + ramps.down / 2)
            sdOnset = 25
            sdOffset = 75
        } else {
            centreOnset = Double(label.onset)
            centreOffset = Double(label.offset)
            sdOnset = 35
            sdOffset = 110
        }
        for i in on.indices {
            for j in off.indices where Self.isValid(onset: on[i], offset: off[j], up: ramps.up, down: ramps.down) {
                let zOn = (Double(on[i]) - centreOnset) / sdOnset
                let zOff = (Double(off[j]) - centreOffset) / sdOffset
                prior[i * off.count + j] = -0.5 * (zOn * zOn + zOff * zOff)
            }
        }
        self.logPosterior = prior
        normalise()
    }

    static func isValid(onset: Int, offset: Int, up: Int, down: Int) -> Bool {
        offset - down > onset + up + 30 // at least 30 min of full effect
    }

    // MARK: Updates

    /// Adds one check-in. `minutesAfterDose` is measured from the logged dose time.
    public mutating func ingest(_ answer: CheckInAnswer, minutesAfterDose m: Double, day: DateComponents) {
        let on = Self.onsetGrid, off = Self.offsetGrid
        let e0 = Self.lapseYesWhenFlat, e1 = Self.lapseNoWhenFine
        for i in on.indices {
            for j in off.indices {
                let k = i * off.count + j
                guard logPosterior[k].isFinite else { continue }
                let effect = FocusCurve.effect(minutesAfterDose: m, onset: Double(on[i]), offset: Double(off[j]),
                                               rampUp: Double(rampUp), rampDown: Double(rampDown))
                let pYes = e0 + (1 - e0 - e1) * effect
                switch answer {
                case .yes: logPosterior[k] += log(pYes)
                case .no: logPosterior[k] += log(1 - pYes)
                case .partly: logPosterior[k] += 0.5 * log(pYes) + 0.5 * log(1 - pYes)
                }
            }
        }
        normalise()
        checkInCount += 1
        checkInDays.insert(day)
    }

    public mutating func setManualOverride(onset: Int, offset: Int) { manualOverride = (onset, offset) }
    public mutating func releaseManualOverride() { manualOverride = nil }

    // MARK: Summaries

    public struct Summary: Sendable, Equatable {
        public var onsetMedian: Int
        public var offsetMedian: Int
        public var onset80: ClosedRange<Int>
        public var offset80: ClosedRange<Int>
        public var confidence: Confidence
        /// Half-widths of the 80% intervals on the window edges, in minutes.
        public var startUncertainty: Int { (onset80.upperBound - onset80.lowerBound) / 2 }
        public var endUncertainty: Int { (offset80.upperBound - offset80.lowerBound) / 2 }
    }

    public var summary: Summary {
        let on = Self.onsetGrid, off = Self.offsetGrid
        var onsetMarginal = [Double](repeating: 0, count: on.count)
        var offsetMarginal = [Double](repeating: 0, count: off.count)
        for i in on.indices {
            for j in off.indices {
                let p = exp(logPosterior[i * off.count + j])
                onsetMarginal[i] += p
                offsetMarginal[j] += p
            }
        }
        let onQ = Self.quantiles(onsetMarginal, grid: on)
        let offQ = Self.quantiles(offsetMarginal, grid: off)
        var summary = Summary(onsetMedian: onQ.median, offsetMedian: offQ.median,
                              onset80: onQ.p10...onQ.p90, offset80: offQ.p10...offQ.p90, confidence: .starting)
        let days = checkInDays.count
        if manualOverride != nil {
            summary.confidence = .manualOverride
        } else if days >= 8 && summary.startUncertainty <= 30 && summary.endUncertainty <= 30 {
            summary.confidence = .learned(checkIns: checkInCount)
        } else if days >= 3 {
            summary.confidence = .early(days: days)
        }
        return summary
    }

    /// The window to plan with for a specific logged dose.
    public func window(forDoseAt dose: Date) -> FocusWindow {
        let s = summary
        let onset = manualOverride?.onset ?? s.onsetMedian
        let offset = manualOverride?.offset ?? s.offsetMedian
        return FocusWindow(dose: dose, onsetMinutes: onset, offsetMinutes: offset, rampUpMinutes: rampUp,
                           rampDownMinutes: rampDown, startUncertaintyMinutes: s.startUncertainty,
                           endUncertaintyMinutes: s.endUncertainty, confidence: s.confidence)
    }

    /// Posterior predictive P(yes) at a time after the dose.
    public func predictiveYes(minutesAfterDose m: Double) -> Double {
        let on = Self.onsetGrid, off = Self.offsetGrid
        let e0 = Self.lapseYesWhenFlat, e1 = Self.lapseNoWhenFine
        var total = 0.0
        for i in on.indices {
            for j in off.indices {
                let p = exp(logPosterior[i * off.count + j])
                guard p > 1e-12 else { continue }
                let e = FocusCurve.effect(minutesAfterDose: m, onset: Double(on[i]), offset: Double(off[j]),
                                          rampUp: Double(rampUp), rampDown: Double(rampDown))
                total += p * (e0 + (1 - e0 - e1) * e)
            }
        }
        return total
    }

    /// Where the next check-in teaches the model most: the time whose predicted answer is the
    /// most uncertain (closest to 50/50), at least `gap` minutes after the last prompt (§7.4).
    public func nextCheckInMinute(after minute: Int, gap: Int = 45) -> Int? {
        var best: (minute: Int, distance: Double)?
        for m in stride(from: minute + gap, through: 960, by: 15) {
            let d = abs(predictiveYes(minutesAfterDose: Double(m)) - 0.5)
            if best == nil || d < best!.distance { best = (m, d) }
        }
        return best?.minute
    }

    /// "You said about 7 hours; your check-ins suggest about 5½. Use 5½ for planning?" (§7.5)
    /// Only raised once the data is at least an early estimate and the gap is 60+ minutes.
    public var proposal: (statedMinutes: Int, learnedMinutes: Int)? {
        guard let stated, manualOverride == nil else { return nil }
        let s = summary
        guard case .starting = s.confidence else {
            let learned = (s.offsetMedian - rampDown / 2) - (s.onsetMedian + rampUp / 2)
            let statedDuration = stated.helpsFor
            return abs(learned - statedDuration) >= 60 ? (statedDuration, learned) : nil
        }
        return nil
    }

    // MARK: Private

    private mutating func normalise() {
        let maxLog = logPosterior.filter(\.isFinite).max() ?? 0
        var sum = 0.0
        for k in logPosterior.indices where logPosterior[k].isFinite { sum += exp(logPosterior[k] - maxLog) }
        let logZ = maxLog + log(sum)
        for k in logPosterior.indices where logPosterior[k].isFinite { logPosterior[k] -= logZ }
    }

    private static func quantiles(_ weights: [Double], grid: [Int]) -> (p10: Int, median: Int, p90: Int) {
        let total = weights.reduce(0, +)
        var acc = 0.0
        var p10 = grid.first!, median = grid.first!, p90 = grid.last!
        var found10 = false, found50 = false, found90 = false
        for (k, w) in weights.enumerated() {
            acc += w / total
            if !found10 && acc >= 0.1 { p10 = grid[k]; found10 = true }
            if !found50 && acc >= 0.5 { median = grid[k]; found50 = true }
            if !found90 && acc >= 0.9 { p90 = grid[k]; found90 = true }
        }
        return (p10, median, p90)
    }
}
