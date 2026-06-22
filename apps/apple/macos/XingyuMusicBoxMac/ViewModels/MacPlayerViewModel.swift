import AppKit
import AVFoundation
import CoreMedia
import Foundation

enum MacLibrarySection: String, CaseIterable, Identifiable {
    case favorites
    case recent
    case local

    var id: String { rawValue }

    var title: String {
        switch self {
        case .favorites: return "喜欢"
        case .recent: return "最近"
        case .local: return "本地"
        }
    }

    var systemImage: String {
        switch self {
        case .favorites: return "heart"
        case .recent: return "clock"
        case .local: return "arrow.down.circle"
        }
    }
}

enum MacTrackSource: String {
    case musicVault = "星语音库"
    case localFolder = "本地目录"
}

enum MacPlaybackMode: CaseIterable, Equatable {
    case sequential
    case repeatOne
    case shuffle

    var title: String {
        switch self {
        case .sequential: return "顺序播放"
        case .repeatOne: return "单曲循环"
        case .shuffle: return "随机播放"
        }
    }

    var systemImage: String {
        switch self {
        case .sequential: return "repeat"
        case .repeatOne: return "repeat.1"
        case .shuffle: return "shuffle"
        }
    }

    var persistenceValue: String {
        switch self {
        case .sequential: return "sequential"
        case .repeatOne: return "repeatOne"
        case .shuffle: return "shuffle"
        }
    }
}

struct MacTrackItem: Identifiable {
    let id: String
    let title: String
    let artist: String
    let album: String
    let durationMs: Int64?
    let artworkData: Data?
    let qualityBadge: String?
    let source: MacTrackSource
    let remoteTrack: MusicVaultTrack?
    let localURL: URL?
    let securityScopedRootURL: URL?

    init(remoteTrack: MusicVaultTrack) {
        id = "vault-\(remoteTrack.id)"
        title = remoteTrack.title
        artist = remoteTrack.displayArtist
        album = remoteTrack.displayAlbum
        durationMs = remoteTrack.durationMs
        artworkData = nil
        qualityBadge = MacAudioQualityBadge.infer(
            fileExtension: remoteTrack.fileExtension,
            fileSize: remoteTrack.fileSize,
            durationMs: remoteTrack.durationMs
        )
        source = .musicVault
        self.remoteTrack = remoteTrack
        localURL = nil
        securityScopedRootURL = nil
    }

    init(
        localURL: URL,
        securityScopedRootURL: URL,
        title: String,
        artist: String,
        album: String,
        durationMs: Int64?,
        artworkData: Data?,
        qualityBadge: String?,
        remoteTrack: MusicVaultTrack? = nil
    ) {
        id = "local-\(localURL.path)"
        self.title = title
        self.artist = artist
        self.album = album
        self.durationMs = durationMs
        self.artworkData = artworkData
        self.qualityBadge = qualityBadge
        source = .localFolder
        self.remoteTrack = remoteTrack
        self.localURL = localURL
        self.securityScopedRootURL = securityScopedRootURL
    }

    func applyingMusicVault(track: MusicVaultTrack, artworkData vaultArtworkData: Data?) -> MacTrackItem {
        guard let localURL, let securityScopedRootURL else {
            return MacTrackItem(remoteTrack: track)
        }

        return MacTrackItem(
            localURL: localURL,
            securityScopedRootURL: securityScopedRootURL,
            title: track.title.nilIfBlank ?? title,
            artist: track.artist?.nilIfBlank ?? artist,
            album: track.album?.nilIfBlank ?? album,
            durationMs: track.durationMs ?? durationMs,
            artworkData: vaultArtworkData ?? artworkData,
            qualityBadge: MacAudioQualityBadge.infer(
                fileExtension: track.fileExtension ?? localURL.pathExtension,
                fileSize: track.fileSize,
                durationMs: track.durationMs ?? durationMs
            ) ?? qualityBadge,
            remoteTrack: track
        )
    }
}

@MainActor
final class MacPlayerViewModel: ObservableObject {
    @Published var selectedSection: MacLibrarySection = .local
    @Published var isShowingSettings = false
    @Published var selectedTrackID: String?
    @Published private(set) var tracks: [MacTrackItem] = []
    @Published private(set) var localTracks: [MacTrackItem] = []
    @Published private(set) var recentTrackIDs: [String] = []
    @Published private(set) var favoriteTrackIDs: Set<String> = []
    @Published private(set) var lyricsPreview = "暂无歌词"
    @Published private(set) var lyricLines: [LyricLine] = []
    @Published private(set) var lyricSourceDescription = "星语音库歌词"
    @Published private(set) var isLoading = false
    @Published private(set) var isImportingLocalFolder = false
    @Published private(set) var isPlaying = false
    @Published private(set) var currentTime: Double = 0
    @Published private(set) var duration: Double = 0
    @Published private(set) var playbackMode: MacPlaybackMode = .sequential
    @Published private(set) var volume: Double = 0.50
    @Published private(set) var message = "可导入本地歌曲目录"
    @Published private(set) var errorMessage: String?

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private var failureObserver: NSObjectProtocol?
    private var importedFolderAccessURLs: [URL] = []
    private var playbackAccessURL: URL?
    private let recentTrackIDsKey = "macRecentTrackIDs"
    private let favoriteTrackIDsKey = "macFavoriteTrackIDs"
    private let localFolderBookmarkDataKey = "macLocalFolderBookmarkData"
    private let localFolderPathKey = "macLocalFolderPath"
    private let playbackPersistence = PlaybackPersistence(store: PlaybackStateStore(defaults: UserDefaults.standard))
    private let supportedLocalAudioExtensions: Set<String> = ["mp3", "m4a", "flac", "aac", "wav", "aif", "aiff"]
    private var restoredCheckpointID: String?
    private var lastNowPlayingTrackID: String?
    private var lastNowPlayingDuration: Double = 0
    private var lastNowPlayingElapsedUpdate = Date.distantPast
    private var runtimeServicesStarted = false

    init() {
        recentTrackIDs = UserDefaults.standard.stringArray(forKey: recentTrackIDsKey) ?? []
        favoriteTrackIDs = Set(UserDefaults.standard.stringArray(forKey: favoriteTrackIDsKey) ?? [])
    }

    deinit {
        if let timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        if let failureObserver {
            NotificationCenter.default.removeObserver(failureObserver)
        }
        playbackAccessURL?.stopAccessingSecurityScopedResource()
        importedFolderAccessURLs.forEach { $0.stopAccessingSecurityScopedResource() }
        Task { @MainActor in
            RemoteCommandManager.shared.removeTargets()
        }
    }

    var selectedTrack: MacTrackItem? {
        guard let selectedTrackID else { return currentTrack ?? tracks.first }
        return tracks.first { $0.id == selectedTrackID } ?? currentTrack
    }

    var currentTrack: MacTrackItem?

    private var client: MusicVaultApiClient {
        MusicVaultApiClient.shared
    }

    var albums: [String] {
        uniqueValues(tracks.map(\.album))
    }

    var artists: [String] {
        uniqueValues(tracks.map(\.artist))
    }

    var favoriteCount: Int {
        favoriteTrackIDs.count
    }

    var recentCount: Int {
        recentTrackIDs.count
    }

    var localCount: Int {
        localTracks.count
    }

    var recentTracks: [MacTrackItem] {
        tracksByID(ids: recentTrackIDs)
    }

    var favoriteTracks: [MacTrackItem] {
        tracks.filter { favoriteTrackIDs.contains($0.id) }
    }

    var currentLyricLineIndex: Int? {
        guard !lyricLines.isEmpty else { return nil }
        let current = max(currentTime, 0)
        let index = lyricLines.lastIndex { $0.time <= current } ?? 0
        return lyricLines[index].index
    }

    var menuBarDisplayText: String {
        if let currentLyricLineIndex,
           let line = lyricLines.first(where: { $0.index == currentLyricLineIndex })?.displayText.nilIfBlank {
            return line
        }

        let previewLine = lyricsPreview
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty && !$0.localizedCaseInsensitiveContains("暂无歌词") }

        if let previewLine {
            return previewLine
        }

        if let currentTrack {
            return "\(currentTrack.title) - \(currentTrack.artist)"
        }

        return "星语音乐盒"
    }

    func startRuntimeServicesIfNeeded() {
        guard !runtimeServicesStarted else { return }
        runtimeServicesStarted = true

        Task { @MainActor in
            await Task.yield()
            setupRemoteCommands()
            restorePersistedLocalFolder()
        }
    }

    func isFavorite(_ track: MacTrackItem?) -> Bool {
        guard let track else { return false }
        return favoriteTrackIDs.contains(track.id)
    }

    func importLocalFolder(_ folderURL: URL) {
        guard !isImportingLocalFolder else { return }
        isImportingLocalFolder = true
        errorMessage = nil
        message = "正在导入本地歌曲目录"

        Task {
            do {
                try await loadLocalFolder(folderURL)
                persistLocalFolderBookmark(for: folderURL)
                message = localTracks.isEmpty ? "未在目录中找到可播放音频" : "已导入 \(localTracks.count) 首本地歌曲"
                if !localTracks.isEmpty {
                    Task {
                        await enrichLocalTracksFromMusicVault()
                    }
                }
            } catch {
                errorMessage = error.localizedDescription
                message = "导入失败"
            }
            isImportingLocalFolder = false
        }
    }

    private func localTracks(in folderURL: URL) async throws -> [MacTrackItem] {
        var items: [MacTrackItem] = []
        for fileURL in try localAudioFileURLs(in: folderURL) {
            items.append(await localTrackItem(for: fileURL, securityScopedRootURL: folderURL))
        }
        return items.sorted { lhs, rhs in
            if lhs.artist == rhs.artist {
                return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
            }
            return lhs.artist.localizedStandardCompare(rhs.artist) == .orderedAscending
        }
    }

    private func localAudioFileURLs(in folderURL: URL) throws -> [URL] {
        let resourceKeys: Set<URLResourceKey> = [.isRegularFileKey, .nameKey]
        guard let enumerator = FileManager.default.enumerator(
            at: folderURL,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return []
        }

        var urls: [URL] = []
        for case let fileURL as URL in enumerator {
            let values = try fileURL.resourceValues(forKeys: resourceKeys)
            guard values.isRegularFile == true,
                  supportedLocalAudioExtensions.contains(fileURL.pathExtension.lowercased()) else {
                continue
            }
            urls.append(fileURL)
        }
        return urls
    }

    private func localTrackItem(for url: URL, securityScopedRootURL: URL) async -> MacTrackItem {
        let asset = AVURLAsset(url: url)
        let duration = try? await asset.load(.duration)
        let metadata = await localMetadataItems(for: asset)
        let title = metadata.stringValue(
            commonKey: .commonKeyTitle,
            identifiers: [.commonIdentifierTitle],
            rawKeys: ["tit2", "title", "©nam", "name"]
        ) ?? url.deletingPathExtension().lastPathComponent
        let artist = metadata.stringValue(
            commonKey: .commonKeyArtist,
            identifiers: [.commonIdentifierArtist],
            rawKeys: ["tpe1", "artist", "©art", "author"]
        ) ?? "未知歌手"
        let album = metadata.stringValue(
            commonKey: .commonKeyAlbumName,
            identifiers: [.commonIdentifierAlbumName],
            rawKeys: ["talb", "album", "©alb"]
        ) ?? "本地音乐"
        let durationMs = duration?.seconds.isFinite == true ? Int64((duration!.seconds * 1000).rounded()) : nil
        let artworkData = metadata.artworkData()
        let audioTraits = await localAudioTraits(for: asset)
        let qualityBadge = MacAudioQualityBadge.infer(
            metadataItems: metadata,
            fileExtension: url.pathExtension,
            fileSize: fileSize(for: url),
            durationMs: durationMs,
            traits: audioTraits
        )
        return MacTrackItem(
            localURL: url,
            securityScopedRootURL: securityScopedRootURL,
            title: title,
            artist: artist,
            album: album,
            durationMs: durationMs,
            artworkData: artworkData,
            qualityBadge: qualityBadge
        )
    }

    private func localAudioTraits(for asset: AVURLAsset) async -> MacAudioTraits {
        let audioTracks = ((try? await asset.load(.tracks)) ?? []).filter { $0.mediaType == .audio }
        var traits = MacAudioTraits()
        for track in audioTracks {
            let descriptions = (try? await track.load(.formatDescriptions)) ?? []
            for description in descriptions {
                guard let streamDescription = CMAudioFormatDescriptionGetStreamBasicDescription(description) else {
                    continue
                }
                traits.channelCount = max(traits.channelCount, Int(streamDescription.pointee.mChannelsPerFrame))
                traits.sampleRate = max(traits.sampleRate, streamDescription.pointee.mSampleRate)
                traits.bitsPerChannel = max(traits.bitsPerChannel, Int(streamDescription.pointee.mBitsPerChannel))
            }
        }
        return traits
    }

    private func fileSize(for url: URL) -> Int64? {
        (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init)
    }

    private func localMetadataItems(for asset: AVURLAsset) async -> [AVMetadataItem] {
        var items = (try? await asset.load(.commonMetadata)) ?? []
        guard let formats = try? await asset.load(.availableMetadataFormats) else {
            return items
        }

        for format in formats {
            items.append(contentsOf: (try? await asset.loadMetadata(for: format)) ?? [])
        }
        return items
    }

    private func mergeTracks() {
        tracks = localTracks
    }

    func select(_ track: MacTrackItem) {
        selectedTrackID = track.id
        if let remoteTrack = track.remoteTrack {
            Task {
                await loadLyrics(for: remoteTrack)
            }
        } else {
            clearLyrics(message: "星语音库暂未匹配到歌词")
        }
    }

    func play(_ track: MacTrackItem) {
        load(track, shouldPlay: true, startTime: 0)
    }

    private func load(_ track: MacTrackItem, shouldPlay: Bool, startTime: Double) {
        selectedTrackID = track.id
        currentTrack = track
        errorMessage = nil
        message = "正在载入：\(track.title)"
        cleanupPlaybackObservers()

        do {
            let item: AVPlayerItem
            if let localURL = track.localURL {
                startPlaybackAccess(for: track)
                item = AVPlayerItem(url: localURL)
                if let remoteTrack = track.remoteTrack {
                    Task {
                        await loadLyrics(for: remoteTrack)
                    }
                } else {
                    clearLyrics(message: "星语音库暂未匹配到歌词")
                }
            } else if let remoteTrack = track.remoteTrack {
                let request = try client.audioStreamRequest(trackId: remoteTrack.id)
                let asset = AVURLAsset(url: request.url!, options: [
                    "AVURLAssetHTTPHeaderFieldsKey": request.allHTTPHeaderFields ?? [:]
                ])
                item = AVPlayerItem(asset: asset)
            } else {
                throw MusicVaultApiError.invalidURL
            }
            player = AVPlayer(playerItem: item)
            player?.volume = Float(volume)
            observeProgress()
            observePlaybackEnd(for: item)
            observePlaybackFailure(for: item)
            if startTime > 0 {
                let target = max(0, startTime)
                player?.seek(to: CMTime(seconds: target, preferredTimescale: 600))
                currentTime = target
            }
            if shouldPlay {
                player?.play()
                isPlaying = true
                recordRecentTrack(track)
                message = "正在播放：\(track.title)"
            } else {
                isPlaying = false
                message = "已恢复：\(track.title)"
            }
            persistPlaybackCheckpoint(currentTimeOverride: startTime)
            updateNowPlayingInfo(for: track, elapsedTime: startTime)
            Task {
                await loadDuration(for: item, fallback: track.durationMs)
                if let remoteTrack = track.remoteTrack {
                    await loadLyrics(for: remoteTrack)
                }
                await MainActor.run {
                    updateNowPlayingInfo(for: track)
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            message = "播放失败"
            isPlaying = false
            NowPlayingInfoManager.shared.clear()
        }
    }

    func togglePlayback() {
        if player == nil, let track = selectedTrack {
            play(track)
            return
        }
        if isPlaying {
            player?.pause()
            isPlaying = false
        } else {
            player?.play()
            isPlaying = true
        }
        persistPlaybackCheckpoint()
        syncPlaybackStateToNowPlaying()
    }

    func previous() {
        guard let track = track(offset: -1) else { return }
        play(track)
    }

    func next() {
        guard let track = nextTrackForUserAction() else { return }
        play(track)
    }

    func cyclePlaybackMode() {
        guard let currentIndex = MacPlaybackMode.allCases.firstIndex(of: playbackMode) else {
            playbackMode = .sequential
            return
        }
        let nextIndex = MacPlaybackMode.allCases.index(after: currentIndex)
        playbackMode = nextIndex == MacPlaybackMode.allCases.endIndex ? MacPlaybackMode.allCases[0] : MacPlaybackMode.allCases[nextIndex]
        persistPlaybackCheckpoint()
    }

    func setVolume(_ value: Double) {
        guard value.isFinite else { return }
        volume = min(max(value, 0), 1)
        player?.volume = Float(volume)
    }

    func toggleFavorite(_ track: MacTrackItem?) {
        guard let track else { return }
        if favoriteTrackIDs.contains(track.id) {
            favoriteTrackIDs.remove(track.id)
            message = "已取消喜欢：\(track.title)"
        } else {
            favoriteTrackIDs.insert(track.id)
            message = "已加入喜欢：\(track.title)"
        }
        UserDefaults.standard.set(Array(favoriteTrackIDs), forKey: favoriteTrackIDsKey)
    }

    func revealInFinder(_ track: MacTrackItem) {
        guard let localURL = track.localURL else {
            return
        }

        let accessURL = track.securityScopedRootURL ?? localURL
        let didStartAccess = accessURL.startAccessingSecurityScopedResource()
        NSWorkspace.shared.activateFileViewerSelecting([localURL])
        if didStartAccess {
            accessURL.stopAccessingSecurityScopedResource()
        }
    }

    func seek(to seconds: Double) {
        guard let player else { return }
        let target = duration.isFinite && duration > 0 ? min(max(0, seconds), duration) : max(0, seconds)
        currentTime = target
        player.seek(to: CMTime(seconds: target, preferredTimescale: 600)) { [weak self] finished in
            Task { @MainActor in
                guard finished else { return }
                self?.persistPlaybackCheckpoint(currentTimeOverride: target)
                self?.syncElapsedTimeToNowPlaying(target)
            }
        }
        persistPlaybackCheckpoint(currentTimeOverride: target)
        syncElapsedTimeToNowPlaying(target)
    }

    func persistPlaybackCheckpoint() {
        persistPlaybackCheckpoint(currentTimeOverride: nil)
    }

    func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds > 0 else { return "0:00" }
        let totalSeconds = Int(seconds.rounded())
        return "\(totalSeconds / 60):\(String(format: "%02d", totalSeconds % 60))"
    }

    private func enrichLocalTracksFromMusicVault() async {
        message = "正在从星语音库补全歌曲信息"
        for track in localTracks {
            guard track.remoteTrack == nil else { continue }
            guard let enriched = await enrichedTrackFromMusicVault(for: track) else { continue }
            replaceTrack(enriched, matchingID: track.id)
        }
        message = "星语音库信息同步完成"
    }

    private func enrichedTrackFromMusicVault(for track: MacTrackItem) async -> MacTrackItem? {
        do {
            let match = try await matchMusicVaultTrack(for: track)
            guard match.matched, let matchedTrack = match.track else {
                return nil
            }

            let detail = (try? await client.track(id: matchedTrack.id)) ?? matchedTrack
            let artworkData = await musicVaultArtworkData(for: detail)
            return track.applyingMusicVault(track: detail, artworkData: artworkData)
        } catch {
            return nil
        }
    }

    private func matchMusicVaultTrack(for track: MacTrackItem) async throws -> MusicVaultTrackMatch {
        let titleCandidates = uniqueMatchTitles(title: track.title, artist: track.artist)
        var lastMatch = MusicVaultTrackMatch(matched: false, score: 0, reason: "No title candidate matched", track: nil)

        for title in titleCandidates {
            let query = MusicVaultTrackMatchQuery(
                title: title,
                artist: track.artist.nilIfBlank,
                album: track.album.nilIfBlank,
                durationMs: track.durationMs
            )
            let match = try await client.matchTrack(query: query)
            lastMatch = match
            if match.matched {
                return match
            }
        }

        return lastMatch
    }

    private func uniqueMatchTitles(title: String, artist: String) -> [String] {
        [title.removingLeadingArtistPrefix(artist: artist.nilIfBlank), title]
            .reduce(into: [String]()) { result, value in
                guard let normalized = value.nilIfBlank,
                      !result.contains(where: { $0.normalizedForMusicVaultMatch == normalized.normalizedForMusicVaultMatch }) else {
                    return
                }
                result.append(normalized)
            }
    }

    private func musicVaultArtworkData(for track: MusicVaultTrack) async -> Data? {
        do {
            let meta = try await client.artworkMeta(trackId: track.id)
            guard meta.available else { return nil }
            return try await client.artwork(trackId: track.id).value
        } catch {
            return nil
        }
    }

    private func replaceTrack(_ updatedTrack: MacTrackItem, matchingID id: String) {
        if let index = localTracks.firstIndex(where: { $0.id == id }) {
            localTracks[index] = updatedTrack
        }
        if let index = tracks.firstIndex(where: { $0.id == id }) {
            tracks[index] = updatedTrack
        }
        if currentTrack?.id == id {
            currentTrack = updatedTrack
            Task {
                await loadLyrics(for: updatedTrack.remoteTrack)
            }
        }
        if selectedTrackID == id {
            Task {
                await loadLyrics(for: updatedTrack.remoteTrack)
            }
        }
    }

    private func loadLyrics(for track: MusicVaultTrack?) async {
        guard let track else {
            clearLyrics(message: "星语音库暂未匹配到歌词")
            return
        }

        do {
            let meta = try await client.lyricsMeta(trackId: track.id)
            guard meta.available else {
                clearLyrics(message: "星语音库暂未收录歌词")
                return
            }
            let response = try await client.lyrics(trackId: track.id)
            let text = response.value?.content.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let text, !text.isEmpty else {
                clearLyrics(message: "歌词内容为空")
                return
            }
            lyricSourceDescription = meta.format?.localizedCaseInsensitiveContains("lrc") == true ? "星语音库歌词 · LRC" : "星语音库歌词"
            lyricsPreview = text
            lyricLines = LRCParser.parse(text)
        } catch {
            clearLyrics(message: "歌词加载失败：\(error.localizedDescription)")
        }
    }

    private func clearLyrics(message: String) {
        lyricsPreview = message
        lyricLines = []
        lyricSourceDescription = "星语音库歌词"
    }

    private func loadDuration(for item: AVPlayerItem, fallback durationMs: Int64?) async {
        if let loadedDuration = try? await item.asset.load(.duration), loadedDuration.seconds.isFinite {
            duration = loadedDuration.seconds
        } else {
            duration = durationMs.map { Double($0) / 1000 } ?? 0
        }
    }

    private func track(offset: Int) -> MacTrackItem? {
        guard !tracks.isEmpty else { return nil }
        let anchorID = currentTrack?.id ?? selectedTrackID
        let currentIndex = anchorID.flatMap { id in tracks.firstIndex { $0.id == id } } ?? 0
        let nextIndex = (currentIndex + offset + tracks.count) % tracks.count
        return tracks[nextIndex]
    }

    private func nextTrackForUserAction() -> MacTrackItem? {
        playbackMode == .shuffle ? randomTrack() : track(offset: 1)
    }

    private func randomTrack() -> MacTrackItem? {
        guard !tracks.isEmpty else { return nil }
        guard tracks.count > 1, let currentID = currentTrack?.id ?? selectedTrackID else {
            return tracks.randomElement()
        }
        return tracks.filter { $0.id != currentID }.randomElement() ?? tracks.randomElement()
    }

    private func handlePlaybackEnd() {
        isPlaying = false
        persistPlaybackCheckpoint(currentTimeOverride: duration)
        switch playbackMode {
        case .repeatOne:
            guard let track = currentTrack else { return }
            play(track)
        case .sequential:
            guard let track = track(offset: 1) else { return }
            play(track)
        case .shuffle:
            guard let track = randomTrack() else { return }
            play(track)
        }
    }

    private func setupRemoteCommands() {
        RemoteCommandManager.shared.setup(
            onPlay: { [weak self] in self?.playFromRemoteCommand() },
            onPause: { [weak self] in self?.pauseFromRemoteCommand() },
            onTogglePlayPause: { [weak self] in self?.togglePlayback() },
            onNext: { [weak self] in self?.next() },
            onPrevious: { [weak self] in self?.previous() },
            onSeek: { [weak self] time in self?.seek(to: time) }
        )
    }

    private func playFromRemoteCommand() {
        if player == nil, let track = selectedTrack {
            play(track)
            return
        }
        player?.play()
        isPlaying = player != nil
        persistPlaybackCheckpoint()
        syncPlaybackStateToNowPlaying()
    }

    private func pauseFromRemoteCommand() {
        player?.pause()
        isPlaying = false
        persistPlaybackCheckpoint()
        syncPlaybackStateToNowPlaying()
    }

    private func restorePlaybackCheckpointIfPossible() {
        guard let checkpoint = playbackPersistence.loadCheckpoint(),
              restoredCheckpointID != checkpoint.currentTrack.id else {
            return
        }
        let restored = PlaybackPersistence.restore(
            checkpoint: checkpoint,
            library: tracks,
            id: \.id,
            sourceURLString: { $0.localURL?.absoluteString },
            duration: { $0.durationMs.map { Double($0) / 1000 } },
            fallbackQueue: tracks
        )
        guard let restored else { return }
        restoredCheckpointID = checkpoint.currentTrack.id
        load(restored.track, shouldPlay: false, startTime: restored.startTime)
    }

    private func persistPlaybackCheckpoint(currentTimeOverride: Double? = nil) {
        guard let currentTrack else { return }
        let queue = tracks.isEmpty ? [currentTrack] : tracks
        let checkpoint = PlaybackCheckpoint(
            currentTrack: snapshot(for: currentTrack),
            currentTime: boundedCheckpointTime(currentTimeOverride ?? currentTime),
            queue: queue.map(snapshot(for:)),
            queueIndex: queue.firstIndex { $0.id == currentTrack.id } ?? 0,
            playbackMode: playbackMode.persistenceValue,
            updatedAt: Date()
        )
        playbackPersistence.save(checkpoint)
    }

    private func snapshot(for track: MacTrackItem) -> PlaybackTrackSnapshot {
        PlaybackTrackSnapshot(
            id: track.id,
            sourceURLString: track.localURL?.absoluteString,
            title: track.title,
            artist: track.artist,
            album: track.album
        )
    }

    private func boundedCheckpointTime(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        let time = max(0, value)
        guard duration.isFinite, duration > 0 else { return time }
        if time >= duration {
            return playbackMode == .repeatOne ? 0 : min(time, max(0, duration - 0.25))
        }
        return time
    }

    private func refreshNowPlayingAndCheckpoint() {
        guard let currentTrack else { return }
        if lastNowPlayingTrackID != currentTrack.id || abs(duration - lastNowPlayingDuration) > 0.5 {
            updateNowPlayingInfo(for: currentTrack)
        } else if isPlaying && Date().timeIntervalSince(lastNowPlayingElapsedUpdate) >= 1 {
            syncElapsedTimeToNowPlaying(currentTime)
        }
        if Date().timeIntervalSince(lastNowPlayingElapsedUpdate) >= 5 {
            persistPlaybackCheckpoint()
        }
    }

    private func updateNowPlayingInfo(for track: MacTrackItem, elapsedTime: Double? = nil) {
        NowPlayingInfoManager.shared.update(
            track: track,
            duration: duration,
            elapsedTime: elapsedTime ?? currentTime,
            isPlaying: isPlaying
        )
        lastNowPlayingTrackID = track.id
        lastNowPlayingDuration = duration
        lastNowPlayingElapsedUpdate = Date()
    }

    private func syncPlaybackStateToNowPlaying() {
        guard currentTrack != nil, player != nil else { return }
        NowPlayingInfoManager.shared.updatePlaybackState(isPlaying: isPlaying, elapsedTime: currentTime)
        lastNowPlayingElapsedUpdate = Date()
    }

    private func syncElapsedTimeToNowPlaying(_ elapsedTime: Double) {
        guard currentTrack != nil, player != nil else { return }
        NowPlayingInfoManager.shared.updateElapsedTime(elapsedTime)
        lastNowPlayingElapsedUpdate = Date()
    }

    private func recordRecentTrack(_ track: MacTrackItem) {
        recentTrackIDs.removeAll { $0 == track.id }
        recentTrackIDs.insert(track.id, at: 0)
        if recentTrackIDs.count > 500 {
            recentTrackIDs = Array(recentTrackIDs.prefix(500))
        }
        UserDefaults.standard.set(recentTrackIDs, forKey: recentTrackIDsKey)
    }

    private func persistLocalFolderBookmark(for folderURL: URL) {
        do {
            let bookmarkData = try folderURL.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(bookmarkData, forKey: localFolderBookmarkDataKey)
            UserDefaults.standard.set(folderURL.path, forKey: localFolderPathKey)
        } catch {
            UserDefaults.standard.set(folderURL.path, forKey: localFolderPathKey)
            errorMessage = error.localizedDescription
        }
    }

    private func restorePersistedLocalFolder() {
        guard UserDefaults.standard.data(forKey: localFolderBookmarkDataKey) != nil
                || UserDefaults.standard.string(forKey: localFolderPathKey) != nil else {
            return
        }

        Task {
            do {
                isImportingLocalFolder = true
                errorMessage = nil
                message = "正在恢复本地歌曲目录"
                let (folderURL, isStale) = try persistedLocalFolderURL()
                try await loadLocalFolder(folderURL)
                if isStale {
                    persistLocalFolderBookmark(for: folderURL)
                }
                message = localTracks.isEmpty ? "未在已保存目录中找到可播放音频" : "已恢复 \(localTracks.count) 首本地歌曲"
                if !localTracks.isEmpty {
                    Task {
                        await enrichLocalTracksFromMusicVault()
                    }
                }
            } catch {
                UserDefaults.standard.removeObject(forKey: localFolderBookmarkDataKey)
                UserDefaults.standard.removeObject(forKey: localFolderPathKey)
                errorMessage = error.localizedDescription
                message = "本地歌曲目录恢复失败"
            }
            isImportingLocalFolder = false
        }
    }

    private func persistedLocalFolderURL() throws -> (url: URL, isStale: Bool) {
        if let bookmarkData = UserDefaults.standard.data(forKey: localFolderBookmarkDataKey) {
            var isStale = false
            let folderURL = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            return (folderURL, isStale)
        }

        if let path = UserDefaults.standard.string(forKey: localFolderPathKey) {
            return (URL(fileURLWithPath: path), false)
        }

        throw CocoaError(.fileNoSuchFile)
    }

    private func loadLocalFolder(_ folderURL: URL) async throws {
        let accessStarted = folderURL.startAccessingSecurityScopedResource()
        if accessStarted {
            importedFolderAccessURLs.append(folderURL)
        }
        localTracks = try await localTracks(in: folderURL)
        mergeTracks()
        selectedTrackID = selectedTrackID ?? tracks.first?.id
        restorePlaybackCheckpointIfPossible()
    }

    private func tracksByID(ids: [String]) -> [MacTrackItem] {
        let availableTracks = Dictionary(uniqueKeysWithValues: tracks.map { ($0.id, $0) })
        return ids.compactMap { availableTracks[$0] }
    }

    private func observeProgress() {
        guard let player else { return }
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor in
                self?.currentTime = time.seconds.isFinite ? time.seconds : 0
                if let itemDuration = self?.player?.currentItem?.duration.seconds,
                   itemDuration.isFinite,
                   itemDuration > 0 {
                    self?.duration = itemDuration
                }
                self?.refreshNowPlayingAndCheckpoint()
            }
        }
    }

    private func observePlaybackEnd(for item: AVPlayerItem) {
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handlePlaybackEnd()
            }
        }
    }

    private func observePlaybackFailure(for item: AVPlayerItem) {
        failureObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
                self?.errorMessage = error?.localizedDescription ?? "本地音频文件播放失败"
                self?.message = "播放失败"
                self?.isPlaying = false
            }
        }
    }

    private func startPlaybackAccess(for track: MacTrackItem) {
        playbackAccessURL?.stopAccessingSecurityScopedResource()
        playbackAccessURL = nil

        guard let accessURL = track.securityScopedRootURL ?? track.localURL else { return }
        if accessURL.startAccessingSecurityScopedResource() {
            playbackAccessURL = accessURL
        }
    }

    private func cleanupPlaybackObservers() {
        if let timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        if let failureObserver {
            NotificationCenter.default.removeObserver(failureObserver)
            self.failureObserver = nil
        }
        playbackAccessURL?.stopAccessingSecurityScopedResource()
        playbackAccessURL = nil
    }

    private func uniqueValues(_ values: [String]) -> [String] {
        values.reduce(into: [String]()) { result, value in
            guard !result.contains(value) else { return }
            result.append(value)
        }
    }
}

private extension Array where Element == AVMetadataItem {
    func stringValue(commonKey: AVMetadataKey, identifiers: [AVMetadataIdentifier], rawKeys: [String]) -> String? {
        let normalizedRawKeys = Set(rawKeys.map { $0.lowercased() })
        return first { item in
            item.commonKey == commonKey
                || item.identifier.map(identifiers.contains) == true
                || item.lookupKeys.contains { normalizedRawKeys.contains($0) }
        }?.trimmedStringValue
    }

    func artworkData() -> Data? {
        first { item in
            item.commonKey == .commonKeyArtwork
                || item.identifier == .commonIdentifierArtwork
                || item.lookupKeys.contains { ["apic", "pic", "covr", "artwork"].contains($0) }
        }?.imageData
    }

    func qualityBadge() -> String? {
        let qualityKeys: Set<String> = [
            "quality",
            "qualitybadge",
            "audioquality",
            "audio quality",
            "description",
            "comment",
            "©des",
            "©cmt"
        ]
        let values = compactMap { item -> String? in
            guard item.lookupKeys.contains(where: qualityKeys.contains) else {
                return nil
            }
            return item.trimmedStringValue
        }
        return values.compactMap(MacAudioQualityBadge.normalizedLabel(from:)).first
    }
}

private struct MacAudioTraits {
    var channelCount = 0
    var sampleRate: Double = 0
    var bitsPerChannel = 0
}

private enum MacAudioQualityBadge {
    static func infer(
        metadataItems: [AVMetadataItem] = [],
        fileExtension: String?,
        fileSize: Int64?,
        durationMs: Int64?,
        traits: MacAudioTraits = MacAudioTraits()
    ) -> String? {
        if let metadataBadge = metadataItems.qualityBadge() {
            return metadataBadge
        }
        if traits.channelCount >= 6 {
            return "全景声"
        }
        if traits.sampleRate >= 88_200 || traits.bitsPerChannel >= 24 {
            return "臻品母带"
        }

        let normalizedExtension = fileExtension?.lowercased()
        if ["flac", "ape", "wav", "aif", "aiff"].contains(normalizedExtension) {
            return "SQ"
        }
        if let bitrateKbps = bitrateKbps(fileSize: fileSize, durationMs: durationMs),
           bitrateKbps >= 900 {
            return "SQ"
        }
        return nil
    }

    static func normalizedLabel(from rawValue: String) -> String? {
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercased = value.lowercased()
        if value.contains("全景声") || lowercased.contains("atmos") || lowercased.contains("spatial") || lowercased.contains("surround") {
            return "全景声"
        }
        if value.contains("臻品母带") || value.contains("母带") || lowercased.contains("master") || lowercased.contains("hi-res") || lowercased.contains("hires") {
            return "臻品母带"
        }
        if value.contains("无损") || lowercased.contains("lossless") || lowercased == "sq" {
            return "SQ"
        }
        return nil
    }

    private static func bitrateKbps(fileSize: Int64?, durationMs: Int64?) -> Double? {
        guard let fileSize, let durationMs, durationMs > 0 else {
            return nil
        }
        return Double(fileSize * 8) / (Double(durationMs) / 1000) / 1000
    }
}

private extension AVMetadataItem {
    var trimmedStringValue: String? {
        if let stringValue = stringValue?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty {
            return stringValue
        }
        if let stringValue = value as? String {
            return stringValue.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        }
        return nil
    }

    var imageData: Data? {
        if let dataValue {
            return dataValue
        }
        if let data = value as? Data {
            return data
        }
        if let dictionary = value as? [String: Any], let data = dictionary["data"] as? Data {
            return data
        }
        return nil
    }

    var lookupKeys: [String] {
        var keys: [String] = []
        if let identifier {
            keys.append(identifier.rawValue)
        }
        if let commonKey {
            keys.append(commonKey.rawValue)
        }
        if let key {
            keys.append(String(describing: key))
        }
        return keys.map { $0.lowercased() }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }

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
