import SwiftUI

/// Пружинящее нажатие: кнопка мягко сжимается под пальцем.
struct SpringPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Главная акцентная кнопка-капсула.
struct PrimaryCapsuleButton: View {
    let title: String
    var systemImage: String?
    let theme: CourtTheme
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                }
                Text(title)
                    .font(.system(.title3, design: .rounded).weight(.semibold))
            }
            .foregroundStyle(isEnabled ? theme.onAccent : theme.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Capsule().fill(isEnabled ? theme.accent : theme.cardFill)
            )
            .overlay(
                Capsule().strokeBorder(Color.white.opacity(isEnabled ? 0.25 : 0.1), lineWidth: 1)
            )
        }
        .buttonStyle(SpringPressStyle())
        .disabled(!isEnabled)
    }
}

/// Полупрозрачная «стеклянная» карточка поверх градиента.
struct GlassCard<Content: View>: View {
    let theme: CourtTheme
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(theme.cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(theme.cardStroke, lineWidth: 1)
            )
    }
}

/// Кастомный сегментированный переключатель-капсула.
struct CapsuleSegmentedPicker<T: Hashable>: View {
    let options: [T]
    let title: (T) -> String
    @Binding var selection: T
    let theme: CourtTheme
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.self) { option in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selection = option
                    }
                    Haptics.selection()
                } label: {
                    Text(title(option))
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(selection == option ? theme.onAccent : theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background {
                            if selection == option {
                                Capsule()
                                    .fill(theme.accent)
                                    .matchedGeometryEffect(id: "segment", in: namespace)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Capsule().fill(theme.cardFill))
        .overlay(Capsule().strokeBorder(theme.cardStroke, lineWidth: 1))
    }
}

/// Переключатель в стиле приложения.
struct ThemedToggleRow: View {
    let title: String
    var subtitle: String?
    @Binding var isOn: Bool
    let theme: CourtTheme

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.body, design: .rounded).weight(.medium))
                    .foregroundStyle(theme.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                }
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(theme.accent)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Кастомный шаговый регулятор «− значение +».
struct ValueStepper: View {
    @Binding var value: Int
    var range: ClosedRange<Int>
    var step: Int = 1
    let theme: CourtTheme

    var body: some View {
        HStack(spacing: 0) {
            stepButton("minus", enabled: value - step >= range.lowerBound) {
                value = max(range.lowerBound, value - step)
            }
            Text("\(value)")
                .font(.system(.body, design: .rounded).weight(.bold).monospacedDigit())
                .foregroundStyle(theme.textPrimary)
                .frame(minWidth: 44)
                .contentTransition(.numericText(value: Double(value)))
                .animation(.snappy, value: value)
            stepButton("plus", enabled: value + step <= range.upperBound) {
                value = min(range.upperBound, value + step)
            }
        }
        .background(Capsule().fill(theme.cardFill))
        .overlay(Capsule().strokeBorder(theme.cardStroke, lineWidth: 1))
    }

    private func stepButton(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            action()
            Haptics.selection()
        } label: {
            Image(systemName: symbol)
                .font(.system(.footnote, design: .rounded).weight(.bold))
                .foregroundStyle(enabled ? theme.textPrimary : theme.textSecondary.opacity(0.4))
                .frame(width: 40, height: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(SpringPressStyle())
        .disabled(!enabled)
    }
}

/// Поле ввода имени в стиле приложения.
struct NameField: View {
    let placeholder: String
    @Binding var text: String
    let theme: CourtTheme

    var body: some View {
        TextField(
            "",
            text: $text,
            prompt: Text(placeholder).foregroundStyle(theme.textSecondary.opacity(0.7))
        )
        .font(.system(.body, design: .rounded).weight(.medium))
        .foregroundStyle(theme.textPrimary)
        .tint(theme.accent)
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(theme.cardFill))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(theme.cardStroke, lineWidth: 1)
        )
        .autocorrectionDisabled()
    }
}

/// Кнопка «назад» и заголовок кастомной навигации.
struct ScreenHeader: View {
    let title: String
    var subtitle: String?
    let theme: CourtTheme
    var onBack: (() -> Void)?
    var trailing: AnyView?

    var body: some View {
        HStack(spacing: 12) {
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(.body, design: .rounded).weight(.bold))
                        .foregroundStyle(theme.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(theme.cardFill))
                        .overlay(Circle().strokeBorder(theme.cardStroke, lineWidth: 1))
                }
                .buttonStyle(SpringPressStyle())
                .accessibilityLabel("Back")
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(theme.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                }
            }
            Spacer()
            if let trailing {
                trailing
            }
        }
    }
}
