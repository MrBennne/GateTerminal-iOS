import SwiftUI

enum UnitStatus: String, CaseIterable, Codable, Identifiable {
    case needsTrailer = "needs_trailer"
    case notArrived = "not_arrived"
    case hasEta = "has_eta"
    case loadIfTime = "load_if_time"
    case ready = "ready"
    case loaded = "loaded"
    case shorted = "shorted"

    var id: String { rawValue }
    var key: String { rawValue }

    var label: String {
        switch self {
        case .needsTrailer: return "Needs Trailer"
        case .notArrived: return "Not Arrived"
        case .hasEta: return "Has ETA"
        case .loadIfTime: return "Load If Time"
        case .ready: return "Ready"
        case .loaded: return "Loaded"
        case .shorted: return "Shorted"
        }
    }

    var color: Color {
        switch self {
        case .needsTrailer: return Color(hex: 0xF97316)
        case .notArrived: return Color(hex: 0x9CA3AF)
        case .hasEta: return Color(hex: 0xF59E0B)
        case .loadIfTime: return Color(hex: 0xFBBF24)
        case .ready: return Color(hex: 0x22C55E)
        case .loaded: return Color(hex: 0x06B6D4)
        case .shorted: return Color(hex: 0xEF4444)
        }
    }

    var sortOrder: Int {
        switch self {
        case .needsTrailer: return 0
        case .notArrived: return 1
        case .hasEta: return 2
        case .loadIfTime: return 3
        case .ready: return 4
        case .loaded: return 5
        case .shorted: return 6
        }
    }

    static var sorted: [UnitStatus] {
        allCases.sorted { $0.sortOrder < $1.sortOrder }
    }

    static func fromKey(_ key: String) -> UnitStatus {
        UnitStatus(rawValue: key) ?? .notArrived
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
