import Foundation

@Observable
@MainActor
final class AuthService {
    private let pb: PocketBaseClient
    private let defaults = UserDefaults.standard

    private(set) var currentUser: User?
    private(set) var permissions: RolePermissions = .interchangeDefaults
    private(set) var isLoggedIn: Bool = false

    var isInterchange: Bool {
        (currentUser?.normalizedRole() ?? "interchange") == "interchange"
    }

    init(pb: PocketBaseClient) {
        self.pb = pb
        restoreSession()
    }

    func login(identity: String, password: String, serverUrl: String? = nil) async throws {
        if let url = serverUrl, !url.isEmpty {
            await pb.setBaseURL(url)
            defaults.set(url, forKey: "pb_server_url")
        }
        let response = try await pb.authWithPassword(identity: identity, password: password)
        await pb.setToken(response.token)
        currentUser = response.record
        isLoggedIn = true
        defaults.set(response.token, forKey: "pb_token")
        if let userData = try? JSONEncoder().encode(response.record) {
            defaults.set(userData, forKey: "pb_user")
        }
        loadPermissions()
    }

    func logout() {
        Task { await pb.setToken(nil) }
        currentUser = nil
        isLoggedIn = false
        permissions = .interchangeDefaults
        defaults.removeObject(forKey: "pb_token")
        defaults.removeObject(forKey: "pb_user")
    }

    private func restoreSession() {
        guard let token = defaults.string(forKey: "pb_token"),
              let userData = defaults.data(forKey: "pb_user"),
              let user = try? JSONDecoder().decode(User.self, from: userData) else {
            return
        }
        if let savedUrl = defaults.string(forKey: "pb_server_url"), !savedUrl.isEmpty {
            Task { await pb.setBaseURL(savedUrl) }
        }
        Task { await pb.setToken(token) }
        currentUser = user
        isLoggedIn = true
        loadPermissions()
    }

    private func loadPermissions() {
        guard let user = currentUser else { return }
        let role = user.normalizedRole()
        permissions = RolePermissions.forRole(role)
        Task {
            await loadRemotePermissions(userId: user.id, role: role)
        }
    }

    private func loadRemotePermissions(userId: String, role: String) async {
        do {
            let record = try await pb.getFirstListItem("role_permissions", filter: "role=\"\(role)\"")
            if let record = record {
                await MainActor.run {
                    self.permissions = RolePermissions.fromJson(record)
                }
            }
        } catch {
            // Non-fatal, use defaults
        }
    }
}
