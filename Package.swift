// swift-tools-version:5.9
// Вспомогательный манифест для быстрой проверки компиляции UI-кода
// без запуска симулятора: `make typecheck`.
// Само приложение собирается XcodeGen-проектом (project.yml).
import PackageDescription

let package = Package(
    name: "TennisScoreCheck",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "TennisScoreUI", targets: ["TennisScoreUI"])
    ],
    dependencies: [
        .package(path: "TennisEngine")
    ],
    targets: [
        .target(
            name: "TennisScoreUI",
            dependencies: [.product(name: "TennisEngine", package: "TennisEngine")],
            path: "App/Sources"
        )
    ]
)
