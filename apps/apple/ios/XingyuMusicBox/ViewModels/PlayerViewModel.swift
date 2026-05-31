import Foundation
import Combine
import MediaPlayer
import SwiftUI

enum PlaybackMode: String, CaseIterable, Codable, Identifiable {
    case sequential
    case repeatAll
    case repeatOne
    case shuffle

    var id: String { rawValue }

    init(savedRawValue: String) {
        switch savedRawValue {
        case "listLoop":
            self = .repeatAll
        case "singleLoop":
            self = .repeatOne
        default:
            self = PlaybackMode(rawValue: savedRawValue) ?? .repeatAll
        }
    }

    var title: String {
        switch self {
        case .sequential:
            return "顺序播放"
        case .repeatAll:
            return "列表循环"
        case .repeatOne:
            return "单曲循环"
        case .shuffle:
            return "随机播放"
        }
    }

    var systemImage: String {
        switch self {
        case .sequential:
            return "arrow.right"
        case .repeatAll:
            return "repeat"
        case .repeatOne:
            return "repeat.1"
        case .shuffle:
            return "shuffle"
        }
    }
}

enum LocalMusicSortMode: String, CaseIterable, Identifiable {
    case titleAZ
    case artistAZ
    case playCountDesc

    var id: String { rawValue }

    var title: String {
        switch self {
        case .titleAZ:
            return "歌曲名 A-Z"
        case .artistAZ:
            return "歌手名 A-Z"
        case .playCountDesc:
            return "播放量 高-低"
        }
    }
}

@MainActor
final class PlayerViewModel: ObservableObject {
    @Published private(set) var songs: [Song] = []
    @Published private(set) var mediaLibraryAuthorizationStatus = MPMediaLibrary.authorizationStatus()
    @Published private(set) var mediaLibraryScanMessage: String?
    @Published private(set) var mediaLibraryScannedSongCount = 0
    @Published private(set) var mediaLibraryUnavailableSongCount = 0
    @Published private(set) var isRefreshingMediaLibrary = false
    @Published private(set) var mediaLibraryPlayCounts: [String: Int] = [:]
    @Published private(set) var currentSong: Song?
    @Published private(set) var isPlaying = false
    @Published private(set) var currentTime: Double = 0
    @Published private(set) var duration: Double = 0
    @Published private(set) var message: String?
    @Published private(set) var playbackErrorMessage: String?
    @Published private(set) var playbackMode: PlaybackMode = .repeatAll
    @Published private(set) var recentPlayRecords: [RecentPlayRecord] = []
    @Published private(set) var savedPlaybackState: PlaybackState?
    @Published private(set) var autoFetchingLyricsSongIDs: Set<String> = []
    @Published var favorites: Set<String> = [] {
        didSet { saveFavorites() }
    }

    @AppStorage("currentSongID") private var savedCurrentSongID = ""
    @AppStorage("playbackMode") private var savedPlaybackMode = PlaybackMode.repeatAll.rawValue
    @AppStorage("localMusicSortMode") private var savedLocalMusicSortMode = LocalMusicSortMode.titleAZ.rawValue

    private let library = SongLibrary()
    private let player = MusicPlayer()
    private let playbackStateStore = PlaybackStateStore()
    private let recentPlayStore = RecentPlayStore()
    private let favoritesKey = "favoriteSongIDs"
    private let mediaLibraryPlayCountsKey = "mediaLibraryPlayCounts"
    private var bundledSongs: [Song] = []
    private var mediaLibrarySongs: [Song] = []
    private var playbackQueue: [Song] = []
    private var observationTask: Task<Void, Never>?
    private var pendingSeekTime: Double?
    private var seekSequence = 0
    private var lastNowPlayingSongID: String?
    private var lastNowPlayingDuration: Double = 0
    private var lastNowPlayingElapsedUpdate = Date.distantPast
    private var autoLyricsTask: Task<Void, Never>?
    private var autoLyricsAttemptedSongIDs: Set<String> = []

    init() {
        playbackMode = PlaybackMode(savedRawValue: savedPlaybackMode)
        savedPlaybackMode = playbackMode.rawValue
        loadFavorites()
        loadMediaLibraryPlayCounts()
        recentPlayRecords = recentPlayStore.load()
        setupRemoteCommands()
        bindPlayer()
        loadSongs()
    }

    deinit {
        observationTask?.cancel()
        autoLyricsTask?.cancel()
    }

    func loadSongs() {
        bundledSongs = (try? library.loadSongs()) ?? []
        refreshMediaLibrarySongsIfAuthorized()
        refreshDisplayedSongs()

        let savedState = playbackStateStore.load()
        savedPlaybackState = savedState
        if let savedState {
            playbackMode = savedState.playbackMode
            savedPlaybackMode = savedState.playbackMode.rawValue
        }

        let restoredSong = savedState.flatMap { state in
            songs.first { $0.id == state.songID }
        }

        currentSong = restoredSong ?? songs.first(where: { $0.id == savedCurrentSongID }) ?? songs.first
        if let currentSong {
            let restoredTime = restoredSong == nil ? 0 : max(0, savedState?.currentTime ?? 0)
            savedCurrentSongID = currentSong.id
            loadCurrentSong(currentSong, shouldPlay: false, startTime: restoredTime, shouldSaveState: false)
        }
    }

    func play(song: Song) {
        play(song: song, queue: songs)
    }

    func play(song: Song, queue: [Song]) {
        currentSong = song
        savedCurrentSongID = song.id
        playbackQueue = queue.filter(isPlayable)
        loadCurrentSong(song, shouldPlay: true)
    }

    func togglePlayback() {
        if !player.hasLoadedSong, let currentSong {
            loadCurrentSong(currentSong, shouldPlay: false)
        }
        player.togglePlayback()
        if player.isPlaying, let currentSong {
            RemoteCommandManager.shared.beginReceivingRemoteControlEvents()
            recordRecentPlay(for: currentSong)
            updateNowPlayingInfo(for: currentSong)
        } else {
            persistPlaybackState()
            syncPlaybackStateToNowPlaying()
        }
    }

    func previous() {
        guard let song = songForManualPrevious() else { return }
        play(song: song, queue: activePlaybackQueue)
    }

    func next() {
        guard let song = songForManualNext() else { return }
        play(song: song, queue: activePlaybackQueue)
    }

    func seek(to seconds: Double) {
        let targetTime: Double
        if duration.isFinite, duration > 0 {
            targetTime = min(max(0, seconds), duration)
        } else {
            targetTime = max(0, seconds)
        }
        seekSequence += 1
        let currentSeekSequence = seekSequence
        pendingSeekTime = targetTime
        currentTime = targetTime
        player.seek(to: targetTime) { [weak self] finished in
            guard let self,
                  finished,
                  currentSeekSequence == seekSequence else { return }
            currentTime = targetTime
            pendingSeekTime = nil
            syncElapsedTimeToNowPlaying(targetTime)
        }
        persistPlaybackState(currentTimeOverride: targetTime)
        syncElapsedTimeToNowPlaying(targetTime)
    }

    func toggleFavorite(for song: Song) {
        if favorites.contains(song.id) {
            favorites.remove(song.id)
        } else {
            favorites.insert(song.id)
        }
    }

    func isFavorite(_ song: Song) -> Bool {
        favorites.contains(song.id)
    }

    func availableAudioFormats(for song: Song) -> [AudioFormat] {
        if song.sourceType == .mediaLibrary {
            return song.assetURL == nil ? [] : [.m4a]
        }

        return song.playableSourceCandidates.reduce(into: [AudioFormat]()) { result, source in
            guard audioFileExists(filename: source.filename),
                  !result.contains(source.format) else { return }
            result.append(source.format)
        }
    }

    func audioImportStatus(for song: Song) -> String {
        if song.sourceType == .mediaLibrary {
            return song.assetURL == nil ? "不可播放" : "系统媒体库"
        }

        let formats = availableAudioFormats(for: song)
        guard !formats.isEmpty else { return "未导入" }
        return formats.map { $0.rawValue.uppercased() }.joined(separator: " / ")
    }

    var recentSongs: [Song] {
        recentPlayRecords.compactMap { record in
            songs.first { $0.id == record.songID }
        }
    }

    var mediaLibrarySongCount: Int {
        mediaLibrarySongs.count
    }

    var hasAuthorizedEmptyMediaLibrary: Bool {
        mediaLibraryAuthorizationStatus == .authorized && mediaLibraryScannedSongCount == 0
    }

    var hasAuthorizedMediaLibraryWithoutPlayableSongs: Bool {
        mediaLibraryAuthorizationStatus == .authorized && mediaLibraryScannedSongCount > 0 && mediaLibrarySongs.isEmpty
    }

    var localMusicSortMode: LocalMusicSortMode {
        get { LocalMusicSortMode(rawValue: savedLocalMusicSortMode) ?? .titleAZ }
        set {
            savedLocalMusicSortMode = newValue.rawValue
            refreshDisplayedSongs()
        }
    }

    var localMusicSortModeTitle: String {
        localMusicSortMode.title
    }

    var canRequestMediaLibraryAuthorization: Bool {
        mediaLibraryAuthorizationStatus == .notDetermined
    }

    var shouldShowMediaLibraryDeniedMessage: Bool {
        mediaLibraryAuthorizationStatus == .denied || mediaLibraryAuthorizationStatus == .restricted
    }

    var mediaLibraryAuthorizationTitle: String {
        switch mediaLibraryAuthorizationStatus {
        case .notDetermined:
            return "需要授权读取 iPhone 系统媒体库"
        case .denied:
            return "媒体库访问已关闭，请在系统设置中开启"
        case .restricted:
            return "媒体库访问受限制"
        case .authorized:
            return mediaLibraryScanMessage ?? "已读取系统媒体库"
        @unknown default:
            return "媒体库权限状态未知"
        }
    }

    var savedPlaybackSongTitle: String {
        guard let songID = savedPlaybackState?.songID,
              let song = songs.first(where: { $0.id == songID }) else {
            return "无"
        }
        return song.title
    }

    var savedPlaybackProgressText: String {
        guard let savedPlaybackState else { return "无" }
        return formatTime(savedPlaybackState.currentTime)
    }

    var savedPlaybackModeTitle: String {
        savedPlaybackState?.playbackMode.title ?? playbackMode.title
    }

    func clearMessage() {
        message = nil
    }

    func togglePlaybackMode() {
        guard let currentIndex = PlaybackMode.allCases.firstIndex(of: playbackMode) else {
            playbackMode = .repeatAll
            savedPlaybackMode = playbackMode.rawValue
            persistPlaybackState()
            return
        }

        let nextIndex = PlaybackMode.allCases.index(after: currentIndex)
        playbackMode = nextIndex == PlaybackMode.allCases.endIndex ? PlaybackMode.allCases[0] : PlaybackMode.allCases[nextIndex]
        savedPlaybackMode = playbackMode.rawValue
        persistPlaybackState()
        message = playbackMode.title
    }

    func persistPlaybackState() {
        persistPlaybackState(currentTimeOverride: nil)
    }

    func clearRecentPlays() {
        recentPlayStore.clear()
        recentPlayRecords = []
        message = "已清空最近播放"
    }

    func clearPlaybackState() {
        playbackStateStore.clear()
        savedPlaybackState = nil
        savedCurrentSongID = ""
        message = "已清空播放状态"
    }

    func clearFavorites() {
        UserDefaults.standard.removeObject(forKey: favoritesKey)
        favorites = []
        message = "已清空收藏"
    }

    func clearAllLocalPreferences() {
        recentPlayStore.clear()
        recentPlayRecords = []

        playbackStateStore.clear()
        savedPlaybackState = nil
        savedCurrentSongID = ""

        UserDefaults.standard.removeObject(forKey: favoritesKey)
        favorites = []

        playbackMode = .repeatAll
        savedPlaybackMode = playbackMode.rawValue
        message = "已清空本地偏好"
    }

    func requestMediaLibraryAuthorization() {
        guard mediaLibraryAuthorizationStatus == .notDetermined else {
            refreshMediaLibrarySongsIfAuthorized()
            refreshDisplayedSongs()
            return
        }

        MPMediaLibrary.requestAuthorization { [weak self] status in
            Task { @MainActor in
                guard let self = self else { return }
                self.mediaLibraryAuthorizationStatus = status
                if status == .authorized {
                    self.refreshMediaLibrarySongsIfAuthorized()
                    self.refreshDisplayedSongs()
                } else {
                    self.mediaLibraryScanMessage = self.mediaLibraryAuthorizationTitle
                }
            }
        }
    }

    func refreshMediaLibrarySongs() {
        isRefreshingMediaLibrary = true
        defer { isRefreshingMediaLibrary = false }
        mediaLibraryAuthorizationStatus = MPMediaLibrary.authorizationStatus()
        refreshMediaLibrarySongsIfAuthorized()
        refreshDisplayedSongs()
    }

    func playSystemMediaProbe(assetURL: URL, title: String) {
        pendingSeekTime = nil
        seekSequence += 1
        playbackErrorMessage = nil
        currentSong = nil
        NowPlayingInfoManager.shared.clear()
        lastNowPlayingSongID = nil
        lastNowPlayingDuration = 0

        let loaded = player.load(url: assetURL, displayTitle: title) { }
        if loaded {
            player.play()
            if player.isPlaying {
                RemoteCommandManager.shared.beginReceivingRemoteControlEvents()
                message = "正在测试播放：\(title)"
            } else if let errorMessage = player.errorMessage {
                playbackErrorMessage = errorMessage
                message = errorMessage
            }
        } else if let errorMessage = player.errorMessage {
            playbackErrorMessage = errorMessage
            message = errorMessage
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
        if !player.hasLoadedSong, let currentSong {
            loadCurrentSong(currentSong, shouldPlay: false)
        }
        player.play()
        if player.isPlaying, let currentSong {
            RemoteCommandManager.shared.beginReceivingRemoteControlEvents()
            recordRecentPlay(for: currentSong)
            updateNowPlayingInfo(for: currentSong)
        }
    }

    private func pauseFromRemoteCommand() {
        player.pause()
        persistPlaybackState()
        syncPlaybackStateToNowPlaying()
    }

    private func song(offset: Int) -> Song? {
        let queue = activePlaybackQueue
        guard let currentSong,
              let currentIndex = queue.firstIndex(of: currentSong),
              !queue.isEmpty else {
            return queue.first
        }

        let nextIndex = (currentIndex + offset + queue.count) % queue.count
        return queue[nextIndex]
    }

    private func playableSong(offset: Int, wrapping: Bool) -> Song? {
        let queue = activePlaybackQueue
        guard let currentSong,
              let currentIndex = queue.firstIndex(of: currentSong),
              !queue.isEmpty else {
            return queue.first(where: isPlayable)
        }

        for step in 1..<queue.count {
            let candidateIndex = currentIndex + (offset > 0 ? step : -step)

            if queue.indices.contains(candidateIndex) {
                let candidate = queue[candidateIndex]
                if isPlayable(candidate) {
                    return candidate
                }
            } else if wrapping {
                let wrappedIndex = (candidateIndex + queue.count) % queue.count
                let candidate = queue[wrappedIndex]
                if isPlayable(candidate) {
                    return candidate
                }
            } else {
                return nil
            }
        }

        return nil
    }

    private func randomPlayableSongExcludingCurrent() -> Song? {
        let queue = activePlaybackQueue
        guard !queue.isEmpty else { return nil }
        guard let currentSong else {
            return queue.first(where: isPlayable) ?? queue.first
        }

        let playableCandidates = queue.filter { $0.id != currentSong.id && isPlayable($0) }
        if let candidate = playableCandidates.randomElement() {
            return candidate
        }

        if isPlayable(currentSong) {
            return currentSong
        }

        return queue.first { $0.id != currentSong.id } ?? currentSong
    }

    private func songForManualNext() -> Song? {
        switch playbackMode {
        case .sequential:
            return playableSong(offset: 1, wrapping: false)
        case .repeatAll, .repeatOne:
            return playableSong(offset: 1, wrapping: true) ?? song(offset: 1)
        case .shuffle:
            return randomPlayableSongExcludingCurrent()
        }
    }

    private func songForManualPrevious() -> Song? {
        switch playbackMode {
        case .sequential:
            return playableSong(offset: -1, wrapping: false)
        case .repeatAll, .repeatOne:
            return playableSong(offset: -1, wrapping: true) ?? song(offset: -1)
        case .shuffle:
            return randomPlayableSongExcludingCurrent()
        }
    }

    private func handlePlaybackEnded() {
        switch playbackMode {
        case .sequential:
            guard let song = playableSong(offset: 1, wrapping: false) else { return }
            play(song: song, queue: activePlaybackQueue)
        case .repeatAll:
            guard let song = playableSong(offset: 1, wrapping: true) ?? song(offset: 1) else { return }
            play(song: song, queue: activePlaybackQueue)
        case .repeatOne:
            guard let currentSong else { return }
            loadCurrentSong(currentSong, shouldPlay: true, startTime: 0)
        case .shuffle:
            guard let song = randomPlayableSongExcludingCurrent() else { return }
            play(song: song, queue: activePlaybackQueue)
        }
    }

    private func loadCurrentSong(
        _ song: Song,
        shouldPlay: Bool,
        startTime: Double = 0,
        shouldSaveState: Bool = true
    ) {
        pendingSeekTime = nil
        seekSequence += 1
        playbackErrorMessage = nil
        let loaded = player.load(song: song) { [weak self] in
            self?.handlePlaybackEnded()
        }

        if loaded {
            if startTime > 0 {
                player.seek(to: startTime)
            }
            if shouldPlay {
                player.play()
                RemoteCommandManager.shared.beginReceivingRemoteControlEvents()
                recordRecentPlay(for: song)
                incrementPlayCountIfNeeded(for: song)
            }
            if shouldSaveState {
                persistPlaybackState(currentTimeOverride: startTime)
            }
            updateNowPlayingInfo(for: song, elapsedTime: startTime)
            scheduleAutoLyricsFetchIfNeeded(for: song)
        } else if let errorMessage = player.errorMessage {
            playbackErrorMessage = errorMessage
            message = errorMessage
            NowPlayingInfoManager.shared.clear()
            lastNowPlayingSongID = nil
            lastNowPlayingDuration = 0
            if shouldSaveState {
                persistPlaybackState(currentTimeOverride: 0)
            }
        }
    }

    private func scheduleAutoLyricsFetchIfNeeded(for song: Song) {
        guard !autoLyricsAttemptedSongIDs.contains(song.id),
              LyricsCacheStore.shared.cachedLyrics(for: song.id) == nil,
              mediaLibraryLyrics(for: song) == nil,
              song.lyrics?.nilIfEmpty == nil,
              song.title.nilIfEmpty != nil else {
            return
        }

        autoLyricsAttemptedSongIDs.insert(song.id)
        autoLyricsTask?.cancel()

        let lyricsDuration = automaticLyricsDuration(for: song)

        autoFetchingLyricsSongIDs.insert(song.id)
        autoLyricsTask = Task {
            defer {
                autoFetchingLyricsSongIDs.remove(song.id)
            }

            do {
                if let musicVaultResult = await MusicVaultLyricsService.shared.fetchLyrics(for: song, duration: lyricsDuration) {
                    guard !Task.isCancelled else { return }
                    _ = try LyricsCacheStore.shared.save(
                        musicVaultLyrics: musicVaultResult.lyrics,
                        track: musicVaultResult.track,
                        for: song.id
                    )
                    return
                }

                #if DEBUG
                print("[MusicVaultLyrics] 星语音库未获取到歌词，已停止互联网歌词自动获取：\(song.title)")
                #endif
            } catch {
                return
            }
        }
    }

    private func automaticLyricsDuration(for song: Song) -> TimeInterval? {
        if duration.isFinite, duration > 0 {
            return duration
        }
        return song.duration.secondsFromClockText
    }

    private func mediaLibraryLyrics(for song: Song) -> String? {
        guard song.sourceType == .mediaLibrary,
              let persistentID = UInt64(song.id) else {
            return nil
        }

        let predicate = MPMediaPropertyPredicate(
            value: NSNumber(value: persistentID),
            forProperty: MPMediaItemPropertyPersistentID
        )
        let query = MPMediaQuery.songs()
        query.addFilterPredicate(predicate)
        return query.items?.first?.lyrics?.nilIfEmpty
    }

    private func updateNowPlayingInfo(for song: Song, elapsedTime: Double? = nil) {
        NowPlayingInfoManager.shared.update(
            song: song,
            duration: duration,
            elapsedTime: elapsedTime ?? currentTime,
            isPlaying: player.isPlaying
        )
        lastNowPlayingSongID = song.id
        lastNowPlayingDuration = duration
        lastNowPlayingElapsedUpdate = Date()
    }

    private func syncPlaybackStateToNowPlaying() {
        guard currentSong != nil, player.hasLoadedSong else { return }
        NowPlayingInfoManager.shared.updatePlaybackState(
            isPlaying: player.isPlaying,
            elapsedTime: currentTime
        )
        lastNowPlayingElapsedUpdate = Date()
    }

    private func syncElapsedTimeToNowPlaying(_ elapsedTime: Double) {
        guard currentSong != nil, player.hasLoadedSong else { return }
        NowPlayingInfoManager.shared.updateElapsedTime(elapsedTime)
        lastNowPlayingElapsedUpdate = Date()
    }

    private func recordRecentPlay(for song: Song) {
        recentPlayRecords = recentPlayStore.record(songID: song.id)
    }

    private var activePlaybackQueue: [Song] {
        playbackQueue.isEmpty ? songs : playbackQueue
    }

    private func persistPlaybackState(currentTimeOverride: Double?) {
        guard let currentSong else { return }
        let state = PlaybackState(
            songID: currentSong.id,
            currentTime: max(0, currentTimeOverride ?? player.currentTime),
            playbackMode: playbackMode,
            updatedAt: Date()
        )
        playbackStateStore.save(state)
        savedPlaybackState = state
        savedCurrentSongID = currentSong.id
        savedPlaybackMode = playbackMode.rawValue
    }

    private func formatTime(_ value: Double) -> String {
        let seconds = max(0, Int(value.rounded()))
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60

        if hours > 0 {
            return "\(hours):\(String(format: "%02d", minutes)):\(String(format: "%02d", remainingSeconds))"
        }
        return "\(minutes):\(String(format: "%02d", remainingSeconds))"
    }

    private func bindPlayer() {
        observationTask = Task { [weak self, weak player] in
            guard let player else { return }
            for await _ in Timer.publish(every: 0.2, on: .main, in: .common).autoconnect().values {
                guard let self else { return }
                let previousIsPlaying = isPlaying
                isPlaying = player.isPlaying
                if let pendingSeekTime {
                    if abs(player.currentTime - pendingSeekTime) < 0.75 {
                        currentTime = player.currentTime
                        self.pendingSeekTime = nil
                    } else {
                        currentTime = pendingSeekTime
                    }
                } else {
                    currentTime = player.currentTime
                }
                duration = player.duration

                if let currentSong {
                    if lastNowPlayingSongID != currentSong.id || abs(duration - lastNowPlayingDuration) > 0.5 {
                        updateNowPlayingInfo(for: currentSong)
                    } else if previousIsPlaying != isPlaying {
                        syncPlaybackStateToNowPlaying()
                    } else if isPlaying && Date().timeIntervalSince(lastNowPlayingElapsedUpdate) >= 1 {
                        syncElapsedTimeToNowPlaying(currentTime)
                    }
                }

                if let errorMessage = player.errorMessage {
                    if playbackErrorMessage != errorMessage {
                        playbackErrorMessage = errorMessage
                        message = errorMessage
                    }
                } else if player.hasLoadedSong {
                    playbackErrorMessage = nil
                }
            }
        }
    }

    private func refreshDisplayedSongs() {
        let allSongs = bundledSongs + mediaLibrarySongs
        songs = sortedSongs(allSongs)
        if playbackQueue.isEmpty {
            playbackQueue = songs.filter(isPlayable)
        } else {
            playbackQueue = playbackQueue.compactMap { queuedSong in
                songs.first { $0.id == queuedSong.id }
            }
        }
    }

    private func refreshMediaLibrarySongsIfAuthorized() {
        mediaLibraryAuthorizationStatus = MPMediaLibrary.authorizationStatus()
        guard mediaLibraryAuthorizationStatus == .authorized else {
            mediaLibrarySongs = []
            mediaLibraryScannedSongCount = 0
            mediaLibraryUnavailableSongCount = 0
            mediaLibraryScanMessage = mediaLibraryAuthorizationTitle
            return
        }

        let items = MPMediaQuery.songs().items ?? []
        mediaLibraryScannedSongCount = items.count
        mediaLibrarySongs = items.compactMap(mediaLibrarySong(from:))
        mediaLibraryUnavailableSongCount = max(0, items.count - mediaLibrarySongs.count)

        if items.isEmpty {
            mediaLibraryScanMessage = "还没有同步音乐到 iPhone"
        } else if mediaLibrarySongs.isEmpty {
            mediaLibraryScanMessage = "当前没有可播放的本地媒体库歌曲"
        } else {
            mediaLibraryScanMessage = "系统媒体库 \(mediaLibrarySongs.count) 首可播放"
        }
    }

    private func mediaLibrarySong(from item: MPMediaItem) -> Song? {
        guard let assetURL = item.assetURL else { return nil }
        let title = item.title?.nilIfEmpty ?? "未知歌曲"
        let artist = item.artist?.nilIfEmpty ?? "未知歌手"
        let album = item.albumTitle?.nilIfEmpty ?? "未知专辑"
        return Song(
            id: String(item.persistentID),
            title: title,
            artist: artist,
            album: album,
            duration: formatTime(item.playbackDuration),
            src: assetURL.absoluteString,
            audioSources: [],
            cover: "",
            year: nil,
            genre: item.genre,
            lyrics: nil,
            sourceType: .mediaLibrary,
            assetURL: assetURL
        )
    }

    private func sortedSongs(_ songs: [Song]) -> [Song] {
        songs.sorted { lhs, rhs in
            switch localMusicSortMode {
            case .titleAZ:
                let result = lhs.title.localizedStandardCompare(rhs.title)
                return result == .orderedSame ? lhs.artist.localizedStandardCompare(rhs.artist) == .orderedAscending : result == .orderedAscending
            case .artistAZ:
                let result = lhs.artist.localizedStandardCompare(rhs.artist)
                return result == .orderedSame ? lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending : result == .orderedAscending
            case .playCountDesc:
                let lhsCount = mediaLibraryPlayCounts[lhs.id] ?? 0
                let rhsCount = mediaLibraryPlayCounts[rhs.id] ?? 0
                if lhsCount == rhsCount {
                    return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
                }
                return lhsCount > rhsCount
            }
        }
    }

    private func incrementPlayCountIfNeeded(for song: Song) {
        guard song.sourceType == .mediaLibrary else { return }
        mediaLibraryPlayCounts[song.id, default: 0] += 1
        saveMediaLibraryPlayCounts()
        if localMusicSortMode == .playCountDesc {
            refreshDisplayedSongs()
        }
    }

    private func loadMediaLibraryPlayCounts() {
        let rawCounts = UserDefaults.standard.dictionary(forKey: mediaLibraryPlayCountsKey) ?? [:]
        mediaLibraryPlayCounts = rawCounts.reduce(into: [String: Int]()) { result, entry in
            if let value = entry.value as? Int {
                result[entry.key] = value
            } else if let value = entry.value as? NSNumber {
                result[entry.key] = value.intValue
            }
        }
    }

    private func saveMediaLibraryPlayCounts() {
        UserDefaults.standard.set(mediaLibraryPlayCounts, forKey: mediaLibraryPlayCountsKey)
    }

    private func loadFavorites() {
        let ids = UserDefaults.standard.stringArray(forKey: favoritesKey) ?? []
        favorites = Set(ids)
    }

    private func saveFavorites() {
        UserDefaults.standard.set(Array(favorites), forKey: favoritesKey)
    }

    private func isPlayable(_ song: Song) -> Bool {
        if song.sourceType == .mediaLibrary {
            return song.assetURL != nil
        }
        return !availableAudioFormats(for: song).isEmpty
    }

    private func audioFileExists(filename: String) -> Bool {
        for candidate in resourceCandidates(for: filename) {
            if Bundle.main.url(forResource: candidate, withExtension: nil) != nil {
                return true
            }

            let nsCandidate = candidate as NSString
            let fileName = nsCandidate.deletingPathExtension
            let ext = nsCandidate.pathExtension.isEmpty ? nil : nsCandidate.pathExtension

            if Bundle.main.url(forResource: fileName, withExtension: ext) != nil {
                return true
            }

            if Bundle.main.url(forResource: fileName, withExtension: ext, subdirectory: "audio") != nil {
                return true
            }

            if Bundle.main.url(forResource: fileName, withExtension: ext, subdirectory: "Resources/audio") != nil {
                return true
            }
        }

        return false
    }

    private func resourceCandidates(for source: String) -> [String] {
        let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
        let lastPathComponent = (trimmed as NSString).lastPathComponent
        let withoutLeadingSlash = trimmed.hasPrefix("/") ? String(trimmed.drop(while: { $0 == "/" })) : trimmed

        return [trimmed, withoutLeadingSlash, lastPathComponent]
            .filter { !$0.isEmpty }
            .reduce(into: [String]()) { result, candidate in
                if !result.contains(candidate) {
                    result.append(candidate)
                }
            }
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var secondsFromClockText: TimeInterval? {
        let parts = split(separator: ":").compactMap { TimeInterval($0) }
        guard parts.count >= 2, parts.count <= 3 else { return nil }
        return parts.reduce(0) { $0 * 60 + $1 }
    }

    func removingLeadingArtistPrefix(artist: String) -> String {
        guard let artist = artist.nilIfEmpty else {
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
        return cleaned.nilIfEmpty ?? trimmedTitle
    }
}
