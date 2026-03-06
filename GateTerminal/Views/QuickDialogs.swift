import SwiftUI

// MARK: - Quick Status Picker

struct QuickStatusPickerSheet: View {
    let unit: GateUnit
    let onSelect: (UnitStatus) -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(UnitStatus.sorted) { status in
                    let isCurrent = status.key == unit.status
                    Button {
                        onSelect(status)
                    } label: {
                        HStack {
                            StatusDot(status: status, size: 14)
                            Text(status.label)
                                .fontWeight(isCurrent ? .bold : .regular)
                                .foregroundStyle(isCurrent ? status.color : AppColors.onSurface)
                            Spacer()
                            if isCurrent {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(status.color)
                            }
                        }
                    }
                }
            }
            .navigationTitle(unit.unitno.isEmpty ? "Change Status" : unit.unitno)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Quick Deck Location

struct QuickDeckLocationSheet: View {
    let unit: GateUnit
    let onSelect: (String) -> Void
    let onDismiss: () -> Void

    private let mainLocations: [(main: String, ramp: String?)] = [
        ("WD", "WD RAMP"),
        ("MD", nil),
        ("LH", "LH RAMP"),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                ForEach(mainLocations, id: \.main) { loc in
                    HStack(spacing: 8) {
                        deckButton(loc.main)
                        if let ramp = loc.ramp {
                            deckButton(ramp)
                                .frame(maxWidth: 140)
                        }
                    }
                }
                Spacer()
            }
            .padding(16)
            .navigationTitle("\(unit.unitno) - Deck Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    @ViewBuilder
    private func deckButton(_ location: String) -> some View {
        let isCurrent = location == unit.locationDeck
        Button {
            onSelect(location)
        } label: {
            HStack {
                Text(location)
                    .fontWeight(isCurrent ? .bold : .regular)
                if isCurrent {
                    Image(systemName: "checkmark")
                        .font(.caption)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isCurrent ? AppColors.primary.opacity(0.15) : AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(
                isCurrent ? AppColors.primary.opacity(0.5) : AppColors.outline.opacity(0.5), lineWidth: 1
            ))
        }
        .foregroundStyle(AppColors.onSurface)
    }
}

// MARK: - Quick TRA Location

struct QuickTraLocationSheet: View {
    let unit: GateUnit
    let onSelect: (String) -> Void
    let onDismiss: () -> Void
    @State private var customText = ""

    private let mainLocations = ["Import", "Export", "Farlig Gods Række"]
    private let quickLocations = ["Kaj 24", "Hal 1", "Hal 2", "Hal 3", "Hal 4", "Hal 5"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(mainLocations, id: \.self) { loc in
                        let isCurrent = loc == unit.locationTra
                        Button {
                            onSelect(loc)
                        } label: {
                            HStack {
                                Text(loc)
                                    .fontWeight(isCurrent ? .bold : .regular)
                                Spacer()
                                if isCurrent {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(AppColors.secondary)
                                }
                            }
                            .padding(12)
                            .background(isCurrent ? AppColors.secondary.opacity(0.15) : AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .foregroundStyle(AppColors.onSurface)
                    }

                    Divider()

                    Text("Quick locations")
                        .font(.caption)
                        .foregroundStyle(AppColors.onSurfaceVariant)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                        ForEach(quickLocations, id: \.self) { loc in
                            let isCurrent = loc == unit.locationTra
                            Button {
                                onSelect(loc)
                            } label: {
                                Text(loc)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(isCurrent ? AppColors.primary.opacity(0.2) : AppColors.surfaceVariant)
                                    .clipShape(Capsule())
                            }
                            .foregroundStyle(AppColors.onSurface)
                        }
                    }

                    Divider()

                    HStack {
                        TextField("Other location", text: $customText)
                            .textFieldStyle(.roundedBorder)
                        if !customText.trimmingCharacters(in: .whitespaces).isEmpty {
                            Button {
                                onSelect(customText.trimmingCharacters(in: .whitespaces))
                            } label: {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("\(unit.unitno) - TRA Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }
}

// MARK: - IMO Sticker Sheet

struct ImoStickerSheet: View {
    let unit: GateUnit
    var skipQuestion: Bool = false
    let onConfirm: (String?) -> Void
    let onDismiss: () -> Void

    @State private var step: Int
    @State private var showAllClasses = false
    @State private var selectedCounts: [String: Int] = [:]

    private static let allImoClasses = [
        "1", "1.1", "1.2", "1.3", "1.4", "1.5", "1.6",
        "2.1", "2.2", "2.3", "3", "4.1", "4.2", "4.3",
        "5.1", "5.2", "6.1", "6.2", "7", "8", "9", "LQ", "MP",
    ]
    private static let defaultStickerCount = 4

    init(unit: GateUnit, skipQuestion: Bool = false, onConfirm: @escaping (String?) -> Void, onDismiss: @escaping () -> Void) {
        self.unit = unit
        self.skipQuestion = skipQuestion
        self.onConfirm = onConfirm
        self.onDismiss = onDismiss
        _step = State(initialValue: skipQuestion ? 2 : 1)
    }

    private var unitClasses: [String] {
        guard !unit.imoClass.isEmpty else { return [] }
        let cleaned = unit.imoClass.replacingOccurrences(of: "class", with: "", options: .caseInsensitive).trimmingCharacters(in: .whitespaces)
        return cleaned.components(separatedBy: CharacterSet.alphanumerics.inverted.subtracting(CharacterSet(charactersIn: ".")))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { Self.allImoClasses.contains($0) }
    }

    var body: some View {
        NavigationStack {
            if step == 1 {
                VStack(spacing: 20) {
                    Text("Are all IMO stickers on the unit?")
                        .font(.body)

                    HStack(spacing: 16) {
                        Button("No") { step = 2 }
                            .buttonStyle(.bordered)
                            .frame(maxWidth: .infinity)
                        Button("Yes") { onConfirm(nil) }
                            .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(24)
                .navigationTitle("IMO Stickers")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { onDismiss() }
                    }
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select missing IMO classes. Default is \(Self.defaultStickerCount) stickers per class.")
                            .font(.caption)
                            .foregroundStyle(AppColors.onSurfaceVariant)

                        let visibleClasses = showAllClasses ? Self.allImoClasses : (unitClasses.isEmpty ? Self.allImoClasses : unitClasses)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 8) {
                            ForEach(visibleClasses, id: \.self) { cls in
                                let isSelected = selectedCounts[cls] != nil
                                Button {
                                    if isSelected { selectedCounts.removeValue(forKey: cls) }
                                    else { selectedCounts[cls] = Self.defaultStickerCount }
                                } label: {
                                    Text(cls)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(isSelected ? AppColors.primary.opacity(0.2) : AppColors.surfaceVariant)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(isSelected ? AppColors.primary : Color.clear, lineWidth: 1))
                                }
                                .foregroundStyle(AppColors.onSurface)
                            }
                        }

                        if !showAllClasses && !unitClasses.isEmpty {
                            Button("Show all IMO classes") { showAllClasses = true }
                                .font(.caption)
                        }

                        if !selectedCounts.isEmpty {
                            Divider()
                            ForEach(selectedCounts.keys.sorted(), id: \.self) { cls in
                                HStack {
                                    Text("Class \(cls)")
                                    Spacer()
                                    TextField("Count", value: Binding(
                                        get: { selectedCounts[cls] ?? Self.defaultStickerCount },
                                        set: { selectedCounts[cls] = $0 }
                                    ), format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 60)
                                    Button { selectedCounts.removeValue(forKey: cls) } label: {
                                        Image(systemName: "xmark")
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                }
                .navigationTitle("IMO Stickers")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Back") { step = 1 }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            let note = buildStickerNote(selectedCounts)
                            onConfirm(note)
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func buildStickerNote(_ classCounts: [String: Int]) -> String {
        let sorted = classCounts.filter { $0.value > 0 }.sorted { a, b in
            let av: Double = {
                switch a.key { case "LQ": return 100; case "MP": return 101; default: return Double(a.key) ?? 999 }
            }()
            let bv: Double = {
                switch b.key { case "LQ": return 100; case "MP": return 101; default: return Double(b.key) ?? 999 }
            }()
            return av < bv
        }
        guard !sorted.isEmpty else { return "" }
        return sorted.map { "\($0.value)xClass \($0.key)" }.joined(separator: ", ") + "."
    }
}

// MARK: - ETA Time Sheet

struct EtaTimeSheet: View {
    let unit: GateUnit
    let onConfirm: (String) -> Void
    let onDismiss: () -> Void
    @State private var timeText: String
    @FocusState private var focused: Bool

    init(unit: GateUnit, onConfirm: @escaping (String) -> Void, onDismiss: @escaping () -> Void) {
        self.unit = unit
        self.onConfirm = onConfirm
        self.onDismiss = onDismiss
        let existing = extractTimeComponent(unit.etaTime)
        if !existing.isEmpty {
            _timeText = State(initialValue: existing)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            _timeText = State(initialValue: formatter.string(from: Date()))
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Enter the expected arrival time (HH:MM)")
                    .font(.caption)
                    .foregroundStyle(AppColors.onSurfaceVariant)

                TextField("HH:MM", text: $timeText)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .focused($focused)

                Spacer()
            }
            .padding(24)
            .navigationTitle("\(unit.unitno) - ETA Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Set ETA") {
                        if let eta = buildEtaValue(timeText) {
                            onConfirm(eta)
                        }
                    }
                    .disabled(timeText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear { focused = true }
    }
}

// MARK: - DFDS Note Sheet

struct DfdsNoteSheet: View {
    let unit: GateUnit
    let onSave: (String) -> Void
    let onDismiss: () -> Void
    @State private var noteText: String
    @FocusState private var focused: Bool

    init(unit: GateUnit, onSave: @escaping (String) -> Void, onDismiss: @escaping () -> Void) {
        self.unit = unit
        self.onSave = onSave
        self.onDismiss = onDismiss
        _noteText = State(initialValue: unit.dfdsNote)
    }

    var body: some View {
        NavigationStack {
            TextEditor(text: $noteText)
                .padding(16)
                .focused($focused)
                .navigationTitle("\(unit.unitno) - DFDS Note")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { onDismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            onSave(noteText.trimmingCharacters(in: .whitespaces))
                        }
                    }
                }
        }
        .presentationDetents([.medium])
        .onAppear { focused = true }
    }
}
