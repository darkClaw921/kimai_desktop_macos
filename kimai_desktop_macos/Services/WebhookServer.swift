import Foundation
import Network

actor WebhookServer {
    private var listener: NWListener?
    private var activeConnections: [NWConnection] = []
    private let queue = DispatchQueue(label: "webhook-server")
    private var authToken: String?
    private(set) var isRunning = false

    nonisolated let onEvent: @Sendable (AgentEvent) -> Void

    init(onEvent: @escaping @Sendable (AgentEvent) -> Void) {
        self.onEvent = onEvent
    }

    // MARK: - Lifecycle

    func start(port: UInt16, token: String?) throws {
        stop()

        authToken = token

        let nwPort = NWEndpoint.Port(rawValue: port)!
        let params = NWParameters.tcp
        let listener = try NWListener(using: params, on: nwPort)

        listener.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .ready:
                break
            case .failed, .cancelled:
                Task { await self.handleListenerStopped() }
            default:
                break
            }
        }

        listener.newConnectionHandler = { [weak self] connection in
            guard let self else { return }
            Task { await self.handleNewConnection(connection) }
        }

        listener.start(queue: queue)
        self.listener = listener
        isRunning = true
    }

    func stop() {
        listener?.cancel()
        listener = nil
        for connection in activeConnections {
            connection.cancel()
        }
        activeConnections.removeAll()
        isRunning = false
    }

    // MARK: - Connection Handling

    private func handleListenerStopped() {
        isRunning = false
    }

    private func handleNewConnection(_ connection: NWConnection) {
        activeConnections.append(connection)

        connection.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            if case .cancelled = state {
                Task { await self.removeConnection(connection) }
            } else if case .failed = state {
                connection.cancel()
                Task { await self.removeConnection(connection) }
            }
        }

        connection.start(queue: queue)
        receiveData(on: connection, buffer: Data())
    }

    private func removeConnection(_ connection: NWConnection) {
        activeConnections.removeAll { $0 === connection }
    }

    // MARK: - HTTP Parsing

    private nonisolated func receiveData(on connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] content, _, isComplete, _ in
            guard let self else { return }

            var accumulated = buffer
            if let content {
                accumulated.append(content)
            }

            // Try to parse the HTTP request from accumulated data
            if let request = Self.parseHTTPRequest(from: accumulated) {
                Task { await self.handleHTTPRequest(request, on: connection) }
            } else if isComplete {
                // Connection closed before we got a complete request
                connection.cancel()
            } else {
                // Need more data
                self.receiveData(on: connection, buffer: accumulated)
            }
        }
    }

    private nonisolated struct HTTPRequest: Sendable {
        let method: String
        let path: String
        let headers: [String: String]
        let body: Data?
    }

    private nonisolated static func parseHTTPRequest(from data: Data) -> HTTPRequest? {
        guard let headerEnd = findCRLFCRLF(in: data) else { return nil }

        let headerData = data[data.startIndex..<headerEnd]
        guard let headerString = String(data: headerData, encoding: .utf8) else { return nil }

        let lines = headerString.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else { return nil }

        let parts = requestLine.split(separator: " ", maxSplits: 2)
        guard parts.count >= 2 else { return nil }

        let method = String(parts[0])
        let path = String(parts[1])

        var headers: [String: String] = [:]
        for line in lines.dropFirst() {
            guard let colonIndex = line.firstIndex(of: ":") else { continue }
            let key = line[line.startIndex..<colonIndex].trimmingCharacters(in: .whitespaces).lowercased()
            let value = line[line.index(after: colonIndex)...].trimmingCharacters(in: .whitespaces)
            headers[key] = value
        }

        let bodyStart = headerEnd + 4 // skip \r\n\r\n
        let contentLength = headers["content-length"].flatMap(Int.init) ?? 0

        if contentLength > 0 {
            let availableBody = data.count - bodyStart
            guard availableBody >= contentLength else { return nil } // need more data
            let body = data[bodyStart..<(bodyStart + contentLength)]
            return HTTPRequest(method: method, path: path, headers: headers, body: Data(body))
        }

        return HTTPRequest(method: method, path: path, headers: headers, body: nil)
    }

    private nonisolated static func findCRLFCRLF(in data: Data) -> Int? {
        let crlf: [UInt8] = [0x0D, 0x0A, 0x0D, 0x0A]
        guard data.count >= 4 else { return nil }
        for i in 0...(data.count - 4) {
            if data[data.startIndex + i] == crlf[0]
                && data[data.startIndex + i + 1] == crlf[1]
                && data[data.startIndex + i + 2] == crlf[2]
                && data[data.startIndex + i + 3] == crlf[3] {
                return data.startIndex + i
            }
        }
        return nil
    }

    // MARK: - Request Handling

    private func handleHTTPRequest(_ request: HTTPRequest, on connection: NWConnection) {
        // Check authorization
        if let token = authToken {
            let authHeader = request.headers["authorization"] ?? ""
            guard authHeader == "Bearer \(token)" else {
                sendResponse(on: connection, statusCode: 401, body: #"{"error":"Unauthorized"}"#)
                return
            }
        }

        // Route
        guard request.path == "/api/events" else {
            sendResponse(on: connection, statusCode: 404, body: #"{"error":"Not found"}"#)
            return
        }

        guard request.method == "POST" else {
            sendResponse(on: connection, statusCode: 405, body: #"{"error":"Method not allowed"}"#)
            return
        }

        guard let body = request.body, !body.isEmpty else {
            sendResponse(on: connection, statusCode: 400, body: #"{"error":"Bad request"}"#)
            return
        }

        // Parse incoming event
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let incoming = try decoder.decode(IncomingEvent.self, from: body)

            let event = AgentEvent(
                id: UUID(),
                description: incoming.description,
                realDuration: incoming.realDuration,
                estimatedHumanDuration: incoming.estimatedHumanDuration,
                timestamp: incoming.timestamp,
                source: incoming.source,
                status: .pending
            )

            onEvent(event)

            let responseBody = """
            {"status":"ok","id":"\(event.id.uuidString)"}
            """
            sendResponse(on: connection, statusCode: 200, body: responseBody)
        } catch {
            sendResponse(on: connection, statusCode: 400, body: #"{"error":"Bad request"}"#)
        }
    }

    // MARK: - HTTP Response

    private nonisolated func sendResponse(on connection: NWConnection, statusCode: Int, body: String) {
        let statusText: String
        switch statusCode {
        case 200: statusText = "OK"
        case 400: statusText = "Bad Request"
        case 401: statusText = "Unauthorized"
        case 404: statusText = "Not Found"
        case 405: statusText = "Method Not Allowed"
        default: statusText = "Error"
        }

        let responseBody = body.data(using: .utf8) ?? Data()
        let header = "HTTP/1.1 \(statusCode) \(statusText)\r\nContent-Type: application/json\r\nContent-Length: \(responseBody.count)\r\nConnection: close\r\n\r\n"
        var responseData = header.data(using: .utf8) ?? Data()
        responseData.append(responseBody)

        connection.send(content: responseData, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
}

// MARK: - Incoming Event DTO

private nonisolated struct IncomingEvent: Decodable, Sendable {
    let description: String
    let realDuration: Int
    let estimatedHumanDuration: Int
    let timestamp: Date
    let source: String
}
