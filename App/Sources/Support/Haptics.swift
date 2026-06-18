import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Тактильная отдача. Сила удара пропорциональна стоимости очка.
enum Haptics {
    /// Лёгкий «удар» при начислении очка; intensity 0...1.
    static func impact(_ intensity: Double) {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: intensity > 0.7 ? .heavy : .medium)
        generator.impactOccurred(intensity: max(0.3, min(1.0, intensity)))
        #endif
    }

    /// Сила удара по стоимости очка относительно максимальной.
    static func impact(value: Int, maxValue: Int) {
        let ratio = maxValue > 0 ? Double(value) / Double(maxValue) : 0.5
        impact(0.35 + 0.65 * ratio)
    }

    static func success() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    static func warning() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        #endif
    }

    static func selection() {
        #if canImport(UIKit)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }
}

/// Не гасить экран, пока идёт игра.
struct KeepScreenAwake: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                #if canImport(UIKit)
                UIApplication.shared.isIdleTimerDisabled = true
                #endif
            }
            .onDisappear {
                #if canImport(UIKit)
                UIApplication.shared.isIdleTimerDisabled = false
                #endif
            }
    }
}

extension View {
    func keepScreenAwake() -> some View { modifier(KeepScreenAwake()) }
}

extension Bundle {
    /// Маркетинговая версия приложения для экрана «О приложении».
    var appVersionString: String {
        (infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0"
    }
}
