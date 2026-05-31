# 本地开发

使用 Xcode 打开 `apps/apple/ios/` 下的 Xcode 工程：

```sh
open apps/apple/ios/XingyuMusicBox.xcodeproj
```

可以使用 iOS 模拟器或真机运行 Apple 客户端。

星语音库服务端需要在本机或局域网内可访问，客户端通过星语音库提供的 OpenAPI 获取服务信息、曲目、歌词、封面与元数据。

本地配置、私有服务地址、Token、签名相关敏感文件不应提交到仓库。需要本地覆盖配置时，请使用被 `.gitignore` 排除的本地文件或 Xcode 用户配置。
