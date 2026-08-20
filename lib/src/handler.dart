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
  LemonPlayerState _reportedState = const LemonPlayerState.idle();
  late LemonAudioSettings _settings;
  bool _wasPlayingBeforeInterruption = false;

  Stream<String?> get lyricStream => _lyrics.stream;
  Stream<Duration> get positionStream => _positions.stream;
  Stream<Duration> get bufferedPositionStream => _bufferedPositions.stream;
  Stream<Duration?> get durationStream => _durations.stream;
  Stream<LemonAudioSettings> get settingsStream => _settingsController.stream;
  LemonAudioSettings get settings => _settings;

  Future<void> initialize() async {
    _settings = config.settings;
    _validateVolume(_settings.duckVolume);
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
    mediaItem.add(_track!.toMediaItem());
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

  Future<void> updateLyric(
    String? lyric, {
    LemonLyricMode mode = LemonLyricMode.appOnly,
  }) async {
    _lyrics.add(lyric);
    final track = _track;
    if (track != null && mode == LemonLyricMode.bluetoothTitle) {
      mediaItem.add(
        track.toMediaItem(
          titleOverride: lyric == null || lyric.isEmpty ? null : lyric,
        ),
      );
    }
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
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          state.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
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
