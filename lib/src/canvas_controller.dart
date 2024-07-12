import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

typedef CanvasStateCallback = void Function(bool isDrawing, bool isErasing);
typedef CanvasExportCallback = void Function(Uint8List pngBytes);

class CanvasController {
  final List<Offset> _positions = [];
  final List<Widget> _components = [];
  final List<List<Offset>> _undoPositions = [];
  final List<List<Widget>> _undoComponents = [];
  final List<List<Offset>> _redoPositions = [];
  final List<List<Widget>> _redoComponents = [];
  final List<Offset> _drawingPoints = [];
  int _selectedIndex = -1;
  bool _isDrawing = false;
  bool _isErasing = false;
  final List<double> _rotations = []; // To keep track of the rotations of each component
  final GlobalKey _canvasKey = GlobalKey();

  List<Offset> get positions => List.unmodifiable(_positions);
  List<Widget> get components => List.unmodifiable(_components);
  List<Offset> get drawingPoints => List.unmodifiable(_drawingPoints);
  int get selectedIndex => _selectedIndex;
  bool get isDrawing => _isDrawing;
  bool get isErasing => _isErasing;
  List<double> get rotations => List.unmodifiable(_rotations);
  GlobalKey get canvasKey => _canvasKey;

  late CanvasStateCallback onStateChanged;
  late CanvasExportCallback exportCanvasCallback;

  CanvasController(this.exportCanvasCallback);

  void setOnStateChanged(CanvasStateCallback callback) {
    onStateChanged = callback;
  }

  void enableDrawing() {
    _isDrawing = true;
    _isErasing = false;
    onStateChanged(_isDrawing, _isErasing);
  }

  void enableErasing() {
    _isDrawing = false;
    _isErasing = true;
    onStateChanged(_isDrawing, _isErasing);
  }

  void disableDrawingErasing() {
    _isDrawing = false;
    _isErasing = false;
    onStateChanged(_isDrawing, _isErasing);
  }

  void addDrawingPoint(Offset point) {
    _drawingPoints.add(point);
    onStateChanged(_isDrawing, _isErasing);
  }

  void removeDrawingPoint(Offset point) {
    _drawingPoints.removeWhere((p) => (p - point).distance < 30);
    onStateChanged(_isDrawing, _isErasing);
  }

  void addComponent(Widget component, Offset position) {
    _saveStateForUndo();
    _components.add(component);
    _positions.add(position);
    _rotations.add(0.0);
    onStateChanged(_isDrawing, _isErasing);
  }

  void updatePosition(int index, Offset position) {
    _saveStateForUndo();
    _positions[index] = position;
    onStateChanged(_isDrawing, _isErasing);
  }

  void selectComponent(int index) {
    _selectedIndex = index;
    onStateChanged(_isDrawing, _isErasing);
  }

  void deselectComponent() {
    _selectedIndex = -1;
    _isDrawing = false;
    _isErasing = false;
    onStateChanged(_isDrawing, _isErasing);
  }

  void deleteComponent(int index) {
    _saveStateForUndo();
    _components.removeAt(index);
    _positions.removeAt(index);
    _rotations.removeAt(index);
    onStateChanged(_isDrawing, _isErasing);
  }

  void rotateComponent(int index) {
    _saveStateForUndo();
    _rotations[index] = (_rotations[index] + 45.0) % 360;
    onStateChanged(_isDrawing, _isErasing);
  }

  void undo() {
    if (_undoPositions.isNotEmpty && _undoComponents.isNotEmpty) {
      _saveStateForRedo();
      _positions
        ..clear()
        ..addAll(_undoPositions.removeLast());
      _components
        ..clear()
        ..addAll(_undoComponents.removeLast());
      onStateChanged(_isDrawing, _isErasing);
    }
  }

  void redo() {
    if (_redoPositions.isNotEmpty && _redoComponents.isNotEmpty) {
      _saveStateForUndo();
      _positions
        ..clear()
        ..addAll(_redoPositions.removeLast());
      _components
        ..clear()
        ..addAll(_redoComponents.removeLast());
      onStateChanged(_isDrawing, _isErasing);
    }
  }

  void clearAll() {
    _saveStateForUndo();
    _components.clear();
    _positions.clear();
    _drawingPoints.clear();
    onStateChanged(_isDrawing, _isErasing);
  }

  void _saveStateForUndo() {
    _undoPositions.add(List.from(_positions));
    _undoComponents.add(List.from(_components));
  }

  void _saveStateForRedo() {
    _redoPositions.add(List.from(_positions));
    _redoComponents.add(List.from(_components));
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
      print('Error exporting canvas: $e');
    }
  }
}
