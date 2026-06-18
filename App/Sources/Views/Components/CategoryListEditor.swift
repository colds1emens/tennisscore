import SwiftUI
import TennisEngine

/// Редактор списка категорий очков «105»: включение/выключение любой категории,
/// значение (можно отрицательное), добавление и удаление пользовательских.
/// Общий компонент для Настроек и экрана новой игры.
struct CategoryListEditor: View {
    @Binding var categories: [PointCategory]
    let theme: CourtTheme

    @State private var adding = false
    @State private var newName = ""
    @State private var newValue = 5
    @FocusState private var nameFocused: Bool

    var body: some View {
        VStack(spacing: 10) {
            ForEach($categories) { $category in
                row($category)
            }
            Divider().overlay(Color.white.opacity(0.12))
            if adding { addForm } else { addButton }
        }
    }

    // MARK: - Строка категории

    private func row(_ category: Binding<PointCategory>) -> some View {
        let c = category.wrappedValue
        return HStack(spacing: 10) {
            Button {
                category.wrappedValue.isEnabled.toggle()
                Haptics.selection()
            } label: {
                Image(systemName: c.isEnabled ? "checkmark.circle.fill" : "circle")
                    .font(.system(.title3, design: .rounded))
                    .foregroundStyle(c.isEnabled ? theme.accent : theme.textSecondary.opacity(0.45))
                    .brightness(c.isEnabled ? 0.2 : 0)
            }
            .buttonStyle(SpringPressStyle())
            .accessibilityLabel("\(c.displayLongTitle), \(c.isEnabled ? "enabled" : "disabled")")

            Image(systemName: c.displaySymbol)
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .foregroundStyle(c.isEnabled ? theme.accent.opacity(0.9) : theme.textSecondary.opacity(0.4))
                .brightness(0.15)
                .frame(width: 18)

            Text(c.displayLongTitle)
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(c.isEnabled ? theme.textPrimary : theme.textSecondary.opacity(0.5))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer(minLength: 4)

            ValueStepper(value: category.value, range: -90...100, theme: theme)
                .opacity(c.isEnabled ? 1 : 0.4)
                .disabled(!c.isEnabled)

            if c.isCustom {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        categories.removeAll { $0.id == c.id }
                    }
                    Haptics.warning()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(SpringPressStyle())
                .accessibilityLabel("Delete \(c.displayLongTitle)")
            }
        }
    }

    // MARK: - Добавление кастомной категории

    private var addButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { adding = true }
            nameFocused = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                Text("Add custom category")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
            }
            .foregroundStyle(theme.accent)
            .brightness(0.2)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(SpringPressStyle())
    }

    private var addForm: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                TextField(
                    "",
                    text: $newName,
                    prompt: Text("Category name").foregroundStyle(theme.textSecondary.opacity(0.7))
                )
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(theme.textPrimary)
                .tint(theme.accent)
                .focused($nameFocused)
                .padding(.horizontal, 12)
                .frame(height: 40)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(theme.cardFill))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(theme.cardStroke, lineWidth: 1))

                ValueStepper(value: $newValue, range: -90...100, theme: theme)
            }
            HStack(spacing: 10) {
                Text("Tip: a negative value subtracts points")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(theme.textSecondary.opacity(0.7))
                Spacer()
                Button("Cancel") {
                    withAnimation(.spring(response: 0.3)) { adding = false }
                    newName = ""; newValue = 5
                }
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(theme.textSecondary)

                Button {
                    let title = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !title.isEmpty else { return }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        categories.append(.custom(title: title, value: newValue, symbol: CategoryInfo.customDefaultSymbol))
                        adding = false
                    }
                    newName = ""; newValue = 5
                    Haptics.success()
                } label: {
                    Text("Add")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(theme.onAccent)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(theme.accent))
                }
                .buttonStyle(SpringPressStyle())
                .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
            }
        }
        .transition(.opacity)
    }
}
