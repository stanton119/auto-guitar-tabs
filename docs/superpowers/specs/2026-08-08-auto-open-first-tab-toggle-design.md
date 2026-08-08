# Auto-Open First Tab Toggle — Design

## Goal

Add a user-facing toggle that controls the WebView's automatic navigation from
the Ultimate Guitar search results page straight to the first "good" tab. When
OFF, the app stays on the search results list so the user can pick a tab
manually.

## Current Behavior

When a new song is detected, `refreshTab()` sets `currentURL` to the UG search
URL. When the search page finishes loading, `WebView.Coordinator.didFinish`
(WebView.swift:97-126) injects JS that:

1. Reads search results from `window.UGAPP.store.page.data`
2. Picks the first result whose type is `tab`/`chords`/`bass` with rating >= 3
3. Redirects `window.location.href` to that tab's URL
4. Uses a `sessionStorage` guard so it only auto-jumps once per query

## Changes

### 1. ContentView.swift

- Add `@State private var autoOpenFirstTab = true` near `autoRefresh` (:7).
- Pass it into the `WebView` initializer (:43).
- Pass a `@Binding` to `SidebarFooter` (:34).

### 2. SidebarFooter (in ContentView.swift)

- Add `@Binding var autoOpenFirstTab: Bool`.
- Add a `Toggle("Auto-Open First Tab")` directly under the existing
  "Auto-Refresh" toggle (:205-210).

### 3. WebView.swift

- Add `let autoOpenFirstTab: Bool` property.
- In `updateNSView`, mirror into the Coordinator:
  `context.coordinator.autoOpenFirstTab = autoOpenFirstTab`.
- Coordinator: add `var autoOpenFirstTab = true`; in `didFinish` (:97),
  early-return before the JS injection when `false`.

## Behavior

- ON (default): unchanged — first tab/chords/bass result with rating >= 3
  opens immediately.
- OFF: the search results page remains visible; the user clicks a tab manually.
- The existing `sessionStorage` guard still prevents repeat jumps on the same
  query.

## Out of Scope

- No persistence across app relaunches (the setting resets to ON on launch).
- No change to the result-selection heuristic (type/rating filter).