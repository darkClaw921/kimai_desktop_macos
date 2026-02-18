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
        }
        .frame(width: 450, height: 300)
    }
}
