//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <lemon_audio/lemon_audio_plugin.h>
#include <mpv_audio_kit/mpv_audio_kit_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) lemon_audio_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "LemonAudioPlugin");
  lemon_audio_plugin_register_with_registrar(lemon_audio_registrar);
  g_autoptr(FlPluginRegistrar) mpv_audio_kit_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "MpvAudioKitPlugin");
  mpv_audio_kit_plugin_register_with_registrar(mpv_audio_kit_registrar);
}
