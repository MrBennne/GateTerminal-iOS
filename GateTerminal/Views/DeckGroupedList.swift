import SwiftUI

struct DeckGroupedList: View {
    let groups: [UnitGroup]
    let isRefreshing: Bool
    let onRefresh: () -> Void
    let onCardClick: (GateUnit) -> Void
    var onCardLongClick: ((GateUnit) -> Void)? = nil
    var onSwipeLeft: ((GateUnit) -> Void)? = nil
    var onSwipeRight: ((GateUnit) -> Void)? = nil
    var selectedIds: Set<String> = []
    var isBulkMode: Bool = false

    @State private var expandedSections: Set<String> = []
    @State private var initialized = false

    var body: some View {
        ScrollView {
            if groups.isEmpty || groups.allSatisfy({ $0.units.isEmpty }) {
                VStack(spacing: 12) {
                    Spacer().frame(height: 100)
                    Text("No loaded units")
                        .foregroundStyle(.secondary)
                        .font(.body)
                }
                .frame(maxWidth: .infinity)
            } else {
                LazyVStack(spacing: 4, pinnedViews: [.sectionHeaders]) {
                    ForEach(groups) { group in
                        Section {
                            if expandedSections.contains(group.label) {
                                ForEach(group.units) { unit in
                                    UnitCard(
                                        unit: unit,
                                        onClick: { onCardClick(unit) },
                                        onLongClick: onCardLongClick.map { cb in { cb(unit) } },
                                        onSwipeLeft: onSwipeLeft.map { cb in { cb(unit) } },
                                        onSwipeRight: onSwipeRight.map { cb in { cb(unit) } },
                                        isSelected: selectedIds.contains(unit.id),
                                        isBulkMode: isBulkMode
                                    )
                                }
                            }
                        } header: {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if expandedSections.contains(group.label) {
                                        expandedSections.remove(group.label)
                                    } else {
                                        expandedSections.insert(group.label)
                                    }
                                }
                            } label: {
                                HStack {
                                    Text("\(group.label) (\(group.units.count))")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundStyle(Color.accentColor)
                                    Spacer()
                                    Image(systemName: expandedSections.contains(group.label) ? "chevron.up" : "chevron.down")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .refreshable { onRefresh() }
        .onAppear {
            if !initialized {
                expandedSections = Set(groups.map(\.label))
                initialized = true
            }
        }
        .onChange(of: groups) { _, newGroups in
            for group in newGroups where !expandedSections.contains(group.label) {
                expandedSections.insert(group.label)
            }
        }
    }
}
