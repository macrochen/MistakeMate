import Foundation
import Security

struct KeychainService {
    static let shared = KeychainService()
    static let geminiKey = "com.mistakemate.gemini-api-key"

    func save(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidValue
        }

        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key
        ]

        let attributes: [CFString: Any] = [
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecSuccess { return }

        guard status == errSecItemNotFound else {
            throw KeychainError.unhandledStatus(status)
        }

        var createQuery = query
        createQuery[kSecValueData] = data
        createQuery[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let createStatus = SecItemAdd(createQuery as CFDictionary, nil)
        guard createStatus == errSecSuccess else {
            throw KeychainError.unhandledStatus(createStatus)
        }
    }

    func load(key: String) throws -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else {
            throw KeychainError.unhandledStatus(status)
        }

        guard let data = result as? Data else {
            throw KeychainError.invalidValue
        }

        return String(data: data, encoding: .utf8)
    }

    func delete(key: String) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledStatus(status)
        }
    }
}

enum KeychainError: LocalizedError {
    case invalidValue
    case unhandledStatus(OSStatus)

    var errorDescription: String? {
        switch self {
        case .invalidValue:
            return "Keychain 数据格式无效"
        case .unhandledStatus(let status):
            return "Keychain 操作失败：\(status)"
        }
    }
}
