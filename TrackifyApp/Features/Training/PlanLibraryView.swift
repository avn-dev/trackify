import SwiftUI

struct PlanLibraryView: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    @AppStorage(PlanData.versionKey) private var planStoreVersion = 0

    @State private var showNewPlanEditor = false
    @State private var editingPlan: PlanConfig? = nil

    private var store: PlanStore {
        _ = planStoreVersion
        return PlanData.loadStore()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ScreenHeader(title: "Meine Pläne", eyebrow: "Training") {
                        CircleBtn(systemIcon: "plus") { showNewPlanEditor = true }
                    }

                    VStack(spacing: 10) {
                        ForEach(store.plans) { plan in
                            PlanLibraryCard(
                                plan: plan,
                                isActive: plan.id == store.activePlanID,
                                onActivate: { PlanData.setActivePlan(id: plan.id) },
                                onEdit: { editingPlan = plan },
                                onDelete: (store.plans.count > 1 && plan.id != store.activePlanID)
                                    ? { PlanData.deletePlan(id: plan.id) } : nil
                            )
                        }
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, Spacing.screenSafeBottom)
                }
            }
            .background(t.bg.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showNewPlanEditor) {
            ThemedRoot { PlanEditorView(mode: .createNew) }
        }
        .sheet(item: $editingPlan) { plan in
            ThemedRoot { PlanEditorView(mode: .update(plan)) }
        }
    }
}

// MARK: - Plan library card

struct PlanLibraryCard: View {
    @Environment(\.theme) private var t
    var plan: PlanConfig
    var isActive: Bool
    var onActivate: () -> Void
    var onEdit: () -> Void
    var onDelete: (() -> Void)?

    private var trainingDays: [PlanDay] { plan.days.filter { !$0.isRestDay } }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        if isActive {
                            Circle().fill(t.accent).frame(width: 6, height: 6)
                        }
                        Text(plan.name)
                            .font(.custom(Typography.geist, size: 16).weight(.semibold))
                            .foregroundStyle(t.text)
                    }
                    Text("\(plan.type.label) · \(trainingDays.count) Trainingstage")
                        .font(.custom(Typography.geistMono, size: 12))
                        .foregroundStyle(t.textMuted)
                }

                Spacer()

                HStack(spacing: 8) {
                    Button("Bearbeiten", action: onEdit)
                        .font(.custom(Typography.geist, size: 13))
                        .foregroundStyle(t.textMid)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(Capsule().fill(t.surface2))
                        .buttonStyle(.plain)

                    if isActive {
                        Text("Aktiv")
                            .font(.custom(Typography.geistMono, size: 11).weight(.semibold))
                            .foregroundStyle(t.accent)
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .overlay(Capsule().stroke(t.accent, lineWidth: 1))
                    } else {
                        Button("Aktivieren", action: onActivate)
                            .font(.custom(Typography.geist, size: 13).weight(.semibold))
                            .foregroundStyle(t.accentText)
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(Capsule().fill(t.accent))
                            .buttonStyle(.plain)
                    }
                }
            }
            .padding(Spacing.l)

            if !trainingDays.isEmpty {
                Rectangle().fill(t.border).frame(height: 0.5).padding(.horizontal, Spacing.l)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(trainingDays) { day in
                            Text(day.focus)
                                .font(.custom(Typography.geistMono, size: 10).weight(.medium))
                                .foregroundStyle(isActive ? t.text : t.textMid)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(isActive ? Capsule().fill(t.text.opacity(0.1)) : nil)
                        }
                    }
                    .padding(.horizontal, Spacing.l).padding(.vertical, 10)
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: Radii.card, style: .continuous).fill(t.surface))
        .overlay(
            RoundedRectangle(cornerRadius: Radii.card, style: .continuous)
                .stroke(isActive ? t.accent : t.border, lineWidth: isActive ? 1.5 : 1)
        )
        .contextMenu {
            if let onDelete {
                Button(role: .destructive, action: onDelete) {
                    Label("Plan löschen", systemImage: "trash")
                }
            }
        }
    }
}

#Preview {
    ThemedRoot { PlanLibraryView() }
}
