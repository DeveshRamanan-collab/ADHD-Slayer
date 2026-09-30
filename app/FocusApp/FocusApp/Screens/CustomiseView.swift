import SwiftUI
import FocusGlance

/// The categories people can change, each on its own page so the first screen stays calm.
enum CustomiseSection: String, CaseIterable, Identifiable, Hashable {
    case pages, tabs, look, voice, feel, home, focus, live
    var id: Self { self }

    var title: String {
        switch self {
        case .pages: "Pages"
        case .tabs: "Tabs"
        case .look: "Look"
        case .voice: "Voice"
        case .feel: "Feel"
        case .home: "Home page"
        case .focus: "Focus mode"
        case .live: "Lock Screen and Dynamic Island"
        }
    }

    var detail: String {
        switch self {
        case .pages: "Add, remove and reorder pages"
        case .tabs: "Names, order, which ones show"
        case .look: "Light or dark, background, colour, type"
        case .voice: "How funny, how often it changes"
        case .feel: "Vibrations and motion"
        case .home: "Priorities and what they show"
        case .focus: "Timer and first step"
        case .live: "Live Activities for Focus mode and your day"
        }
    }

    var symbol: String {
        switch self {
        case .pages: "rectangle.stack"
        case .tabs: "square.grid.2x2"
        case .look: "circle.lefthalf.filled"
        case .voice: "text.bubble"
        case .feel: "hand.tap"
        case .home: "sun.horizon"
        case .focus: "timer"
        case .live: "platter.filled.top.iphone"
        }
    }
}

/// Make it yours. The first screen is only a short list; every control sits one tap deeper, so
/// nobody lands on a wall of switches. Nothing here can hide medication, the plan or the safety parts.
struct CustomiseView: View {
    @Environment(Customisation.self) private var custom
    @Environment(AppModel.self) private var model
    @State private var confirmReset = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Customise").eyebrow()
                    HeroText(text: "Your app, your rules", size: 32)
                    Text(Copy.line(.customiseIntro)).font(.subheadline).foregroundStyle(Color.inkSoft)
                }

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "exclamationmark.triangle").foregroundStyle(Color.honey)
                    Text(Copy.line(.hyperfixationWarning))
                        .font(.subheadline)
                        .foregroundStyle(Color.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .veil(tint: .honey, padding: 16)
                .onAppear { Haptics.shared.play(.nudge) }

                VStack(spacing: 0) {
                    ForEach(CustomiseSection.allCases) { section in
                        NavigationLink { CustomisePage(section: section) } label: {
                            DoorRow(title: section.title, detail: section.detail, symbol: section.symbol)
                        }
                        .buttonStyle(.plain)
                        .tapHaptic(.choose)
                        if section != CustomiseSection.allCases.last { Rectangle().fill(Color.inkFaint.opacity(0.25)).frame(height: 0.5).padding(.leading, 38) }
                    }
                }
                .veil(padding: 12)

                Button("Put everything back how it was") { confirmReset = true }
                    .font(.footnote)
                    .foregroundStyle(Color.inkSoft)
                    .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .background { SkyBackground(phase: model.skyPhase) }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .confirmationDialog("Reset how Focus looks and feels?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset customisation", role: .destructive) { Haptics.shared.play(.acknowledge); custom.reset() }
        } message: {
            Text("Your plan, medication and history stay exactly as they are.")
        }
    }
}

/// One category's controls.
struct CustomisePage: View {
    let section: CustomiseSection
    @Environment(Customisation.self) private var custom
    @Environment(AppModel.self) private var model
    @Environment(\.motionIsCalm) private var calm
    @Environment(\.openURL) private var openURL
    @AppStorage("hapticsEnabled") private var haptics = true
    @AppStorage("stillMotion") private var stillMotion = false
    @State private var editingTab: TabKind?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Customise").eyebrow()
                    HeroText(text: section.title, size: 30)
                }
                if section == .live {
                    liveControls
                } else {
                    VStack(alignment: .leading, spacing: 4) { controls }
                        .veil(padding: 16)
                }
                if section == .voice {
                    Text("Anything about medication, safety or money stays plain, whatever you pick.").font(.caption).foregroundStyle(Color.inkSoft)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.immediately)
        .background { SkyBackground(phase: model.skyPhase) }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .sheet(item: $editingTab) { tab in PageEditor(tab: tab) }
    }

    @ViewBuilder private var controls: some View {
        @Bindable var custom = custom
        switch section {
        case .pages:
            ForEach(custom.settings.visibleTabs) { tab in
                Button { Haptics.shared.play(.tap); editingTab = tab } label: {
                    row(custom.settings.name(for: tab), detail: "\(custom.settings.visiblePages(tab).count) pages", symbol: tab.symbol)
                }
                .buttonStyle(.plain)
            }
        case .tabs:
            ForEach(TabKind.allCases) { tab in
                HStack(spacing: 12) {
                    Image(systemName: tab.symbol).foregroundStyle(Color.zoneBest).frame(width: 24)
                    TextField(tab.defaultName, text: Binding(get: { custom.settings.tabNames[tab] ?? "" },
                                                             set: { custom.settings.tabNames[tab] = $0 }))
                        .font(.subheadline).foregroundStyle(Color.ink)
                    if tab.canHide {
                        Toggle("Show", isOn: Binding(get: { !custom.settings.hiddenTabs.contains(tab) }, set: { show in
                            Haptics.shared.play(.toggle)
                            if show { custom.settings.hiddenTabs.remove(tab) } else { custom.settings.hiddenTabs.insert(tab) }
                        }))
                        .labelsHidden()
                        .tint(Color.zoneBest)
                    } else {
                        Image(systemName: "lock").font(.caption).foregroundStyle(Color.inkSoft).accessibilityLabel("Always shown")
                    }
                }
                .padding(.vertical, 6)
            }
            HStack {
                Text("Swap Plan and Rhythm").font(.subheadline).foregroundStyle(Color.ink)
                Spacer()
                Button { Haptics.shared.play(.choose); swapMiddleTabs() } label: { Image(systemName: "arrow.left.arrow.right") }
                    .buttonStyle(.glass).buttonBorderShape(.circle)
            }
            .padding(.vertical, 4)
        case .look:
            picker("Light or dark", selection: $custom.settings.appearance, options: Appearance.allCases) { $0.label }
            picker("Background when dark", selection: $custom.settings.darkBackdrop, options: Backdrop.allCases) { $0.label }
            slider("Darkness when dark", value: $custom.settings.darkness, range: 0...0.8, step: 0.05) { "\(Int($0 * 100))%" }
            picker("Background when light", selection: $custom.settings.lightBackdrop, options: Backdrop.allCases) { $0.label }
            slider("Extra blur", value: $custom.settings.blur, range: 0...30, step: 1) { "\(Int($0))" }
            slider("Mist", value: $custom.settings.frost, range: 0...1, step: 0.05) { "\(Int($0 * 100))%" }
            slider("Grain", value: $custom.settings.grain, range: 0...1, step: 0.05) { "\(Int($0 * 100))%" }
            accentRow
            picker("Headings", selection: $custom.settings.typeface, options: Typeface.allCases) { $0.label }
            picker("Text size", selection: $custom.settings.textSize, options: TextSizeChoice.allCases) { $0.label }
            slider("Roundness", value: $custom.settings.roundness, range: 0.5...1.4, step: 0.05) { String(format: "%.2g×", $0) }
            picker("Page markers", selection: $custom.settings.dots, options: DotStyle.allCases) { $0.label }
        case .voice:
            picker("Humour", selection: $custom.settings.humour, options: Humour.allCases) { $0.label }
            toggle("New words every day", detail: "Sentences change daily so the app never goes stale.", isOn: $custom.settings.dailyVariety)
            HStack {
                Text("Call me").font(.subheadline).foregroundStyle(Color.ink)
                TextField("a nickname", text: $custom.settings.nickname).multilineTextAlignment(.trailing)
                    .font(.subheadline).foregroundStyle(Color.ink)
            }
            .padding(.vertical, 6)
        case .feel:
            toggle("Vibrations", detail: "Touch keeps a lot of us anchored. Switch off if it gets too much.", isOn: $haptics)
            slider("Strength", value: $custom.settings.hapticStrength, range: 0.3...1.3, step: 0.05) { "\(Int($0 * 100))%" }
                .disabled(!haptics).opacity(haptics ? 1 : 0.45)
            toggle("Ticks on sliders", detail: nil, isOn: $custom.settings.sliderTicks)
            toggle("Celebrate logging", detail: "A glow and a little burst when you log medication.", isOn: $custom.settings.celebrateLogging)
            toggle("Still motion", detail: "Fades instead of movement. Also follows Reduce Motion.", isOn: $stillMotion)
        case .home:
            picker("Priorities", selection: $custom.settings.priorityCount, options: [3, 5]) { "\($0)" }
            toggle("Say who wrote the priorities", detail: nil, isOn: $custom.settings.showPrioritySource)
            picker("Bottom bar shows", selection: $custom.settings.accessory, options: AccessoryContent.allCases) { $0.label }
        case .focus:
            picker("Timer", selection: $custom.settings.ringStyle, options: RingStyle.allCases) { $0.label }
            toggle("Show the first step", detail: nil, isOn: $custom.settings.showFirstStep)
        case .live:
            EmptyView()
        }
    }

    /// Lock Screen and Dynamic Island: two quiet cards, and a note with a way to iOS Settings when
    /// Live Activities are switched off there (the switches dim until they're back on).
    @ViewBuilder private var liveControls: some View {
        @Bindable var custom = custom
        let enabled = LiveActivityController.shared.areActivitiesEnabled
        if !enabled {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "exclamationmark.circle").foregroundStyle(Color.honey)
                    Text("Live Activities are off for Focus in iOS Settings.")
                        .font(.subheadline)
                        .foregroundStyle(Color.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Button("Open Settings") {
                    Haptics.shared.play(.tap)
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
                .buttonStyle(.glass)
                .font(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .veil(tint: .honey, padding: 16)
        }
        VStack(alignment: .leading, spacing: 4) {
            toggle("Focus mode", detail: "Shows the task and the time left while you’re in Focus mode.", isOn: $custom.settings.liveFocusMode)
            toggle("Your day", detail: "Shows the stretch you’re in and what’s next.", isOn: $custom.settings.liveDay)
            if custom.settings.liveDay {
                picker("Your day shows", selection: $custom.settings.liveDayShows, options: DayShows.allCases) { $0.label }
                    .transition(.opacity)
            }
        }
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.45)
        .animation(.gentle(calm), value: custom.settings.liveDay)
        .veil(padding: 16)
        VStack(alignment: .leading, spacing: 4) {
            toggle("Log button", detail: "Adds Log when something’s set for about now. Asks for Face ID first.", isOn: $custom.settings.liveLogButton)
            toggle("Hide task names on the Lock Screen", detail: "Shows “Focus” instead of the task.", isOn: $custom.settings.liveHideTaskNames)
        }
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.45)
        .veil(padding: 16)
        Text("Live Activities never name a medicine.")
            .font(.caption)
            .foregroundStyle(Color.inkSoft)
    }

    private var accentRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Accent").font(.subheadline).foregroundStyle(Color.ink)
            HStack(spacing: 14) {
                ForEach(AccentChoice.allCases) { accent in
                    VStack(spacing: 4) {
                        HStack(spacing: 0) {
                            Rectangle().fill(accent.fill(.light))
                            Rectangle().fill(accent.fill(.dark))
                        }
                        .frame(width: 34, height: 34)
                        .clipShape(.circle)
                        .overlay(Circle().strokeBorder(Color.ink, lineWidth: custom.settings.accent == accent ? 2 : 0).padding(-3))
                        Text(accent.label).font(.caption2).foregroundStyle(Color.inkSoft)
                    }
                    .onTapGesture { Haptics.shared.play(.choose); custom.settings.accent = accent }
                    .accessibilityAddTraits(custom.settings.accent == accent ? [.isButton, .isSelected] : .isButton)
                    .accessibilityLabel(accent.label)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func swapMiddleTabs() {
        var order = custom.settings.tabOrder
        if let p = order.firstIndex(of: .plan), let r = order.firstIndex(of: .rhythm) { order.swapAt(p, r) }
        custom.settings.tabOrder = order
    }

    // Building blocks

    private func row(_ title: String, detail: String, symbol: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).foregroundStyle(Color.zoneBest).frame(width: 24)
            Text(title).font(.subheadline).foregroundStyle(Color.ink)
            Spacer()
            Text(detail).font(.caption).foregroundStyle(Color.inkSoft)
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Color.inkSoft)
        }
        .padding(.vertical, 8)
        .contentShape(.rect)
    }

    private func toggle(_ title: String, detail: String?, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline).foregroundStyle(Color.ink)
                if let detail { Text(detail).font(.caption).foregroundStyle(Color.inkSoft) }
            }
        }
        .tint(Color.zoneBest)
        .padding(.vertical, 6)
        .onChange(of: isOn.wrappedValue) { Haptics.shared.play(.toggle) }
    }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, label: @escaping (Double) -> String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title).font(.subheadline).foregroundStyle(Color.ink)
                Spacer()
                Text(label(value.wrappedValue)).font(.caption.monospacedDigit()).foregroundStyle(Color.inkSoft)
            }
            GlassSlider(value: value, range: range, step: step, label: label).accessibilityLabel(title)
        }
        .padding(.vertical, 4)
    }

    private func picker<T: Hashable>(_ title: String, selection: Binding<T>, options: [T], label: @escaping (T) -> String) -> some View {
        HStack {
            Text(title).font(.subheadline).foregroundStyle(Color.ink)
            Spacer()
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(label(option)) { Haptics.shared.play(.choose); selection.wrappedValue = option }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(label(selection.wrappedValue)).font(.subheadline)
                    Image(systemName: "chevron.up.chevron.down").font(.caption2)
                }
                .foregroundStyle(Color.ink)
            }
        }
        .padding(.vertical, 8)
    }
}

/// A quiet row that opens something: symbol, name, one line of detail, chevron. Used wherever a page
/// should stay calm and push the detail one level deeper.
struct DoorRow: View {
    let title: String
    let detail: String
    let symbol: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol).font(.body).foregroundStyle(Color.zoneBest).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline).foregroundStyle(Color.ink)
                Text(detail).font(.caption).foregroundStyle(Color.inkSoft).lineLimit(1)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Color.inkSoft)
        }
        .padding(.vertical, 12)
        .contentShape(.rect)
    }
}

/// Reorder, remove and add pages for one tab. Locked pages show a lock and can move but not leave.
struct PageEditor: View {
    let tab: TabKind
    @Environment(Customisation.self) private var custom
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(custom.settings.visiblePages(tab)) { page in
                        HStack(spacing: 12) {
                            Image(systemName: page.symbol).foregroundStyle(Color.zoneBest).frame(width: 24)
                            Text(page.title).foregroundStyle(Color.ink)
                            Spacer()
                            if page.locked {
                                Image(systemName: "lock").font(.caption).foregroundStyle(Color.inkSoft).accessibilityLabel("Always shown")
                            }
                        }
                        .deleteDisabled(page.locked)
                    }
                    .onMove { from, to in Haptics.shared.play(.tick); custom.move(tab, from: from, to: to) }
                    .onDelete { offsets in
                        Haptics.shared.play(.tap)
                        let pages = custom.settings.visiblePages(tab)
                        for i in offsets where !pages[i].locked { custom.remove(pages[i]) }
                    }
                } header: {
                    Text("Showing, in this order")
                } footer: {
                    Text("Drag to reorder. Swipe to remove. The first page is where the tab opens.")
                }
                let hidden = custom.hiddenPages(tab)
                if !hidden.isEmpty {
                    Section("Add a page") {
                        ForEach(hidden) { page in
                            Button { Haptics.shared.play(.success); custom.add(page) } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: page.symbol).foregroundStyle(Color.zoneBest).frame(width: 24)
                                    Text(page.title).foregroundStyle(Color.ink)
                                    Spacer()
                                    Image(systemName: "plus.circle").foregroundStyle(Color.zoneBest)
                                }
                            }
                        }
                    }
                }
            }
            .environment(\.editMode, .constant(.active))
            .scrollContentBackground(.hidden)
            .background { SkyBackground(phase: model.skyPhase) }
            .navigationTitle(custom.settings.name(for: tab))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done", systemImage: "checkmark") { dismiss() } } }
        }
    }
}
