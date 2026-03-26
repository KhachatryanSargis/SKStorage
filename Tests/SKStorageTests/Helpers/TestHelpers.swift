import Foundation
import SKCore

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

// MARK: - Spy Logger

/// A test spy logger that records all log entries for verification.
///
/// - Note: `@unchecked Sendable` is safe here because this type is only used
///   in test suites where access is serialized by the test runner.
final class SpyLogger: LoggerProtocol, @unchecked Sendable {
    let minimumLevel: LogLevel

    struct Entry {
        let message: String
        let level: LogLevel
    }

    private(set) var entries: [Entry] = []

    init(minimumLevel: LogLevel = .debug) {
        self.minimumLevel = minimumLevel
    }

    func log(
        _ message: @autoclosure () -> String,
        level: LogLevel,
        file: String,
        function: String,
        line: Int
    ) {
        guard level >= minimumLevel else { return }
        entries.append(Entry(message: message(), level: level))
    }

    /// Returns entries filtered by level.
    func entries(at level: LogLevel) -> [Entry] {
        entries.filter { $0.level == level }
    }
}

