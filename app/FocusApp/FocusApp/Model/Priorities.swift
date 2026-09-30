import Foundation
import Observation
import FoundationModels
import FocusModel

/// Today's five most important things, in the shortest sentences possible.
///
/// Apple Intelligence (the on-device Foundation Models framework) reads a numbered summary of what's
/// left of today's plan, picks the five that matter most and words each as a short action ("Draft
/// the essay"). The app then adds the exact time itself, so times are never invented. Every answer is
/// checked item by item — length, plain words, no mention of medication — and anything that fails is
/// replaced by the plan's own wording. When the model isn't available the list is ranked from the plan.
/// No medicine names, doses or health data are ever put in the prompt, and nothing leaves the phone.
@MainActor @Observable
final class PriorityWriter {
    enum Source: Equatable { case plan, appleIntelligence }

    private(set) var lines: [String] = []
    private(set) var source: Source = .plan
    private var lastKey: String?

    func refresh(from model: AppModel) async {
        let facts = PriorityFacts(model)
        guard facts.key != lastKey else { return }
        lastKey = facts.key
        if lines.isEmpty || source == .plan { lines = facts.planLines }

        guard SystemLanguageModel.default.isAvailable else { use(facts.planLines, .plan); return }
        do {
            let session = LanguageModelSession(instructions: Self.instructions)
            let response = try await session.respond(to: facts.prompt, generating: DayPriorities.self,
                                                     options: GenerationOptions(temperature: 0.2, maximumResponseTokens: 200))
            guard facts.key == lastKey else { return }
            if let written = facts.compose(response.content) { use(written, .appleIntelligence) } else { use(facts.planLines, .plan) }
        } catch {
            guard facts.key == lastKey else { return }
            use(facts.planLines, .plan)
        }
    }

    private func use(_ lines: [String], _ source: Source) {
        self.lines = lines
        self.source = source
    }

    static let instructions = """
    You help someone with ADHD see what matters most today.
    You get today's remaining items, numbered. Choose the five that matter most, most important first:
    1. whatever is happening now,
    2. items marked essential,
    3. fixed appointments,
    4. deep work during best focus,
    5. eating and looking after the body.
    Then write a short action for every item. Plain and calm. Never mention medication, doses, pills or health.
    """
}

/// The model's answer: which five items, in what order, and a short action for every item.
@Generable
nonisolated struct DayPriorities {
    @Guide(description: "The numbers of the five most important items, most important first. Use each number once.", .count(5))
    var ranking: [Int]
    @Guide(description: "For every item in the list, in the list's order: a short action of two to five words that starts with a verb, like 'Draft the essay' or 'Eat lunch'. No times, no numbers.", .count(6))
    var actions: [String]
}

/// A snapshot of today's plan: six candidate items, the prompt, and the plan-ranked fallback.
struct PriorityFacts {
    struct Item {
        let title: String
        let detail: String
        /// "until 10:55" for what's happening now, "at 11:05" for what's coming, nil for no time.
        let when: String?
        let fallback: String
    }

    let key: String
    let items: [Item]          // exactly six, most important first by the plan's own ranking
    let prompt: String
    var planLines: [String] { items.prefix(5).map(\.fallback) }

    init(_ model: AppModel) {
        let now = model.now
        let open = model.plan.blocks.filter { !model.isDone($0) && $0.interval.end > now }
        let essential = Set(model.tasks.filter(\.isBaseline).map(\.id))
        let time: (Date) -> String = { $0.formatted(.compactTime) }

        func score(_ b: Block) -> Double {
            var s = 0.0
            if b.interval.contains(now) { s += 100 }
            if let id = b.taskID, essential.contains(id) { s += 80 }
            if b.kind == .fixed { s += 70 }
            if b.demand == .deep { s += 60 }
            if b.demand == .body { s += 45 }
            if b.demand == .medium || b.demand == .light { s += 35 }
            return s - b.interval.start.timeIntervalSince(now) / 3600   // sooner breaks ties
        }
        /// "Tutorial · Room 4.12" → "Tutorial"; "Lunch — even if not hungry" → "Lunch".
        func short(_ title: String) -> String {
            let cut = title.components(separatedBy: " · ").first ?? title
            return (cut.components(separatedBy: " — ").first ?? cut).trimmingCharacters(in: .whitespaces)
        }
        func item(_ b: Block) -> Item {
            let nowish = b.interval.contains(now)
            var detail: [String] = []
            if b.kind == .fixed { detail.append("fixed appointment") }
            switch b.demand {
            case .deep: detail.append("deep work")
            case .medium, .light: detail.append("lighter work")
            case .body: detail.append("body")
            case nil: break
            }
            if let id = b.taskID, essential.contains(id) { detail.append("essential") }
            detail.append(nowish ? "happening now, until \(time(b.interval.end))" : time(b.interval.start))
            let when = nowish ? "until \(time(b.interval.end))" : "at \(time(b.interval.start))"
            let name = short(b.title)
            let fallback = nowish ? "Finish \(name.lowercasedFirst) by \(time(b.interval.end))." : "\(name) \(when)."
            return Item(title: b.title.replacingOccurrences(of: " · ", with: " in ").replacingOccurrences(of: " — ", with: ", "),
                        detail: detail.joined(separator: ", "), when: when, fallback: fallback)
        }

        var list = open.sorted { score($0) > score($1) }.prefix(6).map(item)
        if list.count < 6, let window = model.window, window.end > now {
            list.append(Item(title: "Rest as focus fades", detail: "looking after yourself, from \(time(window.end))",
                             when: "at \(time(window.end))", fallback: "Rest when focus fades at \(time(window.end))."))
        }
        let fillers = [Item(title: "Write tomorrow's first step", detail: "evening", when: nil, fallback: "Write tomorrow’s first step tonight."),
                       Item(title: "Drink some water", detail: "looking after yourself", when: nil, fallback: "Drink a glass of water."),
                       Item(title: "Go gently with yourself", detail: "looking after yourself", when: nil, fallback: "Go gently with yourself.")]
        for filler in fillers where list.count < 6 { list.append(filler) }
        items = list

        var lines = ["Now: \(time(now))."]
        if let window = model.window { lines.append("Best focus until \(time(window.bestFocusEnd)).") }
        if model.dayVersion == .baseline { lines.append("It's a lighter day: essentials first.") }
        for (index, item) in list.enumerated() { lines.append("\(index + 1). \(item.title): \(item.detail)") }
        prompt = lines.joined(separator: "\n")

        key = [model.dayVersion.rawValue, model.brainWeather.rawValue, String(model.doneCount),
               open.map(\.id).joined(separator: ","), String(Calendar.current.component(.hour, from: now))].joined(separator: "|")
    }

    /// Turns the model's answer into five sentences, or nil if the ranking itself isn't usable.
    /// Each action is checked on its own; a bad one falls back to the plan's wording for that item.
    func compose(_ answer: DayPriorities) -> [String]? {
        let order = answer.ranking.map { $0 - 1 }
        guard order.count == 5, Set(order).count == 5, order.allSatisfy(items.indices.contains) else { return nil }
        var usedModelWording = 0
        let sentences = order.map { index -> String in
            let item = items[index]
            guard index < answer.actions.count, let action = Self.clean(answer.actions[index]) else { return item.fallback }
            usedModelWording += 1
            return item.when.map { "\(action) \($0)." } ?? "\(action)."
        }
        return usedModelWording >= 3 ? sentences : nil
    }

    private static let banned = try! Regex("(?i)medic|dose|dosage|pill|tablet|\\bmg\\b|stimulant|prescri|vyvanse|adderall|ritalin|concerta|elvanse|dexamph|\\bai\\b")

    /// "Draft the essay" passes; anything long, numeric, bracketed or about medication does not.
    static func clean(_ raw: String) -> String? {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        guard !s.isEmpty, s.count <= 40 else { return nil }
        guard s.allSatisfy({ $0.isLetter || $0 == " " || $0 == "’" || $0 == "'" || $0 == "-" }) else { return nil }
        let words = s.split(separator: " ")
        guard (1...6).contains(words.count), s.firstMatch(of: banned) == nil else { return nil }
        s = s.prefix(1).uppercased() + s.dropFirst()
        return s
    }
}

private extension String {
    var lowercasedFirst: String { prefix(1).lowercased() + dropFirst() }
}
