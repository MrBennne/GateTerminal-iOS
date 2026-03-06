import SwiftUI

struct NewArrivalSheet: View {
    let bookingLists: [BookingList]
    let onSave: (NewArrivalData) -> Void
    let onCancel: () -> Void

    @State private var unitno = ""
    @State private var refno = ""
    @State private var carrier = ""
    @State private var type = ""
    @State private var weight = ""
    @State private var length = ""
    @State private var isImo = false
    @State private var imoClass = ""
    @State private var isReefer = false
    @State private var vehRegNo = ""
    @State private var drivers = ""
    @State private var customerNote = ""
    @State private var selectedListId: String?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                // Identity
                Section("Identity") {
                    TextField("Unit No *", text: $unitno)
                        .textInputAutocapitalization(.characters)
                    TextField("Ref No", text: $refno)
                        .textInputAutocapitalization(.characters)
                    TextField("Carrier", text: $carrier)
                        .textInputAutocapitalization(.characters)
                    TextField("Type", text: $type)
                        .textInputAutocapitalization(.characters)
                }

                // Booking list
                if !bookingLists.isEmpty {
                    Section("Booking List") {
                        Picker("List", selection: $selectedListId) {
                            Text("None").tag(nil as String?)
                            ForEach(bookingLists) { list in
                                Text(list.name).tag(list.id as String?)
                            }
                        }
                    }
                }

                // Properties
                Section("Properties") {
                    TextField("Weight", text: $weight)
                        .keyboardType(.decimalPad)
                    TextField("Length", text: $length)
                        .keyboardType(.decimalPad)
                    TextField("Veh Reg No", text: $vehRegNo)
                        .textInputAutocapitalization(.characters)
                    TextField("Drivers", text: $drivers)
                }

                // Flags
                Section("Flags") {
                    Toggle("IMO (Dangerous Goods)", isOn: $isImo)
                    if isImo {
                        TextField("IMO Class", text: $imoClass)
                    }
                    Toggle("Reefer (Temperature Controlled)", isOn: $isReefer)
                }

                // Notes
                Section("Notes") {
                    TextField("Customer Note", text: $customerNote, axis: .vertical)
                        .lineLimit(1...4)
                }
            }
            .navigationTitle("New Arrival")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        isSaving = true
                        let data = NewArrivalData(
                            unitno: unitno,
                            refno: refno,
                            carrier: carrier,
                            type: type,
                            weight: weight,
                            length: length,
                            isImo: isImo,
                            imoClass: imoClass,
                            isReefer: isReefer,
                            vehRegNo: vehRegNo,
                            drivers: drivers,
                            customerNote: customerNote,
                            bookingListId: selectedListId
                        )
                        onSave(data)
                    }
                    .disabled(unitno.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct NewArrivalData {
    let unitno: String
    let refno: String
    let carrier: String
    let type: String
    let weight: String
    let length: String
    let isImo: Bool
    let imoClass: String
    let isReefer: Bool
    let vehRegNo: String
    let drivers: String
    let customerNote: String
    let bookingListId: String?

    func toFields() -> [String: Any] {
        var fields: [String: Any] = [
            "unitno": unitno,
            "refno": refno,
            "carrier": carrier,
            "type": type,
            "status": "not_arrived",
            "weight": weight,
            "length": length,
            "is_imo": isImo,
            "imo_class": imoClass,
            "is_reefer": isReefer,
            "veh_reg_no": vehRegNo,
            "drivers": drivers,
            "customer_note": customerNote,
        ]
        if let listId = bookingListId {
            fields["booking_list_id"] = listId
            fields["booking_list_ids"] = [listId]
        }
        return fields
    }
}
