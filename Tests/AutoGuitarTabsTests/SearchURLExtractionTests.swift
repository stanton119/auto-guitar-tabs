import XCTest
@testable import AutoGuitarTabs

final class SearchURLExtractionTests: XCTestCase {
    private let track = TrackInfo(title: "Song A", artist: "Artist B", source: "Spotify")

    func testGuitarTypeID() {
        XCTAssertEqual(Instrument.guitar.typeID, 200)
    }

    func testChordsTypeID() {
        XCTAssertEqual(Instrument.chords.typeID, 300)
    }

    func testBassTypeID() {
        XCTAssertEqual(Instrument.bass.typeID, 400)
    }

    func testGuitarURLIncludesValueAndType() throws {
        let url = try XCTUnwrap(Instrument.guitar.ultimateGuitarURL(for: track))
        let items = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        XCTAssertEqual(items.first { $0.name == "value" }?.value, "Artist B Song A")
        XCTAssertEqual(items.first { $0.name == "type[]" }?.value, "200")
    }

    func testBassURLUsesType400() throws {
        let url = try XCTUnwrap(Instrument.bass.ultimateGuitarURL(for: track))
        let items = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        XCTAssertEqual(items.first { $0.name == "type[]" }?.value, "400")
    }

    func testAllTypeIDIsNil() {
        XCTAssertNil(Instrument.all.typeID)
    }

    func testAllIsFirstInstrument() {
        XCTAssertEqual(Instrument.allCases.first, .all)
    }

    func testAllURLOmitsTypeFilter() throws {
        let url = try XCTUnwrap(Instrument.all.ultimateGuitarURL(for: track))
        let items = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        XCTAssertNil(items.first { $0.name == "type[]" })
        XCTAssertEqual(items.first { $0.name == "value" }?.value, "Artist B Song A")
    }
}
