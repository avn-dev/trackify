import Foundation

// MARK: - Enums

enum PlanType: String, Codable, CaseIterable {
    case rotating = "rotating"
    case weekday  = "weekday"

    var label: String { self == .rotating ? "Rotierend" : "Wochentage" }
    var description: String {
        switch self {
        case .rotating: return "A → B → C → Pause → wiederholen"
        case .weekday:  return "Mo: Brust, Di: Rücken, usw."
        }
    }
}

enum SkipBehavior: String, Codable, CaseIterable {
    case shiftAll = "shiftAll"
    case skipOnly = "skipOnly"

    var label: String {
        switch self {
        case .shiftAll: return "Alles nach hinten schieben"
        case .skipOnly: return "Nur diesen Tag überspringen"
        }
    }
    var description: String {
        switch self {
        case .shiftAll: return "Verpasster Tag wird morgen nachgeholt"
        case .skipOnly: return "Plan rotiert weiter trotz Pause"
        }
    }
}

// MARK: - PlanDay

enum PlanStatus: String, Codable { case today, next, planned }

struct PlanDay: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var tag: String
    var focus: String             // empty string = Ruhetag
    var exercises: Int = 4
    var minutes: Int = 60
    var status: PlanStatus = .planned
    var weekday: Int = 0          // 0 = unused; 1=Mo … 7=So

    var isRestDay: Bool { focus.isEmpty }
}

// MARK: - PlanConfig

struct PlanConfig: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var name: String = "Mein Plan"
    var type: PlanType = .rotating
    var skipBehavior: SkipBehavior = .shiftAll
    var days: [PlanDay] = PlanConfig.defaultDays
    var lastCompletedDayID: String = ""

    // Tolerant decoder: missing keys fall back to defaults (handles old JSON format)
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id                  = (try? c.decode(UUID.self,           forKey: .id))                  ?? UUID()
        name                = (try? c.decode(String.self,         forKey: .name))                ?? "Mein Plan"
        type                = (try? c.decode(PlanType.self,       forKey: .type))                ?? .rotating
        skipBehavior        = (try? c.decode(SkipBehavior.self,   forKey: .skipBehavior))        ?? .shiftAll
        days                = (try? c.decode([PlanDay].self,      forKey: .days))                ?? PlanConfig.defaultDays
        lastCompletedDayID  = (try? c.decode(String.self,         forKey: .lastCompletedDayID))  ?? ""
    }

    init(
        id: UUID = UUID(),
        name: String = "Mein Plan",
        type: PlanType = .rotating,
        skipBehavior: SkipBehavior = .shiftAll,
        days: [PlanDay] = PlanConfig.defaultDays,
        lastCompletedDayID: String = ""
    ) {
        self.id                 = id
        self.name               = name
        self.type               = type
        self.skipBehavior       = skipBehavior
        self.days               = days
        self.lastCompletedDayID = lastCompletedDayID
    }

    static let defaultDays: [PlanDay] = [
        PlanDay(id: UUID(uuidString: "A0000001-0000-0000-0000-000000000000")!,
                tag: "Tag A", focus: "Push",  exercises: 6, minutes: 58),
        PlanDay(id: UUID(uuidString: "A0000002-0000-0000-0000-000000000000")!,
                tag: "Tag B", focus: "Pull",  exercises: 6, minutes: 62),
        PlanDay(id: UUID(uuidString: "A0000003-0000-0000-0000-000000000000")!,
                tag: "Tag C", focus: "Legs",  exercises: 5, minutes: 70),
        PlanDay(id: UUID(uuidString: "A0000004-0000-0000-0000-000000000000")!,
                tag: "Tag D", focus: "Upper", exercises: 7, minutes: 65),
    ]
}

// MARK: - PlanStore

struct PlanStore: Codable {
    var plans: [PlanConfig]
    var activePlanID: UUID

    static var fresh: PlanStore {
        let p = PlanConfig()
        return PlanStore(plans: [p], activePlanID: p.id)
    }

    var activePlan: PlanConfig {
        plans.first { $0.id == activePlanID } ?? plans[0]
    }

    var activePlanIndex: Int? {
        plans.firstIndex { $0.id == activePlanID }
    }
}

// MARK: - PlanData Engine

struct PlanData {

    private static let storeKey    = "planStoreJSON_v1"
    private static let legacyKey   = "planConfigJSON_v2"
    private static let legacyIDKey = "lastCompletedEntryID"
    static  let versionKey         = "planStoreVersion"   // @AppStorage reactivity signal

    // MARK: Store persistence

    static func loadStore() -> PlanStore {
        if UserDefaults.standard.string(forKey: storeKey) == nil {
            return migrate()
        }
        guard let raw   = UserDefaults.standard.string(forKey: storeKey),
              let data  = raw.data(using: .utf8),
              let store = try? JSONDecoder().decode(PlanStore.self, from: data)
        else { return .fresh }
        return store
    }

    static func saveStore(_ store: PlanStore) {
        guard let data = try? JSONEncoder().encode(store),
              let str  = String(data: data, encoding: .utf8)
        else { return }
        UserDefaults.standard.set(str, forKey: storeKey)
        let v = UserDefaults.standard.integer(forKey: versionKey)
        UserDefaults.standard.set(v + 1, forKey: versionKey)
    }

    private static func migrate() -> PlanStore {
        var cfg = PlanConfig()
        if let raw  = UserDefaults.standard.string(forKey: legacyKey),
           let data = raw.data(using: .utf8),
           let old  = try? JSONDecoder().decode(PlanConfig.self, from: data) {
            cfg = old
        }
        cfg.lastCompletedDayID = UserDefaults.standard.string(forKey: legacyIDKey) ?? ""
        let store = PlanStore(plans: [cfg], activePlanID: cfg.id)
        saveStore(store)
        return store
    }

    // MARK: Plan CRUD

    static func addPlan(_ plan: PlanConfig) {
        var store = loadStore()
        store.plans.append(plan)
        store.activePlanID = plan.id
        saveStore(store)
    }

    static func updatePlan(_ plan: PlanConfig) {
        var store = loadStore()
        guard let idx = store.plans.firstIndex(where: { $0.id == plan.id }) else { return }
        store.plans[idx] = plan
        saveStore(store)
    }

    static func setActivePlan(id: UUID) {
        var store = loadStore()
        guard store.plans.contains(where: { $0.id == id }) else { return }
        store.activePlanID = id
        saveStore(store)
    }

    static func deletePlan(id: UUID) {
        var store = loadStore()
        guard store.plans.count > 1 else { return }
        store.plans.removeAll { $0.id == id }
        if store.activePlanID == id { store.activePlanID = store.plans[0].id }
        saveStore(store)
    }

    // MARK: Today's training day

    static func todayDay(config: PlanConfig) -> PlanDay? {
        switch config.type {
        case .rotating:
            let training = config.days.filter { !$0.isRestDay }
            guard !training.isEmpty else { return nil }
            if let idx = training.firstIndex(where: { $0.id.uuidString == config.lastCompletedDayID }) {
                return training[(idx + 1) % training.count]
            }
            return training.first

        case .weekday:
            return config.days.first { $0.weekday == todayWeekday && !$0.isRestDay }
        }
    }

    static func markCompleted(dayID: UUID) {
        var store = loadStore()
        guard let idx = store.activePlanIndex else { return }
        store.plans[idx].lastCompletedDayID = dayID.uuidString
        saveStore(store)
    }

    static func skipToday() {
        let store = loadStore()
        guard let today = todayDay(config: store.activePlan) else { return }
        markCompleted(dayID: today.id)
    }

    // MARK: Display list

    static func computedDays(config: PlanConfig) -> [PlanDay] {
        let today = todayDay(config: config)
        switch config.type {

        case .rotating:
            let training = config.days.filter { !$0.isRestDay }
            return config.days.map { day in
                var d = day
                if day.isRestDay {
                    d.status = .planned
                } else if day.id == today?.id {
                    d.status = .today
                } else if let ti = training.firstIndex(where: { $0.id == today?.id }),
                          let di = training.firstIndex(where: { $0.id == day.id }),
                          (di - ti + training.count) % training.count == 1 {
                    d.status = .next
                } else {
                    d.status = .planned
                }
                return d
            }

        case .weekday:
            let wd = todayWeekday
            return (1...7).map { w in
                var d = config.days.first(where: { $0.weekday == w })
                    ?? PlanDay(tag: wdShort(w), focus: "", weekday: w)
                d.status = (w == wd && !d.isRestDay) ? .today : .planned
                return d
            }
        }
    }

    // MARK: Body labels

    static func bodyLabel(_ day: PlanDay) -> String {
        switch day.focus {
        case "Push":  return "Brust · Schulter · Trizeps"
        case "Pull":  return "Rücken · Bizeps"
        case "Legs":  return "Beine · Gesäß · Waden"
        case "Lower": return "Beine · Unterkörper"
        case "Upper": return "Oberkörper · Compound"
        case "Full":  return "Ganzkörper · Compound"
        case "Kraft": return "Bankdrücken · Kniebeuge · Kreuzheben"
        default:      return day.focus
        }
    }

    // MARK: Weekday helpers

    static var todayWeekday: Int {
        let wd = Calendar.current.component(.weekday, from: Date())
        return wd == 1 ? 7 : wd - 1
    }

    static let wdShortNames = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
    static let wdLongNames  = ["Montag", "Dienstag", "Mittwoch", "Donnerstag",
                                "Freitag", "Samstag", "Sonntag"]

    static func wdShort(_ wd: Int) -> String {
        guard wd >= 1, wd <= 7 else { return "" }
        return wdShortNames[wd - 1]
    }

    static func wdLong(_ wd: Int) -> String {
        guard wd >= 1, wd <= 7 else { return "" }
        return wdLongNames[wd - 1]
    }

    // MARK: Backwards-compatible shims

    static var today: PlanDay?    { todayDay(config: loadStore().activePlan) }
    static var allDays: [PlanDay] { computedDays(config: loadStore().activePlan) }
    static func loadConfig() -> PlanConfig  { loadStore().activePlan }
    static func saveConfig(_ c: PlanConfig) { updatePlan(c) }
}
