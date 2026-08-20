# lemon_audio

`lemon_audio` connects any Flutter audio player to system media controls. It
does not decode or play audio itself.

Implement `LemonAudioPlayer` around just_audio, media_kit, VLC or a native
engine, then initialise it once near the start of `main`:

```dart
WidgetsFlutterBinding.ensureInitialized();
final lemon = await LemonAudio.initialize(player: MyPlayerAdapter());

await lemon.setTrack(const LemonAudioTrack(
  id: 'song-1',
  title: 'Lemon Tree',
  artist: 'Artist',
));
await lemon.play();
```

The duration is optional when metadata first becomes available. Report each
value independently as the player discovers or changes it:

```dart
await lemon.setTrack(const LemonAudioTrack(id: 'song-1', title: 'Lemon Tree'));

// Usually emitted once after the media has loaded.
lemon.setDuration(const Duration(minutes: 4));

// Usually emitted repeatedly while loading/playing.
lemon.setPosition(const Duration(seconds: 30));
lemon.setBufferedPosition(const Duration(seconds: 50));
```

`setPosition` only reports the real player position. Use `seek` to request that
the injected player jumps to a new position.

## Audio focus and interruptions

Defaults can be supplied during initialisation:

```dart
const LemonAudioConfig(
  allowConcurrentPlayback: true,
  audioInterruptionEnabled: true,
  interruptionBehavior: LemonInterruptionBehavior.duck,
  duckVolume: 0.2,
  resumeAfterInterruption: true,
)
```

Every policy can also be changed later:

```dart
await lemon.setAllowConcurrentPlayback(false);
lemon.setAudioInterruptionEnabled(true);
lemon.setInterruptionBehavior(LemonInterruptionBehavior.pause);
lemon.setDuckVolume(0.25);
lemon.setResumeAfterInterruption(true);
```

Runtime changes are available from `settings` and `settingsStream`.

## Platform support

| Platform | System integration | Host setup |
| --- | --- | --- |
| Android | notification, foreground service, media buttons, audio focus | permissions/service/activity; see `audio_service` setup |
| iOS | lock screen, remote commands, audio session | enable Background Audio in the Runner target |
| macOS | Now Playing, remote commands, audio session | enable audio capability when sandboxed |
| Windows | SMTC media center and hardware media keys via `audio_service_win` | application identity is optional for a custom display name |
| Linux | desktop media controls via `audio_service_mpris` | an MPRIS-compatible desktop session |
| Web | browser Media Session API | HTTPS and browser Media Session support |

`allowConcurrentPlayback` and automatic interruption handling use
`audio_session` on Android, iOS, macOS and Web. Windows and Linux expose the
same API but actual focus/ducking is controlled by the injected player and the
desktop audio server because those platforms do not provide the same mobile
audio-focus contract.

With recent Visual Studio releases, `audio_service_win 0.0.3` also needs this
line in the host application's `windows/CMakeLists.txt` until that platform
package migrates away from experimental coroutines:

```cmake
add_definitions(-D_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS)
```

The adapter emits `LemonPlayerState` whenever playing, buffering, position,
speed or queue index changes. Notification, lock-screen, headset and Bluetooth
commands are routed back to the adapter methods.

Change notification metadata with `lemon.setTrack(updatedTrack)`. Lyrics stay
app-local by default. An opt-in compatibility mode updates the AVRCP title:

```dart
await lemon.updateLyric('Hello', mode: LemonLyricMode.bluetoothTitle);
```

This is not a standard synchronized-lyrics protocol and receiver support
varies. Follow the `audio_service` Android manifest and iOS background-audio
setup in the host application.

