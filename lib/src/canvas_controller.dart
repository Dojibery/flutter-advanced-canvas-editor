import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'canvas_layer.dart';

/// Called when the canvas drawing/erasing mode changes.
///
/// [isDrawing] is `true` while drawing mode is active.
/// [isErasing] is `true` while erasing mode is active.
typedef CanvasStateCallback = void Function(bool isDrawing, bool isErasing);

/// Called after [CanvasController.exportCanvas] completes successfully.
///
/// [pngBytes] contains the raw PNG-encoded bytes of the exported canvas.
typedef CanvasExportCallback = void Function(Uint8List pngBytes);

/// Called after an undo operation is applied.
typedef UndoCallback = void Function();

/// Called after a redo operation is applied.
typedef RedoCallback = void Function();

/// Called when erasing mode is enabled via [CanvasController.enableErasing].
typedef EraseCallback = void Function();

/// Internal class for storing complete layer state snapshots for undo/redo
class _LayerSnapshot {
  final List<CanvasLayer> layers;
  final int currentLayerIndex;

  _LayerSnapshot({
    required this.layers,
    required this.currentLayerIndex,
  });

  /// Creates a deep copy of this snapshot
  _LayerSnapshot clone() {
    return _LayerSnapshot(
      layers: layers.map((layer) => layer.clone()).toList(),
      currentLayerIndex: currentLayerIndex,
    );
  }
}

/// Controls the state of a [CanvasWidget].
///
/// [CanvasController] manages all canvas content through a Photoshop-style
/// layer system. Each layer can contain freehand drawing points and draggable
/// widget components, and has independent visibility, opacity, and lock state.
///
/// ## Basic usage
///
/// ```dart
/// final controller = CanvasController(
///   (pngBytes) {
///     // Handle exported PNG bytes
///   },
/// );
/// ```
///
/// ## Layer management
///
/// ```dart
/// // Create a new layer
/// final layerId = controller.createLayer(name: 'Background');
///
/// // Switch the active layer
/// controller.setCurrentLayer(0);
///
/// // Adjust opacity
/// controller.setLayerOpacity(0, 0.5);
/// ```
///
/// ## Drawing
///
/// ```dart
/// controller.enableDrawing();  // enter draw mode
/// controller.enableErasing();  // enter erase mode
/// controller.disableDrawingErasing(); // exit both modes
/// ```
///
/// ## Undo / redo
///
/// ```dart
/// controller.undo();
/// controller.redo();
/// ```
class CanvasController {
  // Layer-based storage
  final List<CanvasLayer> _layers = [];
  int _currentLayerIndex = 0;
  int _nextLayerId = 1; // Auto-increment for unique IDs

  // Undo/redo as full snapshots
  final List<_LayerSnapshot> _undoHistory = [];
  final List<_LayerSnapshot> _redoHistory = [];

  // Selection now includes layer context
  int _selectedLayerIndex = -1;
  int _selectedComponentIndex = -1;

  // Mode flags (unchanged)
  bool _isDrawing = false;
  bool _isErasing = false;
  final GlobalKey _canvasKey = GlobalKey();

  // Backwards-compatible getters (return current layer's data)
  List<Widget> get components {
    if (_layers.isEmpty) return List.unmodifiable([]);
    return List.unmodifiable(_layers[_currentLayerIndex].components);
  }

  List<Offset> get positions {
    if (_layers.isEmpty) return List.unmodifiable([]);
    return List.unmodifiable(_layers[_currentLayerIndex].positions);
  }

  List<double> get rotations {
    if (_layers.isEmpty) return List.unmodifiable([]);
    return List.unmodifiable(_layers[_currentLayerIndex].rotations);
  }

  List<Offset> get drawingPoints {
    if (_layers.isEmpty) return List.unmodifiable([]);
    return List.unmodifiable(_layers[_currentLayerIndex].drawingPoints);
  }

  int get selectedIndex => _selectedComponentIndex; // Backwards compatible

  // New layer getters
  List<CanvasLayer> get layers => List.unmodifiable(_layers);
  int get currentLayerIndex => _currentLayerIndex;
  int get selectedLayerIndex => _selectedLayerIndex;
  CanvasLayer? get currentLayer {
    if (_layers.isEmpty) return null;
    return _layers[_currentLayerIndex];
  }

  // Unchanged getters
  bool get isDrawing => _isDrawing;
  bool get isErasing => _isErasing;
  GlobalKey get canvasKey => _canvasKey;

  CanvasStateCallback? onStateChanged;
  late CanvasExportCallback exportCanvasCallback;
  UndoCallback? onUndo;
  RedoCallback? onRedo;
  EraseCallback? onErase;

  CanvasController(
    this.exportCanvasCallback, {
    this.onUndo,
    this.onRedo,
    this.onErase,
    bool createDefaultLayer = true,
  }) {
    if (createDefaultLayer) {
      _layers.add(CanvasLayer(
        id: _generateLayerId(),
        name: 'Layer 1',
      ));
    }
  }

  /// Generates a unique layer ID
  String _generateLayerId() {
    return 'layer_${_nextLayerId++}';
  }

  void setOnStateChanged(CanvasStateCallback callback) {
    onStateChanged = callback;
  }

  void enableDrawing() {
    if (_layers.isNotEmpty && _layers[_currentLayerIndex].locked) {
      return;
    }
    _isDrawing = true;
    _isErasing = false;
    onStateChanged?.call(_isDrawing, _isErasing);
  }

  void enableErasing() {
    if (_layers.isNotEmpty && _layers[_currentLayerIndex].locked) {
      return;
    }
    _isDrawing = false;
    _isErasing = true;
    onStateChanged?.call(_isDrawing, _isErasing);
    onErase?.call();
  }

  void disableDrawingErasing() {
    _isDrawing = false;
    _isErasing = false;
    onStateChanged?.call(_isDrawing, _isErasing);
  }

  void addDrawingPoint(Offset point) {
    if (_layers.isEmpty) return;

    final layer = _layers[_currentLayerIndex];

    // Cannot draw on locked layers
    if (layer.locked) return;

    // No undo for individual drawing points (performance)
    layer.drawingPoints.add(point);
    onStateChanged?.call(_isDrawing, _isErasing);
  }

  void removeDrawingPoint(Offset point) {
    if (_layers.isEmpty) return;

    final layer = _layers[_currentLayerIndex];

    // Cannot erase from locked layers
    if (layer.locked) return;

    layer.drawingPoints.removeWhere((p) => (p - point).distance < 30);
    onStateChanged?.call(_isDrawing, _isErasing);
  }

  void addComponent(Widget component, Offset position, {int? targetLayerIndex}) {
    final layerIndex = targetLayerIndex ?? _currentLayerIndex;

    // Prevent adding to locked layers
    if (_layers[layerIndex].locked) {
      return;
    }

    _saveStateForUndo();
    _layers[layerIndex].components.add(component);
    _layers[layerIndex].positions.add(position);
    _layers[layerIndex].rotations.add(0.0);
    onStateChanged?.call(_isDrawing, _isErasing);
  }

  void updatePosition(int index, Offset position, {int? targetLayerIndex}) {
    final layerIndex = targetLayerIndex ?? _selectedLayerIndex;
    if (layerIndex < 0 || layerIndex >= _layers.length) return;

    final layer = _layers[layerIndex];

    // Prevent modifying locked layers
    if (layer.locked) return;

    // Bounds check
    if (index < 0 || index >= layer.positions.length) return;

    _saveStateForUndo();
    layer.positions[index] = position;
    onStateChanged?.call(_isDrawing, _isErasing);
  }

  void selectComponent(int layerIndex, int componentIndex) {
    // Cannot select from hidden or locked layers
    if (layerIndex < 0 || layerIndex >= _layers.length) return;

    final layer = _layers[layerIndex];
    if (!layer.visible || layer.locked) {
      return;
    }

    if (componentIndex < 0 || componentIndex >= layer.components.length) return;

    _selectedLayerIndex = layerIndex;
    _selectedComponentIndex = componentIndex;
    onStateChanged?.call(_isDrawing, _isErasing);
  }

  /// Backwards compatible wrapper for selectComponent
  void selectComponentByIndex(int index) {
    selectComponent(_currentLayerIndex, index);
  }

  void deselectComponent() {
    _selectedLayerIndex = -1;
    _selectedComponentIndex = -1;
    _isDrawing = false;
    _isErasing = false;
    onStateChanged?.call(_isDrawing, _isErasing);
  }

  void deleteComponent(int index, {int? targetLayerIndex}) {
    final layerIndex = targetLayerIndex ?? _selectedLayerIndex;
    if (layerIndex < 0 || layerIndex >= _layers.length) return;

    final layer = _layers[layerIndex];

    // Prevent deleting from locked layers
    if (layer.locked) return;

    if (index < 0 || index >= layer.components.length) return;

    _saveStateForUndo();
    layer.components.removeAt(index);
    layer.positions.removeAt(index);
    layer.rotations.removeAt(index);

    // Clear selection if deleted
    if (_selectedLayerIndex == layerIndex && _selectedComponentIndex == index) {
      deselectComponent();
    }

    onStateChanged?.call(_isDrawing, _isErasing);
  }

  void rotateComponent(int index, {int? targetLayerIndex}) {
    final layerIndex = targetLayerIndex ?? _selectedLayerIndex;
    if (layerIndex < 0 || layerIndex >= _layers.length) return;

    final layer = _layers[layerIndex];

    // Prevent rotating locked layer components
    if (layer.locked) return;

    if (index < 0 || index >= layer.rotations.length) return;

    _saveStateForUndo();
    layer.rotations[index] = (layer.rotations[index] + 45.0) % 360;
    onStateChanged?.call(_isDrawing, _isErasing);
  }

  void undo() {
    if (_undoHistory.isEmpty) return;

    // Save current state to redo
    _saveStateForRedo();

    // Restore previous state
    final snapshot = _undoHistory.removeLast();
    _layers
      ..clear()
      ..addAll(snapshot.layers.map((layer) => layer.clone()).toList());
    _currentLayerIndex = snapshot.currentLayerIndex;

    // Clear selection (component might not exist after undo)
    deselectComponent();

    onStateChanged?.call(_isDrawing, _isErasing);
    onUndo?.call();
  }

  void redo() {
    if (_redoHistory.isEmpty) return;

    // Save current state to undo (but DON'T clear redo - that's the bug!)
    final currentSnapshot = _LayerSnapshot(
      layers: _layers.map((layer) => layer.clone()).toList(),
      currentLayerIndex: _currentLayerIndex,
    );
    _undoHistory.add(currentSnapshot);

    // Limit undo history size
    if (_undoHistory.length > 50) {
      _undoHistory.removeAt(0);
    }

    // Restore next state from redo
    final snapshot = _redoHistory.removeLast();
    _layers
      ..clear()
      ..addAll(snapshot.layers.map((layer) => layer.clone()).toList());
    _currentLayerIndex = snapshot.currentLayerIndex;

    // Clear selection
    deselectComponent();

    onStateChanged?.call(_isDrawing, _isErasing);
    onRedo?.call();
  }

  void clearAll() {
    _saveStateForUndo();

    for (var layer in _layers) {
      if (!layer.locked) {
        layer.components.clear();
        layer.positions.clear();
        layer.rotations.clear();
        layer.drawingPoints.clear();
      }
    }

    deselectComponent();
    onStateChanged?.call(_isDrawing, _isErasing);
  }

  void _saveStateForUndo() {
    // Snapshot entire layer state
    final snapshot = _LayerSnapshot(
      layers: _layers.map((layer) => layer.clone()).toList(),
      currentLayerIndex: _currentLayerIndex,
    );

    _undoHistory.add(snapshot);

    // Clear redo history on new action
    _redoHistory.clear();

    // Optional: Limit undo history size (prevent memory issues)
    if (_undoHistory.length > 50) {
      _undoHistory.removeAt(0);
    }
  }

  void _saveStateForRedo() {
    final snapshot = _LayerSnapshot(
      layers: _layers.map((layer) => layer.clone()).toList(),
      currentLayerIndex: _currentLayerIndex,
    );

    _redoHistory.add(snapshot);
  }

  // ==================== Layer Management API ====================

  /// Creates a new layer and optionally makes it the current layer
  String createLayer({
    String? name,
    bool visible = true,
    double opacity = 1.0,
    bool locked = false,
    bool makeActive = true,
  }) {
    _saveStateForUndo();

    final layerId = _generateLayerId();
    final layerName = name ?? 'Layer ${_layers.length + 1}';

    final newLayer = CanvasLayer(
      id: layerId,
      name: layerName,
      visible: visible,
      opacity: opacity,
      locked: locked,
    );

    _layers.add(newLayer);

    if (makeActive) {
      _currentLayerIndex = _layers.length - 1;
    }

    onStateChanged?.call(_isDrawing, _isErasing);
    return layerId;
  }

  /// Deletes a layer by index
  void deleteLayer(int index) {
    if (index < 0 || index >= _layers.length) return;

    // Prevent deleting the last layer
    if (_layers.length == 1) {
      return;
    }

    _saveStateForUndo();
    _layers.removeAt(index);

    // Adjust current layer index
    if (_currentLayerIndex >= _layers.length) {
      _currentLayerIndex = _layers.length - 1;
    }

    // Clear selection if from deleted layer
    if (_selectedLayerIndex == index) {
      deselectComponent();
    } else if (_selectedLayerIndex > index) {
      _selectedLayerIndex--;
    }

    onStateChanged?.call(_isDrawing, _isErasing);
  }

  /// Deletes a layer by ID
  void deleteLayerById(String layerId) {
    final index = _layers.indexWhere((layer) => layer.id == layerId);
    if (index >= 0) {
      deleteLayer(index);
    }
  }

  /// Moves a layer from one index to another
  void reorderLayer(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _layers.length) return;
    if (newIndex < 0 || newIndex >= _layers.length) return;
    if (oldIndex == newIndex) return;

    _saveStateForUndo();

    final layer = _layers.removeAt(oldIndex);
    _layers.insert(newIndex, layer);

    // Update current layer index if affected
    if (_currentLayerIndex == oldIndex) {
      _currentLayerIndex = newIndex;
    } else if (oldIndex < _currentLayerIndex && newIndex >= _currentLayerIndex) {
      _currentLayerIndex--;
    } else if (oldIndex > _currentLayerIndex && newIndex <= _currentLayerIndex) {
      _currentLayerIndex++;
    }

    // Update selection layer index if affected
    if (_selectedLayerIndex == oldIndex) {
      _selectedLayerIndex = newIndex;
    } else if (oldIndex < _selectedLayerIndex && newIndex >= _selectedLayerIndex) {
      _selectedLayerIndex--;
    } else if (oldIndex > _selectedLayerIndex && newIndex <= _selectedLayerIndex) {
      _selectedLayerIndex++;
    }

    onStateChanged?.call(_isDrawing, _isErasing);
  }

  /// Moves a layer up in the stack (increases z-index)
  void moveLayerUp(int index) {
    if (index < _layers.length - 1) {
      reorderLayer(index, index + 1);
    }
  }

  /// Moves a layer down in the stack (decreases z-index)
  void moveLayerDown(int index) {
    if (index > 0) {
      reorderLayer(index, index - 1);
    }
  }

  /// Renames a layer
  void renameLayer(int index, String newName) {
    if (index < 0 || index >= _layers.length) return;

    _saveStateForUndo();
    _layers[index].name = newName;
    onStateChanged?.call(_isDrawing, _isErasing);
  }

  /// Sets layer visibility
  void setLayerVisibility(int index, bool visible) {
    if (index < 0 || index >= _layers.length) return;

    _saveStateForUndo();
    _layers[index].visible = visible;

    // Deselect if hiding the selected layer
    if (!visible && _selectedLayerIndex == index) {
      deselectComponent();
    }

    onStateChanged?.call(_isDrawing, _isErasing);
  }

  /// Sets layer opacity (0.0 to 1.0)
  void setLayerOpacity(int index, double opacity) {
    if (index < 0 || index >= _layers.length) return;

    final clampedOpacity = opacity.clamp(0.0, 1.0);

    _saveStateForUndo();
    _layers[index].opacity = clampedOpacity;
    onStateChanged?.call(_isDrawing, _isErasing);
  }

  /// Sets layer locked state
  void setLayerLocked(int index, bool locked) {
    if (index < 0 || index >= _layers.length) return;

    _saveStateForUndo();
    _layers[index].locked = locked;

    // Deselect if locking the selected layer
    if (locked && _selectedLayerIndex == index) {
      deselectComponent();
    }

    onStateChanged?.call(_isDrawing, _isErasing);
  }

  /// Sets the active/current layer
  void setCurrentLayer(int index) {
    if (index < 0 || index >= _layers.length) return;

    _currentLayerIndex = index;
    onStateChanged?.call(_isDrawing, _isErasing);
  }

  /// Duplicates a layer with all its contents
  String duplicateLayer(int index, {String? newName}) {
    if (index < 0 || index >= _layers.length) return '';

    _saveStateForUndo();

    final sourceLayer = _layers[index];
    final layerId = _generateLayerId();
    final layerName = newName ?? '${sourceLayer.name} Copy';

    final duplicatedLayer = CanvasLayer(
      id: layerId,
      name: layerName,
      components: List.from(sourceLayer.components),
      positions: List.from(sourceLayer.positions),
      rotations: List.from(sourceLayer.rotations),
      drawingPoints: List.from(sourceLayer.drawingPoints),
      visible: sourceLayer.visible,
      opacity: sourceLayer.opacity,
      locked: false, // Unlocked by default
    );

    _layers.insert(index + 1, duplicatedLayer);

    onStateChanged?.call(_isDrawing, _isErasing);
    return layerId;
  }

  /// Merges a layer down (combines with layer below)
  void mergeLayerDown(int index) {
    if (index <= 0 || index >= _layers.length) return;

    _saveStateForUndo();

    final topLayer = _layers[index];
    final bottomLayer = _layers[index - 1];

    // Combine contents into bottom layer
    bottomLayer.components.addAll(topLayer.components);
    bottomLayer.positions.addAll(topLayer.positions);
    bottomLayer.rotations.addAll(topLayer.rotations);
    bottomLayer.drawingPoints.addAll(topLayer.drawingPoints);

    // Remove top layer
    _layers.removeAt(index);

    // Update indices
    if (_currentLayerIndex == index) {
      _currentLayerIndex = index - 1;
    } else if (_currentLayerIndex > index) {
      _currentLayerIndex--;
    }

    if (_selectedLayerIndex == index) {
      deselectComponent();
    } else if (_selectedLayerIndex > index) {
      _selectedLayerIndex--;
    }

    onStateChanged?.call(_isDrawing, _isErasing);
  }

  /// Clears all content from a layer
  void clearLayer(int index) {
    if (index < 0 || index >= _layers.length) return;

    final layer = _layers[index];
    if (layer.locked) return;

    _saveStateForUndo();
    layer.components.clear();
    layer.positions.clear();
    layer.rotations.clear();
    layer.drawingPoints.clear();

    if (_selectedLayerIndex == index) {
      deselectComponent();
    }

    onStateChanged?.call(_isDrawing, _isErasing);
  }

  // ==================== Export ====================

  /// Scales every component's position across all layers by [scaleX] and [scaleY].
  ///
  /// Useful when the canvas widget is resized and component positions need to
  /// be remapped to the new coordinate space. For example, if the canvas grows
  /// from 400×300 to 800×600, call `scaleAllPositions(2.0, 2.0)`.
  ///
  /// Hidden and locked layers are included — positions are geometry, not content.
  void scaleAllPositions(double scaleX, double scaleY) {
    for (final layer in _layers) {
      for (int i = 0; i < layer.positions.length; i++) {
        layer.positions[i] = Offset(
          layer.positions[i].dx * scaleX,
          layer.positions[i].dy * scaleY,
        );
      }
    }
    onStateChanged?.call(_isDrawing, _isErasing);
  }

  Future<void> exportCanvas() async {
    // first deselect all items because the picture will contains unnecessary thinks such as rotator, delete icon etc...
    deselectComponent();
    try {
      RenderRepaintBoundary boundary = _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage();
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      exportCanvasCallback(pngBytes);
    } catch (e) {
      debugPrint('Error exporting canvas: $e');
    }
  }
}
