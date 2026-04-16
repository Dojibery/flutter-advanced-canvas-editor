import 'package:flutter/material.dart';

/// Represents a single layer in the canvas with all its contents and properties.
///
/// Each layer can contain multiple components (widgets), drawing points, and has
/// properties like visibility, opacity, and lock state. This enables a Photoshop-style
/// layer system where content can be organized, reordered, and controlled independently.
class CanvasLayer {
  /// Unique identifier for this layer
  final String id;

  /// Display name of the layer
  String name;

  /// Components (widgets) in this layer
  final List<Widget> components;

  /// Positions for each component (parallel to [components])
  final List<Offset> positions;

  /// Rotation angles for each component in degrees (parallel to [components])
  final List<double> rotations;

  /// Per-component colour used for the action icon buttons (rotate / delete)
  /// shown when a component is selected. `null` means "use the canvas default".
  /// Parallel to [components].
  final List<Color?> iconColors;

  /// Asset paths for each component (parallel to [components]).
  /// Stores the Flutter asset path (e.g. 'assets/images/carA.svg') so the
  /// layer state can be serialised and restored across widget remounts.
  /// `null` for components that were not created from an asset path.
  final List<String?> assetPaths;

  /// Freehand drawing points in this layer
  final List<Offset> drawingPoints;

  /// Whether this layer is visible (affects rendering and export)
  bool visible;

  /// Opacity of this layer (0.0 = fully transparent, 1.0 = fully opaque)
  double opacity;

  /// Whether this layer is locked (prevents editing when true)
  bool locked;

  CanvasLayer({
    required this.id,
    required this.name,
    List<Widget>? components,
    List<Offset>? positions,
    List<double>? rotations,
    List<Color?>? iconColors,
    List<String?>? assetPaths,
    List<Offset>? drawingPoints,
    this.visible = true,
    this.opacity = 1.0,
    this.locked = false,
  })  : components = components ?? [],
        positions = positions ?? [],
        rotations = rotations ?? [],
        iconColors = iconColors ?? [],
        assetPaths = assetPaths ?? [],
        drawingPoints = drawingPoints ?? [];

  /// Creates a copy of this layer with optional property overrides.
  ///
  /// This performs a shallow copy of the lists. For a full deep copy suitable
  /// for undo/redo, use [clone] instead.
  CanvasLayer copyWith({
    String? id,
    String? name,
    List<Widget>? components,
    List<Offset>? positions,
    List<double>? rotations,
    List<Color?>? iconColors,
    List<String?>? assetPaths,
    List<Offset>? drawingPoints,
    bool? visible,
    double? opacity,
    bool? locked,
  }) {
    return CanvasLayer(
      id: id ?? this.id,
      name: name ?? this.name,
      components: components != null ? List.from(components) : List.from(this.components),
      positions: positions != null ? List.from(positions) : List.from(this.positions),
      rotations: rotations != null ? List.from(rotations) : List.from(this.rotations),
      iconColors: iconColors != null ? List.from(iconColors) : List.from(this.iconColors),
      assetPaths: assetPaths != null ? List.from(assetPaths) : List.from(this.assetPaths),
      drawingPoints: drawingPoints != null ? List.from(drawingPoints) : List.from(this.drawingPoints),
      visible: visible ?? this.visible,
      opacity: opacity ?? this.opacity,
      locked: locked ?? this.locked,
    );
  }

  /// Creates a full deep copy of this layer.
  ///
  /// This is used for undo/redo history to ensure modifications to the layer
  /// don't affect saved history states. Note that Widget objects themselves
  /// are shared references (not cloned), which is acceptable since they are
  /// typically immutable.
  CanvasLayer clone() {
    return copyWith();
  }
}
