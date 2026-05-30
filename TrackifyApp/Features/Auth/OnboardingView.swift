import SwiftUI

struct OnboardingView: View {
    @Environment(\.theme) private var t
    var onFinish: () -> Void

    @State private var page = 0

    private let pages: [(title: String, body: String)] = [
        ("Trainier smarter,\nnicht härter.", "Erfasse jeden Satz, jeden RIR, jede Wiederholung – und sieh deinen Fortschritt in Echtzeit."),
        ("Sieh dein Training.\nSchwarz auf weiß.", "Volumen, RIR, 1RM-Schätzung – alles automatisch ausgewertet, ohne Tabellen-Gefummel."),
        ("Alles an einem Ort.", "Training, Läufe, Körpermaße, Blutwerte, Supplements – dein komplettes Health-Tracking."),
    ]

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("\(String(format: "%02d", page + 1)) / 03")
                        .font(Typography.eyebrow).kerning(1)
                        .foregroundStyle(t.textMuted)
                    Spacer()
                    Button("Überspringen") { onFinish() }
                        .font(.custom(Typography.geist, size: 14))
                        .foregroundStyle(t.textMid)
                }
                .padding(.top, 64)
                .padding(.horizontal, Spacing.xl)

                previewCard
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, 32)

                Spacer()

                VStack(alignment: .leading, spacing: 12) {
                    Text(pages[page].title)
                        .font(.custom(Typography.geist, size: 30).weight(.semibold))
                        .kerning(-1)
                        .foregroundStyle(t.text)
                    Text(pages[page].body)
                        .font(Typography.body)
                        .foregroundStyle(t.textMid)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.xl)
                .animation(.easeInOut, value: page)

                HStack {
                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { i in
                            Capsule()
                                .fill(i == page ? t.accent : t.borderStrong)
                                .frame(width: i == page ? 22 : 6, height: 6)
                                .animation(.spring(duration: 0.3), value: page)
                        }
                    }
                    Spacer()
                    Button {
                        if page < 2 {
                            withAnimation { page += 1 }
                        } else {
                            onFinish()
                        }
                    } label: {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(t.accentText)
                            .frame(width: 64, height: 52)
                            .background(Capsule().fill(t.accent))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, 60)
            }
        }
        .navigationBarHidden(true)
    }

    @ViewBuilder private var previewCard: some View {
        Card(pad: 22) {
            HStack {
                Eyebrow(text: "Volumen · 4 Wochen")
                Spacer()
                Text("↑ 14%")
                    .font(.custom(Typography.geistMono, size: 11))
                    .foregroundStyle(t.accent)
            }
            Text("18.420")
                .font(Typography.number(44))
                .kerning(-1.4)
                .foregroundStyle(t.text)
                + Text(" kg")
                .font(.custom(Typography.geistMono, size: 16))
                .foregroundStyle(t.textMuted)

            TrackifyLineChart(
                data: [12, 14, 13, 17, 16, 19, 18, 22, 21, 25].enumerated().map {
                    LinePoint(x: Double($0.offset), y: $0.element)
                },
                accent: true,
                showAxis: false
            )
            .frame(height: 88)
            .padding(.top, 12)
        }
    }
}

#Preview {
    ThemedRoot { OnboardingView(onFinish: {}) }
}
