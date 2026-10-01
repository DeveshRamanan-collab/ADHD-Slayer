import Foundation
import SwiftUI
import Observation

// MARK: - Pages and tabs

enum TabKind: String, Codable, CaseIterable, Identifiable {
    case today, plan, rhythm, you
    var id: Self { self }

    var defaultName: String {
        switch self {
        case .today: "Today"
        case .plan: "Plan"
        case .rhythm: "Rhythm"
        case .you: "You"
        }
    }

    var symbol: String {
        switch self {
        case .today: "sun.horizon"
        case .plan: "calendar"
        case .rhythm: "waveform.path"
        case .you: "person.crop.circle"
        }
    }

    /// Today and You always stay; Plan and Rhythm can be hidden.
    var canHide: Bool { self == .plan || self == .rhythm }
}

/// Every page the app can show, where it lives, and whether it can be hidden. The Now page, the first
/// You page and the fiddly-bits page stay no matter what, so medication, today's plan and Settings are
/// never lost.
enum PageKind: String, Codable, CaseIterable, Identifiable {
    case fiveThings, now, focusWindow, restOfToday, shapes, ifChanges, tinyWins, breathe
    case planDay, planRiver, planDetails, planWeek
    case rhythmIntro, planDone, brainWeather, finishHours, windowPattern, estimates, sleep, logTimes, tune
    case youHome, youSupport, youMore

    var id: Self { self }

    var tab: TabKind {
        switch self {
        case .fiveThings, .now, .focusWindow, .restOfToday, .shapes, .ifChanges, .tinyWins, .breathe: .today
        case .planDay, .planRiver, .planDetails, .planWeek: .plan
        case .rhythmIntro, .planDone, .brainWeather, .finishHours, .windowPattern, .estimates, .sleep, .logTimes, .tune: .rhythm
        case .youHome, .youSupport, .youMore: .you
        }
    }

    var title: String {
        switch self {
        case .fiveThings: "Today, in five"
        case .now: "Now"
        case .focusWindow: "Your focus window"
        case .restOfToday: "Rest of today"
        case .shapes: "Today in shapes"
        case .ifChanges: "If today changes"
        case .tinyWins: "Tiny wins"
        case .breathe: "One minute of breathing"
        case .planDay: "The day"
        case .planRiver: "The shape of the day"
        case .planDetails: "Waiting for you"
        case .planWeek: "This week"
        case .rhythmIntro: "Four weeks of you"
        case .planDone: "Planned and done"
        case .brainWeather: "Brain weather"
        case .finishHours: "When things get done"
        case .windowPattern: "Your focus window, learned"
        case .estimates: "How long things take"
        case .sleep: "Sleep and done"
        case .logTimes: "When you log"
        case .tune: "Your patterns, your call"
        case .youHome: "You"
        case .youSupport: "Support"
        case .youMore: "The fiddly bits"
        }
    }

    var symbol: String {
        switch self {
        case .fiveThings: "list.number"
        case .now: "circle.circle"
        case .focusWindow: "sun.max"
        case .restOfToday: "list.bullet"
        case .shapes: "chart.pie"
        case .ifChanges: "wand.and.sparkles"
        case .tinyWins: "checkmark.seal"
        case .breathe: "wind"
        case .planDay: "calendar"
        case .planRiver: "timeline.selection"
        case .planDetails: "tray.full"
        case .planWeek: "circle.grid.cross"
        case .rhythmIntro: "waveform.path"
        case .planDone: "chart.bar"
        case .brainWeather: "cloud.sun"
        case .finishHours: "square.grid.3x3"
        case .windowPattern: "chart.line.uptrend.xyaxis"
        case .estimates: "timer"
        case .sleep: "moon"
        case .logTimes: "clock"
        case .tune: "slider.horizontal.3"
        case .youHome: "person.crop.circle"
        case .youSupport: "heart"
        case .youMore: "ellipsis.circle"
        }
    }

    /// Now, the first You page and the fiddly-bits page (where Settings lives) can move but never leave.
    var locked: Bool { self == .now || self == .youHome || self == .youMore }
    /// Extras start switched off; people add them from the page gallery.
    var isExtra: Bool { self == .tinyWins || self == .breathe }

    static func defaults(for tab: TabKind) -> [PageKind] {
        allCases.filter { $0.tab == tab }
    }
}

// MARK: - Look, voice and feel

enum Appearance: String, Codable, CaseIterable, Identifiable {
    case dark, light, system
    var id: Self { self }
    var label: String { switch self { case .dark: "Dark"; case .light: "Light"; case .system: "Match iPhone" } }
    var scheme: ColorScheme? { switch self { case .dark: .dark; case .light: .light; case .system: nil } }
}

enum Backdrop: String, Codable, CaseIterable, Identifiable {
    case facade, baroque, plain
    var id: Self { self }
    var label: String { switch self { case .facade: "Dusk façade"; case .baroque: "Baroque interior"; case .plain: "Plain" } }
}

enum AccentChoice: String, Codable, CaseIterable, Identifiable {
    case espresso, champagne, rose, sage, slate
    var id: Self { self }
    var label: String { rawValue.capitalized }

    /// Button colour and the text that sits on it, per appearance. Every pair clears 4.5:1.
    nonisolated func fill(_ scheme: ColorScheme) -> Color {
        switch (self, scheme) {
        case (.espresso, .dark): Color(hex: "E9E1D4")
        case (.espresso, _): Color(hex: "2A231F")
        case (.champagne, .dark): Color(hex: "D8BC88")
        case (.champagne, _): Color(hex: "6B5128")
        case (.rose, .dark): Color(hex: "D9A497")
        case (.rose, _): Color(hex: "7E4338")
        case (.sage, .dark): Color(hex: "A9BBA0")
        case (.sage, _): Color(hex: "43533D")
        case (.slate, .dark): Color(hex: "A6B4C6")
        case (.slate, _): Color(hex: "3A4A5E")
        }
    }

    nonisolated func on(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "1B1714") : Color(hex: "F8F4EE")
    }
}

enum Typeface: String, Codable, CaseIterable, Identifiable {
    case serif, sans, rounded
    var id: Self { self }
    var label: String { switch self { case .serif: "Serif"; case .sans: "Sans"; case .rounded: "Rounded" } }
    var design: Font.Design { switch self { case .serif: .serif; case .sans: .default; case .rounded: .rounded } }
}

enum Humour: String, Codable, CaseIterable, Identifiable {
    case straight, little, lots
    var id: Self { self }
    var label: String { switch self { case .straight: "Straight"; case .little: "A little"; case .lots: "Lots" } }
}

enum DotStyle: String, Codable, CaseIterable, Identifiable {
    case dots, numbers, hidden
    var id: Self { self }
    var label: String { switch self { case .dots: "Dots"; case .numbers: "Numbers"; case .hidden: "Hidden" } }
}

enum TextSizeChoice: String, Codable, CaseIterable, Identifiable {
    case matchPhone, smaller, bigger, biggest
    var id: Self { self }
    var label: String { switch self { case .matchPhone: "Match iPhone"; case .smaller: "Smaller"; case .bigger: "Bigger"; case .biggest: "Biggest" } }
    var size: DynamicTypeSize? { switch self { case .matchPhone: nil; case .smaller: .small; case .bigger: .xLarge; case .biggest: .xxxLarge } }
}

enum RingStyle: String, Codable, CaseIterable, Identifiable {
    case ring, bar, number
    var id: Self { self }
    var label: String { switch self { case .ring: "Ring"; case .bar: "Bar"; case .number: "Just the number" } }
}

enum AccessoryContent: String, Codable, CaseIterable, Identifiable {
    case doses, nextThing
    var id: Self { self }
    var label: String { switch self { case .doses: "Medication"; case .nextThing: "What’s next" } }
}

/// Everything on the Customise page. Stored as one small JSON blob on the phone (and in the
/// encrypted sync bundle), versioned so new options can be added without losing old choices.
struct CustomSettings: Codable, Equatable {
    var version = 1
    // Pages and tabs
    var pages: [TabKind: [PageKind]] = Dictionary(uniqueKeysWithValues: TabKind.allCases.map { ($0, PageKind.defaults(for: $0).filter { !$0.isExtra }) })
    var tabOrder: [TabKind] = [.today, .plan, .rhythm, .you]
    var hiddenTabs: Set<TabKind> = []
    var tabNames: [TabKind: String] = [:]
    // Look
    var appearance: Appearance = .dark
    var darkBackdrop: Backdrop = .facade
    var lightBackdrop: Backdrop = .baroque
    var darkness: Double = 0.5      // how much the dark backdrop is dimmed, 0...0.8 (half as bright by default)
    var blur: Double = 0            // extra blur on top of the frosted plate, 0...30
    var frost: Double = 0           // 0 = the plate as made, 1 = a heavier mist
    var grain: Double = 0.5
    var accent: AccentChoice = .espresso
    var typeface: Typeface = .serif
    var textSize: TextSizeChoice = .matchPhone
    var roundness: Double = 1       // 0.5...1.4 times the standard corner radius
    var dots: DotStyle = .dots
    // Voice
    var humour: Humour = .little
    var dailyVariety = true
    var nickname = ""
    // Feel
    var celebrateLogging = true
    var sliderTicks = true
    var hapticStrength: Double = 1  // 0.3...1.3
    // Home
    var priorityCount = 5
    var showPrioritySource = true
    // Focus mode and the bottom bar
    var ringStyle: RingStyle = .ring
    var showFirstStep = true
    var accessory: AccessoryContent = .doses

    init() {}

    /// Starts from today's defaults and takes whatever the saved copy has, key by key, so adding an
    /// option in an update never wipes the choices someone already made.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func take<T: Decodable>(_ key: CodingKeys, _ value: inout T) {
            if let saved = try? c.decodeIfPresent(T.self, forKey: key) { value = saved }
        }
        take(.version, &version); take(.pages, &pages); take(.tabOrder, &tabOrder); take(.hiddenTabs, &hiddenTabs)
        take(.tabNames, &tabNames); take(.appearance, &appearance); take(.darkBackdrop, &darkBackdrop)
        take(.lightBackdrop, &lightBackdrop); take(.darkness, &darkness); take(.blur, &blur); take(.frost, &frost)
        take(.grain, &grain); take(.accent, &accent); take(.typeface, &typeface); take(.textSize, &textSize)
        take(.roundness, &roundness); take(.dots, &dots); take(.humour, &humour); take(.dailyVariety, &dailyVariety)
        take(.nickname, &nickname); take(.celebrateLogging, &celebrateLogging); take(.sliderTicks, &sliderTicks)
        take(.hapticStrength, &hapticStrength); take(.priorityCount, &priorityCount)
        take(.showPrioritySource, &showPrioritySource); take(.ringStyle, &ringStyle); take(.showFirstStep, &showFirstStep)
        take(.accessory, &accessory)
        // Pages saved by an older build may be missing ones that are now required.
        for tab in TabKind.allCases {
            let required = PageKind.defaults(for: tab).filter(\.locked)
            var list = pages[tab] ?? PageKind.defaults(for: tab).filter { !$0.isExtra }
            for page in required where !list.contains(page) { list.append(page) }
            pages[tab] = list
        }
    }

    private enum CodingKeys: String, CodingKey {
        case version, pages, tabOrder, hiddenTabs, tabNames, appearance, darkBackdrop, lightBackdrop, darkness, blur, frost
        case grain, accent, typeface, textSize, roundness, dots, humour, dailyVariety, nickname, celebrateLogging
        case sliderTicks, hapticStrength, priorityCount, showPrioritySource, ringStyle, showFirstStep, accessory
    }

    func name(for tab: TabKind) -> String {
        let custom = tabNames[tab]?.trimmingCharacters(in: .whitespaces) ?? ""
        return custom.isEmpty ? tab.defaultName : custom
    }

    func visiblePages(_ tab: TabKind) -> [PageKind] {
        let list = pages[tab] ?? PageKind.defaults(for: tab)
        return list.isEmpty ? PageKind.defaults(for: tab).filter(\.locked) : list
    }

    var visibleTabs: [TabKind] { tabOrder.filter { !hiddenTabs.contains($0) } }
}

@MainActor @Observable
final class Customisation {
    var settings: CustomSettings {
        didSet {
            guard settings != oldValue else { return }
            save()
            UserDefaults.standard.set(settings.hapticStrength, forKey: "hapticStrength")
            UserDefaults.standard.set(settings.sliderTicks, forKey: "sliderTicks")
            UserDefaults.standard.set(settings.celebrateLogging, forKey: "celebrateLogging")
        }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: "customSettings"),
           let saved = try? JSONDecoder().decode(CustomSettings.self, from: data) {
            settings = saved
        } else {
            settings = CustomSettings()
        }
    }

    func reset() { settings = CustomSettings() }

    private func save() {
        if let data = try? JSONEncoder().encode(settings) { UserDefaults.standard.set(data, forKey: "customSettings") }
    }

    // Page editing

    func move(_ tab: TabKind, from source: IndexSet, to destination: Int) {
        var list = settings.visiblePages(tab)
        list.move(fromOffsets: source, toOffset: destination)
        settings.pages[tab] = list
    }

    func remove(_ page: PageKind) {
        guard !page.locked else { return }
        settings.pages[page.tab] = settings.visiblePages(page.tab).filter { $0 != page }
    }

    func add(_ page: PageKind) {
        var list = settings.visiblePages(page.tab)
        guard !list.contains(page) else { return }
        list.append(page)
        settings.pages[page.tab] = list
    }

    func hiddenPages(_ tab: TabKind) -> [PageKind] {
        PageKind.defaults(for: tab).filter { !settings.visiblePages(tab).contains($0) }
    }
}

// MARK: - Environment

private nonisolated struct TypefaceKey: EnvironmentKey { static let defaultValue: Typeface = .serif }
private nonisolated struct AccentKey: EnvironmentKey { static let defaultValue: AccentChoice = .espresso }
private nonisolated struct RoundnessKey: EnvironmentKey { static let defaultValue: Double = 1 }

extension EnvironmentValues {
    nonisolated var typeface: Typeface {
        get { self[TypefaceKey.self] }
        set { self[TypefaceKey.self] = newValue }
    }
    nonisolated var accentChoice: AccentChoice {
        get { self[AccentKey.self] }
        set { self[AccentKey.self] = newValue }
    }
    nonisolated var roundness: Double {
        get { self[RoundnessKey.self] }
        set { self[RoundnessKey.self] = newValue }
    }
}

/// Text or symbols that sit on a prominent (accent-filled) button.
nonisolated struct OnAccentStyle: ShapeStyle {
    func resolve(in environment: EnvironmentValues) -> Color {
        environment.accentChoice.on(environment.colorScheme)
    }
}

/// The accent fill itself.
nonisolated struct AccentFillStyle: ShapeStyle {
    func resolve(in environment: EnvironmentValues) -> Color {
        environment.accentChoice.fill(environment.colorScheme)
    }
}

extension ShapeStyle where Self == OnAccentStyle {
    static var onAccent: OnAccentStyle { OnAccentStyle() }
}

extension ShapeStyle where Self == AccentFillStyle {
    static var accentFill: AccentFillStyle { AccentFillStyle() }
}

