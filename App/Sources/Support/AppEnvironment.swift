import SwiftUI
import TennisEngine

/// Настройки приложения, переживающие перезапуск (UserDefaults).
@Observable
final class AppSettings {
    private let defaults: UserDefaults
    private static let categoriesKey = "settings.categories.v1"
    private static let themeKey = "settings.theme.v1"
    private static let targetKey = "settings.target105.v1"
    private static let winByTwoKey = "settings.winByTwo105.v1"
    private static let feedRuleKey = "settings.feedRule105.v1"

    /// Текущие значения очков «105» (редактируются в настройках).
    var categories: [PointCategory] {
        didSet { save() }
    }

    /// Тема по умолчанию для новых игр.
    var theme: CourtTheme {
        didSet { defaults.set(theme.rawValue, forKey: Self.themeKey) }
    }

    var targetScore: Int {
        didSet { defaults.set(targetScore, forKey: Self.targetKey) }
    }

    var winByTwo: Bool {
        didSet { defaults.set(winByTwo, forKey: Self.winByTwoKey) }
    }

    var feedRule: FeedRule {
        didSet { defaults.set(feedRule.rawValue, forKey: Self.feedRuleKey) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.categoriesKey),
           let saved = try? JSONDecoder().decode([PointCategory].self, from: data) {
            categories = saved
        } else {
            categories = PointCategory.standardSet()
        }
        theme = defaults.string(forKey: Self.themeKey).flatMap(CourtTheme.init(rawValue:)) ?? .wimbledon
        let target = defaults.integer(forKey: Self.targetKey)
        targetScore = target > 0 ? target : 105
        winByTwo = defaults.bool(forKey: Self.winByTwoKey)
        feedRule = defaults.string(forKey: Self.feedRuleKey).flatMap(FeedRule.init(rawValue:)) ?? .winnerFeeds
    }

    private func save() {
        if let data = try? JSONEncoder().encode(categories) {
            defaults.set(data, forKey: Self.categoriesKey)
        }
    }

    /// Чистые настройки для demo-режима: ничего не читают и не пишут на диск.
    static func ephemeral() -> AppSettings {
        let suiteName = "tennisscore.demo.ephemeral"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removePersistentDomain(forName: suiteName)
        return AppSettings(defaults: defaults)
    }

    func game105Config() -> Game105Config {
        Game105Config(
            targetScore: targetScore,
            winByTwo: winByTwo,
            categories: categories,
            feedRule: feedRule
        )
    }
}

/// Экран, на который ведёт навигация.
enum Route: Hashable {
    case newMatch
    case new105
    case match
    case game105
    case victory
    case history
    case settings
}

/// Главный роутер приложения + живые сессии игр.
@Observable
final class AppRouter {
    var path: [Route] = []

    /// Текущие игровые сессии (создаются на экранах настройки новой игры).
    var matchSession: MatchViewModel?
    var game105Session: Game105ViewModel?

    func open(_ route: Route) {
        path.append(route)
    }

    func popToRoot() {
        path.removeAll()
    }

    func startMatch(_ viewModel: MatchViewModel) {
        matchSession = viewModel
        path.append(.match)
    }

    func start105(_ viewModel: Game105ViewModel) {
        game105Session = viewModel
        path.append(.game105)
    }
}
