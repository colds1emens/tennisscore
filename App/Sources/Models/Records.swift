import Foundation
import SwiftData
import TennisEngine

/// Режим игры для записей истории.
enum GameMode: String, Codable {
    case match
    case game105

    var title: String {
        switch self {
        case .match: return "Матч"
        case .game105: return "Игра «105»"
        }
    }
}

/// Слепок завершённого классического матча.
struct MatchDetail: Codable {
    var playerA: String
    var playerB: String
    var config: MatchConfig
    var sets: [CompletedSet]
    var winner: Player

    var resultLine: String {
        sets.map { set in
            if set.isSuperTiebreak {
                let a = set.tiebreakPointsA ?? 0
                let b = set.tiebreakPointsB ?? 0
                return "[\(a):\(b)]"
            }
            var line = "\(set.gamesA):\(set.gamesB)"
            if let tbA = set.tiebreakPointsA, let tbB = set.tiebreakPointsB {
                line += "(\(min(tbA, tbB)))"
            }
            return line
        }
        .joined(separator: ", ")
    }

    var winnerName: String { winner == .a ? playerA : playerB }
}

/// Слепок завершённой игры «105».
struct Game105Detail: Codable {
    var sideA: String
    var sideB: String
    var config: Game105Config
    var scoreA: Int
    var scoreB: Int
    var breakdownA: [BreakdownLine]
    var breakdownB: [BreakdownLine]
    var winner: Side

    struct BreakdownLine: Codable, Identifiable {
        var categoryID: String
        var count: Int
        var total: Int
        var id: String { categoryID }
    }

    var resultLine: String { "\(scoreA):\(scoreB)" }
    var winnerName: String { winner == .a ? sideA : sideB }
}

/// Запись истории — общая для обоих режимов.
@Model
final class GameRecord {
    var id: UUID = UUID()
    var date: Date = Date()
    var modeRaw: String = GameMode.match.rawValue
    var title: String = ""
    var resultSummary: String = ""
    var winnerName: String = ""
    var themeRaw: String = CourtTheme.wimbledon.rawValue
    var detailData: Data = Data()

    init(
        date: Date = Date(),
        mode: GameMode,
        title: String,
        resultSummary: String,
        winnerName: String,
        theme: CourtTheme,
        detailData: Data
    ) {
        self.id = UUID()
        self.date = date
        self.modeRaw = mode.rawValue
        self.title = title
        self.resultSummary = resultSummary
        self.winnerName = winnerName
        self.themeRaw = theme.rawValue
        self.detailData = detailData
    }

    var mode: GameMode { GameMode(rawValue: modeRaw) ?? .match }
    var theme: CourtTheme { CourtTheme(rawValue: themeRaw) ?? .wimbledon }

    var matchDetail: MatchDetail? {
        guard mode == .match else { return nil }
        return try? JSONDecoder().decode(MatchDetail.self, from: detailData)
    }

    var game105Detail: Game105Detail? {
        guard mode == .game105 else { return nil }
        return try? JSONDecoder().decode(Game105Detail.self, from: detailData)
    }

    static func record(match detail: MatchDetail, theme: CourtTheme, date: Date = Date()) -> GameRecord {
        GameRecord(
            date: date,
            mode: .match,
            title: "\(detail.playerA) — \(detail.playerB)",
            resultSummary: detail.resultLine,
            winnerName: detail.winnerName,
            theme: theme,
            detailData: (try? JSONEncoder().encode(detail)) ?? Data()
        )
    }

    static func record(game105 detail: Game105Detail, theme: CourtTheme, date: Date = Date()) -> GameRecord {
        GameRecord(
            date: date,
            mode: .game105,
            title: "\(detail.sideA) — \(detail.sideB)",
            resultSummary: detail.resultLine,
            winnerName: detail.winnerName,
            theme: theme,
            detailData: (try? JSONEncoder().encode(detail)) ?? Data()
        )
    }
}

/// Сохранённый пресет правил «105».
@Model
final class RulePreset {
    var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date()
    var categoriesData: Data = Data()

    init(name: String, categories: [PointCategory], createdAt: Date = Date()) {
        self.id = UUID()
        self.name = name
        self.createdAt = createdAt
        self.categoriesData = (try? JSONEncoder().encode(categories)) ?? Data()
    }

    var categories: [PointCategory] {
        (try? JSONDecoder().decode([PointCategory].self, from: categoriesData))
            ?? PointCategory.standardSet()
    }
}

/// Человекочитаемые названия категорий очков «105».
enum CategoryInfo {
    static func title(_ id: String) -> String {
        switch id {
        case PointCategory.errorID: return "Ошибка"
        case PointCategory.winnerID: return "Виннер"
        case PointCategory.volleyID: return "С лёта"
        case PointCategory.lobID: return "Свеча"
        case PointCategory.smashID: return "Смэш"
        default: return id
        }
    }

    static func longTitle(_ id: String) -> String {
        switch id {
        case PointCategory.errorID: return "Ошибка соперника"
        case PointCategory.winnerID: return "Чистый виннер"
        case PointCategory.volleyID: return "Виннер с лёта"
        case PointCategory.lobID: return "Виннер свечой"
        case PointCategory.smashID: return "Смэш с лёта"
        default: return id
        }
    }

    static func symbol(_ id: String) -> String {
        switch id {
        case PointCategory.errorID: return "xmark.circle"
        case PointCategory.winnerID: return "bolt"
        case PointCategory.volleyID: return "figure.tennis"
        case PointCategory.lobID: return "arrow.up.forward"
        case PointCategory.smashID: return "flame"
        default: return "circle"
        }
    }
}
