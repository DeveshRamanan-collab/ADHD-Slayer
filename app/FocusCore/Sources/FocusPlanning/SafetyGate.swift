import Foundation

/// Second fence behind the type system (spec §8.4): screens every user-visible string that did
/// not come from a compiled table — AI rephrasings, parsed titles, imported text. Anything that
/// reads as dose, timing, booster or drug-effect language is replaced with a fixed referral.
public struct SafetyGate: Sendable {
    public enum Context: Sendable { case aiRephrase, parsedTitle, notificationBody }
    public enum Verdict: Sendable, Equatable {
        case allow(String)
        case replaced(with: String, matched: [String])
    }

    public static let referral = "That’s one for your prescriber or pharmacist."

    // Patterns are deliberately broad: a false positive costs a rephrase, a false negative costs trust.
    private static let patterns: [(label: String, regex: String)] = [
        ("dose action", #"\b(take|taking|took|skip|skipping|double|increase|decrease|reduce|lower|raise|up|move|delay)\b[^.]{0,30}\b(dose|doses|meds|medication|medicine|tablet|pill|capsule|booster|stimulant)s?\b"#),
        ("booster", #"\bboosters?\b"#),
        ("dose timing", #"\b(when|what time|how late|how early)\b[^.]{0,25}\b(take|dose|meds|medication|booster)\b"#),
        ("dose amount", #"\b\d+(\.\d+)?\s?(mg|milligrams?|mcg)\b"#),
        ("drug-effect words", #"\b(wear(s|ing)? off|onset|pharmacokinetic|half-?life|effectiveness|kicks? in)\b"#),
        ("device words", #"\b(predicts?|prediction)\b[^.]{0,30}\b(dose|medication|meds|window)\b"#),
        ("safety claim", #"\b(safe|unsafe|dangerous)\s+to\s+take\b"#),
        ("treatment claim", #"\b(treats?|cures?|reduces?)\s+(adhd|symptoms)\b"#),
    ]

    public init() {}

    public func screen(_ candidate: String, context: Context) -> Verdict {
        var matched: [String] = []
        for (label, pattern) in Self.patterns {
            if candidate.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil { matched.append(label) }
        }
        guard !matched.isEmpty else { return .allow(candidate) }
        switch context {
        case .parsedTitle:
            // A parsed title keeps the person's own words out of our copy; strip to a neutral label.
            return .replaced(with: "Untitled task", matched: matched)
        case .aiRephrase, .notificationBody:
            return .replaced(with: Self.referral, matched: matched)
        }
    }
}
