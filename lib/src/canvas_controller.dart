import 'package:flutter/material.dart';

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

  List<Offset> get positions => List.unmodifiable(_positions);
  List<Widget> get components => List.unmodifiable(_components);
  List<Offset> get drawingPoints => List.unmodifiable(_drawingPoints);
  int get selectedIndex => _selectedIndex;
  bool get isDrawing => _isDrawing;
  bool get isErasing => _isErasing;

  late VoidCallback onStateChanged;

  CanvasController({required this.onStateChanged});

  void enableDrawing() {
    _isDrawing = true;
    _isErasing = false;
    onStateChanged();
  }

  void enableErasing() {
    _isDrawing = false;
    _isErasing = true;
    onStateChanged();
  }

  void disableDrawingErasing() {
    _isDrawing = false;
    _isErasing = false;
    onStateChanged();
  }

  void addDrawingPoint(Offset point) {
    _drawingPoints.add(point);
    onStateChanged();
  }

  void removeDrawingPoint(Offset point) {
    _drawingPoints.removeWhere((p) => (p - point).distance < 30);
    onStateChanged();
  }

  void addComponent(Widget component, Offset position) {
    _saveStateForUndo();
    _components.add(component);
    _positions.add(position);
    onStateChanged();
  }

  void updatePosition(int index, Offset position) {
    _saveStateForUndo();
    _positions[index] = position;
    onStateChanged();
  }

  void selectComponent(int index) {
    _selectedIndex = index;
    onStateChanged();
  }

  void deselectComponent() {
    _selectedIndex = -1;
    onStateChanged();
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
      onStateChanged();
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
      onStateChanged();
    }
  }

  void clearAll() {
    _saveStateForUndo();
    _components.clear();
    _positions.clear();
    _drawingPoints.clear();
    onStateChanged();
  }

  void _saveStateForUndo() {
    _undoPositions.add(List.from(_positions));
    _undoComponents.add(List.from(_components));
  }

  void _saveStateForRedo() {
    _redoPositions.add(List.from(_positions));
    _redoComponents.add(List.from(_components));
  }
}
