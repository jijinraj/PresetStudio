# PresetStudio Roadmap

> Living development checklist.
> Update this file as features are completed, changed, removed, deferred, or reprioritized.
>
> PresetStudio is a local-first, non-destructive photo editor focused on
> customizable editing, portable presets, and community sharing across
> desktop and mobile.

## Current milestone - Advanced Editing / Preset Engine v2

### Vignette

- [x] Add configurable Vignette effect
  - [x] Add Vignette Amount
  - [x] Add Vignette Feather
  - [x] Integrate vignette state with ImageAdjustments
  - [x] Include vignette in editor state equality
  - [x] Integrate vignette with History replay
  - [x] Preserve History enable / disable reconstruction
  - [x] Add GPU live-preview rendering
  - [x] Add CPU full-resolution export rendering
  - [x] Account for image aspect ratio in vignette falloff
  - [x] Add desktop controls
  - [x] Add mobile controls
  - [x] Add portable `.presetstudio` serialization
  - [x] Add preset adjustment mapping
  - [x] Preserve backwards compatibility with existing Presets v1 files
  - [x] Add adjustment-model coverage
  - [x] Add export-rendering coverage
  - [x] Add preset-mapper coverage
  - [x] Add preset-codec coverage

### Tone Curves

- [ ] Define structured Tone Curve domain model
  - [ ] Define normalized curve control points
  - [ ] Keep curve state separate from scalar AdjustmentType values
  - [ ] Define neutral / identity curve
  - [ ] Define curve sanitization and validation
  - [ ] Define curve interpolation behavior
- [ ] Add master / RGB curve
- [ ] Add interactive curve editor
  - [ ] Add control-point creation
  - [ ] Add control-point movement
  - [ ] Add control-point deletion
  - [ ] Prevent invalid point ordering
  - [ ] Add curve reset
- [ ] Integrate Tone Curves with EditorSession
- [ ] Integrate Tone Curve edits with History
  - [ ] Group continuous curve interaction into semantic History entries
  - [ ] Support Undo / Redo
  - [ ] Support History enable / disable
  - [ ] Support History reconstruction
- [ ] Add GPU live-preview rendering
- [ ] Add CPU full-resolution export rendering
- [ ] Maintain preview / export parity
- [ ] Add portable `.presetstudio` serialization
- [ ] Preserve backwards compatibility with presets without curve data
- [ ] Add desktop Tone Curve UI
- [ ] Add mobile Tone Curve UI
- [ ] Add model and interaction tests
- [ ] Add History regression coverage
- [ ] Add preset round-trip coverage
- [ ] Add export-rendering coverage

### HSL / Color Mixer

- [ ] Define HSL / Color Mixer domain state
- [ ] Add per-color Hue controls
- [ ] Add per-color Saturation controls
- [ ] Add per-color Luminance controls
- [ ] Add GPU preview rendering
- [ ] Add CPU full-resolution export rendering
- [ ] Add portable preset serialization
- [ ] Add desktop UI
- [ ] Add mobile UI
- [ ] Add regression coverage

### Color Grading

- [ ] Define Color Grading domain state
- [ ] Add Shadows color control
- [ ] Add Midtones color control
- [ ] Add Highlights color control
- [ ] Add Balance control
- [ ] Add GPU preview rendering
- [ ] Add CPU full-resolution export rendering
- [ ] Add portable preset serialization
- [ ] Add desktop UI
- [ ] Add mobile UI
- [ ] Add regression coverage

### Grain

- [ ] Add Grain Amount
- [ ] Add Grain Size
- [ ] Add Grain Roughness
- [ ] Add GPU preview rendering
- [ ] Add CPU full-resolution export rendering
- [ ] Maintain deterministic / appropriate export behavior
- [ ] Add portable preset serialization
- [ ] Add desktop controls
- [ ] Add mobile controls
- [ ] Add regression coverage

### Additional advanced adjustments

- [ ] Clarity / texture-style controls
- [ ] Dehaze-style control
- [ ] Detail / sharpening

---

## Editor foundation

- [x] Image import
- [x] Non-destructive editor session
- [x] Exposure
- [x] Contrast
- [x] Saturation
- [x] Highlights
- [x] Shadows
- [x] Whites
- [x] Blacks
- [x] Temperature
- [x] Tint
- [x] Vibrance
- [x] GPU tonal shader
- [x] Rotation
- [x] Horizontal flip
- [x] Vertical flip
- [x] History
- [x] Undo / Redo
- [x] Reset adjustments
- [x] Hold Before / After
- [x] Desktop + mobile zoom
- [x] Viewport pan
- [x] Fix adjustment-slider mouse-wheel propagation
- [x] Preserve intentional inverse vertical mouse panning on desktop

---

## Comparison workflow

- [x] Add hold Before / After
- [x] Move mobile Before / After beside Change Image
- [x] Keep desktop hold Before / After in toolbar
- [x] Add desktop side-by-side Before / After
- [x] Synchronize zoom / pan between Before and After
- [x] Preserve crop and transform geometry during Before / After comparison
- [x] Compare tonal / editing state without removing committed geometry

---

## History v2

- [x] Make desktop History collapsible
- [x] Coalesce mouse-wheel adjustment changes into one meaningful History entry
- [x] Coalesce continuous keyboard adjustment changes
- [x] Keep slider / ruler drags grouped as one History entry
- [x] Suppress no-op transactions that finish at their starting state
- [x] Store replayable before / after state for History operations
- [x] Add non-destructive enable / disable toggles for individual edits
- [x] Rebuild the current image from enabled History operations
- [x] Keep Undo / Redo chronological while edits are disabled
- [x] Add Enable all edits
- [x] Add safe Clear history
- [x] Add semantic / logical History groups for compound actions
- [x] Support crop operations through semantic History transactions
- [x] Support preset application as a semantic History operation
- [x] Preserve History reconstruction for Vignette
- [ ] Design permanent operation delete / rebase semantics separately from enable / disable

---

## Crop & geometry

### Crop model

- [x] Add non-destructive crop model
  - [x] Normalized crop rectangle
  - [x] Constrained aspect-ratio state
  - [x] Fine straighten state
  - [x] Crop scale
  - [x] Normalized image offset
  - [x] History replay / enable-disable support

### Crop interaction

- [x] Add interactive crop viewport
- [x] Add constrained crop resize handles
- [x] Add image repositioning inside crop
- [x] Add image zoom with desktop wheel
- [x] Add image zoom with mobile pinch
- [x] Clamp crop pan so the frame never exposes empty pixels
- [x] Add Tilt / Straighten
- [x] Keep crop frame stable while straightening
- [x] Guarantee image coverage for portrait / landscape ratio changes
- [x] Auto-scale coverage for ordinary rotation + straighten
- [x] Add crop grid while interacting
- [x] Group crop gestures into single History transactions

### Crop ratios

- [x] Original
- [x] 1:1
- [x] 4:5
- [x] 3:4
- [x] 2:3
- [x] 3:2
- [x] 16:9
- [x] 9:16
- [x] Swap fixed ratios between portrait and landscape orientation

### Crop presentation

- [x] Render committed crop composition in normal desktop preview
- [x] Render committed crop composition in normal mobile preview
- [x] Keep committed crop visible in Before / After
- [x] Keep committed crop visible in desktop side-by-side comparison
- [x] Use focused desktop crop mode with read-only surrounding UI
- [x] Speed up desktop crop panning while preserving inverse vertical motion
- [x] Remove misaligned ghost background from crop workspace
- [x] Redesign mobile crop presentation around the existing crop engine
- [x] Add precision-ruler straighten interaction on mobile
- [x] Add immersive mobile straighten interaction
- [x] Preserve exact crop state when Cancel is used
- [x] Record one semantic crop History operation when Apply is used
- [ ] Continue desktop crop presentation polish

> Free Crop is not part of the current PresetStudio crop model or roadmap.
> The supported workflow uses constrained crop geometry and defined aspect ratios.

---

## Composition guides

- [x] Keep composition-guide state presentation-only
- [x] Keep composition guides outside EditorSession edit state
- [x] Keep composition guides outside CropState
- [x] Keep composition guides outside History
- [x] Keep composition guides outside presets
- [x] Keep composition guides outside exports
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
- [x] Share guide presentation state between normal mobile editor and crop workspace
- [x] Add dedicated mobile composition-guides mode

---

## Presets v1

### Portable preset format

- [x] Define versioned preset schema
- [x] Use `.presetstudio` as the portable preset file format
- [x] Define portable preset metadata
- [x] Define adjustment mapping
- [x] Keep portable presets adjustment-focused
- [x] Keep crop geometry out of portable presets
- [x] Keep rotation out of portable presets
- [x] Keep straighten out of portable presets
- [x] Keep pan / zoom out of portable presets
- [x] Keep composition guides out of portable presets
- [x] Reserve reusable geometry / layout state for future templates
- [x] Import portable `.presetstudio` presets
- [x] Export portable `.presetstudio` presets
- [x] Preserve backwards-compatible schema decoding
- [x] Extend Presets v1 with Vignette Amount and Feather without breaking older presets

### Local preset library

- [x] Save current adjustments as preset
- [x] Apply preset
- [x] Apply presets without modifying crop / geometry
- [x] Record preset application as one semantic History operation
- [x] Rename preset
- [x] Delete preset
- [x] Local / offline preset library

### Remote preset sources

- [x] Define multi-source remote preset registry
- [x] Keep preset files independent from a specific Git hosting provider
- [x] Persist preset source registry
- [x] Add repository-backed catalog provider
- [x] Add generic catalog URL provider
- [x] Add / remove / enable multiple repository or catalog URLs
- [x] Cache remote catalogs for offline use
- [x] Cache installed presets for offline use
- [x] Add optional remote preset preview metadata
- [x] Add local preview cache
- [x] Add remote preset descriptions
- [x] Add remote preset tags
- [x] Render Discover presets against the currently edited image when available
- [x] Apply remote presets immediately without saving them first
- [x] Save remote presets explicitly for offline use

### Desktop preset experience

- [x] Move desktop presets from the Library sidebar into a collapsible bottom tray
- [x] Keep desktop History independently collapsible in the Library sidebar

### Mobile preset experience

- [x] Fit mobile editor images to the available screen width
- [x] Start each newly opened mobile image with a random real preset
- [x] Add gesture-driven preset discovery
- [x] Swipe left to move forward to a new / unseen preset
- [x] Swipe right to return through the visited preset trail
- [x] Track unique filters viewed
- [x] Record every applied preset in editor History
- [x] Tap the mobile image for Save Image / Save Filter actions
- [x] Add mobile-native preset browser
- [x] Add live-preview preset cards
- [x] Add Original option
- [x] Add selected preset state
- [x] Add explicit Save controls
- [x] Add saved / update states
- [x] Derive categories from real preset metadata
- [x] Preserve access to preset management

---

## Mobile editor UI revamp v1

- [x] Establish image-first mobile editor scaffold
- [x] Add adaptive contain-fit image presentation
- [x] Add mobile-only rounded image clipping
- [x] Add comfortable canvas margins
- [x] Use near-black image-first workspace presentation
- [x] Add premium mobile top bar
- [x] Add four-tool bottom dock
  - [x] Presets
  - [x] Adjust
  - [x] Crop
  - [x] Guides
- [x] Allow portrait previews to use device width behind floating bottom chrome
- [x] Add contextual tool-panel host
- [x] Redesign mobile preset browser
- [x] Add reusable precision ruler control
- [x] Redesign mobile adjustment workflow
- [x] Add horizontally scrollable adjustment selector
- [x] Show one focused adjustment at a time
- [x] Add immersive adjustment-ruler interaction
- [x] Redesign mobile crop workflow
- [x] Add dedicated composition-guides mode
- [x] Finish responsive mobile polish
- [x] Support compact-phone layouts
- [x] Support increased text scale
- [x] Maintain accessible touch targets
- [x] Polish mobile spacing, radii, selected states, and disabled states
- [x] Preserve desktop workflows during the mobile redesign
- [x] Preserve editor, crop, preset, History, and rendering behavior throughout the revamp

---

## Precision controls

- [x] Add reusable camera-style precision ruler
- [x] Add stationary center indicator
- [x] Add horizontally moving tick scale
- [x] Add major / minor ticks
- [x] Add numeric labels
- [x] Support configurable ranges
- [x] Support configurable precision
- [x] Clamp values
- [x] Add double-tap reset
- [x] Add accessibility increment / decrement semantics
- [x] Add optional haptic checkpoints
- [x] Keep ruler independent from editor domain state
- [x] Reuse ruler for mobile adjustments
- [x] Reuse ruler for crop straightening

---

## Export

### Export pipeline

- [x] Define full-resolution export architecture
- [x] Add full-resolution export renderer
- [x] Keep original source image untouched
- [x] Apply non-destructive editor state during export

### Formats

- [x] JPEG
- [x] PNG
- [x] WebP

### Output settings

- [x] Original resolution
- [x] Optional longest-edge limit
- [x] JPEG quality preference
- [x] WebP quality preference
- [x] Save As / export destination flow
- [x] Export preferences UI

### Rendering parity

- [x] Add CPU export implementation for existing tonal adjustments
- [x] Add CPU export implementation for Vignette
- [ ] Verify complete preview / export parity across every supported adjustment
- [ ] Expand automated preview / export parity regression coverage

---

## Settings backlog

- [ ] Add Settings feature
- [ ] Persist application preferences locally

### Desktop interaction preferences

- [ ] Add "Invert vertical mouse panning"
  - Current default: ON
  - Desktop only
  - Allow user to disable it
  - Must not affect EditorSession, History, presets, or exports

- [ ] Consider mouse-wheel zoom preference
- [ ] Consider editor grid preferences
- [ ] Consider default comparison mode

---

## Community

### Preset sharing

- [ ] Share presets directly from PresetStudio
- [ ] Community preset library
- [ ] Download / import community presets
- [ ] Community preset discovery
- [ ] Preset metadata improvements
- [ ] Creator profiles
- [ ] Ratings / popularity signals
- [ ] Community moderation / reporting model

### Shareable editor resources

- [ ] Share custom aspect ratios
- [ ] Define templates
- [ ] Share templates
- [ ] Define which geometry / layout state belongs in templates
- [ ] Keep templates separate from portable adjustment presets

---

## Future editor architecture

### Selective editing

- [ ] Local / selective adjustments
- [ ] Masks
- [ ] Brush-based edits
- [ ] Linear gradient masks
- [ ] Radial masks
- [ ] Investigate locally feasible subject / sky-assisted masks

### Reusable editing resources

- [ ] User-defined aspect ratios
- [ ] Shareable aspect-ratio definitions
- [ ] Templates for reusable geometry / layout state

### History

- [ ] Permanent History operation delete / rebase semantics

### Additional editor capabilities

- [ ] Additional advanced effects
- [ ] Continue professional desktop editor UX refinement

---

## Project quality & architecture

- [x] Bootstrap Flutter application
- [x] Establish PresetStudio application architecture
- [x] Establish centralized design system
- [x] Establish responsive desktop / mobile editor shell
- [x] Establish automated test baseline
- [x] Establish GitHub Actions CI baseline
- [x] Maintain non-destructive editing
- [x] Maintain local-first editing
- [x] Keep source images untouched
- [x] Keep editor state mutations centralized
- [x] Keep composition guides presentation-only
- [x] Keep portable presets separate from crop / transform geometry
- [x] Keep desktop and mobile presentation capable of sharing editor domain state
- [x] Maintain semantic History transactions for compound interactions
- [x] Maintain backwards-compatible portable preset decoding
- [ ] Continue expanding regression coverage with every advanced editing feature

---

## Development principles

- Keep editing non-destructive.
- Keep source images untouched.
- Prefer local-first functionality.
- Keep portable presets focused on reusable visual adjustments.
- Keep geometry and layout concepts separate from portable adjustment presets.
- Keep presentation-only state out of EditorSession and History.
- Preserve desktop behavior when implementing mobile-specific UX.
- Preserve mobile behavior when implementing desktop-specific UX.
- Reuse domain state and rendering infrastructure instead of duplicating editor logic in UI widgets.
- Treat History operations as semantic user actions rather than raw state changes.
- Keep GPU preview and CPU export implementations aligned.
- Maintain backwards compatibility for existing `.presetstudio` files whenever practical.
- Build community sharing around portable, understandable formats rather than application-internal state.
- Add advanced editing capabilities incrementally and validate each one before moving to the next.
