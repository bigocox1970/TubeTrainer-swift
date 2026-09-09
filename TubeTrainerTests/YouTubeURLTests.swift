import XCTest
@testable import TubeTrainer

final class YouTubeURLTests: XCTestCase {

    func testStandardWatchURL() {
        let p = YouTubeURL.parse("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
        XCTAssertEqual(p?.videoID, "dQw4w9WgXcQ")
        XCTAssertEqual(p?.contentType, .video)
    }

    func testShortURLLink() {
        let p = YouTubeURL.parse("https://youtu.be/dQw4w9WgXcQ?t=42")
        XCTAssertEqual(p?.videoID, "dQw4w9WgXcQ")
        XCTAssertEqual(p?.startSeconds, 42)
    }

    func testShortsForm() {
        let p = YouTubeURL.parse("https://www.youtube.com/shorts/abc123DEF_-")
        XCTAssertEqual(p?.videoID, "abc123DEF_-")
        XCTAssertEqual(p?.contentType, .short)
    }

    func testBareID() {
        let p = YouTubeURL.parse("dQw4w9WgXcQ")
        XCTAssertEqual(p?.videoID, "dQw4w9WgXcQ")
    }

    func testEmbedAndNoCookie() {
        XCTAssertEqual(YouTubeURL.parse("https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ")?.videoID, "dQw4w9WgXcQ")
        XCTAssertEqual(YouTubeURL.parse("https://m.youtube.com/watch?v=dQw4w9WgXcQ&t=1m30s")?.startSeconds, 90)
    }

    func testMissingSchemeStillParses() {
        XCTAssertEqual(YouTubeURL.parse("youtu.be/dQw4w9WgXcQ")?.videoID, "dQw4w9WgXcQ")
    }

    func testInvalidStrings() {
        XCTAssertNil(YouTubeURL.parse("https://vimeo.com/12345"))
        XCTAssertNil(YouTubeURL.parse("just some text"))
        XCTAssertNil(YouTubeURL.parse(""))
    }

    func testTimeStringParsing() {
        XCTAssertEqual(YouTubeURL.parseTimeString("90"), 90)
        XCTAssertEqual(YouTubeURL.parseTimeString("90s"), 90)
        XCTAssertEqual(YouTubeURL.parseTimeString("1m30s"), 90)
        XCTAssertEqual(YouTubeURL.parseTimeString("2:14"), 134)
        XCTAssertEqual(YouTubeURL.parseTimeString("1:01:00"), 3660)
        XCTAssertNil(YouTubeURL.parseTimeString(""))
    }

    func testCanonicalBuilders() {
        XCTAssertEqual(YouTubeURL.watchURL("abc", start: 30), "https://www.youtube.com/watch?v=abc&t=30s")
        XCTAssertEqual(YouTubeURL.shortURL("abc"), "https://www.youtube.com/shorts/abc")
        XCTAssertTrue(YouTubeURL.embedURL(id: "abc", start: 5).contains("start=5"))
    }
}
