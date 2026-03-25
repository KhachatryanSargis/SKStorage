import Foundation

// MARK: - Storage Protocol

/// A protocol for raw data storage backends (UserDefaults, Keychain, etc.).
///
/// Unlike SKCore's type-safe `StorageProtocol` (which uses phantom-typed keys),
/// this protocol works with raw `Data` and plain `String` keys. It serves as the
/// foundation for ``StorageCoordinator``, which adds Codable encoding on top.
///
/// Conforming types must be `Sendable` for safe use across concurrency domains.
///
/// ## Implementations
///
/// - ``UserDefaultsDataStorage``: Non-sensitive preferences and cached settings.
/// - ``KeychainStorage``: Sensitive data (tokens, credentials, PII).
///
/// ## Usage
///
/// ```swift
/// let storage: any DataStorageProtocol = UserDefaultsDataStorage()
/// try storage.save(Data("token".utf8), forKey: "auth_token")
/// let data = try storage.load(forKey: "auth_token")
/// ```
public protocol DataStorageProtocol: Sendable {
    /// Persists raw data for the given key.
    ///
    /// - Parameters:
    ///   - data: The raw data to store.
    ///   - key: A string identifier for the stored value.
    /// - Throws: An error if the save operation fails.
    func save(_ data: Data, forKey key: String) throws

    /// Loads raw data for the given key.
    ///
    /// - Parameter key: A string identifier for the stored value.
    /// - Returns: The stored data, or `nil` if no value exists for the key.
    /// - Throws: An error if the load operation fails (not including "not found").
    func load(forKey key: String) throws -> Data?

    /// Deletes the value for the given key.
    ///
    /// - Parameter key: A string identifier for the stored value.
    /// - Throws: An error if the delete operation fails.
    func delete(forKey key: String) throws
}
