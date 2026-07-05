# Apple 客户端

Apple 客户端当前以 iOS/iPadOS 为主，并在 v0.4.0 增加原生 macOS Apple Silicon 初版，使用 SwiftUI 和 Xcode 开发。

当前 Xcode 工程位于 `apps/apple/ios/`。iOS/iPadOS Target、Scheme、Bundle Identifier 和 Swift 源码模块名保持为现有命名；macOS 初版 Target/Scheme 为 `XingyuMusicBoxMac`，源码位于 `apps/apple/macos/XingyuMusicBoxMac`。

相关适配应优先复用现有业务能力，并保持与星语音库 OpenAPI 的联动，包括服务信息、曲目、歌词、封面和元数据等能力。macOS v0.4.0 初版范围详见 `docs/macos-arm-mvp.md`。

v0.4.2 起，iOS/iPadOS 设置页可直接配置星语音库服务地址、Access Key，并输入本次运行使用的 Secret Key。Secret Key 不保存到系统钥匙串或普通配置文件；普通配置只保存服务地址和 Access Key。歌词加载优先级为 SWLRC 逐字歌词、LRC 标准歌词、无歌词；当前不启用公网歌词兜底，也不实现在线读取星语音库音频。随机播放维护运行期随机队列，上一首/下一首在同一轮已确定顺序内移动，App 重启后暂不恢复完整随机队列。

当前文档只描述本地客户端定位，不承诺 App Store 或 TestFlight 发布计划。
