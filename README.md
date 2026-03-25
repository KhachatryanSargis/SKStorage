# SKStorage

[![Swift](https://img.shields.io/badge/Swift-6.1+-orange?logo=swift)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-17%2B-blue?logo=apple)](https://developer.apple.com/ios/)
[![macOS](https://img.shields.io/badge/macOS-14%2B-blue?logo=apple)](https://developer.apple.com/macos/)
[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen?logo=swift)](https://swift.org/package-manager/)
[![License](https://img.shields.io/badge/license-MIT-lightgrey)](LICENSE)

Image caching and SwiftData persistence implementations built with Swift 6 strict concurrency and full test coverage.

> **Architecture:** [SKCore](https://github.com/KhachatryanSargis/SKCore) defines the protocols (`ImageCacheProtocol`, `PersistentRepositoryProtocol`). SKStorage provides the implementations. Feature modules depend only on SKCore; the app layer injects SKStorage at composition time. This enables parallel compilation across feature and infrastructure modules.

---

## Requirements

- iOS 17+ / macOS 14+
- Swift 6.1+
- Xcode 16.3+

---

## Installation

**Xcode:** File > Add Package Dependencies > enter the repository URL, select *Up to Next Major Version* from `0.1.0`.

**`Package.swift`:**

```swift
dependencies: [
    .package(url: "https://github.com/KhachatryanSargis/SKStorage.git", from: "0.1.0")
],
targets: [
    .target(name: "YourTarget", dependencies: ["SKStorage"])
]
```

---

## Modules

| Module | Description | Key Types |
|--------|-------------|-----------|
| **ImageCache** | Two-tier image caching (memory + disk) | `ImageCacheCoordinator`, `InMemoryImageCache`, `DiskImageCache` |
| **SwiftData** | Generic CRUD repository for `PersistentModel` types | `SwiftDataRepository` |

---

## ImageCache

Two-tier image caching with automatic memory-to-disk promotion. Uses actor isolation for thread safety and `PlatformImage` (from SKCore) for cross-platform support.

### ImageCacheCoordinator

```swift
let cache = ImageCacheCoordinator()

// Store
await cache.store(image, for: imageURL)

// Retrieve — checks memory first, then disk (with auto-promotion)
let cached = await cache.image(for: imageURL)

// Cleanup
await cache.remove(for: imageURL)
await cache.clear()
```

### Individual Tiers

```swift
// Memory only — fast, volatile, auto-evicts under pressure
let memory = InMemoryImageCache(countLimit: 200, totalCostLimit: 100 * 1024 * 1024)

// Disk only — persistent across launches
let disk = DiskImageCache(directory: customCacheURL, compressionQuality: 0.9)

// Custom coordinator with configured tiers
let cache = ImageCacheCoordinator(memoryCache: memory, diskCache: disk)
```

### Tiers

| Type | Storage | Characteristics |
|------|---------|----------------|
| `InMemoryImageCache` | `NSCache` | Fast, volatile, configurable limits, auto-eviction |
| `DiskImageCache` | File system (SHA-256 filenames) | Persistent, JPEG (iOS) / TIFF (macOS) |
| `ImageCacheCoordinator` | Both | Memory-first with disk fallback and auto-promotion |

---

## SwiftData

Generic repository wrapping `ModelContext` for type-safe CRUD operations on any `PersistentModel`.

```swift
@Model final class Item {
    var name: String
    init(name: String) { self.name = name }
}

let repo = SwiftDataRepository<Item>(modelContext: container.mainContext)

// Insert
try await repo.insert(Item(name: "New Item"))

// Fetch all
let items = try await repo.fetch()

// Fetch with predicate
let predicate = #Predicate<Item> { $0.name == "New Item" }
let filtered = try await repo.fetch(predicate: predicate)

// Delete
try await repo.delete(item)
```

---

## Dependency Inversion

Feature modules depend on SKCore (protocols), not SKStorage (implementations):

```swift
// FeatureModule/AvatarLoader.swift — depends on SKCore only
import SKCore

struct AvatarLoader {
    let cache: any ImageCacheProtocol

    func loadAvatar(url: URL) async -> PlatformImage? {
        await cache.image(for: url)
    }
}

// App/CompositionRoot.swift — wires implementations
import SKCore
import SKStorage

let cache = ImageCacheCoordinator()
let loader = AvatarLoader(cache: cache)
```

---

## Testing

All implementations conform to SKCore protocols, making them fully mockable. Tests use Swift Testing (`@Suite`, `@Test`, `#expect`) exclusively — no XCTest.

```swift
// Image cache — direct testing with actors
let memory = InMemoryImageCache(countLimit: 10)
await memory.store(testImage, for: testURL)
#expect(await memory.image(for: testURL) != nil)

// Disk cache — isolated test directory
let disk = DiskImageCache(directory: tempDir)
await disk.store(testImage, for: testURL)
#expect(await disk.image(for: testURL) != nil)

// SwiftData — in-memory container
let container = try ModelContainer(for: Item.self, configurations: .init(isStoredInMemoryOnly: true))
let repo = SwiftDataRepository<Item>(modelContext: container.mainContext)
```

---

## Package Structure

```
SKStorage/
├── Package.swift
├── Sources/SKStorage/
│   ├── ImageCache/
│   │   ├── InMemoryImageCache.swift       # NSCache-backed actor
│   │   ├── DiskImageCache.swift           # File-based actor with SHA-256
│   │   └── ImageCacheCoordinator.swift    # Two-tier coordinator
│   └── SwiftData/
│       └── SwiftDataRepository.swift      # Generic PersistentModel CRUD
└── Tests/SKStorageTests/
    ├── Helpers/
    │   └── TestHelpers.swift
    ├── ImageCache/
    │   ├── InMemoryImageCacheTests.swift
    │   ├── DiskImageCacheTests.swift
    │   └── ImageCacheCoordinatorTests.swift
    └── SwiftData/
        └── SwiftDataRepositoryTests.swift
```

---

## Dependencies

- [SKCore](https://github.com/KhachatryanSargis/SKCore) — protocol definitions (`ImageCacheProtocol`, `PlatformImage`, `PersistentRepositoryProtocol`)

---

## License

MIT
