# Immersive Studio UI Overhaul Implementation Plan

> **For Gemini:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Transform the Auto Guitar Tabs UI from a simple top-bar layout to a modern, glassmorphic sidebar interface.

**Architecture:** Refactor `ContentView.swift` to use `NavigationSplitView`. Create a dedicated `SidebarView` for track info and navigation, and a `MainContentView` for the tab sheet. Use `ultraThinMaterial` for glass effects.

**Tech Stack:** Swift, SwiftUI.

---

### Task 1: UI Model & Enum Preparation

**Files:**
- Modify: `Sources/AutoGuitarTabs/ContentView.swift`

**Step 1: Define Instrument Enum**
Add an `Instrument` enum to `ContentView.swift` to manage navigation state.

```swift
enum Instrument: String, CaseIterable, Identifiable {
    case guitar = "Guitar Tab"
    case chords = "Chords"
    case bass = "Bass Tab"
    
    var id: String { self.rawValue }
    var icon: String {
        switch self {
        case .guitar: return "guitars"
        case .chords: return "music.note.list"
        case .bass: return "amplifier"
        }
    }
}
```

**Step 2: Update ContentView State**
Replace `tabType` string with `selectedInstrument` of type `Instrument?`.

---

### Task 2: Create Sidebar Components

**Files:**
- Modify: `Sources/AutoGuitarTabs/ContentView.swift`

**Step 1: Implement Now Playing Card**
Create a subview for the track info with glass styling.

**Step 2: Implement Navigation List**
Create a `List` within the sidebar using the `Instrument` enum.

**Step 3: Implement Utility Footer**
Move the `Source Priority` and `Auto-Refresh` toggle to the bottom of the sidebar.

---

### Task 3: Implement NavigationSplitView

**Files:**
- Modify: `Sources/AutoGuitarTabs/ContentView.swift`

**Step 1: Refactor body to NavigationSplitView**
```swift
NavigationSplitView {
    SidebarView(...)
} detail: {
    MainContentView(...)
}
```

**Step 2: Apply ultraThinMaterial Background**
Ensure the sidebar uses the correct macOS vibrancy.

---

### Task 4: Main Content "Floating Sheet" Design

**Files:**
- Modify: `Sources/AutoGuitarTabs/ContentView.swift`

**Step 1: Implement the "Sheet" Container**
Wrap the `WebView` in a container with a white background (in light mode) or dark gray (in dark mode), large rounded corners, and a soft shadow.

**Step 2: Implement Empty State View**
Create a refined "No Track Detected" view with SF Symbols and soft typography.

---

### Task 5: Floating Control Pill

**Files:**
- Modify: `Sources/AutoGuitarTabs/ContentView.swift`

**Step 1: Create the Control Pill View**
A small, floating glass pill at the bottom of the main content area.

**Step 2: Add Zoom and Scroll placeholders**
Implement basic buttons for future zoom/scroll functionality.

---

### Task 6: Final Polishing & Testing

**Step 1: Verify Layout Responsiveness**
Ensure the sidebar can be collapsed and the main content resizes correctly.

**Step 2: Verify Track Updates**
Confirm the "Now Playing" card updates when the `DetectionManager` publishes a new track.
