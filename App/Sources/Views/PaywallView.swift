import SwiftUI
import StoreKit

/// Пейволл: после окончания пробного дня доступ только по подписке.
struct PaywallView: View {
    /// true, когда пейволл показан шторкой (есть кнопка закрытия).
    var allowsDismiss = false

    @Environment(AppSettings.self) private var settings
    @Environment(StoreManager.self) private var store
    @Environment(TrialManager.self) private var trial
    @Environment(AccountManager.self) private var accountManager
    @Environment(\.dismiss) private var dismiss

    private var theme: CourtTheme { settings.theme }

    var body: some View {
        ZStack {
            CourtBackground(theme: theme)

            if allowsDismiss {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                .foregroundStyle(theme.textPrimary)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(theme.cardFill))
                        }
                        .buttonStyle(SpringPressStyle())
                        .accessibilityLabel("Close")
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    Spacer()
                }
                .zIndex(1)
            }

            VStack(spacing: 0) {
                Spacer(minLength: 24)

                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(theme.accent.opacity(0.22))
                            .frame(width: 92, height: 92)
                        TennisBall(size: 56)
                    }

                    VStack(spacing: 6) {
                        Text("Tennis Score Pro")
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundStyle(theme.textPrimary)
                        Text(trial.isTrialActive
                             ? "Free trial: \(trial.remainingText)"
                             : "Your free day is over")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(theme.textSecondary)
                    }
                }

                Spacer(minLength: 18)

                GlassCard(theme: theme, padding: 20) {
                    VStack(alignment: .leading, spacing: 14) {
                        featureRow(symbol: "figure.tennis", text: "Classic matches with full scoring")
                        featureRow(symbol: "bolt.fill", text: "“105” practice game for coaches")
                        featureRow(symbol: "paintpalette.fill", text: "All four court themes")
                        featureRow(symbol: "clock.arrow.circlepath", text: "Unlimited game history")
                        featureRow(symbol: "slider.horizontal.3", text: "Custom point values and presets")
                    }
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 18)

                VStack(spacing: 10) {
                    Button {
                        Task { await store.purchase() }
                    } label: {
                        VStack(spacing: 2) {
                            Text(store.isPurchasing ? "Processing…" : "Subscribe")
                                .font(.system(.title3, design: .rounded).weight(.bold))
                            Text("\(store.priceText) / month · cancel anytime")
                                .font(.system(.caption, design: .rounded).weight(.medium))
                                .opacity(0.85)
                        }
                        .foregroundStyle(theme.onAccent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Capsule().fill(theme.accent))
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
                    }
                    .buttonStyle(SpringPressStyle())
                    .disabled(store.isPurchasing)
                    .accessibilityLabel("Subscribe for \(store.priceText) per month")

                    HStack(spacing: 18) {
                        Button("Restore purchases") {
                            Task { await store.restore() }
                        }
                        if accountManager.isSignedIn {
                            Button("Sign out") {
                                accountManager.signOut()
                            }
                        }
                    }
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                    .foregroundStyle(theme.textSecondary)

                    if let error = store.lastError {
                        Text(error)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(Color(red: 1.0, green: 0.55, blue: 0.5))
                            .multilineTextAlignment(.center)
                    }

                    Text("Subscription renews monthly through your Apple ID.\nManage or cancel in App Store settings.")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(theme.textSecondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 26)
            }
        }
        .onChange(of: store.isSubscribed) { _, subscribed in
            if subscribed && allowsDismiss {
                dismiss()
            }
        }
    }

    private func featureRow(symbol: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(theme.accent)
                .brightness(0.25)
                .frame(width: 24)
            Text(text)
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(theme.textPrimary)
            Spacer(minLength: 0)
        }
    }
}
