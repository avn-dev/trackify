import Foundation
import SwiftData

@MainActor
final class SwiftDataSupplementRepository: SupplementRepository {
    private let context: ModelContext

    init(context: ModelContext) { self.context = context }

    func fetchSupplements() throws -> [Supplement] {
        let descriptor = FetchDescriptor<Supplement>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try context.fetch(descriptor)
    }

    func fetchSupplement(id: UUID) throws -> Supplement? {
        let descriptor = FetchDescriptor<Supplement>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }

    func save(_ supplement: Supplement) throws {
        context.insert(supplement)
        try context.save()
    }

    func delete(_ supplement: Supplement) throws {
        context.delete(supplement)
        try context.save()
    }

    func recordIntake(supplementID: UUID, takenAt: Date) throws {
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: takenAt)
        guard let endOfDay = cal.date(byAdding: .day, value: 1, to: startOfDay) else { return }

        let existing = FetchDescriptor<SupplementIntake>(
            predicate: #Predicate {
                $0.supplementID == supplementID &&
                $0.plannedAt >= startOfDay &&
                $0.plannedAt < endOfDay
            }
        )
        var isNew = false
        if let intake = try context.fetch(existing).first {
            intake.takenAt = takenAt
            intake.skipped = false
        } else {
            let intake = SupplementIntake(
                supplementID: supplementID,
                plannedAt: startOfDay,
                takenAt: takenAt
            )
            context.insert(intake)
            isNew = true
        }

        // Decrement stock for new intakes when tracking is enabled
        if isNew {
            let supDesc = FetchDescriptor<Supplement>(
                predicate: #Predicate { $0.id == supplementID }
            )
            if let sup = try context.fetch(supDesc).first, sup.trackStock, sup.stockUnits > 0 {
                sup.stockUnits -= 1
            }
        }
        try context.save()
    }

    func todayIntakes() throws -> [SupplementIntake] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: .now)
        guard let end = cal.date(byAdding: .day, value: 1, to: start) else { return [] }
        let descriptor = FetchDescriptor<SupplementIntake>(
            predicate: #Predicate { $0.plannedAt >= start && $0.plannedAt < end }
        )
        return try context.fetch(descriptor)
    }

    func clearIntake(supplementID: UUID) throws {
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: .now)
        guard let endOfDay = cal.date(byAdding: .day, value: 1, to: startOfDay) else { return }
        let descriptor = FetchDescriptor<SupplementIntake>(
            predicate: #Predicate {
                $0.supplementID == supplementID &&
                $0.plannedAt >= startOfDay &&
                $0.plannedAt < endOfDay
            }
        )
        if let intake = try context.fetch(descriptor).first {
            intake.takenAt = nil
        }
        try context.save()
    }

    func fetchIntakes(supplementID: UUID, limit: Int) throws -> [SupplementIntake] {
        var descriptor = FetchDescriptor<SupplementIntake>(
            predicate: #Predicate { $0.supplementID == supplementID },
            sortBy: [SortDescriptor(\.plannedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor)
    }

    func streakDays() throws -> Int {
        let descriptor = FetchDescriptor<SupplementIntake>(
            sortBy: [SortDescriptor(\.plannedAt, order: .reverse)]
        )
        let intakes = try context.fetch(descriptor)
        guard !intakes.isEmpty else { return 0 }

        let cal = Calendar.current
        var streak = 0
        var checkDate = cal.startOfDay(for: .now)

        while true {
            guard let nextDay = cal.date(byAdding: .day, value: 1, to: checkDate),
                  let prevDay = cal.date(byAdding: .day, value: -1, to: checkDate) else { break }
            let hasTaken = intakes.contains {
                $0.plannedAt >= checkDate && $0.plannedAt < nextDay && $0.takenAt != nil
            }
            guard hasTaken else { break }
            streak += 1
            checkDate = prevDay
        }
        return streak
    }
}
