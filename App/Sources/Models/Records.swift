import Foundation
import SwiftData
import TennisEngine

/// Режим игры для записей истории.
enum GameMode: String, Codable {
    case match
    case game105

    var title: String {
        switch self {
        case .match: return "Match"
        case .game105: return "Game “105”"
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

/// Состав команды: имя команды + список игроков.
struct TeamRoster: Codable, Equatable, Hashable {
    var name: String
    var players: [String]

    init(name: String, players: [String]) {
        self.name = name
        self.players = players
    }

    /// Стартовый состав: N игроков с пустыми именами.
    static func makeDefault(name: String, count: Int = 3) -> TeamRoster {
        TeamRoster(name: name, players: Array(repeating: "", count: max(1, count)))
    }

    /// Имена для показа: пустые поля → «Player N».
    var displayPlayers: [String] {
        players.enumerated().map { index, raw in
            let trimmed = raw.trimmingCharacters(in: .whitespaces)
            return trimmed.isEmpty ? "Player \(index + 1)" : trimmed
        }
    }

    /// «Daniil / Mike / Alex».
    var playersLine: String { displayPlayers.joined(separator: " / ") }
}

/// Слепок завершённой игры «105».
struct Game105Detail: Codable {
    var sideA: String
    var sideB: String
    /// Составы команд (опционально — для записей до v1.1).
    var playersA: [String]?
    var playersB: [String]?
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

    var rosterA: TeamRoster { TeamRoster(name: sideA, players: playersA ?? []) }
    var rosterB: TeamRoster { TeamRoster(name: sideB, players: playersB ?? []) }

    func score(of side: Side) -> Int { side == .a ? scoreA : scoreB }

    /// Текст для «Поделиться» по образцу тестера.
    func shareText(date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US")
        df.dateFormat = "MMMM d, yyyy"
        var lines = ["105 Game Result", ""]
        if !rosterA.players.isEmpty {
            lines.append("\(sideA): \(rosterA.playersLine)")
        } else {
            lines.append(sideA)
        }
        lines.append("Score: \(scoreA)")
        lines.append("")
        if !rosterB.players.isEmpty {
            lines.append("\(sideB): \(rosterB.playersLine)")
        } else {
            lines.append(sideB)
        }
        lines.append("Score: \(scoreB)")
        lines.append("")
        lines.append("Winner: \(winnerName)")
        lines.append("")
        lines.append("Game type: First to \(config.targetScore)")
        lines.append("Date: \(df.string(from: date))")
        return lines.joined(separator: "\n")
    }
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
        case PointCategory.errorID: return "Error"
        case PointCategory.winnerID: return "Winner"
        case PointCategory.volleyID: return "Volley"
        case PointCategory.lobID: return "Lob"
        case PointCategory.smashID: return "Smash"
        default: return id
        }
    }

    static func longTitle(_ id: String) -> String {
        switch id {
        case PointCategory.errorID: return "Error"
        case PointCategory.winnerID: return "Clean winner"
        case PointCategory.volleyID: return "Volley winner"
        case PointCategory.lobID: return "Lob winner"
        case PointCategory.smashID: return "Overhead Smash"
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
        default: return "star.circle"
        }
    }

    /// Символ по умолчанию для новых пользовательских категорий.
    static let customDefaultSymbol = "star.circle.fill"
}

extension PointCategory {
    /// Короткое название для кнопок (кастомное или встроенное).
    var displayTitle: String {
        if let customTitle, !customTitle.isEmpty { return customTitle }
        return CategoryInfo.title(id)
    }

    /// Длинное название для настроек (кастомное или встроенное).
    var displayLongTitle: String {
        if let customTitle, !customTitle.isEmpty { return customTitle }
        return CategoryInfo.longTitle(id)
    }

    /// SF Symbol (кастомный или встроенный).
    var displaySymbol: String {
        if let symbolName, !symbolName.isEmpty { return symbolName }
        return CategoryInfo.symbol(id)
    }

    /// Подпись стоимости со знаком: «+5» или «−3».
    var signedValueText: String {
        value < 0 ? "−\(abs(value))" : "+\(value)"
    }
}
