import Foundation

#if canImport(UIKit)
import UIKit
/// Cross-platform image type alias. Resolves to `UIImage` on iOS/tvOS/visionOS.
public typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
/// Cross-platform image type alias. Resolves to `NSImage` on macOS.
public typealias PlatformImage = NSImage
#endif

// MARK: - Image Cache Protocol

/// A protocol for image caching backends (memory, disk, or tiered).
///
/// All methods are asynchronous to support both in-memory and disk-backed
/// implementations without blocking the caller.
///
/// Conforming types must be `Sendable` for safe use across concurrency domains.
///
/// ## Implementations
///
/// - ``InMemoryImageCache``: Fast, volatile NSCache-backed storage.
/// - ``DiskImageCache``: Persistent file-based storage.
/// - ``ImageCacheCoordinator``: Two-tier coordinator combining memory and disk.
///
/// ## Usage
///
/// ```swift
/// let cache: any ImageCacheProtocol = InMemoryImageCache()
/// await cache.store(image, for: url)
/// let cached = await cache.image(for: url)
/// ```
public protocol ImageCacheProtocol: Sendable {
    /// Retrieves a cached image for the given URL.
    ///
    /// - Parameter url: The URL that identifies the cached image.
    /// - Returns: The cached image, or `nil` if not found.
    func image(for url: URL) async -> PlatformImage?

    /// Stores an image in the cache, keyed by its URL.
    ///
    /// - Parameters:
    ///   - image: The image to cache.
    ///   - url: The URL that identifies the image.
    func store(_ image: PlatformImage, for url: URL) async

    /// Removes a cached image for the given URL.
    ///
    /// - Parameter url: The URL that identifies the cached image.
    func remove(for url: URL) async

    /// Removes all cached images.
    func clear() async
}
