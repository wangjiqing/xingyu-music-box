import SwiftUI

@main
struct XingyuMusicBoxApp: App {
    @StateObject private var viewModel = PlayerViewModel()
    @StateObject private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            AdaptiveRootView()
                .environmentObject(viewModel)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.currentTheme.colorScheme)
        }
    }
}
