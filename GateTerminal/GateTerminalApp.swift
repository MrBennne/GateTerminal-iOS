import SwiftUI

@main
struct GateTerminalApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .preferredColorScheme(appState.appearanceSettings.darkMode ? .dark : .light)
        }
    }
}

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if appState.authService.isLoggedIn {
            MainNavigationView()
        } else {
            LoginView()
        }
    }
}

struct MainNavigationView: View {
    @Environment(AppState.self) private var appState
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            UnitListView(
                onNavigateToListManagement: { path.append(Route.listManagement) },
                onNavigateToSettings: { path.append(Route.settings) },
                onNavigateToAppearance: { path.append(Route.appearance) },
                onLogout: { appState.authService.logout() }
            )
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .listManagement:
                    ListManagementView()
                case .settings:
                    SettingsView(onLogout: { appState.authService.logout() })
                case .appearance:
                    AppearanceView()
                }
            }
        }
        .tint(AppColors.primary)
    }
}

enum Route: Hashable {
    case listManagement
    case settings
    case appearance
}
