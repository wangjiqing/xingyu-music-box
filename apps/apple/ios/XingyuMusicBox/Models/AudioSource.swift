import Foundation

enum AudioFormat: String, Codable, CaseIterable, Hashable {
    case flac
    case m4a
    case mp3

    var priority: Int {
        switch self {
        case .flac:
            return 0
        case .m4a:
            return 1
        case .mp3:
            return 2
        }
    }

    init?(mimeType: String) {
        switch mimeType.lowercased() {
        case "audio/flac", "audio/x-flac":
            self = .flac
        case "audio/mp4", "audio/m4a", "audio/x-m4a", "audio/aac":
            self = .m4a
        case "audio/mpeg", "audio/mp3":
            self = .mp3
        default:
            return nil
        }
    }

    init?(filename: String) {
        let ext = (filename as NSString).pathExtension.lowercased()
        self.init(rawValue: ext)
    }

    var mimeType: String {
        switch self {
        case .flac:
            return "audio/flac"
        case .m4a:
            return "audio/mp4"
        case .mp3:
            return "audio/mpeg"
        }
    }
}

struct AudioSource: Identifiable, Codable, Hashable {
    var id: String { "\(format.rawValue)-\(filename)" }

    let format: AudioFormat
    let filename: String

    var type: String { format.mimeType }
    var src: String { filename }

    init(format: AudioFormat, filename: String) {
        self.format = format
        self.filename = filename
    }

    enum CodingKeys: String, CodingKey {
        case format
        case filename
        case type
        case src
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedFilename = try container.decodeIfPresent(String.self, forKey: .filename)
            ?? container.decode(String.self, forKey: .src)

        if let format = try container.decodeIfPresent(AudioFormat.self, forKey: .format) {
            self.format = format
        } else if let type = try container.decodeIfPresent(String.self, forKey: .type),
                  let format = AudioFormat(mimeType: type) {
            self.format = format
        } else if let format = AudioFormat(filename: decodedFilename) {
            self.format = format
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .filename,
                in: container,
                debugDescription: "Unsupported audio format for \(decodedFilename)"
            )
        }

        filename = decodedFilename
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(format, forKey: .format)
        try container.encode(filename, forKey: .filename)
    }
}
