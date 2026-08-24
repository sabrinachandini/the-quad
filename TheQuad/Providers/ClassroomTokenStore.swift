import Foundation
import Security

final class ClassroomTokenStore {
    static let shared = ClassroomTokenStore()
    private init() {}

    private let service = "com.thequad.app.classroom"
    private let account = "oauth.tokens"

    private struct TokenBundle: Codable {
        var accessToken: String
        var refreshToken: String?
        var expiresAt: Date?
        var email: String?
    }

    func save(accessToken: String, refreshToken: String?, expiresAt: Date?, email: String? = nil) throws {
        let bundle = TokenBundle(accessToken: accessToken, refreshToken: refreshToken, expiresAt: expiresAt, email: email)
        let data = try JSONEncoder().encode(bundle)

        // Delete existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw ClassroomTokenStoreError.keychainError(status)
        }
    }

    func loadAccessToken() throws -> String? {
        try loadBundle()?.accessToken
    }

    func loadRefreshToken() throws -> String? {
        try loadBundle()?.refreshToken
    }

    func loadExpiry() throws -> Date? {
        try loadBundle()?.expiresAt
    }

    func loadEmail() throws -> String? {
        try loadBundle()?.email
    }

    func delete() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw ClassroomTokenStoreError.keychainError(status)
        }
    }

    private func loadBundle() throws -> TokenBundle? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            if status == errSecItemNotFound { return nil }
            throw ClassroomTokenStoreError.keychainError(status)
        }
        return try JSONDecoder().decode(TokenBundle.self, from: data)
    }
}

enum ClassroomTokenStoreError: Error {
    case keychainError(OSStatus)
}
