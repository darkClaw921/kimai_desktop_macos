import Foundation

nonisolated struct KimaiTimesheet: Codable, Identifiable, Sendable {
    let id: Int
    let begin: String
    let end: String?
    let duration: Int?
    let projectId: Int
    let projectName: String?
    let activityId: Int
    let activityName: String?
    let description: String?
    let tags: [String]?
    let rate: Double?

    // MARK: - Custom Codable (project/activity can be Int or Object)

    enum CodingKeys: String, CodingKey {
        case id, begin, end, duration, project, activity, description, tags, rate
    }

    private struct ProjectRef: Decodable {
        let id: Int
        let name: String
    }

    private struct ActivityRef: Decodable {
        let id: Int
        let name: String
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        begin = try container.decode(String.self, forKey: .begin)
        end = try container.decodeIfPresent(String.self, forKey: .end)
        duration = try container.decodeIfPresent(Int.self, forKey: .duration)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        tags = try container.decodeIfPresent([String].self, forKey: .tags)
        rate = try container.decodeIfPresent(Double.self, forKey: .rate)

        // Project: Int or Object
        if let obj = try? container.decode(ProjectRef.self, forKey: .project) {
            projectId = obj.id
            projectName = obj.name
        } else {
            projectId = (try? container.decode(Int.self, forKey: .project)) ?? 0
            projectName = nil
        }

        // Activity: Int or Object
        if let obj = try? container.decode(ActivityRef.self, forKey: .activity) {
            activityId = obj.id
            activityName = obj.name
        } else {
            activityId = (try? container.decode(Int.self, forKey: .activity)) ?? 0
            activityName = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(begin, forKey: .begin)
        try container.encodeIfPresent(end, forKey: .end)
        try container.encodeIfPresent(duration, forKey: .duration)
        try container.encode(projectId, forKey: .project)
        try container.encode(activityId, forKey: .activity)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(tags, forKey: .tags)
        try container.encodeIfPresent(rate, forKey: .rate)
    }

    // MARK: - Computed

    var isActive: Bool {
        end == nil
    }

    var beginDate: Date? {
        DateFormatting.parseKimaiDate(begin)
    }

    var endDate: Date? {
        guard let end else { return nil }
        return DateFormatting.parseKimaiDate(end)
    }

    var formattedDuration: String {
        if let duration, duration > 0 {
            return DateFormatting.formatDuration(duration)
        }
        if let beginDate {
            let elapsed = Date.now.timeIntervalSince(beginDate)
            return DateFormatting.formatElapsed(elapsed)
        }
        return "--:--"
    }

    /// Returns embedded name or falls back to placeholder
    func resolvedProjectName(from projects: [KimaiProject]) -> String {
        if let projectName { return projectName }
        return projects.first { $0.id == projectId }?.name ?? "Project #\(projectId)"
    }

    func resolvedActivityName(from activities: [KimaiActivity]) -> String {
        if let activityName { return activityName }
        return activities.first { $0.id == activityId }?.name ?? "Activity #\(activityId)"
    }
}

nonisolated struct CreateTimesheetRequest: Encodable, Sendable {
    let begin: String
    let project: Int
    let activity: Int
    let description: String?

    init(project: Int, activity: Int, description: String? = nil) {
        self.begin = DateFormatting.formatForAPI(Date.now)
        self.project = project
        self.activity = activity
        self.description = description
    }
}
