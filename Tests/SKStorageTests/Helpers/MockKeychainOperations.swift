import Foundation
@testable import SKStorage

/// In-memory mock for ``KeychainOperations`` that avoids hitting the real keychain.
///
/// Stores data in a dictionary and supports configurable failure flags
/// for testing error paths.
///
/// ## Usage
///
/// ```swift
/// let mock = MockKeychainOperations()
/// let keychain = KeychainStorage(keychain: mock)
/// try keychain.save(data, forKey: "key")
///
/// // Simulate failure
/// mock.shouldFailOnAdd = true
/// ```
final class MockKeychainOperations: KeychainOperations, @unchecked Sendable {
    // MARK: - Storage

    private var items: [String: Data] = [:]

    // MARK: - Failure Flags

    var shouldFailOnAdd = false
    var shouldFailOnCopy = false
    var shouldFailOnDelete = false

    // MARK: - Call Tracking

    private(set) var addCallCount = 0
    private(set) var copyCallCount = 0
    private(set) var deleteCallCount = 0

    // MARK: - KeychainOperations

    func add(_ query: CFDictionary) -> OSStatus {
        addCallCount += 1
        guard !shouldFailOnAdd else { return errSecIO }

        let dict = query as! [String: Any]
        guard let account = dict[kSecAttrAccount as String] as? String,
              let data = dict[kSecValueData as String] as? Data else {
            return errSecParam
        }

        items[account] = data
        return errSecSuccess
    }

    func copyMatching(_ query: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus {
        copyCallCount += 1
        guard !shouldFailOnCopy else { return errSecIO }

        let dict = query as! [String: Any]
        guard let account = dict[kSecAttrAccount as String] as? String else {
            return errSecParam
        }

        guard let data = items[account] else {
            return errSecItemNotFound
        }

        result?.pointee = data as CFTypeRef
        return errSecSuccess
    }

    func delete(_ query: CFDictionary) -> OSStatus {
        deleteCallCount += 1
        guard !shouldFailOnDelete else { return errSecIO }

        let dict = query as! [String: Any]
        guard let account = dict[kSecAttrAccount as String] as? String else {
            return errSecParam
        }

        items.removeValue(forKey: account)
        return errSecSuccess
    }

    // MARK: - Test Helpers

    /// Resets all stored items and counters.
    func reset() {
        items.removeAll()
        addCallCount = 0
        copyCallCount = 0
        deleteCallCount = 0
        shouldFailOnAdd = false
        shouldFailOnCopy = false
        shouldFailOnDelete = false
    }
}
