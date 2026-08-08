# Design: "All" Instrument Type

## Goal

Add an "All" instrument option to the sidebar so users can view Ultimate Guitar results without filtering by instrument type.

## Approach

Model "All" as the first case of the existing `Instrument` enum and omit the `type[]` URL query parameter when it is selected. Ultimate Guitar treats an absent `type[]` filter as "all types", so no special request handling is needed beyond leaving the parameter out.

## Changes

### 1. `Instrument` enum (`Sources/AutoGuitarTabs/ContentView.swift`)

- Replace the current enum case list with `.all` first, followed by `.guitar`, `.chords`, `.bass`. Default enum ordering places "All" at the top of the sidebar list.
- Add a `typeID: Int?` computed property:
  - `.all` → `nil`
  - `.guitar` → `200`
  - `.chords` → `300`
  - `.bass` → `400`
- Add `.all` to the `icon` switch:
  - `.all` → `music.note`
- Remove the `typeMap` local dictionary in `refreshTab()`.

### 2. Default selection (`ContentView.swift:6`)

- Change `@State private var selectedInstrument: Instrument = .guitar` to `.all`.

### 3. URL building (`refreshTab()` at `ContentView.swift:89`)

- Build `queryItems` conditionally:
  - If `selectedInstrument.typeID` is non-nil, append `URLQueryItem(name: "type[]", value: String(typeID))`.
  - If nil (i.e. "All"), omit the `type[]` item entirely.
- Artist/title `value` query item is unchanged.

## Behavior

- App launches with "All" selected, so search results are not filtered by type.
- Selecting "All" in the sidebar reloads unfiltered results via the existing `onChange(of: selectedInstrument)` handler.
- Selecting Guitar Tab / Chords / Bass behaves exactly as today.

## Testing

No unit tests currently cover URL construction. Add one unit test asserting the generated URL for `.all` contains no `type[]` query item and for `.guitar` contains `type[]=200`, if the URL-building logic is extracted into a testable function. Otherwise Best-effort: verify by building and launching the app.