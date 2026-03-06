import Foundation

enum ShortcutAction: String, CaseIterable, Identifiable {
    case none = "none"
    case openDetails = "open_details"
    case editUnit = "edit_unit"
    case editDfds = "edit_dfds"
    case statusPicker = "status_picker"
    case deckLocation = "deck_location"
    case traLocation = "tra_location"
    case setTraExport = "set_tra_export"
    case imoSticker = "imo_sticker"
    case bulkSelect = "bulk_select"
    case setHasEta = "set_has_eta"
    case setNeedsTrailer = "needs_trailer"
    case setNotArrived = "not_arrived"
    case setLoadIfTime = "load_if_time"
    case setReady = "ready"
    case setLoaded = "loaded"
    case setShorted = "shorted"

    var id: String { rawValue }
    var key: String { rawValue }

    var label: String {
        switch self {
        case .none: return "None"
        case .openDetails: return "Open Details"
        case .editUnit: return "Edit Unit"
        case .editDfds: return "Edit DFDS Note"
        case .statusPicker: return "Status Picker"
        case .deckLocation: return "Deck Location"
        case .traLocation: return "TRA Location"
        case .setTraExport: return "Set TRA Export"
        case .imoSticker: return "IMO Sticker"
        case .bulkSelect: return "Bulk Select"
        case .setHasEta: return "Set Has ETA"
        case .setNeedsTrailer: return "→ Needs Trailer"
        case .setNotArrived: return "→ Not Arrived"
        case .setLoadIfTime: return "→ Load If Time"
        case .setReady: return "→ Ready"
        case .setLoaded: return "→ Loaded"
        case .setShorted: return "→ Shorted"
        }
    }

    var isDirectStatus: Bool {
        switch self {
        case .setNeedsTrailer, .setNotArrived, .setLoadIfTime, .setReady, .setLoaded, .setShorted:
            return true
        default: return false
        }
    }

    static func fromKey(_ key: String) -> ShortcutAction {
        ShortcutAction(rawValue: key) ?? .none
    }
}

struct GestureShortcut: Equatable, Codable {
    var step1: ShortcutAction
    var step2: ShortcutAction

    init(step1: ShortcutAction = .none, step2: ShortcutAction = .none) {
        self.step1 = step1
        self.step2 = step2
    }

    enum CodingKeys: String, CodingKey {
        case step1, step2
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let s1 = (try? c.decode(String.self, forKey: .step1)) ?? "none"
        let s2 = (try? c.decode(String.self, forKey: .step2)) ?? "none"
        step1 = ShortcutAction.fromKey(s1)
        step2 = ShortcutAction.fromKey(s2)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(step1.key, forKey: .step1)
        try c.encode(step2.key, forKey: .step2)
    }
}

struct RoleShortcuts: Equatable {
    var tap: GestureShortcut
    var longPress: GestureShortcut
    var swipeLeft: GestureShortcut
    var swipeRight: GestureShortcut

    init(
        tap: GestureShortcut = GestureShortcut(step1: .openDetails),
        longPress: GestureShortcut = GestureShortcut(step1: .statusPicker),
        swipeLeft: GestureShortcut = GestureShortcut(step1: .deckLocation),
        swipeRight: GestureShortcut = GestureShortcut(step1: .traLocation)
    ) {
        self.tap = tap
        self.longPress = longPress
        self.swipeLeft = swipeLeft
        self.swipeRight = swipeRight
    }

    static func defaultsForRole(_ role: String) -> RoleShortcuts {
        switch role.lowercased() {
        case "customer":
            return RoleShortcuts(
                tap: GestureShortcut(step1: .openDetails),
                longPress: GestureShortcut(),
                swipeLeft: GestureShortcut(),
                swipeRight: GestureShortcut()
            )
        case "admin":
            return RoleShortcuts(
                tap: GestureShortcut(step1: .openDetails),
                longPress: GestureShortcut(step1: .statusPicker),
                swipeLeft: GestureShortcut(step1: .deckLocation),
                swipeRight: GestureShortcut(step1: .traLocation)
            )
        default: // interchange
            return RoleShortcuts(
                tap: GestureShortcut(step1: .openDetails),
                longPress: GestureShortcut(step1: .statusPicker),
                swipeLeft: GestureShortcut(step1: .deckLocation),
                swipeRight: GestureShortcut(step1: .traLocation)
            )
        }
    }

    func toPocketBaseMap() -> [String: [String: String]] {
        [
            "tap": ["step1": tap.step1.key, "step2": tap.step2.key],
            "longPress": ["step1": longPress.step1.key, "step2": longPress.step2.key],
            "swipeLeft": ["step1": swipeLeft.step1.key, "step2": swipeLeft.step2.key],
            "swipeRight": ["step1": swipeRight.step1.key, "step2": swipeRight.step2.key],
        ]
    }

    static func fromPocketBaseMap(_ map: [String: [String: String]], role: String) -> RoleShortcuts {
        let defaults = defaultsForRole(role)
        func gesture(key: String, fallback: GestureShortcut) -> GestureShortcut {
            guard let stepMap = map[key] else { return fallback }
            let s1 = stepMap["step1"].flatMap { ShortcutAction.fromKey($0) } ?? fallback.step1
            let s2 = stepMap["step2"].flatMap { ShortcutAction.fromKey($0) } ?? fallback.step2
            return GestureShortcut(step1: s1, step2: s2)
        }
        return RoleShortcuts(
            tap: gesture(key: "tap", fallback: defaults.tap),
            longPress: gesture(key: "longPress", fallback: defaults.longPress),
            swipeLeft: gesture(key: "swipeLeft", fallback: defaults.swipeLeft),
            swipeRight: gesture(key: "swipeRight", fallback: defaults.swipeRight)
        )
    }
}
