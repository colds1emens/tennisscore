import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Это iPad? (на iPhone — false). Для адаптивного укрупнения интерфейса.
var isPadDevice: Bool {
    #if canImport(UIKit)
    return UIDevice.current.userInterfaceIdiom == .pad
    #else
    return false
    #endif
}

extension CGFloat {
    /// Значение с укрупнением на iPad: `68.pad(120)` → 68 на iPhone, 120 на iPad.
    func pad(_ padValue: CGFloat) -> CGFloat { isPadDevice ? padValue : self }
}

extension Double {
    func pad(_ padValue: Double) -> Double { isPadDevice ? padValue : self }
}
