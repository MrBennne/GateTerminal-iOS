import Foundation

enum ColorTheme: String, CaseIterable, Identifiable {
    case defaultTheme = "default"
    case arctic = "arctic"
    case rust = "rust"
    case nightOps = "night_ops"
    case mono = "mono"
    case fjord = "fjord"

    var id: String { rawValue }
    var key: String { rawValue }

    var label: String {
        switch self {
        case .defaultTheme: return "Default"
        case .arctic: return "Arctic"
        case .rust: return "Rust"
        case .nightOps: return "Night Ops"
        case .mono: return "Mono"
        case .fjord: return "Fjord"
        }
    }

    var description: String {
        switch self {
        case .defaultTheme: return "Purple-blue terminal theme"
        case .arctic: return "Cool blue tones"
        case .rust: return "Warm amber and orange"
        case .nightOps: return "Stealth grey"
        case .mono: return "Pure grayscale"
        case .fjord: return "Nordic green-blue"
        }
    }

    static func fromKey(_ key: String) -> ColorTheme {
        ColorTheme(rawValue: key) ?? .defaultTheme
    }
}

enum CardDensity: String, CaseIterable, Identifiable {
    case compact = "compact"
    case normal = "normal"
    case comfortable = "comfortable"

    var id: String { rawValue }
    var key: String { rawValue }

    var label: String {
        switch self {
        case .compact: return "Compact"
        case .normal: return "Normal"
        case .comfortable: return "Comfortable"
        }
    }

    var verticalPaddingDp: CGFloat {
        switch self {
        case .compact: return 4
        case .normal: return 8
        case .comfortable: return 12
        }
    }

    static func fromKey(_ key: String) -> CardDensity {
        CardDensity(rawValue: key) ?? .normal
    }
}

struct CardFieldKey {
    static let UNITNO = "unitno"
    static let REFNO = "refno"
    static let TYPE = "type"
    static let CARRIER = "carrier"
    static let STATUS = "status"
    static let DECK = "deck"
    static let TRA = "tra"

    static func label(_ key: String) -> String {
        switch key {
        case UNITNO: return "Unit No"
        case REFNO: return "Ref No"
        case TYPE: return "Type"
        case CARRIER: return "Carrier"
        case STATUS: return "Status"
        case DECK: return "Deck"
        case TRA: return "TRA"
        default: return key
        }
    }
}

enum FieldColorMode: String, Codable {
    case defaultMode = "default"
    case status = "status"
    case custom = "custom"
}

struct FieldTypography: Codable, Equatable {
    var colorMode: FieldColorMode = .defaultMode
    var customColor: String = ""
    var perStatusColors: [String: String] = [:]
    var fontWeight: Int = 400
    var fontSizeScale: Float = 1.0
}

struct CardLayoutConfig: Codable, Equatable {
    var leftRows: [[String]] = [
        [CardFieldKey.REFNO, CardFieldKey.UNITNO],
        [CardFieldKey.CARRIER],
        [CardFieldKey.DECK, CardFieldKey.TRA],
    ]
    var rightRows: [[String]] = [
        [CardFieldKey.STATUS],
        [CardFieldKey.TYPE],
    ]
    var bottomRows: [[String]] = []
}

struct TypographyConfig: Codable, Equatable {
    var globalFontScale: Float = 1.0
    var fields: [String: FieldTypography] = [:]
}

struct AppearanceSettings: Codable, Equatable {
    var darkMode: Bool = true
    var colorTheme: String = ColorTheme.defaultTheme.key
    var cardDensity: String = CardDensity.normal.key
    var cardLayout: CardLayoutConfig = CardLayoutConfig()
    var typography: TypographyConfig = TypographyConfig()
}
