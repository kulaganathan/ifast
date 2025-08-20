import Foundation
import Security

public protocol TokenStore: Sendable {
    func save(_ tokens: TokenPair) throws
    func load() throws -> TokenPair?
    func delete() throws
}

public enum TokenStoreError: Error {
    case encoding
    case keychain(OSStatus)
}

public final class KeychainTokenStore: TokenStore {
    private let service = "com.iFast.AuthAPI.TokenStore"
    private let account = "default"
    
    public init() {}
    
    public func save(_ tokens: TokenPair) throws {
        let data = try JSONEncoder().encode(tokens)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        var addQuery = query
        addQuery[kSecValueData as String] = data
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else { 
            #if DEBUG
            print("Keychain save failed with status: \(status)")
            #endif
            throw TokenStoreError.keychain(status) 
        }
    }
    
    public func load() throws -> TokenPair? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = item as? Data else { 
            #if DEBUG
            print("Keychain load failed with status: \(status)")
            #endif
            throw TokenStoreError.keychain(status) 
        }
        return try JSONDecoder().decode(TokenPair.self, from: data)
    }
    
    public func delete() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { 
            #if DEBUG
            print("Keychain delete failed with status: \(status)")
            #endif
            throw TokenStoreError.keychain(status) 
        }
    }
}


