import Foundation

actor KimaiAPIClient {
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }

    // MARK: - Configuration

    private var baseURL: String? {
        KeychainService.baseURL
    }

    private var apiToken: String? {
        KeychainService.apiToken
    }

    var isConfigured: Bool {
        baseURL != nil && apiToken != nil
    }

    // MARK: - Generic Request

    private func request<T: Decodable & Sendable>(
        method: String = "GET",
        path: String,
        body: (any Encodable & Sendable)? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        guard let baseURL, let apiToken else {
            throw APIError.notConfigured
        }

        guard var components = URLComponents(string: baseURL + path) else {
            throw APIError.invalidURL
        }

        if let queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown("Invalid response type")
        }

        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 500...599:
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        default:
            throw APIError.invalidResponse(statusCode: httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }

    private func requestNoContent(
        method: String,
        path: String,
        body: (any Encodable & Sendable)? = nil
    ) async throws {
        guard let baseURL, let apiToken else {
            throw APIError.notConfigured
        }

        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (_, response): (Data, URLResponse)
        do {
            (_, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown("Invalid response type")
        }

        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 500...599:
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        default:
            throw APIError.invalidResponse(statusCode: httpResponse.statusCode)
        }
    }

    // MARK: - API Endpoints

    func testConnection() async throws -> Bool {
        struct UserInfo: Decodable, Sendable {
            let id: Int
            let username: String
        }
        let _: UserInfo = try await request(path: "/api/users/me")
        return true
    }

    func fetchProjects() async throws -> [KimaiProject] {
        try await request(
            path: "/api/projects",
            queryItems: [URLQueryItem(name: "visible", value: "1")]
        )
    }

    func fetchActivities(projectId: Int? = nil) async throws -> [KimaiActivity] {
        var queryItems = [URLQueryItem(name: "visible", value: "1")]
        if let projectId {
            queryItems.append(URLQueryItem(name: "project", value: "\(projectId)"))
        }
        return try await request(path: "/api/activities", queryItems: queryItems)
    }

    func fetchActiveTimesheets() async throws -> [KimaiTimesheet] {
        try await request(path: "/api/timesheets/active")
    }

    func fetchRecentTimesheets(count: Int = Constants.Defaults.recentTimesheetsCount) async throws -> [KimaiTimesheet] {
        try await request(
            path: "/api/timesheets/recent",
            queryItems: [URLQueryItem(name: "size", value: "\(count)")]
        )
    }

    func fetchTimesheets(page: Int = 1, size: Int = Constants.Defaults.historyPageSize) async throws -> [KimaiTimesheet] {
        try await request(
            path: "/api/timesheets",
            queryItems: [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "size", value: "\(size)"),
                URLQueryItem(name: "order", value: "DESC"),
                URLQueryItem(name: "orderBy", value: "begin"),
            ]
        )
    }

    func startTimesheet(projectId: Int, activityId: Int, description: String? = nil) async throws -> KimaiTimesheet {
        let body = CreateTimesheetRequest(
            project: projectId,
            activity: activityId,
            description: description
        )
        return try await request(method: "POST", path: "/api/timesheets", body: body)
    }

    func stopTimesheet(id: Int) async throws -> KimaiTimesheet {
        try await request(method: "PATCH", path: "/api/timesheets/\(id)/stop")
    }

    func restartTimesheet(id: Int) async throws -> KimaiTimesheet {
        try await request(method: "PATCH", path: "/api/timesheets/\(id)/restart")
    }

    func fetchProjectRates(projectId: Int) async throws -> [KimaiRate] {
        try await request(path: "/api/projects/\(projectId)/rates")
    }

    func fetchActivityRates(activityId: Int) async throws -> [KimaiRate] {
        try await request(path: "/api/activities/\(activityId)/rates")
    }
}
