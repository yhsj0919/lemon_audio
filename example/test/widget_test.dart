import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_audio/lemon_audio.dart';

void main() {
  test('example can create notification metadata', () {
    const track = LemonAudioTrack(id: 'demo', title: 'Demo');
    expect(track.toMediaItem().title, 'Demo');
  });
}
