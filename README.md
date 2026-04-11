## Flutter Advanced Canvas Editor

A Flutter package for creating, editing, and exporting canvas-based artwork with advanced features.

## Preview

<img src="https://raw.githubusercontent.com/Dojibery/flutter-advanced-canvas-editor/master/assets/images/preview-layers.png" width=400px height=500px>

## Features

* **Photoshop-style layer system** — create, delete, duplicate, rename, and reorder layers
* Per-layer visibility, opacity, and lock controls
* Freehand drawing and erasing
* Drag-and-drop widget components onto the canvas
* Global undo / redo (snapshot-based, covers all layers)
* Export the canvas as a PNG image
* Works on all platforms (Android, iOS, Web, macOS, Windows, Linux)

## Installation

```yaml
dependencies:
  flutter_advanced_canvas_editor: ^2.0.3
```

## Quick start

```dart
import 'package:flutter_advanced_canvas_editor/flutter_advanced_canvas_editor.dart';

// 1. Create a controller
final controller = CanvasController(
  (pngBytes) => savePng(pngBytes), // called on exportCanvas()
);

// 2. Listen to state changes and rebuild your UI
controller.setOnStateChanged((isDrawing, isErasing) => setState(() {}));

// 3. Drop CanvasWidget into your widget tree
CanvasWidget(controller: controller)
```

For a complete working example with a layer panel, draggable items, and action buttons see the [example tab](example/lib/main.dart).

## Core API

| Method | Description |
|---|---|
| `enableDrawing()` / `enableErasing()` | Enter draw / erase mode |
| `disableDrawingErasing()` | Exit both modes |
| `undo()` / `redo()` | Step through history |
| `clearAll()` | Clear all unlocked layers |
| `exportCanvas()` | Export to PNG (fires the export callback) |
| `createLayer({name, opacity, locked})` | Add a new layer, returns its ID |
| `deleteLayer(index)` | Remove a layer |
| `setCurrentLayer(index)` | Switch the active layer |
| `setLayerVisibility(index, bool)` | Show / hide a layer |
| `setLayerOpacity(index, double)` | Set layer opacity (0.0 – 1.0) |
| `setLayerLocked(index, bool)` | Lock / unlock a layer |
| `duplicateLayer(index)` | Duplicate a layer |
| `mergeLayerDown(index)` | Merge a layer into the one below |
| `addComponent(widget, offset)` | Place a widget on the canvas |
| `scaleAllPositions(scaleX, scaleY)` | Rescale every component's position across all layers (e.g. after canvas resize) |

## Contributing

Contributions are welcome! Feel free to open issues and pull requests.

## License

MIT — see the [LICENSE](https://github.com/Dojibery/flutter-advanced-canvas-editor/blob/master/LICENSE) file for details.
