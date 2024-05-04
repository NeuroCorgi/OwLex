import XCTest
import Regex

final class RegexTests: XCTestCase {
    func testParsing() throws {
        // XCTAssertNotNil(parseRegex(from: "a*b*(c123)|(ab)*q+"), "Cannot parse regex")
    }

    func testRun() throws {
        let regex = try XCTUnwrap(parseRegex(from: "a+c|abc"), "Cannot parse regex")
        print(regex)
        XCTAssertTrue(regex.run(on: "aaaaaaac"))
        XCTAssertTrue(regex.run(on: "abc"))
        XCTAssertFalse(regex.run(on: "c"))
        XCTAssertFalse(regex.run(on: "dahlk"))
    }
}
