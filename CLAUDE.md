# Trackify — Build Spec

> **Hand this file to Claude Code (or any AI/dev) to build the iOS app.**
> Everything below is canonical. The HTML prototype is the visual truth; this file is the engineering brief.

---

## 0. Mission

Build **Trackify**: a native iOS fitness-tracking app. Users log workouts, runs, body metrics, lab values, and supplements/medications. Design language is **Refined Sport-Tech** — monochrome surface, one lime accent, mono numerics. iOS 17+, SwiftUI, German UI (du-form).

---

## 1. Tech stack

| Concern | Choice | Why |
|---|---|---|
| UI | **SwiftUI** | iOS-only, modern declarative |
| Min OS | iOS 17.0 | `@Observable`, native `Charts`, `Inspector` API |
| State | `@Observable` + repository pattern | Testable, swap mocks for real backend |
| Charts | **Swift Charts** | Built-in, matches `LineChart`/`BarChart` API 1:1 |
| Persistence | **SwiftData** | Offline-first, sync to remote later |
| Backend | **Supabase** (Postgres + Auth + Storage + RLS) | Fast to ship, RLS handles multi-tenant |
| Auth | Email/PW + **Sign in with Apple** + Google | Apple is App Store requirement once you have any social auth |
| Maps | **MapKit** | Run routes |
| Health | **HealthKit** (optional opt-in) | Weight import, heart-rate during runs |
| OCR | `VisionKit.DataScannerViewController` (v1), Mistral OCR / Google Vision (v2) | Lab PDF/photo import |
| Locations | `CLLocationManager` (background entitlement) | Run tracking |
| Fonts | **Geist** + **Geist Mono** (OFL, free) — `vercel.com/font` | The brand |
| Keychain | `KeychainAccess` | Auth tokens |
| Networking | `URLSession` + Supabase Swift SDK | Don't add Alamofire |
| Forms | Pure SwiftUI | No third-party form lib needed |

---

## 2. Project structure

```
TrackifyApp/
├── TrackifyApp.swift              // @main
├── RootView.swift                 // auth gate
│
├── Core/
│   ├── DesignTokens.swift         // colors, fonts, spacing, radii
│   ├── Theme.swift                // Theme struct + Environment key
│   │
│   ├── Components/
│   │   ├── Card.swift
│   │   ├── Buttons.swift          // PrimaryButton, GhostButton, CircleBtn
│   │   ├── ScreenHeader.swift
│   │   ├── SectionHead.swift
│   │   ├── Stat.swift
│   │   └── TabBar.swift           // 5-slot custom bottom nav
│   │
│   ├── Charts/
│   │   ├── LineChart.swift
│   │   ├── BarChart.swift
│   │   └── RangeScale.swift       // lab norm-band horizontal scale
│   │
│   └── Util/
│       ├── Formatters.swift       // German number/date formatters
│       └── HapticFeedback.swift
│
├── Features/
│   ├── Auth/                      // 4 screens: Splash, Onboarding, Login, Register
│   ├── Home/                      // 1 screen: HomeView (Dashboard)
│   ├── Training/                  // 3 screens: Plan, ExerciseDetail, ActiveWorkout
│   ├── Cardio/                    // 2 screens: RunLive, RunHistory + RunTracker actor
│   ├── Body/                      // 3 screens: Weight, BodyFat, Measurements
│   ├── Lab/                       // 3 screens: Overview, MarkerDetail, Add + OCR service
│   ├── Supplements/               // 3 screens: Overview, Detail, Add
│   └── Profile/                   // 2 screens: Insights, Profile
│
└── Data/
    ├── Models/                    // SwiftData @Models
    ├── Repositories/              // protocols
    │   ├── WorkoutRepository.swift
    │   ├── RunRepository.swift
    │   ├── BodyMetricRepository.swift
    │   ├── LabRepository.swift
    │   └── SupplementRepository.swift
    ├── Mock/                      // MockRepositories for previews/tests
    └── Supabase/                  // real-backend implementations
```

**Rule:** Each screen is one View file. No god-files. Repositories are protocols with Mock + Supabase impls so previews stay fast and tests don't hit the network.

---

## 3. Design tokens

### Colors

| Token | Dark | Light | Used for |
|---|---|---|---|
| `bg` | `#0b0b0c` | `#f6f5f1` | screen bg |
| `bgElev` | `#101012` | `#fafaf8` | elevated bg |
| `surface` | `#161618` | `#ffffff` | cards |
| `surface2` | `#1c1c1f` | `#efeeea` | nested surfaces, chips |
| `border` | `white 8%` | `black 8%` | subtle separators |
| `borderStrong` | `white 14%` | `black 14%` | buttons |
| `text` | `#f6f6f7` | `#0b0b0c` | primary |
| `textMid` | `#b8b8bd` | `#3a3a3d` | body |
| `textMuted` | `#76767c` | `#86858a` | meta/labels |
| **`accent`** | `#c8ff3d` | `#c8ff3d` | THE accent — lime |
| `accentText` | `#0b0b0c` | `#0b0b0c` | text on accent |
| `danger` | `#ff6b4a` | `#e0432a` | errors, over-target |
| `amber` (lab only) | `#f5b13a` | `#f5b13a` | "zu niedrig" |

**Accent rule:** lime only on primary CTA, "today" state, positive delta, normal-range markers, focused inputs, current/active states. Never decorative. Never two accents on one screen.

### Typography

- **Geist** (400/500/600/700) — UI
- **Geist Mono** (400/500/600) — numbers, metadata, eyebrows, status badges
- Numbers always: Geist Mono + `monospacedDigit()`
- Eyebrows: 11pt mono, uppercase, kerning 0.6–1.2, color `textMuted`
- Titles: 26 / 30 / 34, weight 600, kerning -1 to -3.5
- Body: 14–15, line-height 1.4
- No italics

### Spacing & radii

- Screen horizontal padding: **20pt**
- Card radius: **18–22**
- Row inside card: **14**
- Pill: **999** (capsule)
- Vertical section gap: **12–18**
- TabBar reserves bottom **100pt** padding on every screen

---

## 4. Numbers & dates (German)

- Decimal: `72,4` not `72.4` — `NumberFormatter(locale: "de_DE")`
- Thousands: `18.420` not `18,420`
- Always show unit. Unit is `textMuted`, smaller (10–13pt when number is 16–60pt).
- Dates: `12. Mai 2026` (medium) · `08. Mai` (short, year omitted if current)
- Times: 24h, `HH:mm`
- Durations: `MM:SS` or `H:MM:SS` for runs >1h
- All time/number labels use Geist Mono

---

## 5. Status semantics

- **Lime accent** → good / normal / current / positive delta / today
- **Danger red** → above-target / error
- **Amber `#f5b13a`** → below-target — **lab values only**, don't generalize
- **textMuted gray** → unchanged / inactive / future

---

## 6. Component primitives (port from `tokens.jsx`)

| Mockup | SwiftUI |
|---|---|
| `Screen` | `ZStack { theme.bg.ignoresSafeArea(); content }` |
| `Card` | `RoundedRectangle(22, .continuous).fill(t.surface).overlay(stroke t.border)` |
| `PrimaryButton` | Capsule + accent bg + accentText, h:52 |
| `GhostButton` | Capsule + borderStrong stroke, h:52 |
| `CircleBtn` | Circle 40×40, surface2 |
| `ScreenHeader` | VStack(eyebrow, title 32pt, optional back chevron), 54pt top inset |
| `SectionHead` | HStack(uppercase mono label, optional trailing action) |
| `Stat` | label (eyebrow) + value (mono large) + unit (mono small) + optional delta |
| `LineChart` | Swift Charts wrapper: 1.75pt line, optional area fill, optional dashed baseline |
| `BarChart` | Swift Charts: cornerRadius=halfWidth, optional `highlighted` bar in accent |
| `TabBar` | Custom HStack at bottom — SwiftUI default TabView chrome doesn't match |

---

## 7. Screens (19 total, 7 sections)

References live in `references/Trackify.html`. Open and zoom each artboard for pixel-precise reference. Screen names below match artboard labels.

### 7.1 Auth (4)

**SplashView** — brand reveal on cold launch. Logomark + wordmark "Trackify" + tagline "train · run · measure" (mono, uppercase, letterSpacing 1.2). 3-dot ghost pagination at bottom. Auto-advance to Onboarding after 2.5s (or skip if returning user).

**OnboardingView** — 3-step value pitch. Mini stat-card preview (volume sparkline) + bold title + body copy + dot pagination (active dot is elongated lime pill) + lime arrow CTA right + Skip link top-right.

**LoginView** — email + password fields styled as `Card` with eyebrow-style label, password as `••••••••`. Right-aligned "vergessen?" link. Lime `PrimaryButton` "Login". Divider "oder weiter mit". Two `GhostButton`s stacked: Google + Apple. Footer line "Noch keinen Account? Registrieren".

**RegisterView** — back chevron top. Name + email + password fields (same style as login). AGB checkbox row with lime tick. Lime PrimaryButton "Konto erstellen". Divider "oder". Two GhostButtons side-by-side: Google + Apple.

### 7.2 Home (1)

**HomeView (Dashboard)** —
- Top bar: greeting eyebrow ("Mittwoch · 14. Mai") + name title ("Hey, Lena.") + bell CircleBtn + avatar (initials in surface2 circle)
- Hero card: full-width `text`-color background card. Eyebrow "Heute · Tag A" + lime `PUSH` badge top-right. Title "Brust · Schulter · Trizeps". Meta row ("6 Übungen · ~58 Min · 22 Sätze"). Lime "Workout starten" rectangle button.
- Stats row (2-up): "Diese Woche" (3/4 mono + 7-day grid; today is dashed border) | "Volumen" (18.420 kg mono + lime sparkline)
- Section "Schnell tracken" (with "Alle" action) → 3-up tiles: Lauf · Gewicht · Maße
- Weight trend card: eyebrow + big value (72,4 kg) + delta + "+ Eintragen" chip + 30-day sparkline (no axes)

### 7.3 Training (3)

**TrainingPlanView** — Header "Training" + eyebrow "Plan · 4-Tage Split" + search CircleBtn. Pill nav: `Mein Plan` (active, filled text-color) · `Vorlagen` · `Verlauf`. List of 4 day cards. Today is fully inverted (text-color bg, bg-color text) with lime "Heute" badge top-right and lime primary "Starten" button + ghost "Vorschau" button. Other days are surface with "Morgen" badge or no badge. Dashed "+ Freies Workout" tile at the end.

**ActiveWorkoutView** — Live indicator (pulsing lime dot + "LIVE · TAG A") + red "Beenden" link. Big clock (Geist Mono, 52pt, 32:14) + right-aligned "Volumen · 4.820 kg". Progress dots row (each exercise = bar segment: done=lime, active=text, pending=borderStrong). Focused current exercise card with lime border. Set table: columns Set · Kg · Wdh · RIR + check button. Active row is highlighted (different bg + border). Rest-timer card embedded in exercise card: small lime icon, eyebrow "Pause läuft", mono 01:24 / 02:00, ghost "Skip" button. Next-exercise preview row (dim). Bottom: full-width lime "Satz abschließen" + side pause CircleBtn.

**ExerciseDetailView** — back chevron, eyebrow "Brust · Hauptübung", title "Schrägbank Kurzhantel", more CircleBtn. Hero video placeholder card (diagonal striped pattern). 3-up stats: 1RM Schätz. 42 kg · Letztes Mal 20×9 · Sätze ges. 148. SectionHead "Fortschritt" w/ "4 Wochen" action → LineChart (accent, with axis). SectionHead "Verlauf" → 3 history rows: date + set notation + weight.

### 7.4 Cardio (2)

**RunLiveView** — Live status (pulsing lime + "LIVE · GPS GUT") + ghost "Karte" pill. Massive distance hero: eyebrow "Distanz" + 88pt mono `5,42 km`. Then 3-column stats with column dividers: Zeit 28:14 · Pace 5:12 (lime) · BPM 154. Elevation profile sparkline (lime area fill). Splits table: KM N · progress bar · pace · BPM. Best km uses lime. Bottom controls: stop button (square icon) + hero pause button (88pt lime circle with white border ring) + LAP button.

**RunHistoryView** — Eyebrow "Cardio · Mai", title "Läufe", filter CircleBtn. Month summary card: eyebrow "Mai · 8 Läufe" + big 42,8 km + weekly BarChart (5 weeks, current highlighted lime) + right-aligned Ø Pace 5:14/km. SectionHead "Letzte Läufe". List rows: small SVG route thumbnail (lime path on dotted grid) + date + distance mono + meta row (time · pace · gain). Detail callout card with embedded BigMap: bigger faux map with lime route, start/end pins. Stats row beneath.

### 7.5 Körper (3)

**WeightView** — back to Körper. Title "72,4 kg" (mono in title slot). Range toggle: 1W / 1M / 3M (active) / 1J / Alles as full-width pill row. Trend card: eyebrow "3 Monate · Trend" + delta "−2,8 kg" + right-aligned eyebrow "Ziel" + "70,0 kg" lime. LineChart with **dashed lime baseline** at 70 kg goal. 3-up stats: Aktuell 72,4 kg · 7T Ø 72,8 kg · BMI 22,4. SectionHead "Einträge" → row list: date + value + delta (lime if loss, danger if gain — context-sensitive! since goal is loss).

**BodyFatView** — eyebrow "Körperfett · Caliper", title "14,8 %". Ring stat card: BodyFatRing (96px donut with lime arc proportional to value/30) + meta column (eyebrow "Letzte Messung" + big 14,8% + lime "↓ 1,6% / 3 Mon." + textMuted "Athletisch · 18-29J"). Trend card with 6M/1J pill toggle + LineChart (6 months). SectionHead "Methode" → 3 methods listed as rows with lime dot for active: Caliper 4-Punkt (active) · Bioimpedanz · Bilder-Schätzung.

**MeasurementsView** — title "Körpermaße" + plus CircleBtn. Big card containing body silhouette SVG (centered) with measurement bands drawn as lime ellipses on chest/waist/hips/biceps/thigh/calf. Tag cards positioned around the silhouette with dotted-line connectors pointing to anatomy: each tag has eyebrow label + value + cm unit + delta (lime if up for measurement-positive metrics like chest/biceps, danger if up for waist/hips). SectionHead "Diese Woche" → 2-col KV grid for secondary measurements: Schulter, Unterarm, Nacken, Knöchel.

### 7.6 Lab & Blutwerte (3)

**LabOverviewView** — eyebrow "Labor · Letzte Messung 12. Mai", title "Blutwerte", plus CircleBtn. Summary card: eyebrow "Großes Blutbild · Mai 26" + big "11 / 13" mono + caption "Marker im Normbereich" + right-aligned 3 status pips (lime 11 normal, danger 1 zu hoch, amber 1 zu niedrig). Below: 3-segment status bar visualization (lime 85% / danger 7% / amber 8%). Ghost "Bericht ansehen" button. Marker groups by category (Vitamine & Mineralstoffe / Blutfette / Hormone / Blutbild), each is a `Card` with rows: status dot (lime/danger/amber) + name + status label + norm range + value + trend arrow. Dashed "+ Neue Messung" tile.

**LabMarkerDetailView** — back "Labor", eyebrow "Vitamine · 25-OH", title "Vitamin D". Big value card: 56pt mono `38 ng/ml` + lime "● Normal" pill badge + delta "↑ 4 / 3 Mon." + right-aligned norm range "30–70 ng/ml". Below the value: **RangeScale** — horizontal track with amber low zone, lime normal zone, danger high zone, with a vertical text-color marker showing current position. Trend card with 1J/5J/Alles pills + **ChartWithBand** — LineChart with lime translucent fill across the normal range + dashed lime boundary lines. Tip card with lime icon. SectionHead "Einträge" → history rows: date + value + delta + source.

**LabAddView** — title "Neue Messung". 4-tile method picker: Foto (active, dark text-color tile w/ lime icon) · PDF · Manuell · HL7 / Praxis. Big camera preview area (very dark): faux Befund paper tilted slightly with monospace lab values list, scan corners (lime L-brackets at all 4 corners), blurred glass pill at top "● Befund erkannt · 8 Marker". SectionHead "Erkannte Werte" → list of detected values with check-mark approval checkboxes (lime when ticked). Bottom: full-width lime "Werte speichern".

### 7.7 Supplements & Meds (3)

**SupplementOverviewView** — eyebrow "14. Mai · heute", title "Supplements", plus CircleBtn. Adherence card: eyebrow "Heute eingenommen" + big "3 / 8" + lime "↑ 14T Streak" + right-aligned DonutMini (72px lime arc with center % label). 14-day adherence row (one cell per day; lime/amber/danger/dashed for today). Time-blocked schedule: 4 blocks (Morgens / Mittags / Abends / Vor Schlaf), each block header has bold time-label + mono clock-time + right "N/Total". Each block is a `Card` with rows: pill icon (kind: sup = capsule with lime when taken, med = circle with horizontal line) + name (strikethrough if taken) + meta (dose · mit Essen · note) + RX badge for meds + check button (lime when taken). Stock alert card with amber dot.

**SupplementDetailView** — back "Supplements", eyebrow "Vitamin · täglich", title "Vitamin D3 + K2", more CircleBtn. Top 2-up stat row: Adhärenz · 30T (96% mono, lime "29 / 30 Tage") | Bestand (84 Kapseln, "≈ 84 Tage"). 30-day calendar grid card: 15-col grid with lime cells (taken), red (missed), dashed border (planned/future). Legend below. SectionHead "Plan" → 5 KV rows: Dosis · Häufigkeit · Einnahme · Form · Erinnerung. SectionHead "Letzte Einnahmen" → 5 rows: date · status (lime check or red "verpasst" tag).

**SupplementAddView** — title "Neu hinzufügen". 3-tile kind picker: Supplement (active, text-color tile w/ lime icon) · Medikament · Pflanzlich. Details `Card` with 4 form rows: Name · Dosis (number + unit) · Form (chevron picker) · Bestand. "Wann" `Card` with two sub-sections divided by border: Häufigkeit pill chooser (Täglich active) + Zeitpunkte list (each is a row with checkbox + mono time + label; selected row has lime border + lime-tinted bg). Optionen `Card` with 3 toggle rows (Mit Essen · Erinnerung senden · Bestand nachverfolgen — all on). Bottom: full-width lime "Hinzufügen".

### 7.8 Insights & Profil (2)

**InsightsView** — eyebrow "14. Mai · diese Woche", title "Insights", filter CircleBtn. Time pill row: Woche (active) / Monat / 3M / Jahr. Hero black streak card: eyebrow "Streak · aktiv" + 60pt mono "12" + "Wochen" + 12-pip row (latest pip is lime, rest are translucent white). SectionHead "Persönliche Bestleistungen" → 3 rows: Bankdrücken 90 kg (with lime icon tile + "5×5 · neu" sub) · 5K Lauf 24:42 (-18s) · Deadlift 140 kg (1RM-Schätz.). Volume per muscle card: 5 horizontal bars (lime if >90% of period max, text-color otherwise), with mono labels and tabular kg values. AI Insight card with **lime border** + lime "● Beobachtung" eyebrow + body copy.

**ProfileView** — title "Profil" + settings CircleBtn. User card: avatar (initials) + name + email mono + lime "PRO" badge with bolt icon. Stats divider row: 3-up Workouts 148 · Läufe 32 · Streak 12W. Then 3 SettingsGroups, each is a labeled `Card` of rows. Each row has either a value + chevron (navigates), a value preview only, or a toggle. Groups: **Persönlich** (Ziele · Einheiten · Verbundene Geräte) · **App** (Erscheinungsbild · Erinnerungen · Live-Aktivitäten) · **Konto** (Datenexport · Datenschutz · Abmelden in danger color). App-version footer in mono.

---

## 8. Charts spec (Swift Charts)

### LineChart
- `LineMark` with `.interpolationMethod(.monotone)`
- Line width: `1.75pt`
- Domain padding: 15% top + 15% bottom of data range
- `accent: Bool` flag: line becomes lime + area fill `accent.opacity(0.12)`. Default: line is `text` color, area fill `text.opacity(0.06)`
- `baseline: Double?`: draws a dashed lime `RuleMark` at that y value (goals, targets)
- Y axis: 3 ticks (min/mid/max), 9pt Geist Mono, color textMuted, tabular figures
- Grid lines: 1pt solid `grid` token
- X axis: only show labels for points where `label != nil`

### BarChart
- `BarMark` with `cornerRadius` = halfWidth
- Faint track behind each bar at full height (use `RectangleMark` from 0 to max in `surface2`)
- Highlighted bar (today/current) → accent; others → text color

### Norm-band chart (lab)
- `RectangleMark` for band, fill `accent.opacity(0.08)`
- Two `RuleMark` dashed boundaries at `bandMin` and `bandMax`, color `accent.opacity(0.5)`
- Line drawn on top, **always text color** (not accent — the band already says "good")
- Dot on latest point: filled `bg`, stroke `text`, 2pt

### RangeScale (lab marker)
- Horizontal compound bar showing low (amber) / normal (lime) / high (danger) zones
- Value marker: vertical text-color line + circle at top (fill `bg`, stroke `text`)
- Tick labels at fullMin / normMin / normMax / fullMax

---

## 9. Tab bar

5 tabs, fixed order. Use SF Symbols as placeholders until custom icons exist:

| Key | Label | SF Symbol |
|---|---|---|
| `home` | Home | `house` |
| `train` | Training | `dumbbell` |
| `run` | Cardio | `figure.run` |
| `body` | Körper | `figure.stand` |
| `me` | Profil | `person.crop.circle` |

**Don't** use SwiftUI's default `TabView` chrome. Build a custom bottom HStack:
- 22pt icon, 10pt mono label, 6pt gap
- Active = `text` color; inactive = `textMuted`
- Gradient mask: `linear-gradient(to top, bg 70%, transparent)` so content fades behind it
- 76pt total height (8 top + 28 bottom safe-area + 40 content)
- Every screen reserves `paddingBottom: 100` so content doesn't sit under the bar

Lab and Supplements live in the "Körper" tab navigation stack (push view from there). They are not top-level tabs.

---

## 10. Data shape

```swift
// All IDs are UUIDs from Supabase.

enum MuscleGroup: String, Codable { case chest, back, legs, shoulders, arms, core, fullBody }

@Model final class User {
    @Attribute(.unique) var id: UUID
    var email: String
    var displayName: String
    var unitsKg: Bool = true      // false = lbs
    var unitsKm: Bool = true      // false = mi
    var createdAt: Date
}

@Model final class Workout {
    @Attribute(.unique) var id: UUID
    var userID: UUID
    var planDay: String?           // "A" / "B" / nil for free workouts
    var startedAt: Date
    var endedAt: Date?
    var volumeKg: Double           // computed, cached
    @Relationship(deleteRule: .cascade) var sets: [WorkoutSet] = []
}

@Model final class WorkoutSet {
    @Attribute(.unique) var id: UUID
    var workoutID: UUID
    var exerciseID: UUID
    var setNo: Int
    var weightKg: Double
    var reps: Int
    var rir: Int?
    var doneAt: Date
}

@Model final class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var muscleGroup: MuscleGroup
    var demoVideoURL: URL?
}

@Model final class Run {
    @Attribute(.unique) var id: UUID
    var userID: UUID
    var startedAt: Date
    var endedAt: Date
    var distanceM: Double
    var durationS: Int
    var gainM: Double
    var polyline: Data             // encoded [CLLocationCoordinate2D]
    var splitsJSON: String         // [{km, paceSecPerKm, avgBpm}]
}

enum BodyMetricType: String, Codable {
    case weight, bodyFat
    case chest, waist, hips, biceps, thigh, calf, shoulder, forearm, neck, ankle
}

@Model final class BodyMetric {
    @Attribute(.unique) var id: UUID
    var userID: UUID
    var ts: Date
    var type: BodyMetricType
    var value: Double
    var unit: String               // "kg" / "cm" / "%"
    var method: String?            // for bodyFat: "caliper" / "bia" / "photo"
}

@Model final class LabMeasurement {
    @Attribute(.unique) var id: UUID
    var userID: UUID
    var takenAt: Date
    var source: String             // "Hausarzt" / "Labor selbst" / ...
    var rawPDFURL: URL?            // Supabase Storage URL
    @Relationship(deleteRule: .cascade) var values: [LabValue] = []
}

@Model final class LabValue {
    @Attribute(.unique) var id: UUID
    var measurementID: UUID
    var marker: String             // "Vitamin D" / "Ferritin" / ...
    var value: Double
    var unit: String
    var refLow: Double
    var refHigh: Double
    var category: String           // "Vitamine & Mineralstoffe" / "Blutfette" / ...
}

enum SupplementKind: String, Codable { case supplement, medication, herbal }

@Model final class Supplement {
    @Attribute(.unique) var id: UUID
    var userID: UUID
    var name: String
    var kind: SupplementKind
    var dose: String               // "4000 IE / 200 µg"
    var form: String               // "Kapsel" / "Tablette" / "Pulver" / "Tropfen"
    var stockUnits: Int            // remaining count
    var frequency: String          // "daily" / "specific_days" / "cyclic" / "as_needed"
    var times: [String]            // ["07:30", "13:00"]
    var withFood: Bool
    var reminderOn: Bool
    var trackStock: Bool
    var note: String?
    @Relationship(deleteRule: .cascade) var intakes: [SupplementIntake] = []
}

@Model final class SupplementIntake {
    @Attribute(.unique) var id: UUID
    var supplementID: UUID
    var plannedAt: Date
    var takenAt: Date?             // nil = missed/pending
    var skipped: Bool = false
}
```

---

## 11. Critical flows

### Auth boot
1. App launch → check Keychain for `access_token` + `refresh_token`
2. Valid token: enter `MainTabView`
3. Invalid/missing: `NavigationStack` → SplashView (3s) → OnboardingView (or skip) → LoginView (or RegisterView)
4. Sign in with Apple uses `ASAuthorizationController`; the credential's identity token is exchanged at Supabase

### Active workout
- Workout state lives in `ActiveWorkoutViewModel` (`@Observable`)
- Background timer: keep screen awake (`UIApplication.shared.isIdleTimerDisabled = true`) while workout is active. **Don't** use `audio` background mode unless you have an actual audio reason (App Review will reject)
- Each set tap commits to SwiftData immediately — never lose a logged set
- Rest timer fires a `UNNotificationRequest` at the target time + a haptic when the screen is foreground
- "Beenden" sets `workout.endedAt`, computes `volumeKg`, syncs to Supabase

### Run tracking
- `CLLocationManager` with `kCLLocationAccuracyBest`, `desiredAccuracy = kCLLocationAccuracyBest`, `activityType = .fitness`
- Request `.authorizedWhenInUse` first, then **`.authorizedAlways` when user starts their first run** (with a clear pre-prompt screen explaining why)
- Add `UIBackgroundModes` → `location` to Info.plist
- Append every received location to the run's polyline; compute splits on-the-fly as the cumulative distance crosses km boundaries
- Pause/resume: stop appending but keep the manager active
- Heart-rate optionally via HealthKit during runs (separate permission)

### Lab OCR (v1 → v2)
- v1: `VisionKit.DataScannerViewController` with `recognizedDataTypes: [.text]`. Show detected text overlay. After capture, regex-extract known marker names + values. **Always show user the parsed list for confirmation before save.**
- v2: send the captured image to Mistral OCR / Google Vision for structured extraction. Same confirmation step.
- Reference ranges: maintain a built-in lookup table of common markers (Vitamin D, Ferritin, etc.) with default ranges. User can override per-measurement.

### Supplement notifications
- Schedule `UNCalendarNotificationTrigger` per time slot per active supplement
- Re-schedule on edit (cancel old, schedule new)
- Tapping notification deep-links to Today's plan with that row scrolled into view

---

## 12. Animations

Keep them tight:
- Tab switch: 250ms ease-out (SwiftUI default)
- Sheet present: `.sheet` default
- Toggle: 200ms spring
- Set check-off: scale-bounce on the checkmark, 150ms
- Streak pip increment: spring on the new pip

**No** parallax, no tilt, no hero animations between screens for v1. Hero animations are *one* per major flow at most; over-animating cheapens the design.

---

## 13. Localization

UI is German, du-form, but **always** route through `Localizable.strings` (`String(localized: "...")`). Even German-only v1. Adding English / French later is then trivial.

Naming convention: `dot.separated.lowercase` keys grouped by screen:
```
home.greeting.morning = "Guten Morgen"
home.today.eyebrow = "Heute · Tag %@"
workout.set.checkoff = "Satz abschließen"
```

---

## 14. Assets

- **Geist fonts**: download `.otf` from https://vercel.com/font (OFL, free). Add to bundle. Register in `Info.plist > UIAppFonts`. Reference as `"Geist"` and `"Geist Mono"` in `Font.custom(...)`.
- **App icon**: not yet designed. Placeholder = logomark (rounded square `#f6f6f7` + lime sparkline checkmark). Generate full icon set from a 1024×1024 source.
- **Launch screen**: iOS Launch Storyboard with `bg` color (`#0b0b0c` dark / `#f6f5f1` light) and the logomark centered. iOS handles dark/light auto.

---

## 15. Don'ts (hard rules)

- ❌ **No second accent color.** If a screen needs more than lime + monochrome, the layout is wrong
- ❌ **No gradients** as backgrounds. No glass effects beyond what the iOS system already does
- ❌ **No emoji** as functional UI
- ❌ **No Inter, Roboto, San Francisco.** The brand is Geist
- ❌ **No proportional numerics** — every number uses `monospacedDigit()`
- ❌ **No filler stats / motivational quotes / "did you know"**. Empty space is fine
- ❌ **No KI/AI/intelligent/powered-by speak** in copy. The AI Insight on InsightsView says "Beobachtung", not "Wir denken"
- ❌ **No custom alerts.** Use `.alert(...)`. No custom toasts beyond what the system offers
- ❌ **No async/await on the main thread** for repository calls — wrap in `Task { @MainActor in ... }` only at the UI boundary
- ❌ **Never lose user data.** Logged sets, completed runs, lab entries → all commit to SwiftData synchronously before any UI transition

---

## 16. Definition of done (v1)

A user can:
1. Sign up via email or Apple
2. Walk through onboarding once
3. See today's plan on Home
4. Start a planned workout, log 4–6 exercises × 3–4 sets each with weight/reps/RIR + rest timer, finish
5. Start a free workout (pick exercises from a list), same logging
6. Start a run, see live distance/time/pace/BPM + splits + elevation, pause/resume/finish, get a saved run with route map
7. Log weight, body fat, and at least 6 circumference measurements
8. Add a lab measurement via photo scan + confirm values, see one marker's trend over time
9. Add a supplement with schedule, get a notification at the scheduled time, tap to check off in-app
10. See their streak, top PRs, and weekly volume on Insights
11. Switch theme (or follow system), see version, sign out

All of the above must work **offline** with sync-on-reconnect.

---

## 17. Files in this handoff (if delivered as a bundle)

- `Trackify.html` — the canvas. Open and zoom each artboard for pixel reference.
- `screens-*.jsx` — React source for every screen. **Read these for layout truth.**
- `tokens.jsx` — the React version of design tokens, icon SVG, primitive components.
- `Trackify-deck.html` — 23-slide deck (1920×1080) for stakeholder reviews.
- `Trackify-overview.png` — single-image overview of all screens.
- `design_handoff_swift_ios/scaffolding/` — starter SwiftUI files (`DesignTokens.swift`, `Theme.swift`, primitives, charts, HomeView example).

**Build order suggestion:**
1. Xcode project, add Geist fonts, install Supabase Swift SDK
2. Drop in scaffolding → confirm `HomeView` renders in preview
3. Build out `TrainingPlanView` → `ActiveWorkoutView` (most complex flow first — get the data model + state shape right early)
4. Auth (Supabase email + Apple) so you can save real data
5. Cardio (RunLive needs CLLocationManager + background entitlement — biggest infra cost)
6. Body / Lab / Supplements (mostly forms + lists + charts — fast)
7. Insights / Profile (read-only, easy)

Good luck. Ping the design canvas whenever a screen feels off — the truth is there.
