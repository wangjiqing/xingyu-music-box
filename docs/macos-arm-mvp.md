# macOS ARM MVP

本文记录星语音乐盒 v0.4.0 macOS ARM 初版范围、工程结构、运行方式和限制。

## 范围

- 新增原生 macOS SwiftUI Target：`XingyuMusicBoxMac`。
- 只支持 Apple Silicon / `arm64`。
- 不使用 Mac Catalyst。
- 复用现有 Apple 客户端里的 OpenAPI 模型、签名、配置读取和 API Client，但 macOS MVP 暂不直接获取星语音库歌曲列表。
- macOS 端提供独立桌面界面：左侧 Sidebar、中间本地歌曲列表、右侧当前播放与歌词摘要、底部播放栏。
- 支持从 macOS 本地目录导入音频文件，并在歌曲列表中播放。

## 工程结构

- Xcode 工程仍位于 `apps/apple/ios/XingyuMusicBox.xcodeproj`。
- iOS/iPadOS App 源码保持在 `apps/apple/ios/XingyuMusicBox`。
- macOS App 源码新增在 `apps/apple/macos/XingyuMusicBoxMac`。
- macOS target 直接引用下列现有共用 Swift 文件：
  - `Models/AudioSource.swift`
  - `Models/Song.swift`
  - `Models/MusicVaultDTOs.swift`
  - `Services/MusicVaultConfig.swift`
  - `Services/OpenApiHmacSigner.swift`
  - `Services/MusicVaultApiClient.swift`
  - `Services/LRCParser.swift`

## 运行方式

1. 在 Xcode 打开 `apps/apple/ios/XingyuMusicBox.xcodeproj`。
2. 选择 Scheme：`XingyuMusicBoxMac`。
3. 选择 My Mac 作为运行目标。
4. 在 Apple Silicon Mac 上运行。

macOS 初版保留 OpenAPI 配置复用能力，配置文件沿用 iOS/iPadOS 的本地 OpenAPI 配置文件：

`apps/apple/ios/XingyuMusicBox/Resources/OpenApiConfig.plist`

可复制 `apps/apple/ios/XingyuMusicBox/Resources/OpenApiConfig.example.plist` 为上述本地配置文件，并填入星语音库地址、`accessKey`、`secretKey`。当前公网入口为 `https://www.oceanofstars.com.cn:18443`；需要局域网或本机调试时再把 `baseUrl` 改为调试入口。构建 macOS target 时脚本会把 iOS/iPadOS 这份本地配置复制进 macOS App bundle。当前 MVP 不在 macOS 端直接拉取星语音库歌曲列表。

## 限制

- 不支持 x86_64。
- 不包含 Mac Catalyst target。
- 不做菜单栏迷你播放器。
- 不做全局快捷键。
- 不做桌面歌词悬浮窗。
- 不做完整媒体库管理。
- 设置页只记录 MVP 状态，不提供复杂设置。
- 本地目录导入当前只保留本次运行的导入结果，支持 `mp3`、`m4a`、`flac`、`aac`、`wav`、`aif`、`aiff`，暂不做持久化媒体库管理。
- 当前 macOS MVP 暂不直接获取星语音库歌曲列表，也不从星语音库歌曲列表发起音频流播放。

## CI

当前仓库未发现独立 CI 配置。v0.4.0 初版只新增 Xcode scheme 和 target，不改变现有 iOS scheme；如后续接入 CI，可先继续只构建 `XingyuMusicBox`，再单独增加 Apple Silicon macOS runner 构建 `XingyuMusicBoxMac`。
