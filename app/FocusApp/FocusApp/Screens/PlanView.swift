import SwiftUI
import FocusModel

/// The last seven days, one at a time: step between days with the arrows, then flick through the
/// day's shape, what's waiting (or how it went) and how the week's baselines went.
struct PlanView: View {
    @Environment(AppModel.self) private var model
    @Environment(Customisation.self) private var custom
    @Environment(\.motionIsCalm) private var calm

    @State private var chapter: Int? = 0
    @State private var selectedID: Int?
    @State private var riverShown = false
    @State private var beadsShown = false

    private var week: [LifeHistory.Day] { model.history.lastWeek }
    private var selected: LifeHistory.Day { week.first { $0.id == selectedID } ?? week.last! }
    private var selectedIndex: Int { week.firstIndex { $0.id == selected.id } ?? week.count - 1 }

    var body: some View {
        let pages = custom.settings.visiblePages(.plan)
        NavigationStack {
            PagedScreen(count: pages.count, page: $chapter) {
                EmptyView()
            } pages: {
                ForEach(Array(pages.enumerated()), id: \.element) { index, page in
                    Chapter(id: index) {
                        switch page {
                        case .planRiver: riverChapter
                        case .planDetails: detailChapter
                        case .planWeek: weekChapter
                        default: header
                        }
                    }
                }
            }
        }
    }

    // MARK: Page 0 — one day

    @ViewBuilder
    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                Text(selected.isToday ? "Plan" : selected.date.formatted(.dateTime.day().month(.wide))).eyebrow()
                HeroText(text: selected.isToday ? "Today" : selected.date.formatted(.dateTime.weekday(.wide)))
                    .id(selected.id)
                    .transition(.opacity)
            }
            Spacer(minLength: 8)
            GlassEffectContainer(spacing: 6) {
                HStack(spacing: 6) {
                    Button { step(-1) } label: { Image(systemName: "chevron.left").frame(width: 18, height: 18) }
                        .disabled(selectedIndex == 0)
                        .accessibilityLabel("Previous day")
                    Button { step(1) } label: { Image(systemName: "chevron.right").frame(width: 18, height: 18) }
                        .disabled(selected.isToday)
                        .accessibilityLabel("Next day")
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
            }
        }
        .reveal()

        HStack(alignment: .top, spacing: 44) {
            figure(label: selected.isToday ? "To-do" : "Done", value: firstFigure, unit: firstUnit)
            figure(label: "Focus", value: focusFigure, unit: "window")
        }
        .padding(.top, 22)
        .reveal(delay: 0.08)

        Group {
            if selected.isToday {
                DayStrip(items: todayItems, windowStart: warmStart, windowEnd: model.window?.end, now: model.now)
            } else {
                DayStrip(marks: completionMarks(selected), windowStart: selected.windowStart, windowEnd: selected.windowEnd)
            }
        }
        .veil(padding: 16)
        .padding(.top, 22)
        .reveal(delay: 0.12)
    }

    private func step(_ delta: Int) {
        let index = min(max(0, selectedIndex + delta), week.count - 1)
        Haptics.shared.play(.choose)
        withAnimation(.gentle(calm, .smooth)) {
            selectedID = week[index].id
            riverShown = false
        }
        withAnimation(.gentle(calm, .smooth.delay(0.1))) { riverShown = true }
    }

    private var firstFigure: String {
        selected.isToday ? "\(model.taskCount - model.doneCount)" : "\(Int((selected.donePercent * 100).rounded()))%"
    }
    private var firstUnit: String {
        selected.isToday ? (model.taskCount - model.doneCount == 1 ? "task" : "tasks") : "of plan"
    }
    private var focusFigure: String {
        let start = selected.isToday ? model.window?.start : selected.windowStart
        let end = selected.isToday ? model.window?.end : selected.windowEnd
        guard let start, let end else { return "None" }
        return Duration.seconds(end.timeIntervalSince(start)).formatted(.units(allowed: [.hours, .minutes], width: .narrow))
    }

    private func figure(label: LocalizedStringKey, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).eyebrow()
            Text(value)
                .figureFont(30)
                .foregroundStyle(Color.ink)
                .contentTransition(.numericText())
            Text(unit).font(.footnote).foregroundStyle(Color.inkSoft)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Chapter 1 — the day as a river

    @ViewBuilder
    private var riverChapter: some View {
        Text("The shape of the day").eyebrow().reveal()
        Group {
            if selected.isToday {
                DayRiver(items: todayItems, warmStart: warmStart, windowStart: model.window?.start,
                         bestEnd: model.window?.bestFocusEnd, windowEnd: model.window?.end,
                         dose: model.todaysDose?.takenAt, now: model.now, shown: riverShown)
            } else {
                DayRiver(items: [], windowStart: selected.windowStart, windowEnd: selected.windowEnd,
                         dose: selected.logged, marks: completionMarks(selected), shown: riverShown)
            }
        }
        .veil(padding: 16)
        .reveal(delay: 0.05)
        .onScrollVisibilityChange(threshold: 0.3) { visible in
            if visible && !riverShown { riverShown = true }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(riverLabel)
    }

    private var warmStart: Date? {
        guard let w = model.window else { return nil }
        return w.dose.addingTimeInterval(TimeInterval(w.onsetMinutes * 60))
    }

    private var todayItems: [DayRiver.Item] {
        model.plan.blocks.map { block in
            DayRiver.Item(id: block.id, title: block.title, start: block.interval.start, end: block.interval.end,
                          color: Explainer.tint(for: block), done: model.isDone(block))
        }
    }

    private func completionMarks(_ day: LifeHistory.Day) -> [Date] {
        day.completionHours.compactMap { Calendar.current.date(bySettingHour: $0, minute: 30, second: 0, of: day.date) }
    }

    private var riverLabel: String {
        if selected.isToday {
            return "Today: \(model.plan.blocks.count) blocks. " + (model.window.map { "Focus window \($0.start.formatted(date: .omitted, time: .shortened)) to \($0.end.formatted(date: .omitted, time: .shortened))." } ?? "")
        }
        return "\(selected.completionHours.count) things finished" + (selected.windowStart.map { ", focus window from \($0.formatted(date: .omitted, time: .shortened))" } ?? ", a medication-free day")
    }

    // MARK: Chapter 2 — what's waiting / how it went

    @ViewBuilder
    private var detailChapter: some View {
        if selected.isToday {
            Text("Waiting for you").eyebrow().reveal()
            HeroText(text: model.tasks.count == 1 ? "One task" : "\(model.tasks.count) tasks", size: 30).reveal()
            RowGroup {
                ForEach(model.tasks) { task in
                    let done = model.completed.contains(task.id)
                    InfoRow(label: LocalizedStringKey(task.isBaseline ? "\(demandLabel(task.demand)), a must today" : demandLabel(task.demand)),
                            title: task.title, dot: Kind.color(demand: task.demand.rawValue, fixed: false)) {
                        ValueChip(text: done ? "Done" : "\(task.estimateMinutes) min", systemImage: done ? "checkmark" : nil)
                    }
                    .opacity(done ? 0.55 : 1)
                }
            }
            .padding(.top, 8)
            .reveal(delay: 0.05)
        } else {
            Text("How it went").eyebrow().reveal()
            HeroText(text: selected.baselineHit ? "The musts got done" : "A lighter day", size: 30).reveal()
            RowGroup {
                InfoRow(label: "Logged") { ValueChip(text: selected.logged?.formatted(.compactTime) ?? "Medication-free") }
                InfoRow(label: "Sleep") { ValueChip(text: selected.sleepHours.formatted(.number.precision(.fractionLength(1))) + " h") }
                InfoRow(label: "Brain weather") {
                    ValueChip(text: ["Low", "Okay", "Good"][selected.brain], systemImage: ["cloud.drizzle", "cloud.sun", "sun.max"][selected.brain])
                }
                InfoRow(label: "Planned") { ValueChip(text: hours(selected.plannedMinutes)) }
                InfoRow(label: "Done") { ValueChip(text: hours(selected.doneMinutes)) }
            }
            .padding(.top, 8)
            .reveal(delay: 0.05)
        }
    }

    private func demandLabel(_ demand: FocusDemand) -> String {
        switch demand {
        case .deep: "Deep"
        case .medium: "Medium"
        case .light: "Light"
        case .body: "Body"
        }
    }

    private func hours(_ minutes: Int) -> String {
        Duration.seconds(minutes * 60).formatted(.units(allowed: [.hours, .minutes], width: .narrow))
    }

    // MARK: Chapter 3 — the week's baselines

    @ViewBuilder
    private var weekChapter: some View {
        let hits = week.filter(\.baselineHit).count
        Text("This week").eyebrow().reveal()
        HeroText(text: Copy.line(.planWeekHeadline, ["count": "\(hits)"]), size: 30).reveal()
        HStack(spacing: 16) {
            ForEach(Array(week.enumerated()), id: \.element.id) { index, day in
                VStack(spacing: 8) {
                    Circle()
                        .fill(day.baselineHit ? Color.zoneBest : Color.clear)
                        .overlay(Circle().strokeBorder(day.baselineHit ? Color.clear : Color.inkFaint, lineWidth: 0.75))
                        .frame(width: 12, height: 12)
                        .scaleEffect(beadsShown ? 1 : 0.2)
                        .opacity(beadsShown ? 1 : 0)
                        .animation(.gentle(calm, .bouncy.delay(Double(index) * 0.07)), value: beadsShown)
                    Text(day.date, format: .dateTime.weekday(.narrow))
                        .font(.caption2)
                        .foregroundStyle(day.isToday ? Color.ink : Color.inkSoft)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(day.date.formatted(.dateTime.weekday(.wide))): \(day.baselineHit ? "counted" : "not counted")")
            }
        }
        .padding(.top, 16)
        .reveal(delay: 0.05)
        .onScrollVisibilityChange(threshold: 0.5) { visible in
            if visible && !beadsShown {
                beadsShown = true
                if !calm { Haptics.shared.play(.land) }
            }
        }
        Text(Copy.line(.planWeekExplainer))
            .font(.footnote)
            .foregroundStyle(Color.inkSoft)
            .padding(.top, 16)
            .reveal(delay: 0.1)
    }
}
