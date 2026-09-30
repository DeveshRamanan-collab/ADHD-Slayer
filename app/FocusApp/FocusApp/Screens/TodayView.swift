import SwiftUI
import FocusModel
import FocusPlanning
import FocusMedication

/// Today, one page at a time. The pages and their order come from Customise; the home page (five
/// priorities and today's medication) comes first unless someone moves it. Flick up for the next page.
struct TodayView: View {
    @Environment(AppModel.self) private var model
    @Environment(Customisation.self) private var custom
    @Environment(\.motionIsCalm) private var calm
    @AppStorage("coachDone") private var coachDone = false
    @AppStorage("welcomed") private var welcomed = false
    @State private var chapter: Int? = 0
    @State private var bandDrawn = false
    @State private var shapesShown = false
    @State private var showAllRest = false
    @State private var fixPreview: PlanResult?
    @State private var focusMode = false
    @State private var priorities = PriorityWriter()
    @State private var coachStep: Int?
    @State private var toast: String?
    @State private var social: SocialSuggestion?
    @Namespace private var zoom

    var body: some View {
        let pages = custom.settings.visiblePages(.today)
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 30)) { _ in
                let now = model.now
                PagedScreen(count: pages.count, page: $chapter) {
                    brainWeatherMenu
                } pages: {
                    ForEach(Array(pages.enumerated()), id: \.element) { index, page in
                        Chapter(id: index) { content(for: page, now: now) }
                    }
                }
            }
            .task(id: PriorityFacts(model).key) { await priorities.refresh(from: model) }
            .fullScreenCover(isPresented: $focusMode) {
                FocusModeView()
                    .navigationTransition(.zoom(sourceID: "now", in: zoom))
            }
            .sheet(item: $fixPreview) { FixMyDaySheet(result: $0) }
            .sheet(item: $social) { suggestion in
                SocialSuggestionCard(suggestion: suggestion)
                    .padding(24)
                    .presentationDetents([.medium])
            }
            .modifier(CoachTour(step: $coachStep) { model.route = .medication })
            .onChange(of: coachStep) { old, new in if old != nil && new == nil { coachDone = true } }
            .toast($toast)
            .task {
                guard !welcomed else { return }
                welcomed = true
                try? await Task.sleep(for: .seconds(0.9))
                toast = Copy.line(.welcomeHome)
                guard !coachDone else { return }
                try? await Task.sleep(for: .seconds(1.6))
                withAnimation(.gentle(calm)) { coachStep = 0 }
            }
        }
    }

    @ViewBuilder
    private func content(for page: PageKind, now: Date) -> some View {
        switch page {
        case .fiveThings: homeChapter
        case .now: nowChapter(now)
        case .focusWindow: windowChapter(now)
        case .restOfToday: restChapter
        case .shapes: shapesChapter
        case .ifChanges: changeChapter
        case .tinyWins: tinyWinsChapter
        case .breathe: BreathePage()
        default: EmptyView()
        }
    }

    // MARK: Home: today, in five, and today's medication

    @ViewBuilder
    private var homeChapter: some View {
        let lines = Array(priorities.lines.prefix(custom.settings.priorityCount))
        Text(Copy.line(.fiveThingsEyebrow)).eyebrow().reveal()
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                HStack(alignment: .firstTextBaseline, spacing: 14) {
                    Text("\(index + 1)")
                        .figureFont(15)
                        .foregroundStyle(Color.inkSoft)
                        .frame(width: 14, alignment: .leading)
                        .accessibilityHidden(true)
                    Text(line)
                        .headingFont(.title3)
                        .foregroundStyle(Color.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .contentTransition(.opacity)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(index + 1). \(line)")
                .reveal(delay: 0.04 + Double(index) * 0.05)
            }
        }
        .padding(.top, 4)
        .animation(.gentle(calm, .smooth(duration: 0.6)), value: priorities.lines)
        .coachTarget(.priorities)
        if custom.settings.showPrioritySource {
            Label(priorities.source == .appleIntelligence ? "Written on this iPhone by Apple Intelligence" : "Ranked from your plan",
                  systemImage: priorities.source == .appleIntelligence ? "apple.intelligence" : "list.number")
                .font(.caption2)
                .foregroundStyle(Color.inkSoft)
                .reveal(delay: 0.3)
        }
        MedsStrip(toast: $toast)
            .padding(.top, 14)
            .coachTarget(.meds)
            .reveal(delay: 0.35)
        LiveDayOffer()
            .padding(.top, 16)
            .reveal(delay: 0.4)
    }

    // MARK: Now

    @ViewBuilder
    private func nowChapter(_ now: Date) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Now").eyebrow()
            HeroText(text: model.dayLine, size: 26)
        }
        .reveal()
        .padding(.bottom, 6)

        if let block = model.nowBlock {
            nowCard(block, now: now).reveal(delay: 0.05)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text(Copy.line(.nowGap)).headingFont(.title2).foregroundStyle(Color.ink)
                if let next = model.nextBlock {
                    Text("Free until \(next.interval.start.formatted(.compactTime)).")
                        .font(.subheadline).foregroundStyle(Color.inkSoft)
                }
            }
            .reveal(delay: 0.05)
        }

        if let next = model.nextBlock {
            Text(Copy.line(.nowThen, ["task": next.title, "time": next.interval.start.formatted(.compactTime)]))
                .font(.footnote)
                .foregroundStyle(Color.inkSoft)
                .padding(.top, 10)
                .reveal(delay: 0.12)
        }
    }

    private func nowCard(_ block: Block, now: Date) -> some View {
        let remaining = max(0, block.interval.end.timeIntervalSince(now))
        let minutesLeft = Int((remaining / 60).rounded(.up))
        let wrapUp = minutesLeft <= 5
        return VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 18) {
                TimeRing(remaining: remaining / block.interval.duration, minutesLeft: minutesLeft, isWrapUp: wrapUp)
                VStack(alignment: .leading, spacing: 4) {
                    Text(wrapUp ? "Wrap up" : Explainer.demandWord(for: block)).eyebrow(wrapUp ? .ink : .inkSoft)
                    Text(block.title)
                        .headingFont(.title2)
                        .foregroundStyle(Color.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(block.interval.start.formatted(.compactTime)) to \(block.interval.end.formatted(.compactTime))")
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(Color.inkSoft)
                }
            }
            if custom.settings.showFirstStep {
                VStack(alignment: .leading, spacing: 3) {
                    Text("First step").eyebrow()
                    Text(Explainer.firstStep(for: block))
                        .font(.subheadline)
                        .foregroundStyle(Color.ink)
                }
            }
            ActionRow {
                Button("Done", systemImage: "checkmark") {
                    Haptics.shared.play(.complete)
                    withAnimation(.gentle(calm, .bouncy)) { model.markDone(block) }
                    toast = Copy.line(.focusDoneCheer)
                }
                .buttonStyle(.glassProminent)
                .foregroundStyle(.onAccent)

                Menu {
                    Button("Done for now", systemImage: "pause") { withAnimation(.gentle(calm)) { model.markDoneForNow(block) } }
                    Button("Fix my day", systemImage: "wand.and.sparkles") { fixPreview = model.previewFixMyDay(runningLateMinutes: 40) }
                } label: {
                    Text("Not now")
                }
                .buttonStyle(.glass)

                Button {
                    Haptics.shared.play(.tap)
                    focusMode = true
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .accessibilityLabel("Open focus mode")
            }
            .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .veil(padding: 20)
        .matchedTransitionSource(id: "now", in: zoom)
    }

    // MARK: Your focus window

    @ViewBuilder
    private func windowChapter(_ now: Date) -> some View {
        Text("Your focus window").eyebrow().reveal()
        if let w = model.window {
            HeroText(text: "\(w.start.formatted(.compactTime)) to \(w.end.formatted(.compactTime))", size: 30).reveal()
            Text(confidenceLine(w)).font(.footnote).foregroundStyle(Color.inkSoft).reveal()
            VStack(alignment: .leading, spacing: 14) {
                SkyBand(window: w, now: now, drawn: bandDrawn)
                HStack(spacing: 16) {
                    legend(.zoneWarm, "Warm-up")
                    legend(.zoneBest, "Best")
                    legend(.zoneLight, "Lighter")
                }
            }
            .veil(padding: 18)
            .padding(.top, 10)
            .reveal(delay: 0.05)
            .onScrollVisibilityChange(threshold: 0.5) { visible in
                if visible && !bandDrawn { bandDrawn = true }
            }
            .onChange(of: model.doseLoggedSequence) {
                var t = Transaction(); t.disablesAnimations = true
                withTransaction(t) { bandDrawn = false }
                DispatchQueue.main.async { bandDrawn = true }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Focus window \(w.start.formatted(date: .omitted, time: .shortened)) to \(w.end.formatted(date: .omitted, time: .shortened)). \(confidenceLine(w)).")
            if let schedule = model.todaySchedule, !schedule.gaps.isEmpty {
                Text(schedule.gaps.count == 1 ? "One low-focus stretch in between. Lighter things go there." : "\(schedule.gaps.count) low-focus stretches in between. Lighter things go there.")
                    .font(.caption).foregroundStyle(Color.inkSoft)
                    .reveal(delay: 0.1)
            }
        } else {
            HeroText(text: "A routine day", size: 30)
            Text(Copy.line(.dayLineRoutine)).font(.footnote).foregroundStyle(Color.inkSoft)
        }
    }

    private func confidenceLine(_ w: FocusWindow) -> String {
        let u = max(w.startUncertaintyMinutes, w.endUncertaintyMinutes)
        switch w.confidence {
        case .learned(let n): return "Your usual focus, from \(n) check-ins, give or take \(u) min"
        case .early(let d): return "An early guess from \(d) days, give or take \(u) min"
        case .starting: return "A first guess from what you told us"
        case .manualOverride: return "Your own setting"
        }
    }

    private func legend(_ color: Color, _ label: LocalizedStringKey) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).font(.caption2).foregroundStyle(Color.inkSoft)
        }
    }

    // MARK: The rest of today

    @ViewBuilder
    private var restChapter: some View {
        let rest = model.restOfToday.filter { !model.isDone($0) }
        let visible = showAllRest ? rest : Array(rest.prefix(3))
        Text("Rest of today").eyebrow().reveal()
        HeroText(text: rest.isEmpty ? Copy.line(.emptyPlan)
                 : rest.count == 1 ? Copy.line(.restOneLeft)
                 : Copy.line(.restHeadline, ["count": "\(rest.count)"]), size: 30).reveal()
        if !rest.isEmpty {
            RowGroup {
                ForEach(visible) { block in
                    InfoRow(label: "\(block.interval.start.formatted(.compactTime)) to \(block.interval.end.formatted(.compactTime))",
                            title: block.title, dot: Explainer.tint(for: block))
                        .transition(.opacity)
                        .accessibilityHint(Explainer.meta(for: block))
                }
            }
            .padding(.top, 8)
            .reveal(delay: 0.05)
        }
        if rest.count > 3 {
            Button {
                Haptics.shared.play(.tap)
                withAnimation(.gentle(calm, .smooth)) { showAllRest.toggle() }
            } label: {
                Label(showAllRest ? "Show less" : "Show \(rest.count - 3) more",
                      systemImage: showAllRest ? "chevron.up" : "chevron.down")
                    .font(.footnote)
                    .foregroundStyle(Color.ink)
            }
            .buttonStyle(.plain)
            .reveal()
        }
        if !model.unplaced.isEmpty {
            Text(Copy.line(.restUnplaced, ["count": "\(model.unplaced.count)"]))
                .font(.footnote).foregroundStyle(Color.inkSoft)
                .reveal()
        }
        if model.personalisation.socialSuggestions, let first = model.socialSuggestions.first {
            Button {
                Haptics.shared.play(.tap)
                social = first
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Image(systemName: "person.2").foregroundStyle(Color.zoneBest)
                    Text(Copy.line(.socialLine, ["event": first.eventTitle, "time": first.current.start.formatted(.compactTime)]))
                        .font(.footnote).foregroundStyle(Color.ink)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 14).padding(.vertical, 10)
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
            .reveal(delay: 0.1)
        }
    }

    // MARK: Today in shapes

    @ViewBuilder
    private var shapesChapter: some View {
        Text("Today in shapes").eyebrow().reveal()
        HeroText(text: Copy.line(.shapesHeadline, ["done": "\(model.doneCount)", "total": "\(model.taskCount)"]), size: 30).reveal()
        HStack(alignment: .center, spacing: 24) {
            DayShapes(slices: model.todaySlices, centreFigure: "\(model.fillPercent)%",
                      centreCaption: "planned", shown: shapesShown)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(model.todaySlices) { slice in
                    HStack(spacing: 8) {
                        Circle().fill(slice.color).frame(width: 6, height: 6)
                        Text(slice.id).font(.caption).foregroundStyle(Color.ink)
                        Text(Duration.seconds(slice.minutes * 60).formatted(.units(allowed: [.hours, .minutes], width: .narrow)))
                            .font(.caption.monospacedDigit()).foregroundStyle(Color.inkSoft)
                    }
                }
            }
        }
        .padding(.top, 12)
        .reveal(delay: 0.05)
        .onScrollVisibilityChange(threshold: 0.4) { visible in
            if visible && !shapesShown { withAnimation(.gentle(calm, .smooth(duration: 1.0))) { shapesShown = true } }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: If today changes

    @ViewBuilder
    private var changeChapter: some View {
        Text("If today changes").eyebrow().reveal()
        VStack(alignment: .leading, spacing: 10) {
            Button("Fix my day", systemImage: "wand.and.sparkles") {
                Haptics.shared.play(.tap)
                fixPreview = model.previewFixMyDay(runningLateMinutes: 40)
            }
            Button(model.dayVersion == .ideal ? "Switch to a lighter day" : "Back to the full day", systemImage: "leaf") {
                Haptics.shared.play(.choose)
                withAnimation(.gentle(calm)) { model.dayVersion = model.dayVersion == .ideal ? .baseline : .ideal }
            }
        }
        .buttonStyle(.glass)
        .font(.subheadline)
        .reveal(delay: 0.05)
        Text(Copy.line(.changeFootnote))
            .font(.footnote).foregroundStyle(Color.inkSoft)
            .reveal(delay: 0.1)
    }

    // MARK: Tiny wins

    @ViewBuilder
    private var tinyWinsChapter: some View {
        let done = model.plan.blocks.filter { $0.kind == .task && model.isDone($0) }
        let logged = model.plannedDoses.filter(\.isLogged).count
        Text("Tiny wins").eyebrow().reveal()
        HeroText(text: done.isEmpty && logged == 0 ? Copy.line(.tinyWinsEmpty) : Copy.line(.tinyWinsTitle), size: 28).reveal()
        VStack(alignment: .leading, spacing: 10) {
            ForEach(done) { block in
                Label(block.title, systemImage: "checkmark.circle.fill")
                    .font(.subheadline).foregroundStyle(Color.ink)
                    .symbolRenderingMode(.hierarchical)
            }
            if logged > 0 {
                Label(logged == 1 ? "Logged your medication" : "Logged \(logged) doses", systemImage: "checkmark.circle.fill")
                    .font(.subheadline).foregroundStyle(Color.ink)
            }
            if model.hasArrived {
                Label("Opened the app and looked at the day", systemImage: "checkmark.circle")
                    .font(.subheadline).foregroundStyle(Color.inkSoft)
            }
        }
        .padding(.top, 6)
        .reveal(delay: 0.05)
    }

    // MARK: Toolbar

    private var brainWeatherMenu: some View {
        Menu {
            Picker("How’s your brain today?", selection: Binding(get: { model.brainWeather }, set: { model.brainWeather = $0; Haptics.shared.play(.choose) })) {
                Label("Low, so a lighter day", systemImage: "cloud.drizzle").tag(AppModel.BrainWeather.low)
                Label("Okay", systemImage: "cloud.sun").tag(AppModel.BrainWeather.okay)
                Label("Good", systemImage: "sun.max").tag(AppModel.BrainWeather.good)
            }
        } label: {
            Image(systemName: model.brainWeather == .low ? "cloud.drizzle" : model.brainWeather == .good ? "sun.max" : "cloud.sun")
                .frame(width: 22, height: 22)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel("Brain weather")
    }
}

extension PlanResult: @retroactive Identifiable {
    public var id: Int { plan.hashValue }
}

// MARK: - Your day in the Dynamic Island, offered once

/// Once something's been logged, a quiet offer to show Your day as a Live Activity. "Show it" turns
/// it on (Customise, Lock Screen and Dynamic Island); "Not now" never asks again.
struct LiveDayOffer: View {
    @Environment(AppModel.self) private var model
    @Environment(Customisation.self) private var custom
    @Environment(\.motionIsCalm) private var calm
    @AppStorage("liveDayOfferAnswered") private var answered = false

    private var shows: Bool {
        let live = LiveActivityController.shared
        return !answered && !custom.settings.liveDay && !model.todaysDoses.isEmpty
            && live.areActivitiesEnabled && !live.isShowingDay
    }

    var body: some View {
        if shows {
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick one").eyebrow()
                Text("Want your day in the Dynamic Island?")
                    .headingFont(.title3)
                    .foregroundStyle(Color.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text("See which stretch you’re in without opening Focus.")
                    .font(.footnote)
                    .foregroundStyle(Color.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                ActionRow {
                    Button("Show it") {
                        Haptics.shared.play(.success)
                        withAnimation(.gentle(calm)) {
                            answered = true
                            custom.settings.liveDay = true
                        }
                    }
                    .buttonStyle(.glassProminent)
                    .foregroundStyle(.onAccent)
                    Button("Not now") {
                        Haptics.shared.play(.tap)
                        withAnimation(.gentle(calm)) { answered = true }
                    }
                    .buttonStyle(.glass)
                }
                .font(.subheadline)
                .padding(.top, 6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .veil(padding: 18)
            .transition(.opacity)
        }
    }
}

// MARK: - Today's medication on the home page

/// Today's medication on the home page, kept to one slim row: two buttons and a more button.
/// Tap a button to log that dose now (always through the double-dose guard); press and hold to log it
/// at another time. More opens every dose for today, with Log all at the top.
struct MedsStrip: View {
    @Binding var toast: String?
    @Environment(AppModel.self) private var model
    @Environment(Customisation.self) private var custom
    @State private var showAll = false
    @State private var logging: Medication?

    /// The two that matter right now, from two different medicines where possible: the next doses
    /// still to log, then the latest logged. The rest sit behind the more button.
    private var featured: [AppModel.PlannedDose] {
        let doses = model.plannedDoses
        let ranked = doses.filter { !$0.isLogged } + doses.filter(\.isLogged).reversed()
        var picked: [AppModel.PlannedDose] = []
        for dose in ranked where picked.count < 2 && !picked.contains(where: { $0.medication.id == dose.medication.id }) {
            picked.append(dose)
        }
        for dose in ranked where picked.count < 2 && !picked.contains(where: { $0.id == dose.id }) {
            picked.append(dose)
        }
        return picked.sorted { $0.planned < $1.planned }
    }

    var body: some View {
        let doses = model.plannedDoses
        let shown = featured
        let sameMedicine = shown.count == 2 && shown[0].medication.id == shown[1].medication.id
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                if model.medications.isEmpty {
                    wide("Add medication", systemImage: "plus") { model.route = .medication }
                } else if doses.isEmpty {
                    wide("Log a dose", systemImage: "plus") { logging = model.medications.first }
                } else {
                    ForEach(shown) { dose in
                        DoseButton(dose: dose, setForNow: model.dueDoses.contains { $0.id == dose.id }, showTime: sameMedicine) {
                            Task { await log(dose) }
                        } elsewhen: {
                            logging = dose.medication
                        }
                    }
                }
                Button {
                    Haptics.shared.play(.tap)
                    showAll = true
                } label: {
                    Group {
                        if doses.count > shown.count { Text("+\(doses.count - shown.count)").font(.subheadline.monospacedDigit()) }
                        else { Image(systemName: "ellipsis") }
                    }
                    .foregroundStyle(Color.ink)
                    .frame(width: 40, height: 40)
                    .contentShape(.circle)
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: .circle)
                .accessibilityLabel("All of today’s medication")
            }
        }
        .logCelebration(trigger: model.doseLoggedSequence, active: custom.settings.celebrateLogging)
        .sheet(isPresented: $showAll) { AllDosesSheet(logging: $logging, toast: $toast).presentationDetents([.medium, .large]) }
        .sheet(item: $logging) { LogDoseSheet(initial: $0) }
    }

    private func wide(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.shared.play(.tap)
            action()
        } label: {
            Label(title, systemImage: systemImage)
                .font(.subheadline)
                .foregroundStyle(Color.ink)
                .frame(maxWidth: .infinity, minHeight: 40)
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .capsule)
    }

    private func log(_ dose: AppModel.PlannedDose) async {
        let result = await model.logDose(dose.medication, takenAt: model.now, ateFirst: nil, gesture: UserGesture(origin: .button, at: model.now))
        switch result {
        case .logged:
            toast = Copy.line(.medsLoggedToast, ["count": "1"])
        case .alreadyLogged(let previous):
            Haptics.shared.play(.caution)
            toast = "Already logged at \(previous.takenAt.formatted(.compactTime)). Press and hold to log another."
        case .failed(let message):
            Haptics.shared.play(.caution)
            toast = message
        }
    }
}

/// One medication on the home page: a dot (or a tick once logged) and the name. Set for about now
/// shows as the accent colour. Two of the same medicine show their times so they can be told apart.
struct DoseButton: View {
    let dose: AppModel.PlannedDose
    let setForNow: Bool
    let showTime: Bool
    let log: () -> Void
    let elsewhen: () -> Void
    @Environment(\.accentChoice) private var accent
    @Environment(\.colorScheme) private var scheme

    private var name: String { dose.medication.name.split(separator: " ").first.map(String.init) ?? dose.medication.name }
    private var time: String { (dose.logged?.takenAt ?? dose.planned).formatted(.compactTime) }

    var body: some View {
        let highlight = setForNow && !dose.isLogged
        Button {
            Haptics.shared.play(.tap)
            if dose.isLogged { elsewhen() } else { log() }
        } label: {
            HStack(spacing: 7) {
                if dose.isLogged {
                    Image(systemName: "checkmark.circle.fill").font(.footnote).foregroundStyle(dose.medication.color)
                        .contentTransition(.symbolEffect(.replace))
                } else {
                    Circle().fill(dose.medication.color).frame(width: 7, height: 7)
                }
                Text(name)
                    .font(.subheadline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if showTime {
                    Text(time).font(.caption.monospacedDigit()).fixedSize()
                }
            }
            .foregroundStyle(highlight ? accent.on(scheme) : (dose.isLogged ? Color.inkSoft : Color.ink))
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 40)
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .glassEffect(highlight ? .regular.tint(accent.fill(scheme)).interactive() : .regular.interactive(), in: .capsule)
        .contextMenu {
            Button("Log at a different time", systemImage: "clock") { elsewhen() }
        }
        .accessibilityLabel("\(dose.medication.shownName(discreet: false)), \(dose.isLogged ? "logged at" : "set for") \(time)")
        .accessibilityHint(dose.isLogged ? "Opens the log to change it or log another" : "Logs it now")
    }
}

/// One planned dose in the full list: colour, name, time, and a tick once it's logged.
struct DoseRow: View {
    let dose: AppModel.PlannedDose
    let log: () -> Void

    var body: some View {
        Button {
            Haptics.shared.play(.tap)
            log()
        } label: {
            HStack(spacing: 10) {
                Circle().fill(dose.medication.color).frame(width: 7, height: 7).frame(width: 14)
                Text(dose.medication.shownName(discreet: false))
                    .font(.subheadline)
                    .foregroundStyle(dose.isLogged ? Color.inkSoft : Color.ink)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text((dose.logged?.takenAt ?? dose.planned).formatted(.compactTime))
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(Color.inkSoft)
                Image(systemName: dose.isLogged ? "checkmark.circle.fill" : "circle")
                    .font(.footnote)
                    .foregroundStyle(dose.isLogged ? Color.zoneBest : Color.inkFaint)
            }
            .padding(.vertical, 10)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) { Rectangle().fill(Color.inkFaint.opacity(0.25)).frame(height: 0.5).padding(.leading, 24) }
        .accessibilityLabel("\(dose.medication.shownName(discreet: false)), \(dose.isLogged ? "logged at" : "set for") \((dose.logged?.takenAt ?? dose.planned).formatted(date: .omitted, time: .shortened))")
    }
}

/// Every dose today, from the more button: Log all on top, then each dose (tap to log that one or
/// log it at another time).
struct AllDosesSheet: View {
    @Binding var logging: Medication?
    @Binding var toast: String?
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var working = false

    var body: some View {
        let doses = model.plannedDoses
        VStack(alignment: .leading, spacing: 12) {
            Text("Today’s medication").eyebrow()
            HeroText(text: model.todayDayType?.name ?? "Today", size: 28)
            if !model.dueDoses.isEmpty {
                Button {
                    Task { await logAll() }
                } label: {
                    Label(model.dueDoses.count > 1 ? "Log all \(model.dueDoses.count)" : "Log it", systemImage: "checkmark")
                }
                .buttonStyle(.glassProminent)
                .foregroundStyle(.onAccent)
                .font(.subheadline)
                .disabled(working)
            } else {
                Text(status(doses)).font(.footnote).foregroundStyle(Color.inkSoft)
            }
            VStack(alignment: .leading, spacing: 0) {
                ForEach(doses) { dose in
                    DoseRow(dose: dose) {
                        dismiss()
                        Task { try? await Task.sleep(for: .seconds(0.4)); logging = dose.medication }
                    }
                }
            }
            .padding(.top, 4)
            Spacer()
        }
        .padding(24)
        .background { SkyBackground(phase: model.skyPhase) }
    }

    private func status(_ doses: [AppModel.PlannedDose]) -> String {
        if doses.isEmpty { return Copy.line(.medsNone) }
        if doses.allSatisfy(\.isLogged) { return Copy.line(.medsAllLogged) }
        if let next = model.nextDose { return Copy.line(.medsNothingDue, ["time": next.planned.formatted(.compactTime)]) }
        return "\(doses.filter(\.isLogged).count) of \(doses.count) logged"
    }

    private func logAll() async {
        working = true
        defer { working = false }
        Haptics.shared.play(.logAll)
        let outcome = await model.logAllDue(origin: .button)
        if outcome.failed {
            Haptics.shared.play(.caution)
            toast = outcome.spoken
        } else if !outcome.logged.isEmpty {
            Haptics.shared.play(.success)
            toast = outcome.skipped.isEmpty ? Copy.line(.medsLoggedToast, ["count": "\(outcome.logged.count)"]) : outcome.spoken
            dismiss()
        } else {
            toast = outcome.spoken
        }
    }
}

// MARK: - One minute of breathing

/// A slow circle, four seconds in and six out, with the phone tapping along. Six rounds, then it
/// stops by itself.
struct BreathePage: View {
    @Environment(\.motionIsCalm) private var calm
    @State private var running = false
    @State private var inhale = false
    @State private var round = 0

    var body: some View {
        Text("Breathe").eyebrow().reveal()
        HeroText(text: Copy.line(.breatheIntro), size: 24).reveal()
        ZStack {
            Circle().strokeBorder(Color.inkFaint.opacity(0.4), lineWidth: 1)
            Circle()
                .fill(RadialGradient(colors: [Color.zoneBest.opacity(0.55), Color.zoneBest.opacity(0.08)], center: .center, startRadius: 4, endRadius: 110))
                .scaleEffect(inhale ? 1 : 0.42)
            Text(running ? (inhale ? "In" : "Out") : "Ready")
                .headingFont(.title3)
                .foregroundStyle(Color.ink)
                .contentTransition(.opacity)
        }
        .frame(width: 200, height: 200)
        .padding(.vertical, 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(running ? (inhale ? "Breathe in" : "Breathe out") : "Breathing exercise, ready")
        Button(running ? "Stop" : "Start a minute", systemImage: running ? "stop" : "wind") {
            running.toggle()
            Haptics.shared.play(.tap)
        }
        .buttonStyle(.glass)
        .font(.subheadline)
        .task(id: running) {
            guard running else { withAnimation(.easeOut(duration: 0.6)) { inhale = false }; return }
            round = 0
            while running && round < 6 {
                Haptics.shared.play(.breatheIn)
                withAnimation(calm ? .linear(duration: 0.01) : .easeInOut(duration: 4)) { inhale = true }
                try? await Task.sleep(for: .seconds(4))
                guard running else { break }
                Haptics.shared.play(.breatheOut)
                withAnimation(calm ? .linear(duration: 0.01) : .easeInOut(duration: 6)) { inhale = false }
                try? await Task.sleep(for: .seconds(6))
                round += 1
            }
            running = false
        }
    }
}
