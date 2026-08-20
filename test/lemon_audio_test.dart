import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_audio/lemon_audio.dart';

void main() {
  test('track metadata can be converted and overridden', () {
    const track = LemonAudioTrack(id: '1', title: 'Song', artist: 'Artist');
    expect(track.toMediaItem().artist, 'Artist');
    expect(track.toMediaItem(titleOverride: 'A lyric').title, 'A lyric');
  });

  test('duration can be discovered after metadata', () {
    const track = LemonAudioTrack(id: '1', title: 'Song');
    expect(track.duration, isNull);
    expect(
      track.copyWith(duration: const Duration(minutes: 4)).duration,
      const Duration(minutes: 4),
    );
  });

  test('audio policies have music-player defaults', () {
    const config = LemonAudioConfig();
    expect(config.allowConcurrentPlayback, isFalse);
    expect(config.audioInterruptionEnabled, isTrue);
    expect(config.interruptionBehavior, LemonInterruptionBehavior.pause);
  });
}
