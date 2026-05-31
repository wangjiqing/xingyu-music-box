import SwiftUI

struct PlayerControlsView: View {
    let isPlaying: Bool
    let isFavorite: Bool
    let playbackMode: PlaybackMode
    let onPrevious: () -> Void
    let onTogglePlayback: () -> Void
    let onNext: () -> Void
    let onTogglePlaybackMode: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button(action: onTogglePlaybackMode) {
                    Image(systemName: playbackMode.systemImage)
                        .controlIcon(size: 36, color: XYStyle.accent)
                }
                .accessibilityLabel("切换播放模式")
                .accessibilityValue(playbackMode.title)

                Button(action: onPrevious) {
                    Image(systemName: "backward.fill")
                        .controlIcon(size: 52, color: XYStyle.text)
                }
                .accessibilityLabel("上一首")

                Button(action: onTogglePlayback) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 29, weight: .bold))
                        .foregroundStyle(XYStyle.accent)
                        .frame(width: 74, height: 74)
                        .background(
                            RadialGradient(
                                colors: [Color.white.opacity(0.20), Color(red: 0.07, green: 0.10, blue: 0.12), Color.black.opacity(0.92)],
                                center: .topLeading,
                                startRadius: 4,
                                endRadius: 78
                            ),
                            in: Circle()
                        )
                        .overlay {
                            Circle().stroke(Color.white.opacity(0.24), lineWidth: 1)
                        }
                        .shadow(color: .black.opacity(0.52), radius: 16, y: 9)
                        .shadow(color: XYStyle.accent.opacity(0.24), radius: 13)
                }
                .accessibilityLabel(isPlaying ? "暂停" : "播放")

                Button(action: onNext) {
                    Image(systemName: "forward.fill")
                        .controlIcon(size: 52, color: XYStyle.text)
                }
                .accessibilityLabel("下一首")

                Button(action: onTogglePlaybackMode) {
                    Text(String(playbackMode.title.prefix(2)))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(XYStyle.accent)
                        .frame(width: 36, height: 36)
                        .background(
                            RadialGradient(
                                colors: [Color.white.opacity(0.14), Color.black.opacity(0.58)],
                                center: .topLeading,
                                startRadius: 2,
                                endRadius: 36
                            ),
                            in: Circle()
                        )
                        .overlay {
                            Circle().stroke(Color.white.opacity(0.20), lineWidth: 1)
                        }
                        .shadow(color: .black.opacity(0.38), radius: 10, y: 6)
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
                    colors: [Color.white.opacity(0.14), Color.black.opacity(0.58)],
                    center: .topLeading,
                    startRadius: 2,
                    endRadius: size
                ),
                in: Circle()
            )
            .overlay {
                Circle().stroke(Color.white.opacity(0.20), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.38), radius: 10, y: 6)
    }
}
