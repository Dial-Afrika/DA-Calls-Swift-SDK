#if canImport(XCTest)
import XCTest
@testable import DACalls

final class DACallsTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // XCTAssert and related functions are used to verify your tests produce the correct
        // results.
        XCTAssertNotNil(DACalls.shared)
    }
}
#else
// Mock test class for platforms where XCTest is not available
final class DACallsTests {
    // No tests can be run without XCTest
    static func run() {
        print("XCTest not available on this platform")
    }
}
#endif

final class DACallsTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // XCTAssert and related functions are used to verify your tests produce the correct
        // results.
        XCTAssertNotNil(DACalls.shared)
    }
}
