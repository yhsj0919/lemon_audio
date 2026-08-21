//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import audio_service
import audio_session
import lemon_audio
import mpv_audio_kit
import sqflite_darwin

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  AudioServicePlugin.register(with: registry.registrar(forPlugin: "AudioServicePlugin"))
  AudioSessionPlugin.register(with: registry.registrar(forPlugin: "AudioSessionPlugin"))
  LemonAudioPlugin.register(with: registry.registrar(forPlugin: "LemonAudioPlugin"))
  MpvAudioKitPlugin.register(with: registry.registrar(forPlugin: "MpvAudioKitPlugin"))
  SqflitePlugin.register(with: registry.registrar(forPlugin: "SqflitePlugin"))
}
