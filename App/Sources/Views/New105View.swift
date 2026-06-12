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
    private var nameA: String { sideA.isEmpty ? (isDoubles ? "Team A" : "Player A") : sideA }
    private var nameB: String { sideB.isEmpty ? (isDoubles ? "Team B" : "Player B") : sideB }

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
                            sectionLabel("Players")
                            CapsuleSegmentedPicker(
                                options: [false, true],
                                title: { $0 ? "2 v 2" : "1 v 1" },
                                selection: $isDoubles,
                                theme: theme
                            )
                            NameField(
                                placeholder: isDoubles ? "Team A" : "Player A",
                                text: $sideA,
                                theme: theme
                            )
                            NameField(
                                placeholder: isDoubles ? "Team B" : "Player B",
                                text: $sideB,
                                theme: theme
                            )
                        }
                    }

                    GlassCard(theme: theme) {
                        VStack(spacing: 14) {
                            sectionLabel("Rules")
                            HStack {
                                Text("Play to")
                                    .font(.system(.body, design: .rounded).weight(.medium))
                                    .foregroundStyle(theme.textPrimary)
                                Spacer()
                                ValueStepper(value: $target, range: 25...305, step: 5, theme: theme)
                            }
                            ThemedToggleRow(
                                title: "Win by 2",
                                subtitle: "Victory requires a two-point lead",
                                isOn: $winByTwo,
                                theme: theme
                            )
                        }
                    }

                    GlassCard(theme: theme) {
                        VStack(spacing: 12) {
                            sectionLabel("Who feeds the ball")
                            CapsuleSegmentedPicker(
                                options: FeedRule.allCases,
                                title: { $0 == .winnerFeeds ? "Point winner" : "Coach — to loser" },
                                selection: $feedRule,
                                theme: theme
                            )
                        }
                    }

                    GlassCard(theme: theme) {
                        VStack(spacing: 12) {
                            sectionLabel("Rules preset")
                            presetChips
                            categoriesSummary
                        }
                    }

                    PrimaryCapsuleButton(title: "Start game", systemImage: "play.fill", theme: theme) {
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
                    name: "Classic 1/5/10/20",
                    isSelected: selectedPresetName == nil && categories == PointCategory.standardSet()
                ) {
                    categories = PointCategory.standardSet()
                    selectedPresetName = nil
                }
                presetChip(
                    name: "My settings",
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
        .accessibilityLabel("Preset \(name)")
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
            Text("Values can be changed in Settings")
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
