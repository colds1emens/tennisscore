import SwiftUI
import SwiftData
import TennisEngine

/// История игр обоих режимов.
struct HistoryView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GameRecord.date, order: .reverse) private var records: [GameRecord]

    @State private var selected: GameRecord?

    private var theme: CourtTheme { settings.theme }

    var body: some View {
        ZStack {
            CourtBackground(theme: theme)

            VStack(spacing: 0) {
                ScreenHeader(title: "История", subtitle: subtitle, theme: theme) {
                    router.path.removeLast()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                if records.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(records) { record in
                                RecordCard(record: record, theme: theme) {
                                    selected = record
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        modelContext.delete(record)
                                    } label: {
                                        Label("Удалить", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 14)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .sheet(item: $selected) { record in
            RecordDetailSheet(record: record)
                .presentationDetents([.medium, .large])
                .presentationBackground(.clear)
        }
    }

    private var subtitle: String {
        records.isEmpty ? "Пока пусто" : "Игр: \(records.count)"
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            TennisBall(size: 56)
                .opacity(0.8)
            Text("Здесь появятся ваши игры")
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(theme.textPrimary)
            Text("Сыграйте матч или партию «105» —\nрезультат сохранится автоматически")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
            Spacer()
        }
    }
}

/// Карточка записи истории.
private struct RecordCard: View {
    let record: GameRecord
    let theme: CourtTheme
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                modeIcon

                VStack(alignment: .leading, spacing: 3) {
                    Text(record.title)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(theme.textPrimary)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        Text(record.mode.title)
                        Text("·")
                        Text(record.date, format: .dateTime.day().month().hour().minute())
                    }
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(theme.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text(record.resultSummary)
                        .font(.system(.subheadline, design: .rounded).weight(.bold).monospacedDigit())
                        .foregroundStyle(theme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    HStack(spacing: 3) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(CourtTheme.ballYellow)
                        Text(record.winnerName)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(theme.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(theme.cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(theme.cardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(SpringPressStyle())
        .accessibilityLabel("\(record.mode.title): \(record.title), счёт \(record.resultSummary)")
    }

    private var modeIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: record.theme.backgroundColors(dark: false),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 46, height: 46)
            if record.mode == .match {
                Image(systemName: "figure.tennis")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            } else {
                Text("105")
                    .font(.system(size: 14, weight: .heavy, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
            }
        }
    }
}

/// Детали записи (модальная карточка).
private struct RecordDetailSheet: View {
    let record: GameRecord
    @Environment(\.dismiss) private var dismiss

    private var theme: CourtTheme { record.theme }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: theme.backgroundColors(dark: true),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    Capsule()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 40, height: 5)
                        .padding(.top, 10)

                    Text(record.date, format: .dateTime.day().month(.wide).year().hour().minute())
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(theme.textSecondary)

                    if let matchDetail = record.matchDetail {
                        MatchResultCard(detail: matchDetail, theme: theme)
                    } else if let gameDetail = record.game105Detail {
                        Game105ResultCard(detail: gameDetail, theme: theme)
                    }

                    Button("Закрыть") { dismiss() }
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(theme.textPrimary)
                        .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
            }
        }
    }
}
