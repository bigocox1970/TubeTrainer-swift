# TubeTrainer (iOS)

Your coaches. Your exercises. Your progress.

TubeTrainer is a personal coaching library that happens to be an excellent
workout tracker. Attach the best YouTube coaching you find to each exercise and
keep it right beside your sets — local-first, no account, no backend.

Built with **SwiftUI + SwiftData**, dark-first, iOS 18+.

---

## Running it

The project is generated with [XcodeGen](https://github.com/yonyz/XcodeGen).

```bash
brew install xcodegen        # once
xcodegen generate            # regenerates TubeTrainer.xcodeproj from project.yml
open TubeTrainer.xcodeproj
```

Then pick an iPhone simulator (or your device) and hit **Run**.

> Regenerate the project (`xcodegen generate`) whenever you add/remove source
> files. Everything under `TubeTrainer/` is picked up automatically.

### Command line

```bash
# Build
xcodebuild -scheme TubeTrainer -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17' build

# Test (27 tests)
xcodebuild -scheme TubeTrainer -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

### Debug launch arguments

Useful for inspecting states quickly (DEBUG builds only):

- `-seedSample` — wipe and load Push/Pull/Legs + coaching + representative history
- `-openActive` — auto-open the active-workout screen
- `-tab library|history|you` — open on a specific tab
- `-appearance dark|light|system` — force an appearance

Example: `... launch booted app.tubetrainer.ios -seedSample -tab library`

---

## Architecture

```
TubeTrainer/
  App/            — entry, root navigation, app state, settings, DI environment
  Models/         — SwiftData @Model types + enums
  Persistence/    — container, seed catalog, sample data, performance/PR lookups
  Services/
    VideoDiscovery/  — VideoDiscoveryService protocol + YouTube implementation
    VideoPlayback/   — compliant embedded YouTube player (WKWebView)
    Backup/          — versioned JSON export/import
    Notifications/   — rest-timer local notifications
  DesignSystem/   — tokens (color/space/type/anim), haptics, reusable TT* components
  Features/       — Onboarding, Today, Workouts, ActiveWorkout, ExerciseLibrary,
                    Coaching, History, Settings
  Utilities/      — YouTube URL parsing, search, formatting, 1RM
```

Views never touch network code directly — all video work goes through the
`VideoDiscoveryService` protocol, so the YouTube layer can change without
rewriting any UI.

---

## YouTube integration — decisions & limitations

We verified the current Google requirements before implementing. TubeTrainer
uses only official, compliant mechanisms and **never downloads, mirrors or
redistributes video content**.

| Need | Mechanism | API key? |
|------|-----------|----------|
| Resolve a pasted/shared link | **oEmbed** (`youtube.com/oembed`) | No |
| Video title / channel / thumbnail | **oEmbed** + `i.ytimg.com` thumbnails | No |
| Inline playback | Privacy-enhanced **IFrame embed** (`youtube-nocookie.com`) in `WKWebView` | No |
| Open original | YouTube app deep link → Safari fallback | No |
| Free-text / Recommended search | **YouTube Data API v3** `search.list` | **Yes** |

### Why search is optional

`search.list` requires a Google API key and a mobile app cannot keep a static
key secret. Rather than ship a shared key (fragile, quota-limited across all
users) or stand up a backend (the PRD's V1 goal is backend-free), search is
**bring-your-own-key**:

- Add a key in **You → YouTube search key** to enable in-app Recommended/Search.
  Restrict it to the YouTube Data API and your bundle id in Google Cloud.
  Free-tier quota is ~100 searches/day.
- **Without a key**, the app is fully usable: paste any YouTube link (keyless
  oEmbed resolves it) or tap **Search on YouTube** to search in the YouTube app
  and paste the result back. Discovery never blocks logging.

This keeps V1 free, backend-free and account-free while remaining honest about
the tradeoff instead of faking search.

### Share Extension (share to TubeTrainer)

TubeTrainer registers a **Share Extension** so YouTube (or Safari, or anywhere
with a link) offers **TubeTrainer** in the share sheet. Tapping it shows "Save to
an exercise" — search, pick the exercise, and the video becomes that exercise's
coach without ever leaving YouTube.

- The app and the extension share one SwiftData store via the App Group
  `group.app.tubetrainer.ios`, so a coach saved from the extension appears
  instantly in the app.
- The extension resolves title/channel via keyless oEmbed, but saves even if
  offline (it always has the link, id and thumbnail).
- Signing: the App Group entitlement is declared for both targets in
  `project.yml`. Xcode's automatic signing provisions it on first device build;
  it works out-of-the-box on the simulator.

To try it: run the app once (so the catalog exists), then in the YouTube app tap
**Share → TubeTrainer**, or in Safari open any `youtube.com/watch?...` link and
share it.

### Offline / poor signal

Coaching media failing never blocks the workout: the logger, previous
performance and history stay fully functional, and unavailable media shows a
**Retry / Open in YouTube** state (PRD scenario D).

---

## Data & privacy

- Everything lives locally in SwiftData. No account, no server, no analytics.
- **Export/Import** (You → Data) produces a versioned JSON backup containing your
  exercises, coaching *references* (never media), coaches, templates and history.
  Import validates the schema/version and offers merge or replace with clear
  confirmation.

---

## Tests

27 tests cover YouTube URL parsing, forgiving exercise search/aliases, unit
handling, 1RM estimation, workout/set persistence, previous-session lookup,
workout completion, PR detection, and backup encode/decode + invalid-backup
handling.

> **Note on the test container:** the unit-test bundle is hosted inside the app,
> and SwiftData does not support two `ModelContainer`s for the same models in one
> process. Tests therefore share the app's single container
> (`PersistenceController.shared`, in-memory under XCTest) and wipe it between
> tests for isolation. See `TestSupport.swift`.

---

## App icon

The supplied TubeTrainer icon (black / red play / white dumbbell) is the brand
anchor. `AppIcon.appiconset` is set up so a **light-appearance icon variant** can
be dropped in later without code changes.
