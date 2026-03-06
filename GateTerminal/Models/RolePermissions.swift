import Foundation

struct RolePermissions: Equatable {
    var canViewUnits: Bool = true
    var canEditUnits: Bool = true
    var canCreateUnits: Bool = true
    var canDeleteUnits: Bool = false
    var canChangeStatus: Bool = true
    var canEditDeckLocation: Bool = true
    var canEditTraLocation: Bool = true
    var canEditDrivers: Bool = true
    var canEditDFDS: Bool = false
    var canBulkEdit: Bool = true
    var canBulkActions: Bool = true
    var canCreateList: Bool = false
    var canRenameList: Bool = false
    var canDeleteList: Bool = false
    var canEditTypeOrder: Bool = false
    var canViewHistory: Bool = true
    var canManageRoles: Bool = false
    var canEditShortcuts: Bool = true

    static let interchangeDefaults = RolePermissions()

    static let customerDefaults = RolePermissions(
        canViewUnits: true,
        canEditUnits: false,
        canCreateUnits: false,
        canDeleteUnits: false,
        canChangeStatus: false,
        canEditDeckLocation: false,
        canEditTraLocation: false,
        canEditDrivers: false,
        canEditDFDS: false,
        canBulkEdit: false,
        canBulkActions: false,
        canCreateList: false,
        canRenameList: false,
        canDeleteList: false,
        canEditTypeOrder: false,
        canViewHistory: true,
        canManageRoles: false,
        canEditShortcuts: true
    )

    static let adminDefaults = RolePermissions(
        canViewUnits: true,
        canEditUnits: true,
        canCreateUnits: true,
        canDeleteUnits: true,
        canChangeStatus: true,
        canEditDeckLocation: true,
        canEditTraLocation: true,
        canEditDrivers: true,
        canEditDFDS: true,
        canBulkEdit: true,
        canBulkActions: true,
        canCreateList: true,
        canRenameList: true,
        canDeleteList: true,
        canEditTypeOrder: true,
        canViewHistory: true,
        canManageRoles: true,
        canEditShortcuts: true
    )

    static func forRole(_ role: String) -> RolePermissions {
        switch role.lowercased() {
        case "admin": return adminDefaults
        case "customer": return customerDefaults
        default: return interchangeDefaults
        }
    }

    static func fromJson(_ json: [String: Any]) -> RolePermissions {
        var p = RolePermissions()
        if let v = json["canViewUnits"] as? Bool { p.canViewUnits = v }
        if let v = json["canEditUnits"] as? Bool { p.canEditUnits = v }
        if let v = json["canCreateUnits"] as? Bool { p.canCreateUnits = v }
        if let v = json["canDeleteUnits"] as? Bool { p.canDeleteUnits = v }
        if let v = json["canChangeStatus"] as? Bool { p.canChangeStatus = v }
        if let v = json["canEditDeckLocation"] as? Bool { p.canEditDeckLocation = v }
        if let v = json["canEditTraLocation"] as? Bool { p.canEditTraLocation = v }
        if let v = json["canEditDrivers"] as? Bool { p.canEditDrivers = v }
        if let v = json["canEditDFDS"] as? Bool { p.canEditDFDS = v }
        if let v = json["canBulkEdit"] as? Bool { p.canBulkEdit = v }
        if let v = json["canBulkActions"] as? Bool { p.canBulkActions = v }
        if let v = json["canCreateList"] as? Bool { p.canCreateList = v }
        if let v = json["canRenameList"] as? Bool { p.canRenameList = v }
        if let v = json["canDeleteList"] as? Bool { p.canDeleteList = v }
        if let v = json["canEditTypeOrder"] as? Bool { p.canEditTypeOrder = v }
        if let v = json["canViewHistory"] as? Bool { p.canViewHistory = v }
        if let v = json["canManageRoles"] as? Bool { p.canManageRoles = v }
        if let v = json["canEditShortcuts"] as? Bool { p.canEditShortcuts = v }
        return p
    }
}
