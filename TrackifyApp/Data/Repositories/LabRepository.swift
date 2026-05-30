import Foundation

@MainActor
protocol LabRepository {
    func fetchMeasurements(limit: Int) async throws -> [LabMeasurement]
    func latestMeasurement() async throws -> LabMeasurement?
    func save(_ measurement: LabMeasurement) async throws
    func delete(_ measurement: LabMeasurement) async throws
    func fetchValues(marker: String) async throws -> [LabValue]
}
