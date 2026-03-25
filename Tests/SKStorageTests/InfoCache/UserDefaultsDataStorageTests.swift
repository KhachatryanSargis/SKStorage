import Testing
import Foundation
@testable import SKStorage

@Suite("UserDefaultsDataStorage")
struct UserDefaultsDataStorageTests {

    // MARK: - Helpers

    private func makeSUT() -> (sut: UserDefaultsDataStorage, defaults: UserDefaults) {
        let suiteName = "SKStorageTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let sut = UserDefaultsDataStorage(defaults: defaults)
        return (sut, defaults)
    }

    // MARK: - Save

    @Test("saves data for key")
    func saveStoresData() throws {
        let (sut, defaults) = makeSUT()
        let data = Data("test".utf8)

        try sut.save(data, forKey: "test_key")

        let stored = defaults.data(forKey: "test_key")
        #expect(stored == data)
    }

    // MARK: - Load

    @Test("loads previously stored data")
    func loadReturnsStoredData() throws {
        let (sut, defaults) = makeSUT()
        let data = Data("test".utf8)
        defaults.set(data, forKey: "test_key")

        let result = try sut.load(forKey: "test_key")

        #expect(result == data)
    }

    @Test("load returns nil for missing key")
    func loadReturnsNilForMissingKey() throws {
        let (sut, _) = makeSUT()

        let result = try sut.load(forKey: "nonexistent")

        #expect(result == nil)
    }

    // MARK: - Delete

    @Test("delete removes data for key")
    func deleteRemovesData() throws {
        let (sut, defaults) = makeSUT()
        let data = Data("test".utf8)
        defaults.set(data, forKey: "test_key")

        try sut.delete(forKey: "test_key")

        #expect(defaults.data(forKey: "test_key") == nil)
    }
}
