import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum AppTheme: String, CaseIterable, Codable, Identifiable {
    case springDawn
    case midsummerStarlight
    case autumnVinyl
    case winterMoonlight

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .springDawn:
            return "春日晨光"
        case .midsummerStarlight:
            return "仲夏星河"
        case .autumnVinyl:
            return "秋日唱片"
        case .winterMoonlight:
            return "冬夜雪境"
        }
    }

    var description: String {
        switch self {
        case .springDawn:
            return "1-3 月默认，清亮绿色与晨光暖色。"
        case .midsummerStarlight:
            return "4-6 月默认，浅蓝与星河水色。"
        case .autumnVinyl:
            return "7-9 月默认，唱片感橙棕与金色。"
        case .winterMoonlight:
            return "10-12 月默认，深蓝雪境与月光色。"
        }
    }

    var resourceFolder: String {
        switch self {
        case .springDawn:
            return "spring-dawn"
        case .midsummerStarlight:
            return "midsummer-starlight"
        case .autumnVinyl:
            return "autumn-vinyl"
        case .winterMoonlight:
            return "winter-moonlight"
        }
    }

    var backgroundTop: Color {
        switch self {
        case .springDawn:
            return Color(red: 0.980, green: 0.988, blue: 0.969)
        case .midsummerStarlight:
            return Color(red: 0.965, green: 0.984, blue: 1.000)
        case .autumnVinyl:
            return Color(red: 1.000, green: 0.969, blue: 0.933)
        case .winterMoonlight:
            return Color(red: 0.039, green: 0.071, blue: 0.141)
        }
    }

    var backgroundBottom: Color {
        switch self {
        case .springDawn:
            return Color(red: 0.745, green: 0.906, blue: 0.882)
        case .midsummerStarlight:
            return Color(red: 0.659, green: 0.902, blue: 0.882)
        case .autumnVinyl:
            return Color(red: 0.910, green: 0.635, blue: 0.298)
        case .winterMoonlight:
            return Color(red: 0.067, green: 0.133, blue: 0.227)
        }
    }

    var panel: Color {
        switch self {
        case .springDawn:
            return Color.white.opacity(0.84)
        case .midsummerStarlight:
            return Color.white.opacity(0.80)
        case .autumnVinyl:
            return Color(red: 1.000, green: 0.945, blue: 0.882).opacity(0.86)
        case .winterMoonlight:
            return Color(red: 0.067, green: 0.133, blue: 0.227).opacity(0.88)
        }
    }

    var panelDark: Color {
        switch self {
        case .springDawn:
            return Color(red: 0.886, green: 0.922, blue: 0.863).opacity(0.88)
        case .midsummerStarlight:
            return Color(red: 0.867, green: 0.918, blue: 0.961).opacity(0.88)
        case .autumnVinyl:
            return Color(red: 0.902, green: 0.839, blue: 0.765).opacity(0.90)
        case .winterMoonlight:
            return Color(red: 0.125, green: 0.184, blue: 0.290).opacity(0.94)
        }
    }

    var text: Color {
        switch self {
        case .springDawn:
            return Color(red: 0.141, green: 0.227, blue: 0.196)
        case .midsummerStarlight:
            return Color(red: 0.149, green: 0.220, blue: 0.302)
        case .autumnVinyl:
            return Color(red: 0.169, green: 0.114, blue: 0.078)
        case .winterMoonlight:
            return Color(red: 0.910, green: 0.941, blue: 1.000)
        }
    }

    var muted: Color {
        switch self {
        case .springDawn:
            return Color(red: 0.424, green: 0.498, blue: 0.451)
        case .midsummerStarlight:
            return Color(red: 0.431, green: 0.506, blue: 0.596)
        case .autumnVinyl:
            return Color(red: 0.420, green: 0.341, blue: 0.275)
        case .winterMoonlight:
            return Color(red: 0.635, green: 0.698, blue: 0.788)
        }
    }

    var accent: Color {
        switch self {
        case .springDawn:
            return Color(red: 0.220, green: 0.550, blue: 0.420)
        case .midsummerStarlight:
            return Color(red: 0.180, green: 0.480, blue: 0.920)
        case .autumnVinyl:
            return Color(red: 0.850, green: 0.380, blue: 0.150)
        case .winterMoonlight:
            return Color(red: 0.969, green: 0.784, blue: 0.451)
        }
    }

    var line: Color {
        switch self {
        case .springDawn:
            return Color(red: 0.886, green: 0.922, blue: 0.863)
        case .midsummerStarlight:
            return Color(red: 0.867, green: 0.918, blue: 0.961)
        case .autumnVinyl:
            return Color(red: 0.902, green: 0.839, blue: 0.765)
        case .winterMoonlight:
            return Color(red: 0.122, green: 0.184, blue: 0.290)
        }
    }

    var colorScheme: ColorScheme? {
        self == .winterMoonlight ? .dark : .light
    }

    // MARK: Theme-aware component colors

    /// Color for unselected tab bar items — visible on both light and dark themes.
    var tabBarUnselected: Color {
        switch self {
        case .springDawn:
            return Color(red: 0.141, green: 0.227, blue: 0.196).opacity(0.52)
        case .midsummerStarlight:
            return Color(red: 0.149, green: 0.220, blue: 0.302).opacity(0.52)
        case .autumnVinyl:
            return Color(red: 0.169, green: 0.114, blue: 0.078).opacity(0.52)
        case .winterMoonlight:
            return Color.white.opacity(0.68)
        }
    }

    /// Dimmed text for non-current lyrics, secondary status labels — clear on any theme.
    var lyricsDimmed: Color {
        switch self {
        case .springDawn:
            return Color(red: 0.341, green: 0.408, blue: 0.361).opacity(0.50)
        case .midsummerStarlight:
            return Color(red: 0.349, green: 0.420, blue: 0.502).opacity(0.50)
        case .autumnVinyl:
            return Color(red: 0.369, green: 0.314, blue: 0.278).opacity(0.50)
        case .winterMoonlight:
            return Color.white.opacity(0.46)
        }
    }

    /// Subtle background for controls, mini buttons, search bars.
    var controlBackground: Color {
        switch self {
        case .springDawn:
            return Color(red: 0.341, green: 0.408, blue: 0.361).opacity(0.12)
        case .midsummerStarlight:
            return Color(red: 0.349, green: 0.420, blue: 0.502).opacity(0.12)
        case .autumnVinyl:
            return Color(red: 0.369, green: 0.314, blue: 0.278).opacity(0.12)
        case .winterMoonlight:
            return Color.white.opacity(0.10)
        }
    }

    /// Base color for playback control button backgrounds — contrasts page background.
    var controlButtonBase: Color {
        switch self {
        case .springDawn:
            return Color(red: 0.141, green: 0.227, blue: 0.196)
        case .midsummerStarlight:
            return Color(red: 0.149, green: 0.220, blue: 0.302)
        case .autumnVinyl:
            return Color(red: 0.169, green: 0.114, blue: 0.078)
        case .winterMoonlight:
            return Color.white
        }
    }

    // MARK: Phonograph resources

    var phonographBaseName: String { "record_player_light_base@2x" }
    var phonographArmName: String { "record_player_light_arm@2x" }
    var phonographShadowName: String { "record_player_light_shadow@2x" }
    var phonographChassisName: String { "record_player_light_chassis@2x" }
    var phonographHighlightName: String { "record_player_light_highlight@2x" }
    var phonographShadowOpacity: Double { 0.72 }

    static var current: AppTheme {
        guard let rawValue = UserDefaults.standard.string(forKey: "appTheme") else {
            return seasonalDefault()
        }
        return AppTheme(rawValue: rawValue) ?? seasonalDefault()
    }

    static func seasonalDefault(date: Date = Date(), calendar: Calendar = .current) -> AppTheme {
        let month = calendar.component(.month, from: date)
        switch month {
        case 1...3:
            return .springDawn
        case 4...6:
            return .midsummerStarlight
        case 7...9:
            return .autumnVinyl
        default:
            return .winterMoonlight
        }
    }
}

final class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "appTheme")
        }
    }

    init() {
        currentTheme = AppTheme.current
    }

    func select(_ theme: AppTheme) {
        currentTheme = theme
    }

    func selectNextTheme() {
        guard let currentIndex = AppTheme.allCases.firstIndex(of: currentTheme) else {
            currentTheme = AppTheme.seasonalDefault()
            return
        }

        let nextIndex = AppTheme.allCases.index(after: currentIndex)
        currentTheme = nextIndex == AppTheme.allCases.endIndex ? AppTheme.allCases[0] : AppTheme.allCases[nextIndex]
    }
}

enum AppTab: Hashable, CaseIterable, Identifiable {
    case nowPlaying
    case localSongs
    case favorites
    case settings

    var id: Self { self }

    var title: String {
        switch self {
        case .nowPlaying:
            return "正在播放"
        case .localSongs:
            return "本地歌曲"
        case .favorites:
            return "收藏"
        case .settings:
            return "设置"
        }
    }

    var systemImage: String {
        switch self {
        case .nowPlaying:
            return "music.note"
        case .localSongs:
            return "list.bullet"
        case .favorites:
            return "heart"
        case .settings:
            return "gearshape"
        }
    }
}

enum AppLayoutContext {
    case phone
    case ipad
}

enum XYStyle {
    static var backgroundTop: Color { AppTheme.current.backgroundTop }
    static var backgroundBottom: Color { AppTheme.current.backgroundBottom }
    static var panel: Color { AppTheme.current.panel }
    static var panelDark: Color { AppTheme.current.panelDark }
    static var line: Color { AppTheme.current.line }
    static var text: Color { AppTheme.current.text }
    static var muted: Color { AppTheme.current.muted }
    static var accent: Color { AppTheme.current.accent }
    static var accentSoft: Color { AppTheme.current.accent.opacity(0.18) }
    static var green: Color { Color(red: 0.54, green: 0.83, blue: 0.29) }
    static var danger: Color { Color(red: 1.0, green: 0.42, blue: 0.48) }
    static var tabBarUnselected: Color { AppTheme.current.tabBarUnselected }
    static var lyricsDimmed: Color { AppTheme.current.lyricsDimmed }
    static var controlBackground: Color { AppTheme.current.controlBackground }
    static var controlButtonBase: Color { AppTheme.current.controlButtonBase }
}

struct ContentView: View {
    @EnvironmentObject private var viewModel: PlayerViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: AppTab = .nowPlaying
    @State private var messageDismissTask: Task<Void, Never>?

    var body: some View {
        ZStack(alignment: .bottom) {
            ThemeBackground()

            selectedContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            XingyuTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, 14)
                .padding(.bottom, 6)
                .zIndex(10)
        }
        .animation(.easeOut(duration: 0.24), value: themeManager.currentTheme)
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
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

    @ViewBuilder
    private var selectedContent: some View {
        switch selectedTab {
        case .nowPlaying:
            NowPlayingView {
                selectedTab = .localSongs
            }
        case .localSongs:
            SongListView {
                selectedTab = .nowPlaying
            }
        case .favorites:
            FavoriteSongsView {
                selectedTab = .nowPlaying
            }
        case .settings:
            SettingsView()
        }
    }
}

struct XingyuTabBar: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    XingyuTabBarItem(tab: tab, isSelected: selectedTab == tab)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 64)
        .padding(.horizontal, 6)
        .background(
            LinearGradient(
                colors: [
                    XYStyle.panelDark,
                    XYStyle.panelDark.opacity(0.96)
                ],
                startPoint: .top,
                endPoint: .bottom
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(XYStyle.line, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.34), radius: 18, y: 8)
    }
}

struct XingyuTabBarItem: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let tab: AppTab
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: tab.systemImage)
                .font(.system(size: 18, weight: .semibold))
            Text(tab.title)
                .font(.system(size: 10, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .foregroundStyle(isSelected ? XYStyle.accent : XYStyle.tabBarUnselected)
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .background {
            if isSelected {
                Capsule()
                    .fill(XYStyle.accentSoft.opacity(1.0))
                    .overlay {
                        Capsule()
                            .stroke(XYStyle.accent.opacity(0.22), lineWidth: 1)
                    }
            }
        }
        .contentShape(Rectangle())
        .animation(.easeOut(duration: 0.18), value: isSelected)
    }
}

struct ToastMessageView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.circle")
            .font(.footnote.weight(.medium))
            .foregroundStyle(.white)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(XYStyle.panelDark, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(XYStyle.accent.opacity(0.45), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.28), radius: 12, y: 6)
            .allowsHitTesting(true)
    }
}

struct ThemeBackground: View {
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        ZStack {
            if let backgroundImage {
                Image(uiImage: backgroundImage)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            }

            LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(backgroundImage == nil ? 1.0 : themeManager.currentTheme == .winterMoonlight ? 0.34 : 0.22)

            RadialGradient(
                colors: [XYStyle.accent.opacity(0.24), .clear],
                center: .topLeading,
                startRadius: 20,
                endRadius: 360
            )

            RadialGradient(
                colors: [XYStyle.accent.opacity(0.18), .clear],
                center: .bottomTrailing,
                startRadius: 30,
                endRadius: 420
            )
        }
        .ignoresSafeArea()
    }

    private var backgroundImage: UIImage? {
        let folder = themeManager.currentTheme.resourceFolder
        let preferredName = UIDevice.current.userInterfaceIdiom == .pad ? "background-desktop" : "background-mobile"
        if let mobileURL = Bundle.main.url(
            forResource: preferredName,
            withExtension: "webp",
            subdirectory: "Themes/\(folder)/background"
        ), let image = UIImage(contentsOfFile: mobileURL.path) {
            return image
        }

        if let desktopURL = Bundle.main.url(
            forResource: "background-desktop",
            withExtension: "png",
            subdirectory: "Themes/\(folder)/background"
        ) {
            return UIImage(contentsOfFile: desktopURL.path)
        }

        return nil
    }

    private var colors: [Color] {
        [
            themeManager.currentTheme.backgroundTop,
            themeManager.currentTheme.panelDark,
            themeManager.currentTheme.backgroundBottom
        ]
    }
}

struct ThemeSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        ZStack {
            ThemeBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("主题皮肤")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(XYStyle.text)
                            Text("选择一个适合今天听歌心情的皮肤。")
                                .font(.footnote)
                                .foregroundStyle(XYStyle.muted)
                        }

                        Spacer()

                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(XYStyle.accent)
                                .frame(width: 38, height: 38)
                                .background(XYStyle.panel.opacity(0.78), in: Circle())
                                .overlay {
                                    Circle().stroke(XYStyle.line, lineWidth: 1)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 18)

                    LazyVStack(spacing: 12) {
                        ForEach(AppTheme.allCases) { theme in
                            Button {
                                themeManager.select(theme)
                            } label: {
                                ThemeOptionRow(
                                    theme: theme,
                                    isSelected: themeManager.currentTheme == theme
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

private struct ThemeOptionRow: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let theme: AppTheme
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 13) {
            HStack(spacing: 5) {
                theme.backgroundTop
                theme.panel
                theme.accent
                theme.text
            }
            .frame(width: 74, height: 42)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(theme.line, lineWidth: 1)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(theme.displayName)
                    .font(.headline)
                    .foregroundStyle(XYStyle.text)
                    .lineLimit(1)
                Text(theme.description)
                    .font(.caption)
                    .foregroundStyle(XYStyle.muted)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3.weight(.semibold))
                .foregroundStyle(isSelected ? XYStyle.accent : XYStyle.muted)
        }
        .padding(13)
        .background(isSelected ? XYStyle.accentSoft : XYStyle.panel.opacity(0.58), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isSelected ? XYStyle.accent.opacity(0.42) : XYStyle.line, lineWidth: 1)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PlayerViewModel())
}
