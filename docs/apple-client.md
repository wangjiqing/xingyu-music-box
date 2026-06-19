# Apple 客户端

Apple 客户端当前以 iOS/iPadOS 为主，并在 v0.4.0 增加原生 macOS Apple Silicon 初版，使用 SwiftUI 和 Xcode 开发。

当前 Xcode 工程位于 `apps/apple/ios/`。iOS/iPadOS Target、Scheme、Bundle Identifier 和 Swift 源码模块名保持为现有命名；macOS 初版 Target/Scheme 为 `XingyuMusicBoxMac`，源码位于 `apps/apple/macos/XingyuMusicBoxMac`。

相关适配应优先复用现有业务能力，并保持与星语音库 OpenAPI 的联动，包括服务信息、曲目、歌词、封面和元数据等能力。macOS v0.4.0 初版范围详见 `docs/macos-arm-mvp.md`。

当前文档只描述本地客户端定位，不承诺 App Store 或 TestFlight 发布计划。
