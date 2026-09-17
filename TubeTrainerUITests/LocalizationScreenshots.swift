import XCTest

/// Reusable localization screenshot harness.
///
/// Launches the app in a chosen language (seeded with sample data, onboarding
/// skipped via the app's `-seedSample` hook), walks the main screens, and saves a
/// screenshot of each as a test attachment. Run per language, then export the
/// attachments and eyeball them for truncation / context / wrong labels.
///
/// Language is read from env var `TT_UITEST_LANG` (default "es"). Because Xcode
/// passes runner env vars prefixed with `TEST_RUNNER_`, invoke like:
///   xcodebuild test ... -only-testing:TubeTrainerUITests \
///     TEST_RUNNER_TT_UITEST_LANG=de -resultBundlePath de.xcresult
///
/// Navigation is driven by tab-bar INDEX and first-match cells so it never
/// depends on localized button text (which would break across languages).
final class LocalizationScreenshots: XCTestCase {

    private var lang = "es"

    override func setUpWithError() throws {
        continueAfterFailure = true
        lang = ProcessInfo.processInfo.environment["TT_UITEST_LANG"] ?? "es"
    }

    private func makeApp(extraArgs: [String] = []) -> XCUIApplication {
        let localeMap = ["es": "es_ES", "de": "de_DE", "pt-br": "pt_BR", "fr": "fr_FR", "it": "it_IT"]
        let app = XCUIApplication()
        app.launchArguments = [
            "-seedSample",
            "-AppleLanguages", "(\(lang))",
            "-AppleLocale", localeMap[lang] ?? lang,
        ] + extraArgs
        return app
    }

    /// Optional host directory to write PNGs to (set via TEST_RUNNER_TT_SHOT_DIR).
    /// The simulator shares the Mac filesystem, so this writes straight to disk —
    /// reliable regardless of how the result bundle prunes passing-test attachments.
    private lazy var outDir: URL? = {
        guard let p = ProcessInfo.processInfo.environment["TT_SHOT_DIR"], !p.isEmpty else { return nil }
        let u = URL(fileURLWithPath: p)
        try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }()

    private func shot(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let att = XCTAttachment(screenshot: screenshot)
        att.name = "\(lang)-\(name)"
        att.lifetime = .keepAlways
        add(att)
        if let dir = outDir {
            try? screenshot.pngRepresentation.write(to: dir.appendingPathComponent("\(lang)-\(name).png"))
        }
    }

    /// Today, Library (+ first exercise detail), History, You (+ scrolled).
    func testMainScreens() {
        let app = makeApp()
        app.launch()
        sleep(2) // let SwiftUI settle + sample data seed

        shot("01-today")

        let tabs = app.tabBars.buttons
        guard tabs.count >= 4 else {
            XCTFail("Expected 4 tab-bar buttons, found \(tabs.count)")
            return
        }

        // Library
        tabs.element(boundBy: 1).tap(); sleep(1); shot("02-library")
        // First exercise → detail (best-effort, language-independent).
        let firstCell = app.cells.firstMatch
        if firstCell.waitForExistence(timeout: 3), firstCell.isHittable {
            firstCell.tap(); sleep(1); shot("03-exercise-detail")
            if app.navigationBars.buttons.firstMatch.exists {
                app.navigationBars.buttons.firstMatch.tap(); sleep(1)
            }
        }

        // History
        tabs.element(boundBy: 2).tap(); sleep(1); shot("04-history")

        // You + scrolled (settings sections)
        tabs.element(boundBy: 3).tap(); sleep(1); shot("05-you")
        app.swipeUp(); sleep(1); shot("06-you-scrolled")
        app.swipeUp(); sleep(1); shot("07-you-bottom")
    }

    /// Proves the in-app language picker switches the UI live (no relaunch).
    /// Starts at the device language (no override), opens the You tab, switches to
    /// German via the picker, and screenshots before/after.
    func testLanguageSwitch() {
        let app = XCUIApplication()
        app.launchArguments = ["-seedSample"] // device language, no override
        app.launch()
        sleep(2)
        let tabs = app.tabBars.buttons
        guard tabs.count >= 4 else { XCTFail("no tab bar"); return }
        tabs.element(boundBy: 3).tap(); sleep(1)
        writePNG("switch-01-device")

        let picker = app.buttons["languagePicker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5), "language picker not found")
        picker.tap(); sleep(1)
        let deutsch = app.buttons["Deutsch"]
        XCTAssertTrue(deutsch.waitForExistence(timeout: 3), "Deutsch option not found")
        deutsch.tap(); sleep(2)
        writePNG("switch-02-after-de")
    }

    private func writePNG(_ name: String) {
        let s = XCUIScreen.main.screenshot()
        let att = XCTAttachment(screenshot: s); att.name = name; att.lifetime = .keepAlways; add(att)
        if let dir = outDir { try? s.pngRepresentation.write(to: dir.appendingPathComponent("\(name).png")) }
    }

    /// Active workout / set logger (opened via the app's -openActive hook).
    func testActiveWorkout() {
        let app = makeApp(extraArgs: ["-openActive"])
        app.launch()
        sleep(2)
        shot("10-active-workout")
        // Try to reveal the set logger / rest by tapping the first cell.
        let firstCell = app.cells.firstMatch
        if firstCell.waitForExistence(timeout: 3), firstCell.isHittable {
            firstCell.tap(); sleep(1); shot("11-active-detail")
        }
    }
}
