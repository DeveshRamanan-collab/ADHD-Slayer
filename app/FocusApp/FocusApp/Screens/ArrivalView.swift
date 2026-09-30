import SwiftUI

/// The starting page. The sky settles from night into where your focus day is, the date writes
/// itself in, and a gentle haptic swell lands with each line. One question, three small glass
/// answers, then Today. Nothing else — the first thing you see should never be a wall of information.
struct ArrivalView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.motionIsCalm) private var calm
    @Namespace private var glass

    @State private var phase: SkyPhase = .night
    @State private var dateReveal = 0.0
    @State private var showEyebrow = false
    @State private var showGreeting = false
    @State private var showQuestion = false
    @State private var chosen: AppModel.BrainWeather?

    var body: some View {
        ZStack {
            SkyBackground(phase: phase)
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                Text(model.now, format: .dateTime.weekday(.wide))
                    .eyebrow()
                    .opacity(showEyebrow ? 1 : 0)
                HeroText(text: model.now.formatted(.dateTime.day().month(.wide)), size: 38, reveal: dateReveal)
                    .padding(.top, 8)
                greeting
                    .padding(.top, 10)
                    .opacity(showGreeting ? 1 : 0)
                    .offset(y: showGreeting || calm ? 0 : 6)
                Spacer()
                Spacer()
                question
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.bottom, 48)
        }
        .onAppear(perform: arrive)
        .accessibilityElement(children: .contain)
    }

    private var greeting: some View {
        let hello = model.greeting.components(separatedBy: ",").first ?? model.greeting
        let line = model.userName.isEmpty
            ? Text("\(hello).")
            : Text("\(hello), \(Text(model.userName).italic()).")
        return line
            .headingFont(.title3)
            .foregroundStyle(Color.inkSoft)
    }

    private var question: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("How’s your brain today?")
                .font(.subheadline)
                .foregroundStyle(Color.ink)
            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(AppModel.BrainWeather.allCases) { option in
                        if chosen == nil || chosen == option {
                            answer(option)
                                .glassEffectID(option.rawValue, in: glass)
                        }
                    }
                }
            }
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            Button("Not now") { finish(nil) }
                .font(.footnote)
                .foregroundStyle(Color.inkSoft)
                .buttonStyle(.plain)
                .padding(.top, 4)
        }
        .opacity(showQuestion ? 1 : 0)
        .offset(y: showQuestion || calm ? 0 : 12)
    }

    private func answer(_ option: AppModel.BrainWeather) -> some View {
        let label: (String, String) = switch option {
        case .low: ("Low", "cloud.drizzle")
        case .okay: ("Okay", "cloud.sun")
        case .good: ("Good", "sun.max")
        }
        return Button {
            finish(option)
        } label: {
            Label(label.0, systemImage: label.1)
                .font(.subheadline)
                .foregroundStyle(Color.ink)
        }
        .buttonStyle(.glass)
        .accessibilityHint(option == .low ? "Gives you a lighter, baseline day" : "")
    }

    private func arrive() {
        let target = model.skyPhase
        guard !calm else {
            phase = target; dateReveal = 1; showEyebrow = true; showGreeting = true; showQuestion = true
            return
        }
        Haptics.shared.play(.arrival)
        withAnimation(.smooth(duration: 1.8)) { phase = target }
        withAnimation(.smooth(duration: 0.6).delay(0.2)) { showEyebrow = true }
        withAnimation(.easeOut(duration: 1.2).delay(0.35)) { dateReveal = 1 }
        withAnimation(.smooth(duration: 0.7).delay(1.1)) { showGreeting = true }
        withAnimation(.smooth(duration: 0.7).delay(1.6)) { showQuestion = true }
    }

    private func finish(_ option: AppModel.BrainWeather?) {
        if let option {
            Haptics.shared.play(.choose)
            withAnimation(.gentle(calm, .bouncy)) { chosen = option }
        }
        let delay = option == nil || calm ? 0.0 : 0.55
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if let option { model.brainWeather = option }
            model.hasArrived = true
        }
    }
}
