import SwiftUI

struct UnitsView: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss

    @AppStorage("unitsKg") private var unitsKg = true
    @AppStorage("unitsKm") private var unitsKm = true

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ScreenHeader(title: "Einheiten", back: "Profil", onBack: { dismiss() })

                SectionHead(label: "Gewicht").padding(.top, 4)

                Card(pad: 0) {
                    VStack(spacing: 0) {
                        unitOption(label: "Kilogramm", sub: "kg", selected: unitsKg) { unitsKg = true }
                        Divider().background(t.border).padding(.horizontal, Spacing.l)
                        unitOption(label: "Pfund", sub: "lbs", selected: !unitsKg) { unitsKg = false }
                    }
                }
                .padding(.horizontal, Spacing.xl)

                SectionHead(label: "Distanz").padding(.top, 18)

                Card(pad: 0) {
                    VStack(spacing: 0) {
                        unitOption(label: "Kilometer", sub: "km", selected: unitsKm) { unitsKm = true }
                        Divider().background(t.border).padding(.horizontal, Spacing.l)
                        unitOption(label: "Meilen", sub: "mi", selected: !unitsKm) { unitsKm = false }
                    }
                }
                .padding(.horizontal, Spacing.xl)

                Text("Änderungen gelten ab sofort für alle neuen Einträge.")
                    .font(.custom(Typography.geistMono, size: 11))
                    .foregroundStyle(t.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, 20)

                Spacer().frame(height: Spacing.screenSafeBottom)
            }
        }
        .background(t.bg.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    @ViewBuilder private func unitOption(label: String, sub: String, selected: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.custom(Typography.geist, size: 15))
                        .foregroundStyle(t.text)
                    Text(sub)
                        .font(.custom(Typography.geistMono, size: 12))
                        .foregroundStyle(t.textMuted)
                }
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(t.accent)
                }
            }
            .padding(.horizontal, Spacing.l).padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ThemedRoot {
        NavigationStack { UnitsView() }
    }
}
