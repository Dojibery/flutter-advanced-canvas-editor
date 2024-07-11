import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_advanced_canvas_editor/flutter_advanced_canvas_editor.dart';
import 'package:flutter_advanced_canvas_editor/flutter_advanced_canvas_editor_platform_interface.dart';
import 'package:flutter_advanced_canvas_editor/flutter_advanced_canvas_editor_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterAdvancedCanvasEditorPlatform
    with MockPlatformInterfaceMixin
    implements FlutterAdvancedCanvasEditorPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterAdvancedCanvasEditorPlatform initialPlatform = FlutterAdvancedCanvasEditorPlatform.instance;

  test('$MethodChannelFlutterAdvancedCanvasEditor is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterAdvancedCanvasEditor>());
  });

  test('getPlatformVersion', () async {
    FlutterAdvancedCanvasEditor flutterAdvancedCanvasEditorPlugin = FlutterAdvancedCanvasEditor();
    MockFlutterAdvancedCanvasEditorPlatform fakePlatform = MockFlutterAdvancedCanvasEditorPlatform();
    FlutterAdvancedCanvasEditorPlatform.instance = fakePlatform;

    expect(await flutterAdvancedCanvasEditorPlugin.getPlatformVersion(), '42');
  });
}
