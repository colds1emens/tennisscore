import SwiftUI

/// Теннисный мяч: радиальный градиент + фирменный изгиб шва.
struct TennisBall: View {
    var size: CGFloat = 22

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.93, green: 0.98, blue: 0.45),
                            CourtTheme.ballYellow,
                            CourtTheme.ballYellowDeep
                        ],
                        center: .init(x: 0.35, y: 0.3),
                        startRadius: 1,
                        endRadius: size * 0.9
                    )
                )
            BallSeam()
                .stroke(Color.white.opacity(0.9), lineWidth: max(1.2, size * 0.07))
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.25), radius: size * 0.12, y: size * 0.08)
        .accessibilityHidden(true)
    }
}

/// Два дуговых шва мяча.
private struct BallSeam: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * 0.78, y: h * 0.02))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.78, y: h * 0.98),
            control: CGPoint(x: w * 0.30, y: h * 0.50)
        )
        path.move(to: CGPoint(x: w * 0.22, y: h * 0.02))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.22, y: h * 0.98),
            control: CGPoint(x: w * 0.70, y: h * 0.50)
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
