import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lemon_audio/lemon_audio.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final audio = await LemonAudio.initialize(player: DemoPlayer());
  await audio.setTrack(
    const LemonAudioTrack(
      id: 'demo',
      title: 'Your custom player',
      artist: 'Lemon Audio',
    ),
  );
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
          builder: (context, snapshot) => IconButton(
            iconSize: 72,
            icon: Icon(
              snapshot.data?.playing == true ? Icons.pause : Icons.play_arrow,
            ),
            onPressed: snapshot.data?.playing == true
                ? audio.pause
                : audio.play,
          ),
        ),
      ),
    ),
  );
}

/// Replace this with an adapter around the actual audio engine.
class DemoPlayer extends LemonAudioPlayer {
  final _states = StreamController<LemonPlayerState>.broadcast();
  LemonPlayerState _state = const LemonPlayerState.idle();

  @override
  LemonPlayerState get currentState => _state;
  @override
  Stream<LemonPlayerState> get stateStream => _states.stream;

  void _emit(bool playing) {
    _state = LemonPlayerState(
      playing: playing,
      processingState: LemonProcessingState.ready,
    );
    _states.add(_state);
  }

  @override
  Future<void> play() async => _emit(true);
  @override
  Future<void> pause() async => _emit(false);
  @override
  Future<void> stop() async => _emit(false);
  @override
  Future<void> seek(Duration position) async {}
  @override
  Future<void> skipToNext() async {}
  @override
  Future<void> skipToPrevious() async {}
  @override
  Future<void> skipToQueueItem(int index) async {}
  @override
  Future<void> setSpeed(double speed) async {}
  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<void> dispose() => _states.close();
}
