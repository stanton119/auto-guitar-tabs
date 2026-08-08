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

    func testPausePreservesLastKnownTrack() {
        let manager = DetectionManager()
        let track = TrackInfo(title: "Song A", artist: "Artist B", source: "Spotify")
        manager.applySelection(spotifyTrack: track, youtubeTrack: nil)
        XCTAssertEqual(manager.currentTrack, track)

        // Pausing Spotify makes pollSpotify() return nil
        manager.applySelection(spotifyTrack: nil, youtubeTrack: nil)
        XCTAssertEqual(manager.currentTrack, track, "Pausing should not wipe the last known track")
    }

    func testNewTrackStillUpdatesCurrentTrack() {
        let manager = DetectionManager()
        let first = TrackInfo(title: "Song A", artist: "Artist B", source: "Spotify")
        let second = TrackInfo(title: "Song C", artist: "Artist D", source: "Spotify")
        manager.applySelection(spotifyTrack: first, youtubeTrack: nil)
        manager.applySelection(spotifyTrack: second, youtubeTrack: nil)
        XCTAssertEqual(manager.currentTrack, second)
    }
}
