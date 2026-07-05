import Foundation

enum LyricsSource: String, Codable {
    // Kept for decoding lyrics cached by older builds.
    case lrclib
    case musicVault
}

enum CachedLyricType: String, Codable {
    case lrc
    case swlrc
    case plain
    case instrumental
}

extension Notification.Name {
    static let cachedLyricsDidChange = Notification.Name("xy.cachedLyricsDidChange")
}

struct CachedLyrics: Codable, Equatable {
    let songId: String
    let lyricText: String
    let lyricType: CachedLyricType
    let source: LyricsSource
    let matchedTitle: String
    let matchedArtist: String
    let matchedAlbum: String?
    let fetchedAt: Date
    let lrcLibId: Int?
    let resourceHash: String?
    let resourceEtag: String?
    let updatedAt: String?

    var displayText: String {
        lyricType == .instrumental ? "该曲目标记为纯音乐" : lyricText
    }

    private enum CodingKeys: String, CodingKey {
        case songId
        case lyricText
        case lyricType
        case source
        case matchedTitle
        case matchedArtist
        case matchedAlbum
        case fetchedAt
        case lrcLibId
        case resourceHash
        case resourceEtag
        case updatedAt
    }

    init(
        songId: String,
        lyricText: String,
        lyricType: CachedLyricType,
        source: LyricsSource,
        matchedTitle: String,
        matchedArtist: String,
        matchedAlbum: String?,
        fetchedAt: Date,
        lrcLibId: Int?,
        resourceHash: String?,
        resourceEtag: String?,
        updatedAt: String?
    ) {
        self.songId = songId
        self.lyricText = lyricText
        self.lyricType = lyricType
        self.source = source
        self.matchedTitle = matchedTitle
        self.matchedArtist = matchedArtist
        self.matchedAlbum = matchedAlbum
        self.fetchedAt = fetchedAt
        self.lrcLibId = lrcLibId
        self.resourceHash = resourceHash
        self.resourceEtag = resourceEtag
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        songId = try container.decode(String.self, forKey: .songId)
        lyricText = try container.decode(String.self, forKey: .lyricText)
        lyricType = try container.decode(CachedLyricType.self, forKey: .lyricType)
        source = try container.decode(LyricsSource.self, forKey: .source)
        matchedTitle = try container.decode(String.self, forKey: .matchedTitle)
        matchedArtist = try container.decode(String.self, forKey: .matchedArtist)
        matchedAlbum = try container.decodeIfPresent(String.self, forKey: .matchedAlbum)
        fetchedAt = try container.decode(Date.self, forKey: .fetchedAt)
        lrcLibId = try container.decodeIfPresent(Int.self, forKey: .lrcLibId)
        resourceHash = try container.decodeIfPresent(String.self, forKey: .resourceHash)
        resourceEtag = try container.decodeIfPresent(String.self, forKey: .resourceEtag)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
    }
}

enum LyricsCacheError: LocalizedError {
    case invalidDuration
    case noUsableLyrics

    var errorDescription: String? {
        switch self {
        case .invalidDuration:
            return "时长无效，请填写有效的秒数或留空"
        case .noUsableLyrics:
            return "该结果没有可用歌词"
        }
    }
}

final class LyricsCacheStore {
    static let shared = LyricsCacheStore()

    private let key = "xy.cachedLyrics.v1"
    private let defaults: UserDefaults
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func cachedLyrics(for songId: String) -> CachedLyrics? {
        allLyrics()[songId]
    }

    func save(musicVaultLyrics: MusicVaultLyrics, track: MusicVaultTrack?, etag: String?, for songId: String) throws -> CachedLyrics {
        guard let text = musicVaultLyrics.content.nilIfBlank else {
            throw LyricsCacheError.noUsableLyrics
        }

        let type: CachedLyricType
        if musicVaultLyrics.format?.localizedCaseInsensitiveContains("SWLRC") == true {
            type = .swlrc
        } else if musicVaultLyrics.format?.localizedCaseInsensitiveContains("LRC") == true {
            type = .lrc
        } else {
            type = .plain
        }
        let cached = CachedLyrics(
            songId: songId,
            lyricText: text,
            lyricType: type,
            source: .musicVault,
            matchedTitle: track?.title ?? "星语音库歌词",
            matchedArtist: track?.artist ?? "",
            matchedAlbum: track?.album,
            fetchedAt: Date(),
            lrcLibId: nil,
            resourceHash: musicVaultLyrics.hash,
            resourceEtag: etag,
            updatedAt: musicVaultLyrics.updatedAt
        )

        var lyrics = allLyrics()
        lyrics[songId] = cached
        saveAll(lyrics)
        return cached
    }

    func deleteLyrics(for songId: String) {
        var lyrics = allLyrics()
        lyrics.removeValue(forKey: songId)
        saveAll(lyrics)
    }

    private func allLyrics() -> [String: CachedLyrics] {
        guard let data = defaults.data(forKey: key),
              let lyrics = try? decoder.decode([String: CachedLyrics].self, from: data) else {
            return [:]
        }
        return lyrics
    }

    private func saveAll(_ lyrics: [String: CachedLyrics]) {
        guard let data = try? encoder.encode(lyrics) else { return }
        defaults.set(data, forKey: key)
        NotificationCenter.default.post(name: .cachedLyricsDidChange, object: nil)
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

}
