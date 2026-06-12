import SwiftUI
import TennisEngine

/// Состояние экрана классического матча поверх движка.
@Observable
@MainActor
final class MatchViewModel {
    private(set) var engine: MatchEngine
    let playerA: String
    let playerB: String
    let theme: CourtTheme

    /// Подсказка «смена сторон» (исчезает сама).
    var showChangeEnds = false
    /// Счётчик залпов конфетти (увеличение запускает залп).
    var confettiBursts = 0
    /// Тост (например, после undo).
    var toast: String?
    /// Записан ли результат в историю.
    var savedToHistory = false

    private var changeEndsTask: Task<Void, Never>?
    private var toastTask: Task<Void, Never>?

    init(playerA: String, playerB: String, theme: CourtTheme, config: MatchConfig, initialServer: Player) {
        self.playerA = playerA
        self.playerB = playerB
        self.theme = theme
        self.engine = MatchEngine(config: config, initialServer: initialServer)
    }

    /// Готовый движок (для demo-сценариев).
    init(playerA: String, playerB: String, theme: CourtTheme, engine: MatchEngine) {
        self.playerA = playerA
        self.playerB = playerB
        self.theme = theme
        self.engine = engine
    }

    func name(_ player: Player) -> String { player == .a ? playerA : playerB }

    var isFinished: Bool { engine.isFinished }

    // MARK: - Действия

    func point(_ player: Player) {
        guard !engine.isFinished else { return }
        let outcome = engine.winPoint(player)

        if outcome.matchWon != nil {
            Haptics.success()
            confettiBursts += 1
        } else if outcome.setWon != nil {
            Haptics.success()
            confettiBursts += 1
        } else if outcome.gameWon != nil {
            Haptics.success()
        } else {
            Haptics.impact(0.5)
        }

        if outcome.changeEnds && outcome.matchWon == nil {
            flashChangeEnds()
        }
        if outcome.tiebreakStarted {
            showToast(engine.isSuperTiebreak ? "Супер тай-брейк" : "Тай-брейк")
        }
    }

    func undo() {
        guard engine.canUndo else { return }
        engine.undo()
        Haptics.warning()
        showToast("Отменено")
    }

    // MARK: - Подсказки

    private func flashChangeEnds() {
        changeEndsTask?.cancel()
        withAnimation(.spring(duration: 0.45)) { showChangeEnds = true }
        changeEndsTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(3.2))
            guard let self, !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.4)) { self.showChangeEnds = false }
        }
    }

    private func showToast(_ text: String) {
        toastTask?.cancel()
        withAnimation(.spring(duration: 0.35)) { toast = text }
        toastTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.2))
            guard let self, !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.35)) { self.toast = nil }
        }
    }

    // MARK: - Итог

    func makeDetail() -> MatchDetail? {
        guard let winner = engine.winner else { return nil }
        return MatchDetail(
            playerA: playerA,
            playerB: playerB,
            config: engine.config,
            sets: engine.completedSets,
            winner: winner
        )
    }
}
