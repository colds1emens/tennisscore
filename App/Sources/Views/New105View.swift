import SwiftUI
import SwiftData
import TennisEngine

/// Настройка новой игры «105».
struct New105View: View {
    @Environment(AppRouter.self) private var router
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RulePreset.createdAt) private var presets: [RulePreset]

    @State private var sideA = ""
    @State private var sideB = ""
    @State private var target = 105
    @State private var categories: [PointCategory] = PointCategory.standardSet()

    private var theme: CourtTheme { settings.theme }
    private var nameA: String { sideA.isEmpty ? "Side A" : sideA }
    private var nameB: String { sideB.isEmpty ? "Side B" : sideB }
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
                            sectionLabel("Sides")
                            NameField(placeholder: "Side A — player or team", text: $sideA, theme: theme)
                            NameField(placeholder: "Side B — player or team", text: $sideB, theme: theme)
                            Text("Type a single player or a whole team — whatever you like. You can swap sides any time during the game.")
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
                .readableWidth()
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear {
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
        let viewModel = Game105ViewModel(sideA: nameA, sideB: nameB, theme: theme, config: config)
        settings.targetScore = target
        router.start105(viewModel)
    }
}
