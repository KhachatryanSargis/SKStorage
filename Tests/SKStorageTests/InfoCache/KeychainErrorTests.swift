import Testing
import Foundation
@testable import SKStorage

@Suite("KeychainError")
struct KeychainErrorTests {

    @Test("saveFailed includes status code in description")
    func saveFailedDescription() {
        let error = KeychainError.saveFailed(-25300)

        #expect(error.errorDescription?.contains("-25300") == true)
    }

    @Test("loadFailed includes status code in description")
    func loadFailedDescription() {
        let error = KeychainError.loadFailed(-25291)

        #expect(error.errorDescription?.contains("-25291") == true)
    }

    @Test("deleteFailed includes status code in description")
    func deleteFailedDescription() {
        let error = KeychainError.deleteFailed(-25292)

        #expect(error.errorDescription?.contains("-25292") == true)
    }

    @Test("all cases have non-nil descriptions")
    func allCasesHaveDescriptions() {
        let cases: [KeychainError] = [
            .saveFailed(0),
            .loadFailed(0),
            .deleteFailed(0)
        ]

        for error in cases {
            #expect(error.errorDescription != nil)
        }
    }
}
