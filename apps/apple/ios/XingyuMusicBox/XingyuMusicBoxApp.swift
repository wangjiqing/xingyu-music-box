import SwiftUI

@main
struct XingyuMusicBoxApp: App {
    @StateObject private var viewModel = PlayerViewModel()
    @StateObject private var themeManager = ThemeManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            AdaptiveRootView()
                .environmentObject(viewModel)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.currentTheme.colorScheme)
                .onChange(of: scenePhase) { _, phase in
                    if phase != .active {
                        viewModel.persistPlaybackState()
                    }
                }
        }
    }
}
