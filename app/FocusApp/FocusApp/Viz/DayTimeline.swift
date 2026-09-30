import SwiftUI

/// A day type at a glance, 5 am to 1 am: the productive windows glow, the unproductive gaps between
/// them are hatched, each dose sits at its time in its medication's colour, the wind-down shows as a
/// moon where focus wraps up, and a second moon marks when sleep usually becomes possible.
struct DayTimeline: View {
    let schedule: DaySchedule
    let doses: [(minute: Int, color: Color, symbol: String)]
    var now: Int?
    var compact = false
    private let from = 5 * 60, to = 25 * 60

    private func x(_ minute: Int, _ width: CGFloat) -> CGFloat {
        CGFloat(min(max(minute - from, 0), to - from)) / CGFloat(to - from) * width
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                let w = geo.size.width
                let barY: CGFloat = compact ? 8 : 22
                let barH: CGFloat = compact ? 10 : 16
                ZStack(alignment: .topLeading) {
                    Capsule().fill(Color.track).frame(width: w, height: barH).offset(y: barY)
                    ForEach(Array(schedule.windows.enumerated()), id: \.offset) { _, window in
                        Capsule()
                            .fill(LinearGradient(colors: [.zoneWarm, .zoneBest, .zoneBest, .zoneLight], startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(4, x(window.end, w) - x(window.start, w)), height: barH)
                            .offset(x: x(window.start, w), y: barY)
                    }
                    ForEach(Array(schedule.gaps.enumerated()), id: \.offset) { _, gap in
                        Hatch()
                            .stroke(Color.inkFaint.opacity(0.6), lineWidth: 1)
                            .frame(width: max(4, x(gap.end, w) - x(gap.start, w)), height: barH)
                            .clipShape(.capsule)
                            .offset(x: x(gap.start, w), y: barY)
                        if !compact {
                            Text("low focus").font(.system(size: 9)).foregroundStyle(Color.inkSoft)
                                .fixedSize()
                                .offset(x: x(gap.start, w), y: barY + barH + 3)
                        }
                    }
                    ForEach(Array(doses.enumerated()), id: \.offset) { _, dose in
                        VStack(spacing: 2) {
                            if !compact {
                                Image(systemName: dose.symbol).font(.system(size: 9)).foregroundStyle(dose.color)
                            }
                            Circle().fill(dose.color).overlay(Circle().strokeBorder(Color.veilSolid, lineWidth: 1.5))
                                .frame(width: compact ? 8 : 10, height: compact ? 8 : 10)
                        }
                        .offset(x: x(dose.minute, w) - (compact ? 4 : 5), y: compact ? barY + 1 : 2)
                    }
                    if let sleep = schedule.sleepReadyAt {
                        Image(systemName: "moon.zzz")
                            .font(.system(size: compact ? 9 : 11))
                            .foregroundStyle(Color.slate)
                            .offset(x: x(sleep, w) - 6, y: compact ? barY - 12 : barY + barH + 2)
                    }
                    if let now, now > from, now < to {
                        Capsule().fill(Color.ink).frame(width: 1.5, height: barH + 10).offset(x: x(now, w), y: barY - 5)
                    }
                }
            }
            .frame(height: compact ? 26 : 56)
            if !compact {
                HStack(spacing: 0) {
                    let labels = ["5a", "9a", "1p", "5p", "9p", "1a"]
                    ForEach(labels.indices, id: \.self) { i in
                        if i > 0 { Spacer(minLength: 0) }
                        Text(labels[i]).font(.caption2.monospacedDigit()).foregroundStyle(Color.inkSoft)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(summary)
    }

    private var summary: String {
        let windows = schedule.windows.map { "\(ClockMinutes.text($0.start)) to \(ClockMinutes.text($0.end))" }.joined(separator: ", then ")
        var parts = [windows.isEmpty ? "No productive window set" : "Productive \(windows)"]
        if !schedule.gaps.isEmpty { parts.append("\(schedule.gaps.count) low-focus stretch\(schedule.gaps.count == 1 ? "" : "es") in between") }
        if let sleep = schedule.sleepReadyAt { parts.append("sleep usually possible from \(ClockMinutes.text(sleep))") }
        return parts.joined(separator: ". ")
    }
}

/// Diagonal hatching for unproductive stretches.
nonisolated struct Hatch: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        var x = rect.minX - rect.height
        while x < rect.maxX {
            p.move(to: CGPoint(x: x, y: rect.maxY))
            p.addLine(to: CGPoint(x: x + rect.height, y: rect.minY))
            x += 5
        }
        return p
    }
}
