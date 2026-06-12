import SwiftUI
import TennisEngine

/// Экран победы: салют, итоговая карточка, «поделиться».
struct VictoryView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AppSettings.self) private var settings

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
            ShareableCard(theme: theme) {
                Game105ResultCard(detail: detail, theme: viewModel.theme)
            }
        case nil:
            GlassCard(theme: theme) {
                Text("Игра не найдена")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(theme.textSecondary)
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 10) {
            PrimaryCapsuleButton(title: "Сыграть ещё раз", systemImage: "arrow.counterclockwise", theme: theme) {
                playAgain()
            }
            Button {
                router.popToRoot()
            } label: {
                Text("На главную")
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(theme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Capsule().fill(theme.cardFill))
                    .overlay(Capsule().strokeBorder(theme.cardStroke, lineWidth: 1))
            }
            .buttonStyle(SpringPressStyle())
        }
    }

    private func playAgain() {
        switch source {
        case .match(let viewModel, _):
            let fresh = MatchViewModel(
                playerA: viewModel.playerA,
                playerB: viewModel.playerB,
                theme: viewModel.theme,
                config: viewModel.engine.config,
                initialServer: viewModel.engine.initialServer.opponent
            )
            router.matchSession = fresh
            router.path = [.match]
        case .game105(let viewModel, _):
            let fresh = Game105ViewModel(
                sideA: viewModel.sideA,
                sideB: viewModel.sideB,
                theme: viewModel.theme,
                config: viewModel.engine.config
            )
            router.game105Session = fresh
            router.path = [.game105]
        case nil:
            router.popToRoot()
        }
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
                preview: SharePreview("Tennis Score — результат", image: Image(uiImage: image))
            ) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    Text("Поделиться")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                }
                .foregroundStyle(theme.textPrimary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Capsule().fill(theme.cardFill))
                .overlay(Capsule().strokeBorder(theme.cardStroke, lineWidth: 1))
            }
            .accessibilityLabel("Поделиться картинкой результата")
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
                    Text("ПОБЕДА")
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
                    Text("ПОБЕДА")
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

                HStack(alignment: .top, spacing: 14) {
                    breakdownColumn(name: detail.sideA, lines: detail.breakdownA, isWinner: detail.winner == .a)
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 1)
                    breakdownColumn(name: detail.sideB, lines: detail.breakdownB, isWinner: detail.winner == .b)
                }
            }
        }
    }

    private func breakdownColumn(name: String, lines: [Game105Detail.BreakdownLine], isWinner: Bool) -> some View {
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
            if lines.isEmpty {
                Text("Без очков")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(theme.textSecondary)
            }
            ForEach(lines) { line in
                HStack(spacing: 4) {
                    Text("\(CategoryInfo.title(line.categoryID)) ×\(line.count)")
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
