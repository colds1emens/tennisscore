import SwiftUI
import SwiftData
import TennisEngine

/// Настройка новой игры «105».
struct New105View: View {
    @Environment(AppRouter.self) private var router
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RulePreset.createdAt) private var presets: [RulePreset]

    @State private var playersA: [RosterPlayer] = .roster(count: 3)
    @State private var playersB: [RosterPlayer] = .roster(count: 3)
    @State private var target = 105
    @State private var categories: [PointCategory] = PointCategory.standardSet()
    @State private var didLoad = false

    private var theme: CourtTheme { settings.theme }
    private var hasEnabled: Bool { categories.contains(where: \.isEnabled) }

    var body: some View {
        ZStack {
            CourtBackground(theme: theme)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    ScreenHeader(title: "Game “105”", subtitle: "Practice scoring", theme: theme) {
                        router.path.removeLast()
                    }

                    GlassCard(theme: theme) {
                        VStack(spacing: 12) {
                            HStack {
                                sectionLabel("Teams")
                                Spacer()
                            }
                            RosterEditor(playersA: $playersA, playersB: $playersB, theme: theme)
                            Text("Default is 3 vs 3. Add or remove players — 1 to 6 each, teams can be uneven. You can move players between teams after each game.")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(theme.textSecondary.opacity(0.7))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    GlassCard(theme: theme) {
                        HStack {
                            Text("Play to")
                                .font(.system(.body, design: .rounded).weight(.medium))
                                .foregroundStyle(theme.textPrimary)
                            Spacer()
                            ValueStepper(value: $target, range: 25...305, step: 5, theme: theme)
                        }
                    }

                    GlassCard(theme: theme) {
                        VStack(spacing: 12) {
                            HStack {
                                sectionLabel("Points")
                                Spacer()
                                presetMenu
                            }
                            CategoryListEditor(categories: $categories, theme: theme)
                        }
                    }

                    PrimaryCapsuleButton(
                        title: "Start game",
                        systemImage: "play.fill",
                        theme: theme,
                        isEnabled: hasEnabled
                    ) {
                        startGame()
                    }
                    .accessibilityHint(hasEnabled ? "" : "Enable at least one point type")
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .readableWidth(isPadDevice ? 860 : 620)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            categories = settings.categories
            target = settings.targetScore
        }
    }

    // MARK: - Пресеты (быстрый сброс/загрузка)

    private var presetMenu: some View {
        Menu {
            Button("Classic 1/5/10/20") {
                withAnimation(.spring(response: 0.3)) { categories = PointCategory.standardSet() }
            }
            Button("My defaults") {
                withAnimation(.spring(response: 0.3)) { categories = settings.categories }
            }
            if !presets.isEmpty {
                Divider()
                ForEach(presets) { preset in
                    Button(preset.name) {
                        withAnimation(.spring(response: 0.3)) { categories = preset.categories }
                    }
                }
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "slider.horizontal.3")
                Text("Presets")
            }
            .font(.system(.footnote, design: .rounded).weight(.semibold))
            .foregroundStyle(theme.accent)
            .brightness(0.2)
        }
        .accessibilityLabel("Apply a rules preset")
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(.caption, design: .rounded).weight(.bold))
            .tracking(1.5)
            .foregroundStyle(theme.textSecondary)
    }

    private func startGame() {
        guard hasEnabled else { return }
        let config = Game105Config(targetScore: target, categories: categories)
        let viewModel = Game105ViewModel(
            sideA: "Team A",
            sideB: "Team B",
            playersA: playersA.names,
            playersB: playersB.names,
            theme: theme,
            config: config
        )
        settings.targetScore = target
        router.start105(viewModel)
    }
}
