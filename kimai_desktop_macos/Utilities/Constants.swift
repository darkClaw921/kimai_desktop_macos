import Foundation

nonisolated enum Constants {
    static let keychainService = "com.alteran.industries.kimai-desktop-macos"
    static let keychainAPITokenKey = "kimai-api-token"
    static let keychainBaseURLKey = "kimai-base-url"

    enum Defaults {
        static let refreshInterval: TimeInterval = 30
        static let recentTimesheetsCount = 5
        static let historyPageSize = 50
        static let currencySuffix = "₽"
    }

    enum Webhook {
        static let defaultPort: UInt16 = 29876
        static let portUserDefaultsKey = "webhookPort"
        static let tokenKeychainKey = "webhook-auth-token"
    }

    enum EventStorage {
        static let fileName = "agent_events.json"
    }
}
