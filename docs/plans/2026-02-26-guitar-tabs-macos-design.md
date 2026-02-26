# Design Doc: Auto Guitar Tabs (macOS)

## Overview
A native macOS application that automatically detects the currently playing song on the Spotify desktop app or YouTube (in Safari) and fetches/displays the corresponding guitar tab from Ultimate Guitar.

## Features
- **Automatic Song Detection:** Uses AppleScript to poll Spotify and Safari every 3 seconds.
- **Ultimate Guitar Integration:** Searches and fetches text-based tabs, chord sheets, and bass tabs.
- **Horizontal Top Bar Navigation:** 
  - Current Track Display.
  - Tab Type Toggle (Guitar Tab, Chords, Bass Tab).
  - Auto-Refresh toggle for "Fully Automatic" mode.
- **Clean Tab Viewer:** Scrollable area with fixed-width font support and optional auto-scroll.
- **Native Experience:** Built with SwiftUI for optimal performance and macOS system integration.

## Architecture
1. **App Layer (SwiftUI):** Main window and Top Navigation Bar.
2. **Detection Manager (Swift/AppleScript):** Periodically polls `com.spotify.client` and `com.apple.Safari` for track info.
3. **Tab Search Engine:** 
   - Constructs search URLs for Ultimate Guitar.
   - Fetches HTML and parses the internal JSON data for the tab content.
4. **View Controller:** Manages the state of the current tab and handles switching between versions.

## Success Criteria
- [ ] Successfully detects song changes in Spotify.
- [ ] Successfully detects song changes in YouTube (Safari).
- [ ] Displays the correct tab from Ultimate Guitar within 5 seconds of a song change.
- [ ] Allows switching between Guitar Tab, Chords, and Bass Tab.

## Technical Stack
- **Language:** Swift 5.10+
- **Framework:** SwiftUI
- **Automation:** AppleScript / NSAppleScript
- **Data Fetching:** URLSession
