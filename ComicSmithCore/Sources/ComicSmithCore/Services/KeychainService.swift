import Foundation
import Security

public final class KeychainService {
    private let serviceName: String
    
    public enum KeychainError: LocalizedError {
        case unhandledError(status: OSStatus)
        case noData
        case unexpectedData
        
        public var errorDescription: String? {
            switch self {
            case .unhandledError(let status):
                return "Keychain error: \(status)"
            case .noData:
                return "No data found in keychain"
            case .unexpectedData:
                return "Unexpected data format in keychain"
            }
        }
    }
    
    public init(serviceName: String = "ComicSmith") {
        self.serviceName = serviceName
    }
    
    // MARK: - API Key Management
    
    public func saveAPIKey(_ apiKey: String, for service: String = "gemini") throws {
        let account = "\(service).apiKey"
        let data = apiKey.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        // Try to update existing item first
        let updateQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account
        ]
        
        let updateAttributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        var status = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
        
        // If item doesn't exist, add it
        if status == errSecItemNotFound {
            status = SecItemAdd(query as CFDictionary, nil)
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    public func getAPIKey(for service: String = "gemini") throws -> String {
        let account = "\(service).apiKey"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status != errSecItemNotFound else {
            throw KeychainError.noData
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
        
        guard let data = item as? Data,
              let apiKey = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedData
        }
        
        return apiKey
    }
    
    public func deleteAPIKey(for service: String = "gemini") throws {
        let account = "\(service).apiKey"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    public func hasAPIKey(for service: String = "gemini") -> Bool {
        do {
            _ = try getAPIKey(for: service)
            return true
        } catch {
            return false
        }
    }
}