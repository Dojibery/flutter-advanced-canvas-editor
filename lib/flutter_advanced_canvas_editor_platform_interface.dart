import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_advanced_canvas_editor_method_channel.dart';

abstract class FlutterAdvancedCanvasEditorPlatform extends PlatformInterface {
  /// Constructs a FlutterAdvancedCanvasEditorPlatform.
  FlutterAdvancedCanvasEditorPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterAdvancedCanvasEditorPlatform _instance = MethodChannelFlutterAdvancedCanvasEditor();

  /// The default instance of [FlutterAdvancedCanvasEditorPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterAdvancedCanvasEditor].
  static FlutterAdvancedCanvasEditorPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterAdvancedCanvasEditorPlatform] when
  /// they register themselves.
  static set instance(FlutterAdvancedCanvasEditorPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
