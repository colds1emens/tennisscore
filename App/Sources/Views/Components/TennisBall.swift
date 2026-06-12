import SwiftUI

/// Теннисный мяч с объёмом: сферическое освещение, корректные швы «)(»,
/// затенение кромки и блик.
struct TennisBall: View {
    var size: CGFloat = 22

    var body: some View {
        ZStack {
            // Основа: свет сверху-слева, к кромке темнее
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.96, green: 1.00, blue: 0.58),
                            Color(red: 0.86, green: 0.94, blue: 0.32),
                            Color(red: 0.64, green: 0.74, blue: 0.13),
                            Color(red: 0.44, green: 0.52, blue: 0.07)
                        ],
                        center: UnitPoint(x: 0.33, y: 0.28),
                        startRadius: size * 0.02,
                        endRadius: size * 1.02
                    )
                )

            // Швы: две дуги окружностей с центрами за пределами мяча
            BallSeams()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.95),
                            Color(red: 0.97, green: 0.95, blue: 0.88).opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: max(1.0, size * 0.07), lineCap: .round)
                )
                .shadow(color: .black.opacity(0.25), radius: size * 0.015, y: size * 0.02)
                .clipShape(Circle())

            // Затенение нижне-правой кромки — сферический объём
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.clear, .clear, Color.black.opacity(0.30)],
                        center: UnitPoint(x: 0.36, y: 0.30),
                        startRadius: size * 0.30,
                        endRadius: size * 0.78
                    )
                )

            // Мягкий блик
            Ellipse()
                .fill(Color.white.opacity(0.50))
                .frame(width: size * 0.36, height: size * 0.20)
                .rotationEffect(.degrees(-28))
                .offset(x: -size * 0.17, y: -size * 0.25)
                .blur(radius: size * 0.07)
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.25), radius: size * 0.10, y: size * 0.07)
        .accessibilityHidden(true)
    }
}

/// Классический вид швов спереди: левая и правая дуги «)(», не пересекаются.
/// Каждая — дуга окружности, центр которой лежит далеко за мячом.
private struct BallSeams: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = rect.width / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let seamRadius = radius * 1.55
        let offset = radius * 1.78

        // Левая дуга — выгибается вправо, к центру мяча
        path.addArc(
            center: CGPoint(x: center.x - offset, y: center.y),
            radius: seamRadius,
            startAngle: .degrees(-46),
            endAngle: .degrees(46),
            clockwise: false
        )

        // Правая дуга — зеркальная; начинаем новый подпуть, чтобы не было перемычки
        let start = CGPoint(
            x: center.x + offset + seamRadius * cos(.pi * 134 / 180),
            y: center.y + seamRadius * sin(.pi * 134 / 180)
        )
        path.move(to: start)
        path.addArc(
            center: CGPoint(x: center.x + offset, y: center.y),
            radius: seamRadius,
            startAngle: .degrees(134),
            endAngle: .degrees(226),
            clockwise: false
        )
        return path
    }
}

/// Индикатор подачи: мяч с лёгким покачиванием.
struct ServeIndicator: View {
    var size: CGFloat = 18
    @State private var bounce = false

    var body: some View {
        TennisBall(size: size)
            .offset(y: bounce ? -1.5 : 1.5)
            .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: bounce)
            .onAppear { bounce = true }
            .accessibilityLabel("Подаёт")
    }
}
