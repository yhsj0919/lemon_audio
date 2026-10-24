import 'package:audio_service_platform_interface/audio_service_platform_interface.dart';
import 'package:audio_service_win/audio_service_win.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final platform = AudioServiceWin();
  final calls = <MethodCall>[];
  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(platform.methodChannel, (call) async {
      calls.add(call);
      return null;
    });
  });
  tearDown(
    () => messenger.setMockMethodCallHandler(platform.methodChannel, null),
  );

  test('lyric changes retain the same local artwork cache path', () async {
    for (final title in ['Line A', 'Line B']) {
      await platform.setMediaItem(
        SetMediaItemRequest(
          mediaItem: MediaItemMessage(
            id: 'track',
            title: title,
            artist: 'Song · Artist',
            artUri: Uri.parse('https://example.invalid/cover.jpg'),
            extras: {'artCacheFile': r'C:\covers\cover.jpg'},
          ),
        ),
      );
    }
    expect(calls.map((call) => call.arguments['title']), ['Line A', 'Line B']);
    expect(calls.map((call) => call.arguments['artUri']), [
      r'C:\covers\cover.jpg',
      r'C:\covers\cover.jpg',
    ]);
  });

  test('missing artwork sends an empty URI, never the string null', () async {
    await platform.setMediaItem(
      SetMediaItemRequest(
        mediaItem: const MediaItemMessage(id: 'track', title: 'Song'),
      ),
    );
    expect(calls.single.arguments['artUri'], '');
  });
}
