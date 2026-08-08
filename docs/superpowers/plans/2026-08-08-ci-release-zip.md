# CI Release Zip Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a GitHub Actions workflow that, on each published release, builds AutoGuitarTabs, ad-hoc signs the bundle, and attaches a versioned `AutoGuitarTabs-<tag>-macOS.zip` (containing the `.app` plus a plain-English `INSTALL.txt`) to that release.

**Architecture:** A single new workflow file (`.github/workflows/release.yml`) runs on a `macos-14` runner, calls the existing `package.sh` to assemble the `.app`, ad-hoc code-signs it, stages it with `INSTALL.txt`, zips the staging folder, and uploads the zip to the triggering release via `softprops/action-gh-release`. Documentation is added via a new `INSTALL.txt` composer step and a README "How to Install" section.

**Tech Stack:** GitHub Actions, SwiftPM (`swift build -c release`), bash (`package.sh`), `codesign`, `ditto`, `softprops/action-gh-release@v2`.

## Global Constraints

- macOS 14 minimum target (from `Package.swift`); runner: `macos-14`.
- **No notarization** — developer has only a free Apple account; must not attempt signing beyond ad-hoc `codesign --force --deep -s -`.
- Do not modify `package.sh` — CI calls it unchanged, then signs on top.
- Do not modify app source code (`Sources/`, `Tests/`).
- Zip name: `AutoGuitarTabs-<release-tag-stripped-of-leading-v>-macOS.zip`.
- Workflow triggers on `release` events with `types: [published]`.

---

### Task 1: Create the release workflow

**Files:**
- Create: `.github/workflows/release.yml`

**Interfaces:**
- Consumes: existing `package.sh` (builds `AutoGuitarTabs.app` in project root), `Package.swift`.
- Produces: workflow job `build` → release asset `AutoGuitarTabs-<tag>-macOS.zip` attached to the triggering release.

- [ ] **Step 1: Create `.github/workflows/release.yml`**

```yaml
name: Build and Attach Release Zip

on:
  release:
    types: [published]

jobs:
  build:
    runs-on: macos-14
    permissions:
      contents: write
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Build release binary
        run: swift build -c release

      - name: Assemble app bundle
        run: ./package.sh

      - name: Ad-hoc code-sign bundle
        run: codesign --force --deep -s - AutoGuitarTabs.app

      - name: Compute version from tag
        id: version
        run: |
          TAG="${{ github.event.release.tag_name }}"
          VER="${TAG#v}"
          echo "version=$VER" >> "$GITHUB_OUTPUT"

      - name: Stage app and install instructions
        run: |
          mkdir -p dist
          cp -R AutoGuitarTabs.app dist/
          cat > dist/INSTALL.txt <<'EOF'
          AutoGuitarTabs — How to Install

          1. Unzip this file.
          2. Drag the AutoGuitarTabs.app folder into your Applications folder.
          3. The first time you open it, right-click the app and choose Open.
             macOS shows a warning because the app is not notarized; click Open.
          4. Enjoy! Launch AutoGuitarTabs from Launchpad or Applications.
          EOF

      - name: Create release zip
        run: ditto -c -k --keepParent dist "AutoGuitarTabs-${{ steps.version.outputs.version }}-macOS.zip"

      - name: Attach zip to release
        uses: softprops/action-gh-release@v2
        with:
          files: "AutoGuitarTabs-${{ steps.version.outputs.version }}-macOS.zip"
          name: ${{ github.event.release.tag_name }}
          append_only: true
          fail_on_unmatched_files: true
```

- [ ] **Step 2: Validate the YAML parses**

Run: `python3 -c "import yaml, sys; yaml.safe_load(open('.github/workflows/release.yml'))"` (if PyYAML absent, run `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/release.yml")'`)
Expected: no output / no exception.

- [ ] **Step 3: Sanity-check workflow block structure**

Run: `grep -c 'on:' .github/workflows/release.yml && grep -c 'jobs:' .github/workflows/release.yml`
Expected: `1` for each and output shows both present.

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/release.yml
git commit -m "feat: add CI workflow to build and attach release zip"
```

- [ ] **Step 5: Verify on GitHub (manual, after first push)**

Push to `main`, create a draft Release with tag `0.1.0` and publish it. The workflow should attach `AutoGuitarTabs-0.1.0-macOS.zip` to the release with the correct asset name. Screenshot or note the asset presence. (If unavailable, note this as pending manual verification.)

---

### Task 2: Add "How to Install" docs to the README

**Files:**
- Modify: `README.md` — insert new "How to Install" section between the "Requirements" section (line 21) and "How to Run" (line 22), and add the release download link text.

**Interfaces:**
- Consumes: `README.md` structure (confirmed in current file, `:21`-`:22` boundary).
- Produces: `README.md` with a non-developer install path.

- [ ] **Step 1: Add "How to Install" section**

Insert between "Requirements" and "How to Run" (current line 21/22 boundary):

```markdown
## How to Install (No Coding Required)

If you just want to use AutoGuitarTabs, download the latest release:

- **[Download AutoGuitarTabs](https://github.com/stanton119/auto-guitar-tabs/releases/latest)**

1.  Unzip `AutoGuitarTabs-<version>-macOS.zip`.
2.  Drag `AutoGuitarTabs.app` into your Applications folder.
3.  First launch: right-click the app and choose **Open**. (macOS shows one
    warning because the app is not notarized — click **Open** to continue.)
4.  Launch AutoGuitarTabs from Launchpad or Applications, and enjoy.

This section is for non-developers. If you want to build or run the app from
source, continue to [How to Run](#how-to-run).
```

- [ ] **Step 2: Verify markdown renders without breaking existing section anchors**

Run: `grep -n '^## How to' README.md`
Expected: both `## How to Install` and `## How to Run` headings present, numbered.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: add non-developer How to Install section"
```