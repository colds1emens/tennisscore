import SwiftUI
import TennisEngine

/// Настройка нового классического матча + жеребьёвка подачи.
struct NewMatchView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AppSettings.self) private var settings

    @State private var playerA = ""
    @State private var playerB = ""
    @State private var format: MatchConfig.Format = .bestOfThree
    @State private var noAd = false
    @State private var superTiebreak = false
    @State private var theme: CourtTheme = .wimbledon
    @State private var server: Player?
    @State private var showCoinFlip = false

    private var nameA: String { playerA.isEmpty ? "Игрок А" : playerA }
    private var nameB: String { playerB.isEmpty ? "Игрок Б" : playerB }

    var body: some View {
        ZStack {
            CourtBackground(theme: theme)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    ScreenHeader(title: "Новый матч", subtitle: nil, theme: theme) {
                        router.path.removeLast()
                    }

                    GlassCard(theme: theme) {
                        VStack(spacing: 12) {
                            sectionLabel("Игроки")
                            NameField(placeholder: "Игрок А", text: $playerA, theme: theme)
                                .accessibilityLabel("Имя первого игрока")
                            NameField(placeholder: "Игрок Б", text: $playerB, theme: theme)
                                .accessibilityLabel("Имя второго игрока")
                        }
                    }

                    GlassCard(theme: theme) {
                        VStack(spacing: 14) {
                            sectionLabel("Формат")
                            CapsuleSegmentedPicker(
                                options: MatchConfig.Format.allCases,
                                title: { $0 == .bestOfThree ? "До 2 сетов" : "До 3 сетов" },
                                selection: $format,
                                theme: theme
                            )
                            ThemedToggleRow(
                                title: "Решающее очко (no-ad)",
                                subtitle: "При «ровно» разыгрывается одно очко",
                                isOn: $noAd,
                                theme: theme
                            )
                            ThemedToggleRow(
                                title: "Супер тай-брейк",
                                subtitle: "До 10 очков вместо решающего сета",
                                isOn: $superTiebreak,
                                theme: theme
                            )
                        }
                    }

                    GlassCard(theme: theme) {
                        VStack(spacing: 12) {
                            sectionLabel("Тема корта")
                            ThemePicker(selection: $theme)
                        }
                    }

                    GlassCard(theme: theme) {
                        VStack(spacing: 12) {
                            sectionLabel("Подача")
                            if let server {
                                HStack(spacing: 10) {
                                    TennisBall(size: 20)
                                    Text("Подаёт: \(server == .a ? nameA : nameB)")
                                        .font(.system(.body, design: .rounded).weight(.semibold))
                                        .foregroundStyle(theme.textPrimary)
                                    Spacer()
                                    Button("Изменить") { showCoinFlip = true }
                                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                        .foregroundStyle(theme.accent)
                                        .brightness(0.2)
                                }
                            } else {
                                Button {
                                    showCoinFlip = true
                                } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: "circle.grid.cross")
                                            .font(.system(.body, design: .rounded).weight(.semibold))
                                        Text("Жеребьёвка монеткой")
                                            .font(.system(.body, design: .rounded).weight(.semibold))
                                    }
                                    .foregroundStyle(theme.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(Capsule().fill(theme.cardFill))
                                    .overlay(Capsule().strokeBorder(theme.cardStroke, lineWidth: 1))
                                }
                                .buttonStyle(SpringPressStyle())
                            }
                        }
                    }

                    PrimaryCapsuleButton(
                        title: "Начать матч",
                        systemImage: "play.fill",
                        theme: theme
                    ) {
                        startMatch()
                    }
                    .accessibilityHint(server == nil ? "Подающий будет выбран жеребьёвкой" : "")
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)

            if showCoinFlip {
                coinFlipOverlay
            }
        }
        .onAppear { theme = settings.theme }
    }

    private var coinFlipOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {}
            GlassCard(theme: theme, padding: 28) {
                VStack(spacing: 20) {
                    CoinFlipView(nameA: nameA, nameB: nameB, theme: theme) { result in
                        server = result
                    }
                    Button("Готово") {
                        withAnimation(.spring(duration: 0.35)) { showCoinFlip = false }
                    }
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(server == nil ? theme.textSecondary : theme.accent)
                    .brightness(0.2)
                    .disabled(server == nil)
                }
            }
            .padding(.horizontal, 36)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.black.opacity(0.4))
                    .padding(.horizontal, 30)
            )
            .transition(.scale(scale: 0.85).combined(with: .opacity))
        }
        .transition(.opacity)
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

    private func startMatch() {
        let config = MatchConfig(
            format: format,
            noAd: noAd,
            superTiebreakInsteadOfFinalSet: superTiebreak
        )
        let initialServer = server ?? (Bool.random() ? Player.a : Player.b)
        let viewModel = MatchViewModel(
            playerA: nameA,
            playerB: nameB,
            theme: theme,
            config: config,
            initialServer: initialServer
        )
        settings.theme = theme
        router.startMatch(viewModel)
    }
}

/// Выбор темы: четыре мини-карточки корта.
struct ThemePicker: View {
    @Binding var selection: CourtTheme

    var body: some View {
        HStack(spacing: 10) {
            ForEach(CourtTheme.allCases) { court in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selection = court
                    }
                    Haptics.selection()
                } label: {
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: court.backgroundColors(dark: false),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 52)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(
                                        selection == court ? court.accent : Color.white.opacity(0.2),
                                        lineWidth: selection == court ? 2.5 : 1
                                    )
                                    .brightness(selection == court ? 0.3 : 0)
                            )
                            .overlay {
                                if selection == court {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(.white)
                                        .shadow(color: .black.opacity(0.4), radius: 3)
                                }
                            }
                        Text(court.title)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.white.opacity(selection == court ? 1 : 0.6))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                .buttonStyle(SpringPressStyle())
                .accessibilityLabel("Тема \(court.title)")
                .accessibilityAddTraits(selection == court ? .isSelected : [])
            }
        }
    }
}
