import Testing
import Foundation
@testable import SKStorage

@Suite("KeychainStorage")
struct KeychainStorageTests {

    // MARK: - Save

    @Test("saves data successfully")
    func saveData() throws {
        let mock = MockKeychainOperations()
        let sut = KeychainStorage(service: "test", keychain: mock)
        let data = Data("secret".utf8)

        try sut.save(data, forKey: "token")

        #expect(mock.addCallCount == 1)
    }

    @Test("save throws on keychain failure")
    func saveThrowsOnFailure() {
        let mock = MockKeychainOperations()
        mock.shouldFailOnAdd = true
        let sut = KeychainStorage(service: "test", keychain: mock)

        #expect(throws: KeychainError.self) {
            try sut.save(Data("x".utf8), forKey: "key")
        }
    }

    @Test("save deletes existing item first")
    func saveDeletesExistingFirst() throws {
        let mock = MockKeychainOperations()
        let sut = KeychainStorage(service: "test", keychain: mock)

        try sut.save(Data("v1".utf8), forKey: "key")
        try sut.save(Data("v2".utf8), forKey: "key")

        // First save: 1 delete attempt + 1 add. Second save: 1 delete + 1 add.
        #expect(mock.addCallCount == 2)
        #expect(mock.deleteCallCount == 2)
    }

    // MARK: - Load

    @Test("loads previously saved data")
    func loadSavedData() throws {
        let mock = MockKeychainOperations()
        let sut = KeychainStorage(service: "test", keychain: mock)
        let data = Data("secret".utf8)

        try sut.save(data, forKey: "token")
        let loaded = try sut.load(forKey: "token")

        #expect(loaded == data)
    }

    @Test("load returns nil for missing key")
    func loadReturnsNilForMissingKey() throws {
        let mock = MockKeychainOperations()
        let sut = KeychainStorage(service: "test", keychain: mock)

        let result = try sut.load(forKey: "nonexistent")

        #expect(result == nil)
    }

    @Test("load throws on keychain failure")
    func loadThrowsOnFailure() {
        let mock = MockKeychainOperations()
        mock.shouldFailOnCopy = true
        let sut = KeychainStorage(service: "test", keychain: mock)

        #expect(throws: KeychainError.self) {
            _ = try sut.load(forKey: "key")
        }
    }

    // MARK: - Delete

    @Test("deletes existing item")
    func deleteExistingItem() throws {
        let mock = MockKeychainOperations()
        let sut = KeychainStorage(service: "test", keychain: mock)

        try sut.save(Data("x".utf8), forKey: "key")
        try sut.delete(forKey: "key")

        let result = try sut.load(forKey: "key")
        #expect(result == nil)
    }

    @Test("delete succeeds for missing key")
    func deleteSucceedsForMissingKey() throws {
        let mock = MockKeychainOperations()
        let sut = KeychainStorage(service: "test", keychain: mock)

        // Should not throw — errSecItemNotFound is treated as success.
        try sut.delete(forKey: "nonexistent")
    }

    @Test("delete throws on keychain failure")
    func deleteThrowsOnFailure() {
        let mock = MockKeychainOperations()
        mock.shouldFailOnDelete = true
        let sut = KeychainStorage(service: "test", keychain: mock)

        #expect(throws: KeychainError.self) {
            try sut.delete(forKey: "key")
        }
    }
}
