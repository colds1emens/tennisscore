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
                        HStack(spacing: 12) {
                            SideZone(viewModel: viewModel, side: viewModel.topSide)
                            swapDivider(vertical: true)
                            SideZone(viewModel: viewModel, side: viewModel.bottomSide)
                        }
                        .padding(.horizontal, 16)
                    } else {
                        VStack(spacing: 6) {
                            SideZone(viewModel: viewModel, side: viewModel.topSide)
                            swapDivider(vertical: false)
                            SideZone(viewModel: viewModel, side: viewModel.bottomSide)
                        }
                        .padding(.horizontal, 16)
                    }

                    ticker
                        .padding(.horizontal, 20)
                        .padding(.top, 6)
                        .padding(.bottom, 10)
                }
                .readableWidth(isPadDevice ? 1120 : 760)
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
            if finished {
                finishTask?.cancel()
                finishTask = Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1.4))
                    // Игру могли отменить (undo) за время задержки — перепроверяем.
                    guard !Task.isCancelled, viewModel.engine.isFinished else { return }
                    saveRecord()
                    router.open(.victory)
                }
            } else {
                // Undo вернул игру в незавершённое состояние: отменяем переход
                // и разрешаем повторное сохранение при следующей победе.
                finishTask?.cancel()
                viewModel.savedToHistory = false
            }
        }
        .onDisappear { finishTask?.cancel() }
    }

    @State private var finishTask: Task<Void, Never>?

    // MARK: - Шапка

    private var header: some View {
        ScreenHeader(
            title: "First to \(engine.config.targetScore)",
            subtitle: nil,
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
                .accessibilityLabel("Undo last award")
            )
        )
    }

    // MARK: - Разделитель со «сменой сторон»

    private func swapDivider(vertical: Bool) -> some View {
        let button = Button {
            viewModel.swapSides()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.arrow.down")
                Text("Swap sides")
            }
            .font(.system(.caption, design: .rounded).weight(.semibold))
            .foregroundStyle(theme.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Capsule().fill(.black.opacity(0.3)))
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.14), lineWidth: 1))
        }
        .buttonStyle(SpringPressStyle())
        .accessibilityLabel("Swap the two sides")

        return Group {
            if vertical {
                ZStack {
                    Rectangle().fill(Color.white.opacity(0.15)).frame(width: 1)
                    button
                }
                .frame(maxHeight: .infinity)
                .padding(.vertical, 20)
            } else {
                HStack(spacing: 10) {
                    Rectangle().fill(Color.white.opacity(0.15)).frame(height: 1)
                    button
                    Rectangle().fill(Color.white.opacity(0.15)).frame(height: 1)
                }
            }
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
        .accessibilityLabel("Recent events")
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
            VStack(spacing: 2) {
                HStack(spacing: 8) {
                    Text(viewModel.name(side))
                        .font(.system(size: 17.pad(26), weight: .bold, design: .rounded))
                        .foregroundStyle(theme.textPrimary)
                        .lineLimit(1)
                    if engine.isGamePoint(for: side) {
                        PulsingBadge(badge: .gamePoint)
                    }
                }
                if !viewModel.players(side).isEmpty {
                    Text(viewModel.roster(side).playersLine)
                        .font(.system(size: 11.pad(16), design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .frame(minHeight: 30.pad(44))
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: engine.isGamePoint(for: side))

            scoreView

            buttonsGrid
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var scoreView: some View {
        Text("\(engine.score(of: side))")
            .font(.system(size: 68.pad(132), weight: .heavy, design: .rounded).monospacedDigit())
            .foregroundStyle(theme.textPrimary)
            .contentTransition(.numericText(value: Double(engine.score(of: side))))
            .animation(.snappy(duration: 0.45), value: engine.score(of: side))
            .frame(height: 70.pad(140))
            .overlay(alignment: .topTrailing) {
                if let flash = viewModel.lastAward, flash.side == side {
                    FlyingValue(value: flash.value, theme: theme)
                        .id(flash.id)
                        .offset(x: 44)
                }
            }
            .accessibilityLabel("\(viewModel.name(side)) score: \(engine.score(of: side))")
    }

    private var buttonsGrid: some View {
        let categories = engine.config.enabledCategories
        // До 4 типов — 2 колонки (крупнее), 5+ — 3 колонки; всё в зоне большого пальца.
        let columnCount = categories.count > 4 ? 3 : 2
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: 12.pad(18)),
            count: columnCount
        )
        return LazyVGrid(columns: columns, spacing: 12.pad(18)) {
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
            VStack(spacing: 3.pad(6)) {
                HStack(spacing: 5.pad(8)) {
                    Image(systemName: category.displaySymbol)
                        .font(.system(size: 14.pad(20), design: .rounded).weight(.semibold))
                        .foregroundStyle(theme.textSecondary)
                    Text(category.displayTitle)
                        .font(.system(size: 17.pad(24), design: .rounded).weight(.semibold))
                        .foregroundStyle(theme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }
                Text(category.signedValueText)
                    .font(.system(size: 22.pad(36), design: .rounded).weight(.heavy).monospacedDigit())
                    .foregroundStyle(category.value < 0 ? Color(red: 1.0, green: 0.55, blue: 0.5) : theme.accent)
                    .brightness(category.value < 0 ? 0 : 0.25)
            }
            .padding(.horizontal, 8.pad(14))
            .frame(maxWidth: .infinity)
            .frame(minHeight: 78.pad(120))
            .background(
                RoundedRectangle(cornerRadius: 22.pad(28), style: .continuous)
                    .fill(theme.cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22.pad(28), style: .continuous)
                    .strokeBorder(theme.cardStroke, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 22.pad(28), style: .continuous))
        }
        .buttonStyle(SpringPressStyle())
        .accessibilityLabel("\(sideName): \(category.displayLongTitle), \(category.value < 0 ? "minus \(abs(category.value))" : "plus \(category.value)") points")
    }
}

/// Вылетающая капсула «+5», улетающая в счёт.
private struct FlyingValue: View {
    let value: Int
    let theme: CourtTheme
    @State private var appeared = false

    var body: some View {
        Text(value < 0 ? "−\(abs(value))" : "+\(value)")
            .font(.system(.headline, design: .rounded).weight(.heavy).monospacedDigit())
            .foregroundStyle(value < 0 ? .white : theme.onAccent)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(value < 0 ? Color(red: 0.85, green: 0.3, blue: 0.27) : theme.accent))
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
