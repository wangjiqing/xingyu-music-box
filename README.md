# 星语音乐盒

<img src="assets/app-icon/xingyu-music-box-icon-midsummer-starlight-512.png" alt="星语音乐盒 App 图标" width="160">

星语音乐盒是面向多端客户端的 Monorepo，用于承载 iOS、iPadOS、macOS、Android、Windows 等客户端工程与共享文档。

当前阶段优先建设 Apple 客户端。现有 Apple 客户端以 iOS/iPadOS 为主，v0.4.0 开始新增原生 macOS Apple Silicon 初版，v0.4.2 增加移动端星语音库 AK/SK 配置与 SWLRC 逐字歌词支持。Android 与 Windows 客户端暂未开始。

星语音乐盒依赖星语音库 `xingyu-music-vault` 提供 OpenAPI、歌词、封面、元数据等服务。星语音库仓库保持独立，不与客户端仓库合并。

## 目录

- `apps/apple/ios/`: Apple iOS 客户端 Xcode 工程。
- `apps/apple/macos/`: Apple macOS 客户端源码，当前为 `XingyuMusicBoxMac` 原生 SwiftUI ARM MVP。
- `docs/`: 客户端设计、开发与维护文档。
- `protocol/`: 多端客户端复用的协议约定与 OpenAPI 对接说明。
- `assets/`: 图标、截图、品牌与发布素材。

## 视觉方向

星语音乐盒的主视觉方向以“星星音乐盒 / 水晶罩 / 月光湖面”为核心意象，默认皮肤可围绕“仲夏星河”或“月泊银声”展开。详见 `docs/visual-direction.md`。

## macOS ARM 初版

v0.4.0 新增 `XingyuMusicBoxMac` 原生 macOS SwiftUI Target，只支持 Apple Silicon / `arm64`，不使用 Mac Catalyst。初版范围、运行方式和限制见 `docs/macos-arm-mvp.md`。

## 星语音库连接与歌词

- iOS/iPadOS 可在设置页的“星语音库连接”中配置服务地址、Access Key，并输入本次运行使用的 Secret Key。
- Secret Key 不保存到系统钥匙串、UserDefaults、JSON 或普通配置文件；服务地址和 Access Key 保存到 App Sandbox 的 Application Support 配置，App 重启后需重新输入 SK 才能发起 HMAC 请求。
- 歌词优先级为：SWLRC 逐字歌词 -> LRC 标准歌词 -> 无歌词。
- 当前不使用 LRCLIB 或其他公网歌词服务作为兜底。
- 在线读取星语音库音频不属于 v0.4.2 范围。

## 播放队列

- 随机播放使用独立的运行期随机队列，不再每次点击下一首时即时抽一首。
- 同一轮随机播放中，下一首按已生成顺序推进，上一首返回真实播放历史，回退后再下一首会回到原先确定的歌曲。
- 当前歌曲集合变化时会剔除失效歌曲并尽量保留当前歌曲；新增歌曲主要在下一轮随机队列中出现。
- v0.4.2 暂不持久化完整随机队列，App 重启后会按已保存的播放模式和当前歌曲重新生成随机上下文。
