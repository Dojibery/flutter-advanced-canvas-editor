## 2.0.3

- Converted from Flutter plugin to pure Flutter package — now supports all platforms (Android, iOS, Web, macOS, Windows, Linux) without native code dependencies
- Removed `plugin_platform_interface` dependency and deleted unused plugin boilerplate files
- Fixed deprecated `Color.withOpacity()` → `Color.fromRGBO()` in painter
- Replaced `print()` with `debugPrint()` in `exportCanvas` error handler
- Added class-level dartdoc to `CanvasController`, `CanvasWidget`, and all public typedefs
- Fixed `prefer_const_constructors` lint in canvas widget (`Size` constructor)
- Suppressed `library_private_types_in_public_api` on `createState()` with inline ignore comment
- Added library-level doc comment to the main barrel file
- Filled in `homepage` field in pubspec.yaml
- Improved pubspec `description` to better reflect all features
- Rewrote README to show only a minimal quick-start snippet and API table; full example remains in `example/lib/main.dart`
- Replaced outdated plugin boilerplate tests with real unit tests covering `CanvasController` and `CanvasLayer` (64 tests total, all passing)

## 2.0.2

CHANGELOG:
- **MAJOR FEATURE**: Added Photoshop-style layer system with full backwards compatibility
  - Multiple named layers for organizing canvas content
  - Create, delete, duplicate, rename, and reorder layers
  - Per-layer drawing points and components
  - Layer visibility toggle (show/hide)
  - Layer opacity control (0-100%)
  - Lock layers to prevent editing
  - Merge layer down functionality
  - Clear individual layers
  - Global undo/redo that snapshots all layers together
  - Hidden/locked layers cannot be selected
  - New layer management API: `createLayer()`, `deleteLayer()`, `renameLayer()`, `setLayerVisibility()`, `setLayerOpacity()`, `setLayerLocked()`, `reorderLayer()`, `duplicateLayer()`, `mergeLayerDown()`, `clearLayer()`
  - Demo includes collapsible layer navbar with horizontal scrolling layer cards
  - Image Preview
- Made `onStateChanged` callback nullable for easier testing
- Removed redundant debug logs throughout codebase
- Added comprehensive test suite (53 tests) covering all layer functionality

## 1.1.6

CHANGELOG:
- Undo Calls onUndo?.call() when undo is triggered
- Redo Calls onRedo?.call() when redo is triggered
- Erase Calls onErase?.call() when erasing mode is enabled

* TODO: export in different formats and colors
