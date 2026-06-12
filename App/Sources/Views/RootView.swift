import SwiftUI
import SwiftData
import TennisEngine

/// Корень приложения: навигация и запуск demo-сценариев.
struct RootView: View {
    @State private var router = AppRouter()
    @State private var settings: AppSettings
    let demo: DemoTarget?

    init(demo: DemoTarget?) {
        self.demo = demo
        _settings = State(initialValue: demo != nil ? AppSettings.ephemeral() : AppSettings())
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationBarBackButtonHidden(true)
                .navigationDestination(for: Route.self) { route in
                    destination(for: route)
                        .navigationBarBackButtonHidden(true)
                        .toolbar(.hidden, for: .navigationBar)
                }
                .toolbar(.hidden, for: .navigationBar)
        }
        .environment(router)
        .environment(settings)
        .tint(settings.theme.accent)
        .preferredColorScheme(nil)
        .onAppear { applyDemoIfNeeded() }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .newMatch:
            NewMatchView()
        case .new105:
            New105View()
        case .match:
            if let session = router.matchSession {
                MatchView(viewModel: session)
            } else {
                HomeView()
            }
        case .game105:
            if let session = router.game105Session {
                Game105View(viewModel: session)
            } else {
                HomeView()
            }
        case .victory:
            VictoryView()
        case .history:
            HistoryView()
        case .settings:
            SettingsView()
        }
    }

    private func applyDemoIfNeeded() {
        guard let demo else { return }
        switch demo {
        case .home:
            break
        case .newmatch:
            router.path = [.newMatch]
        case .match:
            router.matchSession = DemoFactory.midMatchSession(settings: settings)
            router.path = [.match]
        case .tiebreak:
            router.matchSession = DemoFactory.tiebreakSession(settings: settings)
            router.path = [.match]
        case .game105:
            router.game105Session = DemoFactory.game105Session(settings: settings)
            router.path = [.game105]
        case .victory:
            router.game105Session = DemoFactory.finished105Session(settings: settings)
            router.path = [.victory]
        case .history:
            router.path = [.history]
        case .settings:
            router.path = [.settings]
        }
    }
}

/// Аргумент --demo для скриншотов без ручной навигации.
enum DemoTarget: String {
    case home
    case newmatch
    case match
    case tiebreak
    case game105 = "105"
    case victory
    case history
    case settings

    static func fromArguments(_ arguments: [String]) -> DemoTarget? {
        guard let index = arguments.firstIndex(of: "--demo"),
              arguments.indices.contains(index + 1)
        else { return nil }
        return DemoTarget(rawValue: arguments[index + 1].lowercased())
    }
}
