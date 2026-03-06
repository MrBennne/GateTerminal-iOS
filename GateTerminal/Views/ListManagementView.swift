import SwiftUI

struct ListManagementView: View {
    @Bindable var viewModel: UnitListViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showingNewList = false
    @State private var newListName = ""
    @State private var renamingList: BookingList?
    @State private var renameText = ""
    @State private var deletingList: BookingList?
    @State private var editingTypeOrder: BookingList?
    @State private var typeOrderText = ""
    @State private var error: String?

    var body: some View {
        NavigationStack {
            List {
                if viewModel.lists.isEmpty {
                    Section {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "list.clipboard")
                                    .font(.title)
                                    .foregroundStyle(.secondary)
                                Text("No booking lists")
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 20)
                    }
                }

                ForEach(viewModel.lists) { list in
                    Section {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(list.name)
                                    .font(.headline)

                                let unitCount = viewModel.allUnits.filter { unit in
                                    unit.bookingListIds.contains(list.id) || unit.bookingListId == list.id
                                }.count
                                Text("\(unitCount) units")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if !list.typeOrder.isEmpty {
                                    Text("Type order: \(list.typeOrder)")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            Spacer()

                            if viewModel.selectedListId == list.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.selectedListId = list.id
                        }

                        // Actions
                        HStack(spacing: 12) {
                            Button {
                                renameText = list.name
                                renamingList = list
                            } label: {
                                Label("Rename", systemImage: "pencil")
                                    .font(.caption)
                            }

                            Button {
                                typeOrderText = list.typeOrder
                                editingTypeOrder = list
                            } label: {
                                Label("Type Order", systemImage: "arrow.up.arrow.down")
                                    .font(.caption)
                            }

                            Spacer()

                            Button(role: .destructive) {
                                deletingList = list
                            } label: {
                                Label("Delete", systemImage: "trash")
                                    .font(.caption)
                            }
                        }
                    }
                }

                if let error {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Booking Lists")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        newListName = ""
                        showingNewList = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("New Booking List", isPresented: $showingNewList) {
                TextField("List name", text: $newListName)
                Button("Create") {
                    guard !newListName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    Task {
                        let result = await viewModel.unitRepo.createList(name: newListName)
                        if case .failure(let err) = result {
                            error = err.localizedDescription
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Rename List", isPresented: Binding(
                get: { renamingList != nil },
                set: { if !$0 { renamingList = nil } }
            )) {
                TextField("New name", text: $renameText)
                Button("Rename") {
                    guard let list = renamingList else { return }
                    Task {
                        let result = await viewModel.unitRepo.renameList(id: list.id, name: renameText)
                        if case .failure(let err) = result {
                            error = err.localizedDescription
                        }
                        renamingList = nil
                    }
                }
                Button("Cancel", role: .cancel) { renamingList = nil }
            }
            .alert("Delete List?", isPresented: Binding(
                get: { deletingList != nil },
                set: { if !$0 { deletingList = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    guard let list = deletingList else { return }
                    Task {
                        let result = await viewModel.unitRepo.deleteList(id: list.id)
                        if case .failure(let err) = result {
                            error = err.localizedDescription
                        }
                        deletingList = nil
                    }
                }
                Button("Cancel", role: .cancel) { deletingList = nil }
            } message: {
                Text("This will permanently delete \"\(deletingList?.name ?? "")\".")
            }
            .alert("Type Order", isPresented: Binding(
                get: { editingTypeOrder != nil },
                set: { if !$0 { editingTypeOrder = nil } }
            )) {
                TextField("e.g. CON40,T/T,MAFI", text: $typeOrderText)
                Button("Save") {
                    guard let list = editingTypeOrder else { return }
                    Task {
                        let result = await viewModel.unitRepo.saveTypeOrder(listId: list.id, order: typeOrderText)
                        if case .failure(let err) = result {
                            error = err.localizedDescription
                        }
                        editingTypeOrder = nil
                    }
                }
                Button("Cancel", role: .cancel) { editingTypeOrder = nil }
            } message: {
                Text("Comma-separated type display order")
            }
        }
    }
}
