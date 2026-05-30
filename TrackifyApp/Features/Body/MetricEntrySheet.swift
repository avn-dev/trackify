import SwiftUI

/// Simple numeric-input sheet for logging a single body metric.
struct MetricEntrySheet: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss

    var type: BodyMetricType
    var onSave: (Double) -> Void

    @State private var text = ""

    private var placeholder: String {
        switch type {
        case .weight:  return "72,4"
        case .bodyFat: return "14,8"
        default:       return "80"
        }
    }

    var body: some View {
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
                Text(type.label + " eintragen")
                    .font(.custom(Typography.geist, size: 17).weight(.semibold))
                    .foregroundStyle(t.text)
                Spacer()
                Spacer().frame(width: 32)
            }
            .padding(.top, 54)
            .padding(.horizontal, Spacing.xl)

            Spacer()

            VStack(spacing: 6) {
                TextField(placeholder, text: $text)
                    .font(Typography.number(56))
                    .multilineTextAlignment(.center)
                    .keyboardType(.decimalPad)
                    .foregroundStyle(t.text)
                Text(type.unit)
                    .font(.custom(Typography.geistMono, size: 18))
                    .foregroundStyle(t.textMuted)
            }

            Spacer()

            PrimaryButton(title: "Speichern") {
                let normalized = text.replacingOccurrences(of: ",", with: ".")
                if let value = Double(normalized), value > 0 {
                    onSave(value)
                    dismiss()
                }
            }
            .disabled(text.isEmpty)
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.screenSafeBottom)
        }
        .background(t.bg.ignoresSafeArea())
    }
}

#Preview {
    ThemedRoot {
        MetricEntrySheet(type: .weight) { v in print(v) }
    }
}
