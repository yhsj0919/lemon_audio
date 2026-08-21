# lemon_audio_example

演示如何接入和使用 `lemon_audio` 插件。

## 开始使用

此项目是 `lemon_audio` 的示例 Flutter 应用，使用 `mpv_audio_kit ^0.4.4`
播放内置测试音频，并演示 Android 媒体通知、真实播放进度以及播放/暂停控制。
应用启动后会自动播放，便于直接测试通知栏、蓝牙耳机和车机按键。

测试音频由 `tool/generate_test_tone.dart` 生成；需要重新生成时，在 `example`
目录执行 `dart run tool/generate_test_tone.dart`。

如果这是你的第一个 Flutter 项目，可以参考：

- [学习 Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [编写第一个 Flutter 应用](https://docs.flutter.dev/get-started/codelab)
- [Flutter 学习资源](https://docs.flutter.dev/reference/learning-resources)

更多教程、示例、移动端开发指南和 API 参考见
[Flutter 官方文档](https://docs.flutter.dev/)。
