import SwiftUI

/// Medication: what you take, how it works for you, and the kinds of days you have. It is your routine
/// written down so the plan can fit around it. Nothing here tells you what to take, how much or when.
struct MedicationView: View {
    @Environment(AppModel.self) private var model
    @Environment(Store.self) private var store
    @Environment(Customisation.self) private var custom
    @AppStorage("healthConsent") private var consent = false
    @State private var editingMedication: Medication?
    @State private var editingDayType: DayType?
    @State private var upgrade = false
    @State private var pitch = false
    @State private var showActionSetup = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Medication").eyebrow()
                    HeroText(text: "Your medication, your rhythm", size: 32)
                    Text("Nothing here tells you what to take. It’s your routine, written down, so your day can fit around it.")
                        .font(.subheadline).foregroundStyle(Color.inkSoft)
                }

                if !consent { consentCard }

                Group {
                    todayCard
                    medicationsSection
                    dayTypesSection
                    if model.actionButtonSuggested { actionButtonCard }
                    Label("Your prescriber decides your medication. This page only helps your day fit around it.", systemImage: "stethoscope")
                        .font(.caption).foregroundStyle(Color.inkSoft)
                }
                .disabled(!consent)
                .opacity(consent ? 1 : 0.4)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .background { SkyBackground(phase: model.skyPhase) }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .sheet(item: $editingMedication) { med in
            MedicationEditor(original: med, isNew: !model.medications.contains { $0.id == med.id }) { saved in
                model.save(saved)
                if !model.actionButtonSuggested {
                    model.actionButtonSuggested = true
                    Task { try? await Task.sleep(for: .seconds(0.6)); pitch = true }
                }
            }
        }
        .sheet(item: $editingDayType) { dayType in
            DayTypeEditor(original: dayType, isNew: !model.dayTypes.contains { $0.id == dayType.id })
        }
        .sheet(isPresented: $upgrade) {
            TrialOfferView(context: .upgrade(reason: Copy.line(.dayTypesLimit))) { upgrade = false }
                .background { SkyBackground(phase: model.skyPhase) }
                .presentationDetents([.large])
        }
        .sheet(isPresented: $pitch) {
            ActionButtonPitch { pitch = false; showActionSetup = true }
                .presentationDetents([.medium])
        }
        .navigationDestination(isPresented: $showActionSetup) { ActionButtonSetupView() }
    }

    // MARK: Consent

    private var consentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("One thing first").eyebrow()
            Text("Your medication details are health information. Focus keeps them on this iPhone, encrypted, and never shares or sells them. Is it OK to store them?")
                .font(.subheadline).foregroundStyle(Color.ink)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 10) {
                Button("Yes, store them") { Haptics.shared.play(.acknowledge); consent = true }
                    .buttonStyle(.glassProminent).foregroundStyle(.onAccent)
                NavigationLink("Privacy") { PrivacyDetailView() }
                    .buttonStyle(.glass)
            }
            .font(.subheadline)
        }
        .veil(padding: 18)
    }

    // MARK: Today

    private var todayCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Today").eyebrow()
                    Text(model.todayDayType?.name ?? "No day type yet").headingFont(.title2).foregroundStyle(Color.ink)
                }
                Spacer()
                Menu {
                    ForEach(model.dayTypes) { dayType in
                        Button(dayType.name, systemImage: dayType.symbol) { Haptics.shared.play(.choose); model.chooseToday(dayType) }
                    }
                    Divider()
                    Button("Use the usual for today", systemImage: "arrow.uturn.backward") { model.chooseToday(nil) }
                } label: {
                    Text("Change").font(.subheadline)
                }
                .buttonStyle(.glass)
            }
            if let schedule = model.todaySchedule, let dayType = model.todayDayType {
                DayTimeline(schedule: schedule, doses: dots(for: dayType), now: ClockMinutes.minute(of: model.now))
                Text(scheduleSentence(schedule)).font(.footnote).foregroundStyle(Color.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .veil(padding: 18)
    }

    // MARK: Medications

    private var medicationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What you take").eyebrow()
            ForEach(model.medications) { med in
                Button { Haptics.shared.play(.tap); editingMedication = med } label: { MedicationRow(medication: med) }
                    .buttonStyle(.plain)
            }
            if model.medications.isEmpty {
                Text(Copy.line(.medsNone)).font(.subheadline).foregroundStyle(Color.inkSoft)
            }
            Button("Add a medication", systemImage: "plus") {
                Haptics.shared.play(.tap)
                editingMedication = Medication(name: "", strength: "", kind: .longActing, tint: model.medications.count)
            }
            .buttonStyle(.glass)
            .font(.subheadline)
        }
    }

    // MARK: Day types

    private var dayTypesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Kinds of days").eyebrow()
            Text(Copy.line(.dayTypesIntro)).font(.subheadline).foregroundStyle(Color.inkSoft)
            ForEach(model.dayTypes) { dayType in
                Button { Haptics.shared.play(.tap); editingDayType = dayType } label: {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            Image(systemName: dayType.symbol).foregroundStyle(Color.zoneBest)
                            Text(dayType.name).headingFont(.title3).foregroundStyle(Color.ink)
                            Spacer()
                            if dayType.id == model.todayDayType?.id {
                                Text("Today").font(.caption2.weight(.semibold)).foregroundStyle(Color.ink)
                                    .padding(.horizontal, 8).padding(.vertical, 3)
                                    .background(Capsule().fill(Color.zoneBest.opacity(0.25)))
                            }
                        }
                        DayTimeline(schedule: dayType.schedule(model.medicationsByID), doses: dots(for: dayType), compact: true)
                        Text(appliesText(dayType)).font(.caption).foregroundStyle(Color.inkSoft)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .veil(padding: 16)
                }
                .buttonStyle(.plain)
            }
            HStack(spacing: 10) {
                Button("Add a kind of day", systemImage: "plus") {
                    if store.canAddDayType(existing: model.dayTypes.count) {
                        Haptics.shared.play(.tap)
                        editingDayType = DayType(name: "")
                    } else {
                        Haptics.shared.play(.caution)
                        upgrade = true
                    }
                }
                .buttonStyle(.glass)
                if !store.isPlus {
                    Text("\(model.dayTypes.count) of \(Store.freeDayTypes) on the free plan").font(.caption).foregroundStyle(Color.inkSoft)
                }
            }
            .font(.subheadline)
        }
    }

    private var actionButtonCard: some View {
        Button { showActionSetup = true } label: {
            HStack(spacing: 14) {
                Image(systemName: "button.vertical.left.press").font(.title2).foregroundStyle(Color.zoneBest)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Log with one press").headingFont(.title3).foregroundStyle(Color.ink)
                    Text("Set your Action button to log your medication.").font(.caption).foregroundStyle(Color.inkSoft)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Color.inkSoft)
            }
            .veil(padding: 16)
        }
        .buttonStyle(.plain)
    }

    // MARK: Helpers

    private func dots(for dayType: DayType) -> [(minute: Int, color: Color, symbol: String)] {
        let meds = model.medicationsByID
        return dayType.sortedDoses.compactMap { slot in meds[slot.medicationID].map { (slot.minute, $0.color, $0.kind.symbol) } }
    }

    private func appliesText(_ dayType: DayType) -> String {
        let when = dayType.appliesWhen
        var parts: [String] = []
        switch when.weekdays {
        case []: break
        case [2, 3, 4, 5, 6]: parts.append("Weekdays")
        case [1, 7]: parts.append("Weekends")
        case Set(1...7): parts.append("Every day")
        default:
            let symbols = Calendar.current.shortWeekdaySymbols
            // Monday first reads more naturally than Sunday first.
            let ordered = when.weekdays.sorted { ($0 + 5) % 7 < ($1 + 5) % 7 }
            parts.append(ordered.map { symbols[$0 - 1] }.joined(separator: ", "))
        }
        if let from = when.from, let to = when.to {
            parts.append("\(from.formatted(.dateTime.day().month())) to \(to.formatted(.dateTime.day().month()))")
        }
        let doses = dayType.doses.count
        parts.append(doses == 0 ? "no medication" : "\(doses) dose\(doses == 1 ? "" : "s")")
        let text = parts.joined(separator: ", ")
        return text.prefix(1).uppercased() + text.dropFirst()
    }

    private func scheduleSentence(_ s: DaySchedule) -> String {
        var parts: [String] = []
        if s.windows.isEmpty { parts.append("No productive window today, so the plan follows your routine.") }
        else {
            parts.append("Productive " + s.windows.map { "\(ClockMinutes.text($0.start)) to \(ClockMinutes.text($0.end))" }.joined(separator: ", then ") + ".")
        }
        if !s.gaps.isEmpty { parts.append("Low focus " + s.gaps.map { "\(ClockMinutes.text($0.start)) to \(ClockMinutes.text($0.end))" }.joined(separator: " and ") + ".") }
        if s.focusEndsFor == .windDown, let w = s.windDownAt { parts.append("Focus wraps up before your wind-down at \(ClockMinutes.text(w)).") }
        if let sleep = s.sleepReadyAt { parts.append("Sleep usually possible from \(ClockMinutes.text(sleep)).") }
        return parts.joined(separator: " ")
    }
}

/// One medication as a row: its colour, name (or kind, in discreet mode) and its timing in words.
struct MedicationRow: View {
    let medication: Medication
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(medication.color.opacity(0.2)).frame(width: 38, height: 38)
                Image(systemName: medication.kind.symbol).foregroundStyle(medication.color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(medication.shownName(discreet: model.discreetMode && medication.name.isEmpty)).font(.body).foregroundStyle(Color.ink)
                Text(summary).font(.caption).foregroundStyle(Color.inkSoft).fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(Color.inkSoft)
        }
        .veil(padding: 14)
    }

    private var summary: String {
        if medication.kind == .windDown { return "\(medication.kind.label). Evening focus wraps up before you take it." }
        let learned = medication.learns ? " Fine-tuned by your check-ins." : ""
        return "\(medication.kind.label). Working well after \(ClockMinutes.duration(medication.kicksInMinutes)), helps for about \(ClockMinutes.duration(medication.lastsMinutes)). Sleep usually \(ClockMinutes.duration(medication.sleepAfterMinutes)) after.\(learned)"
    }
}

// MARK: - Medication editor

struct MedicationEditor: View {
    let original: Medication
    let isNew: Bool
    let onSave: (Medication) -> Void
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.motionIsCalm) private var calm
    @State private var draft: Medication
    @State private var confirmDelete = false

    init(original: Medication, isNew: Bool, onSave: @escaping (Medication) -> Void) {
        self.original = original
        self.isNew = isNew
        self.onSave = onSave
        _draft = State(initialValue: original)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(isNew ? "Add a medication" : "Medication").eyebrow()
                    HeroText(text: draft.name.isEmpty ? "What do you take?" : draft.title, size: 30)

                    VStack(spacing: 10) {
                        field("Name", text: $draft.name, prompt: "e.g. Vyvanse")
                        field("Strength", text: $draft.strength, prompt: "e.g. 50 mg")
                    }

                    kindPicker
                    colourPicker
                    CurvePreview(medication: draft).frame(height: 110).veil(padding: 14)

                    if draft.kind == .windDown {
                        sliderRow("Starts working after", value: minutes(\.kicksInMinutes), range: 0...120, step: 5)
                        Text("In a day type, evening focus wraps up before you take this, so nothing demanding lands after it.")
                            .font(.footnote).foregroundStyle(Color.inkSoft)
                    } else {
                        if draft.kind == .longActing {
                            Toggle(isOn: $draft.learns.animation(.gentle(calm))) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Fine-tune from my check-ins").font(.subheadline).foregroundStyle(Color.ink)
                                    Text(learnedLine).font(.caption).foregroundStyle(Color.inkSoft)
                                }
                            }
                            .tint(Color.zoneBest)
                            .onChange(of: draft.learns) { Haptics.shared.play(.toggle) }
                        }
                        Group {
                            sliderRow("Working well after", value: minutes(\.kicksInMinutes), range: 0...240, step: 5)
                            sliderRow("Stops helping after", value: minutes(\.lastsMinutes), range: 60...960, step: 15)
                        }
                        .disabled(draft.learns)
                        .opacity(draft.learns ? 0.45 : 1)
                        sliderRow("You can usually sleep after", value: minutes(\.sleepAfterMinutes), range: 60...1200, step: 15)
                    }

                    Text("These are your own experience, written down. They don’t change what you take or when.")
                        .font(.caption).foregroundStyle(Color.inkSoft)

                    if !isNew {
                        Button("Remove this medication", systemImage: "trash", role: .destructive) { confirmDelete = true }
                            .buttonStyle(.glass).font(.subheadline)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.immediately)
            .background { SkyBackground(phase: model.skyPhase) }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel", systemImage: "xmark") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", systemImage: "checkmark") {
                        Haptics.shared.play(.success)
                        onSave(draft)
                        dismiss()
                    }
                    .disabled(draft.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog("Remove \(draft.title)?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Remove", role: .destructive) { model.delete(original); dismiss() }
            } message: {
                Text("It comes off your list and out of your day types. Doses you’ve already logged stay in your history.")
            }
        }
    }

    private var learnedLine: String {
        let w = model.learnedWindow
        return "Your check-ins so far: working well after about \(ClockMinutes.duration(w.onset + 45)), helping for about \(ClockMinutes.duration(w.offset))."
    }

    private func minutes(_ path: WritableKeyPath<Medication, Int>) -> Binding<Double> {
        Binding(get: { Double(draft[keyPath: path]) }, set: { draft[keyPath: path] = Int($0) })
    }

    private func field(_ label: String, text: Binding<String>, prompt: String) -> some View {
        HStack(spacing: 12) {
            Text(label).eyebrow().frame(width: 72, alignment: .leading)
            TextField(prompt, text: text).font(.body).foregroundStyle(Color.ink)
        }
        .padding(.horizontal, 20)
        .frame(minHeight: 52)
        .pill()
    }

    private var kindPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What it’s for").eyebrow()
            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(MedKind.allCases) { kind in
                        Button {
                            Haptics.shared.play(.choose)
                            withAnimation(.gentle(calm, .snappy)) {
                                let wasDefault = draft.kicksInMinutes == draft.kind.defaults.kicksIn && draft.lastsMinutes == draft.kind.defaults.lasts
                                draft.kind = kind
                                if wasDefault || isNew {
                                    draft.kicksInMinutes = kind.defaults.kicksIn
                                    draft.lastsMinutes = kind.defaults.lasts
                                    draft.sleepAfterMinutes = kind.defaults.sleepAfter
                                }
                                if kind != .longActing { draft.learns = false }
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: kind.symbol)
                                Text(kind.label).font(.caption2).lineLimit(1).minimumScaleFactor(0.7)
                            }
                            .foregroundStyle(draft.kind == kind ? AnyShapeStyle(.onAccent) : AnyShapeStyle(Color.ink))
                            .frame(maxWidth: .infinity, minHeight: 52)
                        }
                        .buttonStyle(.plain)
                        .glassEffect(draft.kind == kind ? .regular.tint(Color.zoneBest).interactive() : .regular.interactive(), in: .rect(cornerRadius: 18))
                    }
                }
            }
            Text(draft.kind.explainer).font(.caption).foregroundStyle(Color.inkSoft)
        }
    }

    private var colourPicker: some View {
        HStack(spacing: 12) {
            Text("Colour").eyebrow()
            ForEach(Medication.tints.indices, id: \.self) { i in
                Circle().fill(Medication.tints[i]).frame(width: 24, height: 24)
                    .overlay(Circle().strokeBorder(Color.ink, lineWidth: draft.tint == i ? 2 : 0).padding(-3))
                    .onTapGesture { Haptics.shared.play(.choose); draft.tint = i }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityLabel("Colour \(i + 1)")
            }
        }
    }

    private func sliderRow(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.subheadline).foregroundStyle(Color.ink)
                Spacer()
                Text(ClockMinutes.duration(Int(value.wrappedValue))).figureFont(17).foregroundStyle(Color.ink)
            }
            GlassSlider(value: value, range: range, step: step, tint: draft.color) { ClockMinutes.duration(Int($0)) }
                .accessibilityLabel(title)
        }
    }
}

/// How one medication feels across the day, from the numbers above: rises to "working well", holds,
/// falls to "stopped helping", then a moon where sleep becomes possible.
struct CurvePreview: View {
    let medication: Medication

    var body: some View {
        Canvas { context, size in
            let hours = 16.0
            let x = { (m: Int) in CGFloat(Double(m) / 60 / hours) * size.width }
            let top: CGFloat = 16, base = size.height - 18
            var axis = Path()
            axis.move(to: CGPoint(x: 0, y: base)); axis.addLine(to: CGPoint(x: size.width, y: base))
            context.stroke(axis, with: .color(Color.track), lineWidth: 1)
            if medication.kind != .windDown {
                let k = x(medication.kicksInMinutes), l = x(max(medication.lastsMinutes, medication.kicksInMinutes + 30))
                let fall = min(size.width, l + size.width * 0.06)
                var curve = Path()
                curve.move(to: CGPoint(x: 0, y: base))
                curve.addCurve(to: CGPoint(x: k, y: top), control1: CGPoint(x: k * 0.5, y: base), control2: CGPoint(x: k * 0.6, y: top))
                curve.addLine(to: CGPoint(x: l, y: top))
                curve.addCurve(to: CGPoint(x: fall, y: base), control1: CGPoint(x: l + (fall - l) * 0.5, y: top), control2: CGPoint(x: l + (fall - l) * 0.4, y: base))
                var fill = curve
                fill.closeSubpath()
                context.fill(fill, with: .linearGradient(Gradient(colors: [medication.color.opacity(0.35), medication.color.opacity(0.05)]),
                                                         startPoint: CGPoint(x: 0, y: top), endPoint: CGPoint(x: 0, y: base)))
                context.stroke(curve, with: .color(medication.color), lineWidth: 1.5)
                let s = x(medication.sleepAfterMinutes)
                if s < size.width {
                    var dash = Path(); dash.move(to: CGPoint(x: s, y: top)); dash.addLine(to: CGPoint(x: s, y: base))
                    context.stroke(dash, with: .color(Color.slate.opacity(0.7)), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    context.draw(Image(systemName: "moon.zzz"), at: CGPoint(x: s, y: top - 8))
                }
            } else {
                let k = x(medication.kicksInMinutes)
                context.draw(Image(systemName: "moon.stars"), at: CGPoint(x: max(10, k), y: base - 16))
            }
            for h in stride(from: 0, through: 16, by: 4) {
                context.draw(Text("\(h)h").font(.caption2).foregroundStyle(Color.inkSoft), at: CGPoint(x: min(size.width - 10, max(10, CGFloat(Double(h) / hours) * size.width)), y: size.height - 6))
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Day type editor

struct DayTypeEditor: View {
    let original: DayType
    let isNew: Bool
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.motionIsCalm) private var calm
    @State private var draft: DayType
    @State private var confirmDelete = false
    @State private var dateRange: Bool

    private let symbols = ["graduationcap", "briefcase", "sun.max", "cup.and.saucer", "moon.stars", "figure.run", "airplane", "house", "books.vertical", "leaf"]

    init(original: DayType, isNew: Bool) {
        self.original = original
        self.isNew = isNew
        _draft = State(initialValue: original)
        _dateRange = State(initialValue: original.appliesWhen.hasDateRange)
    }

    private var schedule: DaySchedule { draft.schedule(model.medicationsByID) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(isNew ? "A new kind of day" : "Kind of day").eyebrow()
                    TextField("Name it anything: Uni day, Night shift, Holidays", text: $draft.name)
                        .headingFont(.title2)
                        .foregroundStyle(Color.ink)
                    symbolRow

                    VStack(alignment: .leading, spacing: 10) {
                        DayTimeline(schedule: schedule, doses: dots)
                        Text(summary).font(.footnote).foregroundStyle(Color.inkSoft).fixedSize(horizontal: false, vertical: true)
                    }
                    .veil(padding: 16)
                    .animation(.gentle(calm, .smooth), value: schedule)

                    dosesSection
                    windowsSection
                    if schedule.windDownAt != nil { windDownSection }
                    appliesSection

                    if !isNew {
                        Button("Delete this kind of day", systemImage: "trash", role: .destructive) { confirmDelete = true }
                            .buttonStyle(.glass).font(.subheadline)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.immediately)
            .background { SkyBackground(phase: model.skyPhase) }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel", systemImage: "xmark") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", systemImage: "checkmark") {
                        if !dateRange { draft.appliesWhen.from = nil; draft.appliesWhen.to = nil }
                        Haptics.shared.play(.success)
                        model.save(draft)
                        dismiss()
                    }
                    .disabled(draft.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog("Delete \(draft.name)?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) { model.delete(original); dismiss() }
            }
        }
    }

    private var dots: [(minute: Int, color: Color, symbol: String)] {
        let meds = model.medicationsByID
        return draft.sortedDoses.compactMap { slot in meds[slot.medicationID].map { (slot.minute, $0.color, $0.kind.symbol) } }
    }

    private var summary: String {
        let s = schedule
        guard !s.windows.isEmpty else { return "No productive window: a routine day. The plan follows your usual rhythm." }
        var parts = ["Productive " + s.windows.map { "\(ClockMinutes.text($0.start)) to \(ClockMinutes.text($0.end))" }.joined(separator: ", then ") + "."]
        if !s.gaps.isEmpty { parts.append("Low focus " + s.gaps.map { "\(ClockMinutes.text($0.start)) to \(ClockMinutes.text($0.end))" }.joined(separator: " and ") + ".") }
        if let sleep = s.sleepReadyAt { parts.append("Sleep usually possible from \(ClockMinutes.text(sleep)).") }
        return parts.joined(separator: " ")
    }

    private var symbolRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(symbols, id: \.self) { symbol in
                    Image(systemName: symbol)
                        .frame(width: 40, height: 40)
                        .foregroundStyle(draft.symbol == symbol ? AnyShapeStyle(.onAccent) : AnyShapeStyle(Color.ink))
                        .glassEffect(draft.symbol == symbol ? .regular.tint(Color.zoneBest).interactive() : .regular.interactive(), in: .circle)
                        .onTapGesture { Haptics.shared.play(.choose); draft.symbol = symbol }
                        .accessibilityAddTraits(.isButton)
                }
            }
        }
    }

    private var dosesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Doses, in order").eyebrow()
            ForEach($draft.doses) { $dose in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Menu {
                            ForEach(model.medications) { med in
                                Button(med.title) { Haptics.shared.play(.choose); dose.medicationID = med.id }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Circle().fill(model.medicationsByID[dose.medicationID]?.color ?? .inkFaint).frame(width: 10, height: 10)
                                Text(model.medicationsByID[dose.medicationID]?.title ?? "Choose").font(.subheadline).foregroundStyle(Color.ink)
                                Image(systemName: "chevron.up.chevron.down").font(.caption2).foregroundStyle(Color.inkSoft)
                            }
                        }
                        Spacer()
                        Text(ClockMinutes.text(dose.minute)).figureFont(17).foregroundStyle(Color.ink)
                        Button { withAnimation(.gentle(calm)) { draft.doses.removeAll { $0.id == dose.id } }; Haptics.shared.play(.tap) } label: {
                            Image(systemName: "minus.circle").foregroundStyle(Color.inkSoft)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove this dose")
                    }
                    GlassSlider(value: Binding(get: { Double(dose.minute) }, set: { dose.minute = Int($0) }),
                                range: 240...1620, step: 5, tint: model.medicationsByID[dose.medicationID]?.color ?? .zoneBest) { ClockMinutes.text(Int($0)) }
                        .accessibilityLabel("Time for this dose")
                }
                .veil(padding: 14)
            }
            Menu {
                ForEach(model.medications) { med in
                    Button(med.title, systemImage: med.kind.symbol) {
                        Haptics.shared.play(.tap)
                        let last = draft.sortedDoses.last?.minute ?? 7 * 60
                        withAnimation(.gentle(calm)) { draft.doses.append(DoseSlot(medicationID: med.id, minute: min(1620, last + (draft.doses.isEmpty ? 0 : 180)))) }
                    }
                }
            } label: {
                Label("Add a dose", systemImage: "plus").font(.subheadline)
            }
            .buttonStyle(.glass)
            Text("Leave a day empty for a medication-free day.").font(.caption).foregroundStyle(Color.inkSoft)
        }
    }

    private var windowsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Productive windows").eyebrow()
            Toggle(isOn: Binding(get: { draft.usesOwnWindows }, set: { own in
                Haptics.shared.play(.toggle)
                withAnimation(.gentle(calm)) {
                    if own && draft.windows.isEmpty { draft.windows = draft.automaticWindows(model.medicationsByID) }
                    if own && draft.windows.isEmpty { draft.windows = [MinuteRange(start: 9 * 60, end: 13 * 60)] }
                    draft.usesOwnWindows = own
                }
            })) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Draw my own").font(.subheadline).foregroundStyle(Color.ink)
                    Text(draft.usesOwnWindows ? "Your windows win. Gaps between them are low-focus time." : "Worked out from each medication’s timing.")
                        .font(.caption).foregroundStyle(Color.inkSoft)
                }
            }
            .tint(Color.zoneBest)
            if draft.usesOwnWindows {
                ForEach(draft.windows.indices, id: \.self) { i in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("\(ClockMinutes.text(draft.windows[i].start)) to \(ClockMinutes.text(draft.windows[i].end))")
                                .figureFont(17).foregroundStyle(Color.ink)
                            Spacer()
                            if draft.windows.count > 1 {
                                Button { withAnimation(.gentle(calm)) { _ = draft.windows.remove(at: i) } } label: {
                                    Image(systemName: "minus.circle").foregroundStyle(Color.inkSoft)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Remove this window")
                            }
                        }
                        RangeSlider(lower: Binding(get: { Double(draft.windows[i].start) }, set: { draft.windows[i].start = Int($0) }),
                                    upper: Binding(get: { Double(draft.windows[i].end) }, set: { draft.windows[i].end = Int($0) }),
                                    range: 300...1560, step: 15, minimumGap: 30) { ClockMinutes.text(Int($0)) }
                    }
                    .veil(padding: 14)
                }
                Button("Add another window", systemImage: "plus") {
                    Haptics.shared.play(.tap)
                    let start = (draft.windows.map(\.end).max() ?? 9 * 60) + 60
                    withAnimation(.gentle(calm)) { draft.windows.append(MinuteRange(start: min(start, 1440), end: min(start + 180, 1560))) }
                }
                .buttonStyle(.glass).font(.subheadline)
            }
        }
    }

    private var windDownSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Wind-down").eyebrow()
            HStack {
                Text("Wrap up focus before it").font(.subheadline).foregroundStyle(Color.ink)
                Spacer()
                Text(ClockMinutes.duration(draft.windDownBufferMinutes)).figureFont(17).foregroundStyle(Color.ink)
            }
            GlassSlider(value: Binding(get: { Double(draft.windDownBufferMinutes) }, set: { draft.windDownBufferMinutes = Int($0) }),
                        range: 0...180, step: 15, tint: .zoneLight) { ClockMinutes.duration(Int($0)) }
                .accessibilityLabel("Wrap up focus before your wind-down")
            Text("Your productive window ends this long before your wind-down, so the evening can slow down properly.")
                .font(.caption).foregroundStyle(Color.inkSoft)
        }
    }

    private var appliesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Switches on by itself").eyebrow()
            HStack(spacing: 6) {
                ForEach(1...7, id: \.self) { day in
                    let on = draft.appliesWhen.weekdays.contains(day)
                    Text(Calendar.current.veryShortWeekdaySymbols[day - 1])
                        .font(.subheadline)
                        .foregroundStyle(on ? AnyShapeStyle(.onAccent) : AnyShapeStyle(Color.ink))
                        .frame(width: 38, height: 38)
                        .glassEffect(on ? .regular.tint(Color.zoneBest).interactive() : .regular.interactive(), in: .circle)
                        .onTapGesture {
                            Haptics.shared.play(.choose)
                            if on { draft.appliesWhen.weekdays.remove(day) } else { draft.appliesWhen.weekdays.insert(day) }
                        }
                        .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
                        .accessibilityLabel(Calendar.current.weekdaySymbols[day - 1])
                }
            }
            Toggle(isOn: $dateRange.animation(.gentle(calm))) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Only between dates").font(.subheadline).foregroundStyle(Color.ink)
                    Text("For school holidays, exam weeks or a trip.").font(.caption).foregroundStyle(Color.inkSoft)
                }
            }
            .tint(Color.zoneBest)
            .onChange(of: dateRange) {
                Haptics.shared.play(.toggle)
                if dateRange && draft.appliesWhen.from == nil {
                    draft.appliesWhen.from = model.now
                    draft.appliesWhen.to = Calendar.current.date(byAdding: .day, value: 14, to: model.now)
                }
            }
            if dateRange {
                DatePicker("From", selection: Binding(get: { draft.appliesWhen.from ?? model.now }, set: { draft.appliesWhen.from = $0 }), displayedComponents: .date)
                DatePicker("To", selection: Binding(get: { draft.appliesWhen.to ?? model.now }, set: { draft.appliesWhen.to = $0 }), displayedComponents: .date)
            }
            Text("If two kinds of day match, the one with the shortest date range wins. You can always switch today by hand.")
                .font(.caption).foregroundStyle(Color.inkSoft)
        }
        .font(.subheadline)
    }
}

// MARK: - Action button suggestion

/// Shown once, right after the first medication is saved. One press to log is the single biggest
/// friction cut there is, so it's offered at the moment it's most useful, not buried in Settings.
struct ActionButtonPitch: View {
    let showMe: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var press = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 14).strokeBorder(Color.ink.opacity(0.6), lineWidth: 1.5).frame(width: 52, height: 96)
                    Capsule().fill(Color.zoneBest).frame(width: 4, height: 16).offset(x: press ? -1 : -3, y: -22)
                }
                Text(Copy.line(.actionButtonPitch)).headingFont(.title3).foregroundStyle(Color.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text("Press it and everything you’ve set for about now gets logged, with the same double-dose check as the app.")
                .font(.subheadline).foregroundStyle(Color.inkSoft)
            HStack(spacing: 10) {
                Button("Show me how", systemImage: "arrow.right") { Haptics.shared.play(.tap); showMe() }
                    .buttonStyle(.glassProminent).foregroundStyle(.onAccent)
                Button("Maybe later") { dismiss() }.buttonStyle(.glass)
            }
            .font(.subheadline)
        }
        .padding(24)
        .onAppear {
            Haptics.shared.play(.nudge)
            withAnimation(.easeInOut(duration: 0.5).repeatCount(3, autoreverses: true)) { press = true }
        }
    }
}
