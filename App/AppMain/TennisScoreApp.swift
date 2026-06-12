import SwiftUI
import SwiftData

@main
struct TennisScoreApp: App {
    private let demo = DemoTarget.fromArguments(ProcessInfo.processInfo.arguments)
    private let container: ModelContainer

    init() {
        let schema = Schema([GameRecord.self, RulePreset.self])
        let isDemo = demo != nil
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isDemo)
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // Падение основного хранилища: работаем из памяти, не теряя функций.
            let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                container = try ModelContainer(for: schema, configurations: [memory])
            } catch {
                fatalError("Unable to create SwiftData storage: \(error)")
            }
        }

        if let demo {
            seedDemoData(for: demo)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(demo: demo)
        }
        .modelContainer(container)
    }

    private func seedDemoData(for demo: DemoTarget) {
        // Запуск приложения всегда происходит на главном потоке.
        MainActor.assumeIsolated {
            switch demo {
            case .history:
                DemoFactory.seedHistory(into: container.mainContext)
            case .settings:
                DemoFactory.seedPresets(into: container.mainContext)
            default:
                break
            }
        }
    }
}
