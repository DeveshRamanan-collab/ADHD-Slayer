import SwiftUI

/// When you like doing things, counted from your first dose of the day: the kinds of work you name
/// yourself, eating, being around people, and time on your own. The plan leans that way; social
/// plans that land at awkward times get a gentle suggestion you can switch off.
struct PersonaliseView: View {
    @Environment(AppModel.self) private var model
    @Environment(Store.self) private var store
    @Environment(\.motionIsCalm) private var calm
    @State private var upgrade = false
    @State private var editing: ActivityCategory?

    var body: some View {
        @Bindable var model = model
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Personalise").eyebrow()
                    HeroText(text: "Your timing", size: 32)
                    Text(Copy.line(.personaliseIntro)).font(.subheadline).foregroundStyle(Color.inkSoft)
                }

                RhythmChart(personalisation: model.personalisation, anchor: model.doseAnchor)
                    .veil(padding: 16)

                categories

                Text("Your day").eyebrow()
                windowCard(title: "Eating", symbol: "fork.knife", tint: .honey, range: $model.personalisation.eating,
                           note: "Meals get planned in here, even if you’re not hungry.")
                windowCard(title: "Being around people", symbol: "person.2", tint: .zoneWarm, range: $model.personalisation.social,
                           note: "Catch-ups, calls and plans with friends fit best here.")
                windowCard(title: "Time on your own", symbol: "moon", tint: .slate, range: $model.personalisation.alone,
                           note: "Social suggestions steer clear of this.")

                socialSection
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .background { SkyBackground(phase: model.skyPhase) }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .sheet(isPresented: $upgrade) {
            TrialOfferView(context: .upgrade(reason: Copy.line(.categoriesLimit))) { upgrade = false }
                .background { SkyBackground(phase: model.skyPhase) }
        }
        .sheet(item: $editing) { category in CategoryEditor(original: category) }
    }

    private var categories: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your categories").eyebrow()
            ForEach(model.personalisation.categories) { category in
                Button { Haptics.shared.play(.tap); editing = category } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle().fill(category.color.opacity(0.2)).frame(width: 36, height: 36)
                            Image(systemName: category.symbol).foregroundStyle(category.color)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(category.name).font(.body).foregroundStyle(Color.ink)
                            Text(timeText(category.window)).font(.caption).foregroundStyle(Color.inkSoft)
                        }
                        Spacer()
                        Text("\(model.tasks.filter { model.personalisation.taskCategories[$0.id.raw] == category.id }.count)")
                            .figureFont(17).foregroundStyle(Color.inkSoft)
                            .accessibilityLabel("tasks in this category")
                    }
                    .veil(padding: 14)
                }
                .buttonStyle(.plain)
            }
            HStack(spacing: 10) {
                Button("Add a category", systemImage: "plus") {
                    if store.canAddCategory(existing: model.personalisation.categories.count) {
                        Haptics.shared.play(.tap)
                        editing = ActivityCategory(name: "", symbol: "sparkles", tint: model.personalisation.categories.count,
                                                   window: HourRange(from: 2, to: 5), keywords: [])
                    } else {
                        Haptics.shared.play(.caution)
                        upgrade = true
                    }
                }
                .buttonStyle(.glass)
                if !store.isPlus {
                    Text("\(model.personalisation.categories.count) of \(Store.freeCategories) on the free plan").font(.caption).foregroundStyle(Color.inkSoft)
                }
            }
            .font(.subheadline)
            Text("Your iPhone sorts tasks into these on its own, using Apple Intelligence on the phone.")
                .font(.caption).foregroundStyle(Color.inkSoft)
        }
    }

    private func windowCard(title: String, symbol: String, tint: Color, range: Binding<HourRange>, note: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: symbol).foregroundStyle(tint)
                Text(title).font(.subheadline).foregroundStyle(Color.ink)
                Spacer()
                Text(hoursText(range.wrappedValue)).figureFont(15).foregroundStyle(Color.ink)
            }
            RangeSlider(lower: range.from, upper: range.to, range: 0...16, step: 0.25, minimumGap: 0.5, tint: tint) { hourLabel($0) }
                .accessibilityLabel(title)
            Text(clockText(range.wrappedValue).map { "\(note) Today that’s \($0)." } ?? note)
                .font(.caption).foregroundStyle(Color.inkSoft)
        }
        .veil(padding: 16)
    }

    private var socialSection: some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: 12) {
            Text("Plans with people").eyebrow()
            Toggle(isOn: $model.personalisation.socialSuggestions) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Suggest better times").font(.subheadline).foregroundStyle(Color.ink)
                    Text(Copy.line(.socialIntro)).font(.caption).foregroundStyle(Color.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .tint(Color.zoneBest)
            .onChange(of: model.personalisation.socialSuggestions) {
                Haptics.shared.play(.toggle)
                Task { await model.refreshSocial() }
            }
            if model.personalisation.socialSuggestions {
                if model.calendarAccess != .fullAccess {
                    Button("Let Focus read your calendar", systemImage: "calendar") {
                        Task { await model.requestCalendarAccess() }
                    }
                    .buttonStyle(.glass).font(.subheadline)
                    Text("Only to spot plans with people. Nothing is changed, and your calendar never leaves the phone.")
                        .font(.caption).foregroundStyle(Color.inkSoft)
                }
                ForEach(model.socialSuggestions) { suggestion in SocialSuggestionCard(suggestion: suggestion) }
                if model.socialSuggestions.isEmpty {
                    Text("Nothing to suggest today. Your plans with people all land at good times.")
                        .font(.caption).foregroundStyle(Color.inkSoft)
                }
            }
        }
    }

    // Formatting

    private func hourLabel(_ h: Double) -> String {
        let whole = Int(h), minutes = Int(((h - Double(whole)) * 60).rounded())
        return minutes == 0 ? "\(whole) h" : "\(whole) h \(minutes)"
    }

    private func hoursText(_ r: HourRange) -> String { "\(hourLabel(r.from)) to \(hourLabel(r.to))" }

    private func clockText(_ r: HourRange) -> String? {
        guard let anchor = model.doseAnchor else { return nil }
        let i = r.interval(after: anchor)
        return "\(i.start.formatted(.compactTime)) to \(i.end.formatted(.compactTime))"
    }

    private func timeText(_ r: HourRange) -> String {
        hoursText(r) + " after your first dose" + (clockText(r).map { ", \($0) today" } ?? "")
    }
}

/// Every category and window on one axis of "hours after your first dose", with today's clock times
/// underneath: the whole rhythm in one glance.
struct RhythmChart: View {
    let personalisation: Personalisation
    let anchor: Date?

    private var rows: [(String, Color, HourRange)] {
        personalisation.categories.map { ($0.name, $0.color, $0.window) } + [
            ("Eating", .honey, personalisation.eating),
            ("People", .zoneWarm, personalisation.social),
            ("On your own", .slate, personalisation.alone),
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hours after your first dose").eyebrow()
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 10) {
                    Text(row.0).font(.caption).foregroundStyle(Color.ink).frame(width: 84, alignment: .leading).lineLimit(1)
                    GeometryReader { geo in
                        let w = geo.size.width
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.track).frame(height: 8)
                            Capsule().fill(row.1.opacity(0.85))
                                .frame(width: max(6, CGFloat((row.2.to - row.2.from) / 16) * w), height: 8)
                                .offset(x: CGFloat(row.2.from / 16) * w)
                        }
                        .frame(height: geo.size.height)
                    }
                    .frame(height: 14)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(row.0): \(Int(row.2.from)) to \(Int(row.2.to)) hours after your first dose")
            }
            HStack(spacing: 0) {
                Color.clear.frame(width: 94)
                ForEach([0, 4, 8, 12, 16], id: \.self) { h in
                    if h > 0 { Spacer(minLength: 0) }
                    VStack(spacing: 0) {
                        Text("\(h)h").font(.caption2.monospacedDigit()).foregroundStyle(Color.inkSoft)
                        if let anchor {
                            Text(anchor.addingTimeInterval(Double(h) * 3600).formatted(.compactTime))
                                .font(.system(size: 9).monospacedDigit()).foregroundStyle(Color.inkFaint)
                        }
                    }
                }
            }
        }
    }
}

/// "Coffee with Maya is at 10:30, in your focus time. Ask to move it to 3:30?" The draft message opens
/// in the share sheet for the person to edit and send themselves. Nothing is ever sent for them.
struct SocialSuggestionCard: View {
    let suggestion: SocialSuggestion
    @Environment(AppModel.self) private var model

    private var message: String {
        Copy.line(.socialMessage, ["name": suggestion.person ?? "there",
                                   "event": shortEvent,
                                   "time": suggestion.proposed.formatted(date: .omitted, time: .shortened)])
    }

    private var shortEvent: String {
        let lower = suggestion.eventTitle.lowercased()
        if let r = lower.range(of: " with ") { return String(lower[..<r.lowerBound]) }
        return lower
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(suggestion.eventTitle).headingFont(.title3).foregroundStyle(Color.ink)
            Text("\(suggestion.current.start.formatted(date: .omitted, time: .shortened)) now. \(suggestion.why) How about \(suggestion.proposed.formatted(date: .omitted, time: .shortened))?")
                .font(.subheadline).foregroundStyle(Color.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            Text("“\(message)”").font(.footnote).italic().foregroundStyle(Color.ink)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 10) {
                ShareLink(item: message) { Label("Send it", systemImage: "paperplane") }
                    .buttonStyle(.glassProminent).foregroundStyle(.onAccent)
                    .simultaneousGesture(TapGesture().onEnded { Haptics.shared.play(.tap) })
                Button("Leave it") { Haptics.shared.play(.tap); model.dismissSuggestion(suggestion) }
                    .buttonStyle(.glass)
            }
            .font(.subheadline)
        }
        .veil(tint: .zoneWarm, padding: 16)
    }
}

/// Name, icon, colour and when you like doing it.
struct CategoryEditor: View {
    let original: ActivityCategory
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var draft: ActivityCategory
    private let symbols = ["books.vertical", "tray", "list.clipboard", "figure.run", "house", "paintbrush", "music.note", "laptopcomputer", "cart", "sparkles", "phone", "leaf"]

    init(original: ActivityCategory) {
        self.original = original
        _draft = State(initialValue: original)
    }

    private var isNew: Bool { !model.personalisation.categories.contains { $0.id == original.id } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(isNew ? "New category" : "Category").eyebrow()
                    TextField("Deep study, Admin, Making music", text: $draft.name).headingFont(.title2).foregroundStyle(Color.ink)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                        ForEach(symbols, id: \.self) { symbol in
                            Image(systemName: symbol)
                                .frame(width: 40, height: 40)
                                .foregroundStyle(draft.symbol == symbol ? AnyShapeStyle(.onAccent) : AnyShapeStyle(Color.ink))
                                .glassEffect(draft.symbol == symbol ? .regular.tint(draft.color).interactive() : .regular.interactive(), in: .circle)
                                .onTapGesture { Haptics.shared.play(.choose); draft.symbol = symbol }
                        }
                    }
                    HStack(spacing: 12) {
                        ForEach(Medication.tints.indices, id: \.self) { i in
                            Circle().fill(Medication.tints[i]).frame(width: 24, height: 24)
                                .overlay(Circle().strokeBorder(Color.ink, lineWidth: draft.tint == i ? 2 : 0).padding(-3))
                                .onTapGesture { Haptics.shared.play(.choose); draft.tint = i }
                        }
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("When you like doing it").eyebrow()
                        RangeSlider(lower: $draft.window.from, upper: $draft.window.to, range: 0...16, step: 0.25, minimumGap: 0.5, tint: draft.color) {
                            let whole = Int($0), m = Int((($0 - Double(whole)) * 60).rounded())
                            return m == 0 ? "\(whole) h" : "\(whole) h \(m)"
                        }
                        Text(draft.window.text).font(.caption).foregroundStyle(Color.inkSoft)
                    }
                    .veil(padding: 16)
                    if !isNew {
                        Button("Delete this category", systemImage: "trash", role: .destructive) {
                            model.personalisation.categories.removeAll { $0.id == original.id }
                            dismiss()
                        }
                        .buttonStyle(.glass).font(.subheadline)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .background { SkyBackground(phase: model.skyPhase) }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel", systemImage: "xmark") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", systemImage: "checkmark") {
                        Haptics.shared.play(.success)
                        if let i = model.personalisation.categories.firstIndex(where: { $0.id == draft.id }) {
                            model.personalisation.categories[i] = draft
                        } else {
                            model.personalisation.categories.append(draft)
                        }
                        dismiss()
                    }
                    .disabled(draft.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
