import SwiftUI

struct WeightView: View {
    @Environment(\.theme) private var t
    @Environment(AppDependencies.self) private var deps
    @Environment(\.dismiss) private var dismiss
    @State private var range = 2
    @State private var metrics: [BodyMetric] = []
    @State private var showEntry = false
    @State private var isImportingHK = false

    @AppStorage("goalWeightKg")  private var goalKg      = 70.0
    @AppStorage("goalHeightCm")  private var heightCm    = 178.0
    @AppStorage("unitsKg")       private var unitsKg     = true
    @AppStorage("hkWeightSync")  private var hkWeightSync = false
    private let ranges = ["1W", "1M", "3M", "1J", "Alles"]

    private var filtered: [BodyMetric] {
        let days = [7, 30, 90, 365, Int.max][range]
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .distantPast
        return metrics.filter { $0.ts >= cutoff }
    }

    private var currentKg: Double { metrics.first?.value ?? 0 }

    private var chartData: [LinePoint] {
        let pts = filtered.reversed().enumerated().map {
            LinePoint(x: Double($0.offset), y: $0.element.value)
        }
        return pts
    }

    private var sevenDayAvg: Double {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .distantPast
        let recent = metrics.filter { $0.ts >= cutoff }
        guard !recent.isEmpty else { return currentKg }
        return recent.reduce(0) { $0 + $1.value } / Double(recent.count)
    }

    private var trendDelta: Double {
        guard let first = filtered.first, let last = filtered.last, first.id != last.id else { return 0 }
        return first.value - last.value
    }

    private var bmi: Double {
        let h = heightCm > 0 ? heightCm / 100.0 : 1.78
        return currentKg > 0 ? currentKg / (h * h) : 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ScreenHeader(
                    title: currentKg > 0 ? "\(Formatters.weightValue(currentKg, useKg: unitsKg)) \(Formatters.weightUnit(unitsKg))" : "–",
                    eyebrow: "Körpergewicht",
                    back: "Körper",
                    onBack: { dismiss() }
                ) {
                    CircleBtn(systemIcon: "plus") { showEntry = true }
                }

                rangePicker.padding(.horizontal, Spacing.xl).padding(.bottom, 16)
                trendCard.padding(.horizontal, Spacing.xl)
                statsRow.padding(.horizontal, Spacing.xl).padding(.top, 12)
                SectionHead(
                    label: "Einträge",
                    action: hkWeightSync ? (isImportingHK ? "…" : "Von Health") : "",
                    onAction: hkWeightSync ? { Task { await importFromHealthKit() } } : nil
                ).padding(.top, 18)

                if metrics.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "scalemass")
                            .font(.system(size: 36))
                            .foregroundStyle(t.textMuted)
                        Text("Noch keine Einträge")
                            .font(.custom(Typography.geist, size: 17).weight(.semibold))
                            .foregroundStyle(t.text)
                        Text("Tippe auf + um dein erstes\nGewicht einzutragen.")
                            .font(.custom(Typography.geist, size: 14))
                            .foregroundStyle(t.textMuted)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, Spacing.screenSafeBottom)
                } else {
                    VStack(spacing: 8) {
                        ForEach(Array(metrics.prefix(10).enumerated()), id: \.element.id) { idx, m in
                            let prev = metrics.count > idx + 1 ? metrics[idx + 1].value : m.value
                            entryRow(date: m.ts, value: m.value, delta: m.value - prev)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        Task { await deleteMetric(m) }
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
        }
        .background(t.bg.ignoresSafeArea())
        .navigationBarHidden(true)
        .task { await loadMetrics() }
        .sheet(isPresented: $showEntry) {
            MetricEntrySheet(type: .weight, onSave: { value in
                Task { await saveMetric(value) }
            })
        }
    }

    private func deleteMetric(_ m: BodyMetric) async {
        try? await deps.body.delete(m)
        await loadMetrics()
    }

    private func saveMetric(_ value: Double) async {
        let now = Date()
        let m = BodyMetric(userID: .localUser, ts: now, type: .weight, value: value)
        try? await deps.body.save(m)
        if hkWeightSync && HealthKitService.isAvailable {
            await HealthKitService.shared.saveWeight(value, date: now)
        }
        await loadMetrics()
    }

    private func loadMetrics() async {
        metrics = (try? await deps.body.fetchMetrics(type: .weight, limit: 365)) ?? []
        if hkWeightSync && !isImportingHK {
            await importFromHealthKit()
        }
    }

    private func importFromHealthKit() async {
        guard HealthKitService.isAvailable && !isImportingHK else { return }
        isImportingHK = true
        defer { isImportingHK = false }

        let since = Calendar.current.date(byAdding: .year, value: -1, to: .now) ?? .distantPast
        let hkEntries = await HealthKitService.shared.weightHistory(since: since)
        guard !hkEntries.isEmpty else { return }

        let existingDates = Set(metrics.map { Calendar.current.startOfDay(for: $0.ts) })
        var didAdd = false
        for (kg, date) in hkEntries {
            let day = Calendar.current.startOfDay(for: date)
            guard !existingDates.contains(day) else { continue }
            let m = BodyMetric(userID: .localUser, ts: date, type: .weight, value: kg)
            try? await deps.body.save(m)
            didAdd = true
        }
        if didAdd {
            metrics = (try? await deps.body.fetchMetrics(type: .weight, limit: 365)) ?? []
        }
    }

    @ViewBuilder private var rangePicker: some View {
        HStack(spacing: 0) {
            ForEach(ranges.indices, id: \.self) { i in
                Button {
                    withAnimation(.easeOut(duration: 0.18)) { range = i }
                } label: {
                    Text(ranges[i])
                        .font(.custom(Typography.geist, size: 13).weight(range == i ? .semibold : .regular))
                        .foregroundStyle(range == i ? t.bg : t.textMid)
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(range == i ? Capsule().fill(t.text) : nil)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: Radii.pill, style: .continuous).fill(t.surface2))
    }

    @ViewBuilder private var trendCard: some View {
        Card(pad: Spacing.l) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow(text: "\(ranges[range]) · Trend")
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        let sign = trendDelta <= 0 ? "−" : "+"
                        Text("\(sign)\(Formatters.weightValue(abs(trendDelta), useKg: unitsKg))")
                            .font(Typography.number(24))
                            .foregroundStyle(trendDelta <= 0 ? t.accent : t.danger)
                        Text(Formatters.weightUnit(unitsKg))
                            .font(.custom(Typography.geistMono, size: 12))
                            .foregroundStyle(t.textMuted)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Eyebrow(text: "Ziel")
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(Formatters.weightValue(goalKg, useKg: unitsKg))
                            .font(Typography.number(18))
                            .foregroundStyle(t.accent)
                        Text(Formatters.weightUnit(unitsKg))
                            .font(.custom(Typography.geistMono, size: 12))
                            .foregroundStyle(t.textMuted)
                    }
                }
            }
            TrackifyLineChart(
                data: chartData.isEmpty
                    ? [LinePoint(x: 0, y: goalKg), LinePoint(x: 1, y: goalKg)]
                    : chartData,
                accent: false,
                baseline: goalKg,
                showAxis: true
            )
            .frame(height: 160)
            .padding(.top, 12)
        }
    }

    @ViewBuilder private var statsRow: some View {
        HStack(spacing: 10) {
            Card(pad: 12) {
                Stat(label: "Aktuell",
                     value: currentKg > 0 ? Formatters.weightValue(currentKg, useKg: unitsKg) : "–",
                     unit: Formatters.weightUnit(unitsKg))
            }
            Card(pad: 12) {
                Stat(label: "7T Ø",
                     value: sevenDayAvg > 0 ? Formatters.weightValue(sevenDayAvg, useKg: unitsKg) : "–",
                     unit: Formatters.weightUnit(unitsKg))
            }
            Card(pad: 12) {
                Stat(label: "BMI",
                     value: bmi > 0 ? Formatters.compact(bmi) : "–")
            }
        }
    }

    @ViewBuilder private func entryRow(date: Date, value: Double, delta: Double) -> some View {
        HStack {
            Text(Formatters.shortDate(date))
                .font(.custom(Typography.geist, size: 14))
                .foregroundStyle(t.text)
            Spacer()
            HStack(spacing: 12) {
                if delta != 0 {
                    let absDelta = Formatters.weightValue(abs(delta), useKg: unitsKg)
                    Text(delta < 0 ? "↓ \(absDelta)" : "↑ \(absDelta)")
                        .font(.custom(Typography.geistMono, size: 12))
                        .foregroundStyle(delta < 0 ? t.accent : t.danger)
                }
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(Formatters.weightValue(value, useKg: unitsKg))
                        .font(Typography.number(15))
                        .foregroundStyle(t.text)
                    Text(Formatters.weightUnit(unitsKg))
                        .font(.custom(Typography.geistMono, size: 11))
                        .foregroundStyle(t.textMuted)
                }
            }
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: Radii.row, style: .continuous).fill(t.surface))
        .overlay(RoundedRectangle(cornerRadius: Radii.row, style: .continuous).stroke(t.border, lineWidth: 1))
    }
}

#Preview {
    ThemedRoot { WeightView() }
        .environment(AppDependencies.mock())
}
