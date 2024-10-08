import 'package:flutter/material.dart';
import 'package:flutter_advanced_canvas_editor/src/canvas_controller.dart';
import 'package:flutter_advanced_canvas_editor/src/canvas.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late CanvasController controller;
  bool isDrawing = false;
  bool isErasing = false;

  @override
  void initState() {
    super.initState();
    controller = CanvasController((pngBytes) {
      print('PNG bytes exporting canvas: $pngBytes');
    });
  }

  @override
  Widget build(BuildContext context) {
    controller.setOnStateChanged((isDrawing, isErasing) {
      print('isDrawing: $isDrawing');
      print('isErasing: $isErasing');
      setState(() {
        isDrawing = isDrawing;
        isErasing = isErasing;
      });
    });

    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: CanvasWidget(controller: controller, backgroundImage: 'assets/images/background.png', iconsSize: 25.0,),
                ),
              ),
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
                  color: !controller.isDrawing ? Colors.black : Colors.red,
                  onPressed: !controller.isDrawing ? controller.enableDrawing : controller.disableDrawingErasing,
                ),
                IconButton(
                  icon: Icon(Icons.brush),
                  color: !controller.isErasing ? Colors.black : Colors.red,
                  onPressed: !controller.isErasing ? controller.enableErasing : controller.disableDrawingErasing,
                ),
                IconButton(icon: Icon(Icons.save), onPressed: controller.exportCanvas),
              ]),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Drawing: $isDrawing, Erasing: $isErasing'),
              ),
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
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      // Disable drawing and erasing when the drag interaction starts
      onPanStart: (onPanStart) {
        controller.disableDrawingErasing();
      },
      // Disable drawing and erasing when the drag interaction ends
      onPanEnd: (onPanEnd) {
        controller.disableDrawingErasing();
      },
      child: Container(
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
                // Disable drawing and erasing when the drag interaction starts
                onDragStarted: () {
                  controller.disableDrawingErasing();
                },
                // Optionally, you can disable drawing and erasing when the drag interaction is completed or canceled
                onDragEnd: (details) {
                  controller.disableDrawingErasing();
                },
                onDraggableCanceled: (velocity, offset) {
                  controller.disableDrawingErasing();
                },
              ),
            );
          }).toList(),
        ),
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
