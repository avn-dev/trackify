import Foundation
import Security

/// Stores and retrieves the Sanctum bearer token from the iOS Keychain.
final class KeychainService: @unchecked Sendable {

    static let shared = KeychainService()

    private let tokenKey = "app.trackify.ios.token"

    var token: String? {
        get { read(key: tokenKey) }
        set {
            if let value = newValue { save(key: tokenKey, value: value) }
            else { delete(key: tokenKey) }
        }
    }

    // MARK: - Keychain ops

    private func save(key: String, value: String) {
        let data = Data(value.utf8)
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData:   data,
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func read(key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrAccount:      key,
            kSecReturnData:       true,
            kSecMatchLimit:       kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else { return nil }
        return string
    }

    private func delete(key: String) {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
