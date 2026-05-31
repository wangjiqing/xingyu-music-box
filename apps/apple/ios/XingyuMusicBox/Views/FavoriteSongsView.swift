import SwiftUI

struct FavoriteSongsView: View {
    @EnvironmentObject private var viewModel: PlayerViewModel
    var onMiniPlayerTap: () -> Void = {}

    private var favoriteSongs: [Song] {
        viewModel.songs.filter { viewModel.favorites.contains($0.id) }
    }

    var body: some View {
        ZStack {
            ThemeBackground()

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("收藏")
                            .font(.title.weight(.bold))
                            .foregroundStyle(XYStyle.text)
                        Text("把旧时光放进口袋 · \(favoriteSongs.count) 首")
                            .font(.footnote)
                            .foregroundStyle(XYStyle.muted)
                    }
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)

                if favoriteSongs.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "heart")
                            .font(.system(size: 38))
                            .foregroundStyle(XYStyle.danger)
                        Text("还没有收藏")
                            .font(.headline)
                            .foregroundStyle(XYStyle.text)
                        Text("在播放页点亮爱心，把旧时光放进口袋。")
                            .font(.footnote)
                            .foregroundStyle(XYStyle.muted)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(28)
                    .glassCard()
                    .padding()
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(favoriteSongs) { song in
                                Button {
                                    viewModel.play(song: song, queue: favoriteSongs)
                                } label: {
                                    SongRowView(
                                        song: song,
                                        isCurrent: song.id == viewModel.currentSong?.id,
                                        playCount: viewModel.mediaLibraryPlayCounts[song.id] ?? 0,
                                        isFavorite: true
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, 14)
                        .padding(.bottom, 178)
                    }
                }

                MiniPlayerView(onTap: onMiniPlayerTap)
                    .padding(.horizontal)
                    .padding(.bottom, 82)
            }
        }
    }
}

#Preview {
    FavoriteSongsView()
        .environmentObject(PlayerViewModel())
}
