import SwiftUI

struct BulkEditSheet: View {
    let selectedCount: Int
    let onApply: (UnitStatus) -> Void
    let onCancel: () -> Void

    @State private var selectedStatus: UnitStatus = .ready

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Count header
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                    Text("\(selectedCount) units selected")
                        .font(.headline)
                }
                .padding(.top)

                Divider()

                // Status picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Set Status")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(UnitStatus.allCases, id: \.self) { status in
                            Button {
                                selectedStatus = status
                            } label: {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(status.color)
                                        .frame(width: 10, height: 10)
                                    Text(status.label)
                                        .font(.caption)
                                        .fontWeight(selectedStatus == status ? .bold : .regular)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 10)
                                .background(
                                    selectedStatus == status
                                        ? status.color.opacity(0.2)
                                        : Color(.systemGray6)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(
                                            selectedStatus == status ? status.color : .clear,
                                            lineWidth: 1.5
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Actions
                VStack(spacing: 10) {
                    Button {
                        onApply(selectedStatus)
                    } label: {
                        Text("Apply to \(selectedCount) Units")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(selectedStatus.color)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    Button("Cancel", role: .cancel) {
                        onCancel()
                    }
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Bulk Edit")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
