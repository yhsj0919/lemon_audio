import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lemon_audio/lemon_audio.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart' as mpv;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  mpv.MpvAudioKit.ensureInitialized();
  final player = MpvDemoPlayer();
  await player.initialize();
  final audio = await LemonAudio.initialize(
    player: player,
    config: const LemonAudioConfig(androidNotificationOngoing: true),
  );
  await audio.setTrack(
    const LemonAudioTrack(
      id: 'demo',
      title: 'Notification progress demo',
      artist: 'Lemon Audio',
      album: 'Android media notification test',
      duration: MpvDemoPlayer.duration,
    ),
  );
  await audio.play();
  runApp(DemoApp(audio: audio));
}

class DemoApp extends StatelessWidget {
  const DemoApp({required this.audio, super.key});
  final LemonAudio audio;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: StreamBuilder(
          stream: audio.playbackState,
          builder: (context, snapshot) {
            final state = snapshot.data;
            final position = state?.updatePosition ?? Duration.zero;
            final playing = state?.playing == true;
            return Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Android notification progress demo',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  LinearProgressIndicator(
                    value:
                        position.inMilliseconds /
                        MpvDemoPlayer.duration.inMilliseconds,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_formatDuration(position)} / '
                    '${_formatDuration(MpvDemoPlayer.duration)}',
                  ),
                  const SizedBox(height: 16),
                  IconButton(
                    iconSize: 72,
                    icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                    onPressed: playing ? audio.pause : audio.play,
                  ),
                  Text(
                    playing
                        ? 'Playing — pull down the notification shade'
                        : 'Tap play to create the media notification',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}

String _formatDuration(Duration value) {
  final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

/// 使用 mpv_audio_kit 输出真实音频的 lemon_audio 适配器。
class MpvDemoPlayer extends LemonAudioPlayer {
  static const duration = Duration(seconds: 30);
  static const _source = 'asset:///assets/test-tone.wav';

  final _player = mpv.Player();
  final _states = StreamController<LemonPlayerState>.broadcast();
  final _subscriptions = <StreamSubscription<dynamic>>[];
  LemonPlayerState _state = const LemonPlayerState.idle();
  bool _loaded = false;

  Future<void> initialize() async {
    _subscriptions.addAll([
      _player.stream.playbackState.listen((_) => _emit()),
      _player.stream.playWhenReady.listen((_) => _emit()),
      _player.stream.position.listen((_) => _emit()),
      _player.stream.buffer.listen((_) => _emit()),
    ]);
    await _load();
  }

  Future<void> _load() async {
    await _player.open(const mpv.Media(_source), play: false);
    _loaded = true;
    _emit();
  }

  @override
  LemonPlayerState get currentState => _state;
  @override
  Stream<LemonPlayerState> get stateStream => _states.stream;

  void _emit() {
    final value = _player.state;
    _state = LemonPlayerState(
      playing: value.playWhenReady,
      processingState: _processingState(value),
      position: value.position,
      bufferedPosition: value.buffer,
    );
    _states.add(_state);
  }

  LemonProcessingState _processingState(mpv.PlayerState value) {
    if (value.completed) return LemonProcessingState.completed;
    if (value.buffering) return LemonProcessingState.buffering;
    if (value.duration == Duration.zero) return LemonProcessingState.loading;
    return LemonProcessingState.ready;
  }

  @override
  Future<void> play() async {
    if (!_loaded) await _load();
    if (_player.state.completed) {
      await _player.seek(Duration.zero, relative: false, exact: true);
    }
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _loaded = false;
  }

  @override
  Future<void> seek(Duration position) async {
    final target = position.isNegative
        ? Duration.zero
        : position > duration
        ? duration
        : position;
    await _player.seek(target, relative: false, exact: true);
  }

  @override
  Future<void> skipToNext() async {}
  @override
  Future<void> skipToPrevious() async {}
  @override
  Future<void> skipToQueueItem(int index) async {}
  @override
  Future<void> setSpeed(double speed) => _player.setRate(speed);
  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume * 100);
  @override
  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _player.dispose();
    await _states.close();
  }
}
