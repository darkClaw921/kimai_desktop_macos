import SwiftUI

enum SidebarItem: String, Hashable, CaseIterable {
    case dashboard = "Обзор"
    case history = "История"
    case projects = "Проекты"

    var icon: String {
        switch self {
        case .dashboard: "gauge.with.dots.needle.33percent"
        case .history: "clock.arrow.circlepath"
        case .projects: "folder"
        }
    }
}

struct SidebarView: View {
    @Binding var selection: SidebarItem?

    var body: some View {
        List(SidebarItem.allCases, id: \.self, selection: $selection) { item in
            Label(item.rawValue, systemImage: item.icon)
        }
        .navigationTitle("Kimai")
    }
}
