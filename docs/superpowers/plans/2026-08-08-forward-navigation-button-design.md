# Design: Forward Navigation Button

## Goal

Add a forward button to the toolbar so users can navigate forward in the tab history after pressing Back. The forward button is only enabled when the Back button has been pressed (i.e. when forward history exists).

## Approach

The tab container is a `WKWebView` which already maintains its own navigation history and exposes `canGoBack` / `canGoForward`. Model the forward action the same way the existing Back button works: an integer trigger that is incremented by the toolbar button, prompting the coordinator to call `goForward()`. Visibility is driven by KVO observation of `canGoForward` (and `canGoBack` for symmetry), surfaced into SwiftUI state so the toolbar buttons can be disabled when no history direction is available.

## Changes

### 1. `WebView` (`Sources/AutoGuitarTabs/WebView.swift`)

- Add bindings:
  - `@Binding var goForwardTrigger: Int` — incremented by the toolbar to fire `nsView.goForward()`.
  - `@Binding var canGoBack: Bool` — toggled by KVO so the Back button can be disabled when there is no back history.
  - `@Binding var canGoForward: Bool` — toggled by KVO so the Forward button is disabled until Back is pressed.
- Pass these bindings from `ContentView`.
- In `updateNSView`, mirror the `goBackTrigger` handler:
  - If `goForward > context.coordinator.lastGoForward`, call `nsView.goForward()` and store the last value.
- In `Coordinator`:
  - Track `lastGoForward` alongside `lastGoBack` / `lastReload`.
  - In `makeNSView`, after `setMagnification`, observe `canGoBack` and `canGoForward` via KVO (`webView.addObserver(...)`) and in `observeValue` update the corresponding bindings with the new value (initialized from the view's current values).
  - In `deinit` (or `Coordinator` teardown), remove the observers.

### 2. `ContentView` (`Sources/AutoGuitarTabs/ContentView.swift`)

- Add `@State private var goForwardTrigger = 0`, `@State private var canGoBack = false`, `@State private var canGoForward = false`.
- Pass the three new bindings into `WebView`.
- In the toolbar `ToolbarItemGroup(placement: .navigation)`, add a forward button after Back:
  - `Button(action: { goForwardTrigger += 1 }) { Image(systemName: "chevron.right") }`, `.help("Go Forward")`.
  - `.disabled(!canGoForward)`.
- Add `.disabled(!canGoBack)` to the existing Back button.

## Behavior

- On launch, both Back and Forward are disabled (no navigation history yet).
- After auto-loading a tab search result, Back becomes enabled; pressing it returns to the previous page and enables Forward.
- Pressing Forward navigates forward through real page history and disables Forward at the newest page.
- Toolbar Back / Forward state stays in sync as the user clicks other in-app links that change history.

## Testing

No unit tests currently cover `WebView`. Verify by building and launching the app: load a tab, navigate into a result, press Back (Forward becomes enabled), press Forward (returns to result, Forward disables). Confirm buttons start disabled and only enable when history supports the direction.