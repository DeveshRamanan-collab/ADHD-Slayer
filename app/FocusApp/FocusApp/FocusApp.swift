import SwiftUI
import AppIntents
import FoundationModels

@main
struct FocusApp: App {
    @State private var model: AppModel
    @State private var store = Store()
    @State private var accounts = AccountStore()
    @State private var custom = Customisation()
    @State private var ai = ExternalAI()

    init() {
        let model = AppModel()
        _model = State(initialValue: model)
        // App Intents (Action button, Siri, Shortcuts) log through the same model as the app.
        AppDependencyManager.shared.add(dependency: model)
        // Live Activities: pick up the ones already running, end duplicates, and let their buttons
        // (which run in this process) reach the same model.
        LiveActivityController.shared.launch(model: model)
    }

    var body: some Scene {
        WindowGroup {
            // Innermost first: the look reads Customisation, so it sits inside the environment.
            RootView()
                .modifier(LookModifier())
                .modifier(CalmMotionReader())
                .environment(model)
                .environment(store)
                .environment(accounts)
                .environment(custom)
                .environment(ai)
                .task { store.start() }
        }
    }
}

extension TabKind {
    /// `-tab rhythm` opens straight on a tab (screenshots, UI tests).
    static var atLaunch: TabKind {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-tab"), i + 1 < args.count else { return .today }
        return TabKind(rawValue: args[i + 1]) ?? .today
    }
}

/// Everything from Customise that changes how the whole app looks: dark first, the accent, the
/// heading typeface, corner roundness and text size. Also tells the copy deck how funny to be.
struct LookModifier: ViewModifier {
    @Environment(Customisation.self) private var custom

    func body(content: Content) -> some View {
        let s = custom.settings
        let _ = syncCopy(s)
        sized(content, s.textSize.size)
            .environment(\.typeface, s.typeface)
            .environment(\.accentChoice, s.accent)
            .environment(\.roundness, s.roundness)
            .tint(AccentFillStyle())
            .preferredColorScheme(s.appearance.scheme)
    }

    @ViewBuilder private func sized(_ content: Content, _ size: DynamicTypeSize?) -> some View {
        if let size { content.dynamicTypeSize(size) } else { content }
    }

    private func syncCopy(_ s: CustomSettings) {
        Copy.humour = s.humour
        Copy.dailyVariety = s.dailyVariety
    }
}

/// First launch: the device check, then the start animation, greeting, the honest bit, account and
/// the trial offer, then straight to the home page with skippable pointers. After that, the
/// starting page once a day, then the tabs.
struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.motionIsCalm) private var calm
    @AppStorage("onboarded") private var onboarded = false
    @State private var availability = SystemLanguageModel.default.availability
    @State private var gatePassed = ProcessInfo.processInfo.arguments.contains("-skipGate")

    var body: some View {
        ZStack {
            if gateBlocks {
                ZStack {
                    SkyBackground(phase: .night)
                    DeviceGateView(availability: availability) {
                        availability = SystemLanguageModel.default.availability
                        if case .unavailable(.modelNotReady) = availability { gatePassed = true }
                    }
                }
                .transition(.opacity)
            } else if !onboarded {
                OnboardingFlow {
                    model.hasArrived = true
                    withAnimation(.gentle(calm, .smooth(duration: 0.9))) { onboarded = true }
                }
                .transition(.opacity)
            } else if model.hasArrived {
                MainTabs()
                    .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 1.03)), removal: .opacity))
            } else {
                ArrivalView()
                    .transition(.opacity)
            }
        }
        .animation(.gentle(calm, .smooth(duration: 0.8)), value: model.hasArrived)
        .animation(.gentle(calm, .smooth(duration: 0.6)), value: gateBlocks)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            availability = SystemLanguageModel.default.availability
        }
    }

    /// iPhones that can't run Apple Intelligence can't use Focus, ever. On first launch we also ask
    /// people to switch it on (or wait for the download). After that, if it's switched off or
    /// re-downloading, the app keeps working on its plan-ranked fallbacks: logging, the guard and Get
    /// support must never be locked away.
    private var gateBlocks: Bool {
        if gatePassed { return false }
        switch availability {
        case .available: return false
        case .unavailable(.deviceNotEligible): return true
        default: return !onboarded
        }
    }
}

/// The glass tab bar with the tabs people chose, in their order and with their names, plus the
/// medication glance in the bottom accessory so logging is always within thumb reach.
struct MainTabs: View {
    @Environment(AppModel.self) private var model
    @Environment(Customisation.self) private var custom
    @State private var tab: TabKind = .atLaunch
    @State private var showLog = false

    var body: some View {
        let s = custom.settings
        TabView(selection: $tab) {
            ForEach(s.visibleTabs) { kind in
                Tab(s.name(for: kind), systemImage: kind.symbol, value: kind) { screen(kind) }
            }
        }
        .tabViewBottomAccessory { DoseAccessory { showLog = true } }
        .sensoryFeedback(.selection, trigger: tab) { _, _ in Haptics.shared.isEnabled }
        .sheet(isPresented: $showLog) { LogDoseSheet() }
        .onChange(of: model.route) { if model.route != nil { tab = .you } }
        .onChange(of: s.visibleTabs) { if !s.visibleTabs.contains(tab) { tab = .today } }
    }

    @ViewBuilder private func screen(_ kind: TabKind) -> some View {
        switch kind {
        case .today: TodayView()
        case .plan: PlanView()
        case .rhythm: RhythmView()
        case .you: YouView()
        }
    }
}

/// "Did I already log it?" at a glance, on every tab. Collapses to a compact tick when the tab bar
/// tucks away. Can show what's next instead, from Customise.
struct DoseAccessory: View {
    @Environment(AppModel.self) private var model
    @Environment(Customisation.self) private var custom
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement
    let onLog: () -> Void

    private var allLogged: Bool {
        let doses = model.plannedDoses
        return !doses.isEmpty && doses.allSatisfy(\.isLogged)
    }

    var body: some View {
        HStack(spacing: 10) {
            if custom.settings.accessory == .nextThing, let next = model.nextBlock {
                Image(systemName: "arrow.forward.circle").foregroundStyle(Color.zoneBest)
                Text(placement == .expanded ? "\(next.title) at \(next.interval.start.formatted(.compactTime))" : next.interval.start.formatted(.compactTime))
                    .font(.subheadline).lineLimit(1)
                Spacer(minLength: 0)
            } else {
                Image(systemName: allLogged ? "checkmark.circle.fill" : model.todaysDose == nil ? "circle.dashed" : "circle.lefthalf.filled")
                    .foregroundStyle(Color.zoneBest)
                    .symbolEffect(.bounce, value: model.doseLoggedSequence)
                if placement == .expanded {
                    Text(model.doseGlance).font(.subheadline).lineLimit(1)
                    Spacer()
                    // Plain inside the accessory: it's already glass, and glass on glass washes the label out.
                    Button(action: { Haptics.shared.play(.tap); onLog() }) {
                        Label("Log", systemImage: model.discreetMode ? "checkmark" : "pills")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.ink)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .overlay(Capsule().strokeBorder(Color.ink.opacity(0.35), lineWidth: 0.75))
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(model.todaysDose.map { $0.takenAt.formatted(.compactTime) } ?? "Log")
                        .font(.subheadline)
                }
            }
        }
        .padding(.horizontal, 16)
        .contentShape(.rect)
        .onTapGesture { if placement != .expanded { onLog() } }
        .accessibilityElement(children: .contain)
    }
}
