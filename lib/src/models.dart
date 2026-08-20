import 'package:audio_service/audio_service.dart';

class LemonAudioTrack {
  const LemonAudioTrack({
    required this.id,
    required this.title,
    this.album,
    this.artist,
    this.duration,
    this.artUri,
    this.extras = const {},
  });
  final String id;
  final String title;
  final String? album;
  final String? artist;
  final Duration? duration;
  final Uri? artUri;
  final Map<String, dynamic> extras;

  LemonAudioTrack copyWith({Duration? duration, bool clearDuration = false}) =>
      LemonAudioTrack(
        id: id,
        title: title,
        album: album,
        artist: artist,
        duration: clearDuration ? null : duration ?? this.duration,
        artUri: artUri,
        extras: extras,
      );

  MediaItem toMediaItem({String? titleOverride}) => MediaItem(
    id: id,
    title: titleOverride ?? title,
    album: album,
    artist: artist,
    duration: duration,
    artUri: artUri,
    extras: extras,
  );
}

enum LemonProcessingState { idle, loading, buffering, ready, completed, error }

class LemonPlayerState {
  const LemonPlayerState({
    required this.playing,
    required this.processingState,
    this.position = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.speed = 1,
    this.queueIndex,
    this.errorMessage,
  });
  const LemonPlayerState.idle()
    : this(playing: false, processingState: LemonProcessingState.idle);
  final bool playing;
  final LemonProcessingState processingState;
  final Duration position;
  final Duration bufferedPosition;
  final double speed;
  final int? queueIndex;
  final String? errorMessage;

  LemonPlayerState copyWith({
    bool? playing,
    LemonProcessingState? processingState,
    Duration? position,
    Duration? bufferedPosition,
    double? speed,
    int? queueIndex,
    String? errorMessage,
  }) => LemonPlayerState(
    playing: playing ?? this.playing,
    processingState: processingState ?? this.processingState,
    position: position ?? this.position,
    bufferedPosition: bufferedPosition ?? this.bufferedPosition,
    speed: speed ?? this.speed,
    queueIndex: queueIndex ?? this.queueIndex,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}

enum LemonLyricMode { appOnly, bluetoothTitle }
