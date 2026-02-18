import SwiftUI

@main
struct kimai_desktop_macosApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        // Main Window
        WindowGroup {
            MainWindowView()
                .environment(appState)
        }
        .defaultSize(width: 900, height: 600)

        // Menu Bar
        MenuBarExtra {
            MenuBarPopover()
                .environment(appState)
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)

        // Settings
        Settings {
            SettingsView()
                .environment(appState)
        }
    }

    private var menuBarLabel: some View {
        HStack(spacing: 4) {
            Image(systemName: appState.isTracking ? "clock.badge.checkmark" : "clock")
                .symbolEffect(.pulse, isActive: appState.isTracking)

            if appState.isTracking {
                Text(appState.timerService.formattedElapsed)
                    .font(.system(.caption, design: .monospaced))
                    .monospacedDigit()
            }
        }
    }
}
