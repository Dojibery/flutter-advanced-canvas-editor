## Flutter Advanced Canvas Editor

A Flutter package for creating, editing, and exporting canvas-based artwork with advanced features.

## Preview

<img src="https://raw.githubusercontent.com/Dojibery/flutter-advanced-canvas-editor/master/assets/images/preview-layers.png" width=400px height=500px>

## Features

* **Photoshop-style layer system** — create, delete, duplicate, rename, and reorder layers
* Per-layer visibility, opacity, and lock controls
* Freehand drawing and erasing
* Drag-and-drop widget components onto the canvas
* Per-component icon colour for the rotate / delete action buttons
* Global undo / redo (snapshot-based, covers all layers)
* Canvas serialisation — save to JSON and restore later, including component positions and asset paths
* Export the canvas as a PNG image
* Works on all platforms (Android, iOS, Web, macOS, Windows, Linux)

## Installation

```yaml
dependencies:
  flutter_advanced_canvas_editor: 
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

### Drawing

| Method | Description |
|---|---|
| `enableDrawing()` | Enter freehand draw mode |
| `enableErasing()` | Enter erase mode |
| `disableDrawingErasing()` | Exit both modes |
| `undo()` / `redo()` | Step through snapshot history |
| `clearAll()` | Clear all unlocked layers |
| `exportCanvas()` | Capture canvas as PNG and fire the export callback |

### Components

| Method | Description |
|---|---|
| `addComponent(widget, offset, {iconColor, assetPath})` | Place a widget on the active layer |
| `scaleAllPositions(scaleX, scaleY)` | Rescale every component's position (e.g. after canvas resize) |

Use `CanvasComponentData` as `Draggable` data to carry an optional `iconColor` and `assetPath` alongside the widget:

```dart
Draggable<CanvasComponentData>(
  data: CanvasComponentData(
    widget: SvgPicture.asset('assets/car.svg'),
    iconColor: Colors.blue,
    assetPath: 'assets/car.svg', // needed for serialisation
  ),
  feedback: ...,
  child: ...,
)
```

### Layer management

| Method | Description |
|---|---|
| `createLayer({name, opacity, locked})` | Add a new layer, returns its ID |
| `deleteLayer(index)` | Remove a layer |
| `setCurrentLayer(index)` | Switch the active layer |
| `setLayerVisibility(index, bool)` | Show / hide a layer |
| `setLayerOpacity(index, double)` | Set layer opacity (0.0 – 1.0) |
| `setLayerLocked(index, bool)` | Lock / unlock a layer |
| `duplicateLayer(index)` | Duplicate a layer |
| `mergeLayerDown(index)` | Merge a layer into the one below |

### Serialisation

Save the full canvas state to JSON and restore it later — including all component positions, rotations, drawing points, and asset paths.

```dart
// Save
final json = controller.toJson(); // Map<String, dynamic>
final encoded = jsonEncode(json);
await prefs.setString('canvas', encoded);

// Restore
final json = jsonDecode(await prefs.getString('canvas')!) as Map<String, dynamic>;
controller.loadFromJson(json, (path) => SvgPicture.asset(path));
```

`loadFromJson` calls the `widgetBuilder` closure for every stored `assetPath` to reconstruct each component widget. Undo/redo history is cleared on restore.

Use `controller.hasContent` to check whether the canvas has any components or drawing points before deciding whether to show a restore prompt.

## Contributing

Contributions are welcome! Feel free to open issues and pull requests.

## License

MIT — see the [LICENSE](https://github.com/Dojibery/flutter-advanced-canvas-editor/blob/master/LICENSE) file for details.
