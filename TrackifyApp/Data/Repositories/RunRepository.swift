import Foundation

@MainActor
protocol RunRepository {
    func fetchRuns(limit: Int) async throws -> [Run]
    func fetchRun(id: UUID) async throws -> Run?
    func save(_ run: Run) async throws
    func delete(_ run: Run) async throws
    func monthlySummary(year: Int, month: Int) async throws -> RunMonthlySummary
}

struct RunMonthlySummary {
    var totalDistanceM: Double
    var count: Int
    var weeklyDistances: [Double]
    var avgPaceSecPerKm: Int
}
