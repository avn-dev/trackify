import SwiftUI

struct DataExportView: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    @Environment(AppDependencies.self) private var deps

    @State private var workoutCount = 0
    @State private var runCount = 0
    @State private var bodyMetricCount = 0
    @State private var labCount = 0
    @State private var supplementCount = 0
    @State private var isExporting = false
    @State private var exportURL: URL?
    @State private var showShare = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ScreenHeader(title: "Datenexport", back: "Profil", onBack: { dismiss() })

                infoCard
                    .padding(.horizontal, Spacing.xl)

                SectionHead(label: "Enthaltene Daten").padding(.top, 18)

                VStack(spacing: 8) {
                    dataRow(icon: "dumbbell", label: "Workouts & Sätze", count: workoutCount)
                    dataRow(icon: "figure.run", label: "Läufe", count: runCount)
                    dataRow(icon: "scalemass", label: "Körpermessungen", count: bodyMetricCount)
                    dataRow(icon: "drop", label: "Laborwerte", count: labCount)
                    dataRow(icon: "pills", label: "Supplements", count: supplementCount)
                }
                .padding(.horizontal, Spacing.xl)

                PrimaryButton(title: isExporting ? "Wird exportiert…" : "JSON exportieren") {
                    guard !isExporting else { return }
                    Task { await exportData() }
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.top, 24)
                .padding(.bottom, Spacing.screenSafeBottom)
                .disabled(isExporting)
            }
        }
        .background(t.bg.ignoresSafeArea())
        .navigationBarHidden(true)
        .task { await loadCounts() }
        .sheet(isPresented: $showShare) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
        .alert("Export fehlgeschlagen", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func loadCounts() async {
        workoutCount    = ((try? await deps.workouts.fetchWorkouts(limit: 9999)) ?? []).count
        runCount        = ((try? await deps.runs.fetchRuns(limit: 9999)) ?? []).count
        supplementCount = ((try? await deps.supplements.fetchSupplements()) ?? []).count
        labCount        = ((try? await deps.lab.fetchMeasurements(limit: 9999)) ?? []).flatMap(\.values).count
        var bodyTotal = 0
        for type in BodyMetricType.allCases {
            bodyTotal += ((try? await deps.body.fetchMetrics(type: type, limit: 9999)) ?? []).count
        }
        bodyMetricCount = bodyTotal
    }

    private func exportData() async {
        isExporting = true
        defer { isExporting = false }

        let workouts     = (try? await deps.workouts.fetchWorkouts(limit: 9999)) ?? []
        let runs         = (try? await deps.runs.fetchRuns(limit: 9999)) ?? []
        let supplements  = (try? await deps.supplements.fetchSupplements()) ?? []
        let measurements = (try? await deps.lab.fetchMeasurements(limit: 9999)) ?? []

        var bodyMetrics: [String: [[String: Any]]] = [:]
        for type in BodyMetricType.allCases {
            let metrics = (try? await deps.body.fetchMetrics(type: type, limit: 9999)) ?? []
            if !metrics.isEmpty {
                bodyMetrics[type.rawValue] = metrics.map { m in
                    ["ts": ISO8601DateFormatter().string(from: m.ts),
                     "value": m.value,
                     "unit": type.unit]
                }
            }
        }

        let df = ISO8601DateFormatter()
        let payload: [String: Any] = [
            "exportedAt": df.string(from: .now),
            "appVersion": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0",
            "workouts": workouts.map { w in
                ["id": w.id.uuidString,
                 "startedAt": df.string(from: w.startedAt),
                 "volumeKg": w.volumeKg,
                 "planDay": w.planDay as Any]
            },
            "runs": runs.map { r in
                ["id": r.id.uuidString,
                 "startedAt": df.string(from: r.startedAt),
                 "distanceM": r.distanceM,
                 "durationS": r.durationS,
                 "gainM": r.gainM]
            },
            "bodyMetrics": bodyMetrics,
            "supplements": supplements.map { s in
                ["id": s.id.uuidString,
                 "name": s.name,
                 "dose": s.dose,
                 "kind": s.kind.rawValue,
                 "form": s.form,
                 "times": s.times]
            },
            "labMeasurements": measurements.map { m in
                ["id": m.id.uuidString,
                 "takenAt": df.string(from: m.takenAt),
                 "source": m.source,
                 "values": m.values.map { v in
                     ["marker": v.marker,
                      "value": v.value,
                      "unit": v.unit,
                      "refLow": v.refLow,
                      "refHigh": v.refHigh]
                 }]
            },
        ]

        do {
            let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("trackify-export.json")
            try data.write(to: url)
            exportURL = url
            showShare = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @ViewBuilder private var infoCard: some View {
        Card(pad: Spacing.l) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 22))
                    .foregroundStyle(t.accent)
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(t.surface2))
                VStack(alignment: .leading, spacing: 4) {
                    Text("JSON-Export")
                        .font(.custom(Typography.geist, size: 15).weight(.semibold))
                        .foregroundStyle(t.text)
                    Text("Alle deine Daten als maschinenlesbares JSON-Archiv.")
                        .font(.custom(Typography.geistMono, size: 12))
                        .foregroundStyle(t.textMuted)
                }
            }
        }
    }

    @ViewBuilder private func dataRow(icon: String, label: String, count: Int?) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(t.accent)
                .frame(width: 32, height: 32)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(t.surface2))
            Text(label)
                .font(.custom(Typography.geist, size: 15))
                .foregroundStyle(t.text)
            Spacer()
            if let count {
                Text("\(count)")
                    .font(Typography.number(14))
                    .foregroundStyle(t.textMuted)
            }
        }
        .padding(.horizontal, Spacing.l).padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: Radii.row, style: .continuous).fill(t.surface))
        .overlay(RoundedRectangle(cornerRadius: Radii.row, style: .continuous).stroke(t.border, lineWidth: 1))
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}

#Preview {
    ThemedRoot {
        NavigationStack { DataExportView() }
    }
    .environment(AppDependencies.mock())
}
