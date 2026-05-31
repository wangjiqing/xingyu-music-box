import Foundation
import MediaPlayer
import UIKit

final class NowPlayingInfoManager {
    static let shared = NowPlayingInfoManager()

    private init() {}

    func update(song: Song, duration: TimeInterval, elapsedTime: TimeInterval, isPlaying: Bool) {
        let playbackDuration = duration > 0 ? duration : parsedDuration(from: song.duration)
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: song.title,
            MPMediaItemPropertyArtist: song.artist,
            MPMediaItemPropertyAlbumTitle: song.album.isEmpty ? "星语音乐盒" : song.album,
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
            MPNowPlayingInfoPropertyIsLiveStream: false,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: max(0, elapsedTime),
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]

        if playbackDuration > 0 {
            info[MPMediaItemPropertyPlaybackDuration] = playbackDuration
        }
        info[MPMediaItemPropertyArtwork] = artwork(for: song, size: CGSize(width: 512, height: 512))

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        MPNowPlayingInfoCenter.default().playbackState = isPlaying ? .playing : .paused
    }

    func updatePlaybackState(isPlaying: Bool, elapsedTime: TimeInterval) {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = max(0, elapsedTime)
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        MPNowPlayingInfoCenter.default().playbackState = isPlaying ? .playing : .paused
    }

    func updateElapsedTime(_ elapsedTime: TimeInterval) {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = max(0, elapsedTime)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    func clear() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        MPNowPlayingInfoCenter.default().playbackState = .stopped
    }

    private func parsedDuration(from value: String) -> TimeInterval {
        let parts = value.split(separator: ":").compactMap { TimeInterval($0) }
        guard parts.count >= 2 else { return 0 }
        return parts.reduce(0) { $0 * 60 + $1 }
    }

    private func artwork(for song: Song, size: CGSize) -> MPMediaItemArtwork {
        if let image = SongArtworkProvider.shared.image(for: song, targetSize: size) {
            return MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }

        let image = UIGraphicsImageRenderer(size: size).image { context in
            let bounds = CGRect(origin: .zero, size: size)
            UIColor(red: 0.01, green: 0.025, blue: 0.04, alpha: 1).setFill()
            context.fill(bounds)

            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(red: 0.02, green: 0.18, blue: 0.26, alpha: 1).cgColor,
                    UIColor(red: 0.005, green: 0.018, blue: 0.03, alpha: 1).cgColor
                ] as CFArray,
                locations: [0, 1]
            )
            if let gradient {
                context.cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: size.width, y: size.height),
                    options: []
                )
            }

            let accentRect = CGRect(x: 42, y: 42, width: size.width - 84, height: size.height - 84)
            let path = UIBezierPath(roundedRect: accentRect, cornerRadius: 42)
            UIColor.white.withAlphaComponent(0.08).setStroke()
            path.lineWidth = 2
            path.stroke()

            let title = song.title.prefix(8)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 54, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let titleSize = String(title).size(withAttributes: attributes)
            String(title).draw(
                at: CGPoint(x: (size.width - titleSize.width) / 2, y: (size.height - titleSize.height) / 2),
                withAttributes: attributes
            )
        }

        return MPMediaItemArtwork(boundsSize: size) { _ in image }
    }
}

final class SongArtworkProvider {
    static let shared = SongArtworkProvider()

    private let cache = NSCache<NSString, UIImage>()

    private init() {}

    func image(for song: Song, targetSize: CGSize, allowMediaLibraryLookup: Bool = true) -> UIImage? {
        let normalizedSize = CGSize(
            width: max(1, targetSize.width.rounded()),
            height: max(1, targetSize.height.rounded())
        )
        let cacheKey = "\(song.sourceType.rawValue)-\(song.id)-\(Int(normalizedSize.width))x\(Int(normalizedSize.height))" as NSString
        if let cachedImage = cache.object(forKey: cacheKey) {
            return cachedImage
        }

        let image: UIImage?
        switch song.sourceType {
        case .bundled:
            image = bundledImage(for: song)
        case .mediaLibrary:
            image = allowMediaLibraryLookup ? mediaLibraryImage(for: song, targetSize: normalizedSize) : nil
        }

        if let image {
            cache.setObject(image, forKey: cacheKey)
        }
        return image
    }

    private func mediaLibraryImage(for song: Song, targetSize: CGSize) -> UIImage? {
        guard let persistentID = UInt64(song.id) else { return nil }
        let query = MPMediaQuery.songs()
        query.addFilterPredicate(
            MPMediaPropertyPredicate(
                value: NSNumber(value: persistentID),
                forProperty: MPMediaItemPropertyPersistentID
            )
        )
        return query.items?.first?.artwork?.image(at: targetSize)
    }

    private func bundledImage(for song: Song) -> UIImage? {
        for candidate in coverCandidates(for: song.cover) {
            if let image = UIImage(named: candidate) {
                return image
            }

            let nsCandidate = candidate as NSString
            let fileName = nsCandidate.deletingPathExtension
            let ext = nsCandidate.pathExtension
            if !fileName.isEmpty, !ext.isEmpty {
                let urls = [
                    Bundle.main.url(forResource: fileName, withExtension: ext),
                    Bundle.main.url(forResource: fileName, withExtension: ext, subdirectory: "covers"),
                    Bundle.main.url(forResource: fileName, withExtension: ext, subdirectory: "Resources/covers"),
                    Bundle.main.url(forResource: fileName, withExtension: ext, subdirectory: "assets/covers")
                ]

                for url in urls.compactMap({ $0 }) {
                    if let image = UIImage(contentsOfFile: url.path) {
                        return image
                    }
                }
            }
        }

        return nil
    }

    private func coverCandidates(for cover: String) -> [String] {
        let raw = cover.trimmingCharacters(in: .whitespacesAndNewlines)
        let lastPathComponent = (raw as NSString).lastPathComponent
        let baseName = (lastPathComponent as NSString).deletingPathExtension
        let withoutLeadingSlash = raw.hasPrefix("/") ? String(raw.drop(while: { $0 == "/" })) : raw

        return [raw, withoutLeadingSlash, lastPathComponent, baseName]
            .filter { !$0.isEmpty }
            .reduce(into: [String]()) { result, candidate in
                if !result.contains(candidate) {
                    result.append(candidate)
                }
            }
    }
}
