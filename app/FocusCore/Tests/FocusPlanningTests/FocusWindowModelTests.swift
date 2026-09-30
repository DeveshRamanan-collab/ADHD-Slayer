import Foundation
import Testing
import FocusModel
@testable import FocusPlanning

/// Deterministic RNG so learning tests are reproducible.
struct SplitMix64: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

@Suite("Focus window model — grid posterior (spec §7.3–7.5)")
struct FocusWindowModelTests {
    @Test func nonStimulantsHaveNoDailyWindow() {
        #expect(FocusWindowModel(formulation: .nonStimulant) == nil)
    }

    @Test func startsAsAStartingEstimateCentredOnWhatThePersonSaid() throws {
        let model = try #require(FocusWindowModel(formulation: .lisdexamfetamine,
                                                  stated: .init(startsHelpingAfter: 45, helpsFor: 420)))
        let s = model.summary
        #expect(s.confidence == .starting)
        // Stated 45 min to "starts helping" (50% crossing) → onset ≈ 45 − 45/2.
        #expect(abs(s.onsetMedian - 22) <= 15)
    }

    /// Simulates a person whose real window differs from their own estimate and from the label,
    /// answering 4 prompts a day for 10 days with 10% lapses and 20% missed prompts (§7.4).
    @Test func learnsAPersonalWindowWithinThirtyMinutesInTenDays() throws {
        var rng = SplitMix64(seed: 42)
        let trueOnset = 30.0, trueOffset = 360.0 // effect ends 6 h after logging — much shorter than the label
        var model = try #require(FocusWindowModel(formulation: .lisdexamfetamine,
                                                  stated: .init(startsHelpingAfter: 45, helpsFor: 420)))
        let calendar = Calendar(identifier: .gregorian)
        for day in 0..<10 {
            var last = 0
            for _ in 0..<4 {
                let minute = model.nextCheckInMinute(after: last, gap: 45) ?? 120
                last = minute
                if Double.random(in: 0..<1, using: &rng) < 0.2 { continue } // unanswered
                let e = FocusCurve.effect(minutesAfterDose: Double(minute), onset: trueOnset, offset: trueOffset,
                                          rampUp: Double(model.rampUp), rampDown: Double(model.rampDown))
                let pYes = 0.1 + 0.8 * e
                let answer: CheckInAnswer = Double.random(in: 0..<1, using: &rng) < pYes ? .yes : .no
                model.ingest(answer, minutesAfterDose: Double(minute), day: DateComponents(calendar: calendar, year: 2026, month: 10, day: day + 1))
            }
        }
        let s = model.summary
        #expect(s.offset80.contains(Int(trueOffset)) || abs(s.offsetMedian - Int(trueOffset)) <= 30,
                "offset \(s.offsetMedian) 80% \(s.offset80) should cover truth \(trueOffset)")
        #expect(abs(s.offsetMedian - Int(trueOffset)) <= 30)
        #expect(s.endUncertainty <= 45)
        // With a stated 7 h and a real ~5 h, the app should propose updating — never silently switch.
        let proposal = try #require(model.proposal)
        #expect(proposal.statedMinutes == 420)
        #expect(proposal.learnedMinutes < 360)
    }

    @Test func nextCheckInTargetsTheUncertainEdges() throws {
        let model = try #require(FocusWindowModel(formulation: .lisdexamfetamine))
        let minute = try #require(model.nextCheckInMinute(after: 0, gap: 45))
        let p = model.predictiveYes(minutesAfterDose: Double(minute))
        #expect(p > 0.2 && p < 0.8, "chosen minute \(minute) has predictive yes \(p)")
    }

    @Test func manualOverrideWinsUntilReleased() throws {
        var model = try #require(FocusWindowModel(formulation: .lisdexamfetamine))
        model.setManualOverride(onset: 30, offset: 420)
        let dose = Date(timeIntervalSince1970: 1_792_000_000)
        let w = model.window(forDoseAt: dose)
        #expect(w.confidence == .manualOverride)
        #expect(w.end == dose.addingTimeInterval(420 * 60))
        model.releaseManualOverride()
        #expect(model.summary.confidence == .starting)
    }
}
