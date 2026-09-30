import SwiftUI
import Charts
import FocusModel
import FocusPlanning

// Shared chart styling: thin, soft, no grid clutter, the sky's palette. Every chart takes `shown`
// and grows in from zero when its chapter scrolls into view.

private extension View {
    func quietAxes() -> some View {
        self
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel().font(.caption2).foregroundStyle(Color.inkSoft)
                }
            }
            .chartYAxis(.hidden)
    }
}

/// One label a week, kept away from the plot edges so none is clipped.
private func weeklyTicks(_ days: [LifeHistory.Day]) -> [Date] {
    stride(from: 3, to: days.count, by: 7).map { days[$0].date }
}

// MARK: 1 · This week — seven skies

/// Each day is a vertical strip of sky from 6 am (top) to 11 pm (bottom): the focus window glows
/// where it was, dots mark what got done, and a bead under the day fills when baseline was met.
struct WeekRibbon: View {
    let days: [LifeHistory.Day]
    var shown: Bool
    var height: CGFloat = 170
    @Environment(\.motionIsCalm) private var calm

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                VStack(spacing: 8) {
                    column(day)
                        .animation(.gentle(calm, .smooth(duration: 0.8).delay(Double(index) * 0.06)), value: shown)
                    Text(day.date, format: .dateTime.weekday(.narrow))
                        .font(.caption.weight(day.isToday ? .semibold : .regular))
                        .foregroundStyle(day.isToday ? Color.ink : .inkSoft)
                    Circle()
                        .fill(day.baselineHit ? Color.zoneBest : Color.clear)
                        .overlay(Circle().strokeBorder(Color.inkFaint, lineWidth: day.baselineHit ? 0 : 1))
                        .frame(width: 7, height: 7)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(label(day))
            }
        }
    }

    private func y(_ date: Date?) -> CGFloat {
        guard let date else { return 0 }
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        let h = Double(c.hour ?? 0) + Double(c.minute ?? 0) / 60
        return CGFloat(min(max((h - 6) / 17, 0), 1)) * height
    }

    private func column(_ day: LifeHistory.Day) -> some View {
        ZStack(alignment: .top) {
            Capsule().fill(Color.track)
            if let e = day.windowEnd, let dose = day.logged {
                Capsule()
                    .fill(LinearGradient(colors: [.zoneWarm, .zoneBest, .zoneBest, .zoneLight], startPoint: .top, endPoint: .bottom))
                    .frame(height: max(8, (y(e) - y(dose)) * (shown ? 1 : 0.02)))
                    .offset(y: y(dose))
            }
            ForEach(Array(day.completionHours.enumerated()), id: \.offset) { _, hour in
                Circle().fill(Color.ink.opacity(0.85)).frame(width: 5, height: 5)
                    .offset(y: CGFloat(Double(hour - 6) / 17) * height - 2.5)
                    .opacity(shown ? 1 : 0)
            }
        }
        .frame(width: 22, height: height)
        .overlay {
            if day.isToday { Capsule().strokeBorder(Color.ink.opacity(0.6), lineWidth: 1.5).padding(-4) }
        }
    }

    private func label(_ day: LifeHistory.Day) -> String {
        let name = day.date.formatted(.dateTime.weekday(.wide))
        guard let s = day.windowStart, let e = day.windowEnd else { return "\(name): routine day, \(day.completionHours.count) things done" }
        return "\(name): focus \(s.formatted(date: .omitted, time: .shortened)) to \(e.formatted(date: .omitted, time: .shortened)), \(day.completionHours.count) things done\(day.baselineHit ? ", baseline met" : "")"
    }
}

// MARK: 2 · Plan and done

struct PlanDoneChart: View {
    let days: [LifeHistory.Day]
    var shown: Bool

    var body: some View {
        Chart(days) { day in
            BarMark(x: .value("Day", day.date, unit: .day), yStart: .value("Start", 0),
                    yEnd: .value("Planned", shown ? Double(day.plannedMinutes) / 60 : 0), width: .ratio(0.28))
                .foregroundStyle(Color.track)
                .clipShape(Capsule())
            BarMark(x: .value("Day", day.date, unit: .day), yStart: .value("Start", 0),
                    yEnd: .value("Done", shown ? Double(day.doneMinutes) / 60 : 0), width: .ratio(0.28))
                .foregroundStyle(day.isToday ? Color.zoneLight : Color.zoneBest)
                .clipShape(Capsule())
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisValueLabel(format: .dateTime.weekday(.narrow)).font(.caption2).foregroundStyle(Color.inkSoft)
            }
        }
        .chartYAxis(.hidden)
        .frame(height: 140)
        .accessibilityLabel("Planned and done hours for the last two weeks")
    }
}

// MARK: 3 · Brain weather

struct BrainWeatherChart: View {
    let days: [LifeHistory.Day]
    var shown: Bool

    var body: some View {
        Chart {
            ForEach(days) { day in
                AreaMark(x: .value("Day", day.date, unit: .day), yStart: .value("Base", 0),
                         yEnd: .value("Brain", shown ? Double(day.brain) + 0.15 : 0.15))
                    .interpolationMethod(.monotone)
                    .foregroundStyle(LinearGradient(colors: [.zoneBest.opacity(0.45), .zoneWarm.opacity(0.05)], startPoint: .top, endPoint: .bottom))
                LineMark(x: .value("Day", day.date, unit: .day), y: .value("Brain", shown ? Double(day.brain) + 0.15 : 0.15))
                    .interpolationMethod(.monotone)
                    .foregroundStyle(Color.ink.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round))
                PointMark(x: .value("Day", day.date, unit: .day), y: .value("Brain", shown ? Double(day.brain) + 0.15 : 0.15))
                    .symbolSize(day.brain == 0 ? 60 : 24)
                    .foregroundStyle(day.brain == 0 ? Color.zoneLight : Color.ink)
            }
        }
        .chartYScale(domain: 0...2.4)
        .chartYAxis {
            AxisMarks(position: .leading, values: [0.15, 1.15, 2.15]) { value in
                AxisValueLabel {
                    let v = value.as(Double.self) ?? 0
                    Image(systemName: v < 1 ? "cloud.drizzle" : v < 2 ? "cloud.sun" : "sun.max")
                        .foregroundStyle(Color.inkSoft)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: weeklyTicks(days)) { _ in
                AxisValueLabel(format: .dateTime.day().month(.abbreviated)).font(.caption2).foregroundStyle(Color.inkSoft)
            }
        }
        .frame(height: 130)
        .accessibilityLabel("Brain weather for the last four weeks")
    }
}

// MARK: 4 · When things get done

/// Weekday × hour grid of soft dots; bigger, warmer dots are hours where more got done.
struct HourHeat: View {
    let days: [LifeHistory.Day]
    var shown: Bool
    /// Spoken summary for VoiceOver, worked out by the caller from the same days.
    var summary: String = "When things got done, by weekday and hour"
    private let hours = Array(7...21)

    private var counts: [[Int]] {
        var grid = Array(repeating: Array(repeating: 0, count: 15), count: 7)
        for day in days {
            let row = (Calendar.current.component(.weekday, from: day.date) + 5) % 7 // Mon = 0
            for hour in day.completionHours where (7...21).contains(hour) { grid[row][hour - 7] += 1 }
        }
        return grid
    }

    var body: some View {
        let grid = counts
        let maxCount = Double(max(1, grid.flatMap { $0 }.max() ?? 1))
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 0) {
                Text(" ").frame(width: 20)
                ForEach(hours, id: \.self) { h in
                    Text(h % 5 == 2 ? (h == 12 ? "12" : "\(h > 12 ? h - 12 : h)") : "")
                        .font(.caption2).foregroundStyle(Color.inkSoft).frame(maxWidth: .infinity)
                }
            }
            ForEach(0..<7, id: \.self) { row in
                HStack(spacing: 0) {
                    Text(["M", "T", "W", "T", "F", "S", "S"][row]).font(.caption2).foregroundStyle(Color.inkSoft).frame(width: 20, alignment: .leading)
                    ForEach(0..<15, id: \.self) { col in
                        let v = Double(grid[row][col]) / maxCount
                        Circle()
                            .fill(v == 0 ? Color.track : Color.zoneBest.opacity(0.35 + 0.65 * v))
                            .frame(width: 4 + 9 * sqrt(v) * (shown ? 1 : 0), height: 4 + 9 * sqrt(v) * (shown ? 1 : 0))
                            .frame(maxWidth: .infinity, minHeight: 16)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(summary)
    }
}

// MARK: 5 · Focus pattern

struct FocusPatternChart: View {
    let model: FocusWindowModel
    let points: [AppModel.CheckInPoint]
    var shown: Bool

    private struct Sample: Identifiable { let id: Int; let hours: Double; let p: Double; let low: Double; let high: Double }

    private var samples: [Sample] {
        let s = model.summary
        return stride(from: 0, through: 720, by: 10).map { m in
            let wide = FocusCurve.effect(minutesAfterDose: Double(m), onset: Double(s.onset80.lowerBound), offset: Double(s.offset80.upperBound), rampUp: Double(model.rampUp), rampDown: Double(model.rampDown))
            let narrow = FocusCurve.effect(minutesAfterDose: Double(m), onset: Double(s.onset80.upperBound), offset: Double(s.offset80.lowerBound), rampUp: Double(model.rampUp), rampDown: Double(model.rampDown))
            return Sample(id: m, hours: Double(m) / 60, p: model.predictiveYes(minutesAfterDose: Double(m)),
                          low: 0.1 + 0.8 * min(wide, narrow), high: 0.1 + 0.8 * max(wide, narrow))
        }
    }

    var body: some View {
        Chart {
            ForEach(samples) { s in
                AreaMark(x: .value("Hours", s.hours), yStart: .value("Floor", 0), yEnd: .value("Said working", shown ? s.p : 0),
                         series: .value("Layer", "Said working"))
                    .interpolationMethod(.monotone)
                    .foregroundStyle(LinearGradient(colors: [.zoneWarm.opacity(0.7), .zoneBest.opacity(0.7), .zoneBest.opacity(0.6), .zoneLight.opacity(0.5)], startPoint: .leading, endPoint: .trailing))
            }
            ForEach(samples) { s in
                AreaMark(x: .value("Hours", s.hours), yStart: .value("Low", shown ? s.low : 0), yEnd: .value("High", shown ? s.high : 0),
                         series: .value("Layer", "Uncertainty"))
                    .interpolationMethod(.monotone)
                    .foregroundStyle(Color.ink.opacity(0.12))
            }
            ForEach(samples) { s in
                LineMark(x: .value("Hours", s.hours), y: .value("Said working", shown ? s.p : 0), series: .value("Layer", "Line"))
                    .interpolationMethod(.monotone)
                    .foregroundStyle(Color.ink)
                    .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round))
            }
            ForEach(points) { point in
                PointMark(x: .value("Hours", Double(point.minute) / 60), y: .value("Answer", point.answer == .yes ? 0.92 : 0.08))
                    .symbolSize(14)
                    .foregroundStyle(Color.ink.opacity(shown ? 0.55 : 0))
            }
        }
        .chartYScale(domain: 0...1)
        .chartXAxis {
            AxisMarks(values: [0, 2, 4, 6, 8, 10, 12]) { value in
                AxisValueLabel { if let h = value.as(Double.self) { Text(h == 0 ? "logged" : "\(Int(h))h") } }
                    .font(.caption2).foregroundStyle(Color.inkSoft)
            }
        }
        .chartYAxis(.hidden)
        .frame(height: 130)
    }
}

// MARK: 6 · How long things take

struct EstimateChart: View {
    let estimates: [LifeHistory.Estimate]
    var shown: Bool

    var body: some View {
        Chart(estimates) { e in
            RuleMark(xStart: .value("Guess", e.guessMinutes), xEnd: .value("Actual", shown ? e.actualMinutes : e.guessMinutes), y: .value("Task", e.id))
                .lineStyle(StrokeStyle(lineWidth: 8, lineCap: .round))
                .foregroundStyle(LinearGradient(colors: [.zoneWarm.opacity(0.6), .zoneBest], startPoint: .leading, endPoint: .trailing))
            PointMark(x: .value("Guess", e.guessMinutes), y: .value("Task", e.id))
                .symbol { Circle().strokeBorder(Color.ink, lineWidth: 1.5).background(Circle().fill(Color.veilSolid)).frame(width: 11, height: 11) }
            PointMark(x: .value("Actual", shown ? e.actualMinutes : e.guessMinutes), y: .value("Task", e.id))
                .symbol { Circle().fill(Color.ink).frame(width: 11, height: 11) }
                .annotation(position: .trailing, spacing: 6) {
                    Text("×\(Double(e.actualMinutes) / Double(e.guessMinutes), format: .number.precision(.fractionLength(1)))")
                        .font(.caption2.weight(.semibold)).foregroundStyle(Color.inkSoft)
                        .opacity(shown ? 1 : 0)
                }
        }
        .chartXAxis {
            AxisMarks(values: [0, 30, 60, 90, 120]) { value in
                AxisValueLabel(anchor: .top) { if let m = value.as(Int.self) { Text(m == 0 ? "0" : m % 60 == 0 ? "\(m / 60)h" : "\(m)m") } }
                    .font(.caption2).foregroundStyle(Color.inkSoft)
            }
        }
        .chartYAxis {
            AxisMarks { _ in AxisValueLabel().font(.caption).foregroundStyle(Color.ink) }
        }
        .chartXScale(domain: 0...135)
        .frame(height: 230)
    }
}

// MARK: 7 · Sleep and your days

struct SleepChart: View {
    let days: [LifeHistory.Day]
    var shown: Bool

    var body: some View {
        Chart {
            ForEach(days) { day in
                BarMark(x: .value("Day", day.date, unit: .day), yStart: .value("Zero", 0),
                        yEnd: .value("Sleep", shown ? day.sleepHours : 0), width: .ratio(0.28))
                    .foregroundStyle(Color.slate.opacity(0.55))
                    .clipShape(Capsule())
            }
            ForEach(days) { day in
                LineMark(x: .value("Day", day.date, unit: .day), y: .value("Plan done", shown ? day.donePercent * 10 : 0))
                    .interpolationMethod(.monotone)
                    .foregroundStyle(Color.zoneBest)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                PointMark(x: .value("Day", day.date, unit: .day), y: .value("Plan done", shown ? day.donePercent * 10 : 0))
                    .symbolSize(18).foregroundStyle(Color.zoneBest)
            }
        }
        .chartYScale(domain: 0...10)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 3)) { _ in
                AxisValueLabel(format: .dateTime.day().month(.abbreviated)).font(.caption2).foregroundStyle(Color.inkSoft)
            }
        }
        .chartYAxis(.hidden)
        .frame(height: 130)
        .accessibilityLabel("Hours slept and share of plan done, last fourteen days")
    }
}

// MARK: 8 · Your log times

struct LogTimesChart: View {
    let days: [LifeHistory.Day]
    var shown: Bool

    private func minutes(_ d: Date) -> Double {
        let c = Calendar.current.dateComponents([.hour, .minute], from: d)
        return Double((c.hour ?? 0) * 60 + (c.minute ?? 0))
    }

    var body: some View {
        let logged = days.compactMap { d in d.logged.map { (d, minutes($0)) } }
        let sorted = logged.map(\.1).sorted()
        let low = sorted.isEmpty ? 480 : sorted[sorted.count / 4]
        let high = sorted.isEmpty ? 510 : sorted[(sorted.count * 3) / 4]
        Chart {
            RectangleMark(yStart: .value("From", low), yEnd: .value("To", high))
                .foregroundStyle(Color.zoneWarm.opacity(0.22))
            ForEach(logged, id: \.0.id) { day, m in
                PointMark(x: .value("Day", day.date, unit: .day), y: .value("Logged", shown ? m : low))
                    .symbolSize(40)
                    .foregroundStyle(Color.ink.opacity(0.8))
            }
        }
        .chartYScale(domain: ((sorted.first ?? low) - 20)...((sorted.last ?? high) + 20))
        .chartYAxis {
            AxisMarks(position: .leading, values: [low, high]) { value in
                AxisValueLabel {
                    let m = Int(value.as(Double.self) ?? 0)
                    Text(Calendar.current.date(bySettingHour: m / 60, minute: m % 60, second: 0, of: .now)!, format: .dateTime.hour().minute())
                }
                .font(.caption2).foregroundStyle(Color.inkSoft)
            }
        }
        .chartPlotStyle { $0.clipped() }
        .chartXAxis {
            AxisMarks(values: weeklyTicks(days)) { _ in
                AxisValueLabel(format: .dateTime.day().month(.abbreviated)).font(.caption2).foregroundStyle(Color.inkSoft)
            }
        }
        .frame(height: 130)
        .accessibilityLabel("Times you logged, last four weeks")
    }
}

// MARK: Today in shapes

struct DayShapes: View {
    struct Slice: Identifiable { let id: String; let minutes: Double; let color: Color }
    let slices: [Slice]
    let centreFigure: String
    let centreCaption: String
    var shown: Bool
    var diameter: CGFloat = 132

    var body: some View {
        Chart(slices) { slice in
            SectorMark(angle: .value("Minutes", shown ? slice.minutes : (slice.id == "Open" ? 1 : 0)),
                       innerRadius: .ratio(0.84), angularInset: 1.5)
                .cornerRadius(3)
                .foregroundStyle(slice.color)
        }
        .chartLegend(.hidden)
        .chartBackground { _ in
            VStack(spacing: 0) {
                Text(centreFigure).figureFont(24).foregroundStyle(Color.ink)
                Text(centreCaption).font(.caption2).foregroundStyle(Color.inkSoft).multilineTextAlignment(.center)
            }
            .frame(width: diameter * 0.66)
        }
        .frame(width: diameter, height: diameter)
    }
}
