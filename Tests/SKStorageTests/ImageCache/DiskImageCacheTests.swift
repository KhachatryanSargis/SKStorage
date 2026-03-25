import Testing
import Foundation
@testable import SKStorage

@Suite("DiskImageCache")
struct DiskImageCacheTests {

    // MARK: - Helpers

    private func makeSUT() -> DiskImageCache {
        DiskImageCache(directory: testDirectory())
    }

    // MARK: - Store & Retrieve

    @Test("stores and retrieves image from disk")
    func storeAndRetrieve() async {
        let sut = makeSUT()
        let url = anyURL()
        let image = anyImage()

        await sut.store(image, for: url)
        let result = await sut.image(for: url)

        #expect(result != nil)
    }

    @Test("returns nil for uncached URL")
    func returnsNilForUncachedURL() async {
        let sut = makeSUT()

        let result = await sut.image(for: anyURL())

        #expect(result == nil)
    }

    // MARK: - Remove

    @Test("remove clears specific image from disk")
    func removeSpecificImage() async {
        let sut = makeSUT()
        let url = anyURL()

        await sut.store(anyImage(), for: url)
        await sut.remove(for: url)
        let result = await sut.image(for: url)

        #expect(result == nil)
    }

    // MARK: - Clear

    @Test("clear removes all images from disk")
    func clearRemovesAll() async {
        let sut = makeSUT()
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
        let cache1 = DiskImageCache(directory: dir)
        await cache1.store(anyImage(), for: url)

        // Retrieve with second instance pointing to same directory.
        let cache2 = DiskImageCache(directory: dir)
        let result = await cache2.image(for: url)

        #expect(result != nil)
    }
}
