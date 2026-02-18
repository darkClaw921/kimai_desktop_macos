import AppIntents
import SwiftUI
import WidgetKit

struct kimai_desktop_macos_wigetControl: ControlWidget {
    static let kind: String = "alteran.industries.kimai-desktop-macos.kimai_desktop_macos_wiget"

    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(
            kind: Self.kind,
            provider: Provider()
        ) { value in
            ControlWidgetToggle(
                "Таймер",
                isOn: value.isRunning,
                action: StartTimerIntent(value.name)
            ) { isRunning in
                Label(isRunning ? "Отслеживание" : "Неактивен", systemImage: isRunning ? "clock.badge.checkmark" : "clock")
            }
        }
        .displayName("Таймер Kimai")
        .description("Показывает текущий статус Kimai.")
    }
}

extension kimai_desktop_macos_wigetControl {
    struct Value {
        var isRunning: Bool
        var name: String
    }

    struct Provider: AppIntentControlValueProvider {
        func previewValue(configuration: TimerConfiguration) -> Value {
            Value(isRunning: false, name: "Kimai")
        }

        func currentValue(configuration: TimerConfiguration) async throws -> Value {
            let defaults = UserDefaults(suiteName: "group.alteran.industries.kimai-desktop-macos")
            let isRunning = defaults?.bool(forKey: "isTracking") ?? false
            let name = defaults?.string(forKey: "currentProjectName") ?? "Kimai"
            return Value(isRunning: isRunning, name: name)
        }
    }
}

struct TimerConfiguration: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "Настройка таймера Kimai"

    @Parameter(title: "Имя таймера", default: "Kimai")
    var timerName: String
}

struct StartTimerIntent: SetValueIntent {
    static let title: LocalizedStringResource = "Переключить таймер Kimai"

    @Parameter(title: "Имя таймера")
    var name: String

    @Parameter(title: "Таймер запущен")
    var value: Bool

    init() {}

    init(_ name: String) {
        self.name = name
    }

    func perform() async throws -> some IntentResult {
        return .result()
    }
}
