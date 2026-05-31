import Foundation

enum SongSourceType: String, Codable, Hashable {
    case bundled
    case mediaLibrary
}

struct Song: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let artist: String
    let album: String
    let duration: String
    let src: String
    let audioSources: [AudioSource]
    let cover: String
    let year: Int?
    let genre: String?
    let lyrics: String?
    let sourceType: SongSourceType
    let assetURL: URL?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case artist
        case album
        case duration
        case src
        case sources
        case audioSources
        case cover
        case year
        case genre
        case lyrics
        case sourceType
        case assetURL
    }

    init(
        id: String,
        title: String,
        artist: String,
        album: String,
        duration: String,
        src: String,
        audioSources: [AudioSource],
        cover: String,
        year: Int?,
        genre: String?,
        lyrics: String?,
        sourceType: SongSourceType = .bundled,
        assetURL: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.src = src
        self.audioSources = Song.uniqueSources(audioSources)
        self.cover = cover
        self.year = year
        self.genre = genre
        self.lyrics = lyrics
        self.sourceType = sourceType
        self.assetURL = assetURL
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        artist = try container.decode(String.self, forKey: .artist)
        album = try container.decode(String.self, forKey: .album)
        duration = try container.decode(String.self, forKey: .duration)
        src = try container.decode(String.self, forKey: .src)
        cover = try container.decode(String.self, forKey: .cover)
        year = try container.decodeIfPresent(Int.self, forKey: .year)
        genre = try container.decodeIfPresent(String.self, forKey: .genre)
        lyrics = try Song.decodeLyrics(from: container)
        sourceType = try container.decodeIfPresent(SongSourceType.self, forKey: .sourceType) ?? .bundled
        assetURL = try container.decodeIfPresent(URL.self, forKey: .assetURL)

        var decodedSources = try container.decodeIfPresent([AudioSource].self, forKey: .audioSources) ?? []
        decodedSources.append(contentsOf: try container.decodeIfPresent([AudioSource].self, forKey: .sources) ?? [])

        if let source = AudioSource(filename: src) {
            decodedSources.append(source)
        }

        audioSources = Song.uniqueSources(decodedSources)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(artist, forKey: .artist)
        try container.encode(album, forKey: .album)
        try container.encode(duration, forKey: .duration)
        try container.encode(src, forKey: .src)
        try container.encode(audioSources, forKey: .audioSources)
        try container.encode(cover, forKey: .cover)
        try container.encodeIfPresent(year, forKey: .year)
        try container.encodeIfPresent(genre, forKey: .genre)
        try container.encodeIfPresent(lyrics, forKey: .lyrics)
        try container.encode(sourceType, forKey: .sourceType)
        try container.encodeIfPresent(assetURL, forKey: .assetURL)
    }

    var displayYear: String {
        year.map(String.init) ?? "未知年份"
    }

    var primarySource: String {
        audioSources.first?.filename ?? src
    }

    var isMediaLibrarySong: Bool {
        sourceType == .mediaLibrary
    }

    var playableSourceCandidates: [AudioSource] {
        audioSources.sorted { lhs, rhs in
            if lhs.format.priority == rhs.format.priority {
                return lhs.filename < rhs.filename
            }
            return lhs.format.priority < rhs.format.priority
        }
    }

    private static func uniqueSources(_ sources: [AudioSource]) -> [AudioSource] {
        sources.reduce(into: [AudioSource]()) { result, source in
            guard !result.contains(where: { $0.format == source.format && $0.filename == source.filename }) else { return }
            result.append(source)
        }
    }

    private static func decodeLyrics(from container: KeyedDecodingContainer<CodingKeys>) throws -> String? {
        if let text = try container.decodeIfPresent(String.self, forKey: .lyrics)?.nilIfBlank {
            return text
        }

        let lines = try container.decodeIfPresent([String].self, forKey: .lyrics) ?? []
        let text = lines.joined(separator: "\n")
        return text.nilIfBlank
    }
}

private extension AudioSource {
    init?(filename: String) {
        guard let format = AudioFormat(filename: filename) else { return nil }
        self.init(format: format, filename: filename)
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : self
    }
}
