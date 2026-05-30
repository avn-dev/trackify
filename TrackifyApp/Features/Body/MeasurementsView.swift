import SwiftUI

struct MeasurementsView: View {
    @Environment(\.theme) private var t
    @Environment(AppDependencies.self) private var deps
    @Environment(\.dismiss) private var dismiss
    @State private var latestValues: [BodyMetricType: Double] = [:]
    @State private var previousValues: [BodyMetricType: Double] = [:]
    @State private var showEntry = false

    private let primaryTypes: [BodyMetricType] = [.chest, .waist, .hips, .biceps, .thigh, .calf]
    private let secondaryTypes: [BodyMetricType] = [.shoulder, .forearm, .neck, .ankle]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ScreenHeader(title: "Körpermaße", back: "Körper", onBack: { dismiss() }) {
                    CircleBtn(systemIcon: "plus") { showEntry = true }
                }

                silhouetteCard
                    .padding(.horizontal, Spacing.xl)

                SectionHead(label: "Weitere Maße").padding(.top, 18)

                secondaryGrid
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, Spacing.screenSafeBottom)
            }
        }
        .background(t.bg.ignoresSafeArea())
        .navigationBarHidden(true)
        .task { await loadData() }
        .sheet(isPresented: $showEntry) {
            MeasurementsEntrySheet { entries in
                Task { await saveEntries(entries) }
            }
        }
    }

    private func loadData() async {
        for type in BodyMetricType.allCases {
            let recent = (try? await deps.body.fetchMetrics(type: type, limit: 2)) ?? []
            latestValues[type]   = recent.first?.value
            previousValues[type] = recent.count > 1 ? recent[1].value : nil
        }
    }

    private func saveEntries(_ entries: [BodyMetricType: Double]) async {
        for (type, value) in entries {
            let m = BodyMetric(userID: .localUser, ts: .now, type: type, value: value)
            try? await deps.body.save(m)
        }
        await loadData()
    }

    // MARK: - Silhouette card

    @ViewBuilder private var silhouetteCard: some View {
        Card(pad: Spacing.l) {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack {
                    // Body silhouette
                    BodySilhouettePath()
                        .stroke(t.borderStrong, lineWidth: 1.5)
                        .frame(width: w * 0.38, height: h)
                        .position(x: w * 0.5, y: h * 0.5)

                    // Measurement ellipses (lime outlines)
                    ForEach(ellipseBands(w: w, h: h), id: \.label) { band in
                        Ellipse()
                            .stroke(t.accent.opacity(0.7), style: StrokeStyle(lineWidth: 1.5))
                            .frame(width: band.ellipseW, height: 8)
                            .position(x: w * 0.5, y: band.y)
                    }

                    // Left tags: chest, waist, hips
                    ForEach(leftTags(w: w, h: h), id: \.type) { tag in
                        bodyTag(type: tag.type, x: tag.x, y: tag.y,
                                anchorX: tag.anchorX, anchorY: tag.anchorY,
                                side: .left, size: geo.size)
                    }

                    // Right tags: biceps, thigh, calf
                    ForEach(rightTags(w: w, h: h), id: \.type) { tag in
                        bodyTag(type: tag.type, x: tag.x, y: tag.y,
                                anchorX: tag.anchorX, anchorY: tag.anchorY,
                                side: .right, size: geo.size)
                    }
                }
            }
            .frame(height: 380)
        }
    }

    private struct EllipseBand { var label: String; var y: CGFloat; var ellipseW: CGFloat }
    private struct TagPlacement { var type: BodyMetricType; var x: CGFloat; var y: CGFloat; var anchorX: CGFloat; var anchorY: CGFloat }

    private func ellipseBands(w: CGFloat, h: CGFloat) -> [EllipseBand] {
        [
            EllipseBand(label: "chest",  y: h * 0.305, ellipseW: w * 0.26),
            EllipseBand(label: "waist",  y: h * 0.435, ellipseW: w * 0.20),
            EllipseBand(label: "hips",   y: h * 0.535, ellipseW: w * 0.26),
            EllipseBand(label: "biceps", y: h * 0.295, ellipseW: w * 0.09),
            EllipseBand(label: "thigh",  y: h * 0.655, ellipseW: w * 0.15),
            EllipseBand(label: "calf",   y: h * 0.800, ellipseW: w * 0.10),
        ]
    }

    private func leftTags(w: CGFloat, h: CGFloat) -> [TagPlacement] {
        [
            TagPlacement(type: .chest,  x: w * 0.14, y: h * 0.305, anchorX: w * 0.315, anchorY: h * 0.305),
            TagPlacement(type: .waist,  x: w * 0.14, y: h * 0.435, anchorX: w * 0.290, anchorY: h * 0.435),
            TagPlacement(type: .hips,   x: w * 0.14, y: h * 0.535, anchorX: w * 0.315, anchorY: h * 0.535),
        ]
    }

    private func rightTags(w: CGFloat, h: CGFloat) -> [TagPlacement] {
        [
            TagPlacement(type: .biceps, x: w * 0.86, y: h * 0.295, anchorX: w * 0.655, anchorY: h * 0.295),
            TagPlacement(type: .thigh,  x: w * 0.86, y: h * 0.655, anchorX: w * 0.618, anchorY: h * 0.655),
            TagPlacement(type: .calf,   x: w * 0.86, y: h * 0.800, anchorX: w * 0.600, anchorY: h * 0.800),
        ]
    }

    private enum TagSide { case left, right }

    @ViewBuilder private func bodyTag(type: BodyMetricType, x: CGFloat, y: CGFloat,
                                      anchorX: CGFloat, anchorY: CGFloat,
                                      side: TagSide, size: CGSize) -> some View {
        let value = latestValues[type] ?? 0
        let prev  = previousValues[type] ?? value
        let delta = value - prev
        let isGood = type.higherIsBetter ? delta >= 0 : delta <= 0

        ZStack {
            // Dashed connector line
            Path { path in
                path.move(to: CGPoint(x: anchorX, y: anchorY))
                path.addLine(to: CGPoint(x: side == .left ? x + 36 : x - 36, y: y))
            }
            .stroke(t.borderStrong, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))

            // Tag card
            VStack(spacing: 1) {
                Text(type.label.uppercased())
                    .font(.custom(Typography.geistMono, size: 7).weight(.medium))
                    .kerning(0.4)
                    .foregroundStyle(t.textMuted)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value > 0 ? Formatters.compact(value) : "–")
                        .font(Typography.number(13))
                        .foregroundStyle(t.text)
                    if value > 0 {
                        Text("cm")
                            .font(.custom(Typography.geistMono, size: 8))
                            .foregroundStyle(t.textMuted)
                    }
                }
                if delta != 0 && value > 0 {
                    Text(delta > 0 ? "+\(Formatters.compact(abs(delta)))" : "−\(Formatters.compact(abs(delta)))")
                        .font(.custom(Typography.geistMono, size: 8))
                        .foregroundStyle(isGood ? t.accent : t.danger)
                }
            }
            .padding(.horizontal, 6).padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous).fill(t.surface2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(t.border, lineWidth: 1)
            )
            .frame(width: 72)
            .position(x: x, y: y)
        }
    }

    // MARK: - Primary list (used when silhouette unavailable)

    @ViewBuilder private var measurementList: some View {
        Card(pad: 0) {
            VStack(spacing: 0) {
                ForEach(primaryTypes, id: \.self) { type in
                    let value = latestValues[type] ?? 0
                    let prev  = previousValues[type] ?? value
                    let delta = value - prev
                    HStack {
                        Text(type.label)
                            .font(.custom(Typography.geist, size: 13))
                            .foregroundStyle(t.textMid)
                        Spacer()
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            if value != prev && delta != 0 {
                                let isGood = type.higherIsBetter ? delta > 0 : delta < 0
                                Text(delta > 0 ? "+\(Formatters.compact(delta))" : "−\(Formatters.compact(abs(delta)))")
                                    .font(.custom(Typography.geistMono, size: 11))
                                    .foregroundStyle(isGood ? t.accent : t.danger)
                            }
                            Text(value > 0 ? Formatters.compact(value) : "–")
                                .font(Typography.number(15))
                                .foregroundStyle(t.text)
                            Text("cm")
                                .font(.custom(Typography.geistMono, size: 11))
                                .foregroundStyle(t.textMuted)
                        }
                    }
                    .padding(.horizontal, Spacing.l).padding(.vertical, 12)
                    if type != primaryTypes.last {
                        Divider().background(t.border).padding(.horizontal, Spacing.l)
                    }
                }
            }
        }
    }

    @ViewBuilder private var secondaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(secondaryTypes, id: \.self) { type in
                let value = latestValues[type] ?? 0
                Card(pad: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(type.label.uppercased())
                            .font(Typography.eyebrow).kerning(Tracking.eyebrow)
                            .foregroundStyle(t.textMuted)
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text(value > 0 ? Formatters.compact(value) : "–")
                                .font(Typography.number(18))
                                .foregroundStyle(t.text)
                            if value > 0 {
                                Text("cm")
                                    .font(.custom(Typography.geistMono, size: 11))
                                    .foregroundStyle(t.textMuted)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

// MARK: - Entry sheet for all measurements at once

struct MeasurementsEntrySheet: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss

    var onSave: ([BodyMetricType: Double]) -> Void

    private let allTypes: [BodyMetricType] = [
        .chest, .waist, .hips, .biceps, .thigh, .calf,
        .shoulder, .forearm, .neck, .ankle,
    ]
    @State private var texts: [BodyMetricType: String] = [:]

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
                    Text("Maße eintragen")
                        .font(.custom(Typography.geist, size: 17).weight(.semibold))
                        .foregroundStyle(t.text)
                    Spacer()
                    Spacer().frame(width: 32)
                }
                .padding(.top, 54)
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, 20)

                Card(pad: 0) {
                    VStack(spacing: 0) {
                        ForEach(allTypes, id: \.self) { type in
                            HStack {
                                Text(type.label)
                                    .font(.custom(Typography.geist, size: 14))
                                    .foregroundStyle(t.textMid)
                                    .frame(width: 110, alignment: .leading)
                                TextField("–", text: Binding(
                                    get: { texts[type] ?? "" },
                                    set: { texts[type] = $0 }
                                ))
                                .font(Typography.number(15))
                                .foregroundStyle(t.text)
                                .keyboardType(.decimalPad)
                                Spacer()
                                Text("cm")
                                    .font(.custom(Typography.geistMono, size: 12))
                                    .foregroundStyle(t.textMuted)
                            }
                            .padding(.horizontal, Spacing.l).padding(.vertical, 13)
                            if type != allTypes.last {
                                Divider().background(t.border).padding(.horizontal, Spacing.l)
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.xl)

                PrimaryButton(title: "Speichern") {
                    var entries: [BodyMetricType: Double] = [:]
                    for (type, text) in texts {
                        let normalized = text.replacingOccurrences(of: ",", with: ".")
                        if let val = Double(normalized), val > 0 {
                            entries[type] = val
                        }
                    }
                    if !entries.isEmpty {
                        onSave(entries)
                        dismiss()
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.top, 20)
                .padding(.bottom, Spacing.screenSafeBottom)
            }
        }
        .background(t.bg.ignoresSafeArea())
    }
}

#Preview {
    ThemedRoot {
        NavigationStack { MeasurementsView() }
    }
    .environment(AppDependencies.mock())
}
