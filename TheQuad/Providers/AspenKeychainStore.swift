import Foundation
import Security

// MARK: - Errors

enum AspenKeychainError: Error, LocalizedError {
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
    case deleteFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Keychain save failed (OSStatus \(status))"
        case .loadFailed(let status):
            return "Keychain load failed (OSStatus \(status))"
        case .deleteFailed(let status):
            return "Keychain delete failed (OSStatus \(status))"
        }
    }
}

// MARK: - Store

/// Device-local keychain storage for Aspen credentials.
/// Never touches UserDefaults or any cloud sync path.
final class AspenKeychainStore {
    static let shared = AspenKeychainStore()

    private let service = "com.thequad.app.aspen"
    private let usernameAccount = "aspen_username"
    private let passwordAccount = "aspen_password"

    private init() {}

    // MARK: - Public API

    func save(username: String, password: String) throws {
        try saveItem(account: usernameAccount, value: username)
        try saveItem(account: passwordAccount, value: password)
    }

    func load() throws -> (username: String, password: String)? {
        guard let username = try loadItem(account: usernameAccount),
              let password = try loadItem(account: passwordAccount) else {
            return nil
        }
        return (username: username, password: password)
    }

    func delete() throws {
        try deleteItem(account: usernameAccount)
        try deleteItem(account: passwordAccount)
    }

    // MARK: - Private Helpers

    private func saveItem(account: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw AspenKeychainError.saveFailed(errSecParam)
        }

        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ]
        let attributes: [CFString: Any] = [
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData] = data
            addQuery[kSecAttrAccessible] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw AspenKeychainError.saveFailed(addStatus)
            }
        } else if updateStatus != errSecSuccess {
            throw AspenKeychainError.saveFailed(updateStatus)
        }
    }

    private func loadItem(account: String) throws -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw AspenKeychainError.loadFailed(status)
        }
        guard let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }

    private func deleteItem(account: String) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AspenKeychainError.deleteFailed(status)
        }
    }
}
