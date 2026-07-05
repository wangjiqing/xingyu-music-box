# 星语音库 OpenAPI 对接

星语音乐盒通过星语音库 OpenAPI 获取服务信息、曲目、歌词、封面、元数据等客户端所需数据。

当前协议文档作为占位，后续将根据星语音库接口逐步补充请求、响应、错误处理和兼容性约定。

多端客户端应优先复用统一协议约定，而不是各端自行发明字段或行为。

## v1.3.2 歌词契约

- OpenAPI 前缀：`/api/open/v1`。
- 歌词元数据：`GET /tracks/{id}/lyrics/meta`，JSON 字段包括 `available`、`format`、`hash`、`etag`、`updatedAt`、`wordLyricsAvailable`、`wordLyricsUrl`、`lyricsVersionSource`。
- LRC 正文：`GET /tracks/{id}/lyrics`，`Content-Type: application/json`，返回 `{ trackId, lyricId, format, content, hash, updatedAt }`，支持 `ETag` 和 `304 Not Modified`；无歌词返回 `404`。
- SWLRC 正文：`GET /tracks/{id}/word-lyrics`，`Content-Type: application/json`，返回同一结构，`format` 为 `SWLRC`，`content` 为 SWLRC v1 纯文本；不存在时返回 `404 OPENAPI_WORD_LYRICS_NOT_FOUND`。
- 客户端优先级：SWLRC -> LRC -> 无歌词。SWLRC 不存在、请求失败或解析失败时回退 LRC。

SWLRC v1 为 UTF-8 文本，首行必须为 `[swlrc:1]`，推荐包含 `[offset:0]` 和 `[tokenization:char|word|mixed]`。歌词行使用 `[MM:SS.mmm,MM:SS.mmm]`，token 使用 `<MM:SS.mmm,MM:SS.mmm>文本`。中文显示文本按 token 文本直接拼接，不按空格拆分。
