import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'canvas_controller.dart';
import 'large_image_painter.dart';

class LargeImageCanvas extends StatefulWidget {
  final String? backgroundImage; // 'assets/images/road.png'
  final CanvasController controller;

  const LargeImageCanvas({Key? key, this.backgroundImage, required this.controller}) : super(key: key);

  @override
  _LargeImageCanvasState createState() => _LargeImageCanvasState();
}

class _LargeImageCanvasState extends State<LargeImageCanvas> {
  ui.Image? backgroundImage;

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
      onPanStart: (details) {
        if (controller.isDrawing) {
          RenderBox renderBox = context.findRenderObject() as RenderBox;
          Offset localOffset = renderBox.globalToLocal(details.localPosition);
          controller.addDrawingPoint(localOffset);
        } else if (controller.isErasing) {
          RenderBox renderBox = context.findRenderObject() as RenderBox;
          Offset localOffset = renderBox.globalToLocal(details.localPosition);
          controller.removeDrawingPoint(localOffset);
        }
      },
      onPanUpdate: (details) {
        if (controller.isDrawing) {
          RenderBox renderBox = context.findRenderObject() as RenderBox;
          Offset localOffset = renderBox.globalToLocal(details.localPosition);
          controller.addDrawingPoint(localOffset);
        } else if (controller.isErasing) {
          RenderBox renderBox = context.findRenderObject() as RenderBox;
          Offset localOffset = renderBox.globalToLocal(details.localPosition);
          controller.removeDrawingPoint(localOffset);
        }
      },
      onTap: () {
        if (!controller.isDrawing && !controller.isErasing) {
          controller.deselectComponent();
        }
      },
      child: Stack(
        children: [
          CustomPaint(
            size: Size(double.infinity, double.infinity),
            painter: LargeImagePainter(backgroundImage: backgroundImage, drawingPoints: controller.drawingPoints),
          ),
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
                child: Container(
                  decoration: isSelected
                      ? BoxDecoration(
                          border: Border.all(color: Colors.green, width: 2),
                        )
                      : null,
                  child: component,
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
