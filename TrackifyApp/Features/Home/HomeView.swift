import SwiftUI
import CoreLocation

struct HomeView: View {
    @Environment(\.theme) private var t
    @Environment(AppDependencies.self) private var deps
    @Environment(AuthState.self) private var auth
    @AppStorage("unitsKg")                    private var unitsKg = true
    @AppStorage(PlanData.versionKey)          private var planStoreVersion = 0
    @AppStorage("goalWorkoutsPerWeek")        private var goalWorkoutsPerWeek = 4
    @AppStorage("locationPrePromptShown")     private var locationPrePromptShown = false
    @State private var showWorkout = false
    @State private var showWeightEntry = false
    @State private var showRunLive = false
    @State private var showLocationPrePrompt = false
    @State private var showMeasurementsEntry = false
    @State private var showReminders = false
    @State private var weekDays: [DayVolume] = []
    @State private var weekCount = 0
    @State private var weightMetrics: [BodyMetric] = []

    private var todayPlanDay: PlanDay? { _ = planStoreVersion; return PlanData.today }
    private var currentKg: Double { weightMetrics.first?.value ?? 0 }
    private var weightDelta: Double {
        guard weightMetrics.count >= 2 else { return 0 }
        return weightMetrics[0].value - weightMetrics[1].value
    }
    private var weeklyVolumeKg: Double { weekDays.reduce(0) { $0 + $1.volumeKg } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                topBar
                content
            }
        }
        .background(t.bg.ignoresSafeArea())
        .fullScreenCover(isPresented: $showWorkout) {
            ThemedRoot { ActiveWorkoutView(planDay: todayPlanDay) }
        }
        .onChange(of: showWorkout) { _, showing in
            if !showing { Task { await loadData() } }
        }
        .fullScreenCover(isPresented: $showRunLive) {
            ThemedRoot { RunLiveView() }
        }
        .onChange(of: showRunLive) { _, showing in
            if !showing { Task { await loadData() } }
        }
        .sheet(isPresented: $showMeasurementsEntry) {
            ThemedRoot { MeasurementsEntrySheet(onSave: { values in
                Task {
                    for (type, value) in values {
                        let m = BodyMetric(userID: .localUser, ts: .now, type: type, value: value)
                        try? await deps.body.save(m)
                    }
                    await loadData()
                }
            }) }
        }
        .sheet(isPresented: $showWeightEntry) {
            MetricEntrySheet(type: .weight) { value in
                Task {
                    let m = BodyMetric(userID: .localUser, ts: .now, type: .weight, value: value)
                    try? await deps.body.save(m)
                    await loadData()
                }
            }
        }
        .sheet(isPresented: $showReminders) {
            ThemedRoot {
                NavigationStack { RemindersView() }
            }
        }
        .sheet(isPresented: $showLocationPrePrompt) {
            LocationPrePromptSheet {
                locationPrePromptShown = true
                showLocationPrePrompt = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showRunLive = true }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .task { await loadData() }
    }

    private func handleRunTap() {
        let status = CLLocationManager().authorizationStatus
        if status == .authorizedAlways || locationPrePromptShown {
            showRunLive = true
        } else {
            showLocationPrePrompt = true
        }
    }

    private func loadData() async {
        weekDays      = (try? await deps.workouts.weeklyVolume()) ?? []
        weekCount     = (try? await deps.workouts.weeklyCount()) ?? 0
        weightMetrics = (try? await deps.body.fetchMetrics(type: .weight, limit: 30)) ?? []
    }

    @ViewBuilder private var topBar: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Eyebrow(text: todayEyebrow)
                let firstName = auth.userName.split(separator: " ").first.map(String.init) ?? "Hey"
                Text("Hey, \(firstName).")
                    .font(Typography.title(26))
                    .kerning(-0.8)
                    .foregroundStyle(t.text)
            }
            Spacer()
            CircleBtn(systemIcon: "bell") { showReminders = true }
            Avatar(initials: auth.userInitials.isEmpty ? "?" : auth.userInitials)
        }
        .padding(.top, 54)
        .padding(.horizontal, Spacing.xl)
    }

    @ViewBuilder private var content: some View {
        VStack(spacing: 14) {
            todayCard
            statsRow
            quickTrack
            weightCard
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, 20)
        .padding(.bottom, Spacing.screenSafeBottom)
    }

    @ViewBuilder private var todayCard: some View {
        let day = todayPlanDay
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(day.map { "HEUTE · \($0.tag.uppercased())" } ?? "HEUTE")
                    .font(Typography.eyebrow).kerning(1.0)
                    .foregroundStyle(t.bg.opacity(0.6))
                Spacer()
                if let day = day {
                    Text(day.focus.uppercased())
                        .font(.custom(Typography.geistMono, size: 10).weight(.semibold))
                        .kerning(0.6)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Capsule().fill(t.accent))
                        .foregroundStyle(t.accentText)
                }
            }
            Text(day.map { PlanData.bodyLabel($0) } ?? "Freies Workout")
                .font(Typography.title(26))
                .kerning(-0.6)
                .foregroundStyle(t.bg)
            if let day = day {
                HStack(spacing: 16) {
                    Text("\(day.exercises) Übungen")
                    Text("·")
                    Text("~\(day.minutes) Min")
                }
                .font(.custom(Typography.geistMono, size: 12))
                .foregroundStyle(t.bg.opacity(0.7))
            }
            Button { showWorkout = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill").font(.system(size: 14, weight: .semibold))
                    Text("Workout starten").font(.custom(Typography.geist, size: 15).weight(.semibold))
                }
                .foregroundStyle(t.accentText)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(t.accent))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radii.card, style: .continuous).fill(t.text))
    }

    @ViewBuilder private var statsRow: some View {
        HStack(spacing: 10) {
            Card(pad: Spacing.l) {
                HStack {
                    Eyebrow(text: "Diese Woche")
                    Spacer()
                    Image(systemName: "dumbbell").font(.system(size: 14)).foregroundStyle(t.textMuted)
                }
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(weekCount)").font(Typography.number(28)).kerning(-1)
                        .foregroundStyle(weekCount >= goalWorkoutsPerWeek ? t.accent : t.text)
                    Text("/ \(goalWorkoutsPerWeek)")
                        .font(.custom(Typography.geistMono, size: 14)).foregroundStyle(t.textMuted)
                }
                .padding(.top, 8)
                Text("Workouts").font(.custom(Typography.geist, size: 11)).foregroundStyle(t.textMid)
                weekGrid.padding(.top, 12)
            }
            .frame(maxWidth: .infinity)

            Card(pad: Spacing.l) {
                HStack {
                    Eyebrow(text: "Volumen")
                    Spacer()
                    Image(systemName: "arrow.up.right").font(.system(size: 12)).foregroundStyle(t.accent)
                }
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(Formatters.compact(weeklyVolumeKg)).font(Typography.number(28)).kerning(-1)
                    Text("kg").font(.custom(Typography.geistMono, size: 14)).foregroundStyle(t.textMuted)
                }
                .padding(.top, 8)
                if !weekDays.isEmpty {
                    TrackifyLineChart(
                        data: weekDays.enumerated().map { LinePoint(x: Double($0.offset), y: $0.element.volumeKg) },
                        accent: true, showAxis: false
                    )
                    .frame(height: 36).padding(.top, 8)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder private var weekGrid: some View {
        let fallback: [DayVolume] = {
            let labels = ["Mo","Di","Mi","Do","Fr","Sa","So"]
            return labels.enumerated().map { i, l in
                DayVolume(dayLabel: l, volumeKg: 0, hasWorkout: false, isToday: i == 0)
            }
        }()
        let days = weekDays.isEmpty ? fallback : weekDays
        HStack(spacing: 4) {
            ForEach(days) { day in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(day.hasWorkout ? t.accent : (day.isToday ? Color.clear : t.surface2))
                        .frame(height: 24)
                        .overlay(
                            day.isToday
                            ? RoundedRectangle(cornerRadius: 4)
                                .stroke(t.borderStrong, style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                            : nil
                        )
                    Text(day.dayLabel)
                        .font(.custom(Typography.geistMono, size: 9))
                        .foregroundStyle(t.textMuted)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder private var quickTrack: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHead(label: "Schnell tracken", action: "Alle")
                .padding(.horizontal, 0)
            HStack(spacing: 10) {
                QuickTile(icon: "figure.run", label: "Lauf", sub: "Live") {
                    handleRunTap()
                }
                QuickTile(icon: "scalemass", label: "Gewicht", sub: "eintragen") {
                    showWeightEntry = true
                }
                QuickTile(icon: "ruler", label: "Maße", sub: "+ Wert") {
                    showMeasurementsEntry = true
                }
            }
        }
    }

    @ViewBuilder private var weightCard: some View {
        Card(pad: Spacing.l) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Eyebrow(text: "Körpergewicht · 30T")
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(currentKg > 0 ? Formatters.weightValue(currentKg, useKg: unitsKg) : "–")
                            .font(Typography.number(30)).kerning(-1)
                        Text(Formatters.weightUnit(unitsKg))
                            .font(.custom(Typography.geistMono, size: 13)).foregroundStyle(t.textMuted)
                        if weightDelta != 0 {
                            let sign = weightDelta < 0 ? "↓" : "↑"
                            Text("\(sign) \(Formatters.weightValue(abs(weightDelta), useKg: unitsKg))")
                                .font(.custom(Typography.geistMono, size: 12))
                                .foregroundStyle(weightDelta < 0 ? t.accent : t.danger)
                        }
                    }
                }
                Spacer()
                Button("+ Eintragen") { showWeightEntry = true }
                    .font(.custom(Typography.geist, size: 12))
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Capsule().fill(t.surface2))
                    .foregroundStyle(t.text)
                    .buttonStyle(.plain)
            }
            .padding(.bottom, 8)

            let sparkData = Array(weightMetrics.prefix(10).reversed())
            if !sparkData.isEmpty {
                TrackifyLineChart(
                    data: sparkData.enumerated().map { LinePoint(x: Double($0.offset), y: $0.element.value) },
                    accent: false, showAxis: false
                )
                .frame(height: 88)
            }
        }
    }

    private var todayEyebrow: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "de_DE")
        df.dateFormat = "EEEE · d. MMM"
        return df.string(from: Date()).capitalized
    }
}

struct Avatar: View {
    @Environment(\.theme) private var t
    var initials: String
    var body: some View {
        Text(initials)
            .font(.custom(Typography.geist, size: 14).weight(.semibold))
            .foregroundStyle(t.text)
            .frame(width: 40, height: 40)
            .background(Circle().fill(t.surface2))
            .overlay(Circle().stroke(t.border, lineWidth: 1))
    }
}

struct QuickTile: View {
    @Environment(\.theme) private var t
    var icon: String
    var label: String
    var sub: String
    var action: (() -> Void)? = nil

    var body: some View {
        Button { action?() } label: {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(t.text)
                    .frame(width: 32, height: 32)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(t.surface2))
                VStack(alignment: .leading, spacing: 2) {
                    Text(label).font(.custom(Typography.geist, size: 14).weight(.semibold)).foregroundStyle(t.text)
                    Text(sub).font(.custom(Typography.geistMono, size: 11)).foregroundStyle(t.textMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12).padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: Radii.cardSmall, style: .continuous).fill(t.surface))
            .overlay(RoundedRectangle(cornerRadius: Radii.cardSmall, style: .continuous).stroke(t.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ThemedRoot { HomeView() }
        .environment(AppDependencies.mock())
        .environment(AuthState())
}
