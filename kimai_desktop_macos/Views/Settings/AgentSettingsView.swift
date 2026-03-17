import SwiftUI

struct AgentSettingsView: View {
    @Environment(AppState.self) private var appState

    @AppStorage(Constants.Webhook.portUserDefaultsKey) private var port: Int = Int(Constants.Webhook.defaultPort)
    @State private var token: String = ""
    @State private var isServerRunning = false

    var body: some View {
        Form {
            Section {
                TextField("Порт", value: $port, format: .number)
                    .textFieldStyle(.roundedBorder)

                SecureField("Токен авторизации", text: $token, prompt: Text("Bearer токен"))
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: token) { _, newValue in
                        if !newValue.isEmpty {
                            _ = KeychainService.save(key: Constants.Webhook.tokenKeychainKey, value: newValue)
                        }
                    }

                HStack {
                    Button("Сгенерировать токен") {
                        let newToken = UUID().uuidString
                        token = newToken
                        _ = KeychainService.save(key: Constants.Webhook.tokenKeychainKey, value: newToken)
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        Circle()
                            .fill(isServerRunning ? .green : .gray)
                            .frame(width: 8, height: 8)
                        Text(isServerRunning ? "Запущен" : "Остановлен")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Button("Перезапустить сервер") {
                    Task {
                        await appState.stopWebhookServer()
                        await appState.startWebhookServer()
                        await updateServerStatus()
                    }
                }

                Text("Webhook сервер слушает POST /api/events на указанном порту")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Webhook сервер")
            }

            Section {
                ScrollView {
                    Text(agentFileContent)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 200)

                HStack {
                    Button("Копировать агент-файл") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(agentFileContent, forType: .string)
                    }

                    Button("Копировать curl пример") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(curlExample, forType: .string)
                    }
                }

                Text("Сохраните как .claude/agents/time_tracker.md в вашем проекте")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Агент для Claude Code")
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            token = KeychainService.load(key: Constants.Webhook.tokenKeychainKey) ?? ""
            Task { await updateServerStatus() }
        }
    }

    // MARK: - Server Status

    private func updateServerStatus() async {
        if let server = appState.webhookServer {
            isServerRunning = await server.isRunning
        } else {
            isServerRunning = false
        }
    }

    // MARK: - Instructions Text

    private var displayToken: String {
        token.isEmpty ? "<ваш-токен>" : token
    }

    // swiftlint:disable function_body_length
    private var agentFileContent: String {
"""
---
name: time-tracker
description: "Агент для трекинга времени выполненных задач и отправки webhook-отчётов в Kimai Desktop. Запускай этого агента после завершения задачи или фазы для записи затраченного времени.\\n\\nExamples:\\n\\n<example>\\nContext: A task has just been completed.\\nuser: \\"Задача выполнена, запиши время\\"\\nassistant: \\"Запускаю трекинг времени для выполненной задачи.\\"\\n<commentary>\\nЗадача завершена и пользователь хочет записать время. Запускаем агент time-tracker с описанием задачи и данными о времени.\\n</commentary>\\nassistant uses the Task tool to launch time-tracker agent with task description and timing data.\\n</example>\\n\\n<example>\\nContext: A phase of work has been completed.\\nuser: \\"Фаза 2 завершена, отправь отчёт в Kimai\\"\\nassistant: \\"Отправляю webhook с данными о затраченном времени.\\"\\n<commentary>\\nПользователь завершил фазу и хочет отправить отчёт о времени. Запускаем агент time-tracker.\\n</commentary>\\nassistant uses the Task tool to launch time-tracker agent.\\n</example>"
model: sonnet
color: green
memory: project
permissionMode: dontAsk
---

Ты — агент трекинга времени, который фиксирует время выполнения задач и отправляет структурированные отчёты в Kimai Desktop через локальный webhook-сервер.

## Твоя миссия

После завершения задачи — замерь затраченное время, оцени человеческий эквивалент и отправь webhook-событие в Kimai Desktop. Каждая завершённая задача ОБЯЗАНА иметь соответствующий webhook-отчёт.

## Перед началом

1. Зафиксируй текущее время через `date +%s` (Bash), если оно ещё не записано
2. Определи что за задача была выполнена и собери её описание
3. Если время начала уже зафиксировано — вычисли длительность

## Процесс трекинга

### Шаг 1: Сбор информации о задаче
- Получи описание задачи из контекста (что было сделано)
- Определи время начала (передано как входные данные или зафиксировано ранее)
- Получи время окончания: `date +%s`

### Шаг 2: Расчёт длительностей
- **realDuration** = end_time - start_time (в секундах)
- **estimatedHumanDuration** = оценка по типу задачи (см. правила ниже)

### Шаг 3: Отправка webhook

Выполни следующую curl-команду:

```bash
curl -X POST http://localhost:\(port)/api/events \\
  -H "Content-Type: application/json" \\
  -H "Authorization: Bearer \(displayToken)" \\
  -d '{
    "description": "ОПИСАНИЕ_ЗАДАЧИ",
    "realDuration": РЕАЛЬНЫЕ_СЕКУНДЫ,
    "estimatedHumanDuration": РАСЧЁТНЫЕ_СЕКУНДЫ,
    "source": "claude-code",
    "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
  }'
```

### Шаг 4: Проверка ответа
- Ожидаемый ответ: HTTP 200 с `{"status":"ok","id":"<uuid>"}`
- При ошибке — повтори один раз
- Сообщи результат вызывающему

## Справка по Webhook API

| Поле | Тип | Описание |
|------|-----|----------|
| `description` | string | Краткое описание выполненной задачи |
| `realDuration` | int | Реальное время выполнения агентом в секундах |
| `estimatedHumanDuration` | int | Оценка времени для человека-разработчика в секундах |
| `source` | string | Идентификатор агента — всегда используй `"claude-code"` |
| `timestamp` | string | ISO 8601 UTC время завершения задачи |

**Endpoint:** `POST http://localhost:\(port)/api/events`
**Авторизация:** `Authorization: Bearer \(displayToken)`

## Правила оценки estimatedHumanDuration

Оценивай на основе типа выполненной работы:

| Тип задачи | Множитель | Пример |
|------------|-----------|--------|
| Написание кода | x5-x8 | Новая фича, реализация |
| Исследование/поиск | x3-x5 | Поиск по кодовой базе, чтение документации |
| Рефакторинг | x4-x6 | Реструктуризация, очистка кода |
| Исправление багов | x5-x10 | Отладка, поиск причины |
| Документация | x2-x3 | README, комментарии, docs |
| Конфигурация | x3-x5 | Настройка сборки, CI/CD |
| Тестирование | x4-x6 | Написание и запуск тестов |

Выбирай множитель исходя из сложности задачи в рамках диапазона.

## Важные правила

- ВСЕГДА отправляй webhook после завершения задачи — это обязательное требование
- При ошибке curl — повтори один раз, но НЕ блокируй основной рабочий процесс
- `description` должен быть кратким и информативным (1-2 предложения)
- Округляй `realDuration` до целых секунд
- Для `timestamp` всегда используй UTC (суффикс Z)
- Если время начала не было зафиксировано — оцени `realDuration` на основе выполненной работы
- Сообщи об успехе или ошибке вызывающему

## Формат вывода

1. Покажи рассчитанные длительности (реальная и расчётная)
2. Покажи выполняемую curl-команду
3. Покажи ответ webhook-сервера
4. Подтверди успех или сообщи об ошибке
"""
    }
    // swiftlint:enable function_body_length

    private var curlExample: String {
"""
curl -X POST http://localhost:\(port)/api/events \\
  -H "Content-Type: application/json" \\
  -H "Authorization: Bearer \(displayToken)" \\
  -d '{
    "description": "Реализована фича X",
    "realDuration": 300,
    "estimatedHumanDuration": 1800,
    "source": "claude-code",
    "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
  }'
"""
    }
}
