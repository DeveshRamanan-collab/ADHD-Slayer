import SwiftUI

// MARK: Calm motion

/// True when the system's Reduce Motion is on or the person picked "Still" motion in You.
/// Every custom animation in the app goes through this.
private struct MotionIsCalmKey: EnvironmentKey { static let defaultValue = false }

extension EnvironmentValues {
    var motionIsCalm: Bool {
        get { self[MotionIsCalmKey.self] }
        set { self[MotionIsCalmKey.self] = newValue }
    }
}

struct CalmMotionReader: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("stillMotion") private var stillMotion = false
    func body(content: Content) -> some View {
        content.environment(\.motionIsCalm, reduceMotion || stillMotion)
    }
}

extension Animation {
    /// Nil when motion should be calm, so `withAnimation(.gentle(calm))` becomes an instant change.
    static func gentle(_ calm: Bool, _ animation: Animation = .smooth(duration: 0.55)) -> Animation? {
        calm ? nil : animation
    }
}

// MARK: Reveal on scroll

/// Content arrives as it scrolls into view — rising, sharpening, fading in — and softly recedes as it
/// leaves. One idea at a time: what's below stays quiet until you go to it.
struct Reveal: ViewModifier {
    @Environment(\.motionIsCalm) private var calm
    var delay: Double = 0

    func body(content: Content) -> some View {
        let calm = calm
        // Thresholds are fractions of the view, so a card taller than the screen (large text sizes)
        // still counts as arrived once a slice of it is showing.
        return content.scrollTransition(topLeading: .interactive.threshold(.visible(0.25)),
                                        bottomTrailing: .animated(.smooth(duration: 0.6).delay(delay)).threshold(.visible(0.12))) { view, phase in
            view
                // Leaving at the top fades with the finger (so the last chapter never lingers
                // under the status bar); arriving from below is a short, eased reveal.
                .opacity(phase.isIdentity ? 1 : (phase == .topLeading ? max(0, 1 - abs(phase.value) * 1.6) : 0))
                .scaleEffect(calm || phase.isIdentity ? 1 : 0.98)
                .offset(y: calm || phase.isIdentity ? 0 : (phase == .bottomTrailing ? 18 : -8))
                .blur(radius: calm || phase.isIdentity ? 0 : 3)
        }
    }
}

extension View {
    func reveal(delay: Double = 0) -> some View { modifier(Reveal(delay: delay)) }
}

// MARK: Pages

/// A screen made of full-height pages, like reels: one idea per page, and a flick moves exactly one
/// page. The date sits fixed at the top, the tab bar and dose bar stay fixed at the bottom, and each
/// page centres its content between them. Dots on the trailing edge show where you are.
/// At accessibility text sizes a page may grow taller than the screen; it then scrolls freely inside
/// and only settles at its edges, so nothing is ever unreachable.
struct PagedScreen<Trailing: View, Pages: View>: View {
    let count: Int
    @Binding var page: Int?
    @ViewBuilder var trailing: () -> Trailing
    @ViewBuilder var pages: () -> Pages

    @Environment(AppModel.self) private var model
    @Environment(Customisation.self) private var custom
    @Environment(\.motionIsCalm) private var calm
    @State private var tops = ChapterTops()
    @State private var headerHeight: CGFloat = 56

    var body: some View {
        GeometryReader { proxy in
            let insets = proxy.safeAreaInsets
            let headerBottom = insets.top + headerHeight
            let metrics = PageMetrics(height: proxy.size.height + insets.top + insets.bottom,
                                      top: headerBottom + 12, bottom: insets.bottom + 12)
            ScrollView {
                VStack(spacing: 0) {
                    pages()
                }
                .scrollTargetLayout()
                .environment(\.pageMetrics, metrics)
                .environment(\.chapterTops, tops)
                .coordinateSpace(.named(ChapterTops.space))
            }
            .scrollTargetBehavior(ChapterSnap(tops: tops))
            .scrollPosition(id: $page, anchor: .top)
            .scrollIndicators(.hidden)
            .scrollContentBackground(.hidden)
            // Content leaving the top fades out before it reaches the date.
            .mask {
                VStack(spacing: 0) {
                    Color.clear.frame(height: max(0, headerBottom - 6))
                    LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom).frame(height: 22)
                    Color.black
                }
            }
            .ignoresSafeArea()
            .overlay(alignment: .top) {
                DateHeader(date: model.now, trailing: trailing)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { headerHeight = $0 }
            }
            .overlay(alignment: .trailing) {
                if custom.settings.dots != .hidden && count > 1 {
                    PageDots(count: count, current: page ?? 0, numbers: custom.settings.dots == .numbers) { target in
                        withAnimation(.gentle(calm, .smooth(duration: 0.45))) { page = target }
                    }
                    .padding(.trailing, 8)
                    .coachTarget(.dots)
                }
            }
        }
        .background { SkyBackground(phase: model.skyPhase) }
        .toolbar(.hidden, for: .navigationBar)
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: page) { old, new in
            old != nil && new != nil && old != new && Haptics.shared.isEnabled
        }
    }
}

/// The fixed top of every main screen: the day and the date, with the screen's own glass buttons.
struct DateHeader<Trailing: View>: View {
    let date: Date
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text(date, format: .dateTime.weekday(.wide)).eyebrow()
                Text(date, format: .dateTime.day().month(.wide))
                    .font(.system(.title3, design: .serif))
                    .foregroundStyle(Color.ink)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 12)
            trailing()
        }
        .padding(.horizontal, 24)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }
}

/// Vertical page dots: the current page is a short bar, the rest are points. Tap one to go there;
/// VoiceOver can swipe up and down on it to change page.
struct PageDots: View {
    let count: Int
    let current: Int
    var numbers = false
    let select: (Int) -> Void
    @Environment(\.motionIsCalm) private var calm

    var body: some View {
        if numbers {
            VStack(spacing: 1) {
                Text("\(current + 1)").font(.caption2.monospacedDigit()).foregroundStyle(Color.ink)
                    .contentTransition(.numericText())
                Rectangle().fill(Color.inkFaint).frame(width: 8, height: 0.5)
                Text("\(count)").font(.caption2.monospacedDigit()).foregroundStyle(Color.inkSoft)
            }
            .frame(width: 22)
            .contentShape(.rect)
            .onTapGesture { select((current + 1) % count) }
            .animation(.gentle(calm, .snappy(duration: 0.3)), value: current)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Page \(current + 1) of \(count)")
        } else {
            dots
        }
    }

    private var dots: some View {
        VStack(spacing: 2) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? Color.ink : Color.inkFaint.opacity(0.7))
                    .frame(width: 4, height: index == current ? 16 : 4)
                    .frame(width: 20, height: index == current ? 22 : 12)
                    .contentShape(.rect)
                    .onTapGesture { select(index) }
            }
        }
        .animation(.gentle(calm, .snappy(duration: 0.3)), value: current)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(current + 1) of \(count)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: select(min(count - 1, current + 1))
            case .decrement: select(max(0, current - 1))
            @unknown default: break
            }
        }
    }
}

struct PageMetrics: Equatable {
    var height: CGFloat = 800
    var top: CGFloat = 120
    var bottom: CGFloat = 120
}

/// Where each page starts and ends in the scroll content, written by the pages as they lay out and
/// read by `ChapterSnap` when a scroll is about to settle.
nonisolated final class ChapterTops: @unchecked Sendable {
    static let space = "chapters"
    private let lock = NSLock()
    private var frames: [Int: ClosedRange<CGFloat>] = [:]

    func set(_ id: Int, _ range: ClosedRange<CGFloat>) {
        lock.lock(); frames[id] = range; lock.unlock()
    }

    var sorted: [ClosedRange<CGFloat>] {
        lock.lock(); defer { lock.unlock() }
        return frames.values.sorted { $0.lowerBound < $1.lowerBound }
    }
}

/// Reel-style settling: a flick moves exactly one page in its direction; a slow drag settles on the
/// nearest page. Inside a page taller than the screen, scrolling rests anywhere until its bottom
/// meets the bottom of the screen.
nonisolated struct ChapterSnap: ScrollTargetBehavior {
    let tops: ChapterTops

    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        let viewport = context.containerSize.height
        let maxOffset = max(0, context.contentSize.height - viewport)
        let chapters = tops.sorted
        guard !chapters.isEmpty, viewport > 0 else { return }
        let y = target.rect.minY
        let start = context.originalTarget.rect.minY

        var stops: [CGFloat] = []
        for chapter in chapters {
            stops.append(chapter.lowerBound)
            let lastFull = chapter.upperBound - viewport
            if lastFull > chapter.lowerBound + 1 {
                if y >= chapter.lowerBound && y <= lastFull { return }
                stops.append(lastFull)
            }
        }
        stops = stops.map { min(max(0, $0), maxOffset) }

        let velocity = context.velocity.dy
        var chosen = stops.min { abs($0 - y) < abs($1 - y) } ?? y
        if abs(velocity) > 0.3 {
            if velocity > 0, let next = stops.filter({ $0 > start + 1 }).min() { chosen = next }
            if velocity < 0, let previous = stops.filter({ $0 < start - 1 }).max() { chosen = previous }
        }
        target.rect.origin.y = chosen
    }
}

private struct PageMetricsKey: EnvironmentKey { static let defaultValue = PageMetrics() }
private struct ChapterTopsKey: EnvironmentKey { static let defaultValue = ChapterTops() }
extension EnvironmentValues {
    var pageMetrics: PageMetrics {
        get { self[PageMetricsKey.self] }
        set { self[PageMetricsKey.self] = newValue }
    }
    var chapterTops: ChapterTops {
        get { self[ChapterTopsKey.self] }
        set { self[ChapterTopsKey.self] = newValue }
    }
}

/// One page. Its content sits centred between the date and the bottom bar, with equal space above
/// and below; the page is exactly one screen tall unless its content needs more.
struct Chapter<Content: View>: View {
    let id: Int
    @ViewBuilder var content: () -> Content
    @Environment(\.pageMetrics) private var metrics
    @Environment(\.chapterTops) private var tops

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 24)
        .padding(.trailing, 34)
        .padding(.top, metrics.top)
        .padding(.bottom, metrics.bottom)
        .frame(maxWidth: .infinity, minHeight: metrics.height, alignment: .leading)
        .onGeometryChange(for: ClosedRange<CGFloat>.self) { proxy in
            let frame = proxy.frame(in: .named(ChapterTops.space))
            return frame.minY...max(frame.minY, frame.maxY)
        } action: { tops.set(id, $0) }
        .id(id)
    }
}
