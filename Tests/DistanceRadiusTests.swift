import XCTest
@testable import StickerMatch

final class DistanceRadiusTests: XCTestCase {

    func testMetersPerRadius() {
        XCTAssertEqual(DistanceRadius.km50.meters, 50_000)
        XCTAssertEqual(DistanceRadius.km100.meters, 100_000)
        XCTAssertEqual(DistanceRadius.km250.meters, 250_000)
        XCTAssertNil(DistanceRadius.country.meters) // "Country" = no distance cap
    }

    func testEveryCaseHasALabel() {
        for radius in DistanceRadius.allCases {
            XCTAssertFalse(radius.label.isEmpty)
        }
    }
}
