import SwiftUI
import StoreKit
import AuthenticationServices
import FoundationModels

/// First launch, in five beats, each one screen: the start animation, a hello, the medical notice,
/// an account, and the free month. Then straight to the home page, where a skippable tour points
/// at the few things worth knowing. No long setup wizard: attention is precious.
struct OnboardingFlow: View {
    enum Step: Int { case splash, greeting, notice, account, trial }

    let finish: () -> Void
    @State private var step: Step = .splash
    @Environment(\.motionIsCalm) private var calm
    @Environment(AccountStore.self) private var accounts

    var body: some View {
        ZStack {
            SkyBackground(phase: step == .splash ? .night : .dawn)
            Group {
                switch step {
                case .splash: SplashView { go(.greeting) }
                case .greeting: GreetingView { go(.notice) }
                case .notice: MedicalNoticeView(standalone: false) { go(.account) }
                case .account: AccountView { go(.trial) }
                case .trial: TrialOfferView(context: .onboarding) { finish() }
                }
            }
            .transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: calm ? 0 : 24)),
                                    removal: .opacity.combined(with: .offset(y: calm ? 0 : -16))))
            .id(step)
        }
        // A sign-in link opened from Mail, even after the app was closed while the email arrived:
        // once the honest bit has been accepted, go straight to the account step to finish.
        .onOpenURL { url in
            guard accounts.receive(url), step.rawValue < Step.account.rawValue,
                  UserDefaults.standard.integer(forKey: "noticeAcceptedVersion") >= MedicalNoticeView.version else { return }
            go(.account)
        }
    }

    private func go(_ next: Step) {
        withAnimation(.gentle(calm, .smooth(duration: 0.7))) { step = next }
    }
}

// MARK: - 1. Start animation

/// A thin champagne ring draws itself, a point of light settles into it, the name writes in, and
/// the phone swells along with it. Tap anywhere to skip.
struct SplashView: View {
    let done: () -> Void
    @Environment(\.motionIsCalm) private var calm
    @State private var ring: CGFloat = 0
    @State private var dot = false
    @State private var name = 0.0
    @State private var tagline = false
    @State private var bloom = false

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle().stroke(Color.track, lineWidth: 1)
                Circle()
                    .trim(from: 0, to: ring)
                    .stroke(AngularGradient(colors: [.zoneWarm, .zoneBest, .honey, .zoneBest], center: .center),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .shadow(color: .zoneBest.opacity(bloom ? 0.7 : 0), radius: bloom ? 18 : 0)
                Circle()
                    .fill(Color.zoneBest)
                    .frame(width: dot ? 10 : 2, height: dot ? 10 : 2)
                    .opacity(dot ? 1 : 0)
                    .shadow(color: .zoneBest, radius: dot ? 8 : 0)
            }
            .frame(width: 96, height: 96)
            HeroText(text: "Focus", size: 44, reveal: name)
            Text(Copy.line(.splashTagline))
                .font(.subheadline)
                .foregroundStyle(Color.inkSoft)
                .opacity(tagline ? 1 : 0)
                .offset(y: tagline || calm ? 0 : 6)
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .contentShape(.rect)
        .onTapGesture { done() }
        .task {
            guard !calm else {
                ring = 1; dot = true; name = 1; tagline = true
                try? await Task.sleep(for: .seconds(1.2)); done(); return
            }
            Haptics.shared.play(.splash)
            withAnimation(.easeInOut(duration: 1.4)) { ring = 1 }
            withAnimation(.bouncy(duration: 0.6).delay(1.35)) { dot = true }
            withAnimation(.easeOut(duration: 0.5).delay(1.6)) { bloom = true }
            withAnimation(.easeOut(duration: 1.0).delay(1.6)) { name = 1 }
            withAnimation(.smooth(duration: 0.6).delay(2.3)) { tagline = true }
            withAnimation(.easeOut(duration: 0.8).delay(2.2)) { bloom = false }
            try? await Task.sleep(for: .seconds(3.6))
            done()
        }
    }
}

// MARK: - 2. Hello

struct GreetingView: View {
    let next: () -> Void
    @Environment(\.motionIsCalm) private var calm
    @State private var shown = 0.0
    @State private var rest = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()
            HeroText(text: Copy.line(.greetingTitle), size: 40, reveal: shown)
            Text(Copy.line(.greetingBody))
                .headingFont(.title3)
                .foregroundStyle(Color.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(rest ? 1 : 0)
            Spacer()
            Button("Let’s go", systemImage: "arrow.right") { Haptics.shared.play(.tap); next() }
                .buttonStyle(.glassProminent)
                .foregroundStyle(.onAccent)
                .font(.subheadline)
                .opacity(rest ? 1 : 0)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 48)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            Haptics.shared.play(.land)
            withAnimation(.gentle(calm, .easeOut(duration: 1.0))) { shown = 1 }
            withAnimation(.gentle(calm, .smooth(duration: 0.6).delay(0.8))) { rest = true }
            if calm { shown = 1; rest = true }
        }
    }
}

// MARK: - 3. The medical notice

/// Shown once before sign-up and always available from Settings. Plain words; no small print games.
struct MedicalNoticeView: View {
    var standalone: Bool
    var accepted: () -> Void = {}
    @AppStorage("noticeAcceptedVersion") private var acceptedVersion = 0
    static let version = 1
    @Environment(\.motionIsCalm) private var calm
    @State private var shown = false

    private let points: [(String, String)] = [
        ("calendar.badge.clock", "Focus is a planner. It is not a medical device."),
        ("stethoscope", "It doesn’t diagnose, treat, monitor or prevent ADHD or any other condition."),
        ("pills", "It never tells you what medication to take, how much, or when. Your prescriber decides that. The app only plans your day around what you tell it."),
        ("person.2", "If you’re unsure about your medication or how you’re feeling, talk to your doctor or pharmacist."),
        ("phone", "If you’re in danger or crisis, call 000. You can also call Lifeline on 13 11 14, any time."),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Before we start").eyebrow()
                HeroText(text: "The honest bit", size: 34)
                ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                    HStack(alignment: .firstTextBaseline, spacing: 14) {
                        Image(systemName: point.0)
                            .font(.callout)
                            .foregroundStyle(Color.zoneBest)
                            .frame(width: 22)
                            .accessibilityHidden(true)
                        Text(point.1)
                            .font(.body)
                            .foregroundStyle(Color.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .opacity(shown ? 1 : 0)
                    .offset(y: shown || calm ? 0 : 10)
                    .animation(.gentle(calm, .smooth.delay(0.15 + Double(index) * 0.12)), value: shown)
                }
                if !standalone {
                    Button {
                        Haptics.shared.play(.acknowledge)
                        acceptedVersion = Self.version
                        accepted()
                    } label: {
                        Label("I understand", systemImage: "checkmark")
                    }
                    .buttonStyle(.glassProminent)
                    .foregroundStyle(.onAccent)
                    .font(.subheadline)
                    .padding(.top, 12)
                } else if acceptedVersion >= Self.version {
                    Label("You agreed to this when you started.", systemImage: "checkmark.seal")
                        .font(.footnote)
                        .foregroundStyle(Color.inkSoft)
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 60)
        }
        .scrollIndicators(.hidden)
        .onAppear { shown = true; if !standalone { Haptics.shared.play(.nudge) } }
    }
}

// MARK: - 4. Account

struct AccountView: View {
    /// Replaces the onboarding heading when signing in again from Settings.
    var heading: String?
    let next: () -> Void
    @Environment(AccountStore.self) private var accounts
    @Environment(\.colorScheme) private var scheme
    @Environment(\.motionIsCalm) private var calm
    @AppStorage("confirmedAdult") private var adult = false
    @AppStorage(AccountStore.adultConfirmedAtKey) private var adultConfirmedAt = 0.0
    @State private var email = ""
    @State private var code = ""
    @State private var showEmail = false
    @State private var error: String?
    @State private var offerNewLink = false
    @State private var working = false

    var body: some View {
        ScrollView {
            Group {
                if let sentTo = accounts.pendingEmail {
                    checkEmail(sentTo)
                } else {
                    signInChoices
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 60)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.immediately)
        .onOpenURL { accounts.receive($0) }
        .task(id: accounts.pendingLinkToken) { await verifyOpenedLink() }
    }

    // MARK: Choosing a way in

    private var signInChoices: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your account").eyebrow()
            HeroText(text: heading ?? Copy.line(.accountTitle), size: 32)
            Text(heading == nil ? Copy.line(.accountBody) : "Use the same way you signed in before.")
                .font(.subheadline)
                .foregroundStyle(Color.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            Toggle(isOn: $adult) {
                Text("I’m 18 or older").font(.subheadline).foregroundStyle(Color.ink)
            }
            .tint(Color.zoneBest)
            .onChange(of: adult) {
                Haptics.shared.play(.toggle)
                // Only when it was confirmed, never a birth date. Sent with sign-up.
                adultConfirmedAt = adult ? Date.now.timeIntervalSince1970 : 0
                if adult { Task { await verifyOpenedLink() } }
            }
            .padding(.top, 8)

            VStack(alignment: .leading, spacing: 10) {
                SignInWithAppleButton(.continue) { accounts.configure($0) } onCompletion: { result in
                    Task { await run { try await accounts.completeApple(result) } }
                }
                .signInWithAppleButtonStyle(scheme == .dark ? .white : .black)
                .frame(height: 48)
                .clipShape(.capsule)

                Button { Task { await run { try await accounts.signInWithGoogle() } } } label: {
                    Label("Continue with Google", systemImage: "g.circle").frame(maxWidth: .infinity, minHeight: 34)
                }
                .buttonStyle(.glass)

                Button { withAnimation(.gentle(calm)) { showEmail.toggle() }; Haptics.shared.play(.tap) } label: {
                    Label("Continue with email", systemImage: "envelope").frame(maxWidth: .infinity, minHeight: 34)
                }
                .buttonStyle(.glass)

                if showEmail {
                    emailForm.transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .font(.subheadline)
            .disabled(!adult || working)
            .opacity(adult ? 1 : 0.45)
            .padding(.top, 6)

            if !adult {
                Text("Focus is for adults for now.").font(.footnote).foregroundStyle(Color.inkSoft)
            }
            errorLine
            Text("By continuing you agree to the Terms and the Privacy Policy. You can delete your account any time in Settings.")
                .font(.caption)
                .foregroundStyle(Color.inkSoft)
                .padding(.top, 8)
        }
    }

    private var emailForm: some View {
        HStack(spacing: 10) {
            TextField(text: $email, prompt: Text(verbatim: "you@example.com").foregroundStyle(Color.inkSoft)) { Text("Email") }
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.send)
                .onSubmit { sendLink() }
                .padding(.horizontal, 18)
                .frame(minHeight: 48)
                .pill()
            Button("Send link") { sendLink() }
                .buttonStyle(.glassProminent)
                .foregroundStyle(.onAccent)
        }
    }

    // MARK: Check your email

    private func checkEmail(_ address: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your account").eyebrow()
            HeroText(text: "Check your email.", size: 32)
            Text("We sent a link to \(address). Tap it on this iPhone and you’re in.")
                .font(.subheadline)
                .foregroundStyle(Color.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 10) {
                Text("Or type the 6-digit code from the email").font(.footnote).foregroundStyle(Color.inkSoft)
                OneTimeCodeField(code: $code) { typed in
                    Task { await run { try await accounts.finishEmail(code: typed) } }
                }
                .disabled(working)
                if !accounts.usesServer {
                    Text("This build has no server, so any six digits will do.").font(.caption).foregroundStyle(Color.inkSoft)
                }
            }
            .padding(.top, 8)

            errorLine
            resendLine

            Button("Use a different email") {
                Haptics.shared.play(.tap)
                error = nil
                offerNewLink = false
                code = ""
                email = address
                showEmail = true
                accounts.useDifferentEmail()
            }
            .buttonStyle(.plain)
            .font(.subheadline)
            .foregroundStyle(Color.ink)
        }
    }

    /// "You can ask for a new link in 0:42." becomes a button once 60 seconds have passed, or straight
    /// away when the last link can't be used any more.
    private var resendLine: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let waited = accounts.emailSentAt.map { context.date.timeIntervalSince($0) } ?? .infinity
            let left = Int((accounts.resendAfter - waited).rounded(.up))
            if left > 0 && !offerNewLink {
                Text("You can ask for a new link in \(left / 60):\(String(format: "%02d", left % 60)).")
                    .font(.footnote)
                    .foregroundStyle(Color.inkSoft)
                    .monospacedDigit()
            } else {
                Button("Send a new link") {
                    Task {
                        await run(signsIn: false) { try await accounts.resendEmail() }
                        if error == nil { code = ""; offerNewLink = false }
                    }
                }
                .buttonStyle(.glass)
                .font(.subheadline)
                .disabled(working)
            }
        }
    }

    @ViewBuilder private var errorLine: some View {
        if let error {
            Label(error, systemImage: "exclamationmark.circle").font(.footnote).foregroundStyle(Color.ink)
        }
    }

    // MARK: Actions

    private func sendLink() {
        Task {
            await run(signsIn: false) { try await accounts.startEmail(email) }
            if accounts.pendingEmail != nil { Haptics.shared.play(.land) }
        }
    }

    /// A link opened from Mail finishes here, once "I'm 18 or older" is on.
    private func verifyOpenedLink() async {
        guard accounts.pendingLinkToken != nil, adult, !working else { return }
        await run { try await accounts.finishEmailLink() }
    }

    /// `signsIn` is false for sending a link, which never finishes a sign-in on its own.
    private func run(signsIn: Bool = true, _ action: () async throws -> Void) async {
        working = true
        defer { working = false }
        do {
            try await action()
            error = nil
            offerNewLink = false
            if signsIn, accounts.isSignedIn { Haptics.shared.play(.success); next() }
        } catch let e as AccountStore.AuthError {
            switch e {
            case .cancelled:
                break
            case .adultConfirmationNeeded:
                // Back to the toggle: it shows "Focus is for adults for now." until it's on again.
                adult = false
                error = nil
                Haptics.shared.play(.caution)
            default:
                error = e.errorDescription
                offerNewLink = e.offersNewLink
                if e == .codeMismatch || e == .tooManyCodes { code = "" }
                Haptics.shared.play(.caution)
            }
        } catch {
            self.error = "That didn’t work. Try again?"
            Haptics.shared.play(.caution)
        }
    }
}

/// Six single-digit boxes over one invisible field, so the keyboard's one-time code suggestion,
/// paste and VoiceOver all work on the whole code at once.
struct OneTimeCodeField: View {
    @Binding var code: String
    let complete: (String) -> Void
    @FocusState private var focused: Bool

    var body: some View {
        let digits = Array(code)
        HStack(spacing: 8) {
            ForEach(0..<6, id: \.self) { index in
                let isNext = focused && index == min(digits.count, 5)
                Text(index < digits.count ? String(digits[index]) : " ")
                    .figureFont(22)
                    .foregroundStyle(Color.ink)
                    .frame(width: 44, height: 54)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.veil))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(isNext ? Color.zoneBest : Color.veilStroke, lineWidth: isNext ? 1.5 : 0.5))
            }
        }
        .accessibilityHidden(true)
        .overlay {
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($focused)
                .foregroundStyle(.clear)
                .tint(.clear)
                .accessibilityLabel("Six-digit code")
                .accessibilityValue(code)
        }
        .contentShape(.rect)
        .onTapGesture { focused = true }
        .onChange(of: code) { old, new in
            let cleaned = String(new.filter(\.isNumber).prefix(6))
            if cleaned != new { code = cleaned; return }
            if cleaned.count == 6, old.count < 6 {
                focused = false
                complete(cleaned)
            }
        }
    }
}

// MARK: - 5. The free month

/// The paid plan comes first, with an honest reason and an easy way out. Every price and period is
/// Apple's own, straight from StoreKit, and the renewal terms sit right under the button.
struct TrialOfferView: View {
    enum Context { case onboarding, upgrade(reason: String) }
    let context: Context
    let done: () -> Void

    @Environment(Store.self) private var store
    @Environment(AccountStore.self) private var accounts
    @Environment(\.motionIsCalm) private var calm
    @Environment(\.openURL) private var openURL
    @State private var yearly = true
    @State private var appeared = false
    @State private var shimmer = false
    @State private var working = false
    @State private var message: String?

    private var selected: StoreKit.Product? { yearly ? (store.yearly ?? store.monthly) : (store.monthly ?? store.yearly) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if case .upgrade(let reason) = context {
                    Text(reason).font(.subheadline).foregroundStyle(Color.inkSoft)
                }
                Text("Focus Plus").eyebrow()
                HeroText(text: Copy.line(.trialTitle), size: 32)
                Text(Copy.line(.trialWhy))
                    .headingFont(.title3)
                    .foregroundStyle(Color.ink)
                    .fixedSize(horizontal: false, vertical: true)

                trialBadge

                VStack(alignment: .leading, spacing: 10) {
                    benefit("infinity", "As many day types as your life has")
                    benefit("square.grid.2x2", "As many activity categories as you want")
                    benefit("heart", "Everything else stays free, forever")
                }
                .padding(.vertical, 6)
                .opacity(appeared ? 1 : 0)
                .animation(.gentle(calm, .smooth.delay(0.25)), value: appeared)

                HStack(spacing: 10) {
                    planCard(title: "Yearly", product: store.yearly, isSelected: yearly) { yearly = true }
                    planCard(title: "Monthly", product: store.monthly, isSelected: !yearly) { yearly = false }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared || calm ? 0 : 20)
                .animation(.gentle(calm, .bouncy.delay(0.35)), value: appeared)

                Button {
                    Task { await start() }
                } label: {
                    Label(store.trialEligible ? "Start my free month" : "Get Plus", systemImage: "sparkles")
                }
                .buttonStyle(.glassProminent)
                .foregroundStyle(.onAccent)
                .font(.subheadline)
                .disabled(working || (selected == nil && !Self.demoAllowed))

                terms

                Button(context.isOnboarding ? "Not now, use the free plan" : "Not now") {
                    Haptics.shared.play(.tap)
                    done()
                }
                .font(.subheadline)
                .foregroundStyle(Color.ink)
                .buttonStyle(.glass)
                .padding(.top, 4)

                if let message { Text(message).font(.footnote).foregroundStyle(Color.ink) }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 56)
        }
        .scrollIndicators(.hidden)
        .onAppear {
            appeared = true
            if !calm { withAnimation(.linear(duration: 2.4).repeatForever(autoreverses: false)) { shimmer = true } }
        }
        .task { await store.refresh() }
    }

    private var trialBadge: some View {
        Text(store.trialLength.map { "Free for \($0)" } ?? "Your first month is free")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Color.ink)
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background {
                Capsule().fill(Color.zoneBest.opacity(0.18))
                    .overlay {
                        LinearGradient(colors: [.clear, .white.opacity(0.45), .clear], startPoint: .leading, endPoint: .trailing)
                            .frame(width: 60)
                            .offset(x: shimmer ? 160 : -160)
                            .blendMode(.softLight)
                    }
                    .clipShape(.capsule)
            }
            .overlay(Capsule().strokeBorder(Color.zoneBest.opacity(0.6), lineWidth: 0.75))
    }

    private func benefit(_ symbol: String, _ text: String) -> some View {
        Label { Text(text).font(.subheadline).foregroundStyle(Color.ink) } icon: {
            Image(systemName: symbol).foregroundStyle(Color.zoneBest)
        }
    }

    private func planCard(title: String, product: StoreKit.Product?, isSelected: Bool, select: @escaping () -> Void) -> some View {
        Button {
            Haptics.shared.play(.choose)
            withAnimation(.gentle(calm, .snappy)) { select() }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).eyebrow(isSelected ? .ink : .inkSoft)
                Text(product?.displayPrice ?? "…").figureFont(24).foregroundStyle(Color.ink)
                Text(product.map { $0.subscription?.subscriptionPeriod.unit == .year ? "a year" : "a month" } ?? "Price from the App Store")
                    .font(.caption).foregroundStyle(Color.inkSoft)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(isSelected ? Color.zoneBest.opacity(0.16) : Color.veil))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(isSelected ? Color.zoneBest : Color.veilStroke, lineWidth: isSelected ? 1.5 : 0.5))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var terms: some View {
        let price = selected.map { "\($0.displayPrice) \($0.subscription?.subscriptionPeriod.unit == .year ? "a year" : "a month")" } ?? "the price shown by the App Store"
        let trial = store.trialEligible ? "Free for \(store.trialLength ?? "the trial period"), then \(price). " : "\(price.prefix(1).uppercased() + price.dropFirst()). "
        VStack(alignment: .leading, spacing: 8) {
            Text(trial + "Renews automatically until you cancel. Cancel any time in Settings, at least 24 hours before the trial ends, and you won’t be charged. We’ll remind you two days before it ends. Payment is handled by Apple.")
                .font(.caption)
                .foregroundStyle(Color.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 16) {
                Button("Restore purchases") { Task { await store.restore(); Haptics.shared.play(.tap) } }
                Link("Terms", destination: URL(string: "https://focus.adhdslayer.au/terms")!)
                Link("Privacy", destination: URL(string: "https://focus.adhdslayer.au/privacy")!)
            }
            .font(.caption)
            .foregroundStyle(Color.ink)
            .buttonStyle(.plain)
        }
    }

    /// Builds with no App Store products (simulator, no StoreKit configuration) can still walk through.
    static var demoAllowed: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }

    private func start() async {
        working = true
        defer { working = false }
        guard let product = selected else {
            if Self.demoAllowed {
                message = "Demo build: no App Store products here, so nothing was bought."
                Haptics.shared.play(.success)
                try? await Task.sleep(for: .seconds(1.2))
                done()
            }
            return
        }
        switch await store.purchase(product, account: accounts.account?.id) {
        case .purchased:
            Haptics.shared.play(.success)
            if case .trial(let until) = store.status, let until { await Reminders.scheduleTrialEnding(on: until) }
            done()
        case .pending: message = "Waiting on Apple to approve that. You can keep going."
        case .cancelled: break
        case .failed(let why): message = why; Haptics.shared.play(.caution)
        }
    }
}

private extension TrialOfferView.Context {
    var isOnboarding: Bool { if case .onboarding = self { true } else { false } }
}

// MARK: - iPhones that can't run it

/// Focus's smart parts run on Apple Intelligence on the phone itself, so iPhones without it can't
/// use the app. Kind and specific about why, and what to do if it's just switched off.
struct DeviceGateView: View {
    let availability: SystemLanguageModel.Availability
    let proceed: () -> Void
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()
            Text("Apple Intelligence").eyebrow()
            switch availability {
            case .unavailable(.deviceNotEligible):
                HeroText(text: "This iPhone can’t run Focus", size: 34)
                Text("Focus does its thinking on your iPhone itself, which needs Apple Intelligence. That means an iPhone 15 Pro or newer. Sorry, we know that’s annoying.")
                    .font(.body).foregroundStyle(Color.inkSoft)
            case .unavailable(.appleIntelligenceNotEnabled):
                HeroText(text: "Switch on Apple Intelligence", size: 34)
                Text("Focus does its thinking on your iPhone itself. Turn on Apple Intelligence in Settings, then come back.")
                    .font(.body).foregroundStyle(Color.inkSoft)
                HStack {
                    Button("Open Settings") { if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) } }
                        .buttonStyle(.glassProminent).foregroundStyle(.onAccent)
                    Button("Check again", action: proceed).buttonStyle(.glass)
                }
                .font(.subheadline)
            default:
                HeroText(text: "Apple Intelligence is still getting ready", size: 32)
                Text("It’s downloading on this iPhone. You can start now; the smart parts switch on when it’s done.")
                    .font(.body).foregroundStyle(Color.inkSoft)
                Button("Start anyway", action: proceed).buttonStyle(.glassProminent).foregroundStyle(.onAccent).font(.subheadline)
            }
            Spacer()
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 48)
    }
}
