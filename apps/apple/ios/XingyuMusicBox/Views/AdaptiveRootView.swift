import SwiftUI
import UIKit

struct AdaptiveRootView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let iPadLayoutThreshold: CGFloat = 700

    var body: some View {
        GeometryReader { proxy in
            if shouldUseIPadLayout(width: proxy.size.width) {
                IPadRootView()
            } else {
                ContentView()
            }
        }
    }

    private func shouldUseIPadLayout(width: CGFloat) -> Bool {
        UIDevice.current.userInterfaceIdiom == .pad
            && horizontalSizeClass != .compact
            && width >= iPadLayoutThreshold
    }
}

#Preview {
    AdaptiveRootView()
        .environmentObject(PlayerViewModel())
        .environmentObject(ThemeManager())
}

