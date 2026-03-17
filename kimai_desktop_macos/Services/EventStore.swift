import Foundation
import Observation

@Observable
final class EventStore {
    private(set) var events: [AgentEvent] = []

    var pendingEvents: [AgentEvent] {
        events.filter { $0.status == .pending }
    }

    var pendingCount: Int {
        pendingEvents.count
    }

    init() {
        load()
    }

    // MARK: - Public Methods

    func add(_ event: AgentEvent) {
        events.append(event)
        save()
    }

    func dismiss(_ eventId: UUID) {
        guard let index = events.firstIndex(where: { $0.id == eventId }) else { return }
        events[index].status = .dismissed
        save()
    }

    func markProcessed(_ eventIds: [UUID]) {
        let idSet = Set(eventIds)
        for index in events.indices where idSet.contains(events[index].id) {
            events[index].status = .processed
        }
        save()
    }

    func remove(_ eventId: UUID) {
        events.removeAll { $0.id == eventId }
        save()
    }

    // MARK: - Persistence

    private var fileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let bundleId = Bundle.main.bundleIdentifier ?? "com.alteran.industries.kimai-desktop-macos"
        let directory = appSupport.appendingPathComponent(bundleId)
        return directory.appendingPathComponent(Constants.EventStorage.fileName)
    }

    private func load() {
        let url = fileURL
        guard FileManager.default.fileExists(atPath: url.path) else { return }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            events = try decoder.decode([AgentEvent].self, from: data)
        } catch {
            events = []
        }
    }

    private func save() {
        let url = fileURL
        let directory = url.deletingLastPathComponent()

        do {
            if !FileManager.default.fileExists(atPath: directory.path) {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            }

            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(events)
            try data.write(to: url, options: .atomic)
        } catch {
            // Silently handle write errors — events remain in memory
        }
    }
}
