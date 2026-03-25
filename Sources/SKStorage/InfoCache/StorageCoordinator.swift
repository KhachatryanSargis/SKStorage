import Foundation
import SKCore

// MARK: - Storage Coordinator

/// Actor-based coordinator providing unified access to UserDefaults and Keychain storage.
///
/// Wraps two ``DataStorageProtocol`` backends — one for non-sensitive data
/// (UserDefaults) and one for secure data (Keychain) — and adds Codable
/// encoding/decoding on top.
///
/// ## Thread Safety
///
/// Uses Swift actor isolation to serialize all storage access, making it
/// safe to call from any concurrency context.
///
/// ## Usage
///
/// ```swift
/// let coordinator = StorageCoordinator()
///
/// // Non-sensitive storage (UserDefaults)
/// try await coordinator.save("dark", forKey: "theme")
/// let theme: String? = try await coordinator.load(forKey: "theme")
///
/// // Secure storage (Keychain)
/// try await coordinator.save(token, forKey: "auth_token", secure: true)
/// let token: String? = try await coordinator.load(forKey: "auth_token", secure: true)
/// ```
public actor StorageCoordinator {
    // MARK: - Dependencies

    private let userDefaults: DataStorageProtocol
    private let keychain: DataStorageProtocol
    private let logger: (any LoggerProtocol)?

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Init

    /// Creates a `StorageCoordinator` instance.
    ///
    /// - Parameters:
    ///   - userDefaults: Backend for non-sensitive data. Defaults to ``UserDefaultsDataStorage``.
    ///   - keychain: Backend for secure data. Defaults to ``KeychainStorage``.
    ///   - logger: Optional logger for debug diagnostics. Pass `nil` to disable logging.
    public init(
        userDefaults: DataStorageProtocol = UserDefaultsDataStorage(),
        keychain: DataStorageProtocol = KeychainStorage(),
        logger: (any LoggerProtocol)? = nil
    ) {
        self.userDefaults = userDefaults
        self.keychain = keychain
        self.logger = logger
    }

    // MARK: - Public API

    /// Saves a `Codable` value to storage.
    ///
    /// - Parameters:
    ///   - value: The value to encode and store.
    ///   - key: A string identifier for the stored value.
    ///   - secure: If `true`, stores in Keychain. Otherwise uses UserDefaults.
    /// - Throws: An encoding error or a storage backend error.
    public func save<T: Codable & Sendable>(_ value: T, forKey key: String, secure: Bool = false) throws {
        let data = try encoder.encode(value)
        let backend = storage(secure: secure)
        try backend.save(data, forKey: key)
        logger?.debug("Saved value for key: \(key) (secure: \(secure))")
    }

    /// Loads a `Codable` value from storage.
    ///
    /// - Parameters:
    ///   - key: A string identifier for the stored value.
    ///   - secure: If `true`, loads from Keychain. Otherwise uses UserDefaults.
    /// - Returns: The decoded value, or `nil` if no value exists for the key.
    /// - Throws: A decoding error or a storage backend error.
    public func load<T: Codable & Sendable>(forKey key: String, secure: Bool = false) throws -> T? {
        let backend = storage(secure: secure)
        guard let data = try backend.load(forKey: key) else { return nil }
        return try decoder.decode(T.self, from: data)
    }

    /// Deletes a value from storage.
    ///
    /// - Parameters:
    ///   - key: A string identifier for the stored value.
    ///   - secure: If `true`, deletes from Keychain. Otherwise uses UserDefaults.
    /// - Throws: A storage backend error.
    public func delete(forKey key: String, secure: Bool = false) throws {
        let backend = storage(secure: secure)
        try backend.delete(forKey: key)
        logger?.debug("Deleted key: \(key) (secure: \(secure))")
    }

    // MARK: - Private

    private func storage(secure: Bool) -> DataStorageProtocol {
        secure ? keychain : userDefaults
    }
}
