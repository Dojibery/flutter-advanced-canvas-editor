import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_advanced_canvas_editor_platform_interface.dart';

/// An implementation of [FlutterAdvancedCanvasEditorPlatform] that uses method channels.
class MethodChannelFlutterAdvancedCanvasEditor extends FlutterAdvancedCanvasEditorPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_advanced_canvas_editor');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
