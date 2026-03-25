import Foundation
import SKCore

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Image Cache Coordinator

/// Two-tier image cache combining in-memory and disk-based storage.
///
/// Implements a classic cache hierarchy:
/// 1. **Memory** (``InMemoryImageCache``): Fast, volatile.
/// 2. **Disk** (``DiskImageCache``): Slower, persistent.
///
/// On a disk hit, the image is automatically promoted to memory
/// so subsequent reads are served from the faster tier.
///
/// ## Usage
///
/// ```swift
/// let coordinator = ImageCacheCoordinator()
/// await coordinator.store(image, for: url)
/// let cached = await coordinator.image(for: url)  // memory → disk fallback
/// ```
public actor ImageCacheCoordinator: ImageCacheProtocol {
    // MARK: - Dependencies

    private let memoryCache: InMemoryImageCache
    private let diskCache: DiskImageCache

    // MARK: - Init

    /// Creates a two-tier image cache coordinator.
    ///
    /// - Parameters:
    ///   - memoryCache: The in-memory cache tier.
    ///   - diskCache: The disk cache tier.
    public init(
        memoryCache: InMemoryImageCache = InMemoryImageCache(),
        diskCache: DiskImageCache = DiskImageCache()
    ) {
        self.memoryCache = memoryCache
        self.diskCache = diskCache
    }

    // MARK: - ImageCacheProtocol

    public func image(for url: URL) async -> PlatformImage? {
        // Check memory first.
        if let memoryImage = await memoryCache.image(for: url) {
            return memoryImage
        }

        // Fall back to disk and promote to memory on hit.
        if let diskImage = await diskCache.image(for: url) {
            await memoryCache.store(diskImage, for: url)
            return diskImage
        }

        return nil
    }

    public func store(_ image: PlatformImage, for url: URL) async {
        await memoryCache.store(image, for: url)
        await diskCache.store(image, for: url)
    }

    public func remove(for url: URL) async {
        await memoryCache.remove(for: url)
        await diskCache.remove(for: url)
    }

    public func clear() async {
        await memoryCache.clear()
        await diskCache.clear()
    }
}
