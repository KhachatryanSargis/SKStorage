# SKStorage

[![Swift](https://img.shields.io/badge/Swift-6.1+-orange?logo=swift)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-17%2B-blue?logo=apple)](https://developer.apple.com/ios/)
[![macOS](https://img.shields.io/badge/macOS-14%2B-blue?logo=apple)](https://developer.apple.com/macos/)
[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen?logo=swift)](https://swift.org/package-manager/)
[![License](https://img.shields.io/badge/license-MIT-lightgrey)](LICENSE)

Type-safe storage, image caching, and SwiftData persistence built with Swift 6 strict concurrency and full test coverage.

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
| **InfoCache** | Codable key-value storage backed by UserDefaults or Keychain | `StorageCoordinator`, `KeychainStorage`, `UserDefaultsDataStorage` |
| **ImageCache** | Two-tier image caching (memory + disk) | `ImageCacheCoordinator`, `InMemoryImageCache`, `DiskImageCache` |
| **SwiftData** | Generic CRUD repository for `PersistentModel` types | `SwiftDataRepository` |

---

## InfoCache

Unified access to UserDefaults and Keychain through a single actor-based coordinator. Non-sensitive data goes to UserDefaults; pass `secure: true` to route to the Keychain.

### StorageCoordinator

```swift
let storage = StorageCoordinator()

// Non-sensitive (UserDefaults)
try await storage.save("dark", forKey: "theme")
let theme: String? = try await storage.load(forKey: "theme")

// Secure (Keychain)
try await storage.save(token, forKey: "auth_token", secure: true)
let token: String? = try await storage.load(forKey: "auth_token", secure: true)

// Delete
try await storage.delete(forKey: "theme")
```

### Direct Backend Access

For cases where you need the raw `Data`-level API without Codable encoding:

```swift
// UserDefaults
let defaults = UserDefaultsDataStorage()
try defaults.save(Data("hello".utf8), forKey: "greeting")

// Keychain
let keychain = KeychainStorage(service: "com.example.myapp")
try keychain.save(secretData, forKey: "api_key")
```

### Backends

| Type | Backed By | Use Case |
|------|-----------|----------|
| `UserDefaultsDataStorage` | `UserDefaults` | Preferences, flags, non-sensitive settings |
| `KeychainStorage` | Security framework | Tokens, credentials, sensitive data |
| `StorageCoordinator` | Both (via `secure:` flag) | Unified Codable storage |

---

## ImageCache

Two-tier image caching with automatic memory-to-disk promotion. Uses actor isolation for thread safety and `PlatformImage` for cross-platform support (`UIImage` on iOS, `NSImage` on macOS).

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
| `ImageCacheCoordinator` | Both | Memory → disk fallback with auto-promotion |

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

## Testing

All dependencies are injectable via protocols, making every type fully testable without hitting real storage backends.

```swift
// Mock keychain operations
let mock = MockKeychainOperations()
let keychain = KeychainStorage(service: "test", keychain: mock)

// Mock data storage for StorageCoordinator
let mockDefaults = MockDataStorage()
let mockKeychain = MockDataStorage()
let coordinator = StorageCoordinator(userDefaults: mockDefaults, keychain: mockKeychain)

// Verify interactions
try await coordinator.save("value", forKey: "key")
#expect(mockDefaults.saveCallCount == 1)
```

Tests use Swift Testing (`@Suite`, `@Test`, `#expect`) exclusively — no XCTest.

---

## Package Structure

```
SKStorage/
├── Package.swift
├── Sources/SKStorage/
│   ├── Protocols/
│   │   ├── StorageProtocol.swift          # DataStorageProtocol
│   │   ├── ImageCacheProtocol.swift       # ImageCacheProtocol + PlatformImage
│   │   └── PersistentRepositoryProtocol.swift
│   ├── InfoCache/
│   │   ├── KeychainStorage.swift          # Keychain + KeychainOperations + KeychainError
│   │   ├── UserDefaultsDataStorage.swift  # Raw Data UserDefaults wrapper
│   │   └── StorageCoordinator.swift       # Actor-based Codable coordinator
│   ├── ImageCache/
│   │   ├── InMemoryImageCache.swift       # NSCache-backed actor
│   │   ├── DiskImageCache.swift           # File-based actor with SHA-256
│   │   └── ImageCacheCoordinator.swift    # Two-tier coordinator
│   └── SwiftData/
│       └── SwiftDataRepository.swift      # Generic PersistentModel CRUD
└── Tests/SKStorageTests/
    ├── Helpers/
    │   ├── MockKeychainOperations.swift
    │   ├── MockDataStorage.swift
    │   ├── TestError.swift
    │   └── TestHelpers.swift
    ├── InfoCache/
    │   ├── KeychainStorageTests.swift
    │   ├── KeychainErrorTests.swift
    │   ├── UserDefaultsDataStorageTests.swift
    │   └── StorageCoordinatorTests.swift
    ├── ImageCache/
    │   ├── InMemoryImageCacheTests.swift
    │   ├── DiskImageCacheTests.swift
    │   └── ImageCacheCoordinatorTests.swift
    └── SwiftData/
        └── SwiftDataRepositoryTests.swift
```

---

## Dependencies

- [SKCore](https://github.com/KhachatryanSargis/SKCore) — `LoggerProtocol` for optional diagnostics in `StorageCoordinator`

---

## License

MIT
