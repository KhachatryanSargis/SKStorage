import Foundation
import SKCore
import SwiftData

// MARK: - SwiftData Repository

/// Generic SwiftData repository providing CRUD operations for any `PersistentModel`.
///
/// Isolates SwiftData's `ModelContext` behind the ``PersistentRepositoryProtocol``
/// interface, making persistence logic testable and swappable.
///
/// ## Thread Safety
///
/// `@MainActor` isolation matches SwiftData's requirement that `ModelContext`
/// be accessed from the main actor. The `@unchecked Sendable` conformance
/// is safe because all access is serialized through `@MainActor`.
///
/// ## Usage
///
/// ```swift
/// @Model final class Item { var name: String }
///
/// let repo = SwiftDataRepository<Item>(modelContext: container.mainContext)
/// try await repo.insert(Item(name: "New"))
/// let items = try await repo.fetch()
/// ```
@MainActor
public final class SwiftDataRepository<Model: PersistentModel>: PersistentRepositoryProtocol, @unchecked Sendable {
    // MARK: - Dependencies

    private let modelContext: ModelContext

    // MARK: - Init

    /// Creates a repository for the given model context.
    ///
    /// - Parameter modelContext: The SwiftData model context to operate on.
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - PersistentRepositoryProtocol

    public func fetch(predicate: Predicate<Model>?) async throws -> [Model] {
        let descriptor = FetchDescriptor<Model>(predicate: predicate)
        return try modelContext.fetch(descriptor)
    }

    public func fetch() async throws -> [Model] {
        try await fetch(predicate: nil)
    }

    public func insert(_ model: Model) async throws {
        modelContext.insert(model)
        try modelContext.save()
    }

    public func delete(_ model: Model) async throws {
        modelContext.delete(model)
        try modelContext.save()
    }
}
