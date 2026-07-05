import Foundation

enum LyricDocumentType: String, Codable, Equatable {
    case none
    case lrc
    case swlrc
}

struct TimedLyricToken: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let startTime: TimeInterval
    let endTime: TimeInterval
    let text: String
    let index: Int
}

struct TimedLyricLine: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let startTime: TimeInterval
    let endTime: TimeInterval?
    let text: String
    let tokens: [TimedLyricToken]
    let index: Int

    var displayText: String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "..." : trimmed
    }
}

struct ParsedLyricsDocument: Codable, Equatable {
    let type: LyricDocumentType
    let rawText: String
    let lines: [TimedLyricLine]
    let sourceDescription: String?
    let hash: String?
    let etag: String?
    let updatedAt: String?

    var currentLineIndex: Int? {
        lines.first?.index
    }

    static let none = ParsedLyricsDocument(
        type: .none,
        rawText: "",
        lines: [],
        sourceDescription: nil,
        hash: nil,
        etag: nil,
        updatedAt: nil
    )
}

enum SWLRCParserError: LocalizedError, Equatable {
    case missingHeader
    case missingRequiredMetadata
    case invalidTokenization
    case invalidSyntax
    case invalidTiming
    case empty

    var errorDescription: String? {
        switch self {
        case .missingHeader:
            return "SWLRC 缺少 [swlrc:1] 头部。"
        case .missingRequiredMetadata:
            return "SWLRC 缺少 offset 或 tokenization 元信息。"
        case .invalidTokenization:
            return "SWLRC tokenization 不受支持。"
        case .invalidSyntax:
            return "SWLRC 语法无效。"
        case .invalidTiming:
            return "SWLRC 时间范围无效。"
        case .empty:
            return "SWLRC 没有可显示歌词。"
        }
    }
}

enum SWLRCParser {
    private static let metadataPattern = #"^\[([^:\],]+):([^\]]*)\]$"#
    private static let linePattern = #"^\[(\d{1,3}:\d{2}[.:]\d{3}),(\d{1,3}:\d{2}[.:]\d{3})\]\s*$"#
    private static let tokenPattern = #"^<(\d{1,3}:\d{2}[.:]\d{3}),(\d{1,3}:\d{2}[.:]\d{3})>(.*)$"#

    static func parse(_ text: String) throws -> ParsedLyricsDocument {
        let rawLines = text.components(separatedBy: .newlines)
        guard rawLines.first?.replacingOccurrences(of: "\u{feff}", with: "") == "[swlrc:1]" else {
            throw SWLRCParserError.missingHeader
        }

        var metadata: [String: String] = ["swlrc": "1"]
        var lines: [TimedLyricLine] = []
        var currentStart: TimeInterval?
        var currentEnd: TimeInterval?
        var currentTokens: [TimedLyricToken] = []
        var tokenIndex = 0
        var sawLyricLine = false

        func pushCurrentLine() throws {
            guard let start = currentStart, let end = currentEnd else { return }
            guard !currentTokens.isEmpty else {
                throw SWLRCParserError.empty
            }
            let text = currentTokens.map(\.text).joined()
            let line = TimedLyricLine(
                id: "\(lines.count)-\(start)",
                startTime: start,
                endTime: end,
                text: text,
                tokens: currentTokens,
                index: lines.count
            )
            lines.append(line)
            currentTokens = []
        }

        for rawLine in rawLines.dropFirst() {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }

            if let match = line.firstMatch(pattern: linePattern),
               let start = parseTime(match[1]),
               let end = parseTime(match[2]) {
                try pushCurrentLine()
                guard start < end else { throw SWLRCParserError.invalidTiming }
                currentStart = start
                currentEnd = end
                sawLyricLine = true
                continue
            }

            if let match = line.firstMatch(pattern: tokenPattern),
               let start = parseTime(match[1]),
               let end = parseTime(match[2]) {
                guard sawLyricLine, let lineStart = currentStart, let lineEnd = currentEnd else {
                    throw SWLRCParserError.invalidSyntax
                }
                guard lineStart <= start, start < end, end <= lineEnd else {
                    throw SWLRCParserError.invalidTiming
                }
                let token = TimedLyricToken(
                    id: "\(lines.count)-\(tokenIndex)-\(start)",
                    startTime: start,
                    endTime: end,
                    text: match[3],
                    index: tokenIndex
                )
                currentTokens.append(token)
                tokenIndex += 1
                continue
            }

            if !sawLyricLine, let match = line.firstMatch(pattern: metadataPattern) {
                metadata[match[1].lowercased()] = match[2]
                continue
            }

            throw SWLRCParserError.invalidSyntax
        }

        try pushCurrentLine()

        guard metadata["offset"] != nil, metadata["tokenization"] != nil else {
            throw SWLRCParserError.missingRequiredMetadata
        }
        guard ["char", "word", "mixed"].contains(metadata["tokenization"]?.lowercased() ?? "") else {
            throw SWLRCParserError.invalidTokenization
        }
        guard !lines.isEmpty else {
            throw SWLRCParserError.empty
        }

        let offset = TimeInterval(Int(metadata["offset"] ?? "0") ?? 0) / 1000
        if offset == 0 {
            return ParsedLyricsDocument(type: .swlrc, rawText: text, lines: lines, sourceDescription: nil, hash: nil, etag: nil, updatedAt: nil)
        }
        let adjusted = lines.map { line in
            let tokens = line.tokens.map {
                TimedLyricToken(id: $0.id, startTime: $0.startTime + offset, endTime: $0.endTime + offset, text: $0.text, index: $0.index)
            }
            return TimedLyricLine(
                id: line.id,
                startTime: line.startTime + offset,
                endTime: line.endTime.map { $0 + offset },
                text: line.text,
                tokens: tokens,
                index: line.index
            )
        }
        return ParsedLyricsDocument(type: .swlrc, rawText: text, lines: adjusted, sourceDescription: nil, hash: nil, etag: nil, updatedAt: nil)
    }

    private static func parseTime(_ value: String) -> TimeInterval? {
        let parts = value.replacingOccurrences(of: ".", with: ":").split(separator: ":")
        guard parts.count == 3,
              let minutes = TimeInterval(parts[0]),
              let seconds = TimeInterval(parts[1]),
              let milliseconds = TimeInterval(parts[2]),
              seconds >= 0, seconds < 60 else {
            return nil
        }
        return minutes * 60 + seconds + milliseconds / 1000
    }
}

extension ParsedLyricsDocument {
    static func lrc(rawText: String, sourceDescription: String?, hash: String?, etag: String?, updatedAt: String?) -> ParsedLyricsDocument {
        let lrcLines = LRCParser.parse(rawText)
        let lines = lrcLines.map {
            TimedLyricLine(
                id: $0.id,
                startTime: $0.time,
                endTime: nil,
                text: $0.text,
                tokens: [],
                index: $0.index
            )
        }
        return ParsedLyricsDocument(type: .lrc, rawText: rawText, lines: lines, sourceDescription: sourceDescription, hash: hash, etag: etag, updatedAt: updatedAt)
    }

    static func swlrc(rawText: String, sourceDescription: String?, hash: String?, etag: String?, updatedAt: String?) throws -> ParsedLyricsDocument {
        let parsed = try SWLRCParser.parse(rawText)
        return ParsedLyricsDocument(type: .swlrc, rawText: rawText, lines: parsed.lines, sourceDescription: sourceDescription, hash: hash, etag: etag, updatedAt: updatedAt)
    }
}

private extension String {
    func firstMatch(pattern: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(startIndex..<endIndex, in: self)
        guard let match = regex.firstMatch(in: self, range: range) else { return nil }
        return (0..<match.numberOfRanges).map { index in
            guard let swiftRange = Range(match.range(at: index), in: self) else { return "" }
            return String(self[swiftRange])
        }
    }
}
