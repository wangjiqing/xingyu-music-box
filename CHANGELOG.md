# Changelog

## v0.4.1

- macOS 接入系统媒体控制与 Now Playing 信息，支持耳机、键盘媒体键和控制中心。
- iOS/iPadOS 增加电话、微信通话等音频中断后的安全恢复状态机。
- 新增 PlaybackCheckpoint 持久化，重启后恢复最后歌曲、队列和进度且默认暂停。
- 修复 macOS 菜单栏“打开星语音乐盒”无法可靠拉起主窗口。
- 隔离 Release 配置，Debug 本地配置不进入 Release 包；macOS 用户填写的星语音库配置优先保存到共享 Application Support，目录不可写时回退到用户 Application Support。

## v0.1.0

- 初始化客户端 Monorepo。
- 迁入现有 Apple 客户端项目。
