# TubeTrainer — Localization Plan

_Working document. Last updated 2026-09-16._

## TL;DR verdict

Your instinct is right: **TubeTrainer is small and this is a low-effort job** — but not for the
reason you might think. The win isn't that the app is tiny (it is); it's that **the app has almost
no long-form text**. There are no exercise instruction paragraphs, no articles, no onboarding
essays. The coaching content is YouTube videos the user brings themselves, so **none of the actual
"content" needs translating** — only the app chrome and ~54 exercise names.

The effort is **front-loaded into the first language (Spanish)**. Once the plumbing is in, every
additional language is just a translation pass over the same ~210 short strings — a few hours each,
largely automatable.

---

## The translatable surface (measured, not guessed)

| Bucket | Count | Where | Auto or manual |
|---|---:|---|---|
| **UI string literals** (`Text("…")`, `Button`, `navigationTitle`, alerts, section headers…) | ~144 | Across `TubeTrainer/Features/**` and `DesignSystem/**` | **Auto-extracted** by Xcode String Catalog |
| **Exercise names** | 54 | `TubeTrainer/Persistence/SeedCatalog.swift` | **Manual** (data-layer) |
| **Muscle-group + equipment labels** | ~14 | `TubeTrainer/Models/Enums.swift`, `Models.swift` | **Manual** (data-layer) |
| **"You" tab settings option labels** | ~6 | `WeightUnit` / `AppearancePreference` `.label` (`YouView.swift`) | **Manual** (data-layer) |
| **In-app Privacy prose block** | 1 paragraph | `YouView.swift:307` | **Auto-extracted**, but a real paragraph to translate |
| **Dynamic count/date strings** (History, Today, Complete) | ~6 format strings | `HistoryView.swift`, `Formatters.swift` | **Manual** — catalog plurals + locale formatters |
| **Search aliases** (synonyms so in-language search works) | ~150 | `SeedCatalog.swift` | **Manual, optional** (polish) |
| **App Store metadata** (name, subtitle, keywords, description, screenshot captions) | ~1 page | App Store Connect | **Manual, per language** |

**Core translatable strings for a solid release: ~210** (UI + names + labels). Aliases are optional
polish. For context: the entire app is 58 Swift files / ~8,500 lines, and there is **no** existing
localization infrastructure yet (no String Catalog, no `.strings`, no `String(localized:)`).

---

## How SwiftUI localization actually works here (the one gotcha)

SwiftUI auto-localizes **string _literals_** passed to `Text`, `Button`, etc. Xcode extracts them
into a **String Catalog** (`.xcstrings`) at build time. So the ~144 UI strings are essentially free —
add the catalog, build, translate the generated entries.

The catch is **runtime `String` variables are NOT auto-localized**:

- `Text(exercise.name)` — `TTExerciseRow.swift:41`, `WorkoutPlanView.swift:185`, others
- `Text(equipment.rawValue)` — `ExercisePickerView.swift:119` (showing an enum raw value directly)
- `Text(exercise.category.shortName)` — `TTExerciseRow.swift:47`
- **"You" tab settings pickers** — `Text($0.label)` for `WeightUnit` (kg/lb) and
  `AppearancePreference` (System/Light/Dark) at `YouView.swift:83` and `:162`. The `.label` computed
  properties return hardcoded English → must go through `String(localized:)`. **Every option a user
  can pick in Settings has to read correctly in their language, not just the section titles.**

These render data, not literals, so they bypass auto-localization. This is the **only real
engineering** in the whole project: make the exercise catalog and the enum labels localizable at the
data layer. Two clean options:

1. **`String(localized:)` on display** — give `MuscleCategory`/`Equipment` a `displayName` computed
   via `String(localized:)`, and localize exercise names through a lookup keyed on a stable English
   base name. Names stay English in the DB (stable IDs, search still works), display is localized.
2. **Localize the seed at first launch** — translate names when seeding. Simpler, but ties stored
   data to the install language (bad if the user switches language later). **Prefer option 1.**

### Dynamically-generated strings (the History tab especially)

This is the most involved slice — runtime-assembled text that neither auto-localizes nor translates
as flat strings. Three distinct problems:

1. **Interpolated count + noun → needs plural rules.** These weld English nouns to numbers:
   - `"\(count) exercises · \(setCount) sets · \(duration)"` — `HistoryView.swift:111`
   - `"\(session.completedSetCount) sets · \(duration)"` — `HistoryView.swift:141`
   - `"Set \(set.setNumber)"` — `HistoryView.swift:149`
   - stat-tile labels "Workouts" / "Sets" / "This week" — `HistoryView.swift:53–55` (literals, auto-OK)

   Spanish/German/pt-BR pluralize differently ("1 serie" vs "2 series"), and some languages reorder
   number and noun. Convert these to **String Catalog format strings with plural variations**
   (`%lld exercises` → one/other per language). Do **not** ship `count + " " + noun`.

2. **Dates → locale templates, not fixed formats.** Fixed `dateFormat` strings localize the month
   and weekday *names* but keep English word order and hardcoded 24-hour time:
   - Month headers `"MMMM yyyy"` — `HistoryView.swift:84`
   - `"EEE d MMM · HH:mm"` — `Formatters.swift:81` (`dayAndTime`)
   - `"EEEE"`, `mediumDate` — `Formatters.swift:66,72`

   Switch to `setLocalizedDateFormatFromTemplate(...)` or `Date.FormatStyle`, so order and 12/24-hour
   follow the user's locale.

3. **Numbers → locale separators.** `TTFormat.number()` (`Formatters.swift:10`) must format via a
   locale-aware formatter (Spanish/German use a comma decimal: `12,5 kg`).

**Silver lining:** dates, durations, clock and weight formatting are **all centralized in
`TubeTrainer/Utilities/Formatters.swift`**, so problems 2 and 3 are a single-file fix. Only the
plural count-strings (problem 1) live in the views — and they're a short, findable list. Audit other
tabs for the same `"\(count) noun"` pattern (Today summary, workout-complete screen) while you're in
there.

Units (kg/lb) are already a user setting, so no locale coupling needed there.

---

## Design principles — the elegant, minimum-code way

**The test of elegance for this project: adding language #4 must touch _zero_ Swift code, and adding a
new exercise or setting must touch _zero_ localization plumbing.** If either forces code edits, we've
built the grind-forever version. Everything below is designed to hit that bar.

The "bullshit again and again" anti-patterns we explicitly avoid: per-language `switch` statements,
hand-maintained `.strings`/`.stringsdict` files, parallel translation dictionaries, and — worst —
**concatenating localized fragments** (`count + " " + noun`), which silently breaks word order and
plurals in every non-English language.

### One catalog does ~95% of the work
A single **`Localizable.xcstrings`** String Catalog. Xcode auto-extracts every UI _literal_ at build,
holds **plural variations inline** (no separate `.stringsdict`), and is the one file translators
touch. Adding a language = **adding a column in that file.** No code.

### Self-localizing enums — one line each, zero per-case boilerplate
All the display enums (`MuscleCategory`, `Equipment`, `WeightUnit`, `AppearancePreference`) are
`String`-backed with stable `rawValue`s, so one generic default implementation covers all of them:

```swift
protocol LocalizedDisplayable: RawRepresentable where RawValue == String {}
extension LocalizedDisplayable {
    // Key is derived, e.g. "Equipment.barbell" — no hand-written cases.
    var displayName: String {
        String(localized: .init("\(String(describing: Self.self)).\(rawValue)"))
    }
}
extension MuscleCategory: LocalizedDisplayable {}     // ← the entire cost per enum
extension Equipment: LocalizedDisplayable {}
extension WeightUnit: LocalizedDisplayable {}
extension AppearancePreference: LocalizedDisplayable {}
```

Add a new case → it derives its own key; you just fill the translation in the catalog. Then delete
the `.rawValue`/`.shortName`/`.label` display shortcuts and route the handful of call sites through
`displayName`.

### Exercise names key off themselves — no translation table
The 54 seed names _are_ stable identifiers. One helper resolves display:

```swift
extension Exercise {
    var displayName: String { String(localized: .init(name)) }   // "Barbell Bench Press" → catalog
}
```

Every `Text(exercise.name)` becomes `Text(exercise.displayName)` (a few call sites). The magic:
`String(localized:)` **returns the key unchanged when no translation exists** — which is exactly the
right behaviour for **user-created custom exercises** (show what they typed) with no extra code. 54
catalog entries, zero parallel dictionaries, automatic fallback.

### Dynamic strings — one localized format string, never fragments
The summary line becomes a single catalog entry with placeholders, so translators own word order
_and_ per-number plurals in one place:

```swift
// ONE format string in the catalog, e.g. key "history.session.summary":
//   en: "%lld exercises · %lld sets · %@"   (with inline plural variants on each %lld)
Text("history.session.summary \(count) \(setCount) \(TTFormat.duration(secs))")
```

Counts elsewhere (`"Set \(n)"`, "%lld sets") use the catalog's inline plural variations — you write
one natural string, the catalog carries `one`/`other`/etc. per language.

### Formatting — fixed once, centrally, locale-aware
Everything date/number/duration already funnels through **`Utilities/Formatters.swift`**. Make that
file locale-correct exactly once: `Date.FormatStyle` / `setLocalizedDateFormatFromTemplate` instead
of fixed `dateFormat`, and a locale-aware `NumberFormatter`. No view ever formats a date itself.

### Net result
Adding a language: translate one catalog + the App Store metadata. **No Swift changes, ever.** Adding
an exercise/setting/case: it auto-derives its key; fill one catalog row. That's the elegant target.

## The effort model: front-loaded, then cheap

This is the key to answering "how much work per language."

```
Language #1 (Spanish)  ██████████████████  ~80% of total effort  (build the machine)
Language #2 (pt-BR)    ███                 translate + metadata
Language #3 (German)   ███                 translate + metadata
Language #4…           ███                 translate + metadata
```

### Phase 0 — Infrastructure (one-time, done alongside Spanish)
- Add a String Catalog (`Localizable.xcstrings`); set base development region.
- Build once → Xcode harvests the ~144 UI literals into the catalog.
- Refactor the ~68 data-layer strings (54 names + ~14 enum labels) to be localizable (option 1 above).
- Kill the `equipment.rawValue` / `category.shortName` display shortcuts; route through localized `displayName`.
- Quick audit: any date/number formatting not going through locale formatters.
- Add `es` to the project's known regions.
- **Estimate: ~0.5–1.5 days of dev.** This is the whole "hard" part, and it's done exactly once.

### Phase 1 — Spanish translation
- Translate ~210 strings. A good first pass can be machine-generated, then **native review is
  essential** (gym terminology is idiomatic — "curl", "sentadilla", "peso muerto" etc.).
- Localize App Store listing: title, subtitle, keywords, description. Screenshots optional at first
  (can ship English screenshots, localize later).
- **Estimate: ~0.5–1 day** (mostly the native review pass).

### Phase 2+ — Each additional language
- No code. Duplicate the string set, translate, native-review, add region, localize App Store text.
- **Estimate: ~0.5 day each**, and it scales down as you build a glossary.

---

## Per-language depth & priority

Order confirmed from market research (see separate research notes): **Spanish → Brazilian
Portuguese → German**, then optional Japanese/Korean/French/Italian.

| Language | Reach | Depth of work | Notes |
|---|---|---|---|
| **Spanish (es)** | Spain + all Latin America + US Hispanic (~60M in US) | **Highest** — includes Phase 0 infra | One translation, enormous reach. Do first. Use neutral/LatAm-friendly Spanish. |
| **Portuguese-BR (pt-BR)** | Brazil (~200M mobile users) | Low — translation only | Under-served, mobile-first. Use pt-BR specifically, not pt-PT. |
| **German (de)** | DACH region | Low — translation only | Small audience, high willingness-to-pay. Longer words → check layout doesn't clip. |
| **Japanese (ja)** | Japan (highest ARPU on App Store) | Low-medium | Higher revenue-per-user; needs careful native review + font/line-break check. |
| **French / Italian (fr/it)** | France, Italy | Low | Easy adds once the machine exists. |

**None of these are right-to-left**, so there's zero RTL layout work for the priority list. The main
per-language QA is just checking that longer German/French strings don't clip in tight buttons.

---

## What you do NOT have to translate (why this is cheap)

- **Coaching videos** — user-supplied YouTube content, stays in whatever language the user picks. No
  content pipeline to localize.
- **Exercise instructions** — there aren't any long-form ones; names only.
- **User data** — logs, weights, PRs are numeric/locale-formatted, not translated.
- **Backend copy** — there's no backend. Fully local app.

---

## Cheapest possible validation (before committing)

1. **Localize only the App Store listing into Spanish** (title/subtitle/keywords/description +
   optionally Spanish screenshot captions) *without* translating the app. A few hours. If
   Spanish-market installs jump, demand is validated with almost no code.
2. **Watch App Store Connect → Analytics → by territory** once TubeTrainer has ~2–4 weeks of
   installs. That's real demand data for _your_ app and confirms/reorders the priority list.

---

## Scaling: reuse across all your apps + go wide on languages

The ambition — "the gym app in the most languages," and the same treatment across the other 5+ apps —
is achievable, but be clear-eyed about where the real cost is. **The code is not the bottleneck. The
bottleneck is translation _quality_ and _maintenance_.** Anyone can machine-translate into 40
languages in an afternoon; the trap is shipping subtly wrong translations that get roasted in local
reviews. The design below makes the code near-free and puts the effort where it belongs.

### Extract the machine into a shared Swift package (build once, use everywhere)

Nothing in the elegant machine is gym-specific. Pull it into one local Swift package — call it
`LocaleKit` — and every app just imports it:

- `LocalizedDisplayable` protocol + generic default impl (self-localizing enums).
- Locale-aware formatter helpers (dates via `FormatStyle`, locale `NumberFormatter`, relative dates).
- A dev-time **completeness assertion**: in `DEBUG`, verify every enum case and seed key has a catalog
  entry — so a missing translation is caught at launch in dev, not by a user.
- Optional: a tiny "report a translation issue" hook apps can wire to a mailto/support form.

Per app, the only work is its **own `Localizable.xcstrings`** (its own strings) + conforming its own
enums. The pattern, formatters, and QA harness are identical across all six apps. TubeTrainer is the
**reference implementation** — get it perfect once, then rolling it to XRPMaxi, Reel Vision Board,
etc. is mechanical.

### A reliable translation pipeline (this is what "most languages" actually needs)

Use Apple's own round-trip — it's the reliable, tooling-backed path, not a bespoke script:

1. **Author** in the String Catalog (base language English). Plurals inline.
2. **Export** `.xcloc` files (`Product ▸ Export Localizations`) — the standard XLIFF-based exchange
   format. Send these to a translation service, a translator, or an MT step.
3. **Import** back (`Product ▸ Import Localizations`). The catalog tracks **state per string**
   (new / stale / translated / needs-review), so when you change a base string later, it flags every
   language that went stale. That state tracking is what keeps 20+ languages from silently rotting
   across app updates.
4. **Pseudolocalization** first (Xcode's accented / double-length pseudolanguage) to catch truncation
   and any hardcoded strings **before** paying for real translation. Cheap reliability.

### Tier the languages so quality scales, not just quantity

- **Tier 1 — native/professional review** (your money markets): es, pt-BR, de, fr, it, ja, ko,
  zh-Hans. These get a human who lifts. Short UI strings + a shared **gym glossary** (bench press,
  deadlift, RPE…) keep terminology consistent across all your gym content and cheap to review.
- **Tier 2 — quality MT + a user feedback path** (the long tail that wins "most languages"): the
  strings here are short and mechanical, so MT is unusually safe — but ship a visible "suggest a
  better translation" link and improve from real user reports. Never dump raw MT into 40 languages
  and walk away.
- **App Store metadata**: localize broadly and early even where the app UI review lags — localized
  keyword fields drive discoverability per storefront and are low-risk.

### Honest reality check

App Store supports ~40 languages; being in the most is a legitimate ASO wedge for a small app. The
differentiator is that our strings are short and terminology-bounded, which makes wide MT far safer
than for a text-heavy app. Lead with Tier 1 done _properly_; let Tier 2 breadth follow with a
feedback loop. Reliability comes from the `.xcloc` round-trip + catalog state tracking + the DEBUG
completeness assertion — not from hoping.

## Website localization (tubetrainer.app)

Do this **in lockstep with the app** — only publish a language's web pages once the app itself ships
that language, so a Spanish visitor never lands on a Spanish site that links to an English-only app.

### The goal (and the common trap)

Goal: someone Googling in Spanish finds the Spanish page, clicks, and lands on Spanish. Good. **The
trap** is thinking IP-based auto-switching delivers that. It does not:

- **Googlebot crawls from US IPs.** If the same URL changes content by IP, Google only ever sees
  English and never indexes the other languages. Silently varying content by IP on one URL is an
  anti-pattern Google explicitly cautions against.
- **Language ≠ geography.** A German speaker in London wants German. IP guesses location, not language
  preference.

### The architecture that actually ranks

Three things, in order of importance:

1. **Separate, static URLs per locale.** Astro i18n routing generates `/` (English, default),
   `/es/`, `/pt-br/`, `/de/`. Each is a real crawlable page. The site is already static on Netlify,
   so this is a natural fit — `astro build` just emits more HTML files.
2. **`hreflang` alternate tags** in `<head>` on every page, listing all language variants of that
   page plus `x-default`. This is what tells Google "these are the same page in other languages —
   serve the right one per user." Without it, the localized pages compete instead of cooperate.
3. **Localized sitemap.** Configure `@astrojs/sitemap` for i18n so `sitemap-index.xml` lists every
   locale URL with its `hreflang` links. Submit in Google Search Console.

### Then, and only then, geo/language convenience

- **Manual language dropdown** in the header (and footer): the source of truth. Persists the choice
  (cookie or `localStorage`) so it sticks across visits. Always visible — never hide the escape hatch.
- **Soft auto-detection on first visit only:** read the browser `Accept-Language` header (better
  signal than IP) and either (a) show a dismissible banner — "View in Español? →" — or (b) do a
  one-time redirect to the matching locale, but **always** with the dropdown override and **never**
  applied to crawler user-agents. Netlify Edge Functions or `_redirects` with `Country`/`Language`
  conditions can do this at the edge; keep it a suggestion, not a cage.
- **Canonical + `lang` attribute:** each localized page sets `<html lang="es">` and a self-referential
  canonical. Small but matters for correctness and accessibility.

### Per-language website effort

Mirror the app model — front-loaded, then cheap:

- **First locale (Spanish):** set up Astro i18n routing, extract the site's copy into per-locale
  content, add the `hreflang` + sitemap plumbing, build the dropdown + soft banner. **~1 day.**
- **Each locale after:** translate the same page copy (hero, features, support, privacy, terms) and
  drop in the locale file. No new plumbing. **~2–4 hours each.**

The site is small — a handful of pages (`index`, `support`, `privacy`, `terms`) — so the copy volume
per language is modest. Legal pages (privacy/terms) can stay English initially with a note, or be
translated for polish; they don't affect ranking much.

## Rough total estimate

- **Spanish (incl. all infrastructure): ~1.5–2.5 dev-days + native review.**
- **Each language after that: ~0.5 day.**
- So a **Spanish + Portuguese + German** launch is realistically **~3–4 days of focused work**, most
  of it one-time plumbing you never repeat.

## Open TODOs
- [ ] Decide data-layer approach (recommend option 1: `String(localized:)` + English base-name lookup)
- [ ] Add `Localizable.xcstrings`, build, verify ~144 UI strings harvested
- [ ] Refactor `Enums.swift` / `Models.swift` display labels + `SeedCatalog.swift` names
- [ ] Localize "You" tab settings option labels (`WeightUnit`, `AppearancePreference` `.label`) + Privacy prose — every pickable option must read correctly in-language
- [ ] Add `LocalizedDisplayable` protocol (one generic impl) + conform the 4 display enums — no per-case code
- [ ] `Exercise.displayName` helper keyed on `name`; swap `Text(exercise.name)` → `displayName` (auto-fallback for custom exercises)
- [ ] History/Today/Complete: replace `"\(count) noun"` interpolation with single catalog format strings + inline plural variations (no fragment concatenation)
- [ ] `Formatters.swift`: fixed once → `Date.FormatStyle`/localized templates + locale-aware `NumberFormatter`
- [ ] Spanish translation + native review
- [ ] Spanish App Store metadata
- [ ] (Optional) native search aliases for Spanish
- [ ] Repeat translation-only pass for pt-BR, de
