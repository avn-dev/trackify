import SwiftUI

struct SupplementAddView: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    @Environment(AppDependencies.self) private var deps

    var editingSupplement: Supplement? = nil

    @State private var kind = 0 // 0=Supplement 1=Medikament 2=Pflanzlich
    @State private var name = ""
    @State private var dose = ""
    @State private var form = "Kapsel"
    @State private var stock = ""
    @State private var frequency = "Täglich"
    @State private var selectedTimes: Set<Int> = [0]
    @State private var withFood = false
    @State private var reminderOn = true
    @State private var trackStock = true

    private var isEditing: Bool { editingSupplement != nil }

    private let kinds = ["Supplement", "Medikament", "Pflanzlich"]
    private let kindIcons = ["leaf.fill", "pills.fill", "leaf.circle.fill"]
    private let forms = ["Kapsel", "Tablette", "Pulver", "Tropfen", "Gel"]
    private let timeSlots = ["07:30 · Morgens", "12:00 · Mittags", "19:00 · Abends", "21:00 · Vor Schlaf"]
    private let timeValues = ["07:30", "12:00", "19:00", "21:00"]
    private let frequencies = ["Täglich", "Wöchentlich", "Jeden 2. Tag", "Bei Bedarf"]
    private let frequencyValues = ["daily", "weekly", "every_other", "as_needed"]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(t.textMid)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(t.surface2))
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Text(isEditing ? "Bearbeiten" : "Neu hinzufügen")
                        .font(.custom(Typography.geist, size: 17).weight(.semibold))
                        .foregroundStyle(t.text)
                    Spacer()
                    Spacer().frame(width: 32)
                }
                .padding(.top, 54)
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, 20)

                kindPicker.padding(.horizontal, Spacing.xl)

                detailsCard.padding(.horizontal, Spacing.xl).padding(.top, 16)
                whenCard.padding(.horizontal, Spacing.xl).padding(.top, 12)
                optionsCard.padding(.horizontal, Spacing.xl).padding(.top, 12)

                PrimaryButton(title: isEditing ? "Speichern" : "Hinzufügen") { Task { await saveSupplement() } }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, 20)
                    .padding(.bottom, Spacing.screenSafeBottom)
            }
        }
        .background(t.bg.ignoresSafeArea())
        .onAppear { prefillIfEditing() }
    }

    private func prefillIfEditing() {
        guard let s = editingSupplement else { return }
        name = s.name
        dose = s.dose
        form = s.form
        stock = s.stockUnits > 0 ? "\(s.stockUnits)" : ""
        withFood = s.withFood
        reminderOn = s.reminderOn
        trackStock = s.trackStock
        kind = SupplementKind.allCases.firstIndex(of: s.kind) ?? 0
        frequency = frequencyValues.firstIndex(of: s.frequency).map { frequencies[$0] } ?? "Täglich"
        selectedTimes = Set(
            s.times.compactMap { timeValues.firstIndex(of: $0) }
        )
        if selectedTimes.isEmpty { selectedTimes = [0] }
    }

    private func saveSupplement() async {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let kindEnum = SupplementKind.allCases[safe: kind] ?? .supplement
        let selectedTimeValues = selectedTimes.sorted().map { timeValues[safe: $0] ?? "07:00" }
        let freqValue = frequencyValues[safe: frequencies.firstIndex(of: frequency) ?? 0] ?? "daily"

        if let existing = editingSupplement {
            existing.name = name.trimmingCharacters(in: .whitespaces)
            existing.kind = kindEnum
            existing.dose = dose
            existing.form = form
            existing.stockUnits = Int(stock) ?? existing.stockUnits
            existing.frequency = freqValue
            existing.times = selectedTimeValues
            existing.withFood = withFood
            existing.reminderOn = reminderOn
            existing.trackStock = trackStock
            try? await deps.supplements.save(existing)
        } else {
            let sup = Supplement(
                userID: .localUser,
                name: name.trimmingCharacters(in: .whitespaces),
                kind: kindEnum,
                dose: dose,
                form: form,
                stockUnits: Int(stock) ?? 0,
                frequency: freqValue,
                times: selectedTimeValues,
                withFood: withFood,
                reminderOn: reminderOn,
                trackStock: trackStock
            )
            try? await deps.supplements.save(sup)
        }
        let all = (try? await deps.supplements.fetchSupplements()) ?? []
        await NotificationScheduler.shared.scheduleSupplements(all)
        dismiss()
    }

    @ViewBuilder private var kindPicker: some View {
        HStack(spacing: 8) {
            ForEach(kinds.indices, id: \.self) { i in
                Button {
                    withAnimation(.easeOut(duration: 0.18)) { kind = i }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: kindIcons[i])
                            .font(.system(size: 20))
                            .foregroundStyle(kind == i ? t.accent : t.textMid)
                        Text(kinds[i])
                            .font(.custom(Typography.geist, size: 12).weight(kind == i ? .semibold : .regular))
                            .foregroundStyle(kind == i ? t.bg : t.textMuted)
                    }
                    .frame(maxWidth: .infinity, minHeight: 72)
                    .background(
                        RoundedRectangle(cornerRadius: Radii.cardSmall, style: .continuous)
                            .fill(kind == i ? t.text : t.surface2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder private var detailsCard: some View {
        Card(pad: 0) {
            formRow(label: "Name") {
                TextField("z.B. Vitamin D3", text: $name)
                    .font(.custom(Typography.geist, size: 15))
                    .foregroundStyle(t.text)
            }
            Divider().background(t.border).padding(.horizontal, Spacing.l)
            formRow(label: "Dosis") {
                TextField("z.B. 4000 IE", text: $dose)
                    .font(.custom(Typography.geist, size: 15))
                    .foregroundStyle(t.text)
                    .keyboardType(.default)
            }
            Divider().background(t.border).padding(.horizontal, Spacing.l)
            formRow(label: "Form") {
                Menu {
                    ForEach(forms, id: \.self) { f in
                        Button(f) { form = f }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(form).font(.custom(Typography.geist, size: 15)).foregroundStyle(t.text)
                        Image(systemName: "chevron.down").font(.system(size: 11)).foregroundStyle(t.textMuted)
                    }
                }
            }
            Divider().background(t.border).padding(.horizontal, Spacing.l)
            formRow(label: "Bestand") {
                TextField("Anzahl", text: $stock)
                    .font(.custom(Typography.geist, size: 15))
                    .foregroundStyle(t.text)
                    .keyboardType(.numberPad)
            }
        }
    }

    @ViewBuilder private func formRow<T: View>(label: String, @ViewBuilder content: () -> T) -> some View {
        HStack {
            Text(label)
                .font(.custom(Typography.geist, size: 14))
                .foregroundStyle(t.textMid)
                .frame(width: 72, alignment: .leading)
            content()
            Spacer()
        }
        .padding(.horizontal, Spacing.l).padding(.vertical, 14)
    }

    @ViewBuilder private var whenCard: some View {
        Card(pad: 0) {
            VStack(spacing: 0) {
                HStack {
                    Text("Häufigkeit")
                        .font(.custom(Typography.geist, size: 14).weight(.medium))
                        .foregroundStyle(t.text)
                    Spacer()
                }
                .padding(.horizontal, Spacing.l).padding(.vertical, 12)

                HStack(spacing: 6) {
                    ForEach(frequencies, id: \.self) { f in
                        Button {
                            withAnimation { frequency = f }
                        } label: {
                            Text(f)
                                .font(.custom(Typography.geist, size: 12).weight(frequency == f ? .semibold : .regular))
                                .foregroundStyle(frequency == f ? t.bg : t.textMid)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(frequency == f ? Capsule().fill(t.text) : nil)
                                .overlay(frequency == f ? nil : Capsule().stroke(t.border, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.l).padding(.bottom, 12)

                Divider().background(t.border)

                VStack(spacing: 0) {
                    ForEach(timeSlots.indices, id: \.self) { i in
                        HStack(spacing: 12) {
                            Button {
                                withAnimation(.spring(duration: 0.2)) {
                                    if selectedTimes.contains(i) { selectedTimes.remove(i) }
                                    else { selectedTimes.insert(i) }
                                }
                            } label: {
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(selectedTimes.contains(i) ? t.accent : t.surface2)
                                    .frame(width: 18, height: 18)
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(t.accentText)
                                            .opacity(selectedTimes.contains(i) ? 1 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                            Text(timeSlots[i])
                                .font(.custom(Typography.geistMono, size: 13))
                                .foregroundStyle(selectedTimes.contains(i) ? t.text : t.textMuted)
                            Spacer()
                        }
                        .padding(.horizontal, Spacing.l).padding(.vertical, 12)
                        .background(
                            selectedTimes.contains(i)
                            ? RoundedRectangle(cornerRadius: 0).fill(t.accent.opacity(0.06))
                            : nil
                        )
                        .overlay(alignment: .leading) {
                            if selectedTimes.contains(i) {
                                Rectangle().fill(t.accent).frame(width: 2)
                            }
                        }
                        if i < timeSlots.count - 1 {
                            Divider().background(t.border).padding(.horizontal, Spacing.l)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder private var optionsCard: some View {
        Card(pad: 0) {
            ForEach([
                ("Mit Essen", $withFood),
                ("Erinnerung senden", $reminderOn),
                ("Bestand nachverfolgen", $trackStock),
            ], id: \.0) { label, binding in
                HStack {
                    Text(label).font(.custom(Typography.geist, size: 14)).foregroundStyle(t.text)
                    Spacer()
                    Toggle("", isOn: binding)
                        .tint(t.accent)
                        .labelsHidden()
                }
                .padding(.horizontal, Spacing.l).padding(.vertical, 12)
                if label != "Bestand nachverfolgen" {
                    Divider().background(t.border).padding(.horizontal, Spacing.l)
                }
            }
        }
    }
}

#Preview {
    ThemedRoot { SupplementAddView() }
        .environment(AppDependencies.mock())
}
