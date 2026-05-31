# 星语音库 OpenAPI 接入说明

## 当前默认配置

- 局域网服务地址：`http://192.168.31.101:8080`
- OpenAPI 前缀：`/api/open/v1`
- 集中配置入口：`MusicVaultConfig`
- Swift 客户端入口：`MusicVaultApiClient.shared`
- 本地缓存入口：`MusicVaultCacheStore.shared`
- 当前后端 OpenAPI 版本：`v1`

`musicVaultBaseUrl` 只能从 `MusicVaultConfig.defaultBaseURLString` 或显式注入的 `MusicVaultConfig` 读取，不在调用点散落硬编码。

OpenAPI 默认不需要 token。若服务端开启 `xingyu.openapi.auth.enabled=true`，初始化客户端时用 `MusicVaultConfig(baseURLString:apiToken:)` 传入 token，客户端会自动携带 `Authorization: Bearer <token>`。

```swift
let config = MusicVaultConfig(baseURLString: "http://192.168.31.101:8080")
let client = MusicVaultApiClient(config: config)
```

## 建议接入流程

1. 启动时调用 `serverInfo()`，检查 `apiVersion == "v1"` 且 `tracks`、`lyrics`、`artwork` 功能可用。
2. 调用 `syncState()` 获取 `libraryVersion`，与 `MusicVaultCacheStore.syncState()` 中的本地版本比较。
3. 本地曲目需要关联服务端元数据时，调用 `matchTrack(query:)` 获取服务端 track id。
4. 歌词和封面按需加载，优先读取本地 ETag，再用 `lyrics(trackId:ifNoneMatch:)` 和 `artwork(trackId:ifNoneMatch:)` 条件请求。
5. `lyricsMeta(trackId:)` 和 `artworkMeta(trackId:)` 可用于快速判断资源是否存在，避免下载正文。

## 已封装接口

- `serverInfo()`
- `syncState()`
- `matchTrack(query:)`
- `lyricsMeta(trackId:)`
- `lyrics(trackId:ifNoneMatch:)`
- `artworkMeta(trackId:)`
- `artwork(trackId:ifNoneMatch:)`

## 缓存范围

`MusicVaultCacheStore` 当前缓存：

- 服务信息
- 同步状态和 `libraryVersion`
- 本地曲目匹配结果
- 歌词正文和 ETag
- 封面二进制文件、MIME 和 ETag

封面文件写入 app Caches 目录下的 `MusicVaultArtwork`，系统可按需清理；匹配结果和歌词索引写入 `UserDefaults`。当前不实现完整同步中心、后台自动同步、多服务端管理和复杂 UI。

## 注意事项

- 星语音库当前不提供音频流接口，客户端只能使用它补全曲目、歌词、封面等元数据。
- 列表里的 `artworkUrl` 是相对路径，需要用 `MusicVaultApiClient.absoluteURL(forOpenAPIPath:)` 拼成完整 URL。
- 局域网 HTTP 已在 `Info.plist` 中为 `192.168.31.101` 配置 ATS 例外；换 IP 或域名后需要同步更新配置。

## 实测响应

2026-05-30 在当前局域网服务 `http://192.168.31.101:8080` 上验证：

- `GET /api/open/v1/server/info` 返回 `200`，`serviceVersion` 为 `0.9.3`，`apiVersion` 为 `v1`。
- `GET /api/open/v1/sync/state` 返回 `200`，当前 `libraryVersion` 为 `1`，`trackCount` 为 `0`。
- `GET /api/open/v1/match/track?title=test` 返回 `200`，`matched: false`，`reason: "No exact title match"`。
- 当前库为空，`GET /api/open/v1/tracks/1/lyrics/meta` 与 `artwork/meta` 返回 `404 OPENAPI_TRACK_NOT_FOUND`。
