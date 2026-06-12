import SwiftUI

/// Детерминированный псевдослучайный генератор для частиц (без состояния).
private func particleRand(_ seed: Int, _ index: Int, _ salt: Int) -> Double {
    var x = UInt64(bitPattern: Int64(seed &+ index &* 374_761_393 &+ salt &* 668_265_263))
    x = (x ^ (x >> 33)) &* 0xff51_afd7_ed55_8ccd
    x = (x ^ (x >> 33)) &* 0xc4ce_b9fe_1a85_ec53
    x ^= x >> 33
    return Double(x % 100_000) / 100_000
}

private let festiveColors: [Color] = [
    CourtTheme.ballYellow,
    Color(red: 0.99, green: 0.45, blue: 0.42),
    Color(red: 0.45, green: 0.78, blue: 1.0),
    Color(red: 0.65, green: 0.55, blue: 0.98),
    Color(red: 0.45, green: 0.90, blue: 0.60),
    .white
]

/// Конфетти: лёгкий залп сверху (на выигрыш сета).
struct ConfettiOverlay: View {
    /// Каждое увеличение значения запускает новый залп.
    var bursts: Int

    @State private var burstDates: [Date] = []

    private let lifetime: Double = 3.0
    private let particlesPerBurst = 70

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: burstDates.isEmpty)) { context in
            Canvas { ctx, size in
                let now = context.date
                for burst in burstDates {
                    let t = now.timeIntervalSince(burst)
                    guard t >= 0, t < lifetime else { continue }
                    drawBurst(ctx: &ctx, size: size, t: t, seed: Int(burst.timeIntervalSinceReferenceDate * 1000))
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: bursts) { _, newValue in
            guard newValue > 0 else { return }
            burstDates.append(Date())
            burstDates.removeAll { Date().timeIntervalSince($0) > lifetime + 0.5 }
        }
    }

    private func drawBurst(ctx: inout GraphicsContext, size: CGSize, t: Double, seed: Int) {
        for i in 0..<particlesPerBurst {
            let delay = particleRand(seed, i, 1) * 0.25
            let life = t - delay
            guard life > 0 else { continue }
            let progress = life / (lifetime - 0.25)
            guard progress < 1 else { continue }

            let x0 = particleRand(seed, i, 2) * size.width
            let vy = 220 + particleRand(seed, i, 3) * 160
            let sway = (particleRand(seed, i, 4) - 0.5) * 70
            let phase = particleRand(seed, i, 5) * .pi * 2
            let x = x0 + sin(life * 3.1 + phase) * 18 + sway * life
            let y = -20 + vy * life + 110 * life * life

            guard y < size.height + 20 else { continue }

            let color = festiveColors[i % festiveColors.count]
            let w = 5 + particleRand(seed, i, 6) * 5
            let h = w * (0.5 + particleRand(seed, i, 7) * 0.6)
            let angle = Angle.radians(life * (2 + particleRand(seed, i, 8) * 4) + phase)
            let opacity = progress > 0.75 ? (1 - progress) / 0.25 : 1.0

            var particle = ctx
            particle.opacity = opacity
            particle.translateBy(x: x, y: y)
            particle.rotate(by: angle)
            particle.fill(
                Path(roundedRect: CGRect(x: -w / 2, y: -h / 2, width: w, height: h), cornerRadius: 1.5),
                with: .color(color)
            )
        }
    }
}

/// Салют: непрерывные залпы (экран победы).
struct FireworksOverlay: View {
    var isActive = true

    private let rocketInterval: Double = 0.85
    private let sparkCount = 26
    private let explosionLife: Double = 1.5

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !isActive)) { context in
            Canvas { ctx, size in
                let now = context.date.timeIntervalSinceReferenceDate
                // Три «очереди» ракет с разным смещением.
                for lane in 0..<3 {
                    let laneOffset = Double(lane) * rocketInterval / 1.5
                    let cycle = (now + laneOffset) / rocketInterval
                    let index = Int(cycle)
                    let t = (cycle - Double(index)) * rocketInterval
                    drawFirework(ctx: &ctx, size: size, t: t, seed: index &* 31 &+ lane)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func drawFirework(ctx: inout GraphicsContext, size: CGSize, t: Double, seed: Int) {
        let cx = size.width * (0.18 + particleRand(seed, 0, 1) * 0.64)
        let cy = size.height * (0.16 + particleRand(seed, 0, 2) * 0.30)
        let launchTime = 0.45
        let baseColor = festiveColors[abs(seed) % festiveColors.count]

        if t < launchTime {
            // Подъём ракеты
            let progress = t / launchTime
            let y = size.height - (size.height - cy) * progress
            let x = cx + sin(progress * 6) * 4
            var rocket = ctx
            rocket.opacity = 0.9
            rocket.fill(
                Path(ellipseIn: CGRect(x: x - 2, y: y - 2, width: 4, height: 8)),
                with: .color(.white)
            )
            // Хвост
            var tail = ctx
            tail.opacity = 0.35
            tail.fill(
                Path(ellipseIn: CGRect(x: x - 1.2, y: y + 8, width: 2.4, height: 16)),
                with: .color(CourtTheme.ballYellow)
            )
        } else {
            // Взрыв
            let life = t - launchTime
            let progress = life / explosionLife
            guard progress < 1 else { return }
            let radius = 90 * (1 - pow(1 - min(progress * 1.25, 1), 2.2))
            let opacity = progress > 0.55 ? (1 - progress) / 0.45 : 1.0

            for i in 0..<sparkCount {
                let angle = Double(i) / Double(sparkCount) * .pi * 2 + particleRand(seed, i, 3) * 0.2
                let r = radius * (0.85 + particleRand(seed, i, 4) * 0.3)
                let x = cx + cos(angle) * r
                let y = cy + sin(angle) * r + 36 * progress * progress
                let sparkSize = 3.4 * (1 - progress * 0.6)

                var spark = ctx
                spark.opacity = opacity
                spark.addFilter(.blur(radius: 0.4))
                spark.fill(
                    Path(ellipseIn: CGRect(x: x - sparkSize / 2, y: y - sparkSize / 2, width: sparkSize, height: sparkSize)),
                    with: .color(i % 4 == 0 ? .white : baseColor)
                )
            }
            // Вспышка в центре
            if progress < 0.22 {
                var flash = ctx
                flash.opacity = (0.22 - progress) / 0.22 * 0.8
                let flashSize = 26.0
                flash.fill(
                    Path(ellipseIn: CGRect(x: cx - flashSize / 2, y: cy - flashSize / 2, width: flashSize, height: flashSize)),
                    with: .color(.white)
                )
            }
        }
    }
}
