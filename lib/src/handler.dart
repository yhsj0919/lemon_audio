import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';

import 'config.dart';
import 'models.dart';
import 'player.dart';

class LemonAudioHandler extends BaseAudioHandler with SeekHandler {
  LemonAudioHandler(this.player, this.config);

  final LemonAudioPlayer player;
  final LemonAudioConfig config;
  final _lyrics = StreamController<String?>.broadcast();
  final _positions = StreamController<Duration>.broadcast();
  final _bufferedPositions = StreamController<Duration>.broadcast();
  final _durations = StreamController<Duration?>.broadcast();
  final _settingsController = StreamController<LemonAudioSettings>.broadcast();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  AudioSession? _session;
  LemonAudioTrack? _track;
  Timer? _titleTimer;
  String? _pendingTitle;
  String? _publishedTitle;
  LemonPlayerState _reportedState = const LemonPlayerState.idle();
  late LemonAudioSettings _settings;
  bool _wasPlayingBeforeInterruption = false;
  late List<LemonNotificationButton> _notificationButtons;

  Stream<String?> get lyricStream => _lyrics.stream;
  Stream<Duration> get positionStream => _positions.stream;
  Stream<Duration> get bufferedPositionStream => _bufferedPositions.stream;
  Stream<Duration?> get durationStream => _durations.stream;
  Stream<LemonAudioSettings> get settingsStream => _settingsController.stream;
  LemonAudioSettings get settings => _settings;

  Future<void> initialize() async {
    _settings = config.settings;
    _validateVolume(_settings.duckVolume);
    _notificationButtons = List.of(config.notificationButtons);
    _validateNotificationButtons(_notificationButtons);
    if (_supportsAudioSession) {
      _session = await AudioSession.instance;
      await _configureSession();
    }
    _subscriptions.add(player.stateStream.listen(_broadcastState));
    _broadcastState(player.currentState);
    if (config.pauseWhenHeadphonesDisconnected && _session != null) {
      _subscriptions.add(
        _session!.becomingNoisyEventStream.listen((_) => pause()),
      );
    }
    final session = _session;
    if (session != null) {
      _subscriptions.add(
        session.interruptionEventStream.listen((event) async {
          if (!_settings.audioInterruptionEnabled) return;
          if (event.begin) {
            _wasPlayingBeforeInterruption = _reportedState.playing;
            if (_settings.interruptionBehavior ==
                LemonInterruptionBehavior.duck) {
              await player.setVolume(_settings.duckVolume);
            } else {
              await pause();
            }
          } else {
            if (_settings.interruptionBehavior ==
                LemonInterruptionBehavior.duck) {
              await player.setVolume(1);
            } else if (_settings.resumeAfterInterruption &&
                _wasPlayingBeforeInterruption) {
              await play();
            }
            _wasPlayingBeforeInterruption = false;
          }
        }),
      );
    }
  }

  Future<void> setAllowConcurrentPlayback(bool value) async {
    if (_settings.allowConcurrentPlayback == value) return;
    _settings = _copySettings(allowConcurrentPlayback: value);
    if (_session != null) await _configureSession();
    if (_reportedState.playing) {
      if (value) {
        await _session?.setActive(false);
      } else {
        await _session?.setActive(true);
      }
    }
    _settingsController.add(_settings);
  }

  void setAudioInterruptionEnabled(bool value) {
    _settings = _copySettings(audioInterruptionEnabled: value);
    _settingsController.add(_settings);
  }

  void setInterruptionBehavior(LemonInterruptionBehavior value) {
    _settings = _copySettings(interruptionBehavior: value);
    _settingsController.add(_settings);
  }

  void setDuckVolume(double value) {
    _validateVolume(value);
    _settings = _copySettings(duckVolume: value);
    _settingsController.add(_settings);
  }

  void setResumeAfterInterruption(bool value) {
    _settings = _copySettings(resumeAfterInterruption: value);
    _settingsController.add(_settings);
  }

  Future<void> setTrack(LemonAudioTrack track) async {
    _titleTimer?.cancel();
    _titleTimer = null;
    _pendingTitle = _publishedTitle = null;
    _track = track;
    mediaItem.add(track.toMediaItem());
    setPosition(Duration.zero);
    setBufferedPosition(Duration.zero);
    _durations.add(track.duration);
  }

  void setDuration(Duration? duration) {
    _validateDuration(duration, 'duration');
    _durations.add(duration);
    final track = _track;
    if (track == null) return;
    _track = track.copyWith(
      duration: duration,
      clearDuration: duration == null,
    );
    mediaItem.add(_track!.toMediaItem(titleOverride: _publishedTitle));
  }

  void setPosition(Duration position) {
    _validateDuration(position, 'position');
    _reportedState = _reportedState.copyWith(position: position);
    _positions.add(position);
    _publishReportedState();
  }

  void setBufferedPosition(Duration position) {
    _validateDuration(position, 'bufferedPosition');
    _reportedState = _reportedState.copyWith(bufferedPosition: position);
    _bufferedPositions.add(position);
    _publishReportedState();
  }

  Future<void> setTracks(List<LemonAudioTrack> tracks) async {
    queue.add(tracks.map((e) => e.toMediaItem()).toList(growable: false));
  }

  Future<void> setNotificationButtons(
    List<LemonNotificationButton> buttons,
  ) async {
    _validateNotificationButtons(buttons);
    _notificationButtons = List.of(buttons);
    _publishReportedState();
  }

  Future<void> updateLyric(
    String? lyric, {
    LemonLyricMode mode = LemonLyricMode.appOnly,
  }) async {
    _lyrics.add(lyric);
    final track = _track;
    if (track != null && mode == LemonLyricMode.bluetoothTitle) {
      _pendingTitle = lyric == null || lyric.trim().isEmpty
          ? null
          : lyric.trim();
      if (_pendingTitle == null) {
        if (_publishedTitle == null) return;
        _publishedTitle = null;
        mediaItem.add(track.toMediaItem());
      } else if (_titleTimer == null) {
        _publishLyricTitle();
      }
    }
  }

  void _publishLyricTitle() {
    _titleTimer = null;
    if (_pendingTitle == _publishedTitle || _track == null) return;
    _publishedTitle = _pendingTitle;
    mediaItem.add(_track!.toMediaItem(titleOverride: _publishedTitle));
    _titleTimer = Timer(const Duration(seconds: 1), _publishLyricTitle);
  }

  @override
  Future<void> play() async {
    final session = _session;
    if (_settings.allowConcurrentPlayback ||
        session == null ||
        await session.setActive(true)) {
      await player.play();
    }
  }

  @override
  Future<void> pause() => player.pause();
  @override
  Future<void> seek(Duration position) => player.seek(position);
  @override
  Future<void> skipToNext() => player.skipToNext();
  @override
  Future<void> skipToPrevious() => player.skipToPrevious();
  @override
  Future<void> skipToQueueItem(int index) => player.skipToQueueItem(index);
  @override
  Future<void> setSpeed(double speed) => player.setSpeed(speed);
  @override
  Future<void> stop() async {
    await player.stop();
    await _session?.setActive(false);
    playbackState.add(
      playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.idle,
      ),
    );
  }

  @override
  Future<dynamic> customAction(
    String name, [
    Map<String, dynamic>? extras,
  ]) async {
    const prefix = 'lemon_notification:';
    if (!name.startsWith(prefix)) return super.customAction(name, extras);
    final id = name.substring(prefix.length);
    for (var index = 0; index < _notificationButtons.length; index++) {
      final button = _notificationButtons[index];
      if (button.id == id &&
          button.standardAction == null &&
          button.onPressed != null) {
        final replacement = await button.onPressed!();
        if (replacement != null) {
          if (replacement.id != id) {
            throw ArgumentError.value(
              replacement.id,
              'replacement.id',
              'must match the pressed button ID $id',
            );
          }
          final updated = List<LemonNotificationButton>.of(_notificationButtons)
            ..[index] = replacement;
          _validateNotificationButtons(updated);
          _notificationButtons = updated;
          _publishReportedState();
        }
        return;
      }
    }
  }

  void _broadcastState(LemonPlayerState state) {
    if (state.position != _reportedState.position) {
      _positions.add(state.position);
    }
    if (state.bufferedPosition != _reportedState.bufferedPosition) {
      _bufferedPositions.add(state.bufferedPosition);
    }
    _reportedState = state;
    _publishReportedState();
  }

  void _publishReportedState() {
    final state = _reportedState;
    final controls = _notificationButtons
        .map((button) => _mediaControlFor(button, state.playing))
        .toList(growable: false);
    playbackState.add(
      PlaybackState(
        controls: controls,
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: [
          for (var index = 0; index < _notificationButtons.length; index++)
            if (_notificationButtons[index].androidCompact) index,
        ],
        processingState: switch (state.processingState) {
          LemonProcessingState.idle => AudioProcessingState.idle,
          LemonProcessingState.loading => AudioProcessingState.loading,
          LemonProcessingState.buffering => AudioProcessingState.buffering,
          LemonProcessingState.ready => AudioProcessingState.ready,
          LemonProcessingState.completed => AudioProcessingState.completed,
          LemonProcessingState.error => AudioProcessingState.error,
        },
        playing: state.playing,
        updatePosition: state.position,
        bufferedPosition: state.bufferedPosition,
        speed: state.speed,
        queueIndex: state.queueIndex,
        errorMessage: state.errorMessage,
      ),
    );
  }

  void _validateDuration(Duration? value, String name) {
    if (value != null && value.isNegative) {
      throw ArgumentError.value(value, name, 'must not be negative');
    }
  }

  void _validateVolume(double value) {
    if (!value.isFinite || value < 0 || value > 1) {
      throw ArgumentError.value(value, 'duckVolume', 'must be between 0 and 1');
    }
  }

  void _validateNotificationButtons(List<LemonNotificationButton> buttons) {
    final ids = buttons.map((button) => button.id).toList(growable: false);
    if (ids.any((id) => id.trim().isEmpty)) {
      throw ArgumentError.value(
        buttons,
        'notificationButtons',
        'button IDs must not be empty',
      );
    }
    if (ids.toSet().length != ids.length) {
      throw ArgumentError.value(
        buttons,
        'notificationButtons',
        'button IDs must be unique',
      );
    }
    if (buttons.where((button) => button.androidCompact).length > 3) {
      throw ArgumentError.value(
        buttons,
        'notificationButtons',
        'at most 3 buttons can set androidCompact to true',
      );
    }
    for (final button in buttons.where(
      (button) => button.standardAction == null,
    )) {
      if (button.androidIcon == null || button.androidIcon!.trim().isEmpty) {
        throw ArgumentError.value(
          button,
          'notificationButtons',
          'custom button androidIcon must not be empty',
        );
      }
      if (button.label == null || button.label!.trim().isEmpty) {
        throw ArgumentError.value(
          button,
          'notificationButtons',
          'custom button label must not be empty',
        );
      }
    }
  }

  MediaControl _mediaControlFor(LemonNotificationButton button, bool playing) {
    if (button.standardAction == null) {
      return MediaControl.custom(
        androidIcon: button.androidIcon!,
        label: button.label!,
        name: 'lemon_notification:${button.id}',
        extras: button.extras,
      );
    }
    return switch (button.standardAction!) {
      LemonStandardNotificationAction.previous => MediaControl.skipToPrevious,
      LemonStandardNotificationAction.playPause =>
        playing ? MediaControl.pause : MediaControl.play,
      LemonStandardNotificationAction.next => MediaControl.skipToNext,
      LemonStandardNotificationAction.stop => MediaControl.stop,
    };
  }

  LemonAudioSettings _copySettings({
    bool? allowConcurrentPlayback,
    bool? audioInterruptionEnabled,
    LemonInterruptionBehavior? interruptionBehavior,
    double? duckVolume,
    bool? resumeAfterInterruption,
  }) => LemonAudioSettings(
    allowConcurrentPlayback:
        allowConcurrentPlayback ?? _settings.allowConcurrentPlayback,
    audioInterruptionEnabled:
        audioInterruptionEnabled ?? _settings.audioInterruptionEnabled,
    interruptionBehavior:
        interruptionBehavior ?? _settings.interruptionBehavior,
    duckVolume: duckVolume ?? _settings.duckVolume,
    resumeAfterInterruption:
        resumeAfterInterruption ?? _settings.resumeAfterInterruption,
  );

  bool get _supportsAudioSession =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  Future<void> _configureSession() => _session!.configure(
    config.sessionConfiguration ??
        AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions: _settings.allowConcurrentPlayback
              ? AVAudioSessionCategoryOptions.mixWithOthers
              : AVAudioSessionCategoryOptions.none,
          avAudioSessionMode: AVAudioSessionMode.defaultMode,
          androidAudioAttributes: const AndroidAudioAttributes(
            contentType: AndroidAudioContentType.music,
            usage: AndroidAudioUsage.media,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
          androidWillPauseWhenDucked:
              _settings.interruptionBehavior == LemonInterruptionBehavior.pause,
        ),
  );

  Future<void> disposeHandler() async {
    _titleTimer?.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _lyrics.close();
    await _positions.close();
    await _bufferedPositions.close();
    await _durations.close();
    await _settingsController.close();
    await player.dispose();
  }
}
