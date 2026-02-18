import Foundation

enum SharedDefaults {
    private static var suite: UserDefaults? {
        UserDefaults(suiteName: Constants.appGroupID)
    }

    static var isTracking: Bool {
        get { suite?.bool(forKey: Constants.SharedDefaultsKeys.isTracking) ?? false }
        set { suite?.set(newValue, forKey: Constants.SharedDefaultsKeys.isTracking) }
    }

    static var currentProjectName: String? {
        get { suite?.string(forKey: Constants.SharedDefaultsKeys.currentProjectName) }
        set { suite?.set(newValue, forKey: Constants.SharedDefaultsKeys.currentProjectName) }
    }

    static var currentActivityName: String? {
        get { suite?.string(forKey: Constants.SharedDefaultsKeys.currentActivityName) }
        set { suite?.set(newValue, forKey: Constants.SharedDefaultsKeys.currentActivityName) }
    }

    static var trackingStartDate: Date? {
        get { suite?.object(forKey: Constants.SharedDefaultsKeys.trackingStartDate) as? Date }
        set { suite?.set(newValue, forKey: Constants.SharedDefaultsKeys.trackingStartDate) }
    }

    static var lastSyncDate: Date? {
        get { suite?.object(forKey: Constants.SharedDefaultsKeys.lastSyncDate) as? Date }
        set { suite?.set(newValue, forKey: Constants.SharedDefaultsKeys.lastSyncDate) }
    }

    static func updateTrackingState(
        isTracking: Bool,
        projectName: String? = nil,
        activityName: String? = nil,
        startDate: Date? = nil
    ) {
        self.isTracking = isTracking
        self.currentProjectName = projectName
        self.currentActivityName = activityName
        self.trackingStartDate = startDate
        self.lastSyncDate = Date.now
    }

    static func clearTracking() {
        updateTrackingState(isTracking: false)
    }
}
