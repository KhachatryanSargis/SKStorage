import Foundation
import SwiftData

// MARK: - Persistent Repository Protocol

/// A protocol for generic CRUD operations on SwiftData persistent models.
///
/// Isolates SwiftData access behind a testable interface and enforces
/// `@MainActor` isolation, which SwiftData's `ModelContext` requires.
///
/// ## Usage
///
/// ```swift
/// let repo: any PersistentRepositoryProtocol<MyModel> = SwiftDataRepository(modelContext: context)
/// try await repo.insert(model)
/// let items = try await repo.fetch()
/// ```
@MainActor
public protocol PersistentRepositoryProtocol<Model>: Sendable {
    /// The persistent model type this repository manages.
    associatedtype Model: PersistentModel

    /// Fetches all models matching an optional predicate.
    ///
    /// - Parameter predicate: An optional filter. Pass `nil` to fetch all.
    /// - Returns: An array of matching models.
    func fetch(predicate: Predicate<Model>?) async throws -> [Model]

    /// Fetches all models without filtering.
    ///
    /// - Returns: An array of all persisted models.
    func fetch() async throws -> [Model]

    /// Inserts a new model and persists it.
    ///
    /// - Parameter model: The model to insert.
    func insert(_ model: Model) async throws

    /// Deletes an existing model.
    ///
    /// - Parameter model: The model to delete.
    func delete(_ model: Model) async throws
}
