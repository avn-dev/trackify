import Foundation
import CoreLocation

// MARK: - Mock Workout Repository

@MainActor
final class MockWorkoutRepository: WorkoutRepository {
    private(set) var workouts: [Workout] = [
        Workout(userID: UUID(), planDay: "Tag A", startedAt: .now - 86400, endedAt: .now - 84000, volumeKg: 18420),
        Workout(userID: UUID(), planDay: "Tag B", startedAt: .now - 172800, endedAt: .now - 170000, volumeKg: 15200),
        Workout(userID: UUID(), planDay: "Tag C", startedAt: .now - 259200, endedAt: .now - 257000, volumeKg: 22100),
    ]

    func fetchWorkouts(limit: Int) async throws -> [Workout] {
        Array(workouts.prefix(limit))
    }

    func fetchWorkout(id: UUID) async throws -> Workout? {
        workouts.first { $0.id == id }
    }

    func save(_ workout: Workout) async throws {
        if let i = workouts.firstIndex(where: { $0.id == workout.id }) {
            workouts[i] = workout
        } else {
            workouts.insert(workout, at: 0)
        }
    }

    func delete(_ workout: Workout) async throws {
        workouts.removeAll { $0.id == workout.id }
    }

    func weeklyVolume() async throws -> [DayVolume] {
        let days = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
        let values: [Double] = [18420, 0, 15200, 22100, 0, 0, 0]
        let worked: [Bool]   = [true, false, true, true, false, false, false]
        let today = 4
        return zip(days, zip(values, worked)).enumerated().map { i, pair in
            DayVolume(dayLabel: pair.0, volumeKg: pair.1.0, hasWorkout: pair.1.1, isToday: i == today)
        }
    }

    func weeklyCount() async throws -> Int { 3 }

    func fetchSets(exerciseName: String, limit: Int) async throws -> [WorkoutSet] {
        let exerciseID = UUID(uuidString: "00000000-0000-0000-0001-000000000001")!
        var sets: [WorkoutSet] = []
        let sessions: [(daysAgo: Int, weights: [Double], reps: [Int])] = [
            (1,  [20, 20, 20, 20], [9, 8, 8, 7]),
            (5,  [18, 20, 20, 18], [10, 9, 8, 8]),
            (9,  [17.5, 17.5, 18, 17.5], [10, 10, 9, 8]),
            (13, [17.5, 17.5, 17.5, 17.5], [10, 10, 10, 9]),
        ]
        for session in sessions {
            let date = Date().addingTimeInterval(Double(-session.daysAgo) * 86400)
            let workoutID = UUID()
            for (i, (kg, rep)) in zip(session.weights, session.reps).enumerated() {
                sets.append(WorkoutSet(
                    workoutID: workoutID, exerciseID: exerciseID,
                    exerciseName: exerciseName, setNo: i + 1,
                    weightKg: kg, reps: rep, rir: 2, doneAt: date
                ))
            }
        }
        return Array(sets.prefix(limit))
    }

    func fetchAllSets(limit: Int) async throws -> [WorkoutSet] {
        let exercises: [(name: String, daysAgo: Int, weights: [Double], reps: [Int])] = [
            ("Schrägbank Kurzhantel", 1,  [20, 20, 20, 20],     [9, 8, 8, 7]),
            ("Schrägbank Kurzhantel", 5,  [18, 20, 20, 18],     [10, 9, 8, 8]),
            ("Schulterdrücken",       2,  [40, 40, 42.5, 42.5], [10, 8, 8, 7]),
            ("Schulterdrücken",       9,  [37.5, 40, 40, 37.5], [10, 9, 8, 8]),
            ("Kreuzheben",            3,  [100, 100, 105, 105], [5, 5, 4, 3]),
            ("Kreuzheben",            10, [95, 100, 100, 95],   [5, 5, 5, 4]),
            ("Kniebeugen",            4,  [80, 80, 85, 80],     [8, 7, 6, 8]),
            ("Bankdrücken",           6,  [60, 62.5, 65, 62.5], [8, 7, 7, 8]),
            ("Bankdrücken",           13, [57.5, 60, 60, 57.5], [8, 8, 7, 8]),
        ]
        var sets: [WorkoutSet] = []
        let baseID = UUID(uuidString: "00000000-0000-0000-0001-000000000001")!
        for ex in exercises {
            let date = Date().addingTimeInterval(Double(-ex.daysAgo) * 86400)
            let workoutID = UUID()
            for (i, (kg, rep)) in zip(ex.weights, ex.reps).enumerated() {
                sets.append(WorkoutSet(
                    workoutID: workoutID, exerciseID: baseID,
                    exerciseName: ex.name, setNo: i + 1,
                    weightKg: kg, reps: rep, rir: 2, doneAt: date
                ))
            }
        }
        sets.sort { $0.doneAt > $1.doneAt }
        return Array(sets.prefix(limit))
    }

    func fetchWorkouts(since: Date) async throws -> [Workout] {
        workouts.filter { $0.startedAt >= since }
    }

    func applySetEdits(_ edits: [(id: UUID, weightKg: Double, reps: Int, rir: Int?)], forWorkoutID: UUID) async throws {
        guard let wi = workouts.firstIndex(where: { $0.id == forWorkoutID }) else { return }
        for edit in edits {
            if let si = workouts[wi].sets.firstIndex(where: { $0.id == edit.id }) {
                workouts[wi].sets[si].weightKg = edit.weightKg
                workouts[wi].sets[si].reps     = edit.reps
                workouts[wi].sets[si].rir      = edit.rir
            }
        }
        workouts[wi].volumeKg = workouts[wi].sets.reduce(0.0) { $0 + $1.weightKg * Double($1.reps) }
    }
}

// MARK: - Mock Run Repository

@MainActor
final class MockRunRepository: RunRepository {
    private(set) var runs: [Run] = {
        var r: [Run] = []
        let uid = UUID()
        r.append(Run(userID: uid, startedAt: .now - 86400, endedAt: .now - 83500,
                     distanceM: 5420, durationS: 1694, gainM: 42,
                     polyline: MockRunRepository.fakePolyline(lat: 48.1551, lon: 11.5418, rLat: 0.009, rLon: 0.016),
                     splitsJSON: "[{\"km\":1,\"paceSecPerKm\":312,\"avgBpm\":148},{\"km\":2,\"paceSecPerKm\":308,\"avgBpm\":151},{\"km\":3,\"paceSecPerKm\":310,\"avgBpm\":153},{\"km\":4,\"paceSecPerKm\":315,\"avgBpm\":154},{\"km\":5,\"paceSecPerKm\":312,\"avgBpm\":154}]"))
        r.append(Run(userID: uid, startedAt: .now - 432000, endedAt: .now - 428800,
                     distanceM: 8200, durationS: 2640, gainM: 88,
                     polyline: MockRunRepository.fakePolyline(lat: 48.1600, lon: 11.5580, rLat: 0.014, rLon: 0.022),
                     splitsJSON: "[]"))
        return r
    }()

    func fetchRuns(limit: Int) async throws -> [Run] { Array(runs.prefix(limit)) }

    func fetchRun(id: UUID) async throws -> Run? {
        runs.first { $0.id == id }
    }

    static func fakePolyline(lat: Double, lon: Double, rLat: Double, rLon: Double, pts: Int = 80) -> Data {
        var vals: [Double] = []
        for i in 0..<pts {
            let a = Double(i) / Double(pts) * 2 * .pi
            vals.append(lat + rLat * sin(a))
            vals.append(lon + rLon * cos(a))
        }
        return (try? JSONEncoder().encode(vals)) ?? Data()
    }

    func save(_ run: Run) async throws {
        if let i = runs.firstIndex(where: { $0.id == run.id }) { runs[i] = run }
        else { runs.insert(run, at: 0) }
    }

    func delete(_ run: Run) async throws { runs.removeAll { $0.id == run.id } }

    func monthlySummary(year: Int, month: Int) async throws -> RunMonthlySummary {
        RunMonthlySummary(totalDistanceM: 42800, count: 8,
                          weeklyDistances: [6.2, 9.4, 11.8, 8.4, 7.0],
                          avgPaceSecPerKm: 314)
    }
}

// MARK: - Mock Body Metric Repository

@MainActor
final class MockBodyMetricRepository: BodyMetricRepository {
    private(set) var metrics: [BodyMetric] = {
        let uid = UUID()
        var m: [BodyMetric] = []
        for i in 0..<30 {
            m.append(BodyMetric(userID: uid, ts: .now - Double(i) * 86400,
                                type: .weight, value: 75.2 - Double(i) * 0.09))
        }
        m.append(BodyMetric(userID: uid, ts: .now, type: .bodyFat, value: 14.8, method: "caliper"))
        m.append(BodyMetric(userID: uid, ts: .now, type: .chest, value: 102))
        m.append(BodyMetric(userID: uid, ts: .now, type: .waist, value: 80))
        m.append(BodyMetric(userID: uid, ts: .now, type: .hips, value: 96))
        m.append(BodyMetric(userID: uid, ts: .now, type: .biceps, value: 38))
        m.append(BodyMetric(userID: uid, ts: .now, type: .thigh, value: 58))
        m.append(BodyMetric(userID: uid, ts: .now, type: .calf, value: 38))
        return m
    }()

    func fetchMetrics(type: BodyMetricType, limit: Int) async throws -> [BodyMetric] {
        Array(metrics.filter { $0.type == type }.prefix(limit))
    }

    func latestMetric(type: BodyMetricType) async throws -> BodyMetric? {
        metrics.filter { $0.type == type }.sorted { $0.ts > $1.ts }.first
    }

    func save(_ metric: BodyMetric) async throws { metrics.insert(metric, at: 0) }
    func delete(_ metric: BodyMetric) async throws { metrics.removeAll { $0.id == metric.id } }
}

// MARK: - Mock Lab Repository

private func makeLabUnit(_ name: String) -> String {
    if name == "LDL" || name == "HDL" || name == "Triglyzeride" { return "mmol/L" }
    if name == "Ferritin" || name == "Kortisol" { return "µg/L" }
    return "ng/mL"
}

private func makeLabValues(for measurement: LabMeasurement, offset: Double = 0) -> [LabValue] {
    let specs: [(String, Double, Double, Double, String)] = [
        ("Vitamin D",    38 + offset,  30,   70,  "Vitamine & Mineralstoffe"),
        ("Ferritin",     85 + offset,  20,  200,  "Vitamine & Mineralstoffe"),
        ("Eisen",        18 + offset,   9,   30,  "Vitamine & Mineralstoffe"),
        ("LDL",         2.8 + offset,   0,  3.0,  "Blutfette"),
        ("HDL",         1.4 - offset, 1.0,  2.5,  "Blutfette"),
        ("Triglyzeride",1.2 + offset,   0,  1.7,  "Blutfette"),
        ("Testosteron", 18.4 + offset, 8.6, 29.0, "Hormone"),
        ("TSH",          2.1 - offset, 0.4,  4.0, "Hormone"),
        ("Hämoglobin",  15.2 + offset,13.5, 17.5, "Blutbild"),
        ("Leukozyten",   6.4 - offset, 3.5, 10.5, "Blutbild"),
        ("Thrombozyten",248 + offset, 150,  400,  "Blutbild"),
        ("Kortisol",    550 - offset, 130,  620,  "Hormone"),
    ]
    return specs.map { name, val, low, high, cat in
        LabValue(measurementID: measurement.id, marker: name, value: val,
                 unit: makeLabUnit(name), refLow: low, refHigh: high, category: cat)
    }
}

@MainActor
final class MockLabRepository: LabRepository {
    private(set) var measurements: [LabMeasurement] = {
        let uid = UUID()
        // Most recent measurement
        let m1 = LabMeasurement(userID: uid, takenAt: .now - 604800, source: "Labor")
        m1.values.append(contentsOf: makeLabValues(for: m1, offset: 0))
        // Previous measurement 3 months ago (slightly different values for trend arrows)
        let m2 = LabMeasurement(userID: uid, takenAt: .now - 7776000, source: "Labor")
        m2.values.append(contentsOf: makeLabValues(for: m2, offset: -4))
        return [m1, m2]
    }()

    func fetchMeasurements(limit: Int) async throws -> [LabMeasurement] {
        Array(measurements.prefix(limit))
    }

    func latestMeasurement() async throws -> LabMeasurement? { measurements.first }

    func save(_ measurement: LabMeasurement) async throws {
        measurements.insert(measurement, at: 0)
    }

    func delete(_ measurement: LabMeasurement) async throws {
        measurements.removeAll { $0.id == measurement.id }
    }

    func fetchValues(marker: String) async throws -> [LabValue] {
        measurements.flatMap { $0.values }.filter { $0.marker == marker }
    }
}

// MARK: - Mock Supplement Repository

@MainActor
final class MockSupplementRepository: SupplementRepository {
    private(set) var supplements: [Supplement] = {
        let uid = UUID()
        var s: [Supplement] = []
        s.append(Supplement(userID: uid, name: "Vitamin D3 + K2", kind: .supplement,
                            dose: "4000 IE / 200 µg", form: "Kapsel", stockUnits: 84,
                            times: ["07:30"]))
        s.append(Supplement(userID: uid, name: "Magnesium Bisglycinat", kind: .supplement,
                            dose: "300 mg", form: "Kapsel", stockUnits: 60,
                            times: ["21:00"]))
        s.append(Supplement(userID: uid, name: "Omega-3", kind: .supplement,
                            dose: "2000 mg EPA/DHA", form: "Kapsel", stockUnits: 120,
                            times: ["07:30", "19:00"]))
        s.append(Supplement(userID: uid, name: "Creatin Monohydrat", kind: .supplement,
                            dose: "5 g", form: "Pulver", stockUnits: 200,
                            times: ["12:00"]))
        s.append(Supplement(userID: uid, name: "Zink", kind: .supplement,
                            dose: "25 mg", form: "Tablette", stockUnits: 100,
                            times: ["21:00"]))
        s.append(Supplement(userID: uid, name: "Metformin", kind: .medication,
                            dose: "500 mg", form: "Tablette", stockUnits: 60,
                            times: ["08:00", "20:00"], withFood: true))
        s.append(Supplement(userID: uid, name: "Ashwagandha", kind: .herbal,
                            dose: "600 mg KSM-66", form: "Kapsel", stockUnits: 45,
                            times: ["21:00"]))
        s.append(Supplement(userID: uid, name: "Probiotikum", kind: .supplement,
                            dose: "10 Mrd. KBE", form: "Kapsel", stockUnits: 30,
                            times: ["07:30"]))
        return s
    }()

    func fetchSupplements() async throws -> [Supplement] { supplements }

    func fetchSupplement(id: UUID) async throws -> Supplement? {
        supplements.first { $0.id == id }
    }

    func save(_ supplement: Supplement) async throws {
        if let i = supplements.firstIndex(where: { $0.id == supplement.id }) {
            supplements[i] = supplement
        } else {
            supplements.append(supplement)
        }
    }

    func delete(_ supplement: Supplement) async throws {
        supplements.removeAll { $0.id == supplement.id }
    }

    func recordIntake(supplementID: UUID, takenAt: Date) async throws {}
    func clearIntake(supplementID: UUID) async throws {}
    func todayIntakes() async throws -> [SupplementIntake] { [] }
    func streakDays() async throws -> Int { 14 }
    func fetchIntakes(supplementID: UUID, limit: Int) async throws -> [SupplementIntake] {
        var intakes: [SupplementIntake] = []
        for i in 0..<min(limit, 30) {
            let date = Calendar.current.startOfDay(for: .now - Double(i) * 86400)
            let taken = i != 3 && i != 11
            intakes.append(SupplementIntake(
                supplementID: supplementID,
                plannedAt: date,
                takenAt: taken ? date.addingTimeInterval(7 * 3600) : nil
            ))
        }
        return intakes
    }
}
