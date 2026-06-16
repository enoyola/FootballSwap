import XCTest
@testable import StickerMatch

final class MatchServiceTests: XCTestCase {

    func testTheyHaveAStickerImMissing() {
        let album = [Fixtures.albumItem("001", status: .missing)]
        let posts = [Fixtures.postWith(repeated: ["001"], missing: [])]
        let matches = MatchService.computeMatches(album: album, posts: posts)

        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matches[0].theyHave, ["001"])
        XCTAssertTrue(matches[0].iHave.isEmpty)
        XCTAssertEqual(matches[0].score, 1)
    }

    func testIHaveAStickerTheyNeed() {
        let album = [Fixtures.albumItem("012", status: .repeated, qty: 2)]
        let posts = [Fixtures.postWith(repeated: [], missing: ["012"])]
        let matches = MatchService.computeMatches(album: album, posts: posts)

        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matches[0].iHave, ["012"])
        XCTAssertTrue(matches[0].theyHave.isEmpty)
        XCTAssertEqual(matches[0].score, 1)
    }

    func testBidirectionalScore() {
        let album = [
            Fixtures.albumItem("001", status: .missing),
            Fixtures.albumItem("002", status: .missing),
            Fixtures.albumItem("012", status: .repeated, qty: 2),
        ]
        let posts = [Fixtures.postWith(repeated: ["001", "002"], missing: ["012"])]
        let matches = MatchService.computeMatches(album: album, posts: posts)

        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matches[0].theyHave, ["001", "002"])
        XCTAssertEqual(matches[0].iHave, ["012"])
        XCTAssertEqual(matches[0].score, 3)
    }

    func testNoOverlapIsExcluded() {
        // I already HAVE #001 (not missing), and they don't need #012.
        let album = [
            Fixtures.albumItem("001", status: .have),
            Fixtures.albumItem("012", status: .repeated, qty: 2),
        ]
        let posts = [Fixtures.postWith(repeated: ["001"], missing: ["999"])]
        XCTAssertTrue(MatchService.computeMatches(album: album, posts: posts).isEmpty)
    }

    func testRankedByScoreDescending() {
        let album = ["001", "002", "003"].map { Fixtures.albumItem($0, status: .missing) }
        let weak = Fixtures.postWith(repeated: ["001"], missing: [], nickname: "Weak")
        let strong = Fixtures.postWith(repeated: ["001", "002", "003"], missing: [], nickname: "Strong")
        let matches = MatchService.computeMatches(album: album, posts: [weak, strong])

        XCTAssertEqual(matches.map(\.post.nickname), ["Strong", "Weak"])
    }

    func testNumbersAreSorted() {
        let album = ["003", "001", "002"].map { Fixtures.albumItem($0, status: .missing) }
        let posts = [Fixtures.postWith(repeated: ["003", "001", "002"], missing: [])]
        XCTAssertEqual(MatchService.computeMatches(album: album, posts: posts)[0].theyHave,
                       ["001", "002", "003"])
    }

    func testHaveStatusIsNotOfferedNorNeeded() {
        // "have" (exactly 1 copy) is neither missing nor repeated -> never matches.
        let album = [Fixtures.albumItem("050", status: .have)]
        let posts = [Fixtures.postWith(repeated: ["050"], missing: ["050"])]
        XCTAssertTrue(MatchService.computeMatches(album: album, posts: posts).isEmpty)
    }
}
