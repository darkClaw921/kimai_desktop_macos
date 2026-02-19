import SwiftUI

struct MenuBarPopover: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 12) {
            if !appState.isConfigured {
                notConfiguredView
            } else {
                if appState.timesheetToRestart != nil {
                    #if compiler(>=6.2)
                    if #available(macOS 26.0, *) {
                        GlassEffectContainer {
                            RestartDescriptionView()
                        }
                    } else {
                        RestartDescriptionView()
                    }
                    #else
                    RestartDescriptionView()
                    #endif
                } else {
                    #if compiler(>=6.2)
                    if #available(macOS 26.0, *) {
                        GlassEffectContainer {
                            if let activeTimesheet = appState.activeTimesheet {
                                ActiveTimerView(timesheet: activeTimesheet)
                            } else {
                                QuickStartView()
                            }
                        }
                    } else {
                        if let activeTimesheet = appState.activeTimesheet {
                            ActiveTimerView(timesheet: activeTimesheet)
                        } else {
                            QuickStartView()
                        }
                    }
                    #else
                    if let activeTimesheet = appState.activeTimesheet {
                        ActiveTimerView(timesheet: activeTimesheet)
                    } else {
                        QuickStartView()
                    }
                    #endif
                }

                RecentTimesheetsView()
            }

            Divider()

            MenuBarFooterView()
        }
        .padding(16)
        .frame(width: 320)
        .task {
            if appState.isConfigured {
                appState.startPolling()
                await appState.loadProjects()
            }
        }
    }

    private var notConfiguredView: some View {
        VStack(spacing: 8) {
            Image(systemName: "gear.badge.questionmark")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Не настроено")
                .font(.headline)
            Text("Откройте Настройки для подключения к серверу Kimai.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 12)
    }
}
