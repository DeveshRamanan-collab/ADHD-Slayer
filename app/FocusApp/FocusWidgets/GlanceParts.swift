import SwiftUI
import WidgetKit
import AppIntents
import FocusGlance

typealias GlanceState = FocusActivityAttributes.ContentState

/// The palette for one surface. The Dynamic Island is black in both appearances, so it always takes
/// the dark values; the Lock Screen, StandBy and the Watch follow the appearance.
struct Tones {
    let scheme: ColorScheme
    static let island = Tones(scheme: .dark)

    func color(_ pair: GlancePalette.Pair) -> Color { pair.color(scheme) }
    var accent: Color { color(GlancePalette.accent) }
    var ink: Color { color(GlancePalette.ink) }
    var inkSoft: Color { color(GlancePalette.inkSoft) }
    var tertiary: Color { color(GlancePalette.tertiary) }
    var doneFill: Color { color(GlancePalette.doneFill) }
    var onDone: Color { color(GlancePalette.onDone) }
    func stretch(_ stretch: Stretch) -> Color { color(GlancePalette.stretch(stretch)) }
}

// MARK: - Type

extension Font {
    /// Serif for titles and the stretch line (New York), following Dynamic Type from its text style.
    static func glanceSerif(_ style: Font.TextStyle) -> Font { .system(style, design: .serif) }
}

extension Text {
    /// Small tracked capitals ("NEXT"), as in the app.
    func glanceEyebrow(_ color: Color) -> some View {
        font(.caption2.weight(.semibold)).tracking(1.4).textCase(.uppercase).foregroundStyle(color)
    }
}

// MARK: - The time ring and the time

/// The time ring. While it runs, the system draws it live from the session's interval
/// (`ProgressView(timerInterval:)`), so it keeps emptying on the Lock Screen and in the Dynamic Island
/// with no updates from the app. Paused, it stands still and dims; when the time is up only the track
/// is left.
struct FocusRing: View {
    let phase: GlanceState.FocusPhase
    let diameter: CGFloat
    let lineWidth: CGFloat
    let tones: Tones

    var body: some View {
        ZStack {
            switch phase {
            case .running(let range):
                ProgressView(timerInterval: range, countsDown: true) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
                .progressViewStyle(.circular)
                .tint(tones.accent)
            case .paused(_, let fraction):
                track
                arc(fraction).opacity(0.45)
            case .timeUp, .ended:
                track
            }
        }
        .frame(width: diameter, height: diameter)
        .accessibilityHidden(true)
    }

    private var track: some View {
        Circle().stroke(tones.tertiary.opacity(0.55), lineWidth: lineWidth)
    }

    private func arc(_ fraction: Double) -> some View {
        Circle()
            .trim(from: 0, to: max(0.001, fraction))
            .stroke(tones.accent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .rotationEffect(.degrees(-90))
    }
}

/// Time left: live while running (`Text(timerInterval:)`, so it counts without updates), still while
/// paused. Minutes run past 59 ("80:00") so the width never jumps.
struct TimeLeft: View {
    let phase: GlanceState.FocusPhase
    let font: Font
    let color: Color

    var body: some View {
        Group {
            switch phase {
            case .running(let range):
                Text(timerInterval: range, countsDown: true, showsHours: false)
            case .paused(let left, _):
                Text(GlanceFormat.timer(left))
            case .timeUp:
                Text(verbatim: "0:00")
            case .ended:
                EmptyView()
            }
        }
        .font(font.monospacedDigit())
        .foregroundStyle(color)
        .lineLimit(1)
        .multilineTextAlignment(.trailing)
    }
}

// MARK: - Buttons

/// A 34 pt capsule label for the Live Activity buttons: solid for the main action (Done), a quiet
/// glass-like film for the rest (+5 min, Log).
struct CapsuleLabel: View {
    let title: LocalizedStringKey
    var systemImage: String?
    let prominent: Bool
    let tones: Tones

    var body: some View {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage).font(.footnote.weight(.semibold))
            }
            Text(title).font(.subheadline.weight(.semibold))
        }
        .lineLimit(1)
        .foregroundStyle(prominent ? tones.onDone : tones.ink)
        .padding(.horizontal, 14)
        .frame(minHeight: 34)
        .background {
            if prominent {
                Capsule().fill(tones.doneFill)
            } else {
                Capsule().fill(tones.ink.opacity(tones.scheme == .dark ? 0.14 : 0.08))
                Capsule().strokeBorder(tones.ink.opacity(0.16), lineWidth: 0.5)
            }
        }
        .contentShape(.capsule)
    }
}

/// Done and +5 min, side by side and left aligned.
struct FocusButtons: View {
    let tones: Tones

    var body: some View {
        HStack(spacing: 8) {
            Button(intent: EndFocusSessionIntent()) {
                CapsuleLabel(title: "Done", systemImage: "checkmark", prominent: true, tones: tones)
            }
            .accessibilityLabel("Done")
            Button(intent: ExtendFocusSessionIntent()) {
                CapsuleLabel(title: "+5 min", prominent: false, tones: tones)
            }
            .accessibilityLabel("Five more minutes")
        }
        .buttonStyle(.plain)
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
    }
}

/// Log: records what's set for about now, after Face ID on a locked phone. A tick and the word Log;
/// never a pill or a medicine name.
struct LogButton: View {
    let tones: Tones

    var body: some View {
        Button(intent: LogMedicationIntent()) {
            CapsuleLabel(title: "Log", systemImage: "checkmark", prominent: false, tones: tones)
        }
        .buttonStyle(.plain)
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
        .accessibilityLabel("Log")
    }
}

// MARK: - Your day

/// A dot in the stretch's colour.
struct StretchDot: View {
    let color: Color
    var diameter: CGFloat = 12

    var body: some View {
        Circle().fill(color).frame(width: diameter, height: diameter).accessibilityHidden(true)
    }
}

/// The next 8 hours as one bar: a 6 pt capsule per stretch with 2 pt between them, and a now marker.
struct SegmentBar: View {
    let segments: [Segment]
    let tones: Tones
    var now: Date = .now

    var body: some View {
        GeometryReader { geo in
            let widths = Self.widths(segments.map(\.duration), in: geo.size.width, gap: 2, minimum: 6)
            ZStack(alignment: .leading) {
                HStack(spacing: 2) {
                    ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                        Capsule()
                            .fill(tones.stretch(segment.stretch))
                            .frame(width: widths[index], height: 6)
                    }
                }
                Capsule()
                    .fill(tones.ink)
                    .frame(width: 2, height: 12)
                    .offset(x: markerOffset(width: geo.size.width))
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .leading)
        }
        .frame(height: 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.summary(segments))
    }

    private func markerOffset(width: CGFloat) -> CGFloat {
        guard let first = segments.first, let last = segments.last else { return 0 }
        let span = last.end.timeIntervalSince(first.start)
        guard span > 0 else { return 0 }
        let fraction = min(1, max(0, now.timeIntervalSince(first.start) / span))
        return fraction * max(0, width - 2)
    }

    /// Widths in proportion to each segment's length, none thinner than a dot.
    static func widths(_ durations: [TimeInterval], in total: CGFloat, gap: CGFloat, minimum: CGFloat) -> [CGFloat] {
        guard !durations.isEmpty else { return [] }
        let available = max(0, total - gap * CGFloat(durations.count - 1))
        let sum = max(1, durations.reduce(0, +))
        var widths = durations.map { CGFloat($0 / sum) * available }
        let short = widths.indices.filter { widths[$0] < minimum }
        guard !short.isEmpty else { return widths }
        let taken = minimum * CGFloat(short.count)
        let rest = widths.indices.filter { !short.contains($0) }
        let restSum = rest.reduce(CGFloat(0)) { $0 + widths[$1] }
        for i in short { widths[i] = minimum }
        if restSum > 0 {
            let scale = max(0, available - taken) / restSum
            for i in rest { widths[i] *= scale }
        }
        return widths
    }

    static func summary(_ segments: [Segment]) -> String {
        let parts = segments.map { "\($0.stretch.displayName) until \(GlanceFormat.time($0.end))" }
        return parts.isEmpty ? "The next 8 hours" : "The next 8 hours: " + parts.joined(separator: ", then ")
    }
}

extension GlanceState {
    /// "Next: Essay drafting at 11:25".
    var nextSentence: String? {
        guard let nextTitle else { return nil }
        guard let nextAt else { return "Next: \(nextTitle)" }
        return "Next: \(nextTitle) at \(GlanceFormat.time(nextAt))"
    }
}
