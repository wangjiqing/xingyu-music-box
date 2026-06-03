import SwiftUI

private enum LocalMusicBrowseMode: String, CaseIterable, Identifiable {
    case songs
    case artists
    case albums

    var id: String { rawValue }

    var title: String {
        switch self {
        case .songs:
            return "歌曲"
        case .artists:
            return "歌手"
        case .albums:
            return "专辑"
        }
    }
}

private struct ArtistSongGroup: Identifiable, Hashable {
    let name: String
    let songs: [Song]

    var id: String { name }
}

private struct AlbumSongGroup: Identifiable, Hashable {
    let title: String
    let artistName: String
    let songs: [Song]

    var id: String { title }

    var coverSong: Song? {
        songs.first
    }
}

struct SongListView: View {
    @EnvironmentObject private var viewModel: PlayerViewModel
    @State private var searchText = ""
    @State private var browseMode: LocalMusicBrowseMode = .songs
    var layoutContext: AppLayoutContext = .phone
    var onMiniPlayerTap: () -> Void = {}

    private var scrollBottomPadding: CGFloat {
        layoutContext == .phone ? 178 : 32
    }

    private var miniPlayerBottomPadding: CGFloat {
        layoutContext == .phone ? 82 : 16
    }

    private var filteredSongs: [Song] {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return viewModel.songs }

        return viewModel.songs.filter { song in
            song.title.localizedCaseInsensitiveContains(keyword)
                || song.artist.localizedCaseInsensitiveContains(keyword)
                || song.album.localizedCaseInsensitiveContains(keyword)
        }
    }

    private var artistGroups: [ArtistSongGroup] {
        Dictionary(grouping: viewModel.songs, by: { normalizedArtistName($0.artist) })
            .map { ArtistSongGroup(name: $0.key, songs: sortedGroupSongs($0.value)) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private var filteredArtistGroups: [ArtistSongGroup] {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return artistGroups }

        return artistGroups.filter { group in
            group.name.localizedCaseInsensitiveContains(keyword)
                || group.songs.contains { song in
                    song.title.localizedCaseInsensitiveContains(keyword)
                        || song.album.localizedCaseInsensitiveContains(keyword)
                }
        }
    }

    private var albumGroups: [AlbumSongGroup] {
        Dictionary(grouping: viewModel.songs, by: { normalizedAlbumTitle($0.album) })
            .map { title, songs in
                AlbumSongGroup(
                    title: title,
                    artistName: albumArtistName(for: songs),
                    songs: sortedGroupSongs(songs)
                )
            }
            .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }

    private var filteredAlbumGroups: [AlbumSongGroup] {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return albumGroups }

        return albumGroups.filter { group in
            group.title.localizedCaseInsensitiveContains(keyword)
                || group.artistName.localizedCaseInsensitiveContains(keyword)
                || group.songs.contains { song in
                    song.title.localizedCaseInsensitiveContains(keyword)
                        || song.artist.localizedCaseInsensitiveContains(keyword)
                }
        }
    }

    private var hasSearchKeyword: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ThemeBackground()

                VStack(spacing: 0) {
                    header

                    ScrollViewReader { proxy in
                        ZStack(alignment: .bottomTrailing) {
                            ScrollView {
                                LazyVStack(spacing: 14) {
                                    mediaLibraryStatusSection

                                    switch browseMode {
                                    case .songs:
                                        songListSection(songs: filteredSongs, emptyTitle: "暂无本地歌曲")
                                    case .artists:
                                        artistListSection(groups: filteredArtistGroups)
                                    case .albums:
                                        albumListSection(groups: filteredAlbumGroups)
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.top, 10)
                                .padding(.bottom, scrollBottomPadding)
                            }
                            .refreshable {
                                viewModel.refreshMediaLibrarySongs()
                            }

                            currentPlayingAnchorButton(proxy: proxy)
                        }
                    }

                    MiniPlayerView(onTap: onMiniPlayerTap)
                        .padding(.horizontal)
                        .padding(.bottom, miniPlayerBottomPadding)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("本地歌曲")
                        .font(.title.weight(.bold))
                        .foregroundStyle(XYStyle.text)
                    Text("本地音乐 \(viewModel.mediaLibrarySongCount) 首 · \(viewModel.localMusicSortModeTitle)")
                        .font(.footnote)
                        .foregroundStyle(XYStyle.muted)
                }

                Spacer()

                Button {
                    viewModel.refreshMediaLibrarySongs()
                } label: {
                    Image(systemName: viewModel.isRefreshingMediaLibrary ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(XYStyle.accent)
                        .frame(width: 40, height: 40)
                        .background(XYStyle.panel.opacity(0.78), in: Circle())
                        .overlay {
                            Circle().stroke(XYStyle.line, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isRefreshingMediaLibrary)

                Menu {
                    Picker("排序方式", selection: Binding(
                        get: { viewModel.localMusicSortMode },
                        set: { viewModel.localMusicSortMode = $0 }
                    )) {
                        ForEach(LocalMusicSortMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(XYStyle.accent)
                        .frame(width: 40, height: 40)
                        .background(XYStyle.panel.opacity(0.78), in: Circle())
                        .overlay {
                            Circle().stroke(XYStyle.line, lineWidth: 1)
                        }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)

            Picker("浏览方式", selection: $browseMode) {
                ForEach(LocalMusicBrowseMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 14)

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(XYStyle.accent)
                TextField(searchPlaceholder, text: $searchText)
                    .foregroundStyle(XYStyle.text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                Spacer()
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(XYStyle.muted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .font(.subheadline)
            .padding(.horizontal, 14)
            .frame(height: 40)
            .background(Color.black.opacity(0.22), in: Capsule())
            .overlay {
                Capsule().stroke(XYStyle.line, lineWidth: 1)
            }
            .padding(.horizontal, 14)
        }
    }

    private var searchPlaceholder: String {
        switch browseMode {
        case .songs:
            return "搜索本地音乐、歌手、专辑"
        case .artists:
            return "搜索歌手或歌曲"
        case .albums:
            return "搜索专辑、歌手或歌曲"
        }
    }

    private func songListSection(songs: [Song], emptyTitle: String) -> some View {
        Group {
            if songs.isEmpty {
                emptyState(title: hasSearchKeyword ? "没有找到歌曲" : emptyTitle, systemImage: hasSearchKeyword ? "magnifyingglass" : "music.note.list")
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(songs) { song in
                        Button {
                            viewModel.play(song: song, queue: songs)
                        } label: {
                            SongRowView(
                                song: song,
                                isCurrent: song.id == viewModel.currentSong?.id,
                                playCount: viewModel.mediaLibraryPlayCounts[song.id] ?? 0,
                                isFavorite: viewModel.isFavorite(song)
                            )
                        }
                        .buttonStyle(.plain)
                        .id(song.id)
                    }
                }
            }
        }
    }

    private func artistListSection(groups: [ArtistSongGroup]) -> some View {
        Group {
            if groups.isEmpty {
                emptyState(title: hasSearchKeyword ? "没有找到歌手" : "没有歌手数据", systemImage: hasSearchKeyword ? "magnifyingglass" : "music.mic")
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(groups) { group in
                        NavigationLink {
                            LocalMusicGroupDetailView(
                                title: group.name,
                                subtitle: "\(group.songs.count) 首歌曲",
                                songs: group.songs,
                                layoutContext: layoutContext,
                                onMiniPlayerTap: onMiniPlayerTap
                            )
                        } label: {
                            ArtistGroupRowView(group: group)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func albumListSection(groups: [AlbumSongGroup]) -> some View {
        Group {
            if groups.isEmpty {
                emptyState(title: hasSearchKeyword ? "没有找到专辑" : "没有专辑数据", systemImage: hasSearchKeyword ? "magnifyingglass" : "rectangle.stack")
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(groups) { group in
                        NavigationLink {
                            LocalMusicGroupDetailView(
                                title: group.title,
                                subtitle: "\(group.artistName) · \(group.songs.count) 首歌曲",
                                songs: group.songs,
                                layoutContext: layoutContext,
                                onMiniPlayerTap: onMiniPlayerTap
                            )
                        } label: {
                            AlbumGroupRowView(group: group)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func emptyState(title: String, systemImage: String) -> some View {
        ContentUnavailableView(
            title,
            systemImage: systemImage,
            description: Text(hasSearchKeyword ? "换个关键词试试。" : "授权并刷新系统媒体库后，这里会显示可播放的本地音乐。")
        )
        .foregroundStyle(XYStyle.text)
        .padding(20)
        .glassCard()
    }

    @ViewBuilder
    private func currentPlayingAnchorButton(proxy: ScrollViewProxy) -> some View {
        if browseMode == .songs,
           let currentSong = viewModel.currentSong,
           filteredSongs.contains(where: { $0.id == currentSong.id }) {
            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                    proxy.scrollTo(currentSong.id, anchor: .center)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "scope")
                        .font(.caption.weight(.bold))
                    Text("当前播放")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(Color.black.opacity(0.82))
                .padding(.horizontal, 12)
                .frame(height: 36)
                .background(XYStyle.accent, in: Capsule())
                .shadow(color: XYStyle.accent.opacity(0.30), radius: 12, y: 5)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 18)
            .padding(.bottom, 18)
        }
    }

    @ViewBuilder
    private var mediaLibraryStatusSection: some View {
        if viewModel.canRequestMediaLibraryAuthorization {
            mediaLibraryActionCard(
                title: "读取系统媒体库",
                message: viewModel.mediaLibraryAuthorizationTitle,
                systemImage: "music.note.list",
                tint: XYStyle.accent,
                actionTitle: "授权"
            ) {
                viewModel.requestMediaLibraryAuthorization()
            }
        } else if viewModel.shouldShowMediaLibraryDeniedMessage {
            mediaLibraryMessageCard(
                title: "无法读取系统媒体库",
                message: viewModel.mediaLibraryAuthorizationTitle,
                systemImage: "lock.circle",
                tint: XYStyle.danger
            )
        } else if viewModel.hasAuthorizedEmptyMediaLibrary {
            mediaLibraryMessageCard(
                title: "还没有同步音乐",
                message: "请先通过 Finder、iTunes 或爱思助手把音乐同步到本机系统媒体库。",
                systemImage: "tray",
                tint: XYStyle.muted
            )
        } else if viewModel.hasAuthorizedMediaLibraryWithoutPlayableSongs {
            mediaLibraryMessageCard(
                title: "没有可播放的本地媒体库歌曲",
                message: "扫描到 \(viewModel.mediaLibraryScannedSongCount) 首，但都没有可用 assetURL，可能是云端、受保护或 DRM 内容。",
                systemImage: "exclamationmark.triangle",
                tint: XYStyle.danger
            )
        }
    }

    private func mediaLibraryActionCard(
        title: String,
        message: String,
        systemImage: String,
        tint: Color,
        actionTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("系统媒体库")
                .font(.caption.weight(.semibold))
                .foregroundStyle(XYStyle.muted)
                .padding(.horizontal, 2)

            Button(action: action) {
                mediaLibraryCardContent(
                    title: title,
                    message: message,
                    systemImage: systemImage,
                    tint: tint,
                    trailing: actionTitle
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func mediaLibraryMessageCard(
        title: String,
        message: String,
        systemImage: String,
        tint: Color
    ) -> some View {
        mediaLibraryCardContent(
            title: title,
            message: message,
            systemImage: systemImage,
            tint: tint,
            trailing: nil
        )
    }

    private func mediaLibraryCardContent(
        title: String,
        message: String,
        systemImage: String,
        tint: Color,
        trailing: String?
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 34)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(XYStyle.text)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(XYStyle.muted)
                    .lineLimit(3)
            }

            Spacer()

            if let trailing {
                Text(trailing)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
            }
        }
        .padding(14)
        .background(XYStyle.panel.opacity(0.58), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(XYStyle.line, lineWidth: 1)
        }
    }
}

private struct ArtistGroupRowView: View {
    let group: ArtistSongGroup

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(group.name)
                    .font(.headline)
                    .foregroundStyle(XYStyle.text)
                    .lineLimit(1)

                Text("\(group.songs.count) 首歌曲")
                    .font(.caption)
                    .foregroundStyle(XYStyle.muted)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.white.opacity(0.38))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(XYStyle.line)
                .frame(height: 1)
                .padding(.leading, 12)
        }
    }
}

private struct AlbumGroupRowView: View {
    let group: AlbumSongGroup

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(group.title)
                    .font(.headline)
                    .foregroundStyle(XYStyle.text)
                    .lineLimit(1)

                Text("\(group.artistName) · \(group.songs.count) 首歌曲")
                    .font(.caption)
                    .foregroundStyle(XYStyle.muted)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.white.opacity(0.38))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(XYStyle.line)
                .frame(height: 1)
                .padding(.leading, 12)
        }
    }
}

private struct LocalMusicGroupDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: PlayerViewModel

    let title: String
    let subtitle: String
    let songs: [Song]
    var layoutContext: AppLayoutContext
    var onMiniPlayerTap: () -> Void

    private var scrollBottomPadding: CGFloat {
        layoutContext == .phone ? 178 : 32
    }

    private var miniPlayerBottomPadding: CGFloat {
        layoutContext == .phone ? 82 : 16
    }

    var body: some View {
        ZStack {
            ThemeBackground()

            VStack(spacing: 0) {
                detailHeader

                ScrollView {
                    LazyVStack(spacing: 14) {
                        if songs.isEmpty {
                            ContentUnavailableView(
                                "暂无歌曲",
                                systemImage: "music.note.list",
                                description: Text("这个分类下暂时没有可播放的本地音乐。")
                            )
                            .foregroundStyle(XYStyle.text)
                            .padding(20)
                            .glassCard()
                        } else {
                            LazyVStack(spacing: 0) {
                                ForEach(songs) { song in
                                    Button {
                                        viewModel.play(song: song, queue: songs)
                                    } label: {
                                        SongRowView(
                                            song: song,
                                            isCurrent: song.id == viewModel.currentSong?.id,
                                            playCount: viewModel.mediaLibraryPlayCounts[song.id] ?? 0,
                                            isFavorite: viewModel.isFavorite(song)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .id(song.id)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
                    .padding(.bottom, scrollBottomPadding)
                }

                MiniPlayerView(onTap: onMiniPlayerTap)
                    .padding(.horizontal)
                    .padding(.bottom, miniPlayerBottomPadding)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var detailHeader: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(XYStyle.accent)
                    .frame(width: 40, height: 40)
                    .background(XYStyle.panel.opacity(0.78), in: Circle())
                    .overlay {
                        Circle().stroke(XYStyle.line, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(XYStyle.text)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(XYStyle.muted)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 8)
    }
}

struct RecentPlaysSectionView: View {
    let records: [RecentPlayRecord]
    let songs: [Song]
    let currentSong: Song?
    let audioImportStatus: (Song) -> String
    let onPlay: (Song) -> Void

    private var rows: [(record: RecentPlayRecord, song: Song)] {
        records.compactMap { record in
            guard let song = songs.first(where: { $0.id == record.songID }) else { return nil }
            return (record, song)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("最近播放")
                .font(.caption.weight(.semibold))
                .foregroundStyle(XYStyle.muted)
                .padding(.horizontal, 2)

            VStack(spacing: 0) {
                ForEach(rows, id: \.record.id) { row in
                    Button {
                        onPlay(row.song)
                    } label: {
                        RecentPlayRowView(
                            song: row.song,
                            playedAt: row.record.playedAt,
                            status: audioImportStatus(row.song),
                            isCurrent: row.song.id == currentSong?.id
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(XYStyle.panel.opacity(0.58), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(XYStyle.line, lineWidth: 1)
            }
        }
    }
}

struct RecentPlayRowView: View {
    let song: Song
    let playedAt: Date
    let status: String
    let isCurrent: Bool

    var body: some View {
        HStack(spacing: 12) {
            CoverView(song: song, size: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.subheadline.weight(isCurrent ? .semibold : .regular))
                    .foregroundStyle(isCurrent ? XYStyle.accent : XYStyle.text)
                    .lineLimit(1)
                Text("\(song.artist) · \(formatDate(playedAt))")
                    .font(.caption)
                    .foregroundStyle(XYStyle.muted)
                    .lineLimit(1)
            }

            Spacer()

            Text(status)
                .font(.caption.weight(.semibold))
                .foregroundStyle(status == "未导入" ? XYStyle.danger : XYStyle.accent)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(isCurrent ? XYStyle.accentSoft : Color.clear)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(XYStyle.line)
                .frame(height: 1)
                .padding(.leading, 64)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct SongRowView: View {
    let song: Song
    let isCurrent: Bool
    var playCount: Int = 0
    var isFavorite: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.headline.weight(isCurrent ? .semibold : .regular))
                    .foregroundStyle(isCurrent ? XYStyle.accent : XYStyle.text)
                    .lineLimit(1)
                Text("\(song.artist) - \(song.album)")
                    .font(.caption)
                    .foregroundStyle(XYStyle.muted)
                    .lineLimit(1)
                if !detailText.isEmpty {
                    Text(detailText)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(XYStyle.accent.opacity(0.86))
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(song.duration)
                .font(.caption.monospacedDigit())
                .foregroundStyle(Color.white.opacity(0.62))
                .frame(width: 42, alignment: .trailing)

            if isCurrent {
                VStack(spacing: 3) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.subheadline)
                    Text("播放中")
                        .font(.caption2.weight(.semibold))
                }
                .foregroundStyle(XYStyle.accent)
                .frame(width: 42)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(isCurrent ? XYStyle.accentSoft : Color.clear)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(XYStyle.line)
                .frame(height: 1)
                .padding(.leading, 12)
            }
    }

    private var detailText: String {
        var parts: [String] = []
        if song.sourceType == .mediaLibrary {
            parts.append("系统媒体库")
            parts.append("播放 \(playCount) 次")
        }
        if isFavorite {
            parts.append("已收藏")
        }
        if isCurrent {
            parts.append("正在播放")
        }
        return parts.joined(separator: " · ")
    }
}

private extension View {
    func listPanel() -> some View {
        background(XYStyle.panel.opacity(0.58), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(XYStyle.line, lineWidth: 1)
            }
    }
}

private func normalizedArtistName(_ artist: String) -> String {
    let trimmed = artist.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? "未知歌手" : trimmed
}

private func normalizedAlbumTitle(_ album: String) -> String {
    let trimmed = album.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? "未知专辑" : trimmed
}

private func sortedGroupSongs(_ songs: [Song]) -> [Song] {
    songs.sorted { lhs, rhs in
        let result = lhs.title.localizedStandardCompare(rhs.title)
        if result == .orderedSame {
            return lhs.artist.localizedStandardCompare(rhs.artist) == .orderedAscending
        }
        return result == .orderedAscending
    }
}

private func albumArtistName(for songs: [Song]) -> String {
    let artists = songs
        .map { normalizedArtistName($0.artist) }
        .reduce(into: [String]()) { result, artist in
            guard !result.contains(where: { $0.compare(artist, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame }) else { return }
            result.append(artist)
        }

    if artists.count > 1 {
        return "多位歌手"
    }

    return artists.first ?? "未知歌手"
}

#Preview {
    SongListView()
        .environmentObject(PlayerViewModel())
}
