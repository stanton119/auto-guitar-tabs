# Auto-Open First Tab Toggle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a sidebar toggle that controls whether the WebView auto-navigates from UG search results to the first good tab.

**Architecture:** A new `@State`-backed `autoOpenFirstTab` flag lives in `ContentView`, is passed into `WebView` as a plain `let` value (mirroring `zoomLevel`/`scrollSpeed`), re-synced into the `Coordinator` inside `updateNSView` (and initially in `makeNSView`), and read by `didFinish` which guards the injected JS redirect. The toggle sits in the sidebar footer under the existing "Auto-Refresh" switch.

**Tech Stack:** Swift, SwiftUI, WebKit (WKWebView). Swift Package Manager (macOS 14+ target).

## Global Constraints

- Do not change the result-selection heuristic in the injected JS (allowed types + rating >= 3).
- Do not change `autoRefresh` behavior or the other WebView triggers (`reloadTrigger`, `goBackTrigger`, `goForwardTrigger`).
- No persistence: `autoOpenFirstTab` resets to `true` each launch.
- Existing `sessionStorage` guard in the JS must remain untouched.
- Setting defaults to ON (`true`).
- `autoOpenFirstTab` is a plain `let` value on `WebView` (NOT a `@Binding`), matching the `zoomLevel`/`autoScrollEnabled` property style. The `@State`/`@Binding` plumbing lives only in `ContentView`/`SidebarFooter`.
- **Ordering resolution (approved):** Task 1 declares `var autoOpenFirstTab: Bool = true` (a defaulted `var` IS a memberwise-init parameter; `let` is excluded) with a default so the existing call site compiles untouched; Task 2 adds the `@State` property and then updates the call site to pass it explicitly.

**Verification note:** `swift build` succeeds in this environment; `swift test` currently fails with a pre-existing environment error (`no such module 'XCTest'`) unrelated to this feature. Do not attempt to fix the test toolchain as part of this plan; verify only with `swift build`.

---
## File Structure

- `Sources/AutoGuitarTabs/WebView.swift`: add `autoOpenFirstTab` property, sync to Coordinator, guard `didFinish`.
- `Sources/AutoGuitarTabs/ContentView.swift`: add state, wire into `WebView` init and `SidebarFooter`.

---
### Task 1: Guard the JS injection in WebView

**Files:**
- Modify: `Sources/AutoGuitarTabs/WebView.swift` (struct properties ~line 13, `makeNSView` ~line 15-32, `updateNSView` ~line 34-39, Coordinator ~line 84-97)

**Interfaces:**
- Consumes: none
- Produces: `WebView(url:..., reloadTrigger:..., goBackTrigger:..., goForwardTrigger:..., canGoBack:..., canGoForward:..., zoomLevel:..., autoScrollEnabled:..., scrollSpeed:..., autoOpenFirstTab: Bool = true)` — a new init parameter with a default; `Coordinator.autoOpenFirstTab: Bool`.

- [ ] **Step 1: Add the `autoOpenFirstTab` property**

In `WebView.swift`, add a new stored property after `scrollSpeed` (line 13):

```swift
    var autoOpenFirstTab: Bool = true
```

The default value keeps the existing call site at `ContentView.swift:43` compiling unchanged — the call site is updated in Task 2 once the `@State` exists.

- [ ] **Step 2: Sync the initial value into the Coordinator**

In `makeNSView`, after `context.coordinator.canGoForwardObservation = webView.observe(...)` (line 28-29), add:

```swift
        context.coordinator.autoOpenFirstTab = autoOpenFirstTab
```

- [ ] **Step 3: Re-sync on every update**

At the top of `updateNSView` (`WebView.swift:34`), after the function opening brace, add:

```swift
        context.coordinator.autoOpenFirstTab = autoOpenFirstTab
```

- [ ] **Step 4: Add the Coordinator property and guard `didFinish`**

Add to `Coordinator` at the existing stored properties (after `var canGoForwardObservation` at line 90):

```swift
        var autoOpenFirstTab = true
```

Then in `webView(_:didFinish:)` at line 97, insert a guard before the `if webView.url...` check:

```swift
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard autoOpenFirstTab else { return }
            if webView.url?.absoluteString.contains("search.php") == true {
```

The injected JS and the rest of the method remain unchanged.

- [ ] **Step 5: Build to verify**

Run: `swift build`
Expected: Build complete with zero errors (the default value keeps the existing call site compiling). Do NOT run `swift test` — pre-existing toolchain error `no such module 'XCTest'`.

- [ ] **Step 6: Commit**

```bash
git add Sources/AutoGuitarTabs/WebView.swift
git commit -m "feat: gate auto-open-first-tab JS injection behind a flag"
```

---
### Task 2: Add the state and sidebar toggle

**Files:**
- Modify: `Sources/AutoGuitarTabs/ContentView.swift:7` (state), `:43` (WebView call site), `:34` (SidebarFooter), `:183-216` (SidebarFooter struct)

**Interfaces:**
- Consumes: `WebView(... autoOpenFirstTab: Bool = true)` init parameter (from Task 1).
- Produces: `@State private var autoOpenFirstTab = true` in `ContentView`; `@Binding var autoOpenFirstTab: Bool` on `SidebarFooter`.

- [ ] **Step 1: Add the state property**

In `ContentView`, after `@State private var autoRefresh = true` (line 7):

```swift
    @State private var autoOpenFirstTab = true
```

- [ ] **Step 2: Update the WebView call site**

At `ContentView.swift:43`, add the trailing argument to the `WebView(...)` initializer (relies on the property from Step 1):

```swift
                            WebView(url: url, reloadTrigger: $reloadTrigger, goBackTrigger: $goBackTrigger, goForwardTrigger: $goForwardTrigger, canGoBack: $canGoBack, canGoForward: $canGoForward, zoomLevel: $zoomLevel, autoScrollEnabled: $autoScrollEnabled, scrollSpeed: $scrollSpeed, autoOpenFirstTab: autoOpenFirstTab)
```

- [ ] **Step 3: Pass it to `SidebarFooter`**

At `ContentView.swift:34`, update the `SidebarFooter` construction:

```swift
                SidebarFooter(detectionManager: detectionManager, autoRefresh: $autoRefresh, autoOpenFirstTab: $autoOpenFirstTab)
```

- [ ] **Step 4: Add the binding and toggle to `SidebarFooter`**

In `struct SidebarFooter` (line 183), add a new binding after the existing `autoRefresh` binding:

```swift
    @Binding var autoOpenFirstTab: Bool
```

Then, directly under the existing "Auto-Refresh" toggle (line 205-210), inside the same inner `VStack(alignment: .leading, spacing: 10)`, add:

```swift
                Toggle(isOn: $autoOpenFirstTab) {
                    Text("Auto-Open First Tab")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .toggleStyle(.switch)
```

- [ ] **Step 5: Build to verify**

Run: `swift build`
Expected: Build complete with zero errors. (Do NOT run `swift test` — pre-existing toolchain error.)

- [ ] **Step 6: Commit**

```bash
git add Sources/AutoGuitarTabs/ContentView.swift
git commit -m "feat: add auto-open-first-tab toggle to sidebar"
```

---
## Self-Review

- **Spec coverage:** Toggle in sidebar footer under Auto-Refresh ✓; state defaults `true` ✓; `WebView.autoOpenFirstTab` plain value + Coordinator mirror ✓; `didFinish` early-return guard ✓; sessionStorage JS untouched ✓; no persistence ✓.
- **Placeholder scan:** No TBD/TODO; every step has concrete code or an exact edit target.
- **Type consistency:** `autoOpenFirstTab` is `let ...: Bool = true` on `WebView`, `Bool` on `Coordinator`, `@State ... = true` in `ContentView`, `@Binding var autoOpenFirstTab: Bool` on `SidebarFooter`. Task 2 call-site passes `autoOpenFirstTab` (value) to `WebView` and `$autoOpenFirstTab` (binding) to `SidebarFooter`. Consistent across compilations.

## Execution Notes

- **Pre-flight resolution (approved by human):** Task 1 originally updated the WebView call site before the `@State` existed, which would break Task 1's own build. Changed so Task 1 adds `var autoOpenFirstTab: Bool = true` (default keeps existing call site compiling) and the call-site update moved to Task 2.