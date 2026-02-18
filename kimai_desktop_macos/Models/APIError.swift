import Foundation

nonisolated enum APIError: LocalizedError, Sendable {
    case notConfigured
    case invalidURL
    case invalidResponse(statusCode: Int)
    case unauthorized
    case forbidden
    case notFound
    case serverError(statusCode: Int)
    case decodingError(String)
    case networkError(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            "API не настроен. Укажите URL и токен в Настройках."
        case .invalidURL:
            "Некорректный URL сервера."
        case .invalidResponse(let code):
            "Неожиданный ответ (HTTP \(code))."
        case .unauthorized:
            "Неверный API-токен. Проверьте учётные данные."
        case .forbidden:
            "Доступ запрещён. Недостаточно прав."
        case .notFound:
            "Ресурс не найден."
        case .serverError(let code):
            "Ошибка сервера (HTTP \(code))."
        case .decodingError(let detail):
            "Ошибка разбора ответа: \(detail)"
        case .networkError(let detail):
            "Ошибка сети: \(detail)"
        case .unknown(let detail):
            "Неизвестная ошибка: \(detail)"
        }
    }
}
