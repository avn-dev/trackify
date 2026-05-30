# Handoff: Trackify (iOS / SwiftUI)

## Overview

Trackify is a mobile fitness-tracking app: workouts, runs, body metrics, and lab values, with a focus on clear data display and a single visual identity (monochrome + lime accent, mono numerics).

This bundle contains the **finished high-fidelity design** (16 screens) and **starter SwiftUI scaffolding** to implement it as a native iOS app.

## About the design files

The files in `references/` are **design references created in HTML/React**. They are prototypes that show the intended look, layout, copy, and interactions — **not production code to ship**. Your task is to recreate them in SwiftUI using the patterns of a real Swift iOS app (proper navigation, state management, persistence, etc.).

The files in `scaffolding/` are **starter Swift code** that translates the design system (tokens, primitives, charts) into idiomatic SwiftUI. Build the rest of the app on top of those.

## Fidelity

**High-fidelity.** All colors, type, spacing, radii, and copy are final. The HTML prototype matches what should ship. Pixel-perfect recreation is the goal.

---

## Target platform

- **iOS 17+** (uses `Observation`, `@Observable`, native `Chart` from Swift Charts)
- **SwiftUI**, no UIKit (except where unavoidable — e.g. `MapKit` for the run route)
- **Swift 5.9+**
- Bundle ID suggestion: `app.trackify.ios`
- Display name: `Trackify`

### Recommended dependencies

- `Swift Charts` (built-in) — for `LineChart`, `BarChart`
- `MapKit` (built-in) — for the run-history route view
- `HealthKit` (built-in) — heart rate during runs, weight import if user opts in
- **Supabase Swift SDK** — auth + DB + storage
- **KeychainAccess** — auth tokens
- **Sign in with Apple** is **required by App Store** for any app that has social login (Google sign-in is fine, but Apple must be offered alongside)

---

## App architecture

```
TrackifyApp.swift              // @main entry
RootView.swift                 // auth gate → AuthFlow or MainTabView

Core/
  DesignTokens.swift           // colors, fonts, spacing, radii  ← in scaffolding/
  Theme.swift                  // light/dark Theme struct        ← in scaffolding/
  Components/
    Card.swift                 // ← in scaffolding/
    Buttons.swift              // PrimaryButton, GhostButton, CircleBtn
    ScreenHeader.swift
    SectionHead.swift
    Stat.swift
    TabBar.swift               // (use SwiftUI TabView; custom item style)
  Charts/
    LineChart.swift            // wraps Swift Charts
    BarChart.swift
    RangeScale.swift           // lab marker norm-band

Features/
  Auth/
    SplashView.swift
    OnboardingView.swift
    LoginView.swift
    RegisterView.swift
    AuthViewModel.swift
  Home/
    HomeView.swift             // ← example port in scaffolding/
  Training/
    TrainingPlanView.swift
    ActiveWorkoutView.swift
    ExerciseDetailView.swift
    TrainingViewModel.swift
  Cardio/
    RunLiveView.swift
    RunHistoryView.swift
    RunTracker.swift           // CLLocationManager wrapper
  Body/
    WeightView.swift
    BodyFatView.swift
    MeasurementsView.swift
    BodySilhouetteView.swift
  Lab/
    LabOverviewView.swift
    LabMarkerDetailView.swift
    LabAddView.swift
    LabOCRService.swift        // VisionKit or external OCR
  Profile/
    InsightsView.swift
    ProfileView.swift

Data/
  Models/                      // workout, run, body, lab structs
  Repositories/                // protocol-based; SupabaseImpl + MockImpl
  PersistedStore.swift         // SwiftData or GRDB for offline-first
```

### State

- `@Observable` view models per feature (iOS 17+ `Observation` framework)
- Repository pattern with a protocol so views consume a `WorkoutRepository`, not Supabase directly — makes previews and tests trivial with a `MockRepository`
- Offline-first: workouts must save locally first, then sync. Use **SwiftData** for v1 (acceptable trade-off; consider GRDB if you outgrow it).

### Auth

- Email + password via Supabase
- Sign in with Apple (`AuthenticationServices`) — App Store requirement
- Sign in with Google via `GoogleSignIn-iOS`

---

## Design tokens

The full token table lives in `references/CLAUDE.md` and is translated to Swift in `scaffolding/DesignTokens.swift`.

### Colors

| Token         | Dark         | Light        |
|---------------|--------------|--------------|
| bg            | `#0b0b0c`    | `#f6f5f1`    |
| bgElev        | `#101012`    | `#fafaf8`    |
| surface       | `#161618`    | `#ffffff`    |
| surface2      | `#1c1c1f`    | `#efeeea`    |
| border        | white 8%     | black 8%     |
| borderStrong  | white 14%    | black 14%    |
| text          | `#f6f6f7`    | `#0b0b0c`    |
| textMid       | `#b8b8bd`    | `#3a3a3d`    |
| textMuted     | `#76767c`    | `#86858a`    |
| **accent**    | `#c8ff3d`    | `#c8ff3d`    |
| accentText    | `#0b0b0c`    | `#0b0b0c`    |
| danger        | `#ff6b4a`    | `#e0432a`    |
| amber (lab only) | `#f5b13a` | `#f5b13a`    |

**Accent rule:** Lime appears only for primary CTA / "today" state / positive deltas / normal-range markers / focused inputs. Never decorative.

### Typography

- **Geist** (UI), **Geist Mono** (numbers / metadata / eyebrows)
- Numbers ALWAYS use Geist Mono + tabular figures (`monospacedDigit()` on Font)
- Title sizes: 26 / 30 / 34, weight 600, tight tracking (-1 to -3.5)
- Body: 14–15, line-height 1.4
- Eyebrow: 11pt mono, uppercase, letterSpacing 0.6–1.2, color `textMuted`

Geist is **OFL-licensed and free**: https://vercel.com/font. Add the `.otf` files to the bundle, declare in `Info.plist` under `UIAppFonts`.

### Spacing & radii

- Screen padding: 20pt horizontal
- Card radius: 18–22, row radius inside card: 14
- Pill: full round (button height / 2)
- TabBar height: 76 (8 top, 28 bottom safe-area, 40 content)
- Section gaps: 12–18

---

## Screens

Each screen below is a top-level View. Pixel-perfect references are in `references/Trackify.html` (open and zoom — the artboard labels match the section names).

### Auth (4)

| Screen | Purpose | Key elements |
|---|---|---|
| **Splash** | Brand reveal on cold launch | Logomark, wordmark "Trackify", tagline "train · run · measure" in mono; dot pagination ghost |
| **Onboarding** | 3-step value pitch | Mini stat-card preview, dot pagination (active = elongated lime), skip button top-right, lime arrow CTA |
| **Login** | Returning user | Email + password fields (rounded, eyebrow-style label), "vergessen?" affordance, lime PrimaryButton, divider "oder weiter mit", Google + Apple ghost buttons |
| **Register** | New account | Same field treatment + checkbox row for AGB; back chevron top |

Behavior: all 4 auth screens stack inside a `NavigationStack`. On success → `MainTabView`.

### Home (1)

| Screen | Purpose | Key elements |
|---|---|---|
| **HomeView (Dashboard)** | Today snapshot | Greeting + date eyebrow; hero card (black/text-color bg) with today's training-day, mini-meta, lime "Workout starten" CTA; 2-up stat row (week grid + volume sparkline); 3-up quick-track tiles (Lauf · Gewicht · Maße); weight trend card |

### Training (3)

| Screen | Purpose | Key elements |
|---|---|---|
| **TrainingPlanView** | Pick a day | Pill nav (Mein Plan / Vorlagen / Verlauf); list of day cards (today is fully-inverted; others surface); dashed "+ Freies Workout" tile |
| **ActiveWorkoutView** | Live set logging | Live indicator + day name, big clock (mono, 52pt), volume counter; segmented progress bar; focused exercise card with set table (Set · Kg · Wdh · RIR), active row highlighted, rest-timer card with skip; bottom: lime "Satz abschließen" + pause CircleBtn |
| **ExerciseDetailView** | Per-exercise history | Hero video placeholder (striped pattern); 3-up stat row (1RM est. · letztes Mal · Sätze ges.); 4-week LineChart with accent; verlauf list |

### Cardio (2)

| Screen | Purpose | Key elements |
|---|---|---|
| **RunLiveView** | Track current run | Live + GPS chip; massive distance (88pt mono); 3-col stat (Zeit · Pace · BPM) with column dividers; elevation sparkline; km-splits list with bar visualization + "best" highlight; 3-button bottom (stop / pause hero / LAP) |
| **RunHistoryView** | Past runs + month rollup | Month summary card with weekly BarChart; recent runs list with mini route SVG thumbnails; embedded hero map for selected run |

### Body (3)

| Screen | Purpose | Key elements |
|---|---|---|
| **WeightView** | Weight trend | Range toggle (1W/1M/3M/1J/Alles); LineChart with dashed accent goal-line; 3 stats; entry log with daily delta |
| **BodyFatView** | BF% trend | Donut ring (38pt mono center, lime stroke); 6-month LineChart; 3 measurement methods with active dot |
| **MeasurementsView** | Circumference measurements | Body silhouette SVG with measurement bands (chest/waist/hips), tag cards with connector dotted lines; "Diese Woche" secondary measurements grid |

### Lab (3)

| Screen | Purpose | Key elements |
|---|---|---|
| **LabOverviewView** | All blood markers | Summary card (X/Y im Normbereich) + 3-segment status bar; markers grouped by category (Vitamine, Blutfette, Hormone, Blutbild), each row: status dot + name + status badge + value + trend; dashed "+ Neue Messung" CTA |
| **LabMarkerDetailView** | Single marker trend | Big value + status badge; horizontal range-scale showing low/normal/high zones with value marker; LineChart with **normal-range band** (faint lime fill + dashed boundaries); tip card; history list with source (Hausarzt / Labor selbst) |
| **LabAddView** | Add new measurement | 4-tile method picker (Foto / PDF / Manuell / HL7) with first active; large camera preview area showing scan corners + "Befund erkannt · 8 Marker" pill; auto-detected values list with checkbox-style approvals; bottom: lime "Werte speichern" |

### Profile (2)

| Screen | Purpose | Key elements |
|---|---|---|
| **InsightsView** | Stats roll-up | Hero black streak card with 12-week pip row; PR list (3 rows); muscle-group volume horizontal bars; AI "Beobachtung" card with lime border |
| **ProfileView** | Settings | User card with avatar + 3-up stat divider; 3 settings groups (Persönlich · App · Konto) with rows that can show: navigation chevron, value preview, or toggle; app version footer |

---

## Charts (Swift Charts)

The HTML prototype uses custom SVG charts. In SwiftUI use **Swift Charts** with these rules:

### LineChart
- `LineMark` interpolation: `.monotone`
- Line width: `1.75pt`
- Domain padding: 15% top/bottom of data range
- Show only min/mid/max y-ticks (`AxisMarks` with custom selector)
- Tick labels: 9pt Geist Mono, color textMuted, tabular figures
- Grid: 1pt solid, color `grid` token (white/black at ~6% alpha)
- Variants: `accent: Bool` — switches line color to lime + adds a faint accent area-fill (opacity 0.12)
- `baseline: Double?` — dashed lime horizontal line for goals/targets

### BarChart (weekly volume etc)
- `BarMark` with `cornerRadius` half-width
- Track behind every bar at full height (`surface2`)
- Today/highlight bar → accent, others → text color

### Norm-band chart (lab)
- `RectangleMark` for the band, fill `accent.opacity(0.08)`
- Two `RuleMark` boundaries, dashed `accent.opacity(0.5)`
- Line on top, color `text`, no accent
- Dot on the latest point: filled with `bg`, stroke `text`, 2pt

---

## Tab bar

5 tabs, labels and SF Symbol fallbacks (replace with custom icons later):

| Tab key | Label    | SF Symbol (placeholder)  |
|---------|----------|--------------------------|
| home    | Home     | `house`                  |
| train   | Training | `dumbbell`               |
| run     | Cardio   | `figure.run`             |
| body    | Körper   | `figure.stand`           |
| me      | Profil   | `person.crop.circle`     |

Use a custom `TabBar` view (SwiftUI's default tab style adds chrome we don't want). Style: bottom-anchored, transparent gradient over content, 22pt icons, 10pt labels.

---

## Conventions

### Language
- **German, du-form** throughout
- Lowercase mid-sentence where it tightens copy ("vergessen?", "+ Eintragen")
- Eyebrows uppercase mono
- No "KI" / "AI" / "powered by" / "intelligent"
- Locale strings via `Localizable.strings` even if German-only for now — makes future locales painless

### Numbers
- German decimal: `72,4` not `72.4`. Use `NumberFormatter` with `locale = Locale(identifier: "de_DE")`
- Thousands: `18.420` not `18,420` — same formatter
- Always show unit, but unit is smaller and uses `textMuted`

### Time / Date
- Date format: `12. Mai 2026` (medium), `08. Mai` (short, when year is current)
- Time: 24h, `HH:mm`
- Workout duration / pace: `MM:SS` or `H:MM:SS` for runs > 1h
- All time labels in Geist Mono

### Status semantics
- Lime accent = good / normal / current / positive delta
- Danger red = above-target / error
- Amber `#f5b13a` = below-target — **lab only**, don't generalize
- textMuted gray = unchanged / inactive

---

## Interactions & state

### Auth flow
1. App boot → check Keychain for token
2. Valid token → `MainTabView`
3. No / invalid → `NavigationStack` containing `SplashView` → auto-advance to `OnboardingView` (or skip if returning) → `LoginView` (or `RegisterView`)

### Active workout
- Background-runnable timer (needs `audio` background mode + a silent audio loop, OR keep the screen awake while in-app)
- Rest timer fires haptic + sound when done; user can swipe to skip
- Sets persist on tap-to-check; the workout is one row that gets `ended_at` set on "Beenden"

### Run tracking
- `CLLocationManager` with `kCLLocationAccuracyBest`
- Background location entitlement required
- Pause/lap state lives in `RunTracker` actor; UI observes via `@Observable`
- Splits computed on-the-fly per kilometer crossing

### Lab OCR
- v1: `VisionKit.DataScannerViewController` for live capture + manual confirmation
- v2: send to OCR service (Mistral OCR or Google Cloud Vision) for structured extraction
- Always confirm before save — never auto-import

---

## Animations & transitions

Keep them tight:
- Tab switch: 250ms ease-out (SwiftUI default is fine)
- Sheet present: SwiftUI `.sheet` default
- Toggle: 200ms spring
- Set check-off: small scale bounce on the checkmark, 150ms

No hero animations between screens for v1. No parallax. No tilt.

---

## Data shape

```swift
// Identifiers are Supabase UUIDs

struct User { let id: UUID; let email: String; let displayName: String }

struct Workout {
    let id: UUID; let userID: UUID
    let planDay: String?           // "A" / "B" / nil for free workouts
    let startedAt: Date; let endedAt: Date?
    let volumeKg: Double
    let sets: [WorkoutSet]
}
struct WorkoutSet {
    let id: UUID; let workoutID: UUID
    let exerciseID: UUID; let setNo: Int
    let weightKg: Double; let reps: Int; let rir: Int?
    let doneAt: Date
}
struct Exercise {
    let id: UUID; let name: String; let muscleGroup: MuscleGroup
    let demoVideoURL: URL?
}

struct Run {
    let id: UUID; let userID: UUID
    let startedAt: Date; let endedAt: Date
    let distanceM: Double; let durationS: Int; let gainM: Double
    let polyline: [CLLocationCoordinate2D]
    let splits: [RunSplit]
}
struct RunSplit { let km: Int; let paceSecPerKm: Int; let avgBpm: Int? }

enum BodyMetricType: String { case weight, bodyFat, chest, waist, hips, biceps, thigh, calf, shoulder, forearm, neck, ankle }
struct BodyMetric {
    let id: UUID; let userID: UUID
    let ts: Date; let type: BodyMetricType
    let value: Double; let unit: String
}

struct LabMeasurement {
    let id: UUID; let userID: UUID
    let takenAt: Date; let source: String       // "Hausarzt", "Labor selbst", ...
    let rawPDFURL: URL?
    let values: [LabValue]
}
struct LabValue {
    let id: UUID; let measurementID: UUID
    let marker: String                          // "Vitamin D", "Ferritin", ...
    let value: Double; let unit: String
    let refLow: Double; let refHigh: Double
}
```

Persist with **SwiftData** for v1 (matching `@Model` types). Sync layer pushes to Supabase Postgres on connectivity.

---

## Assets

- **Geist & Geist Mono** fonts — download from https://vercel.com/font (OFL, free), add `.otf` files to bundle, register in `Info.plist > UIAppFonts`
- **App icon** — not designed yet; placeholder is the logomark (rounded square + lime checkmark sparkline). Generate the full icon set from a 1024×1024 source.
- **Splash screen** — use the Logomark + wordmark; iOS Launch Storyboard with `bg` as the background color (will swap to dark/light by system appearance).

---

## Files in this bundle

```
README.md                          ← this file (everything you need to start)
scaffolding/
  DesignTokens.swift               ← all colors, fonts, spacing as Swift constants
  Theme.swift                      ← Theme struct + .light/.dark + EnvironmentKey
  Components/Card.swift            ← Card + SectionHead + Eyebrow
  Components/Buttons.swift         ← PrimaryButton, GhostButton, CircleBtn
  Components/ScreenHeader.swift    ← Large title + eyebrow + back/action
  Components/Stat.swift            ← Number + unit + delta primitive
  Charts/LineChart.swift           ← Swift Charts wrapper
  Charts/BarChart.swift
  Features/Home/HomeView.swift     ← Example port of one full screen
references/
  Trackify.html                    ← canvas — open and zoom artboards for pixel reference
  Trackify (standalone).html       ← single-file offline version
  Trackify-deck.html               ← 23-slide deck (1920×1080)
  CLAUDE.md                        ← short design-system summary
  *.jsx                            ← React source of every screen (read for layout truth)
```

Open `Trackify.html` in a browser to navigate the canvas. Each artboard label = one screen in this README. To see a screen full-size, click the expand icon on the artboard or hit it once to focus (←/→/Esc work).

Don't ship the HTML. It's the spec, not the product.
