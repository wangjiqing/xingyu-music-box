import SwiftUI

struct PlayerControlsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let isPlaying: Bool
    let isFavorite: Bool
    let playbackMode: PlaybackMode
    let onFavorite: () -> Void
    let onPrevious: () -> Void
    let onTogglePlayback: () -> Void
    let onNext: () -> Void
    let onTogglePlaybackMode: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button(action: onFavorite) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(isFavorite ? Color(red: 1.0, green: 0.42, blue: 0.28) : XYStyle.text)
                        .frame(width: 36, height: 36)
                }
                .accessibilityLabel(isFavorite ? "取消喜欢" : "标记喜欢")

                Button(action: onPrevious) {
                    Image(systemName: "backward.fill")
                        .controlIcon(size: 48, color: XYStyle.text)
                }
                .accessibilityLabel("上一首")

                Button(action: onTogglePlayback) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(XYStyle.accent)
                        .frame(width: 66, height: 66)
                        .background(
                            RadialGradient(
                                colors: [
                                    XYStyle.controlButtonBase.opacity(0.34),
                                    XYStyle.controlButtonBase.opacity(0.62),
                                    XYStyle.controlButtonBase.opacity(0.86)
                                ],
                                center: .topLeading,
                                startRadius: 4,
                                endRadius: 72
                            ),
                            in: Circle()
                        )
                        .overlay {
                            Circle().stroke(XYStyle.controlButtonBase.opacity(0.22), lineWidth: 1)
                        }
                        .shadow(color: .black.opacity(0.22), radius: 14, y: 8)
                        .shadow(color: XYStyle.accent.opacity(0.24), radius: 12)
                }
                .accessibilityLabel(isPlaying ? "暂停" : "播放")

                Button(action: onNext) {
                    Image(systemName: "forward.fill")
                        .controlIcon(size: 48, color: XYStyle.text)
                }
                .accessibilityLabel("下一首")

                Button(action: onTogglePlaybackMode) {
                    Image(systemName: playbackMode.systemImage)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(XYStyle.text.opacity(0.64))
                        .frame(width: 36, height: 36)
                }
                .accessibilityLabel("切换播放模式")
                .accessibilityValue(playbackMode.title)
            }
        }
        .buttonStyle(.plain)
    }
}

private extension View {
    func controlIcon(size: CGFloat, color: Color) -> some View {
        font(.system(size: size >= 50 ? 23 : 19, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(
                RadialGradient(
                    colors: [
                        XYStyle.controlButtonBase.opacity(0.18),
                        XYStyle.controlButtonBase.opacity(0.44)
                    ],
                    center: .topLeading,
                    startRadius: 2,
                    endRadius: size
                ),
                in: Circle()
            )
            .overlay {
                Circle().stroke(XYStyle.controlButtonBase.opacity(0.18), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.18), radius: 10, y: 6)
    }
}
