import XCTest
@testable import Modernistik

final class ModernistikTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Modernistik().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
