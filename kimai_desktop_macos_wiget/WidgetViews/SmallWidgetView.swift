import SwiftUI
import WidgetKit

struct SmallWidgetView: View {
    let entry: KimaiWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: entry.isTracking ? "clock.badge.checkmark" : "clock")
                    .font(.title2)
                    .foregroundStyle(entry.isTracking ? .green : .secondary)
                Spacer()
            }

            Spacer()

            if entry.isTracking {
                if let project = entry.projectName {
                    Text(project)
                        .font(.headline)
                        .lineLimit(1)
                }

                if let startDate = entry.trackingStartDate {
                    Text(startDate, style: .timer)
                        .font(.system(.title3, design: .monospaced))
                        .foregroundStyle(.green)
                }
            } else {
                Text("Не отслеживается")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("Откройте приложение")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
