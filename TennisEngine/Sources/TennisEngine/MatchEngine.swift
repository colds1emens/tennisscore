import Foundation

/// Конечный автомат классического теннисного матча.
///
/// Чистая value-семантика: всё состояние — структура, undo/redo реализованы
/// стеками снимков, бейджи (game/set/match/break point) — симуляцией
/// следующего очка на копии, что исключает расхождение с реальными правилами.
public struct MatchEngine: Equatable, Codable, Sendable {

    // MARK: - Внутреннее состояние

    struct GamePoints: Equatable, Codable, Hashable, Sendable {
        var a = 0
        var b = 0

        func points(of player: Player) -> Int { player == .a ? a : b }

        mutating func add(to player: Player) {
            if player == .a { a += 1 } else { b += 1 }
        }
    }

    enum Phase: Equatable, Codable, Hashable, Sendable {
        case game(points: GamePoints)
        case tiebreak(points: GamePoints, target: Int, isSuper: Bool)
        case finished(winner: Player)
    }

    struct Snapshot: Equatable, Codable, Hashable, Sendable {
        var completedSets: [CompletedSet]
        var gamesA: Int
        var gamesB: Int
        var phase: Phase
        var currentGameServer: Player
    }

    public let config: MatchConfig
    public private(set) var initialServer: Player

    public private(set) var completedSets: [CompletedSet] = []
    public private(set) var gamesA = 0
    public private(set) var gamesB = 0

    private(set) var phase: Phase
    /// Подающий в текущем гейме; для тай-брейка — подающий первым в тай-брейке.
    private(set) var currentGameServer: Player

    private var history: [Snapshot] = []
    private var future: [Snapshot] = []

    public init(config: MatchConfig = MatchConfig(), initialServer: Player = .a) {
        self.config = config
        self.initialServer = initialServer
        self.currentGameServer = initialServer
        self.phase = .game(points: GamePoints())
    }

    // MARK: - Снимки для undo/redo

    var snapshot: Snapshot {
        get {
            Snapshot(
                completedSets: completedSets,
                gamesA: gamesA,
                gamesB: gamesB,
                phase: phase,
                currentGameServer: currentGameServer
            )
        }
        set {
            completedSets = newValue.completedSets
            gamesA = newValue.gamesA
            gamesB = newValue.gamesB
            phase = newValue.phase
            currentGameServer = newValue.currentGameServer
        }
    }

    public var canUndo: Bool { !history.isEmpty }
    public var canRedo: Bool { !future.isEmpty }

    @discardableResult
    public mutating func undo() -> Bool {
        guard let previous = history.popLast() else { return false }
        future.append(snapshot)
        snapshot = previous
        return true
    }

    @discardableResult
    public mutating func redo() -> Bool {
        guard let next = future.popLast() else { return false }
        history.append(snapshot)
        snapshot = next
        return true
    }

    // MARK: - Розыгрыш очка

    @discardableResult
    public mutating func winPoint(_ player: Player) -> PointOutcome {
        guard !isFinished else { return PointOutcome() }
        history.append(snapshot)
        future.removeAll()
        return applyPoint(player)
    }

    private mutating func applyPoint(_ player: Player) -> PointOutcome {
        var outcome = PointOutcome()
        switch phase {
        case .finished:
            break

        case .game(var points):
            points.add(to: player)
            if isGameWon(points: points, by: player) {
                outcome.gameWon = player
                registerGameWin(by: player, outcome: &outcome)
            } else {
                phase = .game(points: points)
            }

        case .tiebreak(var points, let target, let isSuper):
            points.add(to: player)
            let mine = points.points(of: player)
            let theirs = points.points(of: player.opponent)
            if mine >= target && mine - theirs >= 2 {
                outcome.gameWon = player
                if isSuper {
                    completedSets.append(
                        CompletedSet(
                            gamesA: player == .a ? 1 : 0,
                            gamesB: player == .b ? 1 : 0,
                            tiebreakPointsA: points.a,
                            tiebreakPointsB: points.b,
                            isSuperTiebreak: true
                        )
                    )
                    outcome.setWon = player
                    outcome.matchWon = player
                    phase = .finished(winner: player)
                } else {
                    if player == .a { gamesA += 1 } else { gamesB += 1 }
                    finishSet(winner: player, tiebreak: points, outcome: &outcome)
                }
            } else {
                phase = .tiebreak(points: points, target: target, isSuper: isSuper)
                let played = points.a + points.b
                if played > 0 && played % 6 == 0 {
                    outcome.changeEnds = true
                }
            }
        }
        return outcome
    }

    private func isGameWon(points: GamePoints, by player: Player) -> Bool {
        let mine = points.points(of: player)
        let theirs = points.points(of: player.opponent)
        if config.noAd {
            return mine >= 4
        }
        return mine >= 4 && mine - theirs >= 2
    }

    private mutating func registerGameWin(by player: Player, outcome: inout PointOutcome) {
        if player == .a { gamesA += 1 } else { gamesB += 1 }
        let mine = player == .a ? gamesA : gamesB
        let theirs = player == .a ? gamesB : gamesA

        if mine >= config.gamesForSet && mine - theirs >= 2 {
            finishSet(winner: player, tiebreak: nil, outcome: &outcome)
        } else if gamesA == config.gamesForSet && gamesB == config.gamesForSet {
            currentGameServer = currentGameServer.opponent
            phase = .tiebreak(points: GamePoints(), target: config.tiebreakTarget, isSuper: false)
            outcome.tiebreakStarted = true
        } else {
            currentGameServer = currentGameServer.opponent
            phase = .game(points: GamePoints())
            if (gamesA + gamesB) % 2 == 1 {
                outcome.changeEnds = true
            }
        }
    }

    private mutating func finishSet(winner: Player, tiebreak: GamePoints?, outcome: inout PointOutcome) {
        completedSets.append(
            CompletedSet(
                gamesA: gamesA,
                gamesB: gamesB,
                tiebreakPointsA: tiebreak?.a,
                tiebreakPointsB: tiebreak?.b,
                isSuperTiebreak: false
            )
        )
        outcome.setWon = winner
        // Тай-брейк считается одним геймом при подсчёте суммы для смены сторон.
        let totalGames = gamesA + gamesB
        gamesA = 0
        gamesB = 0
        if totalGames % 2 == 1 {
            outcome.changeEnds = true
        }

        if setsWon(by: winner) >= config.format.setsToWin {
            outcome.matchWon = winner
            phase = .finished(winner: winner)
            return
        }

        // Подача в первом гейме следующего сета переходит к сопернику подававшего
        // в последнем гейме (для тай-брейка — подававшего первым в тай-брейке).
        currentGameServer = currentGameServer.opponent

        let setsEach = config.format.setsToWin - 1
        if config.superTiebreakInsteadOfFinalSet,
           setsWon(by: .a) == setsEach, setsWon(by: .b) == setsEach {
            phase = .tiebreak(points: GamePoints(), target: config.superTiebreakTarget, isSuper: true)
            outcome.tiebreakStarted = true
        } else {
            phase = .game(points: GamePoints())
        }
    }

    // MARK: - Текущее состояние для UI

    public var isFinished: Bool {
        if case .finished = phase { return true }
        return false
    }

    public var winner: Player? {
        if case .finished(let winner) = phase { return winner }
        return nil
    }

    public func setsWon(by player: Player) -> Int {
        completedSets.filter { $0.winner == player }.count
    }

    public func games(of player: Player) -> Int { player == .a ? gamesA : gamesB }

    public var isTiebreak: Bool {
        if case .tiebreak = phase { return true }
        return false
    }

    public var isSuperTiebreak: Bool {
        if case .tiebreak(_, _, let isSuper) = phase { return isSuper }
        return false
    }

    /// Подающий на текущем розыгрыше.
    public var server: Player {
        switch phase {
        case .game:
            return currentGameServer
        case .tiebreak(let points, _, _):
            // Первый розыгрыш — начавший тай-брейк, далее смена после 1-го очка
            // и затем каждые 2 очка.
            let played = points.a + points.b
            let pairIndex = (played + 1) / 2
            return pairIndex.isMultiple(of: 2) ? currentGameServer : currentGameServer.opponent
        case .finished:
            return currentGameServer
        }
    }

    /// «Ровно» (40:40 и далее при равенстве).
    public var isDeuce: Bool {
        if case .game(let points) = phase {
            return points.a >= 3 && points.a == points.b
        }
        return false
    }

    /// У кого «больше» (advantage); nil, если его нет.
    public var advantage: Player? {
        if case .game(let points) = phase, points.a >= 3, points.b >= 3 {
            if points.a == points.b + 1 { return .a }
            if points.b == points.a + 1 { return .b }
        }
        return nil
    }

    /// Сырые очки текущего гейма или тай-брейка (для тай-брейка — счёт очков).
    public func rawPoints(of player: Player) -> Int {
        switch phase {
        case .game(let points), .tiebreak(let points, _, _):
            return points.points(of: player)
        case .finished:
            return 0
        }
    }

    /// Табличное обозначение счёта в гейме: "0", "15", "30", "40", "Ad".
    public func gameScoreText(for player: Player) -> String {
        switch phase {
        case .game(let points):
            let mine = points.points(of: player)
            let theirs = points.points(of: player.opponent)
            if mine >= 3 && theirs >= 3 {
                return mine > theirs ? "Ad" : "40"
            }
            return ["0", "15", "30", "40"][min(mine, 3)]
        case .tiebreak(let points, _, _):
            return String(points.points(of: player))
        case .finished:
            return "—"
        }
    }

    // MARK: - Бейджи: симуляция следующего очка

    private func simulatePoint(for player: Player) -> PointOutcome {
        var copy = self
        copy.history.removeAll()
        copy.future.removeAll()
        guard !copy.isFinished else { return PointOutcome() }
        return copy.applyPoint(player)
    }

    /// Выиграет ли игрок гейм (или тай-брейк), взяв следующее очко.
    public func isGamePoint(for player: Player) -> Bool {
        simulatePoint(for: player).gameWon == player
    }

    /// Брейк-пойнт: гейм-пойнт у принимающего (в тай-брейке не определяется).
    public func isBreakPoint(for player: Player) -> Bool {
        !isTiebreak && server == player.opponent && isGamePoint(for: player)
    }

    /// Выиграет ли игрок сет, взяв следующее очко.
    public func isSetPoint(for player: Player) -> Bool {
        simulatePoint(for: player).setWon == player
    }

    /// Выиграет ли игрок матч, взяв следующее очко.
    public func isMatchPoint(for player: Player) -> Bool {
        simulatePoint(for: player).matchWon == player
    }
}
