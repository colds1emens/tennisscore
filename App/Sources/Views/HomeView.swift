import SwiftUI

/// Главный экран: выбор режима.
struct HomeView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AppSettings.self) private var settings
    @Environment(StoreManager.self) private var store
    @Environment(TrialManager.self) private var trial

    @State private var showPaywall = false

    private var theme: CourtTheme { settings.theme }

    var body: some View {
        ZStack {
            CourtBackground(theme: theme)

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 24)
                    .padding(.top, 12)

                if !store.isSubscribed {
                    trialBadge
                        .padding(.top, 12)
                }

                Spacer(minLength: 12)

                VStack(spacing: 18) {
                    ModeCard(
                        title: "Match",
                        subtitle: "Classic scoring: games,\nsets and tiebreaks",
                        symbol: "figure.tennis",
                        theme: theme
                    ) {
                        router.open(.newMatch)
                    }
                    .accessibilityHint("Start a classic match")

                    ModeCard(
                        title: "105",
                        subtitle: "Practice game\nplayed to a target score",
                        symbol: nil,
                        theme: theme
                    ) {
                        router.open(.new105)
                    }
                    .accessibilityHint("Start a one-oh-five practice game")
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 18)

                footer
                    .padding(.horizontal, 24)
                    .padding(.bottom, 10)
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(allowsDismiss: true)
        }
    }

    private var trialBadge: some View {
        Button {
            showPaywall = true
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "sparkles")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                Text("Pro trial · \(trial.remainingText)")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
            }
            .foregroundStyle(theme.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Capsule().fill(theme.accent.opacity(0.30)))
            .overlay(Capsule().strokeBorder(theme.accent.opacity(0.5), lineWidth: 1))
        }
        .buttonStyle(SpringPressStyle())
        .accessibilityLabel("Pro trial, \(trial.remainingText). Subscribe")
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("TENNIS")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(theme.textPrimary)
                    .tracking(4)
                Text("SCORE")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(theme.accent == .white ? theme.textPrimary : theme.accent)
                    .tracking(4)
                    .brightness(0.25)
            }
            Spacer()
            TennisBall(size: 44)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tennis Score")
    }

    private var footer: some View {
        HStack(spacing: 12) {
            FooterButton(symbol: "clock.arrow.circlepath", title: "History", theme: theme) {
                router.open(.history)
            }
            FooterButton(symbol: "gearshape", title: "Settings", theme: theme) {
                router.open(.settings)
            }
        }
    }
}

/// Большая карточка выбора режима.
private struct ModeCard: View {
    let title: String
    let subtitle: String
    let symbol: String?
    let theme: CourtTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundStyle(theme.textPrimary)
                        .monospacedDigit()
                    Text(subtitle)
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundStyle(theme.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(theme.accent.opacity(0.22))
                        .frame(width: 74, height: 74)
                    if let symbol {
                        Image(systemName: symbol)
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(theme.accent)
                            .brightness(0.2)
                    } else {
                        Text("105")
                            .font(.system(size: 24, weight: .heavy, design: .rounded).monospacedDigit())
                            .foregroundStyle(theme.accent)
                            .brightness(0.2)
                    }
                }
                Image(systemName: "chevron.right")
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundStyle(theme.textSecondary)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(theme.cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(theme.cardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(SpringPressStyle())
        .accessibilityLabel(title == "105" ? "Game one-oh-five" : title)
    }
}

private struct FooterButton: View {
    let symbol: String
    let title: String
    let theme: CourtTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                Text(title)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
            }
            .foregroundStyle(theme.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Capsule().fill(theme.cardFill))
            .overlay(Capsule().strokeBorder(theme.cardStroke, lineWidth: 1))
        }
        .buttonStyle(SpringPressStyle())
        .accessibilityLabel(title)
    }
}
