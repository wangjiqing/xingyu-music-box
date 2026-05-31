import SwiftUI
import UIKit

struct CoverView: View {
    let song: Song
    let size: CGFloat
    var allowsMusicVaultLookup = false

    @State private var musicVaultImage: UIImage?
    @State private var musicVaultImageSongID: String?

    var body: some View {
        Group {
            if musicVaultImageSongID == song.id, let musicVaultImage {
                Image(uiImage: musicVaultImage)
                    .resizable()
                    .scaledToFill()
            } else if let image = coverImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholderCover
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    size > 100 ? Color.white.opacity(0.12) : Color.white.opacity(0.18),
                    lineWidth: 1
                )
        }
        .shadow(color: .black.opacity(size > 100 ? 0.24 : 0.12), radius: size > 100 ? 14 : 2, y: size > 100 ? 8 : 1)
        .shadow(color: XYStyle.accent.opacity(size > 100 ? 0.08 : 0), radius: size > 100 ? 10 : 0)
        .accessibilityLabel("\(song.title) 封面")
        .task(id: "\(song.id)-\(allowsMusicVaultLookup)") {
            await loadMusicVaultArtworkIfNeeded()
        }
    }

    private var placeholderCover: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.90, green: 0.78, blue: 0.58),
                            Color(red: 0.36, green: 0.25, blue: 0.17),
                            Color(red: 0.03, green: 0.03, blue: 0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            LinearGradient(
                colors: [Color.white.opacity(0.24), .clear],
                startPoint: .topLeading,
                endPoint: .center
            )

            Image(systemName: "music.note")
                .font(.system(size: max(18, size * 0.22), weight: .semibold))
                .foregroundStyle(Color(red: 1.0, green: 0.94, blue: 0.78).opacity(0.86))
                .shadow(color: .black.opacity(0.45), radius: 5, y: 2)

            VStack(alignment: .trailing, spacing: 2) {
                Spacer()
                Text(size > 100 ? song.title : "星语")
                    .lineLimit(size > 100 ? 2 : 1)
                    .multilineTextAlignment(.trailing)
                Text(size > 100 ? song.artist : "音乐盒")
                    .lineLimit(1)
            }
            .font(.system(size: max(10, size * 0.12), weight: .bold))
            .foregroundStyle(Color(red: 1.0, green: 0.94, blue: 0.78))
            .shadow(color: .black.opacity(0.7), radius: 4, y: 2)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(size > 100 ? 18 : 5)
        }
    }

    private var cornerRadius: CGFloat {
        size > 100 ? 5 : 6
    }

    private var coverImage: UIImage? {
        if let image = SongArtworkProvider.shared.image(
            for: song,
            targetSize: CGSize(width: size * UIScreen.main.scale, height: size * UIScreen.main.scale),
            allowMediaLibraryLookup: size > 100
        ) {
            return image
        }

        return nil
    }

    private func loadMusicVaultArtworkIfNeeded() async {
        guard allowsMusicVaultLookup else {
            musicVaultImage = nil
            musicVaultImageSongID = nil
            return
        }

        let result = await MusicVaultArtworkService.shared.fetchArtwork(
            for: song,
            duration: song.duration.secondsFromClockText
        )

        await MainActor.run {
            guard allowsMusicVaultLookup else { return }
            if let result {
                musicVaultImage = result.image
                musicVaultImageSongID = song.id
            } else {
                musicVaultImage = nil
                musicVaultImageSongID = nil
            }
        }
    }
}

private extension String {
    var secondsFromClockText: TimeInterval? {
        let parts = split(separator: ":").compactMap { TimeInterval($0) }
        guard parts.count >= 2 else { return nil }
        return parts.reduce(0) { $0 * 60 + $1 }
    }
}
