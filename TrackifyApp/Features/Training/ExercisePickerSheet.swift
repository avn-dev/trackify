import SwiftUI

struct ExercisePickerSheet: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    var onSelect: (CatalogExercise) -> Void

    @State private var search = ""
    @State private var muscleFilter: MuscleGroup? = nil

    private struct FilterOpt {
        var label: String
        var value: MuscleGroup?
    }
    private let filterOpts: [FilterOpt] = [
        .init(label: "Alle",      value: nil),
        .init(label: "Brust",     value: .chest),
        .init(label: "Rücken",    value: .back),
        .init(label: "Beine",     value: .legs),
        .init(label: "Schultern", value: .shoulders),
        .init(label: "Arme",      value: .arms),
        .init(label: "Core",      value: .core),
    ]

    private var filtered: [CatalogExercise] {
        ExerciseCatalog.filtered(muscle: muscleFilter, search: search)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                filterPills.padding(.bottom, 12)
                exerciseList
            }
            .background(t.bg.ignoresSafeArea())
            .navigationTitle("Übung wählen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                        .font(.custom(Typography.geist, size: 15))
                        .foregroundStyle(t.text)
                }
            }
        }
    }

    @ViewBuilder private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15))
                .foregroundStyle(t.textMuted)
            TextField("Übung suchen", text: $search)
                .font(.custom(Typography.geist, size: 15))
                .foregroundStyle(t.text)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(t.surface))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(t.border, lineWidth: 1))
    }

    @ViewBuilder private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filterOpts, id: \.label) { opt in
                    let isActive = muscleFilter == opt.value
                    Button {
                        withAnimation(.easeOut(duration: 0.15)) { muscleFilter = opt.value }
                    } label: {
                        Text(opt.label)
                            .font(.custom(Typography.geist, size: 13).weight(isActive ? .semibold : .regular))
                            .foregroundStyle(isActive ? t.bg : t.textMid)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(Capsule().fill(isActive ? t.text : Color.clear))
                            .overlay(isActive ? nil : Capsule().stroke(t.border, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.xl)
        }
    }

    @ViewBuilder private var exerciseList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filtered) { ex in
                    Button {
                        onSelect(ex)
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(ex.name)
                                    .font(.custom(Typography.geist, size: 15).weight(.medium))
                                    .foregroundStyle(t.text)
                                Text(ex.muscleLabel)
                                    .font(.custom(Typography.geistMono, size: 11))
                                    .foregroundStyle(t.textMuted)
                            }
                            Spacer()
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(t.textMuted)
                        }
                        .padding(.horizontal, Spacing.l).padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: Radii.row, style: .continuous).fill(t.surface))
                        .overlay(RoundedRectangle(cornerRadius: Radii.row, style: .continuous).stroke(t.border, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.screenSafeBottom)
        }
    }
}

#Preview {
    ThemedRoot { ExercisePickerSheet { _ in } }
}
