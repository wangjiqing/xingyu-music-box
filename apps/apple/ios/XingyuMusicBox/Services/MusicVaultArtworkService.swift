import Foundation
import UIKit

final class MusicVaultArtworkService {
    static let shared = MusicVaultArtworkService()

    private let client: MusicVaultApiClient
    private let cacheStore: MusicVaultCacheStore

    init(
        client: MusicVaultApiClient = .shared,
        cacheStore: MusicVaultCacheStore = .shared
    ) {
        self.client = client
        self.cacheStore = cacheStore
    }

    func fetchArtwork(for song: Song, duration: TimeInterval?) async -> MusicVaultArtworkFetchResult? {
        guard let title = song.title.nilIfBlank else {
            debugLog("跳过星语音库封面：歌曲名为空")
            return nil
        }

        debugLog("开始尝试星语音库封面：\(title) / \(song.artist)")

        do {
            let match = try await matchTrack(song: song, title: title, duration: duration)
            guard match.matched, let track = match.track else {
                debugLog("星语音库封面 match/track 未命中：\(match.reason)，降级到本地封面 / 默认封面")
                return nil
            }

            debugLog("星语音库封面 match/track 命中：trackId=\(track.id), score=\(match.score)")

            let meta = try await client.fetchArtworkMeta(trackId: track.id)
            debugLog("星语音库 artwork/meta available=\(meta.available), hash=\(meta.hash ?? "nil"), etag=\(meta.etag ?? "nil")")
            guard meta.available else {
                debugLog("星语音库无封面，降级到本地封面 / 默认封面")
                return nil
            }

            let cached = cacheStore.cachedArtwork(trackId: track.id)
            let validCachedImage = cached.flatMap(image(from:))
            if let cached, let image = validCachedImage, isCacheFresh(cached, meta: meta) {
                debugLog("星语音库封面命中本地缓存：trackId=\(track.id)")
                return MusicVaultArtworkFetchResult(image: image, track: track, meta: meta, cached: true)
            }

            let response = try await client.fetchArtwork(trackId: track.id, etag: validCachedImage == nil ? nil : cached?.etag)
            if response.notModified, let image = validCachedImage {
                debugLog("星语音库封面 ETag 未变化，使用缓存：trackId=\(track.id)")
                return MusicVaultArtworkFetchResult(image: image, track: track, meta: meta, cached: true)
            }

            guard let data = response.value, let image = UIImage(data: data) else {
                debugLog("星语音库封面图片解码失败，降级到本地封面 / 默认封面")
                return nil
            }

            let mimeType = response.contentType?.nilIfBlank ?? meta.mimeType
            _ = try cacheStore.saveArtwork(
                data: data,
                etag: response.etag ?? meta.etag,
                mimeType: mimeType,
                hash: meta.hash,
                updatedAt: meta.updatedAt,
                trackId: track.id
            )
            debugLog("成功下载星语音库封面：trackId=\(track.id), mimeType=\(mimeType ?? "unknown")")
            return MusicVaultArtworkFetchResult(image: image, track: track, meta: meta, cached: false)
        } catch {
            debugLog("星语音库封面失败，降级到本地封面 / 默认封面：\(error.localizedDescription)")
            return nil
        }
    }

    private func matchTrack(song: Song, title: String, duration: TimeInterval?) async throws -> MusicVaultTrackMatch {
        let artist = song.artist.nilIfBlank
        let titles = uniqueStrings([
            title.removingLeadingArtistPrefix(artist: artist),
            title
        ])
        var lastMatch = MusicVaultTrackMatch(matched: false, score: 0, reason: "No title candidate matched", track: nil)

        for candidate in titles {
            let query = MusicVaultTrackMatchQuery(
                title: candidate,
                artist: artist,
                album: song.album.nilIfBlank,
                durationMs: durationMs(from: duration)
            )

            if let cached = cacheStore.cachedTrackMatch(for: query) {
                debugLog("使用缓存的 match/track 结果：title=\(candidate), matched=\(cached.match.matched)")
                lastMatch = cached.match
                if cached.match.matched {
                    return cached.match
                }
                continue
            }

            debugLog("尝试星语音库封面 match/track title=\(candidate)")
            let match = try await client.matchTrack(query: query)
            cacheStore.save(trackMatch: match, for: query)
            lastMatch = match
            if match.matched {
                return match
            }
        }

        return lastMatch
    }

    private func isCacheFresh(_ cached: CachedMusicVaultArtwork, meta: MusicVaultArtworkMeta) -> Bool {
        guard FileManager.default.fileExists(atPath: cached.fileURL.path) else {
            return false
        }

        if let cachedHash = cached.hash?.nilIfBlank, let metaHash = meta.hash?.nilIfBlank {
            return cachedHash == metaHash
        }

        if let cachedEtag = cached.etag?.nilIfBlank, let metaEtag = meta.etag?.nilIfBlank {
            return cachedEtag == metaEtag
        }

        return false
    }

    private func image(from cached: CachedMusicVaultArtwork) -> UIImage? {
        guard FileManager.default.fileExists(atPath: cached.fileURL.path) else {
            return nil
        }
        return UIImage(contentsOfFile: cached.fileURL.path)
    }

    private func uniqueStrings(_ values: [String]) -> [String] {
        values.reduce(into: [String]()) { result, value in
            guard let normalized = value.nilIfBlank,
                  !result.contains(where: { $0.normalizedForMusicVaultMatch == normalized.normalizedForMusicVaultMatch }) else {
                return
            }
            result.append(normalized)
        }
    }

    private func durationMs(from duration: TimeInterval?) -> Int64? {
        guard let duration, duration.isFinite, duration > 0 else {
            return nil
        }
        return Int64((duration * 1000).rounded())
    }

    private func debugLog(_ message: String) {
        #if DEBUG
        print("[MusicVaultArtwork] \(message)")
        #endif
    }
}

struct MusicVaultArtworkFetchResult {
    let image: UIImage
    let track: MusicVaultTrack
    let meta: MusicVaultArtworkMeta
    let cached: Bool
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var normalizedForMusicVaultMatch: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .replacingOccurrences(of: " ", with: "")
    }

    func removingLeadingArtistPrefix(artist: String?) -> String {
        guard let artist = artist?.nilIfBlank else {
            return self
        }

        let trimmedTitle = trimmingCharacters(in: .whitespacesAndNewlines)
        let escapedArtist = NSRegularExpression.escapedPattern(for: artist)
        let pattern = #"^\s*\#(escapedArtist)\s*[-－–—:：]\s*"#
        let cleaned = trimmedTitle.replacingOccurrences(
            of: pattern,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        return cleaned.nilIfBlank ?? self
    }
}
