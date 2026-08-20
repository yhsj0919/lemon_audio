import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';

enum LemonInterruptionBehavior { duck, pause }

class LemonAudioSettings {
  const LemonAudioSettings({
    required this.allowConcurrentPlayback,
    required this.audioInterruptionEnabled,
    required this.interruptionBehavior,
    required this.duckVolume,
    required this.resumeAfterInterruption,
  });

  final bool allowConcurrentPlayback;
  final bool audioInterruptionEnabled;
  final LemonInterruptionBehavior interruptionBehavior;
  final double duckVolume;
  final bool resumeAfterInterruption;
}

class LemonAudioConfig {
  const LemonAudioConfig({
    this.androidNotificationChannelId = 'lemon_audio.playback',
    this.androidNotificationChannelName = 'Music playback',
    this.androidNotificationOngoing = false,
    this.stopForegroundOnPause = true,
    this.pauseWhenHeadphonesDisconnected = true,
    this.allowConcurrentPlayback = false,
    this.audioInterruptionEnabled = true,
    this.interruptionBehavior = LemonInterruptionBehavior.pause,
    this.duckVolume = 0.2,
    this.resumeAfterInterruption = false,
    this.sessionConfiguration,
  });
  final String androidNotificationChannelId;
  final String androidNotificationChannelName;
  final bool androidNotificationOngoing;
  final bool stopForegroundOnPause;
  final bool pauseWhenHeadphonesDisconnected;
  final bool allowConcurrentPlayback;
  final bool audioInterruptionEnabled;
  final LemonInterruptionBehavior interruptionBehavior;
  final double duckVolume;
  final bool resumeAfterInterruption;
  final AudioSessionConfiguration? sessionConfiguration;

  AudioServiceConfig get serviceConfig => AudioServiceConfig(
    androidNotificationChannelId: androidNotificationChannelId,
    androidNotificationChannelName: androidNotificationChannelName,
    androidNotificationOngoing: androidNotificationOngoing,
    androidStopForegroundOnPause: stopForegroundOnPause,
  );

  LemonAudioSettings get settings => LemonAudioSettings(
    allowConcurrentPlayback: allowConcurrentPlayback,
    audioInterruptionEnabled: audioInterruptionEnabled,
    interruptionBehavior: interruptionBehavior,
    duckVolume: duckVolume,
    resumeAfterInterruption: resumeAfterInterruption,
  );
}
