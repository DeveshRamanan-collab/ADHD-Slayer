import SwiftUI
import WidgetKit
import FocusGlance

/// Your day: the stretch you're in and what's next. It goes stale when the stretch ends; if the app
/// hasn't caught up by then, it says so instead of showing a stretch that's over.
enum YourDayLines {
    static let stale = "Open Focus to catch up"
    static let nothingNext = "Nothing else planned today."

    static func sentence(_ state: GlanceState) -> String {
        state.stretchSentence(time: { GlanceFormat.time($0) })
    }

    static func until(_ state: GlanceState) -> String? {
        state.stretchEndsAt.map { "until \(GlanceFormat.time($0))" }
    }

    /// "Essay drafting at 11:25", for Next only.
    static func next(_ state: GlanceState) -> String {
        guard let title = state.nextTitle else { return nothingNext }
        guard let at = state.nextAt else { return title }
        return "\(title) at \(GlanceFormat.time(at))"
    }

    static func spoken(_ state: GlanceState, isStale: Bool) -> String {
        if isStale { return stale }
        var parts: [String] = []
        if state.dayShows.showsStretch { parts.append(sentence(state)) }
        if state.dayShows.showsNext, let next = state.nextSentence { parts.append(next) }
        return parts.joined(separator: " ")
    }
}

// MARK: - Lock Screen, StandBy, the Watch Smart Stack and CarPlay

struct YourDayLockScreen: View {
    let context: ActivityViewContext<FocusActivityAttributes>
    @Environment(\.colorScheme) private var scheme
    @Environment(\.activityFamily) private var family

    var body: some View {
        let state = context.state
        let tones = Tones(scheme: scheme)
        Group {
            if family == .small {
                small(state, tones)
            } else {
                medium(state, tones)
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }

    /// The stretch line in serif, the next 8 hours, then what's next and Log.
    private func medium(_ state: GlanceState, _ tones: Tones) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if context.isStale {
                Text(YourDayLines.stale)
                    .font(.glanceSerif(.title3))
                    .foregroundStyle(tones.ink)
            } else if state.dayShows.showsStretch {
                Text(YourDayLines.sentence(state))
                    .font(.glanceSerif(.title3))
                    .foregroundStyle(tones.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                if !state.segments.isEmpty {
                    SegmentBar(segments: state.segments, tones: tones)
                }
                footer(state, tones, next: state.dayShows.showsNext ? state.nextSentence : nil)
            } else {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Next").glanceEyebrow(tones.inkSoft)
                    Text(YourDayLines.next(state))
                        .font(.glanceSerif(.title3))
                        .foregroundStyle(tones.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                }
                footer(state, tones, next: nil)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func footer(_ state: GlanceState, _ tones: Tones, next: String?) -> some View {
        if next != nil || state.showLog {
            HStack(alignment: .center, spacing: 12) {
                if let next {
                    Text(next)
                        .font(.footnote)
                        .foregroundStyle(tones.inkSoft)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                if state.showLog {
                    LogButton(tones: tones)
                }
            }
        }
    }

    /// The Watch and CarPlay: the dot, the stretch and its end, or what's next.
    private func small(_ state: GlanceState, _ tones: Tones) -> some View {
        HStack(spacing: 10) {
            StretchDot(color: context.isStale ? tones.tertiary : tones.stretch(state.stretch), diameter: 10)
            VStack(alignment: .leading, spacing: 1) {
                if context.isStale {
                    Text(YourDayLines.stale).font(.footnote).foregroundStyle(tones.ink)
                } else if state.dayShows.showsStretch {
                    Text(state.stretch.displayName).font(.glanceSerif(.footnote)).foregroundStyle(tones.ink)
                    if let until = YourDayLines.until(state) {
                        Text(until).font(.caption).foregroundStyle(tones.inkSoft)
                    }
                } else {
                    Text("Next").font(.caption2).foregroundStyle(tones.inkSoft)
                    Text(YourDayLines.next(state)).font(.glanceSerif(.footnote)).foregroundStyle(tones.ink)
                }
            }
            .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(YourDayLines.spoken(state, isStale: context.isStale))
    }
}

// MARK: - Dynamic Island

enum YourDayIsland {
    static func make(_ context: ActivityViewContext<FocusActivityAttributes>) -> DynamicIsland {
        let state = context.state
        let stale = context.isStale
        let tones = Tones.island
        let dot = stale ? tones.tertiary : tones.stretch(state.stretch)
        let nextOnly = !state.dayShows.showsStretch
        return DynamicIsland {
            DynamicIslandExpandedRegion(.leading) {
                Group {
                    if nextOnly && !stale {
                        Text("Next").glanceEyebrow(tones.inkSoft)
                    } else {
                        HStack(spacing: 7) {
                            StretchDot(color: dot, diameter: 8)
                            Text(stale ? "Your day" : state.stretch.displayName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(tones.ink)
                        }
                    }
                }
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxHeight: .infinity, alignment: .center)
                .padding(.leading, 6)
            }
            DynamicIslandExpandedRegion(.trailing) {
                Group {
                    if stale {
                        EmptyView()
                    } else if nextOnly {
                        if let at = state.nextAt { Text(GlanceFormat.time(at)) }
                    } else if let until = YourDayLines.until(state) {
                        Text(until)
                    }
                }
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(tones.inkSoft)
                .lineLimit(1)
                .frame(maxHeight: .infinity, alignment: .center)
                .padding(.trailing, 6)
            }
            DynamicIslandExpandedRegion(.bottom) {
                VStack(alignment: .leading, spacing: 10) {
                    if stale {
                        Text(YourDayLines.stale)
                            .font(.glanceSerif(.body))
                            .foregroundStyle(tones.ink)
                    } else if nextOnly {
                        HStack(alignment: .center, spacing: 12) {
                            Text(state.nextTitle ?? YourDayLines.nothingNext)
                                .font(.glanceSerif(.body))
                                .foregroundStyle(tones.ink)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                            if state.showLog { LogButton(tones: tones) }
                        }
                    } else {
                        if !state.segments.isEmpty {
                            SegmentBar(segments: state.segments, tones: tones)
                        }
                        let next = state.dayShows.showsNext ? state.nextSentence : nil
                        if next != nil || state.showLog {
                            HStack(alignment: .center, spacing: 12) {
                                if let next {
                                    Text(next)
                                        .font(.footnote)
                                        .foregroundStyle(tones.inkSoft)
                                        .lineLimit(1)
                                }
                                Spacer(minLength: 0)
                                if state.showLog { LogButton(tones: tones) }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 6)
                .padding(.top, 6)
                .dynamicTypeSize(...DynamicTypeSize.xLarge)
            }
        } compactLeading: {
            Group {
                if nextOnly && !stale {
                    Image(systemName: "arrow.forward")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(tones.ink)
                } else {
                    StretchDot(color: dot, diameter: 12)
                }
            }
            .accessibilityLabel(YourDayLines.spoken(state, isStale: stale))
        } compactTrailing: {
            Group {
                if stale {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(tones.inkSoft)
                } else if nextOnly {
                    Text(state.nextAt.map { GlanceFormat.time($0) } ?? "")
                } else {
                    Text(state.stretchEndsAt.map { GlanceFormat.time($0) } ?? "")
                }
            }
            .font(.system(size: 15, weight: .semibold).monospacedDigit())
            .foregroundStyle(tones.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: 44, alignment: .trailing)
            .accessibilityHidden(true)
        } minimal: {
            Group {
                if nextOnly && !stale {
                    Image(systemName: "arrow.forward")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(tones.ink)
                } else {
                    StretchDot(color: dot, diameter: 12)
                }
            }
            .accessibilityLabel(YourDayLines.spoken(state, isStale: stale))
        }
        .keylineTint(dot)
    }
}
