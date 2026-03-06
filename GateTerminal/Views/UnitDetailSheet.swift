import SwiftUI

struct UnitDetailSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let unitId: String

    @State private var viewModel: UnitDetailViewModel?
    @State private var showDeleteConfirm = false

    var body: some View {
        let vm = viewModel ?? makeVM()

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Error
                    if let error = vm.error {
                        Text(error)
                            .font(.callout)
                            .foregroundStyle(.white)
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(AppColors.error.opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // Identity
                    SectionHeader(title: "Identity")
                    HStack(spacing: 8) {
                        VStack(alignment: .leading) {
                            Text("Unit No").font(.caption).foregroundStyle(AppColors.onSurfaceVariant)
                            TextField("Unit No", text: editBinding(\.unitno))
                                .textFieldStyle(.roundedBorder)
                                .disabled(!vm.permissions.canEditUnits)
                        }
                        VStack(alignment: .leading) {
                            Text("Ref No").font(.caption).foregroundStyle(AppColors.onSurfaceVariant)
                            TextField("Ref No", text: editBinding(\.refno))
                                .textFieldStyle(.roundedBorder)
                                .disabled(!vm.permissions.canEditUnits)
                        }
                    }
                    HStack(spacing: 8) {
                        VStack(alignment: .leading) {
                            Text("Carrier").font(.caption).foregroundStyle(AppColors.onSurfaceVariant)
                            TextField("Carrier", text: editBinding(\.carrier))
                                .textFieldStyle(.roundedBorder)
                                .disabled(!vm.permissions.canEditUnits)
                        }
                        VStack(alignment: .leading) {
                            Text("Type").font(.caption).foregroundStyle(AppColors.onSurfaceVariant)
                            TextField("Type", text: editBinding(\.type))
                                .textFieldStyle(.roundedBorder)
                                .disabled(!vm.permissions.canEditUnits)
                        }
                    }

                    // Status
                    if vm.permissions.canChangeStatus {
                        SectionHeader(title: "Status")
                        StatusPicker(
                            selected: UnitStatus.fromKey(vm.editState.status),
                            onSelect: { status in
                                vm.updateField { $0.status = status.key }
                            }
                        )
                        TextField("Status Note", text: editBinding(\.statusNote), axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(1...3)
                    }

                    // Location
                    SectionHeader(title: "Location")
                    DeckLocationPicker(
                        selected: vm.editState.locationDeck.isEmpty ? nil : vm.editState.locationDeck,
                        onSelect: { vm.updateField { $0.locationDeck = $1 ?? "" } },
                        enabled: vm.permissions.canEditDeckLocation
                    )
                    TraLocationPicker(
                        selected: vm.editState.locationTra.isEmpty ? nil : vm.editState.locationTra,
                        onSelect: { vm.updateField { $0.locationTra = $1 ?? "" } },
                        enabled: vm.permissions.canEditTraLocation
                    )

                    // Properties
                    SectionHeader(title: "Properties")
                    HStack(spacing: 8) {
                        VStack(alignment: .leading) {
                            Text("Weight").font(.caption).foregroundStyle(AppColors.onSurfaceVariant)
                            TextField("Weight", text: editBinding(\.weight))
                                .textFieldStyle(.roundedBorder)
                                .disabled(!vm.permissions.canEditUnits)
                        }
                        VStack(alignment: .leading) {
                            Text("Length").font(.caption).foregroundStyle(AppColors.onSurfaceVariant)
                            TextField("Length", text: editBinding(\.length))
                                .textFieldStyle(.roundedBorder)
                                .disabled(!vm.permissions.canEditUnits)
                        }
                    }
                    HStack(spacing: 8) {
                        VStack(alignment: .leading) {
                            Text("Veh Reg No").font(.caption).foregroundStyle(AppColors.onSurfaceVariant)
                            TextField("Veh Reg No", text: editBinding(\.vehRegNo))
                                .textFieldStyle(.roundedBorder)
                                .disabled(!vm.permissions.canEditUnits)
                        }
                        VStack(alignment: .leading) {
                            Text("Drivers").font(.caption).foregroundStyle(AppColors.onSurfaceVariant)
                            TextField("Drivers", text: editBinding(\.drivers))
                                .textFieldStyle(.roundedBorder)
                                .disabled(!vm.permissions.canEditDrivers)
                        }
                    }

                    // Flags
                    SectionHeader(title: "Flags")
                    HStack(spacing: 16) {
                        Toggle("IMO", isOn: Binding(
                            get: { vm.editState.isImo },
                            set: { vm.updateField { $0.isImo = $1 } }
                        ))
                        .toggleStyle(.button)
                        .disabled(!vm.permissions.canEditUnits)

                        Toggle("Reefer", isOn: Binding(
                            get: { vm.editState.isReefer },
                            set: { vm.updateField { $0.isReefer = $1 } }
                        ))
                        .toggleStyle(.button)
                        .disabled(!vm.permissions.canEditUnits)
                    }

                    if vm.editState.isImo {
                        TextField("IMO Class", text: editBinding(\.imoClass))
                            .textFieldStyle(.roundedBorder)
                            .disabled(!vm.permissions.canEditUnits)
                    }

                    // Notes
                    SectionHeader(title: "Notes")
                    TextField("Customer Note", text: editBinding(\.customerNote), axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...3)
                        .disabled(!vm.permissions.canEditUnits)
                    TextField("Sticker Note", text: editBinding(\.stickerNote), axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...3)
                        .disabled(!vm.permissions.canEditUnits)
                    TextField("Handling Instructions", text: editBinding(\.handlingInstructions), axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...3)
                        .disabled(!vm.permissions.canEditUnits)
                    TextField("DFDS Note", text: editBinding(\.dfdsNote), axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...3)
                        .disabled(!(vm.permissions.canEditDFDS || vm.permissions.canEditUnits))

                    // ETA
                    TextField("ETA Time", text: editBinding(\.etaTime))
                        .textFieldStyle(.roundedBorder)
                        .disabled(!vm.permissions.canEditUnits)

                    // History
                    Divider()
                    ChangeHistorySection(history: vm.history)
                }
                .padding(16)
            }
            .navigationTitle("Edit Unit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        vm.save { dismiss() }
                    } label: {
                        if vm.isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(vm.isSaving || !vm.permissions.canEditUnits)
                }
                if vm.permissions.canDeleteUnits {
                    ToolbarItem(placement: .bottomBar) {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                                .foregroundStyle(AppColors.error)
                        }
                    }
                }
            }
            .alert("Delete Unit", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        try? await vm.deleteUnit(unitId)
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to delete \(vm.editState.unitno)? This cannot be undone.")
            }
            .sheet(isPresented: Binding(get: { vm.showImoPrompt }, set: { vm.showImoPrompt = $0 })) {
                let unit = GateUnit(id: unitId, unitno: vm.editState.unitno, isImo: vm.editState.isImo, imoClass: vm.editState.imoClass, stickerNote: vm.editState.stickerNote)
                ImoStickerSheet(unit: unit) { stickerNote in
                    if let note = stickerNote {
                        vm.confirmImoSticker(note) { dismiss() }
                    } else {
                        vm.dismissImoPrompt { dismiss() }
                    }
                } onDismiss: {
                    vm.dismissImoPrompt { dismiss() }
                }
            }
            .sheet(isPresented: Binding(get: { vm.showEtaPrompt }, set: { vm.showEtaPrompt = $0 })) {
                let unit = GateUnit(id: unitId, unitno: vm.editState.unitno, etaTime: vm.editState.etaTime)
                EtaTimeSheet(unit: unit) { etaTime in
                    vm.confirmEta(etaTime) { dismiss() }
                } onDismiss: {
                    vm.dismissEtaPrompt { dismiss() }
                }
            }
        }
        .onAppear {
            if viewModel == nil { viewModel = makeVM() }
            vm.loadUnit(unitId)
        }
    }

    private func editBinding(_ keyPath: WritableKeyPath<UnitEditState, String>) -> Binding<String> {
        guard let vm = viewModel else {
            return .constant("")
        }
        return Binding(
            get: { vm.editState[keyPath: keyPath] },
            set: { newValue in vm.updateField { $0[keyPath: keyPath] = newValue } }
        )
    }

    private func makeVM() -> UnitDetailViewModel {
        let vm = UnitDetailViewModel(unitRepo: appState.unitRepository, authService: appState.authService)
        viewModel = vm
        return vm
    }
}

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(AppColors.primary)
    }
}

struct ChangeHistorySection: View {
    let history: [AuditLog]
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                withAnimation { expanded.toggle() }
            } label: {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.caption)
                    Text("Change History (\(history.count))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .foregroundStyle(AppColors.onSurfaceVariant)
            }

            if expanded {
                if history.isEmpty {
                    Text("No history available")
                        .font(.caption)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                } else {
                    ForEach(history.prefix(20)) { log in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text("\(log.actor) (\(log.action))")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                Spacer()
                                Text(formatDisplayDateTime(log.at))
                                    .font(.caption2)
                                    .foregroundStyle(AppColors.onSurfaceVariant)
                            }
                            ForEach(log.changes.indices, id: \.self) { i in
                                let change = log.changes[i]
                                Text("\(change.field): \(change.from.isEmpty ? "(empty)" : change.from) → \(change.to.isEmpty ? "(empty)" : change.to)")
                                    .font(.caption2)
                                    .foregroundStyle(AppColors.onSurfaceVariant)
                            }
                        }
                        .padding(8)
                        .background(AppColors.surfaceVariant.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
        }
    }
}
