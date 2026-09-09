# TubeTrainer — Project Status

_Last updated: 2026-09-10_

A living handoff document. Read this first when picking the project back up.

---

## Where we are

**TubeTrainer V1 (iOS app) is complete, builds clean, runs, and is device-ready.**

- Native **SwiftUI + SwiftData**, iOS 18+, dark-first with full light mode.
- Clean build: **0 warnings, 0 errors**. **27 tests pass.**
- Runs end-to-end in the iPhone 17 simulator; verified visually across every
  primary screen (onboarding, Today, Active Workout, Library, Exercise detail,
  Coaching discovery, History, You/Settings) in both light and dark.
- **Signing baked in:** `DEVELOPMENT_TEAM = 7XY8PA34AM` (Apple team
  "CHRISTOPHER LEWIS COX" — Chris's personal team). A real-device build succeeds
  with automatic signing; Xcode auto-provisions the app + extension + App Group.

### Implemented (full PRD V1)

- **Design system** — semantic light/dark color tokens, type/space/radius/anim
  scales, haptics, reusable `TT*` components.
- **Onboarding** — 6 steps (brand → experience → structure → customize → coaches →
  coaching explainer); builds a populated workout structure; skippable.
- **Workout engine** — templates, active session, fast set logger (steppers +
  keypad + prev-fill), previous-performance display, auto rest timer (background
  via local notifications), completion summary with PR detection.
- **Coaching** — the differentiator. Video hero with inline compliant player,
  clip start-times, empty "Find your X coach" discovery panel. Discovery routes:
  Recommended / My Coaches / Search + paste-a-link. "Use this for X?" confirm.
- **Library** — search + Needs/Has Coach filters + coaching-progress bar;
  exercise detail (Coach / Train / History + PRs); custom exercises.
- **History** — sessions grouped by month, session detail, exercise progression,
  Epley 1RM (labelled estimate).
- **Settings (You)** — units (kg/lb), rest defaults, **Appearance System/Dark/
  Light**, export/import JSON backup (versioned, merge/replace), YouTube API key,
  privacy, My Coaches.
- **Share Extension** — "Share → TubeTrainer" from YouTube/Safari saves a link as
  an exercise's coach. App + extension share one SwiftData store via **App Group
  `group.app.tubetrainer.ios`**.
- **Backup** — versioned JSON export/import with validation + safe failure.
- Haptics, animation, Dynamic Type, Reduce Motion, offline-safe media states.

### YouTube integration (compliant, backend-free)

- Keyless **oEmbed** for link resolution / metadata / thumbnails.
- Privacy-enhanced **IFrame embed** (`youtube-nocookie.com`) in `WKWebView`.
- **Optional** bring-your-own **YouTube Data API v3** key for in-app search
  (You → YouTube search key). Without a key: paste any link, or "Search on
  YouTube" and paste back. Search never blocks logging. No media is downloaded.

---

## How to build / run

```bash
brew install xcodegen          # once
xcodegen generate              # regenerate .xcodeproj after adding/removing files
open TubeTrainer.xcodeproj

# CLI build + test
xcodebuild -scheme TubeTrainer -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
xcodebuild -scheme TubeTrainer -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

**Debug launch args** (DEBUG only): `-seedSample`, `-openActive`,
`-tab library|history|you`, `-appearance dark|light|system`.

---

## Key gotchas (don't relearn these)

- **Project is XcodeGen-generated** from `project.yml`. Never hand-edit the
  `.xcodeproj`; run `xcodegen generate`.
- **SwiftData tests must share ONE container.** The test bundle is hosted in the
  app; two `ModelContainer`s for the same models in one process SIGTRAP. Tests use
  `PersistenceController.shared` (in-memory under XCTest) via `TestStore`, wiped
  per test. The app skips its auto-seed under XCTest. See `TestSupport.swift`.
- **Store location:** `PersistenceController.makeContainer` prefers the App Group
  store (`AppGroup.storeURL`), falls back to local on-disk, then in-memory.
- The Share Extension recompiles a **subset of shared source files** (listed in
  `project.yml`) rather than using a shared framework, to avoid public-API churn.

---

## Repo layout

```
TubeTrainer-swift/
  project.yml               # XcodeGen source of truth
  TubeTrainer/              # app sources (App, Models, Persistence, Services,
                            #   DesignSystem, Features, Utilities, Resources)
  TubeTrainerShare/         # Share Extension
  TubeTrainerTests/         # 27 tests
  website/                  # marketing website (Astro, deploys to Netlify)
  netlify.toml              # Netlify config (base = website)
  README.md                 # app + integration docs
  PROJECT_STATUS.md         # this file
  TubeTrainer-PRD.md        # original spec
```

---

## Website  ✅ built

Marketing site in `website/` — **Astro**, static output (pure HTML → fully
indexable), same dark/light toggle as the app, real device-frame screenshots
(populated with coaching), Netlify email capture, full SEO (OG image, JSON-LD,
sitemap, robots). Logo/favicons/OG derive from `TubeTrainer-Icon.png`.

- **Requires Node ≥ 22.12** (`nvm use 22`). Build: `cd website && npm install && npm run build`.
- Deploys to **Netlify** from the repo — root `netlify.toml` sets base `website/`,
  `NODE_VERSION=22`. Connect the repo once; every push auto-deploys. Point
  `tubetrainer.app` at the Netlify site.
- Verified in-browser: hero, coaching/logging split sections, screenshot gallery,
  share-flow, privacy, FAQ, notify form — dark + light, desktop + mobile.
- See `website/README.md` for details and how to refresh screenshots/OG.

Not yet a git repo — when ready: `git init`, add `.gitignore` (already present),
commit, push to GitHub, connect to Netlify (it reads `netlify.toml`).

---

## Possible next steps

- Provide a **light-mode app icon** variant (AppIcon catalog is ready for it).
- Real device gym test (the actual acceptance test from the PRD).
- Optional: App Store metadata/screenshots, TestFlight.
- Future (post-V1, per PRD §40): Form Check, Coach Packs, iCloud sync.
