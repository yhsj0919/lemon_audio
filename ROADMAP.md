# Lemon Audio 开发计划

## 项目定位

Lemon Audio 是播放器无关的系统音频集成框架。它不负责解码或播放音频，
而是把任意播放器接入后台播放、系统媒体控制、通知、锁屏、耳机、蓝牙、
桌面媒体中心和可选车机扩展。

## 已完成

### 核心播放器桥接

- [x] 使用 `audio_service ^0.18.19`。
- [x] 使用 `audio_session ^0.2.4`。
- [x] 提供 `LemonAudioPlayer` 自定义播放器适配接口。
- [x] 框架不内置具体播放器。
- [x] 支持播放、暂停、停止和跳转进度。
- [x] 支持上一首、下一首和跳转队列项目。
- [x] 支持播放速度和播放器音量回调入口。
- [x] 将系统媒体按键操作转发给自定义播放器。

### 媒体信息与进度

- [x] `setTrack` 设置歌曲名称、歌手、专辑、封面和可选时长。
- [x] `setTracks` 设置系统播放队列。
- [x] `setDuration` 独立设置或清除总时长。
- [x] `setPosition` 独立上报播放进度。
- [x] `setBufferedPosition` 独立上报缓冲进度。
- [x] `seek` 与 `setPosition` 职责分离，避免回调循环。
- [x] 切歌时自动清零播放进度和缓冲进度。
- [x] 提供媒体信息、系统播放状态、时长、播放位置和缓冲位置流。
- [x] 拒绝负数进度和非法避让音量。

### 后台、耳机与音频焦点

- [x] Android 前台媒体服务基础接入。
- [x] iOS 后台音频示例配置。
- [x] 标准通知、锁屏和系统媒体控制。
- [x] 耳机拔出自动暂停。
- [x] 系统音频中断监听。
- [x] 支持中断时暂停或降低音量。
- [x] 支持配置避让音量。
- [x] 支持配置避让结束后是否恢复播放。
- [x] 支持允许或禁止与其他应用同时播放。
- [x] 音频策略可在初始化时设置。
- [x] 音频策略可在运行时修改。
- [x] 提供当前音频策略和策略变更流。

### 歌词

- [x] 提供应用内歌词流。
- [x] 提供实验性的 AVRCP 标题复用模式。
- [x] 蓝牙歌词模式可以把当前歌词写入媒体标题。
- [x] 歌词为空时恢复歌曲名称。

### 平台支持

- [x] Android：`audio_service` + `audio_session`。
- [x] iOS：`audio_service` + `audio_session`。
- [x] macOS：`audio_service` + `audio_session`。
- [x] Web：浏览器 Media Session 基础支持。
- [x] Linux：引入 `audio_service_mpris ^0.2.1`。
- [x] Windows：引入 `audio_service_win ^0.0.3`。
- [x] Windows/Linux 自动跳过不支持的移动端 `audio_session` 初始化。
- [x] Windows 示例在当前工具链构建成功。
- [x] Web 示例构建成功。
- [x] Windows 新版 MSVC coroutine 兼容配置。

### 文档与验证

- [x] 基础 README 和使用示例。
- [x] Android/iOS 宿主配置示例。
- [x] 全平台支持矩阵。
- [x] BYD DiLink 仪表音乐适配调研文档。
- [x] Dart 静态检查通过。
- [x] 当前单元测试通过。

## 第一阶段：统一易用 API

- [ ] 增加 `LemonAudioCallbacks`，不要求业务创建完整播放器 Adapter。
- [ ] 同时保留 Adapter 和 callbacks 两种接入方式。
- [ ] 增加独立的 `setPlaying`。
- [ ] 增加独立的 `setProcessingState`。
- [ ] 增加独立的 `setSpeed` 状态上报。
- [ ] 增加 `setQueueIndex`。
- [ ] 增加统一错误流 `errorStream`。
- [ ] 增加框架事件流，例如耳机拔出、音频中断和系统媒体按钮事件。
- [ ] 明确所有 setter 为“状态上报”，所有控制方法为“播放器命令”。
- [ ] 防止重复初始化 `AudioService` 并提供清晰错误。
- [ ] 完善 dispose、停止服务和重新初始化策略。

## 第二阶段：权限与开箱即用配置

- [ ] 设计 `LemonPermissionMode.auto/manual/none`。
- [ ] 插件内部检查 Android 13+ 通知权限。
- [ ] 第一次播放时按策略申请必要权限。
- [ ] 提供 `checkPermissions`。
- [ ] 提供 `requestPermissions`。
- [ ] 提供权限状态流。
- [ ] 提供打开应用系统设置入口。
- [ ] 区分拒绝和永久拒绝。
- [ ] 不为普通蓝牙媒体播放申请不必要的扫描权限。
- [ ] 仅启用蓝牙设备扫描功能时申请 Bluetooth Scan/Connect 权限。
- [ ] 实现 `dart run lemon_audio:setup`。
- [ ] setup 自动配置 Android Manifest。
- [ ] setup 自动配置 Android `AudioServiceActivity`。
- [ ] setup 自动配置 iOS `UIBackgroundModes/audio`。
- [ ] setup 自动配置 Windows CMake 兼容项。
- [ ] 提供 `dart run lemon_audio:setup --check`。
- [ ] 初始化时可选执行平台配置检查。
- [ ] 配置缺失时返回包含文件路径和修复方式的错误。

## 第三阶段：播放状态与音频策略完善

- [ ] 避让前保存播放器原始音量，结束后恢复原值而不是固定恢复为 `1.0`。
- [ ] 处理用户在避让期间手动暂停的情况，避免错误恢复播放。
- [ ] 区分暂时中断和永久音频焦点丢失。
- [ ] 区分电话、导航播报、其他媒体应用等中断类型。
- [ ] 支持仅降低音量、不暂停的导航类模式。
- [ ] 支持提示音的 transient/transient-duck 策略。
- [ ] 添加实时输出设备监听。
- [ ] 添加耳机、蓝牙、扬声器和 AirPlay 路由状态。
- [ ] 建立平台能力查询，避免在 Windows/Linux 承诺移动端焦点语义。

## 第四阶段：通知、锁屏与队列

- [ ] 可配置通知按钮及顺序。
- [ ] 支持收藏、自定义动作等扩展按钮。
- [ ] 支持 Repeat 和 Shuffle 状态及系统回调。
- [ ] 支持完整队列增删改和当前索引同步。
- [ ] 明确队列由框架管理或播放器管理的模式。
- [ ] 支持通知关闭后的行为配置。
- [ ] 支持 Android 通知图标和颜色配置。
- [ ] 支持本地、网络及受鉴权保护的封面。
- [ ] 增加封面缓存、失败回退和去重更新。
- [ ] 支持恢复上次歌曲、队列和进度的可选持久化接口。
- [ ] 处理 Android 冷启动后由通知或耳机唤醒播放服务。

## 第五阶段：蓝牙歌词与外接设备

- [ ] 建立 `LemonExternalDisplayMode.standard/bluetoothLyrics/auto`。
- [ ] 增加结构化歌词行模型，包括开始和结束时间。
- [ ] 歌词相同内容去重。
- [ ] 限制 AVRCP 元数据刷新频率。
- [ ] 切歌、停止和断开设备后可靠恢复原始歌曲标题。
- [ ] 增加不同车机的 Title/Artist/Album 映射策略。
- [ ] 支持用户手动启用蓝牙歌词，避免错误识别普通耳机。
- [ ] 测试 Android 与 iOS 的 AVRCP 元数据刷新差异。
- [ ] 测试 AVRCP 1.3/1.4/1.5/1.6 车机兼容性。
- [ ] 调研并验证 AVRCP 1.6 封面传输支持。
- [ ] 调研 BLE Media Control Service，但不将其误认为通用歌词协议。

## 第六阶段：车机生态

### Android Auto / Android Automotive

- [ ] 完整 MediaBrowser 媒体树。
- [ ] Android Auto/AAOS 应用声明和宿主配置。
- [ ] 支持车机浏览歌曲、专辑、歌单。
- [ ] 当前歌曲、队列、封面和进度同步。
- [ ] Android Automotive 模拟器验证。
- [ ] 说明仪表盘最终显示区域由车厂系统决定。

### CarPlay

- [ ] 完善 Now Playing 与远程控制同步。
- [ ] 整理 CarPlay 音频应用 entitlement 和宿主配置。
- [ ] 验证 CarPlay 标题复用型歌词。
- [ ] 明确普通锁屏媒体控制与完整 CarPlay 应用资格的区别。

### BYD DiLink（实验性、可选）

- [ ] 创建独立 BYD adapter，不进入通用核心流程。
- [ ] 反射探测 `BYDAutoInstrumentDevice`。
- [ ] 验证 `sendMusicName`。
- [ ] 验证 `sendMusicState`。
- [ ] 验证 `sendMusicPlaybackProgress` 的单位。
- [ ] 验证 `sendMusicSource` 和来源常量。
- [ ] 检测 `BYDAUTO_INSTRUMENT_COMMON/GET/SET` 权限。
- [ ] 验证普通包名是否能使用仪表接口。
- [ ] 不采用伪装酷狗包名作为正式方案。
- [ ] 支持歌曲信息和歌词两种仪表显示模式。
- [ ] 适配失败时自动回退标准 MediaSession/AVRCP。
- [ ] 独立研究小迪默认音乐和语音控制 Intent。
- [ ] 第一版禁止访问音乐信息以外的车辆控制接口。

详细调研见 [`docs/byd-dilink-integration.md`](docs/byd-dilink-integration.md)。

## 第七阶段：桌面与 Web 完善

### Windows

- [ ] 增加 `windowsAppId` 和 `windowsDisplayName` 配置。
- [ ] 未打包应用可选注册 AppUserModelID 和开始菜单快捷方式。
- [ ] MSIX 发布时优先使用包身份。
- [ ] 避免开发版 SMTC 显示“未知应用”。
- [ ] 支持 SMTC timeline、进度和 seek 请求。
- [ ] 评估维护或替换成熟度较低的 `audio_service_win`。

### Linux

- [ ] 验证 KDE Plasma MPRIS。
- [ ] 验证 GNOME MPRIS。
- [ ] 补齐 MPRIS position、seek、queue 和 metadata 行为测试。

### macOS

- [ ] 在 macOS 真机执行构建和 Now Playing 测试。
- [ ] 验证沙盒与后台音频 capability。

### Web

- [ ] 测试 Chrome、Edge、Safari 和 Firefox Media Session 差异。
- [ ] 处理浏览器自动播放限制。
- [ ] 支持 Media Session seek、next、previous 和 position state。
- [ ] 验证 PWA 安装后的后台行为。

## 第八阶段：质量与发布

- [ ] 为 handler 增加可注入平台接口，便于单元测试。
- [ ] 测试每个控制命令只调用播放器一次。
- [ ] 测试 setter 不反向触发 seek/play 等命令。
- [ ] 测试中断、恢复和手动暂停竞态。
- [ ] 测试高频进度及歌词更新性能。
- [ ] 添加 Android 集成测试。
- [ ] 添加 iOS 集成测试。
- [ ] 添加 Windows SMTC 集成测试。
- [ ] 添加 Web Media Session 集成测试。
- [ ] 建立 Android、iOS、macOS、Windows、Linux 和 Web CI。
- [ ] 清理最初插件模板中不再使用的 `getPlatformVersion` 代码和测试。
- [ ] 完善 Dart API 文档注释。
- [ ] 增加 just_audio、media_kit、VLC 接入示例。
- [ ] 补充迁移指南、错误排查和平台限制文档。
- [ ] 确定稳定版 API 后发布 `1.0.0`。

## 建议实施顺序

1. 统一 callbacks/setter API，稳定核心接口。
2. 权限处理、setup 命令和平台配置检查。
3. 音频焦点、恢复逻辑和设备路由完善。
4. 通知、队列、持久化和冷启动。
5. 蓝牙歌词兼容层。
6. Android Auto、CarPlay 与桌面平台完善。
7. BYD DiLink 独立实验适配。
8. 全平台集成测试、CI 和 `1.0.0` 发布。
