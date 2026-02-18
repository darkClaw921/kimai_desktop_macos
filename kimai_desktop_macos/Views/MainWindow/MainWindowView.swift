import SwiftUI

struct MainWindowView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedSidebarItem: SidebarItem? = .dashboard

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selectedSidebarItem)
        } detail: {
            switch selectedSidebarItem {
            case .dashboard:
                DashboardView()
            case .history:
                TimesheetHistoryView()
            case .projects:
                ProjectDetailView()
            case nil:
                ContentUnavailableView(
                    "Выберите раздел",
                    systemImage: "sidebar.left",
                    description: Text("Выберите раздел в боковой панели.")
                )
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .task {
            guard appState.isConfigured else { return }
            appState.startPolling()
            await appState.loadProjects()
        }
    }
}
