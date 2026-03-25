import Foundation
import Security

// MARK: - Keychain Operations Protocol

/// Abstracts Security framework keychain operations for testability.
///
/// The default implementation (``SystemKeychainOperations``) delegates
/// directly to `SecItemAdd`, `SecItemCopyMatching`, and `SecItemDelete`.
/// In tests, inject ``MockKeychainOperations`` to avoid hitting the real keychain.
public protocol KeychainOperations: Sendable {
    /// Adds an item to the keychain.
    func add(_ query: CFDictionary) -> OSStatus

    /// Searches for a keychain item matching the query.
    func copyMatching(_ query: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus

    /// Deletes a keychain item matching the query.
    func delete(_ query: CFDictionary) -> OSStatus
}

// MARK: - System Keychain Operations

/// Production implementation of ``KeychainOperations`` using the Security framework.
public struct SystemKeychainOperations: KeychainOperations {
    public init() {}

    public func add(_ query: CFDictionary) -> OSStatus {
        SecItemAdd(query, nil)
    }

    public func copyMatching(_ query: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus {
        SecItemCopyMatching(query, result)
    }

    public func delete(_ query: CFDictionary) -> OSStatus {
        SecItemDelete(query)
    }
}

// MARK: - Keychain Error

/// Errors produced by ``KeychainStorage`` operations.
public enum KeychainError: Error, LocalizedError, Sendable {
    /// The save operation failed with the given `OSStatus` code.
    case saveFailed(OSStatus)

    /// The load operation failed with the given `OSStatus` code.
    case loadFailed(OSStatus)

    /// The delete operation failed with the given `OSStatus` code.
    case deleteFailed(OSStatus)

    public var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            "Keychain save failed with status: \(status)"
        case .loadFailed(let status):
            "Keychain load failed with status: \(status)"
        case .deleteFailed(let status):
            "Keychain delete failed with status: \(status)"
        }
    }
}

// MARK: - Keychain Storage

/// Secure data storage backed by the system Keychain.
///
/// Stores raw `Data` blobs as `kSecClassGenericPassword` items, keyed
/// by a service identifier and an account string. Items are protected
/// with `kSecAttrAccessibleAfterFirstUnlock`.
///
/// ## Thread Safety
///
/// `KeychainStorage` is a value type whose stored properties are all
/// `Sendable`. The underlying Security framework functions are thread-safe.
///
/// ## Usage
///
/// ```swift
/// let keychain = KeychainStorage(service: "com.example.myapp")
/// try keychain.save(tokenData, forKey: "auth_token")
/// let data = try keychain.load(forKey: "auth_token")
/// ```
public struct KeychainStorage: DataStorageProtocol {
    // MARK: - Dependencies

    private let service: String
    private let keychain: KeychainOperations

    // MARK: - Init

    /// Creates a `KeychainStorage` instance.
    ///
    /// - Parameters:
    ///   - service: Service identifier for keychain items.
    ///     Defaults to the app's bundle identifier.
    ///   - keychain: Keychain operations implementation.
    ///     Defaults to ``SystemKeychainOperations``.
    public init(
        service: String? = nil,
        keychain: KeychainOperations = SystemKeychainOperations()
    ) {
        self.service = service ?? Bundle.main.bundleIdentifier ?? "com.sk.storage.keychain"
        self.keychain = keychain
    }

    // MARK: - DataStorageProtocol

    public func save(_ data: Data, forKey key: String) throws {
        // Delete any existing item first to avoid errSecDuplicateItem.
        try? delete(forKey: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = keychain.add(query as CFDictionary)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    public func load(forKey key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = keychain.copyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeychainError.loadFailed(status)
        }

        return result as? Data
    }

    public func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = keychain.delete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}
