import Foundation

nonisolated struct KimaiActivity: Codable, Identifiable, Sendable, Hashable {
    let id: Int
    let name: String
    let project: Int?
    let visible: Bool
    let color: String?

    // Extra fields from API (ignored in Hashable/Equatable)
    let parentTitle: String?
    let comment: String?

    enum CodingKeys: String, CodingKey {
        case id, name, project, visible, color, parentTitle, comment
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        project = try container.decodeIfPresent(Int.self, forKey: .project)
        visible = try container.decodeIfPresent(Bool.self, forKey: .visible) ?? true
        color = try container.decodeIfPresent(String.self, forKey: .color)
        parentTitle = try container.decodeIfPresent(String.self, forKey: .parentTitle)
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
    }

    static func == (lhs: KimaiActivity, rhs: KimaiActivity) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
