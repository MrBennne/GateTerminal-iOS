import Foundation

struct SseEvent {
    var event: String = ""
    var data: String = ""
    var id: String = ""
}

struct SseRecord: Codable {
    var action: String = ""
    var record: GateUnit?
}
