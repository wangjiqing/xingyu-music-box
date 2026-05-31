import AVFoundation
import Foundation

enum PlayerError: LocalizedError {
    case audioFileMissing(songTitle: String)
    case noPlayableSource(songTitle: String)
    case failedToLoad(songTitle: String)

    var errorDescription: String? {
        switch self {
        case .audioFileMissing(let songTitle), .noPlayableSource(let songTitle):
            return "当前歌曲音频文件暂未导入：\(songTitle)"
        case .failedToLoad(let songTitle):
            return "当前歌曲暂时无法播放：\(songTitle)"
        }
    }
}

@MainActor
final class MusicPlayer: ObservableObject {
    @Published private(set) var isPlaying = false
    @Published private(set) var currentTime: Double = 0
    @Published private(set) var duration: Double = 0
    @Published private(set) var errorMessage: String?
    @Published private(set) var hasLoadedSong = false

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private var onPlaybackEnded: (@MainActor () -> Void)?

    deinit {
        if let timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
    }

    @discardableResult
    func load(song: Song, onPlaybackEnded: @escaping @MainActor () -> Void) -> Bool {
        cleanupObservers()
        resetForNewLoad()

        do {
            let url: URL
            if song.sourceType == .mediaLibrary, let assetURL = song.assetURL {
                url = assetURL
            } else {
                url = try resolvePlayableSource(for: song)
            }
            return load(url: url, displayTitle: song.title, onPlaybackEnded: onPlaybackEnded)
        } catch {
            resetForFailedLoad(errorMessage: error.localizedDescription)
            return false
        }
    }

    @discardableResult
    func load(url: URL, displayTitle _: String, onPlaybackEnded: @escaping @MainActor () -> Void) -> Bool {
        cleanupObservers()
        self.onPlaybackEnded = onPlaybackEnded
        resetForNewLoad()

        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        hasLoadedSong = true
        observeProgress()
        observePlaybackEnd(for: item)

        Task {
            let loadedDuration = try? await item.asset.load(.duration)
            if let loadedDuration {
                duration = loadedDuration.seconds.isFinite ? loadedDuration.seconds : 0
            }
        }

        return true
    }

    func play() {
        guard errorMessage == nil, hasLoadedSong else { return }
        do {
            try AudioSessionManager.shared.configureForPlayback()
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        player?.play()
        isPlaying = player != nil
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func togglePlayback() {
        isPlaying ? pause() : play()
    }

    func seek(to seconds: Double, completion: (@MainActor (Bool) -> Void)? = nil) {
        guard let player else { return }
        let targetTime = max(0, seconds)
        currentTime = targetTime
        let time = CMTime(seconds: targetTime, preferredTimescale: 600)
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { finished in
            Task { @MainActor in
                completion?(finished)
            }
        }
    }

    func resolvePlayableSource(for song: Song) throws -> URL {
        guard !song.playableSourceCandidates.isEmpty else {
            throw PlayerError.noPlayableSource(songTitle: song.title)
        }

        for source in song.playableSourceCandidates {
            for candidate in resourceCandidates(for: source.filename) {
                if let url = Bundle.main.url(forResource: candidate, withExtension: nil) {
                    return url
                }

                let nsCandidate = candidate as NSString
                let fileName = nsCandidate.deletingPathExtension
                let ext = nsCandidate.pathExtension.isEmpty ? nil : nsCandidate.pathExtension

                if let url = Bundle.main.url(forResource: fileName, withExtension: ext) {
                    return url
                }

                if let url = Bundle.main.url(forResource: fileName, withExtension: ext, subdirectory: "audio") {
                    return url
                }

                if let url = Bundle.main.url(forResource: fileName, withExtension: ext, subdirectory: "Resources/audio") {
                    return url
                }
            }
        }

        throw PlayerError.audioFileMissing(songTitle: song.title)
    }

    private func resourceCandidates(for source: String) -> [String] {
        let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
        let lastPathComponent = (trimmed as NSString).lastPathComponent
        let withoutLeadingSlash = trimmed.hasPrefix("/") ? String(trimmed.drop(while: { $0 == "/" })) : trimmed

        return [trimmed, withoutLeadingSlash, lastPathComponent]
            .filter { !$0.isEmpty }
            .reduce(into: [String]()) { result, candidate in
                if !result.contains(candidate) {
                    result.append(candidate)
                }
            }
    }

    private func observeProgress() {
        guard let player else { return }
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor in
                self?.currentTime = time.seconds.isFinite ? time.seconds : 0
                if let itemDuration = self?.player?.currentItem?.duration.seconds,
                   itemDuration.isFinite,
                   itemDuration > 0 {
                    self?.duration = itemDuration
                }
            }
        }
    }

    private func observePlaybackEnd(for item: AVPlayerItem) {
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isPlaying = false
                self?.onPlaybackEnded?()
            }
        }
    }

    private func cleanupObservers() {
        if let timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
    }

    private func resetForNewLoad() {
        player = nil
        errorMessage = nil
        currentTime = 0
        duration = 0
        isPlaying = false
        hasLoadedSong = false
    }

    private func resetForFailedLoad(errorMessage: String) {
        player = nil
        self.errorMessage = errorMessage
        currentTime = 0
        duration = 0
        isPlaying = false
        hasLoadedSong = false
    }
}
