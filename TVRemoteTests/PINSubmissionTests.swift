import XCTest
@testable import TVRemote

final class PINSubmissionTests: XCTestCase {

    func testSanitizedPINEmpty() {
        XCTAssertEqual(PINSubmission.sanitizedPIN(""), "")
    }

    func testSanitizedPINNonDigits() {
        XCTAssertEqual(PINSubmission.sanitizedPIN("abcd"), "")
        XCTAssertEqual(PINSubmission.sanitizedPIN("a-b.c"), "")
    }

    func testSanitizedPINTruncation() {
        XCTAssertEqual(PINSubmission.sanitizedPIN("12345"), "1234")
        XCTAssertEqual(PINSubmission.sanitizedPIN("12a34b56"), "1234")
    }

    func testSanitizedPINExactFour() {
        XCTAssertEqual(PINSubmission.sanitizedPIN("1234"), "1234")
    }
}
