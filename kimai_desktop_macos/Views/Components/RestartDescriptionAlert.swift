import SwiftUI

struct RestartDescriptionView: View {
    @Environment(AppState.self) private var appState
    @FocusState private var isFocused: Bool

    var body: some View {
        @Bindable var appState = appState

        if let timesheet = appState.timesheetToRestart {
            GlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Перезапуск таймера")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(appState.resolvedProjectName(for: timesheet))
                            .font(.subheadline)
                        Text(appState.resolvedActivityName(for: timesheet))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    TextField("Комментарий", text: $appState.restartDescription)
                        .textFieldStyle(.roundedBorder)
                        .focused($isFocused)

                    HStack {
                        Button("Отмена") {
                            appState.timesheetToRestart = nil
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)

                        Spacer()

                        Button("Пропустить") {
                            Task { await appState.confirmRestartSkip() }
                        }
                        .buttonStyle(.bordered)

                        Button("Запустить") {
                            Task { await appState.confirmRestartWithDescription() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .onAppear { isFocused = true }
        }
    }
}
