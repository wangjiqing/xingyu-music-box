import Foundation

enum SongLibraryError: LocalizedError {
    case resourceNotFound
    case decodeFailed

    var errorDescription: String? {
        switch self {
        case .resourceNotFound:
            return "没有找到示例曲库资源。"
        case .decodeFailed:
            return "示例曲库读取失败。"
        }
    }
}

final class SongLibrary {
    func loadSongs() throws -> [Song] {
        guard let url = Bundle.main.url(forResource: "songs", withExtension: "json") else {
            throw SongLibraryError.resourceNotFound
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([Song].self, from: data)
        } catch {
            throw SongLibraryError.decodeFailed
        }
    }
}
