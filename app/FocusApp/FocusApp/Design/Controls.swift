import SwiftUI

// MARK: - Sliders

/// A single-value slider with a glass thumb that grows under your finger, a tinted fill, a value
/// bubble while dragging, and a tick of haptic at every step.
struct GlassSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 1
    var tint: Color = .zoneBest
    let label: (Double) -> String

    @State private var dragging = false
    @Environment(\.motionIsCalm) private var calm
    private let thumb: CGFloat = 28

    var body: some View {
        GeometryReader { geo in
            let usable = max(1, geo.size.width - thumb)
            let fraction = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
            ZStack(alignment: .leading) {
                Capsule().fill(Color.track).frame(height: 6)
                Capsule()
                    .fill(LinearGradient(colors: [tint.opacity(0.55), tint], startPoint: .leading, endPoint: .trailing))
                    .frame(width: fraction * usable + thumb / 2, height: 6)
                Circle()
                    .fill(Color.veilSolid.opacity(0.35))
                    .frame(width: thumb, height: thumb)
                    .glassEffect(.regular.interactive(), in: .circle)
                    .overlay(Circle().fill(tint).frame(width: 8, height: 8))
                    .scaleEffect(dragging ? 1.18 : 1)
                    .offset(x: fraction * usable)
                    .overlay(alignment: .topLeading) {
                        if dragging {
                            Text(label(value))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(Color.ink)
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .glassEffect(.regular, in: .capsule)
                                .fixedSize()
                                .offset(x: fraction * usable - 20, y: -38)
                                .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .bottom)))
                        }
                    }
            }
            .frame(height: geo.size.height)
            .contentShape(.rect)
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { g in
                    if !dragging { withAnimation(.gentle(calm, .snappy)) { dragging = true } }
                    let f = min(max(0, (g.location.x - thumb / 2) / usable), 1)
                    set(range.lowerBound + Double(f) * (range.upperBound - range.lowerBound))
                }
                .onEnded { _ in withAnimation(.gentle(calm, .snappy)) { dragging = false } })
        }
        .frame(height: 44)
        .accessibilityElement()
        .accessibilityValue(label(value))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: set(value + step)
            case .decrement: set(value - step)
            @unknown default: break
            }
        }
    }

    private func set(_ raw: Double) {
        let stepped = min(max((raw / step).rounded() * step, range.lowerBound), range.upperBound)
        if stepped != value {
            value = stepped
            Haptics.shared.play(.tick)
        }
    }
}

/// Two thumbs on one track: "from 3 h to 6 h", "9:10 am to 5:10 pm".
struct RangeSlider: View {
    @Binding var lower: Double
    @Binding var upper: Double
    let range: ClosedRange<Double>
    var step: Double = 0.25
    var minimumGap: Double = 0.25
    var tint: Color = .zoneBest
    let label: (Double) -> String

    @State private var active: Int?
    @Environment(\.motionIsCalm) private var calm
    private let thumb: CGFloat = 28

    var body: some View {
        GeometryReader { geo in
            let usable = max(1, geo.size.width - thumb)
            let span = range.upperBound - range.lowerBound
            let a = CGFloat((lower - range.lowerBound) / span) * usable
            let b = CGFloat((upper - range.lowerBound) / span) * usable
            ZStack(alignment: .leading) {
                Capsule().fill(Color.track).frame(height: 6)
                Capsule()
                    .fill(LinearGradient(colors: [tint.opacity(0.55), tint], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(6, b - a), height: 6)
                    .offset(x: a + thumb / 2)
                thumbView(isActive: active == 0, value: lower).offset(x: a)
                thumbView(isActive: active == 1, value: upper).offset(x: b)
            }
            .frame(height: geo.size.height)
            .contentShape(.rect)
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { g in
                    let x = g.location.x - thumb / 2
                    if active == nil {
                        withAnimation(.gentle(calm, .snappy)) { active = abs(x - a) <= abs(x - b) ? 0 : 1 }
                    }
                    let v = range.lowerBound + Double(min(max(0, x / usable), 1)) * span
                    let stepped = (v / step).rounded() * step
                    if active == 0 {
                        let new = min(max(stepped, range.lowerBound), upper - minimumGap)
                        if new != lower { lower = new; Haptics.shared.play(.tick) }
                    } else {
                        let new = max(min(stepped, range.upperBound), lower + minimumGap)
                        if new != upper { upper = new; Haptics.shared.play(.tick) }
                    }
                }
                .onEnded { _ in withAnimation(.gentle(calm, .snappy)) { active = nil } })
        }
        .frame(height: 44)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label(lower)) to \(label(upper))")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: upper = min(range.upperBound, upper + step)
            case .decrement: upper = max(lower + minimumGap, upper - step)
            @unknown default: break
            }
        }
    }

    private func thumbView(isActive: Bool, value: Double) -> some View {
        Circle()
            .fill(Color.veilSolid.opacity(0.35))
            .frame(width: thumb, height: thumb)
            .glassEffect(.regular.interactive(), in: .circle)
            .overlay(Circle().fill(tint).frame(width: 8, height: 8))
            .scaleEffect(isActive ? 1.18 : 1)
            .overlay(alignment: .top) {
                if isActive {
                    Text(label(value))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Color.ink)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .glassEffect(.regular, in: .capsule)
                        .fixedSize()
                        .offset(y: -38)
                }
            }
    }
}

// MARK: - Type that follows the chosen typeface

struct HeadingFont: ViewModifier {
    var style: Font.TextStyle?
    var size: CGFloat?
    var monospacedDigits = false
    @Environment(\.typeface) private var typeface

    func body(content: Content) -> some View {
        let font: Font = if let size { .system(size: size, weight: .regular, design: typeface.design) }
                         else { .system(style ?? .title3, design: typeface.design) }
        return content.font(monospacedDigits ? font.monospacedDigit() : font)
    }
}

extension View {
    /// Titles in the chosen typeface (serif by default), following Dynamic Type.
    func headingFont(_ style: Font.TextStyle = .title3) -> some View { modifier(HeadingFont(style: style)) }
    /// Figures in the chosen typeface with steady digits ("5", "7h 45m", "74").
    func figureFont(_ size: CGFloat) -> some View { modifier(HeadingFont(size: size, monospacedDigits: true)) }
    /// A soft tap under the finger for any button.
    func tapHaptic(_ moment: Haptics.Moment = .tap) -> some View {
        simultaneousGesture(TapGesture().onEnded { Haptics.shared.play(moment) })
    }
}

// MARK: - Logging celebration

/// When a dose is logged: a champagne line draws itself around the chip, a soft glow blooms and a few
/// sparks drift out, while the phone plays the "logged" pattern. Off switch in Customise.
struct LogCelebration: ViewModifier {
    let trigger: Int
    let active: Bool
    @AppStorage("celebrateLogging") private var celebrate = true
    @Environment(\.motionIsCalm) private var calm

    private struct Burst { var trim: CGFloat = 0; var glow: Double = 0; var spread: CGFloat = 0; var fade: Double = 0 }

    func body(content: Content) -> some View {
        content.overlay {
            if active && celebrate && !calm {
                ZStack {
                    Color.clear
                }
                .keyframeAnimator(initialValue: Burst(), trigger: trigger) { _, v in
                    ZStack {
                        Capsule(style: .continuous)
                            .trim(from: 0, to: v.trim)
                            .stroke(AngularGradient(colors: [.zoneBest, .zoneWarm, .zoneBest, .honey, .zoneBest], center: .center), lineWidth: 2)
                            .shadow(color: .zoneBest.opacity(0.8 * v.glow), radius: 10 * v.glow)
                            .opacity(v.fade)
                        ForEach(0..<8, id: \.self) { i in
                            let angle = Double(i) / 8 * 2 * .pi
                            Circle()
                                .fill(i.isMultiple(of: 2) ? Color.zoneBest : Color.honey)
                                .frame(width: 4, height: 4)
                                .offset(x: cos(angle) * (26 + 40 * v.spread), y: sin(angle) * (16 + 26 * v.spread))
                                .opacity(v.fade * (1 - Double(v.spread) * 0.6))
                        }
                    }
                    .allowsHitTesting(false)
                } keyframes: { _ in
                    KeyframeTrack(\.trim) { MoveKeyframe(0); CubicKeyframe(1, duration: 0.5) }
                    KeyframeTrack(\.glow) { MoveKeyframe(0); CubicKeyframe(1, duration: 0.25); CubicKeyframe(0, duration: 0.8) }
                    KeyframeTrack(\.spread) { MoveKeyframe(0); LinearKeyframe(0, duration: 0.15); CubicKeyframe(1, duration: 0.8) }
                    KeyframeTrack(\.fade) { MoveKeyframe(1); LinearKeyframe(1, duration: 0.7); CubicKeyframe(0, duration: 0.5) }
                }
            }
        }
    }
}

extension View {
    func logCelebration(trigger: Int, active: Bool) -> some View { modifier(LogCelebration(trigger: trigger, active: active)) }
}

// MARK: - Coach marks

/// Things the first-run tour can point at.
enum CoachTarget: String, CaseIterable { case priorities, meds, dots }

struct CoachAnchorKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: [CoachTarget: Anchor<CGRect>] = [:]
    static func reduce(value: inout [CoachTarget: Anchor<CGRect>], nextValue: () -> [CoachTarget: Anchor<CGRect>]) {
        value.merge(nextValue()) { $1 }
    }
}

extension View {
    func coachTarget(_ target: CoachTarget) -> some View {
        anchorPreference(key: CoachAnchorKey.self, value: .bounds) { [target: $0] }
    }
}

/// The tour: dims everything except the thing it's talking about, says one short thing, and can be
/// skipped at any point. Never a wall of steps: four marks, then you're free.
struct CoachTour: ViewModifier {
    @Binding var step: Int?
    let openSetup: () -> Void
    @Environment(\.motionIsCalm) private var calm

    private var steps: [(CoachTarget?, CopySlot)] {
        [(.priorities, .coachPriorities), (.meds, .coachMeds), (.dots, .coachDots), (nil, .coachSetup), (nil, .coachDone)]
    }

    func body(content: Content) -> some View {
        content.overlayPreferenceValue(CoachAnchorKey.self) { anchors in
            GeometryReader { geo in
                if let step, steps.indices.contains(step) {
                    let (target, slot) = steps[step]
                    let rect = target.flatMap { anchors[$0] }.map { geo[$0].insetBy(dx: -10, dy: -10) }
                    ZStack(alignment: .topLeading) {
                        // The dimming ignores the safe area, so its origin sits above the reader's.
                        Path { p in
                            p.addRect(CGRect(origin: .zero, size: geo.size).insetBy(dx: -200, dy: -200))
                            if let rect {
                                p.addRoundedRect(in: rect.offsetBy(dx: geo.safeAreaInsets.leading, dy: geo.safeAreaInsets.top),
                                                 cornerSize: CGSize(width: 18, height: 18))
                            }
                        }
                        .fill(Color.black.opacity(0.5), style: FillStyle(eoFill: true))
                        .ignoresSafeArea()
                        .onTapGesture { advance() }
                        if let rect {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(Color.zoneBest, lineWidth: 1.5)
                                .frame(width: rect.width, height: rect.height)
                                .offset(x: rect.minX, y: rect.minY)
                                .allowsHitTesting(false)
                        }
                        bubble(slot, isSetup: target == nil && step == 3, isLast: step == steps.count - 1)
                            .frame(maxWidth: 300, alignment: .leading)
                            .offset(x: 24, y: bubbleY(rect: rect, in: geo.size))
                    }
                    .transition(.opacity)
                    .id(step)
                }
            }
        }
    }

    private func bubbleY(rect: CGRect?, in size: CGSize) -> CGFloat {
        guard let rect else { return size.height * 0.42 }
        return rect.maxY + 190 < size.height ? rect.maxY + 14 : max(40, rect.minY - 170)
    }

    private func bubble(_ slot: CopySlot, isSetup: Bool, isLast: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(Copy.line(slot))
                .headingFont(.title3)
                .foregroundStyle(Color.ink)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 10) {
                if isSetup {
                    Button("Take me there") { step = nil; openSetup() }
                        .buttonStyle(.glassProminent)
                        .foregroundStyle(.onAccent)
                    Button("Later") { advance() }.buttonStyle(.glass)
                } else {
                    Button(isLast ? "Got it" : "Next") { advance() }
                        .buttonStyle(.glassProminent)
                        .foregroundStyle(.onAccent)
                }
                if !isLast && !isSetup {
                    Button("Skip, I’ll explore") { withAnimation(.gentle(calm)) { step = nil } }
                        .font(.footnote)
                        .foregroundStyle(Color.ink)
                        .buttonStyle(.plain)
                }
            }
            .font(.subheadline)
        }
        .padding(18)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
        .onAppear { Haptics.shared.play(.nudge) }
    }

    private func advance() {
        withAnimation(.gentle(calm, .smooth)) {
            if let s = step, s + 1 < steps.count { step = s + 1 } else { step = nil }
        }
    }
}

/// Lets a single call site choose between two glass button styles.
struct AnyPrimitiveButtonStyle: PrimitiveButtonStyle {
    private let make: (Configuration) -> AnyView
    init<S: PrimitiveButtonStyle>(_ style: S) { make = { AnyView(style.makeBody(configuration: $0)) } }
    func makeBody(configuration: Configuration) -> some View { make(configuration) }
}

// MARK: - Toast

/// A small glass note that floats up from the bottom for two seconds ("Logged 2. Done and dusted.").
struct Toast: ViewModifier {
    @Binding var message: String?
    @Environment(\.motionIsCalm) private var calm

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color.ink)
                    .padding(.horizontal, 18).padding(.vertical, 12)
                    .glassEffect(.regular, in: .capsule)
                    .padding(.bottom, 150)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .task(id: message) {
                        try? await Task.sleep(for: .seconds(2.4))
                        withAnimation(.gentle(calm)) { self.message = nil }
                    }
                    .accessibilityAddTraits(.isStaticText)
            }
        }
        .animation(.gentle(calm, .snappy), value: message)
    }
}

extension View {
    func toast(_ message: Binding<String?>) -> some View { modifier(Toast(message: message)) }
}
