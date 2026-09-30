import Foundation
import SwiftUI
import FoundationModels
import FocusModel

/// Hours after the first dose of the day, e.g. 3 to 6 means "from three hours after I take my
/// first dose until six hours after".
struct HourRange: Codable, Hashable {
    var from: Double
    var to: Double

    func interval(after anchor: Date) -> DateInterval {
        DateInterval(start: anchor.addingTimeInterval(from * 3600), end: anchor.addingTimeInterval(max(from, to) * 3600))
    }

    var text: String {
        func h(_ v: Double) -> String {
            let whole = Int(v), half = v - Double(whole) >= 0.5
            return half ? "\(whole)½" : "\(whole)"
        }
        return "\(h(from)) to \(h(to)) h after your first dose"
    }
}

/// A kind of activity the person names themselves ("Deep study", "Admin", "Making music"), with
/// when they like doing it. Tasks are sorted into categories on the phone by Apple's on-device model.
struct ActivityCategory: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var symbol: String
    var tint: Int
    var window: HourRange
    /// Words that point at this category when the on-device model isn't available.
    var keywords: [String]

    var color: Color { Medication.tints[tint % Medication.tints.count] }
}

struct Personalisation: Codable, Equatable {
    var categories: [ActivityCategory]
    var eating = HourRange(from: 4.5, to: 6)
    var social = HourRange(from: 7, to: 12)
    var alone = HourRange(from: 0, to: 3)
    var socialSuggestions = true
    var dismissedSuggestions: Set<String> = []
    /// Task id → category id, filled in by the on-device classifier (or by hand).
    var taskCategories: [String: UUID] = [:]

    static let starter = Personalisation(categories: [
        ActivityCategory(name: "Deep study", symbol: "books.vertical", tint: 0, window: HourRange(from: 1, to: 5),
                         keywords: ["essay", "reading", "study", "write", "assignment", "research", "case"]),
        ActivityCategory(name: "Admin", symbol: "tray", tint: 4, window: HourRange(from: 5.5, to: 7.5),
                         keywords: ["email", "admin", "forms", "bills", "plan tomorrow", "reply"]),
        ActivityCategory(name: "Prep", symbol: "list.clipboard", tint: 2, window: HourRange(from: 5, to: 8),
                         keywords: ["prep", "prepare", "revise", "notes", "tutorial"]),
        ActivityCategory(name: "Movement", symbol: "figure.run", tint: 3, window: HourRange(from: 9, to: 11),
                         keywords: ["gym", "run", "walk", "yoga", "swim", "training"]),
        ActivityCategory(name: "Home stuff", symbol: "house", tint: 5, window: HourRange(from: 8, to: 10),
                         keywords: ["clean", "laundry", "groceries", "dishes", "tidy", "cook"]),
    ])

    static let key = "personalisation"
    static func load() -> Personalisation {
        guard let data = UserDefaults.standard.data(forKey: key),
              let saved = try? JSONDecoder().decode(Personalisation.self, from: data) else { return .starter }
        return saved
    }
    func save() {
        if let data = try? JSONEncoder().encode(self) { UserDefaults.standard.set(data, forKey: Self.key) }
    }

    func category(for task: TaskSnapshot) -> ActivityCategory? {
        guard let id = taskCategories[task.id.raw] else { return nil }
        return categories.first { $0.id == id }
    }
}

// MARK: - On-device reading of tasks and plans

/// Sorts tasks into the person's categories and reads calendar events for "is this with other people?"
/// using Apple's on-device model. Nothing leaves the phone. When the model isn't available it falls
/// back to the category's own keywords and simple phrases ("coffee with", "dinner").
enum OnDeviceReader {
    @Generable
    nonisolated struct CategoryPick {
        @Guide(description: "The number of the category that fits best, or 0 if none fits.")
        var choice: Int
    }

    @Generable
    nonisolated struct EventRead {
        @Guide(description: "True if this plan involves meeting or talking with other people.")
        var withOtherPeople: Bool
        @Guide(description: "The first name of the other person if the title gives one, otherwise an empty string.")
        var personName: String
    }

    static var modelAvailable: Bool { SystemLanguageModel.default.isAvailable }

    static func category(for title: String, among categories: [ActivityCategory]) async -> UUID? {
        if modelAvailable {
            let list = categories.enumerated().map { "\($0.offset + 1). \($0.element.name)" }.joined(separator: "\n")
            let session = LanguageModelSession(instructions: "You sort someone's tasks into their own categories. Answer with a number only.")
            if let pick = try? await session.respond(to: "Categories:\n\(list)\nTask: \(title)", generating: CategoryPick.self,
                                                     options: GenerationOptions(temperature: 0)).content.choice,
               categories.indices.contains(pick - 1) {
                return categories[pick - 1].id
            }
        }
        let lower = title.lowercased()
        return categories.first { $0.keywords.contains { lower.contains($0) } }?.id
    }

    static func read(event title: String, attendees: Int) async -> (social: Bool, person: String?) {
        if attendees > 1 { return (true, nil) }
        if modelAvailable {
            let session = LanguageModelSession(instructions: "You read calendar event titles. Never guess private details.")
            if let r = try? await session.respond(to: "Event title: \(title)", generating: EventRead.self,
                                                  options: GenerationOptions(temperature: 0)).content {
                return (r.withOtherPeople, r.personName.isEmpty ? nil : r.personName)
            }
        }
        let lower = title.lowercased()
        let social = [" with ", "coffee", "dinner", "drinks", "catch up", "catch-up", "party", "brunch", "date", "hang", "call w"]
            .contains { lower.contains($0) }
        var person: String?
        if let range = lower.range(of: " with ") {
            person = title[range.upperBound...].split(separator: " ").first.map(String.init)
        }
        return (social, person)
    }
}

/// "Coffee with Maya is at 10:00, right in your focus time. Ask to move it to 3:30?"
struct SocialSuggestion: Identifiable, Equatable {
    let id: String
    let eventTitle: String
    let person: String?
    let current: DateInterval
    let proposed: Date
    let why: String
}
