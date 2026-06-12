import Foundation

/// Сторона корта / игрок в классическом матче.
public enum Player: Int, Codable, Sendable, CaseIterable, Hashable {
    case a = 0
    case b = 1

    public var opponent: Player { self == .a ? .b : .a }
}

/// Конфигурация классического матча.
public struct MatchConfig: Codable, Sendable, Equatable, Hashable {
    public enum Format: Int, Codable, Sendable, CaseIterable, Hashable {
        case bestOfThree = 3
        case bestOfFive = 5

        public var setsToWin: Int { self == .bestOfThree ? 2 : 3 }
    }

    /// Best of 3 или best of 5.
    public var format: Format
    /// Решающее очко при «ровно» вместо «больше/меньше».
    public var noAd: Bool
    /// Вместо решающего сета — супер тай-брейк до 10.
    public var superTiebreakInsteadOfFinalSet: Bool
    /// Геймов для выигрыша сета (стандарт — 6).
    public var gamesForSet: Int
    /// Очков для выигрыша обычного тай-брейка (стандарт — 7).
    public var tiebreakTarget: Int
    /// Очков для выигрыша супер тай-брейка (стандарт — 10).
    public var superTiebreakTarget: Int

    public init(
        format: Format = .bestOfThree,
        noAd: Bool = false,
        superTiebreakInsteadOfFinalSet: Bool = false,
        gamesForSet: Int = 6,
        tiebreakTarget: Int = 7,
        superTiebreakTarget: Int = 10
    ) {
        self.format = format
        self.noAd = noAd
        self.superTiebreakInsteadOfFinalSet = superTiebreakInsteadOfFinalSet
        self.gamesForSet = gamesForSet
        self.tiebreakTarget = tiebreakTarget
        self.superTiebreakTarget = superTiebreakTarget
    }
}

/// Завершённый сет.
public struct CompletedSet: Codable, Sendable, Equatable, Hashable {
    public let gamesA: Int
    public let gamesB: Int
    public let tiebreakPointsA: Int?
    public let tiebreakPointsB: Int?
    public let isSuperTiebreak: Bool

    public init(
        gamesA: Int,
        gamesB: Int,
        tiebreakPointsA: Int? = nil,
        tiebreakPointsB: Int? = nil,
        isSuperTiebreak: Bool = false
    ) {
        self.gamesA = gamesA
        self.gamesB = gamesB
        self.tiebreakPointsA = tiebreakPointsA
        self.tiebreakPointsB = tiebreakPointsB
        self.isSuperTiebreak = isSuperTiebreak
    }

    public var winner: Player { gamesA > gamesB ? .a : .b }

    public func games(of player: Player) -> Int { player == .a ? gamesA : gamesB }

    public func tiebreakPoints(of player: Player) -> Int? {
        player == .a ? tiebreakPointsA : tiebreakPointsB
    }
}

/// Что произошло после розыгрыша очка — для анимаций, хаптики и подсказок UI.
public struct PointOutcome: Equatable, Sendable {
    public var gameWon: Player?
    public var setWon: Player?
    public var matchWon: Player?
    public var tiebreakStarted: Bool
    public var changeEnds: Bool

    public init(
        gameWon: Player? = nil,
        setWon: Player? = nil,
        matchWon: Player? = nil,
        tiebreakStarted: Bool = false,
        changeEnds: Bool = false
    ) {
        self.gameWon = gameWon
        self.setWon = setWon
        self.matchWon = matchWon
        self.tiebreakStarted = tiebreakStarted
        self.changeEnds = changeEnds
    }
}
