import Foundation

struct LyricLine: Identifiable, Hashable {
    let id: String
    let time: TimeInterval
    let text: String
    let index: Int

    var displayText: String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "..." : trimmed
    }
}

enum LRCParser {
    private static let timestampPattern = #"\[(\d{1,2}):(\d{2})(?:[.:](\d{1,3}))?\]"#

    static func parse(_ text: String) -> [LyricLine] {
        let rawLines = text.components(separatedBy: .newlines)
        var parsed: [(time: TimeInterval, text: String)] = []

        for rawLine in rawLines {
            let timestamps = timestamps(in: rawLine)
            guard !timestamps.isEmpty else {
                continue
            }

            let lyricText = removeTimestamps(from: rawLine)
            for time in timestamps {
                parsed.append((time, lyricText))
            }
        }

        return parsed
            .sorted { lhs, rhs in
                if lhs.time == rhs.time {
                    return lhs.text < rhs.text
                }
                return lhs.time < rhs.time
            }
            .enumerated()
            .map { index, item in
                LyricLine(
                    id: "\(index)-\(item.time)",
                    time: item.time,
                    text: item.text,
                    index: index
                )
            }
    }

    private static func timestamps(in line: String) -> [TimeInterval] {
        guard let regex = try? NSRegularExpression(pattern: timestampPattern) else {
            return []
        }

        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        return regex.matches(in: line, range: range).compactMap { match in
            guard let minutesText = line.string(for: match.range(at: 1)),
                  let secondsText = line.string(for: match.range(at: 2)),
                  let minutes = TimeInterval(minutesText),
                  let seconds = TimeInterval(secondsText) else {
                return nil
            }

            let fractionText = line.string(for: match.range(at: 3)) ?? ""
            let fraction = fractionalSeconds(from: fractionText)
            return minutes * 60 + seconds + fraction
        }
    }

    private static func removeTimestamps(from line: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: timestampPattern) else {
            return line
        }

        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        let cleaned = regex.stringByReplacingMatches(in: line, range: range, withTemplate: "")
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func fractionalSeconds(from text: String) -> TimeInterval {
        guard !text.isEmpty, let value = TimeInterval(text) else {
            return 0
        }

        return value / pow(10, TimeInterval(text.count))
    }
}

private extension String {
    func string(for range: NSRange) -> String? {
        guard range.location != NSNotFound,
              let swiftRange = Range(range, in: self) else {
            return nil
        }
        return String(self[swiftRange])
    }
}
