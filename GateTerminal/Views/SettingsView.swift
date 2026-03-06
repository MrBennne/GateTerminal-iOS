import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: UnitListViewModel
    @Environment(\.dismiss) private var dismiss

    @AppStorage("pocketbase_url") private var serverUrl = "https://your-pocketbase.com"
    @State private var showingUrlEdit = false
    @State private var editUrl = ""

    var body: some View {
        NavigationStack {
            List {
                // Server
                Section("Server") {
                    HStack {
                        Text("PocketBase URL")
                        Spacer()
                        Text(serverUrl)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .onTapGesture {
                        editUrl = serverUrl
                        showingUrlEdit = true
                    }
                }

                // Permissions
                if let permissions = viewModel.permissions {
                    Section("Your Permissions") {
                        permRow("Edit Units", permissions.canEditUnits)
                        permRow("Change Status", permissions.canChangeStatus)
                        permRow("Edit Deck Location", permissions.canEditDeckLocation)
                        permRow("Edit TRA Location", permissions.canEditTraLocation)
                        permRow("Edit Drivers", permissions.canEditDrivers)
                        permRow("Edit DFDS Notes", permissions.canEditDFDS)
                        permRow("Create Units", permissions.canCreateUnits)
                        permRow("Delete Units", permissions.canDeleteUnits)
                    }
                }

                // Gesture shortcuts
                Section("Gesture Shortcuts") {
                    let shortcuts = viewModel.roleShortcuts
                    shortcutRow("Tap", shortcuts.tap)
                    shortcutRow("Long Press", shortcuts.longPress)
                    shortcutRow("Swipe Left", shortcuts.swipeLeft)
                    shortcutRow("Swipe Right", shortcuts.swipeRight)
                }

                // Info
                Section("About") {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Platform")
                        Spacer()
                        Text("iOS (SwiftUI)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Backend")
                        Spacer()
                        Text("PocketBase")
                            .foregroundStyle(.secondary)
                    }
                }

                // Danger zone
                Section {
                    Button(role: .destructive) {
                        viewModel.logout()
                    } label: {
                        Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Server URL", isPresented: $showingUrlEdit) {
                TextField("https://...", text: $editUrl)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Save") {
                    serverUrl = editUrl
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Change the PocketBase server URL. You'll need to log in again.")
            }
        }
    }

    private func permRow(_ label: String, _ enabled: Bool) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Image(systemName: enabled ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundStyle(enabled ? .green : .red.opacity(0.5))
                .font(.caption)
        }
    }

    private func shortcutRow(_ gesture: String, _ shortcut: GestureShortcut?) -> some View {
        HStack {
            Text(gesture)
                .font(.subheadline)
            Spacer()
            if let shortcut {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(shortcut.step1.label)
                        .font(.caption2)
                        .foregroundStyle(.cyan)
                    if let step2 = shortcut.step2 {
                        Text("→ \(step2.label)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text("Not set")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
