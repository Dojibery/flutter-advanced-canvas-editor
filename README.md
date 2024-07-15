## Flutter Advanced Canvas Editor

A Flutter package for creating, editing, and exporting canvas-based artwork with advanced features.

## Preview

![Result](https://github.com/Dojibery/flutter-advanced-canvas-editor/blob/master/assets/images/preview.png)

## Features

* Draw, rotate, and delete components on a canvas.
* Undo and redo actions for component manipulation.
* Export the canvas as a PNG image.
* Callback integration for handling canvas exports.

## Installation

Add the following line to your `pubspec.yaml` file:
```yaml
dependencies:
  flutter_advanced_canvas_editor:
```

## Usage

```dart
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
    return MaterialApp(
        home: Scaffold(
            body: SafeArea(
                child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: CanvasWidget(controller: controller, backgroundImage: 'assets/images/background.png',),
                        ),
                      ),
                    ])))

    );
  }
}
```

## Save Canvas as PNG Bytes

```dart
late CanvasController controller;

@override
void initState() {
  super.initState();
  controller = CanvasController((pngBytes) {
    print('PNG bytes exporting canvas: $pngBytes');
  });
}
```

## Contributing

Contributions are welcome! Feel free to open issues and pull requests to suggest new features, report bugs, or improve the codebase.

## License
This project is licensed under the MIT License - see the [LICENSE](https://github.com/Dojibery/flutter-advanced-canvas-editor/blob/master/LICENSE)
file for details.
