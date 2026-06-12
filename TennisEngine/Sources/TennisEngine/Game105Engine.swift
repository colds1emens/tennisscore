import Foundation

/// Сторона в игре «105» (игрок или команда).
public enum Side: Int, Codable, Sendable, CaseIterable, Hashable {
    case a = 0
    case b = 1

    public var opponent: Side { self == .a ? .b : .a }
}

/// Кто набрасывает мяч после розыгрыша.
public enum FeedRule: String, Codable, Sendable, CaseIterable, Hashable {
    /// Набрасывает сторона, выигравшая очко.
    case winnerFeeds
    /// Тренер набрасывает проигравшим очко.
    case coachFeedsLoser
}

/// Тип начисления очков в «105».
public struct PointCategory: Codable, Equatable, Hashable, Identifiable, Sendable {
    /// Стабильный идентификатор: "error", "winner", "volley", "lob", "smash".
    public let id: String
    public var value: Int
    public var isEnabled: Bool

    public init(id: String, value: Int, isEnabled: Bool = true) {
        self.id = id
        self.value = value
        self.isEnabled = isEnabled
    }

    public static let errorID = "error"
    public static let winnerID = "winner"
    public static let volleyID = "volley"
    public static let lobID = "lob"
    public static let smashID = "smash"

    /// Стандартный набор: ошибка +1, виннер +5, с лёта +10, свеча +10, смэш +20.
    public static func standardSet() -> [PointCategory] {
        [
            PointCategory(id: errorID, value: 1),
            PointCategory(id: winnerID, value: 5),
            PointCategory(id: volleyID, value: 10),
            PointCategory(id: lobID, value: 10),
            PointCategory(id: smashID, value: 20)
        ]
    }
}

/// Конфигурация игры «105».
public struct Game105Config: Codable, Equatable, Hashable, Sendable {
    public var targetScore: Int
    /// Играть «до разницы в 2»: достигнув цели, нужно ещё и вести на 2 очка.
    public var winByTwo: Bool
    public var categories: [PointCategory]
    public var feedRule: FeedRule

    public init(
        targetScore: Int = 105,
        winByTwo: Bool = false,
        categories: [PointCategory] = PointCategory.standardSet(),
        feedRule: FeedRule = .winnerFeeds
    ) {
        self.targetScore = targetScore
        self.winByTwo = winByTwo
        self.categories = categories
        self.feedRule = feedRule
    }

    public var enabledCategories: [PointCategory] { categories.filter(\.isEnabled) }

    public var maxEnabledValue: Int { enabledCategories.map(\.value).max() ?? 0 }

    public func category(id: String) -> PointCategory? {
        categories.first { $0.id == id }
    }
}

/// Событие начисления очков.
public struct ScoreEvent: Codable, Equatable, Hashable, Identifiable, Sendable {
    public let id: Int
    public let side: Side
    public let categoryID: String
    /// Стоимость на момент начисления (на случай смены настроек по ходу игры).
    public let value: Int

    public init(id: Int, side: Side, categoryID: String, value: Int) {
        self.id = id
        self.side = side
        self.categoryID = categoryID
        self.value = value
    }
}

/// Сводка по типу очков для итоговой карточки.
public struct CategoryTotal: Equatable, Hashable, Sendable, Identifiable {
    public let categoryID: String
    public let count: Int
    public let total: Int

    public var id: String { categoryID }

    public init(categoryID: String, count: Int, total: Int) {
        self.categoryID = categoryID
        self.count = count
        self.total = total
    }
}

/// Движок тренировочной игры «105»: сумма очков по событиям,
/// полный undo/redo стек, определение победы и гейм-пойнта.
public struct Game105Engine: Equatable, Codable, Sendable {
    public let config: Game105Config
    public private(set) var events: [ScoreEvent] = []

    private var redoStack: [ScoreEvent] = []
    private var nextEventID = 1
    private var cachedScoreA = 0
    private var cachedScoreB = 0

    public init(config: Game105Config = Game105Config()) {
        self.config = config
    }

    // MARK: - Счёт

    public func score(of side: Side) -> Int {
        side == .a ? cachedScoreA : cachedScoreB
    }

    public var winner: Side? {
        for side in Side.allCases {
            let mine = score(of: side)
            let theirs = score(of: side.opponent)
            if mine >= config.targetScore && (!config.winByTwo || mine - theirs >= 2) {
                return side
            }
        }
        return nil
    }

    public var isFinished: Bool { winner != nil }

    /// «Гейм-пойнт»: сторона может выиграть одним начислением.
    public func isGamePoint(for side: Side) -> Bool {
        guard !isFinished else { return false }
        let mine = score(of: side)
        let theirs = score(of: side.opponent)
        return config.enabledCategories.contains { category in
            let next = mine + category.value
            return next >= config.targetScore && (!config.winByTwo || next - theirs >= 2)
        }
    }

    public var lastPointWinner: Side? { events.last?.side }

    /// Кому набрасывать следующий мяч; nil до первого розыгрыша.
    public var feedingSide: Side? {
        guard let last = lastPointWinner else { return nil }
        switch config.feedRule {
        case .winnerFeeds: return last
        case .coachFeedsLoser: return last.opponent
        }
    }

    // MARK: - Начисление

    /// Начислить очки. Возвращает событие либо nil,
    /// если игра завершена или категория выключена/неизвестна.
    @discardableResult
    public mutating func award(_ categoryID: String, to side: Side) -> ScoreEvent? {
        guard !isFinished,
              let category = config.category(id: categoryID),
              category.isEnabled
        else { return nil }

        let event = ScoreEvent(id: nextEventID, side: side, categoryID: categoryID, value: category.value)
        nextEventID += 1
        events.append(event)
        redoStack.removeAll()
        apply(event, sign: 1)
        return event
    }

    // MARK: - Undo / Redo

    public var canUndo: Bool { !events.isEmpty }
    public var canRedo: Bool { !redoStack.isEmpty }

    /// Отменить последнее начисление. Возвращает отменённое событие.
    @discardableResult
    public mutating func undo() -> ScoreEvent? {
        guard let event = events.popLast() else { return nil }
        redoStack.append(event)
        apply(event, sign: -1)
        return event
    }

    /// Вернуть отменённое начисление.
    @discardableResult
    public mutating func redo() -> ScoreEvent? {
        guard let event = redoStack.popLast() else { return nil }
        events.append(event)
        apply(event, sign: 1)
        return event
    }

    private mutating func apply(_ event: ScoreEvent, sign: Int) {
        if event.side == .a {
            cachedScoreA += sign * event.value
        } else {
            cachedScoreB += sign * event.value
        }
    }

    // MARK: - Сводка

    /// Разбивка набранных очков по типам для стороны
    /// (в порядке категорий конфигурации).
    public func breakdown(for side: Side) -> [CategoryTotal] {
        config.categories.compactMap { category in
            let matched = events.filter { $0.side == side && $0.categoryID == category.id }
            guard !matched.isEmpty else { return nil }
            return CategoryTotal(
                categoryID: category.id,
                count: matched.count,
                total: matched.reduce(0) { $0 + $1.value }
            )
        }
    }

    /// Последние события для ленты (новые в конце).
    public func recentEvents(limit: Int) -> [ScoreEvent] {
        Array(events.suffix(limit))
    }
}
