import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@testable import SKStorage

// MARK: - Test Helpers

/// Creates a deterministic test URL.
func anyURL(_ path: String = "image.jpg") -> URL {
    // swiftlint:disable:next force_unwrapping
    URL(string: "https://example.com/\(path)")!
}

/// Creates a minimal 1×1 platform image for testing.
func anyImage() -> PlatformImage {
    #if canImport(UIKit)
    UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { context in
        UIColor.red.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
    }
    #elseif canImport(AppKit)
    let image = NSImage(size: NSSize(width: 1, height: 1))
    image.lockFocus()
    NSColor.red.drawSwatch(in: NSRect(x: 0, y: 0, width: 1, height: 1))
    image.unlockFocus()
    return image
    #endif
}

/// Creates a unique temporary directory for test isolation.
func testDirectory() -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent("SKStorageTests-\(UUID().uuidString)")
}

// MARK: - Test Codable

/// A simple Codable struct for testing storage encoding/decoding.
struct TestCodable: Codable, Equatable, Sendable {
    let id: String
    let value: Int
}
