import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'lemon_audio_platform_interface.dart';

/// An implementation of [LemonAudioPlatform] that uses method channels.
class MethodChannelLemonAudio extends LemonAudioPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('lemon_audio');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
