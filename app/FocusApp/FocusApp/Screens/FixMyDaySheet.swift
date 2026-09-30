import SwiftUI
import FocusModel
import FocusPlanning

/// "Fix my day" preview: the smallest change that keeps today on track, a reason for every move,
/// pinned items locked, one-tap undo. Nothing is written until Apply.
struct FixMyDaySheet: View {
    let result: PlanResult
    /// How far behind the day is, in minutes (what the preview was asked to absorb).
    var lateMinutes = 40
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    private struct Move: Identifiable {
        let id: String
        let title: String
        let from: DateInterval
        let to: DateInterval
        let reason: String
        let tint: Color
    }

    private var moves: [Move] {
        result.changes.compactMap { change in
            guard case .move(let id, let from, let to, _) = change, let block = result.plan.block(for: id) else { return nil }
            return Move(id: id.raw, title: block.title, from: from, to: to, reason: Explainer.meta(for: block), tint: Explainer.tint(for: block))
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Fix my day").eyebrow()
                    HeroText(text: moves.isEmpty ? "You still have room" : moves.count == 1 ? "One small change" : Copy.line(.fixHeadline, ["count": "\(moves.count)"]),
                             size: 30)
                    Text(Copy.line(.fixSubtitle, ["minutes": "\(lateMinutes)"]))
                        .font(.subheadline)
                        .foregroundStyle(Color.inkSoft)

                    if !moves.isEmpty {
                        RowGroup {
                            ForEach(moves) { move in
                                InfoRow(label: LocalizedStringKey(move.reason), title: move.title, dot: move.tint) {
                                    Text("\(move.from.start.formatted(.compactTime)) → \(move.to.start.formatted(.compactTime))")
                                        .font(.footnote.monospacedDigit())
                                        .foregroundStyle(Color.ink)
                                }
                            }
                        }
                        .padding(.top, 10)
                    }

                    Label("Won’t move: your tutorial, lunch, anything pinned", systemImage: "lock")
                        .font(.footnote)
                        .foregroundStyle(Color.inkSoft)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background { SkyBackground(phase: model.skyPhase) }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(alignment: .leading, spacing: 10) {
                    ActionRow {
                        Button(moves.isEmpty ? "Keep today as it is" : "Apply \(moves.count) changes") {
                            model.applyFix(result)
                            dismiss()
                        }
                        .buttonStyle(.glassProminent)
                        .foregroundStyle(.onAccent)
                        Button("Lighter day instead") {
                            model.dayVersion = .baseline
                            dismiss()
                        }
                        .buttonStyle(.glass)
                    }
                    .font(.subheadline)
                    Text("You can undo with one tap for the rest of the day.")
                        .font(.caption).foregroundStyle(Color.inkSoft)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            }
        }
        .presentationDetents([.large])
    }
}
