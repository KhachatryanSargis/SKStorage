import Testing
import Foundation
@testable import SKStorage

@Suite("ImageCacheCoordinator")
struct ImageCacheCoordinatorTests {

    // MARK: - Helpers

    private func makeSUT() -> (
        sut: ImageCacheCoordinator,
        memory: InMemoryImageCache,
        disk: DiskImageCache
    ) {
        let memory = InMemoryImageCache()
        let disk = DiskImageCache(directory: testDirectory())
        let sut = ImageCacheCoordinator(memoryCache: memory, diskCache: disk)
        return (sut, memory, disk)
    }

    // MARK: - Tiered Cache

    @Test("returns nil when both caches are empty")
    func returnsNilWhenEmpty() async {
        let (sut, _, _) = makeSUT()

        let result = await sut.image(for: anyURL())

        #expect(result == nil)
    }

    @Test("store saves to both caches")
    func storeSavesToBothCaches() async {
        let (sut, memory, disk) = makeSUT()
        let url = anyURL()

        await sut.store(anyImage(), for: url)

        #expect(await memory.image(for: url) != nil)
        #expect(await disk.image(for: url) != nil)
    }

    @Test("retrieves from memory first")
    func retrievesFromMemoryFirst() async {
        let (sut, memory, _) = makeSUT()
        let url = anyURL()

        // Store only in memory.
        await memory.store(anyImage(), for: url)
        let result = await sut.image(for: url)

        #expect(result != nil)
    }

    @Test("falls back to disk when memory is empty")
    func fallsToDiskWhenMemoryEmpty() async {
        let (sut, _, disk) = makeSUT()
        let url = anyURL()

        // Store only on disk.
        await disk.store(anyImage(), for: url)
        let result = await sut.image(for: url)

        #expect(result != nil)
    }

    @Test("promotes disk hit to memory")
    func promotesDiskHitToMemory() async {
        let (sut, memory, disk) = makeSUT()
        let url = anyURL()

        // Store only on disk.
        await disk.store(anyImage(), for: url)

        // Fetch triggers promotion.
        _ = await sut.image(for: url)

        // Now should be in memory.
        let memoryResult = await memory.image(for: url)
        #expect(memoryResult != nil)
    }

    // MARK: - Remove

    @Test("remove clears from both caches")
    func removeFromBoth() async {
        let (sut, memory, disk) = makeSUT()
        let url = anyURL()

        await sut.store(anyImage(), for: url)
        await sut.remove(for: url)

        #expect(await memory.image(for: url) == nil)
        #expect(await disk.image(for: url) == nil)
    }

    // MARK: - Clear

    @Test("clear removes all from both caches")
    func clearBothCaches() async {
        let (sut, _, _) = makeSUT()
        let url = anyURL()

        await sut.store(anyImage(), for: url)
        await sut.clear()
        let result = await sut.image(for: url)

        #expect(result == nil)
    }
}
