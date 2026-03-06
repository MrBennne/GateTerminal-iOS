import Foundation

@Observable
@MainActor
final class LoginViewModel {
    var email: String = ""
    var password: String = ""
    var serverUrl: String = ""
    var isLoading: Bool = false
    var error: String?

    private let authService: AuthService
    private let shortcutPreferences: ShortcutPreferences

    init(authService: AuthService, shortcutPreferences: ShortcutPreferences) {
        self.authService = authService
        self.shortcutPreferences = shortcutPreferences
        self.serverUrl = UserDefaults.standard.string(forKey: "pb_server_url") ?? ""
    }

    func login() async -> Bool {
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty,
              !password.isEmpty else {
            error = "Email and password are required"
            return false
        }

        isLoading = true
        error = nil

        do {
            let url = serverUrl.trimmingCharacters(in: .whitespaces)
            try await authService.login(
                identity: email.trimmingCharacters(in: .whitespaces),
                password: password,
                serverUrl: url.isEmpty ? nil : url
            )
            // Load settings from PocketBase (non-fatal on failure)
            do {
                await shortcutPreferences.loadSettings()
            } catch {
                shortcutPreferences.loadLocal()
            }
            isLoading = false
            return true
        } catch {
            isLoading = false
            self.error = error.localizedDescription
            return false
        }
    }
}
