import Testing
import Foundation
import SwiftData
@testable import SKStorage

// MARK: - Test Model

@Model
final class TestModel {
    var name: String

    init(name: String) {
        self.name = name
    }
}

// MARK: - Tests

@Suite("SwiftDataRepository")
struct SwiftDataRepositoryTests {

    // MARK: - Helpers

    /// Returns both the repository and its container.
    ///
    /// The caller **must** hold onto the container for the duration of the test.
    /// `ModelContext` does not retain its parent `ModelContainer` — if the
    /// container is deallocated, any operation on the context will crash
    /// with `EXC_BREAKPOINT`.
    @MainActor
    private func makeSUT() throws -> (sut: SwiftDataRepository<TestModel>, container: ModelContainer) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: TestModel.self, configurations: config)
        let sut = SwiftDataRepository<TestModel>(modelContext: container.mainContext)
        return (sut, container)
    }

    // MARK: - Insert

    @Test("inserts and persists a model")
    @MainActor
    func insertSavesModel() async throws {
        let (sut, _container) = try makeSUT()
        _ = _container // keep container alive

        try await sut.insert(TestModel(name: "Test Item"))
        let fetched = try await sut.fetch()

        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "Test Item")
    }

    // MARK: - Fetch

    @Test("fetches all models")
    @MainActor
    func fetchReturnsAll() async throws {
        let (sut, _container) = try makeSUT()
        _ = _container

        try await sut.insert(TestModel(name: "Item 1"))
        try await sut.insert(TestModel(name: "Item 2"))
        let fetched = try await sut.fetch()

        #expect(fetched.count == 2)
    }

    @Test("fetches with predicate filters results")
    @MainActor
    func fetchWithPredicate() async throws {
        let (sut, _container) = try makeSUT()
        _ = _container

        try await sut.insert(TestModel(name: "Apple"))
        try await sut.insert(TestModel(name: "Banana"))

        let predicate = #Predicate<TestModel> { $0.name == "Apple" }
        let fetched = try await sut.fetch(predicate: predicate)

        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "Apple")
    }

    // MARK: - Delete

    @Test("deletes a model")
    @MainActor
    func deleteRemovesModel() async throws {
        let (sut, _container) = try makeSUT()
        _ = _container

        let model = TestModel(name: "To Delete")
        try await sut.insert(model)
        try await sut.delete(model)
        let fetched = try await sut.fetch()

        #expect(fetched.isEmpty)
    }
}
