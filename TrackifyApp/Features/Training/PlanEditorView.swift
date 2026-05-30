import SwiftUI

// MARK: - Mode

enum PlanEditorMode {
    case createNew
    case createFrom(PlanConfig)   // adopt a template as a new plan
    case update(PlanConfig)       // edit an existing plan
}

// MARK: - View

struct PlanEditorView: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss

    var mode: PlanEditorMode
    @State private var draft: PlanConfig

    init(mode: PlanEditorMode) {
        self.mode = mode
        switch mode {
        case .createNew:
            self._draft = State(initialValue: PlanConfig(
                name: "Neuer Plan",
                days: [PlanDay(tag: "Tag A", focus: "Push", exercises: 4, minutes: 60)]
            ))
        case .createFrom(let template):
            var p = template
            p.id = UUID()
            p.lastCompletedDayID = ""
            self._draft = State(initialValue: p)
        case .update(let existing):
            self._draft = State(initialValue: existing)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ScreenHeader(
                        title: isCreating ? "Plan erstellen" : "Plan bearbeiten",
                        eyebrow: "Training"
                    )

                    VStack(spacing: 20) {
                        nameSection
                        typeSection
                        if draft.type == .rotating { skipBehaviorSection }
                        daysSection
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, 100)
                }
            }
            .background(t.bg.ignoresSafeArea())
            .navigationBarHidden(true)
            .overlay(alignment: .bottom) { saveBar }
        }
    }

    private var isCreating: Bool {
        if case .update = mode { return false }
        return true
    }

    // MARK: - Sections

    @ViewBuilder private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Plan")
            Card(pad: 0) {
                TextField("Planname", text: $draft.name)
                    .font(.custom(Typography.geist, size: 15))
                    .foregroundStyle(t.text)
                    .submitLabel(.done)
                    .padding(.horizontal, Spacing.l).padding(.vertical, 14)
            }
        }
    }

    @ViewBuilder private var typeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Typ")
            HStack(spacing: 8) {
                ForEach(PlanType.allCases, id: \.self) { type in
                    let sel = draft.type == type
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            draft.type = type
                            if type == .weekday { ensureWeekdayAssignments() }
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(type.label)
                                .font(.custom(Typography.geist, size: 14).weight(.semibold))
                                .foregroundStyle(sel ? t.bg : t.text)
                            Text(type.description)
                                .font(.custom(Typography.geistMono, size: 10))
                                .foregroundStyle(sel ? t.bg.opacity(0.6) : t.textMuted)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: Radii.cardSmall, style: .continuous)
                            .fill(sel ? t.text : t.surface))
                        .overlay(sel ? nil : RoundedRectangle(cornerRadius: Radii.cardSmall, style: .continuous)
                            .stroke(t.border, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder private var skipBehaviorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Skip-Verhalten")
            Card(pad: 0) {
                ForEach(Array(SkipBehavior.allCases.enumerated()), id: \.element) { i, behavior in
                    let sel = draft.skipBehavior == behavior
                    Button {
                        withAnimation(.easeOut(duration: 0.15)) { draft.skipBehavior = behavior }
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(behavior.label)
                                    .font(.custom(Typography.geist, size: 14).weight(.medium))
                                    .foregroundStyle(t.text)
                                Text(behavior.description)
                                    .font(.custom(Typography.geistMono, size: 11))
                                    .foregroundStyle(t.textMuted)
                            }
                            Spacer()
                            if sel {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18)).foregroundStyle(t.accent)
                            } else {
                                Circle().stroke(t.border, lineWidth: 1.5).frame(width: 18, height: 18)
                            }
                        }
                        .padding(.horizontal, Spacing.l).padding(.vertical, 14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if i < SkipBehavior.allCases.count - 1 {
                        Rectangle().fill(t.border).frame(height: 0.5).padding(.horizontal, Spacing.l)
                    }
                }
            }
        }
    }

    @ViewBuilder private var daysSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                sectionLabel("Tage")
                Spacer()
                Button { addDay() } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(t.accent)
                }
                .buttonStyle(.plain)
                .disabled(draft.type == .weekday && draft.days.count >= 7)
            }

            VStack(spacing: 8) {
                ForEach(draft.days.indices, id: \.self) { i in
                    DayEditorRow(
                        day: $draft.days[i],
                        planType: draft.type,
                        canDelete: draft.days.count > 1
                    ) { draft.days.remove(at: i) }
                }
            }

            if draft.type == .rotating {
                Button { addRestDay() } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "moon.zzz").font(.system(size: 13))
                        Text("Ruhetag hinzufügen").font(.custom(Typography.geist, size: 13))
                    }
                    .foregroundStyle(t.textMuted)
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .overlay(RoundedRectangle(cornerRadius: Radii.row, style: .continuous)
                        .stroke(t.border, style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Save bar

    @ViewBuilder private var saveBar: some View {
        VStack(spacing: 0) {
            Rectangle().fill(t.border).frame(height: 0.5)
            HStack(spacing: 10) {
                Button("Abbrechen") { dismiss() }
                    .font(.custom(Typography.geist, size: 15))
                    .foregroundStyle(t.textMid)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(RoundedRectangle(cornerRadius: Radii.row, style: .continuous).fill(t.surface))
                    .overlay(RoundedRectangle(cornerRadius: Radii.row, style: .continuous).stroke(t.border, lineWidth: 1))
                    .buttonStyle(.plain)

                Button(isCreating ? "Erstellen" : "Speichern") { save() }
                    .font(.custom(Typography.geist, size: 15).weight(.semibold))
                    .foregroundStyle(t.accentText)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(RoundedRectangle(cornerRadius: Radii.row, style: .continuous).fill(t.accent))
                    .buttonStyle(.plain)
            }
            .padding(.horizontal, Spacing.xl).padding(.vertical, 12)
            .background(t.bg)
        }
    }

    // MARK: - Helpers

    @ViewBuilder private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(Typography.eyebrow).kerning(Tracking.eyebrow)
            .foregroundStyle(t.textMuted)
    }

    private func save() {
        switch mode {
        case .createNew, .createFrom:
            PlanData.addPlan(draft)
        case .update:
            PlanData.updatePlan(draft)
        }
        dismiss()
    }

    private func addDay() {
        if draft.type == .weekday {
            let used = Set(draft.days.map(\.weekday))
            guard let free = (1...7).first(where: { !used.contains($0) }) else { return }
            draft.days.append(PlanDay(tag: PlanData.wdShort(free), focus: "Push",
                                      exercises: 4, minutes: 60, weekday: free))
        } else {
            draft.days.append(PlanDay(tag: "Tag \(nextLetter())", focus: "Push",
                                      exercises: 4, minutes: 60))
        }
    }

    private func addRestDay() {
        draft.days.append(PlanDay(tag: "Tag \(nextLetter())", focus: "", exercises: 0, minutes: 0))
    }

    private func nextLetter() -> String {
        let letters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        return String(letters[min(draft.days.count, letters.count - 1)])
    }

    private func ensureWeekdayAssignments() {
        draft.days = draft.days.filter { !$0.isRestDay }
        let used = Set(draft.days.compactMap { $0.weekday > 0 ? $0.weekday : nil })
        var available = (1...7).filter { !used.contains($0) }
        for i in draft.days.indices where draft.days[i].weekday == 0 {
            if let wd = available.first {
                draft.days[i].weekday = wd
                draft.days[i].tag = PlanData.wdShort(wd)
                available.removeFirst()
            }
        }
    }
}

// MARK: - Day editor row

struct DayEditorRow: View {
    @Environment(\.theme) private var t
    @Binding var day: PlanDay
    var planType: PlanType
    var canDelete: Bool
    var onDelete: () -> Void

    var body: some View {
        Card(pad: 0) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    if planType == .weekday {
                        weekdayPicker
                    } else {
                        Text(day.tag)
                            .font(.custom(Typography.geistMono, size: 11).weight(.semibold))
                            .foregroundStyle(t.textMuted)
                            .frame(width: 40)
                    }

                    TextField(day.isRestDay ? "Ruhetag" : "Fokus (z.B. Push)", text: $day.focus)
                        .font(.custom(Typography.geist, size: 15).weight(.medium))
                        .foregroundStyle(day.isRestDay ? t.textMuted : t.text)
                        .submitLabel(.done)

                    Spacer()

                    if canDelete {
                        Button(action: onDelete) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(t.danger.opacity(0.75))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.l).padding(.vertical, 14)

                if !day.isRestDay {
                    Rectangle().fill(t.border).frame(height: 0.5).padding(.horizontal, Spacing.l)

                    HStack(spacing: 0) {
                        stepperCell(label: "Üb.", value: $day.exercises, range: 1...20)
                        Rectangle().fill(t.border).frame(width: 0.5, height: 36)
                        stepperCell(label: "min", value: $day.minutes, range: 15...180, step: 5)
                    }
                    .padding(.horizontal, Spacing.l).padding(.vertical, 8)
                }
            }
        }
    }

    @ViewBuilder private func stepperCell(
        label: String, value: Binding<Int>, range: ClosedRange<Int>, step: Int = 1
    ) -> some View {
        Stepper(value: value, in: range, step: step) {
            HStack(spacing: 4) {
                Text("\(value.wrappedValue)")
                    .font(Typography.number(14)).foregroundStyle(t.text)
                Text(label)
                    .font(.custom(Typography.geistMono, size: 11)).foregroundStyle(t.textMuted)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder private var weekdayPicker: some View {
        Menu {
            ForEach(1...7, id: \.self) { wd in
                Button(PlanData.wdLong(wd)) {
                    day.weekday = wd
                    day.tag = PlanData.wdShort(wd)
                }
            }
        } label: {
            HStack(spacing: 3) {
                Text(day.weekday > 0 ? PlanData.wdShort(day.weekday) : "—")
                    .font(.custom(Typography.geistMono, size: 12).weight(.semibold))
                    .foregroundStyle(t.accent)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 8)).foregroundStyle(t.textMuted)
            }
            .frame(width: 40)
        }
    }
}

#Preview {
    ThemedRoot { PlanEditorView(mode: .createNew) }
}
