import SwiftUI

/// Display type: Apple's New York serif, set small and quiet ("28 September", "5 things left").
/// Everything scales with Dynamic Type through @ScaledMetric.
struct HeroText: View {
    let text: String
    var size: CGFloat = 34
    var italic = false
    var color: Color = .ink
    var reveal: Double = 1

    @ScaledMetric(relativeTo: .title) private var scale: CGFloat = 1
    @Environment(\.typeface) private var typeface

    var body: some View {
        Text(text)
            .font(.system(size: size * scale, weight: .regular, design: typeface.design))
            .italic(italic)
            .tracking(-0.2)
            .foregroundStyle(color)
            .lineLimit(4)
            .minimumScaleFactor(0.8)
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.leading)
            .textRenderer(RiseRenderer(progress: reveal))
            .accessibilityAddTraits(.isHeader)
    }
}

extension Text {
    /// Small tracked capitals that label a section ("REST OF TODAY").
    func eyebrow(_ color: Color = .inkSoft) -> some View {
        self.font(.caption2.weight(.semibold))
            .tracking(1.8)
            .textCase(.uppercase)
            .foregroundStyle(color)
    }
}

extension Font {
    /// Serif numerals for figures ("5", "7h 45m", "74").
    static func figure(_ size: CGFloat) -> Font { .system(size: size, weight: .regular, design: .serif).monospacedDigit() }
    /// Serif title that follows Dynamic Type (block and task titles).
    static func serifTitle(_ style: Font.TextStyle = .title3) -> Font { .system(style, design: .serif) }
}

/// Glyph-by-glyph rise-and-sharpen reveal (iOS 18 TextRenderer). Progress 1 = fully shown.
nonisolated struct RiseRenderer: TextRenderer, Animatable {
    var progress: Double
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        let slices = layout.flatMap { line in line.flatMap { run in run.map { $0 } } }
        guard progress < 1, !slices.isEmpty else {
            for line in layout { context.draw(line) }
            return
        }
        let count = Double(slices.count)
        for (index, slice) in slices.enumerated() {
            let start = Double(index) / count * 0.55
            let local = min(1, max(0, (progress - start) / 0.45))
            let eased = 1 - pow(1 - local, 3)
            var copy = context
            copy.opacity = eased
            copy.translateBy(x: 0, y: (1 - eased) * 8)
            if eased < 1 { copy.addFilter(.blur(radius: (1 - eased) * 4)) }
            copy.draw(slice)
        }
    }
}

extension FormatStyle where Self == CompactTimeStyle {
    /// "9:10" rather than "9:10 am" — used where the time of day is already obvious.
    static var compactTime: CompactTimeStyle { CompactTimeStyle() }
}

/// "h:mm" without am/pm in 12-hour locales, "HH:mm" in 24-hour locales.
struct CompactTimeStyle: FormatStyle {
    func format(_ value: Date) -> String {
        let template = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: .current) ?? "h"
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = template.contains("H") ? "HH:mm" : "h:mm"
        return formatter.string(from: value)
    }
}
