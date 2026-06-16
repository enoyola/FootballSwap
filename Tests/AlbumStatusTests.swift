import XCTest
@testable import StickerMatch

final class AlbumStatusTests: XCTestCase {

    func testCopiesMapToStatus() {
        XCTAssertEqual(StickerStatus.from(copies: 0).status, .missing)
        XCTAssertEqual(StickerStatus.from(copies: 0).repeatedQty, 0)

        XCTAssertEqual(StickerStatus.from(copies: 1).status, .have)
        XCTAssertEqual(StickerStatus.from(copies: 1).repeatedQty, 0)

        XCTAssertEqual(StickerStatus.from(copies: 2).status, .repeated)
        XCTAssertEqual(StickerStatus.from(copies: 2).repeatedQty, 2)

        XCTAssertEqual(StickerStatus.from(copies: 7).status, .repeated)
        XCTAssertEqual(StickerStatus.from(copies: 7).repeatedQty, 7)
    }

    func testNegativeCopiesClampToMissing() {
        let r = StickerStatus.from(copies: -5)
        XCTAssertEqual(r.status, .missing)
        XCTAssertEqual(r.repeatedQty, 0)
    }

    func testAlbumItemCopiesDerivation() {
        XCTAssertEqual(Fixtures.albumItem("1", status: .missing).copies, 0)
        XCTAssertEqual(Fixtures.albumItem("1", status: .have).copies, 1)
        XCTAssertEqual(Fixtures.albumItem("1", status: .repeated, qty: 3).copies, 3)
        // A repeated sticker always counts as at least 2 copies.
        XCTAssertEqual(Fixtures.albumItem("1", status: .repeated, qty: 0).copies, 2)
    }

    func testSearchMatching() {
        let item = Fixtures.albumItem("011", status: .missing) // name "Player", number "011"
        XCTAssertTrue(item.matches(searchText: ""))     // empty -> match all
        XCTAssertTrue(item.matches(searchText: "011"))  // by number
        XCTAssertTrue(item.matches(searchText: "play")) // by name (case-insensitive)
        XCTAssertFalse(item.matches(searchText: "zzz"))
    }
}
