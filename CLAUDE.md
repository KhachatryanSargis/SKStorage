# SKStorage — Package Rules

Claude reads this file when working on files inside the SKStorage package.
This file is owned by SKStorage and committed alongside the code.

## Package Overview

SKStorage provides image caching and SwiftData persistence for iOS 17+ / macOS 14+.
Swift 6.1 with strict concurrency. No external dependencies.

Key-value storage (UserDefaults, Keychain) lives in **SKCore**, not here.
SKStorage focuses on two higher-level concerns: image caching and persistent models.

## Modules & Key Types

| Module | Key Types | Notes |
|---|---|---|
| **ImageCache** | `ImageCacheCoordinator`, `InMemoryImageCache`, `DiskImageCache` | Two-tier (memory + disk) with auto-promotion; actor-isolated |
| **SwiftData** | `SwiftDataRepository<T>` | Generic CRUD for any `PersistentModel` |
| **Protocols** | `ImageCacheProtocol`, `PersistentRepositoryProtocol` | SKStorage's own protocols |

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
- Use `PlatformImage` for cross-platform support (`UIImage` on iOS, `NSImage` on macOS)

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
// Direct cache testing — no mocks needed for actors
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
- Key-value storage belongs in SKCore — do NOT add UserDefaults or Keychain abstractions here
- Every public type must have a corresponding protocol
- All protocols must be `Sendable`
- Cache coordinators are actors — use actor isolation for thread safety
- Image cache uses `PlatformImage` typealias — never reference `UIImage`/`NSImage` directly
- All public API must be documented with `///` comments
