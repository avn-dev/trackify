import SwiftUI
import Charts

struct LabMarkerDetailView: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    @Environment(AppDependencies.self) private var deps

    var markerName: String = "Vitamin D"
    var category: String = "Vitamine · 25-OH"
    var value: Double = 38
    var unit: String = "ng/mL"
    var refLow: Double = 30
    var refHigh: Double = 70

    @State private var range = 0 // 0=1J 1=5J 2=Alles
    @State private var history: [LabHistoryEntry] = []

    private var absMin: Double { max(0, refLow > 0 ? refLow * 0.4 : 0) }
    private var absMax: Double { refHigh * 1.6 }

    private var filteredHistory: [LabHistoryEntry] {
        let now = Date()
        switch range {
        case 0:
            let cutoff = Calendar.current.date(byAdding: .year, value: -1, to: now)!
            return history.filter { $0.date >= cutoff }
        case 1:
            let cutoff = Calendar.current.date(byAdding: .year, value: -5, to: now)!
            return history.filter { $0.date >= cutoff }
        default:
            return history
        }
    }

    private var chartPoints: [LabChartPoint] {
        filteredHistory.reversed().map { LabChartPoint(date: $0.date, value: $0.value) }
    }

    private var delta3m: String {
        guard history.count >= 2 else { return "–" }
        let diff = history[0].value - history[1].value
        let sign = diff >= 0 ? "↑" : "↓"
        return "\(sign) \(Formatters.compact(abs(diff)))"
    }

    private var statusColor: Color {
        if value < refLow { return t.amber }
        if value > refHigh { return t.danger }
        return t.accent
    }

    private var statusLabel: String {
        if value < refLow { return "Zu niedrig" }
        if value > refHigh { return "Zu hoch" }
        return "Normal"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ScreenHeader(
                    title: markerName,
                    eyebrow: category,
                    back: "Labor",
                    onBack: { dismiss() }
                ) {
                    EmptyView()
                }

                valueCard.padding(.horizontal, Spacing.xl)

                trendCard
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, 12)

                tipCard
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, 12)

                SectionHead(label: "Einträge").padding(.top, 18)

                if history.isEmpty {
                    Text("Noch kein Verlauf")
                        .font(.custom(Typography.geistMono, size: 13))
                        .foregroundStyle(t.textMuted)
                        .padding(.top, 24)
                        .padding(.bottom, Spacing.screenSafeBottom)
                } else {
                    VStack(spacing: 8) {
                        ForEach(Array(history.enumerated()), id: \.element.id) { i, e in
                            let prevVal = i + 1 < history.count ? history[i + 1].value : e.value
                            let diff = e.value - prevVal
                            let deltaStr: String = {
                                guard i + 1 < history.count else { return "–" }
                                let sign = diff >= 0 ? "↑" : "↓"
                                return "\(sign) \(Formatters.compact(abs(diff)))"
                            }()
                            entryRow(
                                date: Formatters.shortDate(e.date),
                                value: "\(Formatters.compact(e.value)) \(e.unit)",
                                delta: deltaStr
                            )
                        }
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, Spacing.screenSafeBottom)
                }
            }
        }
        .background(t.bg.ignoresSafeArea())
        .navigationBarHidden(true)
        .task { await loadHistory() }
    }

    private func loadHistory() async {
        let measurements = (try? await deps.lab.fetchMeasurements(limit: 20)) ?? []
        history = measurements.compactMap { m in
            guard let v = m.values.first(where: { $0.marker == markerName }) else { return nil }
            return LabHistoryEntry(date: m.takenAt, value: v.value, unit: v.unit)
        }
    }

    @ViewBuilder private var valueCard: some View {
        Card(pad: Spacing.l) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(Formatters.compact(value))
                            .font(Typography.number(56))
                            .kerning(-2)
                            .foregroundStyle(t.text)
                        Text(unit)
                            .font(.custom(Typography.geistMono, size: 16))
                            .foregroundStyle(t.textMuted)
                    }
                    HStack(spacing: 6) {
                        Circle().fill(statusColor).frame(width: 6, height: 6)
                        Text(statusLabel)
                            .font(.custom(Typography.geistMono, size: 12).weight(.medium))
                    }
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Capsule().fill(statusColor.opacity(0.12)))
                    .foregroundStyle(statusColor)
                    if history.count >= 2 {
                        HStack(spacing: 4) {
                            Text(delta3m)
                            Text("/ letzte Messung")
                                .foregroundStyle(t.textMuted)
                        }
                        .font(.custom(Typography.geistMono, size: 12))
                        .foregroundStyle(t.accent)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Eyebrow(text: "Normbereich")
                    Text("\(Formatters.compact(refLow))–\(Formatters.compact(refHigh))")
                        .font(.custom(Typography.geistMono, size: 13))
                        .foregroundStyle(t.textMuted)
                }
            }

            RangeScale(
                value: value,
                refLow: refLow,
                refHigh: refHigh,
                absMin: absMin,
                absMax: absMax
            )
            .padding(.top, 16)
        }
    }

    @ViewBuilder private var trendCard: some View {
        Card(pad: Spacing.l) {
            HStack {
                Eyebrow(text: "Verlauf")
                Spacer()
                HStack(spacing: 6) {
                    ForEach(["1J", "5J", "Alles"].indices, id: \.self) { i in
                        Button {
                            withAnimation { range = i }
                        } label: {
                            Text(["1J", "5J", "Alles"][i])
                                .font(.custom(Typography.geist, size: 12).weight(range == i ? .semibold : .regular))
                                .foregroundStyle(range == i ? t.text : t.textMuted)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(range == i ? Capsule().fill(t.surface2) : nil)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Chart {
                // ─── Zone bands ───
                if refLow > 0 {
                    RectangleMark(yStart: .value("", absMin), yEnd: .value("", refLow))
                        .foregroundStyle(t.amber.opacity(0.07))
                }
                RectangleMark(yStart: .value("", max(absMin, refLow)), yEnd: .value("", refHigh))
                    .foregroundStyle(t.accent.opacity(0.08))
                RectangleMark(yStart: .value("", refHigh), yEnd: .value("", absMax))
                    .foregroundStyle(t.danger.opacity(0.07))

                // ─── Zone boundaries ───
                if refLow > 0 {
                    RuleMark(y: .value("", refLow))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        .foregroundStyle(t.amber.opacity(0.55))
                }
                RuleMark(y: .value("", refHigh))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .foregroundStyle(t.danger.opacity(0.5))

                // ─── Data line ───
                let display: [LabChartPoint] = chartPoints.isEmpty
                    ? [LabChartPoint(date: .now, value: value)]
                    : chartPoints
                ForEach(display) { p in
                    LineMark(x: .value("Datum", p.date), y: .value("Wert", p.value))
                        .foregroundStyle(t.text)
                        .lineStyle(StrokeStyle(lineWidth: 1.75))
                        .interpolationMethod(.monotone)
                    AreaMark(x: .value("Datum", p.date), y: .value("Wert", p.value))
                        .foregroundStyle(t.text.opacity(0.06))
                        .interpolationMethod(.monotone)
                }
            }
            .chartYScale(domain: absMin...absMax)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { v in
                    AxisGridLine().foregroundStyle(t.grid)
                    AxisValueLabel {
                        if let d = v.as(Date.self) {
                            Text(Formatters.shortDate(d))
                                .font(.custom(Typography.geistMono, size: 9))
                                .foregroundStyle(t.textMuted)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { v in
                    AxisGridLine().foregroundStyle(t.grid)
                    AxisValueLabel {
                        if let n = v.as(Double.self) {
                            Text(Formatters.compact(n))
                                .font(.custom(Typography.geistMono, size: 9))
                                .foregroundStyle(t.textMuted)
                        }
                    }
                }
            }
            .frame(height: 180)
            .padding(.top, 12)
        }
    }

    private var tipText: String {
        let key = markerName.lowercased()
        let tips: [String: String] = [
            "vitamin d":     "Vitamin D wird hauptsächlich durch Sonnenlicht gebildet. In Mitteleuropa ist eine Supplementierung von Oktober bis April empfehlenswert.",
            "vitamin b12":   "Vitamin B12 kommt ausschließlich in tierischen Produkten vor. Bei veganer Ernährung ist eine regelmäßige Supplementierung notwendig.",
            "folsäure":      "Folsäure unterstützt die Zellteilung und ist besonders in der Schwangerschaft essenziell. Dunkelgrünes Gemüse ist eine gute natürliche Quelle.",
            "ferritin":      "Ferritin ist der Eisenspeicher des Körpers. Niedrige Werte können Müdigkeit und Konzentrationsschwäche verursachen, auch ohne Anämie.",
            "tsh":           "TSH reguliert die Schilddrüsenaktivität. Erhöhte Werte können auf eine Unterfunktion hinweisen – oft mit Müdigkeit und Gewichtszunahme verbunden.",
            "hämoglobin":    "Hämoglobin transportiert Sauerstoff im Blut. Niedrige Werte (Anämie) führen zu Erschöpfung und verminderter Leistungsfähigkeit.",
            "glukose":       "Der Nüchternblutzucker sollte unter 100 mg/dL liegen. Werte über 126 mg/dL (nüchtern) deuten auf Diabetes hin.",
            "cholesterin":   "Gesamtcholesterin über 200 mg/dL erfordert eine genauere Analyse von LDL und HDL – das Verhältnis ist entscheidender als der Gesamtwert.",
            "ldl":           "LDL-Cholesterin ('schlechtes' Cholesterin) lagert sich in Gefäßwänden ab. Bewegung, Ballaststoffe und weniger gesättigte Fette helfen, es zu senken.",
            "hdl":           "HDL-Cholesterin ('gutes' Cholesterin) transportiert Cholesterin zur Leber. Regelmäßige Ausdauerbelastung erhöht den HDL-Spiegel nachhaltig.",
            "triglyzeride":  "Erhöhte Triglyzeride entstehen oft durch zu viel Zucker und Alkohol. Nüchternheit vor der Blutabnahme (12h) ist für korrekte Werte wichtig.",
            "magnesium":     "Magnesium ist an über 300 Enzymreaktionen beteiligt. Sportler haben oft erhöhten Bedarf – Muskelkrämpfe sind ein häufiges Zeichen eines Mangels.",
            "calcium":       "Calcium ist nicht nur für Knochen wichtig, sondern auch für Muskelkontraktion und Nervenfunktion. Vitamin D verbessert die Aufnahme erheblich.",
            "zink":          "Zink stärkt das Immunsystem und ist an der Wundheilung beteiligt. Pflanzliche Quellen (Hülsenfrüchte) haben durch Phytate eine geringere Bioverfügbarkeit.",
            "kreatinin":     "Kreatinin ist ein Abbauprodukt des Muskelstoffwechsels. Erhöhte Werte können auf eingeschränkte Nierenfunktion hinweisen.",
            "crp":           "CRP (C-reaktives Protein) ist ein Entzündungsmarker. Erhöhte Werte zeigen eine akute Entzündung oder Infektion – nicht krankheitsspezifisch.",
            "harnsäure":     "Harnsäure entsteht beim Abbau von Purinen. Erhöhte Werte können Gicht auslösen. Weniger rotes Fleisch, Alkohol und Fruchtzucker helfen.",
            "testosteron":   "Testosteron beeinflusst Muskelmasse, Energie und Libido. Schlafmangel und hoher Stress können den Spiegel signifikant senken.",
            "cortisol":      "Cortisol ist das primäre Stresshormon. Chronisch erhöhte Werte durch dauerhaften Stress hemmen Regeneration und Immunsystem.",
            "vitamin c":     "Vitamin C ist ein starkes Antioxidans und unterstützt die Kollagensynthese. Frische Früchte und Gemüse decken den Tagesbedarf meist gut ab.",
            "hba1c":         "HbA1c spiegelt den durchschnittlichen Blutzucker der letzten 2–3 Monate wider. Werte unter 5,7 % gelten als normal.",
        ]
        for (k, v) in tips where key.contains(k) { return v }
        return "Besprich auffällige Werte mit deinem Arzt. Einzelmessungen sollten immer im Kontext des Gesamtbildes bewertet werden."
    }

    @ViewBuilder private var tipCard: some View {
        Card(pad: Spacing.l) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(t.accent)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(t.accent.opacity(0.12)))
                Text(tipText)
                    .font(Typography.bodySmall)
                    .foregroundStyle(t.textMid)
                    .lineSpacing(3)
            }
        }
    }

    @ViewBuilder private func entryRow(date: String, value: String, delta: String) -> some View {
        HStack {
            Text(date)
                .font(.custom(Typography.geist, size: 14))
                .foregroundStyle(t.text)
            Spacer()
            Text(delta)
                .font(.custom(Typography.geistMono, size: 12))
                .foregroundStyle(delta.hasPrefix("↑") ? t.accent :
                                 delta.hasPrefix("↓") ? t.danger : t.textMuted)
            Text(value)
                .font(Typography.number(14))
                .foregroundStyle(t.text)
        }
        .padding(.horizontal, Spacing.l).padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: Radii.row, style: .continuous).fill(t.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radii.row, style: .continuous).stroke(t.border, lineWidth: 1)
        )
    }
}

struct LabHistoryEntry: Identifiable {
    let id = UUID()
    var date: Date
    var value: Double
    var unit: String
}

struct LabChartPoint: Identifiable {
    let id = UUID()
    var date: Date
    var value: Double
}

#Preview {
    ThemedRoot { LabMarkerDetailView() }
        .environment(AppDependencies.mock())
}
