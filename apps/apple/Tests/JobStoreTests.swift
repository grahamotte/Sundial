import XCTest
@testable import SundialCore

final class JobStoreTests: XCTestCase {
    func testLoadsEmptyWhenMissing() throws {
        let store = JobStore(url: makeTemporaryDirectory().appending(path: "missing/jobs.json"))
        XCTAssertEqual(try store.load(), [])
    }

    func testSaveCreatesDirectoryAndSortsSameScheduleByName() throws {
        let store = JobStore(url: makeTemporaryDirectory().appending(path: "nested/jobs.json"))
        let jobs = [Job(name: "beta", command: "b"), Job(name: "Alpha", command: "a"), Job(name: "job 10", command: "c"), Job(name: "job 9", command: "d")]
        try store.save(jobs)
        XCTAssertEqual(try store.load().map(\.name), ["Alpha", "beta", "job 9", "job 10"])
    }

    func testSortsByRunsPerDayBeforeName() throws {
        let store = JobStore(url: makeTemporaryDirectory().appending(path: "jobs.json"))
        let jobs = [
            Job(name: "weekly", command: "w", schedule: .weekly(weekdays: [2], hour: 9, minute: 0)),
            Job(name: "daily", command: "d", schedule: .daily(hour: 9, minute: 0)),
            Job(name: "six hours", command: "s", schedule: .interval(minutes: 360)),
            Job(name: "weekdays", command: "k", schedule: .weekly(weekdays: [2, 3, 4, 5, 6], hour: 9, minute: 0)),
            Job(name: "b quarter hour", command: "q", schedule: .interval(minutes: 15)),
            Job(name: "a quarter hour", command: "q", schedule: .interval(minutes: 15)),
        ]
        try store.save(jobs)
        XCTAssertEqual(try store.load().map(\.name), ["a quarter hour", "b quarter hour", "six hours", "daily", "weekdays", "weekly"])
    }

    func testLoadSortsUnsortedFile() throws {
        let url = makeTemporaryDirectory().appending(path: "jobs.json")
        let jobs = [
            Job(name: "daily", command: "d", schedule: .daily(hour: 9, minute: 0)),
            Job(name: "hourly", command: "h", schedule: .interval(minutes: 60)),
        ]
        try JSONEncoder().encode(jobs).write(to: url)
        XCTAssertEqual(try JobStore(url: url).load().map(\.name), ["hourly", "daily"])
    }

    func testLoadThrowsOnCorruptFile() throws {
        let url = makeTemporaryDirectory().appending(path: "jobs.json")
        try Data("nope".utf8).write(to: url)
        XCTAssertThrowsError(try JobStore(url: url).load())
    }
}
