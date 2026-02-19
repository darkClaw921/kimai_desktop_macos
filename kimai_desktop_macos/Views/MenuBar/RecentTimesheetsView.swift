import SwiftUI

struct RecentTimesheetsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Недавние")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            if appState.recentTimesheets.isEmpty {
                Text("Нет недавних записей")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(appState.recentTimesheets.prefix(5)) { timesheet in
                    if !timesheet.isActive {
                        TimesheetRow(timesheet: timesheet) {
                            appState.requestRestart(timesheet)
                        }
                        .padding(.horizontal, 4)

                        if timesheet.id != appState.recentTimesheets.prefix(5).last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }
}
