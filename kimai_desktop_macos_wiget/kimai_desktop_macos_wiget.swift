import WidgetKit
import SwiftUI

// MARK: - Shared Constants (duplicated for widget target)

private enum WidgetConstants {
    static let appGroupID = "group.alteran.industries.kimai-desktop-macos"

    enum Keys {
        static let isTracking = "isTracking"
        static let currentProjectName = "currentProjectName"
        static let currentActivityName = "currentActivityName"
        static let trackingStartDate = "trackingStartDate"
        static let lastSyncDate = "lastSyncDate"
    }
}

// MARK: - Widget Entry

struct KimaiWidgetEntry: TimelineEntry {
    let date: Date
    let isTracking: Bool
    let projectName: String?
    let activityName: String?
    let trackingStartDate: Date?

    static var placeholder: KimaiWidgetEntry {
        KimaiWidgetEntry(
            date: .now,
            isTracking: true,
            projectName: "Мой проект",
            activityName: "Разработка",
            trackingStartDate: Date.now.addingTimeInterval(-3600)
        )
    }

    static var empty: KimaiWidgetEntry {
        KimaiWidgetEntry(
            date: .now,
            isTracking: false,
            projectName: nil,
            activityName: nil,
            trackingStartDate: nil
        )
    }
}

// MARK: - Timeline Provider

struct KimaiTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> KimaiWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (KimaiWidgetEntry) -> Void) {
        completion(readCurrentState())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<KimaiWidgetEntry>) -> Void) {
        let entry = readCurrentState()
        // Refresh every 5 minutes or when app signals
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: entry.date)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func readCurrentState() -> KimaiWidgetEntry {
        guard let defaults = UserDefaults(suiteName: WidgetConstants.appGroupID) else {
            return .empty
        }

        return KimaiWidgetEntry(
            date: .now,
            isTracking: defaults.bool(forKey: WidgetConstants.Keys.isTracking),
            projectName: defaults.string(forKey: WidgetConstants.Keys.currentProjectName),
            activityName: defaults.string(forKey: WidgetConstants.Keys.currentActivityName),
            trackingStartDate: defaults.object(forKey: WidgetConstants.Keys.trackingStartDate) as? Date
        )
    }
}

// MARK: - Widget Definition

struct KimaiTrackingWidget: Widget {
    let kind = "KimaiTrackingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: KimaiTimelineProvider()) { entry in
            KimaiWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Kimai Трекер")
        .description("Показывает текущий статус отслеживания времени.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Entry View Router

struct KimaiWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: KimaiWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}
