import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    let entry: KimaiWidgetEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left: Icon + Status
            VStack {
                Image(systemName: entry.isTracking ? "clock.badge.checkmark" : "clock")
                    .font(.largeTitle)
                    .foregroundStyle(entry.isTracking ? .green : .secondary)

                Circle()
                    .fill(entry.isTracking ? .green : .gray)
                    .frame(width: 8, height: 8)
            }
            .frame(width: 50)

            // Right: Details
            VStack(alignment: .leading, spacing: 4) {
                if entry.isTracking {
                    Text(entry.projectName ?? "Проект")
                        .font(.headline)
                        .lineLimit(1)

                    Text(entry.activityName ?? "Активность")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Spacer()

                    if let startDate = entry.trackingStartDate {
                        HStack {
                            Text("Прошло:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(startDate, style: .timer)
                                .font(.system(.title3, design: .monospaced))
                                .foregroundStyle(.green)
                        }
                    }
                } else {
                    Text("Нет активного таймера")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text("Откройте Kimai для отслеживания")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)

                    Spacer()

                    Text("Kimai Трекер времени")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
        }
    }
}
