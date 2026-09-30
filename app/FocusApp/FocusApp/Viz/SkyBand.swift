import SwiftUI
import FocusModel

/// Today's focus window drawn as a strip of sky: dawn rose while it warms up, daylight amber for best
/// focus, dusk mauve as it lightens — feathered at each edge by the learned ± uncertainty.
/// Draws itself in from the dose dot outward whenever `drawn` flips on (Motion A).
struct SkyBand: View {
    let window: FocusWindow?
    let now: Date
    var drawn: Bool = true
    var height: CGFloat = 12

    @Environment(\.motionIsCalm) private var calm
    private let startHour = 6.0, endHour = 23.0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let x: (Date) -> CGFloat = { date in
                let c = Calendar.current.dateComponents([.hour, .minute], from: date)
                let h = Double(c.hour ?? 0) + Double(c.minute ?? 0) / 60
                return CGFloat(min(max((h - startHour) / (endHour - startHour), 0), 1)) * w
            }
            ZStack(alignment: .topLeading) {
                Capsule().fill(Color.track).frame(width: w, height: height).offset(y: 18)
                if let win = window {
                    windowStrip(win, x: x, perMinute: w / CGFloat((endHour - startHour) * 60))
                    Circle()
                        .strokeBorder(Color.ink, lineWidth: 2)
                        .background(Circle().fill(Color.veilSolid))
                        .frame(width: 10, height: 10)
                        .scaleEffect(drawn ? 1 : 0.01)
                        .animation(.gentle(calm, .timingCurve(0.45, 1.45, 0.8, 1, duration: 0.35)), value: drawn)
                        .offset(x: x(win.dose) - 5, y: 18 + height / 2 - 5)
                }
                nowMarker(x(now))
                ForEach([(6.0, "6"), (9, "9"), (12, "12"), (15, "3"), (18, "6"), (21, "9")], id: \.0) { hour, label in
                    Text(label)
                        .font(.caption2)
                        .foregroundStyle(Color.inkSoft)
                        .fixedSize()
                        .alignmentGuide(.leading) { d in hour == 6 ? 0 : d.width / 2 }
                        .offset(x: CGFloat((hour - startHour) / (endHour - startHour)) * w, y: 18 + height + 8)
                }
            }
        }
        .frame(height: 18 + height + 24)
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func windowStrip(_ win: FocusWindow, x: @escaping (Date) -> CGFloat, perMinute: CGFloat) -> some View {
        let left = x(win.dose)
        let width = max(1, x(win.end) + CGFloat(win.endUncertaintyMinutes) * perMinute - left)
        let frac: (Date) -> Double = { Double((x($0) - left) / width) }
        let uS = Double(CGFloat(win.startUncertaintyMinutes) * perMinute / width)
        let uE = Double(CGFloat(win.endUncertaintyMinutes) * perMinute / width)
        let s = frac(win.start), b = frac(win.bestFocusEnd), e = frac(win.end)
        let stops: [Gradient.Stop] = [
            .init(color: .zoneWarm.opacity(0.35), location: 0),
            .init(color: .zoneWarm, location: min(0.06, max(0, s - uS))),
            .init(color: .zoneWarm, location: max(0, s - uS)),
            .init(color: .zoneBest, location: min(1, s + uS)),
            .init(color: .zoneBest, location: max(s + uS, b - 0.03)),
            .init(color: .zoneLight, location: min(1, b + 0.03)),
            .init(color: .zoneLight, location: max(b + 0.03, e - uE)),
            .init(color: .zoneLight.opacity(0), location: 1),
        ]
        Capsule()
            .fill(LinearGradient(stops: stops, startPoint: .leading, endPoint: .trailing))
            .frame(width: width, height: height)
            .mask(alignment: .leading) {
                Rectangle().frame(width: drawn ? width : 0)
                    .animation(.gentle(calm, .smooth(duration: 1.1).delay(0.25)), value: drawn)
            }
            .offset(x: left, y: 18)
    }

    private func nowMarker(_ nx: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Text("now").font(.caption2.weight(.medium)).foregroundStyle(Color.ink)
                .offset(x: nx - 10, y: 0)
            Capsule().fill(Color.ink).frame(width: 2, height: height + 10).offset(x: nx - 1, y: 13)
        }
        .opacity(drawn ? 1 : 0)
        .animation(.gentle(calm, .smooth(duration: 0.4).delay(1.2)), value: drawn)
    }
}

/// Thin depleting ring for the current block. Linear depletion (time must feel honest); tone shifts
/// from daylight to honey five minutes before a switch, with two ripples and a haptic.
struct TimeRing: View {
    let remaining: Double
    let minutesLeft: Int
    var isWrapUp: Bool = false
    var diameter: CGFloat = 72
    var lineWidth: CGFloat = 2.5

    @Environment(\.motionIsCalm) private var calm

    var body: some View {
        ZStack {
            Circle().stroke(Color.track, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, remaining)))
                .stroke(isWrapUp ? Color.honey : Color.zoneBest, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.3), value: remaining)
            if !calm {
                ForEach(0..<2, id: \.self) { i in
                    Circle().stroke(Color.honey, lineWidth: 1)
                        .keyframeAnimator(initialValue: Ripple(), trigger: isWrapUp) { view, v in
                            view.scaleEffect(v.scale).opacity(isWrapUp ? v.opacity : 0)
                        } keyframes: { _ in
                            KeyframeTrack(\.opacity) { MoveKeyframe(0); LinearKeyframe(0, duration: Double(i) * 0.6); MoveKeyframe(0.7); CubicKeyframe(0, duration: 0.55) }
                            KeyframeTrack(\.scale) { MoveKeyframe(1); LinearKeyframe(1, duration: Double(i) * 0.6); CubicKeyframe(1.22, duration: 0.55) }
                        }
                }
            }
            VStack(spacing: 0) {
                Text(minutesLeft, format: .number)
                    .figureFont(diameter * 0.3)
                    .contentTransition(.numericText(countsDown: true))
                Text(isWrapUp ? "wrap up" : diameter < 110 ? "min" : "min left")
                    .font(diameter < 110 ? .caption2 : .caption)
                    .foregroundStyle(Color.inkSoft)
            }
            .foregroundStyle(Color.ink)
        }
        .frame(width: diameter, height: diameter)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .animation(.gentle(calm, .easeInOut(duration: 0.4)), value: isWrapUp)
        .sensoryFeedback(.warning, trigger: isWrapUp) { _, new in new && Haptics.shared.isEnabled }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isWrapUp ? "Wrap up, \(minutesLeft) minutes left" : "\(minutesLeft) minutes left")
    }

    private struct Ripple { var scale: CGFloat = 1; var opacity: Double = 0 }
}
