# Trackify

> Mobile fitness-tracking app. iOS-first. Trains, runs, body metrics, lab values.
> Design language: **Refined Sport-Tech** — monochrome, lime accent, mono numerics.

---

## What this project is

A high-fidelity design system + clickable prototype for Trackify, built as iOS mockups arranged on a design canvas. The canvas (`Trackify.html`) is the source of truth — every screen lives there as a React component inside an `IOSDevice` frame on a `DCArtboard`.

The prototype is structured for handoff to development: each screen is a standalone React component, tokens are centralized, charts are reusable, and copy is in German (du-form).

---

## File layout

```
Trackify.html               ← main entry: design canvas + all sections + Tweaks
tokens.jsx                  ← themes (light/dark), icons, primitives, charts
screens-auth.jsx            ← Splash, Onboarding, Login, Register
screens-home.jsx            ← Dashboard
screens-training.jsx        ← Plan, Active Workout, Exercise Detail
screens-cardio.jsx          ← Run Live, Run History
screens-body.jsx            ← Weight, Body Fat, Measurements
screens-lab.jsx             ← Lab Overview, Marker Detail, Add Lab
screens-profile.jsx         ← Insights, Profile/Settings
design-canvas.jsx           ← starter: pan/zoom artboard host (don't edit)
ios-frame.jsx               ← starter: iPhone bezel (don't edit)
tweaks-panel.jsx            ← starter: Tweaks UI primitives (don't edit)

Trackify-deck.html          ← presentation deck (23 slides, 1920×1080) for PPTX/Canva export
Trackify (standalone).html  ← bundled offline build of the canvas

export/                     ← generated artifacts (PPTX, PDF, standalone HTML)
```

**Rule:** Never inline a screen into `Trackify.html`. Each screen is a function in its `screens-*.jsx` file, exported via `Object.assign(window, {...})`.

---

## Design system

### Aesthetic
**Refined Sport-Tech.** Mostly monochrome surface with one punchy lime accent. Editorial confidence, not maximalist data slop. No gradients, no emoji, no decorative SVG illustrations.

### Color tokens (`tokens.jsx → themes`)

| Token         | Dark         | Light        | Used for                                  |
|---------------|--------------|--------------|-------------------------------------------|
| `bg`          | `#0b0b0c`    | `#f6f5f1`    | screen background                         |
| `bgElev`      | `#101012`    | `#fafaf8`    | elevated background                       |
| `surface`     | `#161618`    | `#ffffff`    | cards                                     |
| `surface2`    | `#1c1c1f`    | `#efeeea`    | nested surfaces, chips, dividers          |
| `border`      | `0.08 white` | `0.08 black` | subtle separators                         |
| `borderStrong`| `0.14 white` | `0.14 black` | buttons, emphasized borders               |
| `text`        | `#f6f6f7`    | `#0b0b0c`    | primary                                   |
| `textMid`     | `#b8b8bd`    | `#3a3a3d`    | body copy                                 |
| `textMuted`   | `#76767c`    | `#86858a`    | meta, labels, eyebrows                    |
| `accent`      | `#c8ff3d`    | `#c8ff3d`    | THE accent — only on highlight / CTA      |
| `accentText`  | `#0b0b0c`    | `#0b0b0c`    | text on accent                            |
| `danger`      | `#ff6b4a`    | `#e0432a`    | over-target, errors, "zu hoch"            |

**Accent discipline.** Lime is reserved for: primary CTA, "today" state, positive delta, normal-range markers, focused inputs. Never decorative. Never two accents on screen.

A warm amber `#f5b13a` is used **only** for `zu niedrig` lab status. Don't generalize it.

### Type

- **Geist** (400/500/600/700) — UI
- **Geist Mono** (400/500/600) — numbers, metadata, eyebrows, badges

Always:
- Numbers use `fontFamily: 'Geist Mono, monospace'` + `fontVariantNumeric: 'tabular-nums'`.
- Eyebrows/labels/section heads are mono, uppercase, `letterSpacing: 0.6–1.2`, color `textMuted`.
- Large titles: `letterSpacing: -1` to `-3.5`, `fontWeight: 600`.
- Body text: 14–15px, line-height 1.4.
- No `font-style: italic` anywhere.

### Spacing & radii

- Screen padding: `20px` horizontal
- Card radius: `18–22px` (rows in cards: `14px`)
- Pill radius: `999`
- Vertical rhythm: section gaps `12–18px`, intra-card gaps `8–14px`
- TabBar reserves bottom `100px` of every screen via padding-bottom

### Components (in `tokens.jsx`)

- `Screen` — screen frame, bg, font
- `ScreenHeader` — large title + eyebrow + back + action
- `SectionHead` — uppercase mono section label + action link
- `Card` — `surface` + `border` + radius 22, configurable pad
- `PrimaryButton` (accent, height 52, pill) / `GhostButton` (transparent + borderStrong)
- `CircleBtn` (40×40 surface2)
- `LineChart` — thin stroke, optional axis, `accent` flag, `baseline` for goal lines
- `BarChart` — rounded bars, `today` highlight
- `TabBar` — 5-slot bottom nav (`home / train / run / body / me`)
- `Stat` — label + value + unit + delta
- Icons via `I.*` — single-stroke, currentColor, sized at call site

**Never invent a new card chrome.** Compose with `<Card>`. Never invent buttons; reuse `Primary`/`Ghost`/`Circle`.

### Charts

- 1.75px stroke for lines, 1px for grid
- Axes: 9px mono labels, color `textMuted`
- Always tabular-num for axis ticks
- Norm ranges as faint accent-tinted band + dashed accent baseline
- Use `accent` flag only when the metric IS positive (volume, distance). For weight/BF, use neutral `text` stroke.

---

## Conventions

### Language
**German, du-form, locker aber präzise.** Lowercase mid-sentence in copy where it reads tighter ("vergessen?", "+ Eintragen"). Eyebrows uppercase mono. Never use AI-speak ("KI", "intelligent", "powered by"). When the app speaks, use first-person plural sparingly ("Beobachtung", not "Wir denken").

### Numbers
- German decimals: `72,4` not `72.4`
- Thousands: `18.420` not `18,420`
- Always with unit, but unit is `textMuted` and smaller (10–13px when the number is 16–60px)

### Status semantics
- accent (lime) = good / normal / current
- danger (red) = above-target, error
- amber (`#f5b13a`) = below-target (lab only)
- textMuted (gray) = unchanged / inactive

### iOS frame
Use `IOSDevice` from `ios-frame.jsx`. Never draw your own status bar or home indicator. Screens fill `width 402 × height 874`. Don't add `IOSNavBar` — screens have their own `ScreenHeader` with `54px` top inset to clear the status bar.

### Tab bar
Pass `active="home"|"train"|"run"|"body"|"me"`. Labels are fixed: `Home`, `Training`, `Cardio`, `Körper`, `Profil`.

---

## Adding a new screen

1. Pick the right `screens-*.jsx` file (or create a new one if it's a new top-level area).
2. Write a function `function MyScreen() { const t = useTheme(); return (<Screen theme={t}>…</Screen>); }`.
3. Export at the bottom: `Object.assign(window, { MyScreen });`.
4. If you created a new file, add a `<script type="text/babel" src="screens-mine.jsx"></script>` line to `Trackify.html` (after the other screens scripts).
5. Add an `<DCArtboard id="..." label="..." width={402} height={874}>` inside the matching `<DCSection>` in `Trackify.html`. If it's a whole new flow, add a new `<DCSection>`.
6. If the screen has a deck slide, mirror it in `Trackify-deck.html`: add a `<section>` with the slide layout and a `<div class="phone-shell" data-mount="my-screen"></div>`, then register in the `screenMap` of the mount script.

### What goes on a screen, what doesn't
- ✅ Status of right-now data
- ✅ One primary action per screen (the only `PrimaryButton`)
- ✅ Trends contextual to the screen's metric
- ❌ Filler stats / "did you know"
- ❌ Onboarding tips inside production screens
- ❌ Decorative icons next to every label

---

## Tweaks

`Trackify.html` exposes a Tweaks panel (right side, toggle in toolbar):
- `theme`: `dark` / `light`
- `accent`: 4 swatches

To add a tweak, edit the `TWEAK_DEFAULTS` block in `Trackify.html` (between the `EDITMODE-BEGIN`/`END` markers — must remain valid JSON) and add a control in the `<TweaksPanel>` JSX below.

Tweaks must apply via the live `liveTheme` object, not by mutating `themes`.

---

## Export targets

### Standalone HTML
`Trackify (standalone).html` — single offline file bundled from `Trackify.html`. Regenerate when the canvas changes:
```
super_inline_html: Trackify.html → Trackify (standalone).html
```
(Add the `__bundler_thumbnail` template; see git history for the SVG used.)

### Deck (PPTX / Canva)
`Trackify-deck.html` — 23-slide 1920×1080 deck for stakeholder review. Each slide pairs a copy block (left) with one phone screen (right), mounted from the same React components as the canvas.
- Cover, 6 section dividers, 15 screen slides, end card
- Background `#0b0b0c`, lime accent retained
- Editable PPTX export → `export/Trackify.pptx` → Canva import works

When adding a screen, ALSO add a slide for it in `Trackify-deck.html` and a mapping in the `screenMap`.

---

## Roadmap to a real app

When this leaves the design phase, the rough plan is:

- **Stack:** React Native + Expo. Or SwiftUI native if iOS-only matters more than dev velocity.
- **State:** TanStack Query for server state, Zustand for local. Form: react-hook-form + zod.
- **Charts:** Victory Native XL or D3 + react-native-svg. The current `LineChart`/`BarChart` API translates 1:1.
- **Backend:** Supabase (auth + Postgres + RLS) is enough for v1. Polar/Whoop/Apple Health integrations via HealthKit on iOS.
- **Auth:** Email/password + Sign in with Apple (required by App Store for social auth) + Google.
- **Storage:** lab PDFs/photos → Supabase Storage, OCR via Google Cloud Vision or Mistral OCR.
- **Offline-first:** workouts must be loggable offline (gym wifi/dead spots). PowerSync or Watermelon.

### Data shape sketch

```
users
workouts          (id, user_id, plan_day, started_at, ended_at, volume_kg)
sets              (id, workout_id, exercise_id, set_no, weight_kg, reps, rir, done_at)
exercises         (id, name, muscle_group, demo_video_url)
runs              (id, user_id, started_at, distance_m, duration_s, gain_m, polyline, splits jsonb)
body_metrics      (id, user_id, ts, type, value, unit)   -- type: weight|bf|chest|...
lab_measurements  (id, user_id, taken_at, source, raw_pdf_url)
lab_values        (id, lab_measurement_id, marker, value, unit, ref_low, ref_high)
```

### Translation map (design → real components)

| Mockup component       | RN equivalent                                   |
|------------------------|-------------------------------------------------|
| `Screen`               | `SafeAreaView` + themed bg                      |
| `Card`                 | `View` with shadow + border                     |
| `PrimaryButton`        | Pressable + haptic                              |
| `LineChart`            | `victory-native`'s `<CartesianChart>` + `<Line>` |
| `IOSDevice`            | DROP — real device IS the frame                 |
| `TabBar`               | `expo-router` `Tabs` with custom `tabBarButton` |
| `useTheme()`           | `useColorScheme()` + ThemeContext               |

When porting, **preserve the exact token values** from `tokens.jsx`. The mono/accent recipe is the brand.

---

## Don'ts

- ❌ Don't add gradient backgrounds, "glass" effects beyond the iOS status bar, or hero illustrations
- ❌ Don't use emoji as functional icons
- ❌ Don't add `Inter`, `Roboto`, or system fonts — the brand is Geist
- ❌ Don't introduce a second accent color. If a screen needs more than lime + monochrome, the layout is wrong
- ❌ Don't pad screens with filler ("Did you know…", motivational quotes)
- ❌ Don't draw your own status bar/keyboard — use `IOSDevice` props
- ❌ Don't write tabular numerics in proportional figures
