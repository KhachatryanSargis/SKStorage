# SKStorage — Package Rules

Claude reads this file when working on files inside the SKStorage package.
This file is owned by SKStorage and committed alongside the code.

## Package Overview

SKStorage provides type-safe storage, image caching, and SwiftData persistence
for iOS 17+ / macOS 14+. Swift 6.1 with strict concurrency. Depends on SKCore
for `LoggerProtocol`.

## Modules & Key Types

| Module | Key Types | Notes |
|---|---|---|
| **InfoCache** | `StorageCoordinator`, `KeychainStorage`, `UserDefaultsDataStorage` | Actor-based Codable coordinator; `secure:` flag routes to Keychain |
| **ImageCache** | `ImageCacheCoordinator`, `InMemoryImageCache`, `DiskImageCache` | Two-tier (memory + disk) with auto-promotion; actor-isolated |
| **SwiftData** | `SwiftDataRepository<T>` | Generic CRUD for any `PersistentModel` |
| **Protocols** | `DataStorageProtocol`, `ImageCacheProtocol`, `PersistentRepositoryProtocol` | Every concrete type has a corresponding protocol |

## Conventions Specific to This Package

### StorageCoordinator
The primary API for key-value storage. Uses `secure:` flag to route between backends:
```swift
let storage = StorageCoordinator()

// Non-sensitive → UserDefaults
try await storage.save("dark", forKey: "theme")

// Sensitive → Keychain
try await storage.save(token, forKey: "auth_token", secure: true)
```

### Direct Backend Access
Use `UserDefaultsDataStorage` and `KeychainStorage` directly when you need raw `Data`-level API without Codable encoding:
```swift
let keychain = KeychainStorage(service: "com.example.myapp")
try keychain.save(secretData, forKey: "api_key")
```

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
- `StorageCoordinator`, `InMemoryImageCache`, `DiskImageCache`, `ImageCacheCoordinator` are all **actors**
- All public APIs are `async` — callers must `await`
- Backend types (`KeychainStorage`, `UserDefaultsDataStorage`) are synchronous value types conforming to `Sendable`

### Testing in SKStorage
All dependencies are injectable via protocols. Tests use Swift Testing exclusively:
```swift
// Mock data storage for StorageCoordinator
let mockDefaults = MockDataStorage()
let mockKeychain = MockDataStorage()
let coordinator = StorageCoordinator(userDefaults: mockDefaults, keychain: mockKeychain)

// Mock keychain operations
let mock = MockKeychainOperations()
let keychain = KeychainStorage(service: "test", keychain: mock)

// Verify interactions
try await coordinator.save("value", forKey: "key")
#expect(mockDefaults.saveCallCount == 1)
```

### Build & Test
```bash
cd SKStorage
swift build
swift test
```

## Design Rules
- Every public type must have a corresponding protocol
- All protocols must be `Sendable`
- Coordinators are actors — direct backend types are synchronous structs
- Use `LoggerProtocol` (from SKCore) for diagnostics, never `print()`
- Image cache uses `PlatformImage` typealias — never reference `UIImage`/`NSImage` directly
- All public API must be documented with `///` comments
