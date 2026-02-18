import SwiftUI

struct MenuBarFooterView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack {
            StatusIndicator(
                status: appState.isTracking ? .tracking :
                    (appState.isConnected ? .online : .offline)
            )

            Spacer()

            Button("Открыть окно") {
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.tint)

            Divider()
                .frame(height: 12)

            SettingsLink {
                Text("Настройки")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.tint)

            Divider()
                .frame(height: 12)

            Button("Выход") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .font(.caption)
    }
}
