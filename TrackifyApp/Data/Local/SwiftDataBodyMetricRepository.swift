import Foundation
import SwiftData

@MainActor
final class SwiftDataBodyMetricRepository: BodyMetricRepository {
    private let context: ModelContext

    init(context: ModelContext) { self.context = context }

    func fetchMetrics(type: BodyMetricType, limit: Int) throws -> [BodyMetric] {
        let descriptor = FetchDescriptor<BodyMetric>(
            sortBy: [SortDescriptor(\.ts, order: .reverse)]
        )
        let all = try context.fetch(descriptor)
        return Array(all.filter { $0.type == type }.prefix(limit))
    }

    func latestMetric(type: BodyMetricType) throws -> BodyMetric? {
        let descriptor = FetchDescriptor<BodyMetric>(
            sortBy: [SortDescriptor(\.ts, order: .reverse)]
        )
        return try context.fetch(descriptor).first { $0.type == type }
    }

    func save(_ metric: BodyMetric) throws {
        context.insert(metric)
        try context.save()
    }

    func delete(_ metric: BodyMetric) throws {
        context.delete(metric)
        try context.save()
    }
}
