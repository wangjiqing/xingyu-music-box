import SwiftUI

struct GlassCardModifier: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    colors: [
                        XYStyle.panel,
                        XYStyle.panelDark,
                        XYStyle.panelDark
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(XYStyle.line, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.28), radius: 18, y: 12)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 18) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
}
