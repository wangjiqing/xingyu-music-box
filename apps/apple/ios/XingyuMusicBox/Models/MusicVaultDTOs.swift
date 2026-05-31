import Foundation

struct MusicVaultServerInfo: Codable, Equatable {
    let serviceName: String
    let serviceVersion: String
    let apiVersion: String
    let readOnly: Bool
    let features: [String: Bool]

    var supportsRequiredReadFeatures: Bool {
        readOnly
            && apiVersion == "v1"
            && (features["tracks"] ?? false)
            && (features["lyrics"] ?? false)
            && (features["artwork"] ?? false)
    }
}

struct MusicVaultSyncState: Codable, Equatable {
    let libraryVersion: Int64
    let trackCount: Int64
    let artistCount: Int64
    let albumCount: Int64
    let lyricsCount: Int64
    let artworkCount: Int64
    let lastUpdatedAt: String?
    let lastChangedAt: String?
    let changesAvailable: Bool
}

struct MusicVaultTrack: Codable, Equatable, Identifiable {
    let id: Int64
    let title: String
    let artist: String?
    let album: String?
    let albumArtist: String?
    let durationMs: Int64?
    let year: Int?
    let trackNo: Int?
    let genre: String?
    let metadataStatus: String?
    let lyricsStatus: String?
    let artworkStatus: String?
    let fileName: String?
    let fileExtension: String?
    let fileSize: Int64
    let lyricsAvailable: Bool
    let lyricId: Int64?
    let artworkAvailable: Bool
    let artworkId: Int64?
    let artworkUrl: String?
    let createdAt: String?
    let updatedAt: String?

    var displayArtist: String {
        artist?.nilIfBlank ?? "未知歌手"
    }

    var displayAlbum: String {
        album?.nilIfBlank ?? "未知专辑"
    }
}

struct MusicVaultLyrics: Codable, Equatable {
    let trackId: Int64
    let lyricId: Int64?
    let format: String?
    let content: String
    let hash: String?
    let updatedAt: String?
}

struct MusicVaultLyricsMeta: Codable, Equatable {
    let trackId: Int64
    let available: Bool
    let lyricId: Int64?
    let format: String?
    let hash: String?
    let etag: String?
    let updatedAt: String?
}

struct MusicVaultArtworkMeta: Codable, Equatable {
    let trackId: Int64
    let available: Bool
    let artworkId: Int64?
    let mimeType: String?
    let fileSize: Int64?
    let width: Int?
    let height: Int?
    let hash: String?
    let etag: String?
    let updatedAt: String?
}

struct MusicVaultTrackMatch: Codable, Equatable {
    let matched: Bool
    let score: Int
    let reason: String
    let track: MusicVaultTrack?
}

struct MusicVaultErrorResponse: Codable, Equatable {
    let code: String
    let message: String
    let traceId: String?
    let details: [String: String]?
}

struct MusicVaultTrackMatchQuery {
    let title: String
    var artist: String?
    var album: String?
    var durationMs: Int64?

    var queryItems: [URLQueryItem] {
        var items = [URLQueryItem(name: "title", value: title)]
        items.appendIfPresent(name: "artist", value: artist)
        items.appendIfPresent(name: "album", value: album)
        items.appendIfPresent(name: "durationMs", value: durationMs.map(String.init))
        return items
    }
}

struct MusicVaultConditionalResponse<Value> {
    let value: Value?
    let etag: String?
    let contentType: String?
    let notModified: Bool
}

private extension Array where Element == URLQueryItem {
    mutating func appendIfPresent(name: String, value: String?) {
        guard let value = value?.nilIfBlank else { return }
        append(URLQueryItem(name: name, value: value))
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
