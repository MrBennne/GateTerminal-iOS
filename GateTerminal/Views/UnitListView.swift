import SwiftUI

struct UnitListView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: UnitListViewModel?
    @State private var showSearch = false
    @State private var showNewArrival = false
    @State private var showUnitDetail: GateUnit?
    @State private var showBulkEdit = false
    @State private var showLogoutConfirm = false
    @State private var showDrawer = false
    @State private var quickStatusUnit: GateUnit?
    @State private var quickDeckUnit: GateUnit?
    @State private var quickTraUnit: GateUnit?
    @State private var imoStickerUnit: GateUnit?
    @State private var imoStickerSkipQuestion = false
    @State private var etaPromptUnit: GateUnit?
    @State private var dfdsNoteUnit: GateUnit?
    @State private var pendingChainStep2: (String, ShortcutAction)?
    @State private var expandedDecks: [String: Bool] = [:]

    let onNavigateToListManagement: () -> Void
    let onNavigateToSettings: () -> Void
    let onNavigateToAppearance: () -> Void
    let onLogout: () -> Void

    var body: some View {
        let vm = viewModel ?? makeVM()

        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Connection status
                ConnectionStatusBar(connectionState: vm.connectionState)

                // Search bar
                if showSearch {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppColors.onSurfaceVariant)
                        TextField("Search units...", text: Binding(get: { vm.search }, set: { vm.search = $0 }))
                            .textFieldStyle(.plain)
                            .foregroundStyle(AppColors.onSurface)
                        if !vm.search.isEmpty {
                            Button { vm.search = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(AppColors.onSurfaceVariant)
                            }
                        }
                    }
                    .padding(8)
                    .background(AppColors.surfaceVariant)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                }

                // Main content
                let isDeckMode = vm.viewMode == .deck
                let mainGroups: [UnitGroup] = isDeckMode ?
                    vm.visibleUnits.map { group in
                        UnitGroup(label: group.label, units: group.units.filter { $0.parsedStatus != .loaded })
                    } : vm.visibleUnits

                if mainGroups.allSatisfy({ $0.units.isEmpty }) && (!isDeckMode || vm.deckGroupedUnits.allSatisfy({ $0.units.isEmpty })) {
                    Spacer()
                    Text(vm.isLoading ? "Loading units..." : "No units found")
                        .foregroundStyle(AppColors.onSurfaceVariant)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(mainGroups) { group in
                                if !group.label.isEmpty && !group.units.isEmpty {
                                    HStack {
                                        Text("\(group.label) (\(group.units.count))")
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundStyle(AppColors.primary)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.top, 8)
                                }

                                ForEach(group.units) { unit in
                                    unitCardWithGestures(unit: unit, vm: vm)
                                }
                            }

                            // Deck grouped loaded units
                            if isDeckMode {
                                let deckGroups = vm.deckGroupedUnits
                                if deckGroups.contains(where: { !$0.units.isEmpty }) {
                                    Divider()
                                        .overlay(AppColors.primary.opacity(0.3))
                                        .padding(.vertical, 8)

                                    ForEach(deckGroups) { deckGroup in
                                        if !deckGroup.units.isEmpty {
                                            let isExpanded = expandedDecks[deckGroup.label] ?? true

                                            Button {
                                                withAnimation { expandedDecks[deckGroup.label] = !isExpanded }
                                            } label: {
                                                HStack {
                                                    Image(systemName: "ferry")
                                                        .foregroundStyle(AppColors.primary)
                                                    Text("\(deckGroup.label) (\(deckGroup.units.count))")
                                                        .font(.subheadline)
                                                        .fontWeight(.bold)
                                                        .foregroundStyle(AppColors.primary)
                                                    Spacer()
                                                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                                        .foregroundStyle(AppColors.onSurfaceVariant)
                                                }
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 4)

                                            if isExpanded {
                                                ForEach(deckGroup.units) { unit in
                                                    unitCardWithGestures(unit: unit, vm: vm)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.bottom, vm.bulkMode ? 80 : 0)
                    }
                    .refreshable {
                        await appState.unitRepository.refresh()
                    }
                }
            }

            // FAB
            if vm.permissions.canEditUnits && !vm.bulkMode {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showNewArrival = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .background(AppColors.primary)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                    }
                }
            }

            // Bulk mode bottom bar
            if vm.bulkMode {
                VStack {
                    Spacer()
                    BulkActionsBar(
                        selectedCount: vm.selectedIds.count,
                        onSelectAll: { vm.selectAll() },
                        onClearSelection: { vm.clearSelection() },
                        onBulkEdit: { showBulkEdit = true },
                        canBulkEdit: vm.permissions.canBulkEdit
                    )
                }
            }

            // Drawer overlay
            if showDrawer {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { showDrawer = false }

                HStack {
                    DrawerView(
                        vm: vm,
                        onNavigateToSettings: {
                            showDrawer = false
                            onNavigateToSettings()
                        },
                        onNavigateToAppearance: {
                            showDrawer = false
                            onNavigateToAppearance()
                        },
                        onNavigateToListManagement: {
                            showDrawer = false
                            onNavigateToListManagement()
                        },
                        onLogout: {
                            showDrawer = false
                            showLogoutConfirm = true
                        },
                        onClose: { showDrawer = false }
                    )
                    Spacer()
                }
                .transition(.move(edge: .leading))
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { withAnimation { showDrawer.toggle() } } label: {
                    Image(systemName: "line.3.horizontal")
                }
            }
            ToolbarItem(placement: .principal) {
                ListSwitcherDropdown(
                    lists: vm.lists,
                    allUnits: vm.allUnits,
                    selectedListId: Binding(get: { vm.selectedListId }, set: { vm.selectedListId = $0 })
                )
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Text("\(vm.totalVisibleCount)")
                    .font(.caption)
                    .foregroundStyle(AppColors.onSurfaceVariant)
                Button { showSearch.toggle() } label: {
                    Image(systemName: "magnifyingglass")
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel == nil { viewModel = makeVM() }
            vm.onForeground()
            vm.autoSelectList()
        }
        .onDisappear { vm.onBackground() }
        .sheet(item: $showUnitDetail) { unit in
            UnitDetailSheet(unitId: unit.id)
        }
        .sheet(isPresented: $showNewArrival) {
            NewArrivalSheet(selectedListId: vm.selectedListId) {
                showNewArrival = false
            }
        }
        .sheet(isPresented: $showBulkEdit) {
            BulkEditSheet(selectedIds: vm.selectedIds) {
                showBulkEdit = false
                vm.clearSelection()
            }
        }
        .alert("Logout", isPresented: $showLogoutConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Logout", role: .destructive) { vm.logout(); onLogout() }
        } message: {
            Text("Are you sure you want to log out?")
        }
        // Quick dialogs
        .sheet(item: $quickStatusUnit) { unit in
            QuickStatusPickerSheet(unit: unit) { status in
                quickStatusUnit = nil
                if status == .hasEta {
                    etaPromptUnit = unit
                } else if status == .ready && (unit.isImo || !unit.imoClass.isEmpty) {
                    vm.quickSetStatus(unit.id, status)
                    imoStickerSkipQuestion = false
                    imoStickerUnit = unit
                } else {
                    vm.quickSetStatus(unit.id, status)
                    completePendingChain(vm: vm)
                }
            } onDismiss: {
                quickStatusUnit = nil
                pendingChainStep2 = nil
            }
        }
        .sheet(item: $quickDeckUnit) { unit in
            QuickDeckLocationSheet(unit: unit) { loc in
                vm.quickSetDeckLocation(unit.id, loc)
                quickDeckUnit = nil
                completePendingChain(vm: vm)
            } onDismiss: {
                quickDeckUnit = nil
                pendingChainStep2 = nil
            }
        }
        .sheet(item: $quickTraUnit) { unit in
            QuickTraLocationSheet(unit: unit) { loc in
                vm.quickSetTraLocation(unit.id, loc)
                quickTraUnit = nil
                completePendingChain(vm: vm)
            } onDismiss: {
                quickTraUnit = nil
                pendingChainStep2 = nil
            }
        }
        .sheet(item: $imoStickerUnit) { unit in
            ImoStickerSheet(unit: unit, skipQuestion: imoStickerSkipQuestion) { stickerNote in
                if let note = stickerNote {
                    vm.quickSetStickerNote(unit.id, note)
                }
                imoStickerUnit = nil
                completePendingChain(vm: vm)
            } onDismiss: {
                imoStickerUnit = nil
                pendingChainStep2 = nil
            }
        }
        .sheet(item: $etaPromptUnit) { unit in
            EtaTimeSheet(unit: unit) { etaTime in
                vm.quickSetStatusWithEta(unit.id, etaTime)
                etaPromptUnit = nil
                completePendingChain(vm: vm)
            } onDismiss: {
                etaPromptUnit = nil
                pendingChainStep2 = nil
            }
        }
        .sheet(item: $dfdsNoteUnit) { unit in
            DfdsNoteSheet(unit: unit) { note in
                vm.quickSetDfdsNote(unit.id, note)
                dfdsNoteUnit = nil
            } onDismiss: {
                dfdsNoteUnit = nil
            }
        }
    }

    // MARK: - Card with gestures

    @ViewBuilder
    private func unitCardWithGestures(unit: GateUnit, vm: UnitListViewModel) -> some View {
        let shortcuts = vm.roleShortcuts

        UnitCard(
            unit: unit,
            isSelected: vm.selectedIds.contains(unit.id),
            isBulkMode: vm.bulkMode,
            onDfdsNoteEdit: vm.permissions.canEditUnits ? { dfdsNoteUnit = $0 } : nil
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if vm.bulkMode {
                vm.toggleSelection(unit.id)
            } else {
                executeGesture(shortcuts.tap, unit: unit, vm: vm)
            }
        }
        .onLongPressGesture {
            if !vm.bulkMode && shortcuts.longPress.step1 != .none {
                executeGesture(shortcuts.longPress, unit: unit, vm: vm)
            } else if vm.permissions.canBulkActions {
                vm.enterBulkMode(unit.id)
            }
        }
        .swipeActions(edge: .leading) {
            if shortcuts.swipeRight.step1 != .none {
                Button {
                    executeGesture(shortcuts.swipeRight, unit: unit, vm: vm)
                } label: {
                    Image(systemName: "arrow.right")
                }
                .tint(AppColors.primary)
            }
        }
        .swipeActions(edge: .trailing) {
            if shortcuts.swipeLeft.step1 != .none {
                Button {
                    executeGesture(shortcuts.swipeLeft, unit: unit, vm: vm)
                } label: {
                    Image(systemName: "arrow.left")
                }
                .tint(AppColors.secondary)
            }
        }
    }

    // MARK: - Gesture execution

    private func executeSingleAction(_ action: ShortcutAction, unit: GateUnit, vm: UnitListViewModel) -> Bool {
        switch action {
        case .none: return false
        case .openDetails, .editUnit:
            showUnitDetail = unit
            return false
        case .editDfds:
            dfdsNoteUnit = unit
            return true
        case .statusPicker:
            quickStatusUnit = unit
            return true
        case .deckLocation:
            quickDeckUnit = unit
            return true
        case .traLocation:
            quickTraUnit = unit
            return true
        case .setTraExport:
            vm.quickSetTraLocation(unit.id, "Export")
            return false
        case .imoSticker:
            if unit.isImo || !unit.imoClass.isEmpty {
                imoStickerSkipQuestion = true
                imoStickerUnit = unit
                return true
            }
            return false
        case .bulkSelect:
            vm.enterBulkMode(unit.id)
            return false
        case .setHasEta:
            etaPromptUnit = unit
            return true
        default:
            if action.isDirectStatus {
                vm.quickSetDirectStatus(unit.id, action)
                if action == .setReady && (unit.isImo || !unit.imoClass.isEmpty) {
                    imoStickerSkipQuestion = false
                    imoStickerUnit = unit
                    return true
                }
            }
            return false
        }
    }

    private func executeGesture(_ gesture: GestureShortcut, unit: GateUnit, vm: UnitListViewModel) {
        guard gesture.step1 != .none else { return }
        if showSearch { showSearch = false; vm.search = "" }
        let deferred = executeSingleAction(gesture.step1, unit: unit, vm: vm)
        if gesture.step2 != .none {
            if deferred {
                pendingChainStep2 = (unit.id, gesture.step2)
            } else {
                _ = executeSingleAction(gesture.step2, unit: unit, vm: vm)
            }
        }
    }

    private func completePendingChain(vm: UnitListViewModel) {
        guard let (unitId, step2) = pendingChainStep2 else { return }
        pendingChainStep2 = nil
        guard let freshUnit = vm.getUnit(unitId) else { return }
        _ = executeSingleAction(step2, unit: freshUnit, vm: vm)
    }

    private func makeVM() -> UnitListViewModel {
        let vm = UnitListViewModel(
            unitRepo: appState.unitRepository,
            authService: appState.authService,
            shortcutPrefs: appState.shortcutPreferences
        )
        viewModel = vm
        return vm
    }
}
