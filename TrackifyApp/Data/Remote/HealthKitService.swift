import Foundation
import HealthKit

@MainActor
final class HealthKitService {

    static let shared = HealthKitService()
    private let store = HKHealthStore()

    static var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    // MARK: - Authorization

    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
        ]
        if let hr = HKObjectType.quantityType(forIdentifier: .heartRate) {
            types.insert(hr)
        }
        return types
    }

    private var writeTypes: Set<HKSampleType> {
        var types: Set<HKSampleType> = []
        if let bm   = HKSampleType.quantityType(forIdentifier: .bodyMass)              { types.insert(bm) }
        if let dist = HKSampleType.quantityType(forIdentifier: .distanceWalkingRunning) { types.insert(dist) }
        if let wt   = HKSampleType.workoutType() as? HKSampleType                      { types.insert(wt) }
        return types
    }

    /// Returns true if all requested types were granted (or already authorized).
    func requestAuthorization() async -> Bool {
        guard Self.isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: writeTypes, read: readTypes)
            return authorizationStatus(for: .bodyMass) == .sharingAuthorized
        } catch {
            return false
        }
    }

    func authorizationStatus(for id: HKQuantityTypeIdentifier) -> HKAuthorizationStatus {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return .notDetermined }
        return store.authorizationStatus(for: type)
    }

    // MARK: - Weight

    /// Most recent body mass sample, in kg.
    func latestWeight() async -> (kg: Double, date: Date)? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return nil }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                let kg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                continuation.resume(returning: (kg, sample.endDate))
            }
            store.execute(query)
        }
    }

    /// Body mass samples since `since`, in kg, sorted newest-first.
    func weightHistory(since: Date) async -> [(kg: Double, date: Date)] {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: since, end: nil, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 500, sortDescriptors: [sort]) { _, samples, _ in
                let results = (samples as? [HKQuantitySample] ?? []).map {
                    ($0.quantity.doubleValue(for: .gramUnit(with: .kilo)), $0.endDate)
                }
                continuation.resume(returning: results)
            }
            store.execute(query)
        }
    }

    /// Write a single body mass entry to HealthKit.
    func saveWeight(_ kg: Double, date: Date) async {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return }
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kg)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
        try? await store.save(sample)
    }

    // MARK: - Heart rate

    /// Average heart rate (bpm) for a time interval, or nil if unavailable.
    func averageHeartRate(start: Date, end: Date) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .discreteAverage) { _, stats, _ in
                let bpm = stats?.averageQuantity()?.doubleValue(for: HKUnit(from: "count/min"))
                continuation.resume(returning: bpm)
            }
            store.execute(query)
        }
    }

    // MARK: - Workout export

    /// Write a running workout with distance to HealthKit.
    func saveRunningWorkout(start: Date, end: Date, distanceM: Double) async {
        let config = HKWorkoutConfiguration()
        config.activityType = .running
        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
        do {
            try await builder.beginCollection(at: start)
            if let distType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) {
                let qty = HKQuantity(unit: .meter(), doubleValue: distanceM)
                let sample = HKQuantitySample(type: distType, quantity: qty, start: start, end: end)
                try await builder.addSamples([sample])
            }
            try await builder.endCollection(at: end)
            try await builder.finishWorkout()
        } catch {}
    }

    /// Write a strength-training workout to HealthKit.
    func saveWorkout(start: Date, end: Date, activeCalories: Double? = nil) async {
        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
        do {
            try await builder.beginCollection(at: start)
            if let cal = activeCalories {
                let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
                let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: cal)
                let sample = HKQuantitySample(type: energyType, quantity: quantity, start: start, end: end)
                try await builder.addSamples([sample])
            }
            try await builder.endCollection(at: end)
            try await builder.finishWorkout()
        } catch {}
    }
}
