import MediaPlayer
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel: PlayerViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var pendingConfirmation: SettingsConfirmation?
    @State private var isThemeSheetPresented = false

    var body: some View {
        ZStack {
            ThemeBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("设置")
                            .font(.title.weight(.bold))
                            .foregroundStyle(XYStyle.text)
                        Text("少一点喧哗，多一点旋律。")
                            .font(.footnote)
                            .foregroundStyle(XYStyle.muted)
                    }
                    .padding(.top, 18)

                    settingsCard(title: "主题") {
                        VStack(alignment: .leading, spacing: 12) {
                            Button {
                                isThemeSheetPresented = true
                            } label: {
                                HStack(spacing: 12) {
                                    ThemeSwatches(theme: themeManager.currentTheme)
                                        .frame(width: 58, height: 32)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("主题皮肤")
                                            .font(.headline)
                                            .foregroundStyle(XYStyle.text)
                                        Text(themeManager.currentTheme.displayName)
                                            .font(.caption)
                                            .foregroundStyle(XYStyle.muted)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(XYStyle.accent)
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    settingsCard(title: "音乐库") {
                        VStack(spacing: 0) {
                            SettingsRow(title: "歌曲数量", subtitle: "当前可浏览歌曲", value: "\(viewModel.songs.count)")
                            SettingsDivider()
                            SettingsRow(title: "收藏数量", subtitle: "保存在 UserDefaults", value: "\(viewModel.favorites.count)")
                            SettingsDivider()
                            SettingsRow(title: "最近播放", subtitle: "保存在 UserDefaults", value: "\(viewModel.recentPlayRecords.count)")
                            SettingsDivider()
                            SettingsRow(title: "数据源", subtitle: "系统媒体库优先", value: "iPhone")
                        }
                    }

                    settingsCard(title: "星语音库联调") {
                        MusicVaultProbeView()
                    }

                    settingsCard(title: "系统媒体库测试") {
                        SystemMediaLibraryProbeView()
                    }

                    settingsCard(title: "系统媒体库歌词测试") {
                        SystemMediaLibraryLyricsProbeView()
                    }

                    settingsCard(title: "数据管理 / 测试辅助") {
                        VStack(spacing: 0) {
                            SettingsRow(title: "收藏数量", subtitle: "收藏页同步显示", value: "\(viewModel.favorites.count) 首")
                            SettingsDivider()
                            SettingsRow(title: "最近播放", subtitle: "本地歌曲页顶部区域", value: "\(viewModel.recentPlayRecords.count) 首")
                            SettingsDivider()
                            SettingsRow(title: "上次播放", subtitle: "重启后恢复的歌曲", value: viewModel.savedPlaybackSongTitle)
                            SettingsDivider()
                            SettingsRow(title: "上次进度", subtitle: "保存的播放位置", value: viewModel.savedPlaybackProgressText)
                            SettingsDivider()
                            SettingsRow(title: "播放模式", subtitle: "当前持久化模式", value: viewModel.savedPlaybackModeTitle)
                            SettingsDivider()
                            SettingsActionButton(
                                title: "清空最近播放",
                                systemImage: "clock.arrow.circlepath",
                                isDestructive: true,
                                isDisabled: viewModel.recentPlayRecords.isEmpty
                            ) {
                                viewModel.clearRecentPlays()
                            }
                            SettingsDivider()
                            SettingsActionButton(
                                title: "清空播放状态",
                                systemImage: "memories",
                                isDestructive: true,
                                isDisabled: viewModel.savedPlaybackState == nil
                            ) {
                                viewModel.clearPlaybackState()
                            }
                            SettingsDivider()
                            SettingsActionButton(
                                title: "清空收藏",
                                systemImage: "heart.slash",
                                isDestructive: true,
                                isDisabled: viewModel.favorites.isEmpty
                            ) {
                                pendingConfirmation = .clearFavorites
                            }
                            SettingsDivider()
                            SettingsActionButton(
                                title: "清空全部本地偏好",
                                systemImage: "trash",
                                isDestructive: true,
                                isDisabled: viewModel.favorites.isEmpty && viewModel.recentPlayRecords.isEmpty && viewModel.savedPlaybackState == nil && viewModel.playbackMode == .repeatAll
                            ) {
                                pendingConfirmation = .clearAllLocalPreferences
                            }
                        }
                    }

                    settingsCard(title: "播放器说明") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("星语音乐盒")
                                .font(.headline)
                                .foregroundStyle(XYStyle.text)
                            Text("追忆旧时光的播放器，一个纯粹的音乐播放器。当前版本专注本地音乐、歌词展示、收藏、后台播放和锁屏控制，不接网络或云同步。")
                                .font(.footnote)
                                .foregroundStyle(XYStyle.muted)
                                .lineSpacing(4)
                        }
                    }

                    settingsCard(title: "当前版本") {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("MVP")
                                    .font(.headline)
                                    .foregroundStyle(XYStyle.text)
                                Text("SwiftUI · iOS 17 · AVPlayer")
                                    .font(.caption)
                                    .foregroundStyle(XYStyle.muted)
                            }
                            Spacer()
                            Text("1.0")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(XYStyle.accent)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 32)
            }
        }
        .confirmationDialog(
            pendingConfirmation?.title ?? "",
            isPresented: Binding(
                get: { pendingConfirmation != nil },
                set: { if !$0 { pendingConfirmation = nil } }
            ),
            titleVisibility: .visible
        ) {
            if pendingConfirmation == .clearFavorites {
                Button("确认清空收藏", role: .destructive) {
                    viewModel.clearFavorites()
                    pendingConfirmation = nil
                }
            }
            if pendingConfirmation == .clearAllLocalPreferences {
                Button("确认清空全部本地偏好", role: .destructive) {
                    viewModel.clearAllLocalPreferences()
                    pendingConfirmation = nil
                }
            }
            Button("取消", role: .cancel) {
                pendingConfirmation = nil
            }
        } message: {
            Text(pendingConfirmation?.message ?? "")
        }
        .sheet(isPresented: $isThemeSheetPresented) {
            ThemeSelectionView()
        }
    }

    private func settingsCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(XYStyle.muted)
                .padding(.horizontal, 2)

            content()
                .padding(14)
                .glassCard(cornerRadius: 10)
        }
    }
}

private struct ThemeSwatches: View {
    let theme: AppTheme

    var body: some View {
        HStack(spacing: 4) {
            theme.backgroundTop
            theme.panel
            theme.accent
        }
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(theme.line, lineWidth: 1)
        }
    }
}

private enum SettingsConfirmation: Equatable, Identifiable {
    case clearFavorites
    case clearAllLocalPreferences

    var id: Self { self }

    var title: String {
        switch self {
        case .clearFavorites:
            return "确认清空收藏？"
        case .clearAllLocalPreferences:
            return "确认清空全部本地偏好？"
        }
    }

    var message: String {
        switch self {
        case .clearFavorites:
            return "收藏页会同步清空，此操作不会删除歌曲或音频文件。"
        case .clearAllLocalPreferences:
            return "将清空收藏、最近播放、当前播放状态，并把播放模式恢复为列表循环。不会删除歌曲或音频文件。"
        }
    }
}

struct SettingsRow: View {
    let title: String
    let subtitle: String
    let value: String

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(XYStyle.text)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(XYStyle.muted)
            }

            Spacer()

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(XYStyle.accent)
        }
        .padding(.vertical, 10)
    }
}

struct SettingsActionButton: View {
    let title: String
    let systemImage: String
    let isDestructive: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .opacity(0.6)
            }
            .foregroundStyle(isDisabled ? XYStyle.muted : (isDestructive ? XYStyle.danger : XYStyle.accent))
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(XYStyle.line)
            .frame(height: 1)
    }
}

private struct MusicVaultProbeView: View {
    @State private var isChecking = false
    @State private var status = MusicVaultProbeStatus.idle

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsRow(
                title: "服务地址",
                subtitle: "MusicVaultConfig.defaultBaseURLString",
                value: MusicVaultConfig.defaultBaseURLString
            )

            SettingsDivider()

            SettingsActionButton(
                title: isChecking ? "正在检查星语音库" : "检查星语音库连接",
                systemImage: isChecking ? "hourglass" : "network",
                isDestructive: false,
                isDisabled: isChecking
            ) {
                runProbe()
            }

            SettingsDivider()

            VStack(alignment: .leading, spacing: 8) {
                Text(status.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(status.isSuccess ? XYStyle.accent : XYStyle.text)

                Text(status.message)
                    .font(.caption)
                    .foregroundStyle(status.isFailure ? XYStyle.danger : XYStyle.muted)
                    .lineSpacing(3)
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let detail = status.detail {
                SettingsDivider()

                VStack(alignment: .leading, spacing: 6) {
                    SettingsRow(title: "服务版本", subtitle: detail.serviceName, value: detail.serviceVersion)
                    SettingsDivider()
                    SettingsRow(title: "曲目数量", subtitle: "lyrics \(detail.lyricsCount) · artwork \(detail.artworkCount)", value: "\(detail.trackCount)")
                    SettingsDivider()
                    SettingsRow(title: "匹配测试", subtitle: detail.matchReason, value: detail.matchTitle)
                    SettingsDivider()
                    SettingsRow(title: "歌词资源", subtitle: detail.lyricsFormat, value: detail.lyricsAvailable)
                    SettingsDivider()
                    SettingsRow(title: "封面资源", subtitle: detail.artworkDescription, value: detail.artworkAvailable)
                }
            }
        }
    }

    private func runProbe() {
        guard !isChecking else { return }
        isChecking = true
        status = .running

        Task {
            let result = await MusicVaultProbeRunner().run()
            await MainActor.run {
                status = result
                isChecking = false
            }
        }
    }
}

private struct MusicVaultProbeRunner {
    private let client = MusicVaultApiClient.shared

    func run() async -> MusicVaultProbeStatus {
        do {
            let info = try await client.serverInfo()
            guard info.supportsRequiredReadFeatures else {
                return .failure("服务已连接，但 OpenAPI 功能不完整：apiVersion=\(info.apiVersion)")
            }

            let state = try await client.syncState()
            let match = try await client.matchTrack(
                query: MusicVaultTrackMatchQuery(title: "错错错", artist: "六哲&陈娟儿")
            )

            var lyricsMeta: MusicVaultLyricsMeta?
            var artworkMeta: MusicVaultArtworkMeta?
            if let trackId = match.track?.id {
                lyricsMeta = try? await client.lyricsMeta(trackId: trackId)
                artworkMeta = try? await client.artworkMeta(trackId: trackId)
            }

            let detail = MusicVaultProbeDetail(
                serviceName: info.serviceName,
                serviceVersion: info.serviceVersion,
                trackCount: state.trackCount,
                lyricsCount: state.lyricsCount,
                artworkCount: state.artworkCount,
                matchTitle: match.matched ? "#\(match.track?.id ?? 0)" : "未匹配",
                matchReason: match.matched ? "\(match.track?.title ?? "未知歌曲") · score \(match.score)" : match.reason,
                lyricsAvailable: lyricsMeta?.available == true ? "可用" : "不可用",
                lyricsFormat: lyricsMeta?.format ?? "无歌词 meta",
                artworkAvailable: artworkMeta?.available == true ? "可用" : "不可用",
                artworkDescription: artworkMeta.map { "\($0.mimeType ?? "unknown") · \($0.width ?? 0)x\($0.height ?? 0)" } ?? "无封面 meta"
            )

            return .success(detail)
        } catch {
            return .failure(error.localizedDescription)
        }
    }
}

private struct MusicVaultProbeDetail: Equatable {
    let serviceName: String
    let serviceVersion: String
    let trackCount: Int64
    let lyricsCount: Int64
    let artworkCount: Int64
    let matchTitle: String
    let matchReason: String
    let lyricsAvailable: String
    let lyricsFormat: String
    let artworkAvailable: String
    let artworkDescription: String
}

private enum MusicVaultProbeStatus: Equatable {
    case idle
    case running
    case success(MusicVaultProbeDetail)
    case failure(String)

    var title: String {
        switch self {
        case .idle:
            return "尚未检查"
        case .running:
            return "正在连接"
        case .success:
            return "接口调用成功"
        case .failure:
            return "接口调用失败"
        }
    }

    var message: String {
        switch self {
        case .idle:
            return "点击按钮后会请求 server/info、sync/state、match/track、lyrics/meta 和 artwork/meta。"
        case .running:
            return "正在请求局域网星语音库，请保持 iPhone 与服务端在同一 Wi-Fi。"
        case .success:
            return "星语音乐盒已成功从星语音库获取数据。"
        case .failure(let message):
            return message
        }
    }

    var detail: MusicVaultProbeDetail? {
        if case .success(let detail) = self {
            return detail
        }
        return nil
    }

    var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }

    var isFailure: Bool {
        if case .failure = self {
            return true
        }
        return false
    }
}

private struct SystemMediaLibraryProbeView: View {
    @EnvironmentObject private var viewModel: PlayerViewModel
    @State private var authorizationStatus = MPMediaLibrary.authorizationStatus()
    @State private var scannedItems: [SystemMediaLibrarySongProbe] = []
    @State private var scanMessage = "尚未扫描"

    private var playableProbe: SystemMediaLibrarySongProbe? {
        scannedItems.first { $0.assetURL != nil }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsRow(
                title: "媒体库权限",
                subtitle: "MediaPlayer.framework",
                value: authorizationStatus.probeTitle
            )

            SettingsDivider()

            VStack(spacing: 0) {
                SettingsActionButton(
                    title: "请求媒体库权限",
                    systemImage: "music.note.list",
                    isDestructive: false,
                    isDisabled: false
                ) {
                    requestAuthorization()
                }

                SettingsDivider()

                SettingsActionButton(
                    title: "扫描系统音乐库",
                    systemImage: "magnifyingglass",
                    isDestructive: false,
                    isDisabled: authorizationStatus != .authorized
                ) {
                    scanSystemMusicLibrary()
                }

                SettingsDivider()

                SettingsActionButton(
                    title: "播放第一首可播放歌曲",
                    systemImage: "play.circle",
                    isDestructive: false,
                    isDisabled: playableProbe == nil
                ) {
                    playFirstPlayableSong()
                }
            }

            SettingsDivider()

            SettingsRow(title: "扫描到的歌曲", subtitle: scanMessage, value: "\(scannedItems.count)")

            if !scannedItems.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("前 20 首")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(XYStyle.text)

                    ForEach(scannedItems.prefix(20)) { item in
                        SystemMediaLibraryProbeRow(item: item)
                    }
                }
                .padding(.top, 2)
            }
        }
        .onAppear {
            authorizationStatus = MPMediaLibrary.authorizationStatus()
        }
    }

    private func requestAuthorization() {
        MPMediaLibrary.requestAuthorization { status in
            Task { @MainActor in
                authorizationStatus = status
                scanMessage = status == .authorized ? "已授权，可以扫描" : "当前状态：\(status.probeTitle)"
            }
        }
    }

    private func scanSystemMusicLibrary() {
        authorizationStatus = MPMediaLibrary.authorizationStatus()
        guard authorizationStatus == .authorized else {
            scanMessage = "请先授权媒体库访问"
            return
        }

        let items = MPMediaQuery.songs().items ?? []
        scannedItems = items.map(SystemMediaLibrarySongProbe.init(item:))
        let playableCount = scannedItems.filter { $0.assetURL != nil }.count
        scanMessage = "可直接播放 \(playableCount) 首"
    }

    private func playFirstPlayableSong() {
        guard let probe = playableProbe, let assetURL = probe.assetURL else {
            scanMessage = "未找到 assetURL 非空的歌曲"
            return
        }

        viewModel.playSystemMediaProbe(assetURL: assetURL, title: probe.title)
        scanMessage = "尝试播放：\(probe.title)"
    }
}

private struct SystemMediaLibraryProbeRow: View {
    let item: SystemMediaLibrarySongProbe

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(XYStyle.text)
                .lineLimit(2)

            Text("\(item.artist) · \(item.albumTitle)")
                .font(.caption)
                .foregroundStyle(XYStyle.muted)
                .lineLimit(2)

            VStack(alignment: .leading, spacing: 3) {
                Text("时长：\(item.durationText)")
                Text("persistentID：\(item.persistentID)")
                Text("assetURL：\(item.assetURL == nil ? "无" : "有")")
                Text("artwork：\(item.hasArtwork ? "有" : "无")")
            }
            .font(.caption2.monospacedDigit())
            .foregroundStyle(item.assetURL == nil ? XYStyle.muted : XYStyle.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
}

private struct SystemMediaLibrarySongProbe: Identifiable {
    let id: UInt64
    let title: String
    let artist: String
    let albumTitle: String
    let playbackDuration: TimeInterval
    let persistentID: UInt64
    let assetURL: URL?
    let hasArtwork: Bool

    init(item: MPMediaItem) {
        title = item.title?.nilIfEmpty ?? "未知歌曲"
        artist = item.artist?.nilIfEmpty ?? "未知歌手"
        albumTitle = item.albumTitle?.nilIfEmpty ?? "未知专辑"
        playbackDuration = item.playbackDuration
        persistentID = item.persistentID
        id = item.persistentID
        assetURL = item.assetURL
        hasArtwork = item.artwork != nil
    }

    var durationText: String {
        let seconds = max(0, Int(playbackDuration.rounded()))
        return "\(seconds / 60):\(String(format: "%02d", seconds % 60))"
    }
}

private struct SystemMediaLibraryLyricsProbeView: View {
    @EnvironmentObject private var viewModel: PlayerViewModel
    @State private var authorizationStatus = MPMediaLibrary.authorizationStatus()
    @State private var lyricItems: [SystemMediaLibraryLyricsProbe] = []
    @State private var currentSongProbe: SystemMediaLibraryLyricsProbe?
    @State private var scanMessage = "尚未扫描"
    @State private var currentSongMessage = "尚未读取"

    private var canReadCurrentMediaLibrarySong: Bool {
        viewModel.currentSong?.sourceType == .mediaLibrary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsRow(
                title: "媒体库权限",
                subtitle: "MPMediaItem.lyrics 只读探针",
                value: authorizationStatus.probeTitle
            )

            SettingsDivider()

            VStack(spacing: 0) {
                SettingsActionButton(
                    title: "扫描前 50 首可播放歌曲歌词",
                    systemImage: "text.magnifyingglass",
                    isDestructive: false,
                    isDisabled: authorizationStatus != .authorized
                ) {
                    scanLyrics()
                }

                SettingsDivider()

                SettingsActionButton(
                    title: "读取当前歌曲歌词",
                    systemImage: "music.note",
                    isDestructive: false,
                    isDisabled: authorizationStatus != .authorized || !canReadCurrentMediaLibrarySong
                ) {
                    readCurrentSongLyrics()
                }
            }

            SettingsDivider()

            SettingsRow(
                title: "扫描结果",
                subtitle: scanMessage,
                value: "\(lyricItems.filter(\.hasLyrics).count)/\(lyricItems.count)"
            )

            if let currentSongProbe {
                VStack(alignment: .leading, spacing: 8) {
                    Text("当前歌曲")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(XYStyle.text)
                    SystemMediaLibraryLyricsProbeRow(item: currentSongProbe)
                }
            } else {
                Text(currentSongMessage)
                    .font(.caption)
                    .foregroundStyle(XYStyle.muted)
            }

            if !lyricItems.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("前 50 首可播放歌曲")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(XYStyle.text)

                    ForEach(lyricItems) { item in
                        SystemMediaLibraryLyricsProbeRow(item: item)
                    }
                }
                .padding(.top, 2)
            }
        }
        .onAppear {
            authorizationStatus = MPMediaLibrary.authorizationStatus()
        }
    }

    private func scanLyrics() {
        authorizationStatus = MPMediaLibrary.authorizationStatus()
        guard authorizationStatus == .authorized else {
            scanMessage = "请先授权媒体库访问"
            return
        }

        let items = (MPMediaQuery.songs().items ?? [])
            .filter { $0.assetURL != nil }
            .prefix(50)
        lyricItems = items.map(SystemMediaLibraryLyricsProbe.init(item:))

        if lyricItems.isEmpty {
            scanMessage = "未找到 assetURL 非空的歌曲"
        } else {
            let lyricsCount = lyricItems.filter(\.hasLyrics).count
            scanMessage = "读取 \(lyricItems.count) 首，\(lyricsCount) 首存在内置歌词"
        }
    }

    private func readCurrentSongLyrics() {
        authorizationStatus = MPMediaLibrary.authorizationStatus()
        guard authorizationStatus == .authorized else {
            currentSongProbe = nil
            currentSongMessage = "请先授权媒体库访问"
            return
        }

        guard let currentSong = viewModel.currentSong,
              currentSong.sourceType == .mediaLibrary,
              let persistentID = UInt64(currentSong.id) else {
            currentSongProbe = nil
            currentSongMessage = "当前歌曲不是系统媒体库歌曲"
            return
        }

        guard let item = mediaItem(persistentID: persistentID) else {
            currentSongProbe = nil
            currentSongMessage = "未在系统媒体库中找到当前歌曲"
            return
        }

        currentSongProbe = SystemMediaLibraryLyricsProbe(item: item)
        currentSongMessage = currentSongProbe?.hasLyrics == true ? "已读取当前歌曲歌词" : "未读取到内置歌词"
    }

    private func mediaItem(persistentID: UInt64) -> MPMediaItem? {
        let predicate = MPMediaPropertyPredicate(
            value: NSNumber(value: persistentID),
            forProperty: MPMediaItemPropertyPersistentID
        )
        let query = MPMediaQuery.songs()
        query.addFilterPredicate(predicate)
        return query.items?.first
    }
}

private struct SystemMediaLibraryLyricsProbeRow: View {
    let item: SystemMediaLibraryLyricsProbe

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(item.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(XYStyle.text)
                .lineLimit(2)

            Text("\(item.artist) · \(item.albumTitle)")
                .font(.caption)
                .foregroundStyle(XYStyle.muted)
                .lineLimit(2)

            VStack(alignment: .leading, spacing: 3) {
                Text("persistentID：\(item.persistentID)")
                Text("assetURL：\(item.hasAssetURL ? "有" : "无")")
                Text("lyrics：\(item.hasLyrics ? "有" : "未读取到内置歌词")")
                Text("长度：\(item.lyricsLength)")
            }
            .font(.caption2.monospacedDigit())
            .foregroundStyle(item.hasLyrics ? XYStyle.accent : XYStyle.muted)

            if let preview = item.lyricsPreview {
                Text(preview)
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.78))
                    .lineSpacing(3)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.14), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(XYStyle.line, lineWidth: 1)
                    }
            } else {
                Text("未读取到内置歌词")
                    .font(.caption)
                    .foregroundStyle(XYStyle.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
}

private struct SystemMediaLibraryLyricsProbe: Identifiable {
    let id: UInt64
    let title: String
    let artist: String
    let albumTitle: String
    let persistentID: UInt64
    let hasAssetURL: Bool
    let lyrics: String?

    init(item: MPMediaItem) {
        title = item.title?.nilIfEmpty ?? "未知歌曲"
        artist = item.artist?.nilIfEmpty ?? "未知歌手"
        albumTitle = item.albumTitle?.nilIfEmpty ?? "未知专辑"
        persistentID = item.persistentID
        id = item.persistentID
        hasAssetURL = item.assetURL != nil
        lyrics = item.lyrics?.nilIfEmpty
    }

    var hasLyrics: Bool {
        lyrics != nil
    }

    var lyricsLength: Int {
        lyrics?.count ?? 0
    }

    var lyricsPreview: String? {
        lyrics.map { String($0.prefix(100)) }
    }
}

private extension MPMediaLibraryAuthorizationStatus {
    var probeTitle: String {
        switch self {
        case .notDetermined:
            return "notDetermined"
        case .denied:
            return "denied"
        case .restricted:
            return "restricted"
        case .authorized:
            return "authorized"
        @unknown default:
            return "unknown"
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

#Preview {
    SettingsView()
        .environmentObject(PlayerViewModel())
}
