import SwiftUI
import Charts
import MapKit

struct RunLiveView: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    @Environment(AppDependencies.self) private var deps
    @AppStorage("unitsKm")         private var unitsKm        = true
    @AppStorage("hkHeartRate")     private var hkHeartRate     = false
    @AppStorage("hkWorkoutExport") private var hkWorkoutExport = false

    @State private var tracker = RunTracker()
    @State private var showMap = false
    @State private var showSummary = false
    @State private var summaryData: RunSummaryData?

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    statusLine
                    heroDistance
                    secondaryStats
                    elevationSection
                    splitsSection
                    Spacer().frame(height: 160)
                }
            }
            .background(t.bg.ignoresSafeArea())

            bottomControls
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            tracker.requestAuthorization()
            tracker.start(readHeartRate: hkHeartRate)
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .sheet(isPresented: $showMap) {
            LiveRunMapSheet(locations: tracker.locations)
        }
        .sheet(isPresented: $showSummary, onDismiss: { dismiss() }) {
            if let data = summaryData {
                RunSummarySheet(data: data, unitsKm: unitsKm)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Sub-views

    @ViewBuilder private var statusLine: some View {
        HStack {
            HStack(spacing: 8) {
                ZStack {
                    Circle().fill(t.accent.opacity(0.2)).frame(width: 14, height: 14)
                    Circle().fill(t.accent).frame(width: 8, height: 8)
                }
                Text("LIVE · \(tracker.gpsStatus.label)")
                    .font(.custom(Typography.geistMono, size: 11))
                    .kerning(1)
                    .foregroundStyle(t.textMid)
            }
            Spacer()
            Button { showMap = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "map").font(.system(size: 12))
                    Text("Karte").font(.custom(Typography.geist, size: 12))
                }
                .foregroundStyle(t.textMid)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .overlay(Capsule().stroke(t.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 54)
        .padding(.horizontal, Spacing.xl)
    }

    @ViewBuilder private var heroDistance: some View {
        VStack(spacing: 4) {
            Text("DISTANZ")
                .font(.custom(Typography.geistMono, size: 11))
                .kerning(1.2)
                .foregroundStyle(t.textMuted)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(Formatters.distanceValue(tracker.distanceM / 1000, useKm: unitsKm))
                    .font(Typography.number(88))
                    .kerning(-3.5)
                    .foregroundStyle(t.text)
                Text(Formatters.distanceUnit(unitsKm))
                    .font(Typography.number(28))
                    .foregroundStyle(t.textMuted)
            }
        }
        .padding(.top, 36)
        .padding(.horizontal, Spacing.xl)
    }

    @ViewBuilder private var secondaryStats: some View {
        HStack(spacing: 0) {
            ForEach([
                ("ZEIT",  Formatters.duration(tracker.elapsedSeconds), false),
                ("PACE",  tracker.paceSecPerKm > 0 ? Formatters.pace(tracker.paceSecPerKm, useKm: unitsKm) + "/" + Formatters.distanceUnit(unitsKm) : "–", true),
                ("BPM",   tracker.bpm > 0 ? "\(tracker.bpm)" : "–", false),
            ], id: \.0) { label, value, isAccent in
                VStack(spacing: 6) {
                    Text(label)
                        .font(.custom(Typography.geistMono, size: 10))
                        .kerning(1)
                        .foregroundStyle(t.textMuted)
                    Text(value)
                        .font(Typography.number(28))
                        .kerning(-1)
                        .foregroundStyle(isAccent ? t.accent : t.text)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 6)
                .overlay(alignment: .leading) {
                    if label != "ZEIT" {
                        Rectangle().fill(t.border).frame(width: 1, height: 40)
                    }
                }
            }
        }
        .padding(.top, 36)
        .padding(.horizontal, Spacing.xl)
    }

    @ViewBuilder private var elevationSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("HÖHENMETER")
                    .font(.custom(Typography.geistMono, size: 11))
                    .kerning(1)
                    .foregroundStyle(t.textMuted)
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("+\(Int(tracker.gainM))")
                        .font(Typography.number(14))
                        .foregroundStyle(t.text)
                    Text("m").font(.custom(Typography.geistMono, size: 12)).foregroundStyle(t.textMuted)
                }
            }
            ElevationSparkline(history: tracker.altitudeHistory)
                .frame(height: 64)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, 34)
    }

    @ViewBuilder private var splitsSection: some View {
        if !tracker.splits.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("SPLITS")
                    .font(.custom(Typography.geistMono, size: 11))
                    .kerning(1)
                    .foregroundStyle(t.textMuted)

                let validPaces  = tracker.splits.map(\.paceSecPerKm).filter { $0 > 0 }
                let bestPace    = validPaces.min() ?? 0
                let worstPace   = validPaces.max() ?? 0
                let paceRange   = worstPace - bestPace
                VStack(spacing: 0) {
                    ForEach(Array(tracker.splits.enumerated()), id: \.element.id) { idx, split in
                        let fraction: Double = paceRange > 0
                            ? 0.1 + 0.9 * (1.0 - Double(split.paceSecPerKm - bestPace) / Double(paceRange))
                            : 0.6
                        let row = RunSplitRow(
                            km: split.km,
                            pace: Formatters.pace(split.paceSecPerKm, useKm: unitsKm),
                            bpm: split.bpm,
                            isBest: split.paceSecPerKm == bestPace && bestPace > 0,
                            paceFraction: fraction
                        )
                        SplitRow(split: row, isLast: idx == tracker.splits.count - 1)
                    }
                }
                .background(RoundedRectangle(cornerRadius: Radii.row, style: .continuous).fill(t.surface))
                .overlay(RoundedRectangle(cornerRadius: Radii.row, style: .continuous).stroke(t.border, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: Radii.row, style: .continuous))
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, 24)
        }
    }

    @ViewBuilder private var bottomControls: some View {
        HStack(spacing: 14) {
            Button {
                let result = tracker.finish()
                let dist = tracker.distanceM
                let dur  = tracker.elapsedSeconds
                let pace = tracker.paceSecPerKm
                let gain = tracker.gainM
                let spl  = tracker.splits.count
                Task {
                    let startedAt = Date().addingTimeInterval(-Double(dur))
                    let endedAt   = Date.now
                    let run = Run(
                        userID: .localUser,
                        startedAt: startedAt,
                        endedAt: endedAt,
                        distanceM: dist,
                        durationS: dur,
                        gainM: gain,
                        polyline: result.polyline,
                        splitsJSON: result.splitsJSON
                    )
                    try? await deps.runs.save(run)
                    if hkWorkoutExport && HealthKitService.isAvailable {
                        await HealthKitService.shared.saveRunningWorkout(
                            start: startedAt, end: endedAt, distanceM: dist
                        )
                    }
                }
                UIApplication.shared.isIdleTimerDisabled = false
                summaryData = RunSummaryData(distanceM: dist, durationSec: dur,
                                             paceSecPerKm: pace, gainM: gain, splitsCount: spl)
                showSummary = true
            } label: {
                Image(systemName: "stop.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(t.text)
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(t.surface))
                    .overlay(Circle().stroke(t.borderStrong, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Button {
                withAnimation {
                    if tracker.isPaused { tracker.resume() } else { tracker.pause() }
                }
                HapticFeedback.medium()
            } label: {
                Image(systemName: tracker.isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(t.accentText)
                    .frame(width: 88, height: 88)
                    .background(Circle().fill(t.accent))
                    .overlay(Circle().stroke(t.bg, lineWidth: 8))
                    .overlay(Circle().stroke(t.accent.opacity(0.4), lineWidth: 1).padding(-8))
            }
            .buttonStyle(.plain)

            Button {
                tracker.lap()
                HapticFeedback.medium()
            } label: {
                Text("LAP")
                    .font(.custom(Typography.geistMono, size: 11).weight(.semibold))
                    .foregroundStyle(t.text)
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(t.surface))
                    .overlay(Circle().stroke(t.borderStrong, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, 30)
    }
}

// MARK: - Elevation sparkline

struct ElevationSparkline: View {
    @Environment(\.theme) private var t
    var history: [Double]

    private static let fallback: [Double] = [0, 2, 6, 5, 12, 18, 22, 26, 32, 30, 38, 45, 52, 60, 64, 70, 78, 82, 78, 80]

    private var pts: [Double] {
        let src = history.isEmpty ? Self.fallback : history
        // Downsample to max 60 points for chart performance
        guard src.count > 60 else { return src }
        let step = src.count / 60
        return stride(from: 0, to: src.count, by: max(step, 1)).map { src[$0] }
    }

    var body: some View {
        TrackifyLineChart(
            data: pts.enumerated().map { LinePoint(x: Double($0.offset), y: $0.element) },
            accent: true,
            showAxis: false
        )
    }
}

// MARK: - Split row

struct SplitRow: View {
    @Environment(\.theme) private var t
    var split: RunSplitRow
    var isLast: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text("KM \(split.km)")
                .font(.custom(Typography.geistMono, size: 13))
                .foregroundStyle(t.textMuted)
                .frame(width: 44)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(t.surface2).frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(split.isBest ? t.accent : t.text)
                        .frame(width: geo.size.width * split.paceFraction, height: 4)
                }
                .frame(height: geo.size.height)
            }
            Text(split.pace)
                .font(.custom(Typography.geistMono, size: 13))
                .foregroundStyle(split.isBest ? t.accent : t.text)
                .frame(width: 64)
            Text("\(split.bpm) bpm")
                .font(.custom(Typography.geistMono, size: 13))
                .foregroundStyle(t.textMid)
                .frame(width: 56, alignment: .trailing)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            if !isLast { Rectangle().fill(t.border).frame(height: 1) }
        }
    }
}

struct RunSplitRow: Identifiable {
    var id: Int { km }
    var km: Int
    var pace: String
    var bpm: Int
    var isBest: Bool
    var paceFraction: Double = 0.6
}

// MARK: - Live route map sheet

struct LiveRunMapSheet: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    var locations: [CLLocationCoordinate2D]

    private var region: MKCoordinateRegion {
        guard !locations.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 48.137, longitude: 11.576),
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        }
        let lats = locations.map(\.latitude)
        let lons = locations.map(\.longitude)
        let center = CLLocationCoordinate2D(
            latitude: (lats.min()! + lats.max()!) / 2,
            longitude: (lons.min()! + lons.max()!) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((lats.max()! - lats.min()!) * 1.4, 0.005),
            longitudeDelta: max((lons.max()! - lons.min()!) * 1.4, 0.005)
        )
        return MKCoordinateRegion(center: center, span: span)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Map(initialPosition: .region(region)) {
                if locations.count >= 2 {
                    MapPolyline(coordinates: locations)
                        .stroke(t.accent, lineWidth: 4)
                }
                if let last = locations.last {
                    Annotation("", coordinate: last) {
                        ZStack {
                            Circle().fill(t.accent).frame(width: 14, height: 14)
                            Circle().fill(t.accent.opacity(0.3)).frame(width: 24, height: 24)
                        }
                    }
                }
            }
            .ignoresSafeArea()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(t.text)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(t.surface))
                    .overlay(Circle().stroke(t.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
            .padding(.trailing, 16)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Run summary

struct RunSummaryData {
    var distanceM: Double
    var durationSec: Int
    var paceSecPerKm: Int
    var gainM: Double
    var splitsCount: Int
}

struct RunSummarySheet: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    var data: RunSummaryData
    var unitsKm: Bool

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(t.accent)
                    .padding(.top, 36)
                Text("Lauf abgeschlossen")
                    .font(Typography.title(22))
                    .kerning(-0.6)
                    .foregroundStyle(t.text)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, 28)

            HStack(spacing: 0) {
                summaryCell(label: "Distanz",
                            value: Formatters.distanceValue(data.distanceM / 1000, useKm: unitsKm),
                            unit: Formatters.distanceUnit(unitsKm))
                Rectangle().fill(t.border).frame(width: 1, height: 44)
                summaryCell(label: "Zeit", value: Formatters.duration(data.durationSec), unit: nil)
                Rectangle().fill(t.border).frame(width: 1, height: 44)
                summaryCell(label: "Pace",
                            value: data.paceSecPerKm > 0 ? Formatters.pace(data.paceSecPerKm, useKm: unitsKm) : "–",
                            unit: data.paceSecPerKm > 0 ? "/\(Formatters.distanceUnit(unitsKm))" : nil)
            }
            .padding(.bottom, 16)

            HStack(spacing: 0) {
                summaryCell(label: "Anstieg", value: "+\(Int(data.gainM))", unit: "m")
                Rectangle().fill(t.border).frame(width: 1, height: 44)
                summaryCell(label: "Splits", value: "\(data.splitsCount)", unit: nil)
            }
            .padding(.bottom, 32)

            PrimaryButton(title: "Fertig") { dismiss() }
                .padding(.horizontal, Spacing.xl)
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

#Preview {
    ThemedRoot { RunLiveView() }
        .environment(AppDependencies.mock())
}
