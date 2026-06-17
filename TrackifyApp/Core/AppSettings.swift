import Foundation

/// Central registry of `@AppStorage` / `UserDefaults` keys and their canonical
/// default values.
///
/// Use these constants instead of hand-typing key strings at each call site:
/// a typo (`"untisKg"`) silently reads a phantom key, and re-typing the default
/// value at every site lets the defaults drift. That drift was a real bug —
/// `goal5kSec` defaulted to `1500` in Goals/Profile but `0` in Insights, which
/// silently disabled all 5K-goal logic until the user first opened the Goals
/// screen. Routing every site through `AppSettings.Default` makes that impossible.
enum AppSettings {
    enum Key {
        static let goalWeightKg        = "goalWeightKg"
        static let goalHeightCm        = "goalHeightCm"
        static let goal5kSec           = "goal5kSec"
        static let goalWorkoutsPerWeek = "goalWorkoutsPerWeek"
        static let hkWeightSync        = "hkWeightSync"
        static let hkHeartRate         = "hkHeartRate"
        static let hkWorkoutExport     = "hkWorkoutExport"
    }

    enum Default {
        static let goalWeightKg        = 70.0
        static let goalHeightCm        = 178.0
        static let goal5kSec           = 1500   // 25:00
        static let goalWorkoutsPerWeek = 4
    }
}
