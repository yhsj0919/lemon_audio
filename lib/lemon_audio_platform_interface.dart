import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'lemon_audio_method_channel.dart';

abstract class LemonAudioPlatform extends PlatformInterface {
  /// Constructs a LemonAudioPlatform.
  LemonAudioPlatform() : super(token: _token);

  static final Object _token = Object();

  static LemonAudioPlatform _instance = MethodChannelLemonAudio();

  /// The default instance of [LemonAudioPlatform] to use.
  ///
  /// Defaults to [MethodChannelLemonAudio].
  static LemonAudioPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [LemonAudioPlatform] when
  /// they register themselves.
  static set instance(LemonAudioPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
