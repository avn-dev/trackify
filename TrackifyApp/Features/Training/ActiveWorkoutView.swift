import SwiftUI
import UserNotifications

struct ActiveWorkoutView: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    @Environment(AppDependencies.self) private var deps

    @AppStorage("hkWorkoutExport") private var hkWorkoutExport = false

    var planDay: PlanDay? = nil

    init(planDay: PlanDay? = nil) {
        self.planDay = planDay
        _exercises = State(initialValue: planDay.map { ActiveWorkoutView.planExercises(for: $0) }
                           ?? ActiveWorkoutView.defaultExercises())
    }

    @State private var startedAt = Date()
    @State private var elapsed = 0
    @State private var volumeKg = 0.0
    @State private var exercises: [WorkoutExercise]
    @State private var currentExIdx = 0
    @State private var restRemaining = 0
    @AppStorage("preferredRestSeconds") private var restTotal = 120
    @State private var isWorkoutPaused = false
    @State private var showExercisePicker = false
    @State private var showSwapPicker = false
    @State private var showSummary = false
    @State private var summaryData: WorkoutSummaryData?
    @State private var didPrefill = false
    @State private var timer: Timer?
    @State private var navPath = NavigationPath()

    var body: some View {
        workoutStack
            .onAppear { setupOnAppear() }
            .task { await prefillFromHistory() }
            .onDisappear {
                UIApplication.shared.isIdleTimerDisabled = false
                timer?.invalidate()
            }
            .sheet(isPresented: $showExercisePicker) {
                ExercisePickerSheet { catalog in addExercise(catalog) }
            }
            .sheet(isPresented: $showSwapPicker) {
                ExercisePickerSheet { catalog in swapExercise(catalog) }
            }
    }

    @ViewBuilder private var workoutStack: some View {
        NavigationStack(path: $navPath) {
            ZStack(alignment: .bottom) {
                scrollContent
                bottomActions
            }
            .navigationBarHidden(true)
            .navigationDestination(for: ExerciseRoute.self) { route in
                ExerciseDetailView(exerciseName: route.name, muscleLabel: route.muscle)
            }
            .sheet(isPresented: $showSummary, onDismiss: { dismiss() }) {
                if let data = summaryData {
                    WorkoutSummarySheet(data: data)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                }
            }
        }
    }

    @ViewBuilder private var scrollContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                liveHeader
                clockRow
                progressBar
                VStack(spacing: 12) {
                    currentExerciseCard
                    nextExerciseRow
                    addExerciseButton
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, 120)
            }
        }
        .background(t.bg.ignoresSafeArea())
    }

    private func setupOnAppear() {
        currentExIdx = min(currentExIdx, max(0, exercises.count - 1))
        let done = exercises.flatMap { $0.sets }.filter { $0.state == .done && $0.kg > 0 }
        volumeKg = done.reduce(0.0) { $0 + $1.kg * Double($1.reps) }
        UIApplication.shared.isIdleTimerDisabled = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            guard !isWorkoutPaused else { return }
            elapsed += 1
            if restRemaining > 0 {
                restRemaining -= 1
                if restRemaining == 0 {
                    HapticFeedback.medium()
                    cancelRestNotification()
                }
            }
        }
    }

    private func prefillFromHistory() async {
        guard !didPrefill else { return }
        didPrefill = true
        for i in exercises.indices {
            let prevSets = (try? await deps.workouts.fetchSets(exerciseName: exercises[i].name, limit: 8)) ?? []
            guard !prevSets.isEmpty else { continue }
            for j in exercises[i].sets.indices where exercises[i].sets[j].kg == 0 && exercises[i].sets[j].reps == 0 {
                let match = prevSets.first { $0.setNo == exercises[i].sets[j].no } ?? prevSets[0]
                exercises[i].sets[j].kg   = match.weightKg
                exercises[i].sets[j].reps = match.reps
            }
        }
    }

    /// Fallback: one pre-seeded exercise so the view is never empty in previews.
    private static func defaultExercises() -> [WorkoutExercise] {
        [makeExercise("Schrägbank Kurzhantel", muscle: "Brust · Hauptübung",
                      seeds: [(18, 10, 3, .done), (20, 9, 2, .done), (20, 8, 2, .active), (0, 0, 0, .pending)])]
    }

    /// Build starting exercises from a plan day's focus group.
    static func planExercises(for day: PlanDay) -> [WorkoutExercise] {
        let names: [String]
        switch day.focus {
        case "Push":
            names = ["Bankdrücken", "Schrägbank Kurzhantel", "Butterfly Maschine",
                     "Schulterdrücken", "Seitheben", "Trizepsdrücken Kabel"]
        case "Pull":
            names = ["Kreuzheben", "Klimmzüge", "Latzug",
                     "Rudern Langhantel", "Bizepscurls", "Hammercurls"]
        case "Legs":
            names = ["Kniebeugen", "Beinpresse", "Romanian Deadlift",
                     "Beinbeuger", "Wadenheben"]
        case "Upper":
            names = ["Bankdrücken", "Schulterdrücken", "Klimmzüge",
                     "Rudern Langhantel", "Bizepscurls", "Trizepsdrücken Kabel", "Dips"]
        case "Full":
            names = ["Kniebeugen", "Bankdrücken", "Klimmzüge",
                     "Schulterdrücken", "Romanian Deadlift", "Bizepscurls"]
        case "Lower":
            names = ["Kniebeugen", "Beinpresse", "Romanian Deadlift",
                     "Beinbeuger", "Wadenheben", "Wadenheben Sitzend"]
        case "Kraft":
            names = ["Kniebeugen", "Bankdrücken", "Kreuzheben"]
        default:
            return defaultExercises()
        }
        return names.map { name in
            let catalogEx = ExerciseCatalog.exercises.first { $0.name == name }
            let muscle = catalogEx?.muscleLabel ?? name
            return makeExercise(name, muscle: muscle,
                                seeds: [(0, 0, 2, .active), (0, 0, 2, .pending),
                                        (0, 0, 2, .pending), (0, 0, 2, .pending)])
        }
    }

    private static func makeExercise(
        _ name: String, muscle: String,
        seeds: [(kg: Double, reps: Int, rir: Int, state: SetState)]
    ) -> WorkoutExercise {
        let sets = seeds.enumerated().map { i, s in
            LiveSet(no: i + 1, kg: s.kg, reps: s.reps, rir: s.rir, state: s.state)
        }
        return WorkoutExercise(name: name, muscle: muscle, sets: sets)
    }

    private func finishWorkout() {
        let endedAt = Date()
        let workout = Workout(
            userID: .localUser,
            planDay: planDay?.tag,
            startedAt: startedAt,
            endedAt: endedAt,
            volumeKg: volumeKg
        )
        for ex in exercises {
            let exerciseID = UUID()
            for s in ex.sets where s.state == .done && s.kg > 0 {
                workout.sets.append(WorkoutSet(
                    workoutID: workout.id,
                    exerciseID: exerciseID,
                    exerciseName: ex.name,
                    setNo: s.no,
                    weightKg: s.kg,
                    reps: s.reps,
                    rir: s.rir > 0 ? s.rir : nil
                ))
            }
        }
        Task {
            try? await deps.workouts.save(workout)
            if hkWorkoutExport && HealthKitService.isAvailable {
                await HealthKitService.shared.saveWorkout(start: workout.startedAt, end: endedAt)
            }
        }

        // Advance plan to next day
        if let id = planDay?.id { PlanData.markCompleted(dayID: id) }

        UIApplication.shared.isIdleTimerDisabled = false
        timer?.invalidate()
        cancelRestNotification()

        // Build summary and show sheet; sheet's onDismiss calls dismiss()
        let exSummaries: [WorkoutSummaryData.ExSummary] = exercises.compactMap { ex in
            let done = ex.sets.filter { $0.state == .done && $0.kg > 0 }
            guard !done.isEmpty else { return nil }
            return WorkoutSummaryData.ExSummary(
                name: ex.name, sets: done.count,
                topWeightKg: done.map(\.kg).max() ?? 0
            )
        }
        summaryData = WorkoutSummaryData(
            planTag: planDay?.tag,
            volumeKg: volumeKg,
            setCount: exercises.flatMap(\.sets).filter { $0.state == .done && $0.kg > 0 }.count,
            durationSec: elapsed,
            exercises: exSummaries
        )
        showSummary = true
    }

    private func addExercise(_ catalog: CatalogExercise) {
        let ex = WorkoutExercise(
            name: catalog.name,
            muscle: catalog.muscleLabel,
            sets: [
                LiveSet(no: 1, kg: 0, reps: 0, rir: 0, state: .active),
                LiveSet(no: 2, kg: 0, reps: 0, rir: 0, state: .pending),
                LiveSet(no: 3, kg: 0, reps: 0, rir: 0, state: .pending),
                LiveSet(no: 4, kg: 0, reps: 0, rir: 0, state: .pending),
            ]
        )
        exercises.append(ex)
        currentExIdx = exercises.count - 1
    }

    private func swapExercise(_ catalog: CatalogExercise) {
        guard exercises.indices.contains(currentExIdx) else { return }
        exercises[currentExIdx].name   = catalog.name
        exercises[currentExIdx].muscle = catalog.muscleLabel
    }

    private func addSet() {
        guard exercises.indices.contains(currentExIdx) else { return }
        let nextNo = (exercises[currentExIdx].sets.last?.no ?? 0) + 1
        exercises[currentExIdx].sets.append(
            LiveSet(no: nextNo, kg: 0, reps: 0, rir: 0, state: .pending)
        )
    }

    private func scheduleRestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Pause beendet"
        content.body  = "Bereit für den nächsten Satz!"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Double(restTotal), repeats: false)
        let req = UNNotificationRequest(identifier: "trackify.rest.timer", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
    }

    private func cancelRestNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["trackify.rest.timer"])
    }

    @ViewBuilder private var liveHeader: some View {
        HStack {
            HStack(spacing: 10) {
                Circle()
                    .fill(t.accent)
                    .frame(width: 8, height: 8)
                    .overlay(Circle().fill(t.accent.opacity(0.3)).frame(width: 14, height: 14))
                Text(planDay.map { "LIVE · \($0.tag.uppercased())" } ?? "LIVE · FREI")
                    .font(.custom(Typography.geistMono, size: 12))
                    .kerning(1)
                    .foregroundStyle(t.textMid)
            }
            Spacer()
            Button("Beenden") { finishWorkout() }
                .font(.custom(Typography.geist, size: 13).weight(.medium))
                .foregroundStyle(t.danger)
        }
        .padding(.top, 54)
        .padding(.horizontal, Spacing.xl)
        .padding(.bottom, 12)
    }

    @ViewBuilder private var clockRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(Formatters.duration(elapsed))
                .font(Typography.number(52))
                .kerning(-2)
                .foregroundStyle(t.text)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("VOLUMEN")
                    .font(.custom(Typography.geistMono, size: 11))
                    .kerning(0.6)
                    .foregroundStyle(t.textMuted)
                Text(volumeKg > 0 ? String(format: "%.0f kg", volumeKg) : "– kg")
                    .font(Typography.number(18))
                    .foregroundStyle(t.text)
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.bottom, 12)
    }

    @ViewBuilder private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach(exercises.indices, id: \.self) { i in
                let state: SegState = i < currentExIdx ? .done : (i == currentExIdx ? .active : .pending)
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        state == .done ? t.accent :
                        state == .active ? t.text : t.borderStrong
                    )
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.bottom, 18)
        .animation(.easeOut(duration: 0.2), value: exercises.count)
        .animation(.easeOut(duration: 0.2), value: currentExIdx)
    }

    @ViewBuilder private var currentExerciseCard: some View {
        if exercises.indices.contains(currentExIdx) {
        let ex = exercises[currentExIdx]
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("● AKTUELL · Ü \(currentExIdx + 1)/\(exercises.count)")
                        .font(.custom(Typography.geistMono, size: 10).weight(.semibold))
                        .kerning(1)
                        .foregroundStyle(t.accent)
                    Button {
                        navPath.append(ExerciseRoute(name: ex.name, muscle: ex.muscle))
                    } label: {
                        Text(ex.name)
                            .font(.custom(Typography.geist, size: 20).weight(.semibold))
                            .kerning(-0.4)
                            .foregroundStyle(t.text)
                    }
                    .buttonStyle(.plain)
                    Text(ex.muscle)
                        .font(.custom(Typography.geistMono, size: 12))
                        .foregroundStyle(t.textMuted)
                }
                Spacer()
                HStack(spacing: 8) {
                    if exercises.count > 1 {
                        navArrow(icon: "chevron.left", enabled: currentExIdx > 0) {
                            withAnimation(.easeOut(duration: 0.2)) { currentExIdx -= 1 }
                        }
                        navArrow(icon: "chevron.right", enabled: currentExIdx < exercises.count - 1) {
                            withAnimation(.easeOut(duration: 0.2)) { currentExIdx += 1 }
                        }
                    }
                    CircleBtn(systemIcon: "arrow.2.squarepath") { showSwapPicker = true }
                    CircleBtn(systemIcon: "chart.xyaxis.line") {
                        navPath.append(ExerciseRoute(name: ex.name, muscle: ex.muscle))
                    }
                }
            }

            setTable.padding(.top, 14)
            addSetButton.padding(.top, 8)
            if restRemaining > 0 {
                restTimerRow.padding(.top, 12)
            } else {
                restDurationRow.padding(.top, 6)
            }
        }
        .padding(Spacing.l)
        .background(RoundedRectangle(cornerRadius: Radii.card, style: .continuous).fill(t.surface))
        .overlay(RoundedRectangle(cornerRadius: Radii.card, style: .continuous).stroke(t.accent, lineWidth: 1.5))
        }
    }

    @ViewBuilder private func navArrow(icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(enabled ? t.text : t.textMuted)
                .frame(width: 32, height: 32)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(t.surface2))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    @ViewBuilder private var setTable: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Set").frame(width: 24)
                Text("Kg").frame(maxWidth: .infinity)
                Text("Wdh").frame(maxWidth: .infinity)
                Text("RIR").frame(maxWidth: .infinity)
                Spacer().frame(width: 28)
            }
            .font(.custom(Typography.geistMono, size: 10))
            .kerning(0.8)
            .foregroundStyle(t.textMuted)
            .padding(.horizontal, 8)

            ForEach($exercises[currentExIdx].sets) { $s in
                SetRow(set: $s, onEditComplete: { recomputeVolume() }) {
                    withAnimation(.spring(duration: 0.2)) {
                        if let i = exercises[currentExIdx].sets.firstIndex(where: { $0.id == s.id }) {
                            exercises[currentExIdx].sets[i].state = .done
                            if i + 1 < exercises[currentExIdx].sets.count {
                                exercises[currentExIdx].sets[i + 1].state = .active
                            }
                            volumeKg += s.kg * Double(s.reps)
                            HapticFeedback.success()
                            restRemaining = restTotal
                            scheduleRestNotification()
                        }
                    }
                }
            }
        }
    }

    private func recomputeVolume() {
        volumeKg = exercises.flatMap(\.sets)
            .filter { $0.state == .done && $0.kg > 0 }
            .reduce(0.0) { $0 + $1.kg * Double($1.reps) }
    }

    @ViewBuilder private var addSetButton: some View {
        Button { addSet() } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus").font(.system(size: 12, weight: .medium))
                Text("Satz hinzufügen").font(.custom(Typography.geist, size: 13))
            }
            .foregroundStyle(t.textMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(t.border, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var restDurationRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "timer")
                .font(.system(size: 12))
                .foregroundStyle(t.textMuted)
            Text("Pause · \(Formatters.duration(restTotal))")
                .font(.custom(Typography.geistMono, size: 12))
                .foregroundStyle(t.textMuted)
            Spacer()
            Button {
                if restTotal > 30 { restTotal -= 30 }
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(t.textMid)
                    .frame(width: 28, height: 28)
                    .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(t.surface2))
            }
            .buttonStyle(.plain)
            .disabled(restTotal <= 30)

            Button {
                if restTotal < 300 { restTotal += 30 }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(t.textMid)
                    .frame(width: 28, height: 28)
                    .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(t.surface2))
            }
            .buttonStyle(.plain)
            .disabled(restTotal >= 300)
        }
        .padding(.horizontal, 8)
        .opacity(0.7)
    }

    @ViewBuilder private var restTimerRow: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(t.accent)
                .frame(width: 28, height: 28)
                .overlay(Image(systemName: "timer").font(.system(size: 14)).foregroundStyle(t.accentText))
            VStack(alignment: .leading, spacing: 1) {
                Text("PAUSE LÄUFT")
                    .font(.custom(Typography.geistMono, size: 11))
                    .kerning(0.6)
                    .foregroundStyle(t.textMuted)
                HStack(spacing: 0) {
                    Text(Formatters.duration(restRemaining))
                        .font(Typography.number(18))
                        .foregroundStyle(t.text)
                    Text(" / \(Formatters.duration(restTotal))")
                        .font(.custom(Typography.geistMono, size: 13))
                        .foregroundStyle(t.textMuted)
                }
            }
            Spacer()
            Button("Skip") { restRemaining = 0; cancelRestNotification() }
                .font(.custom(Typography.geist, size: 12))
                .foregroundStyle(t.text)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .overlay(Capsule().stroke(t.borderStrong, lineWidth: 1))
                .buttonStyle(.plain)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: Radii.row, style: .continuous).fill(t.bg))
        .overlay(RoundedRectangle(cornerRadius: Radii.row, style: .continuous).stroke(t.border, lineWidth: 1))
    }

    @ViewBuilder private var nextExerciseRow: some View {
        if let next = exercises[safe: currentExIdx + 1] {
            Button {
                withAnimation(.easeOut(duration: 0.2)) { currentExIdx += 1 }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "dumbbell")
                        .font(.system(size: 18))
                        .foregroundStyle(t.text)
                        .frame(width: 36, height: 36)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(t.surface2))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(next.name)
                            .font(.custom(Typography.geist, size: 14).weight(.medium))
                            .foregroundStyle(t.text)
                        Text("Als nächstes · \(next.sets.count) Sätze")
                            .font(.custom(Typography.geistMono, size: 11))
                            .foregroundStyle(t.textMuted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(t.textMuted)
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: Radii.cardSmall, style: .continuous).fill(t.surface))
                .overlay(RoundedRectangle(cornerRadius: Radii.cardSmall, style: .continuous).stroke(t.border, lineWidth: 1))
                .opacity(0.7)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder private var addExerciseButton: some View {
        Button { showExercisePicker = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(t.text)
                    .frame(width: 36, height: 36)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(t.surface))
                Text("Übung hinzufügen")
                    .font(.custom(Typography.geist, size: 14).weight(.medium))
                    .foregroundStyle(t.textMid)
                Spacer()
            }
            .padding(14)
            .overlay(
                RoundedRectangle(cornerRadius: Radii.card, style: .continuous)
                    .stroke(t.borderStrong, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var bottomActions: some View {
        HStack(spacing: 10) {
            Button {
                guard exercises.indices.contains(currentExIdx) else { return }
                if let i = exercises[currentExIdx].sets.firstIndex(where: { $0.state == .active }) {
                    let s = exercises[currentExIdx].sets[i]
                    exercises[currentExIdx].sets[i].state = .done
                    if i + 1 < exercises[currentExIdx].sets.count {
                        exercises[currentExIdx].sets[i + 1].state = .active
                    }
                    if s.kg > 0 && s.reps > 0 { volumeKg += s.kg * Double(s.reps) }
                    restRemaining = restTotal
                    scheduleRestNotification()
                    HapticFeedback.success()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark").font(.system(size: 16, weight: .semibold))
                    Text("Satz abschließen").font(.custom(Typography.geist, size: 16).weight(.semibold))
                }
                .foregroundStyle(t.accentText)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(Capsule().fill(t.accent))
            }
            .buttonStyle(.plain)

            CircleBtn(systemIcon: isWorkoutPaused ? "play.fill" : "pause.fill") {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                    isWorkoutPaused.toggle()
                }
                HapticFeedback.light()
            }
            .frame(width: 56, height: 56)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.bottom, 30)
    }
}

// MARK: - Set row

struct SetRow: View {
    @Environment(\.theme) private var t
    @Binding var set: LiveSet
    var onEditComplete: () -> Void = {}
    var onCheck: () -> Void

    @State private var kgText = ""
    @State private var repsText = ""
    @State private var rirText = ""
    @State private var isEditing = false

    var body: some View {
        let showField = set.state == .active || isEditing
        HStack {
            Text(set.state == .done && !isEditing ? "✓" : "\(set.no)")
                .font(Typography.number(14))
                .foregroundStyle(set.state == .done && !isEditing ? t.accent : t.text)
                .frame(width: 24)

            setCell(showField: showField, strikethrough: set.state == .done && !isEditing) {
                TextField("0", text: $kgText)
                    .keyboardType(.decimalPad)
                    .onChange(of: kgText) { _, v in
                        if let d = Double(v.replacingOccurrences(of: ",", with: ".")) { set.kg = d }
                    }
            } staticLabel: {
                Text(set.state == .pending ? "—" : formatKg(set.kg))
                    .strikethrough(set.state == .done)
            }

            setCell(showField: showField, strikethrough: set.state == .done && !isEditing) {
                TextField("0", text: $repsText)
                    .keyboardType(.numberPad)
                    .onChange(of: repsText) { _, v in
                        if let i = Int(v) { set.reps = i }
                    }
            } staticLabel: {
                Text(set.state == .pending ? "—" : "\(set.reps)")
                    .strikethrough(set.state == .done)
            }

            setCell(showField: showField, strikethrough: set.state == .done && !isEditing) {
                TextField("0", text: $rirText)
                    .keyboardType(.numberPad)
                    .onChange(of: rirText) { _, v in
                        if let i = Int(v) { set.rir = i }
                    }
            } staticLabel: {
                Text(set.state == .pending ? "—" : "\(set.rir)")
                    .strikethrough(set.state == .done)
            }

            if set.state == .active {
                Button(action: onCheck) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(t.accentText)
                        .frame(width: 24, height: 24)
                        .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(t.accent))
                }
                .buttonStyle(.plain)
            } else if set.state == .done {
                if isEditing {
                    Button {
                        isEditing = false
                        onEditComplete()
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(t.text)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 24)
                } else {
                    Button {
                        isEditing = true
                        syncTextsForEdit()
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                            .foregroundStyle(t.textMuted)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundStyle(t.textMuted)
                    .frame(width: 24)
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    set.state == .active ? t.bg :
                    (set.state == .done && isEditing ? t.surface2 : Color.clear)
                )
        )
        .overlay(
            (set.state == .active || (set.state == .done && isEditing))
            ? RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(set.state == .done ? t.border : t.borderStrong, lineWidth: 1)
            : nil
        )
        .onAppear { syncTexts() }
        .onChange(of: set.state) { _, _ in isEditing = false; syncTexts() }
        .onChange(of: set.kg) { _, newKg in
            guard set.state == .active else { return }
            kgText = newKg > 0 ? formatKg(newKg) : ""
        }
        .onChange(of: set.reps) { _, newReps in
            guard set.state == .active else { return }
            repsText = newReps > 0 ? "\(newReps)" : ""
        }
    }

    @ViewBuilder private func setCell<F: View, S: View>(
        showField: Bool, strikethrough: Bool,
        @ViewBuilder field: () -> F,
        @ViewBuilder staticLabel: () -> S
    ) -> some View {
        Group {
            if showField {
                field()
                    .font(Typography.number(14))
                    .foregroundStyle(t.text)
                    .multilineTextAlignment(.center)
            } else {
                staticLabel()
                    .font(Typography.number(14))
                    .foregroundStyle(strikethrough ? t.textMuted : t.text)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func syncTexts() {
        guard set.state == .active else { return }
        kgText   = set.kg > 0   ? formatKg(set.kg) : ""
        repsText = set.reps > 0 ? "\(set.reps)"     : ""
        rirText  = "\(set.rir)"
    }

    private func syncTextsForEdit() {
        kgText   = set.kg > 0   ? formatKg(set.kg) : ""
        repsText = set.reps > 0 ? "\(set.reps)"     : ""
        rirText  = set.rir > 0  ? "\(set.rir)"      : ""
    }

    private func formatKg(_ kg: Double) -> String {
        kg.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", kg)
            : String(format: "%.1f", kg)
    }
}

// MARK: - Models

struct WorkoutExercise: Identifiable {
    let id = UUID()
    var name: String
    var muscle: String
    var sets: [LiveSet]
}

struct LiveSet: Identifiable {
    let id = UUID()
    var no: Int
    var kg: Double
    var reps: Int
    var rir: Int
    var state: SetState
}

enum SetState { case done, active, pending }
enum SegState { case done, active, pending }

struct ExerciseRoute: Hashable {
    var name: String
    var muscle: String
}

#Preview {
    ThemedRoot { ActiveWorkoutView() }
        .environment(AppDependencies.mock())
}

// MARK: - Workout summary

struct WorkoutSummaryData {
    var planTag: String?
    var volumeKg: Double
    var setCount: Int
    var durationSec: Int
    var exercises: [ExSummary]

    struct ExSummary: Identifiable {
        let id = UUID()
        var name: String
        var sets: Int
        var topWeightKg: Double
    }
}

struct WorkoutSummarySheet: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    var data: WorkoutSummaryData

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(t.accent)
                    .padding(.top, 36)
                Text(data.planTag.map { "\($0) abgeschlossen" } ?? "Workout abgeschlossen")
                    .font(Typography.title(22))
                    .kerning(-0.6)
                    .foregroundStyle(t.text)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, 28)

            HStack(spacing: 0) {
                summaryCell(label: "Volumen", value: Formatters.compact(data.volumeKg), unit: "kg")
                Rectangle().fill(t.border).frame(width: 1, height: 44)
                summaryCell(label: "Sätze", value: "\(data.setCount)", unit: nil)
                Rectangle().fill(t.border).frame(width: 1, height: 44)
                summaryCell(label: "Dauer", value: Formatters.duration(data.durationSec), unit: nil)
            }
            .padding(.bottom, 24)

            Rectangle().fill(t.border).frame(height: 0.5)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(data.exercises) { ex in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ex.name)
                                    .font(.custom(Typography.geist, size: 15).weight(.medium))
                                    .foregroundStyle(t.text)
                                Text("\(ex.sets) Sätze · \(Formatters.compact(ex.topWeightKg)) kg max")
                                    .font(.custom(Typography.geistMono, size: 11))
                                    .foregroundStyle(t.textMuted)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, Spacing.l).padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: Radii.row, style: .continuous).fill(t.surface))
                        .overlay(RoundedRectangle(cornerRadius: Radii.row, style: .continuous).stroke(t.border, lineWidth: 1))
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.top, 16)
                .padding(.bottom, 8)
            }

            PrimaryButton(title: "Fertig") { dismiss() }
                .padding(.horizontal, Spacing.xl)
                .padding(.top, 12)
                .padding(.bottom, max(Spacing.screenSafeBottom, 24))
        }
        .background(t.bg.ignoresSafeArea())
    }

    @ViewBuilder private func summaryCell(label: String, value: String, unit: String?) -> some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value).font(Typography.number(26)).kerning(-0.8).foregroundStyle(t.text)
                if let unit {
                    Text(unit).font(.custom(Typography.geistMono, size: 12)).foregroundStyle(t.textMuted)
                }
            }
            Text(label.uppercased()).font(Typography.eyebrow).foregroundStyle(t.textMuted)
        }
        .frame(maxWidth: .infinity)
    }
}
