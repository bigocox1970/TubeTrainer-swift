# App Store screenshots (localized)

**`upload/<lang>/`** — the curated 6-screenshot set to drag into App Store Connect for each
language localization (Spanish, Portuguese-BR, German). Size **1320 × 2868** (iPhone 6.9").

Order: 1-home · 2-coaching · 3-logging · 4-progress · 5-library · 6-history.

`screenshots/<lang>/` holds the full raw capture set (all 12 screens) if you want alternatives.

Regenerate any time: boot an iPhone 17 Pro Max sim, then for each lang run the
`LocalizationScreenshots` UI test with `TEST_RUNNER_TT_UITEST_LANG=<lang>` and
`TEST_RUNNER_TT_SHOT_DIR=<out>` (see scripts/loc-screenshots.sh for the pattern).

English keeps its existing 1.0 App Store screenshots (or regenerate the same way with lang=en).
