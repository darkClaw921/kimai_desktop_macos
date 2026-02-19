import SwiftUI

struct MainWindowView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedSidebarItem: SidebarItem? = .dashboard

    var body: some View {
        @Bindable var appState = appState

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
        .sheet(isPresented: Binding(
            get: { appState.timesheetToRestart != nil },
            set: { if !$0 { appState.timesheetToRestart = nil } }
        )) {
            RestartDescriptionView()
                .frame(width: 350)
                .padding()
        }
        .task {
            guard appState.isConfigured else { return }
            appState.startPolling()
            await appState.loadProjects()
        }
    }
}
