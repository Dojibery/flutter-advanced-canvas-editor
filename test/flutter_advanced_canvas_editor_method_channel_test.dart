import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_advanced_canvas_editor/flutter_advanced_canvas_editor.dart';

void main() {
  group('CanvasController layer operations', () {
    test('createLayer returns a unique ID', () {
      final controller = CanvasController((_) {});
      final id1 = controller.createLayer(name: 'A');
      final id2 = controller.createLayer(name: 'B');
      expect(id1, isNotEmpty);
      expect(id2, isNotEmpty);
      expect(id1, isNot(equals(id2)));
    });

    test('deleteLayer removes the layer', () {
      final controller = CanvasController((_) {});
      controller.createLayer(name: 'Extra');
      expect(controller.layers.length, 2);
      controller.deleteLayer(1);
      expect(controller.layers.length, 1);
    });

    test('cannot delete the last layer', () {
      final controller = CanvasController((_) {});
      controller.deleteLayer(0);
      expect(controller.layers.length, 1);
    });

    test('setLayerVisibility hides and shows a layer', () {
      final controller = CanvasController((_) {});
      controller.setLayerVisibility(0, false);
      expect(controller.layers[0].visible, isFalse);
      controller.setLayerVisibility(0, true);
      expect(controller.layers[0].visible, isTrue);
    });

    test('setLayerOpacity clamps to 0.0–1.0', () {
      final controller = CanvasController((_) {});
      controller.setLayerOpacity(0, 1.5);
      expect(controller.layers[0].opacity, 1.0);
      controller.setLayerOpacity(0, -0.5);
      expect(controller.layers[0].opacity, 0.0);
    });

    test('drawing mode toggles correctly', () {
      final controller = CanvasController((_) {});
      controller.enableDrawing();
      expect(controller.isDrawing, isTrue);
      expect(controller.isErasing, isFalse);
      controller.enableErasing();
      expect(controller.isDrawing, isFalse);
      expect(controller.isErasing, isTrue);
      controller.disableDrawingErasing();
      expect(controller.isDrawing, isFalse);
      expect(controller.isErasing, isFalse);
    });
  });
}
