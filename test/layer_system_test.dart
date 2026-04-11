import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_advanced_canvas_editor/src/canvas_controller.dart';
import 'package:flutter_advanced_canvas_editor/src/canvas_layer.dart';

void main() {
  group('Layer System Tests', () {
    late CanvasController controller;

    setUp(() {
      controller = CanvasController((bytes) {
        // Export callback
      });
    });

    group('Basic Layer Operations', () {
      test('Controller initializes with default layer', () {
        expect(controller.layers.length, 1);
        expect(controller.layers[0].name, 'Layer 1');
        expect(controller.layers[0].visible, true);
        expect(controller.layers[0].opacity, 1.0);
        expect(controller.layers[0].locked, false);
        expect(controller.currentLayerIndex, 0);
      });

      test('Create new layer', () {
        final layerId = controller.createLayer(name: 'Test Layer');

        expect(controller.layers.length, 2);
        expect(controller.layers[1].name, 'Test Layer');
        expect(controller.layers[1].id, layerId);
        expect(controller.currentLayerIndex, 1); // Should be active
      });

      test('Create layer without making it active', () {
        controller.createLayer(name: 'Layer 2', makeActive: false);

        expect(controller.layers.length, 2);
        expect(controller.currentLayerIndex, 0); // Should stay on first layer
      });

      test('Auto-generate layer names', () {
        controller.createLayer(); // Should be "Layer 2"
        controller.createLayer(); // Should be "Layer 3"

        expect(controller.layers[1].name, 'Layer 2');
        expect(controller.layers[2].name, 'Layer 3');
      });

      test('Delete layer', () {
        controller.createLayer(name: 'Layer 2');
        controller.createLayer(name: 'Layer 3');

        expect(controller.layers.length, 3);

        controller.deleteLayer(1);

        expect(controller.layers.length, 2);
        expect(controller.layers[0].name, 'Layer 1');
        expect(controller.layers[1].name, 'Layer 3');
      });

      test('Cannot delete last layer', () {
        expect(controller.layers.length, 1);

        controller.deleteLayer(0);

        expect(controller.layers.length, 1); // Should still have the layer
      });

      test('Delete layer by ID', () {
        final id = controller.createLayer(name: 'To Delete');
        expect(controller.layers.length, 2);

        controller.deleteLayerById(id);

        expect(controller.layers.length, 1);
      });
    });

    group('Layer Reordering', () {
      setUp(() {
        controller.createLayer(name: 'Layer 2');
        controller.createLayer(name: 'Layer 3');
        // Now we have: Layer 1, Layer 2, Layer 3
      });

      test('Reorder layers', () {
        controller.reorderLayer(0, 2); // Move Layer 1 to position 2

        expect(controller.layers[0].name, 'Layer 2');
        expect(controller.layers[1].name, 'Layer 3');
        expect(controller.layers[2].name, 'Layer 1');
      });

      test('Move layer up', () {
        controller.moveLayerUp(0); // Move Layer 1 up (from 0 to 1)

        expect(controller.layers[0].name, 'Layer 2');
        expect(controller.layers[1].name, 'Layer 1');
        expect(controller.layers[2].name, 'Layer 3');
      });

      test('Move layer down', () {
        controller.moveLayerDown(2); // Move Layer 3 down (from 2 to 1)

        expect(controller.layers[0].name, 'Layer 1');
        expect(controller.layers[1].name, 'Layer 3');
        expect(controller.layers[2].name, 'Layer 2');
      });

      test('Current layer index updates after reorder', () {
        controller.setCurrentLayer(1); // Select Layer 2
        expect(controller.currentLayerIndex, 1);

        controller.reorderLayer(1, 0); // Move Layer 2 to position 0

        expect(controller.currentLayerIndex, 0); // Should follow the layer
      });
    });

    group('Layer Properties', () {
      test('Rename layer', () {
        controller.renameLayer(0, 'New Name');

        expect(controller.layers[0].name, 'New Name');
      });

      test('Set layer visibility', () {
        controller.setLayerVisibility(0, false);

        expect(controller.layers[0].visible, false);
      });

      test('Set layer opacity', () {
        controller.setLayerOpacity(0, 0.5);

        expect(controller.layers[0].opacity, 0.5);
      });

      test('Opacity is clamped between 0 and 1', () {
        controller.setLayerOpacity(0, 1.5);
        expect(controller.layers[0].opacity, 1.0);

        controller.setLayerOpacity(0, -0.5);
        expect(controller.layers[0].opacity, 0.0);
      });

      test('Set layer locked', () {
        controller.setLayerLocked(0, true);

        expect(controller.layers[0].locked, true);
      });

      test('Set current layer', () {
        controller.createLayer(name: 'Layer 2');
        controller.setCurrentLayer(1);

        expect(controller.currentLayerIndex, 1);
      });
    });

    group('Component Operations on Layers', () {
      test('Add component to current layer', () {
        final widget = Container();
        final offset = Offset(10, 20);

        controller.addComponent(widget, offset);

        expect(controller.components.length, 1);
        expect(controller.layers[0].components.length, 1);
        expect(controller.positions[0], offset);
        expect(controller.rotations[0], 0.0);
      });

      test('Add component to specific layer', () {
        controller.createLayer(name: 'Layer 2');
        final widget = Container();

        controller.addComponent(widget, Offset(5, 5), targetLayerIndex: 0);

        expect(controller.layers[0].components.length, 1);
        expect(controller.layers[1].components.length, 0);
      });

      test('Cannot add component to locked layer', () {
        controller.setLayerLocked(0, true);
        final widget = Container();

        controller.addComponent(widget, Offset(0, 0));

        expect(controller.components.length, 0); // Should not be added
      });

      test('Delete component from layer', () {
        controller.addComponent(Container(), Offset(0, 0));
        controller.addComponent(Container(), Offset(10, 10));

        expect(controller.components.length, 2);

        controller.deleteComponent(0, targetLayerIndex: 0);

        expect(controller.components.length, 1);
      });

      test('Cannot delete from locked layer', () {
        controller.addComponent(Container(), Offset(0, 0));
        controller.setLayerLocked(0, true);

        controller.deleteComponent(0, targetLayerIndex: 0);

        expect(controller.components.length, 1); // Should not be deleted
      });

      test('Rotate component', () {
        controller.addComponent(Container(), Offset(0, 0));

        controller.rotateComponent(0, targetLayerIndex: 0);

        expect(controller.rotations[0], 45.0);

        controller.rotateComponent(0, targetLayerIndex: 0);

        expect(controller.rotations[0], 90.0);
      });

      test('Cannot rotate on locked layer', () {
        controller.addComponent(Container(), Offset(0, 0));
        controller.setLayerLocked(0, true);

        controller.rotateComponent(0, targetLayerIndex: 0);

        expect(controller.rotations[0], 0.0); // Should not rotate
      });
    });

    group('Selection with Layers', () {
      setUp(() {
        controller.createLayer(name: 'Layer 2');
        controller.addComponent(Container(), Offset(0, 0), targetLayerIndex: 0);
        controller.addComponent(Container(), Offset(10, 10), targetLayerIndex: 1);
      });

      test('Select component on specific layer', () {
        controller.selectComponent(0, 0);

        expect(controller.selectedLayerIndex, 0);
        expect(controller.selectedIndex, 0);
      });

      test('Cannot select from hidden layer', () {
        controller.setLayerVisibility(0, false);

        controller.selectComponent(0, 0);

        expect(controller.selectedLayerIndex, -1); // Should not be selected
      });

      test('Cannot select from locked layer', () {
        controller.setLayerLocked(0, true);

        controller.selectComponent(0, 0);

        expect(controller.selectedLayerIndex, -1); // Should not be selected
      });

      test('Deselect component', () {
        controller.selectComponent(0, 0);
        expect(controller.selectedLayerIndex, 0);

        controller.deselectComponent();

        expect(controller.selectedLayerIndex, -1);
        expect(controller.selectedIndex, -1);
      });
    });

    group('Drawing Points on Layers', () {
      test('Add drawing point to current layer', () {
        controller.addDrawingPoint(Offset(5, 5));
        controller.addDrawingPoint(Offset(10, 10));

        expect(controller.drawingPoints.length, 2);
        expect(controller.layers[0].drawingPoints.length, 2);
      });

      test('Cannot draw on locked layer', () {
        controller.setLayerLocked(0, true);

        controller.addDrawingPoint(Offset(5, 5));

        expect(controller.drawingPoints.length, 0); // Should not be added
      });

      test('Remove drawing point', () {
        controller.addDrawingPoint(Offset(5, 5));
        controller.addDrawingPoint(Offset(50, 50)); // Far away

        controller.removeDrawingPoint(Offset(7, 7)); // Within 30 pixel radius of (5,5) only

        expect(controller.drawingPoints.length, 1);
        expect(controller.drawingPoints[0], Offset(50, 50)); // (5,5) was removed
      });

      test('Cannot erase from locked layer', () {
        controller.addDrawingPoint(Offset(5, 5));
        controller.setLayerLocked(0, true);

        controller.removeDrawingPoint(Offset(5, 5));

        expect(controller.drawingPoints.length, 1); // Should not be erased
      });

      test('Drawing points are per-layer', () {
        controller.createLayer(name: 'Layer 2');
        controller.setCurrentLayer(0);
        controller.addDrawingPoint(Offset(5, 5));

        controller.setCurrentLayer(1);
        controller.addDrawingPoint(Offset(10, 10));

        expect(controller.layers[0].drawingPoints.length, 1);
        expect(controller.layers[1].drawingPoints.length, 1);
      });
    });

    group('Undo/Redo with Layers', () {
      test('Undo layer creation', () {
        controller.createLayer(name: 'Layer 2');
        expect(controller.layers.length, 2);

        controller.undo();

        expect(controller.layers.length, 1);
      });

      test('Redo layer creation', () {
        controller.createLayer(name: 'Layer 2');
        controller.undo();
        expect(controller.layers.length, 1);

        controller.redo();

        expect(controller.layers.length, 2);
        expect(controller.layers[1].name, 'Layer 2');
      });

      test('Undo component addition', () {
        controller.addComponent(Container(), Offset(0, 0));
        expect(controller.components.length, 1);

        controller.undo();

        expect(controller.components.length, 0);
      });

      test('Undo restores current layer index', () {
        controller.createLayer(name: 'Layer 2');
        expect(controller.currentLayerIndex, 1); // New layer is active
        expect(controller.layers.length, 2);

        controller.undo(); // Undo layer creation

        expect(controller.layers.length, 1); // Layer 2 removed
        expect(controller.currentLayerIndex, 0); // Should restore to 0
      });

      test('Undo layer property changes', () {
        controller.setLayerOpacity(0, 0.5);
        expect(controller.layers[0].opacity, 0.5);

        controller.undo();

        expect(controller.layers[0].opacity, 1.0);
      });
    });

    group('Advanced Layer Operations', () {
      test('Duplicate layer', () {
        controller.addComponent(Container(), Offset(5, 5));
        controller.addDrawingPoint(Offset(10, 10));

        final newId = controller.duplicateLayer(0);

        expect(controller.layers.length, 2);
        expect(controller.layers[1].name, 'Layer 1 Copy');
        expect(controller.layers[1].components.length, 1);
        expect(controller.layers[1].drawingPoints.length, 1);
        expect(controller.layers[1].id, newId);
        expect(controller.layers[1].locked, false); // Should be unlocked
      });

      test('Duplicate layer with custom name', () {
        final newId = controller.duplicateLayer(0, newName: 'My Copy');

        expect(controller.layers[1].name, 'My Copy');
      });

      test('Merge layer down', () {
        controller.addComponent(Container(), Offset(0, 0)); // Layer 1
        controller.createLayer(name: 'Layer 2');
        controller.addComponent(Container(), Offset(10, 10)); // Layer 2

        expect(controller.layers.length, 2);
        expect(controller.layers[0].components.length, 1);
        expect(controller.layers[1].components.length, 1);

        controller.mergeLayerDown(1); // Merge Layer 2 into Layer 1

        expect(controller.layers.length, 1);
        expect(controller.layers[0].components.length, 2); // Should have both components
      });

      test('Cannot merge bottom layer', () {
        controller.createLayer(name: 'Layer 2');

        controller.mergeLayerDown(0); // Try to merge bottom layer

        expect(controller.layers.length, 2); // Should not merge
      });

      test('Clear layer', () {
        controller.addComponent(Container(), Offset(0, 0));
        controller.addDrawingPoint(Offset(5, 5));

        controller.clearLayer(0);

        expect(controller.components.length, 0);
        expect(controller.drawingPoints.length, 0);
      });

      test('Cannot clear locked layer', () {
        controller.addComponent(Container(), Offset(0, 0));
        controller.setLayerLocked(0, true);

        controller.clearLayer(0);

        expect(controller.components.length, 1); // Should not be cleared
      });

      test('ClearAll respects locked layers', () {
        controller.addComponent(Container(), Offset(0, 0));
        controller.setLayerLocked(0, true);

        controller.createLayer(name: 'Layer 2');
        controller.addComponent(Container(), Offset(10, 10));

        controller.clearAll();

        expect(controller.layers[0].components.length, 1); // Locked, not cleared
        expect(controller.layers[1].components.length, 0); // Unlocked, cleared
      });
    });

    group('Backwards Compatibility', () {
      test('Old API: components getter returns current layer', () {
        controller.createLayer(name: 'Layer 2');
        controller.addComponent(Container(), Offset(0, 0), targetLayerIndex: 0);
        controller.addComponent(Container(), Offset(10, 10), targetLayerIndex: 1);

        controller.setCurrentLayer(0);
        expect(controller.components.length, 1);

        controller.setCurrentLayer(1);
        expect(controller.components.length, 1);
      });

      test('Old API: selectedIndex returns component index', () {
        controller.addComponent(Container(), Offset(0, 0));
        controller.selectComponent(0, 0);

        expect(controller.selectedIndex, 0);
      });

      test('Old API: selectComponentByIndex works', () {
        controller.addComponent(Container(), Offset(0, 0));
        controller.selectComponentByIndex(0);

        expect(controller.selectedLayerIndex, 0);
        expect(controller.selectedIndex, 0);
      });
    });

    group('Edge Cases', () {
      test('Deleting layer adjusts current layer index', () {
        controller.createLayer(name: 'Layer 2');
        controller.createLayer(name: 'Layer 3');
        controller.setCurrentLayer(2);

        controller.deleteLayer(2);

        expect(controller.currentLayerIndex, 1); // Should adjust to valid index
      });

      test('Deleting selected layer deselects', () {
        controller.createLayer(name: 'Layer 2');
        controller.addComponent(Container(), Offset(0, 0), targetLayerIndex: 1);
        controller.selectComponent(1, 0);

        controller.deleteLayer(1);

        expect(controller.selectedLayerIndex, -1);
        expect(controller.selectedIndex, -1);
      });

      test('Hiding selected layer deselects', () {
        controller.addComponent(Container(), Offset(0, 0));
        controller.selectComponent(0, 0);

        controller.setLayerVisibility(0, false);

        expect(controller.selectedLayerIndex, -1);
      });

      test('Locking selected layer deselects', () {
        controller.addComponent(Container(), Offset(0, 0));
        controller.selectComponent(0, 0);

        controller.setLayerLocked(0, true);

        expect(controller.selectedLayerIndex, -1);
      });

      test('Update position with invalid layer index does nothing', () {
        controller.addComponent(Container(), Offset(0, 0));
        final originalPos = controller.positions[0];

        controller.updatePosition(0, Offset(100, 100), targetLayerIndex: 99);

        expect(controller.positions[0], originalPos); // Should not change
      });
    });

    group('scaleAllPositions', () {
      test('scales positions in a single layer', () {
        controller.addComponent(Container(), const Offset(100, 50));

        controller.scaleAllPositions(2.0, 3.0);

        expect(controller.positions[0], const Offset(200, 150));
      });

      test('scales positions across multiple layers', () {
        controller.addComponent(Container(), const Offset(10, 20), targetLayerIndex: 0);
        controller.createLayer(name: 'Layer 2');
        controller.addComponent(Container(), const Offset(30, 40), targetLayerIndex: 1);

        controller.scaleAllPositions(0.5, 0.5);

        expect(controller.layers[0].positions[0], const Offset(5, 10));
        expect(controller.layers[1].positions[0], const Offset(15, 20));
      });

      test('scale of 1.0 leaves positions unchanged', () {
        controller.addComponent(Container(), const Offset(42, 77));

        controller.scaleAllPositions(1.0, 1.0);

        expect(controller.positions[0], const Offset(42, 77));
      });

      test('scales positions on locked layers', () {
        controller.addComponent(Container(), const Offset(100, 100));
        controller.setLayerLocked(0, true);

        controller.scaleAllPositions(2.0, 2.0);

        expect(controller.positions[0], const Offset(200, 200));
      });

      test('scales positions on hidden layers', () {
        controller.addComponent(Container(), const Offset(100, 100));
        controller.setLayerVisibility(0, false);

        controller.scaleAllPositions(2.0, 2.0);

        expect(controller.layers[0].positions[0], const Offset(200, 200));
      });

      test('no-op on empty layers', () {
        // No components — should not throw
        expect(() => controller.scaleAllPositions(2.0, 2.0), returnsNormally);
      });
    });
  });
}
