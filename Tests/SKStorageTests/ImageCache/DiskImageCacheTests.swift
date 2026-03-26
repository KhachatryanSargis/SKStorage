import Testing
import Foundation
import SKCore
@testable import SKStorage

@Suite("DiskImageCache")
struct DiskImageCacheTests {

    // MARK: - Helpers

    private func makeSUT(
        directory: URL? = nil,
        logger: SpyLogger = SpyLogger()
    ) -> (sut: DiskImageCache, logger: SpyLogger) {
        let dir = directory ?? testDirectory()
        let sut = DiskImageCache(directory: dir, logger: logger)
        return (sut, logger)
    }

    // MARK: - Store & Retrieve

    @Test("stores and retrieves image from disk")
    func storeAndRetrieve() async {
        let (sut, _) = makeSUT()
        let url = anyURL()
        let image = anyImage()

        await sut.store(image, for: url)
        let result = await sut.image(for: url)

        #expect(result != nil)
    }

    @Test("returns nil for uncached URL")
    func returnsNilForUncachedURL() async {
        let (sut, _) = makeSUT()

        let result = await sut.image(for: anyURL())

        #expect(result == nil)
    }

    // MARK: - Remove

    @Test("remove clears specific image from disk")
    func removeSpecificImage() async {
        let (sut, _) = makeSUT()
        let url = anyURL()

        await sut.store(anyImage(), for: url)
        await sut.remove(for: url)
        let result = await sut.image(for: url)

        #expect(result == nil)
    }

    // MARK: - Clear

    @Test("clear removes all images from disk")
    func clearRemovesAll() async {
        let (sut, _) = makeSUT()
        let url1 = anyURL("image1.jpg")
        let url2 = anyURL("image2.jpg")

        await sut.store(anyImage(), for: url1)
        await sut.store(anyImage(), for: url2)
        await sut.clear()

        #expect(await sut.image(for: url1) == nil)
        #expect(await sut.image(for: url2) == nil)
    }

    // MARK: - Persistence

    @Test("image persists across cache instances with same directory")
    func persistsAcrossInstances() async {
        let dir = testDirectory()
        let url = anyURL()

        // Store with first instance.
        let (cache1, _) = makeSUT(directory: dir)
        await cache1.store(anyImage(), for: url)

        // Retrieve with second instance pointing to same directory.
        let (cache2, _) = makeSUT(directory: dir)
        let result = await cache2.image(for: url)

        #expect(result != nil)
    }

    // MARK: - Logging on Failure

    @Test("logs warning when store fails due to invalid directory")
    func storeLogsWarningOnWriteFailure() async {
        // Point to a directory that cannot be created (nested under a nonexistent root).
        let invalidDir = URL(fileURLWithPath: "/nonexistent_root/cache")
        let logger = SpyLogger()
        let sut = DiskImageCache(directory: invalidDir, logger: logger)

        await sut.store(anyImage(), for: anyURL())

        let warnings = logger.entries(at: .warning)
        #expect(!warnings.isEmpty)
    }

    @Test("logs warning when remove fails for missing file")
    func removeLogsWarningOnFailure() async {
        let (sut, logger) = makeSUT()

        // Remove a file that was never stored.
        await sut.remove(for: anyURL("never_stored.jpg"))

        let warnings = logger.entries(at: .warning)
        #expect(!warnings.isEmpty)
    }

    @Test("logs warning when clear fails to list invalid directory")
    func clearLogsWarningOnListFailure() async {
        let invalidDir = URL(fileURLWithPath: "/nonexistent_root/cache")
        let logger = SpyLogger()
        let sut = DiskImageCache(directory: invalidDir, logger: logger)

        await sut.clear()

        let warnings = logger.entries(at: .warning)
        #expect(!warnings.isEmpty)
    }

    @Test("logs debug on cache miss")
    func cacheMissLogsDebug() async {
        let (sut, logger) = makeSUT()

        _ = await sut.image(for: anyURL("missing.jpg"))

        let debugEntries = logger.entries(at: .debug)
        #expect(!debugEntries.isEmpty)
    }

    @Test("no warnings logged on successful operations")
    func noWarningsOnSuccess() async {
        let (sut, logger) = makeSUT()
        let url = anyURL()

        await sut.store(anyImage(), for: url)
        _ = await sut.image(for: url)

        let warnings = logger.entries(at: .warning)
        #expect(warnings.isEmpty)
    }
}
