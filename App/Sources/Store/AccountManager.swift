import Foundation
import AuthenticationServices

/// Аккаунт пользователя: Sign in with Apple или e-mail.
/// Хранится в Keychain (переживает переустановку). Бэкенда у приложения нет,
/// поэтому e-mail сохраняется как локальная учётная запись без верификации.
@Observable
@MainActor
final class AccountManager {
    enum Account: Codable, Equatable {
        case apple(userID: String, name: String?, email: String?)
        case email(address: String)

        var displayName: String {
            switch self {
            case .apple(_, let name, let email):
                if let name, !name.isEmpty { return name }
                if let email, !email.isEmpty { return email }
                return "Apple ID"
            case .email(let address):
                return address
            }
        }

        var providerName: String {
            switch self {
            case .apple: return "Apple"
            case .email: return "Email"
            }
        }
    }

    private static let accountKey = "account.v1"

    private(set) var account: Account?

    var isSignedIn: Bool { account != nil }

    init() {
        if let data = KeychainStore.data(forKey: Self.accountKey),
           let stored = try? JSONDecoder().decode(Account.self, from: data) {
            account = stored
        }
    }

    private func persist() {
        if let account, let data = try? JSONEncoder().encode(account) {
            KeychainStore.set(data, forKey: Self.accountKey)
        } else {
            KeychainStore.remove(forKey: Self.accountKey)
        }
    }

    // MARK: - Вход

    /// Обработка результата Sign in with Apple. Возвращает true при успехе.
    @discardableResult
    func handleAppleAuthorization(_ result: Result<ASAuthorization, Error>) -> Bool {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                return false
            }
            let name = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            account = .apple(
                userID: credential.user,
                name: name.isEmpty ? nil : name,
                email: credential.email
            )
            persist()
            Haptics.success()
            return true
        case .failure:
            return false
        }
    }

    /// Локальный вход по e-mail. Возвращает true, если адрес выглядит корректно.
    @discardableResult
    func signIn(email rawEmail: String) -> Bool {
        let email = rawEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard Self.isValidEmail(email) else { return false }
        account = .email(address: email)
        persist()
        Haptics.success()
        return true
    }

    func signOut() {
        account = nil
        persist()
    }

    static func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }
}
