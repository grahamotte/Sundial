import XCTest
@testable import SundialCore

final class RunRecordTests: XCTestCase {
    private func record(finished: Bool, exitCode: Int32? = nil, signal: Int32? = nil) -> RunRecord {
        RunRecord(
            id: "1",
            jobID: UUID(),
            jobName: "Job",
            command: "true",
            startedAt: utcDate(2026, 10, 25, 12, 0, 0),
            finishedAt: finished ? utcDate(2026, 10, 25, 12, 0, 42) : nil,
            exitCode: exitCode,
            signal: signal,
            processID: 123
        )
    }

    func testStatus() {
        XCTAssertEqual(record(finished: true, exitCode: 0).status { _ in false }, .succeeded)
        XCTAssertEqual(record(finished: true, exitCode: 2).status { _ in false }, .failed)
        XCTAssertEqual(record(finished: true, signal: 9).status { _ in false }, .failed)
        XCTAssertEqual(record(finished: false).status { $0 == 123 }, .running)
        XCTAssertEqual(record(finished: false).status { _ in false }, .interrupted)
    }

    func testFailureFlags() {
        XCTAssertTrue(RunRecord.Status.failed.isFailure)
        XCTAssertTrue(RunRecord.Status.interrupted.isFailure)
        XCTAssertFalse(RunRecord.Status.succeeded.isFailure)
        XCTAssertFalse(RunRecord.Status.running.isFailure)
    }

    func testDurationAndOutcome() {
        XCTAssertEqual(record(finished: true, exitCode: 0).duration(), 42)
        XCTAssertEqual(record(finished: false).duration(now: utcDate(2026, 10, 25, 12, 1, 0)), 60)
        XCTAssertEqual(record(finished: false).duration(now: utcDate(2026, 10, 25, 11, 0, 0)), 0)
        XCTAssertEqual(record(finished: true, exitCode: 3).outcome, "Exit 3")
        XCTAssertEqual(record(finished: true, signal: 15).outcome, "Signal 15")
        XCTAssertNil(record(finished: false).outcome)
    }

    func testDurationText() {
        let now = utcDate(2026, 10, 25, 12, 5, 0)
        XCTAssertEqual(record(finished: true, exitCode: 0).durationText(status: .succeeded, now: now), "42s")
        XCTAssertEqual(record(finished: false).durationText(status: .running, now: now), "5m 0s")
        XCTAssertEqual(record(finished: false).durationText(status: .interrupted, now: now), "—")
    }

    func testFormatDuration() {
        XCTAssertEqual(RunRecord.formatDuration(0.2), "<1s")
        XCTAssertEqual(RunRecord.formatDuration(59.9), "59s")
        XCTAssertEqual(RunRecord.formatDuration(61), "1m 1s")
        XCTAssertEqual(RunRecord.formatDuration(3_725), "1h 2m")
    }

    func testProcessLivenessRejectsInvalidIDs() {
        XCTAssertFalse(RunRecord.isProcessAlive(0))
        XCTAssertFalse(RunRecord.isProcessAlive(-1))
    }
}
