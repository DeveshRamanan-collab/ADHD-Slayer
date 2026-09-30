import SwiftUI

/// Content surfaces. Liquid Glass is reserved for chrome and controls (tab bar, toolbar, buttons,
/// chips); content sits on "veils" — translucent tinted films. Over the smooth sky gradient a veil
/// reads exactly like frosted glass, without breaking the no-glass-on-content rule.
struct Veil<S: InsettableShape>: ViewModifier {
    var shape: S
    var tint: Color?
    var padding: CGFloat

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                ZStack {
                    shape.fill(reduceTransparency ? Color.veilSolid : Color.veil)
                    if let tint { shape.fill(tint.opacity(reduceTransparency ? 0.14 : 0.07)) }
                }
            }
            .overlay { shape.strokeBorder(Color.veilStroke, lineWidth: contrast == .increased ? 1 : 0.5) }
            .shadow(color: .black.opacity(0.03), radius: 16, y: 6)
    }
}

extension View {
    /// A quiet content card: faint film, hairline edge.
    func veil(radius: CGFloat = 22, tint: Color? = nil, padding: CGFloat = 18) -> some View {
        modifier(Veil(shape: RoundedRectangle(cornerRadius: radius, style: .continuous), tint: tint, padding: padding))
    }

    /// Capsule film, for single-line fields.
    func pill(tint: Color? = nil) -> some View {
        modifier(Veil(shape: Capsule(style: .continuous), tint: tint, padding: 0))
    }
}

/// One line of information: a small label over a title, an optional colour dot, a trailing detail.
/// Rows live inside a `RowGroup`, which draws the hairlines between them.
struct InfoRow<Trailing: View>: View {
    var label: LocalizedStringKey?
    var title: String?
    var dot: Color?
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if let dot {
                Circle().fill(dot).frame(width: 6, height: 6).accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 3) {
                if let label { Text(label).eyebrow() }
                if let title {
                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(Color.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 12)
            trailing()
        }
        .padding(.vertical, 13)
        .accessibilityElement(children: .combine)
    }
}

extension InfoRow where Trailing == EmptyView {
    init(label: LocalizedStringKey? = nil, title: String? = nil, dot: Color? = nil) {
        self.init(label: label, title: title, dot: dot) { EmptyView() }
    }
}

/// A card of rows separated by hairlines.
struct RowGroup<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Group(subviews: content) { rows in
                ForEach(rows) { row in
                    if row.id != rows.first?.id {
                        Rectangle().fill(Color.veilStroke).frame(height: 0.5)
                    }
                    row
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 2)
        .veil(padding: 0)
    }
}

/// A trailing value ("11:05", "60 min"): quiet text, optionally led by a symbol.
struct ValueChip: View {
    let text: String
    var systemImage: String?

    var body: some View {
        HStack(spacing: 5) {
            if let systemImage { Image(systemName: systemImage).imageScale(.small) }
            Text(text).monospacedDigit()
        }
        .font(.footnote)
        .foregroundStyle(Color.inkSoft)
    }
}

/// Tint for a block's demand — the same families as the sky: daylight for focus work,
/// sage for body, slate for calendar commitments.
enum Kind {
    static func color(demand: String?, fixed: Bool) -> Color {
        if fixed { return .slate }
        switch demand {
        case "deep": return .zoneBest
        case "medium", "light": return .zoneLight
        case "body": return .sage
        default: return .inkFaint
        }
    }
}

/// Buttons sit left-aligned at their natural width, side by side — stacked at accessibility sizes.
struct ActionRow<Content: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ViewBuilder var content: Content

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
            : AnyLayout(HStackLayout(spacing: 10))
        GlassEffectContainer(spacing: 10) {
            layout { content }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
