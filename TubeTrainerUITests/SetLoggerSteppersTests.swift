import XCTest

/// Regression tests for the set-logger +/- steppers.
///
/// These guard the bugs that shipped in 1.1: the "minus" button had no tappable
/// area (only the drawn glyph took touches), so reps/weight could only go up, and
/// a math bug locked weight at two values. Launches straight into an active
/// workout via the app's `-seedSample`/`-openActive` hooks.
final class SetLoggerSteppersTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchIntoActiveWorkout() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-seedSample", "-openActive"]
        app.launch()
        // -openActive starts a workout ~1.5s after launch; wait for the logger.
        XCTAssertTrue(app.textFields["field.reps"].waitForExistence(timeout: 15),
                      "Set logger did not appear")
        return app
    }

    private func intValue(_ field: XCUIElement) -> Int {
        Int((field.value as? String ?? "").filter { $0.isNumber }) ?? 0
    }

    private func doubleValue(_ field: XCUIElement) -> Double {
        Double((field.value as? String ?? "").replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    /// Reps minus must actually fire — and take reps BELOW the seeded value.
    func testRepsMinusDecrementsBelowSeed() {
        let app = launchIntoActiveWorkout()
        let reps = app.textFields["field.reps"].firstMatch
        let minus = app.buttons["stepper.reps.minus"].firstMatch

        let start = intValue(reps)
        XCTAssertGreaterThan(start, 2, "Need a seeded reps value to decrement from")

        minus.tap()
        minus.tap()
        minus.tap()

        XCTAssertEqual(intValue(reps), start - 3,
                       "Reps minus did not decrement 3× (was \(start))")
        XCTAssertLessThan(intValue(reps), start, "Reps never went below the seed")
    }

    /// Reps plus and minus are symmetric.
    func testRepsPlusThenMinusRoundTrips() {
        let app = launchIntoActiveWorkout()
        let reps = app.textFields["field.reps"].firstMatch
        let start = intValue(reps)

        app.buttons["stepper.reps.plus"].firstMatch.tap()
        XCTAssertEqual(intValue(reps), start + 1)
        app.buttons["stepper.reps.minus"].firstMatch.tap()
        XCTAssertEqual(intValue(reps), start, "Plus then minus should return to start")
    }

    private func clearAndType(_ field: XCUIElement, _ text: String) {
        field.tap()
        // Double-tap selects the existing number; typing then replaces the selection.
        // (Backspace-based clearing is unreliable on the numeric pad — the caret can
        // land mid-value, leaving digits behind.)
        if let current = field.value as? String, !current.isEmpty {
            field.doubleTap()
        }
        field.typeText(text)
    }

    /// Three-digit weight (with decimal) and reps must be fully visible, not truncated.
    func testThreeDigitValuesFitAndRoundTrip() {
        let app = launchIntoActiveWorkout()
        let weight = app.textFields["field.weight"].firstMatch
        let reps = app.textFields["field.reps"].firstMatch

        clearAndType(weight, "102.5")
        clearAndType(reps, "120")
        app.buttons["Done"].firstMatch.tap()   // keyboard toolbar

        XCTAssertEqual(weight.value as? String, "102.5", "Weight did not accept 3 digits + decimal")
        XCTAssertEqual(reps.value as? String, "120", "Reps did not accept 3 digits")

        // Visual check: dump a screenshot when TT_SHOT_DIR is set (harmless otherwise).
        if let dir = ProcessInfo.processInfo.environment["TT_SHOT_DIR"], !dir.isEmpty {
            let url = URL(fileURLWithPath: dir).appendingPathComponent("threedigit.png")
            try? XCUIScreen.main.screenshot().pngRepresentation.write(to: url)
        }
    }

    /// Weight plus increments by a fixed step repeatedly (no lock at two values),
    /// and minus brings it back down by the same step.
    func testWeightStepsUpAndDownConsistently() {
        let app = launchIntoActiveWorkout()
        let weight = app.textFields["field.weight"].firstMatch
        let plus = app.buttons["stepper.weight.plus"].firstMatch
        let minus = app.buttons["stepper.weight.minus"].firstMatch

        let start = doubleValue(weight)
        plus.tap()
        let afterOne = doubleValue(weight)
        let step = afterOne - start
        XCTAssertGreaterThan(step, 0, "Weight plus did nothing")

        plus.tap()
        XCTAssertEqual(doubleValue(weight), start + step * 2, accuracy: 0.001,
                       "Second plus did not add the same step (locked?)")

        minus.tap()
        XCTAssertEqual(doubleValue(weight), start + step, accuracy: 0.001,
                       "Weight minus did not subtract a step")
    }
}
