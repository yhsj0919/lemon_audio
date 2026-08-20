import 'models.dart';

/// Implement this adapter with any audio engine. Lemon Audio owns no player.
abstract class LemonAudioPlayer {
  Stream<LemonPlayerState> get stateStream;
  LemonPlayerState get currentState;
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> skipToNext() async {}
  Future<void> skipToPrevious() async {}
  Future<void> skipToQueueItem(int index) async {}
  Future<void> setSpeed(double speed) async {}
  Future<void> setVolume(double volume) async {}
  Future<void> dispose() async {}
}
