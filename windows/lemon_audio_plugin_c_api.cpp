#include "include/lemon_audio/lemon_audio_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "lemon_audio_plugin.h"

void LemonAudioPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  lemon_audio::LemonAudioPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
