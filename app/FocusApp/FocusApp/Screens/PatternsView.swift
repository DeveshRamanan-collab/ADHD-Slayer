import SwiftUI
import Charts
import FocusModel
import FocusPlanning

/// The workshop behind the calm screens: everything the app has learned about your days, laid out
/// as a collage of editable instruments. Busier than anywhere else in the app on purpose, since it's
/// where you go to look under the hood — but built from the same type, veils and palette.
/// Every change feeds the scheduler straight away; nothing here touches medication.
struct PatternsView: View {
    @Environment(AppModel.self) private var model
    @State private var confirmReset = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your patterns, yours to edit").eyebrow()
                    HeroText(text: "Tune what the app has learned", size: 30)
                    Text("Changes reach today’s plan straight away. This only changes planning, never your medication.")
                        .font(.footnote)
                        .foregroundStyle(Color.inkSoft)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)

                WindowEditorCard()

                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 12) {
                        MealRuleCard()
                        BreathingRoomCard()
                    }
                    VStack(spacing: 12) {
                        PackingCard()
                        LearningCard()
                    }
                }

                DayDialCard()

                EstimatesCard()

                HStack(alignment: .top, spacing: 12) {
                    AfterWindowCard()
                    PatternCard(index: "09", title: "Start over") {
                        Text("Put every pattern back to what the app learned.")
                            .font(.caption)
                            .foregroundStyle(Color.inkSoft)
                        Button("Reset") { confirmReset = true }
                            .buttonStyle(.glass)
                            .font(.footnote)
                            .disabled(model.tuning == AppModel.Tuning())
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .background {
            ZStack {
                SkyBackground(phase: model.skyPhase)
                BlueprintGrid().ignoresSafeArea()
            }
        }
        .toolbar(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Reset your patterns?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset all patterns", role: .destructive) { model.tuning = AppModel.Tuning() }
        } message: {
            Text("Your focus window, estimates and spacing go back to what the app learned. Today’s plan updates.")
        }
    }
}

// MARK: - Card chrome

/// A collage card: a numbered label and a veil. No background figures: everything written on the
/// page means something.
struct PatternCard<Content: View>: View {
    let index: String
    let title: LocalizedStringKey
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).eyebrow()
                Spacer(minLength: 6)
                Text(index)
                    .font(.system(.caption, design: .serif))
                    .italic()
                    .foregroundStyle(Color.inkSoft)
                    .accessibilityHidden(true)
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .clipShape(.rect(cornerRadius: 22, style: .continuous))
        .veil(padding: 0)
    }
}

/// Minus / plus in glass, for stepping a value.
struct StepperPair: View {
    let decrement: () -> Void
    let increment: () -> Void
    var canDecrement = true
    var canIncrement = true
    var label: String

    var body: some View {
        GlassEffectContainer(spacing: 6) {
            HStack(spacing: 6) {
                Button(action: decrement) { Image(systemName: "minus").frame(width: 14, height: 14) }
                    .disabled(!canDecrement)
                    .accessibilityLabel("Less \(label)")
                Button(action: increment) { Image(systemName: "plus").frame(width: 14, height: 14) }
                    .disabled(!canIncrement)
                    .accessibilityLabel("More \(label)")
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .controlSize(.small)
        }
    }
}

/// Hairline graph paper behind the workshop.
struct BlueprintGrid: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            stride(from: 0, through: size.width, by: 24).forEach { path.move(to: CGPoint(x: $0, y: 0)); path.addLine(to: CGPoint(x: $0, y: size.height)) }
            stride(from: 0, through: size.height, by: 24).forEach { path.move(to: CGPoint(x: 0, y: $0)); path.addLine(to: CGPoint(x: size.width, y: $0)) }
            context.stroke(path, with: .color(Color.ink.opacity(0.04)), lineWidth: 0.5)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private func minutesText(_ m: Int) -> String {
    Duration.seconds(m * 60).formatted(.units(allowed: [.hours, .minutes], width: .narrow))
}

// MARK: - 01 Focus window

/// Drag the two handles — where focus starts and where it ends — over the learned curve and your
/// check-in answers. Letting go re-plans today around your window.
struct WindowEditorCard: View {
    @Environment(AppModel.self) private var model
    @Environment(\.motionIsCalm) private var calm
    @State private var onset = 0
    @State private var offset = 0
    @State private var dragging: Handle?
    @State private var loaded = false

    enum Handle { case start, end }

    private var rampUp: Int { model.focusModel.rampUp }
    private var rampDown: Int { model.focusModel.rampDown }
    private var isOverride: Bool { model.tuning.windowOverride != nil }
    private var startsAfter: Int { onset + rampUp / 2 }
    private var endsAfter: Int { offset - rampDown / 2 }

    private struct Sample: Identifiable { let id: Int; let minutes: Double; let yours: Double; let learned: Double }

    private var samples: [Sample] {
        let learned = model.learnedWindow
        return stride(from: 0, through: 780, by: 10).map { m in
            Sample(id: m, minutes: Double(m),
                   yours: FocusCurve.effect(minutesAfterDose: Double(m), onset: Double(onset), offset: Double(offset),
                                            rampUp: Double(rampUp), rampDown: Double(rampDown)),
                   learned: FocusCurve.effect(minutesAfterDose: Double(m), onset: Double(learned.onset), offset: Double(learned.offset),
                                              rampUp: Double(rampUp), rampDown: Double(rampDown)))
        }
    }

    var body: some View {
        PatternCard(index: "01", title: "Focus window") {
            chart
            HStack(alignment: .top, spacing: 22) {
                figure("Starts helping", minutesText(startsAfter))
                figure("Helps for", minutesText(max(0, endsAfter - startsAfter)))
                if let dose = model.todaysDose?.takenAt {
                    // Same edges as the Today screen: best focus from full effect, window until it fades out.
                    let from = dose.addingTimeInterval(TimeInterval((onset + rampUp) * 60))
                    let to = dose.addingTimeInterval(TimeInterval(offset * 60))
                    figure("Today", "\(from.formatted(.compactTime)) to \(to.formatted(.compactTime))")
                }
            }
            HStack(spacing: 10) {
                Text(isOverride ? "Your own window. The app keeps learning quietly." : "Learned from \(model.focusModel.checkInCount) check-ins. Drag a handle to set your own.")
                    .font(.caption)
                    .foregroundStyle(Color.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
                if isOverride {
                    Button("Use learned") {
                        model.tuning.windowOverride = nil
                        load()
                    }
                    .buttonStyle(.glass)
                    .font(.caption)
                }
            }
        }
        .onAppear { if !loaded { load(); loaded = true } }
        .sensoryFeedback(.selection, trigger: onset / 15 * 1000 + offset / 15) { _, _ in dragging != nil && Haptics.shared.isEnabled }
    }

    private func load() {
        if let o = model.tuning.windowOverride, o.count == 2 { onset = o[0]; offset = o[1] }
        else { (onset, offset) = model.learnedWindow }
    }

    private func figure(_ label: LocalizedStringKey, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(Color.inkSoft)
            Text(value).figureFont(20).foregroundStyle(Color.ink)
        }
        .accessibilityElement(children: .combine)
    }

    private var chart: some View {
        Chart {
            ForEach(samples) { s in
                AreaMark(x: .value("Minutes", s.minutes), yStart: .value("Floor", 0), yEnd: .value("Yours", s.yours),
                         series: .value("Layer", "Yours area"))
                    .interpolationMethod(.monotone)
                    .foregroundStyle(LinearGradient(colors: [.zoneWarm.opacity(0.35), .zoneBest.opacity(0.45), .zoneLight.opacity(0.3)],
                                                    startPoint: .leading, endPoint: .trailing))
            }
            ForEach(samples) { s in
                LineMark(x: .value("Minutes", s.minutes), y: .value("Learned", s.learned), series: .value("Layer", "Learned"))
                    .interpolationMethod(.monotone)
                    .foregroundStyle(Color.ink.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
            }
            ForEach(samples) { s in
                LineMark(x: .value("Minutes", s.minutes), y: .value("Yours", s.yours), series: .value("Layer", "Yours"))
                    .interpolationMethod(.monotone)
                    .foregroundStyle(Color.ink)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
            }
            ForEach(model.checkInPoints) { point in
                PointMark(x: .value("Minutes", Double(point.minute)), y: .value("Answer", point.answer == .yes ? 1.08 : -0.08))
                    .symbolSize(10)
                    .foregroundStyle(Color.ink.opacity(0.45))
            }
            RuleMark(x: .value("Start", Double(startsAfter)))
                .foregroundStyle(Color.ink.opacity(0.25))
                .lineStyle(StrokeStyle(lineWidth: 0.5))
            RuleMark(x: .value("End", Double(endsAfter)))
                .foregroundStyle(Color.ink.opacity(0.25))
                .lineStyle(StrokeStyle(lineWidth: 0.5))
            PointMark(x: .value("Start", Double(startsAfter)), y: .value("Half", 0.5))
                .symbol { handle(active: dragging == .start) }
            PointMark(x: .value("End", Double(endsAfter)), y: .value("Half", 0.5))
                .symbol { handle(active: dragging == .end) }
        }
        .chartXScale(domain: 0...780)
        .chartYScale(domain: -0.15...1.15)
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks(values: [0, 120, 240, 360, 480, 600, 720]) { value in
                AxisGridLine().foregroundStyle(Color.ink.opacity(0.06))
                AxisValueLabel {
                    if let m = value.as(Int.self) { Text(m == 0 ? "log" : "\(m / 60)h") }
                }
                .font(.caption2)
                .foregroundStyle(Color.inkSoft)
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle().fill(.clear).contentShape(.rect)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard let plot = proxy.plotFrame else { return }
                                let x = value.location.x - geo[plot].origin.x
                                guard let minutes: Double = proxy.value(atX: x) else { return }
                                let m = Int((minutes / 5).rounded()) * 5
                                if dragging == nil {
                                    dragging = abs(m - startsAfter) <= abs(m - endsAfter) ? .start : .end
                                }
                                move(dragging!, toMinutes: m)
                            }
                            .onEnded { _ in
                                dragging = nil
                                model.tuning.windowOverride = [onset, offset]
                            }
                    )
            }
        }
        .frame(height: 170)
        .accessibilityRepresentation {
            VStack {
                Stepper("Focus starts helping after \(minutesText(startsAfter))") {
                    move(.start, toMinutes: startsAfter + 5); model.tuning.windowOverride = [onset, offset]
                } onDecrement: {
                    move(.start, toMinutes: startsAfter - 5); model.tuning.windowOverride = [onset, offset]
                }
                Stepper("Focus helps until \(minutesText(endsAfter)) after logging") {
                    move(.end, toMinutes: endsAfter + 5); model.tuning.windowOverride = [onset, offset]
                } onDecrement: {
                    move(.end, toMinutes: endsAfter - 5); model.tuning.windowOverride = [onset, offset]
                }
            }
        }
    }

    private func move(_ handle: Handle, toMinutes m: Int) {
        switch handle {
        case .start:
            onset = min(max(0, m - rampUp / 2), offset - rampUp - rampDown - 60)
        case .end:
            offset = min(max(onset + rampUp + rampDown + 60, m + rampDown / 2), 780)
        }
    }

    private func handle(active: Bool) -> some View {
        Circle()
            .fill(Color.veilSolid)
            .overlay(Circle().strokeBorder(Color.ink, lineWidth: active ? 2 : 1.25))
            .frame(width: active ? 22 : 18, height: active ? 22 : 18)
            .animation(.gentle(calm, .snappy), value: active)
    }
}

// MARK: - 02 Meal rule

struct MealRuleCard: View {
    @Environment(AppModel.self) private var model

    private var minutes: Int { model.tuning.mealRuleMinutes }
    private let range = 180...420

    var body: some View {
        PatternCard(index: "02", title: "Eat by") {
            ZStack {
                Circle().trim(from: 0, to: 0.75)
                    .stroke(Color.track, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                Circle().trim(from: 0, to: 0.75 * Double(minutes - range.lowerBound) / Double(range.upperBound - range.lowerBound))
                    .stroke(Color.zoneBest, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
            .rotationEffect(.degrees(135))
            .overlay {
                VStack(spacing: 0) {
                    Text(minutesText(minutes)).figureFont(20).foregroundStyle(Color.ink)
                    Text("after logging").font(.caption2).foregroundStyle(Color.inkSoft)
                }
            }
            .frame(width: 104, height: 104)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Eat within \(minutesText(minutes)) of logging")

            if let dose = model.todaysDose?.takenAt {
                Text("Today ≈ \(dose.addingTimeInterval(TimeInterval(minutes * 60)).formatted(.compactTime))")
                    .font(.caption)
                    .foregroundStyle(Color.inkSoft)
            }
            StepperPair(decrement: { model.tuning.mealRuleMinutes -= 30 },
                        increment: { model.tuning.mealRuleMinutes += 30 },
                        canDecrement: minutes > range.lowerBound, canIncrement: minutes < range.upperBound,
                        label: "time before eating")
        }
    }
}

// MARK: - 03 Packing

struct PackingCard: View {
    @Environment(AppModel.self) private var model
    private var share: Double { model.tuning.fillCap }

    var body: some View {
        PatternCard(index: "03", title: "How full") {
            HStack(alignment: .bottom, spacing: 14) {
                ZStack(alignment: .bottom) {
                    Capsule().fill(Color.track)
                    Capsule()
                        .fill(LinearGradient(colors: [.zoneBest, .zoneWarm.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                        .frame(height: 118 * share)
                }
                .frame(width: 26, height: 118)
                .overlay(Capsule().strokeBorder(Color.veilStroke, lineWidth: 0.5))
                VStack(alignment: .leading, spacing: 2) {
                    Text(share, format: .percent.precision(.fractionLength(0)))
                        .figureFont(26).foregroundStyle(Color.ink)
                        .contentTransition(.numericText())
                    Text("of focus time gets planned; the rest stays open")
                        .font(.caption2).foregroundStyle(Color.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityElement(children: .combine)
            StepperPair(decrement: { model.tuning.fillCap = (share - 0.05).rounded(toPlaces: 2) },
                        increment: { model.tuning.fillCap = (share + 0.05).rounded(toPlaces: 2) },
                        canDecrement: share > 0.4, canIncrement: share < 0.8, label: "planned focus time")
        }
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let p = pow(10, Double(places)); return (self * p).rounded() / p
    }
}

// MARK: - 04 Breathing room

struct BreathingRoomCard: View {
    @Environment(AppModel.self) private var model
    private var minutes: Int { model.tuning.transitionMinutes }

    var body: some View {
        PatternCard(index: "04", title: "Between things") {
            HStack(spacing: CGFloat(2 + minutes) * 0.8) {
                ForEach([Color.zoneBest, .zoneLight, .sage], id: \.self) { color in
                    RoundedRectangle(cornerRadius: 3).fill(color.opacity(0.55)).frame(height: 30)
                }
            }
            .frame(height: 34)
            .animation(.smooth, value: minutes)
            .accessibilityHidden(true)
            Text(minutesText(minutes)).figureFont(20).foregroundStyle(Color.ink)
            Text("to switch between blocks").font(.caption2).foregroundStyle(Color.inkSoft)
            StepperPair(decrement: { model.tuning.transitionMinutes -= 5 },
                        increment: { model.tuning.transitionMinutes += 5 },
                        canDecrement: minutes > 0, canIncrement: minutes < 30, label: "time between blocks")
        }
    }
}

// MARK: - 05 Learning

struct LearningCard: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let summary = model.focusModel.summary
        let checkIns = model.focusModel.checkInCount
        let certainty = max(0, 1 - Double(max(summary.startUncertainty, summary.endUncertainty)) / 90)
        PatternCard(index: "05", title: "How sure") {
            ZStack {
                ring(Double(min(checkIns, 40)) / 40, width: 3, color: .ink.opacity(0.8)).frame(width: 96, height: 96)
                ring(certainty, width: 3, color: .zoneBest).frame(width: 78, height: 78)
                ring(model.tuning.windowOverride == nil ? 1 : 0.02, width: 3, color: .zoneLight).frame(width: 60, height: 60)
                Text("\(checkIns)").figureFont(18).foregroundStyle(Color.ink)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .leading, spacing: 3) {
                legend(.ink.opacity(0.8), "\(checkIns) check-ins")
                legend(.zoneBest, "±\(max(summary.startUncertainty, summary.endUncertainty)) min")
                legend(.zoneLight, model.tuning.windowOverride == nil ? "Using learned" : "Using yours")
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func ring(_ value: Double, width: CGFloat, color: Color) -> some View {
        ZStack {
            Circle().stroke(Color.track, lineWidth: width)
            Circle().trim(from: 0, to: value).stroke(color, style: StrokeStyle(lineWidth: width, lineCap: .round)).rotationEffect(.degrees(-90))
        }
    }

    private func legend(_ color: Color, _ text: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 5, height: 5)
            Text(text).font(.caption2).foregroundStyle(Color.inkSoft)
        }
    }
}

// MARK: - 06 Your day, as a dial

/// The whole learned day on a 24-hour dial: sleep, the log, the focus window, the meal rule, when
/// things usually get finished, and now. Moves as you edit the cards around it.
struct DayDialCard: View {
    @Environment(AppModel.self) private var model

    private func fraction(_ date: Date) -> Double {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (Double(c.hour ?? 0) + Double(c.minute ?? 0) / 60) / 24
    }

    var body: some View {
        let days = model.history.lastFortnight
        let wake = days.map { fraction($0.wake) }.reduce(0, +) / Double(max(days.count, 1))
        let sleep = days.map(\.sleepHours).reduce(0, +) / Double(max(days.count, 1)) / 24
        var counts = [Int](repeating: 0, count: 24)
        for day in model.history.days { for h in day.completionHours where (0..<24).contains(h) { counts[h] += 1 } }
        let peak = Double(counts.max() ?? 1)

        return PatternCard(index: "06", title: "Your day, as learned") {
            HStack(alignment: .center, spacing: 18) {
                ZStack {
                    // Hour ticks
                    ForEach(0..<24, id: \.self) { h in
                        Rectangle()
                            .fill(Color.ink.opacity(h % 6 == 0 ? 0.5 : 0.18))
                            .frame(width: h % 6 == 0 ? 1 : 0.5, height: h % 6 == 0 ? 9 : 5)
                            .offset(y: -97)
                            .rotationEffect(.degrees(Double(h) * 15))
                    }
                    ForEach([0, 6, 12, 18], id: \.self) { h in
                        Text(h == 0 ? "12a" : h == 12 ? "12p" : h < 12 ? "\(h)a" : "\(h - 12)p")
                            .font(.system(size: 9, design: .serif))
                            .foregroundStyle(Color.inkSoft)
                            .rotationEffect(.degrees(-Double(h) * 15))
                            .offset(y: -112)
                            .rotationEffect(.degrees(Double(h) * 15))
                    }
                    arc(from: wake - sleep, to: wake, width: 16, color: .slate.opacity(0.35))
                        .frame(width: 176, height: 176)
                    if let w = model.window {
                        arc(from: fraction(w.dose.addingTimeInterval(TimeInterval(w.onsetMinutes * 60))), to: fraction(w.end), width: 8,
                            style: AnyShapeStyle(AngularGradient(colors: [.zoneWarm, .zoneBest, .zoneBest, .zoneLight],
                                                                 center: .center,
                                                                 startAngle: .degrees(fraction(w.dose.addingTimeInterval(TimeInterval(w.onsetMinutes * 60))) * 360),
                                                                 endAngle: .degrees(fraction(w.end) * 360))))
                            .frame(width: 148, height: 148)
                    }
                    // Finishes, as a ring of dots sized by how often things got done in that hour
                    ForEach(0..<24, id: \.self) { h in
                        let v = Double(counts[h]) / peak
                        Circle().fill(Color.ink.opacity(0.2 + 0.6 * v))
                            .frame(width: 2 + 5 * v, height: 2 + 5 * v)
                            .offset(y: -56)
                            .rotationEffect(.degrees((Double(h) + 0.5) * 15))
                            .opacity(counts[h] == 0 ? 0 : 1)
                    }
                    if let dose = model.todaysDose?.takenAt {
                        marker(at: fraction(dose), radius: 74, symbol: "circle.fill", size: 7)
                        marker(at: fraction(dose.addingTimeInterval(TimeInterval(model.tuning.mealRuleMinutes * 60))),
                               radius: 96, symbol: "fork.knife", size: 10)
                    }
                    // Now hand
                    Rectangle().fill(Color.ink.opacity(0.7)).frame(width: 1, height: 86)
                        .offset(y: -43)
                        .rotationEffect(.degrees(fraction(model.now) * 360))
                    Circle().fill(Color.ink).frame(width: 5, height: 5)
                }
                .frame(width: 230, height: 230)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(dialLabel(wake: wake, sleep: sleep))

                VStack(alignment: .leading, spacing: 7) {
                    key(Color.slate.opacity(0.5), "Sleep")
                    key(Color.zoneBest, "Focus window")
                    key(Color.ink.opacity(0.6), "Finishes")
                    HStack(spacing: 6) {
                        Image(systemName: "fork.knife").font(.system(size: 8)).foregroundStyle(Color.ink)
                        Text("Eat by").font(.caption2).foregroundStyle(Color.inkSoft)
                    }
                    key(Color.ink, "Now")
                }
                .accessibilityHidden(true)
            }
        }
    }

    private func dialLabel(wake: Double, sleep: Double) -> String {
        let wakeHour = Int(wake * 24)
        return "You usually wake around \(wakeHour) and sleep about \(Int((sleep * 24).rounded())) hours."
    }

    private func arc(from a: Double, to b: Double, width: CGFloat, color: Color) -> some View {
        arc(from: a, to: b, width: width, style: AnyShapeStyle(color))
    }

    @ViewBuilder
    private func arc(from a: Double, to b: Double, width: CGFloat, style: AnyShapeStyle) -> some View {
        let start = (a.truncatingRemainder(dividingBy: 1) + 1).truncatingRemainder(dividingBy: 1)
        let end = (b.truncatingRemainder(dividingBy: 1) + 1).truncatingRemainder(dividingBy: 1)
        ZStack {
            if start <= end {
                Circle().trim(from: start, to: end).stroke(style, style: StrokeStyle(lineWidth: width, lineCap: .butt))
            } else {
                Circle().trim(from: start, to: 1).stroke(style, style: StrokeStyle(lineWidth: width, lineCap: .butt))
                Circle().trim(from: 0, to: end).stroke(style, style: StrokeStyle(lineWidth: width, lineCap: .butt))
            }
        }
        .rotationEffect(.degrees(-90))
    }

    private func marker(at f: Double, radius: CGFloat, symbol: String, size: CGFloat) -> some View {
        Image(systemName: symbol)
            .font(.system(size: size))
            .foregroundStyle(Color.ink)
            .rotationEffect(.degrees(-f * 360))
            .offset(y: -radius)
            .rotationEffect(.degrees(f * 360))
    }

    private func key(_ color: Color, _ text: LocalizedStringKey) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(text).font(.caption2).foregroundStyle(Color.inkSoft)
        }
    }
}

// MARK: - 07 Estimates

/// Each task: your guess, what the plan will use, and what your history says. Slide to set the buffer.
struct EstimatesCard: View {
    @Environment(AppModel.self) private var model
    @State private var drafts: [String: Double] = [:]

    private var tasks: [TaskSnapshot] { model.tasks.filter { $0.pinnedInterval == nil && $0.demand != .body } }

    var body: some View {
        PatternCard(index: "07", title: "How long things take") {
            ForEach(tasks) { task in
                row(task)
                if task.id != tasks.last?.id {
                    Rectangle().fill(Color.veilStroke).frame(height: 0.5)
                }
            }
        }
    }

    private func buffer(_ task: TaskSnapshot) -> Double {
        drafts[task.id.raw] ?? model.tuning.estimateBuffers[task.id.raw] ?? 1
    }

    @ViewBuilder
    private func row(_ task: TaskSnapshot) -> some View {
        let value = buffer(task)
        let planned = Int((Double(task.estimateMinutes) * value).rounded())
        let learned = model.learnedRatio(for: task.id)
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(task.title).font(.subheadline).foregroundStyle(Color.ink).lineLimit(1)
                Spacer(minLength: 8)
                Text("×\(value.formatted(.number.precision(.fractionLength(1))))")
                    .figureFont(17).foregroundStyle(Color.ink)
            }
            // Guess → planned, on a shared 0–3 h scale
            GeometryReader { geo in
                let scale = geo.size.width / 180
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.track).frame(height: 2)
                    Capsule().fill(Color.zoneBest.opacity(0.7))
                        .frame(width: max(2, CGFloat(min(planned, 180)) * scale), height: 2)
                    Circle().strokeBorder(Color.ink, lineWidth: 1).frame(width: 7, height: 7)
                        .offset(x: CGFloat(min(task.estimateMinutes, 180)) * scale - 3.5)
                    Circle().fill(Color.zoneBest).frame(width: 7, height: 7)
                        .offset(x: CGFloat(min(planned, 180)) * scale - 3.5)
                    if let learned {
                        Rectangle().fill(Color.ink.opacity(0.5)).frame(width: 1, height: 10)
                            .offset(x: CGFloat(min(Double(task.estimateMinutes) * learned, 180)) * scale)
                    }
                }
                .frame(height: 10)
            }
            .frame(height: 10)
            .accessibilityHidden(true)
            HStack(spacing: 8) {
                Text("Guess \(minutesText(task.estimateMinutes)), plan \(minutesText(planned))")
                    .font(.caption2).foregroundStyle(Color.inkSoft)
                Spacer(minLength: 4)
                if let learned, abs(learned - value) >= 0.05 {
                    Button("Learned ×\(learned.formatted(.number.precision(.fractionLength(1))))") {
                        let rounded = (learned * 10).rounded() / 10
                        drafts[task.id.raw] = nil
                        model.tuning.estimateBuffers[task.id.raw] = rounded
                    }
                    .buttonStyle(.plain)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.ink)
                }
            }
            Slider(value: Binding(get: { value }, set: { drafts[task.id.raw] = ($0 * 10).rounded() / 10 }),
                   in: 1...2, step: 0.1) { editing in
                if !editing, let draft = drafts[task.id.raw] {
                    model.tuning.estimateBuffers[task.id.raw] = draft
                    drafts[task.id.raw] = nil
                }
            }
            .tint(Color.zoneBest)
            .controlSize(.mini)
            .accessibilityLabel("Buffer for \(task.title)")
            .accessibilityValue("times \(value.formatted(.number.precision(.fractionLength(1))))")
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 08 After the window

struct AfterWindowCard: View {
    @Environment(AppModel.self) private var model
    private var minutes: Int { model.tuning.afterWindowBufferMinutes }

    var body: some View {
        PatternCard(index: "08", title: "After focus") {
            HStack(spacing: 0) {
                Rectangle().fill(LinearGradient(colors: [.zoneBest, .zoneLight], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 44, height: 6)
                Rectangle().fill(Color.zoneLight.opacity(0.25))
                    .frame(width: CGFloat(minutes) * 1.2, height: 6)
                    .overlay(alignment: .leading) {
                        HStack(spacing: 3) {
                            ForEach(0..<max(1, minutes / 5), id: \.self) { _ in
                                Rectangle().fill(Color.ink.opacity(0.25)).frame(width: 0.5, height: 6)
                            }
                        }
                    }
                    .clipped()
            }
            .clipShape(.capsule)
            .animation(.smooth, value: minutes)
            .accessibilityHidden(true)
            Text(minutesText(minutes)).figureFont(20).foregroundStyle(Color.ink)
            Text("of easy time before anything demanding").font(.caption2).foregroundStyle(Color.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            StepperPair(decrement: { model.tuning.afterWindowBufferMinutes -= 5 },
                        increment: { model.tuning.afterWindowBufferMinutes += 5 },
                        canDecrement: minutes > 0, canIncrement: minutes < 60, label: "time after focus")
        }
    }
}
