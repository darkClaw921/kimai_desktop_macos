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
                Text(menuBarTimerText)
                    .font(.system(.caption, design: .monospaced))
                    .monospacedDigit()
                    .frame(width: menuBarTextWidth, alignment: .leading)
            }
        }
    }

    /// Fixed width for menu bar text, rounded up to prevent constant resizing.
    /// Grows in steps when the text gets longer, never shrinks during a tracking session.
    private var menuBarTextWidth: CGFloat {
        let text = menuBarTimerText
        // Approximate width per monospaced caption character (~7pt)
        let charWidth: CGFloat = 7.0
        let baseWidth = CGFloat(text.count) * charWidth
        // Round up to nearest 20pt step to avoid frequent resizing
        return ceil(baseWidth / 20.0) * 20.0
    }

    private var menuBarTimerText: String {
        let time = appState.timerService.formattedElapsed
        if let earnings = appState.formattedEarnings {
            return "\(time) · \(earnings)"
        }
        return time
    }
}
