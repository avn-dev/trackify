import SwiftUI

struct BodyFatView: View {
    @Environment(\.theme) private var t
    @Environment(AppDependencies.self) private var deps
    @Environment(\.dismiss) private var dismiss
    @State private var range = 0 // 0=6M 1=1J
    @State private var metrics: [BodyMetric] = []
    @State private var showEntry = false
    @AppStorage("bodyFatMethod") private var bodyFatMethod = "caliper"

    private let maxDisplay = 30.0
    private let methodOptions: [(name: String, key: String)] = [
        ("Caliper 4-Punkt", "caliper"),
        ("Bioimpedanz", "bia"),
        ("Bilder-Schätzung", "photo"),
    ]
    private var methodLabel: String {
        switch bodyFatMethod {
        case "bia":   return "Bioimpedanz"
        case "photo": return "Schätzung"
        default:      return "Caliper"
        }
    }

    private var currentValue: Double { metrics.first?.value ?? 0 }

    private var delta3m: Double {
        let cutoff = Calendar.current.date(byAdding: .month, value: -3, to: .now) ?? .distantPast
        let inRange = metrics.filter { $0.ts >= cutoff }
        guard let first = inRange.first, let last = inRange.last, first.id != last.id else { return 0 }
        return first.value - last.value
    }

    private var chartData: [LinePoint] {
        let months = range == 0 ? 6 : 12
        let cutoff = Calendar.current.date(byAdding: .month, value: -months, to: .now) ?? .distantPast
        return metrics.filter { $0.ts >= cutoff }.reversed().enumerated().map {
            LinePoint(x: Double($0.offset), y: $0.element.value)
        }
    }

    private var categoryLabel: String {
        guard currentValue > 0 else { return "" }
        switch currentValue {
        case ..<6:   return "Essenziell"
        case 6..<14: return "Athletisch"
        case 14..<18: return "Fit"
        case 18..<25: return "Durchschnitt"
        default:     return "Über Durchschnitt"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ScreenHeader(
                    title: currentValue > 0 ? "\(Formatters.compact(currentValue)) %" : "–",
                    eyebrow: "Körperfett · \(methodLabel)",
                    back: "Körper",
                    onBack: { dismiss() }
                ) {
                    CircleBtn(systemIcon: "plus") { showEntry = true }
                }

                ringCard.padding(.horizontal, Spacing.xl)

                trendCard
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, 12)

                SectionHead(label: "Methode").padding(.top, 18)

                VStack(spacing: 8) {
                    ForEach(methodOptions, id: \.key) { option in
                        Button {
                            withAnimation(.easeOut(duration: 0.15)) {
                                bodyFatMethod = option.key
                            }
                        } label: {
                            methodRow(name: option.name, isActive: bodyFatMethod == option.key)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.xl)

                SectionHead(label: "Einträge").padding(.top, 18)

                if metrics.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "chart.pie")
                            .font(.system(size: 36))
                            .foregroundStyle(t.textMuted)
                        Text("Noch keine Einträge")
                            .font(.custom(Typography.geist, size: 17).weight(.semibold))
                            .foregroundStyle(t.text)
                        Text("Tippe auf + um dein erstes\nKörperfett einzutragen.")
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
        .task { await loadData() }
        .sheet(isPresented: $showEntry) {
            MetricEntrySheet(type: .bodyFat) { value in
                Task { await saveMetric(value) }
            }
        }
    }

    private func loadData() async {
        metrics = (try? await deps.body.fetchMetrics(type: .bodyFat, limit: 365)) ?? []
    }

    private func deleteMetric(_ m: BodyMetric) async {
        try? await deps.body.delete(m)
        await loadData()
    }

    private func saveMetric(_ value: Double) async {
        let m = BodyMetric(userID: .localUser, ts: .now, type: .bodyFat, value: value, method: bodyFatMethod)
        try? await deps.body.save(m)
        await loadData()
    }

    @ViewBuilder private var ringCard: some View {
        Card(pad: Spacing.l) {
            HStack(spacing: 20) {
                BodyFatRing(value: currentValue > 0 ? currentValue : 0, maxValue: maxDisplay)
                    .frame(width: 96, height: 96)

                VStack(alignment: .leading, spacing: 6) {
                    Eyebrow(text: "Letzte Messung")
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(currentValue > 0 ? Formatters.compact(currentValue) : "–")
                            .font(Typography.number(32))
                            .kerning(-1)
                            .foregroundStyle(t.text)
                        Text("%")
                            .font(.custom(Typography.geistMono, size: 14))
                            .foregroundStyle(t.textMuted)
                    }
                    if delta3m != 0 {
                        HStack(spacing: 4) {
                            Text("\(delta3m < 0 ? "↓" : "↑") \(Formatters.compact(abs(delta3m)))%")
                                .font(.custom(Typography.geistMono, size: 12))
                                .foregroundStyle(delta3m < 0 ? t.accent : t.danger)
                            Text("/ 3 Mon.")
                                .font(.custom(Typography.geistMono, size: 12))
                                .foregroundStyle(t.textMuted)
                        }
                    }
                    if !categoryLabel.isEmpty {
                        Text(categoryLabel + " · 18–29J")
                            .font(.custom(Typography.geistMono, size: 11))
                            .foregroundStyle(t.textMuted)
                    }
                }
            }
        }
    }

    @ViewBuilder private var trendCard: some View {
        Card(pad: Spacing.l) {
            HStack {
                Eyebrow(text: "Verlauf")
                Spacer()
                HStack(spacing: 6) {
                    ForEach(["6M", "1J"], id: \.self) { r in
                        let idx = ["6M", "1J"].firstIndex(of: r) ?? 0
                        Button {
                            withAnimation { range = idx }
                        } label: {
                            Text(r)
                                .font(.custom(Typography.geist, size: 12).weight(range == idx ? .semibold : .regular))
                                .foregroundStyle(range == idx ? t.text : t.textMuted)
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .background(range == idx ? Capsule().fill(t.surface2) : nil)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            TrackifyLineChart(
                data: chartData.isEmpty
                    ? [LinePoint(x: 0, y: 15), LinePoint(x: 1, y: 15)]
                    : chartData,
                accent: false,
                showAxis: true
            )
            .frame(height: 140)
            .padding(.top, 12)
        }
    }

    @ViewBuilder private func entryRow(date: Date, value: Double, delta: Double) -> some View {
        HStack {
            Text(Formatters.shortDate(date))
                .font(.custom(Typography.geist, size: 14))
                .foregroundStyle(t.text)
            Spacer()
            HStack(spacing: 12) {
                if abs(delta) > 0.01 {
                    Text(delta < 0 ? "↓ \(Formatters.compact(abs(delta)))" : "↑ \(Formatters.compact(delta))")
                        .font(.custom(Typography.geistMono, size: 12))
                        .foregroundStyle(delta < 0 ? t.accent : t.danger)
                }
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(Formatters.compact(value))
                        .font(Typography.number(15))
                        .foregroundStyle(t.text)
                    Text("%")
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

    @ViewBuilder private func methodRow(name: String, isActive: Bool) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(isActive ? t.accent : t.surface2)
                .frame(width: 8, height: 8)
            Text(name)
                .font(.custom(Typography.geist, size: 15))
                .foregroundStyle(isActive ? t.text : t.textMid)
            Spacer()
        }
        .padding(.horizontal, Spacing.l).padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: Radii.row, style: .continuous)
                .fill(t.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radii.row, style: .continuous)
                .stroke(isActive ? t.accent : t.border, lineWidth: isActive ? 1.5 : 1)
        )
    }
}

// MARK: - Donut ring

struct BodyFatRing: View {
    @Environment(\.theme) private var t
    var value: Double
    var maxValue: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(t.surface2, lineWidth: 8)
            Circle()
                .trim(from: 0, to: CGFloat(value / maxValue))
                .stroke(t.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(value > 0 ? Formatters.compact(value) + "%" : "–")
                .font(Typography.number(16))
                .foregroundStyle(t.text)
        }
    }
}

#Preview {
    ThemedRoot {
        NavigationStack { BodyFatView() }
    }
    .environment(AppDependencies.mock())
}
