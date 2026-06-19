import SwiftUI

private enum IPadDrawerPanel {
    case library
    case favorites
    case settings
}

struct IPadRootView: View {
    @EnvironmentObject private var viewModel: PlayerViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.scenePhase) private var scenePhase

    @State private var messageDismissTask: Task<Void, Never>?

    var body: some View {
        IPadNowPlayingView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeOut(duration: 0.24), value: themeManager.currentTheme)
        .overlay(alignment: .top) {
            if let message = viewModel.message {
                ToastMessageView(message: message)
                    .padding(.top, 10)
                    .padding(.horizontal, 18)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
                    .onTapGesture {
                        viewModel.clearMessage()
                    }
            }
        }
        .animation(.easeOut(duration: 0.22), value: viewModel.message)
        .onChange(of: viewModel.message) { _, message in
            messageDismissTask?.cancel()
            guard message != nil else { return }
            messageDismissTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(2.8))
                viewModel.clearMessage()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                viewModel.refreshMediaLibrarySongs()
            } else if phase == .inactive || phase == .background {
                viewModel.persistPlaybackState()
            }
        }
        .onDisappear {
            messageDismissTask?.cancel()
        }
    }
}

private struct IPadNowPlayingView: View {
    @State private var activeDrawerPanel: IPadDrawerPanel?

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .trailing) {
                NowPlayingView {
                    openDrawer(.library)
                }
                .blur(radius: activeDrawerPanel == nil ? 0 : 1.5)

                if let activeDrawerPanel {
                    Color.black.opacity(0.38)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            closeDrawer()
                        }

                    drawerContent(for: activeDrawerPanel)
                        .frame(width: drawerWidth(for: activeDrawerPanel, availableWidth: proxy.size.width))
                        .frame(maxHeight: .infinity)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .overlay(alignment: .topTrailing) {
                if !shouldUseOriginalNowPlaying(size: proxy.size) {
                    topActions
                        .padding(.top, 18)
                        .padding(.trailing, 28)
                }
            }
        }
    }

    private func shouldUseOriginalNowPlaying(size: CGSize) -> Bool {
        size.width < 860 || size.height < 600
    }

    private var topActions: some View {
        HStack(spacing: 10) {
            headerButton(title: "播放列表", systemImage: "music.note.list") {
                openDrawer(.library)
            }

            headerButton(title: "收藏", systemImage: "heart") {
                openDrawer(.favorites)
            }

            headerButton(title: "设置", systemImage: "gearshape") {
                openDrawer(.settings)
            }
        }
    }

    private func headerButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(XYStyle.accent)
                .padding(.horizontal, 13)
                .frame(height: 38)
                .background(XYStyle.panel.opacity(0.72), in: Capsule())
                .overlay {
                    Capsule().stroke(XYStyle.line, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func drawerContent(for panel: IPadDrawerPanel) -> some View {
        switch panel {
        case .library:
            IPadMusicPanelView(onClose: closeDrawer)
        case .favorites:
            IPadFavoritesPanelView(onClose: closeDrawer)
        case .settings:
            IPadSettingsPanelView(onClose: closeDrawer)
        }
    }

    private func drawerWidth(for panel: IPadDrawerPanel, availableWidth: CGFloat) -> CGFloat {
        switch panel {
        case .library, .favorites:
            return min(max(availableWidth * 0.46, 420), 560)
        case .settings:
            return min(max(availableWidth * 0.50, 460), 680)
        }
    }

    private func openDrawer(_ panel: IPadDrawerPanel) {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
            activeDrawerPanel = panel
        }
    }

    private func closeDrawer() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.90)) {
            activeDrawerPanel = nil
        }
    }
}

private struct IPadMusicPanelView: View {
    @EnvironmentObject private var viewModel: PlayerViewModel
    @State private var selectedPage = 0
    @State private var searchText = ""

    let onClose: () -> Void

    private var filteredSongs: [Song] {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return viewModel.songs }

        return viewModel.songs.filter { song in
            song.title.localizedCaseInsensitiveContains(keyword)
                || song.artist.localizedCaseInsensitiveContains(keyword)
                || song.album.localizedCaseInsensitiveContains(keyword)
        }
    }

    private var recentRows: [(record: RecentPlayRecord, song: Song)] {
        viewModel.recentPlayRecords.compactMap { record in
            guard let song = viewModel.songs.first(where: { $0.id == record.songID }) else { return nil }
            return (record, song)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            panelHeader

            Picker("列表", selection: $selectedPage) {
                Text("本地音乐").tag(0)
                Text("最近播放").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 18)
            .padding(.bottom, 10)

            TabView(selection: $selectedPage) {
                localSongsPage
                    .tag(0)

                recentSongsPage
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 7) {
                Circle()
                    .fill(selectedPage == 0 ? XYStyle.accent : XYStyle.lyricsDimmed)
                    .frame(width: 7, height: 7)
                Circle()
                    .fill(selectedPage == 1 ? XYStyle.accent : XYStyle.lyricsDimmed)
                    .frame(width: 7, height: 7)
            }
            .padding(.vertical, 10)

            Button("关闭", action: onClose)
                .font(.headline)
                .foregroundStyle(XYStyle.text)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(XYStyle.controlBackground)
        }
        .background(.ultraThinMaterial)
        .background(XYStyle.panelDark.opacity(0.92))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(XYStyle.line)
                .frame(width: 1)
        }
        .ignoresSafeArea(edges: .vertical)
    }

    private var panelHeader: some View {
        VStack(spacing: 14) {
            HStack {
                Text("播放列表")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(XYStyle.text)

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(XYStyle.muted)
                        .frame(width: 34, height: 34)
                        .background(XYStyle.controlBackground, in: Circle())
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(XYStyle.accent)
                TextField("搜索歌曲、歌手、专辑", text: $searchText)
                    .foregroundStyle(XYStyle.text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
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
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background(XYStyle.controlBackground, in: Capsule())
            .overlay {
                Capsule().stroke(XYStyle.line, lineWidth: 1)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 22)
        .padding(.bottom, 12)
    }

    private var localSongsPage: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if filteredSongs.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "暂无本地音乐" : "没有找到歌曲",
                        systemImage: searchText.isEmpty ? "music.note.list" : "magnifyingglass",
                        description: Text(searchText.isEmpty ? "授权并刷新系统媒体库后，这里会显示歌曲。" : "换个关键词试试。")
                    )
                    .foregroundStyle(XYStyle.text)
                    .padding(20)
                } else {
                    ForEach(filteredSongs) { song in
                        Button {
                            viewModel.play(song: song, queue: filteredSongs)
                        } label: {
                            SongRowView(
                                song: song,
                                isCurrent: song.id == viewModel.currentSong?.id,
                                playCount: viewModel.mediaLibraryPlayCounts[song.id] ?? 0,
                                isFavorite: viewModel.isFavorite(song)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 18)
        }
        .scrollIndicators(.visible)
    }

    private var recentSongsPage: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if recentRows.isEmpty {
                    ContentUnavailableView(
                        "暂无最近播放",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("播放歌曲后，这里会显示最近播放记录。")
                    )
                    .foregroundStyle(XYStyle.text)
                    .padding(20)
                } else {
                    ForEach(recentRows, id: \.record.id) { row in
                        Button {
                            viewModel.play(song: row.song)
                        } label: {
                            RecentHistoryRowView(
                                song: row.song,
                                playedAt: row.record.playedAt,
                                isCurrent: row.song.id == viewModel.currentSong?.id,
                                statusText: viewModel.audioImportStatus(for: row.song)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 18)
        }
        .scrollIndicators(.visible)
    }
}

private struct IPadFavoritesPanelView: View {
    @EnvironmentObject private var viewModel: PlayerViewModel

    let onClose: () -> Void

    private var favoriteSongs: [Song] {
        viewModel.songs.filter { viewModel.favorites.contains($0.id) }
    }

    var body: some View {
        VStack(spacing: 0) {
            drawerHeader(title: "收藏", subtitle: "\(favoriteSongs.count) 首歌曲", systemImage: "heart")

            if favoriteSongs.isEmpty {
                ContentUnavailableView(
                    "还没有收藏",
                    systemImage: "heart",
                    description: Text("在播放页点亮爱心，把旧时光放进口袋。")
                )
                .foregroundStyle(XYStyle.text)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(20)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(favoriteSongs) { song in
                            Button {
                                viewModel.play(song: song, queue: favoriteSongs)
                            } label: {
                                SongRowView(
                                    song: song,
                                    isCurrent: song.id == viewModel.currentSong?.id,
                                    playCount: viewModel.mediaLibraryPlayCounts[song.id] ?? 0,
                                    isFavorite: true
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 18)
                }
                .scrollIndicators(.visible)
            }

            closeButton
        }
        .ipadDrawerBackground()
    }

    private func drawerHeader(title: String, subtitle: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(XYStyle.accent)
                .frame(width: 36, height: 36)
                .background(XYStyle.accentSoft, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(XYStyle.text)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(XYStyle.muted)
            }

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(XYStyle.muted)
                    .frame(width: 34, height: 34)
                    .background(XYStyle.controlBackground, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.top, 22)
        .padding(.bottom, 12)
    }

    private var closeButton: some View {
        Button("关闭", action: onClose)
            .font(.headline)
            .foregroundStyle(XYStyle.text)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(XYStyle.controlBackground)
    }
}

private struct IPadSettingsPanelView: View {
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("设置")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(XYStyle.text)

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(XYStyle.muted)
                        .frame(width: 34, height: 34)
                        .background(XYStyle.controlBackground, in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.top, 22)
            .padding(.bottom, 8)

            SettingsView(maxContentWidth: nil)
        }
        .ipadDrawerBackground()
    }
}

private extension View {
    func ipadDrawerBackground() -> some View {
        background(.ultraThinMaterial)
            .background(XYStyle.panelDark.opacity(0.92))
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(XYStyle.line)
                    .frame(width: 1)
            }
            .ignoresSafeArea(edges: .vertical)
    }
}

#Preview {
    IPadRootView()
        .environmentObject(PlayerViewModel())
        .environmentObject(ThemeManager())
}
