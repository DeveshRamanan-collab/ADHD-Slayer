import SwiftUI
import WidgetKit
import FocusGlance

/// Focus mode: the task you're on and the time left. The ring and the time run on their own from the
/// session's interval; the app only sends an update on pause, resume, +5 min or a new first step.
/// When the time is up (the activity goes stale a minute later, so this works with the app asleep)
/// or the app ends it, it reads "Time's up." over the cheer the app picked from its copy deck.
enum FocusModeLines {
    static let timeUp = "Time’s up."
    static let paused = "Paused"

    /// The serif title: the task while it runs, "Time's up." after.
    static func title(_ state: GlanceState, _ phase: GlanceState.FocusPhase) -> String {
        phase.isOver ? timeUp : state.title ?? "Focus"
    }

    /// The quiet line under the title: the first step, or the cheer once it's over.
    static func detail(_ state: GlanceState, _ phase: GlanceState.FocusPhase) -> String? {
        phase.isOver ? state.cheer : state.firstStep
    }

    static func spoken(_ state: GlanceState, _ phase: GlanceState.FocusPhase) -> String {
        let task = state.title ?? "Focus"
        switch phase {
        case .running(let range): return "\(task), \(GlanceFormat.minutesLeft(range.upperBound.timeIntervalSinceNow))"
        case .paused(let left, _): return "\(task), paused, \(GlanceFormat.minutesLeft(left))"
        case .timeUp, .ended: return [task + ".", timeUp, state.cheer].compactMap { $0 }.joined(separator: " ")
        }
    }
}

// MARK: - Lock Screen, StandBy, the Watch Smart Stack and CarPlay

struct FocusModeLockScreen: View {
    let context: ActivityViewContext<FocusActivityAttributes>
    @Environment(\.colorScheme) private var scheme
    @Environment(\.activityFamily) private var family

    var body: some View {
        let state = context.state
        let phase = state.focusPhase(at: .now, isStale: context.isStale)
        let tones = Tones(scheme: scheme)
        Group {
            if family == .small {
                small(state, phase, tones)
            } else {
                medium(state, phase, tones)
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }

    /// Ring 40 pt, title, first step, time left 28 pt on the right, a hairline bar, Done and +5 min.
    private func medium(_ state: GlanceState, _ phase: GlanceState.FocusPhase, _ tones: Tones) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                FocusRing(phase: phase, diameter: 40, lineWidth: 3, tones: tones)
                VStack(alignment: .leading, spacing: 2) {
                    Text(FocusModeLines.title(state, phase))
                        .font(.glanceSerif(.body))
                        .foregroundStyle(tones.ink)
                    if let detail = FocusModeLines.detail(state, phase) {
                        Text(detail)
                            .font(.footnote)
                            .foregroundStyle(tones.inkSoft)
                    }
                }
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(FocusModeLines.spoken(state, phase))
                if phase.showsTime {
                    VStack(alignment: .trailing, spacing: 0) {
                        TimeLeft(phase: phase, font: .system(.title), color: tones.accent)
                        if phase.isPaused {
                            Text(FocusModeLines.paused).font(.caption2).foregroundStyle(tones.inkSoft)
                        }
                    }
                    .fixedSize()
                    .accessibilityHidden(true)
                }
            }
            HairlineBar(phase: phase, tones: tones)
            if phase != .ended {
                FocusButtons(tones: tones)
            }
        }
        .padding(16)
    }

    /// The Watch and CarPlay: ring, title and time. Buttons do nothing there, so there are none.
    private func small(_ state: GlanceState, _ phase: GlanceState.FocusPhase, _ tones: Tones) -> some View {
        HStack(spacing: 10) {
            FocusRing(phase: phase, diameter: 28, lineWidth: 2.5, tones: tones)
            VStack(alignment: .leading, spacing: 1) {
                Text(FocusModeLines.title(state, phase))
                    .font(.glanceSerif(.footnote))
                    .foregroundStyle(tones.ink)
                if phase.showsTime {
                    TimeLeft(phase: phase, font: .system(.subheadline, weight: .semibold), color: tones.accent)
                } else if let cheer = state.cheer {
                    Text(cheer)
                        .font(.caption)
                        .foregroundStyle(tones.inkSoft)
                }
            }
            .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(FocusModeLines.spoken(state, phase))
    }
}

/// The hairline under the Lock Screen row: live while running, still (and dim) while paused.
private struct HairlineBar: View {
    let phase: GlanceState.FocusPhase
    let tones: Tones

    var body: some View {
        Group {
            switch phase {
            case .running(let range):
                ProgressView(timerInterval: range, countsDown: true) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
                .progressViewStyle(.linear)
                .tint(tones.accent)
                .scaleEffect(x: 1, y: 0.5, anchor: .center)
            case .paused(_, let fraction):
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(tones.tertiary.opacity(0.35))
                        Capsule().fill(tones.accent.opacity(0.45)).frame(width: geo.size.width * fraction)
                    }
                }
                .frame(height: 2)
            case .timeUp, .ended:
                EmptyView()
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Dynamic Island

enum FocusModeIsland {
    static func make(_ context: ActivityViewContext<FocusActivityAttributes>) -> DynamicIsland {
        let state = context.state
        let phase = state.focusPhase(at: .now, isStale: context.isStale)
        let tones = Tones.island
        return DynamicIsland {
            DynamicIslandExpandedRegion(.leading) {
                FocusRing(phase: phase, diameter: 44, lineWidth: 3, tones: tones)
                    .frame(maxHeight: .infinity, alignment: .center)
                    .padding(.leading, 4)
            }
            DynamicIslandExpandedRegion(.trailing) {
                VStack(alignment: .trailing, spacing: 0) {
                    TimeLeft(phase: phase, font: .system(.title), color: tones.accent)
                        .fixedSize()
                    if phase.isPaused {
                        Text(FocusModeLines.paused).font(.caption2).foregroundStyle(tones.inkSoft)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .center)
                .padding(.trailing, 4)
                .accessibilityHidden(true)
            }
            DynamicIslandExpandedRegion(.center) {
                Text(FocusModeLines.title(state, phase))
                    .font(.glanceSerif(.body))
                    .foregroundStyle(tones.ink)
                    .lineLimit(1)
                    .frame(maxHeight: .infinity, alignment: .center)
                    .accessibilityLabel(FocusModeLines.spoken(state, phase))
            }
            DynamicIslandExpandedRegion(.bottom) {
                VStack(alignment: .leading, spacing: 10) {
                    if let detail = FocusModeLines.detail(state, phase) {
                        Text(detail)
                            .font(.footnote)
                            .foregroundStyle(tones.inkSoft)
                            .lineLimit(1)
                    }
                    if phase != .ended {
                        FocusButtons(tones: tones)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
                .padding(.top, 4)
            }
        } compactLeading: {
            FocusRing(phase: phase, diameter: 20, lineWidth: 2.5, tones: tones)
                .accessibilityLabel(FocusModeLines.spoken(state, phase))
        } compactTrailing: {
            TimeLeft(phase: phase, font: .system(size: 15, weight: .semibold), color: phase.isPaused ? tones.inkSoft : tones.accent)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: 44, alignment: .trailing)
                .accessibilityHidden(true)
        } minimal: {
            FocusRing(phase: phase, diameter: 20, lineWidth: 2.5, tones: tones)
                .accessibilityLabel(FocusModeLines.spoken(state, phase))
        }
        .keylineTint(tones.accent)
    }
}

extension GlanceState.FocusPhase {
    var isPaused: Bool { if case .paused = self { true } else { false } }
    /// Time's up, or ended by the app.
    var isOver: Bool {
        switch self {
        case .timeUp, .ended: true
        case .running, .paused: false
        }
    }
    /// Running or paused: there's a time left to show.
    var showsTime: Bool {
        switch self {
        case .running, .paused: true
        case .timeUp, .ended: false
        }
    }
}
