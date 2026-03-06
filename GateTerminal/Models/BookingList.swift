import Foundation

struct BookingList: Codable, Identifiable, Equatable {
    var id: String = ""
    var name: String = ""
    var typeOrder: String = ""
    var created: String = ""
    var updated: String = ""

    var typeOrderList: [String] {
        typeOrder.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    enum CodingKeys: String, CodingKey {
        case id, name
        case typeOrder = "type_order"
        case created, updated
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(String.self, forKey: .id)) ?? ""
        name = (try? c.decode(String.self, forKey: .name)) ?? ""
        typeOrder = (try? c.decode(String.self, forKey: .typeOrder)) ?? ""
        created = (try? c.decode(String.self, forKey: .created)) ?? ""
        updated = (try? c.decode(String.self, forKey: .updated)) ?? ""
    }

    init(id: String = "", name: String = "", typeOrder: String = "", created: String = "", updated: String = "") {
        self.id = id
        self.name = name
        self.typeOrder = typeOrder
        self.created = created
        self.updated = updated
    }
}
