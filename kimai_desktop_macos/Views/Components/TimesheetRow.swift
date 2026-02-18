import SwiftUI

struct TimesheetRow: View {
    @Environment(AppState.self) private var appState
    let timesheet: KimaiTimesheet
    var onRestart: (() -> Void)?

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(appState.resolvedProjectName(for: timesheet))
                    .font(.headline)
                    .lineLimit(1)
                Text(appState.resolvedActivityName(for: timesheet))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(timesheet.formattedDuration)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(timesheet.isActive ? .green : .primary)

                if let beginDate = timesheet.beginDate {
                    Text(DateFormatting.formatTimeOnly(beginDate))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            if let onRestart, !timesheet.isActive {
                Button(action: onRestart) {
                    Image(systemName: "play.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                }
                .buttonStyle(.plain)
                .help("Перезапустить таймер")
            }
        }
        .padding(.vertical, 4)
    }
}
