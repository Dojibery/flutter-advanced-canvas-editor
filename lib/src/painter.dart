import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class Painter extends CustomPainter {
  final List<Offset> drawingPoints;
  final ui.Image? backgroundImage;
  final Color? backgroundColor;

  Painter({this.backgroundColor, required this.drawingPoints, this.backgroundImage}) {}

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = this.backgroundColor != null ? this.backgroundColor! : Colors.grey;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    if (backgroundImage != null) {
      canvas.drawImageRect(
        backgroundImage!,
        Rect.fromLTWH(0, 0, backgroundImage!.width.toDouble(), backgroundImage!.height.toDouble()),
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint(),
      );
    }

    final pointPaint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (Offset point in drawingPoints) {
      canvas.drawCircle(point, 5.0, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
