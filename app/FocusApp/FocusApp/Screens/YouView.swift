import SwiftUI

/// You, kept clutter free. Page 1 is only your name and the two things you'll actually use
/// (Medication and Personalise). Page 2 is support. The last page, two swipes in, holds the fiddly
/// bits (one-press logging, Customise, Settings, your own AI) as a few quiet rows; every complicated
/// control sits one level deeper still.
struct YouView: View {
    @Environment(AppModel.self) private var model
    @Environment(Customisation.self) private var custom
    @Environment(ExternalAI.self) private var ai
    @AppStorage("userName") private var storedName = ""
    @State private var chapter: Int? = 0
    @State private var path: [AppModel.Route] = []
    @FocusState private var editingName: Bool

    var body: some View {
        let pages = custom.settings.visiblePages(.you)
        NavigationStack(path: $path) {
            PagedScreen(count: pages.count, page: $chapter) {
                EmptyView()
            } pages: {
                ForEach(Array(pages.enumerated()), id: \.element) { index, page in
                    Chapter(id: index) { content(for: page) }
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .navigationDestination(for: AppModel.Route.self) { destination($0) }
        }
        .onChange(of: model.route, initial: true) { open(model.route) }
    }

    private func open(_ route: AppModel.Route?) {
        guard let route else { return }
        path = [route]
        model.route = nil
    }

    @ViewBuilder private func destination(_ route: AppModel.Route) -> some View {
        switch route {
        case .medication: MedicationView()
        case .personalise: PersonaliseView()
        case .customise: CustomiseView()
        case .settings: SettingsView()
        case .actionButton: ActionButtonSetupView()
        case .ai: ExternalAIView()
        }
    }

    @ViewBuilder private func content(for page: PageKind) -> some View {
        switch page {
        case .youSupport: support
        case .youMore: more
        default: home
        }
    }

    private var displayName: String {
        let nick = custom.settings.nickname.trimmingCharacters(in: .whitespaces)
        if !nick.isEmpty { return nick }
        return model.userName.isEmpty ? "Hello" : model.userName
    }

    // MARK: Page 1: you

    @ViewBuilder private var home: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: 6) {
            Text("You").eyebrow()
            HeroText(text: displayName)
        }
        .reveal()

        if model.userName.isEmpty && custom.settings.nickname.isEmpty {
            TextField("What should we call you?", text: $model.userName)
                .focused($editingName)
                .textContentType(.givenName)
                .submitLabel(.done)
                .font(.subheadline)
                .foregroundStyle(Color.ink)
                .padding(.vertical, 6)
                .overlay(alignment: .bottom) { Rectangle().fill(Color.inkFaint.opacity(0.35)).frame(height: 0.5) }
                .onChange(of: model.userName) { storedName = model.userName }
                .reveal(delay: 0.04)
        }

        VStack(spacing: 0) {
            door(.medication, "Medication", medicationDetail, "pills")
            divider
            door(.personalise, "Personalise", "When you like to do things", "slider.horizontal.3")
        }
        .padding(.top, 18)
        .reveal(delay: 0.08)
    }

    private var medicationDetail: String {
        let count = model.medications.count
        let days = model.dayTypes.count
        if count == 0 { return "Add what you take" }
        return "\(count) \(count == 1 ? "medication" : "medications"), \(days) \(days == 1 ? "kind" : "kinds") of day"
    }

    // MARK: Page 2: support

    @ViewBuilder private var support: some View {
        Text("If things feel like too much").eyebrow().reveal()
        HeroText(text: "You don’t have to handle it alone", size: 24).reveal()
        NavigationLink {
            GetSupportView()
        } label: {
            Label("Get support", systemImage: "heart")
        }
        .buttonStyle(.glassProminent)
        .foregroundStyle(.onAccent)
        .font(.subheadline)
        .padding(.top, 8)
        .reveal(delay: 0.05)
    }

    // MARK: Last page: the fiddly bits

    @ViewBuilder private var more: some View {
        Text("Everything else").eyebrow().reveal()
        HeroText(text: "The fiddly bits", size: 30).reveal()
        Text("Settings, looks and extras. Nothing here is needed day to day.")
            .font(.footnote)
            .foregroundStyle(Color.inkSoft)
            .reveal(delay: 0.04)
        VStack(spacing: 0) {
            door(.actionButton, "One-press logging", "Action button, Back Tap, Siri", "button.vertical.left.press")
            divider
            door(.customise, "Customise", "Pages, looks, feel", "paintbrush")
            divider
            door(.settings, "Settings", "Account, plan, privacy", "gearshape")
            divider
            door(.ai, "Your own AI", ai.isReady && ai.config.enabled ? ai.config.provider.label : "Optional, off", "sparkle")
        }
        .padding(.top, 14)
        .reveal(delay: 0.08)
    }

    private func door(_ route: AppModel.Route, _ title: String, _ detail: String, _ symbol: String) -> some View {
        NavigationLink(value: route) {
            DoorRow(title: title, detail: detail, symbol: symbol)
        }
        .buttonStyle(.plain)
        .tapHaptic(.choose)
    }

    private var divider: some View {
        Rectangle().fill(Color.inkFaint.opacity(0.25)).frame(height: 0.5).padding(.leading, 38)
    }
}

/// Static, deterministic crisis routing (spec §8.2 rule 15). Never generated, never personalised.
/// Numbers must be re-verified by the clinical/legal reviewer before release.
struct GetSupportView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Get support").eyebrow()
                HeroText(text: "Free and confidential", size: 30)
                Text("If things feel like too much, you don’t have to handle it alone.")
                    .font(.subheadline)
                    .foregroundStyle(Color.inkSoft)
                RowGroup {
                    SupportRow(title: "Lifeline", number: "13 11 14", detail: "Crisis support, 24 hours. Or text 0477 13 11 14", url: "tel:131114")
                    SupportRow(title: "Emergency", number: "000", detail: "If you or someone else is in danger right now", url: "tel:000")
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your GP").eyebrow()
                        Text("A GP can help with how you’ve been feeling and with your ADHD care. You can bring your log export if you want.")
                            .font(.footnote).foregroundStyle(Color.inkSoft)
                    }
                    .padding(.vertical, 14)
                }
                .padding(.top, 12)
                Label("This page is the same for everyone. It isn’t generated by AI, and opening it isn’t recorded anywhere.", systemImage: "lock")
                    .font(.caption)
                    .foregroundStyle(Color.inkSoft)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background { SkyBackground(phase: model.skyPhase) }
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SupportRow: View {
    let title: String
    let number: String
    let detail: String
    let url: String

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).eyebrow()
                Text(number).figureFont(22).foregroundStyle(Color.ink)
                Text(detail).font(.caption).foregroundStyle(Color.inkSoft)
            }
            Spacer(minLength: 8)
            if let link = URL(string: url) {
                Link(destination: link) {
                    Image(systemName: "phone")
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .accessibilityLabel("Call \(title)")
            }
        }
        .padding(.vertical, 14)
    }
}
