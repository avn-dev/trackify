import SwiftUI

struct LabAddView: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    @Environment(AppDependencies.self) private var deps

    @State private var method = 0 // 0=Foto 1=PDF 2=Manuell 3=HL7
    @State private var detectedValues: [DetectedValue] = []
    @State private var showScanner = false
    @State private var showDocumentPicker = false
    @State private var manualInputs: [String: String] = [:]
    @State private var sourceText = "Hausarzt"
    @State private var measurementDate = Date()

    private let methods = [
        ("Foto",         "camera.fill"),
        ("PDF",          "doc.fill"),
        ("Manuell",      "square.and.pencil"),
        ("HL7 / Praxis", "network"),
    ]

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
                    Text("Neue Messung")
                        .font(.custom(Typography.geist, size: 17).weight(.semibold))
                        .foregroundStyle(t.text)
                    Spacer()
                    Spacer().frame(width: 32)
                }
                .padding(.top, 54)
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, 20)

                methodPicker.padding(.horizontal, Spacing.xl)

                if method == 2 {
                    manualForm
                } else if method == 3 {
                    hl7Placeholder.padding(.horizontal, Spacing.xl).padding(.top, 16)
                } else {
                    cameraPreview.padding(.horizontal, Spacing.xl).padding(.top, 16)
                    detectedSection.padding(.top, 24)
                }

                PrimaryButton(title: "Werte speichern") { Task { await save() } }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, 20)
                    .padding(.bottom, Spacing.screenSafeBottom)
            }
        }
        .background(t.bg.ignoresSafeArea())
        .sheet(isPresented: $showScanner) {
            DocumentScannerView(
                onCapture: { lines in
                    detectedValues = parseLabText(lines)
                    showScanner = false
                },
                onCancel: { showScanner = false }
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPickerView(
                onPick: { lines in
                    detectedValues = parseLabText(lines)
                    showDocumentPicker = false
                },
                onCancel: { showDocumentPicker = false }
            )
        }
    }

    // MARK: - Save

    private func save() async {
        let measurement = LabMeasurement(userID: .localUser, takenAt: measurementDate, source: sourceText)
        if method == 2 {
            // Manual: iterate known markers
            for def in LabMarkerDef.all {
                let text = manualInputs[def.marker] ?? ""
                let normalized = text.replacingOccurrences(of: ",", with: ".")
                guard let val = Double(normalized), val > 0 else { continue }
                let lv = LabValue(measurementID: measurement.id, marker: def.marker,
                                  value: val, unit: def.unit,
                                  refLow: def.refLow, refHigh: def.refHigh,
                                  category: def.category)
                measurement.values.append(lv)
            }
        } else {
            // Foto/PDF/HL7: save approved detected values
            for dv in detectedValues where dv.approved {
                guard let val = Double(dv.value), val > 0 else { continue }
                let def = LabMarkerDef.find(dv.marker)
                let lv = LabValue(measurementID: measurement.id, marker: dv.marker,
                                  value: val, unit: dv.unit,
                                  refLow: def?.refLow ?? 0, refHigh: def?.refHigh ?? 999,
                                  category: def?.category ?? "Sonstiges")
                measurement.values.append(lv)
            }
        }
        guard !measurement.values.isEmpty else { return }
        try? await deps.lab.save(measurement)
        dismiss()
    }

    // MARK: - Method picker

    @ViewBuilder private var methodPicker: some View {
        HStack(spacing: 8) {
            ForEach(methods.indices, id: \.self) { i in
                Button {
                    withAnimation(.easeOut(duration: 0.18)) {
                        method = i
                        detectedValues = []
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: methods[i].1)
                            .font(.system(size: 20))
                            .foregroundStyle(method == i ? t.accent : t.textMid)
                        Text(methods[i].0)
                            .font(.custom(Typography.geist, size: 11))
                            .foregroundStyle(method == i ? t.text : t.textMuted)
                    }
                    .frame(maxWidth: .infinity, minHeight: 72)
                    .background(
                        RoundedRectangle(cornerRadius: Radii.cardSmall, style: .continuous)
                            .fill(method == i ? t.surface : t.surface2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Radii.cardSmall, style: .continuous)
                            .stroke(method == i ? t.accent : t.border, lineWidth: method == i ? 1.5 : 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Camera preview (Foto/PDF/HL7)

    @ViewBuilder private var cameraPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Radii.card, style: .continuous)
                .fill(t.surface2.opacity(0.5))
                .frame(height: 220)

            VStack(spacing: 8) {
                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 40))
                    .foregroundStyle(t.accent)
                Text(detectedValues.isEmpty ? "Kein Scan · 0 Marker" : "Befund erkannt · \(detectedValues.count) Marker")
                    .font(.custom(Typography.geistMono, size: 12).weight(.medium))
                    .foregroundStyle(t.text)
                    .padding(.horizontal, 14).padding(.vertical, 7)
                    .background(Capsule().fill(t.surface.opacity(0.9)))
                Button {
                    if method == 1 { showDocumentPicker = true } else { showScanner = true }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: method == 1 ? "doc.fill" : "camera.fill")
                            .font(.system(size: 13))
                        Text(method == 1 ? "PDF auswählen" : "Kamera öffnen")
                            .font(.custom(Typography.geist, size: 13).weight(.medium))
                    }
                    .foregroundStyle(t.accentText)
                    .padding(.horizontal, 18).padding(.vertical, 9)
                    .background(Capsule().fill(t.accent))
                }
                .buttonStyle(.plain)
            }

            ForEach([(true, true), (true, false), (false, true), (false, false)], id: \.0) { (top, left) in
                cornerBracket(top: top, left: left)
            }
        }
    }

    @ViewBuilder private func cornerBracket(top: Bool, left: Bool) -> some View {
        let size: CGFloat = 20
        Path { p in
            if left {
                p.move(to: CGPoint(x: 0, y: size)); p.addLine(to: .zero); p.addLine(to: CGPoint(x: size, y: 0))
            } else {
                p.move(to: CGPoint(x: 0, y: 0)); p.addLine(to: CGPoint(x: size, y: 0)); p.addLine(to: CGPoint(x: size, y: size))
            }
        }
        .stroke(t.accent, style: StrokeStyle(lineWidth: 2, lineCap: .round))
        .frame(width: size, height: size)
        .frame(maxWidth: .infinity, maxHeight: .infinity,
               alignment: Alignment(horizontal: left ? .leading : .trailing, vertical: top ? .top : .bottom))
        .padding(20)
    }

    // MARK: - OCR parser

    private func parseLabText(_ lines: [String]) -> [DetectedValue] {
        var results: [DetectedValue] = []
        let joined = lines.joined(separator: "\n")
        for def in LabMarkerDef.all {
            let escaped = NSRegularExpression.escapedPattern(for: def.marker)
            let pattern = "(?i)\(escaped)[^\\d\\n]{0,30}([0-9]+[,.]?[0-9]*)"
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: joined, range: NSRange(joined.startIndex..., in: joined)),
                  let range = Range(match.range(at: 1), in: joined) else { continue }
            let raw = String(joined[range]).replacingOccurrences(of: ",", with: ".")
            guard Double(raw) != nil else { continue }
            results.append(DetectedValue(marker: def.marker, value: raw, unit: def.unit))
        }
        return results
    }

    // MARK: - Detected values list

    @ViewBuilder private var detectedSection: some View {
        VStack(spacing: 0) {
            SectionHead(label: "Erkannte Werte")
            if detectedValues.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 22))
                        .foregroundStyle(t.textMuted)
                    Text("Noch keine Werte erkannt.\nBitte Dokument scannen.")
                        .font(.custom(Typography.geist, size: 13))
                        .foregroundStyle(t.textMuted)
                        .lineSpacing(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.l)
                .padding(.horizontal, Spacing.xl)
            } else {
                Card(pad: 0) {
                    VStack(spacing: 0) {
                        ForEach($detectedValues) { $v in
                            HStack(spacing: 12) {
                                Button {
                                    withAnimation(.spring(duration: 0.2)) { v.approved.toggle() }
                                } label: {
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .fill(v.approved ? t.accent : t.surface2)
                                        .frame(width: 18, height: 18)
                                        .overlay(
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundStyle(t.accentText)
                                                .opacity(v.approved ? 1 : 0)
                                        )
                                }
                                .buttonStyle(.plain)
                                Text(v.marker)
                                    .font(.custom(Typography.geist, size: 14))
                                    .foregroundStyle(t.text)
                                Spacer()
                                Text("\(v.value) \(v.unit)")
                                    .font(Typography.number(13))
                                    .foregroundStyle(t.textMid)
                            }
                            .padding(.horizontal, Spacing.l).padding(.vertical, 12)
                            if v.id != detectedValues.last?.id {
                                Divider().background(t.border).padding(.horizontal, Spacing.l)
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.xl)
            }
        }
    }

    // MARK: - HL7 placeholder

    @ViewBuilder private var hl7Placeholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "network")
                .font(.system(size: 44))
                .foregroundStyle(t.textMuted)
            Text("Praxis-Anbindung")
                .font(.custom(Typography.geist, size: 17).weight(.semibold))
                .foregroundStyle(t.text)
            Text("HL7 FHIR / LabConnect-Import\nkommt in der nächsten Version.")
                .font(.custom(Typography.geist, size: 14))
                .foregroundStyle(t.textMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: Radii.card, style: .continuous)
                .fill(t.surface2.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radii.card, style: .continuous)
                .stroke(t.border, lineWidth: 1)
        )
    }

    // MARK: - Manual form

    @ViewBuilder private var manualForm: some View {
        VStack(spacing: 0) {
            Card(pad: 0) {
                VStack(spacing: 0) {
                    HStack {
                        Text("Quelle")
                            .font(.custom(Typography.geist, size: 14))
                            .foregroundStyle(t.textMid)
                            .frame(width: 72, alignment: .leading)
                        TextField("z.B. Hausarzt", text: $sourceText)
                            .font(.custom(Typography.geist, size: 15))
                            .foregroundStyle(t.text)
                        Spacer()
                    }
                    .padding(.horizontal, Spacing.l).padding(.vertical, 14)

                    Divider().background(t.border).padding(.horizontal, Spacing.l)

                    DatePicker(
                        "Datum",
                        selection: $measurementDate,
                        in: ...Date.now,
                        displayedComponents: .date
                    )
                    .font(.custom(Typography.geist, size: 14))
                    .foregroundStyle(t.textMid)
                    .tint(t.accent)
                    .padding(.horizontal, Spacing.l).padding(.vertical, 10)
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, 16)

            ForEach(LabMarkerDef.categories, id: \.name) { cat in
                SectionHead(label: cat.name).padding(.top, 18)
                Card(pad: 0) {
                    VStack(spacing: 0) {
                        ForEach(cat.markers, id: \.marker) { def in
                            HStack(spacing: 8) {
                                Text(def.marker)
                                    .font(.custom(Typography.geist, size: 13))
                                    .foregroundStyle(t.textMid)
                                    .frame(minWidth: 100, alignment: .leading)
                                TextField("–", text: Binding(
                                    get: { manualInputs[def.marker] ?? "" },
                                    set: { manualInputs[def.marker] = $0 }
                                ))
                                .font(Typography.number(14))
                                .foregroundStyle(t.text)
                                .keyboardType(.decimalPad)
                                Spacer()
                                Text(def.unit)
                                    .font(.custom(Typography.geistMono, size: 11))
                                    .foregroundStyle(t.textMuted)
                                    .frame(width: 54, alignment: .trailing)
                            }
                            .padding(.horizontal, Spacing.l).padding(.vertical, 11)
                            if def.marker != cat.markers.last?.marker {
                                Divider().background(t.border).padding(.horizontal, Spacing.l)
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.xl)
            }
        }
    }
}

// MARK: - DetectedValue model

struct DetectedValue: Identifiable {
    let id = UUID()
    var marker: String
    var value: String
    var unit: String
    var approved: Bool = true
}

// MARK: - Lab marker reference table

struct LabMarkerDef {
    let marker: String
    let unit: String
    let refLow: Double
    let refHigh: Double
    let category: String

    struct Category {
        let name: String
        let markers: [LabMarkerDef]
    }

    static func find(_ marker: String) -> LabMarkerDef? {
        all.first { $0.marker.lowercased() == marker.lowercased() }
    }

    static let categories: [Category] = [
        Category(name: "Vitamine & Mineralstoffe", markers: [
            LabMarkerDef(marker: "Vitamin D",   unit: "ng/mL", refLow: 30,  refHigh: 70,   category: "Vitamine & Mineralstoffe"),
            LabMarkerDef(marker: "Vitamin B12",  unit: "pg/mL", refLow: 200, refHigh: 900,  category: "Vitamine & Mineralstoffe"),
            LabMarkerDef(marker: "Ferritin",     unit: "µg/L",  refLow: 30,  refHigh: 300,  category: "Vitamine & Mineralstoffe"),
            LabMarkerDef(marker: "Magnesium",    unit: "mmol/L",refLow: 0.7, refHigh: 1.05, category: "Vitamine & Mineralstoffe"),
            LabMarkerDef(marker: "Zink",         unit: "µmol/L",refLow: 9.0, refHigh: 19.0, category: "Vitamine & Mineralstoffe"),
        ]),
        Category(name: "Blutfette", markers: [
            LabMarkerDef(marker: "LDL",          unit: "mmol/L",refLow: 0,   refHigh: 3.4,  category: "Blutfette"),
            LabMarkerDef(marker: "HDL",          unit: "mmol/L",refLow: 1.0, refHigh: 99,   category: "Blutfette"),
            LabMarkerDef(marker: "Triglyzeride", unit: "mmol/L",refLow: 0,   refHigh: 1.7,  category: "Blutfette"),
            LabMarkerDef(marker: "Gesamtcholesterin", unit: "mmol/L", refLow: 0, refHigh: 5.2, category: "Blutfette"),
        ]),
        Category(name: "Hormone", markers: [
            LabMarkerDef(marker: "Testosteron",  unit: "nmol/L",refLow: 9.9, refHigh: 27.8, category: "Hormone"),
            LabMarkerDef(marker: "TSH",          unit: "µU/mL", refLow: 0.4, refHigh: 4.0,  category: "Hormone"),
            LabMarkerDef(marker: "Cortisol",     unit: "nmol/L",refLow: 170, refHigh: 630,  category: "Hormone"),
            LabMarkerDef(marker: "IGF-1",        unit: "nmol/L",refLow: 11,  refHigh: 36,   category: "Hormone"),
        ]),
        Category(name: "Blutbild", markers: [
            LabMarkerDef(marker: "Hämoglobin",   unit: "g/dL",  refLow: 13.5,refHigh: 17.5, category: "Blutbild"),
            LabMarkerDef(marker: "Hematokrit",   unit: "%",     refLow: 40,  refHigh: 52,   category: "Blutbild"),
            LabMarkerDef(marker: "Leukozyten",   unit: "G/L",   refLow: 4.0, refHigh: 10.0, category: "Blutbild"),
            LabMarkerDef(marker: "Thrombozyten", unit: "G/L",   refLow: 150, refHigh: 400,  category: "Blutbild"),
            LabMarkerDef(marker: "CRP",          unit: "mg/L",  refLow: 0,   refHigh: 5.0,  category: "Blutbild"),
        ]),
        Category(name: "Niere & Leber", markers: [
            LabMarkerDef(marker: "Kreatinin",    unit: "µmol/L",refLow: 62,  refHigh: 115,  category: "Niere & Leber"),
            LabMarkerDef(marker: "GFR",          unit: "mL/min",refLow: 60,  refHigh: 999,  category: "Niere & Leber"),
            LabMarkerDef(marker: "ALT (GPT)",    unit: "U/L",   refLow: 0,   refHigh: 45,   category: "Niere & Leber"),
            LabMarkerDef(marker: "AST (GOT)",    unit: "U/L",   refLow: 0,   refHigh: 35,   category: "Niere & Leber"),
            LabMarkerDef(marker: "GGT",          unit: "U/L",   refLow: 0,   refHigh: 55,   category: "Niere & Leber"),
        ]),
    ]

    static let all: [LabMarkerDef] = categories.flatMap(\.markers)
}

#Preview {
    ThemedRoot { LabAddView() }
        .environment(AppDependencies.mock())
}
