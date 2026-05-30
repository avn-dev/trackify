import SwiftUI

struct TrainingPlanView: View {
    @Environment(\.theme) private var t
    @Environment(AppDependencies.self) private var deps
    @AppStorage(PlanData.versionKey) private var planStoreVersion = 0
    @State private var activeTab = 0
    @State private var showActiveWorkout = false
    @State private var showSearch = false
    @State private var showPlanLibrary = false
    @State private var adoptTemplateConfig: PlanConfig? = nil
    @State private var selectedDay: PlanDay? = nil
    @State private var history: [Workout] = []
    @State private var expandedWorkoutID: UUID?
    @State private var editingWorkout: Workout? = nil

    private var activePlan: PlanConfig {
        _ = planStoreVersion
        return PlanData.loadStore().activePlan
    }

    private var days: [PlanDay] {
        _ = planStoreVersion
        return PlanData.computedDays(config: activePlan)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ScreenHeader(title: "Training", eyebrow: "Krafttraining") {
                    CircleBtn(systemIcon: "magnifyingglass") { showSearch = true }
                }
                tabPills.padding(.horizontal, Spacing.xl).padding(.bottom, 16)
                dayList
            }
        }
        .background(t.bg.ignoresSafeArea())
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showActiveWorkout) {
            ThemedRoot { ActiveWorkoutView(planDay: selectedDay) }
        }
        .sheet(isPresented: $showSearch) {
            ThemedRoot { ExerciseBrowserSheet() }
        }
        .sheet(isPresented: $showPlanLibrary) {
            ThemedRoot { PlanLibraryView() }
        }
        .sheet(item: $adoptTemplateConfig) { cfg in
            ThemedRoot { PlanEditorView(mode: .createFrom(cfg)) }
        }
        .task { await loadHistory() }
        .onChange(of: showActiveWorkout) { _, showing in
            if !showing { Task { await loadHistory() } }
        }
        .sheet(item: $editingWorkout) { w in
            ThemedRoot { WorkoutEditSheet(workout: w) { edits in
                await saveSetEdits(workout: w, edits: edits)
            }}
            .presentationDragIndicator(.visible)
        }
    }

    private func saveSetEdits(workout: Workout, edits: [(id: UUID, weightKg: Double, reps: Int, rir: Int?)]) async {
        try? await deps.workouts.applySetEdits(edits, forWorkoutID: workout.id)
        await loadHistory()
    }

    private func loadHistory() async {
        history = (try? await deps.workouts.fetchWorkouts(limit: 50)) ?? []
    }

    private func deleteWorkout(_ w: Workout) async {
        try? await deps.workouts.delete(w)
        await loadHistory()
    }

    @ViewBuilder private var tabPills: some View {
        HStack(spacing: 8) {
            ForEach(["Mein Plan", "Vorlagen", "Verlauf"].indices, id: \.self) { i in
                Button {
                    withAnimation(.easeOut(duration: 0.18)) { activeTab = i }
                } label: {
                    Text(["Mein Plan", "Vorlagen", "Verlauf"][i])
                        .font(.custom(Typography.geist, size: 13).weight(.medium))
                        .foregroundStyle(activeTab == i ? t.bg : t.textMid)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(
                            Capsule().fill(activeTab == i ? t.text : Color.clear)
                        )
                        .overlay(
                            activeTab == i ? nil : Capsule().stroke(t.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder private var dayList: some View {
        if activeTab == 2 {
            historyList
        } else if activeTab == 1 {
            templateList
        } else {
            VStack(spacing: 10) {
                planInfoCard
                    .padding(.bottom, 4)
                ForEach(days) { day in
                    DayCard(
                        day: day,
                        planType: activePlan.type,
                        onStart: { selectedDay = day; showActiveWorkout = true },
                        onSkip: activePlan.type == .rotating ? { PlanData.skipToday() } : nil
                    )
                }
                freeWorkoutTile
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.screenSafeBottom)
        }
    }

    @ViewBuilder private var planInfoCard: some View {
        Button { showPlanLibrary = true } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AKTIVER PLAN")
                        .font(.custom(Typography.geistMono, size: 10).weight(.medium))
                        .kerning(0.8)
                        .foregroundStyle(t.textMuted)
                    Text(activePlan.name)
                        .font(.custom(Typography.geist, size: 15).weight(.semibold))
                        .foregroundStyle(t.text)
                    let count = activePlan.days.filter { !$0.isRestDay }.count
                    Text("\(activePlan.type.label) · \(count) Trainingstage")
                        .font(.custom(Typography.geistMono, size: 11))
                        .foregroundStyle(t.textMuted)
                }
                Spacer()
                HStack(spacing: 6) {
                    Text("Pläne")
                        .font(.custom(Typography.geist, size: 13))
                        .foregroundStyle(t.accent)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(t.accent)
                }
            }
            .padding(.horizontal, Spacing.l).padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: Radii.cardSmall, style: .continuous).fill(t.surface))
            .overlay(RoundedRectangle(cornerRadius: Radii.cardSmall, style: .continuous)
                .stroke(t.accent.opacity(0.35), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private let templates: [(String, String, String, Int, Int)] = [
        ("PPL 6-Tage",    "Push / Pull / Legs – 2x/Woche",    "Push",  6, 60),
        ("Upper / Lower", "4-Tage Oberkörper / Unterkörper",   "Upper", 7, 55),
        ("Ganzkörper 3x", "Dreimal pro Woche, Vollkörper",     "Full",  6, 50),
        ("5×5 Kraft",     "Bankdrücken, Kniebeuge, Kreuzheben","Kraft", 3, 45),
    ]

    @ViewBuilder private var templateList: some View {
        VStack(spacing: 10) {
            ForEach(templates, id: \.0) { name, desc, focus, exercises, minutes in
                VStack(spacing: 0) {
                    HStack(spacing: 14) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.system(size: 18))
                            .foregroundStyle(t.text)
                            .frame(width: 40, height: 40)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(t.surface2))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(name)
                                .font(.custom(Typography.geist, size: 15).weight(.semibold))
                                .foregroundStyle(t.text)
                            Text(desc)
                                .font(.custom(Typography.geistMono, size: 11))
                                .foregroundStyle(t.textMuted)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 3) {
                            Text("\(exercises) Üb.")
                                .font(Typography.number(13))
                                .foregroundStyle(t.accent)
                            Text("~\(minutes) min")
                                .font(.custom(Typography.geistMono, size: 10))
                                .foregroundStyle(t.textMuted)
                        }
                    }
                    .padding(16)

                    Rectangle().fill(t.border).frame(height: 0.5).padding(.horizontal, Spacing.l)

                    HStack(spacing: 8) {
                        Button("Einmalig starten") {
                            selectedDay = PlanDay(tag: name, focus: focus,
                                                 exercises: exercises, minutes: minutes, status: .today)
                            showActiveWorkout = true
                        }
                        .font(.custom(Typography.geist, size: 13))
                        .foregroundStyle(t.textMid)
                        .frame(maxWidth: .infinity, minHeight: 38)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(t.surface2))
                        .buttonStyle(.plain)

                        Button("Als Plan übernehmen") {
                            adoptTemplateConfig = makeTemplateConfig(name: name, focus: focus,
                                                                     exercises: exercises, minutes: minutes)
                        }
                        .font(.custom(Typography.geist, size: 13).weight(.semibold))
                        .foregroundStyle(t.accentText)
                        .frame(maxWidth: .infinity, minHeight: 38)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(t.accent))
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, Spacing.l).padding(.vertical, 10)
                }
                .background(RoundedRectangle(cornerRadius: Radii.cardSmall, style: .continuous).fill(t.surface))
                .overlay(RoundedRectangle(cornerRadius: Radii.cardSmall, style: .continuous).stroke(t.border, lineWidth: 1))
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.bottom, Spacing.screenSafeBottom)
    }

    private func makeTemplateConfig(name: String, focus: String, exercises: Int, minutes: Int) -> PlanConfig {
        let days: [PlanDay]
        switch name {
        case "PPL 6-Tage":
            days = ["Push","Pull","Legs","Push","Pull","Legs"].enumerated().map {
                PlanDay(tag: "Tag \(["A","B","C","D","E","F"][$0.offset])", focus: $0.element,
                        exercises: $0.element == "Legs" ? 5 : 6,
                        minutes: $0.element == "Legs" ? 70 : 60)
            }
        case "Upper / Lower":
            days = ["Upper","Lower","Upper","Lower"].enumerated().map {
                PlanDay(tag: "Tag \(["A","B","C","D"][$0.offset])", focus: $0.element,
                        exercises: $0.element == "Upper" ? 7 : 6,
                        minutes: $0.element == "Upper" ? 55 : 60)
            }
        case "Ganzkörper 3x":
            days = (0..<3).map { PlanDay(tag: "Tag \(["A","B","C"][$0])", focus: "Full",
                                          exercises: 6, minutes: 50) }
        case "5×5 Kraft":
            days = (0..<3).map { PlanDay(tag: "Tag \(["A","B","C"][$0])", focus: "Kraft",
                                          exercises: 3, minutes: 45) }
        default:
            days = [PlanDay(tag: "Tag A", focus: focus, exercises: exercises, minutes: minutes)]
        }
        return PlanConfig(name: name, type: .rotating, days: days)
    }

    @ViewBuilder private var historyList: some View {
        if history.isEmpty {
            VStack(spacing: 14) {
                Image(systemName: "dumbbell")
                    .font(.system(size: 36))
                    .foregroundStyle(t.textMuted)
                Text("Noch keine Workouts")
                    .font(.custom(Typography.geist, size: 17).weight(.semibold))
                    .foregroundStyle(t.text)
                Text("Starte dein erstes Workout\num es hier zu sehen.")
                    .font(.custom(Typography.geist, size: 14))
                    .foregroundStyle(t.textMuted)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 60)
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.screenSafeBottom)
        } else {
            VStack(spacing: 8) {
                ForEach(history) { workout in
                    historyRow(workout)
                        .contextMenu {
                            Button(role: .destructive) {
                                Task { await deleteWorkout(workout) }
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.screenSafeBottom)
        }
    }

    @ViewBuilder private func historyRow(_ w: Workout) -> some View {
        let durationMin: Int = w.endedAt.map { Int($0.timeIntervalSince(w.startedAt) / 60) } ?? 0
        let isExpanded = expandedWorkoutID == w.id

        VStack(spacing: 0) {
            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    expandedWorkoutID = isExpanded ? nil : w.id
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(w.planDay ?? "Freies Workout")
                            .font(.custom(Typography.geist, size: 15).weight(.semibold))
                            .foregroundStyle(t.text)
                        HStack(spacing: 8) {
                            Text(Formatters.shortDate(w.startedAt)).foregroundStyle(t.textMuted)
                            if durationMin > 0 {
                                Text("·").foregroundStyle(t.textMuted)
                                Text("\(durationMin) min").foregroundStyle(t.textMuted)
                            }
                            let sc = w.sets.count
                            if sc > 0 {
                                Text("·").foregroundStyle(t.textMuted)
                                Text("\(sc) Sätze").foregroundStyle(t.textMuted)
                            }
                        }
                        .font(.custom(Typography.geistMono, size: 11))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(Formatters.compact(w.volumeKg))
                            .font(Typography.number(16)).foregroundStyle(t.text)
                        Text("kg")
                            .font(.custom(Typography.geistMono, size: 11)).foregroundStyle(t.textMuted)
                    }
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .medium)).foregroundStyle(t.textMuted)
                        .padding(.leading, 6)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Spacing.l).padding(.vertical, 14)

            if isExpanded && !w.sets.isEmpty {
                Rectangle().fill(t.border).frame(height: 0.5).padding(.horizontal, Spacing.l)

                let orderedNames: [String] = {
                    var seen = Set<String>()
                    return w.sets.compactMap { seen.insert($0.exerciseName).inserted ? $0.exerciseName : nil }
                }()

                VStack(spacing: 8) {
                    ForEach(orderedNames, id: \.self) { name in
                        let exSets = w.sets.filter { $0.exerciseName == name }
                        let topKg  = exSets.map(\.weightKg).max() ?? 0
                        HStack {
                            Text(name)
                                .font(.custom(Typography.geist, size: 13))
                                .foregroundStyle(t.textMid)
                                .lineLimit(1)
                            Spacer()
                            Text("\(exSets.count)× · \(Formatters.compact(topKg)) kg")
                                .font(.custom(Typography.geistMono, size: 11))
                                .foregroundStyle(t.textMuted)
                        }
                    }

                    Button {
                        editingWorkout = w
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "pencil").font(.system(size: 11, weight: .medium))
                            Text("Sätze bearbeiten").font(.custom(Typography.geist, size: 13))
                        }
                        .foregroundStyle(t.textMid)
                        .frame(maxWidth: .infinity, minHeight: 34)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(t.surface2))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, Spacing.l)
                .padding(.vertical, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: isExpanded ? Radii.card : Radii.row, style: .continuous)
                .fill(t.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: isExpanded ? Radii.card : Radii.row, style: .continuous)
                .stroke(isExpanded ? t.borderStrong : t.border, lineWidth: isExpanded ? 1.5 : 1)
        )
        .animation(.easeOut(duration: 0.2), value: isExpanded)
    }

    @ViewBuilder private var freeWorkoutTile: some View {
        Button { showActiveWorkout = true } label: {
            HStack(spacing: 14) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(t.text)
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(t.surface))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Freies Workout")
                        .font(.custom(Typography.geist, size: 15).weight(.semibold))
                        .foregroundStyle(t.text)
                    Text("Übungen frei wählen")
                        .font(.custom(Typography.geistMono, size: 11))
                        .foregroundStyle(t.textMuted)
                }
                Spacer()
            }
            .padding(18)
            .overlay(
                RoundedRectangle(cornerRadius: Radii.card, style: .continuous)
                    .stroke(t.borderStrong, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
            )
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }
}

// MARK: - Day card

struct DayCard: View {
    @Environment(\.theme) private var t
    var day: PlanDay
    var planType: PlanType = .rotating
    var onStart: () -> Void
    var onSkip: (() -> Void)? = nil

    var isToday: Bool { day.status == .today }
    @State private var showPreview = false

    var body: some View {
        if day.isRestDay {
            restCard
        } else {
            trainingCard
        }
    }

    @ViewBuilder private var restCard: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(day.tag.uppercased())
                    .font(.custom(Typography.geistMono, size: 11).weight(.medium))
                    .kerning(1)
                    .foregroundStyle(t.textMuted)
                Text("Ruhetag")
                    .font(.custom(Typography.geist, size: 20).weight(.semibold))
                    .foregroundStyle(t.textMuted)
            }
            Spacer()
            Image(systemName: "moon.zzz")
                .font(.system(size: 20))
                .foregroundStyle(t.textMuted)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radii.card, style: .continuous).fill(t.surface))
        .overlay(
            RoundedRectangle(cornerRadius: Radii.card, style: .continuous)
                .stroke(t.border, style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
        )
    }

    @ViewBuilder private var trainingCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(day.tag.uppercased())
                        .font(.custom(Typography.geistMono, size: 11).weight(.medium))
                        .kerning(1)
                        .foregroundStyle(isToday ? t.bg.opacity(0.6) : t.textMuted)
                    Text(day.focus)
                        .font(.custom(Typography.geist, size: 24).weight(.semibold))
                        .kerning(-0.6)
                        .foregroundStyle(isToday ? t.bg : t.text)
                    HStack(spacing: 12) {
                        Text("\(day.exercises) Übungen")
                        Text("·")
                        Text("~\(day.minutes) min")
                    }
                    .font(.custom(Typography.geistMono, size: 12))
                    .foregroundStyle(isToday ? t.bg.opacity(0.65) : t.textMuted)
                    .padding(.top, 10)
                }
                Spacer()
                statusBadge
            }

            if isToday {
                HStack(spacing: 8) {
                    Button(action: onStart) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill").font(.system(size: 12))
                            Text("Starten").font(.custom(Typography.geist, size: 13).weight(.semibold))
                        }
                        .foregroundStyle(t.accentText)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(t.accent))
                    }
                    .buttonStyle(.plain)

                    Button("Vorschau") { showPreview = true }
                        .font(.custom(Typography.geist, size: 13))
                        .foregroundStyle(t.bg)
                        .frame(minWidth: 80, minHeight: 40)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(t.bg.opacity(0.15)))
                        .buttonStyle(.plain)
                }
                .padding(.top, 16)

                if planType == .rotating, let skip = onSkip {
                    Button(action: skip) {
                        HStack(spacing: 6) {
                            Image(systemName: "forward.end.fill").font(.system(size: 10))
                            Text("Heute überspringen")
                                .font(.custom(Typography.geist, size: 12))
                        }
                        .foregroundStyle(t.bg.opacity(0.5))
                        .frame(maxWidth: .infinity, minHeight: 32)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radii.card, style: .continuous)
                .fill(isToday ? t.text : t.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radii.card, style: .continuous)
                .stroke(isToday ? Color.clear : t.border, lineWidth: 1)
        )
        .sheet(isPresented: $showPreview) {
            ThemedRoot {
                WorkoutPreviewSheet(day: day, onStart: onStart)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder private var statusBadge: some View {
        switch day.status {
        case .today:
            Text("Heute")
                .font(.custom(Typography.geistMono, size: 10).weight(.semibold))
                .kerning(0.8)
                .foregroundStyle(t.accentText)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(t.accent))
        case .next:
            Text("Morgen")
                .font(.custom(Typography.geistMono, size: 10).weight(.semibold))
                .kerning(0.8)
                .foregroundStyle(t.textMid)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(t.border, lineWidth: 1))
        case .planned:
            EmptyView()
        }
    }
}

// MARK: - Workout preview sheet

struct WorkoutPreviewSheet: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    var day: PlanDay
    var onStart: () -> Void

    private var exercises: [(name: String, muscle: String, sets: Int)] {
        switch day.focus {
        case "Push":
            return [("Bankdrücken","Brust · Hauptübung",4),("Schrägbank Kurzhantel","Brust · Schrägbank",4),
                    ("Butterfly Maschine","Brust · Isolation",3),("Schulterdrücken","Schultern · Hauptübung",4),
                    ("Seitheben","Schultern · Lateral",3),("Trizepsdrücken Kabel","Arme · Trizeps",3)]
        case "Pull":
            return [("Kreuzheben","Rücken · Hauptübung",4),("Klimmzüge","Rücken · Hauptübung",4),
                    ("Latzug","Rücken · Latissimus",3),("Rudern Langhantel","Rücken · Mitte",4),
                    ("Bizepscurls","Arme · Bizeps",3),("Hammercurls","Arme · Bizeps",3)]
        case "Legs":
            return [("Kniebeugen","Beine · Hauptübung",4),("Beinpresse","Beine · Quads",4),
                    ("Romanian Deadlift","Beine · Hamstrings",3),("Beinbeuger","Beine · Isolation",3),
                    ("Wadenheben","Beine · Waden",4)]
        case "Upper":
            return [("Bankdrücken","Brust · Hauptübung",4),("Schulterdrücken","Schultern · Hauptübung",4),
                    ("Klimmzüge","Rücken · Hauptübung",4),("Rudern Langhantel","Rücken · Mitte",3),
                    ("Bizepscurls","Arme · Bizeps",3),("Trizepsdrücken Kabel","Arme · Trizeps",3),
                    ("Dips","Brust · Trizeps",3)]
        case "Lower":
            return [("Kniebeugen","Beine · Hauptübung",4),("Beinpresse","Beine · Quads",4),
                    ("Romanian Deadlift","Beine · Hamstrings",3),("Beinbeuger","Beine · Isolation",3),
                    ("Wadenheben","Beine · Waden",4),("Wadenheben Sitzend","Beine · Waden sitzend",3)]
        case "Full":
            return [("Kniebeugen","Beine · Hauptübung",4),("Bankdrücken","Brust · Hauptübung",4),
                    ("Klimmzüge","Rücken · Hauptübung",4),("Schulterdrücken","Schultern · Hauptübung",3),
                    ("Romanian Deadlift","Beine · Hamstrings",3),("Bizepscurls","Arme · Bizeps",3)]
        case "Kraft":
            return [("Kniebeugen","Beine · Hauptübung",5),
                    ("Bankdrücken","Brust · Hauptübung",5),
                    ("Kreuzheben","Rücken · Hauptübung",5)]
        default: return []
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(day.tag.uppercased())
                        .font(Typography.eyebrow).kerning(1).foregroundStyle(t.textMuted)
                    Text(PlanData.bodyLabel(day))
                        .font(Typography.title(20)).foregroundStyle(t.text)
                }
                Spacer()
                HStack(spacing: 6) {
                    Text("\(day.exercises) Üb.").foregroundStyle(t.textMuted)
                    Text("·").foregroundStyle(t.textMuted)
                    Text("~\(day.minutes) min").foregroundStyle(t.textMuted)
                }
                .font(.custom(Typography.geistMono, size: 11))
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, 24).padding(.bottom, 16)

            Rectangle().fill(t.border).frame(height: 0.5)

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(Array(exercises.enumerated()), id: \.offset) { i, ex in
                        HStack(spacing: 14) {
                            Text("\(i + 1)")
                                .font(Typography.number(13)).foregroundStyle(t.textMuted)
                                .frame(width: 20, alignment: .center)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(ex.name)
                                    .font(.custom(Typography.geist, size: 15).weight(.medium))
                                    .foregroundStyle(t.text)
                                Text(ex.muscle)
                                    .font(.custom(Typography.geistMono, size: 11)).foregroundStyle(t.textMuted)
                            }
                            Spacer()
                            Text("\(ex.sets)×")
                                .font(Typography.number(13)).foregroundStyle(t.textMuted)
                        }
                        .padding(.horizontal, Spacing.l).padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: Radii.row, style: .continuous).fill(t.surface))
                        .overlay(RoundedRectangle(cornerRadius: Radii.row, style: .continuous).stroke(t.border, lineWidth: 1))
                    }
                }
                .padding(.horizontal, Spacing.xl).padding(.top, 16).padding(.bottom, 110)
            }
        }
        .background(t.bg.ignoresSafeArea())
        .overlay(alignment: .bottom) {
            VStack(spacing: 0) {
                Rectangle().fill(t.border).frame(height: 0.5)
                Button {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { onStart() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill").font(.system(size: 14))
                        Text("Workout starten")
                            .font(.custom(Typography.geist, size: 16).weight(.semibold))
                    }
                    .foregroundStyle(t.accentText)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(Capsule().fill(t.accent))
                    .padding(.horizontal, Spacing.xl).padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 16)
            }
            .background(t.bg)
        }
    }
}

// MARK: - Exercise browser sheet (search → detail)

struct ExerciseBrowserSheet: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    @Environment(AppDependencies.self) private var deps
    @State private var search = ""
    @State private var muscleFilter: MuscleGroup? = nil

    private let filterOpts: [(String, MuscleGroup?)] = [
        ("Alle", nil), ("Brust", .chest), ("Rücken", .back), ("Beine", .legs),
        ("Schultern", .shoulders), ("Arme", .arms), ("Core", .core),
    ]

    private var filtered: [CatalogExercise] {
        ExerciseCatalog.filtered(muscle: muscleFilter, search: search)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").font(.system(size: 15)).foregroundStyle(t.textMuted)
                    TextField("Übung suchen", text: $search)
                        .font(.custom(Typography.geist, size: 15)).foregroundStyle(t.text)
                }
                .padding(.horizontal, 14).padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(t.surface))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(t.border, lineWidth: 1))
                .padding(.horizontal, Spacing.xl).padding(.top, 16).padding(.bottom, 12)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(filterOpts, id: \.0) { label, value in
                            let active = muscleFilter == value
                            Button {
                                withAnimation(.easeOut(duration: 0.15)) { muscleFilter = value }
                            } label: {
                                Text(label)
                                    .font(.custom(Typography.geist, size: 13).weight(active ? .semibold : .regular))
                                    .foregroundStyle(active ? t.bg : t.textMid)
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(Capsule().fill(active ? t.text : Color.clear))
                                    .overlay(active ? nil : Capsule().stroke(t.border, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Spacing.xl)
                }
                .padding(.bottom, 12)

                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filtered) { ex in
                            NavigationLink(value: ExerciseRoute(name: ex.name, muscle: ex.muscleLabel)) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(ex.name)
                                            .font(.custom(Typography.geist, size: 15).weight(.medium))
                                            .foregroundStyle(t.text)
                                        Text(ex.muscleLabel)
                                            .font(.custom(Typography.geistMono, size: 11)).foregroundStyle(t.textMuted)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .medium)).foregroundStyle(t.textMuted)
                                }
                                .padding(.horizontal, Spacing.l).padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: Radii.row, style: .continuous).fill(t.surface))
                                .overlay(RoundedRectangle(cornerRadius: Radii.row, style: .continuous).stroke(t.border, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Spacing.xl).padding(.bottom, Spacing.screenSafeBottom)
                }
            }
            .background(t.bg.ignoresSafeArea())
            .navigationTitle("Übungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fertig") { dismiss() }
                        .font(.custom(Typography.geist, size: 15)).foregroundStyle(t.text)
                }
            }
            .navigationDestination(for: ExerciseRoute.self) { route in
                ExerciseDetailView(exerciseName: route.name, muscleLabel: route.muscle)
                    .environment(deps)
            }
        }
    }
}

// MARK: - Workout edit sheet (post-workout set editing)

struct WorkoutEditSheet: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss

    var workout: Workout
    var onSave: ([(id: UUID, weightKg: Double, reps: Int, rir: Int?)]) async -> Void

    struct SetEditItem: Identifiable {
        var id: UUID
        var exerciseName: String
        var setNo: Int
        var kgText: String
        var repsText: String
        var rirText: String
    }

    @State private var edits: [SetEditItem] = []

    private var exerciseNames: [String] {
        var seen = Set<String>()
        return edits.compactMap { seen.insert($0.exerciseName).inserted ? $0.exerciseName : nil }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(exerciseNames, id: \.self) { name in
                        let indices = edits.indices.filter { edits[$0].exerciseName == name }
                        exerciseCard(name: name, indices: indices)
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.top, 16)
                .padding(.bottom, Spacing.screenSafeBottom + 16)
            }
            .background(t.bg.ignoresSafeArea())
            .navigationTitle("Sätze bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                        .font(.custom(Typography.geist, size: 15))
                        .foregroundStyle(t.textMid)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { commitSave() }
                        .font(.custom(Typography.geist, size: 15).weight(.semibold))
                        .foregroundStyle(t.accent)
                }
            }
        }
        .onAppear { initEdits() }
    }

    @ViewBuilder private func exerciseCard(name: String, indices: [Int]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(.custom(Typography.geist, size: 13).weight(.semibold))
                .foregroundStyle(t.textMid)
                .padding(.horizontal, 4)

            Card(pad: 0) {
                VStack(spacing: 0) {
                    HStack {
                        Text("Set").frame(width: 28)
                        Text("Kg").frame(maxWidth: .infinity)
                        Text("Wdh").frame(maxWidth: .infinity)
                        Text("RIR").frame(maxWidth: .infinity)
                    }
                    .font(.custom(Typography.geistMono, size: 10))
                    .kerning(0.8)
                    .foregroundStyle(t.textMuted)
                    .padding(.horizontal, Spacing.l).padding(.top, 10).padding(.bottom, 4)

                    ForEach(Array(indices.enumerated()), id: \.offset) { pos, idx in
                        if pos > 0 {
                            Rectangle().fill(t.border).frame(height: 0.5).padding(.horizontal, Spacing.l)
                        }
                        editRow(idx: idx)
                    }
                    .padding(.bottom, 4)
                }
            }
        }
    }

    @ViewBuilder private func editRow(idx: Int) -> some View {
        HStack {
            Text("\(edits[idx].setNo)")
                .font(Typography.number(14)).foregroundStyle(t.textMuted)
                .frame(width: 28)

            TextField("0", text: $edits[idx].kgText)
                .keyboardType(.decimalPad)
                .font(Typography.number(14)).foregroundStyle(t.text)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            TextField("0", text: $edits[idx].repsText)
                .keyboardType(.numberPad)
                .font(Typography.number(14)).foregroundStyle(t.text)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            TextField("—", text: $edits[idx].rirText)
                .keyboardType(.numberPad)
                .font(Typography.number(14)).foregroundStyle(t.textMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, Spacing.l).padding(.vertical, 12)
    }

    private func initEdits() {
        var seen = Set<String>()
        let orderedNames = workout.sets.compactMap { seen.insert($0.exerciseName).inserted ? $0.exerciseName : nil }
        edits = orderedNames.flatMap { name in
            workout.sets
                .filter { $0.exerciseName == name }
                .sorted { $0.setNo < $1.setNo }
                .map { s in
                    let kgStr = s.weightKg.truncatingRemainder(dividingBy: 1) == 0
                        ? String(format: "%.0f", s.weightKg)
                        : String(format: "%.1f", s.weightKg)
                    return SetEditItem(id: s.id, exerciseName: s.exerciseName, setNo: s.setNo,
                                      kgText: kgStr, repsText: "\(s.reps)",
                                      rirText: s.rir.map { "\($0)" } ?? "")
                }
        }
    }

    private func commitSave() {
        let result: [(id: UUID, weightKg: Double, reps: Int, rir: Int?)] = edits.compactMap { item in
            guard let kg   = Double(item.kgText.replacingOccurrences(of: ",", with: ".")),
                  let reps = Int(item.repsText) else { return nil }
            let rir = item.rirText.isEmpty ? nil : Int(item.rirText)
            return (id: item.id, weightKg: kg, reps: reps, rir: rir)
        }
        Task {
            await onSave(result)
            dismiss()
        }
    }
}

#Preview {
    ThemedRoot { TrainingPlanView() }
}
