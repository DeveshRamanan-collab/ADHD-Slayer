import SwiftUI
import FocusModel

/// The focus room: one task, one ring, one first step. Opened full screen from the Now card with a
/// zoom transition, so no tab bar or other chrome competes for attention.
///
/// The session it runs is shared with the Lock Screen and the Dynamic Island
/// (`LiveActivityController`): opening the room starts Focus mode's Live Activity, closing it ends
/// it, and Done or +5 min pressed there shows up here. Tap the timer to pause or resume; press and
/// hold it for five more minutes.
struct FocusModeView: View {
    @Environment(AppModel.self) private var model
    @Environment(Customisation.self) private var custom
    @Environment(\.motionIsCalm) private var calm
    @Environment(\.dismiss) private var dismiss
    @State private var titleShown = 0.0

    private var live: LiveActivityController { .shared }

    var body: some View {
        NavigationStack {
            room
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close", systemImage: "chevron.down") { dismiss() }
                    }
                }
        }
        // Done on the Lock Screen or in the Dynamic Island closes the room as well.
        .onChange(of: live.focusEndedOutside) { dismiss() }
        // However the room closes, Focus mode leaves the Lock Screen (after Done this does nothing).
        .onDisappear { live.focusClosed() }
    }

    private var room: some View {
        TimelineView(.periodic(from: .now, by: 15)) { _ in
            let now = model.now
            let block = live.focusBlock(in: model)
            Group {
                if let block {
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
            .task(id: block?.id) {
                if let block { live.focusOpened(on: block) }
            }
        }
        .background { SkyBackground(phase: model.skyPhase) }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.gentle(calm, .easeOut(duration: 1.0).delay(0.15))) { titleShown = 1 }
        }
    }

    private func content(_ block: Block, now: Date) -> some View {
        // The session can differ from the plan: paused, or with a few more minutes added.
        let session = live.focusSession.flatMap { $0.blockID == block.id ? $0 : nil }
        let remaining = session?.remaining(at: now) ?? max(0, block.interval.end.timeIntervalSince(now))
        let length = session?.length ?? block.interval.duration
        let end = session?.endsAt ?? block.interval.end
        let paused = session?.isPaused ?? false
        let minutesLeft = Int((remaining / 60).rounded(.up))
        let wrapUp = minutesLeft <= 5 && !paused
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

                timer(fraction: remaining / length, minutesLeft: minutesLeft, wrapUp: wrapUp, paused: paused)
                    .padding(.vertical, 48)

                RowGroup {
                    InfoRow(label: "Time", title: "\(block.interval.start.formatted(.compactTime)) to \(end.formatted(.compactTime))")
                    InfoRow(label: "Session", title: block.demand == .deep ? "High focus" : "Light focus")
                    if custom.settings.showFirstStep {
                        InfoRow(label: "First step", title: Explainer.firstStep(for: block))
                    }
                }

                ActionRow {
                    Button("Done", systemImage: "checkmark") {
                        Haptics.shared.play(.complete)
                        withAnimation(.gentle(calm, .bouncy)) { model.markDone(block) }
                        live.focusDone()
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

    /// Ring, bar or just the number, from Customise, Focus mode. The ring sits in the middle; the bar
    /// and the number stay on the left with everything else. Paused, it dims and says so.
    private func timer(fraction: Double, minutesLeft: Int, wrapUp: Bool, paused: Bool) -> some View {
        let centred = custom.settings.ringStyle == .ring
        return VStack(alignment: centred ? .center : .leading, spacing: 10) {
            timerFace(fraction: fraction, minutesLeft: minutesLeft, wrapUp: wrapUp)
                .opacity(paused ? 0.45 : 1)
            if paused {
                Text("Paused").eyebrow()
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, alignment: centred ? .center : .leading)
        .contentShape(.rect)
        .onTapGesture { togglePause(paused) }
        .contextMenu {
            Button(paused ? "Resume" : "Pause", systemImage: paused ? "play" : "pause") { togglePause(paused) }
            Button("Five more minutes", systemImage: "plus") {
                Haptics.shared.play(.tap)
                live.extendFocus()
            }
        }
        .animation(.gentle(calm), value: paused)
        .accessibilityElement(children: .combine)
        .accessibilityAction(named: paused ? "Resume" : "Pause") { togglePause(paused) }
        .accessibilityAction(named: "Five more minutes") { live.extendFocus() }
    }

    private func togglePause(_ paused: Bool) {
        Haptics.shared.play(.toggle)
        if paused { live.resumeFocus() } else { live.pauseFocus() }
    }

    @ViewBuilder
    private func timerFace(fraction: Double, minutesLeft: Int, wrapUp: Bool) -> some View {
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
