import Foundation
import SKCore

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - In-Memory Image Cache

/// Fast, volatile image cache backed by `NSCache`.
///
/// Automatically evicts images under memory pressure thanks to
/// `NSCache`'s built-in memory management. Thread safety is provided
/// by actor isolation — no manual locking required.
///
/// ## Features
///
/// - Configurable count and cost limits.
/// - Automatic eviction under memory pressure.
/// - Actor-isolated for safe concurrent access.
///
/// ## Usage
///
/// ```swift
/// let cache = InMemoryImageCache(countLimit: 200)
/// await cache.store(image, for: url)
/// let cached = await cache.image(for: url)
/// ```
public actor InMemoryImageCache: ImageCacheProtocol {
    // NSCache is thread-safe, but we use actor isolation for consistency
    // with the rest of the SKStorage API.
    private let cache = NSCache<NSURL, PlatformImage>()

    /// Creates an in-memory image cache.
    ///
    /// - Parameters:
    ///   - countLimit: Maximum number of images to cache. `0` means no limit.
    ///   - totalCostLimit: Maximum total cost in bytes. `0` means no limit.
    public init(countLimit: Int = 100, totalCostLimit: Int = 50 * 1024 * 1024) {
        cache.countLimit = countLimit
        cache.totalCostLimit = totalCostLimit
    }

    // MARK: - ImageCacheProtocol

    public func image(for url: URL) -> PlatformImage? {
        cache.object(forKey: url as NSURL)
    }

    public func store(_ image: PlatformImage, for url: URL) {
        let cost = imageCost(image)
        cache.setObject(image, forKey: url as NSURL, cost: cost)
    }

    public func remove(for url: URL) {
        cache.removeObject(forKey: url as NSURL)
    }

    public func clear() {
        cache.removeAllObjects()
    }

    // MARK: - Private

    /// Estimates the in-memory cost of an image in bytes.
    private func imageCost(_ image: PlatformImage) -> Int {
        #if canImport(UIKit)
        Int(image.size.width * image.size.height * image.scale * image.scale * 4)
        #elseif canImport(AppKit)
        guard let rep = image.representations.first else { return 0 }
        return rep.pixelsWide * rep.pixelsHigh * 4
        #endif
    }
}
