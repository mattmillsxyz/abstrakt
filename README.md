# abstrakt

A minimal, modern, procedural 3D art tool for macOS built with SwiftUI and SceneKit.

![macOS 14.6+](https://img.shields.io/badge/macOS-14.6%2B-blue)
![Swift 5.0](https://img.shields.io/badge/Swift-5.0-orange)
![SceneKit](https://img.shields.io/badge/Renderer-SceneKit-green)
![No Dependencies](https://img.shields.io/badge/Dependencies-None-lightgrey)

---

## Overview

abstrakt is a local-first creative tool focused on speed, visual clarity, and non-destructive workflows. Add 3D primitive shapes, stack procedural modifiers, adjust lighting and materials, toggle between fixed cameras, and export high-resolution images. No setup, accounts, or cloud required.

---

## Features

- **Primitive shapes:** Box, Sphere, Cylinder, Plane
- **Non-destructive modifier stack:** Array, Radial Array, Noise Offset, Scale Gradient, Rotation Offset
- **Presets:** Staircase, Circle Burst, Organic Scatter, Spiral
- **Material system:** Color picker + Plastic, Metal, Glass, Matte presets
- **Lighting:** Up to 3 configurable lights (directional or omni) with position presets
- **Fixed cameras:** Isometric (perspective) and Orthographic, toggled from the toolbar
- **Aspect ratio overlay:** Yellow frame for 7 export ratios (1:1, 4:5, 16:9, 9:16, 5:4, 3:4, 4:3)
- **Export:** JPG (with background) or PNG (transparent) at 1x, 2x, or 4x resolution
- **Immediate feedback:** Every change rebuilds only the affected object's node tree in real time

---

## Requirements

| Requirement | Version |
|---|---|
| macOS | 14.6 Sonoma or later |
| Xcode | 16.1 or later |
| Swift | 5.0 |
| Third-party libraries | None |

---

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/yourname/abstrakt.git
   cd abstrakt
   ```

2. Open the Xcode project:
   ```bash
   open abstrakt.xcodeproj
   ```

3. Select the **abstrakt** scheme and **My Mac** destination.

4. Press **⌘R** to build and run.

No package dependencies to resolve. No signing configuration required for local development (the app uses automatic signing with the App Sandbox enabled).

---

## Project Structure

```
abstrakt/
├── Models/
│   ├── Models.swift           # Core data types: SceneObject, Instance, Transform,
│   │                          #   MaterialConfig, GeometryType, CameraMode,
│   │                          #   AspectRatioMode, LightConfig, ExportFormat
│   └── Modifier.swift         # Modifier, ModifierType, ModifierParameters,
│                              #   and all parameter structs (ArrayParams, etc.)
│
├── Engine/
│   └── ModifierEngine.swift   # Pure functional pipeline: apply(object:) -> [Instance]
│                              #   Seeded LCG PRNG for deterministic noise
│
├── ViewModels/
│   ├── AppState.swift         # ObservableObject, single source of truth for all UI state
│   └── SceneController.swift  # Owns SCNScene; handles node building, geometry cache,
│                              #   camera, lighting, hit testing, and selection highlight
│
├── Views/
│   ├── SceneViewContainer.swift  # NSViewRepresentable wrapping SCNView
│   ├── Components.swift          # Shared UI components (FloatRow, Vec3Rows, SectionHeader...)
│   ├── TopToolbar.swift          # Shape buttons, camera toggle, aspect ratio, presets, export
│   ├── SidebarView.swift         # Floating left panel container
│   ├── TransformSection.swift    # Position (0.5 snap) and Rotation (15 deg snap) sliders
│   ├── MaterialSection.swift     # ColorPicker + material preset picker
│   ├── ModifierSection.swift     # Full modifier stack UI with collapsible parameter panels
│   ├── LightingSection.swift     # Light configuration (always visible)
│   └── AspectRatioOverlay.swift  # Yellow border + letterbox via even-odd Path fill
│
├── Utils/
│   ├── Presets.swift          # Four built-in modifier stack presets
│   └── ExportManager.swift    # SCNRenderer off-screen render, center-crop, NSSavePanel
│
├── ContentView.swift          # Root layout: ZStack canvas + overlays + onChange wiring
├── abstraktApp.swift          # App entry point, 1440x900 default window
└── abstrakt.entitlements      # App Sandbox + user-selected read-write for export
```

---

## Architecture

### Data Flow

```
User action (sidebar / toolbar)
       |
  AppState mutation (@Published)
       |
  onChange(of:) in ContentView
       |
  SceneController.sync(with:)
       |
  ModifierEngine.apply(object:) -> [Instance]
       |
  SCNNode subtree rebuilt for changed object only
       |
  SceneKit renders the updated scene
```

### Key Design Decisions

#### Non-destructive modifier stack

Each `SceneObject` carries an ordered `[Modifier]` array. The `ModifierEngine` treats this as a pure functional pipeline: it starts from a single identity `Instance` and threads it through each enabled modifier in order. The base object is never mutated; only the generated `SCNNode` children are updated.

#### Transform composition

The object's base transform (`position`, `rotation`) is applied to the root `SCNNode`. Each child node carries the transform produced by the modifier pipeline. This means:

- Moving the object moves the entire procedural structure
- Modifiers only control internal layout relative to the object origin

#### Geometry reuse

`SceneController` maintains a `Dictionary<GeometryType, SCNGeometry>` cache. Source geometry is created once per type. For each `SceneObject`, the source geometry is copied once (giving that object its own material), then all child nodes under that object share the same geometry reference. This keeps memory usage and draw calls low even at high instance counts.

#### Selection highlight without shared material mutation

When an object is selected, its geometry's material is **cloned** and the clone receives an emission color. All child nodes under that object switch to the cloned geometry. When deselected, the original shared geometry is restored. Other objects and their materials are never touched.

#### Deterministic noise

The Noise Offset modifier uses a Knuth MMIX linear congruential generator seeded with `objectSeed XOR modifierSeed`. Given the same seed and parameters, the noise output is always identical, regardless of insertion order or other scene state. This makes procedural results reproducible.

---

## Usage Guide

### Adding objects

Click the shape buttons in the top toolbar (cube, sphere, cylinder, or plane icon). Objects are added at the scene origin. The new object is automatically selected.

### Selecting objects

Click any object in the 3D viewport. The selected object is highlighted in yellow. Click empty space to deselect.

### Transform controls

With an object selected, use the **Transform** section in the left sidebar:

- **Position:** sliders snapped to 0.5 unit increments, range -20 to 20
- **Rotation:** sliders snapped to 15 deg increments, range -180 deg to 180 deg

### Materials

With an object selected, use the **Material** section:

- Click the color swatch to open the system color picker
- Choose a material preset: Plastic, Metal, Glass, or Matte

| Preset | Lighting Model | Notes |
|---|---|---|
| Plastic | Phong | Moderate specular |
| Metal | Physically Based | High metalness, low roughness |
| Glass | Phong | 35% transparency, double-sided |
| Matte | Lambert | No specular |

### Modifier stack

With an object selected, use the **Modifiers** section. Click **+ Add Modifier** to choose a modifier type. Each modifier appears as a collapsible row with:

- **Enable/disable toggle** (checkbox icon)
- **Reorder** (up/down chevron buttons)
- **Delete** (x button)
- **Parameter controls** (expand by clicking the chevron)

#### Modifier types

| Modifier | Parameters | Effect |
|---|---|---|
| **Array** | Count, Offset (x/y/z), Relative | Duplicates instances in a line |
| **Radial Array** | Count, Radius, Axis (X/Y/Z), Total Angle | Arranges instances in a circle or arc |
| **Noise Offset** | Amplitude (x/y/z), Seed | Displaces instances with deterministic noise |
| **Scale Gradient** | Start Scale, End Scale | Interpolates size across instances |
| **Rotation Offset** | Rotation/Step (x/y/z) | Adds cumulative rotation across instances |

Modifier order matters. Use the chevron buttons to reorder. Every change updates the viewport immediately with no Apply button.

### Presets

Click the **Presets** menu in the toolbar (requires an object to be selected) to apply a pre-built modifier stack:

| Preset | Modifiers |
|---|---|
| Staircase | Array(10, offset 1.2/1.2/0) + Rotation Offset(0, 10 deg, 0) |
| Circle Burst | Radial Array(12, radius 3, Y axis, 360 deg) |
| Organic Scatter | Array(20) + Noise Offset(seed 42) + Scale Gradient(1.0 to 0.3) |
| Spiral | Radial Array(24, radius 2.5, 720 deg) + Scale Gradient + Rotation Offset(15 deg, 0, 0) |

Applying a preset replaces all existing modifiers on the selected object. You can continue editing the stack after applying.

### Randomize seed

Click the **dice** icon in the object header (sidebar) to generate a new random seed for the selected object. This changes the output of any Noise Offset modifiers using that object's seed.

### Lighting

The **Lighting** section is always visible at the bottom of the sidebar (regardless of selection). Up to 3 lights can be configured:

- **Type:** Directional or Omni
- **Color:** system color picker
- **Intensity:** 0 to 3000 lux
- **Position preset:** Front, Back, Top, Bottom, Left, Right
- **Enable/disable** toggle

Click **Add Light** to add a second or third light. The first light cannot be removed (minimum 1).

### Background color

Click the color swatch in the toolbar (between the presets and export controls) to change the scene background. Default is black.

### Camera modes

Toggle between two fixed cameras using the **Iso / Ortho** segmented control in the toolbar:

| Mode | Projection | Description |
|---|---|---|
| **Iso** | Perspective | 45 deg yaw, -35 deg pitch; classic isometric view |
| **Ortho** | Orthographic | Straight-on front view |

The camera is fixed and cannot be panned, rotated, or zoomed by the user.

### Aspect ratio overlay

Use the **ratio picker** in the toolbar to show a yellow overlay frame indicating the export region:

| Ratio | Use case |
|---|---|
| 1:1 | Instagram square |
| 4:5 | Instagram portrait |
| 16:9 | Landscape / YouTube |
| 9:16 | Stories / Reels |
| 5:4 | Medium format |
| 3:4 | Portrait |
| 4:3 | Classic |

The letterboxed area outside the frame will be cropped from the export.

### Exporting

Click **Export** in the toolbar. A dropdown lets you configure:

- **Format:** JPG (with background color) or PNG (transparent background)
- **Resolution:** 1x, 2x, or 4x the current viewport size

Then click **Export...** to open the save panel and choose a destination.

The export is center-cropped to the selected aspect ratio, matching exactly what the yellow overlay shows in the viewport.

---

## Modifier Pipeline - Technical Reference

The engine applies modifiers as a pure transformation pipeline:

```
[Identity Instance]
        |
  Modifier 1 (e.g. Array x 10)          -> [10 instances]
        |
  Modifier 2 (e.g. Noise Offset)         -> [10 displaced instances]
        |
  Modifier 3 (e.g. Scale Gradient)       -> [10 scaled instances]
        |
  [Final Instance list] capped at 1000
        |
  SCNNode children (each sharing base geometry)
```

Each modifier receives the full `[Instance]` array from the previous step and returns a new array. Disabled modifiers are skipped. The pipeline is rebuilt from scratch any time the object changes.

**Instance** carries:
- `position: SIMD3<Float>` applied to `SCNNode.position`
- `rotation: SIMD3<Float>` in degrees, applied to `SCNNode.eulerAngles`
- `scale: SIMD3<Float>` applied to `SCNNode.scale`

---

## Performance Notes

- Instance cap of **1,000** per object is enforced after each modifier step
- Source geometry is created once per `GeometryType` and cached in `SceneController`
- Each `SceneObject` gets one geometry copy (for per-object materials), shared by all its child nodes
- Only the changed object's subtree is rebuilt on each sync; other objects are untouched
- Selection highlighting swaps geometry references (pointer ops) rather than re-uploading to the GPU

---

## Known Limitations

- No persistence; scenes are not saved between sessions
- No undo/redo
- No object duplication or grouping
- Camera is fixed; no orbit/pan/zoom
- Export renders from the scene's camera node; the output matches the viewport camera exactly

---

## License

MIT License. See `LICENSE` for details.
