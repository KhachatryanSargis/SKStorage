import Testing
import Foundation
@testable import SKStorage

@Suite("InMemoryImageCache")
struct InMemoryImageCacheTests {

    // MARK: - Store & Retrieve

    @Test("stores and retrieves image")
    func storeAndRetrieve() async {
        let sut = InMemoryImageCache()
        let url = anyURL()
        let image = anyImage()

        await sut.store(image, for: url)
        let result = await sut.image(for: url)

        #expect(result != nil)
    }

    @Test("returns nil for uncached URL")
    func returnsNilForUncachedURL() async {
        let sut = InMemoryImageCache()

        let result = await sut.image(for: anyURL())

        #expect(result == nil)
    }

    // MARK: - Remove

    @Test("remove clears specific image")
    func removeSpecificImage() async {
        let sut = InMemoryImageCache()
        let url = anyURL()

        await sut.store(anyImage(), for: url)
        await sut.remove(for: url)
        let result = await sut.image(for: url)

        #expect(result == nil)
    }

    @Test("remove does not affect other images")
    func removeDoesNotAffectOthers() async {
        let sut = InMemoryImageCache()
        let url1 = anyURL("image1.jpg")
        let url2 = anyURL("image2.jpg")

        await sut.store(anyImage(), for: url1)
        await sut.store(anyImage(), for: url2)
        await sut.remove(for: url1)

        #expect(await sut.image(for: url1) == nil)
        #expect(await sut.image(for: url2) != nil)
    }

    // MARK: - Clear

    @Test("clear removes all images")
    func clearRemovesAll() async {
        let sut = InMemoryImageCache()
        let url1 = anyURL("image1.jpg")
        let url2 = anyURL("image2.jpg")

        await sut.store(anyImage(), for: url1)
        await sut.store(anyImage(), for: url2)
        await sut.clear()

        #expect(await sut.image(for: url1) == nil)
        #expect(await sut.image(for: url2) == nil)
    }

    // MARK: - Overwrite

    @Test("storing same URL overwrites previous image")
    func overwriteOnSameURL() async {
        let sut = InMemoryImageCache()
        let url = anyURL()

        await sut.store(anyImage(), for: url)
        await sut.store(anyImage(), for: url)
        let result = await sut.image(for: url)

        #expect(result != nil)
    }
}
