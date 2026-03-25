import Foundation
@testable import SKStorage

/// In-memory mock for ``DataStorageProtocol`` with configurable behavior.
///
/// Supports both success and failure paths via `Result`-based stubs,
/// and tracks all calls for verification in tests.
///
/// ## Usage
///
/// ```swift
/// let mock = MockDataStorage()
/// let coordinator = StorageCoordinator(userDefaults: mock)
///
/// // Verify interactions
/// #expect(mock.saveCallCount == 1)
///
/// // Simulate failure
/// mock.saveResult = .failure(TestError.stub("save failed"))
/// ```
final class MockDataStorage: DataStorageProtocol, @unchecked Sendable {
    // MARK: - Storage

    private var store: [String: Data] = [:]

    // MARK: - Stubs

    var saveResult: Result<Void, Error> = .success(())
    var loadResult: Result<Data?, Error>?
    var deleteResult: Result<Void, Error> = .success(())

    // MARK: - Call Tracking

    private(set) var saveCallCount = 0
    private(set) var loadCallCount = 0
    private(set) var deleteCallCount = 0
    private(set) var savedKeys: [String] = []
    private(set) var loadedKeys: [String] = []
    private(set) var deletedKeys: [String] = []

    // MARK: - DataStorageProtocol

    func save(_ data: Data, forKey key: String) throws {
        saveCallCount += 1
        savedKeys.append(key)
        try saveResult.get()
        store[key] = data
    }

    func load(forKey key: String) throws -> Data? {
        loadCallCount += 1
        loadedKeys.append(key)
        if let overrideResult = loadResult {
            return try overrideResult.get()
        }
        return store[key]
    }

    func delete(forKey key: String) throws {
        deleteCallCount += 1
        deletedKeys.append(key)
        try deleteResult.get()
        store.removeValue(forKey: key)
    }

    // MARK: - Test Helpers

    /// Resets all stored data, stubs, and counters.
    func reset() {
        store.removeAll()
        saveResult = .success(())
        loadResult = nil
        deleteResult = .success(())
        saveCallCount = 0
        loadCallCount = 0
        deleteCallCount = 0
        savedKeys.removeAll()
        loadedKeys.removeAll()
        deletedKeys.removeAll()
    }
}
