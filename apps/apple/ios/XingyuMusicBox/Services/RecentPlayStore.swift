import Foundation

struct RecentPlayRecord: Codable, Identifiable, Hashable {
    let songID: String
    let playedAt: Date

    var id: String { songID }
}

final class RecentPlayStore {
    private let key = "recentPlayRecords"
    private let limit = 50
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> [RecentPlayRecord] {
        guard let data = defaults.data(forKey: key),
              let records = try? JSONDecoder().decode([RecentPlayRecord].self, from: data) else {
            return []
        }

        var seenSongIDs: Set<String> = []
        let uniqueRecords = records
            .sorted { $0.playedAt > $1.playedAt }
            .filter { record in
                guard !seenSongIDs.contains(record.songID) else { return false }
                seenSongIDs.insert(record.songID)
                return true
            }

        return Array(uniqueRecords.prefix(limit))
    }

    func save(_ records: [RecentPlayRecord]) {
        let trimmedRecords = Array(records.prefix(limit))
        guard let data = try? JSONEncoder().encode(trimmedRecords) else { return }
        defaults.set(data, forKey: key)
    }

    func record(songID: String) -> [RecentPlayRecord] {
        var records = load().filter { $0.songID != songID }
        records.insert(RecentPlayRecord(songID: songID, playedAt: Date()), at: 0)
        records = Array(records.prefix(limit))
        save(records)
        return records
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}
