import SwiftUI

struct LabOverviewView: View {
    @Environment(\.theme) private var t
    @Environment(AppDependencies.self) private var deps
    @Environment(\.dismiss) private var dismiss
    @State private var showAdd = false
    @State private var showReport = false
    @State private var measurement: LabMeasurement?
    @State private var previousMeasurement: LabMeasurement?

    private var categories: [(name: String, markers: [LabMarker])] {
        guard let m = measurement else { return [] }
        var order: [String] = []
        var dict: [String: [LabMarker]] = [:]
        let prevValues: [String: Double] = previousMeasurement.map { pm in
            Dictionary(uniqueKeysWithValues: pm.values.map { ($0.marker, $0.value) })
        } ?? [:]
        for v in m.values {
            if !order.contains(v.category) { order.append(v.category) }
            let range: String = v.refLow <= 0
                ? "< \(Formatters.compact(v.refHigh))"
                : "\(Formatters.compact(v.refLow))–\(Formatters.compact(v.refHigh))"
            let trend: TrendDir = {
                guard let prev = prevValues[v.marker] else { return .flat }
                if v.value > prev + 0.01 { return .up }
                if v.value < prev - 0.01 { return .down }
                return .flat
            }()
            let marker = LabMarker(
                name: v.marker,
                status: v.status,
                range: range,
                value: "\(Formatters.compact(v.value)) \(v.unit)",
                trend: trend,
                rawValue: v.value,
                unit: v.unit,
                refLow: v.refLow,
                refHigh: v.refHigh,
                category: v.category
            )
            dict[v.category, default: []].append(marker)
        }
        return order.compactMap { cat in dict[cat].map { (cat, $0) } }
    }

    private var normalCount: Int { categories.flatMap(\.markers).filter { $0.status == .normal }.count }
    private var highCount: Int   { categories.flatMap(\.markers).filter { $0.status == .high }.count }
    private var lowCount: Int    { categories.flatMap(\.markers).filter { $0.status == .low }.count }
    private var total: Int       { categories.flatMap(\.markers).count }

    private var headerEyebrow: String {
        measurement.map { "Labor · \(Formatters.shortDate($0.takenAt))" } ?? "Labor"
    }
    private var summaryEyebrow: String {
        measurement.map { "\($0.source) · \(Formatters.shortDate($0.takenAt))" } ?? "Keine Messung"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ScreenHeader(title: "Blutwerte", eyebrow: headerEyebrow,
                             back: "Körper", onBack: { dismiss() }) {
                    CircleBtn(systemIcon: "plus") { showAdd = true }
                }

                if measurement == nil {
                    labEmptyState
                } else {
                    summaryCard.padding(.horizontal, Spacing.xl)

                    ForEach(categories, id: \.name) { cat in
                        categorySection(cat)
                    }
                }

                addTile.padding(.horizontal, Spacing.xl).padding(.top, 8)
                Spacer().frame(height: Spacing.screenSafeBottom)
            }
        }
        .background(t.bg.ignoresSafeArea())
        .navigationBarHidden(true)
        .navigationDestination(for: LabMarker.self) { marker in
            LabMarkerDetailView(
                markerName: marker.name,
                category: "\(marker.category) · \(marker.name)",
                value: marker.rawValue,
                unit: marker.unit,
                refLow: marker.refLow,
                refHigh: marker.refHigh
            )
        }
        .sheet(isPresented: $showAdd) {
            ThemedRoot { LabAddView() }
                .environment(deps)
        }
        .sheet(isPresented: $showReport) {
            if let m = measurement {
                ThemedRoot { LabReportSheet(measurement: m, categories: categories) }
            }
        }
        .task { await loadMeasurement() }
        .onChange(of: showAdd) { _, isShowing in
            if !isShowing { Task { await loadMeasurement() } }
        }
    }

    @ViewBuilder private var labEmptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "drop")
                .font(.system(size: 36))
                .foregroundStyle(t.textMuted)
            Text("Noch keine Blutwerte")
                .font(.custom(Typography.geist, size: 17).weight(.semibold))
                .foregroundStyle(t.text)
            Text("Tippe auf + um deine erste\nLabormessung einzutragen.")
                .font(.custom(Typography.geist, size: 14))
                .foregroundStyle(t.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
        .padding(.horizontal, Spacing.xl)
    }

    private func loadMeasurement() async {
        let recent = (try? await deps.lab.fetchMeasurements(limit: 2)) ?? []
        measurement = recent.first
        previousMeasurement = recent.count > 1 ? recent[1] : nil
    }

    @ViewBuilder private var summaryCard: some View {
        Card(pad: Spacing.l) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow(text: summaryEyebrow)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(normalCount)")
                            .font(Typography.number(40))
                            .kerning(-1.4)
                            .foregroundStyle(t.text)
                        Text("/ \(total)")
                            .font(.custom(Typography.geistMono, size: 18))
                            .foregroundStyle(t.textMuted)
                    }
                    Text("Marker im Normbereich")
                        .font(Typography.bodySmall)
                        .foregroundStyle(t.textMuted)
                }
                Spacer()
                VStack(spacing: 4) {
                    statusPip(count: normalCount, color: t.accent)
                    statusPip(count: highCount, color: t.danger)
                    statusPip(count: lowCount, color: t.amber)
                }
            }

            GeometryReader { geo in
                HStack(spacing: 2) {
                    let w = geo.size.width
                    RoundedRectangle(cornerRadius: 3).fill(t.accent)
                        .frame(width: w * CGFloat(normalCount) / CGFloat(total), height: 8)
                    RoundedRectangle(cornerRadius: 3).fill(t.danger)
                        .frame(width: w * CGFloat(highCount) / CGFloat(total), height: 8)
                    RoundedRectangle(cornerRadius: 3).fill(t.amber)
                        .frame(width: w * CGFloat(lowCount) / CGFloat(total), height: 8)
                }
            }
            .frame(height: 8)
            .padding(.top, 12)

            GhostButton(title: "Bericht ansehen") { showReport = true }
                .frame(height: 40)
                .padding(.top, 12)
        }
    }

    @ViewBuilder private func statusPip(count: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text("\(count)")
                .font(.custom(Typography.geistMono, size: 11))
                .foregroundStyle(t.textMuted)
        }
    }

    @ViewBuilder private func categorySection(_ cat: (name: String, markers: [LabMarker])) -> some View {
        VStack(spacing: 0) {
            SectionHead(label: cat.name).padding(.top, 18)
            Card(pad: 0) {
                VStack(spacing: 0) {
                    ForEach(cat.markers, id: \.name) { marker in
                        NavigationLink(value: marker) {
                            LabMarkerRow(marker: marker, isLast: marker.name == cat.markers.last?.name)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, Spacing.xl)
        }
    }

    @ViewBuilder private var addTile: some View {
        Button { showAdd = true } label: {
            HStack(spacing: 14) {
                Image(systemName: "plus")
                    .font(.system(size: 18))
                    .foregroundStyle(t.text)
                    .frame(width: 36, height: 36)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(t.surface))
                Text("Neue Messung")
                    .font(.custom(Typography.geist, size: 15).weight(.semibold))
                    .foregroundStyle(t.text)
                Spacer()
            }
            .padding(16)
            .overlay(
                RoundedRectangle(cornerRadius: Radii.card, style: .continuous)
                    .stroke(t.borderStrong, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Marker row

struct LabMarkerRow: View {
    @Environment(\.theme) private var t
    var marker: LabMarker
    var isLast: Bool

    private var statusColor: Color {
        switch marker.status {
        case .normal: t.accent
        case .high:   t.danger
        case .low:    t.amber
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Circle().fill(statusColor).frame(width: 8, height: 8)
                Text(marker.name)
                    .font(.custom(Typography.geist, size: 14))
                    .foregroundStyle(t.text)
                Spacer()
                Text(marker.status.label)
                    .font(.custom(Typography.geistMono, size: 11))
                    .foregroundStyle(statusColor)
                Text(marker.range)
                    .font(.custom(Typography.geistMono, size: 11))
                    .foregroundStyle(t.textMuted)
                Text(marker.value)
                    .font(Typography.number(13))
                    .foregroundStyle(t.text)
                trendArrow
            }
            .padding(.horizontal, Spacing.l).padding(.vertical, 14)

            if !isLast {
                Divider().background(t.border).padding(.horizontal, Spacing.l)
            }
        }
    }

    @ViewBuilder private var trendArrow: some View {
        Image(systemName: marker.trend == .up ? "arrow.up" : marker.trend == .down ? "arrow.down" : "minus")
            .font(.system(size: 10))
            .foregroundStyle(marker.trend == .flat ? t.textMuted : marker.trend == .up ? t.accent : t.danger)
    }
}

// MARK: - Models

struct LabMarker: Hashable {
    var name: String
    var status: LabStatus
    var range: String
    var value: String
    var trend: TrendDir
    // Raw data for detail navigation
    var rawValue: Double = 0
    var unit: String = ""
    var refLow: Double = 0
    var refHigh: Double = 0
    var category: String = ""
}

enum TrendDir: Hashable { case up, down, flat }

// MARK: - Report sheet

struct LabReportSheet: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    var measurement: LabMeasurement
    var categories: [(name: String, markers: [LabMarker])]

    private var normalCount: Int { categories.flatMap(\.markers).filter { $0.status == .normal }.count }
    private var highCount:   Int { categories.flatMap(\.markers).filter { $0.status == .high }.count }
    private var lowCount:    Int { categories.flatMap(\.markers).filter { $0.status == .low }.count }
    private var total:       Int { categories.flatMap(\.markers).count }

    private var reportText: String {
        var lines: [String] = [
            "Laborbericht – \(Formatters.shortDate(measurement.takenAt))",
            "Quelle: \(measurement.source)",
            "",
            "Ergebnis: \(normalCount)/\(total) Marker im Normbereich",
            ""
        ]
        for cat in categories {
            lines.append("── \(cat.name) ──")
            for m in cat.markers {
                let statusIcon = m.status == .normal ? "✓" : m.status == .high ? "↑" : "↓"
                lines.append("  \(statusIcon) \(m.name): \(m.value)  (Norm: \(m.range))")
            }
            lines.append("")
        }
        lines.append("Erstellt mit Trackify")
        return lines.joined(separator: "\n")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Summary card
                    Card(pad: Spacing.l) {
                        VStack(alignment: .leading, spacing: 8) {
                            Eyebrow(text: "\(measurement.source) · \(Formatters.shortDate(measurement.takenAt))")
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(normalCount)")
                                    .font(Typography.number(40))
                                    .kerning(-1.4)
                                    .foregroundStyle(t.text)
                                Text("/ \(total)")
                                    .font(.custom(Typography.geistMono, size: 18))
                                    .foregroundStyle(t.textMuted)
                            }
                            Text("Marker im Normbereich")
                                .font(Typography.bodySmall)
                                .foregroundStyle(t.textMuted)

                            HStack(spacing: 12) {
                                statusBadge(label: "Normal", count: normalCount, color: t.accent)
                                statusBadge(label: "Zu hoch", count: highCount, color: t.danger)
                                statusBadge(label: "Zu niedrig", count: lowCount, color: t.amber)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, Spacing.l)

                    // Category sections
                    ForEach(categories, id: \.name) { cat in
                        reportCategorySection(cat)
                    }

                    Spacer().frame(height: Spacing.screenSafeBottom)
                }
            }
            .background(t.bg.ignoresSafeArea())
            .navigationTitle("Laborbericht")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Schließen") { dismiss() }
                        .font(.custom(Typography.geist, size: 15))
                        .foregroundStyle(t.textMid)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: reportText, preview: SharePreview("Laborbericht")) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15))
                            .foregroundStyle(t.text)
                    }
                }
            }
        }
    }

    @ViewBuilder private func statusBadge(label: String, count: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text("\(count) \(label)")
                .font(.custom(Typography.geistMono, size: 11))
                .foregroundStyle(t.textMuted)
        }
    }

    @ViewBuilder private func reportCategorySection(_ cat: (name: String, markers: [LabMarker])) -> some View {
        VStack(spacing: 0) {
            SectionHead(label: cat.name).padding(.top, 18)
            Card(pad: 0) {
                VStack(spacing: 0) {
                    ForEach(cat.markers, id: \.name) { marker in
                        reportRow(marker: marker, isLast: marker.name == cat.markers.last?.name)
                    }
                }
            }
            .padding(.horizontal, Spacing.xl)
        }
    }

    @ViewBuilder private func reportRow(marker: LabMarker, isLast: Bool) -> some View {
        let statusColor: Color = {
            switch marker.status {
            case .normal: return t.accent
            case .high:   return t.danger
            case .low:    return t.amber
            }
        }()

        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Circle().fill(statusColor).frame(width: 8, height: 8)
                Text(marker.name)
                    .font(.custom(Typography.geist, size: 14))
                    .foregroundStyle(t.text)
                Spacer()
                Text(marker.status.label)
                    .font(.custom(Typography.geistMono, size: 11))
                    .foregroundStyle(statusColor)
                Text(marker.range)
                    .font(.custom(Typography.geistMono, size: 11))
                    .foregroundStyle(t.textMuted)
                Text(marker.value)
                    .font(Typography.number(13))
                    .foregroundStyle(t.text)
            }
            .padding(.horizontal, Spacing.l).padding(.vertical, 14)

            if !isLast {
                Divider().background(t.border).padding(.horizontal, Spacing.l)
            }
        }
    }
}

#Preview {
    ThemedRoot { LabOverviewView() }
        .environment(AppDependencies.mock())
}
