import Foundation

struct CatalogExercise: Identifiable {
    let id = UUID()
    var name: String
    var muscle: MuscleGroup
    var muscleLabel: String
}

struct ExerciseCatalog {
    static let exercises: [CatalogExercise] = [
        // Brust
        .init(name: "Bankdrücken",          muscle: .chest,     muscleLabel: "Brust · Hauptübung"),
        .init(name: "Schrägbank Kurzhantel", muscle: .chest,     muscleLabel: "Brust · Schrägbank"),
        .init(name: "Fliegende Kurzhantel",  muscle: .chest,     muscleLabel: "Brust · Isolation"),
        .init(name: "Butterfly Maschine",    muscle: .chest,     muscleLabel: "Brust · Isolation"),
        .init(name: "Dips",                  muscle: .chest,     muscleLabel: "Brust · Trizeps"),
        .init(name: "Kabelzug Crossover",    muscle: .chest,     muscleLabel: "Brust · Isolation"),
        // Rücken
        .init(name: "Kreuzheben",            muscle: .back,      muscleLabel: "Rücken · Hauptübung"),
        .init(name: "Klimmzüge",             muscle: .back,      muscleLabel: "Rücken · Hauptübung"),
        .init(name: "Latzug",                muscle: .back,      muscleLabel: "Rücken · Latissimus"),
        .init(name: "Rudern Langhantel",     muscle: .back,      muscleLabel: "Rücken · Mitte"),
        .init(name: "Rudern Kabelzug",       muscle: .back,      muscleLabel: "Rücken · Mitte"),
        .init(name: "Hyperextension",        muscle: .back,      muscleLabel: "Rücken · Lumbal"),
        // Beine
        .init(name: "Kniebeugen",            muscle: .legs,      muscleLabel: "Beine · Hauptübung"),
        .init(name: "Beinpresse",            muscle: .legs,      muscleLabel: "Beine · Quads"),
        .init(name: "Romanian Deadlift",     muscle: .legs,      muscleLabel: "Beine · Hamstrings"),
        .init(name: "Beinstrecker",          muscle: .legs,      muscleLabel: "Beine · Isolation"),
        .init(name: "Beinbeuger",            muscle: .legs,      muscleLabel: "Beine · Isolation"),
        .init(name: "Wadenheben",            muscle: .legs,      muscleLabel: "Beine · Waden"),
        .init(name: "Wadenheben Sitzend",   muscle: .legs,      muscleLabel: "Beine · Waden sitzend"),
        .init(name: "Bulgarische Ausfallschritte", muscle: .legs, muscleLabel: "Beine · Quads"),
        .init(name: "Sumo Kniebeugen",      muscle: .legs,      muscleLabel: "Beine · Innenoberschenkel"),
        // Schultern
        .init(name: "Schulterdrücken",       muscle: .shoulders, muscleLabel: "Schultern · Hauptübung"),
        .init(name: "Militärpress",          muscle: .shoulders, muscleLabel: "Schultern · Hauptübung"),
        .init(name: "Seitheben",             muscle: .shoulders, muscleLabel: "Schultern · Lateral"),
        .init(name: "Frontheben",            muscle: .shoulders, muscleLabel: "Schultern · Anterior"),
        .init(name: "Face Pulls",            muscle: .shoulders, muscleLabel: "Schultern · Posterior"),
        .init(name: "Reverse Fliegende",     muscle: .shoulders, muscleLabel: "Schultern · Posterior"),
        // Arme
        .init(name: "Bizepscurls",           muscle: .arms,      muscleLabel: "Arme · Bizeps"),
        .init(name: "Hammercurls",           muscle: .arms,      muscleLabel: "Arme · Bizeps"),
        .init(name: "Trizepsdrücken Kabel",  muscle: .arms,      muscleLabel: "Arme · Trizeps"),
        .init(name: "Skull Crushers",        muscle: .arms,      muscleLabel: "Arme · Trizeps"),
        .init(name: "Trizeps Dips",          muscle: .arms,      muscleLabel: "Arme · Trizeps"),
        .init(name: "Preacher Curls",        muscle: .arms,      muscleLabel: "Arme · Bizeps"),
        // Core
        .init(name: "Plank",                 muscle: .core,      muscleLabel: "Core · Stabilität"),
        .init(name: "Crunch",                muscle: .core,      muscleLabel: "Core · Bauch"),
        .init(name: "Russian Twists",        muscle: .core,      muscleLabel: "Core · Rotation"),
        .init(name: "Beinheben",             muscle: .core,      muscleLabel: "Core · Unterbauch"),
        .init(name: "Ab Wheel",              muscle: .core,      muscleLabel: "Core · Stabilität"),
    ]

    static func filtered(muscle: MuscleGroup?, search: String) -> [CatalogExercise] {
        exercises.filter { ex in
            let muscleOK = muscle == nil || ex.muscle == muscle
            let searchOK = search.isEmpty || ex.name.localizedCaseInsensitiveContains(search)
            return muscleOK && searchOK
        }
    }
}
