import Foundation

struct PlaybackState: Codable {
    let songID: String
    let currentTime: Double
    let playbackMode: PlaybackMode
    let updatedAt: Date
}

final class PlaybackStateStore {
    private let key = "lastPlaybackState"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> PlaybackState? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(PlaybackState.self, from: data)
    }

    func save(_ state: PlaybackState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: key)
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}
