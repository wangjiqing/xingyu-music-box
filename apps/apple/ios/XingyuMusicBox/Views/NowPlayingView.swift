import SwiftUI
import MediaPlayer

struct NowPlayingView: View {
    @EnvironmentObject private var viewModel: PlayerViewModel
    @State private var selectedPage = 1
    @State private var isThemeSheetPresented = false
    var onShowLibrary: () -> Void = {}

    var body: some View {
        ZStack {
            ThemeBackground()

            VStack(spacing: 12) {
                header

                if let song = viewModel.currentSong {
                    nowPlayingContent(song)
                        .frame(maxHeight: .infinity)
                } else {
                    ContentUnavailableView("暂无歌曲", systemImage: "music.note", description: Text("请授权并刷新本机系统媒体库。"))
                        .foregroundStyle(XYStyle.text)
                        .padding(22)
                        .glassCard()
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 84)
        }
        .sheet(isPresented: $isThemeSheetPresented) {
            ThemeSelectionView()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white, Color(red: 0.55, green: 0.89, blue: 1.0), Color(red: 0.02, green: 0.45, blue: 0.65)],
                            center: .topLeading,
                            startRadius: 2,
                            endRadius: 34
                        )
                    )
                    .frame(width: 44, height: 44)
                    .shadow(color: XYStyle.accent.opacity(0.42), radius: 14)

                Text("星")
                    .font(.headline.weight(.black))
                    .foregroundStyle(Color(red: 0.02, green: 0.13, blue: 0.20))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("星语音乐盒")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(XYStyle.text)
                Text("追忆旧时光的播放器，一个纯粹的音乐播放器")
                    .font(.caption2)
                    .foregroundStyle(XYStyle.muted)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.horizontal, 4)
    }

    private func nowPlayingContent(_ song: Song) -> some View {
        VStack(spacing: 11) {
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Button {
                        selectedPage = index
                    } label: {
                        Circle()
                            .fill(index == selectedPage ? XYStyle.accent : Color.white.opacity(0.45))
                            .frame(width: 7, height: 7)
                            .shadow(color: index == selectedPage ? XYStyle.accent.opacity(0.8) : .clear, radius: 6)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(pageTitle(for: index))
                }
            }

            TabView(selection: $selectedPage) {
                RecentHistoryPageView(
                    records: viewModel.recentPlayRecords,
                    songs: viewModel.songs,
                    currentSong: viewModel.currentSong,
                    statusText: viewModel.audioImportStatus(for:),
                    onSelect: viewModel.play,
                    onClear: viewModel.clearRecentPlays
                )
                .frame(maxHeight: .infinity, alignment: .top)
                .tag(0)

                CoverPlayerPageView(
                    song: song,
                    isFavorite: viewModel.isFavorite(song),
                    isPlaying: viewModel.isPlaying,
                    playbackMode: viewModel.playbackMode,
                    currentTime: viewModel.currentTime,
                    duration: viewModel.duration,
                    isAutoFetchingLyrics: viewModel.autoFetchingLyricsSongIDs.contains(song.id),
                    onFavorite: {
                        viewModel.toggleFavorite(for: song)
                    },
                    onList: {
                        selectedPage = 0
                    },
                    onTheme: {
                        isThemeSheetPresented = true
                    },
                    onSeek: viewModel.seek,
                    onPrevious: viewModel.previous,
                    onTogglePlayback: viewModel.togglePlayback,
                    onNext: viewModel.next,
                    onTogglePlaybackMode: viewModel.togglePlaybackMode
                )
                .frame(maxHeight: .infinity, alignment: .top)
                .tag(1)

                LyricsPageView(
                    song: song,
                    currentTime: viewModel.currentTime,
                    playbackDuration: viewModel.duration,
                    isPlaying: viewModel.isPlaying,
                    isAutoFetchingLyrics: viewModel.autoFetchingLyricsSongIDs.contains(song.id),
                    onSeek: viewModel.seek,
                    onPrevious: viewModel.previous,
                    onTogglePlayback: viewModel.togglePlayback,
                    onNext: viewModel.next
                )
                    .frame(maxHeight: .infinity, alignment: .top)
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxHeight: .infinity)
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 8)
        .frame(maxHeight: .infinity)
    }

    private func pageTitle(for index: Int) -> String {
        switch index {
        case 0:
            return "最近播放"
        case 1:
            return "封面播放页"
        default:
            return "歌词"
        }
    }
}

struct RecentHistoryPageView: View {
    let records: [RecentPlayRecord]
    let songs: [Song]
    let currentSong: Song?
    let statusText: (Song) -> String
    let onSelect: (Song) -> Void
    let onClear: () -> Void

    private var rows: [(record: RecentPlayRecord, song: Song)] {
        records.compactMap { record in
            guard let song = songs.first(where: { $0.id == record.songID }) else { return nil }
            return (record, song)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("最近播放")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(XYStyle.text)
                    Text(rows.isEmpty ? "还没有播放记录" : "\(rows.count) 条历史记录")
                        .font(.caption)
                        .foregroundStyle(XYStyle.muted)
                }

                Spacer()

                Button {
                    onClear()
                } label: {
                    Image(systemName: "trash")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(rows.isEmpty ? XYStyle.muted : XYStyle.danger)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.06), in: Circle())
                        .overlay {
                            Circle().stroke(XYStyle.line, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .disabled(rows.isEmpty)
            }
            .padding(.horizontal, 4)

            if rows.isEmpty {
                ContentUnavailableView(
                    "暂无最近播放",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("播放歌曲后，这里会显示完整历史。")
                )
                .foregroundStyle(XYStyle.text)
                .padding(.top, 36)
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(rows, id: \.record.id) { row in
                            Button {
                                onSelect(row.song)
                            } label: {
                                RecentHistoryRowView(
                                    song: row.song,
                                    playedAt: row.record.playedAt,
                                    isCurrent: row.song.id == currentSong?.id,
                                    statusText: statusText(row.song)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .scrollIndicators(.hidden)
            }
        }
        .padding(.horizontal, 2)
        .padding(.top, 4)
    }
}

struct RecentHistoryRowView: View {
    let song: Song
    let playedAt: Date
    let isCurrent: Bool
    let statusText: String

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.subheadline.weight(isCurrent ? .semibold : .regular))
                    .foregroundStyle(isCurrent ? XYStyle.accent : XYStyle.text)
                    .lineLimit(1)

                Text(song.artist)
                    .font(.caption)
                    .foregroundStyle(XYStyle.muted)
                    .lineLimit(1)

                Text(formatDate(playedAt))
                    .font(.caption2)
                    .foregroundStyle(Color.white.opacity(0.46))
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text(statusText)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(statusText == "未导入" ? XYStyle.danger : XYStyle.accent)
                .lineLimit(1)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 10)
        .background(isCurrent ? XYStyle.accentSoft.opacity(0.72) : Color.clear)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(XYStyle.line)
                .frame(height: 1)
                .padding(.leading, 12)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct CoverPlayerPageView: View {
    enum QuickActionsPlacement {
        case side
        case belowCover
    }

    let song: Song
    let isFavorite: Bool
    let isPlaying: Bool
    let playbackMode: PlaybackMode
    let currentTime: Double
    let duration: Double
    let isAutoFetchingLyrics: Bool
    var showsLyricsPreview = true
    var quickActionsPlacement: QuickActionsPlacement = .side
    let onFavorite: () -> Void
    let onList: () -> Void
    let onTheme: () -> Void
    let onSeek: (Double) -> Void
    let onPrevious: () -> Void
    let onTogglePlayback: () -> Void
    let onNext: () -> Void
    let onTogglePlaybackMode: () -> Void

    @State private var musicVaultMetadata: MusicVaultMetadataDisplay?
    @State private var musicVaultMetadataSongID: String?
    @State private var cachedLyrics: CachedLyrics?

    var body: some View {
        GeometryReader { proxy in
            content(availableSize: proxy.size)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
        }
        .onAppear(perform: refreshCachedLyrics)
        .onChange(of: song.id) { _, _ in
            refreshCachedLyrics()
        }
        .onReceive(NotificationCenter.default.publisher(for: .cachedLyricsDidChange)) { _ in
            refreshCachedLyrics()
        }
        .task(id: song.id) {
            await loadMusicVaultMetadata()
        }
    }

    private func content(availableSize: CGSize) -> some View {
        let compact = availableSize.height < 620
        let coverSize = min(max(210, availableSize.height * (compact ? 0.36 : 0.42)), max(210, availableSize.width - 78), 300)
        let spacing: CGFloat = compact ? 7 : 11

        return VStack(spacing: spacing) {
            VStack(spacing: compact ? 8 : 12) {
                CoverView(song: song, size: coverSize, allowsMusicVaultLookup: true)

                if quickActionsPlacement == .belowCover {
                    PlayerQuickActionsView(
                        placement: .horizontal,
                        isFavorite: isFavorite,
                        onFavorite: onFavorite,
                        onList: onList,
                        onTheme: onTheme
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .overlay(alignment: .trailing) {
                if quickActionsPlacement == .side {
                    PlayerQuickActionsView(
                        placement: .vertical,
                        isFavorite: isFavorite,
                        onFavorite: onFavorite,
                        onList: onList,
                        onTheme: onTheme
                    )
                    .padding(.trailing, 4)
                }
            }

            VStack(spacing: 5) {
                Text(displayMetadata.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(XYStyle.text)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text([displayMetadata.artist.nilIfBlank, displayMetadata.albumLine.nilIfBlank].compactMap { $0 }.joined(separator: " · "))
                    .font(.callout.weight(.medium))
                    .foregroundStyle(XYStyle.muted)
                    .lineLimit(1)

                if displayMetadata.isFromMusicVault {
                    Text(displayMetadata.detailLine)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(XYStyle.accent.opacity(0.92))
                        .lineLimit(1)
                }
            }

            if showsLyricsPreview {
                LyricsPreviewView(
                    cachedLyrics: cachedLyrics,
                    currentTime: currentTime,
                    isLoading: cachedLyrics == nil && isAutoFetchingLyrics
                )
                    .frame(height: compact ? 48 : nil)
                    .clipped()
            }

            if !compact {
                AudioVisualizerView(isPlaying: isPlaying)
            }

            ProgressSliderView(
                currentTime: currentTime,
                duration: duration,
                onSeek: onSeek
            )

            PlayerControlsView(
                isPlaying: isPlaying,
                isFavorite: isFavorite,
                playbackMode: playbackMode,
                onPrevious: onPrevious,
                onTogglePlayback: onTogglePlayback,
                onNext: onNext,
                onTogglePlaybackMode: onTogglePlaybackMode
            )
        }
    }

    private var displayMetadata: PlayerDisplayMetadata {
        if musicVaultMetadataSongID == song.id, let musicVaultMetadata {
            return PlayerDisplayMetadata(musicVault: musicVaultMetadata, song: song)
        }
        return PlayerDisplayMetadata(song: song)
    }

    private func loadMusicVaultMetadata() async {
        let result = await MusicVaultMetadataService.shared.fetchMetadata(
            for: song,
            duration: duration > 0 ? duration : song.duration.secondsFromClockText
        )

        await MainActor.run {
            if let result {
                musicVaultMetadata = result
                musicVaultMetadataSongID = song.id
            } else {
                musicVaultMetadata = nil
                musicVaultMetadataSongID = nil
            }
        }
    }

    private func refreshCachedLyrics() {
        cachedLyrics = LyricsCacheStore.shared.cachedLyrics(for: song.id)
    }
}

private struct PlayerDisplayMetadata {
    let title: String
    let artist: String
    let album: String
    let yearText: String
    let detailItems: [String]
    let isFromMusicVault: Bool

    init(song: Song) {
        title = song.title
        artist = song.artist
        album = song.album
        yearText = song.displayYear
        detailItems = []
        isFromMusicVault = false
    }

    init(musicVault: MusicVaultMetadataDisplay, song: Song) {
        title = musicVault.title.nilIfBlank ?? song.title
        artist = musicVault.artist.nilIfBlank ?? song.artist
        album = musicVault.album.nilIfBlank ?? song.album
        yearText = musicVault.yearText
        detailItems = musicVault.detailItems
        isFromMusicVault = true
    }

    var albumLine: String {
        [album.nilIfBlank, yearText.nilIfBlank].compactMap { $0 }.joined(separator: " · ")
    }

    var detailLine: String {
        detailItems.joined(separator: " · ")
    }
}

struct LyricsPageView: View {
    enum DisplayStyle {
        case standard
        case spacious
    }

    let song: Song
    let currentTime: TimeInterval
    let playbackDuration: TimeInterval
    let isPlaying: Bool
    let isAutoFetchingLyrics: Bool
    var showsMiniControlBar = true
    var displayStyle: DisplayStyle = .standard
    let onSeek: (Double) -> Void
    let onPrevious: () -> Void
    let onTogglePlayback: () -> Void
    let onNext: () -> Void

    @State private var cachedLyrics: CachedLyrics?
    @State private var isSearchPresented = false
    @State private var isDeleteConfirmationPresented = false
    @State private var autoScrollEnabled = true
    @State private var resumeAutoScrollTask: Task<Void, Never>?

    private var parsedLrcLines: [LyricLine]? {
        makeParsedLrcLines(from: cachedLyrics)
    }

    private var currentLyricLineIndex: Int? {
        makeCurrentLyricLineIndex(in: parsedLrcLines, currentTime: currentTime)
    }

    private var lyricsState: LyricsDisplayState {
        if let cachedLyrics {
            let badgePrefix = cachedLyrics.source == .musicVault ? "星语音库" : "历史缓存"
            return LyricsDisplayState(
                text: cachedLyrics.displayText,
                badge: cachedLyrics.lyricType == .lrc ? "\(badgePrefix) · LRC" : badgePrefix,
                isInstrumental: cachedLyrics.lyricType == .instrumental
            )
        }

        if let mediaLyrics = mediaLibraryLyrics(for: song) {
            return LyricsDisplayState(text: mediaLyrics, badge: "媒体库歌词", isInstrumental: false)
        }

        if let songLyrics = song.lyrics?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank {
            return LyricsDisplayState(text: songLyrics, badge: "内置歌词", isInstrumental: false)
        }

        return LyricsDisplayState(text: nil, badge: nil, isInstrumental: false)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("歌词")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(XYStyle.text)
                    Text("\(song.title) · \(song.artist)")
                        .font(.footnote)
                        .foregroundStyle(XYStyle.muted)
                        .lineLimit(1)
                }

                Spacer()

                Menu {
                    Button(cachedLyrics == nil ? "查找歌词" : "重新查找", systemImage: "magnifyingglass") {
                        isSearchPresented = true
                    }

                    if cachedLyrics != nil {
                        Button("删除缓存歌词", systemImage: "trash", role: .destructive) {
                            isDeleteConfirmationPresented = true
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(XYStyle.text)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.10), in: Circle())
                }
                .accessibilityLabel(cachedLyrics == nil ? "查找歌词" : "歌词操作")
            }
            .padding(.horizontal, 4)

            ScrollViewReader { proxy in
                ZStack(alignment: .bottom) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            Color.clear
                                .frame(height: 1)
                                .id("lyricsTop")

                            if let lrcLines = parsedLrcLines {
                                LyricsBadgeView(text: lyricsState.badge)
                                LrcLyricsTimelineView(
                                    lines: lrcLines,
                                    currentIndex: currentLyricLineIndex,
                                    displayStyle: displayStyle,
                                    onLineTap: { line in
                                        resumeAutoScrollImmediately()
                                        onSeek(line.time)
                                        withAnimation(.easeInOut(duration: 0.22)) {
                                            proxy.scrollTo(lyricLineScrollID(line.index), anchor: .center)
                                        }
                                    }
                                )
                            } else if let lyricsText = lyricsState.text {
                                LyricsBadgeView(text: lyricsState.badge)
                                PlainLyricsTextView(
                                    text: lyricsText,
                                    isInstrumental: lyricsState.isInstrumental,
                                    displayStyle: displayStyle
                                )
                            } else {
                                NoLyricsView(song: song, isAutoFetchingLyrics: isAutoFetchingLyrics) {
                                    isSearchPresented = true
                                }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                            }

                            Color.clear
                                .frame(height: displayStyle == .spacious ? 140 : 96)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, displayStyle == .spacious ? 30 : 18)
                    }
                    .scrollIndicators(.hidden)
                    .mask {
                        if displayStyle == .spacious {
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0.0),
                                    .init(color: .black, location: 0.12),
                                    .init(color: .black, location: 0.84),
                                    .init(color: .clear, location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        } else {
                            Rectangle()
                        }
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 6)
                            .onChanged { _ in
                                suspendAutoScrollTemporarily()
                            }
                            .onEnded { _ in
                                scheduleAutoScrollResume()
                            }
                    )
                    .onAppear {
                        if let currentLyricLineIndex {
                            proxy.scrollTo(lyricLineScrollID(currentLyricLineIndex), anchor: .center)
                        } else {
                            proxy.scrollTo("lyricsTop", anchor: .top)
                        }
                    }
                    .onChange(of: song.id) { _, _ in
                        resumeAutoScrollImmediately()
                        proxy.scrollTo("lyricsTop", anchor: .top)
                    }
                    .onChange(of: currentLyricLineIndex) { _, newValue in
                        guard autoScrollEnabled, parsedLrcLines != nil, let newValue else { return }
                        withAnimation(.easeInOut(duration: 0.24)) {
                            proxy.scrollTo(lyricLineScrollID(newValue), anchor: .center)
                        }
                    }

                    if showsMiniControlBar {
                        LyricsMiniControlBar(
                            song: song,
                            isPlaying: isPlaying,
                            currentTime: currentTime,
                            duration: playbackDuration,
                            onPrevious: onPrevious,
                            onTogglePlayback: onTogglePlayback,
                            onNext: onNext
                        )
                        .padding(.horizontal, 2)
                    }
                }
            }
        }
        .padding(.horizontal, 2)
        .padding(.top, 4)
        .onDisappear {
            resumeAutoScrollTask?.cancel()
            resumeAutoScrollTask = nil
        }
        .onAppear(perform: refreshCachedLyrics)
        .onChange(of: song.id) { _, _ in
            refreshCachedLyrics()
        }
        .onReceive(NotificationCenter.default.publisher(for: .cachedLyricsDidChange)) { _ in
            refreshCachedLyrics()
        }
        .sheet(isPresented: $isSearchPresented) {
            LyricsSearchSheet(
                song: song,
                playbackDuration: playbackDuration,
                onSave: { cached in
                    cachedLyrics = cached
                    isSearchPresented = false
                }
            )
        }
        .confirmationDialog(
            "删除这首歌的本地缓存歌词？",
            isPresented: $isDeleteConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("删除缓存歌词", role: .destructive) {
                LyricsCacheStore.shared.deleteLyrics(for: song.id)
                refreshCachedLyrics()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("只会删除 App 内的歌词缓存，不影响歌曲文件、媒体库或播放状态。")
        }
    }

    private func refreshCachedLyrics() {
        cachedLyrics = LyricsCacheStore.shared.cachedLyrics(for: song.id)
    }

    private func suspendAutoScrollTemporarily() {
        autoScrollEnabled = false
        resumeAutoScrollTask?.cancel()
    }

    private func scheduleAutoScrollResume() {
        resumeAutoScrollTask?.cancel()
        resumeAutoScrollTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                autoScrollEnabled = true
            }
        }
    }

    private func resumeAutoScrollImmediately() {
        resumeAutoScrollTask?.cancel()
        resumeAutoScrollTask = nil
        autoScrollEnabled = true
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
        return query.items?.first?.lyrics?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
    }
}

private struct LyricsDisplayState {
    let text: String?
    let badge: String?
    let isInstrumental: Bool
}

private struct VisibleLyricWindow {
    let previous: LyricLine?
    let current: LyricLine?
    let next: LyricLine?
}

private func makeParsedLrcLines(from cachedLyrics: CachedLyrics?) -> [LyricLine]? {
    guard let cachedLyrics,
          cachedLyrics.lyricType == .lrc else {
        return nil
    }

    let lines = LRCParser.parse(cachedLyrics.lyricText)
    return lines.isEmpty ? nil : lines
}

private func makeCurrentLyricLineIndex(in lines: [LyricLine]?, currentTime: TimeInterval) -> Int? {
    guard let lines, !lines.isEmpty else {
        return nil
    }

    return lines.last(where: { $0.time <= currentTime })?.index
        ?? (currentTime < lines[0].time ? nil : lines[0].index)
}

private func visibleLyricWindow(in lines: [LyricLine]?, currentTime: TimeInterval) -> VisibleLyricWindow? {
    guard let lines, !lines.isEmpty else {
        return nil
    }

    guard let currentIndex = makeCurrentLyricLineIndex(in: lines, currentTime: currentTime) else {
        return VisibleLyricWindow(previous: nil, current: nil, next: lines.first)
    }

    guard let arrayIndex = lines.firstIndex(where: { $0.index == currentIndex }) else {
        return nil
    }

    return VisibleLyricWindow(
        previous: arrayIndex > 0 ? lines[arrayIndex - 1] : nil,
        current: lines[arrayIndex],
        next: arrayIndex < lines.count - 1 ? lines[arrayIndex + 1] : nil
    )
}

private struct LyricsBadgeView: View {
    let text: String?

    var body: some View {
        if let text {
            Text(text)
                .font(.caption.weight(.semibold))
                .foregroundStyle(XYStyle.accent)
                .padding(.bottom, 10)
        }
    }
}

private struct PlainLyricsTextView: View {
    let text: String
    let isInstrumental: Bool
    let displayStyle: LyricsPageView.DisplayStyle

    private var textFont: Font {
        if isInstrumental {
            return displayStyle == .spacious ? .title3.weight(.semibold) : .headline
        }

        return displayStyle == .spacious ? .title3 : .body
    }

    private var textOpacity: Double {
        displayStyle == .spacious ? 0.64 : 0.78
    }

    var body: some View {
        Text(text)
            .font(textFont)
            .foregroundStyle(Color.white.opacity(textOpacity))
            .lineSpacing(displayStyle == .spacious ? 18 : 8)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct LrcLyricsTimelineView: View {
    let lines: [LyricLine]
    let currentIndex: Int?
    let displayStyle: LyricsPageView.DisplayStyle
    let onLineTap: (LyricLine) -> Void

    private var lineSpacing: CGFloat {
        displayStyle == .spacious ? 28 : 14
    }

    private var verticalPadding: CGFloat {
        displayStyle == .spacious ? 16 : 6
    }

    var body: some View {
        VStack(alignment: .leading, spacing: lineSpacing) {
            ForEach(lines) { line in
                LrcLyricLineView(
                    line: line,
                    isCurrent: line.index == currentIndex,
                    displayStyle: displayStyle,
                    onTap: {
                        onLineTap(line)
                    }
                )
                .id(lyricLineScrollID(line.index))
            }
        }
        .padding(.vertical, verticalPadding)
    }
}

private struct LrcLyricLineView: View {
    let line: LyricLine
    let isCurrent: Bool
    let displayStyle: LyricsPageView.DisplayStyle
    let onTap: () -> Void

    private var textFont: Font {
        switch (displayStyle, isCurrent) {
        case (.spacious, true):
            return .title2.weight(.bold)
        case (.spacious, false):
            return .title3
        case (.standard, true):
            return .title3.weight(.bold)
        case (.standard, false):
            return .body
        }
    }

    private var textColor: Color {
        if isCurrent {
            return XYStyle.accent
        }

        return Color.white.opacity(displayStyle == .spacious ? 0.38 : 0.56)
    }

    private var verticalPadding: CGFloat {
        if displayStyle == .spacious {
            return isCurrent ? 7 : 4
        }

        return isCurrent ? 4 : 2
    }

    var body: some View {
        Text(line.displayText)
            .font(textFont)
            .foregroundStyle(textColor)
            .lineSpacing(displayStyle == .spacious ? 10 : 5)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, verticalPadding)
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
            .animation(.easeInOut(duration: 0.18), value: isCurrent)
    }
}

private func lyricLineScrollID(_ index: Int) -> String {
    "lyricLine-\(index)"
}

private struct LyricsMiniControlBar: View {
    let song: Song
    let isPlaying: Bool
    let currentTime: TimeInterval
    let duration: TimeInterval
    let onPrevious: () -> Void
    let onTogglePlayback: () -> Void
    let onNext: () -> Void

    private var progress: CGFloat {
        guard duration.isFinite, duration > 0 else {
            return 0
        }
        return CGFloat(min(max(currentTime / duration, 0), 1))
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(song.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(XYStyle.text)
                    .lineLimit(1)

                Text(song.artist)
                    .font(.caption)
                    .foregroundStyle(XYStyle.muted)
                    .lineLimit(1)

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.14))
                            .frame(height: 3)

                        Capsule()
                            .fill(XYStyle.accent)
                            .frame(width: max(4, proxy.size.width * progress), height: 3)
                            .shadow(color: XYStyle.accent.opacity(0.65), radius: 5)
                    }
                }
                .frame(height: 3)
                .padding(.top, 2)
            }

            HStack(spacing: 8) {
                miniButton(systemImage: "backward.fill", action: onPrevious)

                Button(action: onTogglePlayback) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color(red: 0.03, green: 0.02, blue: 0.08))
                        .frame(width: 42, height: 42)
                        .background(
                            RadialGradient(
                                colors: [.white, XYStyle.accent.opacity(0.96)],
                                center: .topLeading,
                                startRadius: 2,
                                endRadius: 34
                            ),
                            in: Circle()
                        )
                        .shadow(color: XYStyle.accent.opacity(0.45), radius: 10)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isPlaying ? "暂停" : "播放")

                miniButton(systemImage: "forward.fill", action: onNext)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .background(Color.black.opacity(0.20), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(XYStyle.line.opacity(0.9), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.20), radius: 18, y: 8)
    }

    private func miniButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(XYStyle.text)
                .frame(width: 34, height: 34)
                .background(Color.white.opacity(0.09), in: Circle())
                .overlay {
                    Circle().stroke(Color.white.opacity(0.10), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

private struct NoLyricsView: View {
    let song: Song
    let isAutoFetchingLyrics: Bool
    let onFindLyrics: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "text.quote")
                .font(.title2.weight(.semibold))
                .foregroundStyle(XYStyle.accent)
                .frame(width: 52, height: 52)
                .background(XYStyle.accentSoft, in: Circle())

            Text("暂无歌词")
                .font(.headline.weight(.semibold))
                .foregroundStyle(XYStyle.text)

            VStack(spacing: 4) {
                Text(song.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.86))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                Text(song.artist)
                    .font(.caption)
                    .foregroundStyle(XYStyle.muted)
                    .lineLimit(1)
            }

            if isAutoFetchingLyrics {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(XYStyle.accent)
                    Text("正在努力获取歌词")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(XYStyle.accent)
                }
                .padding(.top, 2)
            }

            Text(isAutoFetchingLyrics ? "如果没有匹配结果，可以稍后手动修改歌曲名或歌手再搜索。" : "这首歌还没有歌词，但旋律已经在路上了。")
                .font(.footnote)
                .foregroundStyle(Color.white.opacity(0.66))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.top, 2)

            Button {
                onFindLyrics()
            } label: {
                Label("查找歌词", systemImage: "magnifyingglass")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color(red: 0.02, green: 0.12, blue: 0.18))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(XYStyle.accent, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(.horizontal, 12)
    }
}

private struct LyricsSearchSheet: View {
    let song: Song
    let playbackDuration: TimeInterval
    let onSave: (CachedLyrics) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var artist: String
    @State private var album: String
    @State private var duration: String
    @State private var message: String?
    @State private var isSearching = false

    init(song: Song, playbackDuration: TimeInterval, onSave: @escaping (CachedLyrics) -> Void) {
        self.song = song
        self.playbackDuration = playbackDuration
        self.onSave = onSave

        _title = State(initialValue: Self.recommendedTitle(song: song))
        _artist = State(initialValue: song.artist)
        _album = State(initialValue: song.album)
        _duration = State(initialValue: Self.initialDuration(song: song, playbackDuration: playbackDuration))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ThemeBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header
                        fields
                        searchButton
                        statusArea
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("查找歌词")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                    .foregroundStyle(XYStyle.text)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(song.title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(XYStyle.text)
                .lineLimit(2)
            Text("\(song.artist) · \(song.album)")
                .font(.footnote)
                .foregroundStyle(XYStyle.muted)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }

    private var fields: some View {
        VStack(spacing: 10) {
            lyricField(title: "歌曲名", text: $title)
            lyricField(title: "歌手", text: $artist)
            lyricField(title: "专辑", text: $album)
            lyricField(title: "时长（秒）", text: $duration, keyboardType: .decimalPad)
        }
    }

    private var searchButton: some View {
        Button {
            Task {
                await search()
            }
        } label: {
            HStack(spacing: 8) {
                if isSearching {
                    ProgressView()
                        .tint(Color(red: 0.02, green: 0.12, blue: 0.18))
                } else {
                    Image(systemName: "magnifyingglass")
                }
                Text(isSearching ? "搜索中" : "搜索")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(Color(red: 0.02, green: 0.12, blue: 0.18))
            .background(XYStyle.accent, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(isSearching)
    }

    @ViewBuilder
    private var statusArea: some View {
        if let message {
            Text(message)
                .font(.footnote)
                .foregroundStyle(Color.white.opacity(0.72))
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private func lyricField(title: String, text: Binding<String>, keyboardType: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(XYStyle.muted)
            TextField(title, text: text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(keyboardType)
                .foregroundStyle(XYStyle.text)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private func search() async {
        isSearching = true
        message = nil

        do {
            if !duration.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               parsedDuration == nil {
                throw LyricsCacheError.invalidDuration
            }

            if let musicVaultResult = await MusicVaultLyricsService.shared.fetchLyrics(for: song, duration: parsedDuration) {
                let cached = try LyricsCacheStore.shared.save(
                    musicVaultLyrics: musicVaultResult.lyrics,
                    track: musicVaultResult.track,
                    for: song.id
                )
                onSave(cached)
                return
            }

            #if DEBUG
            print("[MusicVaultLyrics] 星语音库未获取到歌词，已停止互联网歌词手动搜索：\(title)")
            #endif
            message = "星语音库未获取到歌词。当前测试阶段已停用互联网歌词搜索。"
        } catch let error as LocalizedError {
            message = error.errorDescription ?? "搜索失败，请稍后重试"
        } catch {
            message = "搜索失败，请稍后重试"
        }

        isSearching = false
    }

    private var parsedDuration: TimeInterval? {
        guard let text = duration.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank else {
            return nil
        }
        return TimeInterval(text)
    }

    private static func initialDuration(song: Song, playbackDuration: TimeInterval) -> String {
        if playbackDuration.isFinite, playbackDuration > 0 {
            return String(Int(playbackDuration.rounded()))
        }

        if let seconds = song.duration.secondsFromClockText {
            return String(Int(seconds.rounded()))
        }

        return ""
    }

    private static func recommendedTitle(song: Song) -> String {
        song.title.removingLeadingArtistPrefix(artist: song.artist)
    }
}

struct PlayerQuickActionsView: View {
    enum Placement {
        case vertical
        case horizontal
    }

    let placement: Placement
    let isFavorite: Bool
    let onFavorite: () -> Void
    let onList: () -> Void
    let onTheme: () -> Void

    var body: some View {
        Group {
            if placement == .vertical {
                VStack(spacing: 0) {
                    buttons
                }
            } else {
                HStack(spacing: 8) {
                    buttons
                }
            }
        }
        .padding(.vertical, placement == .vertical ? 6 : 5)
        .padding(.horizontal, placement == .vertical ? 5 : 8)
        .fixedSize()
        .background(Color.black.opacity(0.14), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private var buttons: some View {
        quickButton(
            title: "收藏",
            systemImage: isFavorite ? "heart.fill" : "heart",
            color: isFavorite ? XYStyle.danger : Color.white.opacity(0.72),
            action: onFavorite
        )

        if placement == .vertical {
            quickDivider
        }

        quickButton(
            title: "列表",
            systemImage: "list.bullet",
            color: XYStyle.accent,
            action: onList
        )

        if placement == .vertical {
            quickDivider
        }

        quickButton(
            title: "音效",
            systemImage: "waveform",
            color: Color.white.opacity(0.72),
            action: {}
        )

        if placement == .vertical {
            quickDivider
        }

        quickButton(
            title: "皮肤",
            systemImage: "paintpalette",
            color: XYStyle.accent,
            action: onTheme
        )
    }

    private var quickDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.07))
            .frame(width: 28, height: 1)
    }

    private func quickButton(
        title: String,
        systemImage: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(color)
            .frame(width: placement == .vertical ? 48 : 54, height: 45)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct SideQuickActionsView: View {
    let isFavorite: Bool
    let onFavorite: () -> Void
    let onList: () -> Void
    let onTheme: () -> Void

    var body: some View {
        PlayerQuickActionsView(
            placement: .vertical,
            isFavorite: isFavorite,
            onFavorite: onFavorite,
            onList: onList,
            onTheme: onTheme
        )
    }
}

struct LegacySideQuickActionsView: View {
    let isFavorite: Bool
    let onFavorite: () -> Void
    let onList: () -> Void
    let onTheme: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            SideQuickActionButton(
                title: "收藏",
                systemImage: isFavorite ? "heart.fill" : "heart",
                color: isFavorite ? XYStyle.danger : Color.white.opacity(0.72),
                action: onFavorite
            )

            SideActionDivider()

            SideQuickActionButton(
                title: "列表",
                systemImage: "list.bullet",
                color: XYStyle.accent,
                action: onList
            )

            SideActionDivider()

            SideQuickActionButton(
                title: "音效",
                systemImage: "waveform",
                color: Color.white.opacity(0.72),
                action: {}
            )

            SideActionDivider()

            SideQuickActionButton(
                title: "皮肤",
                systemImage: "paintpalette",
                color: XYStyle.accent,
                action: onTheme
            )
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 5)
        .fixedSize()
        .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        }
    }
}

struct SideActionDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.07))
            .frame(width: 28, height: 1)
    }
}

struct SideQuickActionButton: View {
    let title: String
    let systemImage: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.system(size: 9, weight: .medium))
            }
            .foregroundStyle(color)
            .frame(width: 44, height: 43)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct LyricsPreviewLine: Identifiable {
    let id: String
    let text: String
    let isCurrent: Bool
}

struct LyricsPreviewView: View {
    let cachedLyrics: CachedLyrics?
    let currentTime: TimeInterval
    let isLoading: Bool

    private var displayLines: [LyricsPreviewLine] {
        if isLoading {
            return [
                LyricsPreviewLine(id: "loading-0", text: "歌词加载中...", isCurrent: false),
                LyricsPreviewLine(id: "loading-1", text: "正在等待星语音库回应", isCurrent: true),
                LyricsPreviewLine(id: "loading-2", text: " ", isCurrent: false)
            ]
        }

        if let window = visibleLyricWindow(in: makeParsedLrcLines(from: cachedLyrics), currentTime: currentTime) {
            return [
                LyricsPreviewLine(id: "previous", text: window.previous?.displayText ?? " ", isCurrent: false),
                LyricsPreviewLine(id: "current", text: window.current?.displayText ?? "这一刻还没有歌词", isCurrent: true),
                LyricsPreviewLine(id: "next", text: window.next?.displayText ?? " ", isCurrent: false)
            ]
        }

        return [
            LyricsPreviewLine(id: "empty-0", text: "这一刻还没有歌词", isCurrent: false),
            LyricsPreviewLine(id: "empty-1", text: " ", isCurrent: true),
            LyricsPreviewLine(id: "empty-2", text: " ", isCurrent: false)
        ]
    }

    var body: some View {
        VStack(spacing: 2) {
            ForEach(displayLines) { line in
                Text(line.text)
                    .font(line.isCurrent ? .subheadline.weight(.semibold) : .subheadline)
                    .foregroundStyle(line.isCurrent ? XYStyle.accent : Color.white.opacity(0.46))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 2)
        .animation(.easeInOut(duration: 0.18), value: displayLines.map(\.text))
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.18),
                    .init(color: .black, location: 0.82),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var lyricLines: [String] {
        components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var secondsFromClockText: TimeInterval? {
        let parts = split(separator: ":").compactMap { TimeInterval($0) }
        guard parts.count >= 2, parts.count <= 3 else { return nil }
        return parts.reduce(0) { $0 * 60 + $1 }
    }

    func removingLeadingArtistPrefix(artist: String) -> String {
        guard let artist = artist.nilIfBlank else {
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

struct AudioVisualizerView: View {
    let isPlaying: Bool

    private let baseHeights: [CGFloat] = [12, 24, 17, 34, 22, 40, 28, 15, 31, 38, 18, 26, 36, 20, 30, 14, 33, 25, 39, 21, 16, 29]

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.16, paused: !isPlaying)) { timeline in
            let phase = timeline.date.timeIntervalSinceReferenceDate

            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(baseHeights.enumerated()), id: \.offset) { index, baseHeight in
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.82, green: 0.58, blue: 1.0),
                                    XYStyle.accent,
                                    Color(red: 0.24, green: 0.86, blue: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 5, height: barHeight(baseHeight: baseHeight, index: index, phase: phase))
                        .shadow(color: XYStyle.accent.opacity(isPlaying ? 0.46 : 0.22), radius: isPlaying ? 6 : 3)
                }
            }
            .frame(height: 42)
            .opacity(isPlaying ? 0.98 : 0.58)
            .animation(.easeInOut(duration: 0.20), value: isPlaying)
        }
        .frame(height: 42)
    }

    private func barHeight(baseHeight: CGFloat, index: Int, phase: TimeInterval) -> CGFloat {
        guard isPlaying else {
            return max(8, baseHeight * 0.34)
        }

        let wave = sin(phase * (2.2 + Double(index % 5) * 0.28) + Double(index) * 0.72)
        let pulse = (wave + 1) * 0.5
        let lift = CGFloat(pulse) * (16 + CGFloat(index % 4) * 3)
        return min(42, max(8, baseHeight * 0.54 + lift))
    }
}

#Preview {
    NowPlayingView()
        .environmentObject(PlayerViewModel())
}
