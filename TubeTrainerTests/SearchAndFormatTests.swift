import XCTest
@testable import TubeTrainer

final class SearchAndFormatTests: XCTestCase {

    func testAliasSearchRDL() {
        let rdl = Exercise(name: "Romanian Deadlift", category: .hamstrings, equipment: .barbell,
                           aliases: ["rdl", "romanian dl", "stiff leg deadlift"])
        XCTAssertTrue(ExerciseSearch.matches(query: "rdl", exercise: rdl))
        XCTAssertTrue(ExerciseSearch.matches(query: "romanian", exercise: rdl))
        XCTAssertTrue(ExerciseSearch.matches(query: "deadlift", exercise: rdl))
        XCTAssertFalse(ExerciseSearch.matches(query: "bench", exercise: rdl))
    }

    func testPartialAndCategorySearch() {
        let ohp = Exercise(name: "Dumbbell Shoulder Press", category: .shoulders, equipment: .dumbbell,
                           aliases: ["db shoulder press"])
        XCTAssertTrue(ExerciseSearch.matches(query: "shoulder press", exercise: ohp))
        XCTAssertTrue(ExerciseSearch.matches(query: "shou", exercise: ohp))
        XCTAssertTrue(ExerciseSearch.matches(query: "dumbbell", exercise: ohp))
        XCTAssertTrue(ExerciseSearch.matches(query: "", exercise: ohp))
    }

    func testEmptyQueryMatchesAll() {
        let ex = Exercise(name: "Plank", category: .core, equipment: .bodyweight)
        XCTAssertTrue(ExerciseSearch.matches(query: "   ", exercise: ex))
    }

    func testWeightNumberFormatting() {
        XCTAssertEqual(TTFormat.number(80), "80")
        XCTAssertEqual(TTFormat.number(32.5), "32.5")
        XCTAssertEqual(TTFormat.number(32.50), "32.5")
        XCTAssertEqual(TTFormat.weightReps(80, reps: 8), "80 × 8")
    }

    func testClockAndDuration() {
        XCTAssertEqual(TTFormat.clock(90), "1:30")
        XCTAssertEqual(TTFormat.clock(3661), "1:01:01")
        XCTAssertEqual(TTFormat.duration(54 * 60), "54 min")
        XCTAssertEqual(TTFormat.duration(72 * 60), "1 hr 12 min")
    }

    func testEpley1RM() {
        XCTAssertEqual(OneRepMax.epley(weight: 100, reps: 1), 100)
        XCTAssertEqual(OneRepMax.epley(weight: 100, reps: 10), 100 * (1 + 10.0/30.0), accuracy: 0.001)
        XCTAssertEqual(OneRepMax.epley(weight: 100, reps: 0), 0)
    }

    func testUnitSteps() {
        XCTAssertEqual(WeightUnit.kg.step, 2.5)
        XCTAssertEqual(WeightUnit.lb.step, 5)
        XCTAssertEqual(WeightUnit.kg.smallStep, 1.25)
    }
}
