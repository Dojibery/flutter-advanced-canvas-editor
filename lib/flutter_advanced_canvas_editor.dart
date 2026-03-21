/// A powerful Flutter canvas editor with Photoshop-style layers,
/// freehand drawing, drag-and-drop components, undo/redo, and PNG export.
///
/// ## Getting started
///
/// Create a [CanvasController] and pass it to [CanvasWidget]:
///
/// ```dart
/// final controller = CanvasController(
///   (pngBytes) => print('Exported ${pngBytes.length} bytes'),
/// );
///
/// // In your widget tree:
/// CanvasWidget(controller: controller)
/// ```
///
/// See the [CanvasController] documentation for the full API.
library flutter_advanced_canvas_editor;

export 'src/canvas_controller.dart';
export 'src/canvas.dart';
export 'src/canvas_layer.dart';
