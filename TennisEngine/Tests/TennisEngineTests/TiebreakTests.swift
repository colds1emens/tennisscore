import XCTest
@testable import TennisEngine

final class TiebreakTests: XCTestCase {

    private func winGame(_ engine: inout MatchEngine, _ player: Player) {
        for _ in 0..<4 { engine.winPoint(player) }
    }

    /// Довести сет до 6:6 (подача чередуется автоматически).
    private func reachTiebreak(_ engine: inout MatchEngine) {
        for _ in 0..<5 {
            winGame(&engine, .a)
            winGame(&engine, .b)
        }
        winGame(&engine, .a) // 6:5
        winGame(&engine, .b) // 6:6
    }

    func testTiebreakStartsAtSixSix() {
        var engine = MatchEngine()
        var outcome = PointOutcome()
        for _ in 0..<5 {
            winGame(&engine, .a)
            winGame(&engine, .b)
        }
        winGame(&engine, .a)
        for _ in 0..<4 { outcome = engine.winPoint(.b) }
        XCTAssertTrue(outcome.tiebreakStarted)
        XCTAssertTrue(engine.isTiebreak)
        XCTAssertFalse(engine.isSuperTiebreak)
    }

    func testTiebreakServingOrder() {
        var engine = MatchEngine(initialServer: .a)
        reachTiebreak(&engine)
        // Сыграно 12 геймов, подача с A: следующий (13-й «гейм» — тай-брейк)
        // первым подаёт A.
        XCTAssertEqual(engine.server, .a)
        engine.winPoint(.a) // очко 1 → подача переходит
        XCTAssertEqual(engine.server, .b)
        engine.winPoint(.b) // очко 2
        XCTAssertEqual(engine.server, .b)
        engine.winPoint(.a) // очко 3 → смена
        XCTAssertEqual(engine.server, .a)
        engine.winPoint(.b) // очко 4
        XCTAssertEqual(engine.server, .a)
        engine.winPoint(.a) // очко 5 → смена
        XCTAssertEqual(engine.server, .b)
    }

    func testTiebreakWonSevenWithMarginTwo() {
        var engine = MatchEngine()
        reachTiebreak(&engine)
        for _ in 0..<6 { engine.winPoint(.a) } // 6:0
        for _ in 0..<6 { engine.winPoint(.b) } // 6:6 — нужен перевес 2
        engine.winPoint(.a) // 7:6 — ещё не конец
        XCTAssertTrue(engine.isTiebreak)
        XCTAssertFalse(engine.isFinished)
        let outcome = engine.winPoint(.a) // 8:6
        XCTAssertEqual(outcome.setWon, .a)
        let set = engine.completedSets[0]
        XCTAssertEqual(set.gamesA, 7)
        XCTAssertEqual(set.gamesB, 6)
        XCTAssertEqual(set.tiebreakPointsA, 8)
        XCTAssertEqual(set.tiebreakPointsB, 6)
    }

    func testAfterTiebreakReceiverServesFirstInNextSet() {
        var engine = MatchEngine(initialServer: .a)
        reachTiebreak(&engine)
        XCTAssertEqual(engine.server, .a) // A первым подаёт в тай-брейке
        for _ in 0..<7 { engine.winPoint(.a) } // тай-брейк 7:0, сет A
        XCTAssertEqual(engine.completedSets.count, 1)
        // Принимавший первым в тай-брейке (B) подаёт в новом сете
        XCTAssertEqual(engine.server, .b)
    }

    func testTiebreakChangeEndsEverySixPoints() {
        var engine = MatchEngine()
        reachTiebreak(&engine)
        // Строгое чередование очков: к 12-му очку счёт 6:6, никто не выиграл.
        var outcome = PointOutcome()
        for i in 1...12 {
            outcome = engine.winPoint(i.isMultiple(of: 2) ? .b : .a)
            if i % 6 == 0 {
                XCTAssertTrue(outcome.changeEnds, "Смена сторон обязана быть на очке \(i)")
            } else {
                XCTAssertFalse(outcome.changeEnds, "Смены сторон не должно быть на очке \(i)")
            }
        }
        XCTAssertTrue(engine.isTiebreak)
        XCTAssertEqual(engine.gameScoreText(for: .a), "6")
        XCTAssertEqual(engine.gameScoreText(for: .b), "6")
    }

    func testTiebreakScoreText() {
        var engine = MatchEngine()
        reachTiebreak(&engine)
        engine.winPoint(.a)
        engine.winPoint(.a)
        engine.winPoint(.b)
        XCTAssertEqual(engine.gameScoreText(for: .a), "2")
        XCTAssertEqual(engine.gameScoreText(for: .b), "1")
    }

    func testSetPointInTiebreak() {
        var engine = MatchEngine()
        reachTiebreak(&engine)
        for _ in 0..<6 { engine.winPoint(.a) } // 6:0 в тай-брейке
        XCTAssertTrue(engine.isSetPoint(for: .a))
        XCTAssertFalse(engine.isSetPoint(for: .b))
    }

    // MARK: - Супер тай-брейк

    func testSuperTiebreakReplacesDecidingSet() {
        var config = MatchConfig(format: .bestOfThree)
        config.superTiebreakInsteadOfFinalSet = true
        var engine = MatchEngine(config: config)
        for _ in 0..<6 { winGame(&engine, .a) } // сет 1 — A
        var outcome = PointOutcome()
        for game in 0..<6 { // сет 2 — B
            for _ in 0..<4 { outcome = engine.winPoint(.b) }
            _ = game
        }
        XCTAssertTrue(outcome.tiebreakStarted)
        XCTAssertTrue(engine.isTiebreak)
        XCTAssertTrue(engine.isSuperTiebreak)
    }

    func testSuperTiebreakWonAtTenWithMarginTwo() {
        var config = MatchConfig(format: .bestOfThree)
        config.superTiebreakInsteadOfFinalSet = true
        var engine = MatchEngine(config: config)
        for _ in 0..<6 { winGame(&engine, .a) }
        for _ in 0..<6 { winGame(&engine, .b) }

        for _ in 0..<9 { engine.winPoint(.b) } // 0:9
        for _ in 0..<9 { engine.winPoint(.a) } // 9:9 — на 10 ещё не конец
        engine.winPoint(.a) // 10:9
        XCTAssertFalse(engine.isFinished)
        let outcome = engine.winPoint(.a) // 11:9
        XCTAssertEqual(outcome.matchWon, .a)
        XCTAssertTrue(engine.isFinished)
        let deciding = engine.completedSets[2]
        XCTAssertTrue(deciding.isSuperTiebreak)
        XCTAssertEqual(deciding.tiebreakPointsA, 11)
        XCTAssertEqual(deciding.tiebreakPointsB, 9)
        XCTAssertEqual(deciding.winner, .a)
    }

    func testMatchPointInSuperTiebreak() {
        var config = MatchConfig(format: .bestOfThree)
        config.superTiebreakInsteadOfFinalSet = true
        var engine = MatchEngine(config: config)
        for _ in 0..<6 { winGame(&engine, .a) }
        for _ in 0..<6 { winGame(&engine, .b) }
        for _ in 0..<9 { engine.winPoint(.a) } // 9:0
        XCTAssertTrue(engine.isMatchPoint(for: .a))
        XCTAssertFalse(engine.isMatchPoint(for: .b))
    }

    func testUndoThroughTiebreakBoundary() {
        var engine = MatchEngine()
        reachTiebreak(&engine)
        let atTiebreakStart = engine.snapshot
        for _ in 0..<7 { engine.winPoint(.a) } // тай-брейк и сет взяты
        XCTAssertEqual(engine.completedSets.count, 1)
        for _ in 0..<7 { XCTAssertTrue(engine.undo()) }
        XCTAssertEqual(engine.snapshot, atTiebreakStart)
        XCTAssertTrue(engine.isTiebreak)
        XCTAssertEqual(engine.completedSets.count, 0)
    }
}
