import Foundation

@MainActor
protocol SupplementRepository {
    func fetchSupplements() async throws -> [Supplement]
    func fetchSupplement(id: UUID) async throws -> Supplement?
    func save(_ supplement: Supplement) async throws
    func delete(_ supplement: Supplement) async throws
    func recordIntake(supplementID: UUID, takenAt: Date) async throws
    func todayIntakes() async throws -> [SupplementIntake]
    func streakDays() async throws -> Int
    func fetchIntakes(supplementID: UUID, limit: Int) async throws -> [SupplementIntake]
    func clearIntake(supplementID: UUID) async throws
}
