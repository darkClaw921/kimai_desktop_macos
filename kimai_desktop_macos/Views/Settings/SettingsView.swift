import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            ConnectionSettingsView()
                .tabItem {
                    Label("Подключение", systemImage: "network")
                }

            GeneralSettingsView()
                .tabItem {
                    Label("Основные", systemImage: "gearshape")
                }

            AgentSettingsView()
                .tabItem {
                    Label("Агент", systemImage: "terminal")
                }
        }
        .frame(width: 450, height: 500)
    }
}
