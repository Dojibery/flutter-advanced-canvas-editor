#ifndef FLUTTER_PLUGIN_FLUTTER_ADVANCED_CANVAS_EDITOR_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_ADVANCED_CANVAS_EDITOR_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace flutter_advanced_canvas_editor {

class FlutterAdvancedCanvasEditorPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FlutterAdvancedCanvasEditorPlugin();

  virtual ~FlutterAdvancedCanvasEditorPlugin();

  // Disallow copy and assign.
  FlutterAdvancedCanvasEditorPlugin(const FlutterAdvancedCanvasEditorPlugin&) = delete;
  FlutterAdvancedCanvasEditorPlugin& operator=(const FlutterAdvancedCanvasEditorPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace flutter_advanced_canvas_editor

#endif  // FLUTTER_PLUGIN_FLUTTER_ADVANCED_CANVAS_EDITOR_PLUGIN_H_
