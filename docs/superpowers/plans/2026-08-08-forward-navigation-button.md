# Forward Navigation Button Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a toolbar Forward button that is only enabled when Back has been pressed (forward history exists), mirroring the existing Back button's trigger pattern.

**Architecture:** The app's tab container is a `WKWebView` that already tracks navigation history and exposes `canGoBack` / `canGoForward` as KVO-observable properties. The existing Back button fires a `goBack()` call via an integer trigger binding. Forward works the same way with `goForward()`, while KVO observation surfaces `canGoBack` / `canGoForward` into SwiftUI state so the toolbar buttons disable when a direction has no history.

**Tech Stack:** Swift 5.10, SwiftUI (`NSViewRepresentable`), WebKit (`WKWebView`), macOS 14.

## Global Constraints

- Target platform: macOS 14 (`Package.swift`), no new dependencies.
- WebView actions are driven by integer trigger bindings (`goBackTrigger`, `reloadTrigger`); forward must follow the same pattern.
- KVO observation uses `NSKeyValueObservation` on `WKWebView.canGoBack` and `.canGoForward`; observers are created in `makeNSView` and invalidated in `Coordinator.deinit`.
- No new comments in code unless explaining a non-obvious reason; match existing style (spaces, 4-space indent, `Color(NSColor.underPageBackgroundColor)` style).
- No unit tests cover `WebView` (per spec). Verification is `swift build` + manual launch. `swift test` must still pass (existing tests unaffected).
- Commit after each task with `git commit` using the repo's `feat:` / `docs:` message style.

---

### Task 1: WebView forward trigger + KVO state bindings

**Files:**
- Modify: `Sources/AutoGuitarTabs/WebView.swift` (struct properties 5-10, `makeNSView` 12-22, `updateNSView` 54-57, `Coordinator` 69-72)

**Interfaces:**
- Consumes: existing `reloadTrigger`, `goBackTrigger`, `zoomLevel`, `autoScrollEnabled`, `scrollSpeed` bindings.
- Produces: new `@Binding var goForwardTrigger: Int`, `@Binding var canGoBack: Bool`, `@Binding var canGoForward: Bool`; `Coordinator` exposes `lastGoForward: Int`, `onCanGoBackChange: ((Bool) -> Void)?`, `onCanGoForwardChange: ((Bool) -> Void)?`, `canGoBackObservation: NSKeyValueObservation?`, `canGoForwardObservation: NSKeyValueObservation?`. Task 2 passes all three new bindings and reads the toolbar state.

- [ ] **Step 1: Add the three new bindings to `WebView`**

In `Sources/AutoGuitarTabs/WebView.swift`, after the existing `@Binding var goBackTrigger: Int` (line 7), add:

```swift
    @Binding var goForwardTrigger: Int
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
```

- [ ] **Step 2: Set up KVO observations in `makeNSView`**

Replace the body of `makeNSView` (lines 12-22) so it registers closures and observations before returning the web view:

```swift
    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
        webView.navigationDelegate = context.coordinator

        // Initial zoom
        webView.magnification = CGFloat(zoomLevel) / 100.0

        context.coordinator.onCanGoBackChange = { canGoBack = $0 }
        context.coordinator.onCanGoForwardChange = { canGoForward = $0 }
        context.coordinator.canGoBackObservation = webView.observe(\.canGoBack, options: [.initial, .new]) { webView, _ in
            context.coordinator.onCanGoBackChange?(webView.canGoBack)
        }
        context.coordinator.canGoForwardObservation = webView.observe(\.canGoForward, options: [.initial, .new]) { webView, _ in
            context.coordinator.onCanGoForwardChange?(webView.canGoForward)
        }

        return webView
    }
```

The `.initial` option fires each observer once with the current value, so the toolbar state is correct on launch.

- [ ] **Step 3: Add the forward trigger handler in `updateNSView`**

In `Sources/AutoGuitarTabs/WebView.swift`, insert immediately after the existing `goBackTrigger` block (after line 57):

```swift
        if goForwardTrigger > context.coordinator.lastGoForward {
            nsView.goForward()
            context.coordinator.lastGoForward = goForwardTrigger
        }
```

- [ ] **Step 4: Extend `Coordinator` with forward state and observers**

Replace the `Coordinator` class opening (lines 69-72) with:

```swift
    class Coordinator: NSObject, WKNavigationDelegate {
        var lastLoadedURL: URL?
        var lastGoBack = 0
        var lastGoForward = 0
        var lastReload = 0
        var onCanGoBackChange: ((Bool) -> Void)?
        var onCanGoForwardChange: ((Bool) -> Void)?
        var canGoBackObservation: NSKeyValueObservation?
        var canGoForwardObservation: NSKeyValueObservation?

        deinit {
            canGoBackObservation?.invalidate()
            canGoForwardObservation?.invalidate()
        }
```

The `didFinish` method body is unchanged.

- [ ] **Step 5: Build to verify WebView compiles**

Run: `swift build`
Expected: builds without error. (ContentView does not yet pass the new bindings, so the app target will NOT compile yet — this is expected and will be fixed in Task 2. If you want a compiling checkpoint, skip this step until after Task 2.)

- [ ] **Step 6: Commit**

```bash
git add Sources/AutoGuitarTabs/WebView.swift
git commit -m "feat: add forward trigger and navigation state to WebView"
```

### Task 2: Toolbar Forward button with disabled state

**Files:**
- Modify: `Sources/AutoGuitarTabs/ContentView.swift` (state at lines 10-11, `WebView` call at line 38, toolbar at lines 65-75)

**Interfaces:**
- Consumes: `WebView` bindings `goForwardTrigger`, `canGoBack`, `canGoForward` from Task 1.
- Produces: nothing downstream.

- [ ] **Step 1: Add state for forward navigation**

In `Sources/AutoGuitarTabs/ContentView.swift`, replace lines 10-11:

```swift
    // Triggers for WebView actions
    @State private var reloadTrigger = 0
    @State private var goBackTrigger = 0
```

with:

```swift
    // Triggers for WebView actions
    @State private var reloadTrigger = 0
    @State private var goBackTrigger = 0
    @State private var goForwardTrigger = 0

    // WebView navigation history state (drives toolbar button enablement)
    @State private var canGoBack = false
    @State private var canGoForward = false
```

- [ ] **Step 2: Pass the new bindings to `WebView`**

Replace the `WebView(...)` call at line 38 with:

```swift
                            WebView(url: url, reloadTrigger: $reloadTrigger, goBackTrigger: $goBackTrigger, goForwardTrigger: $goForwardTrigger, canGoBack: $canGoBack, canGoForward: $canGoForward, zoomLevel: $zoomLevel, autoScrollEnabled: $autoScrollEnabled, scrollSpeed: $scrollSpeed)
```

- [ ] **Step 3: Add the Forward button and disable Back/Forward based on history**

Replace the toolbar `ToolbarItemGroup(placement: .navigation)` block (lines 65-75) with:

```swift
                ToolbarItemGroup(placement: .navigation) {
                    Button(action: { goBackTrigger += 1 }) {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(!canGoBack)
                    .help("Go Back")

                    Button(action: { goForwardTrigger += 1 }) {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(!canGoForward)
                    .help("Go Forward")

                    Button(action: { reloadTrigger += 1 }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help("Reload")
                }
```

- [ ] **Step 4: Build and run tests to verify**

Run: `swift build && swift test`
Expected: app target and test target build; all existing tests pass (URL extraction, DetectionManager).

- [ ] **Step 5: Manual verification**

Run: `swift run` (or `./package.sh` to bundle, then open `AutoGuitarTabs.app`). Verify:
1. On launch, Back and Forward are both disabled.
2. Start playback so a tab search loads; once a result page is open, Back becomes enabled, Forward stays disabled.
3. Press Back → page returns to the previous search, Forward becomes enabled.
4. Press Forward → page returns to the result, Forward becomes disabled again.
5. Reload and zoom/auto-scroll controls still work.

- [ ] **Step 6: Commit**

```bash
git add Sources/AutoGuitarTabs/ContentView.swift
git commit -m "feat: add forward navigation button to toolbar"
```
