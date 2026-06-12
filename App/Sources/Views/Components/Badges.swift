import SwiftUI
import TennisEngine

/// Важность момента для бейджа.
enum MomentBadge: String {
    case breakPoint = "BREAK POINT"
    case setPoint = "SET POINT"
    case matchPoint = "MATCH POINT"
    case gamePoint = "GAME POINT"
    case decidingPoint = "РЕШАЮЩЕЕ ОЧКО"

    var color: Color {
        switch self {
        case .matchPoint: return Color(red: 0.95, green: 0.26, blue: 0.21)
        case .setPoint: return Color(red: 0.98, green: 0.55, blue: 0.10)
        case .breakPoint: return Color(red: 0.61, green: 0.15, blue: 0.69)
        case .gamePoint: return Color(red: 0.15, green: 0.68, blue: 0.38)
        case .decidingPoint: return Color(red: 0.95, green: 0.26, blue: 0.21)
        }
    }

    var accessibilityText: String {
        switch self {
        case .breakPoint: return "Брейк-пойнт"
        case .setPoint: return "Сет-пойнт"
        case .matchPoint: return "Матч-пойнт"
        case .gamePoint: return "Гейм-пойнт"
        case .decidingPoint: return "Решающее очко"
        }
    }

    /// Самый важный бейдж для игрока в классическом матче.
    static func badge(for engine: MatchEngine, player: Player) -> MomentBadge? {
        guard !engine.isFinished else { return nil }
        if engine.isMatchPoint(for: player) { return .matchPoint }
        if engine.isSetPoint(for: player) { return .setPoint }
        if engine.isBreakPoint(for: player) { return .breakPoint }
        if engine.config.noAd && engine.isDeuce { return .decidingPoint }
        if engine.isGamePoint(for: player) { return .gamePoint }
        return nil
    }
}

/// Пульсирующий бейдж момента.
struct PulsingBadge: View {
    let badge: MomentBadge
    @State private var pulsing = false

    var body: some View {
        Text(badge.rawValue)
            .font(.system(.caption, design: .rounded).weight(.heavy))
            .tracking(1.2)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Capsule().fill(badge.color))
            .shadow(color: badge.color.opacity(pulsing ? 0.7 : 0.25), radius: pulsing ? 10 : 4)
            .scaleEffect(pulsing ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true), value: pulsing)
            .onAppear { pulsing = true }
            .accessibilityLabel(badge.accessibilityText)
            .transition(.scale(scale: 0.6).combined(with: .opacity))
    }
}

/// Деликатная подсказка «Смена сторон».
struct ChangeEndsBanner: View {
    let theme: CourtTheme

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(.footnote, design: .rounded).weight(.bold))
            Text("Смена сторон")
                .font(.system(.footnote, design: .rounded).weight(.semibold))
        }
        .foregroundStyle(theme.textPrimary)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Capsule().fill(.black.opacity(0.35)))
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.2), lineWidth: 1))
        .transition(.move(edge: .top).combined(with: .opacity))
        .accessibilityLabel("Смена сторон")
    }
}

/// Тост внизу экрана.
struct ToastView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(.footnote, design: .rounded).weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Capsule().fill(.black.opacity(0.55)))
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
