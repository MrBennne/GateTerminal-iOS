import SwiftUI

struct DrawerView: View {
    @Bindable var viewModel: UnitListViewModel
    let onListManagement: () -> Void
    let onSettings: () -> Void
    let onAppearance: () -> Void
    let onLogout: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            List {
                // User info
                if let user = viewModel.currentUser {
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: "person.circle.fill")
                                .font(.title)
                                .foregroundStyle(.cyan)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.username)
                                    .font(.headline)
                                Text(user.normalizedRole())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)
                                if let email = user.email, !email.isEmpty {
                                    Text(email)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }
                }

                // Connection status
                Section {
                    HStack {
                        Text("Connection")
                        Spacer()
                        HStack(spacing: 4) {
                            Circle()
                                .fill(viewModel.connectionState == .connected ? .green :
                                      viewModel.connectionState == .reconnecting ? .orange : .red)
                                .frame(width: 8, height: 8)
                            Text(viewModel.connectionState.rawValue.capitalized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Booking lists
                Section("Booking Lists") {
                    ForEach(viewModel.lists) { list in
                        Button {
                            viewModel.selectedListId = list.id
                            onDismiss()
                        } label: {
                            HStack {
                                Text(list.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if viewModel.selectedListId == list.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.cyan)
                                }
                                let count = viewModel.allUnits.filter { unit in
                                    unit.bookingListIds.contains(list.id) || unit.bookingListId == list.id
                                }.count
                                Text("\(count)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Button {
                        onListManagement()
                    } label: {
                        Label("Manage Lists", systemImage: "list.clipboard")
                    }
                }

                // View mode
                Section("View Mode") {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Button {
                            viewModel.viewMode = mode
                            onDismiss()
                        } label: {
                            HStack {
                                Image(systemName: mode == .defaultMode ? "list.bullet" : "square.grid.2x2")
                                    .foregroundStyle(.cyan)
                                Text(mode.label)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if viewModel.viewMode == mode {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.cyan)
                                }
                            }
                        }
                    }
                }

                // Settings
                Section {
                    Button {
                        onAppearance()
                    } label: {
                        Label("Appearance", systemImage: "paintbrush")
                    }

                    Button {
                        onSettings()
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }

                // Logout
                Section {
                    Button(role: .destructive) {
                        onLogout()
                    } label: {
                        Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onDismiss() }
                }
            }
        }
    }
}
