import SwiftUI
import UserNotifications

struct RemindersView: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    @Environment(AppDependencies.self) private var deps

    @State private var authStatus: UNAuthorizationStatus = .notDetermined
    @State private var supplements: [Supplement] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ScreenHeader(title: "Erinnerungen", back: "Profil", onBack: { dismiss() })

                permissionCard
                    .padding(.horizontal, Spacing.xl)

                if !supplements.filter(\.reminderOn).isEmpty {
                    SectionHead(label: "Supplement-Erinnerungen").padding(.top, 18)
                    supplementList
                        .padding(.horizontal, Spacing.xl)
                }

                Spacer().frame(height: Spacing.screenSafeBottom)
            }
        }
        .background(t.bg.ignoresSafeArea())
        .navigationBarHidden(true)
        .task { await loadData() }
    }

    private func loadData() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authStatus = settings.authorizationStatus
        supplements = (try? await deps.supplements.fetchSupplements()) ?? []
    }

    @ViewBuilder private var permissionCard: some View {
        Card(pad: Spacing.l) {
            HStack(spacing: 14) {
                Image(systemName: authStatus == .authorized ? "bell.fill" : "bell.slash.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(authStatus == .authorized ? t.accent : t.textMuted)
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(t.surface2))

                VStack(alignment: .leading, spacing: 4) {
                    Text(authStatus == .authorized ? "Benachrichtigungen aktiv" : "Benachrichtigungen gesperrt")
                        .font(.custom(Typography.geist, size: 15).weight(.semibold))
                        .foregroundStyle(t.text)
                    Text(authStatus == .authorized
                         ? "Deine Supplement-Erinnerungen werden zugestellt."
                         : "Aktiviere Benachrichtigungen in den iOS-Einstellungen.")
                        .font(.custom(Typography.geistMono, size: 12))
                        .foregroundStyle(t.textMuted)
                        .lineSpacing(2)
                }
                Spacer()
            }

            if authStatus != .authorized {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Text("Einstellungen öffnen")
                            .font(.custom(Typography.geist, size: 14).weight(.medium))
                            .foregroundStyle(t.accentText)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 14))
                            .foregroundStyle(t.accentText)
                    }
                    .padding(.horizontal, Spacing.l).padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(t.accent))
                }
                .buttonStyle(.plain)
                .padding(.top, 10)
            }
        }
    }

    @ViewBuilder private var supplementList: some View {
        Card(pad: 0) {
            let active = supplements.filter(\.reminderOn)
            ForEach(active.indices, id: \.self) { i in
                let sup = active[i]
                HStack(spacing: 12) {
                    Image(systemName: sup.kind == .medication ? "pills.fill" : "leaf.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(t.accent)
                        .frame(width: 28, height: 28)
                        .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(t.surface2))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(sup.name)
                            .font(.custom(Typography.geist, size: 14).weight(.medium))
                            .foregroundStyle(t.text)
                        Text(sup.times.sorted().joined(separator: " · "))
                            .font(.custom(Typography.geistMono, size: 11))
                            .foregroundStyle(t.textMuted)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(t.accent)
                }
                .padding(.horizontal, Spacing.l).padding(.vertical, 12)
                if i < active.count - 1 {
                    Divider().background(t.border).padding(.horizontal, Spacing.l)
                }
            }
        }
    }
}

#Preview {
    ThemedRoot {
        NavigationStack { RemindersView() }
    }
    .environment(AppDependencies.mock())
}
