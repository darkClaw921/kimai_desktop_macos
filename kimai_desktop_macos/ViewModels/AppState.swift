import Foundation
import Observation

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

    // Hourly rate for active project
    var activeHourlyRate: Double = 0
    private var cachedRateProjectId: Int?

    // UI state
    var isLoading = false
    var selectedProject: KimaiProject?
    var selectedActivity: KimaiActivity?

    // Polling
    private var pollTimer: Timer?
    private var isRefreshing = false

    var isTracking: Bool {
        activeTimesheet != nil
    }

    /// Current earnings for the active timer based on hourly rate
    var currentEarnings: Double? {
        guard activeTimesheet != nil, activeHourlyRate > 0 else { return nil }
        return activeHourlyRate * (timerService.elapsed / 3600.0)
    }

    private static let earningsFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        f.groupingSeparator = " "
        f.groupingSize = 3
        f.usesGroupingSeparator = true
        return f
    }()

    /// Formatted current earnings string (e.g. "1 234.50 ₽")
    var formattedEarnings: String? {
        guard let earnings = currentEarnings else { return nil }
        let suffix = UserDefaults.standard.string(forKey: "currencySuffix") ?? Constants.Defaults.currencySuffix
        let number = Self.earningsFormatter.string(from: NSNumber(value: earnings)) ?? String(format: "%.2f", earnings)
        return "\(number) \(suffix)"
    }

    var isConfigured: Bool {
        KeychainService.baseURL != nil && KeychainService.apiToken != nil
    }

    // MARK: - Initialization

    func startPolling(interval: TimeInterval = Constants.Defaults.refreshInterval) {
        // Don't restart polling if already active with the same interval
        if pollTimer != nil { return }

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
        guard isConfigured, !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

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
                // Load hourly rate for the active project (cached per projectId)
                if cachedRateProjectId != activeTimesheet.projectId {
                    await loadProjectRate(projectId: activeTimesheet.projectId)
                }
            } else {
                timerService.stop()
                activeHourlyRate = 0
                cachedRateProjectId = nil
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

    private func loadProjectRate(projectId: Int) async {
        // 1. Try local cache of completed timesheets
        // hourlyRate = rate / (duration / 3600)
        let allAvailable = recentTimesheets + allTimesheets
        let reference = allAvailable.first { (ts: KimaiTimesheet) -> Bool in
            guard ts.projectId == projectId, !ts.isActive else { return false }
            guard let r = ts.rate, r > 0 else { return false }
            guard let d = ts.duration, d > 0 else { return false }
            return true
        }
        if let ref = reference, let refRate = ref.rate, let refDuration = ref.duration {
            activeHourlyRate = refRate / (Double(refDuration) / 3600.0)
            cachedRateProjectId = projectId
            return
        }

        // 2. Fetch a completed timesheet for this project from API
        do {
            let projectTimesheets = try await apiClient.fetchTimesheets(page: 1, size: 5, projectId: projectId)
            let apiRef = projectTimesheets.first { (ts: KimaiTimesheet) -> Bool in
                guard !ts.isActive else { return false }
                guard let r = ts.rate, r > 0 else { return false }
                guard let d = ts.duration, d > 0 else { return false }
                return true
            }
            if let ref = apiRef, let refRate = ref.rate, let refDuration = ref.duration {
                activeHourlyRate = refRate / (Double(refDuration) / 3600.0)
                cachedRateProjectId = projectId
                return
            }
        } catch {
            print("[DEBUG] loadProjectRate fetch timesheets error: \(error)")
        }

        // 3. Try project rates API
        do {
            let rates = try await apiClient.fetchProjectRates(projectId: projectId)
            let hourlyRates = rates.filter { !$0.isFixed }
            let rate = hourlyRates.first { $0.user != nil } ?? hourlyRates.first
            if let rateValue = rate?.rate, rateValue > 0 {
                activeHourlyRate = rateValue
                cachedRateProjectId = projectId
                return
            }
        } catch {
            print("[DEBUG] loadProjectRate project rates error: \(error)")
        }

        // 4. Try activity rates API
        if let activeTimesheet {
            do {
                let rates = try await apiClient.fetchActivityRates(activityId: activeTimesheet.activityId)
                let hourlyRates = rates.filter { !$0.isFixed }
                let rate = hourlyRates.first { $0.user != nil } ?? hourlyRates.first
                if let rateValue = rate?.rate, rateValue > 0 {
                    activeHourlyRate = rateValue
                    cachedRateProjectId = projectId
                    return
                }
            } catch {
                print("[DEBUG] loadProjectRate activity rates error: \(error)")
            }
        }

        // Rate not found — do NOT cache so it retries on next poll
        activeHourlyRate = 0
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
            await refresh()
        } catch {
            connectionError = error.localizedDescription
        }
    }

    func testConnection() async throws -> Bool {
        try await apiClient.testConnection()
    }
}
