import Foundation
import SwiftData

@MainActor
final class SwiftDataLabRepository: LabRepository {
    private let context: ModelContext

    init(context: ModelContext) { self.context = context }

    func fetchMeasurements(limit: Int) throws -> [LabMeasurement] {
        var descriptor = FetchDescriptor<LabMeasurement>(
            sortBy: [SortDescriptor(\.takenAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor)
    }

    func latestMeasurement() throws -> LabMeasurement? {
        var descriptor = FetchDescriptor<LabMeasurement>(
            sortBy: [SortDescriptor(\.takenAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func save(_ measurement: LabMeasurement) throws {
        context.insert(measurement)
        try context.save()
    }

    func delete(_ measurement: LabMeasurement) throws {
        context.delete(measurement)
        try context.save()
    }

    func fetchValues(marker: String) throws -> [LabValue] {
        let descriptor = FetchDescriptor<LabValue>(
            sortBy: [SortDescriptor(\.measurementID)]
        )
        return try context.fetch(descriptor).filter { $0.marker == marker }
    }
}
