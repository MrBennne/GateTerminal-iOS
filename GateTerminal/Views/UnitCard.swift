import SwiftUI

struct UnitCard: View {
    let unit: GateUnit
    var isSelected: Bool = false
    var isBulkMode: Bool = false
    var onDfdsNoteEdit: ((GateUnit) -> Void)?

    private var statusColor: Color { unit.parsedStatus.color }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Main row
            HStack(alignment: .top) {
                // Left column
                VStack(alignment: .leading, spacing: 2) {
                    // Ref + Unit number
                    HStack(spacing: 6) {
                        if !unit.refno.isEmpty {
                            Text(unit.refno)
                                .font(.caption)
                                .foregroundStyle(statusColor.opacity(0.85))
                        }
                        Text(unit.unitno)
                            .font(.callout)
                            .fontWeight(.bold)
                            .foregroundStyle(statusColor)
                    }

                    // Carrier
                    if !unit.carrier.isEmpty {
                        Text(unit.carrier)
                            .font(.caption)
                            .foregroundStyle(AppColors.onSurfaceVariant)
                    }

                    // Location
                    HStack(spacing: 8) {
                        if !unit.locationDeck.isEmpty {
                            Label(unit.locationDeck, systemImage: "mappin")
                                .font(.caption2)
                                .foregroundStyle(AppColors.primary)
                        }
                        if !unit.locationTra.isEmpty {
                            Label(unit.locationTra, systemImage: "arrow.triangle.swap")
                                .font(.caption2)
                                .foregroundStyle(AppColors.secondary)
                        }
                    }

                    // Times
                    HStack(spacing: 8) {
                        if !unit.arrivalTime.isEmpty {
                            Text("Arr: \(formatDisplayTime(unit.arrivalTime))")
                                .font(.caption2)
                                .foregroundStyle(AppColors.onSurfaceVariant)
                        }
                        if !unit.etaTime.isEmpty {
                            Text("ETA: \(formatDisplayTime(unit.etaTime))")
                                .font(.caption2)
                                .foregroundStyle(Color(hex: 0xF59E0B))
                        }
                    }
                }

                Spacer()

                // Right column
                VStack(alignment: .trailing, spacing: 4) {
                    // Status pill
                    Text(unit.parsedStatus.label)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(statusColor)

                    // Type badge
                    if !unit.type.isEmpty {
                        Text(unit.type)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(statusColor.opacity(0.15))
                            .overlay(Capsule().stroke(statusColor.opacity(0.5), lineWidth: 1))
                            .clipShape(Capsule())
                            .foregroundStyle(statusColor)
                    }

                    // Badges
                    HStack(spacing: 4) {
                        if unit.isImo || !unit.imoClass.isEmpty {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .foregroundStyle(AppColors.imoIcon)
                        }
                        if unit.isReefer {
                            Image(systemName: "snowflake")
                                .font(.caption2)
                                .foregroundStyle(AppColors.reeferIcon)
                        }
                    }

                    // Bulk mode checkbox
                    if isBulkMode {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(isSelected ? AppColors.primary : AppColors.onSurfaceVariant)
                    }
                }
            }

            // DFDS Note (flashing red)
            if !unit.dfdsNote.isEmpty {
                DfdsNoteView(note: unit.dfdsNote) {
                    onDfdsNoteEdit?(unit)
                }
            }

            // Notes (expandable)
            NotesSection(unit: unit)

            // MAFI Stack Children
            if !unit.stackChildren.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Divider().overlay(statusColor.opacity(0.3))
                    ForEach(unit.stackChildren) { child in
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.turn.down.right")
                                .font(.caption2)
                                .foregroundStyle(AppColors.onSurfaceVariant)
                            Text(child.unitno)
                                .font(.caption2)
                                .foregroundStyle(statusColor)
                            if !child.type.isEmpty {
                                Text(child.type)
                                    .font(.caption2)
                                    .foregroundStyle(AppColors.onSurfaceVariant)
                            }
                            Spacer()
                            Text(child.parsedStatus.label)
                                .font(.caption2)
                                .foregroundStyle(child.parsedStatus.color)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(statusColor.opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    isSelected ? AppColors.selectedBorder : statusColor.opacity(0.55),
                    lineWidth: isSelected ? 2 : 1.5
                )
        )
    }
}

struct DfdsNoteView: View {
    let note: String
    let onTap: () -> Void
    @State private var isFlashing = false

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.bubble.fill")
                .foregroundStyle(AppColors.error)
            Text(note)
                .font(.caption)
                .foregroundStyle(AppColors.error)
                .lineLimit(2)
            Spacer()
        }
        .padding(6)
        .background(AppColors.error.opacity(isFlashing ? 0.2 : 0.08))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .onTapGesture(perform: onTap)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isFlashing = true
            }
        }
    }
}

struct NotesSection: View {
    let unit: GateUnit
    @State private var expanded = false

    private var hasNotes: Bool {
        !unit.statusNote.isEmpty || !unit.customerNote.isEmpty ||
        !unit.stickerNote.isEmpty || !unit.handlingInstructions.isEmpty
    }

    var body: some View {
        if hasNotes {
            VStack(alignment: .leading, spacing: 2) {
                Button {
                    withAnimation { expanded.toggle() }
                } label: {
                    HStack {
                        Image(systemName: "note.text")
                            .font(.caption2)
                        Text("Notes")
                            .font(.caption2)
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundStyle(AppColors.onSurfaceVariant)
                }

                if expanded {
                    VStack(alignment: .leading, spacing: 2) {
                        if !unit.statusNote.isEmpty {
                            NoteRow(label: "Status", text: unit.statusNote)
                        }
                        if !unit.customerNote.isEmpty {
                            NoteRow(label: "Customer", text: unit.customerNote)
                        }
                        if !unit.stickerNote.isEmpty {
                            NoteRow(label: "Sticker", text: unit.stickerNote)
                        }
                        if !unit.handlingInstructions.isEmpty {
                            NoteRow(label: "Handling", text: unit.handlingInstructions)
                        }
                    }
                    .transition(.opacity)
                }
            }
        }
    }
}

struct NoteRow: View {
    let label: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            Text("\(label):")
                .font(.caption2)
                .foregroundStyle(AppColors.primary)
            Text(text)
                .font(.caption2)
                .foregroundStyle(AppColors.onSurfaceVariant)
                .lineLimit(3)
        }
    }
}
