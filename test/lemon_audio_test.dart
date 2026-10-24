import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_audio/lemon_audio.dart';
import 'package:lemon_audio/src/handler.dart';

void main() {
  test(
    'previous and next remain visible unless the host changes the buttons',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final handler = LemonAudioHandler(
        _FakePlayer(),
        const LemonAudioConfig(),
      );
      await handler.initialize();
      addTearDown(handler.disposeHandler);
      expect(
        handler.playbackState.value.controls.map((item) => item.action.name),
        ['skipToPrevious', 'play', 'skipToNext', 'stop'],
      );
      await handler.setTrack(
        const LemonAudioTrack(id: '1', title: 'Only song'),
      );
      expect(
        handler.playbackState.value.controls.map((item) => item.action.name),
        ['skipToPrevious', 'play', 'skipToNext', 'stop'],
      );
      await handler.setNotificationButtons([LemonNotificationButton.playPause]);
      expect(
        handler.playbackState.value.controls.map((item) => item.action.name),
        ['play'],
      );
    },
  );

  test(
    'lyric titles throttle internally and retain only the latest line',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final handler = LemonAudioHandler(
        _FakePlayer(),
        const LemonAudioConfig(),
      );
      await handler.initialize();
      addTearDown(handler.disposeHandler);
      await handler.setTrack(const LemonAudioTrack(id: '1', title: 'Song'));
      await handler.updateLyric('A', mode: LemonLyricMode.bluetoothTitle);
      await handler.updateLyric('B', mode: LemonLyricMode.bluetoothTitle);
      await handler.updateLyric('C', mode: LemonLyricMode.bluetoothTitle);
      expect(handler.mediaItem.value!.title, 'A');
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      expect(handler.mediaItem.value!.title, 'C');
      handler.setDuration(const Duration(minutes: 3));
      expect(handler.mediaItem.value!.title, 'C');
      await handler.updateLyric('pending', mode: LemonLyricMode.bluetoothTitle);
      await handler.updateLyric(null, mode: LemonLyricMode.bluetoothTitle);
      expect(handler.mediaItem.value!.title, 'Song');
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      expect(handler.mediaItem.value!.title, 'Song');
    },
  );

  test('changing track cancels pending lyric titles', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final handler = LemonAudioHandler(_FakePlayer(), const LemonAudioConfig());
    await handler.initialize();
    addTearDown(handler.disposeHandler);
    await handler.setTrack(const LemonAudioTrack(id: '1', title: 'First'));
    await handler.updateLyric('A', mode: LemonLyricMode.bluetoothTitle);
    await handler.updateLyric('pending', mode: LemonLyricMode.bluetoothTitle);
    await handler.setTrack(const LemonAudioTrack(id: '2', title: 'Second'));
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(handler.mediaItem.value!.title, 'Second');
  });

  test('track metadata can be converted and overridden', () {
    const track = LemonAudioTrack(id: '1', title: 'Song', artist: 'Artist');
    expect(track.toMediaItem().artist, 'Artist');
    expect(track.toMediaItem(titleOverride: 'A lyric').title, 'A lyric');
    expect(track.toMediaItem(titleOverride: 'A lyric').artist, 'Song · Artist');
    expect(
      const LemonAudioTrack(
        id: '2',
        title: 'Solo',
      ).toMediaItem(titleOverride: 'Line').artist,
      'Solo',
    );
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
