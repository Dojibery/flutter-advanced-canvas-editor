import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'canvas_controller.dart';
import 'painter.dart';

class CanvasWidget extends StatefulWidget {
  final String? backgroundImage; // e.g. 'assets/images/road.png'
  final Color? backgroundColor;
  final CanvasController controller;

  const CanvasWidget({Key? key, this.backgroundColor, this.backgroundImage, required this.controller}) : super(key: key);

  @override
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
    widget.controller.onStateChanged = _handleStateChanged;
  }

  Future<void> _loadImage(String asset) async {
    final ByteData data = await rootBundle.load(asset);
    final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    setState(() {
      backgroundImage = frameInfo.image;
    });
  }

  void _handleStateChanged(bool isDrawing, bool isErasing) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return GestureDetector(
      onTap: () {
        if (!controller.isDrawing && !controller.isErasing) {
          controller.deselectComponent();
        }
      },
      child: RepaintBoundary(
          key: controller.canvasKey,
          child: Positioned.fill(
              child: CustomPaint(
                            painter: Painter(backgroundColor: backgroundColor, backgroundImage: backgroundImage, drawingPoints: controller.drawingPoints),
                            child: GestureDetector(
                onPanStart: (details) {
                  _handlePan(details.localPosition, controller);
                },
                onPanUpdate: (details) {
                  _handlePan(details.localPosition, controller);
                },
                child: Stack(children: [
                  DragTarget<Widget>(
                    onAcceptWithDetails: (details) {
                      RenderBox renderBox = context.findRenderObject() as RenderBox;
                      Offset localOffset = renderBox.globalToLocal(details.offset);
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
                  ...controller.components.asMap().entries.map((entry) {
                    int index = entry.key;
                    Widget component = entry.value;
                    bool isSelected = controller.selectedIndex == index;
                    return Positioned(
                      left: controller.positions[index].dx,
                      top: controller.positions[index].dy,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          if (!controller.isDrawing && !controller.isErasing) {
                            controller.selectComponent(index);
                          }
                        },
                        onPanUpdate: (details) {
                          if (!controller.isDrawing && !controller.isErasing) {
                            if (isSelected) {
                              controller.updatePosition(
                                index,
                                Offset(
                                  controller.positions[index].dx + details.delta.dx,
                                  controller.positions[index].dy + details.delta.dy,
                                ),
                              );
                            }
                          }
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Transform.rotate(
                              angle: controller.rotations[index] * (3.14159265359 / 180),
                              child: Container(
                                decoration: isSelected
                                    ? BoxDecoration(
                                  border: Border.all(color: Colors.green, width: 2),
                                )
                                    : null,
                                child: component,
                              ),
                            ),
                            if (isSelected)
                              Positioned(
                                right: -15, // Adjust as needed
                                top: -15, // Adjust as needed
                                child: IconButton(
                                  color: Colors.black,
                                  icon: Icon(Icons.rotate_right),
                                  onPressed: () {
                                    controller.rotateComponent(index);
                                  },
                                ),
                              ),
                            if (isSelected)
                              Positioned(
                                left: -15, // Adjust as needed
                                bottom: -15, // Adjust as needed
                                child: IconButton(
                                  color: Colors.black,
                                  icon: Icon(Icons.delete),
                                  onPressed: () {
                                    controller.deleteComponent(index);
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ]),
                            ),
                          ),
              )),
    );
  }

  void _handlePan(Offset localPosition, CanvasController controller) {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Offset localOffset = renderBox.globalToLocal(localPosition);
    if (controller.isDrawing) {
      if (_isInsideCanvas(localOffset, renderBox.size)) {
        controller.addDrawingPoint(localOffset);
      }
    } else if (controller.isErasing) {
      if (_isInsideCanvas(localOffset, renderBox.size)) {
        controller.removeDrawingPoint(localOffset);
      }
    }
  }

  bool _isInsideCanvas(Offset position, Size canvasSize) {
    return position.dx >= 0 && position.dx <= canvasSize.width && position.dy >= 0 && position.dy <= canvasSize.height;
  }
}
