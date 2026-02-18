import Foundation
import Security

nonisolated enum KeychainService {
    static func save(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.keychainService,
            kSecAttrAccount as String: key,
        ]

        SecItemDelete(query as CFDictionary)

        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        return status == errSecSuccess
    }

    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.keychainService,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Convenience

    static var apiToken: String? {
        get { load(key: Constants.keychainAPITokenKey) }
        set {
            if let newValue {
                _ = save(key: Constants.keychainAPITokenKey, value: newValue)
            } else {
                delete(key: Constants.keychainAPITokenKey)
            }
        }
    }

    static var baseURL: String? {
        get { load(key: Constants.keychainBaseURLKey) }
        set {
            if let newValue {
                _ = save(key: Constants.keychainBaseURLKey, value: newValue)
            } else {
                delete(key: Constants.keychainBaseURLKey)
            }
        }
    }
}
