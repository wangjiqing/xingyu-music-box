# 星语音乐盒 v0.4.1 Release Draft

v0.4.1 聚焦播放连续性、系统媒体控制和 Release 配置隔离。

## Highlights

- macOS 接入 `MPRemoteCommandCenter` 和 `MPNowPlayingInfoCenter`，支持 AirPods、键盘媒体键、系统控制中心控制当前 Mac 播放实例。
- iOS/iPadOS 统一处理 `AVAudioSession` interruption，电话和微信通话结束后按状态机恢复播放。
- 新增 `PlaybackCheckpoint` / `PlaybackPersistence`，全平台恢复最后歌曲、队列和进度，冷启动默认暂停。
- macOS 菜单栏“打开星语音乐盒”可靠拉起主窗口，不重复创建无意义窗口。
- Release 首次启动不携带开发 endpoint、AK/SK、内网 IP 或开发者路径；macOS 用户填写的 endpoint 与 AK/SK 优先保存到 `/Library/Application Support/XingyuMusicBox/OpenApiConfig.plist`，目录不可写时回退到 `~/Library/Application Support/XingyuMusicBox/OpenApiConfig.plist`，不进入 App Bundle、Info.plist、UserDefaults 或 Git 仓库。

## Release Checks

- Build iOS/iPadOS target with `XingyuMusicBox`.
- Build macOS Apple Silicon target with `XingyuMusicBoxMac`.
- Build macOS Release and verify no bundled `OpenApiConfig.plist`.
- Search unpacked `.app` for `xmv_ak_`, `xmv_sk_`, concrete internal IPs, developer home directories, and old default service URLs.
- Run the manual media-control and interruption matrix from `docs/playback-continuity.md`.
