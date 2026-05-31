import Foundation

final class MusicVaultLyricsService {
    static let shared = MusicVaultLyricsService()

    private let client: MusicVaultApiClient

    init(client: MusicVaultApiClient = .shared) {
        self.client = client
    }

    func fetchLyrics(for song: Song, duration: TimeInterval?) async -> MusicVaultLyricsFetchResult? {
        guard let title = song.title.nilIfBlank else {
            debugLog("跳过星语音库歌词：歌曲名为空")
            return nil
        }

        debugLog("开始尝试星语音库歌词：\(title) / \(song.artist)")

        do {
            let match = try await matchTrack(song: song, title: title, duration: duration)

            guard match.matched, let track = match.track else {
                debugLog("星语音库 match/track 未命中：\(match.reason)")
                return nil
            }

            debugLog("星语音库 match/track 命中：trackId=\(track.id), score=\(match.score)")

            let meta = try await client.lyricsMeta(trackId: track.id)
            debugLog("星语音库 lyrics/meta available=\(meta.available)")
            guard meta.available else {
                debugLog("星语音库无歌词，停止联网歌词获取")
                return nil
            }

            let cached = MusicVaultCacheStore.shared.cachedLyrics(trackId: track.id)
            let response = try await client.lyrics(trackId: track.id, ifNoneMatch: cached?.etag)
            if response.notModified, let cached {
                debugLog("星语音库歌词 ETag 未变化，使用 MusicVaultCacheStore 缓存")
                return MusicVaultLyricsFetchResult(lyrics: cached.lyrics, track: track, etag: cached.etag)
            }

            guard let lyrics = response.value, lyrics.content.nilIfBlank != nil else {
                debugLog("星语音库歌词正文为空，停止联网歌词获取")
                return nil
            }

            MusicVaultCacheStore.shared.save(lyrics: lyrics, etag: response.etag, trackId: track.id)
            debugLog("成功获取星语音库歌词：trackId=\(track.id), format=\(lyrics.format ?? "unknown")")
            return MusicVaultLyricsFetchResult(lyrics: lyrics, track: track, etag: response.etag)
        } catch {
            debugLog("星语音库歌词失败，停止联网歌词获取：\(error.localizedDescription)")
            return nil
        }
    }

    private func matchTrack(song: Song, title: String, duration: TimeInterval?) async throws -> MusicVaultTrackMatch {
        let artist = song.artist.nilIfBlank
        let titles = matchTitles(title: title, artist: artist)
        var lastMatch = MusicVaultTrackMatch(matched: false, score: 0, reason: "No title candidate matched", track: nil)

        for candidate in titles {
            debugLog("尝试星语音库 match/track title=\(candidate)")
            let match = try await client.matchTrack(
                query: MusicVaultTrackMatchQuery(
                    title: candidate,
                    artist: artist,
                    album: song.album.nilIfBlank,
                    durationMs: durationMs(from: duration)
                )
            )
            lastMatch = match
            if match.matched {
                return match
            }
        }

        return lastMatch
    }

    private func matchTitles(title: String, artist: String?) -> [String] {
        uniqueStrings([
            title.removingLeadingArtistPrefix(artist: artist),
            title
        ])
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
        print("[MusicVaultLyrics] \(message)")
        #endif
    }
}

struct MusicVaultLyricsFetchResult {
    let lyrics: MusicVaultLyrics
    let track: MusicVaultTrack?
    let etag: String?
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
        return cleaned.nilIfBlank ?? trimmedTitle
    }
}
