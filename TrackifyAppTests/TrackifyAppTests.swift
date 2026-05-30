import XCTest

final class TrackifyAppTests: XCTestCase {
    func testFormattersKg() {
        XCTAssertEqual(Formatters.compact(72.4), "72,4")
    }

    func testFormattersInteger() {
        XCTAssertEqual(Formatters.compact(100.0), "100")
    }

    func testDuration() {
        XCTAssertEqual(Formatters.duration(3661), "1:01:01")
        XCTAssertEqual(Formatters.duration(90), "01:30")
    }

    func testPace() {
        XCTAssertEqual(Formatters.pace(312), "5:12")
    }
}
