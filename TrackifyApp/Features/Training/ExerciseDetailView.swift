import SwiftUI

struct ExerciseDetailView: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    @Environment(AppDependencies.self) private var deps

    var exerciseName: String = "Schrägbank Kurzhantel"
    var muscleLabel: String = "Brust · Hauptübung"

    @State private var allSets: [WorkoutSet] = []

    private var sessionGroups: [SessionGroup] {
        var groups: [UUID: SessionGroup] = [:]
        var order: [UUID] = []
        for s in allSets {
            if groups[s.workoutID] == nil {
                groups[s.workoutID] = SessionGroup(workoutID: s.workoutID, date: s.doneAt, sets: [])
                order.append(s.workoutID)
            }
            groups[s.workoutID]?.sets.append(s)
        }
        return order.compactMap { groups[$0] }
    }

    private var estimated1RM: Double {
        guard let best = allSets.max(by: { epley($0) < epley($1) }) else { return 0 }
        return epley(best)
    }

    private var lastSessionBest: (weight: Double, reps: Int)? {
        guard let last = sessionGroups.first, let top = last.sets.max(by: { $0.weightKg < $1.weightKg }) else { return nil }
        return (top.weightKg, top.reps)
    }

    private var totalSets: Int { allSets.count }

    private var progressData: [LinePoint] {
        let sessions = sessionGroups.reversed()
        return sessions.enumerated().map { i, g in
            let max1RM = g.sets.map { epley($0) }.max() ?? 0
            return LinePoint(x: Double(i), y: max1RM, highlighted: i == sessions.count - 1)
        }
    }

    private func epley(_ s: WorkoutSet) -> Double {
        s.reps <= 1 ? s.weightKg : s.weightKg * (1 + Double(s.reps) / 30.0)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ScreenHeader(
                    title: exerciseName,
                    eyebrow: muscleLabel,
                    back: "Training",
                    onBack: { dismiss() }
                ) {
                    Menu {
                        ShareLink(
                            item: "\(exerciseName)\n1RM: \(estimated1RM > 0 ? Formatters.compact(estimated1RM) + " kg" : "–") · Sätze: \(totalSets)"
                        ) {
                            Label("Teilen", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        CircleBtn(systemIcon: "ellipsis") {}
                    }
                }

                videoPlaceholder
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, 18)

                statsRow
                    .padding(.horizontal, Spacing.xl)

                VStack(spacing: 0) {
                    SectionHead(label: "Fortschritt", action: "")
                        .padding(.top, 18)

                    Card(pad: Spacing.l) {
                        if progressData.count >= 2 {
                            TrackifyLineChart(data: progressData, accent: true, showAxis: true)
                                .frame(height: 140)
                        } else {
                            Text("Noch zu wenig Daten")
                                .font(.custom(Typography.geistMono, size: 12))
                                .foregroundStyle(t.textMuted)
                                .frame(height: 140)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, Spacing.xl)

                    SectionHead(label: "Verlauf")
                        .padding(.top, 18)

                    if sessionGroups.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "dumbbell")
                                .font(.system(size: 28))
                                .foregroundStyle(t.textMuted)
                            Text("Noch keine Einträge")
                                .font(.custom(Typography.geist, size: 15).weight(.semibold))
                                .foregroundStyle(t.text)
                            Text("Schließe einen Satz dieser Übung ab\num den Verlauf zu sehen.")
                                .font(.custom(Typography.geist, size: 13))
                                .foregroundStyle(t.textMuted)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 30)
                        .padding(.horizontal, Spacing.xl)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(sessionGroups.prefix(5)) { group in
                                historyRow(group)
                            }
                        }
                        .padding(.horizontal, Spacing.xl)
                    }
                }
                .padding(.bottom, Spacing.screenSafeBottom)
            }
        }
        .background(t.bg.ignoresSafeArea())
        .navigationBarHidden(true)
        .task { await loadData() }
    }

    private func loadData() async {
        allSets = (try? await deps.workouts.fetchSets(exerciseName: exerciseName, limit: 100)) ?? []
    }

    @ViewBuilder private var videoPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Radii.card, style: .continuous)
                .fill(t.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: Radii.card, style: .continuous)
                        .stroke(t.border, lineWidth: 1)
                )
            VStack(spacing: 8) {
                Image(systemName: "dumbbell")
                    .font(.system(size: 28))
                    .foregroundStyle(t.textMuted)
                Text("Kein Video verfügbar")
                    .font(.custom(Typography.geistMono, size: 11))
                    .kerning(0.6)
                    .foregroundStyle(t.textMuted)
            }
        }
        .frame(height: 180)
    }

    @ViewBuilder private var statsRow: some View {
        HStack(spacing: 10) {
            Card(pad: 12) {
                Stat(label: "1RM Schätz.",
                     value: estimated1RM > 0 ? Formatters.compact(estimated1RM) : "–",
                     unit: estimated1RM > 0 ? "kg" : "")
            }
            Card(pad: 12) {
                Stat(label: "Letztes Mal",
                     value: lastSessionBest.map { Formatters.compact($0.weight) } ?? "–",
                     unit: lastSessionBest.map { "× \($0.reps)" } ?? "")
            }
            Card(pad: 12) {
                Stat(label: "Sätze ges.", value: "\(totalSets)")
            }
        }
    }

    @ViewBuilder private func historyRow(_ group: SessionGroup) -> some View {
        let weights = group.sets.map { $0.weightKg }
        let minW = weights.min() ?? 0
        let maxW = weights.max() ?? 0
        let kgStr = minW == maxW ? Formatters.compact(maxW) : "\(Formatters.compact(minW))–\(Formatters.compact(maxW))"
        let setsStr = group.sets.map { "\($0.reps)" }.joined(separator: "·")

        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(Formatters.shortDate(group.date))
                    .font(.custom(Typography.geist, size: 14).weight(.medium))
                    .foregroundStyle(t.text)
                Text("\(group.sets.count)×\(setsStr)")
                    .font(.custom(Typography.geistMono, size: 11))
                    .foregroundStyle(t.textMuted)
            }
            Spacer()
            Text("\(kgStr) kg")
                .font(Typography.number(14))
                .foregroundStyle(t.text)
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: Radii.row, style: .continuous).fill(t.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radii.row, style: .continuous).stroke(t.border, lineWidth: 1)
        )
    }
}

struct SessionGroup: Identifiable {
    var id: UUID { workoutID }
    var workoutID: UUID
    var date: Date
    var sets: [WorkoutSet]
}

#Preview {
    ThemedRoot { ExerciseDetailView() }
        .environment(AppDependencies.mock())
}
