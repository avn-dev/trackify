import Foundation
import SwiftData

@MainActor
final class SwiftDataRunRepository: RunRepository {
    private let context: ModelContext

    init(context: ModelContext) { self.context = context }

    func fetchRuns(limit: Int) throws -> [Run] {
        var descriptor = FetchDescriptor<Run>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor)
    }

    func fetchRun(id: UUID) throws -> Run? {
        let descriptor = FetchDescriptor<Run>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first
    }

    func save(_ run: Run) throws {
        context.insert(run)
        try context.save()
    }

    func delete(_ run: Run) throws {
        context.delete(run)
        try context.save()
    }

    func monthlySummary(year: Int, month: Int) throws -> RunMonthlySummary {
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = 1
        let cal = Calendar.current
        guard let start = cal.date(from: comps),
              let end = cal.date(byAdding: .month, value: 1, to: start) else {
            return RunMonthlySummary(totalDistanceM: 0, count: 0, weeklyDistances: [], avgPaceSecPerKm: 0)
        }

        let descriptor = FetchDescriptor<Run>(
            predicate: #Predicate { $0.startedAt >= start && $0.startedAt < end }
        )
        let monthRuns = try context.fetch(descriptor)

        let totalDist = monthRuns.reduce(0) { $0 + $1.distanceM }
        let avgPace = monthRuns.isEmpty ? 0 : monthRuns.reduce(0) { $0 + $1.paceSecPerKm } / monthRuns.count

        // Weekly buckets (up to 5 weeks)
        var weekly = [Double](repeating: 0, count: 5)
        for run in monthRuns {
            let weekOffset = cal.component(.weekOfMonth, from: run.startedAt) - 1
            let idx = min(max(weekOffset, 0), 4)
            weekly[idx] += run.distanceM / 1000
        }

        return RunMonthlySummary(
            totalDistanceM: totalDist,
            count: monthRuns.count,
            weeklyDistances: weekly,
            avgPaceSecPerKm: avgPace
        )
    }
}
