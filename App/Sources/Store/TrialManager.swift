import Foundation

/// Локальный пробный период: 24 часа с первого запуска.
/// Дата старта хранится в Keychain и переживает переустановку.
/// (App Store Connect не поддерживает 1-дневный встроенный триал —
/// минимальный нативный вариант 3 дня, поэтому отсчёт ведём сами.)
@Observable
@MainActor
final class TrialManager {
    static let trialDuration: TimeInterval = 24 * 60 * 60
    private static let startKey = "trial.start.v1"

    private(set) var trialStart: Date

    /// ephemeral=true — для demo-режимов: ничего не читает и не пишет в Keychain.
    init(ephemeral: Bool = false) {
        if ephemeral {
            trialStart = Date()
            return
        }
        if let data = KeychainStore.data(forKey: Self.startKey),
           let stored = try? JSONDecoder().decode(Date.self, from: data) {
            trialStart = stored
        } else {
            let now = Date()
            trialStart = now
            if let data = try? JSONEncoder().encode(now) {
                KeychainStore.set(data, forKey: Self.startKey)
            }
        }
    }

    var trialEnd: Date { trialStart.addingTimeInterval(Self.trialDuration) }

    var isTrialActive: Bool { Date() < trialEnd }

    var remaining: TimeInterval { max(0, trialEnd.timeIntervalSinceNow) }

    /// «23h 59m left» / «42m left».
    var remainingText: String {
        let total = Int(remaining)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m left"
        }
        return "\(minutes)m left"
    }
}
