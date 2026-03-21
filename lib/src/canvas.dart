import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'canvas_controller.dart';
import 'painter.dart';

/// The main canvas widget that renders all layers and handles user interaction.
///
/// Place [CanvasWidget] in your widget tree and provide a [CanvasController]
/// to control its state. The canvas supports:
///
/// - Freehand drawing and erasing (via pan gestures)
/// - Drag-and-drop of widget components onto the canvas
/// - Per-layer rendering with visibility and opacity support
/// - PNG export via [CanvasController.exportCanvas]
///
/// ## Example
///
/// ```dart
/// CanvasWidget(
///   controller: myController,
///   backgroundColor: Colors.white,
///   backgroundImage: 'assets/bg.png', // optional
/// )
/// ```
class CanvasWidget extends StatefulWidget {
  /// Optional asset path for a background image (e.g. `'assets/images/bg.png'`).
  final String? backgroundImage;

  /// Background fill colour. Defaults to grey when `null`.
  final Color? backgroundColor;

  /// The controller that manages all canvas state.
  final CanvasController controller;

  /// Size of the rotate/delete icon buttons shown on selected components.
  /// Defaults to `30.0`.
  final double? iconsSize;

  const CanvasWidget({
    super.key,
    this.backgroundColor,
    this.backgroundImage,
    this.iconsSize = 30.0,
    required this.controller,
  });

  @override
  // ignore: library_private_types_in_public_api
  _CanvasWidgetState createState() => _CanvasWidgetState();
}

class _CanvasWidgetState extends State<CanvasWidget> {
  ui.Image? backgroundImage;
  Color? backgroundColor;

  @override
  void initState() {
    super.initState();
    if (widget.backgroundImage != null) {
      _loadImage(widget.backgroundImage!);
    }
    // NOTE: We deliberately DON'T set onStateChanged here because it would
    // overwrite the callback set by the parent widget. The parent's rebuild
    // will automatically cascade to this widget, so we don't need our own callback.
  }

  Future<void> _loadImage(String asset) async {
    final ByteData data = await rootBundle.load(asset);
    final ui.Codec codec =
        await ui.instantiateImageCodec(data.buffer.asUint8List());
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    setState(() {
      backgroundImage = frameInfo.image;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final iconsSize = widget.iconsSize;

    return GestureDetector(
        onTap: () {
          if (!controller.isDrawing && !controller.isErasing) {
            controller.deselectComponent();
          }
        },
        child: RepaintBoundary(
            key: controller.canvasKey,
            child: Stack(
              children: [
                CustomPaint(
                  size: const Size(double.infinity, double.infinity),
                  painter: Painter(
                      backgroundColor: backgroundColor,
                      backgroundImage: backgroundImage,
                      layers: controller.layers),
                ),
                DragTarget<Widget>(
                  onAcceptWithDetails: (details) {
                    RenderBox renderBox =
                        context.findRenderObject() as RenderBox;
                    Offset localOffset =
                        renderBox.globalToLocal(details.offset);
                    controller.addComponent(details.data, localOffset);
                  },
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      color: Colors.transparent,
                      width: double.infinity,
                      height: double.infinity,
                    );
                  },
                ),
                GestureDetector(
                  onPanStart: (details) {
                    _handlePan(details.localPosition, controller);
                  },
                  onPanUpdate: (details) {
                    _handlePan(details.localPosition, controller);
                  },
                ),
                // Render all layers
                ..._buildLayerWidgets(controller, iconsSize),
              ],
            )));
  }

  /// Builds widgets for all visible layers
  List<Widget> _buildLayerWidgets(CanvasController controller, double? iconsSize) {
    final layers = controller.layers;
    List<Widget> layerWidgets = [];

    // Iterate through layers (bottom to top for correct z-order)
    for (int layerIndex = 0; layerIndex < layers.length; layerIndex++) {
      final layer = layers[layerIndex];

      // Skip hidden layers completely
      if (!layer.visible) continue;

      // Render each component in this layer
      for (int compIndex = 0; compIndex < layer.components.length; compIndex++) {
        final component = layer.components[compIndex];
        final position = layer.positions[compIndex];
        final rotation = layer.rotations[compIndex];

        final isSelected = controller.selectedLayerIndex == layerIndex &&
            controller.selectedIndex == compIndex;

        double? imageWidth = 50;
        double? imageHeight = 50;
        if (component is Image) {
          imageWidth = component.width;
          imageHeight = component.height;
        }

        Widget componentWidget = Stack(
          children: [
            // Rotate button (only if selected and layer not locked)
            if (isSelected && !layer.locked)
              Positioned(
                left: position.dx + imageWidth!,
                top: position.dy - 30,
                child: IconButton(
                  color: Colors.black,
                  icon: Icon(Icons.rotate_right, size: iconsSize),
                  onPressed: () {
                    controller.rotateComponent(compIndex, targetLayerIndex: layerIndex);
                  },
                ),
              ),

            // Delete button (only if selected and layer not locked)
            if (isSelected && !layer.locked)
              Positioned(
                left: position.dx - 30,
                top: position.dy + imageHeight!,
                child: IconButton(
                  color: Colors.black,
                  icon: Icon(Icons.delete, size: iconsSize),
                  onPressed: () {
                    controller.deleteComponent(compIndex, targetLayerIndex: layerIndex);
                  },
                ),
              ),

            // The component itself
            Positioned(
              left: position.dx,
              top: position.dy,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  if (!controller.isDrawing && !controller.isErasing) {
                    // Pass layer index to selection
                    controller.selectComponent(layerIndex, compIndex);
                  }
                },
                onPanUpdate: (details) {
                  if (!controller.isDrawing && !controller.isErasing) {
                    if (isSelected && !layer.locked) {
                      // Check lock status
                      controller.updatePosition(
                        compIndex,
                        Offset(
                          position.dx + details.delta.dx,
                          position.dy + details.delta.dy,
                        ),
                        targetLayerIndex: layerIndex,
                      );
                    }
                  }
                },
                child: Transform.rotate(
                  angle: rotation * (3.14159265359 / 180),
                  child: Container(
                    decoration: isSelected
                        ? BoxDecoration(
                            border: Border.all(color: Colors.green, width: 2),
                          )
                        : null,
                    child: component,
                  ),
                ),
              ),
            ),
          ],
        );

        // Apply layer opacity
        if (layer.opacity < 1.0) {
          componentWidget = Opacity(
            opacity: layer.opacity,
            child: componentWidget,
          );
        }

        layerWidgets.add(componentWidget);
      }
    }

    return layerWidgets;
  }

  void _handlePan(Offset localPosition, CanvasController controller) {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    if (controller.isDrawing) {
      if (_isInsideCanvas(localPosition, renderBox.size)) {
        controller.addDrawingPoint(localPosition);
      }
    } else if (controller.isErasing) {
      if (_isInsideCanvas(localPosition, renderBox.size)) {
        controller.removeDrawingPoint(localPosition);
      }
    }
  }

  bool _isInsideCanvas(Offset position, Size canvasSize) {
    return position.dx >= 0 &&
        position.dx <= canvasSize.width &&
        position.dy >= 0 &&
        position.dy <= canvasSize.height;
  }
}
