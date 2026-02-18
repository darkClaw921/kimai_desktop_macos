import Foundation
import Observation

@Observable
final class TimesheetViewModel {
    var filterProject: KimaiProject?
    var filterDateFrom: Date?
    var filterDateTo: Date?
    var searchText = ""

    func filteredTimesheets(
        from timesheets: [KimaiTimesheet],
        projects: [KimaiProject] = [],
        activities: [KimaiActivity] = []
    ) -> [KimaiTimesheet] {
        timesheets.filter { timesheet in
            if let filterProject, timesheet.projectId != filterProject.id {
                return false
            }
            if let filterDateFrom, let begin = timesheet.beginDate, begin < filterDateFrom {
                return false
            }
            if let filterDateTo, let begin = timesheet.beginDate, begin > filterDateTo {
                return false
            }
            if !searchText.isEmpty {
                let text = searchText.lowercased()
                let projectName = timesheet.resolvedProjectName(from: projects)
                let activityName = timesheet.resolvedActivityName(from: activities)
                let matchesProject = projectName.lowercased().contains(text)
                let matchesActivity = activityName.lowercased().contains(text)
                let matchesDescription = timesheet.description?.lowercased().contains(text) ?? false
                return matchesProject || matchesActivity || matchesDescription
            }
            return true
        }
    }

    func todayTimesheets(from timesheets: [KimaiTimesheet]) -> [KimaiTimesheet] {
        let calendar = Calendar.current
        return timesheets.filter { timesheet in
            guard let begin = timesheet.beginDate else { return false }
            return calendar.isDateInToday(begin)
        }
    }

    func weekTimesheets(from timesheets: [KimaiTimesheet]) -> [KimaiTimesheet] {
        let calendar = Calendar.current
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date.now)) else {
            return []
        }
        return timesheets.filter { timesheet in
            guard let begin = timesheet.beginDate else { return false }
            return begin >= weekStart
        }
    }

    func totalDuration(of timesheets: [KimaiTimesheet]) -> Int {
        timesheets.compactMap(\.duration).reduce(0, +)
    }
}
