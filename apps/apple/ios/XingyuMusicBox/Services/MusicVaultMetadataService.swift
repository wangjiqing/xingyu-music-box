import Foundation

final class MusicVaultMetadataService {
    static let shared = MusicVaultMetadataService()

    private let client: MusicVaultApiClient
    private let cacheStore: MusicVaultCacheStore

    init(
        client: MusicVaultApiClient = .shared,
        cacheStore: MusicVaultCacheStore = .shared
    ) {
        self.client = client
        self.cacheStore = cacheStore
    }

    func fetchMetadata(for song: Song, duration: TimeInterval?) async -> MusicVaultMetadataDisplay? {
        guard let title = song.title.nilIfBlank else {
            debugLog("跳过星语音库元数据：歌曲名为空")
            return nil
        }

        debugLog("开始尝试星语音库元数据：\(title) / \(song.artist)")

        do {
            let match = try await matchTrack(song: song, title: title, duration: duration)
            guard match.matched, let matchedTrack = match.track else {
                debugLog("星语音库元数据 match/track 未命中：\(match.reason)，保持本地显示")
                return nil
            }

            debugLog("星语音库元数据 match/track 命中：trackId=\(matchedTrack.id), score=\(match.score)")

            let track: MusicVaultTrack
            if let cached = cacheStore.cachedTrackDetail(trackId: matchedTrack.id) {
                debugLog("星语音库曲目详情命中缓存：trackId=\(matchedTrack.id)")
                track = cached.track
            } else {
                let detail = try await client.track(id: matchedTrack.id)
                cacheStore.save(trackDetail: detail)
                debugLog("成功获取星语音库曲目详情：trackId=\(detail.id)")
                track = detail
            }

            return MusicVaultMetadataDisplay(track: track, localSong: song)
        } catch {
            debugLog("星语音库元数据失败，保持本地显示：\(error.localizedDescription)")
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

            debugLog("尝试星语音库元数据 match/track title=\(candidate)")
            let match = try await client.matchTrack(query: query)
            cacheStore.save(trackMatch: match, for: query)
            lastMatch = match
            if match.matched {
                return match
            }
        }

        return lastMatch
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
        print("[MusicVaultMetadata] \(message)")
        #endif
    }
}

struct MusicVaultMetadataDisplay: Equatable {
    let trackId: Int64
    let title: String
    let artist: String
    let album: String
    let albumArtist: String?
    let year: Int?
    let genre: String?
    let trackNo: Int?

    init(track: MusicVaultTrack, localSong: Song) {
        trackId = track.id
        title = track.title.nilIfBlank ?? localSong.title
        artist = track.artist?.nilIfBlank ?? localSong.artist
        album = track.album?.nilIfBlank ?? localSong.album
        albumArtist = track.albumArtist?.nilIfBlank
        year = track.year ?? localSong.year
        genre = track.genre?.nilIfBlank ?? localSong.genre
        trackNo = track.trackNo
    }

    var yearText: String {
        year.map(String.init) ?? "未知年份"
    }

    var albumLine: String {
        [album.nilIfBlank, yearText.nilIfBlank].compactMap { $0 }.joined(separator: " · ")
    }

    var detailItems: [String] {
        var values: [String] = []
        if let albumArtist {
            values.append("专辑艺人 \(albumArtist)")
        }
        if let trackNo {
            values.append("曲目 \(trackNo)")
        }
        if let genre {
            values.append(genre)
        }
        values.append("星语音库 #\(trackId)")
        return values
    }
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
