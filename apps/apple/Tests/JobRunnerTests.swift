import XCTest
@testable import SundialCore

private final class StubLauncher: ProcessLaunching {
    var outcome = ProcessOutcome(exitCode: 0, signal: nil)
    var output = ""
    var error: Error?
    var received: (executable: URL, arguments: [String], environment: [String: String], directory: URL)?

    func run(executable: URL, arguments: [String], environment: [String: String], directory: URL, output: FileHandle) throws -> ProcessOutcome {
        received = (executable, arguments, environment, directory)
        if let error { throw error }
        try output.write(contentsOf: Data(self.output.utf8))
        return outcome
    }
}

final class JobRunnerTests: XCTestCase {
    private var paths: SundialPaths!
    private var launcher: StubLauncher!
    private let job = Job(name: "Backup", command: "echo hi && false", workingDirectory: "~/Code", schedule: .interval(minutes: 5))

    override func setUp() {
        paths = SundialPaths(home: makeTemporaryDirectory())
        launcher = StubLauncher()
        try! JobStore(url: paths.jobsFile).save([job])
    }

    private func runner(now: Date = utcDate(2026, 10, 25, 12)) -> JobRunner {
        JobRunner(paths: paths, launcher: launcher, baseEnvironment: ["PATH": "/custom/bin:/usr/bin", "USER": "tester"], processID: 77, now: { now })
    }

    func testRunsCommandThroughLoginShellAndRecordsSuccess() throws {
        launcher.output = "hi\n"
        XCTAssertEqual(try runner().run(jobID: job.id.uuidString), 0)

        XCTAssertEqual(launcher.received?.executable.path, "/bin/zsh")
        XCTAssertEqual(launcher.received?.arguments, ["-l", "-c", "echo hi && false"])
        XCTAssertEqual(launcher.received?.directory.path, paths.home.appending(path: "Code").path)
        let records = RunStore(directory: paths.runsDirectory).records()
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0].status { _ in false }, .succeeded)
        XCTAssertEqual(records[0].processID, 77)
        XCTAssertEqual(RunStore(directory: paths.runsDirectory).log(for: records[0].id), "hi\n")
    }

    func testRecordsFailureExitCode() throws {
        launcher.outcome = ProcessOutcome(exitCode: 3, signal: nil)
        XCTAssertEqual(try runner().run(jobID: job.id.uuidString), 3)
        let record = RunStore(directory: paths.runsDirectory).records()[0]
        XCTAssertEqual(record.exitCode, 3)
        XCTAssertEqual(record.status { _ in false }, .failed)
    }

    func testRecordsSignals() throws {
        launcher.outcome = ProcessOutcome(exitCode: nil, signal: 9)
        XCTAssertEqual(try runner().run(jobID: job.id.uuidString), 137)
        XCTAssertEqual(RunStore(directory: paths.runsDirectory).records()[0].signal, 9)
    }

    func testRecordsLaunchFailuresInLog() throws {
        launcher.error = CocoaError(.fileNoSuchFile)
        XCTAssertEqual(try runner().run(jobID: job.id.uuidString), 127)
        let store = RunStore(directory: paths.runsDirectory)
        let record = store.records()[0]
        XCTAssertEqual(record.exitCode, 127)
        XCTAssertTrue(store.log(for: record.id).hasPrefix("Sundial could not start the command: "))
    }

    func testUnknownJobThrows() {
        let id = UUID().uuidString
        XCTAssertThrowsError(try runner().run(jobID: id)) { error in
            XCTAssertEqual(error as? JobRunner.RunError, .unknownJob(id))
        }
        XCTAssertThrowsError(try runner().run(jobID: "not-a-uuid"))
    }

    func testPrunesOldRunsAfterRunning() throws {
        let store = RunStore(directory: paths.runsDirectory)
        let now = utcDate(2026, 10, 25, 12)
        let old = try store.begin(job: job, processID: 1, now: now.addingTimeInterval(-RunStore.retention - 1))
        _ = try runner(now: now).run(jobID: job.id.uuidString)
        XCTAssertFalse(store.records().contains { $0.id == old.id })
        XCTAssertEqual(store.records().count, 1)
    }

    func testEnvironmentAddsCommonToolPaths() {
        let environment = runner().environment()
        let home = paths.home.path
        XCTAssertEqual(
            environment["PATH"],
            "\(home)/.local/share/mise/shims:\(home)/.local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/custom/bin"
        )
        XCTAssertEqual(environment["HOME"], home)
        XCTAssertEqual(environment["SHELL"], "/bin/zsh")
        XCTAssertEqual(environment["LANG"], "en_US.UTF-8")
        XCTAssertEqual(environment["USER"], "tester")
    }
}
