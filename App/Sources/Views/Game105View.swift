import SwiftUI
import SwiftData
import TennisEngine

/// Экран игры «105»: две половины с крупными кнопками начисления.
struct Game105View: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: Game105ViewModel

    private var theme: CourtTheme { viewModel.theme }
    private var engine: Game105Engine { viewModel.engine }

    var body: some View {
        ZStack {
            CourtBackground(theme: theme)

            GeometryReader { proxy in
                let isLandscape = proxy.size.width > proxy.size.height
                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    if isLandscape {
                        feedCapsule
                            .padding(.top, 4)
                        HStack(spacing: 12) {
                            SideZone(viewModel: viewModel, side: .a)
                            Rectangle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 1)
                                .padding(.vertical, 20)
                            SideZone(viewModel: viewModel, side: .b)
                        }
                        .padding(.horizontal, 16)
                    } else {
                        VStack(spacing: 6) {
                            SideZone(viewModel: viewModel, side: .a)
                            feedDivider
                            SideZone(viewModel: viewModel, side: .b)
                        }
                        .padding(.horizontal, 16)
                    }

                    ticker
                        .padding(.horizontal, 20)
                        .padding(.top, 6)
                        .padding(.bottom, 4)
                }
            }

            ConfettiOverlay(bursts: viewModel.confettiBursts)

            VStack {
                Spacer()
                if let toast = viewModel.toast {
                    ToastView(text: toast)
                        .padding(.bottom, 60)
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
            title: "Игра до \(engine.config.targetScore)",
            subtitle: engine.config.winByTwo ? "До разницы в 2 очка" : nil,
            theme: theme,
            onBack: { router.popToRoot() },
            trailing: AnyView(
                Button {
                    viewModel.undo()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(.footnote, design: .rounded).weight(.bold))
                        Text("Отменить")
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
                .accessibilityLabel("Отменить последнее начисление")
            )
        )
    }

    // MARK: - Индикатор наброса

    private var feedDivider: some View {
        HStack(spacing: 10) {
            line
            feedCapsule
            line
        }
        .frame(maxWidth: .infinity)
    }

    /// Капсула «кто набрасывает»: мяч мягко смещается к нужной половине.
    private var feedCapsule: some View {
        let feeding = engine.feedingSide
        return HStack(spacing: 7) {
            TennisBall(size: 14)
            Text(feedLabel)
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(theme.textSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(Capsule().fill(.black.opacity(0.25)))
        .offset(y: feedOffset(feeding))
        .animation(.spring(response: 0.55, dampingFraction: 0.7), value: feeding)
        .accessibilityLabel(feedLabel)
    }

    private var line: some View {
        Rectangle()
            .fill(Color.white.opacity(0.15))
            .frame(height: 1)
    }

    private func feedOffset(_ feeding: Side?) -> CGFloat {
        guard let feeding else { return 0 }
        return feeding == .a ? -7 : 7
    }

    private var feedLabel: String {
        guard let feeding = engine.feedingSide else {
            return "Набрасывает любой"
        }
        let name = viewModel.name(feeding)
        switch engine.config.feedRule {
        case .winnerFeeds: return "Набрасывает: \(name)"
        case .coachFeedsLoser: return "Тренер — для: \(name)"
        }
    }

    // MARK: - Лента событий

    private var ticker: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(viewModel.recentLines) { line in
                Text(line.text)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(theme.textSecondary.opacity(0.8))
                    .lineLimit(1)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .bottomLeading)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.recentLines.map(\.id))
        .accessibilityLabel("Последние события")
    }

    // MARK: - Undo-свайп и сохранение

    private var undoSwipe: some Gesture {
        DragGesture(minimumDistance: 40)
            .onEnded { value in
                if value.translation.height > 60 && abs(value.translation.width) < 80 {
                    viewModel.undo()
                }
            }
    }

    private func saveRecord() {
        guard let detail = viewModel.makeDetail() else { return }
        modelContext.insert(GameRecord.record(game105: detail, theme: theme))
        viewModel.savedToHistory = true
    }
}

/// Половина экрана одной стороны: счёт + кнопки начисления.
private struct SideZone: View {
    @Bindable var viewModel: Game105ViewModel
    let side: Side

    private var theme: CourtTheme { viewModel.theme }
    private var engine: Game105Engine { viewModel.engine }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Text(viewModel.name(side))
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(theme.textSecondary)
                    .lineLimit(1)
                if engine.isGamePoint(for: side) {
                    PulsingBadge(badge: .gamePoint)
                }
            }
            .frame(height: 30)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: engine.isGamePoint(for: side))

            scoreView

            buttonsGrid
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var scoreView: some View {
        Text("\(engine.score(of: side))")
            .font(.system(size: 76, weight: .heavy, design: .rounded).monospacedDigit())
            .foregroundStyle(theme.textPrimary)
            .contentTransition(.numericText(value: Double(engine.score(of: side))))
            .animation(.snappy(duration: 0.45), value: engine.score(of: side))
            .frame(height: 78)
            .overlay(alignment: .topTrailing) {
                if let flash = viewModel.lastAward, flash.side == side {
                    FlyingValue(value: flash.value, theme: theme)
                        .id(flash.id)
                        .offset(x: 44)
                }
            }
            .accessibilityLabel("Счёт \(viewModel.name(side)): \(engine.score(of: side))")
    }

    private var buttonsGrid: some View {
        let categories = engine.config.enabledCategories
        let columns = [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ]
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(categories) { category in
                AwardButton(category: category, theme: theme, sideName: viewModel.name(side)) {
                    viewModel.award(category.id, to: side)
                }
            }
        }
    }
}

/// Крупная кнопка-капсула начисления (минимум 64pt высотой).
private struct AwardButton: View {
    let category: PointCategory
    let theme: CourtTheme
    let sideName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: CategoryInfo.symbol(category.id))
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(theme.textSecondary)
                Text(CategoryInfo.title(category.id))
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: 2)
                Text("+\(category.value)")
                    .font(.system(.title3, design: .rounded).weight(.heavy).monospacedDigit())
                    .foregroundStyle(theme.accent)
                    .brightness(0.25)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 64)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(theme.cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(theme.cardStroke, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(SpringPressStyle())
        .accessibilityLabel("\(sideName): \(CategoryInfo.longTitle(category.id)), плюс \(category.value)")
    }
}

/// Вылетающая капсула «+5», улетающая в счёт.
private struct FlyingValue: View {
    let value: Int
    let theme: CourtTheme
    @State private var appeared = false

    var body: some View {
        Text("+\(value)")
            .font(.system(.headline, design: .rounded).weight(.heavy).monospacedDigit())
            .foregroundStyle(theme.onAccent)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(theme.accent))
            .opacity(appeared ? 0 : 1)
            .offset(y: appeared ? -34 : 14)
            .scaleEffect(appeared ? 0.8 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) { appeared = true }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
