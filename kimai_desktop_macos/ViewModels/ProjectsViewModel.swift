import Foundation
import Observation

struct CustomerGroup: Identifiable {
    let name: String
    let projects: [KimaiProject]
    var id: String { name }
}

@Observable
final class ProjectsViewModel {
    var searchText = ""

    func filteredProjects(from projects: [KimaiProject]) -> [KimaiProject] {
        if searchText.isEmpty {
            return projects
        }
        return projects.filter { $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.customerName.localizedCaseInsensitiveContains(searchText)
        }
    }

    func groupedByCustomer(from projects: [KimaiProject]) -> [CustomerGroup] {
        let filtered = filteredProjects(from: projects)
        let grouped = Dictionary(grouping: filtered) { $0.customerName.isEmpty ? "Без клиента" : $0.customerName }
        return grouped
            .map { CustomerGroup(name: $0.key, projects: $0.value) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func projectTimesheets(projectId: Int, from timesheets: [KimaiTimesheet]) -> [KimaiTimesheet] {
        timesheets.filter { $0.projectId == projectId }
    }

    func customerTotalDuration(projects: [KimaiProject], from timesheets: [KimaiTimesheet]) -> Int {
        projects.reduce(0) { $0 + projectTotalDuration(projectId: $1.id, from: timesheets) }
    }

    func projectTotalDuration(projectId: Int, from timesheets: [KimaiTimesheet]) -> Int {
        projectTimesheets(projectId: projectId, from: timesheets)
            .compactMap(\.duration)
            .reduce(0, +)
    }

    func projectTotalEarnings(projectId: Int, from timesheets: [KimaiTimesheet]) -> Double {
        projectTimesheets(projectId: projectId, from: timesheets)
            .compactMap(\.rate)
            .reduce(0, +)
    }

    func customerTotalEarnings(projects: [KimaiProject], from timesheets: [KimaiTimesheet]) -> Double {
        projects.reduce(0) { $0 + projectTotalEarnings(projectId: $1.id, from: timesheets) }
    }
}
