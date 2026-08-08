# "All" Instrument Type Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an "All" instrument option to the sidebar that shows Ultimate Guitar search results without filtering by instrument type.

**Architecture:** Model "All" as a new first case in the existing `Instrument` enum with a `nil` type ID. Extract URL construction into a testable `searchURL(for:)` instance method that omits the `type[]` query item when the type ID is `nil`. Set "All" as the default selection.

**Tech Stack:** SwiftUI, Swift 5.10, macOS 14, XCTest via SwiftPM

## Global Constraints

- SwiftPM `swift-tools-version: 5.10`; target `.macOS(.v14)`
- Test command: `swift test`; build command: `swift build`
- Use TDD: write the failing test, verify it fails, implement, verify it passes, commit
- No code comments unless the existing nearby code uses them
- Follow existing repo style: `Instrument.icon` switch, existing enum/identity pattern
- Existing tests live in `Tests/AutoGuitarTabsTests/` and use `@testable import AutoGuitarTabs`

---

### Task 1: Extract testable URL builder for existing instruments

**Files:**
- Modify: `Sources/AutoGuitarTabs/ContentView.swift` (enum at lines 272-285, `refreshTab()` at lines 89-106)
- Create: `Tests/AutoGuitarTabsTests/SearchURLExtractionTests.swift`

**Interfaces:**
- Produces: instance method `func ultimateGuitarURL(for track: TrackInfo) -> URL?` on `Instrument`, and computed property `var typeID: Int?` on `Instrument` (used by Task 2).

This task locks in testable URL-building for the existing instruments. Task 2 adds the `.all` case.

- [ ] **Step 1: Write the failing tests**

Create `Tests/AutoGuitarTabsTests/SearchURLExtractionTests.swift`:

```swift
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
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `swift test`

Expected: FAIL — `Instrument` has no member `typeID` or `ultimateGuitarURL`, so the test target does not compile.

- [ ] **Step 3: Implement `typeID` and the URL builder**

In `ContentView.swift`, replace the `Instrument` enum (lines 272-285) with:

```swift
enum Instrument: String, CaseIterable, Identifiable {
    case guitar = "Guitar Tab"
    case chords = "Chords"
    case bass = "Bass Tab"

    var id: String { self.rawValue }

    var typeID: Int? {
        switch self {
        case .guitar: return 200
        case .chords: return 300
        case .bass: return 400
        }
    }

    var icon: String {
        switch self {
        case .guitar: return "guitars"
        case .chords: return "music.note.list"
        case .bass: return "amplifier"
        }
    }

    func ultimateGuitarURL(for track: TrackInfo) -> URL? {
        var components = URLComponents(string: "https://www.ultimate-guitar.com/search.php")!
        var queryItems = [URLQueryItem(name: "value", value: "\(track.artist) \(track.title)")]
        if let typeID {
            queryItems.append(URLQueryItem(name: "type[]", value: String(typeID)))
        }
        components.queryItems = queryItems
        return components.url
    }
}
```

Then replace the body of `refreshTab()` (lines 89-106) with:

```swift
    private func refreshTab() {
        guard let track = detectionManager.currentTrack else { return }

        if let url = selectedInstrument.ultimateGuitarURL(for: track) {
            if self.currentURL != url {
                self.currentURL = url
            }
        }
    }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test`

Expected: PASS (Task 1 cases) plus existing `DetectionManagerTests` still pass.

- [ ] **Step 5: Build and commit**

Run: `swift build`

Expected: Build succeeds.

```bash
git add Sources/AutoGuitarTabs/ContentView.swift Tests/AutoGuitarTabsTests/SearchURLExtractionTests.swift
git commit -m "feat: extract testable Ultimate Guitar URL builder"
```

---

### Task 2: Add "All" instrument type as default

**Files:**
- Modify: `Sources/AutoGuitarTabs/ContentView.swift` (line 6 default, lines 272-285 enum)
- Modify: `Tests/AutoGuitarTabsTests/SearchURLExtractionTests.swift`

**Interfaces:**
- Consumes: `Instrument.typeID: Int?`, `Instrument.ultimateGuitarURL(for:)` from Task 1.

- [ ] **Step 1: Write the failing tests**

Append to `Tests/AutoGuitarTabsTests/SearchURLExtractionTests.swift`:

```swift
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `swift test`

Expected: FAIL — `Instrument` has no member `all`, so compilation fails.

- [ ] **Step 3: Implement the `.all` case and default**

In `ContentView.swift`, change the default selection (line 6):

```swift
    @State private var selectedInstrument: Instrument = .all
```

Replace the `Instrument` enum with an `.all` case first, `typeID` returning `nil` for it, and an icon for it:

```swift
enum Instrument: String, CaseIterable, Identifiable {
    case all = "All"
    case guitar = "Guitar Tab"
    case chords = "Chords"
    case bass = "Bass Tab"

    var id: String { self.rawValue }

    var typeID: Int? {
        switch self {
        case .all: return nil
        case .guitar: return 200
        case .chords: return 300
        case .bass: return 400
        }
    }

    var icon: String {
        switch self {
        case .all: return "music.note"
        case .guitar: return "guitars"
        case .chords: return "music.note.list"
        case .bass: return "amplifier"
        }
    }

    func ultimateGuitarURL(for track: TrackInfo) -> URL? {
        var components = URLComponents(string: "https://www.ultimate-guitar.com/search.php")!
        var queryItems = [URLQueryItem(name: "value", value: "\(track.artist) \(track.title)")]
        if let typeID {
            queryItems.append(URLQueryItem(name: "type[]", value: String(typeID)))
        }
        components.queryItems = queryItems
        return components.url
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test`

Expected: PASS — all Task 2 cases plus Task 1 cases and existing `DetectionManagerTests`.

- [ ] **Step 5: Build and commit**

Run: `swift build`

Expected: Build succeeds.

```bash
git add Sources/AutoGuitarTabs/ContentView.swift Tests/AutoGuitarTabsTests/SearchURLExtractionTests.swift
git commit -m "feat: add All instrument type as default"
```
```