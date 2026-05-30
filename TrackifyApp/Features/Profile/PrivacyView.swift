import SwiftUI

struct PrivacyView: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    @Environment(AppDependencies.self) private var deps
    @State private var showDeleteAlert = false
    @State private var deleted = false
    @State private var isDeleting = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ScreenHeader(title: "Datenschutz", back: "Profil", onBack: { dismiss() })

                VStack(spacing: 12) {
                    infoSection(
                        icon: "lock.shield",
                        title: "Lokale Datenhaltung",
                        body: "Alle deine Fitness-Daten werden ausschließlich auf deinem Gerät gespeichert. Es werden keine personenbezogenen Daten an externe Server übermittelt."
                    )
                    infoSection(
                        icon: "eye.slash",
                        title: "Keine Werbung, kein Tracking",
                        body: "Trackify enthält kein Analyse-SDK, keine Werbenetzwerke und kein verhaltensbasiertes Tracking."
                    )
                    infoSection(
                        icon: "applelogo",
                        title: "Sign in with Apple",
                        body: "Bei Nutzung von \u{201E}Anmelden mit Apple\u{201C} verarbeitet Trackify nur deine Apple-ID zur Authentifizierung. Deine E-Mail-Adresse bleibt optional."
                    )
                    infoSection(
                        icon: "heart",
                        title: "HealthKit",
                        body: "Trackify liest HealthKit-Daten (Gewicht, Herzfrequenz) nur mit deiner ausdrücklichen Erlaubnis. Du kannst den Zugriff jederzeit in den Einstellungen widerrufen."
                    )
                }
                .padding(.horizontal, Spacing.xl)

                SectionHead(label: "Daten verwalten").padding(.top, 18)

                VStack(spacing: 8) {
                    NavigationLink(value: ProfileRoute.dataExport) {
                        Card(pad: Spacing.l) {
                            HStack(spacing: 14) {
                                Image(systemName: "arrow.down.circle")
                                    .font(.system(size: 20))
                                    .foregroundStyle(t.accent)
                                    .frame(width: 36, height: 36)
                                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(t.surface2))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Daten exportieren")
                                        .font(.custom(Typography.geist, size: 15).weight(.medium))
                                        .foregroundStyle(t.text)
                                    Text("JSON-Export aller Einträge")
                                        .font(.custom(Typography.geistMono, size: 12))
                                        .foregroundStyle(t.textMuted)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(t.textMuted)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    if deleted {
                        Card(pad: Spacing.l) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(t.accent)
                                Text("Alle Daten wurden gelöscht.")
                                    .font(.custom(Typography.geistMono, size: 13))
                                    .foregroundStyle(t.textMuted)
                            }
                        }
                    } else if isDeleting {
                        Card(pad: Spacing.l) {
                            HStack(spacing: 8) {
                                ProgressView().tint(t.textMuted)
                                Text("Wird gelöscht…")
                                    .font(.custom(Typography.geistMono, size: 13))
                                    .foregroundStyle(t.textMuted)
                            }
                        }
                    } else {
                        Button {
                            showDeleteAlert = true
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "trash")
                                    .font(.system(size: 20))
                                    .foregroundStyle(t.danger)
                                    .frame(width: 36, height: 36)
                                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(t.surface2))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Alle Daten löschen")
                                        .font(.custom(Typography.geist, size: 15).weight(.medium))
                                        .foregroundStyle(t.danger)
                                    Text("Dieser Vorgang ist nicht rückgängig zu machen")
                                        .font(.custom(Typography.geistMono, size: 12))
                                        .foregroundStyle(t.textMuted)
                                }
                                Spacer()
                            }
                            .padding(Spacing.l)
                            .background(RoundedRectangle(cornerRadius: Radii.card, style: .continuous).fill(t.surface))
                            .overlay(RoundedRectangle(cornerRadius: Radii.card, style: .continuous).stroke(t.border, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.xl)

                Text("Trackify speichert keine Daten außerhalb deines Geräts ohne explizite Zustimmung.")
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
        .alert("Alle Daten löschen?", isPresented: $showDeleteAlert) {
            Button("Löschen", role: .destructive) {
                Task { await deleteAllData() }
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Alle Workouts, Läufe, Körperdaten, Laborwerte und Supplements werden unwiderruflich gelöscht.")
        }
    }

    private func deleteAllData() async {
        isDeleting = true
        let workouts = (try? await deps.workouts.fetchWorkouts(limit: 9999)) ?? []
        for w in workouts { try? await deps.workouts.delete(w) }
        let runs = (try? await deps.runs.fetchRuns(limit: 9999)) ?? []
        for r in runs { try? await deps.runs.delete(r) }
        for type in BodyMetricType.allCases {
            let metrics = (try? await deps.body.fetchMetrics(type: type, limit: 9999)) ?? []
            for m in metrics { try? await deps.body.delete(m) }
        }
        let measurements = (try? await deps.lab.fetchMeasurements(limit: 9999)) ?? []
        for m in measurements { try? await deps.lab.delete(m) }
        let supps = (try? await deps.supplements.fetchSupplements()) ?? []
        for s in supps { try? await deps.supplements.delete(s) }
        isDeleting = false
        deleted = true
    }

    @ViewBuilder private func infoSection(icon: String, title: String, body: String) -> some View {
        Card(pad: Spacing.l) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(t.accent)
                    .frame(width: 36, height: 36)
                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(t.surface2))
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.custom(Typography.geist, size: 14).weight(.semibold))
                        .foregroundStyle(t.text)
                    Text(body)
                        .font(.custom(Typography.geist, size: 13))
                        .foregroundStyle(t.textMid)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

#Preview {
    ThemedRoot {
        NavigationStack { PrivacyView() }
    }
    .environment(AppDependencies.mock())
}
