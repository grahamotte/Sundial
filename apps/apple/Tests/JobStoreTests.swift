import XCTest
@testable import SundialCore

final class JobStoreTests: XCTestCase {
    func testLoadsEmptyWhenMissing() throws {
        let store = JobStore(url: makeTemporaryDirectory().appending(path: "missing/jobs.json"))
        XCTAssertEqual(try store.load(), [])
    }

    func testSaveCreatesDirectoryAndSortsByName() throws {
        let store = JobStore(url: makeTemporaryDirectory().appending(path: "nested/jobs.json"))
        let jobs = [Job(name: "beta", command: "b"), Job(name: "Alpha", command: "a"), Job(name: "job 10", command: "c"), Job(name: "job 9", command: "d")]
        try store.save(jobs)
        XCTAssertEqual(try store.load().map(\.name), ["Alpha", "beta", "job 9", "job 10"])
    }

    func testLoadThrowsOnCorruptFile() throws {
        let url = makeTemporaryDirectory().appending(path: "jobs.json")
        try Data("nope".utf8).write(to: url)
        XCTAssertThrowsError(try JobStore(url: url).load())
    }
}
