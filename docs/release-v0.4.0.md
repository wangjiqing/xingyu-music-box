# 星语音乐盒 v0.4.0 Release Draft

## 标题

星语音乐盒 v0.4.0 - macOS Apple Silicon 初版

## 发布摘要

v0.4.0 的主要目标是补齐原生 macOS 客户端 MVP，并继续改善 iOS / iPadOS 正在播放体验。macOS 版本采用独立 SwiftUI Target，不使用 Mac Catalyst，当前仅支持 Apple Silicon / arm64。

## 主要更新

- 新增原生 macOS SwiftUI App：`XingyuMusicBoxMac`。
- 新增 macOS Apple Silicon / arm64 构建配置、Info.plist、entitlements、App Icon 和共享 Scheme。
- macOS 端提供桌面播放器 MVP：
  - 左侧 Sidebar。
  - 中间本地歌曲列表。
  - 右侧当前播放与歌词摘要。
  - 底部播放控制栏。
- macOS 端支持从本地目录导入音频文件并播放。
- macOS 端复用现有 Apple 客户端的 OpenAPI 配置、DTO、签名、API Client 和 LRC 解析能力。
- OpenAPI 配置支持 macOS 用户配置文件读取与保存。
- iOS / iPadOS 正在播放页继续整理播放器布局：
  - 新增留声机视觉组件与四季主题资源。
  - 保留当前 4 套季节主题。
  - 增加右侧快捷按钮组。
  - 恢复播放动态柱状效果。
  - 优化进度条、播放控制区和页面容器适配。
- iPadOS 正在播放页增加基于可用尺寸的布局分支，为横屏大屏播放器工作台做准备。
- 更新 Apple 客户端与 macOS MVP 文档。

## macOS MVP 范围

- 只支持 Apple Silicon / arm64。
- 不使用 Mac Catalyst。
- 当前以本地音频目录导入与播放为主。
- 当前暂不从星语音库歌曲列表直接发起 macOS 音频流播放。
- 当前不包含菜单栏迷你播放器、全局快捷键、桌面歌词悬浮窗和完整媒体库持久化管理。

## 配置说明

macOS 端可复用本地 OpenAPI 配置文件：

```text
apps/apple/ios/XingyuMusicBox/Resources/OpenApiConfig.plist
```

也可以在运行后写入用户配置目录：

```text
~/Library/Application Support/XingyuMusicBox/OpenApiConfig.plist
```

示例配置可参考：

```text
apps/apple/ios/XingyuMusicBox/Resources/OpenApiConfig.example.plist
apps/apple/macos/XingyuMusicBoxMac/Resources/OpenApiConfig.example.plist
```

## 构建验证

iOS / iPadOS：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild \
  -project apps/apple/ios/XingyuMusicBox.xcodeproj \
  -scheme XingyuMusicBox \
  -destination generic/platform=iOS \
  -derivedDataPath /private/tmp/XingyuMusicBoxDerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build
```

macOS：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild \
  -project apps/apple/ios/XingyuMusicBox.xcodeproj \
  -scheme XingyuMusicBoxMac \
  -destination generic/platform=macOS \
  -derivedDataPath /private/tmp/XingyuMusicBoxMacDerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## DMG 打包步骤

先生成 Release 版 macOS App：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild \
  -project apps/apple/ios/XingyuMusicBox.xcodeproj \
  -scheme XingyuMusicBoxMac \
  -configuration Release \
  -destination generic/platform=macOS \
  -derivedDataPath /private/tmp/XingyuMusicBoxMacRelease \
  CODE_SIGNING_ALLOWED=NO \
  build
```

构建产物位置通常是：

```text
/private/tmp/XingyuMusicBoxMacRelease/Build/Products/Release/星语音乐盒.app
```

创建临时 DMG 目录：

```bash
rm -rf /private/tmp/XingyuMusicBox-dmg
mkdir -p /private/tmp/XingyuMusicBox-dmg
cp -R "/private/tmp/XingyuMusicBoxMacRelease/Build/Products/Release/星语音乐盒.app" /private/tmp/XingyuMusicBox-dmg/
ln -s /Applications /private/tmp/XingyuMusicBox-dmg/Applications
```

生成 DMG：

```bash
hdiutil create \
  -volname "星语音乐盒" \
  -srcfolder /private/tmp/XingyuMusicBox-dmg \
  -ov \
  -format UDZO \
  "星语音乐盒-v0.4.0-macOS-arm64.dmg"
```

生成后可校验挂载：

```bash
hdiutil verify "星语音乐盒-v0.4.0-macOS-arm64.dmg"
```

## 发布前建议验证

- 在 Apple Silicon Mac 上运行 `XingyuMusicBoxMac`。
- 导入包含 `mp3`、`m4a`、`flac`、`aac`、`wav` 的本地目录。
- 验证播放、暂停、上一首、下一首、进度跳转。
- 验证歌词摘要和无歌词状态。
- 验证 OpenAPI 配置保存后重启仍能读取。
- 验证 iPhone 竖屏正在播放页、主题切换、收藏、播放列表和底部 Tab。
- 验证 iPad 横屏正在播放页、歌词页和无歌词状态。

## 已知限制

- macOS v0.4.0 暂不支持 Intel Mac。
- DMG 如未签名和 notarize，用户首次打开时可能看到 macOS 安全提示。
- 本地目录导入结果当前为 MVP 行为，不承诺完整媒体库持久化管理。
- macOS 端当前不包含菜单栏、全局快捷键和桌面歌词能力。

