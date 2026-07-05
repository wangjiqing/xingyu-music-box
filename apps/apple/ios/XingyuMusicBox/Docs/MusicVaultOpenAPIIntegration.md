# 星语音库 OpenAPI 接入说明

## 当前默认配置

- 默认 Release 配置不内置服务地址；本地调试请使用自己的星语音库 endpoint。
- 局域网调试地址示例：`http://192.168.x.x:18081`
- OpenAPI 前缀：`/api/open/v1`
- 集中配置入口：`MusicVaultConfig`
- Swift 客户端入口：`MusicVaultApiClient.shared`
- 本地缓存入口：`MusicVaultCacheStore.shared`
- 当前后端 OpenAPI 版本：`v1`，已按星语音库 v1.3.2 对接 SWLRC 逐字歌词。

`musicVaultBaseUrl` 只能从 `MusicVaultConfig.defaultBaseURLString` 或显式注入的 `MusicVaultConfig` 读取，不在调用点散落硬编码。

星语音库 v1.1.3 起，所有 `/api/open/v1/*` 请求都必须使用 AK/SK + HMAC-SHA256 签名；旧 `Authorization: Bearer <token>` 和 `X-Xingyu-Api-Token` 不再可用。

```swift
let credential = OpenApiCredential(accessKey: "xmv_ak_dev", secretKey: "local-secret")
let config = MusicVaultConfig(baseURLString: "https://your-music-vault.example.com", credential: credential)
let client = MusicVaultApiClient(config: config)
```

## 服务地址切换

默认构建使用公网 HTTPS 入口：

```text
https://your-music-vault.example.com
```

本地或局域网调试时，不要修改业务代码；复制 `Resources/OpenApiConfig.example.plist` 为被忽略的 `Resources/OpenApiConfig.plist`，只改其中的 `baseUrl`。例如：

```text
http://192.168.x.x:18081
```

真机使用局域网 HTTP 调试时，iPhone 与服务端需要在同一网络，并按实际 IP / 端口填写 `baseUrl`。公网 HTTPS 入口不需要 ATS 例外；局域网 HTTP 调试仍依赖 `Info.plist` 中对应主机的 ATS 例外或后续改为 HTTPS。

## 本地 AK/SK 配置

1. 复制 `Resources/OpenApiConfig.example.plist` 为 `Resources/OpenApiConfig.plist`。
2. 填入本机开发用 `baseUrl`、`accessKey`、`secretKey`。
3. `OpenApiConfig.plist` 已加入 `.gitignore`，不要提交真实 AK/SK。
4. Xcode 工程中的 `Copy Local OpenAPI Config` build phase 会在本地配置存在时把它复制进 app bundle。

`MusicVaultConfig.default` 会优先读取用户在设置页保存的运行时配置；没有运行时配置时，Debug 构建才读取 bundle 中的 `OpenApiConfig.plist` 作为开发兜底；macOS 再兼容读取既有 Application Support 配置文件。Release 构建不会注入本地开发 plist。未配置 endpoint 或凭证时客户端会在组请求前报错，避免发出带开发配置的请求。

## iOS / iPadOS 运行时配置

移动端可在设置页“星语音库连接”填写服务地址、Access Key 和 Secret Key：

- 服务地址保存前会去除首尾空格并规范化末尾 `/`，必须为 `http://` 或 `https://`。
- AK 和 SK 必须成对输入才能启用本次运行的 OpenAPI 请求。
- SK 不保存到系统钥匙串、JSON、UserDefaults 或普通 plist，只保存在本次 App 运行内存中。
- 普通配置保存到 App Sandbox 的 Application Support，仅包含 base URL、AK 和配置完成状态。
- 清除凭证会删除普通配置和本次运行内存中的 SK，并立即重载后续 OpenAPI 请求配置；若存在旧版遗留 Keychain 项，也会尝试删除。

## HMAC 签名规则

契约来自 `xingyu-music-vault` v1.1.3 后端文档和测试：

- 请求头：`X-Xingyu-Access-Key`、`X-Xingyu-Timestamp`、`X-Xingyu-Nonce`、`X-Xingyu-Signature-Version: v1`、`X-Xingyu-Signature`
- canonical string 固定 5 行：`METHOD`、`PATH_WITH_CANONICAL_QUERY`、`SHA256_HEX_BODY`、`TIMESTAMP`、`NONCE`
- query 按参数名升序、同名参数按值升序；key/value 使用 form URL encoding，空格编码为 `%20`
- GET/DELETE 无 body 时，body hash 为 SHA-256 空字符串
- HMAC 算法为 `HmacSHA256`，签名输出 lowercase hex
- timestamp 为 Unix epoch milliseconds，默认允许偏移窗口为 300 秒
- 认证失败返回 `401 OPENAPI_UNAUTHORIZED`；scope 不足返回 `403 OPENAPI_FORBIDDEN`

## 建议接入流程

1. 启动时调用 `serverInfo()`，检查 `apiVersion == "v1"` 且 `tracks`、`lyrics`、`artwork` 功能可用。
2. 调用 `syncState()` 获取 `libraryVersion`，与 `MusicVaultCacheStore.syncState()` 中的本地版本比较。
3. 本地曲目需要关联服务端元数据时，调用 `matchTrack(query:)` 获取服务端 track id。
4. 歌词和封面按需加载，优先读取本地 ETag，再用 `lyrics(trackId:ifNoneMatch:)` 和 `artwork(trackId:ifNoneMatch:)` 条件请求。
5. `lyricsMeta(trackId:)` 和 `artworkMeta(trackId:)` 可用于快速判断资源是否存在，避免下载正文。

## 已封装接口

- `serverInfo()`
- `syncState()`
- `syncChanges(sinceVersion:limit:)`
- `tracks(query:)`
- `matchTrack(query:)`
- `track(id:)`
- `lyricsMeta(trackId:)`
- `lyrics(trackId:ifNoneMatch:)`
- `wordLyrics(trackId:ifNoneMatch:)`
- `artworkMeta(trackId:)`
- `artwork(trackId:ifNoneMatch:)`

## 缓存范围

`MusicVaultCacheStore` 当前缓存：

- 服务信息
- 同步状态和 `libraryVersion`
- 本地曲目匹配结果
- 歌词正文和 ETag
- 封面二进制文件、MIME 和 ETag

封面文件写入 app Caches 目录下的 `MusicVaultArtwork`，系统可按需清理；匹配结果和歌词索引写入 `UserDefaults`。SWLRC 与 LRC 使用不同缓存标识，不互相覆盖；旧 LRC 缓存仍可读取。当前不实现完整同步中心、后台自动同步、多服务端管理和复杂 UI。

## 歌词优先级

星语音乐盒 v0.4.2 的歌词策略为：

1. 调用 `lyricsMeta(trackId:)`，若 `wordLyricsAvailable == true`，优先请求 `/tracks/{id}/word-lyrics`。
2. SWLRC 返回 JSON，`format=SWLRC`，`content` 为 SWLRC v1 文本；客户端解析失败会回退 LRC。
3. LRC 使用 `/tracks/{id}/lyrics`，返回同一 JSON 结构，`content` 为标准 LRC 文本。
4. 两种歌词都不可用时展示无歌词状态。
5. 当前不请求 LRCLIB 或其他公共歌词服务。

SWLRC 渲染按 token 的 `startTime` / `endTime` 计算连续进度：歌词 UI 使用 60fps animation timeline 推进独立的显示时间，未播放文字保持暗色，高亮层按区间进度横向填充，因此暂停、拖动和跳转时可以落在字/词内部的精确位置，而不是整字跳变。当前行切换使用弹性滚动动画，减少行级跳动感。

## 注意事项

- 星语音库当前不提供音频流接口，客户端只能使用它补全曲目、歌词、封面等元数据。
- 列表里的 `artworkUrl` 是相对路径，需要用 `MusicVaultApiClient.absoluteURL(forOpenAPIPath:)` 拼成完整 URL。
- 默认公网 HTTPS 入口不需要 ATS 例外；局域网 HTTP 调试时如更换 IP 或端口，需要同步确认 `Info.plist` 的 ATS 配置。
- 不要在日志中打印 Secret Key、签名原文或完整签名。需要定位凭证时仅打印 Access Key 掩码。

## 自测方法

在当前公网 HTTPS 或局域网调试服务上验证：

- `serverInfo()` 返回 `200`，`apiVersion == "v1"`。
- `tracks(query: MusicVaultTrackListQuery(page: 0, pageSize: 20))` 返回曲目列表。
- 对一个 `lyricsAvailable == true` 的曲目调用 `lyrics(trackId:ifNoneMatch:)` 成功。
- 对一个 `artworkAvailable == true` 的曲目调用 `artwork(trackId:ifNoneMatch:)` 成功并能解码图片。
- `syncChanges(sinceVersion: 0, limit: 500)` 返回增量结果。
- 临时把本地 `secretKey` 改错，重新运行后请求应返回 `401`，界面/日志能看到认证错误提示。
- 临时让签名 timestamp 偏离超过 300 秒，后端应返回 `401`；恢复设备时间或签名时间后请求恢复。
- 播放本地歌曲，确认播放控制、歌词展示、封面展示仍按原逻辑降级或展示。
