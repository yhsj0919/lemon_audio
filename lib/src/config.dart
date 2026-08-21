import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';

enum LemonInterruptionBehavior { duck, pause }

enum LemonStandardNotificationAction { previous, playPause, next, stop }

typedef LemonNotificationButtonCallback =
    FutureOr<LemonNotificationButton?> Function();

/// A standard or host-defined button shown in the system media notification.
class LemonNotificationButton {
  const LemonNotificationButton._standard({
    required this.id,
    required LemonStandardNotificationAction action,
    required this.androidCompact,
  }) : standardAction = action,
       androidIcon = null,
       label = null,
       extras = const {},
       onPressed = null;

  factory LemonNotificationButton.standard(
    LemonStandardNotificationAction action, {
    bool? androidCompact,
  }) => LemonNotificationButton._standard(
    id: action.name,
    action: action,
    androidCompact:
        androidCompact ?? action != LemonStandardNotificationAction.stop,
  );

  const LemonNotificationButton.custom({
    required this.id,
    required this.androidIcon,
    required this.label,
    this.extras = const {},
    this.androidCompact = false,
    required this.onPressed,
  }) : standardAction = null;

  static const previous = LemonNotificationButton._standard(
    id: 'previous',
    action: LemonStandardNotificationAction.previous,
    androidCompact: true,
  );
  static const playPause = LemonNotificationButton._standard(
    id: 'playPause',
    action: LemonStandardNotificationAction.playPause,
    androidCompact: true,
  );
  static const next = LemonNotificationButton._standard(
    id: 'next',
    action: LemonStandardNotificationAction.next,
    androidCompact: true,
  );
  static const stop = LemonNotificationButton._standard(
    id: 'stop',
    action: LemonStandardNotificationAction.stop,
    androidCompact: false,
  );

  final String id;
  final LemonStandardNotificationAction? standardAction;
  final String? androidIcon;
  final String? label;
  final Map<String, dynamic> extras;
  final bool androidCompact;
  final LemonNotificationButtonCallback? onPressed;
}

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
    this.notificationButtons = const [
      LemonNotificationButton.previous,
      LemonNotificationButton.playPause,
      LemonNotificationButton.next,
      LemonNotificationButton.stop,
    ],
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
  final List<LemonNotificationButton> notificationButtons;
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
