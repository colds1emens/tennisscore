import XCTest
@testable import TennisEngine

final class Game105Tests: XCTestCase {

    // MARK: - Суммирование

    func testScoringAllStandardTypes() {
        var engine = Game105Engine()
        engine.award(PointCategory.errorID, to: .a)   // +1
        engine.award(PointCategory.winnerID, to: .a)  // +5
        engine.award(PointCategory.volleyID, to: .a)  // +10
        engine.award(PointCategory.lobID, to: .a)     // +10
        engine.award(PointCategory.smashID, to: .a)   // +20
        XCTAssertEqual(engine.score(of: .a), 46)
        XCTAssertEqual(engine.score(of: .b), 0)

        engine.award(PointCategory.smashID, to: .b)
        engine.award(PointCategory.errorID, to: .b)
        XCTAssertEqual(engine.score(of: .b), 21)
        XCTAssertEqual(engine.score(of: .a), 46)
    }

    func testCustomValues() {
        let config = Game105Config(
            targetScore: 50,
            categories: [
                PointCategory(id: PointCategory.errorID, value: 2),
                PointCategory(id: PointCategory.winnerID, value: 7),
                PointCategory(id: PointCategory.smashID, value: 25)
            ]
        )
        var engine = Game105Engine(config: config)
        engine.award(PointCategory.errorID, to: .a)
        engine.award(PointCategory.winnerID, to: .a)
        engine.award(PointCategory.smashID, to: .a)
        XCTAssertEqual(engine.score(of: .a), 34)
    }

    func testDisabledCategoryRejected() {
        var categories = PointCategory.standardSet()
        let lobIndex = categories.firstIndex { $0.id == PointCategory.lobID }
        XCTAssertNotNil(lobIndex)
        if let lobIndex { categories[lobIndex].isEnabled = false }
        var engine = Game105Engine(config: Game105Config(categories: categories))
        XCTAssertNil(engine.award(PointCategory.lobID, to: .a))
        XCTAssertEqual(engine.score(of: .a), 0)
        XCTAssertNotNil(engine.award(PointCategory.winnerID, to: .a))
    }

    func testUnknownCategoryRejected() {
        var engine = Game105Engine()
        XCTAssertNil(engine.award("ace", to: .a))
        XCTAssertTrue(engine.events.isEmpty)
    }

    // MARK: - Undo / Redo

    func testUndoChain() {
        var engine = Game105Engine()
        engine.award(PointCategory.winnerID, to: .a)
        engine.award(PointCategory.smashID, to: .b)
        engine.award(PointCategory.errorID, to: .a)
        XCTAssertEqual(engine.score(of: .a), 6)
        XCTAssertEqual(engine.score(of: .b), 20)

        let undone = engine.undo()
        XCTAssertEqual(undone?.categoryID, PointCategory.errorID)
        XCTAssertEqual(undone?.side, .a)
        XCTAssertEqual(undone?.value, 1)
        XCTAssertEqual(engine.score(of: .a), 5)

        engine.undo()
        XCTAssertEqual(engine.score(of: .b), 0)
        engine.undo()
        XCTAssertEqual(engine.score(of: .a), 0)
        XCTAssertNil(engine.undo())
        XCTAssertFalse(engine.canUndo)
    }

    func testRedoChainAndInvalidationByNewAward() {
        var engine = Game105Engine()
        engine.award(PointCategory.winnerID, to: .a)
        engine.award(PointCategory.volleyID, to: .b)
        engine.undo()
        engine.undo()
        XCTAssertTrue(engine.canRedo)

        let redone = engine.redo()
        XCTAssertEqual(redone?.categoryID, PointCategory.winnerID)
        XCTAssertEqual(engine.score(of: .a), 5)
        engine.redo()
        XCTAssertEqual(engine.score(of: .b), 10)
        XCTAssertNil(engine.redo())

        engine.undo()
        engine.award(PointCategory.errorID, to: .a) // новое событие сбрасывает redo
        XCTAssertFalse(engine.canRedo)
        XCTAssertNil(engine.redo())
    }

    // MARK: - Победа

    func testVictoryExactlyAtTarget() {
        let config = Game105Config(targetScore: 15)
        var engine = Game105Engine(config: config)
        engine.award(PointCategory.volleyID, to: .a) // 10
        engine.award(PointCategory.winnerID, to: .a) // 15 — ровно цель
        XCTAssertEqual(engine.score(of: .a), 15)
        XCTAssertEqual(engine.winner, .a)
        XCTAssertTrue(engine.isFinished)
        // После победы начисления не проходят
        XCTAssertNil(engine.award(PointCategory.errorID, to: .b))
    }

    func testVictoryOvershootTarget() {
        let config = Game105Config(targetScore: 15)
        var engine = Game105Engine(config: config)
        engine.award(PointCategory.volleyID, to: .b) // 10
        engine.award(PointCategory.smashID, to: .b)  // 30 > 15
        XCTAssertEqual(engine.winner, .b)
    }

    func testWinByTwoMode() {
        let config = Game105Config(
            targetScore: 10,
            winByTwo: true,
            categories: [PointCategory(id: PointCategory.errorID, value: 1)]
        )
        var engine = Game105Engine(config: config)
        for _ in 0..<9 { engine.award(PointCategory.errorID, to: .a) }
        for _ in 0..<9 { engine.award(PointCategory.errorID, to: .b) } // 9:9
        engine.award(PointCategory.errorID, to: .a) // 10:9 — мало
        XCTAssertNil(engine.winner)
        engine.award(PointCategory.errorID, to: .b) // 10:10
        engine.award(PointCategory.errorID, to: .b) // 10:11 — мало
        XCTAssertNil(engine.winner)
        engine.award(PointCategory.errorID, to: .b) // 10:12 — разница 2
        XCTAssertEqual(engine.winner, .b)
    }

    func testUndoRestoresUnfinishedState() {
        let config = Game105Config(targetScore: 20)
        var engine = Game105Engine(config: config)
        engine.award(PointCategory.smashID, to: .a) // 20 — победа
        XCTAssertTrue(engine.isFinished)
        engine.undo()
        XCTAssertFalse(engine.isFinished)
        XCTAssertNil(engine.winner)
        XCTAssertEqual(engine.score(of: .a), 0)
    }

    // MARK: - Гейм-пойнт

    func testGamePointWhenWithinMaxValue() {
        let config = Game105Config(targetScore: 105)
        var engine = Game105Engine(config: config)
        // A: 85 → 85+20 = 105 — гейм-пойнт
        for _ in 0..<4 { engine.award(PointCategory.smashID, to: .a) } // 80
        engine.award(PointCategory.winnerID, to: .a) // 85
        XCTAssertTrue(engine.isGamePoint(for: .a))
        XCTAssertFalse(engine.isGamePoint(for: .b))
    }

    func testNoGamePointJustBelowReach() {
        let config = Game105Config(targetScore: 105)
        var engine = Game105Engine(config: config)
        for _ in 0..<4 { engine.award(PointCategory.smashID, to: .a) } // 80
        engine.award(PointCategory.errorID, to: .a) // 81; 81+20=101 < 105
        XCTAssertFalse(engine.isGamePoint(for: .a))
    }

    func testGamePointRespectsDisabledCategories() {
        var categories = PointCategory.standardSet()
        for index in categories.indices where categories[index].value >= 10 {
            categories[index].isEnabled = false
        }
        // Максимум теперь +5
        let config = Game105Config(targetScore: 20, categories: categories)
        var engine = Game105Engine(config: config)
        engine.award(PointCategory.winnerID, to: .a)
        engine.award(PointCategory.winnerID, to: .a) // 10; 10+5 < 20
        XCTAssertFalse(engine.isGamePoint(for: .a))
        engine.award(PointCategory.winnerID, to: .a) // 15; 15+5 = 20
        XCTAssertTrue(engine.isGamePoint(for: .a))
    }

    // MARK: - Наброс

    func testFeedingSideWinnerFeeds() {
        var engine = Game105Engine(config: Game105Config(feedRule: .winnerFeeds))
        XCTAssertNil(engine.feedingSide)
        engine.award(PointCategory.winnerID, to: .a)
        XCTAssertEqual(engine.feedingSide, .a)
        engine.award(PointCategory.errorID, to: .b)
        XCTAssertEqual(engine.feedingSide, .b)
    }

    func testFeedingSideCoachFeedsLoser() {
        var engine = Game105Engine(config: Game105Config(feedRule: .coachFeedsLoser))
        engine.award(PointCategory.winnerID, to: .a)
        XCTAssertEqual(engine.feedingSide, .b)
    }

    // MARK: - Сводка и лента

    func testBreakdownTotals() {
        var engine = Game105Engine()
        engine.award(PointCategory.winnerID, to: .a)
        engine.award(PointCategory.winnerID, to: .a)
        engine.award(PointCategory.smashID, to: .a)
        engine.award(PointCategory.errorID, to: .b)

        let aTotals = engine.breakdown(for: .a)
        XCTAssertEqual(aTotals.count, 2)
        XCTAssertEqual(aTotals[0].categoryID, PointCategory.winnerID)
        XCTAssertEqual(aTotals[0].count, 2)
        XCTAssertEqual(aTotals[0].total, 10)
        XCTAssertEqual(aTotals[1].categoryID, PointCategory.smashID)
        XCTAssertEqual(aTotals[1].total, 20)

        let bTotals = engine.breakdown(for: .b)
        XCTAssertEqual(bTotals.count, 1)
        XCTAssertEqual(bTotals[0].total, 1)
    }

    func testRecentEventsLimit() {
        var engine = Game105Engine()
        for _ in 0..<8 { engine.award(PointCategory.errorID, to: .a) }
        engine.award(PointCategory.winnerID, to: .b)
        let recent = engine.recentEvents(limit: 5)
        XCTAssertEqual(recent.count, 5)
        XCTAssertEqual(recent.last?.side, .b)
        XCTAssertEqual(recent.last?.categoryID, PointCategory.winnerID)
    }

    func testEventValueCapturedAtAwardTime() {
        var engine = Game105Engine()
        let event = engine.award(PointCategory.smashID, to: .a)
        XCTAssertEqual(event?.value, 20)
    }

    // MARK: - Кастомные и отрицательные категории

    func testCustomCategoryFactory() {
        let custom = PointCategory.custom(title: "Ace", value: 15)
        XCTAssertTrue(custom.isCustom)
        XCTAssertEqual(custom.value, 15)
        XCTAssertEqual(custom.customTitle, "Ace")
        XCTAssertFalse(PointCategory(id: PointCategory.errorID, value: 1).isCustom)
    }

    func testNegativeAndCustomCategoryAwardAndUndo() {
        let penalty = PointCategory.custom(title: "Double Fault", value: -5)
        var categories = PointCategory.standardSet()
        categories.append(penalty)
        var engine = Game105Engine(config: Game105Config(categories: categories))

        engine.award(PointCategory.winnerID, to: .a)   // +5 → 5
        engine.award(penalty.id, to: .a)               // -5 → 0
        XCTAssertEqual(engine.score(of: .a), 0)

        // Undo минусового очка восстанавливает счёт
        let undone = engine.undo()
        XCTAssertEqual(undone?.value, -5)
        XCTAssertEqual(undone?.categoryID, penalty.id)
        XCTAssertEqual(engine.score(of: .a), 5)

        // Undo до нуля
        engine.undo()
        XCTAssertEqual(engine.score(of: .a), 0)
        XCTAssertFalse(engine.canUndo)

        // Минусовое очко не мешает определять победу
        for _ in 0..<7 { engine.award(PointCategory.smashID, to: .a) } // +140
        XCTAssertEqual(engine.winner, .a)
    }
}
