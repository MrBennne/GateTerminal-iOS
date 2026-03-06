import SwiftUI

struct AppearanceView: View {
    @AppStorage("cardDensity") private var cardDensity: String = "normal"
    @AppStorage("fontScale") private var fontScale: Double = 1.0
    @AppStorage("showRefNo") private var showRefNo = true
    @AppStorage("showCarrier") private var showCarrier = true
    @AppStorage("showLocations") private var showLocations = true
    @AppStorage("showTimes") private var showTimes = true
    @AppStorage("showTypeBadge") private var showTypeBadge = true
    @AppStorage("showNotes") private var showNotes = true
    @AppStorage("colorTheme") private var colorTheme: String = "default"
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Card density
                Section("Card Density") {
                    Picker("Density", selection: $cardDensity) {
                        Text("Compact").tag("compact")
                        Text("Normal").tag("normal")
                        Text("Comfortable").tag("comfortable")
                    }
                    .pickerStyle(.segmented)
                }

                // Color theme
                Section("Color Theme") {
                    Picker("Theme", selection: $colorTheme) {
                        Text("Default").tag("default")
                        Text("High Contrast").tag("highContrast")
                        Text("Muted").tag("muted")
                    }
                    .pickerStyle(.segmented)
                }

                // Font scale
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Font Scale")
                            Spacer()
                            Text(String(format: "%.0f%%", fontScale * 100))
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                        Slider(value: $fontScale, in: 0.8...1.4, step: 0.1)
                    }

                    // Preview
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Preview")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("MSKU1234567")
                            .font(.system(size: 16 * fontScale))
                            .fontWeight(.bold)
                        Text("REF-001 · DFDS")
                            .font(.system(size: 12 * fontScale))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                // Visible fields
                Section("Visible Fields") {
                    Toggle("Ref No", isOn: $showRefNo)
                    Toggle("Carrier", isOn: $showCarrier)
                    Toggle("Locations (Deck/TRA)", isOn: $showLocations)
                    Toggle("Times (Arrival/ETA/Loaded)", isOn: $showTimes)
                    Toggle("Type Badge", isOn: $showTypeBadge)
                    Toggle("Expandable Notes", isOn: $showNotes)
                }

                // Reset
                Section {
                    Button("Reset to Defaults") {
                        cardDensity = "normal"
                        fontScale = 1.0
                        showRefNo = true
                        showCarrier = true
                        showLocations = true
                        showTimes = true
                        showTypeBadge = true
                        showNotes = true
                        colorTheme = "default"
                    }
                    .foregroundStyle(.orange)
                }
            }
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
