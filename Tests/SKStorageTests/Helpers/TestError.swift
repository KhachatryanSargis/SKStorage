import Foundation

/// Common test errors used across test suites.
enum TestError: Error, LocalizedError, Equatable {
    case missingFile(String)
    case timeout
    case unexpectedNil
    case stub(String)

    var errorDescription: String? {
        switch self {
        case .missingFile(let name): "Missing file: \(name)"
        case .timeout: "Operation timed out"
        case .unexpectedNil: "Unexpected nil value"
        case .stub(let message): "Stub error: \(message)"
        }
    }
}
