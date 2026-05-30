import SwiftUI
import HealthKit

struct ConnectedDevicesView: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hkWeightSync")    private var hkWeightSync    = false
    @AppStorage("hkHeartRate")     private var hkHeartRate     = false
    @AppStorage("hkWorkoutExport") private var hkWorkoutExport = false

    @State private var hkAvailable = HKHealthStore.isHealthDataAvailable()
    @State private var requestingAuth = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ScreenHeader(title: "Verbundene Geräte", back: "Profil", onBack: { dismiss() })

                appleHealthCard
                    .padding(.horizontal, Spacing.xl)

                SectionHead(label: "Geplant").padding(.top, 18)

                VStack(spacing: 8) {
                    futureRow(icon: "applewatch", label: "Apple Watch", sub: "Herzfrequenz & Aktivität")
                    futureRow(icon: "sensor.tag.radiowaves.forward", label: "Garmin / Polar", sub: "Run-Import via .FIT")
                    futureRow(icon: "figure.run.circle", label: "Strava", sub: "Lauf-Sync")
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.screenSafeBottom)
            }
        }
        .background(t.bg.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    @ViewBuilder private var appleHealthCard: some View {
        Card(pad: 0) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.red)
                        .frame(width: 40, height: 40)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(t.surface2))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Apple Health")
                            .font(.custom(Typography.geist, size: 16).weight(.semibold))
                            .foregroundStyle(t.text)
                        Text("iOS Gesundheits-App")
                            .font(.custom(Typography.geistMono, size: 11))
                            .foregroundStyle(t.textMuted)
                    }
                    Spacer()
                    if hkAvailable {
                        Text(anyEnabled ? "Aktiv" : "Bereit")
                            .font(.custom(Typography.geistMono, size: 11).weight(.semibold))
                            .foregroundStyle(anyEnabled ? t.accent : t.textMuted)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Capsule().fill(anyEnabled ? t.accent.opacity(0.12) : t.surface2))
                    } else {
                        Text("Nicht verfügbar")
                            .font(.custom(Typography.geistMono, size: 11))
                            .foregroundStyle(t.danger)
                    }
                }
                .padding(.horizontal, Spacing.l).padding(.vertical, 14)

                if hkAvailable {
                    Divider().background(t.border).padding(.horizontal, Spacing.l)
                    hkToggleRow(icon: "scalemass",        label: "Gewicht lesen & schreiben",
                                isOn: $hkWeightSync,    onChange: { requestHKIfNeeded() })
                    Divider().background(t.border).padding(.horizontal, Spacing.l)
                    hkToggleRow(icon: "heart.text.square", label: "Herzfrequenz (bei Läufen)",
                                isOn: $hkHeartRate,     onChange: { requestHKIfNeeded() })
                    Divider().background(t.border).padding(.horizontal, Spacing.l)
                    hkToggleRow(icon: "dumbbell",          label: "Workouts exportieren",
                                isOn: $hkWorkoutExport, onChange: { requestHKIfNeeded() })

                    Divider().background(t.border).padding(.horizontal, Spacing.l)

                    Button {
                        if let url = URL(string: "x-apple-health://") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Text("In Health-App öffnen")
                                .font(.custom(Typography.geist, size: 14))
                                .foregroundStyle(t.text)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 14))
                                .foregroundStyle(t.textMuted)
                        }
                        .padding(.horizontal, Spacing.l).padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                } else {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(t.textMuted)
                        Text("Apple Health ist auf diesem Gerät nicht verfügbar.")
                            .font(.custom(Typography.geistMono, size: 12))
                            .foregroundStyle(t.textMuted)
                    }
                    .padding(.horizontal, Spacing.l).padding(.vertical, 14)
                }
            }
        }
    }

    private var anyEnabled: Bool { hkWeightSync || hkHeartRate || hkWorkoutExport }

    private func requestHKIfNeeded() {
        guard hkAvailable && !requestingAuth else { return }
        requestingAuth = true
        Task {
            _ = await HealthKitService.shared.requestAuthorization()
            requestingAuth = false
        }
    }

    @ViewBuilder private func hkToggleRow(icon: String, label: String,
                                          isOn: Binding<Bool>, onChange: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(t.textMid)
                .frame(width: 24)
            Text(label)
                .font(.custom(Typography.geist, size: 14))
                .foregroundStyle(t.text)
            Spacer()
            Toggle("", isOn: isOn)
                .tint(t.accent)
                .labelsHidden()
                .onChange(of: isOn.wrappedValue) { _, newVal in
                    if newVal { onChange() }
                }
        }
        .padding(.horizontal, Spacing.l).padding(.vertical, 12)
    }

    @ViewBuilder private func futureRow(icon: String, label: String, sub: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(t.textMuted)
                .frame(width: 40, height: 40)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(t.surface))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(t.border, lineWidth: 1))
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.custom(Typography.geist, size: 14).weight(.medium))
                    .foregroundStyle(t.textMid)
                Text(sub)
                    .font(.custom(Typography.geistMono, size: 11))
                    .foregroundStyle(t.textMuted)
            }
            Spacer()
            Text("Bald")
                .font(.custom(Typography.geistMono, size: 10))
                .foregroundStyle(t.textMuted)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .overlay(Capsule().stroke(t.border, lineWidth: 1))
        }
        .padding(.horizontal, Spacing.l).padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: Radii.row, style: .continuous).fill(t.surface))
        .overlay(RoundedRectangle(cornerRadius: Radii.row, style: .continuous).stroke(t.border, lineWidth: 1))
    }
}

#Preview {
    ThemedRoot {
        NavigationStack { ConnectedDevicesView() }
    }
}
