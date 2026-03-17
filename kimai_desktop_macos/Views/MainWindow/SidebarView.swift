import SwiftUI

enum SidebarItem: String, Hashable, CaseIterable {
    case dashboard = "Обзор"
    case history = "История"
    case projects = "Проекты"
    case events = "События"

    var icon: String {
        switch self {
        case .dashboard: "gauge.with.dots.needle.33percent"
        case .history: "clock.arrow.circlepath"
        case .projects: "folder"
        case .events: "bell"
        }
    }
}

struct SidebarView: View {
    @Binding var selection: SidebarItem?
    @Environment(AppState.self) private var appState

    var body: some View {
        List(SidebarItem.allCases, id: \.self, selection: $selection) { item in
            Label(item.rawValue, systemImage: item.icon)
                .badge(item == .events ? appState.eventStore.pendingCount : 0)
        }
        .navigationTitle("Kimai")
    }
}
