import SwiftUI
import CoreLocation

struct RunHistoryView: View {
    @Environment(\.theme) private var t
    @Environment(AppDependencies.self) private var deps
    @AppStorage("unitsKm") private var unitsKm = true
    @State private var showLive = false
    @State private var showPeriodPicker = false
    @State private var filterOffset = 0   // 0 = this month, 1 = last, -1 = all
    @State private var runs: [RunSummary] = []
    @State private var expandedRunID: UUID?
    @AppStorage("locationPrePromptShown") private var locationPrePromptShown = false
    @State private var showLocationPrePrompt = false
    @State private var fetchedRuns: [Run] = []
    @State private var summary = RunMonthlySummary(totalDistanceM: 0, count: 0,
                                                    weeklyDistances: [], avgPaceSecPerKm: 0)

    private static let monthNames = ["Jan","Feb","Mär","Apr","Mai","Jun","Jul","Aug","Sep","Okt","Nov","Dez"]

    private var filterDate: Date {
        guard filterOffset >= 0 else { return .distantPast }
        return Calendar.current.date(byAdding: .month, value: -filterOffset, to: .now) ?? .now
    }
    private var filterMonth: Int { Calendar.current.component(.month, from: filterDate) }
    private var filterYear: Int { Calendar.current.component(.year, from: filterDate) }
    private var filterLabel: String {
        switch filterOffset {
        case 0: return Self.monthNames[filterMonth - 1]
        case 1: return Self.monthNames[filterMonth - 1]
        default: return "Alles"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ScreenHeader(title: "Läufe", eyebrow: "Cardio · \(filterLabel)") {
                    CircleBtn(systemIcon: "line.3.horizontal.decrease") { showPeriodPicker = true }
                }

                monthlySummaryCard
                    .padding(.horizontal, Spacing.xl)

                SectionHead(label: "Letzte Läufe")
                    .padding(.top, 18)

                if runs.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 36))
                            .foregroundStyle(t.textMuted)
                        Text("Noch keine Läufe")
                            .font(.custom(Typography.geist, size: 17).weight(.semibold))
                            .foregroundStyle(t.text)
                        Text("Starte deinen ersten Lauf\num ihn hier zu sehen.")
                            .font(.custom(Typography.geist, size: 14))
                            .foregroundStyle(t.textMuted)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, Spacing.screenSafeBottom)
                } else {
                    VStack(spacing: 10) {
                        ForEach(runs) { run in
                            RunRow(run: run, isExpanded: run.id == expandedRunID, useKm: unitsKm) {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    expandedRunID = expandedRunID == run.id ? nil : run.id
                                }
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    Task { await deleteRun(run) }
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
        .fullScreenCover(isPresented: $showLive) {
            ThemedRoot { RunLiveView() }
        }
        .sheet(isPresented: $showLocationPrePrompt) {
            LocationPrePromptSheet {
                locationPrePromptShown = true
                showLocationPrePrompt = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showLive = true }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .overlay(alignment: .bottomTrailing) {
            Button { handleRunTap() } label: {
                Image(systemName: "figure.run")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(t.accentText)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(t.accent))
            }
            .buttonStyle(.plain)
            .padding(.trailing, 20)
            .padding(.bottom, 110)
        }
        .onChange(of: showLive) { _, showing in
            if !showing { Task { await loadData() } }
        }
        .onChange(of: filterOffset) { _, _ in Task { await loadData() } }
        .confirmationDialog("Zeitraum wählen", isPresented: $showPeriodPicker, titleVisibility: .visible) {
            Button("Dieser Monat") { filterOffset = 0 }
            Button("Letzter Monat") { filterOffset = 1 }
            Button("Alles") { filterOffset = -1 }
            Button("Abbrechen", role: .cancel) {}
        }
        .task { await loadData() }
    }

    private func handleRunTap() {
        let status = CLLocationManager().authorizationStatus
        if status == .authorizedAlways || locationPrePromptShown {
            showLive = true
        } else {
            showLocationPrePrompt = true
        }
    }

    private func loadData() async {
        let all = (try? await deps.runs.fetchRuns(limit: 500)) ?? []

        // Client-side period filter
        let filtered: [Run]
        if filterOffset == -1 {
            filtered = all
        } else {
            let cal = Calendar.current
            guard let start = cal.date(from: cal.dateComponents([.year, .month], from: filterDate)),
                  let end = cal.date(byAdding: .month, value: 1, to: start) else { return }
            filtered = all.filter { $0.startedAt >= start && $0.startedAt < end }
        }

        fetchedRuns = filtered
        let firstID = filtered.first?.id
        runs = filtered.map { r in
            let paceSecPerKm = r.distanceM > 0
                ? Int(Double(r.durationS) / (r.distanceM / 1000.0))
                : 0
            return RunSummary(
                id: r.id,
                date: r.startedAt,
                distanceKm: r.distanceM / 1000.0,
                durationS: r.durationS,
                gainM: Int(r.gainM),
                paceSecPerKm: paceSecPerKm,
                bpm: 0,
                polylineCoords: decodeRunCoordinates(r.polyline)
            )
        }
        if expandedRunID == nil { expandedRunID = firstID }

        if filterOffset == -1 {
            // Compute aggregate summary from all runs
            let totalDist = runs.reduce(0.0) { $0 + $1.distanceKm * 1000 }
            let avgPace   = runs.isEmpty ? 0 : runs.reduce(0) { $0 + $1.paceSecPerKm } / runs.count
            summary = RunMonthlySummary(totalDistanceM: totalDist, count: runs.count,
                                        weeklyDistances: [], avgPaceSecPerKm: avgPace)
        } else {
            summary = (try? await deps.runs.monthlySummary(year: filterYear, month: filterMonth))
                ?? RunMonthlySummary(totalDistanceM: 0, count: 0, weeklyDistances: [], avgPaceSecPerKm: 0)
        }
    }

    private func deleteRun(_ run: RunSummary) async {
        guard let fullRun = fetchedRuns.first(where: { $0.id == run.id }) else { return }
        try? await deps.runs.delete(fullRun)
        await loadData()
    }

    @ViewBuilder private var monthlySummaryCard: some View {
        Card(pad: Spacing.l) {
            Eyebrow(text: "\(filterLabel) · \(summary.count) Läufe")
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(Formatters.distanceValue(summary.totalDistanceM / 1000.0, useKm: unitsKm))
                    .font(Typography.number(38))
                    .kerning(-1.4)
                    .foregroundStyle(t.text)
                Text("km")
                    .font(.custom(Typography.geistMono, size: 16))
                    .foregroundStyle(t.textMuted)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Eyebrow(text: "Ø Pace")
                    Text(summary.avgPaceSecPerKm > 0
                         ? Formatters.pace(summary.avgPaceSecPerKm, useKm: unitsKm) + "/" + Formatters.distanceUnit(unitsKm)
                         : "–")
                        .font(Typography.number(14))
                        .foregroundStyle(t.text)
                }
            }
            .padding(.top, 8)

            if !summary.weeklyDistances.isEmpty {
                let pts = summary.weeklyDistances.enumerated().map { i, d in
                    BarPoint(label: "W\(i + 1)", value: d,
                             highlighted: i == summary.weeklyDistances.count - 1)
                }
                TrackifyBarChart(data: pts)
                    .frame(height: 72)
                    .padding(.top, 12)
            }
        }
    }
}

// MARK: - Run row

struct RunRow: View {
    @Environment(\.theme) private var t
    var run: RunSummary
    var isExpanded: Bool
    var useKm: Bool = true
    var onTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
            HStack(spacing: 12) {
                routeThumbnail
                VStack(alignment: .leading, spacing: 4) {
                    Text(Formatters.shortDate(run.date))
                        .font(.custom(Typography.geist, size: 15).weight(.semibold))
                        .foregroundStyle(t.text)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(Formatters.distanceValue(run.distanceKm, useKm: useKm))
                            .font(Typography.number(20))
                            .foregroundStyle(t.text)
                        Text(Formatters.distanceUnit(useKm))
                            .font(.custom(Typography.geistMono, size: 12))
                            .foregroundStyle(t.textMuted)
                    }
                    HStack(spacing: 10) {
                        Text(Formatters.duration(run.durationS))
                        Text("·")
                        Text(Formatters.pace(run.paceSecPerKm, useKm: useKm) + "/" + Formatters.distanceUnit(useKm))
                        Text("·")
                        Text("+\(run.gainM)m")
                    }
                    .font(.custom(Typography.geistMono, size: 11))
                    .foregroundStyle(t.textMuted)
                }
                Spacer()
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12))
                    .foregroundStyle(t.textMuted)
            }
            .padding(14)
            .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 10) {
                    RunRouteMapView(coordinates: run.polylineCoords)
                        .frame(height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    HStack(spacing: 0) {
                        ForEach([
                            ("Zeit",    Formatters.duration(run.durationS)),
                            ("Pace",    Formatters.pace(run.paceSecPerKm, useKm: useKm) + "/" + Formatters.distanceUnit(useKm)),
                            ("Anstieg", "+\(run.gainM) m"),
                        ], id: \.0) { label, value in
                            VStack(spacing: 4) {
                                Text(label.uppercased())
                                    .font(.custom(Typography.geistMono, size: 10)).kerning(0.6)
                                    .foregroundStyle(t.textMuted)
                                Text(value)
                                    .font(Typography.number(14))
                                    .foregroundStyle(t.text)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: isExpanded ? Radii.card : Radii.cardSmall, style: .continuous)
                .fill(t.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: isExpanded ? Radii.card : Radii.cardSmall, style: .continuous)
                .stroke(t.border, lineWidth: 1)
        )
    }

    @ViewBuilder private var routeThumbnail: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(t.surface2)
            .frame(width: 52, height: 52)
            .overlay(
                Group {
                    if run.polylineCoords.count > 1 {
                        RunRouteMapView(coordinates: run.polylineCoords)
                    } else {
                        Image(systemName: "figure.run")
                            .font(.system(size: 20))
                            .foregroundStyle(t.accent)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct RunSummary: Identifiable {
    var id: UUID
    var date: Date
    var distanceKm: Double
    var durationS: Int
    var gainM: Int
    var paceSecPerKm: Int
    var bpm: Int
    var polylineCoords: [CLLocationCoordinate2D]
}

// MARK: - Location pre-prompt

struct LocationPrePromptSheet: View {
    @Environment(\.theme) private var t
    var onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle().fill(t.accent.opacity(0.12)).frame(width: 72, height: 72)
                Image(systemName: "location.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(t.accent)
            }
            .padding(.top, 32)

            Text("Standort im Hintergrund")
                .font(Typography.title(22)).kerning(-0.6)
                .foregroundStyle(t.text)
                .multilineTextAlignment(.center)
                .padding(.top, 20)
                .padding(.horizontal, Spacing.xl)

            VStack(alignment: .leading, spacing: 18) {
                prePromptRow(icon: "figure.run",
                             text: "Deine Route wird aufgezeichnet, auch wenn das Display gesperrt ist.")
                prePromptRow(icon: "lock.shield",
                             text: "GPS-Daten bleiben lokal auf deinem Gerät und werden nicht übertragen.")
                prePromptRow(icon: "battery.100",
                             text: "Die Aufzeichnung endet automatisch, wenn du den Lauf stoppst.")
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, 28)

            Spacer()

            PrimaryButton(title: "Verstanden · Lauf starten", action: onConfirm)
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, max(Spacing.screenSafeBottom, 24))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(t.bg.ignoresSafeArea())
    }

    @ViewBuilder private func prePromptRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(t.accent)
                .frame(width: 24)
            Text(text)
                .font(.custom(Typography.geist, size: 15))
                .foregroundStyle(t.textMid)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    ThemedRoot { RunHistoryView() }
        .environment(AppDependencies.mock())
}
