import Foundation

struct FieldChange: Codable, Equatable {
    var field: String = ""
    var from: String = ""
    var to: String = ""
}

struct AuditLog: Codable, Identifiable, Equatable {
    var id: String = ""
    var actor: String = ""
    var role: String = ""
    var action: String = ""
    var resource: String = ""
    var changes: [FieldChange] = []
    var at: String = ""

    enum CodingKeys: String, CodingKey {
        case id, actor, role, action, resource, changes, at
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(String.self, forKey: .id)) ?? UUID().uuidString
        actor = (try? c.decode(String.self, forKey: .actor)) ?? ""
        role = (try? c.decode(String.self, forKey: .role)) ?? ""
        action = (try? c.decode(String.self, forKey: .action)) ?? ""
        resource = (try? c.decode(String.self, forKey: .resource)) ?? ""
        changes = (try? c.decode([FieldChange].self, forKey: .changes)) ?? []
        at = (try? c.decode(String.self, forKey: .at)) ?? ""
    }

    init(id: String = "", actor: String = "", role: String = "", action: String = "", resource: String = "", changes: [FieldChange] = [], at: String = "") {
        self.id = id
        self.actor = actor
        self.role = role
        self.action = action
        self.resource = resource
        self.changes = changes
        self.at = at
    }
}
