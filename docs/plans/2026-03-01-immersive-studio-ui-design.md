# Design Doc: The Immersive Studio UI (macOS)

## Overview
A complete UI overhaul for Auto Guitar Tabs, moving from a basic top-bar layout to a modern, **Refined Glassmorphism** sidebar interface. The design aims to feel like a premium macOS utility (similar to Apple Music or Notes) with a "musical studio" aesthetic.

## Aesthetic Direction: Refined Glassmorphism
- **Vibrancy & Transparency:** Extensive use of `ultraThinMaterial` and `thinMaterial` for backgrounds.
- **Typography:** 
  - **Headings:** SF Pro Rounded (Semibold) for a modern, friendly feel.
  - **Tabs/Chords:** JetBrains Mono or SF Mono for perfect alignment.
  - **Titles:** New York (Serif) for a premium "sheet music" look.
- **Color Palette:** System-aware (Light/Dark) with subtle accent glows based on the current track's metadata.

## Layout & Components

### 1. NavigationSplitView Sidebar (Width: 260pt)
- **"Now Playing" Dashboard (Top):**
  - Elevated glass card with `track.title` (Large) and `track.artist` (Medium).
  - Subtle animated "pulse" or waveform background.
  - Source badge (Spotify/YouTube icon).
- **Instrument Navigation (Middle):**
  - Custom rows for **Guitar Tab**, **Chords**, and **Bass Tab**.
  - Refined SF Symbols for each category.
  - "Deep" glass highlight effect for selection.
- **Utility Footer (Bottom):**
  - Source Priority menu (Compact).
  - Auto-Refresh toggle (Clean switch).

### 2. Main Content Area (Tab Viewer)
- **Floating Sheet:** Tab content displayed on a high-contrast sheet with soft, expansive shadows (`paper` feel).
- **Typography:** Monospaced for the tab data to ensure alignment of chords and lyrics.
- **Floating Glass Pill (Bottom Center):**
  - Zoom controls (+/-).
  - Auto-scroll toggle and speed slider.
- **Empty State:** High-quality musical iconography with "Ready to play?" messaging.

## Technical Implementation (SwiftUI)
- Use `NavigationSplitView` for the primary layout.
- Use `.background(.ultraThinMaterial)` for the sidebar.
- Implement a custom `TabViewStyle` or `ListStyle` for the instrument selection.
- Use `View.onReceive` or `onChange` to trigger subtle background glow transitions.
- Ensure `WebView` (or a native text view) is properly embedded in the floating sheet.

## Success Criteria
- [ ] Sidebar layout is responsive and follows macOS native behavior.
- [ ] "Now Playing" dashboard updates seamlessly with track changes.
- [ ] Tab content is clear, readable, and perfectly aligned (monospaced).
- [ ] The app feels like a high-end, native macOS application.
