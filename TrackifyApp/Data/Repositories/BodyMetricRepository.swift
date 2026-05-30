import Foundation

@MainActor
protocol BodyMetricRepository {
    func fetchMetrics(type: BodyMetricType, limit: Int) async throws -> [BodyMetric]
    func latestMetric(type: BodyMetricType) async throws -> BodyMetric?
    func save(_ metric: BodyMetric) async throws
    func delete(_ metric: BodyMetric) async throws
}
