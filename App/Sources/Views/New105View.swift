import SwiftUI
import SwiftData
import TennisEngine

/// Настройка новой игры «105».
struct New105View: View {
    @Environment(AppRouter.self) private var router
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RulePreset.createdAt) private var presets: [RulePreset]

    @State private var isDoubles = false
    @State private var sideA = ""
    @State private var sideB = ""
    @State private var target = 105
    @State private var winByTwo = false
    @State private var feedRule: FeedRule = .winnerFeeds
    @State private var categories: [PointCategory] = PointCategory.standardSet()
    @State private var selectedPresetName: String?

    private var theme: CourtTheme { settings.theme }
    private var nameA: String { sideA.isEmpty ? (isDoubles ? "Команда А" : "Игрок А") : sideA }
    private var nameB: String { sideB.isEmpty ? (isDoubles ? "Команда Б" : "Игрок Б") : sideB }

    var body: some View {
        ZStack {
            CourtBackground(theme: theme)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    ScreenHeader(title: "Игра «105»", subtitle: "Тренировочный счёт", theme: theme) {
                        router.path.removeLast()
                    }

                    GlassCard(theme: theme) {
                        VStack(spacing: 12) {
                            sectionLabel("Состав")
                            CapsuleSegmentedPicker(
                                options: [false, true],
                                title: { $0 ? "2 на 2" : "1 на 1" },
                                selection: $isDoubles,
                                theme: theme
                            )
                            NameField(
                                placeholder: isDoubles ? "Команда А" : "Игрок А",
                                text: $sideA,
                                theme: theme
                            )
                            NameField(
                                placeholder: isDoubles ? "Команда Б" : "Игрок Б",
                                text: $sideB,
                                theme: theme
                            )
                        }
                    }

                    GlassCard(theme: theme) {
                        VStack(spacing: 14) {
                            sectionLabel("Правила")
                            HStack {
                                Text("Игра до")
                                    .font(.system(.body, design: .rounded).weight(.medium))
                                    .foregroundStyle(theme.textPrimary)
                                Spacer()
                                ValueStepper(value: $target, range: 25...305, step: 5, theme: theme)
                            }
                            ThemedToggleRow(
                                title: "До разницы в 2",
                                subtitle: "Победа только с перевесом в два очка",
                                isOn: $winByTwo,
                                theme: theme
                            )
                        }
                    }

                    GlassCard(theme: theme) {
                        VStack(spacing: 12) {
                            sectionLabel("Кто набрасывает")
                            CapsuleSegmentedPicker(
                                options: FeedRule.allCases,
                                title: { $0 == .winnerFeeds ? "Выигравший" : "Тренер — проигравшим" },
                                selection: $feedRule,
                                theme: theme
                            )
                        }
                    }

                    GlassCard(theme: theme) {
                        VStack(spacing: 12) {
                            sectionLabel("Пресет правил")
                            presetChips
                            categoriesSummary
                        }
                    }

                    PrimaryCapsuleButton(title: "Начать игру", systemImage: "play.fill", theme: theme) {
                        startGame()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear {
            categories = settings.categories
            target = settings.targetScore
            winByTwo = settings.winByTwo
            feedRule = settings.feedRule
        }
    }

    // MARK: - Пресеты

    private var presetChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                presetChip(
                    name: "Классика 1/5/10/20",
                    isSelected: selectedPresetName == nil && categories == PointCategory.standardSet()
                ) {
                    categories = PointCategory.standardSet()
                    selectedPresetName = nil
                }
                presetChip(
                    name: "Мои настройки",
                    isSelected: selectedPresetName == nil && categories == settings.categories
                        && categories != PointCategory.standardSet()
                ) {
                    categories = settings.categories
                    selectedPresetName = nil
                }
                ForEach(presets) { preset in
                    presetChip(name: preset.name, isSelected: selectedPresetName == preset.name) {
                        categories = preset.categories
                        selectedPresetName = preset.name
                    }
                }
            }
        }
    }

    private func presetChip(name: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { action() }
            Haptics.selection()
        } label: {
            Text(name)
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .foregroundStyle(isSelected ? theme.onAccent : theme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Capsule().fill(isSelected ? theme.accent : theme.cardFill))
                .overlay(Capsule().strokeBorder(theme.cardStroke, lineWidth: isSelected ? 0 : 1))
        }
        .buttonStyle(SpringPressStyle())
        .accessibilityLabel("Пресет \(name)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var categoriesSummary: some View {
        VStack(spacing: 6) {
            ForEach(categories.filter(\.isEnabled)) { category in
                HStack {
                    Text(CategoryInfo.longTitle(category.id))
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                    Spacer()
                    Text("+\(category.value)")
                        .font(.system(.subheadline, design: .rounded).weight(.bold).monospacedDigit())
                        .foregroundStyle(theme.textPrimary)
                }
            }
            Text("Значения меняются в Настройках")
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(theme.textSecondary.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 2)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        HStack {
            Text(text.uppercased())
                .font(.system(.caption, design: .rounded).weight(.bold))
                .tracking(1.5)
                .foregroundStyle(theme.textSecondary)
            Spacer()
        }
    }

    private func startGame() {
        let config = Game105Config(
            targetScore: target,
            winByTwo: winByTwo,
            categories: categories,
            feedRule: feedRule
        )
        let viewModel = Game105ViewModel(
            sideA: nameA,
            sideB: nameB,
            theme: theme,
            config: config
        )
        settings.targetScore = target
        settings.winByTwo = winByTwo
        settings.feedRule = feedRule
        router.start105(viewModel)
    }
}
