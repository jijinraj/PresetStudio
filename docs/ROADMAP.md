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

## Immediate UX work

- [ ] Invert vertical mouse panning on desktop
- [ ] Move mobile Before / After beside Change Image
- [ ] Keep desktop hold Before / After in toolbar
- [ ] Add desktop side-by-side Before / After
- [ ] Synchronize zoom / pan between Before and After
- [ ] Make desktop History collapsible

## Crop & geometry

- [ ] Add non-destructive crop model
- [ ] Add interactive crop viewport
- [ ] Add free crop
- [ ] Add resize handles
- [ ] Add image repositioning inside crop
- [ ] Add Tilt / Straighten
- [ ] Keep crop frame stable while straightening
- [ ] Add crop grid while interacting
- [ ] Add aspect ratios
  - [ ] Original
  - [ ] Free
  - [ ] 1:1
  - [ ] 4:5
  - [ ] 3:4
  - [ ] 2:3
  - [ ] 3:2
  - [ ] 16:9
  - [ ] 9:16
- [ ] Group crop gestures into single History transactions
- [ ] Improve crop UI toward Adobe-style workflow

## Color controls

- [ ] Temperature
- [ ] Tint
- [ ] Vibrance
- [ ] Finish Color panel UX

## Presets v1

- [ ] Define versioned preset JSON schema
- [ ] Save current adjustments as preset
- [ ] Apply preset
- [ ] Rename preset
- [ ] Delete preset
- [ ] Local preset library
- [ ] Import preset JSON
- [ ] Export preset JSON
- [ ] Decide whether geometry can optionally be included in presets

## Settings backlog

- [ ] Add Settings feature
- [ ] Persist app preferences locally
- [ ] Add "Invert vertical mouse panning"
  - Default: ON
  - Desktop only
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

- [ ] Full-resolution export renderer
- [ ] Ensure exported output matches editor preview
- [ ] JPEG export
- [ ] PNG export
- [ ] Export quality settings
- [ ] Export destination preferences

## Community

- [ ] Share presets
- [ ] Community preset library
- [ ] Share aspect ratios / templates
- [ ] Preset metadata
- [ ] Creator profiles
- [ ] Download / import community presets
