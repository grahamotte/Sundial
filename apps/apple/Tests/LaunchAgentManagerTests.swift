import XCTest
@testable import SundialCore

final class LaunchAgentManagerTests: XCTestCase {
    private var directory: URL!
    private var commands: RecordingCommandRunner!
    private var manager: LaunchAgentManager!

    override func setUp() {
        directory = makeTemporaryDirectory().appending(path: "LaunchAgents", directoryHint: .isDirectory)
        commands = RecordingCommandRunner()
        manager = LaunchAgentManager(directory: directory, executablePath: "/Applications/Sundial.app/Contents/MacOS/Sundial", userID: 501, commands: commands)
    }

    private func job(_ name: String = "Job", enabled: Bool = true) -> Job {
        Job(name: name, command: "true", schedule: .daily(hour: 9, minute: 30), isEnabled: enabled)
    }

    func testPlistContents() throws {
        let job = job()
        let data = try manager.plistData(for: job)
        let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as! [String: Any]
        XCTAssertEqual(plist["Label"] as? String, job.label)
        XCTAssertEqual(plist["ProgramArguments"] as? [String], ["/Applications/Sundial.app/Contents/MacOS/Sundial", "run", job.id.uuidString])
        XCTAssertEqual(plist["StartCalendarInterval"] as? [[String: Int]], [["Hour": 9, "Minute": 30]])
        XCTAssertEqual(plist["AssociatedBundleIdentifiers"] as? [String], ["com.grahamotte.sundial"])
        XCTAssertEqual(try manager.plistData(for: job), data)
    }

    func testSyncWritesAndBootstrapsNewJobs() throws {
        let job = job()
        XCTAssertEqual(try manager.sync([job]), [])
        let url = manager.plistURL(for: job)
        XCTAssertEqual(try Data(contentsOf: url), try manager.plistData(for: job))
        XCTAssertEqual(commands.calls, [["/bin/launchctl", "bootstrap", "gui/501", url.path]])
    }

    func testSyncBootstrapsUnchangedJobsThatAreNotLoaded() throws {
        let job = job()
        _ = try manager.sync([job])
        commands.calls = []
        commands.results["print"] = 113
        _ = try manager.sync([job])
        XCTAssertEqual(commands.calls, [
            ["/bin/launchctl", "print", "gui/501/\(job.label)"],
            ["/bin/launchctl", "bootout", "gui/501/\(job.label)"],
            ["/bin/launchctl", "bootstrap", "gui/501", manager.plistURL(for: job).path],
        ])
    }

    func testSyncSkipsUnchangedLoadedJobs() throws {
        let job = job()
        _ = try manager.sync([job])
        commands.calls = []
        _ = try manager.sync([job])
        XCTAssertEqual(commands.calls, [["/bin/launchctl", "print", "gui/501/\(job.label)"]])
    }

    func testSyncReloadsChangedJobs() throws {
        var job = job()
        _ = try manager.sync([job])
        commands.calls = []
        job.schedule = .interval(minutes: 5)
        _ = try manager.sync([job])
        XCTAssertEqual(commands.calls, [
            ["/bin/launchctl", "bootout", "gui/501/\(job.label)"],
            ["/bin/launchctl", "bootstrap", "gui/501", manager.plistURL(for: job).path],
        ])
    }

    func testSyncRemovesDisabledAndDeletedJobsOnly() throws {
        let kept = job("Kept")
        var disabled = job("Disabled")
        let deleted = job("Deleted")
        _ = try manager.sync([kept, disabled, deleted])
        let foreign = directory.appending(path: "com.example.other.plist")
        try Data().write(to: foreign)
        commands.calls = []
        disabled.isEnabled = false

        _ = try manager.sync([kept, disabled])

        XCTAssertTrue(FileManager.default.fileExists(atPath: manager.plistURL(for: kept).path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: manager.plistURL(for: disabled).path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: manager.plistURL(for: deleted).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: foreign.path))
        XCTAssertEqual(Set(commands.calls.filter { $0[1] == "bootout" }.map { $0[2] }), ["gui/501/\(disabled.label)", "gui/501/\(deleted.label)"])
    }

    func testSyncReportsBootstrapFailures() throws {
        commands.results["bootstrap"] = 5
        XCTAssertEqual(try manager.sync([job("Broken")]), ["Broken"])
    }

    func testRunNowKickstartsLoadedJobs() throws {
        let job = job()
        try manager.runNow(job)
        XCTAssertEqual(commands.calls.last, ["/bin/launchctl", "kickstart", "gui/501/\(job.label)"])
        XCTAssertEqual(commands.spawned, [])
    }

    func testRunNowSpawnsRunnerForDisabledOrUnloadedJobs() throws {
        let disabled = job(enabled: false)
        try manager.runNow(disabled)
        commands.results["print"] = 113
        let unloaded = job()
        try manager.runNow(unloaded)
        XCTAssertEqual(commands.spawned, [
            ["/Applications/Sundial.app/Contents/MacOS/Sundial", "run", disabled.id.uuidString],
            ["/Applications/Sundial.app/Contents/MacOS/Sundial", "run", unloaded.id.uuidString],
        ])
        XCTAssertFalse(commands.calls.contains { $0[1] == "kickstart" })
    }
}
