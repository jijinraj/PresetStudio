# PresetStudio Roadmap

> Living development checklist.
> Update this file as features are completed, changed, or deferred.

## Current milestone — Editor foundation

- [x] Image import
- [x] Non-destructive editor session
- [x] Exposure
- [x] Contrast
- [x] Saturation
- [x] Highlights
- [x] Shadows
- [x] Whites
- [x] Blacks
- [x] GPU tonal shader
- [x] Rotation
- [x] Horizontal / vertical flip
- [x] History
- [x] Undo / Redo
- [x] Reset adjustments
- [x] Hold Before / After
- [x] Desktop + mobile zoom
- [x] Viewport pan
- [x] Fix adjustment-slider mouse-wheel propagation
- [x] Invert vertical mouse panning on desktop

## Immediate UX work

- [x] Move mobile Before / After beside Change Image
- [x] Keep desktop hold Before / After in toolbar
- [x] Add desktop side-by-side Before / After
- [x] Synchronize zoom / pan between Before and After
- [x] History v2

## History v2

- [x] Make desktop History collapsible
- [x] Coalesce mouse-wheel adjustment changes into one meaningful history entry
- [x] Coalesce continuous keyboard adjustment changes
- [x] Keep slider drags grouped as one history entry
- [x] Suppress no-op transactions that finish at their starting state
- [x] Store replayable before/after state for history operations
- [x] Add non-destructive enable / disable toggles for individual edits
- [x] Rebuild the current image from enabled history operations
- [x] Keep Undo / Redo chronological while edits are disabled
- [x] Add Enable all edits and safe Clear history actions
- [x] Add semantic/logical history groups for future compound actions
- [ ] Later: design permanent delete/rebase semantics separately from enable/disable

## Crop & geometry

- [x] Add non-destructive crop model
  - [x] Normalized crop rectangle
  - [x] Free / constrained aspect-ratio state
  - [x] Fine straighten state
  - [x] Crop scale and normalized image offset
  - [x] History replay / enable-disable support
- [x] Add interactive crop viewport
- [x] Render committed crop composition in normal desktop/mobile preview
- [x] Keep committed crop visible in Before/After and side-by-side views
- [ ] Add free crop (deferred; hidden from the current UI until arbitrary crop geometry is stable)
- [x] Add resize handles
- [x] Add image repositioning inside crop
- [x] Add image zoom with desktop wheel and mobile pinch
- [x] Clamp crop pan so the frame never exposes empty pixels
- [x] Add Tilt / Straighten
- [x] Keep crop frame stable while straightening
  - [x] Guarantee image coverage for portrait/landscape ratio changes
  - [x] Auto-scale coverage for ordinary rotation + straighten
  - [x] Use focused desktop crop mode with read-only surrounding UI
- [x] Add crop grid while interacting
- [x] Add aspect ratios
- [x] Swap fixed crop ratios between portrait and landscape orientation
- [x] Speed up desktop crop panning while preserving inverse vertical motion
- [x] Remove misaligned ghost background from the crop workspace
  - [x] Original
  - [x] Free
  - [x] 1:1
  - [x] 4:5
  - [x] 3:4
  - [x] 2:3
  - [x] 3:2
  - [x] 16:9
  - [x] 9:16
- [x] Group crop gestures into single History transactions
- [ ] Improve crop UI toward Adobe-style workflow

## Composition guides

- [x] Separate composition-guide UI state from CropState and History
- [x] Add None guide
- [x] Add Rule of Thirds
- [x] Add Center / Symmetry
- [x] Add Square Grid
- [x] Add Fine Grid
- [x] Add Phi Grid / Golden Ratio
- [x] Add Golden Spiral
- [x] Add Golden Triangle
- [x] Add Diagonal Method
- [x] Add guide orientation controls where relevant
- [x] Add guide opacity control
- [x] Add guide color control

## Color controls

- [x] Temperature
- [x] Tint
- [x] Vibrance
- [ ] Finish Color panel UX

## Presets v1

- [x] Define versioned preset JSON schema
- [x] Define portable preset metadata and adjustment mapping
- [x] Keep crop / transform geometry out of Presets v1; reserve geometry for templates
- [x] Define a multi-source remote preset registry without coupling preset files to Git hosting
- [x] Save current adjustments as preset
- [x] Apply preset
- [x] Rename preset
- [x] Delete preset
- [x] Local / offline preset library
- [x] Import preset JSON
- [x] Export preset JSON
- [x] Persist preset source registry
- [x] Add / remove / enable multiple repository or catalog URLs
- [x] Add repository-backed catalog provider
- [x] Add generic catalog URL provider
- [x] Cache remote catalogs and installed presets for offline use
- [x] Add optional remote preset preview metadata and local preview cache
- [x] Add remote preset descriptions and tags in Discover
- [x] Render Discover presets against the currently edited image when available
- [x] Move desktop presets from the Library sidebar into a collapsible bottom tray
- [x] Apply remote presets immediately on click without saving them first
- [x] Save remote presets explicitly for offline use
- [x] Keep desktop History independently collapsible in the Library sidebar
- [x] Fit mobile editor images to the available screen width
- [x] Start each newly opened mobile image with a random preset
- [x] Add gesture-driven mobile preset discovery with previous/forward trail navigation
- [x] Track unique filters viewed and record every applied preset in editor History
- [x] Tap the mobile image for Save image / Save filter actions

## Mobile editor UI revamp

- [x] Establish image-first mobile editor scaffold with adaptive contain-fit presentation
- [x] Add mobile-only rounded image clipping and comfortable canvas margins
- [x] Add premium mobile top bar and four-tool bottom dock
- [x] Allow portrait previews to use device width behind floating bottom chrome
- [x] Add contextual tool-panel host
- [x] Redesign mobile preset browser
- [x] Add reusable precision ruler control
- [x] Redesign mobile adjustment workflow
- [x] Redesign crop presentation around the existing crop engine
- [x] Add dedicated composition guides mode
- [ ] Finish responsive, accessibility, motion, and interaction polish

## Settings backlog

- [ ] Add Settings feature
- [ ] Persist app preferences locally
- [ ] Add "Invert vertical mouse panning"
  - Current default: ON
  - Desktop only
  - Allow user to disable it
  - Must not affect EditorSession, History, presets, or exports
- [ ] Consider mouse-wheel zoom preference
- [ ] Consider editor grid preferences
- [ ] Consider default comparison mode

## Later editor features

- [ ] Curves
- [ ] HSL / Color Mixer
- [ ] Color grading
- [ ] Vignette
- [ ] Grain
- [ ] Clarity / texture-style controls
- [ ] Dehaze-style control

## Export

- [x] Define export formats and full-resolution output planning
  - [x] JPEG
  - [x] PNG
  - [x] WebP
  - [x] Original resolution
  - [x] Optional longest-edge limit
  - [x] Quality preference for JPEG / WebP
- [x] Full-resolution export renderer
- [ ] Ensure exported output matches editor preview
- [x] JPEG encoding
- [x] PNG encoding
- [x] WebP encoding
- [x] Save As / export destination flow
- [x] Export preferences UI

## Community

- [ ] Share presets
- [ ] Community preset library
- [ ] Share aspect ratios / templates
- [ ] Preset metadata
- [ ] Creator profiles
- [ ] Download / import community presets
