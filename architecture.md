# Kimai Desktop macOS — Architecture

## Overview

macOS application for time tracking via Kimai API. Two interfaces: menu bar popover (quick access) and main window (history/stats). Desktop widget shows tracking state. Built with SwiftUI, Liquid Glass (macOS 26 Tahoe), MVVM + @Observable.

## Architecture Diagram

```
MenuBarExtra (.window)  ←→  AppState (@Observable)  ←→  KimaiAPIClient (actor)
     │                           │                            │
WindowGroup (main)          TimerService              URLSession → Kimai REST API
     │                           │
Settings scene              SharedDefaults (App Groups)
                                 │
WidgetKit Extension  ←→    KeychainService (Security framework)
```

## Project Structure

### Main App — `kimai_desktop_macos/`

#### Entry Point
- [`kimai_desktop_macosApp.swift`](kimai_desktop_macos/kimai_desktop_macosApp.swift) — @main App с тремя scenes: `MenuBarExtra(.window)`, `WindowGroup(id: "main")`, `Settings`. Создаёт и инжектит `AppState` через `.environment()`. Menu bar label показывает иконку часов и elapsed time при активном трекинге.

#### Models/
- [`KimaiProject.swift`](kimai_desktop_macos/Models/KimaiProject.swift) — Codable модель проекта Kimai. Содержит `CustomerRef`, `displayName` для отображения "Customer — Project".
- [`KimaiActivity.swift`](kimai_desktop_macos/Models/KimaiActivity.swift) — Codable модель активности. Связь с проектом через `project: Int?`.
- [`KimaiTimesheet.swift`](kimai_desktop_macos/Models/KimaiTimesheet.swift) — Codable модель таймшита. Вложенные `ProjectRef`, `ActivityRef`. Computed properties: `isActive`, `beginDate`, `formattedDuration`. Также содержит `CreateTimesheetRequest` для создания новых записей.
- [`APIError.swift`](kimai_desktop_macos/Models/APIError.swift) — Enum ошибок API с `LocalizedError` conformance. Покрывает: notConfigured, invalidURL, unauthorized, forbidden, notFound, serverError, decodingError, networkError.

#### Services/
- [`KimaiAPIClient.swift`](kimai_desktop_macos/Services/KimaiAPIClient.swift) — Actor, async/await URLSession. Generic `request<T: Decodable & Sendable>()` method. Эндпоинты: testConnection, fetchProjects, fetchActivities, fetchActiveTimesheets, fetchRecentTimesheets, fetchTimesheets (paginated), startTimesheet, stopTimesheet, restartTimesheet. Auth через Bearer token.
- [`KeychainService.swift`](kimai_desktop_macos/Services/KeychainService.swift) — nonisolated enum, обёртка Security framework. CRUD для Keychain: save/load/delete. Convenience properties: `apiToken`, `baseURL`.
- [`SharedDefaults.swift`](kimai_desktop_macos/Services/SharedDefaults.swift) — App Groups UserDefaults обёртка для синхронизации состояния трекинга с виджетом. Properties: isTracking, currentProjectName, currentActivityName, trackingStartDate, lastSyncDate.
- [`TimerService.swift`](kimai_desktop_macos/Services/TimerService.swift) — @Observable класс, DispatchSourceTimer каждую секунду. Отслеживает `elapsed` time от `startDate`. `formattedElapsed` для отображения.

#### ViewModels/
- [`AppState.swift`](kimai_desktop_macos/ViewModels/AppState.swift) — Корневой @Observable. Содержит `KimaiAPIClient`, `TimerService`. Управляет: подключением, активным таймером, recent/all timesheets, проектами/активностями. Polling с интервалом. Widget sync через `SharedDefaults` + `WidgetCenter.shared.reloadAllTimelines()`.
- [`TimesheetViewModel.swift`](kimai_desktop_macos/ViewModels/TimesheetViewModel.swift) — Фильтрация таймшитов: по проекту, дате, поиску. Helpers: todayTimesheets, weekTimesheets, totalDuration.
- [`ProjectsViewModel.swift`](kimai_desktop_macos/ViewModels/ProjectsViewModel.swift) — Фильтрация проектов по поиску. Helpers: projectTimesheets, projectTotalDuration.

#### Views/MenuBar/
- [`MenuBarPopover.swift`](kimai_desktop_macos/Views/MenuBar/MenuBarPopover.swift) — Главный popover (320pt). Показывает ActiveTimerView или QuickStartView (в GlassEffectContainer), RecentTimesheetsView, MenuBarFooterView. Not-configured state если нет credentials.
- [`ActiveTimerView.swift`](kimai_desktop_macos/Views/MenuBar/ActiveTimerView.swift) — GlassCard с текущим таймером: проект/активность, ElapsedTimeText, Stop кнопка (glass interactive).
- [`QuickStartView.swift`](kimai_desktop_macos/Views/MenuBar/QuickStartView.swift) — GlassCard: Picker проекта, Picker активности (загружаются при выборе проекта), TextField описания, Start Timer кнопка (glass interactive).
- [`RecentTimesheetsView.swift`](kimai_desktop_macos/Views/MenuBar/RecentTimesheetsView.swift) — Последние 5 записей с кнопкой restart.
- [`MenuBarFooterView.swift`](kimai_desktop_macos/Views/MenuBar/MenuBarFooterView.swift) — StatusIndicator + Open Window / Settings / Quit.

#### Views/MainWindow/
- [`MainWindowView.swift`](kimai_desktop_macos/Views/MainWindow/MainWindowView.swift) — NavigationSplitView: sidebar + detail. Min 700x500.
- [`SidebarView.swift`](kimai_desktop_macos/Views/MainWindow/SidebarView.swift) — Enum `SidebarItem` (Dashboard, History, Projects) + List с иконками.
- [`DashboardView.swift`](kimai_desktop_macos/Views/MainWindow/DashboardView.swift) — Active timer section (GlassCard), Today summary с записями, Week summary (grouped by project).
- [`TimesheetHistoryView.swift`](kimai_desktop_macos/Views/MainWindow/TimesheetHistoryView.swift) — Table с колонками: Project, Activity, Description, Date, Duration, Restart. Фильтры: search, project picker, date range. Load More для пагинации.
- [`ProjectDetailView.swift`](kimai_desktop_macos/Views/MainWindow/ProjectDetailView.swift) — Searchable список проектов с цветами, customer, total duration, activity tags. Содержит `Color(hex:)` extension.

#### Views/Settings/
- [`SettingsView.swift`](kimai_desktop_macos/Views/Settings/SettingsView.swift) — TabView: Connection + General.
- [`ConnectionSettingsView.swift`](kimai_desktop_macos/Views/Settings/ConnectionSettingsView.swift) — Form: Server URL, API Token (SecureField), Test Connection с индикатором, Save.
- [`GeneralSettingsView.swift`](kimai_desktop_macos/Views/Settings/GeneralSettingsView.swift) — Form: Refresh Interval picker, Show timer in menu bar toggle, Recent entries count.

#### Views/Components/
- [`GlassCard.swift`](kimai_desktop_macos/Views/Components/GlassCard.swift) — Переиспользуемый контейнер: `.glassEffect(.regular, in: .rect(cornerRadius: 12))`.
- [`ElapsedTimeText.swift`](kimai_desktop_macos/Views/Components/ElapsedTimeText.swift) — Live hh:mm:ss из TimerService. Monospaced font, `.contentTransition(.numericText())`.
- [`TimesheetRow.swift`](kimai_desktop_macos/Views/Components/TimesheetRow.swift) — Строка записи: project/activity, duration, time, optional restart button.
- [`StatusIndicator.swift`](kimai_desktop_macos/Views/Components/StatusIndicator.swift) — Enum Status (online/offline/tracking) с цветным кружком и label.

#### Utilities/
- [`Constants.swift`](kimai_desktop_macos/Utilities/Constants.swift) — nonisolated enum. App Group ID, Keychain keys, default values (refresh interval, page sizes), SharedDefaults keys.
- [`DateFormatting.swift`](kimai_desktop_macos/Utilities/DateFormatting.swift) — nonisolated enum. RFC 3339 парсинг/форматирование, elapsed time (hh:mm:ss), duration (Xh Ym), short date, time only.

### Widget Extension — `kimai_desktop_macos_wiget/`

- [`kimai_desktop_macos_wigetBundle.swift`](kimai_desktop_macos_wiget/kimai_desktop_macos_wigetBundle.swift) — @main WidgetBundle: KimaiTrackingWidget + ControlWidget.
- [`kimai_desktop_macos_wiget.swift`](kimai_desktop_macos_wiget/kimai_desktop_macos_wiget.swift) — StaticConfiguration widget. `KimaiTimelineProvider` читает App Groups UserDefaults. `KimaiWidgetEntry` с tracking state. Поддержка `.systemSmall` и `.systemMedium`.
- [`kimai_desktop_macos_wigetControl.swift`](kimai_desktop_macos_wiget/kimai_desktop_macos_wigetControl.swift) — ControlWidget показывающий статус трекинга. TimerConfiguration intent, StartTimerIntent.
- [`AppIntent.swift`](kimai_desktop_macos_wiget/AppIntent.swift) — ConfigurationAppIntent для widget.
- [`WidgetViews/SmallWidgetView.swift`](kimai_desktop_macos_wiget/WidgetViews/SmallWidgetView.swift) — Small widget: иконка + проект + timer (style: .timer).
- [`WidgetViews/MediumWidgetView.swift`](kimai_desktop_macos_wiget/WidgetViews/MediumWidgetView.swift) — Medium widget: иконка + проект + активность + elapsed + детали.

## Key Technical Decisions

| Решение | Выбор | Причина |
|---------|-------|---------|
| App type | MenuBarExtra + WindowGroup | Quick access + extended view |
| State | @Observable + @Environment | Native Swift Observation, macOS 26 |
| Networking | URLSession actor | Async/await, thread-safe, zero deps |
| Token storage | Keychain Services | Secure, system-level |
| Widget data | App Groups UserDefaults | Standard Apple pattern |
| Liquid Glass | Controls/navigation only | Apple design guidelines |
| Concurrency | Swift 6, MainActor default | Models marked `nonisolated` for cross-actor use |
| Timer | DispatchSourceTimer | MainActor-compatible, 1s interval |
| Main window | NavigationSplitView | Glass sidebar, 3-column layout |

### Scripts — `scripts/`

- [`build_dmg.sh`](scripts/build_dmg.sh) — Bash скрипт автоматической сборки проекта в DMG. Архивирует через xcodebuild, извлекает .app, создаёт DMG с symlink на /Applications. Выходной файл: `build/Kimai_Desktop_v{version}_{build}.dmg`.

## Kimai API Endpoints Used

- `GET /api/users/me` — Test connection
- `GET /api/projects` — Projects list
- `GET /api/activities?project={id}` — Activities by project
- `GET /api/timesheets/active` — Active timesheets
- `GET /api/timesheets/recent` — Recent entries
- `GET /api/timesheets?page&size&order&orderBy` — Paginated history
- `POST /api/timesheets` — Start timer
- `PATCH /api/timesheets/{id}/stop` — Stop timer
- `PATCH /api/timesheets/{id}/restart` — Restart timer
