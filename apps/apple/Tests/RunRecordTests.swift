import XCTest
@testable import SundialCore

final class RunRecordTests: XCTestCase {
    private func record(
        finished: Bool,
        exitCode: Int32? = nil,
        signal: Int32? = nil,
        commandStartedAt: Date? = utcDate(2026, 10, 25, 12, 0, 0),
        sleeps: [RunRecord.Sleep] = []
    ) -> RunRecord {
        RunRecord(
            id: "1",
            jobID: UUID(),
            jobName: "Job",
            command: "true",
            startedAt: utcDate(2026, 10, 25, 12, 0, 0),
            commandStartedAt: commandStartedAt,
            finishedAt: finished ? utcDate(2026, 10, 25, 12, 0, 42) : nil,
            exitCode: exitCode,
            signal: signal,
            processID: 123,
            sleeps: sleeps
        )
    }

    func testStatus() {
        XCTAssertEqual(record(finished: true, exitCode: 0).status { _ in false }, .succeeded)
        XCTAssertEqual(record(finished: true, exitCode: 2).status { _ in false }, .failed)
        XCTAssertEqual(record(finished: true, signal: 9).status { _ in false }, .failed)
        XCTAssertEqual(record(finished: false).status { $0 == 123 }, .running)
        XCTAssertEqual(record(finished: false).status { _ in false }, .interrupted)
        XCTAssertEqual(record(finished: false, commandStartedAt: nil).status { $0 == 123 }, .waiting)
        XCTAssertEqual(record(finished: false, commandStartedAt: nil).status { _ in false }, .interrupted)
        XCTAssertEqual(record(finished: true, exitCode: 0, sleeps: [RunRecord.Sleep(at: utcDate(2026, 10, 25, 12, 0, 10), isOnPower: false)]).status { _ in false }, .succeeded)
    }

    func testFailureFlags() {
        XCTAssertTrue(RunRecord.Status.failed.isFailure)
        XCTAssertTrue(RunRecord.Status.interrupted.isFailure)
        XCTAssertFalse(RunRecord.Status.succeeded.isFailure)
        XCTAssertFalse(RunRecord.Status.running.isFailure)
        XCTAssertFalse(RunRecord.Status.waiting.isFailure)
        XCTAssertTrue(RunRecord.Status.waiting.isActive)
        XCTAssertTrue(RunRecord.Status.running.isActive)
        XCTAssertFalse(RunRecord.Status.succeeded.isActive)
        XCTAssertFalse(RunRecord.Status.failed.isActive)
        XCTAssertFalse(RunRecord.Status.interrupted.isActive)
        XCTAssertEqual(RunRecord.Status.waiting.title, "Waiting")
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
        XCTAssertEqual(record(finished: false, commandStartedAt: nil).durationText(status: .waiting, now: now), "5m 0s")
        XCTAssertEqual(record(finished: false, commandStartedAt: nil).durationText(status: .interrupted, now: now), "—")
    }

    func testWait() {
        let now = utcDate(2026, 10, 25, 20, 2, 0)
        XCTAssertEqual(record(finished: false, commandStartedAt: nil).wait(now: now), 8 * 3600 + 120)
        XCTAssertEqual(record(finished: false, commandStartedAt: utcDate(2026, 10, 25, 12, 0, 30)).wait(now: now), 30)
        XCTAssertEqual(record(finished: true, commandStartedAt: nil).wait(now: now), 42)
        XCTAssertEqual(record(finished: false, commandStartedAt: nil).duration(now: now), 0)
        XCTAssertEqual(record(finished: true, exitCode: 0, commandStartedAt: utcDate(2026, 10, 25, 12, 0, 30)).duration(), 12)
    }

    func testNotesShowLongWaitsAndSleeps() {
        let now = utcDate(2026, 10, 25, 20, 2, 0)
        let sleep = RunRecord.Sleep(at: utcDate(2026, 10, 25, 12, 0, 40), isOnPower: false)
        XCTAssertEqual(record(finished: true, exitCode: 0).notes(status: .succeeded), [])
        XCTAssertEqual(record(finished: true, exitCode: 0, commandStartedAt: utcDate(2026, 10, 25, 12, 0, 30)).notes(status: .succeeded), [])
        XCTAssertEqual(
            record(finished: false, commandStartedAt: utcDate(2026, 10, 25, 20, 2, 0)).notes(status: .running, now: now),
            ["Waited 8h 2m"]
        )
        XCTAssertEqual(record(finished: false, commandStartedAt: nil).notes(status: .waiting, now: now), [])
        XCTAssertEqual(
            record(finished: true, exitCode: 1, commandStartedAt: utcDate(2026, 10, 25, 12, 0, 20), sleeps: [sleep]).notes(status: .failed),
            ["Mac slept during run"]
        )
        XCTAssertEqual(
            record(finished: false, commandStartedAt: utcDate(2026, 10, 25, 20, 2, 0), sleeps: [sleep]).notes(status: .running, now: now),
            ["Mac slept during run", "Waited 8h 2m"]
        )
        XCTAssertFalse(record(finished: true, exitCode: 0).sleptDuringRun)
        XCTAssertTrue(record(finished: true, exitCode: 0, sleeps: [sleep]).sleptDuringRun)
    }

    func testLatestPerJobKeepsNewestRunOfEachJobNewestFirstAndLimited() {
        let jobA = UUID(), jobB = UUID(), jobC = UUID()
        let jobs = [jobA, jobA, jobB, jobA, jobC, jobA, jobA]
        let runs = jobs.enumerated().map { index, jobID in
            RunRecord(id: "\(index)", jobID: jobID, jobName: "Job", command: "true", startedAt: utcDate(2026, 10, 25, index), processID: 1)
        }.shuffled()
        XCTAssertEqual(RunRecord.latestPerJob(runs, limit: 10).map(\.id), ["6", "4", "2"])
        XCTAssertEqual(RunRecord.latestPerJob(runs, limit: 2).map(\.id), ["6", "4"])
        XCTAssertEqual(RunRecord.latestPerJob([], limit: 10), [])
        XCTAssertEqual(RunRecord.latestPerJob(runs, limit: 0), [])
        XCTAssertEqual(RunRecord.latestPerJob(runs, limit: -1), [])
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
