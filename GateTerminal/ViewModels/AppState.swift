import Foundation

@Observable
@MainActor
final class AppState {
    let pb: PocketBaseClient
    let authService: AuthService
    let unitRepository: UnitRepository
    let shortcutPreferences: ShortcutPreferences

    var appearanceSettings: AppearanceSettings {
        didSet { saveAppearance() }
    }

    init() {
        let savedUrl = UserDefaults.standard.string(forKey: "pb_server_url") ?? "https://your-pb-server.com"
        let pb = PocketBaseClient(baseURL: savedUrl)
        self.pb = pb
        self.authService = AuthService(pb: pb)
        self.unitRepository = UnitRepository(pb: pb, authService: authService)
        self.shortcutPreferences = ShortcutPreferences(pb: pb, authService: authService)

        if let data = UserDefaults.standard.data(forKey: "appearance_v1"),
           let settings = try? JSONDecoder().decode(AppearanceSettings.self, from: data) {
            self.appearanceSettings = settings
        } else {
            self.appearanceSettings = AppearanceSettings()
        }
    }

    private func saveAppearance() {
        if let data = try? JSONEncoder().encode(appearanceSettings) {
            UserDefaults.standard.set(data, forKey: "appearance_v1")
        }
    }
}
