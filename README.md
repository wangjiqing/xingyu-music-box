# 星语音乐盒

<img src="assets/app-icon/xingyu-music-box-icon-midsummer-starlight-512.png" alt="星语音乐盒 App 图标" width="160">

星语音乐盒是面向多端客户端的 Monorepo，用于承载 iOS、iPadOS、macOS、Android、Windows 等客户端工程与共享文档。

当前阶段优先建设 Apple 客户端。现有 Apple 客户端以 iOS 为主，后续计划逐步扩展 iPadOS 和 macOS 体验。Android 与 Windows 客户端暂未开始。

星语音乐盒依赖星语音库 `xingyu-music-vault` 提供 OpenAPI、歌词、封面、元数据等服务。星语音库仓库保持独立，不与客户端仓库合并。

## 目录

- `apps/apple/ios/`: Apple iOS 客户端 Xcode 工程。
- `docs/`: 客户端设计、开发与维护文档。
- `protocol/`: 多端客户端复用的协议约定与 OpenAPI 对接说明。
- `assets/`: 图标、截图、品牌与发布素材。

## 视觉方向

星语音乐盒的主视觉方向以“星星音乐盒 / 水晶罩 / 月光湖面”为核心意象，默认皮肤可围绕“仲夏星河”或“月泊银声”展开。详见 `docs/visual-direction.md`。
