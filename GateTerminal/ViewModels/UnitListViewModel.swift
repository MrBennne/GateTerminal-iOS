import Foundation
import SwiftUI

enum SortOption: String, CaseIterable, Identifiable {
    case status, refno, unitno, carrier, type, updated, weight
    var id: String { rawValue }
    var label: String {
        switch self {
        case .status: return "Status"
        case .refno: return "Ref No"
        case .unitno: return "Unit No"
        case .carrier: return "Carrier"
        case .type: return "Type"
        case .updated: return "Updated"
        case .weight: return "Weight"
        }
    }
}

enum GroupOption: String, CaseIterable, Identifiable {
    case none, status, type
    var id: String { rawValue }
    var label: String {
        switch self {
        case .none: return "None"
        case .status: return "Status"
        case .type: return "Type"
        }
    }
}

enum ViewMode: String, CaseIterable, Identifiable {
    case defaultMode = "default"
    case deck = "deck"
    var id: String { rawValue }
    var label: String {
        switch self {
        case .defaultMode: return "Default"
        case .deck: return "Deck View"
        }
    }
}

struct UnitGroup: Identifiable {
    let label: String
    var units: [GateUnit]
    var id: String { label.isEmpty ? "all" : label }
}

@Observable
@MainActor
final class UnitListViewModel {
    let unitRepo: UnitRepository
    private let authService: AuthService
    private let shortcutPrefs: ShortcutPreferences

    var search: String = ""
    var statusFilter: Set<UnitStatus> = []
    var typeFilter: Set<String> = []
    var imoOnly: Bool = false
    var reeferOnly: Bool = false
    var sortBy: SortOption = .refno
    var groupBy: GroupOption = .none
    var selectedListId: String?
    var viewMode: ViewMode = .defaultMode
    var bulkMode: Bool = false
    var selectedIds: Set<String> = []
    var quickActionError: String?

    init(unitRepo: UnitRepository, authService: AuthService, shortcutPrefs: ShortcutPreferences) {
        self.unitRepo = unitRepo
        self.authService = authService
        self.shortcutPrefs = shortcutPrefs
    }

    var connectionState: ConnectionState { unitRepo.connectionState }
    var isLoading: Bool { unitRepo.isLoading }
    var permissions: RolePermissions { authService.permissions }
    var allUnits: [GateUnit] { unitRepo.units }
    var lists: [BookingList] { unitRepo.lists }
    var currentUser: User? { authService.currentUser }
    var roleShortcuts: RoleShortcuts { shortcutPrefs.shortcuts }

    var availableTypes: [String] {
        let filtered = unitRepo.units.filter { unit in
            selectedListId == nil || unit.bookingListIds.contains(selectedListId!) || unit.bookingListId == selectedListId
        }.filter { !$0.type.localizedCaseInsensitiveContains("(CARRIER)") }
        return Array(Set(filtered.map { $0.type }.filter { !$0.isEmpty })).sorted()
    }

    var visibleUnits: [UnitGroup] {
        let listId = selectedListId
        let listUnits = unitRepo.units.filter { unit in
            listId == nil || unit.bookingListIds.contains(listId!) || unit.bookingListId == listId
        }

        let filtered = listUnits.filter { unit in
            (statusFilter.isEmpty || statusFilter.contains(unit.parsedStatus)) &&
            (typeFilter.isEmpty || typeFilter.contains(unit.type)) &&
            (!imoOnly || unit.isImo) &&
            (!reeferOnly || unit.isReefer) &&
            (search.isEmpty || unit.matchesSearch(search))
        }.sorted(by: sortComparator)

        let stacked = buildMafiStacks(filtered, allCarrierCandidates: listUnits)
            .filter { !$0.type.localizedCaseInsensitiveContains("(CARRIER)") }

        switch groupBy {
        case .none:
            return [UnitGroup(label: "", units: stacked)]
        case .status:
            let grouped = Dictionary(grouping: stacked) { $0.parsedStatus }
            return UnitStatus.sorted.compactMap { status in
                guard let units = grouped[status], !units.isEmpty else { return nil }
                return UnitGroup(label: status.label, units: units)
            }
        case .type:
            let grouped = Dictionary(grouping: stacked) { $0.type.isEmpty ? "Unknown" : $0.type }
            return grouped.keys.sorted().map { key in
                UnitGroup(label: key, units: grouped[key]!)
            }
        }
    }

    var totalVisibleCount: Int {
        visibleUnits.reduce(0) { $0 + $1.units.count }
    }

    var deckGroupedUnits: [UnitGroup] {
        let listId = selectedListId
        let loaded = unitRepo.units.filter { unit in
            (listId == nil || unit.bookingListIds.contains(listId!) || unit.bookingListId == listId) &&
            unit.parsedStatus == .loaded
        }

        let deckOrder = ["WD", "MD", "LH"]
        let grouped = Dictionary(grouping: loaded) { normalizeDeck($0.locationDeck) }

        return grouped.keys.sorted { a, b in
            let ia = deckOrder.firstIndex(of: a) ?? deckOrder.count
            let ib = deckOrder.firstIndex(of: b) ?? deckOrder.count
            return ia < ib
        }.map { key in
            UnitGroup(label: key.isEmpty ? "Unassigned" : key, units: grouped[key]!)
        }
    }

    // MARK: - Quick actions

    func quickSetStatus(_ unitId: String, _ status: UnitStatus) {
        Task {
            do {
                _ = try await unitRepo.updateUnit(unitId, ["status": status.key])
            } catch {
                quickActionError = error.localizedDescription
            }
        }
    }

    func quickSetDeckLocation(_ unitId: String, _ location: String) {
        Task {
            do {
                _ = try await unitRepo.updateUnit(unitId, ["location_deck": location])
            } catch {
                quickActionError = error.localizedDescription
            }
        }
    }

    func quickSetTraLocation(_ unitId: String, _ location: String) {
        Task {
            do {
                _ = try await unitRepo.updateUnit(unitId, ["location_tra": location])
            } catch {
                quickActionError = error.localizedDescription
            }
        }
    }

    func quickSetDirectStatus(_ unitId: String, _ action: ShortcutAction) {
        Task {
            do {
                _ = try await unitRepo.updateUnit(unitId, ["status": action.key])
            } catch {
                quickActionError = error.localizedDescription
            }
        }
    }

    func quickSetStickerNote(_ unitId: String, _ note: String) {
        Task {
            do {
                _ = try await unitRepo.updateUnit(unitId, ["sticker_note": note])
            } catch {
                quickActionError = error.localizedDescription
            }
        }
    }

    func quickSetDfdsNote(_ unitId: String, _ note: String) {
        Task {
            do {
                _ = try await unitRepo.updateUnit(unitId, ["DFDS_note": note])
            } catch {
                quickActionError = error.localizedDescription
            }
        }
    }

    func quickSetStatusWithEta(_ unitId: String, _ etaTime: String) {
        Task {
            do {
                _ = try await unitRepo.updateUnit(unitId, ["status": "has_eta", "eta_time": etaTime])
            } catch {
                quickActionError = error.localizedDescription
            }
        }
    }

    func clearQuickActionError() { quickActionError = nil }

    func getUnit(_ unitId: String) -> GateUnit? {
        unitRepo.units.first { $0.id == unitId }
    }

    // MARK: - Filter actions

    func toggleStatusFilter(_ status: UnitStatus) {
        if statusFilter.contains(status) { statusFilter.remove(status) }
        else { statusFilter.insert(status) }
    }

    func toggleTypeFilter(_ type: String) {
        if typeFilter.contains(type) { typeFilter.remove(type) }
        else { typeFilter.insert(type) }
    }

    func clearFilters() {
        search = ""
        statusFilter = []
        typeFilter = []
        imoOnly = false
        reeferOnly = false
    }

    // MARK: - Bulk

    func enterBulkMode(_ unitId: String) {
        bulkMode = true
        selectedIds = [unitId]
    }

    func toggleSelection(_ unitId: String) {
        if selectedIds.contains(unitId) { selectedIds.remove(unitId) }
        else { selectedIds.insert(unitId) }
        if selectedIds.isEmpty { bulkMode = false }
    }

    func selectAll() {
        selectedIds = Set(visibleUnits.flatMap { $0.units.map { $0.id } })
    }

    func clearSelection() {
        selectedIds = []
        bulkMode = false
    }

    // MARK: - Lifecycle

    func onForeground() {
        unitRepo.connect()
    }

    func onBackground() {
        unitRepo.disconnect()
    }

    func refresh() {
        Task { await unitRepo.refresh() }
    }

    func logout() {
        unitRepo.disconnect()
        authService.logout()
    }

    func autoSelectList() {
        if selectedListId == nil, let mostRecent = lists.max(by: { $0.created < $1.created }) {
            selectedListId = mostRecent.id
        }
    }

    // MARK: - Private helpers

    private var sortComparator: (GateUnit, GateUnit) -> Bool {
        switch sortBy {
        case .status: return { $0.parsedStatus.sortOrder < $1.parsedStatus.sortOrder }
        case .refno: return { $0.refno.localizedCaseInsensitiveCompare($1.refno) == .orderedAscending }
        case .unitno: return { $0.unitno.localizedCaseInsensitiveCompare($1.unitno) == .orderedAscending }
        case .carrier: return { $0.carrier.localizedCaseInsensitiveCompare($1.carrier) == .orderedAscending }
        case .type: return { $0.type.localizedCaseInsensitiveCompare($1.type) == .orderedAscending }
        case .updated: return { $0.updated > $1.updated }
        case .weight: return {
            let w0 = Double($0.weight.replacingOccurrences(of: ",", with: ".")) ?? 0
            let w1 = Double($1.weight.replacingOccurrences(of: ",", with: ".")) ?? 0
            return w0 > w1
        }
        }
    }

    private func normalizeDeck(_ deck: String) -> String {
        let upper = deck.uppercased().trimmingCharacters(in: .whitespaces)
        if upper.hasPrefix("WD") { return "WD" }
        if upper.hasPrefix("MD") { return "MD" }
        if upper.hasPrefix("LH") { return "LH" }
        return upper
    }

    private func buildMafiStacks(_ units: [GateUnit], allCarrierCandidates: [GateUnit]) -> [GateUnit] {
        var childrenByParent: [String: [GateUnit]] = [:]
        for unit in allCarrierCandidates {
            if !unit.reloaded.isEmpty {
                childrenByParent[unit.reloaded.uppercased(), default: []].append(unit)
            }
        }
        guard !childrenByParent.isEmpty else { return units }

        let parentUnitnos = Set(units.map { $0.unitno.uppercased() })
        var hiddenChildIds: Set<String> = []
        for (parentNo, children) in childrenByParent {
            if parentUnitnos.contains(parentNo) {
                children.forEach { hiddenChildIds.insert($0.id) }
            }
        }

        return units.compactMap { unit in
            if hiddenChildIds.contains(unit.id) { return nil }
            if let children = childrenByParent[unit.unitno.uppercased()] {
                var copy = unit
                copy.stackChildren = children
                return copy
            }
            return unit
        }
    }
}
