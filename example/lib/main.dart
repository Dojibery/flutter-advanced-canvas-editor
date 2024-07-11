import 'package:flutter/material.dart';
import 'package:flutter_advanced_canvas_editor/src/canvas_controller.dart';
import 'package:flutter_advanced_canvas_editor/src/large_image_canvas.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = CanvasController(onStateChanged: () => {});

    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(child: Center(child: LargeImageCanvas(controller: controller))),
              CustomDraggableItems(controller: controller, items: [
                Image.asset('assets/images/vehicle.png', width: 50, height: 50),
                Image.asset('assets/images/vehicle.png', width: 50, height: 50),
                // Add more items here
              ]),
              CustomActionButtons(controller: controller, buttons: [
                IconButton(icon: Icon(Icons.undo), onPressed: controller.undo),
                IconButton(icon: Icon(Icons.redo), onPressed: controller.redo),
                IconButton(icon: Icon(Icons.delete), onPressed: controller.clearAll),
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: !controller.isDrawing ? controller.enableDrawing : controller.disableDrawingErasing,
                ),
                IconButton(
                  icon: Icon(Icons.brush),
                  onPressed: !controller.isErasing ? controller.enableErasing : controller.disableDrawingErasing,
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomDraggableItems extends StatelessWidget {
  final CanvasController controller;
  final List<Widget> items;

  CustomDraggableItems({required this.controller, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Draggable<Widget>(
              data: item,
              feedback: item,
              childWhenDragging: Opacity(
                opacity: 0.5,
                child: item,
              ),
              child: item,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class CustomActionButtons extends StatelessWidget {
  final CanvasController controller;
  final List<Widget> buttons;

  CustomActionButtons({required this.controller, required this.buttons});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: buttons,
    );
  }
}
