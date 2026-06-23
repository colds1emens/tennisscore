import SwiftUI
import SwiftData
import TennisEngine

/// Экран классического матча: тап по половине — очко, swipe вниз — undo.
struct MatchView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: MatchViewModel

    @State private var dragOffset: CGFloat = 0

    private var theme: CourtTheme { viewModel.theme }
    private var engine: MatchEngine { viewModel.engine }

    var body: some View {
        ZStack {
            CourtBackground(theme: theme)

            GeometryReader { proxy in
                let isLandscape = proxy.size.width > proxy.size.height
                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    SetsGrid(viewModel: viewModel)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)

                    statusLine
                        .padding(.top, 12)

                    if isLandscape {
                        HStack(spacing: 0) {
                            playerZone(.a)
                            zoneDivider(vertical: true)
                            playerZone(.b)
                        }
                    } else {
                        VStack(spacing: 0) {
                            playerZone(.a)
                            zoneDivider(vertical: false)
                            playerZone(.b)
                        }
                    }

                    hint
                        .padding(.bottom, 10)
                }
                .readableWidth(isPadDevice ? 1000 : 820)
            }

            ConfettiOverlay(bursts: viewModel.confettiBursts)

            VStack {
                if viewModel.showChangeEnds {
                    ChangeEndsBanner(theme: theme)
                        .padding(.top, 64)
                }
                Spacer()
                if let toast = viewModel.toast {
                    ToastView(text: toast)
                        .padding(.bottom, 84)
                }
            }
        }
        .keepScreenAwake()
        .gesture(undoSwipe)
        .onChange(of: viewModel.engine.isFinished) { _, finished in
            guard finished, !viewModel.savedToHistory else { return }
            saveRecord()
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.4))
                router.open(.victory)
            }
        }
    }

    // MARK: - Шапка

    private var header: some View {
        ScreenHeader(
            title: setTitle,
            subtitle: formatLine,
            theme: theme,
            onBack: { router.popToRoot() },
            trailing: AnyView(
                Button {
                    viewModel.undo()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(.footnote, design: .rounded).weight(.bold))
                        Text("Undo")
                            .font(.system(.footnote, design: .rounded).weight(.semibold))
                    }
                    .foregroundStyle(engine.canUndo ? theme.textPrimary : theme.textSecondary.opacity(0.4))
                    .padding(.horizontal, 14)
                    .frame(height: 40)
                    .background(Capsule().fill(theme.cardFill))
                    .overlay(Capsule().strokeBorder(theme.cardStroke, lineWidth: 1))
                }
                .buttonStyle(SpringPressStyle())
                .disabled(!engine.canUndo)
                .accessibilityLabel("Undo last point")
            )
        )
    }

    private var setTitle: String {
        if engine.isFinished { return "Match finished" }
        if engine.isSuperTiebreak { return "Super tiebreak" }
        let number = engine.completedSets.count + 1
        return engine.isTiebreak ? "Set \(number) · Tiebreak" : "Set \(number)"
    }

    private var formatLine: String {
        var parts = [engine.config.format == .bestOfThree ? "Best of 3" : "Best of 5"]
        if engine.config.noAd { parts.append("no-ad") }
        if engine.config.superTiebreakInsteadOfFinalSet { parts.append("super TB") }
        return parts.joined(separator: " · ")
    }

    // MARK: - Статус между зонами

    private var statusLine: some View {
        Group {
            if engine.isDeuce {
                Text(engine.config.noAd ? "Deuce · deciding point" : "Deuce")
            } else if let advantage = engine.advantage {
                Text("Advantage \(viewModel.name(advantage))")
            } else if engine.isTiebreak {
                Text("First to \(engine.isSuperTiebreak ? engine.config.superTiebreakTarget : engine.config.tiebreakTarget) points")
            } else {
                Text(" ")
            }
        }
        .font(.system(.subheadline, design: .rounded).weight(.semibold))
        .foregroundStyle(theme.textSecondary)
        .frame(height: 20)
        .animation(.easeInOut(duration: 0.25), value: engine.isDeuce)
    }

    // MARK: - Игровые зоны

    private func playerZone(_ player: Player) -> some View {
        Button {
            viewModel.point(player)
        } label: {
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    if engine.server == player && !engine.isFinished {
                        ServeIndicator(size: 16)
                            .transition(.scale.combined(with: .opacity))
                    }
                    Text(viewModel.name(player))
                        .font(.system(size: 17.pad(26), weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                        .lineLimit(1)
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: engine.server)

                Text(engine.gameScoreText(for: player))
                    .font(.system(size: 96.pad(180), weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(theme.textPrimary)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.3), value: engine.gameScoreText(for: player))
                    .minimumScaleFactor(0.5)
                    .frame(height: 100.pad(180))

                ZStack {
                    if let badge = MomentBadge.badge(for: engine, player: player) {
                        PulsingBadge(badge: badge)
                    }
                }
                .frame(height: 30)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: MomentBadge.badge(for: engine, player: player))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(engine.isFinished)
        .accessibilityLabel("Point for \(viewModel.name(player))")
        .accessibilityHint("Game score \(engine.gameScoreText(for: player))")
    }

    private func zoneDivider(vertical: Bool) -> some View {
        Group {
            if vertical {
                Rectangle().frame(width: 1)
            } else {
                Rectangle().frame(height: 1)
            }
        }
        .foregroundStyle(Color.white.opacity(0.18))
        .padding(vertical ? .vertical : .horizontal, 36)
    }

    private var hint: some View {
        Text("Tap a half to score · swipe down to undo")
            .font(.system(.caption2, design: .rounded))
            .foregroundStyle(theme.textSecondary.opacity(0.7))
    }

    // MARK: - Undo-свайп

    private var undoSwipe: some Gesture {
        DragGesture(minimumDistance: 40)
            .onEnded { value in
                if value.translation.height > 60 && abs(value.translation.width) < 80 {
                    viewModel.undo()
                }
            }
    }

    // MARK: - Сохранение

    private func saveRecord() {
        guard let detail = viewModel.makeDetail() else { return }
        modelContext.insert(GameRecord.record(match: detail, theme: theme))
        viewModel.savedToHistory = true
    }
}

/// Сетка сетов: имена + геймы по сетам + текущий сет.
struct SetsGrid: View {
    let viewModel: MatchViewModel

    private var engine: MatchEngine { viewModel.engine }
    private var theme: CourtTheme { viewModel.theme }

    var body: some View {
        GlassCard(theme: theme, padding: 12) {
            Grid(horizontalSpacing: 14, verticalSpacing: 8) {
                gridRow(for: .a)
                Divider().overlay(Color.white.opacity(0.15))
                gridRow(for: .b)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(setsAccessibility)
    }

    private func gridRow(for player: Player) -> some View {
        GridRow {
            HStack(spacing: 6) {
                Text(viewModel.name(player))
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(1)
                if engine.server == player && !engine.isFinished {
                    TennisBall(size: 10)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(Array(engine.completedSets.enumerated()), id: \.offset) { _, set in
                completedCell(set, player: player)
            }

            if !engine.isFinished {
                Text("\(engine.isSuperTiebreak ? engine.rawPoints(of: player) : engine.games(of: player))")
                    .font(.system(.title3, design: .rounded).weight(.bold).monospacedDigit())
                    .foregroundStyle(theme.accent)
                    .brightness(0.25)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.3), value: engine.games(of: player))
                    .frame(minWidth: 26)
            }
        }
    }

    private func completedCell(_ set: CompletedSet, player: Player) -> some View {
        let games = set.isSuperTiebreak ? (set.tiebreakPoints(of: player) ?? 0) : set.games(of: player)
        let won = set.winner == player
        // У проигравшего тай-брейк — его очки тай-брейка верхним индексом (как в табло ATP).
        let tiebreakIndex: Int? = {
            guard !set.isSuperTiebreak, set.winner != player else { return nil }
            return set.tiebreakPoints(of: player)
        }()
        return HStack(alignment: .top, spacing: 1) {
            Text("\(games)")
                .font(.system(.title3, design: .rounded).weight(won ? .bold : .regular).monospacedDigit())
                .foregroundStyle(won ? theme.textPrimary : theme.textSecondary)
            if let tiebreakIndex {
                Text("\(tiebreakIndex)")
                    .font(.system(.caption2, design: .rounded).monospacedDigit())
                    .foregroundStyle(theme.textSecondary)
            }
        }
        .frame(minWidth: 26)
    }

    private var setsAccessibility: String {
        let sets = engine.completedSets.map { "\($0.gamesA):\($0.gamesB)" }.joined(separator: ", ")
        return "Sets: \(sets). Current: \(engine.gamesA):\(engine.gamesB)"
    }
}
