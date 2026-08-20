# BYD DiLink 仪表音乐适配参考

> 状态：调研记录，尚未在实车验证。本文用于后续实现参考，不代表所有
> BYD 车型、DiLink 版本或固件均支持相同能力。

## 目标

为 Lemon Audio 增加可选的 BYD DiLink 适配层，把框架已有的媒体信息、
播放状态、播放进度和歌词同步到比亚迪原厂仪表音乐区域。

适配必须独立于标准 `MediaSession`、AVRCP、Android Auto 和 CarPlay；在
非 BYD 设备、无权限或固件不支持时应安全回退，不影响正常播放。

## 当前结论

普通 Android 媒体通知或 `MediaSession` 能驱动中控通知、锁屏和蓝牙
AVRCP，但部分 DiLink 仪表不会直接订阅这些数据。公开资料显示，BYD 提供
了专用仪表设备类：

```java
android.hardware.bydauto.instrument.BYDAutoInstrumentDevice
```

与音乐相关的方法：

```java
int sendMusicState(int state);
int sendMusicPlaybackProgress(int progress);
int sendMusicSource(int source);
int sendMusicName(String name);
```

已整理的状态常量：

```text
MUSIC_PLAY
MUSIC_PAUSE
MUSIC_STOP
```

已整理的来源常量：

```text
MUSIC_SOURCE_KOALA
MUSIC_SOURCE_KUWO
MUSIC_SOURCE_VIDEO
MUSIC_SOURCE_OTHERS
```

方法签名和常量来自社区对 BYD SDK/API 的整理，仍需用目标车辆 SDK 或
反射结果确认实际数值、返回码以及 `progress` 的单位。

## 熊猫音乐助手的参考意义

“远方的小熊猫音乐助手”能够把第三方音乐应用的信息同步到 BYD 仪表。
其公开安装说明要求启用通知监听器，并授予日志读取权限：

```bash
adb shell cmd notification allow_listener \
  com.littlepanda.bydmusic/com.littlepanda.bydmusic.NotificationListener

adb shell pm grant \
  com.littlepanda.bydmusic android.permission.READ_LOGS
```

它还提供普通包名版和酷狗包名版。

### 较可信的推断

其整体链路可能为：

```text
QQ音乐 / 网易云 / Poweramp 等
              ↓
NotificationListenerService
              ↓
解析歌曲名称、播放状态和进度
              ↓
BYDAutoInstrumentDevice
              ↓
BYD 原厂仪表音乐区域
```

酷狗包名版更可能用于让 DiLink 将应用识别为默认音乐应用，从而接收“小迪”
语音控制、桌面组件或预装音乐源路由；它不应被视为调用仪表 API 的必要条件。
普通包名版本也具备音乐助手能力，是支持这一判断的重要现象。

以上为根据公开安装说明和功能表现作出的推断，并非来自熊猫音乐助手源码。

## 建议架构

不要把 BYD 私有实现直接放进 `lemon_audio` 核心逻辑。建议形成可选平台适配：

```text
lemon_audio
├── 标准 MediaSession / AVRCP / 系统媒体控制
└── BYD adapter（可选）
    ├── DiLink 能力探测
    ├── 仪表音乐信息
    └── 后续可选语音助手接入
```

初期可在 Android 原生目录中隔离实现，成熟后再拆分为
`lemon_audio_byd` 包。

### 建议的 Dart API

```dart
enum LemonBydInstrumentCapability {
  unavailable,
  permissionMissing,
  available,
  unsupportedFirmware,
}

enum LemonBydInstrumentDisplayMode {
  track,
  lyric,
}

final capability = await audio.getBydInstrumentCapability();

await audio.setBydInstrumentEnabled(true);
await audio.setBydInstrumentDisplayMode(
  LemonBydInstrumentDisplayMode.track,
);
```

业务继续使用统一入口：

```dart
await audio.setTrack(track);
audio.setDuration(duration);
audio.setPosition(position);
audio.setBufferedPosition(bufferedPosition);
audio.setLyric(lyric);
```

BYD adapter 订阅这些状态并转换为仪表调用，业务不应直接调用 BYD API。

### 建议映射

| Lemon Audio 事件 | BYD 调用 |
| --- | --- |
| 切换歌曲 | `sendMusicSource(MUSIC_SOURCE_OTHERS)` + `sendMusicName(...)` |
| 播放 | `sendMusicState(MUSIC_PLAY)` |
| 暂停 | `sendMusicState(MUSIC_PAUSE)` |
| 停止 | `sendMusicState(MUSIC_STOP)` |
| 更新位置 | `sendMusicPlaybackProgress(...)` |
| 当前歌词 | 歌词模式下调用 `sendMusicName(lyric)` |

歌词模式复用了仪表的音乐名称字段，不是 BYD 公开的同步歌词协议。退出歌词
模式、歌词为空、停止播放或切歌时必须恢复原始歌曲名称。

## Android 原生实现建议

为避免普通 Android 构建依赖 BYD 修改版 `android.jar`，优先通过反射加载：

```java
Class<?> type = Class.forName(
    "android.hardware.bydauto.instrument.BYDAutoInstrumentDevice"
);
```

后续需要在实车确认：

1. 单例获取方法的准确签名，例如 `getInstance(Context)`。
2. 四个音乐方法是否为 public，以及参数和返回值是否与文档一致。
3. 常量的真实整数值。
4. `sendMusicPlaybackProgress` 使用秒、毫秒、百分比还是其他单位。
5. 调用线程要求和最小更新间隔。
6. 切换音源、倒车、导航播报、来电后是否需要重新发送状态。

所有反射异常都必须转换为 capability/error 状态，不能影响播放器主流程。

## 权限

社区资料记录了以下 BYD 仪表权限：

```text
android.permission.BYDAUTO_INSTRUMENT_COMMON
android.permission.BYDAUTO_INSTRUMENT_GET
android.permission.BYDAUTO_INSTRUMENT_SET
```

不同固件可能把 `COMMON` 作为可授予权限，把 `GET/SET` 设为签名权限，也可能
在服务端继续校验调用 UID、签名或包名白名单。候选的宿主声明为：

```xml
<uses-permission
    android:name="android.permission.BYDAUTO_INSTRUMENT_COMMON" />
```

候选的实车测试命令为：

```bash
adb shell pm grant <applicationId> \
  android.permission.BYDAUTO_INSTRUMENT_COMMON
```

不能假定该命令在所有固件有效。不得通过伪装酷狗包名、复制第三方签名或绕过
系统权限作为正式实现方案。

## 语音助手应独立处理

“设置为默认播放器”和“向仪表发送音乐信息”是两项能力。后续如果接入小迪，
应设计独立模块：

```dart
LemonAudioCallbacks(
  onPlay: player.play,
  onPause: player.pause,
  onNext: player.next,
  onPrevious: player.previous,
  onSearchAndPlay: searchAndPlay,
);
```

优先研究官方默认音乐应用注册、媒体 Intent 和 DiLink SDK。只有目标固件确实
按预装包名硬编码时，才把它记录为固件限制；正式框架不伪装其他应用包名。

## 安全边界

第一版只允许调用四个音乐信息方法。不得在该适配器中：

- 写入车辆控制、动力、车身或驾驶模式数据；
- 发送未经确认的 CAN/SPI 指令；
- 接管或覆盖 ADAS、故障警告和导航安全界面；
- 因适配器异常阻塞播放线程；
- 在不支持的设备上持续重试私有服务。

仪表适配失败时，标准媒体通知、蓝牙 AVRCP 和播放器必须继续工作。

## 实车验证清单

- [ ] 记录车型、年份、国内/海外版本、DiLink 版本和固件号。
- [ ] 用反射确认类、获取方法、常量和音乐方法。
- [ ] 验证无 BYD 权限时的返回值或异常。
- [ ] 验证 `COMMON` 权限能否通过 `pm grant` 获取。
- [ ] 验证普通应用包名能否显示仪表信息。
- [ ] 验证播放、暂停、停止状态。
- [ ] 确认 progress 单位及有效范围。
- [ ] 验证中文、英文、emoji 和长文本截断。
- [ ] 验证歌词更新频率，避免仪表闪烁或卡死。
- [ ] 验证切歌、来电、导航播报、倒车和重新上电。
- [ ] 验证关闭适配器后原厂媒体源能恢复显示。
- [ ] 确认不会影响故障、ADAS 和安全提示。

## 参考资料

1. BYD-dev 仪表 API 整理：
   <https://github.com/ID-VerNe/BYD-dev/blob/master/docs/modules/09-instrument.md>
2. BYD-dev API 与权限总览：
   <https://github.com/ID-VerNe/BYD-dev/blob/master/docs/README.md>
3. byd-dolphin-hacking BYDAuto 权限研究：
   <https://github.com/wheregoes/byd-dolphin-hacking/blob/master/docs/bydauto-api.md>
4. 熊猫音乐助手公开安装说明：
   <https://www.bydmax.com/apps/280.html>
5. 熊猫音乐助手版本记录：
   <https://www.27bj.cn/archives/24.html>
6. BYD DashCast 仪表投屏研究（与原厂音乐信息通道不同）：
   <https://github.com/Kiroha/byd-dashcast>
7. BYD DiLink 开发者文档入口：
   <https://www.byd.auto/addons/cms/document/index?document_type_id=6>

## 待补充资料

- 目标车型上 `BYDAutoInstrumentDevice` 的反射输出。
- 四个音乐常量及来源常量的整数值。
- progress 参数的单位。
- DiLink 官方 SDK 中的调用示例和权限声明。
- 普通包名与默认音乐应用注册的对照测试。
- 是否存在比 `sendMusicName` 更完整的歌手、专辑、总时长或歌词接口。
