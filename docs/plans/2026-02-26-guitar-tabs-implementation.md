# Auto Guitar Tabs Implementation Plan

> **For Gemini:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a macOS SwiftUI app that detects songs on Spotify/Safari and displays Ultimate Guitar tabs.

**Architecture:** A central `DetectionManager` polls for song changes via AppleScript, triggering a `TabSearchEngine` to fetch and parse Ultimate Guitar HTML/JSON into a SwiftUI view.

**Tech Stack:** Swift, SwiftUI, AppleScript, URLSession.

---

### Task 1: Project Scaffolding

**Files:**
- Create: `Package.swift`
- Create: `Sources/AutoGuitarTabs/AutoGuitarTabsApp.swift`
- Create: `Sources/AutoGuitarTabs/ContentView.swift`

**Step 1: Create Package.swift**
```swift
// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "AutoGuitarTabs",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "AutoGuitarTabs", targets: ["AutoGuitarTabs"])
    ],
    targets: [
        .executableTarget(
            name: "AutoGuitarTabs",
            dependencies: [],
            path: "Sources/AutoGuitarTabs"
        ),
        .testTarget(
            name: "AutoGuitarTabsTests",
            dependencies: ["AutoGuitarTabs"],
            path: "Tests/AutoGuitarTabsTests"
        )
    ]
)
```

**Step 2: Create App Entry Point**
```swift
import SwiftUI

@main
struct AutoGuitarTabsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**Step 3: Create Initial ContentView**
```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("Auto Guitar Tabs Initialized")
            .padding()
            .frame(minWidth: 600, minHeight: 400)
    }
}
```

**Step 4: Commit**
```bash
git add Package.swift Sources/
git commit -m "chore: scaffold basic SwiftUI project structure"
```

---

### Task 2: AppleScript Detection Logic

**Files:**
- Create: `Sources/AutoGuitarTabs/DetectionManager.swift`
- Test: `Tests/AutoGuitarTabsTests/DetectionManagerTests.swift`

**Step 1: Define Track Info Model**
```swift
struct TrackInfo: Equatable {
    let title: String
    let artist: String
    let source: String // "Spotify" or "YouTube"
}
```

**Step 2: Implement AppleScript Polling**
- Use `NSAppleScript` to query Spotify and Safari.
- Spotify script: `tell application "Spotify" to get {name, artist} of current track`
- Safari script: `tell application "Safari" to get name of current tab of window 1` (then parse for "- YouTube")

**Step 3: Commit**
```bash
git add Sources/AutoGuitarTabs/DetectionManager.swift
git commit -m "feat: add DetectionManager with AppleScript support"
```

---

### Task 3: Ultimate Guitar Search Engine

**Files:**
- Create: `Sources/AutoGuitarTabs/TabSearchEngine.swift`

**Step 1: Implement Search URL Construction**
- URL: `https://www.ultimate-guitar.com/search.php?search_type=title&value=ARTIST+TITLE`

**Step 2: Implement HTML Parsing**
- Fetch HTML using `URLSession`.
- Extract the `window.UGAPP.store.page.data` JSON from the `<script>` tag.
- Map JSON to a `TabContent` model.

**Step 3: Commit**
```bash
git add Sources/AutoGuitarTabs/TabSearchEngine.swift
git commit -m "feat: add TabSearchEngine to fetch tabs from Ultimate Guitar"
```

---

### Task 4: UI Development (Top Bar & Tab View)

**Files:**
- Modify: `Sources/AutoGuitarTabs/ContentView.swift`

**Step 1: Build Top Bar**
- Display `currentTrack.title` and `currentTrack.artist`.
- Add Segmented Picker for `[Guitar Tab, Chords, Bass Tab]`.

**Step 2: Build Tab Display**
- Use a `ScrollView` with a `Text` view using `.font(.system(.body, design: .monospaced))`.

**Step 3: Commit**
```bash
git add Sources/AutoGuitarTabs/ContentView.swift
git commit -m "feat: implement top bar and tab display UI"
```

---

### Task 5: Integration & Auto-Scroll

**Step 1: Connect DetectionManager to UI**
- Trigger `TabSearchEngine` when `DetectionManager` publishes a new track.

**Step 2: Implement Auto-Scroll**
- Add a timer-based offset increment to the ScrollView.

**Step 3: Final Commit**
```bash
git commit -m "feat: final integration and auto-scroll support"
```
