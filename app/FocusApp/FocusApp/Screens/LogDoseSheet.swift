import SwiftUI
import FocusModel
import FocusMedication

/// Log a dose: which medication, the time, three glass answers for when, one Log. Optional detail
/// stays folded until asked for. Neutral words only: the app records what you log and never says
/// whether to take a dose.
struct LogDoseSheet: View {
    var initial: Medication?
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.motionIsCalm) private var calm
    @Environment(\.accentChoice) private var accent
    @Environment(\.colorScheme) private var scheme
    @Namespace private var glass
    @State private var medication: Medication?

    enum When: String, CaseIterable, Identifiable { case now, twentyMinutesAgo, earlier; var id: Self { self } }
    enum Stage: Equatable { case form, alreadyLogged(DoseEvent), failed(String) }

    @State private var when: When = .now
    @State private var earlierTime = Date()
    @State private var ateFirst: Bool?
    @State private var showDetail = false
    @State private var stage: Stage = .form

    private var takenAt: Date {
        switch when {
        case .now: model.now
        case .twentyMinutesAgo: model.now.addingTimeInterval(-20 * 60)
        case .earlier: earlierTime
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    switch stage {
                    case .form: form
                    case .alreadyLogged(let previous): guardView(previous)
                    case .failed(let message):
                        Text("Not saved").eyebrow()
                        HeroText(text: message, size: 24)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background { SkyBackground(phase: model.skyPhase) }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") { dismiss() }
                }
            }
        }
        .onAppear {
            earlierTime = model.now.addingTimeInterval(-3600)
            if medication == nil { medication = initial ?? model.dueDoses.first?.medication ?? model.medications.first }
        }
        .presentationDetents([.large])
    }

    // MARK: Form

    @ViewBuilder
    private var form: some View {
        if model.medications.isEmpty {
            Text("Medication").eyebrow()
            HeroText(text: Copy.line(.medsNone), size: 26)
            Button("Add medication", systemImage: "plus") { dismiss(); model.route = .medication }
                .buttonStyle(.glassProminent).foregroundStyle(.onAccent).font(.subheadline).padding(.top, 12)
        } else {
            logForm
        }
    }

    @ViewBuilder
    private var logForm: some View {
        if model.medications.count > 1 {
            ScrollView(.horizontal) {
                GlassEffectContainer(spacing: 8) {
                    HStack(spacing: 8) {
                        ForEach(model.medications) { med in
                            let picked = medication?.id == med.id
                            Button {
                                Haptics.shared.play(.choose)
                                withAnimation(.gentle(calm, .bouncy)) { medication = med }
                            } label: {
                                HStack(spacing: 6) {
                                    Circle().fill(med.color).frame(width: 7, height: 7)
                                    Text(med.shownName(discreet: false)).font(.subheadline)
                                }
                                .foregroundStyle(picked ? accent.on(scheme) : Color.ink)
                                .padding(.horizontal, 14)
                                .frame(minHeight: 36)
                            }
                            .buttonStyle(.plain)
                            .glassEffect(picked ? .regular.tint(accent.fill(scheme)).interactive() : .regular.interactive(), in: .capsule)
                            .glassEffectID("med-\(med.id)", in: glass)
                            .accessibilityAddTraits(picked ? .isSelected : [])
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .padding(.bottom, 10)
        }
        Text(medication?.shownName(discreet: false) ?? "Medication").eyebrow()
        HeroText(text: takenAt.formatted(date: .omitted, time: .shortened), size: 40)
            .contentTransition(.numericText())
            .animation(.gentle(calm, .smooth), value: takenAt)

        Text("When did you take it?")
            .font(.subheadline)
            .foregroundStyle(Color.inkSoft)
            .padding(.top, 24)

        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(When.allCases) { option in
                    Button {
                        Haptics.shared.play(.choose)
                        withAnimation(.gentle(calm, .bouncy)) { when = option }
                    } label: {
                        Text(label(option))
                            .font(.subheadline)
                            .foregroundStyle(when == option ? accent.on(scheme) : Color.ink)
                            .padding(.horizontal, 14)
                            .frame(minHeight: 38)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(when == option ? .regular.tint(accent.fill(scheme)).interactive() : .regular.interactive(), in: .capsule)
                    .glassEffectID(option.rawValue, in: glass)
                    .accessibilityAddTraits(when == option ? .isSelected : [])
                }
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)

        if when == .earlier {
            DatePicker("Time taken", selection: $earlierTime, in: ...model.now, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: 260)
                .transition(.opacity)
        }

        DisclosureGroup(isExpanded: $showDetail.animation(.gentle(calm))) {
            VStack(alignment: .leading, spacing: 10) {
                Picker("Ate something first?", selection: $ateFirst) {
                    Text("Yes").tag(Bool?.some(true))
                    Text("No").tag(Bool?.some(false))
                    Text("Skip").tag(Bool?.none)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 260)
                Text("Food can shift when your focus starts. It’s only used to plan your day.")
                    .font(.footnote).foregroundStyle(Color.inkSoft)
            }
            .padding(.top, 10)
        } label: {
            Text("Ate something first?").font(.subheadline).foregroundStyle(Color.ink)
        }
        .tint(Color.inkSoft)
        .padding(.top, 12)

        Button("Log at \(takenAt.formatted(date: .omitted, time: .shortened))", systemImage: "checkmark") {
            Task { await log() }
        }
        .buttonStyle(.glassProminent)
        .foregroundStyle(.onAccent)
        .disabled(medication == nil)
        .font(.subheadline)
        .padding(.top, 20)

        Text("Not medical advice. Follow your prescription and check with your doctor or pharmacist.")
            .font(.caption)
            .foregroundStyle(Color.inkSoft)
            .padding(.top, 4)
    }

    private func label(_ option: When) -> LocalizedStringKey {
        switch option {
        case .now: "Just now"
        case .twentyMinutesAgo: "20 min ago"
        case .earlier: "Earlier…"
        }
    }

    // MARK: Guard

    @ViewBuilder
    private func guardView(_ previous: DoseEvent) -> some View {
        let time = previous.takenAt.formatted(date: .omitted, time: .shortened)
        let ago = Duration.seconds(model.now.timeIntervalSince(previous.takenAt)).formatted(.units(allowed: [.hours, .minutes], width: .narrow))
        Text("Already logged").eyebrow()
        HeroText(text: time, size: 40)
        Text("\(ago) ago, from your \(previous.source == .watch ? "Watch" : "iPhone"). Logging again adds a second dose to today’s record.")
            .font(.subheadline)
            .foregroundStyle(Color.inkSoft)

        Button("Keep one log") { dismiss() }
            .buttonStyle(.glassProminent)
            .foregroundStyle(.onAccent)
            .font(.subheadline)
            .padding(.top, 20)

        HoldToConfirmButton(title: "Hold to log another", systemImage: "plus") {
            Task {
                guard let medication else { return }
                let result = await model.confirmSecondDose(medication, takenAt: takenAt, previous: previous,
                                                           gesture: UserGesture(origin: .button, at: model.now))
                finish(result)
            }
        }

        Text("Focus records what you log. It never tells you whether to take a dose. That’s one for your prescriber or pharmacist.")
            .font(.caption)
            .foregroundStyle(Color.inkSoft)
            .padding(.top, 8)
    }

    // MARK: Actions

    private func log() async {
        guard let medication else { return }
        let result = await model.logDose(medication, takenAt: takenAt, ateFirst: ateFirst, gesture: UserGesture(origin: .button, at: model.now))
        finish(result)
    }

    private func finish(_ result: AppModel.LogResult) {
        switch result {
        case .logged:
            dismiss()
        case .alreadyLogged(let previous):
            withAnimation(.gentle(calm, .snappy)) { stage = .alreadyLogged(previous) }
        case .failed(let message):
            stage = .failed(message)
        }
    }
}

/// Deliberate confirm for a second log: press and hold for 1.2 s. The phone answers with a
/// vibration that swells under your thumb, so the hold feels like pressing into something.
/// VoiceOver users get the same action as a named accessibility action.
struct HoldToConfirmButton: View {
    let title: LocalizedStringKey
    let systemImage: String
    let action: () -> Void

    private let duration = 1.2
    @State private var pressing = false
    @Environment(\.motionIsCalm) private var calm
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline)
            .foregroundStyle(Color.ink)
            .padding(.horizontal, 18)
            .frame(minHeight: 44)
            .background {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(reduceTransparency ? Color.veilSolid : Color.veil)
                        Capsule().fill(Color.honey.opacity(0.35))
                            .frame(width: pressing ? geo.size.width : 0)
                            .animation(pressing ? .linear(duration: duration) : .gentle(calm, .easeOut(duration: 0.25)), value: pressing)
                    }
                }
            }
            .overlay(Capsule().strokeBorder(Color.veilStroke, lineWidth: 0.5))
            .contentShape(.capsule)
            .onLongPressGesture(minimumDuration: duration, maximumDistance: 40) {
                Haptics.shared.endHoldRamp()
                action()
            } onPressingChanged: { isPressing in
                pressing = isPressing
                if isPressing { Haptics.shared.beginHoldRamp(seconds: duration) } else { Haptics.shared.endHoldRamp() }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Log another dose")
            .accessibilityHint("Adds a second dose to today’s record")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { action() }
    }
}
