# 本地开发

使用 Xcode 打开 `apps/apple/ios/` 下的 Xcode 工程：

```sh
open apps/apple/ios/XingyuMusicBox.xcodeproj
```

可以使用 iOS 模拟器或真机运行 Apple 客户端。

星语音库服务端默认通过公网 HTTPS 入口访问：

```text
https://www.oceanofstars.com.cn:18443
```

客户端通过星语音库提供的 OpenAPI 获取服务信息、曲目、歌词、封面与元数据。需要本机或局域网调试时，复制 `apps/apple/ios/XingyuMusicBox/Resources/OpenApiConfig.example.plist` 为被忽略的 `OpenApiConfig.plist`，把 `baseUrl` 改为实际调试入口，例如：

```text
http://192.168.x.x:18081
```

本地配置、私有服务地址、Token、签名相关敏感文件不应提交到仓库。需要本地覆盖配置时，请使用被 `.gitignore` 排除的本地文件或 Xcode 用户配置。
