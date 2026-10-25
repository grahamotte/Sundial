import XCTest
@testable import SundialCore

final class RunStoreTests: XCTestCase {
    private var directory: URL!
    private var store: RunStore!
    private let job = Job(name: "Backup", command: "echo hi")

    override func setUp() {
        directory = makeTemporaryDirectory().appending(path: "Runs", directoryHint: .isDirectory)
        store = RunStore(directory: directory)
    }

    func testBeginAndFinish() throws {
        let started = utcDate(2026, 10, 25, 12)
        let record = try store.begin(job: job, processID: 42, now: started)
        XCTAssertTrue(record.id.hasPrefix("1792929600000-"))
        XCTAssertEqual(store.records(), [record])
        XCTAssertEqual(store.log(for: record.id), "")

        let finished = try store.finish(record, exitCode: 1, signal: nil, now: started.addingTimeInterval(5))
        XCTAssertEqual(store.records(), [finished])
        XCTAssertEqual(finished.exitCode, 1)
        XCTAssertEqual(finished.duration(), 5)
        XCTAssertEqual(finished.jobName, "Backup")
        XCTAssertEqual(finished.processID, 42)
    }

    func testRecordsAreNewestFirstAndSkipCorruptFiles() throws {
        let older = try store.begin(job: job, processID: 1, now: utcDate(2026, 10, 1))
        let newer = try store.begin(job: job, processID: 1, now: utcDate(2026, 10, 2))
        try Data("{".utf8).write(to: directory.appending(path: "broken.json"))
        XCTAssertEqual(store.records().map(\.id), [newer.id, older.id])
    }

    func testLogReadsTail() throws {
        let record = try store.begin(job: job, processID: 1)
        try Data("hello world".utf8).write(to: store.logURL(record.id))
        XCTAssertEqual(store.log(for: record.id), "hello world")
        XCTAssertEqual(store.log(for: record.id, limit: 5), "world")
        XCTAssertEqual(store.log(for: "missing"), "")
    }

    func testFinishTrimsOversizedLogs() throws {
        let record = try store.begin(job: job, processID: 1)
        let size = RunStore.maxLogBytes + 10
        try Data((String(repeating: "a", count: 10) + String(repeating: "b", count: RunStore.maxLogBytes)).utf8).write(to: store.logURL(record.id))
        _ = try store.finish(record, exitCode: 0, signal: nil)
        let log = store.log(for: record.id, limit: Int.max)
        let marker = "[Sundial trimmed 10 earlier bytes of output]\n"
        XCTAssertTrue(log.hasPrefix(marker))
        XCTAssertEqual(log.dropFirst(marker.count), Substring(String(repeating: "b", count: size - 10)))
    }

    func testPruneRemovesRunsOlderThanRetention() throws {
        let now = utcDate(2026, 10, 31)
        let old = try store.begin(job: job, processID: 1, now: now.addingTimeInterval(-RunStore.retention - 1))
        let recent = try store.begin(job: job, processID: 1, now: now.addingTimeInterval(-RunStore.retention + 60))
        store.prune(now: now)
        XCTAssertEqual(store.records().map(\.id), [recent.id])
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.logURL(old.id).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.logURL(recent.id).path))
    }

    func testPruneKeepsFreshOrphanLogsAndRemovesStaleOnes() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fresh = store.logURL("fresh")
        let stale = store.logURL("stale")
        try Data().write(to: fresh)
        try Data().write(to: stale)
        let now = Date()
        try FileManager.default.setAttributes([.modificationDate: now.addingTimeInterval(-RunStore.retention - 60)], ofItemAtPath: stale.path)
        store.prune(now: now)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fresh.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: stale.path))
    }

    func testDeleteRemovesOnlyThatJobsRuns() throws {
        let other = Job(name: "Other", command: "true")
        let mine = try store.begin(job: job, processID: 1)
        let theirs = try store.begin(job: other, processID: 1)
        store.delete(jobID: job.id)
        XCTAssertEqual(store.records().map(\.id), [theirs.id])
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.logURL(mine.id).path))
    }
}
