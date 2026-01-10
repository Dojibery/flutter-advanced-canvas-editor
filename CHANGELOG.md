## 2.0.0

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
- Made `onStateChanged` callback nullable for easier testing
- Removed redundant debug logs throughout codebase
- Added comprehensive test suite (53 tests) covering all layer functionality

## 1.1.6

CHANGELOG:
- Undo Calls onUndo?.call() when undo is triggered
- Redo Calls onRedo?.call() when redo is triggered
- Erase Calls onErase?.call() when erasing mode is enabled

* TODO: export in different formats and colors
