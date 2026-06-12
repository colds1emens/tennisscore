import SwiftUI
import AuthenticationServices

/// Экран входа: Sign in with Apple или e-mail.
struct AuthView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(AccountManager.self) private var accountManager

    @State private var email = ""
    @State private var showEmailField = false
    @State private var emailError = false
    @FocusState private var emailFocused: Bool

    private var theme: CourtTheme { settings.theme }

    var body: some View {
        ZStack {
            CourtBackground(theme: theme)

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 14) {
                    TennisBall(size: 72)
                    VStack(spacing: 2) {
                        Text("TENNIS SCORE")
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundStyle(theme.textPrimary)
                            .tracking(3)
                        Text("Match and practice scoring")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(theme.textSecondary)
                    }
                }

                Spacer()

                VStack(spacing: 12) {
                    SignInWithAppleButton(.continue) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        accountManager.handleAppleAuthorization(result)
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 52)
                    .clipShape(Capsule())
                    .accessibilityLabel("Continue with Apple")

                    if showEmailField {
                        emailForm
                    } else {
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showEmailField = true
                            }
                            emailFocused = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "envelope.fill")
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                Text("Continue with Email")
                                    .font(.system(.body, design: .rounded).weight(.semibold))
                            }
                            .foregroundStyle(theme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Capsule().fill(theme.cardFill))
                            .overlay(Capsule().strokeBorder(theme.cardStroke, lineWidth: 1))
                        }
                        .buttonStyle(SpringPressStyle())
                    }

                    Text("Your games are stored on this device.\nA subscription is linked to your Apple ID.")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(theme.textSecondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.top, 6)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 30)
            }
        }
    }

    private var emailForm: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "envelope.fill")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(theme.textSecondary)
                TextField(
                    "",
                    text: $email,
                    prompt: Text("you@example.com").foregroundStyle(theme.textSecondary.opacity(0.7))
                )
                .font(.system(.body, design: .rounded))
                .foregroundStyle(theme.textPrimary)
                .tint(theme.accent)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($emailFocused)
                .submitLabel(.go)
                .onSubmit { submitEmail() }
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(Capsule().fill(theme.cardFill))
            .overlay(
                Capsule().strokeBorder(
                    emailError ? Color(red: 0.95, green: 0.3, blue: 0.25) : theme.cardStroke,
                    lineWidth: emailError ? 1.5 : 1
                )
            )

            if emailError {
                Text("Please enter a valid email address")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Color(red: 1.0, green: 0.55, blue: 0.5))
                    .transition(.opacity)
            }

            Button {
                submitEmail()
            } label: {
                Text("Continue")
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(theme.onAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Capsule().fill(theme.accent))
            }
            .buttonStyle(SpringPressStyle())
            .accessibilityLabel("Continue with this email")
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func submitEmail() {
        if accountManager.signIn(email: email) {
            emailError = false
        } else {
            withAnimation(.spring(duration: 0.3)) { emailError = true }
            Haptics.warning()
        }
    }
}
