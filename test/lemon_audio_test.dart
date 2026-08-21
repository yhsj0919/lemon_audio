import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_audio/lemon_audio.dart';
import 'package:lemon_audio/src/handler.dart';

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

  test('notification buttons have useful defaults and can be customised', () {
    const defaults = LemonAudioConfig();
    expect(defaults.notificationButtons, const [
      LemonNotificationButton.previous,
      LemonNotificationButton.playPause,
      LemonNotificationButton.next,
      LemonNotificationButton.stop,
    ]);
    expect(
      defaults.notificationButtons.where((button) => button.androidCompact),
      const [
        LemonNotificationButton.previous,
        LemonNotificationButton.playPause,
        LemonNotificationButton.next,
      ],
    );

    const custom = LemonAudioConfig(
      notificationButtons: [
        LemonNotificationButton.playPause,
        LemonNotificationButton.custom(
          id: 'favorite',
          androidIcon: 'drawable/ic_favorite',
          label: 'Favorite',
          androidCompact: true,
          onPressed: _noButtonUpdate,
        ),
      ],
    );
    expect(custom.notificationButtons, hasLength(2));
    expect(custom.notificationButtons.last.id, 'favorite');
  });

  test(
    'custom notification callback can replace itself in real time',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      var pressed = 0;

      LemonNotificationButton favoriteButton(bool selected) =>
          LemonNotificationButton.custom(
            id: 'favorite',
            androidIcon: selected
                ? 'drawable/ic_favorite'
                : 'drawable/ic_favorite_border',
            label: selected ? 'Unfavorite' : 'Favorite',
            onPressed: () {
              pressed++;
              return favoriteButton(!selected);
            },
          );

      final handler = LemonAudioHandler(
        _FakePlayer(),
        LemonAudioConfig(notificationButtons: [favoriteButton(false)]),
      );
      await handler.initialize();

      await handler.customAction('lemon_notification:favorite');

      expect(pressed, 1);
      expect(handler.playbackState.value.controls.single.label, 'Unfavorite');
      expect(
        handler.playbackState.value.controls.single.androidIcon,
        'drawable/ic_favorite',
      );
      await handler.disposeHandler();
    },
  );
}

LemonNotificationButton? _noButtonUpdate() => null;

class _FakePlayer extends LemonAudioPlayer {
  @override
  LemonPlayerState get currentState => const LemonPlayerState.idle();

  @override
  Stream<LemonPlayerState> get stateStream => const Stream.empty();

  @override
  Future<void> pause() async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> stop() async {}
}
