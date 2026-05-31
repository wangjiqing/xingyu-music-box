import SwiftUI

struct MiniPlayerView: View {
    @EnvironmentObject private var viewModel: PlayerViewModel
    var onTap: () -> Void = {}

    var body: some View {
        if let song = viewModel.currentSong {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(song.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(XYStyle.accent)
                        .lineLimit(1)
                    Text(song.artist)
                        .font(.caption)
                        .foregroundStyle(XYStyle.muted)
                        .lineLimit(1)
                }

                Spacer()

                HStack(spacing: 8) {
                    Button(action: viewModel.togglePlayback) {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(viewModel.isPlaying ? XYStyle.accent : XYStyle.text)
                            .frame(width: 36, height: 36)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Button(action: viewModel.next) {
                        Image(systemName: "forward.fill")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(XYStyle.text)
                            .frame(width: 36, height: 36)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.03, green: 0.10, blue: 0.14).opacity(0.96), Color.black.opacity(0.94)],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(XYStyle.line, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.28), radius: 14, y: 8)
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
        }
    }
}

#Preview {
    MiniPlayerView()
        .environmentObject(PlayerViewModel())
}
