import SwiftUI
import TennisEngine

/// Состояние экрана игры «105».
@Observable
@MainActor
final class Game105ViewModel {
    private(set) var engine: Game105Engine
    let sideA: String
    let sideB: String
    let theme: CourtTheme

    /// Тост после undo: «Отменено: Виннер +5, сторона А».
    var toast: String?
    /// Счётчик залпов конфетти/салюта.
    var confettiBursts = 0
    /// Последнее начисление для анимации «вылетающей капсулы».
    var lastAward: AwardFlash?
    var savedToHistory = false

    struct AwardFlash: Equatable, Identifiable {
        let id: Int
        let side: Side
        let value: Int
    }

    private var toastTask: Task<Void, Never>?

    init(sideA: String, sideB: String, theme: CourtTheme, config: Game105Config) {
        self.sideA = sideA
        self.sideB = sideB
        self.theme = theme
        self.engine = Game105Engine(config: config)
    }

    /// Готовый движок (для demo-сценариев).
    init(sideA: String, sideB: String, theme: CourtTheme, engine: Game105Engine) {
        self.sideA = sideA
        self.sideB = sideB
        self.theme = theme
        self.engine = engine
    }

    func name(_ side: Side) -> String { side == .a ? sideA : sideB }

    var isFinished: Bool { engine.isFinished }

    // MARK: - Действия

    func award(_ categoryID: String, to side: Side) {
        guard let event = engine.award(categoryID, to: side) else { return }
        Haptics.impact(value: event.value, maxValue: engine.config.maxEnabledValue)
        withAnimation(.spring(duration: 0.5)) {
            lastAward = AwardFlash(id: event.id, side: event.side, value: event.value)
        }
        if engine.isFinished {
            Haptics.success()
            confettiBursts += 1
        }
    }

    func undo() {
        guard let event = engine.undo() else { return }
        Haptics.warning()
        let sideName = event.side == .a ? "A" : "B"
        showToast("Undone: \(CategoryInfo.title(event.categoryID)) +\(event.value), side \(sideName)")
    }

    func redo() {
        guard let event = engine.redo() else { return }
        Haptics.impact(value: event.value, maxValue: engine.config.maxEnabledValue)
        let sideName = event.side == .a ? "A" : "B"
        showToast("Redone: \(CategoryInfo.title(event.categoryID)) +\(event.value), side \(sideName)")
    }

    private func showToast(_ text: String) {
        toastTask?.cancel()
        withAnimation(.spring(duration: 0.35)) { toast = text }
        toastTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.4))
            guard let self, !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.35)) { self.toast = nil }
        }
    }

    // MARK: - Лента событий

    struct TickerLine: Identifiable {
        let id: Int
        let text: String
    }

    var recentLines: [TickerLine] {
        engine.recentEvents(limit: 5).reversed().map { event in
            let sideName = event.side == .a ? sideA : sideB
            return TickerLine(
                id: event.id,
                text: "\(sideName): \(CategoryInfo.title(event.categoryID).lowercased()) +\(event.value)"
            )
        }
    }

    // MARK: - Итог

    func makeDetail() -> Game105Detail? {
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
