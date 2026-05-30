import SwiftUI

struct InsightsView: View {
    @Environment(\.theme) private var t
    @Environment(AppDependencies.self) private var deps
    @AppStorage("unitsKg") private var unitsKg = true

    @State private var period = 0 // 0=Woche 1=Monat 2=3M 3=Jahr
    @State private var showPeriodPicker = false
    @State private var streak = 0
    @State private var totalWorkouts = 0
    @State private var weekDays: [DayVolume] = []
    @State private var personalBests: [PREntry] = []
    @State private var best5kSec: Int = 0
    @State private var muscleVolumeData: [(muscle: String, fraction: Double, value: String)] = []
    @State private var weeklyVolumePoints: [BarPoint] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ScreenHeader(title: "Insights", eyebrow: todayEyebrow) {
                    CircleBtn(systemIcon: "line.3.horizontal.decrease") { showPeriodPicker = true }
                }

                periodPicker.padding(.horizontal, Spacing.xl).padding(.bottom, 16)

                streakCard.padding(.horizontal, Spacing.xl)

                SectionHead(label: "Workouts").padding(.top, 18)
                workoutStat.padding(.horizontal, Spacing.xl)

                if !personalBests.isEmpty {
                    SectionHead(label: "Persönliche Bestleistungen").padding(.top, 18)
                    prSection.padding(.horizontal, Spacing.xl)
                }

                if !muscleVolumeData.isEmpty {
                    SectionHead(label: "Volumen · Muskelgruppen").padding(.top, 18)
                    muscleVolumeCard.padding(.horizontal, Spacing.xl)
                }

                aiInsightCard.padding(.horizontal, Spacing.xl).padding(.top, 12)

                Spacer().frame(height: Spacing.screenSafeBottom)
            }
        }
        .background(t.bg.ignoresSafeArea())
        .navigationBarHidden(true)
        .task { await loadData() }
        .onChange(of: period) { Task { await loadData() } }
        .confirmationDialog("Zeitraum", isPresented: $showPeriodPicker, titleVisibility: .visible) {
            Button("Diese Woche")      { period = 0 }
            Button("Dieser Monat")     { period = 1 }
            Button("Letzte 3 Monate") { period = 2 }
            Button("Dieses Jahr")      { period = 3 }
            Button("Abbrechen", role: .cancel) {}
        }
    }

    private var periodCutoff: Date {
        let days = [7, 30, 90, 365][min(period, 3)]
        return Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .distantPast
    }

    private func loadData() async {
        let streakDays = (try? await deps.supplements.streakDays()) ?? 0
        streak         = streakDays / 7
        let workouts  = (try? await deps.workouts.fetchWorkouts(since: periodCutoff)) ?? []
        totalWorkouts = workouts.count
        weekDays      = (try? await deps.workouts.weeklyVolume()) ?? []

        let allSets = (try? await deps.workouts.fetchAllSets(limit: 2000)) ?? []
        personalBests = computePRs(from: allSets)
        muscleVolumeData = computeMuscleVolume(from: allSets)
        weeklyVolumePoints = computeWeeklyVolumes(from: workouts)

        let runs = (try? await deps.runs.fetchRuns(limit: 9999)) ?? []
        best5kSec = computeBest5k(from: runs)
    }

    private func computeMuscleVolume(from sets: [WorkoutSet]) -> [(muscle: String, fraction: Double, value: String)] {
        var volumeByMuscle: [String: Double] = [:]
        for s in sets where s.weightKg > 0 && s.reps > 0 {
            let muscle = ExerciseCatalog.exercises
                .first { $0.name.lowercased() == s.exerciseName.lowercased() }
                .map { $0.muscle.label } ?? "Sonstiges"
            volumeByMuscle[muscle, default: 0] += s.weightKg * Double(s.reps)
        }
        guard !volumeByMuscle.isEmpty else { return [] }
        let maxVol = volumeByMuscle.values.max() ?? 1
        return volumeByMuscle
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { name, vol in
                (name, vol / maxVol, Formatters.weightValue(vol, useKg: unitsKg) + " " + Formatters.weightUnit(unitsKg))
            }
    }

    private func computeBest5k(from runs: [Run]) -> Int {
        runs.filter { $0.distanceM >= 5000 }
            .map { r -> Int in
                let pace = r.distanceM > 0 ? Double(r.durationS) / (r.distanceM / 1000) : 0
                return Int(pace * 5)
            }
            .filter { $0 > 0 }
            .min() ?? 0
    }

    private func computePRs(from sets: [WorkoutSet]) -> [PREntry] {
        let cutoff7d = Date().addingTimeInterval(-7 * 86400)
        var best: [String: (set: WorkoutSet, rm: Double)] = [:]
        for s in sets {
            let rm = s.reps <= 1 ? s.weightKg : s.weightKg * (1 + Double(s.reps) / 30.0)
            if let existing = best[s.exerciseName] {
                if rm > existing.rm { best[s.exerciseName] = (s, rm) }
            } else {
                best[s.exerciseName] = (s, rm)
            }
        }
        return best.values
            .sorted { $0.rm > $1.rm }
            .prefix(3)
            .map { entry in
                let isNew = entry.set.doneAt >= cutoff7d
                let sub = "\(entry.set.reps)× \(Formatters.compact(entry.set.weightKg)) kg\(isNew ? " · neu" : "")"
                return PREntry(
                    name: entry.set.exerciseName,
                    value: Formatters.compact(entry.rm),
                    sub: sub,
                    isNew: isNew
                )
            }
    }

    private func computeWeeklyVolumes(from workouts: [Workout]) -> [BarPoint] {
        let cal = Calendar.current
        let weekCount = min([1, 4, 13, 52][min(period, 3)], 8)
        return (0..<weekCount).reversed().enumerated().map { i, offset in
            let refDate  = cal.date(byAdding: .weekOfYear, value: -offset, to: .now) ?? .now
            let comps    = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: refDate)
            let weekStart = cal.date(from: comps) ?? refDate
            let weekEnd   = cal.date(byAdding: .weekOfYear, value: 1, to: weekStart) ?? refDate
            let vol = workouts.filter { $0.startedAt >= weekStart && $0.startedAt < weekEnd }
                              .reduce(0.0) { $0 + $1.volumeKg }
            return BarPoint(label: offset == 0 ? "Jetzt" : "W\(weekCount - i)",
                            value: vol, highlighted: offset == 0)
        }
    }

    private var insightText: String {
        if let pr = personalBests.first(where: { $0.isNew }) {
            return "Neuer Rekord bei \(pr.name): \(pr.value) \(Formatters.weightUnit(unitsKg)). Starke Leistung!"
        }
        let weeks = max(1, [1, 4, 13, 52][min(period, 3)])
        let avg = Double(totalWorkouts) / Double(weeks)
        if totalWorkouts >= 4 && avg >= 3.5 {
            return "Starke Konsistenz – Ø \(String(format: "%.1f", avg)) Workouts pro Woche. Du bist auf Kurs."
        }
        if best5kSec > 0 {
            let mins = best5kSec / 60; let secs = best5kSec % 60
            let next = String(format: "%d:%02d", mins - (best5kSec % 60 == 0 ? 1 : 0), best5kSec % 60 == 0 ? 59 : secs - 1)
            return "5K-Bestzeit: \(mins):\(String(format: "%02d", secs)) min. Nächste Marke: unter \(next)?"
        }
        if streak > 0 {
            return "Du hast \(streak) Wochen in Folge Supplements eingenommen. Konsistenz zahlt sich aus."
        }
        return "Trage deine ersten Workouts ein, um hier personalisierte Beobachtungen zu sehen."
    }

    private var todayEyebrow: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "de_DE")
        df.dateFormat = "d. MMM · EEEE"
        return df.string(from: .now)
    }

    @ViewBuilder private var periodPicker: some View {
        HStack(spacing: 0) {
            let labels = ["Woche", "Monat", "3M", "Jahr"]
            ForEach(labels.indices, id: \.self) { i in
                Button {
                    withAnimation(.easeOut(duration: 0.18)) { period = i }
                } label: {
                    Text(labels[i])
                        .font(.custom(Typography.geist, size: 13).weight(period == i ? .semibold : .regular))
                        .foregroundStyle(period == i ? t.bg : t.textMid)
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(period == i ? Capsule().fill(t.text) : nil)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: Radii.pill, style: .continuous).fill(t.surface2))
    }

    @ViewBuilder private var streakCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Radii.card, style: .continuous).fill(t.text)
            VStack(spacing: 0) {
                HStack {
                    Text("STREAK · \(streak > 0 ? "AKTIV" : "INAKTIV")")
                        .font(.custom(Typography.geistMono, size: 11).weight(.medium))
                        .kerning(0.8)
                        .foregroundStyle(t.bg.opacity(0.5))
                    Spacer()
                }
                .padding(.top, 20).padding(.horizontal, 20)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(streak)")
                        .font(Typography.number(60)).kerning(-2)
                        .foregroundStyle(t.bg)
                    Text(streak == 1 ? "Woche" : "Wochen")
                        .font(.custom(Typography.geist, size: 20).weight(.medium))
                        .foregroundStyle(t.bg.opacity(0.7))
                }
                .padding(.top, 4).padding(.horizontal, 20)

                let pipCount = min(streak, 12)
                HStack(spacing: 4) {
                    ForEach(0..<max(pipCount, 1), id: \.self) { i in
                        Circle()
                            .fill(i == pipCount - 1 ? t.accent : t.bg.opacity(0.3))
                            .frame(width: i == pipCount - 1 ? 10 : 8,
                                   height: i == pipCount - 1 ? 10 : 8)
                    }
                }
                .padding(.horizontal, 20).padding(.vertical, 20)
            }
        }
        .frame(height: 150)
    }

    private var periodLabel: String {
        ["Diese Woche", "Dieser Monat", "Letzte 3 Monate", "Dieses Jahr"][min(period, 3)]
    }

    @ViewBuilder private var workoutStat: some View {
        Card(pad: Spacing.l) {
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow(text: periodLabel)
                    Text("\(totalWorkouts)")
                        .font(Typography.number(40)).kerning(-1.4)
                        .foregroundStyle(t.text)
                    Text("Workouts")
                        .font(.custom(Typography.geist, size: 12))
                        .foregroundStyle(t.textMuted)
                }
                Divider().frame(height: 60)
                if period == 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        Eyebrow(text: "Tage aktiv")
                        Text("\(weekDays.filter(\.hasWorkout).count)")
                            .font(Typography.number(40)).kerning(-1.4)
                            .foregroundStyle(t.text)
                        Text("/ \(weekDays.count) Tage")
                            .font(.custom(Typography.geistMono, size: 12))
                            .foregroundStyle(t.textMuted)
                    }
                } else {
                    let weeks = max(1, [1, 4, 13, 52][min(period, 3)])
                    let avg = Double(totalWorkouts) / Double(weeks)
                    VStack(alignment: .leading, spacing: 4) {
                        Eyebrow(text: "Ø / Woche")
                        Text(String(format: avg == avg.rounded() ? "%.0f" : "%.1f", avg))
                            .font(Typography.number(40)).kerning(-1.4)
                            .foregroundStyle(t.text)
                        Text("Workouts")
                            .font(.custom(Typography.geistMono, size: 12))
                            .foregroundStyle(t.textMuted)
                    }
                }
                Spacer()
            }
            if weeklyVolumePoints.count >= 2 && weeklyVolumePoints.contains(where: { $0.value > 0 }) {
                TrackifyBarChart(data: weeklyVolumePoints)
                    .frame(height: 52)
                    .padding(.top, 12)
            }
        }
    }

    @ViewBuilder private var muscleVolumeCard: some View {
        Card(pad: Spacing.l) {
            VStack(spacing: 10) {
                ForEach(muscleVolumeData, id: \.muscle) { m in
                    HStack(spacing: 10) {
                        Text(m.muscle)
                            .font(.custom(Typography.geist, size: 13))
                            .foregroundStyle(t.textMid)
                            .frame(width: 80, alignment: .leading)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3).fill(t.surface2).frame(height: 8)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(m.fraction >= 0.95 ? t.accent : t.text)
                                    .frame(width: geo.size.width * CGFloat(m.fraction), height: 8)
                            }
                            .frame(height: geo.size.height)
                        }
                        Text(m.value)
                            .font(Typography.number(12))
                            .foregroundStyle(t.textMuted)
                            .frame(width: 72, alignment: .trailing)
                    }
                    .frame(height: 16)
                }
            }
        }
    }

    @ViewBuilder private var prSection: some View {
        VStack(spacing: 8) {
            ForEach(personalBests) { pr in
                prRow(icon: "trophy", name: pr.name, sub: pr.sub, value: pr.value, unit: Formatters.weightUnit(unitsKg), isNew: pr.isNew)
            }
            if best5kSec > 0 {
                let mins = best5kSec / 60; let secs = best5kSec % 60
                prRow(icon: "figure.run",
                      name: "5K Lauf",
                      sub: "Schnellste 5 km",
                      value: String(format: "%d:%02d", mins, secs),
                      unit: "min",
                      isNew: false)
            }
        }
    }

    @ViewBuilder private func prRow(icon: String, name: String, sub: String, value: String, unit: String, isNew: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(isNew ? t.accentText : t.text)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isNew ? t.accent : t.surface2)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.custom(Typography.geist, size: 14).weight(.semibold))
                    .foregroundStyle(t.text)
                Text(sub)
                    .font(.custom(Typography.geistMono, size: 11))
                    .foregroundStyle(t.textMuted)
            }
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(Typography.number(18))
                    .foregroundStyle(t.text)
                Text(unit)
                    .font(.custom(Typography.geistMono, size: 11))
                    .foregroundStyle(t.textMuted)
            }
        }
        .padding(Spacing.l)
        .background(RoundedRectangle(cornerRadius: Radii.row, style: .continuous).fill(t.surface))
        .overlay(RoundedRectangle(cornerRadius: Radii.row, style: .continuous).stroke(t.border, lineWidth: 1))
    }

    @ViewBuilder private var aiInsightCard: some View {
        Card(pad: Spacing.l) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Circle().fill(t.accent).frame(width: 6, height: 6)
                    Text("BEOBACHTUNG")
                        .font(.custom(Typography.geistMono, size: 11).weight(.semibold))
                        .kerning(0.8)
                        .foregroundStyle(t.accent)
                }
                Text(insightText)
                    .font(Typography.bodySmall)
                    .foregroundStyle(t.textMid)
                    .lineSpacing(4)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: Radii.card, style: .continuous).stroke(t.accent, lineWidth: 1)
        )
    }
}

struct PREntry: Identifiable {
    var id: String { name }
    var name: String
    var value: String
    var sub: String
    var isNew: Bool
}

#Preview {
    ThemedRoot { InsightsView() }
        .environment(AppDependencies.mock())
}
