import SwiftUI
import StoreKit
import EventKit
import UserNotifications
import FocusModel

/// Settings, grouped so the first screen is just a short list.
enum SettingsSection: String, CaseIterable, Identifiable, Hashable {
    case account, look, privacy, permissions, data, safety
    var id: Self { self }

    var title: String {
        switch self {
        case .account: "Account and Focus Plus"
        case .look: "Light or dark"
        case .privacy: "Privacy"
        case .permissions: "Permissions"
        case .data: "Your data"
        case .safety: "Safety and legal"
        }
    }

    var symbol: String {
        switch self {
        case .account: "person.crop.circle"
        case .look: "circle.lefthalf.filled"
        case .privacy: "hand.raised"
        case .permissions: "checkmark.shield"
        case .data: "tray"
        case .safety: "heart.text.square"
        }
    }
}

extension Store.Status {
    var summary: String {
        switch self {
        case .free: "Free"
        case .trial(let until): until.map { "Free trial until \($0.formatted(.dateTime.day().month()))" } ?? "Free trial"
        case .plus(let renews): renews.map { "Plus, renews \($0.formatted(.dateTime.day().month()))" } ?? "Plus"
        case .lapsed: "Free (Plus ended)"
        }
    }
}

/// The boring but important bits. The first screen stays calm: one-press logging (on purpose, it's
/// the one people come for) and a short list. Everything else is one tap deeper.
struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(Store.self) private var store
    @Environment(Customisation.self) private var custom

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Settings").eyebrow()
                    HeroText(text: Copy.line(.settingsIntro), size: 30)
                }

                NavigationLink { ActionButtonSetupView() } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "button.vertical.left.press").font(.title2).foregroundStyle(Color.zoneBest)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Log with one press").headingFont(.title3).foregroundStyle(Color.ink)
                            Text("Action button, Back Tap, Siri or Shortcuts.").font(.caption).foregroundStyle(Color.inkSoft)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(Color.inkSoft)
                    }
                    .veil(tint: .zoneBest, padding: 16)
                }
                .buttonStyle(.plain)
                .tapHaptic(.choose)

                VStack(spacing: 0) {
                    ForEach(SettingsSection.allCases) { section in
                        NavigationLink { SettingsPage(section: section) } label: {
                            DoorRow(title: section.title, detail: detail(section), symbol: section.symbol)
                        }
                        .buttonStyle(.plain)
                        .tapHaptic(.choose)
                        if section != SettingsSection.allCases.last { Rectangle().fill(Color.inkFaint.opacity(0.25)).frame(height: 0.5).padding(.leading, 38) }
                    }
                }
                .veil(padding: 12)

                Text("Focus \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""), made in Australia")
                    .font(.caption).foregroundStyle(Color.inkSoft)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .background { SkyBackground(phase: model.skyPhase) }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }

    private func detail(_ section: SettingsSection) -> String {
        switch section {
        case .account: store.status.summary
        case .look: custom.settings.appearance.label
        case .privacy: model.discreetMode ? "Discreet mode on" : "Discreet mode off"
        case .permissions: "Calendar and notifications"
        case .data: "Export or delete"
        case .safety: "Support, terms, the honest bit"
        }
    }
}

/// One settings category.
struct SettingsPage: View {
    let section: SettingsSection
    @Environment(AppModel.self) private var model
    @Environment(Store.self) private var store
    @Environment(AccountStore.self) private var accounts
    @Environment(Customisation.self) private var custom
    @Environment(ExternalAI.self) private var ai
    @State private var manage = false
    @State private var redeem = false
    @State private var upgrade = false
    @State private var confirmDelete = false
    @State private var confirmWipe = false
    @State private var notificationsOn = false
    @State private var note: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Settings").eyebrow()
                    HeroText(text: section.title, size: 30)
                }
                content
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .background { SkyBackground(phase: model.skyPhase) }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .manageSubscriptionsSheet(isPresented: $manage)
        .offerCodeRedemption(isPresented: $redeem)
        .sheet(isPresented: $upgrade) {
            TrialOfferView(context: .upgrade(reason: "Unlimited day types and categories.")) { upgrade = false }
                .background { SkyBackground(phase: model.skyPhase) }
        }
        .confirmationDialog("Delete your account?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete account and data", role: .destructive) {
                Haptics.shared.play(.acknowledge)
                Task { await accounts.deleteAccount(); DataExport.wipe(); note = "Your account is gone. Close and reopen Focus to start fresh." }
            }
        } message: {
            Text("This removes your account, your synced data and everything on this iPhone. It can’t be undone. A subscription keeps running until you cancel it in Settings, because Apple handles billing.")
        }
        .confirmationDialog("Delete everything on this iPhone?", isPresented: $confirmWipe, titleVisibility: .visible) {
            Button("Delete everything", role: .destructive) {
                Haptics.shared.play(.acknowledge)
                DataExport.wipe()
                note = "Done. Close and reopen Focus to start fresh."
            }
        } message: {
            Text("Medication, logs, plans and settings on this iPhone. It can’t be undone. Export first if you want a copy.")
        }
        .toast($note)
        .task {
            guard section == .permissions else { return }
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            notificationsOn = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
        }
    }

    @ViewBuilder private var content: some View {
        @Bindable var model = model
        @Bindable var custom = custom
        switch section {
        case .account:
            group("Account") {
                if let account = accounts.account {
                    info("Signed in with", value: account.method.rawValue.capitalized)
                    if let email = account.email { info("Email", value: email) }
                    action("Sign out", symbol: "rectangle.portrait.and.arrow.right") { accounts.signOut() }
                    action("Delete my account", symbol: "trash", role: .destructive) { confirmDelete = true }
                } else {
                    Text("Not signed in. Your plan stays on this phone only.").font(.subheadline).foregroundStyle(Color.inkSoft)
                }
            }
            group("Focus Plus") {
                info("Plan", value: store.status.summary)
                if !store.isPlus { action("See Plus", symbol: "sparkles") { upgrade = true } }
                action("Manage subscription", symbol: "creditcard") { manage = true }
                action("Restore purchases", symbol: "arrow.clockwise") { Task { await store.restore(); note = "Checked with Apple." } }
                action("Redeem a code", symbol: "gift") { redeem = true }
                Text("Payments, trials and refunds are all handled by Apple.").font(.caption).foregroundStyle(Color.inkSoft)
            }
        case .look:
            group(nil) {
                HStack {
                    Text("Light or dark").font(.subheadline).foregroundStyle(Color.ink)
                    Spacer()
                    Picker("Light or dark", selection: $custom.settings.appearance) {
                        ForEach(Appearance.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .tint(Color.ink)
                    .onChange(of: custom.settings.appearance) { Haptics.shared.play(.choose) }
                }
                NavigationLink { CustomiseView() } label: { linkRow("Everything else in Customise", symbol: "paintbrush") }
                    .buttonStyle(.plain)
            }
        case .privacy:
            group(nil) {
                Toggle(isOn: $model.discreetMode) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Discreet mode").font(.subheadline).foregroundStyle(Color.ink)
                        Text("No medicine names on the Lock Screen, in notifications, widgets or calendar titles.").font(.caption).foregroundStyle(Color.inkSoft)
                    }
                }
                .tint(Color.zoneBest)
                .onChange(of: model.discreetMode) { Haptics.shared.play(.toggle) }
                NavigationLink { PrivacyDetailView() } label: { linkRow("What leaves this phone", symbol: "lock") }.buttonStyle(.plain)
                NavigationLink { ExternalAIView() } label: { linkRow(ai.isReady ? "Your AI: \(ai.config.provider.label)" : "Connect your own AI", symbol: "sparkle") }
                    .buttonStyle(.plain)
            }
        case .permissions:
            group(nil) {
                HStack {
                    Text("Calendar").font(.subheadline).foregroundStyle(Color.ink)
                    Spacer()
                    if model.calendarAccess == .fullAccess {
                        Text("On").font(.caption).foregroundStyle(Color.inkSoft)
                    } else {
                        Button("Allow") { Task { await model.requestCalendarAccess() } }.buttonStyle(.glass).font(.caption)
                    }
                }
                HStack {
                    Text("Notifications").font(.subheadline).foregroundStyle(Color.ink)
                    Spacer()
                    if notificationsOn {
                        Text("On").font(.caption).foregroundStyle(Color.inkSoft)
                    } else {
                        Button("Allow") { Task { notificationsOn = await Reminders.requestPermission() } }.buttonStyle(.glass).font(.caption)
                    }
                }
                Text("At most five nudges a day, never naming a condition or a medicine.").font(.caption).foregroundStyle(Color.inkSoft)
            }
        case .data:
            group(nil) {
                ShareLink(item: DataExport.file(from: model), preview: SharePreview("Focus export")) {
                    linkRow("Export everything", symbol: "square.and.arrow.up")
                }
                .buttonStyle(.plain)
                action("Delete everything on this iPhone", symbol: "trash", role: .destructive) { confirmWipe = true }
            }
        case .safety:
            group(nil) {
                NavigationLink { MedicalNoticeView(standalone: true).background { SkyBackground(phase: model.skyPhase) } } label: {
                    linkRow("Not a medical device", symbol: "stethoscope")
                }
                .buttonStyle(.plain)
                NavigationLink { GetSupportView() } label: { linkRow("Get support", symbol: "heart") }.buttonStyle(.plain)
                Link(destination: URL(string: "https://focus.adhdslayer.au/terms")!) { linkRow("Terms", symbol: "doc.text") }
                Link(destination: URL(string: "https://focus.adhdslayer.au/privacy")!) { linkRow("Privacy policy", symbol: "hand.raised") }
            }
        }
    }

    private func group<Content: View>(_ title: String?, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let title { Text(title).eyebrow().padding(.bottom, 6) }
            VStack(alignment: .leading, spacing: 12) { content() }
                .frame(maxWidth: .infinity, alignment: .leading)
                .veil(padding: 16)
        }
    }

    private func info(_ label: String, value: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(Color.inkSoft)
            Spacer()
            Text(value).font(.subheadline).foregroundStyle(Color.ink)
        }
    }

    private func action(_ title: String, symbol: String, role: ButtonRole? = nil, perform: @escaping () -> Void) -> some View {
        Button(role: role) { Haptics.shared.play(.tap); perform() } label: {
            Label(title, systemImage: symbol).font(.subheadline)
                .foregroundStyle(Color.ink)
        }
        .buttonStyle(.plain)
    }

    private func linkRow(_ title: String, symbol: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).foregroundStyle(Color.zoneBest).frame(width: 22)
            Text(title).font(.subheadline).foregroundStyle(Color.ink)
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Color.inkSoft)
        }
        .contentShape(.rect)
    }
}

// MARK: - One-press logging

struct ActionButtonSetupView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL
    @Environment(\.motionIsCalm) private var calm
    @State private var press = false
    @State private var result: String?

    private let steps = [
        "Open the Settings app, then Action Button.",
        "Swipe along to Shortcut, then tap Choose a Shortcut.",
        "Pick “Log my meds” from Focus.",
        "Press and hold the Action button. Everything you’ve set for about now gets logged, and your phone taps twice.",
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("One press").eyebrow()
                HeroText(text: "Log with the Action button", size: 32)
                phone
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .firstTextBaseline, spacing: 14) {
                        Text("\(index + 1)").figureFont(17).foregroundStyle(Color.zoneBest).frame(width: 18)
                        Text(step).font(.body).foregroundStyle(Color.ink).fixedSize(horizontal: false, vertical: true)
                    }
                }
                HStack(spacing: 10) {
                    Button("Open Settings") { if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) } }
                        .buttonStyle(.glassProminent).foregroundStyle(.onAccent)
                    Button("Try it now") {
                        Task {
                            let outcome = await model.logAllDue(origin: .button)
                            result = outcome.spoken
                        }
                    }
                    .buttonStyle(.glass)
                }
                .font(.subheadline)
                if let result { Text(result).font(.footnote).foregroundStyle(Color.ink) }

                VStack(alignment: .leading, spacing: 8) {
                    Text("No Action button?").eyebrow()
                    Text("Use Back Tap: Settings, Accessibility, Touch, Back Tap, then Double Tap and choose “Log my meds”. Two taps on the back of your phone and it’s done.")
                        .font(.subheadline).foregroundStyle(Color.inkSoft)
                    Text("Or just say “Log my meds in Focus” to Siri.").font(.subheadline).foregroundStyle(Color.inkSoft)
                }
                .veil(padding: 16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .background { SkyBackground(phase: model.skyPhase) }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .onAppear { if !calm { withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) { press = true } } }
    }

    private var phone: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Color.ink.opacity(0.5), lineWidth: 1.5).frame(width: 110, height: 200)
            Capsule().fill(Color.zoneBest).frame(width: 5, height: 22).offset(x: press ? -3 : -6, y: 44)
                .shadow(color: .zoneBest.opacity(press ? 0.8 : 0), radius: 8)
            Image(systemName: "checkmark.circle.fill").font(.largeTitle).foregroundStyle(Color.zoneBest)
                .opacity(press ? 1 : 0.2).offset(x: 37, y: 78)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .accessibilityHidden(true)
        .onChange(of: press) { if press { Haptics.shared.play(.logged) } }
    }
}

// MARK: - Privacy detail

struct PrivacyDetailView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("What leaves this phone").eyebrow()
                HeroText(text: "Almost nothing", size: 32)
                RowGroup {
                    InfoRow(title: "Medication, doses, check-ins") { ValueChip(text: "Only on this iPhone") }
                    InfoRow(title: "Your focus pattern") { ValueChip(text: "Only on this iPhone") }
                    InfoRow(title: "Apple Health") { ValueChip(text: "Read only, stays here") }
                    InfoRow(title: "Calendar") { ValueChip(text: "Read here, never uploaded") }
                    InfoRow(title: "Apple Intelligence") { ValueChip(text: "On the phone") }
                    InfoRow(title: "Moving to a new phone") { ValueChip(text: "End-to-end encrypted") }
                    InfoRow(title: "Your own AI") { ValueChip(text: "Only what you allow") }
                    InfoRow(title: "Ads and trackers") { ValueChip(text: "None, ever") }
                }
                Text("Health information never goes into iCloud. When you sync to a new phone, it travels encrypted with a key only your devices hold, so we can’t read it.")
                    .font(.footnote).foregroundStyle(Color.inkSoft)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .background { SkyBackground(phase: model.skyPhase) }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }
}

// MARK: - Your own AI

struct ExternalAIView: View {
    @Environment(ExternalAI.self) private var ai
    @Environment(AppModel.self) private var model
    @State private var key = ""
    @State private var warning = false
    @State private var testing = false
    @State private var testResult: String?
    @State private var ask = false

    var body: some View {
        @Bindable var ai = ai
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Your own AI").eyebrow()
                HeroText(text: "Bring the AI you already use", size: 30)
                Text("Everything in Focus runs on Apple Intelligence on your phone, and keeps doing so. Connecting your own AI just adds somewhere to talk things through.")
                    .font(.subheadline).foregroundStyle(Color.inkSoft)

                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: Binding(get: { ai.config.enabled }, set: { on in
                        if on && ai.config.acceptedWarningAt == nil { warning = true } else { ai.config.enabled = on }
                        Haptics.shared.play(.toggle)
                    })) {
                        Text("Use my own AI").font(.subheadline).foregroundStyle(Color.ink)
                    }
                    .tint(Color.zoneBest)
                    Picker("Provider", selection: $ai.config.provider) {
                        ForEach(AIProvider.allCases) { Text($0.label).tag($0) }
                    }
                    .onChange(of: ai.config.provider) { ai.config.model = ai.config.provider.defaultModel }
                    HStack {
                        Text("Model").font(.subheadline).foregroundStyle(Color.inkSoft)
                        TextField("model name", text: $ai.config.model).multilineTextAlignment(.trailing).font(.subheadline)
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                    }
                    if ai.config.provider == .custom {
                        TextField("https://your-endpoint/v1", text: $ai.config.customEndpoint)
                            .font(.subheadline).textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                    }
                    HStack(spacing: 10) {
                        SecureField(ai.hasKey ? "Key saved in your Keychain" : "Paste your API key", text: $key)
                            .font(.subheadline).textContentType(.password)
                        Button(ai.hasKey && key.isEmpty ? "Remove" : "Save") {
                            Haptics.shared.play(.tap)
                            if ai.hasKey && key.isEmpty { ai.setKey(nil) } else { ai.setKey(key); key = "" }
                        }
                        .buttonStyle(.glass).font(.caption)
                    }
                    Text("Your key stays in this iPhone’s Keychain. We never see it.").font(.caption).foregroundStyle(Color.inkSoft)
                }
                .veil(padding: 16)

                VStack(alignment: .leading, spacing: 10) {
                    Text("What it may see").eyebrow()
                    Toggle("Task names", isOn: $ai.config.shareTaskNames).tint(Color.zoneBest)
                    Toggle("Times", isOn: $ai.config.shareTimes).tint(Color.zoneBest)
                    Label("Never: medication, doses, check-ins, health data, your name or your account.", systemImage: "lock")
                        .font(.caption).foregroundStyle(Color.inkSoft)
                }
                .font(.subheadline)
                .veil(padding: 16)

                HStack(spacing: 10) {
                    Button(testing ? "Testing…" : "Test it") {
                        Task {
                            testing = true
                            defer { testing = false }
                            do { testResult = try await ai.ask("Say hello in five words.", context: "") }
                            catch { testResult = error.localizedDescription }
                        }
                    }
                    .buttonStyle(.glass)
                    .disabled(!ai.isReady || testing)
                    Button("Ask it something") { ask = true }
                        .buttonStyle(.glassProminent).foregroundStyle(.onAccent)
                        .disabled(!ai.isReady)
                }
                .font(.subheadline)
                if let testResult { Text(testResult).font(.footnote).foregroundStyle(Color.ink) }

                if ai.hasKey || ai.config.enabled {
                    Button("Disconnect and forget my key", systemImage: "xmark.circle") { ai.disconnect(); Haptics.shared.play(.acknowledge) }
                        .buttonStyle(.glass).font(.subheadline)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.immediately)
        .background { SkyBackground(phase: model.skyPhase) }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .sheet(isPresented: $warning) { AIWarningSheet().presentationDetents([.large]) }
        .sheet(isPresented: $ask) { AskAISheet().presentationDetents([.medium, .large]) }
    }
}

/// Facts, not scare words. The fine print on liability lives in the Terms.
struct AIWarningSheet: View {
    @Environment(ExternalAI.self) private var ai
    @Environment(\.dismiss) private var dismiss

    private let points: [(String, String)] = [
        ("building.2", "Your AI provider isn’t part of Focus. What it says, and what it does with what you send it, is up to them and their terms."),
        ("exclamationmark.bubble", "We can’t check or stand behind its answers, so we’re not responsible for them. Treat it like advice from a clever stranger: sometimes great, sometimes confidently wrong."),
        ("lock", "Focus never sends it your medication, doses, check-ins, health data, name or account. Only task names and times, and only if you allow them."),
        ("dollarsign.circle", "Some free plans use what you send to train their models. Paid keys usually don’t. It’s worth checking their terms."),
        ("checkmark.seal", "Everything in Focus keeps working without it. You can disconnect any time."),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Before you connect").eyebrow()
                HeroText(text: "Your AI, your call", size: 30)
                ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                    HStack(alignment: .firstTextBaseline, spacing: 14) {
                        Image(systemName: point.0).foregroundStyle(Color.honey).frame(width: 22)
                        Text(point.1).font(.body).foregroundStyle(Color.ink).fixedSize(horizontal: false, vertical: true)
                    }
                }
                HStack(spacing: 10) {
                    Button("I understand, connect it") {
                        Haptics.shared.play(.acknowledge)
                        ai.config.acceptedWarningAt = .now
                        ai.config.enabled = true
                        dismiss()
                    }
                    .buttonStyle(.glassProminent).foregroundStyle(.onAccent)
                    Button("Not now") { dismiss() }.buttonStyle(.glass)
                }
                .font(.subheadline)
            }
            .padding(24)
        }
        .onAppear { Haptics.shared.play(.caution) }
    }
}

/// Ask your own AI one thing about today. It sees only what you allowed.
struct AskAISheet: View {
    @Environment(ExternalAI.self) private var ai
    @Environment(AppModel.self) private var model
    @State private var question = ""
    @State private var answer: String?
    @State private var working = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Ask \(ai.config.provider.label)").eyebrow()
            TextField("What should I do first?", text: $question, axis: .vertical)
                .font(.body).lineLimit(2...4)
                .padding(14).pill()
            Button(working ? "Asking…" : "Ask") {
                Task {
                    working = true
                    defer { working = false }
                    let context = model.contextForExternalAI(names: ai.config.shareTaskNames, times: ai.config.shareTimes)
                    do { answer = try await ai.ask(question, context: context) } catch { answer = error.localizedDescription }
                    Haptics.shared.play(.land)
                }
            }
            .buttonStyle(.glassProminent).foregroundStyle(.onAccent).font(.subheadline)
            .disabled(question.isEmpty || working)
            if let answer {
                ScrollView { Text(answer).font(.body).foregroundStyle(Color.ink).frame(maxWidth: .infinity, alignment: .leading) }
                Text("From your own AI, not from Focus.").font(.caption).foregroundStyle(Color.inkSoft)
            }
            Spacer()
        }
        .padding(24)
    }
}

// MARK: - Export and wipe

enum DataExport {
    /// Everything the person has put into Focus on this phone, as readable JSON.
    static func file(from model: AppModel) -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Focus export.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        struct Export: Encodable {
            let exportedAt: Date
            let medications: [Medication]
            let dayTypes: [DayType]
            let personalisation: Personalisation
            let tuning: AppModel.Tuning
            let dosesToday: [String]
        }
        let export = Export(exportedAt: .now, medications: model.medications, dayTypes: model.dayTypes,
                            personalisation: model.personalisation, tuning: model.tuning,
                            dosesToday: model.todaysDoses.map { $0.takenAt.formatted(.iso8601) })
        try? encoder.encode(export).write(to: url, options: .completeFileProtection)
        return url
    }

    static func wipe() {
        try? FileManager.default.removeItem(at: MedicationFile.url)
        if let domain = Bundle.main.bundleIdentifier { UserDefaults.standard.removePersistentDomain(forName: domain) }
        Keychain.set(nil, for: "account")
        Keychain.set(nil, for: "externalAIKey")
    }
}

