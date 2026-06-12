import XCTest
@testable import TennisEngine

final class MatchEngineTests: XCTestCase {

    // MARK: - Вспомогательные

    /// Игрок выигрывает гейм «всухую» (или 4 очка подряд).
    private func winGame(_ engine: inout MatchEngine, _ player: Player) {
        for _ in 0..<4 { engine.winPoint(player) }
    }

    private func winGames(_ engine: inout MatchEngine, _ player: Player, count: Int) {
        for _ in 0..<count { winGame(&engine, player) }
    }

    /// Выиграть сет 6:0.
    private func winSet(_ engine: inout MatchEngine, _ player: Player) {
        winGames(&engine, player, count: 6)
    }

    // MARK: - Очки в гейме

    func testPointLabelsProgression() {
        var engine = MatchEngine()
        XCTAssertEqual(engine.gameScoreText(for: .a), "0")
        engine.winPoint(.a)
        XCTAssertEqual(engine.gameScoreText(for: .a), "15")
        engine.winPoint(.a)
        XCTAssertEqual(engine.gameScoreText(for: .a), "30")
        engine.winPoint(.a)
        XCTAssertEqual(engine.gameScoreText(for: .a), "40")
        XCTAssertEqual(engine.gameScoreText(for: .b), "0")
        let outcome = engine.winPoint(.a)
        XCTAssertEqual(outcome.gameWon, .a)
        XCTAssertEqual(engine.gamesA, 1)
        XCTAssertEqual(engine.gameScoreText(for: .a), "0")
    }

    func testDeuceAdvantageCycles() {
        var engine = MatchEngine()
        // До 40:40
        for _ in 0..<3 { engine.winPoint(.a) }
        for _ in 0..<3 { engine.winPoint(.b) }
        XCTAssertTrue(engine.isDeuce)
        XCTAssertNil(engine.advantage)

        // Несколько циклов «больше» → «ровно»
        for _ in 0..<3 {
            engine.winPoint(.a)
            XCTAssertEqual(engine.advantage, .a)
            XCTAssertEqual(engine.gameScoreText(for: .a), "Ad")
            XCTAssertEqual(engine.gameScoreText(for: .b), "40")
            XCTAssertFalse(engine.isDeuce)

            engine.winPoint(.b)
            XCTAssertTrue(engine.isDeuce)
            XCTAssertNil(engine.advantage)

            engine.winPoint(.b)
            XCTAssertEqual(engine.advantage, .b)

            engine.winPoint(.a)
            XCTAssertTrue(engine.isDeuce)
        }

        // Выигрыш с «больше»
        engine.winPoint(.a)
        let outcome = engine.winPoint(.a)
        XCTAssertEqual(outcome.gameWon, .a)
        XCTAssertEqual(engine.gamesA, 1)
        XCTAssertEqual(engine.gamesB, 0)
    }

    func testNoAdDecidingPoint() {
        var engine = MatchEngine(config: MatchConfig(noAd: true))
        for _ in 0..<3 { engine.winPoint(.a) }
        for _ in 0..<3 { engine.winPoint(.b) }
        XCTAssertTrue(engine.isDeuce)
        // Решающее очко: следующий розыгрыш выигрывает гейм
        XCTAssertTrue(engine.isGamePoint(for: .a))
        XCTAssertTrue(engine.isGamePoint(for: .b))
        let outcome = engine.winPoint(.b)
        XCTAssertEqual(outcome.gameWon, .b)
        XCTAssertEqual(engine.gamesB, 1)
    }

    // MARK: - Сеты

    func testSetWonAtSixWithMarginTwo() {
        var engine = MatchEngine()
        winGames(&engine, .a, count: 5)
        winGames(&engine, .b, count: 4)
        var lastOutcome = PointOutcome()
        for _ in 0..<4 { lastOutcome = engine.winPoint(.a) }
        XCTAssertEqual(lastOutcome.setWon, .a)
        XCTAssertEqual(engine.completedSets.count, 1)
        XCTAssertEqual(engine.completedSets[0].gamesA, 6)
        XCTAssertEqual(engine.completedSets[0].gamesB, 4)
        XCTAssertEqual(engine.gamesA, 0)
        XCTAssertEqual(engine.gamesB, 0)
    }

    func testSetContinuesAtSixFive_thenSevenFive() {
        var engine = MatchEngine()
        winGames(&engine, .a, count: 5)
        winGames(&engine, .b, count: 5)
        winGames(&engine, .a, count: 1) // 6:5 — сет не закончен
        XCTAssertEqual(engine.completedSets.count, 0)
        XCTAssertEqual(engine.gamesA, 6)
        winGames(&engine, .a, count: 1) // 7:5
        XCTAssertEqual(engine.completedSets.count, 1)
        XCTAssertEqual(engine.completedSets[0].gamesA, 7)
        XCTAssertEqual(engine.completedSets[0].gamesB, 5)
    }

    func testMatchBestOfThree() {
        var engine = MatchEngine(config: MatchConfig(format: .bestOfThree))
        winSet(&engine, .a)
        winSet(&engine, .b)
        XCTAssertFalse(engine.isFinished)
        winGames(&engine, .a, count: 5)
        var outcome = PointOutcome()
        for _ in 0..<4 { outcome = engine.winPoint(.a) }
        XCTAssertEqual(outcome.matchWon, .a)
        XCTAssertTrue(engine.isFinished)
        XCTAssertEqual(engine.winner, .a)
        // После завершения очки не начисляются
        let after = engine.winPoint(.b)
        XCTAssertEqual(after, PointOutcome())
        XCTAssertTrue(engine.isFinished)
    }

    func testMatchBestOfFive() {
        var engine = MatchEngine(config: MatchConfig(format: .bestOfFive))
        winSet(&engine, .a)
        winSet(&engine, .a)
        XCTAssertFalse(engine.isFinished)
        winSet(&engine, .b)
        winSet(&engine, .b)
        XCTAssertFalse(engine.isFinished)
        winSet(&engine, .a)
        XCTAssertTrue(engine.isFinished)
        XCTAssertEqual(engine.winner, .a)
        XCTAssertEqual(engine.setsWon(by: .a), 3)
        XCTAssertEqual(engine.setsWon(by: .b), 2)
    }

    // MARK: - Подача

    func testServeAlternatesEachGame() {
        var engine = MatchEngine(initialServer: .b)
        XCTAssertEqual(engine.server, .b)
        winGame(&engine, .a)
        XCTAssertEqual(engine.server, .a)
        winGame(&engine, .a)
        XCTAssertEqual(engine.server, .b)
    }

    func testServeCarriesAcrossSets() {
        var engine = MatchEngine(initialServer: .a)
        winSet(&engine, .a) // 6 геймов: подача A,B,A,B,A,B → следующий A
        XCTAssertEqual(engine.server, .a)
        winGames(&engine, .b, count: 1) // 7-й гейм матча
        XCTAssertEqual(engine.server, .b)
    }

    // MARK: - Смена сторон

    func testChangeEndsAfterOddGames() {
        var engine = MatchEngine()
        var outcome = PointOutcome()
        for _ in 0..<4 { outcome = engine.winPoint(.a) } // 1-й гейм
        XCTAssertTrue(outcome.changeEnds)
        for _ in 0..<4 { outcome = engine.winPoint(.a) } // 2-й гейм
        XCTAssertFalse(outcome.changeEnds)
        for _ in 0..<4 { outcome = engine.winPoint(.a) } // 3-й гейм
        XCTAssertTrue(outcome.changeEnds)
    }

    func testChangeEndsAtSetEndWithOddTotal() {
        var engine = MatchEngine()
        winGames(&engine, .a, count: 5)
        winGames(&engine, .b, count: 4)
        var outcome = PointOutcome()
        for _ in 0..<4 { outcome = engine.winPoint(.a) } // сет 6:4, всего 10 геймов
        XCTAssertEqual(outcome.setWon, .a)
        XCTAssertFalse(outcome.changeEnds)

        winGames(&engine, .a, count: 1)
        winGames(&engine, .b, count: 5)
        for _ in 0..<4 { outcome = engine.winPoint(.b) } // сет 1:6, всего 7 геймов
        XCTAssertEqual(outcome.setWon, .b)
        XCTAssertTrue(outcome.changeEnds)
    }

    // MARK: - Бейджи

    func testGamePointAndBreakPoint() {
        var engine = MatchEngine(initialServer: .a)
        // A подаёт; B ведёт 0:40 — тройной брейк-пойнт
        for _ in 0..<3 { engine.winPoint(.b) }
        XCTAssertTrue(engine.isGamePoint(for: .b))
        XCTAssertTrue(engine.isBreakPoint(for: .b))
        XCTAssertFalse(engine.isGamePoint(for: .a))
        XCTAssertFalse(engine.isBreakPoint(for: .a))
    }

    func testSetAndMatchPointBadges() {
        var engine = MatchEngine(config: MatchConfig(format: .bestOfThree))
        winSet(&engine, .a)
        winGames(&engine, .a, count: 5)
        for _ in 0..<3 { engine.winPoint(.a) } // 40:0 при 5:0 во 2-м сете
        XCTAssertTrue(engine.isGamePoint(for: .a))
        XCTAssertTrue(engine.isSetPoint(for: .a))
        XCTAssertTrue(engine.isMatchPoint(for: .a))
        XCTAssertFalse(engine.isSetPoint(for: .b))
    }

    func testSetPointButNotMatchPointInFirstSet() {
        var engine = MatchEngine()
        winGames(&engine, .a, count: 5)
        for _ in 0..<3 { engine.winPoint(.a) }
        XCTAssertTrue(engine.isSetPoint(for: .a))
        XCTAssertFalse(engine.isMatchPoint(for: .a))
    }

    // MARK: - Undo / Redo

    func testUndoSinglePoint() {
        var engine = MatchEngine()
        let before = engine.snapshot
        engine.winPoint(.a)
        XCTAssertTrue(engine.canUndo)
        XCTAssertTrue(engine.undo())
        XCTAssertEqual(engine.snapshot, before)
        XCTAssertFalse(engine.canUndo)
        XCTAssertFalse(engine.undo())
    }

    func testUndoAcrossSetBoundary() {
        var engine = MatchEngine()
        winGames(&engine, .a, count: 5)
        winGames(&engine, .b, count: 4)
        for _ in 0..<3 { engine.winPoint(.a) } // 40:0 при 5:4 — сет-пойнт
        let beforeSetPoint = engine.snapshot
        engine.winPoint(.a) // сет 6:4 взят
        XCTAssertEqual(engine.completedSets.count, 1)

        // Шагнули во второй сет
        engine.winPoint(.b)
        engine.winPoint(.b)

        // Откат: два очка второго сета + очко, взявшее сет
        XCTAssertTrue(engine.undo())
        XCTAssertTrue(engine.undo())
        XCTAssertTrue(engine.undo())
        XCTAssertEqual(engine.snapshot, beforeSetPoint)
        XCTAssertEqual(engine.completedSets.count, 0)
        XCTAssertEqual(engine.gamesA, 5)
        XCTAssertEqual(engine.gamesB, 4)
        XCTAssertEqual(engine.gameScoreText(for: .a), "40")
        XCTAssertTrue(engine.isSetPoint(for: .a))
    }

    func testRedoAfterUndo() {
        var engine = MatchEngine()
        engine.winPoint(.a)
        engine.winPoint(.b)
        let after = engine.snapshot
        engine.undo()
        engine.undo()
        XCTAssertTrue(engine.canRedo)
        XCTAssertTrue(engine.redo())
        XCTAssertTrue(engine.redo())
        XCTAssertEqual(engine.snapshot, after)
        XCTAssertFalse(engine.canRedo)
    }

    func testNewPointClearsRedo() {
        var engine = MatchEngine()
        engine.winPoint(.a)
        engine.undo()
        XCTAssertTrue(engine.canRedo)
        engine.winPoint(.b)
        XCTAssertFalse(engine.canRedo)
    }

    func testUndoEntireMatch() {
        var engine = MatchEngine()
        let fresh = engine.snapshot
        winSet(&engine, .a)
        winSet(&engine, .a)
        XCTAssertTrue(engine.isFinished)
        while engine.undo() {}
        XCTAssertEqual(engine.snapshot, fresh)
        XCTAssertFalse(engine.isFinished)
    }
}
