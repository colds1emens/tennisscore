import SwiftUI
import TennisEngine

/// Экран победы: салют, итоговая карточка, «поделиться».
struct VictoryView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AppSettings.self) private var settings

    @State private var showNewGame = false
    @State private var editPlayersA: [RosterPlayer] = []
    @State private var editPlayersB: [RosterPlayer] = []

    private enum Source {
        case match(MatchViewModel, MatchDetail)
        case game105(Game105ViewModel, Game105Detail)
    }

    private var source: Source? {
        if let session = router.game105Session, let detail = session.makeDetail() {
            return .game105(session, detail)
        }
        if let session = router.matchSession, let detail = session.makeDetail() {
            return .match(session, detail)
        }
        return nil
    }

    private var theme: CourtTheme {
        switch source {
        case .match(let viewModel, _): return viewModel.theme
        case .game105(let viewModel, _): return viewModel.theme
        case nil: return settings.theme
        }
    }

    var body: some View {
        ZStack {
            CourtBackground(theme: theme)
            FireworksOverlay()

            VStack(spacing: 20) {
                Spacer(minLength: 8)

                resultCard

                Spacer(minLength: 8)

                actions
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }
            .readableWidth(560)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Карточка результата

    @ViewBuilder
    private var resultCard: some View {
        switch source {
        case .match(let viewModel, let detail):
            ShareableCard(theme: theme) {
                MatchResultCard(detail: detail, theme: viewModel.theme)
            }
        case .game105(let viewModel, let detail):
            Game105ResultCard(detail: detail, theme: viewModel.theme)
                .padding(.horizontal, 24)
        case nil:
            GlassCard(theme: theme) {
                Text("Game not found")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(theme.textSecondary)
            }
        }
    }

    @ViewBuilder
    private var actions: some View {
        switch source {
        case .match(let viewModel, _):
            matchActions(viewModel)
        case .game105(let viewModel, let detail):
            game105Actions(viewModel, detail)
        case nil:
            homeButton
        }
    }

    // MARK: - Матч

    private func matchActions(_ viewModel: MatchViewModel) -> some View {
        VStack(spacing: 10) {
            PrimaryCapsuleButton(title: "Play again", systemImage: "arrow.counterclockwise", theme: theme) {
                let fresh = MatchViewModel(
                    playerA: viewModel.playerA,
                    playerB: viewModel.playerB,
                    theme: viewModel.theme,
                    config: viewModel.engine.config,
                    initialServer: viewModel.engine.initialServer.opponent
                )
                router.matchSession = fresh
                router.path = [.match]
            }
            homeButton
        }
    }

    // MARK: - «105»

    private func game105Actions(_ viewModel: Game105ViewModel, _ detail: Game105Detail) -> some View {
        VStack(spacing: 10) {
            ShareLink(item: detail.shareText(date: Date())) {
                actionLabel("Share Result", symbol: "square.and.arrow.up", primary: true)
            }
            HStack(spacing: 10) {
                Button {
                    startNextGame(viewModel, playersA: viewModel.playersA, playersB: viewModel.playersB)
                } label: {
                    actionLabel("Start New Game", symbol: "play.fill")
                }
                .buttonStyle(SpringPressStyle())
                Button {
                    openEditTeams(viewModel)
                } label: {
                    actionLabel("Edit Teams", symbol: "person.2.fill")
                }
                .buttonStyle(SpringPressStyle())
            }
            homeButton
            Text("✓ Saved to History")
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(theme.textSecondary.opacity(0.8))
        }
        .sheet(isPresented: $showNewGame) {
            newGameSheet(viewModel)
        }
    }

    /// «Edit Teams» — открыть лист с составами для перестановки игроков.
    private func openEditTeams(_ viewModel: Game105ViewModel) {
        editPlayersA = viewModel.playersA.isEmpty ? .roster(count: 3) : .roster(names: viewModel.playersA)
        editPlayersB = viewModel.playersB.isEmpty ? .roster(count: 3) : .roster(names: viewModel.playersB)
        showNewGame = true
    }

    /// Старт следующей игры с заданными составами (теми же или отредактированными).
    private func startNextGame(_ viewModel: Game105ViewModel, playersA: [String], playersB: [String]) {
        let fresh = Game105ViewModel(
            sideA: "Team A",
            sideB: "Team B",
            playersA: playersA,
            playersB: playersB,
            theme: viewModel.theme,
            config: viewModel.engine.config
        )
        showNewGame = false
        router.game105Session = fresh
        router.path = [.game105]
    }

    private func newGameSheet(_ viewModel: Game105ViewModel) -> some View {
        ZStack {
            LinearGradient(colors: theme.backgroundColors(dark: true), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    Capsule().fill(Color.white.opacity(0.3)).frame(width: 40, height: 5).padding(.top, 10)
                    Text("Next game")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(theme.textPrimary)
                    Text("Keep the same teams or move players around, then start.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                        .multilineTextAlignment(.center)

                    RosterEditor(playersA: $editPlayersA, playersB: $editPlayersB, theme: theme, allowMoving: true)

                    PrimaryCapsuleButton(title: "Start game", systemImage: "play.fill", theme: theme) {
                        startNextGame(viewModel, playersA: editPlayersA.names, playersB: editPlayersB.names)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .readableWidth()
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var homeButton: some View {
        Button {
            router.popToRoot()
        } label: {
            actionLabel("Home", symbol: nil)
        }
        .buttonStyle(SpringPressStyle())
    }

    private func actionLabel(_ title: String, symbol: String?, primary: Bool = false) -> some View {
        HStack(spacing: 7) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
            }
            Text(title)
                .font(.system(.body, design: .rounded).weight(.semibold))
        }
        .foregroundStyle(primary ? theme.onAccent : theme.textPrimary)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(Capsule().fill(primary ? theme.accent : theme.cardFill))
        .overlay(Capsule().strokeBorder(primary ? Color.white.opacity(0.25) : theme.cardStroke, lineWidth: 1))
    }
}

/// Обёртка карточки с кнопкой «Поделиться» (рендерит карточку в картинку).
private struct ShareableCard<Content: View>: View {
    let theme: CourtTheme
    @ViewBuilder var content: Content

    #if canImport(UIKit)
    @State private var shareImage: UIImage?
    #endif

    var body: some View {
        VStack(spacing: 14) {
            content
                .padding(.horizontal, 24)

            sharedButton
        }
        #if canImport(UIKit)
        .task { shareImage = renderImage() }
        #endif
    }

    @ViewBuilder
    private var sharedButton: some View {
        #if canImport(UIKit)
        if let image = shareImage {
            ShareLink(
                item: Image(uiImage: image),
                preview: SharePreview("Winner 105 — result", image: Image(uiImage: image))
            ) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    Text("Share")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                }
                .foregroundStyle(theme.textPrimary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Capsule().fill(theme.cardFill))
                .overlay(Capsule().strokeBorder(theme.cardStroke, lineWidth: 1))
            }
            .accessibilityLabel("Share the result as an image")
        }
        #endif
    }

    #if canImport(UIKit)
    @MainActor
    private func renderImage() -> UIImage? {
        let exportView = ZStack {
            LinearGradient(
                colors: theme.backgroundColors(dark: false),
                startPoint: .top,
                endPoint: .bottom
            )
            content.padding(28)
        }
        .frame(width: 420)

        let renderer = ImageRenderer(content: exportView)
        renderer.scale = 3
        return renderer.uiImage
    }
    #endif
}

/// Итоговая карточка классического матча.
struct MatchResultCard: View {
    let detail: MatchDetail
    let theme: CourtTheme

    var body: some View {
        GlassCard(theme: theme, padding: 22) {
            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("WINNER")
                        .font(.system(.caption, design: .rounded).weight(.heavy))
                        .tracking(3)
                        .foregroundStyle(theme.textSecondary)
                    Text(detail.winnerName)
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(theme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }

                trophy

                Grid(horizontalSpacing: 16, verticalSpacing: 8) {
                    row(name: detail.playerA, player: .a)
                    Divider().overlay(Color.white.opacity(0.15))
                    row(name: detail.playerB, player: .b)
                }
            }
        }
    }

    private var trophy: some View {
        ZStack {
            Circle()
                .fill(theme.accent.opacity(0.22))
                .frame(width: 64, height: 64)
            Image(systemName: "trophy.fill")
                .font(.system(size: 28))
                .foregroundStyle(CourtTheme.ballYellow)
        }
    }

    private func row(name: String, player: Player) -> some View {
        GridRow {
            HStack(spacing: 6) {
                Text(name)
                    .font(.system(.body, design: .rounded).weight(detail.winner == player ? .bold : .regular))
                    .foregroundStyle(detail.winner == player ? theme.textPrimary : theme.textSecondary)
                    .lineLimit(1)
                if detail.winner == player {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(CourtTheme.ballYellow)
                }
                Spacer(minLength: 0)
            }
            .gridColumnAlignment(.leading)

            ForEach(Array(detail.sets.enumerated()), id: \.offset) { _, set in
                setCell(set, player: player)
            }
        }
    }

    private func setCell(_ set: CompletedSet, player: Player) -> some View {
        let games = set.isSuperTiebreak ? (set.tiebreakPoints(of: player) ?? 0) : set.games(of: player)
        let won = set.winner == player
        let tiebreakIndex: Int? = {
            guard !set.isSuperTiebreak, set.winner != player else { return nil }
            return set.tiebreakPoints(of: player)
        }()
        return HStack(alignment: .top, spacing: 1) {
            Text("\(games)")
                .font(.system(.title3, design: .rounded).weight(won ? .heavy : .regular).monospacedDigit())
                .foregroundStyle(won ? theme.textPrimary : theme.textSecondary)
            if let tiebreakIndex {
                Text("\(tiebreakIndex)")
                    .font(.system(.caption2, design: .rounded).monospacedDigit())
                    .foregroundStyle(theme.textSecondary)
            }
        }
    }
}

/// Итоговая карточка «105» с разбивкой очков по типам.
struct Game105ResultCard: View {
    let detail: Game105Detail
    let theme: CourtTheme

    var body: some View {
        GlassCard(theme: theme, padding: 22) {
            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("WINNER")
                        .font(.system(.caption, design: .rounded).weight(.heavy))
                        .tracking(3)
                        .foregroundStyle(theme.textSecondary)
                    Text(detail.winnerName)
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(theme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }

                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("\(detail.scoreA)")
                        .font(.system(size: 56, weight: .heavy, design: .rounded).monospacedDigit())
                        .foregroundStyle(detail.winner == .a ? theme.textPrimary : theme.textSecondary)
                    Text(":")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                    Text("\(detail.scoreB)")
                        .font(.system(size: 56, weight: .heavy, design: .rounded).monospacedDigit())
                        .foregroundStyle(detail.winner == .b ? theme.textPrimary : theme.textSecondary)
                }

                HStack(alignment: .top, spacing: 28) {
                    breakdownColumn(name: detail.sideA, roster: detail.rosterA, lines: detail.breakdownA, isWinner: detail.winner == .a)
                    breakdownColumn(name: detail.sideB, roster: detail.rosterB, lines: detail.breakdownB, isWinner: detail.winner == .b)
                }
                // Разделитель фоном: не растягивает карточку по вертикали.
                .background(
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 1)
                )
            }
        }
    }

    private func breakdownColumn(name: String, roster: TeamRoster, lines: [Game105Detail.BreakdownLine], isWinner: Bool) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 4) {
                Text(name)
                    .font(.system(.footnote, design: .rounded).weight(.bold))
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(1)
                if isWinner {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(CourtTheme.ballYellow)
                }
            }
            if !roster.players.isEmpty {
                Text(roster.playersLine)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if lines.isEmpty {
                Text("No points")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(theme.textSecondary)
            }
            ForEach(lines) { line in
                HStack(spacing: 4) {
                    Text("\(detail.config.category(id: line.categoryID)?.displayTitle ?? CategoryInfo.title(line.categoryID)) ×\(line.count)")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                    Spacer(minLength: 4)
                    Text("\(line.total)")
                        .font(.system(.caption, design: .rounded).weight(.bold).monospacedDigit())
                        .foregroundStyle(theme.textPrimary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
