# 星语音乐盒 v0.4.2 Release Draft

## 标题

星语音乐盒 v0.4.2 - OpenAPI 凭证配置与 SWLRC 逐字歌词

## 发布摘要

v0.4.2 聚焦星语音库 OpenAPI 连接配置、SWLRC 逐字歌词体验和随机播放队列。移动端可以在设置页配置星语音库服务地址和 Access Key，并输入本次运行使用的 Secret Key；歌词加载优先使用星语音库 SWLRC 逐字歌词，失败后回退 LRC。本版本不包含在线音频播放。

## 主要更新

- iOS / iPadOS 设置页新增“星语音库连接”配置区。
- 移动端可保存星语音库服务地址和 Access Key。
- Secret Key 不保存到系统钥匙串、UserDefaults、JSON 或普通配置文件，只保存在本次 App 运行内存中。
- App 重启后需要重新输入 Secret Key，才会继续发起 HMAC OpenAPI 请求。
- 配置保存后会立即重载 `MusicVaultApiClient.shared`，后续请求使用新配置。
- Debug bundle `OpenApiConfig.plist` 不再覆盖用户运行时配置；有用户配置但缺少本次运行 SK 时不会静默回退到开发配置。
- 保留 macOS 既有直接配置能力，macOS 用户配置仍走兼容配置文件机制。
- 对接星语音库 v1.3.2 歌词 OpenAPI：
  - `GET /api/open/v1/tracks/{id}/lyrics/meta`
  - `GET /api/open/v1/tracks/{id}/word-lyrics`
  - `GET /api/open/v1/tracks/{id}/lyrics`
- 歌词加载优先级为：SWLRC 逐字歌词 -> LRC 标准歌词 -> 无歌词。
- SWLRC 与 LRC 使用不同缓存标识，避免互相覆盖；旧 LRC 缓存仍可读取。
- SWLRC 渲染按 token 的开始 / 结束时间连续填充，使用 60fps 显示时间源减少逐字跳变感。
- iOS / iPadOS / macOS 均支持 SWLRC 当前行高亮和行内逐字推进。
- 随机播放改为稳定随机队列，不再每次点击下一首即时重新随机。
- 随机模式下支持上一首回到真实播放历史，回退后再下一首回到此前已经确定的歌曲。
- 当前不使用 LRCLIB 或其它公网歌词服务作为兜底。
- 当前不实现在线读取星语音库音频。

## OpenAPI 配置说明

iOS / iPadOS 端运行时配置分为两类：

- 普通配置：服务地址、Access Key、配置完成状态，保存到 App Sandbox 的 Application Support。
- 敏感配置：Secret Key，只保存在本次 App 运行内存中，不写入钥匙串和普通文件。

配置读取优先级：

1. 显式注入的测试配置。
2. 用户在设置页保存的运行时配置；必须有本次运行 Secret Key 才能发起 HMAC 请求。
3. Debug 本地 `OpenApiConfig.plist` 开发兜底。
4. macOS 兼容 Application Support 配置。
5. 未配置状态。

清除凭证会删除普通运行时配置和本次运行内存中的 Secret Key；如存在早期开发版本留下的 Keychain 项，会尝试删除该遗留项。

## 歌词能力说明

星语音库 v1.3.2 的歌词契约：

- `lyrics/meta` 返回歌词可用性、歌词格式、hash、etag、updatedAt、`wordLyricsAvailable` 和 `wordLyricsUrl` 等元数据。
- `word-lyrics` 返回 JSON，`format=SWLRC`，`content` 为 SWLRC v1 文本。
- `lyrics` 返回 JSON，`format=LRC`，`content` 为标准 LRC 文本。
- SWLRC 不存在时服务端返回 404，客户端安全回退 LRC。
- SWLRC 解析失败、格式异常或请求失败不会阻塞音频播放。

SWLRC 渲染策略：

- 使用 token 的 `startTime` / `endTime` 计算 0 到 1 的连续进度。
- 底层显示未播放文字，高亮层按进度横向填充。
- 播放、暂停、拖动和跳转时，歌词显示时间会重新校准。
- 行切换使用弹性滚动动画，减少跳动感。

## 随机播放队列

随机播放模式维护独立运行期状态：

- `shuffleQueue`：当前随机播放队列。
- `shuffleCursor`：当前随机游标。
- `shuffleSourceSignature`：当前歌曲集合标识。
- `shuffleSeed`：当前轮随机种子，主要用于调试。

行为规则：

- 进入随机模式时，当前歌曲保持为当前项，后续歌曲随机排列。
- 歌曲数量大于 1 时，下一首不会立即重复当前歌曲。
- 点击上一首会回到当前轮真实历史。
- 从历史回退后再点击下一首，会回到此前已确定的后续歌曲。
- 一轮播放完成后才生成下一轮随机顺序。
- 新一轮首曲尽量避免与上一轮末曲相同。
- 歌曲集合变化时会剔除已失效歌曲，并尽量保留当前歌曲。
- v0.4.2 暂不持久化完整随机队列；App 重启后按当前歌曲和播放模式重新生成随机上下文。

## 构建验证

iOS / iPadOS typecheck：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcrun --sdk iphoneos swiftc \
  -typecheck \
  -target arm64-apple-ios17.0 \
  -module-cache-path /private/tmp/XingyuMusicBoxIPadPhase1ModuleCache \
  $(find apps/apple/ios/XingyuMusicBox -name "*.swift" -print)
```

macOS 构建：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild \
  -project apps/apple/ios/XingyuMusicBox.xcodeproj \
  -scheme XingyuMusicBoxMac \
  -destination generic/platform=macOS \
  -derivedDataPath /private/tmp/XingyuMusicBoxDerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build
```

macOS Release 构建：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild \
  -project apps/apple/ios/XingyuMusicBox.xcodeproj \
  -scheme XingyuMusicBoxMac \
  -configuration Release \
  -destination generic/platform=macOS \
  -derivedDataPath /private/tmp/XingyuMusicBoxMacRelease-v0.4.2 \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## DMG 打包步骤

构建产物路径：

```text
/private/tmp/XingyuMusicBoxMacRelease-v0.4.2/Build/Products/Release/星语音乐盒.app
```

创建 DMG：

```bash
APP_PATH="/private/tmp/XingyuMusicBoxMacRelease-v0.4.2/Build/Products/Release/星语音乐盒.app"
STAGE="/private/tmp/XingyuMusicBox-dmg-v0.4.2"
DIST="dist"
DMG="$DIST/星语音乐盒-v0.4.2-macOS-arm64.dmg"

rm -rf "$STAGE"
mkdir -p "$STAGE" "$DIST"
ditto "$APP_PATH" "$STAGE/星语音乐盒.app"
ln -s /Applications "$STAGE/Applications"

hdiutil create \
  -volname "星语音乐盒" \
  -srcfolder "$STAGE" \
  -ov \
  -format UDZO \
  "$DMG"

hdiutil verify "$DMG"
shasum -a 256 "$DMG"
```

如使用 `CODE_SIGNING_ALLOWED=NO`，生成的 DMG 适合本机或内部验证，不是已签名 / 已公证发行包。

## 发布前建议验证

- iPhone 首次启动未配置凭证时，不显示误导性的已连接状态。
- iPhone / iPad 输入服务地址、AK、SK 后可测试连接。
- App 重启后服务地址和 AK 仍在，SK 需要重新输入。
- 清除配置后，后续请求不再携带旧 AK/SK。
- Debug 本地 `OpenApiConfig.plist` 不覆盖用户设置页保存的配置。
- 存在 SWLRC 的歌曲显示逐字进度。
- 仅有 LRC 的歌曲显示逐行高亮。
- 无歌词歌曲正常播放并显示无歌词状态。
- SWLRC 损坏、请求失败或不存在时安全回退 LRC。
- 随机模式连续播放 10 首以上，不在一轮内提前重复。
- 随机模式下上一首 / 下一首可以在历史与已确定后续歌曲之间往返。
- 切换随机、顺序、列表循环、单曲循环后行为正常。
- macOS 原有 OpenAPI 配置方式仍可访问星语音库。
- 控制台和日志不输出 SK、Authorization 或完整签名字符串。

## 已知限制

- v0.4.2 不实现在线读取星语音库音频。
- iOS / iPadOS 的 Secret Key 不持久化，重启后需要重新输入。
- 随机播放队列暂不跨 App 重启恢复。
- 当前 Xcode 工程尚未整理出完整 XCTest target；自动化验证以 typecheck、macOS build 和独立解析/队列断言为主。
- 未签名 / 未公证 DMG 首次打开时可能触发 macOS 安全提示。
