# lemon_audio

`lemon_audio` 用于把任意 Flutter 音频播放器接入系统媒体控制。它本身不负责
解码或播放音频。

为 just_audio、media_kit、VLC 或原生播放引擎实现 `LemonAudioPlayer` 适配器，
然后在 `main` 启动阶段初始化一次：

```dart
WidgetsFlutterBinding.ensureInitialized();
final lemon = await LemonAudio.initialize(player: MyPlayerAdapter());

await lemon.setTrack(const LemonAudioTrack(
  id: 'song-1',
  title: 'Lemon Tree',
  artist: '歌手',
));
await lemon.play();
```

媒体信息首次可用时可以暂时不提供时长。播放引擎获得或更新数据后，分别上报：

```dart
await lemon.setTrack(const LemonAudioTrack(
  id: 'song-1',
  title: 'Lemon Tree',
));

lemon.setDuration(const Duration(minutes: 4));
lemon.setPosition(const Duration(seconds: 30));
lemon.setBufferedPosition(const Duration(seconds: 50));
```

`setPosition` 只用于上报真实播放位置。需要跳转播放位置时，请调用 `seek`。

## 宿主应用配置

`lemon_audio` 是库，使用它的 Flutter 应用是“宿主应用”。平台配置应写在宿主
应用的平台目录中，而不是业务 Dart 代码或 Pub 缓存目录中。

## Android 配置

### 1. 配置 AndroidManifest.xml

在宿主应用的 `android/app/src/main/AndroidManifest.xml` 中添加以下内容。保留
现有 Activity 的主题、Intent Filter 和 Flutter metadata：

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />

    <!-- targetSdkVersion 为 34 或更高时必须添加。 -->
    <uses-permission
        android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />

    <application ...>
        <activity android:name=".MainActivity" ...>
            <!-- 保留宿主应用原有内容。 -->
        </activity>

        <service
            android:name="com.ryanheise.audioservice.AudioService"
            android:exported="true"
            android:foregroundServiceType="mediaPlayback"
            tools:ignore="Instantiatable">
            <intent-filter>
                <action android:name="android.media.browse.MediaBrowserService" />
            </intent-filter>
        </service>

        <receiver
            android:name="com.ryanheise.audioservice.MediaButtonReceiver"
            android:exported="true"
            tools:ignore="Instantiatable">
            <intent-filter>
                <action android:name="android.intent.action.MEDIA_BUTTON" />
            </intent-filter>
        </receiver>
    </application>
</manifest>
```

Android 13 引入了 `POST_NOTIFICATIONS` 运行时权限，但媒体会话通知不依赖该
权限。只有宿主还会发布普通通知时，才需要声明并申请：

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

### 2. 配置 MainActivity

普通 Flutter Activity 应继承 `AudioServiceActivity`：

```kotlin
package com.example.my_app

import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity : AudioServiceActivity()
```

如果宿主必须使用 `FlutterFragmentActivity`，请改为继承
`AudioServiceFragmentActivity`。也可以在 Manifest 中直接使用
`com.ryanheise.audioservice.AudioServiceActivity`。

### 3. 初始化通知

```dart
WidgetsFlutterBinding.ensureInitialized();

final lemon = await LemonAudio.initialize(
  player: MyPlayerAdapter(),
  config: const LemonAudioConfig(
    androidNotificationChannelId: 'com.example.my_app.playback',
    androidNotificationChannelName: '音频播放',
    androidNotificationOngoing: true,
  ),
);
```

不要同时设置 `androidNotificationOngoing: true` 和
`stopForegroundOnPause: false`，`audio_service` 会拒绝该组合。

### 4. 上报真实播放状态

仅配置 Manifest 不会自动创建通知。播放器真正开始播放后，适配器必须发出
非 idle 状态：

```dart
states.add(const LemonPlayerState(
  playing: true,
  processingState: LemonProcessingState.ready,
  position: Duration(seconds: 12),
  bufferedPosition: Duration(seconds: 30),
));
```

- `playing: true` 配合 `ready`、`loading` 或 `buffering` 会创建或更新前台
  媒体通知。
- `playing: false` 会把媒体状态更新为暂停。
- `processingState: idle` 会停止服务并移除通知。
- 播放前应调用 `setTrack`；提供 `duration` 后才能显示完整进度条。

仓库中的 `example/lib/main.dart` 使用 `mpv_audio_kit` 播放 30 秒内置测试音频，
并持续用真实播放位置更新通知进度。

### 5. 蓝牙耳机与车机控制

宿主不需要另外监听 Android 的媒体按键。Manifest 中注册
`MediaButtonReceiver` 后，蓝牙耳机或车机发出的播放、暂停、上一首和下一首会
由 `lemon_audio` 转发到 `LemonAudioPlayer` 对应方法。

但宿主必须接入真实音频引擎，并遵守以下约定：

- 只通过 `lemon.play()`、`lemon.pause()` 等入口控制播放，或确保音频引擎的
  外部状态变化也会及时上报。
- `LemonAudioPlayer.play()` 和 `pause()` 执行后，必须通过 `stateStream` 发出
  最新的 `playing` 与 `processingState`；否则通知、锁屏和蓝牙设备会继续显示
  旧状态。
- 不要让另一个播放器同时长期占用音频焦点。默认配置会在播放时申请媒体音频
  焦点；设置 `allowConcurrentPlayback: true` 会放弃独占焦点，媒体键可能由
  系统交给其他播放器。
- 在真机上同时测试播放和暂停。部分 Android 厂商会根据实际 `AudioTrack`
  活动情况选择媒体会话，仅声明一个“正在播放”的模拟状态并不足以取得蓝牙
  媒体键。

仓库中的 Demo 使用 `mpv_audio_kit ^0.4.4` 播放内置测试音频，可用于验证通知
创建、进度刷新以及蓝牙播放/暂停。宿主接入 just_audio、media_kit、VLC 或
原生音频引擎时也应遵守相同的状态上报约定。

## 通知按钮

### 标准按钮

```dart
const LemonAudioConfig(
  notificationButtons: [
    LemonNotificationButton.previous,
    LemonNotificationButton.playPause,
    LemonNotificationButton.next,
    LemonNotificationButton.stop,
  ],
)
```

`playPause` 会根据实时播放状态自动切换播放和暂停。传入空列表可隐藏所有按钮。
每个按钮可通过 `androidCompact` 决定是否进入 Android 折叠通知，折叠通知最多
显示三个按钮：

```dart
LemonNotificationButton.standard(
  LemonStandardNotificationAction.next,
  androidCompact: false,
)
```

### 自定义按钮与回调

自定义按钮包含稳定的 `id`、Android 图标、文案和 `onPressed` 回调。回调可以
返回相同 ID 的新按钮，框架会自动替换并立即刷新通知。

下面示例把最后一个按钮设置为“收藏/取消收藏”：

```dart
var isFavorite = false;

LemonNotificationButton favoriteButton(bool selected) =>
    LemonNotificationButton.custom(
      id: 'favorite',
      androidIcon: selected
          ? 'drawable/ic_favorite'
          : 'drawable/ic_favorite_border',
      label: selected ? '取消收藏' : '收藏',
      onPressed: () async {
        final next = !selected;
        await favoritesRepository.setFavorite(next);
        isFavorite = next;
        return favoriteButton(next);
      },
    );

List<LemonNotificationButton> buildButtons() => [
  LemonNotificationButton.previous,
  LemonNotificationButton.playPause,
  LemonNotificationButton.next,
  favoriteButton(isFavorite),
];

final lemon = await LemonAudio.initialize(
  player: MyPlayerAdapter(),
  config: LemonAudioConfig(notificationButtons: buildButtons()),
);
```

如果收藏状态由应用内其他页面修改，可主动同步：

```dart
await lemon.setNotificationButtons(buildButtons());
```

按钮 ID 必须非空且不能重复。回调返回的替换按钮必须保持相同 ID。自定义按钮
回调运行在音频处理器中，应保持轻量，并自行处理业务异常。

### 自定义图标与 Release 资源压缩

自定义 Android 图标应放在宿主应用中：

```text
android/app/src/main/res/drawable/ic_favorite.xml
android/app/src/main/res/drawable/ic_favorite_border.xml
```

通知图标应使用透明背景和纯白图形。`audio_service` 根据 `androidIcon` 字符串
查找资源，Release 资源压缩器无法识别这种间接引用。因此宿主必须创建
`android/app/src/main/res/raw/keep.xml`：

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources xmlns:tools="http://schemas.android.com/tools"
    tools:keep="@drawable/ic_favorite,@drawable/ic_favorite_border" />
```

图标被裁剪后，Android 会抛出以下异常，并导致整个媒体通知无法显示：

```text
IllegalArgumentException: You must specify an icon resource id to build a CustomAction
```

`lemon_audio` 已自动保留内置的 `audio_service_*` 标准按钮图标；宿主只需保留
自己的自定义图标。自定义通知按钮必须同时使用 Debug 和 Release 构建验证。

## 音频焦点与中断

```dart
const LemonAudioConfig(
  allowConcurrentPlayback: true,
  audioInterruptionEnabled: true,
  interruptionBehavior: LemonInterruptionBehavior.duck,
  duckVolume: 0.2,
  resumeAfterInterruption: true,
)
```

运行时也可以修改：

```dart
await lemon.setAllowConcurrentPlayback(false);
lemon.setAudioInterruptionEnabled(true);
lemon.setInterruptionBehavior(LemonInterruptionBehavior.pause);
lemon.setDuckVolume(0.25);
lemon.setResumeAfterInterruption(true);
```

当前配置可通过 `settings` 和 `settingsStream` 获取。

## iOS 配置

在 Runner Target 的 **Signing & Capabilities** 中添加 **Background Modes**，
并启用 **Audio, AirPlay, and Picture in Picture**。对应的
`ios/Runner/Info.plist` 配置为：

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

宿主播放引擎仍需持续上报状态和媒体信息，控制中心及锁屏控制才能保持同步。

## 平台支持

| 平台 | 系统能力 | 宿主配置 |
| --- | --- | --- |
| Android | 通知、前台服务、媒体按钮、音频焦点 | 按本文配置权限、Service、Receiver 和 Activity |
| iOS | 锁屏控制、远程命令、音频会话 | Runner 启用 Background Audio |
| macOS | Now Playing、远程命令、音频会话 | 沙盒应用启用音频能力 |
| Windows | SMTC 媒体中心和硬件媒体键 | 自定义显示名称时可配置应用身份 |
| Linux | MPRIS 桌面媒体控制 | 使用兼容 MPRIS 的桌面会话 |
| Web | 浏览器 Media Session API | 使用 HTTPS 和支持该 API 的浏览器 |

较新的 Visual Studio 配合 `audio_service_win 0.0.3` 时，宿主应用的
`windows/CMakeLists.txt` 需要临时添加：

```cmake
add_definitions(-D_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS)
```

## 歌词与媒体信息

通过 `lemon.setTrack(updatedTrack)` 更新通知媒体信息。歌词默认只在应用内部
传递；可选兼容模式会把当前歌词写入 AVRCP 标题：

```dart
await lemon.updateLyric(
  'Hello',
  mode: LemonLyricMode.bluetoothTitle,
);
```

这不是标准同步歌词协议，实际显示效果取决于接收设备。
