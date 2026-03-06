import Foundation

@Observable
@MainActor
final class ShortcutPreferences {
    private let pb: PocketBaseClient
    private let authService: AuthService
    private let defaults = UserDefaults.standard

    private(set) var shortcuts: RoleShortcuts = RoleShortcuts()

    init(pb: PocketBaseClient, authService: AuthService) {
        self.pb = pb
        self.authService = authService
        loadLocal()
    }

    func loadSettings() async {
        guard let user = authService.currentUser else { return }
        let role = user.normalizedRole()

        do {
            let record = try await pb.getFirstListItem("user_settings", filter: "user=\"\(user.id)\"")
            if let record = record,
               let shortcutsData = record["shortcuts"] as? [String: [String: String]] {
                shortcuts = RoleShortcuts.fromPocketBaseMap(shortcutsData, role: role)
                saveLocal()
            } else {
                shortcuts = RoleShortcuts.defaultsForRole(role)
            }
        } catch {
            shortcuts = RoleShortcuts.defaultsForRole(role)
        }
    }

    func loadLocal() {
        guard let data = defaults.data(forKey: "shortcuts_v1"),
              let decoded = try? JSONDecoder().decode(ShortcutsCodable.self, from: data) else {
            let role = authService.currentUser?.normalizedRole() ?? "interchange"
            shortcuts = RoleShortcuts.defaultsForRole(role)
            return
        }
        shortcuts = decoded.toRoleShortcuts()
    }

    func saveShortcuts(_ newShortcuts: RoleShortcuts) async {
        shortcuts = newShortcuts
        saveLocal()

        guard let user = authService.currentUser else { return }
        let pocketBaseMap = newShortcuts.toPocketBaseMap()

        do {
            let existing = try await pb.getFirstListItem("user_settings", filter: "user=\"\(user.id)\"")
            if let existing = existing, let existingId = existing["id"] as? String {
                let _: [String: Any] = try await pb.updateRecord("user_settings", id: existingId, body: ["shortcuts": pocketBaseMap])
            } else {
                let _: [String: Any] = try await pb.createRecord("user_settings", body: [
                    "user": user.id,
                    "shortcuts": pocketBaseMap
                ])
            }
        } catch {
            // Non-fatal
        }
    }

    func resetToDefaults() async {
        let role = authService.currentUser?.normalizedRole() ?? "interchange"
        let defaultShortcuts = RoleShortcuts.defaultsForRole(role)
        await saveShortcuts(defaultShortcuts)
    }

    private func saveLocal() {
        let codable = ShortcutsCodable.from(shortcuts)
        if let data = try? JSONEncoder().encode(codable) {
            defaults.set(data, forKey: "shortcuts_v1")
        }
    }
}

private struct ShortcutsCodable: Codable {
    var tap: GestureShortcut
    var longPress: GestureShortcut
    var swipeLeft: GestureShortcut
    var swipeRight: GestureShortcut

    func toRoleShortcuts() -> RoleShortcuts {
        RoleShortcuts(tap: tap, longPress: longPress, swipeLeft: swipeLeft, swipeRight: swipeRight)
    }

    static func from(_ shortcuts: RoleShortcuts) -> ShortcutsCodable {
        ShortcutsCodable(tap: shortcuts.tap, longPress: shortcuts.longPress, swipeLeft: shortcuts.swipeLeft, swipeRight: shortcuts.swipeRight)
    }
}
