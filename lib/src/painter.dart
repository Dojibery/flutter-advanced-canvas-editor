import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'canvas_layer.dart';

class Painter extends CustomPainter {
  final List<CanvasLayer> layers;
  final ui.Image? backgroundImage;
  final Color? backgroundColor;

  Painter({this.backgroundColor, required this.layers, this.backgroundImage});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    final paint = Paint()..color = backgroundColor ?? Colors.grey;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Draw background image if provided
    if (backgroundImage != null) {
      canvas.drawImageRect(
        backgroundImage!,
        Rect.fromLTWH(0, 0, backgroundImage!.width.toDouble(), backgroundImage!.height.toDouble()),
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint(),
      );
    }

    // Draw drawing points for each visible layer
    for (final layer in layers) {
      if (!layer.visible) continue; // Skip hidden layers

      final pointPaint = Paint()
        ..color = Colors.black.withOpacity(layer.opacity) // Apply layer opacity
        ..strokeCap = StrokeCap.round;

      for (Offset point in layer.drawingPoints) {
        canvas.drawCircle(point, 3.0, pointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
