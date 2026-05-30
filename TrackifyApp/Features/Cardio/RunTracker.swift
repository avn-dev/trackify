import Foundation
import CoreLocation
import Combine
import HealthKit

// MARK: - RunTracker

@Observable
@MainActor
final class RunTracker: NSObject, @unchecked Sendable {

    // Published state
    var distanceM: Double = 0
    var gainM: Double = 0
    var elapsedSeconds: Int = 0
    var bpm: Int = 0
    var isPaused: Bool = false
    var gpsStatus: GPSStatus = .searching
    var splits: [LiveSplit] = []
    var locations: [CLLocationCoordinate2D] = []
    var altitudeHistory: [Double] = []

    var paceSecPerKm: Int {
        guard distanceM > 50 else { return 0 }
        return Int(Double(elapsedSeconds) / (distanceM / 1000))
    }

    // Private state
    private var locationManager: CLLocationManager?
    private var timerTask: Task<Void, Never>?
    private var lastLocation: CLLocation?
    private var lastAltitude: Double?
    private var nextSplitKm: Double = 1.0
    private var splitStartSeconds: Int = 0
    private var splitStartDistanceM: Double = 0
    private var hkStore: HKHealthStore?
    private var hkQuery: HKQuery?

    // MARK: - Lifecycle

    func requestAuthorization() {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .fitness
        manager.distanceFilter = 5
        locationManager = manager

        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            manager.requestAlwaysAuthorization()
        default:
            break
        }
    }

    func start(readHeartRate: Bool = false) {
        guard let manager = locationManager else { return }
        manager.startUpdatingLocation()
        startTimer()
        gpsStatus = .acquiring
        if readHeartRate && HKHealthStore.isHealthDataAvailable() {
            startHeartRateQuery()
        }
    }

    func pause() {
        isPaused = true
        locationManager?.stopUpdatingLocation()
    }

    func resume() {
        isPaused = false
        locationManager?.startUpdatingLocation()
    }

    func lap() {
        let lapDuration = elapsedSeconds - splitStartSeconds
        let lapDist = distanceM - splitStartDistanceM
        let lapPace = lapDist > 10 ? Int(Double(lapDuration) / (lapDist / 1000)) : 0
        splits.append(LiveSplit(km: splits.count + 1, paceSecPerKm: lapPace, bpm: bpm))
        splitStartSeconds = elapsedSeconds
        splitStartDistanceM = distanceM
        nextSplitKm = (distanceM / 1000).rounded(.up) + 1
    }

    func finish() -> (polyline: Data, splitsJSON: String) {
        locationManager?.stopUpdatingLocation()
        timerTask?.cancel()
        stopHeartRateQuery()

        let coordData = encodePolyline(locations)
        let splitsJSON = encodeSplits()
        return (coordData, splitsJSON)
    }

    // MARK: - Timer

    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self, !Task.isCancelled else { break }
                if !self.isPaused {
                    self.elapsedSeconds += 1
                }
            }
        }
    }

    // MARK: - Location processing

    private func applyLocation(_ location: CLLocation) {
        guard location.horizontalAccuracy >= 0,
              location.horizontalAccuracy <= 50 else { return }

        locations.append(location.coordinate)

        // Distance
        if let last = lastLocation {
            let delta = location.distance(from: last)
            if delta > 1 {
                distanceM += delta
                checkSplitCrossing()
            }
        }
        lastLocation = location

        // Elevation gain + history (capped at 300 samples for the sparkline)
        if let lastAlt = lastAltitude {
            let deltaAlt = location.altitude - lastAlt
            if deltaAlt > 0 { gainM += deltaAlt }
        }
        lastAltitude = location.altitude
        if altitudeHistory.count >= 300 { altitudeHistory.removeFirst() }
        altitudeHistory.append(location.altitude)

        // GPS status
        if location.horizontalAccuracy <= 10 {
            gpsStatus = .good
        } else if location.horizontalAccuracy <= 30 {
            gpsStatus = .ok
        } else {
            gpsStatus = .acquiring
        }
    }

    private func checkSplitCrossing() {
        while distanceM >= nextSplitKm * 1000 {
            let splitDuration = elapsedSeconds - splitStartSeconds
            let splitDist = distanceM - splitStartDistanceM
            let splitPace = splitDist > 0 ? Int(Double(splitDuration) / (splitDist / 1000)) : 0

            splits.append(LiveSplit(
                km: Int(nextSplitKm),
                paceSecPerKm: splitPace,
                bpm: bpm
            ))

            splitStartSeconds = elapsedSeconds
            splitStartDistanceM = distanceM
            nextSplitKm += 1
        }
    }

    // MARK: - Heart rate (HealthKit streaming)

    private func startHeartRateQuery() {
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        let store = HKHealthStore()
        hkStore = store

        let predicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictStartDate)
        let handler: @Sendable (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, (any Error)?) -> Void = { [weak self] _, samples, _, _, _ in
            guard let bpmValue = (samples as? [HKQuantitySample])?.last.map({
                Int($0.quantity.doubleValue(for: HKUnit(from: "count/min")))
            }) else { return }
            Task { @MainActor [weak self] in self?.bpm = bpmValue }
        }
        let query = HKAnchoredObjectQuery(
            type: hrType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit,
            resultsHandler: handler
        )
        query.updateHandler = handler
        hkQuery = query
        store.execute(query)
    }

    private func stopHeartRateQuery() {
        if let query = hkQuery, let store = hkStore {
            store.stop(query)
        }
        hkQuery = nil
        hkStore = nil
    }

    // MARK: - Encoding

    private func encodePolyline(_ coords: [CLLocationCoordinate2D]) -> Data {
        let values = coords.flatMap { [$0.latitude, $0.longitude] }
        return (try? JSONEncoder().encode(values)) ?? Data()
    }

    private func encodeSplits() -> String {
        struct S: Codable { var km: Int; var paceSecPerKm: Int; var avgBpm: Int }
        let payload = splits.map { S(km: $0.km, paceSecPerKm: $0.paceSecPerKm, avgBpm: $0.bpm) }
        return (try? String(data: JSONEncoder().encode(payload), encoding: .utf8)) ?? "[]"
    }
}

// MARK: - CLLocationManagerDelegate

extension RunTracker: @preconcurrency CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse:
            manager.requestAlwaysAuthorization()
        case .authorizedAlways:
            gpsStatus = .acquiring
        default:
            gpsStatus = .denied
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        applyLocation(loc)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        gpsStatus = .acquiring
    }
}

// MARK: - Supporting types

@Observable
final class LiveSplit: Identifiable {
    let id = UUID()
    var km: Int
    var paceSecPerKm: Int
    var bpm: Int

    var isBest: Bool = false

    init(km: Int, paceSecPerKm: Int, bpm: Int) {
        self.km = km
        self.paceSecPerKm = paceSecPerKm
        self.bpm = bpm
    }
}

enum GPSStatus {
    case searching, acquiring, ok, good, denied

    var label: String {
        switch self {
        case .searching:  "GPS SUCHE"
        case .acquiring:  "GPS SCHWACH"
        case .ok:         "GPS OK"
        case .good:       "GPS GUT"
        case .denied:     "GPS GESPERRT"
        }
    }
}
