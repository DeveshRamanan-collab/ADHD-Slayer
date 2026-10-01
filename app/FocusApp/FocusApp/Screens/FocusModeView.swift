import SwiftUI
import FocusModel

/// The focus room: one task, one ring, one first step. Opened full screen from the Now card with a
/// zoom transition, so no tab bar or other chrome competes for attention.
struct FocusModeView: View {
    @Environment(AppModel.self) private var model
    @Environment(Customisation.self) private var custom
    @Environment(\.motionIsCalm) private var calm
    @Environment(\.dismiss) private var dismiss
    @State private var titleShown = 0.0

    var body: some View {
        NavigationStack {
            room
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close", systemImage: "chevron.down") { dismiss() }
                    }
                }
        }
    }

    private var room: some View {
        TimelineView(.periodic(from: .now, by: 15)) { _ in
            let now = model.now
            Group {
                if let block = model.nowBlock {
                    content(block, now: now)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Now").eyebrow()
                        HeroText(text: Copy.line(.nowGap), size: 30)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(24)
                }
            }
        }
        .background { SkyBackground(phase: model.skyPhase) }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.gentle(calm, .easeOut(duration: 1.0).delay(0.15))) { titleShown = 1 }
        }
    }

    private func content(_ block: Block, now: Date) -> some View {
        let remaining = max(0, block.interval.end.timeIntervalSince(now))
        let minutesLeft = Int((remaining / 60).rounded(.up))
        let wrapUp = minutesLeft <= 5
        return ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(Explainer.demandWord(for: block)).eyebrow()
                HeroText(text: block.title, size: 34, reveal: titleShown)
                    .padding(.top, 6)
                if let next = model.nextBlock {
                    Text(Copy.line(.nowThen, ["task": next.title, "time": next.interval.start.formatted(.compactTime)]))
                        .font(.footnote)
                        .foregroundStyle(Color.inkSoft)
                        .padding(.top, 6)
                }

                timer(fraction: remaining / block.interval.duration, minutesLeft: minutesLeft, wrapUp: wrapUp)
                    .padding(.vertical, 48)

                RowGroup {
                    InfoRow(label: "Time", title: "\(block.interval.start.formatted(.compactTime)) to \(block.interval.end.formatted(.compactTime))")
                    InfoRow(label: "Session", title: block.demand == .deep ? "High focus" : "Light focus")
                    if custom.settings.showFirstStep {
                        InfoRow(label: "First step", title: Explainer.firstStep(for: block))
                    }
                }

                ActionRow {
                    Button("Done", systemImage: "checkmark") {
                        Haptics.shared.play(.complete)
                        withAnimation(.gentle(calm, .bouncy)) { model.markDone(block) }
                        dismiss()
                    }
                    .buttonStyle(.glassProminent)
                    .foregroundStyle(.onAccent)
                    Button("Done for now", systemImage: "pause") {
                        Haptics.shared.play(.tap)
                        model.markDoneForNow(block)
                        dismiss()
                    }
                    .buttonStyle(.glass)
                }
                .font(.subheadline)
                .padding(.top, 20)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
    }

    /// Ring, bar or just the number, from Customise, Focus mode.
    @ViewBuilder
    private func timer(fraction: Double, minutesLeft: Int, wrapUp: Bool) -> some View {
        switch custom.settings.ringStyle {
        case .ring:
            TimeRing(remaining: fraction, minutesLeft: minutesLeft, isWrapUp: wrapUp, diameter: 150, lineWidth: 3)
        case .bar:
            VStack(alignment: .leading, spacing: 8) {
                Text("\(minutesLeft) min left").figureFont(30).foregroundStyle(Color.ink).contentTransition(.numericText())
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.track)
                        Capsule().fill(wrapUp ? Color.honey : Color.zoneBest).frame(width: max(6, geo.size.width * min(1, max(0, fraction))))
                    }
                }
                .frame(height: 6)
            }
            .accessibilityElement(children: .combine)
        case .number:
            VStack(alignment: .leading, spacing: 2) {
                Text("\(minutesLeft)").figureFont(72).foregroundStyle(wrapUp ? Color.honey : Color.ink).contentTransition(.numericText())
                Text("minutes left").font(.footnote).foregroundStyle(Color.inkSoft)
            }
            .accessibilityElement(children: .combine)
        }
    }
}
