#include "include/flutter_advanced_canvas_editor/flutter_advanced_canvas_editor_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_advanced_canvas_editor_plugin.h"

void FlutterAdvancedCanvasEditorPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_advanced_canvas_editor::FlutterAdvancedCanvasEditorPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
