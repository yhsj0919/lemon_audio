library;

import 'package:audio_service/audio_service.dart';

import 'src/config.dart';
import 'src/handler.dart';
import 'src/models.dart';
import 'src/player.dart';

export 'src/config.dart';
export 'src/models.dart';
export 'src/player.dart';

class LemonAudio {
  LemonAudio._(this._handler);
  final LemonAudioHandler _handler;

  static Future<LemonAudio> initialize({
    required LemonAudioPlayer player,
    LemonAudioConfig config = const LemonAudioConfig(),
  }) async {
    final handler = await AudioService.init<LemonAudioHandler>(
      builder: () => LemonAudioHandler(player, config),
      config: config.serviceConfig,
    );
    await handler.initialize();
    return LemonAudio._(handler);
  }

  Stream<PlaybackState> get playbackState => _handler.playbackState;
  Stream<MediaItem?> get mediaItem => _handler.mediaItem;
  Stream<List<MediaItem>> get queue => _handler.queue;
  Stream<String?> get lyricStream => _handler.lyricStream;
  Stream<Duration> get positionStream => _handler.positionStream;
  Stream<Duration> get bufferedPositionStream =>
      _handler.bufferedPositionStream;
  Stream<Duration?> get durationStream => _handler.durationStream;
  Stream<LemonAudioSettings> get settingsStream => _handler.settingsStream;
  LemonAudioSettings get settings => _handler.settings;
  Future<void> setTrack(LemonAudioTrack track) => _handler.setTrack(track);
  Future<void> setTracks(List<LemonAudioTrack> tracks) =>
      _handler.setTracks(tracks);
  void setDuration(Duration? duration) => _handler.setDuration(duration);
  void setPosition(Duration position) => _handler.setPosition(position);
  void setBufferedPosition(Duration position) =>
      _handler.setBufferedPosition(position);
  Future<void> setAllowConcurrentPlayback(bool value) =>
      _handler.setAllowConcurrentPlayback(value);
  void setAudioInterruptionEnabled(bool value) =>
      _handler.setAudioInterruptionEnabled(value);
  void setInterruptionBehavior(LemonInterruptionBehavior value) =>
      _handler.setInterruptionBehavior(value);
  void setDuckVolume(double value) => _handler.setDuckVolume(value);
  void setResumeAfterInterruption(bool value) =>
      _handler.setResumeAfterInterruption(value);
  Future<void> updateLyric(
    String? lyric, {
    LemonLyricMode mode = LemonLyricMode.appOnly,
  }) => _handler.updateLyric(lyric, mode: mode);
  Future<void> play() => _handler.play();
  Future<void> pause() => _handler.pause();
  Future<void> stop() => _handler.stop();
  Future<void> seek(Duration position) => _handler.seek(position);
  Future<void> skipToNext() => _handler.skipToNext();
  Future<void> skipToPrevious() => _handler.skipToPrevious();
  Future<void> dispose() => _handler.disposeHandler();
}
