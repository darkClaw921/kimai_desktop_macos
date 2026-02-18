import Foundation
import Observation

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

    func projectTimesheets(projectId: Int, from timesheets: [KimaiTimesheet]) -> [KimaiTimesheet] {
        timesheets.filter { $0.projectId == projectId }
    }

    func projectTotalDuration(projectId: Int, from timesheets: [KimaiTimesheet]) -> Int {
        projectTimesheets(projectId: projectId, from: timesheets)
            .compactMap(\.duration)
            .reduce(0, +)
    }
}
