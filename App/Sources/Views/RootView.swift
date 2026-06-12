import SwiftUI
import SwiftData
import TennisEngine

/// Корень приложения: навигация и запуск demo-сценариев.
struct RootView: View {
    @State private var router = AppRouter()
    @State private var settings: AppSettings
    @State private var store: StoreManager
    @State private var trial: TrialManager
    @State private var accountManager = AccountManager()
    let demo: DemoTarget?

    init(demo: DemoTarget?) {
        self.demo = demo
        _settings = State(initialValue: demo != nil ? AppSettings.ephemeral() : AppSettings())
        _store = State(initialValue: StoreManager(autoload: demo == nil))
        _trial = State(initialValue: TrialManager(ephemeral: demo != nil))
    }

    var body: some View {
        Group {
            switch gate {
            case .auth:
                AuthView()
                    .transition(.opacity)
            case .paywall:
                PaywallView()
                    .transition(.opacity)
            case .app:
                mainNavigation
            }
        }
        .animation(.easeInOut(duration: 0.3), value: gate)
        .environment(router)
        .environment(settings)
        .environment(store)
        .environment(trial)
        .environment(accountManager)
        .environment(\.locale, Locale(identifier: "en_US"))
        .tint(settings.theme.accent)
        .preferredColorScheme(nil)
        .onAppear { applyDemoIfNeeded() }
    }

    private enum Gate: Equatable {
        case auth
        case paywall
        case app
    }

    private var gate: Gate {
        // Demo-режимы открывают нужный экран напрямую, минуя гейты.
        if let demo {
            switch demo {
            case .auth: return .auth
            case .paywall: return .paywall
            default: return .app
            }
        }
        if !accountManager.isSignedIn { return .auth }
        if !store.isSubscribed && !trial.isTrialActive { return .paywall }
        return .app
    }

    private var mainNavigation: some View {
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
        case .home, .auth, .paywall:
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
    case auth
    case paywall

    static func fromArguments(_ arguments: [String]) -> DemoTarget? {
        guard let index = arguments.firstIndex(of: "--demo"),
              arguments.indices.contains(index + 1)
        else { return nil }
        return DemoTarget(rawValue: arguments[index + 1].lowercased())
    }
}
