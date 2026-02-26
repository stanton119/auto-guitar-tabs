import XCTest
@testable import AutoGuitarTabs

final class DetectionManagerTests: XCTestCase {
    func testTrackInfoEquality() {
        let track1 = TrackInfo(title: "Song A", artist: "Artist B", source: "Spotify")
        let track2 = TrackInfo(title: "Song A", artist: "Artist B", source: "Spotify")
        let track3 = TrackInfo(title: "Song C", artist: "Artist B", source: "Spotify")
        
        XCTAssertEqual(track1, track2)
        XCTAssertNotEqual(track1, track3)
    }

    func testDetectionManagerInitialState() {
        let manager = DetectionManager()
        XCTAssertNil(manager.currentTrack)
    }
}
