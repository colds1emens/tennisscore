import SwiftUI
import TennisEngine

/// Анимированная жеребьёвка подачи: монетка с 3D-вращением.
struct CoinFlipView: View {
    let nameA: String
    let nameB: String
    let theme: CourtTheme
    let onResult: (Player) -> Void

    @State private var rotation: Double = 0
    @State private var verticalOffset: CGFloat = 0
    @State private var result: Player?
    @State private var isFlipping = false

    /// Сторона монеты, видимая при данном угле (каждые 180°).
    private var visibleSide: Player {
        let halfTurns = Int((rotation + 90) / 180)
        return halfTurns.isMultiple(of: 2) ? .a : .b
    }

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                coinFace(player: visibleSide)
                    .rotation3DEffect(
                        .degrees(rotation),
                        axis: (x: 1, y: 0, z: 0),
                        perspective: 0.6
                    )
                    .offset(y: verticalOffset)
                    .shadow(color: .black.opacity(0.35), radius: 18, y: 14)
            }
            .frame(height: 170)

            if let result {
                VStack(spacing: 6) {
                    Text("Подаёт")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                    Text(result == .a ? nameA : nameB)
                        .font(.system(.title, design: .rounded).weight(.bold))
                        .foregroundStyle(theme.textPrimary)
                }
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            } else {
                Text(isFlipping ? "Монетка в воздухе…" : "Подбросьте монетку")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(theme.textSecondary)
            }

            Button(action: flip) {
                Text(result == nil ? "Подбросить" : "Ещё раз")
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(theme.textPrimary)
                    .padding(.horizontal, 26)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(theme.cardFill))
                    .overlay(Capsule().strokeBorder(theme.cardStroke, lineWidth: 1))
            }
            .buttonStyle(SpringPressStyle())
            .disabled(isFlipping)
            .accessibilityLabel("Подбросить монетку для жеребьёвки подачи")
        }
        .onAppear {
            if result == nil && !isFlipping {
                flip()
            }
        }
    }

    private func coinFace(player: Player) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            CourtTheme.ballYellow,
                            CourtTheme.ballYellowDeep
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Circle()
                .strokeBorder(Color.white.opacity(0.55), lineWidth: 4)
                .padding(6)
            Text(player == .a ? letter(nameA) : letter(nameB))
                .font(.system(size: 56, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(red: 0.18, green: 0.22, blue: 0.02))
        }
        .frame(width: 140, height: 140)
    }

    private func letter(_ name: String) -> String {
        String(name.trimmingCharacters(in: .whitespaces).prefix(1)).uppercased()
    }

    private func flip() {
        guard !isFlipping else { return }
        isFlipping = true
        withAnimation(.easeOut(duration: 0.3)) { result = nil }

        let target: Player = Bool.random() ? .a : .b
        // Кратное 360 + 0/180, чтобы монета легла нужной стороной.
        let fullSpins = Double(Int.random(in: 3...5)) * 360
        let finalAngle = rotation - rotation.truncatingRemainder(dividingBy: 360)
            + fullSpins + (target == .a ? 0 : 180)

        withAnimation(.easeOut(duration: 0.45)) { verticalOffset = -90 }
        withAnimation(.easeIn(duration: 0.5).delay(0.45)) { verticalOffset = 0 }
        withAnimation(.timingCurve(0.2, 0.65, 0.3, 1.0, duration: 1.6)) {
            rotation = finalAngle
        }

        Haptics.impact(0.6)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.65))
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                result = target
            }
            Haptics.success()
            isFlipping = false
            onResult(target)
        }
    }
}
