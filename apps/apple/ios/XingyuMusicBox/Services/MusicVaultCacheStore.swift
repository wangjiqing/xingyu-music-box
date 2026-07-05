import Foundation

extension Notification.Name {
    static let musicVaultCacheDidChange = Notification.Name("xy.musicVaultCacheDidChange")
}

struct CachedMusicVaultLyrics: Codable, Equatable {
    let trackId: Int64
    let lyrics: MusicVaultLyrics
    let etag: String?
    let lyricType: LyricDocumentType
    let hash: String?
    let updatedAt: String?
    let fetchedAt: Date

    init(
        trackId: Int64,
        lyrics: MusicVaultLyrics,
        etag: String?,
        lyricType: LyricDocumentType,
        hash: String? = nil,
        updatedAt: String? = nil,
        fetchedAt: Date = Date()
    ) {
        self.trackId = trackId
        self.lyrics = lyrics
        self.etag = etag
        self.lyricType = lyricType
        self.hash = hash ?? lyrics.hash
        self.updatedAt = updatedAt ?? lyrics.updatedAt
        self.fetchedAt = fetchedAt
    }

    private enum CodingKeys: String, CodingKey {
        case trackId
        case lyrics
        case etag
        case lyricType
        case hash
        case updatedAt
        case fetchedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        trackId = try container.decode(Int64.self, forKey: .trackId)
        lyrics = try container.decode(MusicVaultLyrics.self, forKey: .lyrics)
        etag = try container.decodeIfPresent(String.self, forKey: .etag)
        lyricType = try container.decodeIfPresent(LyricDocumentType.self, forKey: .lyricType)
            ?? (lyrics.format?.localizedCaseInsensitiveContains("SWLRC") == true ? .swlrc : .lrc)
        hash = try container.decodeIfPresent(String.self, forKey: .hash) ?? lyrics.hash
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt) ?? lyrics.updatedAt
        fetchedAt = try container.decode(Date.self, forKey: .fetchedAt)
    }
}

struct CachedMusicVaultArtwork: Codable, Equatable {
    let trackId: Int64
    let fileURL: URL
    let etag: String?
    let mimeType: String?
    let hash: String?
    let updatedAt: String?
    let fetchedAt: Date
}

struct CachedMusicVaultTrackMatch: Codable, Equatable {
    let cacheKey: String
    let match: MusicVaultTrackMatch
    let fetchedAt: Date
}

struct CachedMusicVaultTrackDetail: Codable, Equatable {
    let trackId: Int64
    let track: MusicVaultTrack
    let fetchedAt: Date
}

final class MusicVaultCacheStore {
    static let shared = MusicVaultCacheStore()

    private let defaults: UserDefaults
    private let fileManager: FileManager
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private let serverInfoKey = "xy.musicVault.serverInfo.v1"
    private let syncStateKey = "xy.musicVault.syncState.v1"
    private let trackMatchesKey = "xy.musicVault.trackMatches.v1"
    private let trackDetailsKey = "xy.musicVault.trackDetails.v1"
    private let lyricsKey = "xy.musicVault.lyrics.v1"
    private let typedLyricsKey = "xy.musicVault.lyrics.v2"
    private let artworkIndexKey = "xy.musicVault.artworkIndex.v1"

    init(defaults: UserDefaults = .standard, fileManager: FileManager = .default) {
        self.defaults = defaults
        self.fileManager = fileManager
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func serverInfo() -> MusicVaultServerInfo? {
        read(MusicVaultServerInfo.self, forKey: serverInfoKey)
    }

    func save(serverInfo: MusicVaultServerInfo) {
        write(serverInfo, forKey: serverInfoKey)
    }

    func syncState() -> MusicVaultSyncState? {
        read(MusicVaultSyncState.self, forKey: syncStateKey)
    }

    func save(syncState: MusicVaultSyncState) {
        write(syncState, forKey: syncStateKey)
    }

    func cachedLyrics(trackId: Int64, type: LyricDocumentType = .lrc) -> CachedMusicVaultLyrics? {
        typedCachedLyricsIndex()[cacheKey(trackId: trackId, type: type)]
            ?? (type == .lrc ? cachedLyricsIndex()[String(trackId)] : nil)
    }

    func save(lyrics: MusicVaultLyrics, etag: String?, trackId: Int64, type: LyricDocumentType) {
        var values = typedCachedLyricsIndex()
        values[cacheKey(trackId: trackId, type: type)] = CachedMusicVaultLyrics(
            trackId: trackId,
            lyrics: lyrics,
            etag: etag,
            lyricType: type
        )
        write(values, forKey: typedLyricsKey)
    }

    func cachedTrackMatch(for query: MusicVaultTrackMatchQuery) -> CachedMusicVaultTrackMatch? {
        cachedTrackMatches()[cacheKey(for: query)]
    }

    func save(trackMatch: MusicVaultTrackMatch, for query: MusicVaultTrackMatchQuery) {
        let key = cacheKey(for: query)
        var values = cachedTrackMatches()
        values[key] = CachedMusicVaultTrackMatch(cacheKey: key, match: trackMatch, fetchedAt: Date())
        write(values, forKey: trackMatchesKey)
    }

    func cachedTrackDetail(trackId: Int64) -> CachedMusicVaultTrackDetail? {
        cachedTrackDetails()[String(trackId)]
    }

    func save(trackDetail: MusicVaultTrack) {
        var values = cachedTrackDetails()
        values[String(trackDetail.id)] = CachedMusicVaultTrackDetail(trackId: trackDetail.id, track: trackDetail, fetchedAt: Date())
        write(values, forKey: trackDetailsKey)
    }

    func cachedArtwork(trackId: Int64) -> CachedMusicVaultArtwork? {
        cachedArtworkIndex()[String(trackId)]
    }

    func saveArtwork(data: Data, etag: String?, mimeType: String?, hash: String?, updatedAt: String?, trackId: Int64) throws -> CachedMusicVaultArtwork {
        let directory = try artworkDirectory()
        let fileURL = directory.appendingPathComponent("track-\(trackId).\(fileExtension(for: mimeType))")
        try data.write(to: fileURL, options: [.atomic])

        let cached = CachedMusicVaultArtwork(
            trackId: trackId,
            fileURL: fileURL,
            etag: etag,
            mimeType: mimeType,
            hash: hash,
            updatedAt: updatedAt,
            fetchedAt: Date()
        )
        var values = cachedArtworkIndex()
        values[String(trackId)] = cached
        write(values, forKey: artworkIndexKey)
        return cached
    }

    func clearAll() {
        [serverInfoKey, syncStateKey, trackMatchesKey, trackDetailsKey, lyricsKey, typedLyricsKey, artworkIndexKey].forEach(defaults.removeObject(forKey:))
        if let directory = try? artworkDirectory(), fileManager.fileExists(atPath: directory.path) {
            try? fileManager.removeItem(at: directory)
        }
        NotificationCenter.default.post(name: .musicVaultCacheDidChange, object: nil)
    }

    private func cachedLyricsIndex() -> [String: CachedMusicVaultLyrics] {
        read([String: CachedMusicVaultLyrics].self, forKey: lyricsKey) ?? [:]
    }

    private func typedCachedLyricsIndex() -> [String: CachedMusicVaultLyrics] {
        read([String: CachedMusicVaultLyrics].self, forKey: typedLyricsKey) ?? [:]
    }

    private func cacheKey(trackId: Int64, type: LyricDocumentType) -> String {
        "\(trackId)-\(type.rawValue)"
    }

    private func cachedTrackMatches() -> [String: CachedMusicVaultTrackMatch] {
        read([String: CachedMusicVaultTrackMatch].self, forKey: trackMatchesKey) ?? [:]
    }

    private func cachedTrackDetails() -> [String: CachedMusicVaultTrackDetail] {
        read([String: CachedMusicVaultTrackDetail].self, forKey: trackDetailsKey) ?? [:]
    }

    private func cachedArtworkIndex() -> [String: CachedMusicVaultArtwork] {
        read([String: CachedMusicVaultArtwork].self, forKey: artworkIndexKey) ?? [:]
    }

    private func read<Value: Decodable>(_ type: Value.Type, forKey key: String) -> Value? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? decoder.decode(type, from: data)
    }

    private func write<Value: Encodable>(_ value: Value, forKey key: String) {
        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: key)
        NotificationCenter.default.post(name: .musicVaultCacheDidChange, object: nil)
    }

    private func artworkDirectory() throws -> URL {
        let caches = try fileManager.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = caches.appendingPathComponent("MusicVaultArtwork", isDirectory: true)
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }

    private func fileExtension(for mimeType: String?) -> String {
        switch mimeType?.lowercased() {
        case "image/png":
            return "png"
        case "image/webp":
            return "webp"
        default:
            return "jpg"
        }
    }

    private func cacheKey(for query: MusicVaultTrackMatchQuery) -> String {
        [
            query.title.normalizedCachePart,
            query.artist?.normalizedCachePart ?? "",
            query.album?.normalizedCachePart ?? "",
            query.durationMs.map(String.init) ?? ""
        ].joined(separator: "|")
    }
}

private extension String {
    var normalizedCachePart: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}
