import Foundation
import Observation
import WidgetKit

@Observable
final class AppState {
    let apiClient = KimaiAPIClient()
    let timerService = TimerService()

    // Connection
    var isConnected = false
    var connectionError: String?

    // Active tracking
    var activeTimesheet: KimaiTimesheet?
    var recentTimesheets: [KimaiTimesheet] = []

    // Data
    var projects: [KimaiProject] = []
    var activities: [KimaiActivity] = []       // filtered by selected project (for pickers)
    var allActivities: [KimaiActivity] = []    // all activities (for name resolution)
    var allTimesheets: [KimaiTimesheet] = []
    var currentHistoryPage = 1
    var hasMoreHistory = true

    // UI state
    var isLoading = false
    var selectedProject: KimaiProject?
    var selectedActivity: KimaiActivity?

    // Polling
    private var pollTimer: Timer?

    var isTracking: Bool {
        activeTimesheet != nil
    }

    var isConfigured: Bool {
        KeychainService.baseURL != nil && KeychainService.apiToken != nil
    }

    // MARK: - Initialization

    func startPolling(interval: TimeInterval = Constants.Defaults.refreshInterval) {
        stopPolling()
        Task { await refresh() }
        pollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refresh()
            }
        }
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    // MARK: - Data Loading

    func refresh() async {
        guard isConfigured else { return }

        do {
            if projects.isEmpty {
                try? await loadProjectsAndActivities()
            }

            let active = try await apiClient.fetchActiveTimesheets()
            let recent = try await apiClient.fetchRecentTimesheets()

            activeTimesheet = active.first
            recentTimesheets = recent

            if let activeTimesheet, let beginDate = activeTimesheet.beginDate {
                timerService.start(from: beginDate)
                syncWidgetState(tracking: true, timesheet: activeTimesheet)
            } else {
                timerService.stop()
                syncWidgetState(tracking: false, timesheet: nil)
            }

            isConnected = true
            connectionError = nil
        } catch {
            isConnected = false
            connectionError = error.localizedDescription
        }
    }

    func loadProjects() async {
        do {
            projects = try await apiClient.fetchProjects()
        } catch {
            connectionError = error.localizedDescription
        }
    }

    func loadActivities(for project: KimaiProject) async {
        do {
            activities = try await apiClient.fetchActivities(projectId: project.id)
        } catch {
            connectionError = error.localizedDescription
        }
    }

    /// Loads all activities (not filtered by project) for name resolution
    func loadAllActivities() async {
        do {
            allActivities = try await apiClient.fetchActivities()
        } catch {
            connectionError = error.localizedDescription
        }
    }

    private func loadProjectsAndActivities() async throws {
        projects = try await apiClient.fetchProjects()
        allActivities = try await apiClient.fetchActivities()
    }

    // MARK: - Name Resolution

    func resolvedProjectName(for timesheet: KimaiTimesheet) -> String {
        timesheet.resolvedProjectName(from: projects)
    }

    func resolvedActivityName(for timesheet: KimaiTimesheet) -> String {
        timesheet.resolvedActivityName(from: allActivities)
    }

    func loadHistory(reset: Bool = false) async {
        if reset {
            currentHistoryPage = 1
            allTimesheets = []
            hasMoreHistory = true
        }

        guard hasMoreHistory else { return }

        do {
            let page = try await apiClient.fetchTimesheets(
                page: currentHistoryPage,
                size: Constants.Defaults.historyPageSize
            )
            if reset {
                allTimesheets = page
            } else {
                allTimesheets.append(contentsOf: page)
            }
            hasMoreHistory = page.count == Constants.Defaults.historyPageSize
            currentHistoryPage += 1
        } catch {
            connectionError = error.localizedDescription
        }
    }

    // MARK: - Timer Actions

    func startTimer(project: KimaiProject, activity: KimaiActivity, description: String? = nil) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let timesheet = try await apiClient.startTimesheet(
                projectId: project.id,
                activityId: activity.id,
                description: description
            )
            activeTimesheet = timesheet
            if let beginDate = timesheet.beginDate {
                timerService.start(from: beginDate)
            }
            syncWidgetState(tracking: true, timesheet: timesheet)
            WidgetCenter.shared.reloadAllTimelines()
            await refresh()
        } catch {
            connectionError = error.localizedDescription
        }
    }

    func stopTimer() async {
        guard let activeTimesheet else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await apiClient.stopTimesheet(id: activeTimesheet.id)
            self.activeTimesheet = nil
            timerService.stop()
            syncWidgetState(tracking: false, timesheet: nil)
            WidgetCenter.shared.reloadAllTimelines()
            await refresh()
        } catch {
            connectionError = error.localizedDescription
        }
    }

    func restartTimesheet(_ timesheet: KimaiTimesheet) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let restarted = try await apiClient.restartTimesheet(id: timesheet.id)
            activeTimesheet = restarted
            if let beginDate = restarted.beginDate {
                timerService.start(from: beginDate)
            }
            syncWidgetState(tracking: true, timesheet: restarted)
            WidgetCenter.shared.reloadAllTimelines()
            await refresh()
        } catch {
            connectionError = error.localizedDescription
        }
    }

    func testConnection() async throws -> Bool {
        try await apiClient.testConnection()
    }

    // MARK: - Widget Sync

    private func syncWidgetState(tracking: Bool, timesheet: KimaiTimesheet?) {
        if tracking, let timesheet {
            SharedDefaults.updateTrackingState(
                isTracking: true,
                projectName: resolvedProjectName(for: timesheet),
                activityName: resolvedActivityName(for: timesheet),
                startDate: timesheet.beginDate
            )
        } else {
            SharedDefaults.clearTracking()
        }
    }
}
