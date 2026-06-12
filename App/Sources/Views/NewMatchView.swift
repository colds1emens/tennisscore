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

    private var nameA: String { playerA.isEmpty ? "Player A" : playerA }
    private var nameB: String { playerB.isEmpty ? "Player B" : playerB }

    var body: some View {
        ZStack {
            CourtBackground(theme: theme)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    ScreenHeader(title: "New match", subtitle: nil, theme: theme) {
                        router.path.removeLast()
                    }

                    GlassCard(theme: theme) {
                        VStack(spacing: 12) {
                            sectionLabel("Players")
                            NameField(placeholder: "Player A", text: $playerA, theme: theme)
                                .accessibilityLabel("First player name")
                            NameField(placeholder: "Player B", text: $playerB, theme: theme)
                                .accessibilityLabel("Second player name")
                        }
                    }

                    GlassCard(theme: theme) {
                        VStack(spacing: 14) {
                            sectionLabel("Format")
                            CapsuleSegmentedPicker(
                                options: MatchConfig.Format.allCases,
                                title: { $0 == .bestOfThree ? "Best of 3" : "Best of 5" },
                                selection: $format,
                                theme: theme
                            )
                            ThemedToggleRow(
                                title: "Deciding point (no-ad)",
                                subtitle: "A single point is played at deuce",
                                isOn: $noAd,
                                theme: theme
                            )
                            ThemedToggleRow(
                                title: "Super tiebreak",
                                subtitle: "First to 10 points instead of a final set",
                                isOn: $superTiebreak,
                                theme: theme
                            )
                        }
                    }

                    GlassCard(theme: theme) {
                        VStack(spacing: 12) {
                            sectionLabel("Court theme")
                            ThemePicker(selection: $theme)
                        }
                    }

                    GlassCard(theme: theme) {
                        VStack(spacing: 12) {
                            sectionLabel("Serve")
                            if let server {
                                HStack(spacing: 10) {
                                    TennisBall(size: 20)
                                    Text("Serving: \(server == .a ? nameA : nameB)")
                                        .font(.system(.body, design: .rounded).weight(.semibold))
                                        .foregroundStyle(theme.textPrimary)
                                    Spacer()
                                    Button("Change") { showCoinFlip = true }
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
                                        Text("Coin toss")
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
                        title: "Start match",
                        systemImage: "play.fill",
                        theme: theme
                    ) {
                        startMatch()
                    }
                    .accessibilityHint(server == nil ? "The server will be chosen by coin toss" : "")
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
                    Button("Done") {
                        withAnimation(.spring(duration: 0.35)) { showCoinFlip = false }
                    }
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(server == nil ? theme.textSecondary : theme.accent)
                    .brightness(0.2)
                    .disabled(server == nil)
                }
            }
            .padding(.horizontal, 36)
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
                .accessibilityLabel("\(court.title) theme")
                .accessibilityAddTraits(selection == court ? .isSelected : [])
            }
        }
    }
}
