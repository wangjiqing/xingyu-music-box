import XCTest

@testable import XingyuMusicBox

final class PlaybackPersistenceTests: XCTestCase {
    struct TestTrack {
        let id: String
        let url: String?
        let duration: Double?
    }

    func testCheckpointEncodeDecode() throws {
        let checkpoint = makeCheckpoint(currentTime: 42, queueIDs: ["a", "b"], queueIndex: 1)
        let data = try JSONEncoder().encode(checkpoint)
        let decoded = try JSONDecoder().decode(PlaybackCheckpoint.self, from: data)

        XCTAssertEqual(decoded.currentTrack.id, "b")
        XCTAssertEqual(decoded.queue.map(\.id), ["a", "b"])
        XCTAssertEqual(decoded.currentTime, 42)
    }

    func testMissingSongDoesNotRestore() {
        let checkpoint = makeCheckpoint(currentTime: 10, queueIDs: ["old"], queueIndex: 0)
        let restored = restore(checkpoint, library: [TestTrack(id: "new", url: nil, duration: 100)])

        XCTAssertNil(restored)
    }

    func testQueueOrderChangesStillRestoresCurrentTrack() throws {
        let checkpoint = makeCheckpoint(currentTime: 8, queueIDs: ["a", "b", "c"], queueIndex: 1)
        let library = [
            TestTrack(id: "c", url: nil, duration: 100),
            TestTrack(id: "b", url: nil, duration: 100),
            TestTrack(id: "a", url: nil, duration: 100)
        ]
        let restored = try XCTUnwrap(restore(checkpoint, library: library))

        XCTAssertEqual(restored.track.id, "b")
        XCTAssertEqual(restored.queue.map(\.id), ["a", "b", "c"])
        XCTAssertEqual(restored.queueIndex, 1)
    }

    func testProgressIsClampedToDuration() throws {
        let checkpoint = makeCheckpoint(currentTime: 120, queueIDs: ["b"], queueIndex: 0)
        let restored = try XCTUnwrap(restore(checkpoint, library: [TestTrack(id: "b", url: nil, duration: 60)]))

        XCTAssertLessThan(restored.startTime, 60)
        XCTAssertGreaterThanOrEqual(restored.startTime, 0)
    }

    func testRestoreWaitsForLoadedLibrary() {
        let checkpoint = makeCheckpoint(currentTime: 12, queueIDs: ["b"], queueIndex: 0)

        XCTAssertNil(restore(checkpoint, library: []))
        XCTAssertNotNil(restore(checkpoint, library: [TestTrack(id: "b", url: nil, duration: 60)]))
    }

    func testColdStartRestoreDoesNotAutoPlay() throws {
        let checkpoint = makeCheckpoint(currentTime: 12, queueIDs: ["b"], queueIndex: 0)
        let restored = try XCTUnwrap(restore(checkpoint, library: [TestTrack(id: "b", url: nil, duration: 60)]))

        XCTAssertEqual(restored.track.id, "b")
        XCTAssertEqual(restored.startTime, 12)
    }

    private func makeCheckpoint(currentTime: Double, queueIDs: [String], queueIndex: Int) -> PlaybackCheckpoint {
        let queue = queueIDs.map {
            PlaybackTrackSnapshot(id: $0, sourceURLString: nil, title: $0, artist: "artist", album: "album")
        }
        return PlaybackCheckpoint(
            currentTrack: queue[min(queueIndex, queue.count - 1)],
            currentTime: currentTime,
            queue: queue,
            queueIndex: queueIndex,
            playbackMode: "sequential",
            updatedAt: Date()
        )
    }

    private func restore(
        _ checkpoint: PlaybackCheckpoint,
        library: [TestTrack]
    ) -> (track: TestTrack, queue: [TestTrack], queueIndex: Int, startTime: Double)? {
        PlaybackPersistence.restore(
            checkpoint: checkpoint,
            library: library,
            id: \.id,
            sourceURLString: \.url,
            duration: \.duration,
            fallbackQueue: library
        )
    }
}
