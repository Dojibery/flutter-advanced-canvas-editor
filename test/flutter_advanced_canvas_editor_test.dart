import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_advanced_canvas_editor/flutter_advanced_canvas_editor.dart';

void main() {
  group('CanvasController', () {
    test('creates a default layer on init', () {
      final controller = CanvasController((_) {});
      expect(controller.layers.length, 1);
      expect(controller.layers.first.name, 'Layer 1');
    });

    test('can skip default layer creation', () {
      final controller = CanvasController((_) {}, createDefaultLayer: false);
      expect(controller.layers, isEmpty);
    });

    test('export callback is stored and invocable', () {
      Uint8List? received;
      final controller = CanvasController((bytes) => received = bytes);
      controller.exportCanvasCallback(Uint8List.fromList([1, 2, 3]));
      expect(received, isNotNull);
      expect(received!.length, 3);
    });
  });

  group('CanvasLayer', () {
    test('default values are correct', () {
      final layer = CanvasLayer(id: 'id', name: 'Test');
      expect(layer.visible, isTrue);
      expect(layer.opacity, 1.0);
      expect(layer.locked, isFalse);
      expect(layer.components, isEmpty);
    });

    test('clone produces independent copy', () {
      final layer = CanvasLayer(id: 'id', name: 'Original');
      layer.components.add(const SizedBox());
      final clone = layer.clone();
      clone.components.clear();
      expect(layer.components.length, 1);
    });
  });
}
