# Changelog

## v0.4.2

- iOS/iPadOS 设置页新增星语音库连接配置，可保存服务地址和 Access Key，并用本次运行内存中的 Secret Key 立即重载 OpenAPI 客户端。
- Secret Key 不保存到系统钥匙串或普通配置文件；App 重启后需重新输入 SK 才能继续发起 HMAC 请求。
- 对接星语音库 v1.3.2 的 `/tracks/{id}/word-lyrics` OpenAPI，优先加载 SWLRC 逐字歌词，失败后回退 LRC。
- 歌词模型和缓存区分 `none`、`lrc`、`swlrc`，SWLRC 与 LRC 缓存不再互相覆盖。
- 播放页支持 SWLRC token 级平滑高亮，使用 60fps 显示时间源按每个字/词的开始和结束时间连续填充，并用弹性滚动切换当前行；拖动、跳转、暂停和恢复继续复用现有播放进度。
- 随机播放改为维护稳定随机队列，支持上一首返回历史、下一首回到已确定后续歌曲，并在一轮耗尽后再生成新随机顺序。
- 明确 v0.4.2 不启用公网歌词兜底，也不实现在线音频播放。

## v0.4.1

- macOS 接入系统媒体控制与 Now Playing 信息，支持耳机、键盘媒体键和控制中心。
- iOS/iPadOS 增加电话、微信通话等音频中断后的安全恢复状态机。
- 新增 PlaybackCheckpoint 持久化，重启后恢复最后歌曲、队列和进度且默认暂停。
- 修复 macOS 菜单栏“打开星语音乐盒”无法可靠拉起主窗口。
- 隔离 Release 配置，Debug 本地配置不进入 Release 包；macOS 用户填写的星语音库配置优先保存到共享 Application Support，目录不可写时回退到用户 Application Support。

## v0.1.0

- 初始化客户端 Monorepo。
- 迁入现有 Apple 客户端项目。
