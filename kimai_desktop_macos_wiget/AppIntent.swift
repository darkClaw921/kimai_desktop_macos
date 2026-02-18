import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Настройка Kimai" }
    static var description: IntentDescription { "Настройка виджета отслеживания Kimai." }
}
