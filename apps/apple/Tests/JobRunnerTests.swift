import XCTest
@testable import SundialCore

private final class StubLauncher: ProcessLaunching {
    var outcome = ProcessOutcome(exitCode: 0, signal: nil)
    var output = ""
    var error: Error?
    var received: (executable: URL, arguments: [String], environment: [String: String], directory: URL)?
    var duringRun: () -> Void = {}

    func run(executable: URL, arguments: [String], environment: [String: String], directory: URL, output: FileHandle) throws -> ProcessOutcome {
        received = (executable, arguments, environment, directory)
        if let error { throw error }
        try output.write(contentsOf: Data(self.output.utf8))
        duringRun()
        return outcome
    }
}

private final class StubPower: PowerMonitoring {
    var onSleep: (@Sendable (Bool) -> Void)?
    var states: [PowerState] = [PowerState(isAsleep: false, isOnPower: false)]
    var waits = 0
    var held: [String] = []
    var released = 0
    var onWait: () -> Void = {}

    func state() -> PowerState {
        states.count > 1 ? states.removeFirst() : states[0]
    }

    func waitForChange() {
        waits += 1
        onWait()
    }

    func keepAwake(reason: String) -> () -> Void {
        held.append(reason)
        return { [weak self] in self?.released += 1 }
    }
}

private final class Clock {
    var date: Date
    init(_ date: Date) { self.date = date }
}

final class JobRunnerTests: XCTestCase {
    private var paths: SundialPaths!
    private var launcher: StubLauncher!
    private var power: StubPower!
    private let job = Job(name: "Backup", command: "echo hi && false", workingDirectory: "~/Code", schedule: .interval(minutes: 5))

    override func setUp() {
        paths = SundialPaths(home: makeTemporaryDirectory())
        launcher = StubLauncher()
        power = StubPower()
        try! JobStore(url: paths.jobsFile).save([job])
    }

    private func runner(now: Date = utcDate(2026, 10, 25, 12)) -> JobRunner {
        runner(clock: Clock(now))
    }

    private func runner(clock: Clock) -> JobRunner {
        JobRunner(
            paths: paths,
            launcher: launcher,
            power: power,
            baseEnvironment: ["PATH": "/custom/bin:/usr/bin", "USER": "tester"],
            processID: 77,
            timeZone: TimeZone(identifier: "UTC")!,
            now: { clock.date }
        )
    }

    private var store: RunStore { RunStore(directory: paths.runsDirectory) }

    func testRunsCommandThroughLoginShellAndRecordsSuccess() throws {
        launcher.output = "hi\n"
        XCTAssertEqual(try runner().run(jobID: job.id.uuidString), 0)

        XCTAssertEqual(launcher.received?.executable.path, "/bin/zsh")
        XCTAssertEqual(launcher.received?.arguments, ["-c", "echo hi && false"])
        XCTAssertEqual(launcher.received?.directory.path, paths.home.appending(path: "Code").path)
        let records = RunStore(directory: paths.runsDirectory).records()
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0].status { _ in false }, .succeeded)
        XCTAssertEqual(records[0].processID, 77)
        XCTAssertEqual(RunStore(directory: paths.runsDirectory).log(for: records[0].id), "hi\n")
        XCTAssertEqual(records[0].commandStartedAt, records[0].startedAt)
        XCTAssertEqual(records[0].sleeps, [])
        XCTAssertEqual(power.waits, 0)
    }

    func testRunsImmediatelyWhenAwakeOnBatteryAwakeOnPowerOrAsleepOnPower() throws {
        for state in [
            PowerState(isAsleep: false, isOnPower: false),
            PowerState(isAsleep: false, isOnPower: true),
            PowerState(isAsleep: true, isOnPower: true),
        ] {
            power = StubPower()
            power.states = [state]
            XCTAssertEqual(try runner().run(jobID: job.id.uuidString), 0)
            XCTAssertEqual(power.waits, 0)
        }
        XCTAssertEqual(store.records().count, 3)
        XCTAssertTrue(store.records().allSatisfy { $0.commandStartedAt == $0.startedAt })
    }

    func testWaitsWhileAsleepOnBatteryAndRunsOnceAwake() throws {
        let clock = Clock(utcDate(2026, 11, 7, 2, 0, 0))
        power.states = [
            PowerState(isAsleep: true, isOnPower: false),
            PowerState(isAsleep: true, isOnPower: false),
            PowerState(isAsleep: false, isOnPower: false),
        ]
        var waitingRecords: [RunRecord] = []
        power.onWait = { [unowned self] in
            waitingRecords.append(store.records()[0])
            XCTAssertNil(launcher.received)
            clock.date = utcDate(2026, 11, 7, 10, 2, 31)
        }
        launcher.output = "tidy\n"
        XCTAssertEqual(try runner(clock: clock).run(jobID: job.id.uuidString), 0)

        XCTAssertEqual(power.waits, 2)
        XCTAssertEqual(waitingRecords.first?.status { _ in true }, .waiting)
        XCTAssertEqual(waitingRecords.first?.startedAt, utcDate(2026, 11, 7, 2, 0, 0))
        let record = store.records()[0]
        XCTAssertEqual(record.startedAt, utcDate(2026, 11, 7, 2, 0, 0))
        XCTAssertEqual(record.commandStartedAt, utcDate(2026, 11, 7, 10, 2, 31))
        XCTAssertEqual(record.status { _ in false }, .succeeded)
        XCTAssertEqual(record.notes(status: .succeeded), ["Waited 8h 2m"])
        XCTAssertEqual(
            store.log(for: record.id),
            """
            Sundial: the Mac is asleep on battery; waiting until it is awake or on power
            Sundial: started at 10:02:31 after waiting 8h 2m
            tidy

            """
        )
    }

    func testWaitingRunStartsWhenPluggedIn() throws {
        power.states = [
            PowerState(isAsleep: true, isOnPower: false),
            PowerState(isAsleep: true, isOnPower: true),
        ]
        XCTAssertEqual(try runner().run(jobID: job.id.uuidString), 0)
        XCTAssertEqual(power.waits, 1)
        XCTAssertNotNil(launcher.received)
    }

    func testHoldsTheMacAwakeOnlyWhileTheCommandRuns() throws {
        launcher.duringRun = { [unowned self] in
            XCTAssertEqual(power.held, ["Sundial is running Backup"])
            XCTAssertEqual(power.released, 0)
            XCTAssertNotNil(power.onSleep)
        }
        _ = try runner().run(jobID: job.id.uuidString)
        XCTAssertEqual(power.held.count, 1)
        XCTAssertEqual(power.released, 1)
        XCTAssertNil(power.onSleep)
    }

    func testRecordsEachSleepDuringTheRunInTheRecordAndLog() throws {
        let clock = Clock(utcDate(2026, 11, 7, 16, 3, 4))
        launcher.output = "pulling\n"
        launcher.outcome = ProcessOutcome(exitCode: 1, signal: nil)
        launcher.duringRun = { [unowned self] in
            clock.date = utcDate(2026, 11, 7, 16, 3, 10)
            power.onSleep?(false)
            XCTAssertEqual(store.records()[0].sleeps, [RunRecord.Sleep(at: utcDate(2026, 11, 7, 16, 3, 10), isOnPower: false)])
            clock.date = utcDate(2026, 11, 7, 16, 20, 0)
            power.onSleep?(true)
            clock.date = utcDate(2026, 11, 7, 16, 21, 0)
        }
        XCTAssertEqual(try runner(clock: clock).run(jobID: job.id.uuidString), 1)

        let record = store.records()[0]
        XCTAssertEqual(record.sleeps, [
            RunRecord.Sleep(at: utcDate(2026, 11, 7, 16, 3, 10), isOnPower: false),
            RunRecord.Sleep(at: utcDate(2026, 11, 7, 16, 20, 0), isOnPower: true),
        ])
        XCTAssertEqual(record.status { _ in false }, .failed)
        XCTAssertEqual(record.notes(status: .failed), ["Mac slept during run"])
        XCTAssertEqual(
            store.log(for: record.id),
            """
            pulling
            Sundial: the Mac went to sleep at 16:03:10 on battery during this run
            Sundial: the Mac went to sleep at 16:20:00 on power during this run

            """
        )
    }

    func testSleepsWhileWaitingAreNotRecordedAsSleepsDuringTheRun() throws {
        power.states = [PowerState(isAsleep: true, isOnPower: false), PowerState(isAsleep: false, isOnPower: false)]
        power.onWait = { [unowned self] in power.onSleep?(false) }
        _ = try runner().run(jobID: job.id.uuidString)
        XCTAssertEqual(store.records()[0].sleeps, [])
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
