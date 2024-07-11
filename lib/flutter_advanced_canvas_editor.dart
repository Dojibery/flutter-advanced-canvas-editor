
import 'flutter_advanced_canvas_editor_platform_interface.dart';

class FlutterAdvancedCanvasEditor {
  Future<String?> getPlatformVersion() {
    return FlutterAdvancedCanvasEditorPlatform.instance.getPlatformVersion();
  }
}
