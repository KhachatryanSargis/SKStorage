import Foundation

// MARK: - UserDefaults Data Storage

/// Raw-data storage backed by `UserDefaults`.
///
/// Unlike SKCore's `UserDefaultsStorage` (which uses phantom-typed `StorageKey<V>`
/// and encodes via `JSONEncoder`), this type stores and retrieves raw `Data` blobs
/// with plain `String` keys. It is designed for use with ``StorageCoordinator``,
/// which handles Codable encoding/decoding at a higher level.
///
/// ## Thread Safety
///
/// `UserDefaults` is thread-safe per Apple documentation.
/// Marked `nonisolated(unsafe)` because `UserDefaults` does not formally
/// conform to `Sendable`, but Apple guarantees thread-safe access.
///
/// ## Usage
///
/// ```swift
/// let storage = UserDefaultsDataStorage()
/// try storage.save(Data("hello".utf8), forKey: "greeting")
/// let data = try storage.load(forKey: "greeting")
/// ```
public struct UserDefaultsDataStorage: DataStorageProtocol {
    // MARK: - Dependencies

    // UserDefaults is thread-safe per Apple documentation.
    private nonisolated(unsafe) let defaults: UserDefaults

    // MARK: - Init

    /// Creates a `UserDefaultsDataStorage` instance.
    ///
    /// - Parameter defaults: The `UserDefaults` suite to use. Defaults to `.standard`.
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - DataStorageProtocol

    public func save(_ data: Data, forKey key: String) throws {
        defaults.set(data, forKey: key)
    }

    public func load(forKey key: String) throws -> Data? {
        defaults.data(forKey: key)
    }

    public func delete(forKey key: String) throws {
        defaults.removeObject(forKey: key)
    }
}
