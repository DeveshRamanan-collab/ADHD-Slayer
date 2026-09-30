import SwiftUI

/// The shape of one day, top to bottom: a thin rail carries the focus window as a band of light
/// (warm-up → best → lighter), blocks float beside it in their kind's colour, finished work is
/// ticked, and a line marks now. Past days show the window and a dot for each thing finished.
struct DayRiver: View {
    struct Item: Identifiable {
        let id: String
        let title: String
        let start: Date
        let end: Date
        let color: Color
        var done = false
    }

    let items: [Item]
    /// Warm-up begins (dose + onset); nil for past days where only the window itself is known.
    var warmStart: Date?
    /// Best focus begins.
    var windowStart: Date?
    var bestEnd: Date?
    var windowEnd: Date?
    var dose: Date?
    var marks: [Date] = []
    var now: Date?
    var shown: Bool
    var fromHour = 7
    var toHour = 21

    @ScaledMetric(relativeTo: .caption) private var hourHeight: CGFloat = 24
    @Environment(\.motionIsCalm) private var calm

    private let labelWidth: CGFloat = 40
    private let railWidth: CGFloat = 6
    private var railX: CGFloat { labelWidth + 6 }
    private var blockX: CGFloat { railX + railWidth + 12 }
    private var totalHeight: CGFloat { CGFloat(toHour - fromHour) * hourHeight }

    private func y(_ date: Date) -> CGFloat {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        let h = Double(c.hour ?? 0) + Double(c.minute ?? 0) / 60
        return CGFloat(min(max(h - Double(fromHour), 0), Double(toHour - fromHour))) * hourHeight
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            hourLabels
            Capsule().fill(Color.track)
                .frame(width: railWidth, height: totalHeight)
                .padding(.leading, railX)
            windowBand
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                block(item)
                    .padding(.top, y(item.start))
                    .padding(.leading, blockX)
                    .opacity(shown ? 1 : 0)
                    .offset(x: shown || calm ? 0 : 18)
                    .animation(.gentle(calm, .smooth(duration: 0.6).delay(0.25 + Double(index) * 0.06)), value: shown)
            }
            ForEach(Array(marks.enumerated()), id: \.offset) { index, mark in
                Circle().fill(Color.ink)
                    .frame(width: 5, height: 5)
                    .padding(.top, y(mark) - 2.5)
                    .padding(.leading, railX + railWidth / 2 - 2.5)
                    .scaleEffect(shown ? 1 : 0.01)
                    .animation(.gentle(calm, .bouncy.delay(0.5 + Double(index) * 0.05)), value: shown)
            }
            if let dose {
                Circle().fill(Color.veilSolid)
                    .overlay(Circle().strokeBorder(Color.ink, lineWidth: 1.5))
                    .frame(width: 10, height: 10)
                    .padding(.top, y(dose) - 5)
                    .padding(.leading, railX + railWidth / 2 - 5)
                    .scaleEffect(shown ? 1 : 0.01)
                    .animation(.gentle(calm, .timingCurve(0.45, 1.45, 0.8, 1, duration: 0.35).delay(0.2)), value: shown)
            }
            if let now, y(now) > 0, y(now) < totalHeight {
                HStack(spacing: 0) {
                    Circle().fill(Color.ink).frame(width: 6, height: 6)
                    Rectangle().fill(Color.ink.opacity(0.35)).frame(height: 0.5)
                }
                .padding(.top, y(now) - 3)
                .padding(.leading, railX + railWidth / 2 - 3)
            }
        }
        .frame(maxWidth: .infinity, minHeight: totalHeight, alignment: .topLeading)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }

    private var hourLabels: some View {
        ForEach(Array(stride(from: fromHour, through: toHour, by: 2)), id: \.self) { hour in
            Text(Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: .now)!, format: .dateTime.hour())
                .font(.caption2.monospacedDigit())
                .foregroundStyle(Color.inkSoft)
                .frame(width: labelWidth, alignment: .trailing)
                .padding(.top, CGFloat(hour - fromHour) * hourHeight - 7)
        }
    }

    @ViewBuilder
    private var windowBand: some View {
        if let windowStart, let windowEnd {
            let top = y(warmStart ?? windowStart), bottom = y(windowEnd)
            let span = max(bottom - top, 1)
            let bestFrom = min(max((y(windowStart) - top) / span, 0.04), 0.5)
            let bestTo = min(max(((bestEnd.map(y) ?? (bottom - span * 0.25)) - top) / span, bestFrom + 0.05), 0.96)
            LinearGradient(stops: [
                .init(color: .zoneWarm, location: 0),
                .init(color: .zoneBest, location: bestFrom),
                .init(color: .zoneBest, location: bestTo),
                .init(color: .zoneLight, location: 1)
            ], startPoint: .top, endPoint: .bottom)
            .frame(width: railWidth, height: shown ? span : 0, alignment: .top)
            .clipShape(.capsule)
            .padding(.top, top)
            .padding(.leading, railX)
            .animation(.gentle(calm, .smooth(duration: 1.1).delay(0.1)), value: shown)
        }
    }

    private func block(_ item: Item) -> some View {
        let height = max(y(item.end) - y(item.start) - 3, 22)
        return HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 1).fill(item.color).frame(width: 2)
            Text(item.title)
                .font(.caption)
                .foregroundStyle(Color.ink)
                .strikethrough(item.done, color: Color.inkSoft)
                .lineLimit(height > 44 ? 2 : 1)
            Spacer(minLength: 4)
            if item.done {
                Image(systemName: "checkmark").font(.caption2.weight(.bold)).foregroundStyle(Color.inkSoft)
            } else {
                Text(item.start, format: .dateTime.hour().minute())
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(Color.inkSoft)
            }
        }
        .padding(.leading, 8)
        .padding(.trailing, 10)
        .frame(height: height)
        .background(item.color.opacity(item.done ? 0.07 : 0.14), in: .rect(cornerRadius: min(8, height / 2)))
        .opacity(item.done ? 0.7 : 1)
    }
}

/// The day in one line, 7 am → 10 pm: the focus window glows underneath, blocks sit on top in their
/// kind's colour (or, for past days, a dot for each thing finished), and a tick marks now.
struct DayStrip: View {
    var items: [DayRiver.Item] = []
    var marks: [Date] = []
    var windowStart: Date?
    var windowEnd: Date?
    var now: Date?
    private let from = 7.0, to = 22.0

    private func x(_ date: Date, _ width: CGFloat) -> CGFloat {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        let h = Double(c.hour ?? 0) + Double(c.minute ?? 0) / 60
        return CGFloat(min(max((h - from) / (to - from), 0), 1)) * width
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.track).frame(height: 20)
                    if let windowStart, let windowEnd {
                        Capsule()
                            .fill(LinearGradient(colors: [.zoneWarm, .zoneBest, .zoneLight], startPoint: .leading, endPoint: .trailing))
                            .opacity(0.35)
                            .frame(width: max(4, x(windowEnd, w) - x(windowStart, w)), height: 20)
                            .offset(x: x(windowStart, w))
                    }
                    ForEach(items) { item in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(item.color.opacity(item.done ? 0.4 : 0.9))
                            .frame(width: max(3, x(item.end, w) - x(item.start, w) - 1.5), height: 10)
                            .offset(x: x(item.start, w))
                    }
                    ForEach(Array(marks.enumerated()), id: \.offset) { _, mark in
                        Circle().fill(Color.ink).frame(width: 5, height: 5).offset(x: x(mark, w) - 2.5)
                    }
                    if let now {
                        Capsule().fill(Color.ink).frame(width: 1.5, height: 28).offset(x: x(now, w) - 0.75)
                    }
                }
                .frame(height: 28)
            }
            .frame(height: 28)
            HStack(spacing: 0) {
                let labels = ["7a", "10a", "1p", "4p", "7p", "10p"]
                ForEach(labels.indices, id: \.self) { i in
                    if i > 0 { Spacer(minLength: 0) }
                    Text(labels[i]).font(.caption2.monospacedDigit()).foregroundStyle(Color.inkSoft)
                }
            }
        }
        .accessibilityHidden(true)
    }
}
