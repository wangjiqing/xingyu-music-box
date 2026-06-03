import SwiftUI

enum AppTheme: String, CaseIterable, Codable, Identifiable {
    case classic
    case darkNight
    case warmTape
    case blueWalkman
    case redPulse
    case orangeGlow
    case yellowVinyl
    case greenTape
    case cyanWave
    case blueOcean
    case purpleDream

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .classic:
            return "经典默认"
        case .darkNight:
            return "深色夜听"
        case .warmTape:
            return "暖黄磁带"
        case .blueWalkman:
            return "蓝色随身听"
        case .redPulse:
            return "红色脉冲"
        case .orangeGlow:
            return "橙色落日"
        case .yellowVinyl:
            return "黄色唱片"
        case .greenTape:
            return "绿色磁带"
        case .cyanWave:
            return "青色声波"
        case .blueOcean:
            return "蓝色海面"
        case .purpleDream:
            return "紫色梦境"
        }
    }

    var description: String {
        switch self {
        case .classic:
            return "延续星语音乐盒当前的复古蓝黑风格。"
        case .darkNight:
            return "更低亮度的夜间配色，适合睡前听歌。"
        case .warmTape:
            return "暖黄与棕色调，像旧磁带盒里的回忆。"
        case .blueWalkman:
            return "清爽蓝色调，轻快、明亮、随身听感。"
        case .redPulse:
            return "红色强调更醒目，适合热烈一点的歌单。"
        case .orangeGlow:
            return "橙色暖光，像傍晚车窗里的旋律。"
        case .yellowVinyl:
            return "明亮黄调，带一点老唱片的轻快感。"
        case .greenTape:
            return "绿色低饱和，安静、松弛、耐听。"
        case .cyanWave:
            return "青色声波感，清透但不刺眼。"
        case .blueOcean:
            return "更深一点的蓝色，像夜里的海面。"
        case .purpleDream:
            return "紫色氛围，适合慢歌和夜晚。"
        }
    }

    var backgroundTop: Color {
        switch self {
        case .classic:
            return Color(red: 0.03, green: 0.11, blue: 0.16)
        case .darkNight:
            return Color(red: 0.015, green: 0.018, blue: 0.032)
        case .warmTape:
            return Color(red: 0.22, green: 0.13, blue: 0.07)
        case .blueWalkman:
            return Color(red: 0.02, green: 0.15, blue: 0.26)
        case .redPulse:
            return Color(red: 0.22, green: 0.035, blue: 0.045)
        case .orangeGlow:
            return Color(red: 0.23, green: 0.095, blue: 0.025)
        case .yellowVinyl:
            return Color(red: 0.20, green: 0.155, blue: 0.035)
        case .greenTape:
            return Color(red: 0.025, green: 0.155, blue: 0.085)
        case .cyanWave:
            return Color(red: 0.020, green: 0.145, blue: 0.155)
        case .blueOcean:
            return Color(red: 0.018, green: 0.080, blue: 0.210)
        case .purpleDream:
            return Color(red: 0.115, green: 0.045, blue: 0.205)
        }
    }

    var backgroundBottom: Color {
        switch self {
        case .classic:
            return Color(red: 0.01, green: 0.02, blue: 0.03)
        case .darkNight:
            return Color(red: 0.002, green: 0.004, blue: 0.010)
        case .warmTape:
            return Color(red: 0.06, green: 0.035, blue: 0.020)
        case .blueWalkman:
            return Color(red: 0.004, green: 0.035, blue: 0.080)
        case .redPulse:
            return Color(red: 0.050, green: 0.010, blue: 0.014)
        case .orangeGlow:
            return Color(red: 0.060, green: 0.025, blue: 0.006)
        case .yellowVinyl:
            return Color(red: 0.050, green: 0.038, blue: 0.010)
        case .greenTape:
            return Color(red: 0.006, green: 0.040, blue: 0.023)
        case .cyanWave:
            return Color(red: 0.004, green: 0.045, blue: 0.052)
        case .blueOcean:
            return Color(red: 0.004, green: 0.018, blue: 0.065)
        case .purpleDream:
            return Color(red: 0.027, green: 0.010, blue: 0.055)
        }
    }

    var panel: Color {
        switch self {
        case .classic:
            return Color(red: 0.05, green: 0.15, blue: 0.21).opacity(0.82)
        case .darkNight:
            return Color(red: 0.035, green: 0.038, blue: 0.060).opacity(0.88)
        case .warmTape:
            return Color(red: 0.26, green: 0.16, blue: 0.08).opacity(0.84)
        case .blueWalkman:
            return Color(red: 0.035, green: 0.18, blue: 0.31).opacity(0.84)
        case .redPulse:
            return Color(red: 0.26, green: 0.055, blue: 0.065).opacity(0.84)
        case .orangeGlow:
            return Color(red: 0.27, green: 0.12, blue: 0.035).opacity(0.84)
        case .yellowVinyl:
            return Color(red: 0.24, green: 0.18, blue: 0.050).opacity(0.84)
        case .greenTape:
            return Color(red: 0.035, green: 0.18, blue: 0.095).opacity(0.84)
        case .cyanWave:
            return Color(red: 0.030, green: 0.17, blue: 0.18).opacity(0.84)
        case .blueOcean:
            return Color(red: 0.030, green: 0.105, blue: 0.245).opacity(0.84)
        case .purpleDream:
            return Color(red: 0.135, green: 0.060, blue: 0.245).opacity(0.84)
        }
    }

    var panelDark: Color {
        switch self {
        case .classic:
            return Color(red: 0.02, green: 0.06, blue: 0.09).opacity(0.92)
        case .darkNight:
            return Color(red: 0.010, green: 0.012, blue: 0.020).opacity(0.94)
        case .warmTape:
            return Color(red: 0.11, green: 0.065, blue: 0.035).opacity(0.94)
        case .blueWalkman:
            return Color(red: 0.010, green: 0.065, blue: 0.13).opacity(0.94)
        case .redPulse:
            return Color(red: 0.095, green: 0.018, blue: 0.025).opacity(0.94)
        case .orangeGlow:
            return Color(red: 0.110, green: 0.045, blue: 0.012).opacity(0.94)
        case .yellowVinyl:
            return Color(red: 0.095, green: 0.070, blue: 0.018).opacity(0.94)
        case .greenTape:
            return Color(red: 0.010, green: 0.075, blue: 0.040).opacity(0.94)
        case .cyanWave:
            return Color(red: 0.008, green: 0.070, blue: 0.078).opacity(0.94)
        case .blueOcean:
            return Color(red: 0.008, green: 0.040, blue: 0.120).opacity(0.94)
        case .purpleDream:
            return Color(red: 0.060, green: 0.025, blue: 0.115).opacity(0.94)
        }
    }

    var text: Color {
        switch self {
        case .warmTape, .yellowVinyl, .orangeGlow:
            return Color(red: 1.00, green: 0.92, blue: 0.78)
        default:
            return Color(red: 0.91, green: 0.96, blue: 1.0)
        }
    }

    var muted: Color {
        switch self {
        case .classic:
            return Color(red: 0.56, green: 0.65, blue: 0.72)
        case .darkNight:
            return Color(red: 0.54, green: 0.56, blue: 0.66)
        case .warmTape:
            return Color(red: 0.78, green: 0.64, blue: 0.46)
        case .blueWalkman:
            return Color(red: 0.58, green: 0.72, blue: 0.86)
        case .redPulse:
            return Color(red: 0.80, green: 0.55, blue: 0.58)
        case .orangeGlow:
            return Color(red: 0.82, green: 0.62, blue: 0.45)
        case .yellowVinyl:
            return Color(red: 0.82, green: 0.72, blue: 0.48)
        case .greenTape:
            return Color(red: 0.55, green: 0.74, blue: 0.62)
        case .cyanWave:
            return Color(red: 0.55, green: 0.75, blue: 0.78)
        case .blueOcean:
            return Color(red: 0.57, green: 0.68, blue: 0.88)
        case .purpleDream:
            return Color(red: 0.72, green: 0.60, blue: 0.88)
        }
    }

    var accent: Color {
        switch self {
        case .classic:
            return Color(red: 0.10, green: 0.72, blue: 1.0)
        case .darkNight:
            return Color(red: 0.46, green: 0.66, blue: 1.0)
        case .warmTape:
            return Color(red: 1.0, green: 0.66, blue: 0.25)
        case .blueWalkman:
            return Color(red: 0.25, green: 0.78, blue: 1.0)
        case .redPulse:
            return Color(red: 1.0, green: 0.25, blue: 0.30)
        case .orangeGlow:
            return Color(red: 1.0, green: 0.52, blue: 0.18)
        case .yellowVinyl:
            return Color(red: 1.0, green: 0.82, blue: 0.24)
        case .greenTape:
            return Color(red: 0.34, green: 0.86, blue: 0.42)
        case .cyanWave:
            return Color(red: 0.24, green: 0.88, blue: 0.90)
        case .blueOcean:
            return Color(red: 0.32, green: 0.58, blue: 1.0)
        case .purpleDream:
            return Color(red: 0.72, green: 0.42, blue: 1.0)
        }
    }

    var line: Color {
        switch self {
        case .warmTape, .orangeGlow, .yellowVinyl:
            return accent.opacity(0.18)
        case .redPulse, .greenTape, .cyanWave, .blueOcean, .purpleDream:
            return accent.opacity(0.16)
        default:
            return Color.white.opacity(0.12)
        }
    }

    var colorScheme: ColorScheme? {
        .dark
    }

    static var current: AppTheme {
        guard let rawValue = UserDefaults.standard.string(forKey: "appTheme") else {
            return .purpleDream
        }
        return AppTheme(rawValue: rawValue) ?? .purpleDream
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
                    XYStyle.panel.opacity(0.94),
                    XYStyle.panelDark.opacity(0.98)
                ],
                startPoint: .top,
                endPoint: .bottom
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.34), radius: 18, y: 8)
    }
}

struct XingyuTabBarItem: View {
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
        .foregroundStyle(isSelected ? XYStyle.accent : Color.white.opacity(0.68))
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
            LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

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
