import Foundation

enum PlaybackPersistenceError: Error {
    case libraryNotReady
}

struct PlaybackTrackSnapshot: Codable, Equatable {
    let id: String
    let sourceURLString: String?
    let title: String
    let artist: String
    let album: String
}

struct PlaybackCheckpoint: Codable, Equatable {
    let currentTrack: PlaybackTrackSnapshot
    let currentTime: Double
    let queue: [PlaybackTrackSnapshot]
    let queueIndex: Int
    let playbackMode: String
    let updatedAt: Date

    var boundedCurrentTime: Double {
        max(0, currentTime.isFinite ? currentTime : 0)
    }

    func resolvedTime(duration: Double?) -> Double {
        let time = boundedCurrentTime
        guard let duration, duration.isFinite, duration > 0 else {
            return time
        }
        return min(time, max(0, duration - 0.25))
    }
}

#if !os(macOS)
struct PlaybackState: Codable {
    let songID: String
    let currentTime: Double
    let playbackMode: PlaybackMode
    let updatedAt: Date
}
#endif

final class PlaybackStateStore {
    private let key = "lastPlaybackCheckpoint"
    private let legacyKey = "lastPlaybackState"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    #if !os(macOS)
    func load() -> PlaybackState? {
        if let checkpoint = loadCheckpoint() {
            return PlaybackState(
                songID: checkpoint.currentTrack.id,
                currentTime: checkpoint.boundedCurrentTime,
                playbackMode: PlaybackMode(savedRawValue: checkpoint.playbackMode),
                updatedAt: checkpoint.updatedAt
            )
        }
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(PlaybackState.self, from: data)
    }

    func save(_ state: PlaybackState) {
        let snapshot = PlaybackTrackSnapshot(
            id: state.songID,
            sourceURLString: nil,
            title: "",
            artist: "",
            album: ""
        )
        save(PlaybackCheckpoint(
            currentTrack: snapshot,
            currentTime: state.currentTime,
            queue: [snapshot],
            queueIndex: 0,
            playbackMode: state.playbackMode.rawValue,
            updatedAt: state.updatedAt
        ))
    }
    #endif

    func loadCheckpoint() -> PlaybackCheckpoint? {
        if let data = defaults.data(forKey: key),
           let checkpoint = try? JSONDecoder().decode(PlaybackCheckpoint.self, from: data) {
            return checkpoint
        }

        #if !os(macOS)
        guard let data = defaults.data(forKey: legacyKey),
              let legacy = try? JSONDecoder().decode(PlaybackState.self, from: data) else {
            return nil
        }
        let snapshot = PlaybackTrackSnapshot(
            id: legacy.songID,
            sourceURLString: nil,
            title: "",
            artist: "",
            album: ""
        )
        let checkpoint = PlaybackCheckpoint(
            currentTrack: snapshot,
            currentTime: legacy.currentTime,
            queue: [snapshot],
            queueIndex: 0,
            playbackMode: legacy.playbackMode.rawValue,
            updatedAt: legacy.updatedAt
        )
        save(checkpoint)
        return checkpoint
        #else
        return nil
        #endif
    }

    func save(_ checkpoint: PlaybackCheckpoint) {
        guard let data = try? JSONEncoder().encode(checkpoint) else { return }
        defaults.set(data, forKey: key)
    }

    func clear() {
        defaults.removeObject(forKey: key)
        defaults.removeObject(forKey: legacyKey)
    }
}

final class PlaybackPersistence {
    private let store: PlaybackStateStore

    init(store: PlaybackStateStore = PlaybackStateStore()) {
        self.store = store
    }

    func loadCheckpoint() -> PlaybackCheckpoint? {
        store.loadCheckpoint()
    }

    func save(_ checkpoint: PlaybackCheckpoint) {
        store.save(checkpoint)
    }

    func clear() {
        store.clear()
    }

    static func restore<Track>(
        checkpoint: PlaybackCheckpoint?,
        library: [Track],
        id: (Track) -> String,
        sourceURLString: (Track) -> String?,
        duration: (Track) -> Double?,
        fallbackQueue: [Track]
    ) -> (track: Track, queue: [Track], queueIndex: Int, startTime: Double)? {
        guard let checkpoint else { return nil }
        guard !library.isEmpty else { return nil }

        func matches(_ track: Track, snapshot: PlaybackTrackSnapshot) -> Bool {
            if id(track) == snapshot.id { return true }
            guard let snapshotURL = snapshot.sourceURLString else { return false }
            return sourceURLString(track) == snapshotURL
        }

        guard let restoredTrack = library.first(where: { matches($0, snapshot: checkpoint.currentTrack) }) else {
            return nil
        }

        let restoredQueue = checkpoint.queue.compactMap { snapshot in
            library.first { matches($0, snapshot: snapshot) }
        }
        let queue = restoredQueue.isEmpty ? fallbackQueue : restoredQueue
        let queueIndex = queue.firstIndex(where: { id($0) == id(restoredTrack) }) ?? min(max(0, checkpoint.queueIndex), max(0, queue.count - 1))
        let startTime = checkpoint.resolvedTime(duration: duration(restoredTrack))
        return (restoredTrack, queue, queueIndex, startTime)
    }
}
