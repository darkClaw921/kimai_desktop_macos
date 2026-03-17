# Kimai Desktop macOS — Architecture

## Overview

macOS application for time tracking via Kimai API. Two interfaces: menu bar popover (quick access) and main window (history/stats). Built with SwiftUI, Liquid Glass (macOS 26 Tahoe), MVVM + @Observable.

## Architecture Diagram

```
MenuBarExtra (.window)  ←→  AppState (@Observable)  ←→  KimaiAPIClient (actor)
     │                           │                            │
WindowGroup (main)          TimerService              URLSession → Kimai REST API
     │                           │
Settings scene              KeychainService (Security framework)
                                 │
                            EventStore (@Observable)  ←  WebhookServer (actor, NWListener)
                                 │                            │
                            JSON file (App Support)    POST /api/events ← External agents
```

## Project Structure

### Main App — `kimai_desktop_macos/`

#### Entry Point
- [`kimai_desktop_macosApp.swift`](kimai_desktop_macos/kimai_desktop_macosApp.swift) — @main App с тремя scenes: `MenuBarExtra(.window)`, `WindowGroup(id: "main")`, `Settings`. Создаёт и инжектит `AppState` через `.environment()`. Menu bar label показывает иконку часов, elapsed time и текущий заработок при активном трекинге.

#### Models/
- [`KimaiProject.swift`](kimai_desktop_macos/Models/KimaiProject.swift) — Codable модель проекта Kimai. Содержит `CustomerRef`, `displayName` для отображения "Customer — Project".
- [`KimaiActivity.swift`](kimai_desktop_macos/Models/KimaiActivity.swift) — Codable модель активности. Связь с проектом через `project: Int?`.
- [`KimaiTimesheet.swift`](kimai_desktop_macos/Models/KimaiTimesheet.swift) — Codable модель таймшита. Вложенные `ProjectRef`, `ActivityRef`. Поле `rate` из API. Computed properties: `isActive`, `beginDate`, `formattedDuration`. Содержит `CreateTimesheetRequest` для создания новых записей и `CreateCompletedTimesheetRequest` для создания уже завершённых записей (с begin и end).
- [`KimaiRate.swift`](kimai_desktop_macos/Models/KimaiRate.swift) — Codable модель ставки проекта/активности. Поля: `rate` (часовая ставка), `isFixed`, `user` (для user-specific ставок).
- [`AgentEvent.swift`](kimai_desktop_macos/Models/AgentEvent.swift) — Модель события от агента. `EventStatus` enum (pending/processed/dismissed). `AgentEvent` struct с полями: id (UUID), description, realDuration, estimatedHumanDuration (секунды), timestamp (Date), source (String), status (EventStatus). Используется для приёма событий от внешних агентов (например claude-code) и конвертации в таймшиты.
- [`APIError.swift`](kimai_desktop_macos/Models/APIError.swift) — Enum ошибок API с `LocalizedError` conformance. Покрывает: notConfigured, invalidURL, unauthorized, forbidden, notFound, serverError, decodingError, networkError.

#### Services/
- [`KimaiAPIClient.swift`](kimai_desktop_macos/Services/KimaiAPIClient.swift) — Actor, async/await URLSession. Generic `request<T: Decodable & Sendable>()` method. Эндпоинты: testConnection, fetchProjects, fetchActivities, fetchActiveTimesheets, fetchRecentTimesheets, fetchTimesheets (paginated), startTimesheet, stopTimesheet, restartTimesheet, createCompletedTimesheet (POST с begin+end для завершённых записей), fetchProjectRates, fetchActivityRates. Auth через Bearer token.
- [`KeychainService.swift`](kimai_desktop_macos/Services/KeychainService.swift) — nonisolated enum, обёртка Security framework. CRUD для Keychain: save/load/delete. Convenience properties: `apiToken`, `baseURL`.
- [`TimerService.swift`](kimai_desktop_macos/Services/TimerService.swift) — @Observable класс, DispatchSourceTimer каждую секунду. Отслеживает `elapsed` time от `startDate`. `formattedElapsed` для отображения.
- [`EventStore.swift`](kimai_desktop_macos/Services/EventStore.swift) — @Observable final class для персистентного хранения AgentEvent в JSON-файле (Application Support / Bundle ID / agent_events.json). Методы: `add`, `dismiss`, `markProcessed`, `remove`. Computed: `pendingEvents`, `pendingCount`. Автозагрузка при init, автосохранение при каждом изменении. JSONEncoder/JSONDecoder с `.iso8601` dateStrategy.
- [`WebhookServer.swift`](kimai_desktop_macos/Services/WebhookServer.swift) — Actor с NWListener (Network framework) для локального HTTP-сервера. Принимает `POST /api/events` с JSON body → AgentEvent. Bearer token авторизация. Ручной парсинг HTTP/1.1 (разделение headers/body по \r\n\r\n, Content-Length). HTTP ответы: 200/400/401/404/405. Callback `onEvent: @Sendable (AgentEvent) -> Void`. Методы: `start(port:token:)`, `stop()`, `isRunning`.

#### ViewModels/
- [`AppState.swift`](kimai_desktop_macos/ViewModels/AppState.swift) — Корневой @Observable. Содержит `KimaiAPIClient`, `TimerService`, `EventStore`, опциональный `WebhookServer`. Управляет: подключением, активным таймером, recent/all timesheets, проектами/активностями. Computed properties: `currentEarnings`, `formattedEarnings` (расчёт заработка по часовой ставке проекта через `/api/projects/{id}/rates`). Кеширование ставки по `projectId`. Polling с интервалом. Методы webhook: `startWebhookServer()` (читает порт/токен, запускает сервер с callback в eventStore), `stopWebhookServer()`. Метод `processEvents(eventIds:project:activity:useEstimatedDuration:)` — создаёт завершённые таймшиты в Kimai для каждого события, помечает обработанные, возвращает количество успешных.
- [`TimesheetViewModel.swift`](kimai_desktop_macos/ViewModels/TimesheetViewModel.swift) — Фильтрация таймшитов: по проекту, дате, поиску. Helpers: todayTimesheets, weekTimesheets, totalDuration.
- [`ProjectsViewModel.swift`](kimai_desktop_macos/ViewModels/ProjectsViewModel.swift) — Фильтрация проектов по поиску. Группировка по клиентам через `CustomerGroup`. Helpers: groupedByCustomer, projectTimesheets, projectTotalDuration, customerTotalDuration, projectTotalEarnings, customerTotalEarnings.

#### Views/MenuBar/
- [`MenuBarPopover.swift`](kimai_desktop_macos/Views/MenuBar/MenuBarPopover.swift) — Главный popover (320pt). Показывает ActiveTimerView или QuickStartView (в GlassEffectContainer), RecentTimesheetsView, MenuBarFooterView. Not-configured state если нет credentials.
- [`ActiveTimerView.swift`](kimai_desktop_macos/Views/MenuBar/ActiveTimerView.swift) — GlassCard с текущим таймером: проект/активность, ElapsedTimeText, Stop кнопка (glass interactive).
- [`QuickStartView.swift`](kimai_desktop_macos/Views/MenuBar/QuickStartView.swift) — GlassCard: Picker проекта, Picker активности (загружаются при выборе проекта), TextField описания, Start Timer кнопка (glass interactive).
- [`RecentTimesheetsView.swift`](kimai_desktop_macos/Views/MenuBar/RecentTimesheetsView.swift) — Последние 5 записей с кнопкой restart.
- [`MenuBarFooterView.swift`](kimai_desktop_macos/Views/MenuBar/MenuBarFooterView.swift) — StatusIndicator + Open Window / Settings / Quit.

#### Views/MainWindow/
- [`MainWindowView.swift`](kimai_desktop_macos/Views/MainWindow/MainWindowView.swift) — NavigationSplitView: sidebar + detail. Min 700x500. Роутинг: Dashboard, History, Projects, Events (EventsInboxView). Запускает webhook сервер в `.task`.
- [`SidebarView.swift`](kimai_desktop_macos/Views/MainWindow/SidebarView.swift) — Enum `SidebarItem` (Dashboard, History, Projects, Events) + List с иконками. Badge на пункте "События" показывает `pendingCount` из `EventStore`.
- [`DashboardView.swift`](kimai_desktop_macos/Views/MainWindow/DashboardView.swift) — Active timer section (GlassCard), Today summary с записями, Week summary (grouped by project).
- [`TimesheetHistoryView.swift`](kimai_desktop_macos/Views/MainWindow/TimesheetHistoryView.swift) — Table с колонками: Project, Activity, Description, Date, Duration, Restart. Фильтры: search, project picker, date range. Load More для пагинации.
- [`ProjectDetailView.swift`](kimai_desktop_macos/Views/MainWindow/ProjectDetailView.swift) — Иерархический список с раскрывающимися группами: Клиент → Проект → Записи таймшитов. DisclosureGroup для каждого уровня. Содержит `Color(hex:)` extension.
- [`EventsInboxView.swift`](kimai_desktop_macos/Views/MainWindow/EventsInboxView.swift) — Экран Events Inbox. Список событий от агентов с multi-select чекбоксами. Toolbar: фильтр по статусу (Все/Ожидающие/Обработанные/Отклонённые), кнопка "Обработать выбранные". Каждая строка: описание, source, timestamp, реальное/расчётное время. Кнопка dismiss для pending событий. ContentUnavailableView при пустом списке. Sheet → EventProcessingSheet.
- [`EventProcessingSheet.swift`](kimai_desktop_macos/Views/MainWindow/EventProcessingSheet.swift) — Sheet обработки выбранных событий. Picker проекта (сгруппирован по клиентам), Picker активности (загружается onChange), Segmented Picker типа времени (расчётное/реальное), превью суммарной длительности. Кнопка "Создать записи" вызывает appState.processEvents(), при успехе автозакрытие.

#### Views/Settings/
- [`SettingsView.swift`](kimai_desktop_macos/Views/Settings/SettingsView.swift) — TabView: Connection + General + Agent. Frame 450x500.
- [`ConnectionSettingsView.swift`](kimai_desktop_macos/Views/Settings/ConnectionSettingsView.swift) — Form: Server URL, API Token (SecureField), Test Connection с индикатором, Save.
- [`GeneralSettingsView.swift`](kimai_desktop_macos/Views/Settings/GeneralSettingsView.swift) — Form: Refresh Interval picker, Show timer in menu bar toggle, Recent entries count, Currency suffix TextField.
- [`AgentSettingsView.swift`](kimai_desktop_macos/Views/Settings/AgentSettingsView.swift) — Form: секция "Webhook сервер" (порт через @AppStorage, токен через Keychain SecureField, генерация токена, статус сервера с индикатором, перезапуск), секция "Инструкции для агента" (read-only текст с динамической подстановкой порта/токена, кнопки копирования инструкций и curl примера через NSPasteboard).

#### Views/Components/
- [`GlassCard.swift`](kimai_desktop_macos/Views/Components/GlassCard.swift) — Переиспользуемый контейнер: `.glassEffect(.regular, in: .rect(cornerRadius: 12))`.
- [`ElapsedTimeText.swift`](kimai_desktop_macos/Views/Components/ElapsedTimeText.swift) — Live hh:mm:ss из TimerService. Monospaced font, `.contentTransition(.numericText())`.
- [`TimesheetRow.swift`](kimai_desktop_macos/Views/Components/TimesheetRow.swift) — Строка записи: project/activity, duration, time, optional restart button.
- [`StatusIndicator.swift`](kimai_desktop_macos/Views/Components/StatusIndicator.swift) — Enum Status (online/offline/tracking) с цветным кружком и label.

#### Utilities/
- [`Constants.swift`](kimai_desktop_macos/Utilities/Constants.swift) — nonisolated enum. Keychain keys, default values (refresh interval, page sizes, currency suffix "₽"). Вложенные: `Webhook` (defaultPort, portUserDefaultsKey, tokenKeychainKey), `EventStorage` (fileName).
- [`DateFormatting.swift`](kimai_desktop_macos/Utilities/DateFormatting.swift) — nonisolated enum. RFC 3339 парсинг/форматирование, elapsed time (hh:mm:ss), duration (Xh Ym), short date, time only.

## Key Technical Decisions

| Решение | Выбор | Причина |
|---------|-------|---------|
| App type | MenuBarExtra + WindowGroup | Quick access + extended view |
| State | @Observable + @Environment | Native Swift Observation, macOS 26 |
| Networking | URLSession actor | Async/await, thread-safe, zero deps |
| Token storage | Keychain Services | Secure, system-level |
| Liquid Glass | Controls/navigation only | Apple design guidelines |
| Concurrency | Swift 6, MainActor default | Models marked `nonisolated` for cross-actor use |
| Timer | DispatchSourceTimer | MainActor-compatible, 1s interval |
| Main window | NavigationSplitView | Glass sidebar, 3-column layout |
| Webhook server | NWListener actor | Manual HTTP parsing, no external deps |
| Event storage | JSON file in App Support | Simple persistence, no CoreData overhead |

### Scripts — `scripts/`

- [`build_dmg.sh`](scripts/build_dmg.sh) — Bash скрипт автоматической сборки проекта в DMG. Архивирует через xcodebuild, извлекает .app, создаёт DMG с symlink на /Applications. Выходной файл: `build/Kimai_Desktop_v{version}_{build}.dmg`.

## Entitlements

- `com.apple.security.app-sandbox` — App Sandbox
- `com.apple.security.network.client` — Исходящие сетевые подключения (Kimai API)
- `com.apple.security.network.server` — Входящие сетевые подключения (WebhookServer NWListener)
- `com.apple.security.files.user-selected.read-only` — Чтение файлов по выбору пользователя

## Kimai API Endpoints Used

- `GET /api/users/me` — Test connection
- `GET /api/projects` — Projects list
- `GET /api/activities?project={id}` — Activities by project
- `GET /api/timesheets/active` — Active timesheets
- `GET /api/timesheets/recent` — Recent entries
- `GET /api/timesheets?page&size&order&orderBy` — Paginated history
- `POST /api/timesheets` — Start timer / Create completed timesheet (with begin+end)
- `PATCH /api/timesheets/{id}/stop` — Stop timer
- `PATCH /api/timesheets/{id}/restart` — Restart timer
- `GET /api/projects/{id}/rates` — Hourly rates for project
- `GET /api/activities/{id}/rates` — Hourly rates for activity

## Webhook Server Endpoint

- `POST /api/events` — Приём событий от внешних агентов. Body: `{description, realDuration, estimatedHumanDuration, timestamp, source}`. Auth: `Authorization: Bearer <token>`. Порт по умолчанию: 29876.
