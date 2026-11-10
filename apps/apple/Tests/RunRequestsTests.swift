import XCTest
@testable import SundialCore

final class RunRequestsTests: XCTestCase {
    private var requests: RunRequests!
    private let jobID = UUID()
    private let now = utcDate(2026, 10, 25, 9, 2, 10)

    override func setUp() {
        requests = RunRequests(directory: makeTemporaryDirectory().appending(path: "Requests", directoryHint: .isDirectory))
    }

    func testFreshRequestIsConsumedOnce() throws {
        try requests.request(jobID: jobID, now: now)
        XCTAssertTrue(FileManager.default.fileExists(atPath: requests.requestURL(jobID).path))
        XCTAssertTrue(requests.consume(jobID: jobID, now: now.addingTimeInterval(RunRequests.freshness)))
        XCTAssertFalse(FileManager.default.fileExists(atPath: requests.requestURL(jobID).path))
        XCTAssertFalse(requests.consume(jobID: jobID, now: now))
    }

    func testStaleRequestIsRemovedWithoutCounting() throws {
        try requests.request(jobID: jobID, now: now)
        XCTAssertFalse(requests.consume(jobID: jobID, now: now.addingTimeInterval(RunRequests.freshness + 1)))
        XCTAssertFalse(FileManager.default.fileExists(atPath: requests.requestURL(jobID).path))
    }

    func testMissingRequestDoesNotCount() {
        XCTAssertFalse(requests.consume(jobID: jobID, now: now))
    }

    func testRequestsAreKeptPerJob() throws {
        let other = UUID()
        try requests.request(jobID: jobID, now: now)
        XCTAssertFalse(requests.consume(jobID: other, now: now))
        XCTAssertTrue(requests.consume(jobID: jobID, now: now))
    }
}
