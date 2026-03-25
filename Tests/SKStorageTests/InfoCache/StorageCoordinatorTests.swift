import Testing
import Foundation
@testable import SKStorage

@Suite("StorageCoordinator")
struct StorageCoordinatorTests {

    // MARK: - Helpers

    private func makeSUT(
        userDefaults: MockDataStorage = MockDataStorage(),
        keychain: MockDataStorage = MockDataStorage()
    ) -> (sut: StorageCoordinator, userDefaults: MockDataStorage, keychain: MockDataStorage) {
        let sut = StorageCoordinator(userDefaults: userDefaults, keychain: keychain)
        return (sut, userDefaults, keychain)
    }

    // MARK: - Save (Non-Secure)

    @Test("save stores to UserDefaults by default")
    func saveNonSecure() async throws {
        let (sut, defaults, keychain) = makeSUT()
        let value = TestCodable(id: "1", value: 42)

        try await sut.save(value, forKey: "item")

        #expect(defaults.saveCallCount == 1)
        #expect(keychain.saveCallCount == 0)
    }

    // MARK: - Save (Secure)

    @Test("save with secure flag stores to Keychain")
    func saveSecure() async throws {
        let (sut, defaults, keychain) = makeSUT()
        let value = TestCodable(id: "1", value: 42)

        try await sut.save(value, forKey: "token", secure: true)

        #expect(defaults.saveCallCount == 0)
        #expect(keychain.saveCallCount == 1)
    }

    // MARK: - Load (Non-Secure)

    @Test("load retrieves from UserDefaults by default")
    func loadNonSecure() async throws {
        let (sut, _, _) = makeSUT()
        let value = TestCodable(id: "1", value: 42)

        try await sut.save(value, forKey: "item")
        let loaded: TestCodable? = try await sut.load(forKey: "item")

        #expect(loaded == value)
    }

    @Test("load returns nil for missing key")
    func loadReturnsNilForMissingKey() async throws {
        let (sut, _, _) = makeSUT()

        let result: TestCodable? = try await sut.load(forKey: "nonexistent")

        #expect(result == nil)
    }

    // MARK: - Load (Secure)

    @Test("load with secure flag retrieves from Keychain")
    func loadSecure() async throws {
        let (sut, defaults, keychain) = makeSUT()
        let value = TestCodable(id: "1", value: 42)

        try await sut.save(value, forKey: "token", secure: true)
        let loaded: TestCodable? = try await sut.load(forKey: "token", secure: true)

        #expect(loaded == value)
        #expect(defaults.loadCallCount == 0)
        #expect(keychain.loadCallCount == 1)
    }

    // MARK: - Delete (Non-Secure)

    @Test("delete removes from UserDefaults by default")
    func deleteNonSecure() async throws {
        let (sut, defaults, keychain) = makeSUT()

        try await sut.save(TestCodable(id: "1", value: 1), forKey: "item")
        try await sut.delete(forKey: "item")

        #expect(defaults.deleteCallCount == 1)
        #expect(keychain.deleteCallCount == 0)
        let loaded: TestCodable? = try await sut.load(forKey: "item")
        #expect(loaded == nil)
    }

    // MARK: - Delete (Secure)

    @Test("delete with secure flag removes from Keychain")
    func deleteSecure() async throws {
        let (sut, defaults, keychain) = makeSUT()

        try await sut.save(TestCodable(id: "1", value: 1), forKey: "token", secure: true)
        try await sut.delete(forKey: "token", secure: true)

        #expect(defaults.deleteCallCount == 0)
        #expect(keychain.deleteCallCount == 1)
    }

    // MARK: - Round-Trip

    @Test("save then load round-trips correctly")
    func roundTrip() async throws {
        let (sut, _, _) = makeSUT()
        let original = TestCodable(id: "abc", value: 99)

        try await sut.save(original, forKey: "data")
        let loaded: TestCodable? = try await sut.load(forKey: "data")

        #expect(loaded == original)
    }
}
