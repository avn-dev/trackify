import SwiftUI

struct SupplementDetailView: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    @Environment(AppDependencies.self) private var deps

    var supplement: SupItem = SupItem(name: "Vitamin D3 + K2", dose: "4000 IE / 200 µg", kind: .supplement, taken: true, withFood: true)

    @State private var intakes: [SupplementIntake] = []
    @State private var fullSupplement: Supplement?
    @State private var showEdit = false
    @State private var showDeleteConfirm = false

    private var eyebrow: String {
        let kindLabel: String
        switch supplement.kind {
        case .medication: kindLabel = "Medikament"
        case .herbal:     kindLabel = "Pflanzlich"
        default:          kindLabel = "Supplement"
        }
        let freqLabel = fullSupplement?.frequency == "daily" ? "täglich" : (fullSupplement?.frequency ?? "täglich")
        return "\(kindLabel) · \(freqLabel)"
    }

    private var calendarData: [CalCell] {
        let cal = Calendar.current
        let trackingStart: Date = intakes.map(\.plannedAt).min().map {
            cal.startOfDay(for: $0)
        } ?? cal.startOfDay(for: .now)
        return (0..<30).map { i in
            let day = cal.startOfDay(for: .now - Double(i) * 86400)
            guard day >= trackingStart else {
                return CalCell(day: i + 1, status: .noData)
            }
            let intake = intakes.first { cal.isDate($0.plannedAt, inSameDayAs: day) }
            let status: CalStatus
            if i == 0 && intake == nil {
                status = .planned
            } else if let intake {
                status = intake.takenAt != nil ? .taken : .missed
            } else {
                status = .planned
            }
            return CalCell(day: i + 1, status: status)
        }.reversed()
    }

    private var takenCount: Int { intakes.filter { $0.takenAt != nil }.count }
    private var adherencePct: Int { intakes.isEmpty ? 0 : Int(Double(takenCount) / Double(intakes.count) * 100) }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ScreenHeader(
                    title: supplement.name,
                    eyebrow: eyebrow,
                    back: "Supplements",
                    onBack: { dismiss() }
                ) {
                    Menu {
                        Button("Bearbeiten") { showEdit = true }
                        Divider()
                        Button("Löschen", role: .destructive) { showDeleteConfirm = true }
                    } label: {
                        CircleBtn(systemIcon: "ellipsis") {}
                    }
                }

                statsRow.padding(.horizontal, Spacing.xl)

                calendarCard
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, 12)

                SectionHead(label: "Plan").padding(.top, 18)
                planSection.padding(.horizontal, Spacing.xl)

                SectionHead(label: "Letzte Einnahmen").padding(.top, 18)
                intakeHistory.padding(.horizontal, Spacing.xl)

                Spacer().frame(height: Spacing.screenSafeBottom)
            }
        }
        .background(t.bg.ignoresSafeArea())
        .navigationBarHidden(true)
        .task { await loadIntakes() }
        .sheet(isPresented: $showEdit, onDismiss: { Task { await loadIntakes() } }) {
            if let s = fullSupplement {
                SupplementAddView(editingSupplement: s)
            }
        }
        .confirmationDialog("Supplement löschen?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("\(supplement.name) löschen", role: .destructive) {
                Task { await deleteSupplement() }
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Diese Aktion kann nicht rückgängig gemacht werden.")
        }
    }

    private func deleteSupplement() async {
        guard let s = fullSupplement else { return }
        try? await deps.supplements.delete(s)
        NotificationScheduler.shared.cancelSupplements(ids: [s.id])
        dismiss()
    }

    private func loadIntakes() async {
        intakes = (try? await deps.supplements.fetchIntakes(supplementID: supplement.supplementID, limit: 30)) ?? []
        fullSupplement = try? await deps.supplements.fetchSupplement(id: supplement.supplementID)
    }

    @ViewBuilder private var statsRow: some View {
        HStack(spacing: 10) {
            Card(pad: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow(text: "Adhärenz · 30T")
                    Text("\(adherencePct)%").font(Typography.number(28)).kerning(-1).foregroundStyle(t.text)
                    Text("\(takenCount) / \(intakes.isEmpty ? 30 : intakes.count) Tage")
                        .font(.custom(Typography.geistMono, size: 11)).foregroundStyle(t.accent)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Card(pad: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow(text: "Bestand")
                    let stock = fullSupplement?.stockUnits ?? 0
                    Text(stock > 0 ? "\(stock)" : "–")
                        .font(Typography.number(28)).kerning(-1).foregroundStyle(t.text)
                    Text(stock > 0 ? "≈ \(stock) Tage" : "Nicht erfasst")
                        .font(.custom(Typography.geistMono, size: 11)).foregroundStyle(t.textMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder private var calendarCard: some View {
        Card(pad: Spacing.l) {
            Eyebrow(text: "30 Tage Kalender")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 15), spacing: 4) {
                ForEach(calendarData) { cell in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(cell.status == .taken   ? t.accent :
                              cell.status == .missed  ? t.danger :
                              cell.status == .noData  ? t.surface2 :
                              Color.clear)
                        .frame(height: 18)
                        .overlay(
                            cell.status == .planned
                            ? RoundedRectangle(cornerRadius: 3).stroke(t.borderStrong, style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                            : nil
                        )
                }
            }
            .padding(.top, 12)

            HStack(spacing: 14) {
                ForEach([
                    (t.accent, "Eingenommen"),
                    (t.danger, "Verpasst"),
                    (t.borderStrong, "Geplant"),
                ], id: \.1) { color, label in
                    HStack(spacing: 5) {
                        RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 10, height: 10)
                        Text(label).font(.custom(Typography.geistMono, size: 10)).foregroundStyle(t.textMuted)
                    }
                }
            }
            .padding(.top, 10)
        }
    }

    @ViewBuilder private var planSection: some View {
        let s = fullSupplement
        let planRows: [(String, String)] = [
            ("Dosis",       s?.dose ?? supplement.dose),
            ("Häufigkeit",  s?.frequency == "daily" ? "Täglich" : (s?.frequency ?? "Täglich")),
            ("Einnahme",    s?.times.sorted().joined(separator: ", ") ?? "–"),
            ("Form",        s?.form ?? "Kapsel"),
            ("Erinnerung",  (s?.reminderOn ?? true) ? "An" : "Aus"),
        ]
        Card(pad: 0) {
            ForEach(planRows.indices, id: \.self) { i in
                let (key, value) = planRows[i]
                HStack {
                    Text(key).font(.custom(Typography.geist, size: 14)).foregroundStyle(t.textMid)
                    Spacer()
                    Text(value).font(.custom(Typography.geistMono, size: 13)).foregroundStyle(t.text)
                }
                .padding(.horizontal, Spacing.l).padding(.vertical, 12)
                if i < planRows.count - 1 {
                    Divider().background(t.border).padding(.horizontal, Spacing.l)
                }
            }
        }
    }

    @ViewBuilder private var intakeHistory: some View {
        let df = DateFormatter()
        let _ = (df.locale = Locale(identifier: "de_DE"))
        let _ = (df.dateFormat = "d. MMM")
        let recentIntakes = Array(intakes.prefix(10))

        if recentIntakes.isEmpty {
            Text("Noch keine Einnahmen erfasst")
                .font(.custom(Typography.geistMono, size: 13))
                .foregroundStyle(t.textMuted)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 24)
        } else {
            VStack(spacing: 8) {
                ForEach(recentIntakes) { intake in
                    let taken = intake.takenAt != nil
                    let dateLabel: String = {
                        if Calendar.current.isDateInToday(intake.plannedAt) { return "Heute" }
                        if Calendar.current.isDateInYesterday(intake.plannedAt) { return "Gestern" }
                        return df.string(from: intake.plannedAt)
                    }()
                    HStack {
                        Text(dateLabel).font(.custom(Typography.geist, size: 14)).foregroundStyle(t.text)
                        Spacer()
                        if taken {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark").font(.system(size: 11, weight: .bold))
                                Text("Eingenommen")
                                    .font(.custom(Typography.geistMono, size: 11))
                            }
                            .foregroundStyle(t.accent)
                        } else {
                            Text("verpasst")
                                .font(.custom(Typography.geistMono, size: 11).weight(.medium))
                                .foregroundStyle(t.danger)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Capsule().fill(t.danger.opacity(0.12)))
                        }
                    }
                    .padding(.horizontal, Spacing.l).padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: Radii.row, style: .continuous).fill(t.surface))
                    .overlay(RoundedRectangle(cornerRadius: Radii.row, style: .continuous).stroke(t.border, lineWidth: 1))
                }
            }
        }
    }
}

struct CalCell: Identifiable {
    let id = UUID()
    var day: Int
    var status: CalStatus
}

enum CalStatus { case taken, missed, planned, noData }

#Preview {
    ThemedRoot { SupplementDetailView() }
        .environment(AppDependencies.mock())
}
