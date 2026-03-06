import Foundation

struct UnitEditState: Equatable {
    var unitno: String = ""
    var refno: String = ""
    var status: String = "not_arrived"
    var type: String = ""
    var carrier: String = ""
    var locationDeck: String = ""
    var locationTra: String = ""
    var weight: String = ""
    var length: String = ""
    var isImo: Bool = false
    var imoClass: String = ""
    var isReefer: Bool = false
    var etaTime: String = ""
    var vehRegNo: String = ""
    var drivers: String = ""
    var statusNote: String = ""
    var customerNote: String = ""
    var stickerNote: String = ""
    var handlingInstructions: String = ""
    var dfdsNote: String = ""
    var reloaded: String = ""

    static func from(_ unit: GateUnit) -> UnitEditState {
        UnitEditState(
            unitno: unit.unitno,
            refno: unit.refno,
            status: unit.status,
            type: unit.type,
            carrier: unit.carrier,
            locationDeck: unit.locationDeck,
            locationTra: unit.locationTra,
            weight: unit.weight,
            length: unit.length,
            isImo: unit.isImo,
            imoClass: unit.imoClass,
            isReefer: unit.isReefer,
            etaTime: unit.etaTime,
            vehRegNo: unit.vehRegNo,
            drivers: unit.drivers,
            statusNote: unit.statusNote,
            customerNote: unit.customerNote,
            stickerNote: unit.stickerNote,
            handlingInstructions: unit.handlingInstructions,
            dfdsNote: unit.dfdsNote,
            reloaded: unit.reloaded
        )
    }

    func toUpdates() -> [String: Any] {
        var updates: [String: Any] = [
            "unitno": unitno,
            "refno": refno,
            "status": status,
            "type": type,
            "carrier": carrier,
            "location_deck": locationDeck,
            "location_tra": locationTra,
            "weight": weight,
            "length": length,
            "is_imo": isImo,
            "imo_class": imoClass,
            "is_reefer": isReefer,
            "eta_time": etaTime,
            "veh_reg_no": vehRegNo,
            "drivers": drivers,
            "status_note": statusNote,
            "customer_note": customerNote,
            "sticker_note": stickerNote,
            "handling_instructions": handlingInstructions,
            "DFDS_note": dfdsNote,
            "reloaded": reloaded,
        ]

        let parsedStatus = UnitStatus.fromKey(status)
        if parsedStatus == .ready {
            updates["arrival_time"] = nowCopenhagenISO()
        }
        if parsedStatus == .loaded {
            updates["loaded_time"] = nowCopenhagenISO()
        }
        return updates
    }
}

@Observable
@MainActor
final class UnitDetailViewModel {
    private let unitRepo: UnitRepository
    private let authService: AuthService

    var editState = UnitEditState()
    var isSaving: Bool = false
    var error: String?
    var history: [AuditLog] = []
    var showImoPrompt: Bool = false
    var showEtaPrompt: Bool = false

    private var currentUnitId: String?
    private var originalUnit: GateUnit?

    var permissions: RolePermissions { authService.permissions }

    init(unitRepo: UnitRepository, authService: AuthService) {
        self.unitRepo = unitRepo
        self.authService = authService
    }

    func loadUnit(_ unitId: String) {
        guard let unit = unitRepo.units.first(where: { $0.id == unitId }) else { return }
        currentUnitId = unitId
        originalUnit = unit
        editState = UnitEditState.from(unit)

        Task {
            history = await unitRepo.fetchHistory(unitId)
        }
    }

    func updateField(_ updater: (inout UnitEditState) -> Void) {
        updater(&editState)
    }

    func save(onSuccess: @escaping () -> Void) {
        guard let unitId = currentUnitId else { return }
        let parsedStatus = UnitStatus.fromKey(editState.status)
        let originalStatus = originalUnit.map { UnitStatus.fromKey($0.status) }

        // Check ETA prompt
        if parsedStatus == .hasEta && originalStatus != .hasEta && editState.etaTime.isEmpty {
            showEtaPrompt = true
            return
        }

        // Check IMO sticker prompt
        if parsedStatus == .ready && originalStatus != .ready && (editState.isImo || !editState.imoClass.isEmpty) {
            showImoPrompt = true
            return
        }

        // Legacy interchange IMO check
        if authService.isInterchange && editState.isImo && originalUnit?.isImo == true && parsedStatus == originalStatus {
            showImoPrompt = true
            return
        }

        doSave(unitId: unitId, state: editState, onSuccess: onSuccess)
    }

    func confirmImoSticker(_ stickerNote: String, onSuccess: @escaping () -> Void) {
        showImoPrompt = false
        guard let unitId = currentUnitId else { return }
        editState.stickerNote = stickerNote
        doSave(unitId: unitId, state: editState, onSuccess: onSuccess)
    }

    func dismissImoPrompt(onSuccess: @escaping () -> Void) {
        showImoPrompt = false
        guard let unitId = currentUnitId else { return }
        doSave(unitId: unitId, state: editState, onSuccess: onSuccess)
    }

    func confirmEta(_ etaTime: String, onSuccess: @escaping () -> Void) {
        showEtaPrompt = false
        guard let unitId = currentUnitId else { return }
        editState.etaTime = etaTime
        doSave(unitId: unitId, state: editState, onSuccess: onSuccess)
    }

    func dismissEtaPrompt(onSuccess: @escaping () -> Void) {
        showEtaPrompt = false
        guard let unitId = currentUnitId else { return }
        doSave(unitId: unitId, state: editState, onSuccess: onSuccess)
    }

    func deleteUnit(_ unitId: String) async throws {
        try await unitRepo.deleteUnit(unitId)
    }

    private func doSave(unitId: String, state: UnitEditState, onSuccess: @escaping () -> Void) {
        isSaving = true
        error = nil

        Task {
            do {
                let updated = try await unitRepo.updateUnit(unitId, state.toUpdates())
                isSaving = false
                originalUnit = updated
                onSuccess()
            } catch {
                isSaving = false
                self.error = error.localizedDescription
            }
        }
    }
}
