import Foundation

struct User: Codable, Equatable {
    var id: String = ""
    var username: String = ""
    var email: String = ""
    var role: String = ""

    func normalizedRole() -> String {
        let r = role.lowercased().trimmingCharacters(in: .whitespaces)
        if r.isEmpty { return "interchange" }
        return r
    }

    enum CodingKeys: String, CodingKey {
        case id, username, email, role
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(String.self, forKey: .id)) ?? ""
        username = (try? c.decode(String.self, forKey: .username)) ?? ""
        email = (try? c.decode(String.self, forKey: .email)) ?? ""
        role = (try? c.decode(String.self, forKey: .role)) ?? ""
    }

    init(id: String = "", username: String = "", email: String = "", role: String = "") {
        self.id = id
        self.username = username
        self.email = email
        self.role = role
    }
}

struct AuthResponse: Codable {
    let token: String
    let record: User
}
