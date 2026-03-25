import Foundation
import CryptoKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Disk Image Cache

/// Persistent image cache that stores images as files on disk.
///
/// Uses SHA-256 hashing of the URL to generate unique, collision-resistant
/// filenames. Images are stored as JPEG (iOS) or TIFF (macOS) data in the
/// specified directory.
///
/// ## Thread Safety
///
/// Actor-isolated for safe concurrent access. All file system operations
/// run within the actor's serial executor.
///
/// ## Features
///
/// - Persistent storage across app launches.
/// - Automatic directory creation.
/// - SHA-256–based filename generation.
///
/// ## Usage
///
/// ```swift
/// let cache = DiskImageCache()
/// await cache.store(image, for: url)
/// let cached = await cache.image(for: url)
/// ```
public actor DiskImageCache: ImageCacheProtocol {
    // MARK: - Dependencies

    private let directory: URL
    private let fileManager: FileManager
    private let compressionQuality: Double

    // MARK: - Init

    /// Creates a disk image cache.
    ///
    /// - Parameters:
    ///   - directory: Directory for storing cached images.
    ///     Defaults to `Caches/SKImageCache`.
    ///   - fileManager: The file manager to use. Defaults to `.default`.
    ///   - compressionQuality: JPEG compression quality (0.0–1.0). Defaults to `0.8`.
    ///     Only used on iOS; macOS uses TIFF representation.
    public init(
        directory: URL? = nil,
        fileManager: FileManager = .default,
        compressionQuality: Double = 0.8
    ) {
        self.fileManager = fileManager
        self.compressionQuality = compressionQuality

        let cacheDir = fileManager
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SKImageCache")
        self.directory = directory ?? cacheDir

        try? fileManager.createDirectory(
            at: self.directory,
            withIntermediateDirectories: true
        )
    }

    // MARK: - ImageCacheProtocol

    public func image(for url: URL) -> PlatformImage? {
        let path = filePath(for: url)
        guard let data = try? Data(contentsOf: path) else { return nil }
        return PlatformImage(data: data)
    }

    public func store(_ image: PlatformImage, for url: URL) {
        let path = filePath(for: url)
        guard let data = imageData(from: image) else { return }
        try? data.write(to: path)
    }

    public func remove(for url: URL) {
        let path = filePath(for: url)
        try? fileManager.removeItem(at: path)
    }

    public func clear() {
        guard let files = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ) else { return }

        for file in files {
            try? fileManager.removeItem(at: file)
        }
    }

    // MARK: - Private

    /// Generates a unique file path for a URL using its SHA-256 hash.
    private func filePath(for url: URL) -> URL {
        let hash = SHA256.hash(data: Data(url.absoluteString.utf8))
        let filename = hash.compactMap { String(format: "%02x", $0) }.joined()
        return directory.appendingPathComponent(filename)
    }

    /// Converts a platform image to serializable data.
    private func imageData(from image: PlatformImage) -> Data? {
        #if canImport(UIKit)
        image.jpegData(compressionQuality: compressionQuality)
        #elseif canImport(AppKit)
        image.tiffRepresentation
        #endif
    }
}
