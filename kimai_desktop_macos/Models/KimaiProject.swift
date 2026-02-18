import Foundation

nonisolated struct KimaiProject: Codable, Identifiable, Sendable, Hashable {
    let id: Int
    let name: String
    let customer: Int
    let parentTitle: String?
    let visible: Bool
    let color: String?

    var customerName: String {
        parentTitle ?? ""
    }

    var displayName: String {
        if let parentTitle, !parentTitle.isEmpty {
            return "\(parentTitle) — \(name)"
        }
        return name
    }
}
