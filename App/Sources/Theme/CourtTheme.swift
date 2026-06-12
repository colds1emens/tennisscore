import SwiftUI

/// Тема корта: задаёт фоновый градиент, акценты и подписи.
enum CourtTheme: String, CaseIterable, Identifiable, Codable {
    case wimbledon
    case rolandGarros
    case usOpen
    case melbourne

    var id: String { rawValue }

    var title: String {
        switch self {
        case .wimbledon: return "Уимблдон"
        case .rolandGarros: return "Ролан Гаррос"
        case .usOpen: return "US Open"
        case .melbourne: return "Мельбурн"
        }
    }

    var subtitle: String {
        switch self {
        case .wimbledon: return "Трава"
        case .rolandGarros: return "Грунт"
        case .usOpen: return "Хард"
        case .melbourne: return "Хард"
        }
    }

    // MARK: - Палитра

    /// Градиент фона экрана.
    func backgroundColors(dark: Bool) -> [Color] {
        switch self {
        case .wimbledon:
            return dark
                ? [Color(red: 0.04, green: 0.13, blue: 0.07), Color(red: 0.02, green: 0.07, blue: 0.04)]
                : [Color(red: 0.13, green: 0.38, blue: 0.20), Color(red: 0.07, green: 0.26, blue: 0.13)]
        case .rolandGarros:
            return dark
                ? [Color(red: 0.22, green: 0.09, blue: 0.05), Color(red: 0.13, green: 0.05, blue: 0.03)]
                : [Color(red: 0.80, green: 0.39, blue: 0.22), Color(red: 0.62, green: 0.27, blue: 0.14)]
        case .usOpen:
            return dark
                ? [Color(red: 0.04, green: 0.08, blue: 0.20), Color(red: 0.02, green: 0.04, blue: 0.12)]
                : [Color(red: 0.10, green: 0.24, blue: 0.55), Color(red: 0.05, green: 0.14, blue: 0.38)]
        case .melbourne:
            return dark
                ? [Color(red: 0.02, green: 0.12, blue: 0.18), Color(red: 0.01, green: 0.06, blue: 0.10)]
                : [Color(red: 0.05, green: 0.46, blue: 0.70), Color(red: 0.02, green: 0.30, blue: 0.50)]
        }
    }

    /// Главный акцент (кнопки, активные элементы).
    var accent: Color {
        switch self {
        case .wimbledon: return Color(red: 0.58, green: 0.31, blue: 0.73)
        case .rolandGarros: return Color(red: 0.13, green: 0.42, blue: 0.31)
        case .usOpen: return Color(red: 1.00, green: 0.84, blue: 0.20)
        case .melbourne: return Color(red: 1.00, green: 0.45, blue: 0.34)
        }
    }

    /// Цвет текста/иконок поверх акцента.
    var onAccent: Color {
        switch self {
        case .usOpen: return Color(red: 0.10, green: 0.10, blue: 0.02)
        default: return .white
        }
    }

    /// Полупрозрачный «материал» карточек поверх градиента.
    var cardFill: Color { Color.white.opacity(0.10) }
    var cardStroke: Color { Color.white.opacity(0.16) }

    /// Основной и второстепенный цвет текста поверх фона.
    var textPrimary: Color { .white }
    var textSecondary: Color { Color.white.opacity(0.65) }

    /// Цвет теннисного мяча — общий для всех тем.
    static var ballYellow: Color { Color(red: 0.85, green: 0.93, blue: 0.27) }
    static var ballYellowDeep: Color { Color(red: 0.65, green: 0.76, blue: 0.10) }
}

/// Фон-градиент темы на весь экран.
struct CourtBackground: View {
    let theme: CourtTheme
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        LinearGradient(
            colors: theme.backgroundColors(dark: colorScheme == .dark),
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(alignment: .top) {
            // Лёгкая «подсветка прожектора» сверху — глубина без тяжёлых блюров.
            RadialGradient(
                colors: [Color.white.opacity(0.10), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 420
            )
        }
        .ignoresSafeArea()
    }
}
