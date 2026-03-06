import Foundation

struct GateUnit: Codable, Identifiable, Equatable, Hashable {
    var id: String = ""
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
    var arrivalTime: String = ""
    var loadedTime: String = ""
    var bookingListId: String = ""
    var bookingListIds: [String] = []
    var stackChildren: [GateUnit] = []
    var updated: String = ""
    var created: String = ""

    var parsedStatus: UnitStatus {
        UnitStatus.fromKey(status)
    }

    func matchesSearch(_ query: String) -> Bool {
        let q = query.lowercased()
        return unitno.lowercased().contains(q) ||
            refno.lowercased().contains(q) ||
            carrier.lowercased().contains(q) ||
            type.lowercased().contains(q) ||
            locationDeck.lowercased().contains(q) ||
            locationTra.lowercased().contains(q) ||
            statusNote.lowercased().contains(q) ||
            customerNote.lowercased().contains(q) ||
            dfdsNote.lowercased().contains(q) ||
            drivers.lowercased().contains(q) ||
            vehRegNo.lowercased().contains(q)
    }

    func fieldValue(_ field: String) -> String? {
        switch field {
        case "unitno": return unitno
        case "refno": return refno
        case "status": return status
        case "type": return type
        case "carrier": return carrier
        case "location_deck": return locationDeck
        case "location_tra": return locationTra
        case "weight": return weight
        case "length": return length
        case "is_imo": return String(isImo)
        case "imo_class": return imoClass
        case "is_reefer": return String(isReefer)
        case "eta_time": return etaTime
        case "veh_reg_no": return vehRegNo
        case "drivers": return drivers
        case "status_note": return statusNote
        case "customer_note": return customerNote
        case "sticker_note": return stickerNote
        case "handling_instructions": return handlingInstructions
        case "DFDS_note": return dfdsNote
        case "reloaded": return reloaded
        case "arrival_time": return arrivalTime
        case "loaded_time": return loadedTime
        case "booking_list_id": return bookingListId
        default: return nil
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, unitno, refno, status, type, carrier
        case locationDeck = "location_deck"
        case locationTra = "location_tra"
        case weight, length
        case isImo = "is_imo"
        case imoClass = "imo_class"
        case isReefer = "is_reefer"
        case etaTime = "eta_time"
        case vehRegNo = "veh_reg_no"
        case drivers
        case statusNote = "status_note"
        case customerNote = "customer_note"
        case stickerNote = "sticker_note"
        case handlingInstructions = "handling_instructions"
        case dfdsNote = "DFDS_note"
        case reloaded
        case arrivalTime = "arrival_time"
        case loadedTime = "loaded_time"
        case bookingListId = "booking_list_id"
        case bookingListIds = "booking_list_ids"
        case stackChildren = "stack_children"
        case updated, created
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(String.self, forKey: .id)) ?? ""
        unitno = (try? c.decode(String.self, forKey: .unitno)) ?? ""
        refno = (try? c.decode(String.self, forKey: .refno)) ?? ""
        status = (try? c.decode(String.self, forKey: .status)) ?? "not_arrived"
        type = (try? c.decode(String.self, forKey: .type)) ?? ""
        carrier = (try? c.decode(String.self, forKey: .carrier)) ?? ""
        locationDeck = (try? c.decode(String.self, forKey: .locationDeck)) ?? ""
        locationTra = (try? c.decode(String.self, forKey: .locationTra)) ?? ""
        weight = (try? c.decode(String.self, forKey: .weight)) ?? ""
        length = (try? c.decode(String.self, forKey: .length)) ?? ""
        isImo = (try? c.decode(Bool.self, forKey: .isImo)) ?? false
        imoClass = (try? c.decode(String.self, forKey: .imoClass)) ?? ""
        isReefer = (try? c.decode(Bool.self, forKey: .isReefer)) ?? false
        etaTime = (try? c.decode(String.self, forKey: .etaTime)) ?? ""
        vehRegNo = (try? c.decode(String.self, forKey: .vehRegNo)) ?? ""
        drivers = (try? c.decode(String.self, forKey: .drivers)) ?? ""
        statusNote = (try? c.decode(String.self, forKey: .statusNote)) ?? ""
        customerNote = (try? c.decode(String.self, forKey: .customerNote)) ?? ""
        stickerNote = (try? c.decode(String.self, forKey: .stickerNote)) ?? ""
        handlingInstructions = (try? c.decode(String.self, forKey: .handlingInstructions)) ?? ""
        dfdsNote = (try? c.decode(String.self, forKey: .dfdsNote)) ?? ""
        reloaded = (try? c.decode(String.self, forKey: .reloaded)) ?? ""
        arrivalTime = (try? c.decode(String.self, forKey: .arrivalTime)) ?? ""
        loadedTime = (try? c.decode(String.self, forKey: .loadedTime)) ?? ""
        bookingListId = (try? c.decode(String.self, forKey: .bookingListId)) ?? ""
        bookingListIds = (try? c.decode([String].self, forKey: .bookingListIds)) ?? []
        stackChildren = (try? c.decode([GateUnit].self, forKey: .stackChildren)) ?? []
        updated = (try? c.decode(String.self, forKey: .updated)) ?? ""
        created = (try? c.decode(String.self, forKey: .created)) ?? ""
    }

    init(
        id: String = "",
        unitno: String = "",
        refno: String = "",
        status: String = "not_arrived",
        type: String = "",
        carrier: String = "",
        locationDeck: String = "",
        locationTra: String = "",
        weight: String = "",
        length: String = "",
        isImo: Bool = false,
        imoClass: String = "",
        isReefer: Bool = false,
        etaTime: String = "",
        vehRegNo: String = "",
        drivers: String = "",
        statusNote: String = "",
        customerNote: String = "",
        stickerNote: String = "",
        handlingInstructions: String = "",
        dfdsNote: String = "",
        reloaded: String = "",
        arrivalTime: String = "",
        loadedTime: String = "",
        bookingListId: String = "",
        bookingListIds: [String] = [],
        stackChildren: [GateUnit] = [],
        updated: String = "",
        created: String = ""
    ) {
        self.id = id
        self.unitno = unitno
        self.refno = refno
        self.status = status
        self.type = type
        self.carrier = carrier
        self.locationDeck = locationDeck
        self.locationTra = locationTra
        self.weight = weight
        self.length = length
        self.isImo = isImo
        self.imoClass = imoClass
        self.isReefer = isReefer
        self.etaTime = etaTime
        self.vehRegNo = vehRegNo
        self.drivers = drivers
        self.statusNote = statusNote
        self.customerNote = customerNote
        self.stickerNote = stickerNote
        self.handlingInstructions = handlingInstructions
        self.dfdsNote = dfdsNote
        self.reloaded = reloaded
        self.arrivalTime = arrivalTime
        self.loadedTime = loadedTime
        self.bookingListId = bookingListId
        self.bookingListIds = bookingListIds
        self.stackChildren = stackChildren
        self.updated = updated
        self.created = created
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: GateUnit, rhs: GateUnit) -> Bool {
        lhs.id == rhs.id && lhs.updated == rhs.updated
    }
}
