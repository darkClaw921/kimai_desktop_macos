import Foundation

nonisolated enum EventStatus: String, Codable, Sendable {
    case pending, processed, dismissed
}

nonisolated struct AgentEvent: Codable, Identifiable, Sendable {
    let id: UUID
    let description: String
    let realDuration: Int           // секунды
    let estimatedHumanDuration: Int // секунды
    let timestamp: Date
    let source: String
    var status: EventStatus
}
