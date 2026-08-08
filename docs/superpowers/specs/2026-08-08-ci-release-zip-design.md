# CI Release Zip — Design

## Goal

Make Auto Guitar Tabs deliverable to non-technical users as a prebuilt `.zip`
of the `.app` bundle, produced automatically by GitHub Actions on each
published GitHub Release. Users download a single file, unzip it, and run the
app — no Swift toolchain or terminal required.

## Background / Constraints

- The developer has only a free Apple account, so **notarization is not
  possible** (requires a paid Apple Developer Program membership and a
  Developer ID certificate). This design does not attempt notarization.
- The app is built with Swift Package Manager (`Package.swift`), macOS 14
  target, Apple Silicon.
- `package.sh` already creates a complete `AutoGuitarTabs.app` bundle in the
  project root (build release binary, create `Contents/MacOS`/`Resources`,
  copy binary, write `Info.plist`).

## Architecture

One new GitHub Actions workflow file:
`.github/workflows/release.yml`.

The workflow:

1. Triggers on `github.event_name == 'release'`, `action == 'published'`.
2. Checks out the repo and runs on `macos-14` (Apple Silicon) so the build
   matches the supported environments.
3. Builds the release binary: `swift build -c release`.
4. Runs `./package.sh` (existing script) to assemble
   `AutoGuitarTabs.app`.
5. Ad-hoc code-signs the bundle:
   `codesign --force --deep -s - AutoGuitarTabs.app`.
   This free identity (no Apple account) gives the bundle a stable signature
   so Gatekeeper falls back to the standard "right-click → Open" flow instead
   of the "app is damaged" error on downloaded files. It is NOT notarization —
   users will still see the one-time unidentified-developer prompt.
6. Zips it with a versioned name derived from the release tag:
   `AutoGuitarTabs-<tag>-macOS.zip`.
7. Attaches the zip to the release using `softprops/action-gh-release`
   (set `created` to false, `append_only` so existing assets aren't
   overwritten) and uploads it as the asset source.

### Steps as job (single job)

| step | command |
|------|---------|
| checkout | `actions/checkout@v4` |
| build | `swift build -c release` |
| package | `./package.sh` |
| sign | `codesign --force --deep -s - AutoGuitarTabs.app` |
| stage | `cp -R AutoGuitarTabs.app dist/` + write `dist/INSTALL.txt` |
| zip | `ditto -c -k --keepParent dist AutoGuitarTabs-${TAG}-macOS.zip` |
| attach | `softprops/action-gh-release@v2` with `files: AutoGuitarTabs-${TAG}-macOS.zip` |

The `stage` step copies the signed `AutoGuitarTabs.app` into a `dist/` folder
and writes `INSTALL.txt` (see Documentation) alongside it. The `zip` step then
bundles the entire `dist/` folder, so the zip contains both the app and the
plain-English instructions.

The release tag is read from `${{ github.event.release.tag_name }}` and
stripped of any leading `v` for the zip name.

## Error handling

- If `swift build`, `./package.sh`, or `codesign` fails, the job fails and no
  release asset is attached (bad artifact guard).
- `softprops/action-gh-release` runs with `append_only: true` so re-running a
  build for an already-published release appends rather than overwrites.

## Documentation

### INSTALL.txt (included inside the zip)

A plain-English text file placed inside the zip (in addition to the .app):

1. Unzip `AutoGuitarTabs-<version>-macOS.zip`.
2. Drag `AutoGuitarTabs.app` to your Applications folder.
3. First launch: right-click the app (or open it with right-click > Open) and
   choose Open the first time — macOS shows one warning because the app
   isn't notarized.
4. Launch the app and enjoy.

### README change

Add a "How to Install" section above How to Run:

- "Non-developers: download AutoGuitarTabs.app here (link to the latest
  release/a specific release asset), unzip, drag to Applications, right-click
  → Open on the first launch."

## Out of Scope

- **Notarization** / paid Apple Developer account — explicitly out; documented
  but not implemented.
- **DMG generation**, installer packages, or auto-update.
- No changes to `package.sh` (it stays the manifest-compatible packaging
  script; CI calls it then adds signing on top).
- No change to the app code itself.