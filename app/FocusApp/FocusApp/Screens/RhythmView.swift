import SwiftUI
import FocusModel

/// Four weeks of you, one pattern per screen. Every chapter leads with a plain-language headline
/// worked out from your own data, then the picture that shows it. Charts grow in as they arrive.
/// Patterns, never scores: nothing here grades you.
struct RhythmView: View {
    @Environment(AppModel.self) private var model
    @Environment(Customisation.self) private var custom
    @Environment(\.motionIsCalm) private var calm
    @State private var chapter: Int? = 0
    @State private var shown: Set<Int> = []
    @State private var editing = false

    private var history: LifeHistory { model.history }

    var body: some View {
        let pages = custom.settings.visiblePages(.rhythm)
        NavigationStack {
            PagedScreen(count: pages.count, page: $chapter) {
                Button { Haptics.shared.play(.tap); editing = true } label: {
                    Image(systemName: "slider.horizontal.3").frame(width: 22, height: 22)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .accessibilityLabel("Edit your patterns")
            } pages: {
                ForEach(Array(pages.enumerated()), id: \.element) { index, page in
                    pageView(page, index)
                }
            }
            .navigationDestination(isPresented: $editing) { PatternsView() }
        }
    }

    @ViewBuilder
    private func pageView(_ page: PageKind, _ id: Int) -> some View {
        switch page {
        case .rhythmIntro:
            Chapter(id: id) {
                Text("Your rhythm").eyebrow().reveal()
                HeroText(text: "Four weeks of you").reveal()
                Text(Copy.line(.rhythmIntro, ["count": "\(history.lastWeek.filter(\.baselineHit).count)"]))
                    .font(.subheadline).foregroundStyle(Color.inkSoft).reveal()
                card(id) { WeekRibbon(days: history.lastWeek, shown: $0) }
                    .padding(.top, 20)
                scrollHint
            }
        case .planDone:
            insight(id, eyebrow: "Planned and done", headline: planDoneHeadline, detail: Copy.line(.detailPlanDone)) {
                PlanDoneChart(days: history.lastFortnight, shown: $0)
            }
        case .brainWeather:
            insight(id, eyebrow: "Brain weather", headline: brainHeadline, detail: Copy.line(.detailBrain)) {
                BrainWeatherChart(days: history.days, shown: $0)
            }
        case .finishHours:
            insight(id, eyebrow: "When things get done", headline: peakHeadline, detail: Copy.line(.detailHours)) {
                HourHeat(days: history.days, shown: $0, summary: peakHeadline)
            }
        case .windowPattern:
            insight(id, eyebrow: "Your focus window", headline: windowHeadline, detail: Copy.line(.detailWindow)) {
                FocusPatternChart(model: model.focusModel, points: model.checkInPoints, shown: $0)
            }
        case .estimates:
            insight(id, eyebrow: "How long things take", headline: estimateHeadline, detail: Copy.line(.detailEstimates)) {
                EstimateChart(estimates: history.estimates, shown: $0)
            }
        case .sleep:
            insight(id, eyebrow: "Sleep and done", headline: sleepHeadline, detail: Copy.line(.detailSleep)) {
                SleepChart(days: history.lastFortnight, shown: $0)
            }
        case .logTimes:
            insight(id, eyebrow: "When you log", headline: logHeadline, detail: Copy.line(.detailLogs)) {
                LogTimesChart(days: history.days, shown: $0)
            }
        default:
            Chapter(id: id) { tuneChapter }
        }
    }

    // MARK: Building blocks

    private func insight<Chart: View>(_ id: Int, eyebrow: LocalizedStringKey, headline: String, detail: String,
                                      @ViewBuilder chart: @escaping (Bool) -> Chart) -> some View {
        Chapter(id: id) {
            Text(eyebrow).eyebrow().reveal()
            HeroText(text: headline, size: 24).reveal()
            card(id, chart: chart)
                .padding(.top, 14)
            Text(detail).font(.footnote).foregroundStyle(Color.inkSoft).reveal(delay: 0.1)
        }
    }

    private func card<Chart: View>(_ id: Int, @ViewBuilder chart: @escaping (Bool) -> Chart) -> some View {
        chart(shown.contains(id))
            .veil(padding: 16)
            .reveal(delay: 0.05)
            .onScrollVisibilityChange(threshold: 0.45) { visible in
                guard visible, !shown.contains(id) else { return }
                withAnimation(.gentle(calm, .smooth(duration: 0.9))) { _ = shown.insert(id) }
            }
    }

    /// The last page: the patterns above are yours to change.
    @ViewBuilder
    private var tuneChapter: some View {
        Text("Your patterns, your call").eyebrow().reveal()
        HeroText(text: Copy.line(.rhythmTuneTitle), size: 30).reveal()
        Text(Copy.line(.rhythmTuneBody))
            .font(.subheadline)
            .foregroundStyle(Color.inkSoft)
            .reveal(delay: 0.05)
        Button("Edit your patterns", systemImage: "slider.horizontal.3") { Haptics.shared.play(.tap); editing = true }
            .buttonStyle(.glassProminent)
            .foregroundStyle(.onAccent)
            .font(.subheadline)
            .padding(.top, 8)
            .reveal(delay: 0.1)
        Label(Copy.line(.rhythmFooter), systemImage: "lock")
            .font(.footnote)
            .foregroundStyle(Color.inkSoft)
            .padding(.top, 24)
            .reveal(delay: 0.15)
    }

    private var scrollHint: some View {
        Label("One pattern at a time, below", systemImage: "chevron.down")
            .font(.footnote)
            .foregroundStyle(Color.inkSoft)
            .padding(.top, 4)
            .symbolEffect(.wiggle.down, options: .nonRepeating, isActive: !calm && chapter == 0)
    }

    // MARK: Headlines, worked out from the person's own history

    private var brainHeadline: String {
        let lows = history.days.filter { $0.brain == 0 }.count
        let goods = history.days.filter { $0.brain == 2 }.count
        if lows == 0 { return "No low-brain days this month" }
        return "\(lows) low days, \(goods) good ones this month"
    }

    /// Leads with what got done, never with a completion score.
    private var planDoneHeadline: String {
        let done = history.lastFortnight.map(\.doneMinutes).reduce(0, +)
        let hours = Int((Double(done) / 60).rounded())
        return "\(hours) hours of real work in two weeks"
    }

    /// The three-hour stretch where the most things got finished across the four weeks.
    private var peakHeadline: String {
        var counts = [Int](repeating: 0, count: 24)
        for day in history.days { for hour in day.completionHours where (0..<24).contains(hour) { counts[hour] += 1 } }
        guard counts.contains(where: { $0 > 0 }) else { return "Your finishes will show up here" }
        let best = (6...19).max { a, b in counts[a..<(a + 3)].reduce(0, +) < counts[b..<(b + 3)].reduce(0, +) } ?? 9
        let start = Calendar.current.date(bySettingHour: best, minute: 0, second: 0, of: .now)!
        let end = start.addingTimeInterval(3 * 3600)
        return "Most things get finished between \(start.formatted(.dateTime.hour())) and \(end.formatted(.dateTime.hour()))"
    }

    private var windowHeadline: String {
        guard let w = model.window else { return "Your window is still being learned" }
        return "Best focus from \(w.start.formatted(.compactTime)) to \(w.bestFocusEnd.formatted(.compactTime)) most days"
    }

    private var estimateHeadline: String {
        let guess = history.estimates.map(\.guessMinutes).reduce(0, +)
        let actual = history.estimates.map(\.actualMinutes).reduce(0, +)
        guard guess > 0 else { return "How long things take" }
        let ratio = Double(actual) / Double(guess)
        return "Things take about \(ratio.formatted(.number.precision(.fractionLength(1))))× your first guess"
    }

    private var sleepHeadline: String {
        let days = history.days.filter { $0.plannedMinutes > 0 }
        let rested = days.filter { $0.sleepHours >= 7 }.map(\.donePercent)
        let short = days.filter { $0.sleepHours < 7 }.map(\.donePercent)
        guard !rested.isEmpty, !short.isEmpty else { return "Sleep and focus travel together" }
        let a = rested.reduce(0, +) / Double(rested.count)
        let b = short.reduce(0, +) / Double(short.count)
        let diff = Int(((a - b) * 100).rounded())
        return diff >= 5 ? "Days after 7 h+ of sleep go further" : "Sleep hasn’t changed much this month"
    }

    private var logHeadline: String {
        let minutes = history.days.compactMap(\.logged).map { date -> Int in
            let c = Calendar.current.dateComponents([.hour, .minute], from: date)
            return (c.hour ?? 0) * 60 + (c.minute ?? 0)
        }.sorted()
        guard !minutes.isEmpty else { return "No logs yet" }
        let median = minutes[minutes.count / 2]
        let time = Calendar.current.date(bySettingHour: median / 60, minute: median % 60, second: 0, of: .now)!
        return "You usually log around \(time.formatted(date: .omitted, time: .shortened))"
    }
}
