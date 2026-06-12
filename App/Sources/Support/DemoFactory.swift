import Foundation
import SwiftData
import TennisEngine

/// Реалистичные demo-состояния для скриншотов (--demo …).
/// Все состояния прогоняются через настоящие движки — ничего синтетического.
enum DemoFactory {

    // MARK: - Классический матч

    /// Третий сет, 5:4, 40:30 — матч-пойнт. Анна против Марии.
    @MainActor
    static func midMatchSession(settings: AppSettings) -> MatchViewModel {
        var engine = MatchEngine(config: MatchConfig(format: .bestOfThree), initialServer: .a)
        // Сет 1 — 6:4 для Анны
        playGames(&engine, [.a, .b, .a, .b, .a, .b, .a, .b, .a, .a])
        // Сет 2 — 3:6 для Марии
        playGames(&engine, [.b, .a, .b, .a, .b, .a, .b, .b, .b])
        // Сет 3 — 5:4, в текущем гейме 40:30
        playGames(&engine, [.a, .b, .a, .b, .a, .b, .a, .b, .a])
        playPoints(&engine, [.a, .a, .b, .b, .a])
        return MatchViewModel(playerA: "Anna", playerB: "Maria", theme: settings.theme, engine: engine)
    }

    /// Тай-брейк первого сета, 5:6 — сет-пойнт у принимающего.
    @MainActor
    static func tiebreakSession(settings: AppSettings) -> MatchViewModel {
        var engine = MatchEngine(config: MatchConfig(format: .bestOfThree), initialServer: .a)
        for _ in 0..<5 {
            playGames(&engine, [.a, .b])
        }
        playGames(&engine, [.a, .b]) // 6:6 → тай-брейк
        playPoints(&engine, [.b, .a, .b, .a, .b, .a, .b, .a, .b, .a, .b]) // 5:6
        return MatchViewModel(playerA: "Anna", playerB: "Maria", theme: settings.theme, engine: engine)
    }

    // MARK: - Игра «105»

    /// Середина игры: 92:84, у «Орлов» гейм-пойнт.
    @MainActor
    static func game105Session(settings: AppSettings) -> Game105ViewModel {
        var engine = Game105Engine(config: Game105Config(categories: PointCategory.standardSet()))
        let script: [(String, Side)] = [
            (PointCategory.smashID, .a), (PointCategory.errorID, .b),
            (PointCategory.smashID, .b), (PointCategory.volleyID, .a),
            (PointCategory.errorID, .a), (PointCategory.smashID, .b),
            (PointCategory.smashID, .a), (PointCategory.errorID, .b),
            (PointCategory.smashID, .a), (PointCategory.errorID, .b),
            (PointCategory.smashID, .b), (PointCategory.errorID, .b),
            (PointCategory.smashID, .b), (PointCategory.smashID, .a),
            (PointCategory.errorID, .a)
        ] // Итог: 92:84 — у «Орлов» гейм-пойнт (92 + смэш 20 ≥ 105)
        for (category, side) in script {
            engine.award(category, to: side)
        }
        return Game105ViewModel(sideA: "Eagles", sideB: "Hawks", theme: settings.theme, engine: engine)
    }

    /// Завершённая игра 105:76 — для экрана победы.
    @MainActor
    static func finished105Session(settings: AppSettings) -> Game105ViewModel {
        var engine = Game105Engine(config: Game105Config(categories: PointCategory.standardSet()))
        let script: [(String, Side)] = [
            (PointCategory.smashID, .a), (PointCategory.smashID, .b),
            (PointCategory.errorID, .a), (PointCategory.volleyID, .b),
            (PointCategory.smashID, .a), (PointCategory.smashID, .b),
            (PointCategory.errorID, .a), (PointCategory.winnerID, .b),
            (PointCategory.smashID, .a), (PointCategory.smashID, .b),
            (PointCategory.errorID, .a), (PointCategory.errorID, .b),
            (PointCategory.smashID, .a), (PointCategory.errorID, .a),
            (PointCategory.errorID, .a), (PointCategory.smashID, .a)
        ]
        for (category, side) in script {
            engine.award(category, to: side)
        }
        let viewModel = Game105ViewModel(sideA: "Eagles", sideB: "Hawks", theme: settings.theme, engine: engine)
        viewModel.savedToHistory = true
        return viewModel
    }

    // MARK: - История и пресеты

    /// Наполняет in-memory контейнер примерами записей.
    @MainActor
    static func seedHistory(into context: ModelContext) {
        let now = Date()

        // Матч с тай-брейком 6:4, 3:6, 7:6(5)
        var tiebreakMatch = MatchEngine(config: MatchConfig(format: .bestOfThree), initialServer: .a)
        playGames(&tiebreakMatch, [.a, .b, .a, .b, .a, .b, .a, .b, .a, .a])
        playGames(&tiebreakMatch, [.b, .a, .b, .a, .b, .a, .b, .b, .b])
        for _ in 0..<6 { playGames(&tiebreakMatch, [.a, .b]) }
        playPoints(&tiebreakMatch, [.a, .b, .a, .b, .a, .b, .a, .b, .a, .b]) // ТБ 5:5
        playPoints(&tiebreakMatch, [.a, .a]) // 7:5
        if let detail = makeMatchDetail(tiebreakMatch, playerA: "Anna", playerB: "Maria") {
            context.insert(GameRecord.record(match: detail, theme: .wimbledon, date: now.addingTimeInterval(-3600 * 5)))
        }

        // Матч с супер тай-брейком 6:3, 4:6, [10:7]
        var superMatch = MatchEngine(
            config: MatchConfig(format: .bestOfThree, superTiebreakInsteadOfFinalSet: true),
            initialServer: .b
        )
        playGames(&superMatch, [.a, .b, .a, .a, .b, .a, .b, .a, .a])
        playGames(&superMatch, [.b, .a, .b, .a, .b, .a, .b, .a, .b, .b])
        playPoints(&superMatch, [.a, .b, .a, .b, .a, .b, .a, .b, .a, .b, .a, .b, .a, .b, .a, .a, .a])
        if let detail = makeMatchDetail(superMatch, playerA: "Peter", playerB: "Ivan") {
            context.insert(GameRecord.record(match: detail, theme: .usOpen, date: now.addingTimeInterval(-86_400)))
        }

        // Быстрый матч 6:2, 6:2
        var quickMatch = MatchEngine(config: MatchConfig(format: .bestOfThree, noAd: true), initialServer: .a)
        playGames(&quickMatch, [.a, .a, .b, .a, .b, .a, .a, .a])
        playGames(&quickMatch, [.a, .b, .a, .a, .b, .a, .a, .a])
        if let detail = makeMatchDetail(quickMatch, playerA: "Sergey", playerB: "Oleg") {
            context.insert(GameRecord.record(match: detail, theme: .rolandGarros, date: now.addingTimeInterval(-86_400 * 2)))
        }

        // «105»: 105:96
        var game = Game105Engine(config: Game105Config())
        for _ in 0..<5 { game.award(PointCategory.smashID, to: .a) }   // 100
        for _ in 0..<4 { game.award(PointCategory.smashID, to: .b) }   // 80
        game.award(PointCategory.volleyID, to: .b)                     // 90
        game.award(PointCategory.winnerID, to: .b)                     // 95
        game.award(PointCategory.errorID, to: .b)                      // 96
        for _ in 0..<5 { game.award(PointCategory.errorID, to: .a) }   // 105
        if let detail = makeGame105Detail(game, sideA: "Eagles", sideB: "Hawks") {
            context.insert(GameRecord.record(game105: detail, theme: .melbourne, date: now.addingTimeInterval(-3600 * 26)))
        }

        // «105» один на один: 105:88
        var single = Game105Engine(config: Game105Config())
        for _ in 0..<4 { single.award(PointCategory.smashID, to: .b) } // 80
        for _ in 0..<2 { single.award(PointCategory.errorID, to: .b) } // 82
        single.award(PointCategory.winnerID, to: .b)                   // 87
        single.award(PointCategory.errorID, to: .b)                    // 88
        for _ in 0..<5 { single.award(PointCategory.volleyID, to: .a) } // 50
        for _ in 0..<2 { single.award(PointCategory.smashID, to: .a) }  // 90
        for _ in 0..<3 { single.award(PointCategory.winnerID, to: .a) } // 105
        if let detail = makeGame105Detail(single, sideA: "Dima", sideB: "Kostya") {
            context.insert(GameRecord.record(game105: detail, theme: .wimbledon, date: now.addingTimeInterval(-86_400 * 3)))
        }
    }

    /// Пресеты для demo-настроек.
    @MainActor
    static func seedPresets(into context: ModelContext) {
        context.insert(
            RulePreset(
                name: "My Club",
                categories: [
                    PointCategory(id: PointCategory.errorID, value: 2),
                    PointCategory(id: PointCategory.winnerID, value: 6),
                    PointCategory(id: PointCategory.volleyID, value: 12),
                    PointCategory(id: PointCategory.lobID, value: 12, isEnabled: false),
                    PointCategory(id: PointCategory.smashID, value: 24)
                ],
                createdAt: Date().addingTimeInterval(-86_400 * 7)
            )
        )
    }

    // MARK: - Вспомогательные

    private static func playGames(_ engine: inout MatchEngine, _ winners: [Player]) {
        for winner in winners {
            for _ in 0..<4 { engine.winPoint(winner) }
        }
    }

    private static func playPoints(_ engine: inout MatchEngine, _ winners: [Player]) {
        for winner in winners {
            engine.winPoint(winner)
        }
    }

    private static func makeMatchDetail(_ engine: MatchEngine, playerA: String, playerB: String) -> MatchDetail? {
        guard let winner = engine.winner else { return nil }
        return MatchDetail(
            playerA: playerA,
            playerB: playerB,
            config: engine.config,
            sets: engine.completedSets,
            winner: winner
        )
    }

    private static func makeGame105Detail(_ engine: Game105Engine, sideA: String, sideB: String) -> Game105Detail? {
        guard let winner = engine.winner else { return nil }
        return Game105Detail(
            sideA: sideA,
            sideB: sideB,
            config: engine.config,
            scoreA: engine.score(of: .a),
            scoreB: engine.score(of: .b),
            breakdownA: engine.breakdown(for: .a).map {
                Game105Detail.BreakdownLine(categoryID: $0.categoryID, count: $0.count, total: $0.total)
            },
            breakdownB: engine.breakdown(for: .b).map {
                Game105Detail.BreakdownLine(categoryID: $0.categoryID, count: $0.count, total: $0.total)
            },
            winner: winner
        )
    }
}
