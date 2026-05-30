import SwiftUI

struct GoalsView: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss

    @AppStorage("goalWeightKg")        private var goalWeightKg        = 70.0
    @AppStorage("goalHeightCm")        private var goalHeightCm        = 178.0
    @AppStorage("goal5kSec")           private var goal5kSec           = 1500  // 25:00
    @AppStorage("goalWorkoutsPerWeek") private var goalWorkoutsPerWeek = 4

    @State private var weightText  = ""
    @State private var heightText  = ""
    @State private var paceMinText = ""
    @State private var paceSecText = ""
    @State private var saved = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ScreenHeader(title: "Ziele", back: "Profil", onBack: { dismiss() })

                SectionHead(label: "Körper").padding(.top, 4)

                Card(pad: 0) {
                    VStack(spacing: 0) {
                        formRow(label: "Zielgewicht") {
                            HStack(spacing: 4) {
                                TextField("70", text: $weightText)
                                    .keyboardType(.decimalPad)
                                    .font(Typography.number(15))
                                    .foregroundStyle(t.text)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 64)
                                Text("kg")
                                    .font(.custom(Typography.geistMono, size: 13))
                                    .foregroundStyle(t.textMuted)
                            }
                        }
                        Divider().background(t.border).padding(.horizontal, Spacing.l)
                        formRow(label: "Körpergröße") {
                            HStack(spacing: 4) {
                                TextField("178", text: $heightText)
                                    .keyboardType(.numberPad)
                                    .font(Typography.number(15))
                                    .foregroundStyle(t.text)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 64)
                                Text("cm")
                                    .font(.custom(Typography.geistMono, size: 13))
                                    .foregroundStyle(t.textMuted)
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.xl)

                SectionHead(label: "Training").padding(.top, 18)

                Card(pad: 0) {
                    formRow(label: "Workouts / Woche") {
                        HStack(spacing: 10) {
                            Button {
                                if goalWorkoutsPerWeek > 1 { goalWorkoutsPerWeek -= 1 }
                            } label: {
                                Image(systemName: "minus")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(t.text)
                                    .frame(width: 28, height: 28)
                                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(t.surface2))
                            }
                            .buttonStyle(.plain)
                            Text("\(goalWorkoutsPerWeek)")
                                .font(Typography.number(16))
                                .foregroundStyle(t.accent)
                                .frame(width: 24, alignment: .center)
                            Button {
                                if goalWorkoutsPerWeek < 7 { goalWorkoutsPerWeek += 1 }
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(t.text)
                                    .frame(width: 28, height: 28)
                                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(t.surface2))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, Spacing.xl)

                SectionHead(label: "Laufen").padding(.top, 18)

                Card(pad: 0) {
                    formRow(label: "5K-Ziel") {
                        HStack(spacing: 2) {
                            TextField("25", text: $paceMinText)
                                .keyboardType(.numberPad)
                                .font(Typography.number(15))
                                .foregroundStyle(t.text)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 36)
                            Text(":")
                                .font(Typography.number(15))
                                .foregroundStyle(t.textMuted)
                            TextField("00", text: $paceSecText)
                                .keyboardType(.numberPad)
                                .font(Typography.number(15))
                                .foregroundStyle(t.text)
                                .frame(width: 36)
                            Text("min")
                                .font(.custom(Typography.geistMono, size: 13))
                                .foregroundStyle(t.textMuted)
                        }
                    }
                }
                .padding(.horizontal, Spacing.xl)

                if saved {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(t.accent)
                        Text("Gespeichert")
                            .font(.custom(Typography.geistMono, size: 13))
                            .foregroundStyle(t.textMuted)
                    }
                    .padding(.top, 20)
                } else {
                    PrimaryButton(title: "Speichern") { saveGoals() }
                        .padding(.horizontal, Spacing.xl)
                        .padding(.top, 24)
                }

                Spacer().frame(height: Spacing.screenSafeBottom)
            }
        }
        .background(t.bg.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear { loadValues() }
    }

    private func loadValues() {
        weightText  = formatDecimal(goalWeightKg)
        heightText  = String(Int(goalHeightCm))
        let mins    = goal5kSec / 60
        let secs    = goal5kSec % 60
        paceMinText = "\(mins)"
        paceSecText = String(format: "%02d", secs)
    }

    private func saveGoals() {
        let normalized = weightText.replacingOccurrences(of: ",", with: ".")
        if let w = Double(normalized), w > 0 { goalWeightKg = w }
        if let h = Double(heightText), h > 0  { goalHeightCm = h }
        let mins = Int(paceMinText) ?? (goal5kSec / 60)
        let secs = Int(paceSecText) ?? (goal5kSec % 60)
        goal5kSec = mins * 60 + secs
        withAnimation { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { saved = false }
        }
    }

    @ViewBuilder private func formRow<C: View>(label: String, @ViewBuilder content: () -> C) -> some View {
        HStack {
            Text(label)
                .font(.custom(Typography.geist, size: 15))
                .foregroundStyle(t.text)
            Spacer()
            content()
        }
        .padding(.horizontal, Spacing.l).padding(.vertical, 14)
    }

    private func formatDecimal(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", v)
            : String(format: "%.1f", v).replacingOccurrences(of: ".", with: ",")
    }
}

#Preview {
    ThemedRoot {
        NavigationStack { GoalsView() }
    }
}
