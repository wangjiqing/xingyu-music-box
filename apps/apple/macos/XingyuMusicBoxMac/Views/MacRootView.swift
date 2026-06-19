import AppKit
import SwiftUI

struct MacRootView: View {
    @EnvironmentObject private var viewModel: MacPlayerViewModel
    @EnvironmentObject private var themeManager: MacThemeManager
    @State private var isSidebarCollapsed = false
    @State private var isShowingNowPlayingPage = false
    @State private var playbackBarHeight: CGFloat = 112
    @Namespace private var nowPlayingNamespace

    var body: some View {
        GeometryReader { proxy in
            let metrics = MacLayoutMetrics(
                size: proxy.size,
                isSidebarCollapsed: isSidebarCollapsed,
                playbackBarHeight: playbackBarHeight
            )

            ZStack {
                QQMusicBackground()
                    .ignoresSafeArea()

                HStack(spacing: 0) {
                    MacSidebarView(isCollapsed: $isSidebarCollapsed)
                        .frame(width: metrics.sidebarWidth)

                    VStack(spacing: 10) {
                        MacContentView(isShowingNowPlayingPage: $isShowingNowPlayingPage)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                        MacPlaybackBar(
                            playbackBarHeight: $playbackBarHeight,
                            isShowingNowPlayingPage: $isShowingNowPlayingPage,
                            namespace: nowPlayingNamespace
                        )
                    }
                    .padding(.trailing, 10)
                    .padding(.bottom, 12)
                    .overlay(alignment: .leading) {
                        MacRightPaneResizeEdge(isCollapsed: $isSidebarCollapsed)
                    }
                }

                if isShowingNowPlayingPage {
                    MacNowPlayingPage(isPresented: $isShowingNowPlayingPage, namespace: nowPlayingNamespace)
                        .transition(.opacity.combined(with: .scale(scale: 1.015)))
                        .zIndex(5)
                }
            }
            .environment(\.macLayoutMetrics, metrics)
        }
        .foregroundStyle(themeManager.currentTheme.text)
        .frame(minWidth: MacLayoutMetrics.minimumWindowSize.width, minHeight: MacLayoutMetrics.minimumWindowSize.height)
        .animation(.easeOut(duration: 0.24), value: themeManager.currentTheme)
        .animation(.easeOut(duration: 0.20), value: isSidebarCollapsed)
        .animation(.easeOut(duration: 0.22), value: isShowingNowPlayingPage)
        .background(MacTrafficLightVisibilityController(isVisible: !isShowingNowPlayingPage))
    }
}

private struct MacTrafficLightVisibilityController: NSViewRepresentable {
    let isVisible: Bool

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            setTrafficLightsVisible(isVisible, in: view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            setTrafficLightsVisible(isVisible, in: nsView.window)
        }
    }

    private func setTrafficLightsVisible(_ isVisible: Bool, in window: NSWindow?) {
        guard let window else { return }
        [.closeButton, .miniaturizeButton, .zoomButton].forEach { button in
            window.standardWindowButton(button)?.isHidden = !isVisible
        }
    }
}

struct MacLayoutMetrics {
    static let minimumWindowSize = CGSize(width: 1040, height: 680)

    let size: CGSize
    let isSidebarCollapsed: Bool
    let playbackBarHeight: CGFloat

    var isCompact: Bool {
        size.width <= Self.minimumWindowSize.width + 80 || size.height <= Self.minimumWindowSize.height + 40
    }

    var sidebarWidth: CGFloat {
        isSidebarCollapsed ? 84 : 232
    }

    var outerPadding: CGFloat {
        isCompact ? 12 : 16
    }

    var contentPadding: CGFloat {
        0
    }

    var contentGap: CGFloat {
        isCompact ? 14 : 18
    }

    var topBarSearchWidth: CGFloat {
        clamp(size.width * 0.24, min: 260, max: 390)
    }

    var listAlbumColumnWidth: CGFloat {
        isCompact ? 210 : clamp(size.width * 0.23, min: 240, max: 330)
    }

    var playbackBarVerticalPadding: CGFloat {
        0
    }

    private func clamp(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
        Swift.min(Swift.max(value, minValue), maxValue)
    }
}

private struct MacLayoutMetricsKey: EnvironmentKey {
    static let defaultValue = MacLayoutMetrics(
        size: MacLayoutMetrics.minimumWindowSize,
        isSidebarCollapsed: false,
        playbackBarHeight: 112
    )
}

private extension EnvironmentValues {
    var macLayoutMetrics: MacLayoutMetrics {
        get { self[MacLayoutMetricsKey.self] }
        set { self[MacLayoutMetricsKey.self] = newValue }
    }
}

private enum QQMusicPalette {
    static let background = Color.primary.opacity(0.08)
    static let sidebar = Color.clear
    static let panel = Color.primary.opacity(0.045)
    static let panelStrong = Color.primary.opacity(0.070)
    static let selected = Color.primary.opacity(0.105)
    static let text = Color.primary
    static let muted = Color.secondary
    static let accent = Color(red: 0.165, green: 0.430, blue: 0.830)
    static let line = Color.primary.opacity(0.11)
}

private extension MacAppTheme {
    var playbackAccent: Color {
        switch self {
        case .springDawn:
            return Color(red: 0.125, green: 0.520, blue: 0.410)
        case .midsummerStarlight:
            return Color(red: 0.145, green: 0.445, blue: 0.890)
        case .autumnVinyl:
            return Color(red: 0.770, green: 0.410, blue: 0.105)
        case .winterMoonlight:
            return Color(red: 0.560, green: 0.773, blue: 1.000)
        }
    }

    var playbackButtonForeground: Color {
        switch self {
        case .winterMoonlight:
            return Color(red: 0.045, green: 0.070, blue: 0.120)
        case .springDawn, .midsummerStarlight, .autumnVinyl:
            return .white
        }
    }

    var nowPlayingPrimaryText: Color {
        text
    }

    var nowPlayingSecondaryText: Color {
        muted
    }

    var nowPlayingDimText: Color {
        switch self {
        case .winterMoonlight:
            return Color(red: 0.760, green: 0.820, blue: 0.920).opacity(0.56)
        case .springDawn, .midsummerStarlight, .autumnVinyl:
            return Color.black.opacity(0.43)
        }
    }

    var nowPlayingSubtleIcon: Color {
        switch self {
        case .winterMoonlight:
            return Color.white.opacity(0.58)
        case .springDawn, .midsummerStarlight, .autumnVinyl:
            return Color.black.opacity(0.38)
        }
    }

    var nowPlayingDisabledIcon: Color {
        switch self {
        case .winterMoonlight:
            return Color.white.opacity(0.28)
        case .springDawn, .midsummerStarlight, .autumnVinyl:
            return Color.black.opacity(0.22)
        }
    }
}

private struct MacGlassPanel: ViewModifier {
    @EnvironmentObject private var themeManager: MacThemeManager
    var cornerRadius: CGFloat = 10
    var opacity: Double = 0.90

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(themeManager.currentTheme.contentPanelFill.opacity(opacity))
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(themeManager.currentTheme.contentLine.opacity(0.80), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.12), radius: 18, y: 8)
    }
}

private extension View {
    func macGlassPanel(cornerRadius: CGFloat = 10, opacity: Double = 0.90) -> some View {
        modifier(MacGlassPanel(cornerRadius: cornerRadius, opacity: opacity))
    }
}

private struct QQMusicBackground: View {
    @EnvironmentObject private var themeManager: MacThemeManager

    var body: some View {
        MacThemeBackground(theme: themeManager.currentTheme)
    }
}

private extension MacAppTheme {
    var contentPanelFill: Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0.045, green: 0.065, blue: 0.100).opacity(0.88)
        case .light, .none:
            return Color.white.opacity(0.84)
        }
    }

    var contentLine: Color {
        switch colorScheme {
        case .dark:
            return Color.white.opacity(0.16)
        case .light, .none:
            return Color.black.opacity(0.12)
        }
    }
}

private struct MacThemeBackground: View {
    let theme: MacAppTheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    theme.backgroundTop,
                    theme.backgroundMiddle,
                    theme.backgroundBottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            MacSeasonalStaticLayer(theme: theme)

            LinearGradient(
                colors: [
                    Color.white.opacity(theme.colorScheme == .dark ? 0.025 : 0.20),
                    Color.clear,
                    Color.black.opacity(theme.colorScheme == .dark ? 0.30 : 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

private struct MacSeasonalStaticLayer: View {
    let theme: MacAppTheme

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [
                    theme.accent.opacity(0.20),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 720
            )

            RadialGradient(
                colors: [
                    theme.backgroundMiddle.opacity(0.24),
                    Color.clear
                ],
                center: .bottomLeading,
                startRadius: 30,
                endRadius: 680
            )
        }
    }
}


private struct MacSidebarView: View {
    @EnvironmentObject private var viewModel: MacPlayerViewModel
    @EnvironmentObject private var themeManager: MacThemeManager

    @Binding var isCollapsed: Bool

    var body: some View {
        VStack(alignment: isCollapsed ? .center : .leading, spacing: 18) {
            MacAccountHeader(isCollapsed: isCollapsed)

            Button {
                openLocalFolderPanel { viewModel.importLocalFolder($0) }
            } label: {
                if isCollapsed {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(themeManager.currentTheme.text.opacity(0.88))
                        .frame(width: 48, height: 42)
                        .background(themeManager.currentTheme.text.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(themeManager.currentTheme.text.opacity(0.88))
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                        .background(themeManager.currentTheme.text.opacity(0.045), in: RoundedRectangle(cornerRadius: 8))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                                .foregroundStyle(themeManager.currentTheme.text.opacity(0.34))
                                .allowsHitTesting(false)
                        }
                    }
            }
            .buttonStyle(.plain)
            .pointingHandCursor()

            VStack(spacing: 4) {
                MacSidebarRow(section: .favorites, badge: viewModel.favoriteCount, isCollapsed: isCollapsed)
                MacSidebarRow(section: .recent, badge: viewModel.recentCount, isCollapsed: isCollapsed)
                MacSidebarRow(section: .local, badge: viewModel.localCount, isCollapsed: isCollapsed)
            }

            Spacer()

            MacSidebarBottomControls(isCollapsed: $isCollapsed)
        }
        .padding(.top, 16)
        .padding(.horizontal, isCollapsed ? 12 : 14)
        .padding(.bottom, 16)
    }
}

private struct MacRightPaneResizeEdge: View {
    @Binding var isCollapsed: Bool
    @State private var isHovering = false
    @State private var didToggleDuringDrag = false

    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.001))
            .frame(width: 8)
            .contentShape(Rectangle())
            .onHover { hovering in
                isHovering = hovering
                if hovering {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
            .onDisappear {
                if isHovering {
                    NSCursor.pop()
                    isHovering = false
                }
            }
            .gesture(
                DragGesture(minimumDistance: 4)
                    .onChanged { value in
                        guard !didToggleDuringDrag else { return }
                        if isCollapsed, value.translation.width > 12 {
                            didToggleDuringDrag = true
                            isCollapsed = false
                        } else if !isCollapsed, value.translation.width < -12 {
                            didToggleDuringDrag = true
                            isCollapsed = true
                        }
                    }
                    .onEnded { _ in
                        didToggleDuringDrag = false
                    }
            )
            .accessibilityLabel("调整侧边栏")
    }
}

private struct MacAccountHeader: View {
    @EnvironmentObject private var themeManager: MacThemeManager

    let isCollapsed: Bool
    private static let iconPath = "/Users/wangjiqing/Project/xingyu-music-box/assets/app-icon/xingyu-music-box-icon-midsummer-starlight-512.png"

    var body: some View {
        HStack(spacing: 10) {
            appIcon
                .frame(width: 32, height: 32)

            if !isCollapsed {
                Text("星语音乐盒")
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                    .foregroundStyle(QQMusicPalette.text)

                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var appIcon: some View {
        if let image = NSImage(contentsOfFile: Self.iconPath) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
        } else {
            Circle()
                .fill(QQMusicPalette.accent.opacity(0.92))
                .overlay {
                    Image(systemName: "music.note")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
        }
    }
}

private struct MacSidebarBottomControls: View {
    @EnvironmentObject private var viewModel: MacPlayerViewModel
    @EnvironmentObject private var themeManager: MacThemeManager

    @Binding var isCollapsed: Bool
    @State private var isShowingThemePicker = false

    var body: some View {
        Group {
            if isCollapsed {
                VStack(spacing: 10) {
                    buttons
                }
            } else {
                HStack(spacing: 18) {
                    buttons
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: isCollapsed ? .center : .leading)
    }

    @ViewBuilder
    private var buttons: some View {
        MacSidebarToolButton(
            systemImage: isCollapsed ? "chevron.right.circle" : "chevron.left.circle",
            accessibilityLabel: isCollapsed ? "打开菜单" : "收起菜单"
        ) {
            isCollapsed.toggle()
        }

        MacSidebarToolButton(systemImage: "gearshape", accessibilityLabel: "设置") {
            viewModel.isShowingSettings = true
        }

        MacSidebarToolButton(systemImage: "tshirt", accessibilityLabel: "换肤") {
            isShowingThemePicker.toggle()
        }
        .popover(isPresented: $isShowingThemePicker, arrowEdge: .trailing) {
            MacThemePickerPopover(isShowingThemePicker: $isShowingThemePicker)
                .environmentObject(themeManager)
        }
    }
}

private struct MacThemePickerPopover: View {
    @EnvironmentObject private var themeManager: MacThemeManager
    @Binding var isShowingThemePicker: Bool

    private let columns = [
        GridItem(.fixed(142), spacing: 10),
        GridItem(.fixed(142), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("主题皮肤")
                    .font(.system(size: 13, weight: .bold))
                Spacer()
                Button {
                    isShowingThemePicker = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .help("关闭")
                .pointingHandCursor()
            }

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(MacAppTheme.allCases) { theme in
                    MacThemePickerCell(
                        theme: theme,
                        isSelected: theme == themeManager.currentTheme
                    ) {
                        withAnimation(.easeOut(duration: 0.22)) {
                            themeManager.select(theme)
                        }
                    }
                }
            }
        }
        .padding(14)
        .frame(width: 326)
        .foregroundStyle(themeManager.currentTheme.text)
        .background(themeManager.currentTheme.panel.opacity(0.92))
    }
}

private struct MacThemePickerCell: View {
    let theme: MacAppTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 7) {
                ZStack(alignment: .topTrailing) {
                    MacThemePreview(theme: theme)
                        .frame(width: 142, height: 78)
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                }

                HStack(spacing: 6) {
                    Text(theme.displayName)
                        .font(.system(size: 11, weight: .semibold))
                        .lineLimit(1)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .semibold))
                    }
                }
                .padding(.horizontal, 2)
            }
            .padding(5)
            .background(isSelected ? theme.accent.opacity(0.24) : Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? theme.accent.opacity(0.82) : theme.line.opacity(0.58), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(theme.text)
        .help(theme.displayName)
        .pointingHandCursor()
    }
}

private struct MacThemePreview: View {
    let theme: MacAppTheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [theme.backgroundTop, theme.backgroundMiddle, theme.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(theme.accent.opacity(0.42))
                .frame(width: 38, height: 38)
                .offset(x: 38, y: -18)
        }
    }
}

private struct MacSidebarToolButton: View {
    let systemImage: String
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .medium))
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(QQMusicPalette.text.opacity(0.64))
        .help(accessibilityLabel)
        .accessibilityLabel(accessibilityLabel)
        .pointingHandCursor()
    }
}

private struct MacSidebarRow: View {
    @EnvironmentObject private var viewModel: MacPlayerViewModel
    @EnvironmentObject private var themeManager: MacThemeManager

    let section: MacLibrarySection
    let badge: Int?
    let isCollapsed: Bool

    var isSelected: Bool {
        viewModel.selectedSection == section
    }

    var body: some View {
        Button {
            viewModel.isShowingSettings = false
            viewModel.selectedSection = section
        } label: {
            HStack(spacing: isCollapsed ? 0 : 10) {
                Image(systemName: section.systemImage)
                    .font(.system(size: isCollapsed ? 18 : 14, weight: .medium))
                    .frame(width: isCollapsed ? 48 : 18)
                if !isCollapsed {
                    Text("\(section.title) · \(badge.map(String.init) ?? "")".trimmingCharacters(in: CharacterSet(charactersIn: " ·")))
                        .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    Spacer()
                }
            }
            .padding(.horizontal, isCollapsed ? 0 : 10)
            .frame(width: isCollapsed ? 54 : nil)
            .frame(maxWidth: isCollapsed ? nil : .infinity)
            .frame(height: isCollapsed ? 54 : 36)
            .background(isSelected ? QQMusicPalette.selected : Color.clear, in: RoundedRectangle(cornerRadius: isCollapsed ? 10 : 7))
            .contentShape(RoundedRectangle(cornerRadius: isCollapsed ? 10 : 7))
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? QQMusicPalette.text : QQMusicPalette.text.opacity(0.72))
        .pointingHandCursor()
    }
}

private struct MacContentView: View {
    @EnvironmentObject private var viewModel: MacPlayerViewModel
    @Environment(\.macLayoutMetrics) private var metrics
    @Binding var isShowingNowPlayingPage: Bool

    var body: some View {
        VStack(spacing: 0) {
            mainPane
        }
    }

    @ViewBuilder
    private var mainPane: some View {
        if viewModel.isShowingSettings {
            MacSettingsSummaryView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            switch viewModel.selectedSection {
            case .local:
                MacLocalLibraryView {
                    withAnimation(.spring(response: 0.50, dampingFraction: 0.90)) {
                        isShowingNowPlayingPage = true
                    }
                }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .favorites:
                MacSavedTracksView(
                    title: "喜欢",
                    tracks: viewModel.favoriteTracks,
                    emptyTitle: "暂无喜欢的歌曲",
                    emptySystemImage: "heart"
                ) {
                    withAnimation(.spring(response: 0.50, dampingFraction: 0.90)) {
                        isShowingNowPlayingPage = true
                    }
                }
            case .recent:
                MacSavedTracksView(
                    title: "最近",
                    tracks: viewModel.recentTracks,
                    emptyTitle: "暂无最近播放",
                    emptySystemImage: "clock"
                ) {
                    withAnimation(.spring(response: 0.50, dampingFraction: 0.90)) {
                        isShowingNowPlayingPage = true
                    }
                }
            }
        }
    }
}

private struct MacLocalLibraryView: View {
    @EnvironmentObject private var viewModel: MacPlayerViewModel
    let showNowPlaying: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(red: 1.0, green: 0.58, blue: 0.58))
            }

            MacTrackBrowserView(tracks: viewModel.localTracks, showNowPlaying: showNowPlaying)
        }
        .foregroundStyle(QQMusicPalette.text)
    }
}

private struct MacPillButton: View {
    @EnvironmentObject private var themeManager: MacThemeManager

    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 14)
                .frame(height: 30)
                .background(QQMusicPalette.panelStrong, in: Capsule())
        }
        .buttonStyle(.plain)
        .foregroundStyle(QQMusicPalette.text)
        .pointingHandCursor()
    }
}

private struct MacMiniSearchLabel: View {
    @EnvironmentObject private var themeManager: MacThemeManager

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
            Text("搜索")
            Divider()
                .frame(height: 14)
                .overlay(QQMusicPalette.line)
            Image(systemName: "line.3.horizontal")
            Image(systemName: "person")
            Image(systemName: "slider.horizontal.3")
        }
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(QQMusicPalette.muted)
        .padding(.horizontal, 12)
        .frame(height: 30)
        .background(QQMusicPalette.panelStrong, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct MacSavedTracksView: View {
    @EnvironmentObject private var viewModel: MacPlayerViewModel
    @Environment(\.macLayoutMetrics) private var metrics

    let title: String
    let tracks: [MacTrackItem]
    let emptyTitle: String
    let emptySystemImage: String
    let showNowPlaying: () -> Void

    var body: some View {
        MacTrackBrowserView(
                tracks: tracks,
                emptyTitle: emptyTitle,
                emptySystemImage: emptySystemImage,
                showNowPlaying: showNowPlaying
        )
        .foregroundStyle(QQMusicPalette.text)
    }
}

private enum MacTrackListGrouping {
    case none
    case artist
    case album

    var accessibilityLabel: String {
        switch self {
        case .none: return "默认的歌曲列表"
        case .artist: return "按照歌手分组"
        case .album: return "按照专辑分组"
        }
    }

    var systemImage: String {
        switch self {
        case .none: return "line.3.horizontal"
        case .artist: return "person"
        case .album: return "opticaldisc"
        }
    }

    var groupTitle: String {
        switch self {
        case .none: return "歌曲"
        case .artist: return "歌手"
        case .album: return "专辑"
        }
    }

    var searchPlaceholder: String {
        switch self {
        case .none: return "搜索"
        case .artist: return "搜索歌手"
        case .album: return "搜索专辑"
        }
    }
}

private struct MacTrackBrowserView: View {
    let tracks: [MacTrackItem]
    var emptyTitle: String?
    var emptySystemImage = "music.note.list"
    var showNowPlaying: (() -> Void)?

    @State private var searchText = ""
    @State private var grouping: MacTrackListGrouping = .none
    @State private var selectedGroupKey: String?

    private var filteredTracks: [MacTrackItem] {
        let normalizedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedSearch.isEmpty else { return tracks }
        return tracks.filter { track in
            track.title.localizedCaseInsensitiveContains(normalizedSearch)
                || track.artist.localizedCaseInsensitiveContains(normalizedSearch)
                || track.album.localizedCaseInsensitiveContains(normalizedSearch)
        }
    }

    private var groupSummaries: [MacTrackGroupSummary] {
        guard grouping != .none else { return [] }
        let groups = Dictionary(grouping: tracks) { track in
            groupKey(for: track)
        }
        let normalizedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return groups.keys
            .filter { normalizedSearch.isEmpty || $0.localizedCaseInsensitiveContains(normalizedSearch) }
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
            .map { key in
                let groupTracks = groups[key] ?? []
                return MacTrackGroupSummary(
                    key: key,
                    title: key,
                    count: groupTracks.count,
                    artworkData: grouping == .album ? groupTracks.first(where: { $0.artworkData != nil })?.artworkData : nil
                )
            }
    }

    private var selectedGroupTracks: [MacTrackItem] {
        let summaries = groupSummaries
        guard !summaries.isEmpty else { return [] }
        let key = selectedGroupKey.flatMap { selected in
            summaries.contains { $0.key == selected } ? selected : nil
        } ?? summaries[0].key
        return tracks.filter { groupKey(for: $0) == key }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MacTrackBrowserToolbar(searchText: $searchText, grouping: $grouping)

            Group {
                if grouping == .none {
                    MacTrackListView(
                        tracks: filteredTracks,
                        emptyTitle: emptyTitle,
                        emptySystemImage: emptySystemImage,
                        showNowPlaying: showNowPlaying
                    )
                } else {
                    HStack(spacing: 18) {
                        MacTrackGroupSidebar(
                            groups: groupSummaries,
                            grouping: grouping,
                            selectedGroupKey: selectedGroupKey ?? groupSummaries.first?.key
                        ) { group in
                            selectedGroupKey = group.key
                        }
                        .frame(width: 174)

                        MacTrackListView(
                            tracks: selectedGroupTracks,
                            emptyTitle: groupSummaries.isEmpty ? "没有匹配的\(grouping.groupTitle)" : nil,
                            emptySystemImage: grouping.systemImage,
                            showNowPlaying: showNowPlaying
                        )
                    }
                }
            }
            .padding(12)
            .macGlassPanel(cornerRadius: 10, opacity: 0.82)
        }
        .onChange(of: grouping) { _, _ in
            searchText = ""
            selectedGroupKey = nil
        }
    }

    private func groupKey(for track: MacTrackItem) -> String {
        let value: String
        switch grouping {
        case .none:
            value = ""
        case .artist:
            value = track.artist
        case .album:
            value = track.album
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "未知" : trimmed
    }
}

private struct MacTrackBrowserToolbar: View {
    @Binding var searchText: String
    @Binding var grouping: MacTrackListGrouping

    var body: some View {
        HStack(spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(QQMusicPalette.muted)
                TextField(grouping.searchPlaceholder, text: $searchText)
                    .textFieldStyle(.plain)
                    .foregroundStyle(QQMusicPalette.text)
            }
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 12)
            .frame(width: 260, height: 34)
            .background(QQMusicPalette.panelStrong, in: RoundedRectangle(cornerRadius: 8))

            HStack(spacing: 0) {
                groupingButton(.none)
                groupingButton(.artist)
                groupingButton(.album)
            }
            .frame(height: 34)
            .background(QQMusicPalette.panel, in: RoundedRectangle(cornerRadius: 3))
            .overlay {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(QQMusicPalette.line.opacity(0.95), lineWidth: 1)
                    .allowsHitTesting(false)
            }
            .pointingHandCursor()

            Spacer()
        }
    }

    private func groupingButton(_ value: MacTrackListGrouping) -> some View {
        Button {
            grouping = value
        } label: {
            Image(systemName: value.systemImage)
                .font(.system(size: 15, weight: .medium))
                .frame(width: 38, height: 32)
                .contentShape(Rectangle())
                .background(grouping == value ? QQMusicPalette.selected : Color.clear)
        }
        .buttonStyle(.plain)
        .foregroundStyle(grouping == value ? QQMusicPalette.text : QQMusicPalette.muted)
        .help(value.accessibilityLabel)
        .accessibilityLabel(value.accessibilityLabel)
        .pointingHandCursor()
    }
}

private struct PointingHandCursorModifier: ViewModifier {
    var isEnabled = true

    func body(content: Content) -> some View {
        content
            .overlay {
                CursorTrackingView(isEnabled: isEnabled)
            }
    }
}

private struct CursorTrackingView: NSViewRepresentable {
    let isEnabled: Bool

    func makeNSView(context: Context) -> CursorTrackingNSView {
        let view = CursorTrackingNSView()
        view.isEnabled = isEnabled
        return view
    }

    func updateNSView(_ nsView: CursorTrackingNSView, context: Context) {
        nsView.isEnabled = isEnabled
    }
}

private final class CursorTrackingNSView: NSView {
    var isEnabled = true {
        didSet {
            window?.invalidateCursorRects(for: self)
            updateTrackingAreas()
        }
    }

    private var trackingArea: NSTrackingArea?

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    override func updateTrackingAreas() {
        if let trackingArea {
            removeTrackingArea(trackingArea)
        }

        guard isEnabled else {
            trackingArea = nil
            return
        }

        let options: NSTrackingArea.Options = [
            .mouseEnteredAndExited,
            .mouseMoved,
            .activeInKeyWindow,
            .inVisibleRect
        ]
        let nextTrackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(nextTrackingArea)
        trackingArea = nextTrackingArea
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        if isEnabled {
            addCursorRect(bounds, cursor: .pointingHand)
        }
    }

    override func mouseEntered(with event: NSEvent) {
        if isEnabled {
            NSCursor.pointingHand.set()
        }
    }

    override func mouseMoved(with event: NSEvent) {
        if isEnabled {
            NSCursor.pointingHand.set()
        }
    }

    override func mouseExited(with event: NSEvent) {
        NSCursor.arrow.set()
    }
}

private extension View {
    func pointingHandCursor(isEnabled: Bool = true) -> some View {
        modifier(PointingHandCursorModifier(isEnabled: isEnabled))
    }
}

private struct MacDisabledIcon: View {
    let systemName: String
    var color: Color = QQMusicPalette.muted.opacity(0.30)

    var body: some View {
        Image(systemName: systemName)
            .foregroundStyle(color)
            .help("暂不可用")
    }
}

private struct MacTrackGroupSummary: Identifiable {
    let key: String
    let title: String
    let count: Int
    let artworkData: Data?

    var id: String { key }
}

private struct MacTrackGroupSidebar: View {
    let groups: [MacTrackGroupSummary]
    let grouping: MacTrackListGrouping
    let selectedGroupKey: String?
    let onSelect: (MacTrackGroupSummary) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(groups) { group in
                    MacTrackGroupRow(
                        group: group,
                        grouping: grouping,
                        isSelected: selectedGroupKey == group.key
                    ) {
                        onSelect(group)
                    }
                }
            }
        }
        .overlay {
            if groups.isEmpty {
                ContentUnavailableView("没有匹配的\(grouping.groupTitle)", systemImage: grouping.systemImage)
                    .foregroundStyle(QQMusicPalette.text)
            }
        }
    }
}

private struct MacTrackGroupRow: View {
    let group: MacTrackGroupSummary
    let grouping: MacTrackListGrouping
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                groupArtwork

                VStack(alignment: .leading, spacing: 3) {
                    Text(group.title)
                        .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                        .lineLimit(2)
                    Text("\(group.count) 首")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(QQMusicPalette.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 8)
            .frame(height: grouping == .album ? 48 : 42)
            .background(isSelected ? QQMusicPalette.selected : Color.clear, in: RoundedRectangle(cornerRadius: 4))
            .contentShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? QQMusicPalette.text : QQMusicPalette.text.opacity(0.78))
    }

    @ViewBuilder
    private var groupArtwork: some View {
        if grouping == .album {
            MacArtworkThumb(artworkData: group.artworkData, isActive: isSelected, size: 30)
        } else {
            Image(systemName: "person")
                .font(.system(size: 14, weight: .medium))
                .frame(width: 30, height: 30)
                .background(QQMusicPalette.panel, in: Circle())
        }
    }
}

private struct MacTrackListView: View {
    @EnvironmentObject private var viewModel: MacPlayerViewModel
    @EnvironmentObject private var themeManager: MacThemeManager
    @Environment(\.macLayoutMetrics) private var metrics

    let tracks: [MacTrackItem]
    var emptyTitle: String?
    var emptySystemImage = "music.note.list"
    var grouping: MacTrackListGrouping = .none
    var showNowPlaying: (() -> Void)?
    @State private var isHoveringNowPlayingButton = false
    @State private var rowCenters: [String: CGFloat] = [:]
    @State private var viewportHeight: CGFloat = 0

    private var currentTrackIDInList: String? {
        guard let currentTrackID = viewModel.currentTrack?.id,
              tracks.contains(where: { $0.id == currentTrackID })
        else {
            return nil
        }
        return currentTrackID
    }

    private var isCurrentTrackCentered: Bool {
        guard let currentTrackID = currentTrackIDInList,
              let rowCenter = rowCenters[currentTrackID],
              viewportHeight > 0
        else {
            return false
        }
        return abs(rowCenter - viewportHeight / 2) <= 34
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("歌名 / 歌手")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("专辑")
                    .frame(width: metrics.listAlbumColumnWidth, alignment: .leading)
                Text("时长")
                    .frame(width: 70, alignment: .trailing)
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(QQMusicPalette.text.opacity(0.88))
            .padding(.horizontal, 14)
            .padding(.bottom, 8)

            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(groupedTracks.enumerated()), id: \.offset) { groupIndex, section in
                            if let title = section.title {
                                MacTrackGroupHeader(title: title)
                            }
                            ForEach(Array(section.tracks.enumerated()), id: \.element.id) { index, track in
                                MacTrackRow(track: track, index: index + groupIndex)
                                    .id(track.id)
                                    .background {
                                        MacTrackRowCenterReporter(trackID: track.id, isActive: track.id == currentTrackIDInList)
                                    }
                            }
                        }
                    }
                }
                .coordinateSpace(name: MacTrackListCoordinateSpace.name)
                .background {
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: MacTrackListViewportHeightPreferenceKey.self, value: proxy.size.height)
                    }
                }
                .onPreferenceChange(MacTrackRowCenterPreferenceKey.self) { centers in
                    rowCenters = centers
                }
                .onPreferenceChange(MacTrackListViewportHeightPreferenceKey.self) { height in
                    viewportHeight = height
                }
                .overlay {
                    if emptyTitle == nil, viewModel.isImportingLocalFolder {
                        ProgressView("导入本地目录")
                            .controlSize(.large)
                            .tint(QQMusicPalette.accent)
                    } else if tracks.isEmpty {
                        ContentUnavailableView(
                            emptyTitle ?? (viewModel.localTracks.isEmpty ? "尚未导入本地歌曲目录" : "没有匹配的歌曲"),
                            systemImage: emptyTitle == nil && viewModel.localTracks.isEmpty ? "folder.badge.plus" : emptySystemImage
                        )
                            .foregroundStyle(QQMusicPalette.text)
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    if let currentTrackID = currentTrackIDInList, !isCurrentTrackCentered {
                        Button {
                            withAnimation(.spring(response: 0.36, dampingFraction: 0.88)) {
                                scrollProxy.scrollTo(currentTrackID, anchor: .center)
                            }
                        } label: {
                            Image(systemName: "record.circle")
                                .font(.system(size: 25, weight: .light))
                                .frame(width: 42, height: 42)
                                .contentShape(Rectangle())
                                .background(Color.white.opacity(isHoveringNowPlayingButton ? 0.12 : 0.055), in: Rectangle())
                                .overlay {
                                    Rectangle()
                                        .stroke(Color.white.opacity(isHoveringNowPlayingButton ? 0.48 : 0.26), lineWidth: 0.8)
                                        .allowsHitTesting(false)
                                }
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(QQMusicPalette.text.opacity(isHoveringNowPlayingButton ? 0.86 : 0.56))
                        .help("定位到正在播放")
                        .padding(.trailing, 28)
                        .padding(.bottom, 28)
                        .opacity(isHoveringNowPlayingButton ? 1.0 : 0.72)
                        .onHover { hovering in
                            withAnimation(.easeOut(duration: 0.14)) {
                                isHoveringNowPlayingButton = hovering
                            }
                        }
                        .pointingHandCursor()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 2)
    }

    private var groupedTracks: [(title: String?, tracks: [MacTrackItem])] {
        switch grouping {
        case .none:
            return [(nil, tracks)]
        case .artist:
            return groupedTracks { $0.artist }
        case .album:
            return groupedTracks { $0.album }
        }
    }

    private func groupedTracks(by keyPath: (MacTrackItem) -> String) -> [(title: String?, tracks: [MacTrackItem])] {
        let groups = Dictionary(grouping: tracks) { track in
            let value = keyPath(track).trimmingCharacters(in: .whitespacesAndNewlines)
            return value.isEmpty ? "未知" : value
        }
        return groups.keys.sorted { $0.localizedStandardCompare($1) == .orderedAscending }.map { key in
            (key, groups[key] ?? [])
        }
    }
}

private enum MacTrackListCoordinateSpace {
    static let name = "MacTrackListScroll"
}

private struct MacTrackRowCenterReporter: View {
    let trackID: String
    let isActive: Bool

    var body: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(
                    key: MacTrackRowCenterPreferenceKey.self,
                    value: isActive ? [trackID: proxy.frame(in: .named(MacTrackListCoordinateSpace.name)).midY] : [:]
                )
        }
    }
}

private struct MacTrackRowCenterPreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGFloat] = [:]

    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { _, next in next })
    }
}

private struct MacTrackListViewportHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct MacTrackGroupHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(QQMusicPalette.text.opacity(0.82))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 6)
            .background(QQMusicPalette.background.opacity(0.16))
    }
}

private struct MacQualityBadge: View {
    enum Size {
        case small
        case regular

        var fontSize: CGFloat {
            switch self {
            case .small: return 8
            case .regular: return 10
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .small: return 3
            case .regular: return 5
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .small: return 0
            case .regular: return 3
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .small: return 2
            case .regular: return 3
            }
        }
    }

    let label: String?
    var size: Size = .small

    var body: some View {
        if let label = label?.trimmingCharacters(in: .whitespacesAndNewlines), !label.isEmpty {
            Text(label)
                .font(.system(size: size.fontSize, weight: .bold))
                .foregroundStyle(color(for: label))
                .lineLimit(1)
                .padding(.horizontal, size.horizontalPadding)
                .padding(.vertical, size.verticalPadding)
                .overlay {
                    RoundedRectangle(cornerRadius: size.cornerRadius)
                        .stroke(color(for: label), lineWidth: 0.8)
                }
        }
    }

    private func color(for label: String) -> Color {
        switch label {
        case "全景声":
            return Color(red: 0.62, green: 0.84, blue: 1.0)
        case "臻品母带":
            return Color(red: 1.0, green: 0.72, blue: 0.38)
        default:
            return Color(red: 1.0, green: 0.48, blue: 0.34)
        }
    }
}

private struct MacTrackRow: View {
    @EnvironmentObject private var viewModel: MacPlayerViewModel
    @EnvironmentObject private var themeManager: MacThemeManager
    @Environment(\.macLayoutMetrics) private var metrics

    let track: MacTrackItem
    let index: Int

    private var isSelected: Bool {
        viewModel.selectedTrackID == track.id || viewModel.currentTrack?.id == track.id
    }

    private var isNowPlaying: Bool {
        viewModel.currentTrack?.id == track.id && viewModel.isPlaying
    }

    var body: some View {
        HStack(spacing: 12) {
            MacTrackArtworkControl(
                artworkData: track.artworkData,
                isSelected: isSelected,
                isNowPlaying: isNowPlaying
            ) {
                viewModel.play(track)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(track.title)
                        .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                        .lineLimit(1)
                    MacQualityBadge(label: track.qualityBadge, size: .small)
                }
                Text(track.artist)
                    .font(.system(size: 11))
                    .foregroundStyle(QQMusicPalette.muted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(track.album)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(QQMusicPalette.muted)
                .lineLimit(1)
                .frame(width: metrics.listAlbumColumnWidth, alignment: .leading)

            Text(durationText(track.durationMs))
                .font(.system(size: 12, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(QQMusicPalette.muted.opacity(0.92))
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 10)
        .frame(height: 56)
        .background(rowBackground, in: RoundedRectangle(cornerRadius: 2))
        .contentShape(RoundedRectangle(cornerRadius: 2))
        .onTapGesture {
            viewModel.select(track)
        }
        .onTapGesture(count: 2) {
            viewModel.play(track)
        }
        .contextMenu {
            if track.localURL != nil {
                Button {
                    viewModel.revealInFinder(track)
                } label: {
                    Label("查看本地文件", systemImage: "folder")
                }
            }
        }
    }

    private var rowBackground: Color {
        if isSelected {
            return QQMusicPalette.selected
        }
        return index.isMultiple(of: 2) ? QQMusicPalette.panel : Color.clear
    }

    private func durationText(_ durationMs: Int64?) -> String {
        guard let durationMs else { return "--:--" }
        return viewModel.formatTime(Double(durationMs) / 1000)
    }
}

private struct MacTrackArtworkControl: View {
    let artworkData: Data?
    let isSelected: Bool
    let isNowPlaying: Bool
    var size: CGFloat = 34
    let playAction: () -> Void

    @State private var isHovering = false

    var body: some View {
        ZStack {
            MacArtworkThumb(artworkData: artworkData, isActive: isSelected, size: size)

            if isNowPlaying {
                QQNowPlayingIndicator()
                    .frame(width: size, height: size)
                    .transition(.opacity)
            } else if isHovering {
                Image(systemName: "play.fill")
                    .font(.system(size: size > 40 ? 18 : 15, weight: .bold))
                    .foregroundStyle(QQMusicPalette.accent)
                    .frame(width: size, height: size)
                    .background(Color.black.opacity(0.24), in: RoundedRectangle(cornerRadius: size > 40 ? 6 : 4))
                .transition(.opacity)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: size > 40 ? 6 : 4))
        .onTapGesture(perform: playAction)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) {
                isHovering = hovering
            }
        }
        .pointingHandCursor()
    }
}

private struct QQNowPlayingIndicator: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.18)) { timeline in
            let tick = timeline.date.timeIntervalSinceReferenceDate
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(0..<4, id: \.self) { index in
                    let phase = tick * 5.0 + Double(index) * 0.82
                    let height = 9 + (sin(phase) + 1) * 7
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Color.white)
                        .frame(width: 4, height: height)
                }
            }
            .frame(width: 34, height: 34)
            .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 4))
        }
    }
}

private struct MacArtworkThumb: View {
    @EnvironmentObject private var themeManager: MacThemeManager

    let artworkData: Data?
    let isActive: Bool
    var size: CGFloat = 34

    var body: some View {
        Group {
            if let artworkImage {
                Image(nsImage: artworkImage)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: isActive
                                ? [QQMusicPalette.accent.opacity(0.92), QQMusicPalette.muted.opacity(0.78)]
                                : [QQMusicPalette.panelStrong, QQMusicPalette.panel],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        Image(systemName: isActive ? "speaker.wave.2.fill" : "music.note")
                            .font(.system(size: size > 50 ? 28 : 15, weight: .semibold))
                            .foregroundStyle(QQMusicPalette.text.opacity(0.82))
                    }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private var artworkImage: NSImage? {
        artworkData.flatMap(NSImage.init(data:))
    }

    private var cornerRadius: CGFloat {
        size > 50 ? 8 : 4
    }
}

private struct MacNowPlayingInspectorView: View {
    @EnvironmentObject private var viewModel: MacPlayerViewModel
    @EnvironmentObject private var themeManager: MacThemeManager

    private var track: MacTrackItem? {
        viewModel.currentTrack ?? viewModel.selectedTrack
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            VStack(spacing: 14) {
                MacInspectorArtwork(isPlaying: viewModel.isPlaying)
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: 220)
                    .frame(maxWidth: .infinity)

                VStack(spacing: 5) {
                    Text(track?.title ?? "未播放")
                        .font(.system(size: 18, weight: .bold))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                    Text(track.map { "\($0.artist) · \($0.album)" } ?? "选择一首歌曲")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(themeManager.currentTheme.muted)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity)

                progressStrip
            }
            .padding(16)
            .background(themeManager.currentTheme.panel.opacity(0.62), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(themeManager.currentTheme.line.opacity(0.86), lineWidth: 1)
            }

            lyricsPanel
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("正在播放")
                    .font(.system(size: 18, weight: .bold))
                Text(viewModel.isPlaying ? "播放中" : "已暂停")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(themeManager.currentTheme.muted)
            }

            Spacer()

            Image(systemName: viewModel.isPlaying ? "waveform.circle.fill" : "music.note")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(themeManager.currentTheme.accent)
        }
    }

    private var progressStrip: some View {
        VStack(spacing: 8) {
            GeometryReader { proxy in
                let progress = progressRatio(width: proxy.size.width)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(themeManager.currentTheme.line.opacity(0.55))
                    Capsule()
                        .fill(themeManager.currentTheme.accent)
                        .frame(width: progress)
                }
            }
            .frame(height: 5)

            HStack {
                Text(viewModel.formatTime(viewModel.currentTime))
                Spacer()
                Text(viewModel.formatTime(viewModel.duration))
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(themeManager.currentTheme.muted)
            .monospacedDigit()
        }
    }

    private var lyricsPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("歌词")
                    .font(.system(size: 15, weight: .bold))
                Text(viewModel.lyricSourceDescription)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(themeManager.currentTheme.accent.opacity(0.78))
                Spacer()
                Image(systemName: "text.quote")
                    .foregroundStyle(themeManager.currentTheme.muted)
            }

            ScrollView {
                Text(viewModel.lyricsPreview)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(themeManager.currentTheme.text.opacity(0.72))
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .scrollIndicators(.visible)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(themeManager.currentTheme.panel.opacity(0.62), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(themeManager.currentTheme.line.opacity(0.86), lineWidth: 1)
        }
    }

    private func progressRatio(width: CGFloat) -> CGFloat {
        guard viewModel.duration.isFinite, viewModel.duration > 0 else { return 0 }
        return width * min(max(viewModel.currentTime / viewModel.duration, 0), 1)
    }
}

private struct MacInspectorArtwork: View {
    @EnvironmentObject private var themeManager: MacThemeManager

    let isPlaying: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        themeManager.currentTheme.accent.opacity(isPlaying ? 0.86 : 0.62),
                        themeManager.currentTheme.panelDark.opacity(0.90),
                        themeManager.currentTheme.backgroundBottom.opacity(0.95)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                Image(systemName: isPlaying ? "speaker.wave.2.fill" : "music.note")
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(themeManager.currentTheme.text.opacity(0.72))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(themeManager.currentTheme.line.opacity(0.9), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.18), radius: 16, y: 10)
    }
}

private struct MacPlaybackArtworkButton: View {
    @EnvironmentObject private var viewModel: MacPlayerViewModel
    @State private var isHovering = false

    let track: MacTrackItem?
    let size: CGFloat
    @Binding var isShowingNowPlayingPage: Bool
    let namespace: Namespace.ID

    var body: some View {
        ZStack {
            MacArtworkThumb(artworkData: track?.artworkData, isActive: viewModel.isPlaying, size: size)
                .matchedGeometryEffect(id: "now-playing-artwork", in: namespace, isSource: !isShowingNowPlayingPage)

            if isHovering, track != nil {
                RoundedRectangle(cornerRadius: size > 50 ? 8 : 4)
                    .fill(Color.black.opacity(0.36))

                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: size > 78 ? 20 : 17, weight: .bold))
                    .foregroundStyle(QQMusicPalette.text)
                    .shadow(color: Color.black.opacity(0.35), radius: 8, y: 2)
            }
        }
        .frame(width: size, height: size)
        .contentShape(RoundedRectangle(cornerRadius: size > 50 ? 8 : 4))
        .onHover { isHovering = $0 }
        .help(track == nil ? "" : "打开歌曲页")
        .onTapGesture {
            guard track != nil else { return }
            withAnimation(.spring(response: 0.58, dampingFraction: 0.86)) {
                isShowingNowPlayingPage = true
            }
        }
        .pointingHandCursor(isEnabled: track != nil)
    }
}

private struct MacNowPlayingPage: View {
    @EnvironmentObject private var viewModel: MacPlayerViewModel
    @EnvironmentObject private var themeManager: MacThemeManager
    @Binding var isPresented: Bool
    let namespace: Namespace.ID
    @State private var isShowingPlaylist = false
    @State private var isShowingThemePicker = false

    private var track: MacTrackItem? {
        viewModel.currentTrack ?? viewModel.selectedTrack
    }

    var body: some View {
        GeometryReader { proxy in
            let artworkSize = clamp(min(proxy.size.width * 0.42, proxy.size.height * 0.74), min: 430, max: 780)
            let lyricsWidth = clamp(proxy.size.width * 0.34, min: 360, max: 620)
            let pageSpacing = clamp(proxy.size.width * 0.045, min: 56, max: 96)
            let contentMaxWidth = Swift.min(
                proxy.size.width - 52,
                clamp(proxy.size.width * 0.82, min: 980, max: 1540)
            )
            let playlistWidth = clamp(proxy.size.width * 0.32, min: 380, max: 520)
            let playlistHeight = Swift.max(420, proxy.size.height - 118)

            ZStack {
                MacNowPlayingBackground()

                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 26)
                        .padding(.top, 14)

                    HStack(spacing: pageSpacing) {
                        MacPhonographView(track: track, isPlaying: viewModel.isPlaying, namespace: namespace)
                            .frame(width: artworkSize, height: artworkSize * 1.05)

                        MacNowPlayingLyricsView(track: track)
                            .frame(width: lyricsWidth)
                    }
                    .frame(maxWidth: contentMaxWidth, maxHeight: .infinity)
                    .padding(.horizontal, clamp(proxy.size.width * 0.04, min: 42, max: 86))
                        .padding(.bottom, 12)

                    MacNowPlayingBottomBar(isPresented: $isPresented, isShowingPlaylist: $isShowingPlaylist)
                        .padding(.horizontal, 26)
                        .padding(.bottom, 20)
                }

                if isShowingPlaylist {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
                                isShowingPlaylist = false
                            }
                        }

                    HStack {
                        Spacer()
                        MacNowPlayingPlaylistPanel()
                            .frame(width: playlistWidth, height: playlistHeight)
                            .padding(.trailing, 30)
                            .padding(.top, 44)
                            .padding(.bottom, 88)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
            }
            .animation(.spring(response: 0.38, dampingFraction: 0.88), value: isShowingPlaylist)
        }
        .foregroundStyle(themeManager.currentTheme.nowPlayingPrimaryText)
        .background(themeManager.currentTheme.backgroundBottom)
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.50, dampingFraction: 0.90)) {
                    isPresented = false
                }
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help("收起歌曲页")
            .pointingHandCursor()

            Spacer()
        }
        .foregroundStyle(themeManager.currentTheme.nowPlayingSubtleIcon)
    }

    private func clamp(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
        Swift.min(Swift.max(value, minValue), maxValue)
    }
}

private struct MacNowPlayingBackground: View {
    @EnvironmentObject private var themeManager: MacThemeManager

    var body: some View {
        MacThemeBackground(theme: themeManager.currentTheme)
            .overlay {
                RadialGradient(
                    colors: [
                        themeManager.currentTheme.accent.opacity(themeManager.currentTheme.colorScheme == .dark ? 0.20 : 0.30),
                        Color.white.opacity(themeManager.currentTheme.colorScheme == .dark ? 0.02 : 0.14),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 40,
                    endRadius: 760
                )
            }
        .ignoresSafeArea()
    }
}

private struct MacBundleImage: View {
    let name: String
    let subdirectory: String

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.35))
            }
        }
    }

    private var image: NSImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: subdirectory) else {
            return nil
        }
        return NSImage(contentsOf: url)
    }
}

private extension MacAppTheme {
    var phonographResourceDirectory: String {
        "NowPlaying"
    }

    var phonographRecordResourceDirectory: String {
        "NowPlaying"
    }

    var phonographBaseName: String {
        "record_player_light_base@2x"
    }

    var phonographArmName: String {
        "record_player_light_arm@2x"
    }

    var phonographShadowName: String {
        "record_player_light_shadow@2x"
    }

    var phonographChassisName: String {
        "record_player_light_chassis@2x"
    }

    var phonographHighlightName: String {
        "record_player_light_highlight@2x"
    }

    var phonographShadowOpacity: Double {
        0.72
    }
}

private struct MacPhonographView: View {
    @EnvironmentObject private var themeManager: MacThemeManager

    let track: MacTrackItem?
    let isPlaying: Bool
    let namespace: Namespace.ID

    var body: some View {
        GeometryReader { proxy in
            let scale = min(proxy.size.width / 500, proxy.size.height / 492)

            VStack(spacing: 24) {
                ZStack(alignment: .topLeading) {
                    MacBundleImage(
                        name: themeManager.currentTheme.phonographBaseName,
                        subdirectory: themeManager.currentTheme.phonographResourceDirectory
                    )
                        .frame(width: 500, height: 400)

                    MacSpinningRecordView(
                        artworkData: track?.artworkData,
                        isPlaying: isPlaying,
                        namespace: namespace
                    )
                    .frame(width: 270, height: 270)
                    .offset(x: 25, y: 15)

                    MacTonearmView(isPlaying: isPlaying)
                        .frame(width: 65, height: 300)
                        .offset(x: 254, y: -24)
                }
                .frame(width: 500, height: 400)

                Spacer()
                    .frame(height: 40)
            }
            .scaleEffect(scale)
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct MacTonearmView: View {
    @EnvironmentObject private var themeManager: MacThemeManager

    let isPlaying: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let wobble = isPlaying ? sin(context.date.timeIntervalSinceReferenceDate * 1.05) * 0.12 : 0
            let angle = (isPlaying ? 8.2 : -6.0) + wobble

            MacBundleImage(
                name: themeManager.currentTheme.phonographArmName,
                subdirectory: themeManager.currentTheme.phonographResourceDirectory
            )
                .frame(width: 65, height: 300)
                .rotationEffect(.degrees(angle), anchor: UnitPoint(x: 0.604, y: 0.192))
                .animation(.spring(response: 0.92, dampingFraction: 0.92), value: isPlaying)
        }
    }
}

private struct MacSpinningRecordView: View {
    @EnvironmentObject private var themeManager: MacThemeManager
    @State private var baseAngle: Double = 0
    @State private var playStartDate: Date?

    let artworkData: Data?
    let isPlaying: Bool
    let namespace: Namespace.ID

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let angle = currentAngle(at: context.date)

            ZStack {
                MacBundleImage(
                    name: themeManager.currentTheme.phonographShadowName,
                    subdirectory: themeManager.currentTheme.phonographRecordResourceDirectory
                )
                    .frame(width: 294, height: 294)
                    .opacity(themeManager.currentTheme.phonographShadowOpacity)

                ZStack {
                    MacBundleImage(
                        name: themeManager.currentTheme.phonographChassisName,
                        subdirectory: themeManager.currentTheme.phonographRecordResourceDirectory
                    )
                        .frame(width: 270, height: 270)

                    MacArtworkThumb(artworkData: artworkData, isActive: isPlaying, size: 142)
                    .clipShape(Circle())
                    .matchedGeometryEffect(id: "now-playing-artwork", in: namespace, isSource: true)
                    .overlay {
                        Circle()
                            .stroke(themeManager.currentTheme.accent.opacity(0.58), lineWidth: 8)
                    }

                    MacBundleImage(
                        name: themeManager.currentTheme.phonographHighlightName,
                        subdirectory: themeManager.currentTheme.phonographRecordResourceDirectory
                    )
                        .frame(width: 270, height: 270)
                        .opacity(0.94)

                    Circle()
                        .fill(Color.white.opacity(0.92))
                        .frame(width: 14, height: 14)
                        .shadow(color: Color.black.opacity(0.12), radius: 4, y: 1)
                }
                .rotationEffect(.degrees(angle.truncatingRemainder(dividingBy: 360)))
            }
        }
        .onAppear {
            if isPlaying, playStartDate == nil {
                playStartDate = Date()
            }
        }
        .onChange(of: isPlaying) { _, newValue in
            if newValue {
                playStartDate = Date()
            } else {
                baseAngle = currentAngle(at: Date()).truncatingRemainder(dividingBy: 360)
                playStartDate = nil
            }
        }
    }

    private func currentAngle(at date: Date) -> Double {
        guard isPlaying, let playStartDate else {
            return baseAngle
        }
        return baseAngle + date.timeIntervalSince(playStartDate) * 36
    }
}

private struct MacNowPlayingLyricsView: View {
    @EnvironmentObject private var viewModel: MacPlayerViewModel
    @EnvironmentObject private var themeManager: MacThemeManager

    let track: MacTrackItem?
    @State private var isUserBrowsingLyrics = false
    @State private var browseResetTask: Task<Void, Never>?

    private var plainLyricLines: [String] {
        let rawLines = viewModel.lyricsPreview
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return rawLines.isEmpty ? ["本歌曲暂无歌词"] : rawLines
    }

    private var activeTimedLineIndex: Int? {
        viewModel.currentLyricLineIndex
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 10) {
                Text(track?.title ?? "未播放")
                    .font(.system(size: 23, weight: .bold))
                    .foregroundStyle(themeManager.currentTheme.nowPlayingPrimaryText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                Text(track?.artist ?? "暂无歌手信息")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(themeManager.currentTheme.nowPlayingSecondaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ScrollViewReader { reader in
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if viewModel.lyricLines.isEmpty {
                            ForEach(Array(plainLyricLines.enumerated()), id: \.offset) { index, line in
                                Text(line)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(index == 0 && plainLyricLines.count == 1 ? themeManager.currentTheme.nowPlayingSecondaryText : themeManager.currentTheme.nowPlayingDimText)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.82)
                                    .id(index)
                            }
                        } else {
                            ForEach(viewModel.lyricLines) { line in
                                let isActive = line.index == activeTimedLineIndex
                                MacTimedLyricRow(
                                    line: line,
                                    isActive: isActive,
                                    onSeek: {
                                        browseResetTask?.cancel()
                                        isUserBrowsingLyrics = false
                                        viewModel.seek(to: line.time)
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            reader.scrollTo(line.index, anchor: .center)
                                        }
                                    }
                                )
                                .id(line.index)
                                .onHover { hovering in
                                    updateLyricBrowsingState(isBrowsing: hovering)
                                }
                                .animation(.easeOut(duration: 0.18), value: activeTimedLineIndex)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 116)
                }
                .scrollIndicators(.hidden)
                .onHover { hovering in
                    updateLyricBrowsingState(isBrowsing: hovering)
                }
                .mask(alignment: .center) {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.00),
                            .init(color: .black.opacity(0.18), location: 0.08),
                            .init(color: .black, location: 0.22),
                            .init(color: .black, location: 0.78),
                            .init(color: .black.opacity(0.18), location: 0.92),
                            .init(color: .clear, location: 1.00)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .onAppear {
                    if let activeTimedLineIndex {
                        reader.scrollTo(activeTimedLineIndex, anchor: .center)
                    }
                }
                .onChange(of: activeTimedLineIndex) { _, newValue in
                    guard let newValue else { return }
                    guard !isUserBrowsingLyrics else { return }
                    withAnimation(.easeInOut(duration: 0.35)) {
                        reader.scrollTo(newValue, anchor: .center)
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding(.horizontal, 18)
    }

    private func updateLyricBrowsingState(isBrowsing: Bool) {
        browseResetTask?.cancel()
        if isBrowsing {
            isUserBrowsingLyrics = true
            return
        }

        browseResetTask = Task {
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            await MainActor.run {
                isUserBrowsingLyrics = false
            }
        }
    }
}

private struct MacTimedLyricRow: View {
    @EnvironmentObject private var viewModel: MacPlayerViewModel
    @EnvironmentObject private var themeManager: MacThemeManager

    let line: LyricLine
    let isActive: Bool
    let onSeek: () -> Void

    var body: some View {
        Button(action: onSeek) {
            Text(line.displayText)
                .font(.system(size: isActive ? 24 : 20, weight: isActive ? .bold : .semibold))
                .foregroundStyle(isActive ? themeManager.currentTheme.playbackAccent : themeManager.currentTheme.nowPlayingDimText)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(MacCursorRegion(cursor: .pointingHand))
    }
}

private struct MacCursorRegion: NSViewRepresentable {
    let cursor: NSCursor

    func makeNSView(context: Context) -> NSView {
        let view = CursorView()
        view.cursor = cursor
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        (nsView as? CursorView)?.cursor = cursor
    }

    private final class CursorView: NSView {
        var cursor: NSCursor = .arrow

        override func resetCursorRects() {
            addCursorRect(bounds, cursor: cursor)
        }
    }
}

private struct MacNowPlayingBottomBar: View {
    @EnvironmentObject private var viewModel: MacPlayerViewModel
    @EnvironmentObject private var themeManager: MacThemeManager
    @Binding var isPresented: Bool
    @Binding var isShowingPlaylist: Bool
    @State private var isShowingThemePicker = false

    private var track: MacTrackItem? {
        viewModel.currentTrack ?? viewModel.selectedTrack
    }

    var body: some View {
        GeometryReader { proxy in
            let controlsWidth = min(max(proxy.size.width * 0.42, 360), 620)

            HStack(alignment: .bottom) {
                trackSummary
                    .frame(width: 260, alignment: .leading)

                Spacer()

                controls
                    .frame(width: controlsWidth)

                Spacer()

                actionCluster
                    .frame(width: 260, alignment: .trailing)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: 78)
        .foregroundStyle(themeManager.currentTheme.nowPlayingSecondaryText)
    }

    private var trackSummary: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.50, dampingFraction: 0.90)) {
                    isPresented = false
                }
            } label: {
                Image(systemName: "arrow.down.right.and.arrow.up.left")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .pointingHandCursor()

            VStack(alignment: .leading, spacing: 7) {
                Text(track.map { "\($0.title) - \($0.artist)" } ?? "未播放")
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)

                HStack(spacing: 18) {
                    favoriteButton(foreground: themeManager.currentTheme.nowPlayingDisabledIcon)
                    revealInFinderButton(foreground: themeManager.currentTheme.nowPlayingDisabledIcon)
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(themeManager.currentTheme.nowPlayingDisabledIcon)
            }
        }
    }

    private func favoriteButton(foreground: Color) -> some View {
        Button {
            viewModel.toggleFavorite(track)
        } label: {
            Image(systemName: viewModel.isFavorite(track) ? "heart.fill" : "heart")
                .foregroundStyle(viewModel.isFavorite(track) ? Color(red: 1.0, green: 0.42, blue: 0.28) : foreground)
        }
        .buttonStyle(.plain)
        .disabled(track == nil)
        .opacity(track == nil ? 0.34 : 1)
        .help(viewModel.isFavorite(track) ? "取消喜欢" : "加入喜欢")
        .pointingHandCursor(isEnabled: track != nil)
    }

    private func revealInFinderButton(foreground: Color) -> some View {
        Button {
            guard let track else { return }
            viewModel.revealInFinder(track)
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundStyle(foreground)
        }
        .buttonStyle(.plain)
        .disabled(track?.localURL == nil)
        .opacity(track?.localURL == nil ? 0.34 : 1)
        .help(track?.localURL == nil ? "暂无本地文件" : "在访达中显示")
        .pointingHandCursor(isEnabled: track?.localURL != nil)
    }

    private var controls: some View {
        VStack(spacing: 7) {
            HStack(spacing: 26) {
                let hasTrack = track != nil
                Button {
                    viewModel.cyclePlaybackMode()
                } label: {
                    Image(systemName: viewModel.playbackMode.systemImage)
                }
                .help(viewModel.playbackMode.title)
                .pointingHandCursor()

                Button {
                    viewModel.previous()
                } label: {
                    Image(systemName: "backward.fill")
                }
                .disabled(!hasTrack)
                .opacity(hasTrack ? 1 : 0.28)
                .pointingHandCursor(isEnabled: hasTrack)

                Button {
                    viewModel.togglePlayback()
                } label: {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(themeManager.currentTheme.playbackButtonForeground)
                        .frame(width: 34, height: 34)
                        .background(themeManager.currentTheme.playbackAccent, in: Circle())
                }
                .disabled(!hasTrack)
                .opacity(hasTrack ? 1 : 0.34)
                .pointingHandCursor(isEnabled: hasTrack)

                Button {
                    viewModel.next()
                } label: {
                    Image(systemName: "forward.fill")
                }
                .disabled(!hasTrack)
                .opacity(hasTrack ? 1 : 0.28)
                .pointingHandCursor(isEnabled: hasTrack)

                MacVolumeControl()
            }
            .buttonStyle(.plain)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(themeManager.currentTheme.nowPlayingSubtleIcon)

            HStack(spacing: 8) {
                Text(viewModel.formatTime(viewModel.currentTime))
                    .frame(width: 38, alignment: .trailing)
                Slider(
                    value: Binding(
                        get: { viewModel.currentTime },
                        set: { viewModel.seek(to: $0) }
                    ),
                    in: 0...max(viewModel.duration, 1)
                )
                .tint(themeManager.currentTheme.playbackAccent)
                Text(viewModel.formatTime(viewModel.duration))
                    .frame(width: 38, alignment: .leading)
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(themeManager.currentTheme.nowPlayingSecondaryText)
            .monospacedDigit()
        }
    }

    private var actionCluster: some View {
        HStack(spacing: 15) {
            Button {
                isShowingThemePicker.toggle()
            } label: {
                Image(systemName: "tshirt")
            }
            .buttonStyle(.plain)
            .help("换肤")
            .popover(isPresented: $isShowingThemePicker, arrowEdge: .top) {
                MacThemePickerPopover(isShowingThemePicker: $isShowingThemePicker)
                    .environmentObject(themeManager)
            }
            .pointingHandCursor()
            MacQualityBadge(label: track?.qualityBadge, size: .regular)
            MacDisabledIcon(systemName: "waveform", color: themeManager.currentTheme.nowPlayingDisabledIcon)
            MacDisabledIcon(systemName: "text.quote", color: themeManager.currentTheme.nowPlayingDisabledIcon)
            Button {
                withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
                    isShowingPlaylist.toggle()
                }
            } label: {
                Image(systemName: "list.bullet")
                    .foregroundStyle(isShowingPlaylist ? themeManager.currentTheme.playbackAccent : themeManager.currentTheme.nowPlayingSubtleIcon)
            }
            .buttonStyle(.plain)
            .help("播放列表")
            .pointingHandCursor()
        }
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(themeManager.currentTheme.nowPlayingSubtleIcon)
    }
}

private struct MacNowPlayingPlaylistPanel: View {
    @EnvironmentObject private var viewModel: MacPlayerViewModel

    private var tracks: [MacTrackItem] {
        viewModel.tracks
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("播放列表")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(QQMusicPalette.text)

            Text("共\(tracks.count)首歌曲")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(QQMusicPalette.text.opacity(0.88))

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                        MacNowPlayingPlaylistRow(track: track, index: index)
                    }
                }
                .padding(.bottom, 12)
            }
            .overlay {
                if tracks.isEmpty {
                    ContentUnavailableView("暂无歌曲", systemImage: "music.note.list")
                        .foregroundStyle(QQMusicPalette.text.opacity(0.86))
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(red: 0.09, green: 0.11, blue: 0.33).opacity(0.96))
                .shadow(color: Color.black.opacity(0.18), radius: 24, x: -6, y: 10)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .onTapGesture {}
    }
}

private struct MacNowPlayingPlaylistRow: View {
    @EnvironmentObject private var viewModel: MacPlayerViewModel

    let track: MacTrackItem
    let index: Int

    private var isSelected: Bool {
        viewModel.selectedTrackID == track.id || viewModel.currentTrack?.id == track.id
    }

    private var isNowPlaying: Bool {
        viewModel.currentTrack?.id == track.id && viewModel.isPlaying
    }

    var body: some View {
        HStack(spacing: 12) {
            MacTrackArtworkControl(
                artworkData: track.artworkData,
                isSelected: isSelected,
                isNowPlaying: isNowPlaying,
                size: 46
            ) {
                viewModel.play(track)
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(track.title)
                        .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                        .foregroundStyle(isSelected ? Color(red: 0.66, green: 0.84, blue: 1.0) : QQMusicPalette.text)
                        .lineLimit(1)

                    MacQualityBadge(label: track.qualityBadge, size: .small)
                }

                Text(track.artist)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(QQMusicPalette.text.opacity(0.74))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .frame(height: 62)
        .background(rowBackground, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .onTapGesture {
            viewModel.select(track)
        }
        .onTapGesture(count: 2) {
            viewModel.play(track)
        }
        .contextMenu {
            if track.localURL != nil {
                Button {
                    viewModel.revealInFinder(track)
                } label: {
                    Label("查看本地文件", systemImage: "folder")
                }
            }
        }
    }

    private var rowBackground: Color {
        if isSelected {
            return Color.white.opacity(0.13)
        }
        return index.isMultiple(of: 2) ? Color.white.opacity(0.04) : Color.clear
    }
}

private struct MacPlaybackBar: View {
    @EnvironmentObject private var viewModel: MacPlayerViewModel
    @EnvironmentObject private var themeManager: MacThemeManager
    @Environment(\.macLayoutMetrics) private var metrics
    @Binding var playbackBarHeight: CGFloat
    @Binding var isShowingNowPlayingPage: Bool
    let namespace: Namespace.ID
    @State private var isHoveringTopResizeEdge = false
    @State private var dragStartHeight: CGFloat?

    private var track: MacTrackItem? {
        viewModel.currentTrack ?? viewModel.selectedTrack
    }

    var body: some View {
        GeometryReader { proxy in
            content(width: proxy.size.width)
        }
        .frame(height: metrics.playbackBarHeight)
        .overlay(alignment: .top) {
            MacPlaybackBarResizeEdge(
                height: $playbackBarHeight,
                dragStartHeight: $dragStartHeight,
                isHovering: $isHoveringTopResizeEdge
            )
        }
    }

    private func content(width: CGFloat) -> some View {
        let compact = width < 860
        let trackWidth = clamp(width * 0.22, min: compact ? 160 : 210, max: 280)
        let controlsWidth = clamp(width * (compact ? 0.58 : 0.62), min: compact ? 360 : 520, max: 860)
        let actionWidth = clamp(width * 0.12, min: 96, max: 160)

        return ViewThatFits(in: .horizontal) {
            regularContent(trackWidth: trackWidth, controlsWidth: controlsWidth, actionWidth: actionWidth, showsExtras: !compact)
            compactContent(controlsWidth: min(width - 210, 420))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, compact ? 14 : 18)
        .macGlassPanel(cornerRadius: 10, opacity: 0.86)
    }

    private func regularContent(trackWidth: CGFloat, controlsWidth: CGFloat, actionWidth: CGFloat, showsExtras: Bool) -> some View {
        HStack(spacing: 14) {
            MacPlaybackArtworkButton(track: track, size: 82, isShowingNowPlayingPage: $isShowingNowPlayingPage, namespace: namespace)

            trackSummary
                .frame(width: trackWidth, alignment: .leading)

            Spacer()

            playbackControls(showsOuterButtons: showsExtras)
                .frame(width: controlsWidth)

            Spacer()

            actionCluster
                .frame(width: actionWidth, alignment: .trailing)
        }
    }

    private func compactContent(controlsWidth: CGFloat) -> some View {
        HStack(spacing: 12) {
            MacPlaybackArtworkButton(track: track, size: 72, isShowingNowPlayingPage: $isShowingNowPlayingPage, namespace: namespace)

            trackSummary
                .frame(maxWidth: .infinity, alignment: .leading)

            playbackControls(showsOuterButtons: false)
                .frame(width: max(260, controlsWidth))
        }
    }

    private var trackSummary: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(track?.title ?? "未播放")
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
            HStack(spacing: 14) {
                Text(track?.artist ?? "选择一首歌曲开始播放")
                    .lineLimit(1)
                if track != nil {
                    Button {
                        viewModel.toggleFavorite(track)
                    } label: {
                        Image(systemName: viewModel.isFavorite(track) ? "heart.fill" : "heart")
                            .foregroundStyle(viewModel.isFavorite(track) ? Color(red: 1.0, green: 0.42, blue: 0.28) : QQMusicPalette.muted.opacity(0.74))
                    }
                    .buttonStyle(.plain)
                    .disabled(track == nil)
                    .opacity(track == nil ? 0.34 : 1)
                    .help(viewModel.isFavorite(track) ? "取消喜欢" : "加入喜欢")
                    .pointingHandCursor(isEnabled: track != nil)
                    MacDisabledIcon(systemName: "ellipsis.circle")
                }
            }
            .font(.system(size: 12))
            .foregroundStyle(QQMusicPalette.muted.opacity(0.74))
        }
    }

    private func playbackControls(showsOuterButtons: Bool) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: showsOuterButtons ? 24 : 18) {
                let hasTrack = track != nil
                if showsOuterButtons {
                    Button {
                        viewModel.cyclePlaybackMode()
                    } label: {
                        Image(systemName: viewModel.playbackMode.systemImage)
                    }
                    .help(viewModel.playbackMode.title)
                    .pointingHandCursor()
                }
                Button {
                    viewModel.previous()
                } label: {
                    Image(systemName: "backward.fill")
                }
                .disabled(!hasTrack)
                .opacity(hasTrack ? 1 : 0.28)
                .pointingHandCursor(isEnabled: hasTrack)
                Button {
                    viewModel.togglePlayback()
                } label: {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(themeManager.currentTheme.playbackButtonForeground)
                        .frame(width: 42, height: 42)
                        .background(themeManager.currentTheme.playbackAccent, in: Circle())
                }
                .disabled(!hasTrack)
                .opacity(hasTrack ? 1 : 0.34)
                .pointingHandCursor(isEnabled: hasTrack)
                Button {
                    viewModel.next()
                } label: {
                    Image(systemName: "forward.fill")
                }
                .disabled(!hasTrack)
                .opacity(hasTrack ? 1 : 0.28)
                .pointingHandCursor(isEnabled: hasTrack)
                if showsOuterButtons {
                    MacVolumeControl()
                }
            }
            .buttonStyle(.plain)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(themeManager.currentTheme.playbackAccent.opacity(0.88))

            HStack(spacing: 8) {
                Text(viewModel.formatTime(viewModel.currentTime))
                    .frame(width: 42, alignment: .trailing)
                Slider(
                    value: Binding(
                        get: { viewModel.currentTime },
                        set: { viewModel.seek(to: $0) }
                    ),
                    in: 0...max(viewModel.duration, 1)
                )
                .tint(themeManager.currentTheme.playbackAccent)
                Text(viewModel.formatTime(viewModel.duration))
                    .frame(width: 42, alignment: .leading)
            }
            .font(.system(size: 11))
            .foregroundStyle(QQMusicPalette.muted)
            .monospacedDigit()
        }
    }

    private var actionCluster: some View {
        HStack(spacing: 14) {
            MacQualityBadge(label: track?.qualityBadge, size: .regular)
            MacDisabledIcon(systemName: "waveform")
            MacDisabledIcon(systemName: "text.quote")
            MacDisabledIcon(systemName: "list.bullet")
        }
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(QQMusicPalette.muted)
    }

    private func clamp(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
        Swift.min(Swift.max(value, minValue), maxValue)
    }
}

private struct MacPlaybackBarResizeEdge: View {
    @Binding var height: CGFloat
    @Binding var dragStartHeight: CGFloat?
    @Binding var isHovering: Bool
    @State private var isDragging = false

    private let minimumHeight: CGFloat = 80
    private let maximumHeight: CGFloat = 120

    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.001))
            .frame(height: 12)
            .contentShape(Rectangle())
            .onHover { hovering in
                isHovering = hovering
                if hovering {
                    NSCursor.resizeUpDown.push()
                } else {
                    NSCursor.pop()
                }
            }
            .onDisappear {
                if isHovering {
                    NSCursor.pop()
                    isHovering = false
                }
            }
            .gesture(
                DragGesture(minimumDistance: 2)
                    .onChanged { value in
                        let start = dragStartHeight ?? height
                        if dragStartHeight == nil {
                            dragStartHeight = start
                        }
                        isDragging = true
                        height = clamp(start - value.translation.height)
                    }
                    .onEnded { _ in
                        dragStartHeight = nil
                        isDragging = false
                    }
            )
            .accessibilityLabel("调整播放控制高度")
    }

    private func clamp(_ value: CGFloat) -> CGFloat {
        Swift.min(Swift.max(value, minimumHeight), maximumHeight)
    }
}

private struct MacVolumeControl: View {
    @EnvironmentObject private var viewModel: MacPlayerViewModel
    @State private var showsVolumePopover = false

    var body: some View {
        Button {
            showsVolumePopover.toggle()
        } label: {
            Image(systemName: volumeImage)
        }
        .buttonStyle(.plain)
        .help("音量")
        .pointingHandCursor()
        .popover(isPresented: $showsVolumePopover, arrowEdge: .top) {
            VStack(spacing: 12) {
                MacVerticalVolumeSlider(value: viewModel.volume) { value in
                    viewModel.setVolume(value)
                }

                Text("\(Int((viewModel.volume * 100).rounded()))%")
                    .font(.system(size: 13, weight: .bold))
                    .monospacedDigit()

                Image(systemName: volumeImage)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundStyle(QQMusicPalette.text)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(width: 78)
            .background(QQMusicPalette.background)
        }
    }

    private var volumeImage: String {
        switch viewModel.volume {
        case ...0.001:
            return "speaker.slash"
        case ..<0.45:
            return "speaker.wave.1"
        default:
            return "speaker.wave.2"
        }
    }
}

private struct MacVerticalVolumeSlider: View {
    let value: Double
    let onChange: (Double) -> Void

    var body: some View {
        GeometryReader { proxy in
            let height = proxy.size.height
            let clampedValue = min(max(value, 0), 1)
            let knobY = height * (1 - clampedValue)

            ZStack(alignment: .top) {
                Capsule()
                    .fill(QQMusicPalette.text.opacity(0.88))
                    .frame(width: 5)
                    .frame(maxHeight: .infinity)

                Circle()
                    .fill(QQMusicPalette.accent)
                    .frame(width: 12, height: 12)
                    .offset(y: knobY - 6)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        guard height > 0 else { return }
                        let nextValue = 1 - (gesture.location.y / height)
                        onChange(Double(min(max(nextValue, 0), 1)))
                    }
            )
        }
        .frame(width: 28, height: 118)
    }
}

private struct MacCollectionListView: View {
    @EnvironmentObject private var themeManager: MacThemeManager

    let title: String
    let values: [String]
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(title)
                .font(.system(size: 28, weight: .bold))
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(values, id: \.self) { value in
                        Label(value, systemImage: systemImage)
                            .font(.system(size: 13, weight: .medium))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 14)
                            .frame(height: 42)
                            .background(themeManager.currentTheme.panel.opacity(0.58), in: RoundedRectangle(cornerRadius: 7))
                    }
                }
            }
            .overlay {
                if values.isEmpty {
                    ContentUnavailableView("暂无\(title)", systemImage: systemImage)
                        .foregroundStyle(themeManager.currentTheme.text)
                }
            }
        }
    }
}

private struct MacSettingsSummaryView: View {
    @EnvironmentObject private var themeManager: MacThemeManager
    @State private var baseURLString = ""
    @State private var accessKey = ""
    @State private var secretKey = ""
    @State private var statusMessage = "配置会保存到用户目录，更新覆盖安装后仍会保留。"
    @State private var isStatusError = false
    @State private var isCheckingConnection = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
            Text("设置")
                .font(.system(size: 28, weight: .bold))

            VStack(alignment: .leading, spacing: 14) {
                Text("星语音库")
                    .font(.system(size: 16, weight: .bold))

                MacSettingsTextField(
                    title: "连接地址",
                    placeholder: MusicVaultConfig.defaultBaseURLString,
                    text: $baseURLString
                )

                MacSettingsTextField(
                    title: "Access Key",
                    placeholder: "xmv_ak_...",
                    text: $accessKey
                )

                MacSettingsSecureField(
                    title: "Secret Key",
                    placeholder: "xmv_sk_...",
                    text: $secretKey
                )

                HStack(spacing: 10) {
                    MacSettingsActionButton(title: "保存配置", systemName: "checkmark.circle.fill") {
                        saveConfiguration()
                    }

                    MacSettingsActionButton(
                        title: isCheckingConnection ? "正在检查" : "检查连接",
                        systemName: isCheckingConnection ? "hourglass" : "network"
                    ) {
                        checkConnection()
                    }
                    .disabled(isCheckingConnection)

                    Spacer()
                }

                Text(statusMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isStatusError ? Color.red.opacity(0.88) : themeManager.currentTheme.muted)
                    .textSelection(.enabled)

                MacSettingLine(title: "保存位置", value: MusicVaultConfig.userConfigurationPath)
            }
            .padding(18)
            .background(themeManager.currentTheme.panel.opacity(0.58), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 14) {
                MacSettingLine(title: "本地目录", value: "支持 mp3、m4a、flac、aac、wav、aiff，导入目录会在用户配置中保留")
                MacSettingLine(title: "皮肤", value: "支持春日晨光、仲夏星河、秋日唱片、冬夜雪境，一键循环切换")
                MacSettingLine(title: "平台", value: "原生 macOS SwiftUI Target，仅 Apple Silicon / arm64")
            }
            .padding(18)
            .background(themeManager.currentTheme.panel.opacity(0.58), in: RoundedRectangle(cornerRadius: 10))

            Spacer()
            }
        }
        .onAppear(perform: loadConfiguration)
    }

    private func loadConfiguration() {
        let config = MusicVaultConfig.default
        baseURLString = config.baseURL.absoluteString
        accessKey = config.credential?.accessKey ?? ""
        secretKey = config.credential?.secretKey ?? ""
    }

    private func saveConfiguration() {
        do {
            try MusicVaultConfig.saveUserConfiguration(
                baseURLString: baseURLString,
                accessKey: accessKey,
                secretKey: secretKey
            )
            MusicVaultApiClient.reloadSharedConfiguration()
            isStatusError = false
            statusMessage = "已保存到 \(MusicVaultConfig.userConfigurationPath)，后续请求会使用新配置。"
        } catch {
            isStatusError = true
            statusMessage = error.localizedDescription
        }
    }

    private func checkConnection() {
        guard !isCheckingConnection else { return }
        do {
            try MusicVaultConfig.saveUserConfiguration(
                baseURLString: baseURLString,
                accessKey: accessKey,
                secretKey: secretKey
            )
            MusicVaultApiClient.reloadSharedConfiguration()
        } catch {
            isStatusError = true
            statusMessage = error.localizedDescription
            return
        }

        isCheckingConnection = true
        isStatusError = false
        statusMessage = "正在连接星语音库..."

        Task {
            do {
                let info = try await MusicVaultApiClient.shared.serverInfo()
                await MainActor.run {
                    isStatusError = false
                    statusMessage = "连接成功：\(info.serviceName) \(info.serviceVersion)，apiVersion=\(info.apiVersion)。"
                    isCheckingConnection = false
                }
            } catch {
                await MainActor.run {
                    isStatusError = true
                    statusMessage = error.localizedDescription
                    isCheckingConnection = false
                }
            }
        }
    }
}

private struct MacSettingLine: View {
    @EnvironmentObject private var themeManager: MacThemeManager

    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 88, alignment: .leading)
            Text(value)
                .font(.system(size: 13))
                .foregroundStyle(themeManager.currentTheme.muted)
            Spacer()
        }
    }
}

private struct MacSettingsTextField: View {
    @EnvironmentObject private var themeManager: MacThemeManager

    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(themeManager.currentTheme.muted)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(themeManager.currentTheme.text)
                .padding(.horizontal, 12)
                .frame(height: 36)
                .background(themeManager.currentTheme.panelDark.opacity(0.55), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(themeManager.currentTheme.line.opacity(0.72), lineWidth: 1)
                )
        }
    }
}

private struct MacSettingsSecureField: View {
    @EnvironmentObject private var themeManager: MacThemeManager

    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(themeManager.currentTheme.muted)
            SecureField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(themeManager.currentTheme.text)
                .padding(.horizontal, 12)
                .frame(height: 36)
                .background(themeManager.currentTheme.panelDark.opacity(0.55), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(themeManager.currentTheme.line.opacity(0.72), lineWidth: 1)
                )
        }
    }
}

private struct MacSettingsActionButton: View {
    @EnvironmentObject private var themeManager: MacThemeManager

    let title: String
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemName)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(themeManager.currentTheme.playbackButtonForeground)
                .padding(.horizontal, 14)
                .frame(height: 34)
                .background(themeManager.currentTheme.playbackAccent, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct MacNightBackground: View {
    let theme: MacAppTheme

    var body: some View {
        ZStack {
            if let backgroundImage {
                Image(nsImage: backgroundImage)
                    .resizable()
                    .scaledToFill()
            }

            LinearGradient(
                colors: [
                    theme.backgroundTop,
                    theme.backgroundMiddle,
                    theme.backgroundBottom
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .opacity(backgroundImage == nil ? 1.0 : theme == .winterMoonlight ? 0.30 : 0.20)

            MacStarField()
                .opacity(theme == .winterMoonlight ? 0.9 : 0.35)

            VStack {
                Spacer()
                MacMountainLayer(color: theme.panelDark.opacity(0.78), height: 230, offsetY: 90)
                MacMountainLayer(color: theme.panel.opacity(0.72), height: 180, offsetY: 40)
            }

            LinearGradient(
                colors: [
                    Color.black.opacity(0.04),
                    theme.backgroundBottom.opacity(0.28)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var backgroundImage: NSImage? {
        guard let url = Bundle.main.url(
            forResource: "background-desktop",
            withExtension: "png",
            subdirectory: "Themes/\(theme.resourceFolder)/background"
        ) else {
            return nil
        }
        return NSImage(contentsOf: url)
    }
}

private struct MacStarField: View {
    private let points: [CGPoint] = [
        CGPoint(x: 0.06, y: 0.13), CGPoint(x: 0.22, y: 0.06), CGPoint(x: 0.31, y: 0.18),
        CGPoint(x: 0.45, y: 0.09), CGPoint(x: 0.58, y: 0.19), CGPoint(x: 0.74, y: 0.08),
        CGPoint(x: 0.90, y: 0.14), CGPoint(x: 0.12, y: 0.33), CGPoint(x: 0.28, y: 0.38),
        CGPoint(x: 0.41, y: 0.30), CGPoint(x: 0.62, y: 0.36), CGPoint(x: 0.77, y: 0.31),
        CGPoint(x: 0.94, y: 0.39), CGPoint(x: 0.18, y: 0.58), CGPoint(x: 0.36, y: 0.55),
        CGPoint(x: 0.53, y: 0.61), CGPoint(x: 0.70, y: 0.53), CGPoint(x: 0.86, y: 0.59)
    ]

    var body: some View {
        GeometryReader { proxy in
            ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                Circle()
                    .fill(Color.white.opacity(index.isMultiple(of: 3) ? 0.78 : 0.48))
                    .frame(width: index.isMultiple(of: 4) ? 5 : 3, height: index.isMultiple(of: 4) ? 5 : 3)
                    .shadow(color: .white.opacity(0.8), radius: 8)
                    .position(x: proxy.size.width * point.x, y: proxy.size.height * point.y)
            }
        }
    }
}

private struct MacMountainLayer: View {
    let color: Color
    let height: CGFloat
    let offsetY: CGFloat

    var body: some View {
        GeometryReader { proxy in
            Path { path in
                let width = proxy.size.width
                let baseY = proxy.size.height - offsetY
                path.move(to: CGPoint(x: 0, y: baseY))
                path.addLine(to: CGPoint(x: width * 0.08, y: baseY - height * 0.35))
                path.addLine(to: CGPoint(x: width * 0.16, y: baseY - height * 0.12))
                path.addLine(to: CGPoint(x: width * 0.27, y: baseY - height * 0.42))
                path.addLine(to: CGPoint(x: width * 0.38, y: baseY - height * 0.10))
                path.addLine(to: CGPoint(x: width * 0.48, y: baseY - height * 0.36))
                path.addLine(to: CGPoint(x: width * 0.59, y: baseY - height * 0.09))
                path.addLine(to: CGPoint(x: width * 0.72, y: baseY - height * 0.31))
                path.addLine(to: CGPoint(x: width * 0.84, y: baseY - height * 0.08))
                path.addLine(to: CGPoint(x: width, y: baseY - height * 0.24))
                path.addLine(to: CGPoint(x: width, y: proxy.size.height))
                path.addLine(to: CGPoint(x: 0, y: proxy.size.height))
                path.closeSubpath()
            }
            .fill(color)
        }
        .frame(height: height + offsetY)
    }
}

private func openLocalFolderPanel(importHandler: (URL) -> Void) {
    let panel = NSOpenPanel()
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = false
    panel.prompt = "导入"
    panel.message = "选择一个包含本地歌曲文件的目录"

    if panel.runModal() == .OK, let url = panel.url {
        importHandler(url)
    }
}
