# Salt Player Lyric Adapter

Xposed 模块，用于将 Salt Player (椒盐音乐) 的歌词同步到 Lyricon (词幕) 状态栏歌词显示。

## 功能特性

- 🎵 实时提取 Salt Player 播放的歌词
- 🔄 同步播放状态和进度
- 📝 支持普通歌词和翻译歌词
- 🎯 通过 Lyricon Provider API 发送数据
- 📱 需要 LSPosed 框架支持

## 环境要求

- Android 8.1 (API 27) 或更高版本
- Root 权限 + LSPosed 框架
- Salt Player 已安装 (`com.salt.music`)
- Lyricon (词幕) 已安装

## 安装说明

1. 下载并安装 APK 文件
2. 打开 LSPosed 管理器
3. 找到 "Salt Player Lyric Adapter" 模块并启用
4. 作用域选择：
   - ✅ Salt Player (com.salt.music)
   - ✅ 系统界面 (System UI)
5. 重启系统界面或重启设备
6. 打开 Salt Player 播放音乐
7. Lyricon 将自动显示歌词

## 工作原理

本模块通过 Xposed 框架 Hook Salt Player 的内部方法：

1. **SaltPlayerHook**: Xposed Hook 入口，拦截歌词更新事件
2. **SaltLyricProvider**: 通过 Lyricon SDK 发送数据
3. **LyricInterceptor**: 歌词提取和解析（支持 LRC 格式和增强格式）
4. **PlaybackMonitor**: 播放状态监控，通过 MediaSession API 获取播放信息

## 项目结构

```
SaltPlayerLyricAdapter/
├── app/
│   ├── src/main/java/io/github/proify/saltadapter/
│   │   ├── SaltPlayerHook.kt      # Xposed Hook 入口
│   │   ├── SaltLyricProvider.kt   # Lyricon Provider 集成
│   │   ├── LyricInterceptor.kt    # 歌词提取和解析
│   │   └── PlaybackMonitor.kt     # 播放状态监控
│   ├── build.gradle.kts
│   └── src/main/res/
├── build.gradle.kts
├── settings.gradle.kts
└── gradle.properties
```

## 技术栈

- **语言**: Kotlin
- **Hook 框架**: [YukiHookAPI](https://github.com/HighCapable/YukiHookAPI)
- **Provider SDK**: Lyricon Provider API 0.1.64
- **构建系统**: Gradle Kotlin DSL
- **最低 SDK**: Android 8.1 (API 27)
- **目标 SDK**: Android 15 (API 35)

## 构建说明

### 环境准备

1. 安装 Android Studio 或 IntelliJ IDEA
2. 配置 Android SDK (API 27-35)
3. 确保安装了 JDK 17

### 构建 APK

```bash
# 克隆项目
cd SaltPlayerLyricAdapter

# 构建 Debug APK
./gradlew :app:assembleDebug

# 构建 Release APK
./gradlew :app:assembleRelease
```

APK 输出位置:
- Debug: `app/build/outputs/apk/debug/app-debug.apk`
- Release: `app/build/outputs/apk/release/app-release.apk`

### 安装测试

```bash
# 安装到设备
adb install app/build/outputs/apk/debug/app-debug.apk

# 查看日志
adb logcat -s YukiHookAPI:S SaltPlayerHook:S
```

## Hook 目标

模块尝试 Hook 以下 Salt Player 类（类名可能随版本变化）：

### 歌词显示
- `com.salt.music.ui.lyric.LyricView`
- `com.salt.music.lyric.LyricView`
- `com.salt.music.view.LyricTextView`
- `com.salt.music.widget.LyricView`

### 歌词控制
- `com.salt.music.player.LyricController`
- `com.salt.music.lyric.LyricController`
- `com.salt.music.service.LyricManager`

### 媒体控制
- `com.salt.music.player.MediaController`
- `com.salt.music.player.PlayerService`

### 备选方案
- 通过 `MediaSessionManager` API 监控播放状态
- 通过通知栏提取歌词信息

## 已知问题

1. **Salt Player 是闭源应用**，Hook 点可能因版本更新而失效
2. 如遇到问题请提交 Issue 并附上：
   - Salt Player 版本号
   - Android 版本
   - LSPosed 版本
   - 相关日志 (logcat)

## 调试

启用详细日志：
```kotlin
// 在 SaltPlayerHook.kt 中
YLog.config {
    isDebug = true
}
```

查看日志：
```bash
adb logcat -s YukiHookAPI:* | grep -i "salt\|lyric"
```

## 相关项目

- [Lyricon (词幕)](https://github.com/proify/lyricon) - 状态栏歌词显示工具
- [LyricProvider](https://github.com/proify/LyricProvider) - 歌词提供器插件库
- [Salt Player](https://github.com/Moriafly/SaltPlayerSource) - 椒盐音乐播放器
- [YukiHookAPI](https://github.com/HighCapable/YukiHookAPI) - Xposed Hook 框架

## 开源协议

Apache License 2.0

```
Copyright 2026 SaltAdapter Developer

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

## 贡献

欢迎提交 Pull Request 和 Issue！

## 致谢

- [Proify](https://github.com/proify) 开发的 Lyricon 和 LyricProvider
- [Moriafly](https://github.com/Moriafly) 开发的 Salt Player
- [HighCapable](https://github.com/HighCapable) 开发的 YukiHookAPI
