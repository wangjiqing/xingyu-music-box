import Foundation

struct ShufflePlaybackQueue {
    private(set) var queue: [String] = []
    private(set) var cursor: Int = 0
    private(set) var sourceSignature = ""
    private(set) var seed: UInt64?

    var currentID: String? {
        guard queue.indices.contains(cursor) else { return nil }
        return queue[cursor]
    }

    var isEmpty: Bool {
        queue.isEmpty
    }

    mutating func reset() {
        queue = []
        cursor = 0
        sourceSignature = ""
        seed = nil
    }

    mutating func enter(sourceIDs: [String], currentID: String?) {
        let ids = uniqueIDs(sourceIDs)
        guard !ids.isEmpty else {
            reset()
            return
        }

        let resolvedCurrentID = currentID.flatMap { ids.contains($0) ? $0 : nil } ?? ids[0]
        seed = UInt64.random(in: UInt64.min...UInt64.max)
        queue = makeRound(sourceIDs: ids, currentID: resolvedCurrentID, avoidingImmediateRepeatAfter: nil)
        cursor = 0
        sourceSignature = signature(for: ids)
    }

    mutating func reconcile(sourceIDs: [String], currentID: String?) {
        let ids = uniqueIDs(sourceIDs)
        guard !ids.isEmpty else {
            reset()
            return
        }

        let signature = signature(for: ids)
        guard signature != sourceSignature || !queue.indices.contains(cursor) else { return }

        let validIDs = Set(ids)
        var reconciledQueue = queue.filter { validIDs.contains($0) }
        let resolvedCurrentID = currentID.flatMap { validIDs.contains($0) ? $0 : nil }

        if let resolvedCurrentID {
            if let currentIndex = reconciledQueue.firstIndex(of: resolvedCurrentID) {
                queue = reconciledQueue
                cursor = currentIndex
            } else {
                reconciledQueue.insert(resolvedCurrentID, at: 0)
                queue = reconciledQueue
                cursor = 0
            }
        } else if reconciledQueue.isEmpty {
            queue = makeRound(sourceIDs: ids, currentID: ids[0], avoidingImmediateRepeatAfter: nil)
            cursor = 0
        } else {
            queue = reconciledQueue
            cursor = min(cursor, max(0, reconciledQueue.count - 1))
        }

        sourceSignature = signature
    }

    mutating func next(sourceIDs: [String], currentID: String?) -> String? {
        let ids = uniqueIDs(sourceIDs)
        guard !ids.isEmpty else {
            reset()
            return nil
        }

        ensureReady(sourceIDs: ids, currentID: currentID)

        if cursor + 1 < queue.count {
            cursor += 1
            return queue[cursor]
        }

        let lastID = currentID ?? currentIDInQueue() ?? queue.last
        let firstID = ids.count == 1 ? ids[0] : nil
        queue = makeRound(sourceIDs: ids, currentID: firstID, avoidingImmediateRepeatAfter: lastID)
        cursor = 0
        sourceSignature = signature(for: ids)
        return queue.first
    }

    mutating func previous(sourceIDs: [String], currentID: String?) -> String? {
        let ids = uniqueIDs(sourceIDs)
        guard !ids.isEmpty else {
            reset()
            return nil
        }

        ensureReady(sourceIDs: ids, currentID: currentID)

        guard cursor > 0 else {
            return currentIDInQueue() ?? currentID
        }
        cursor -= 1
        return queue[cursor]
    }

    private mutating func ensureReady(sourceIDs: [String], currentID: String?) {
        if queue.isEmpty {
            enter(sourceIDs: sourceIDs, currentID: currentID)
        } else {
            reconcile(sourceIDs: sourceIDs, currentID: currentID)
        }
    }

    private func makeRound(
        sourceIDs: [String],
        currentID: String?,
        avoidingImmediateRepeatAfter previousID: String?
    ) -> [String] {
        guard !sourceIDs.isEmpty else { return [] }
        let ids = uniqueIDs(sourceIDs)

        if let currentID, ids.contains(currentID) {
            let tail = ids.filter { $0 != currentID }.shuffled()
            return [currentID] + tail
        }

        guard ids.count > 1, let previousID else {
            return ids.shuffled()
        }

        var shuffled = ids.shuffled()
        if shuffled.first == previousID,
           let swapIndex = shuffled.firstIndex(where: { $0 != previousID }) {
            shuffled.swapAt(0, swapIndex)
        }
        return shuffled
    }

    private func currentIDInQueue() -> String? {
        guard queue.indices.contains(cursor) else { return nil }
        return queue[cursor]
    }

    private func uniqueIDs(_ ids: [String]) -> [String] {
        var seen = Set<String>()
        return ids.filter { id in
            guard !id.isEmpty, !seen.contains(id) else { return false }
            seen.insert(id)
            return true
        }
    }

    private func signature(for ids: [String]) -> String {
        uniqueIDs(ids).joined(separator: "\u{1f}")
    }
}
