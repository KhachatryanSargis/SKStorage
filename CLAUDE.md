# SKStorage — Package Rules

Claude reads this file when working on files inside the SKStorage package.
This file is owned by SKStorage and committed alongside the code.

## Package Overview

SKStorage provides image caching and SwiftData persistence implementations
for iOS 17+ / macOS 14+. Swift 6.1 with strict concurrency. Depends on SKCore
for all protocol definitions.

## Relationship to SKCore

SKCore defines the protocols; SKStorage provides the implementations. Feature
modules depend only on SKCore (protocols). The app layer injects SKStorage
(implementations) at composition time, enabling parallel compilation.

| From SKCore (protocols) | From SKStorage (implementations) |
|---|---|
| `ImageCacheProtocol` | `InMemoryImageCache`, `DiskImageCache`, `ImageCacheCoordinator` |
| `PersistentRepositoryProtocol` | `SwiftDataRepository<T>` |
| `PlatformImage` typealias | — |

**Do NOT define protocols here.** All protocols belong in SKCore.

## Modules & Key Types

| Module | Key Types | Notes |
|---|---|---|
| **ImageCache** | `ImageCacheCoordinator`, `InMemoryImageCache`, `DiskImageCache` | Two-tier (memory + disk) with auto-promotion; actor-isolated |
| **SwiftData** | `SwiftDataRepository<T>` | Generic CRUD for any `PersistentModel` |

## Conventions Specific to This Package

### ImageCacheCoordinator
Two-tier cache: checks memory first, then disk (with auto-promotion back to memory):
```swift
let cache = ImageCacheCoordinator()
await cache.store(image, for: imageURL)
let cached = await cache.image(for: imageURL)
```

- `InMemoryImageCache` — `NSCache`-backed, configurable limits, auto-eviction
- `DiskImageCache` — file-based with SHA-256 filenames, JPEG (iOS) / TIFF (macOS)
- Use `PlatformImage` (from SKCore) for cross-platform support

### SwiftDataRepository
Generic repository wrapping `ModelContext` for type-safe CRUD:
```swift
let repo = SwiftDataRepository<Item>(modelContext: container.mainContext)
try await repo.insert(Item(name: "New Item"))
let items = try await repo.fetch(predicate: #Predicate<Item> { $0.name == "New Item" })
```

### Concurrency Model
- `InMemoryImageCache`, `DiskImageCache`, `ImageCacheCoordinator` are all **actors**
- `SwiftDataRepository` is `@MainActor` (SwiftData requirement)
- All public APIs are `async` — callers must `await`

### Testing in SKStorage
All dependencies are injectable via protocols. Tests use Swift Testing exclusively:
```swift
let memory = InMemoryImageCache(countLimit: 10)
await memory.store(anyImage(), for: anyURL())
let cached = await memory.image(for: anyURL())
#expect(cached != nil)
```

### Build & Test
```bash
cd SKStorage
swift build
swift test
```

## Design Rules
- All protocols belong in SKCore — SKStorage provides implementations only
- Key-value storage belongs in SKCore — do NOT add UserDefaults or Keychain abstractions here
- Every public type must conform to its corresponding SKCore protocol
- Cache coordinators are actors — use actor isolation for thread safety
- Image cache uses `PlatformImage` (from SKCore) — never reference `UIImage`/`NSImage` directly
- All public API must be documented with `///` comments
