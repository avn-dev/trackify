import Foundation

enum Formatters {
    private static let de = Locale(identifier: "de_DE")

    static let decimal: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = de
        f.numberStyle = .decimal
        f.minimumFractionDigits = 1
        f.maximumFractionDigits = 1
        return f
    }()

    static let integer: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = de
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()

    static let dateShort: DateFormatter = {
        let f = DateFormatter()
        f.locale = de
        f.dateFormat = "d. MMM"
        return f
    }()

    static let dateMedium: DateFormatter = {
        let f = DateFormatter()
        f.locale = de
        f.dateFormat = "d. MMMM yyyy"
        return f
    }()

    static let time: DateFormatter = {
        let f = DateFormatter()
        f.locale = de
        f.dateFormat = "HH:mm"
        return f
    }()

    static func kg(_ value: Double) -> String {
        (decimal.string(from: NSNumber(value: value)) ?? "\(value)") + " kg"
    }

    static func percent(_ value: Double) -> String {
        (decimal.string(from: NSNumber(value: value)) ?? "\(value)") + " %"
    }

    static func cm(_ value: Double) -> String {
        (decimal.string(from: NSNumber(value: value)) ?? "\(value)") + " cm"
    }

    static func compact(_ value: Double) -> String {
        if value == value.rounded() {
            return integer.string(from: NSNumber(value: value)) ?? "\(Int(value))"
        }
        return decimal.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    static func shortDate(_ date: Date) -> String {
        dateShort.string(from: date)
    }

    static func duration(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }

    static func pace(_ secondsPerKm: Int) -> String {
        let m = secondsPerKm / 60
        let s = secondsPerKm % 60
        return String(format: "%d:%02d", m, s)
    }

    // Unit-aware helpers — always receive SI values, format for display.
    static func weightValue(_ kg: Double, useKg: Bool) -> String {
        useKg ? compact(kg) : compact(kg * 2.20462)
    }
    static func weightUnit(_ useKg: Bool) -> String { useKg ? "kg" : "lbs" }

    static func distanceValue(_ km: Double, useKm: Bool) -> String {
        useKm ? compact(km) : compact(km * 0.621371)
    }
    static func distanceUnit(_ useKm: Bool) -> String { useKm ? "km" : "mi" }

    // Pace adapts: returns "/km" or "/mi" pace string.
    static func pace(_ secondsPerKm: Int, useKm: Bool) -> String {
        let secPerUnit = useKm ? secondsPerKm : Int(Double(secondsPerKm) / 0.621371)
        let m = secPerUnit / 60; let s = secPerUnit % 60
        return String(format: "%d:%02d", m, s)
    }
}

// Deterministic local user ID for offline/dev use.
extension UUID {
    static let localUser = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
