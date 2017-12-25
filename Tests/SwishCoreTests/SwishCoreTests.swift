import XCTest
@testable import SwishCore

class SwishCoreTests: XCTestCase {
    func testSwishCoreDescription() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(SwishCore().description, "Swish Core")
    }

    static var allTests = [
        ("testSwishCoreDescription", testSwishCoreDescription),
    ]
}
