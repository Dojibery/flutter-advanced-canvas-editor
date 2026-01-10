
import 'flutter_advanced_canvas_editor_platform_interface.dart';

export 'src/canvas_controller.dart';
export 'src/canvas.dart';
export 'src/canvas_layer.dart';

class FlutterAdvancedCanvasEditor {
  Future<String?> getPlatformVersion() {
    return FlutterAdvancedCanvasEditorPlatform.instance.getPlatformVersion();
  }
}
