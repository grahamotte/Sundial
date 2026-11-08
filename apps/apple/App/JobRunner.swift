import Foundation

struct ProcessOutcome: Equatable {
    var exitCode: Int32?
    var signal: Int32?
}

protocol ProcessLaunching {
    func run(executable: URL, arguments: [String], environment: [String: String], directory: URL, output: FileHandle) throws -> ProcessOutcome
}

struct SystemProcessLauncher: ProcessLaunching {
    func run(executable: URL, arguments: [String], environment: [String: String], directory: URL, output: FileHandle) throws -> ProcessOutcome {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        process.environment = environment
        process.currentDirectoryURL = directory
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = output
        process.standardError = output
        try process.run()
        process.waitUntilExit()
        if process.terminationReason == .uncaughtSignal {
            return ProcessOutcome(exitCode: nil, signal: process.terminationStatus)
        }
        return ProcessOutcome(exitCode: process.terminationStatus, signal: nil)
    }
}

struct JobRunner {
    enum RunError: LocalizedError, Equatable {
        case unknownJob(String)

        var errorDescription: String? {
            switch self {
            case .unknownJob(let id): return "No Sundial job has the ID \(id)."
            }
        }
    }

    static let shell = URL(filePath: "/bin/zsh")

    let paths: SundialPaths
    let launcher: ProcessLaunching
    let power: PowerMonitoring
    var baseEnvironment: [String: String] = ProcessInfo.processInfo.environment
    var processID: Int32 = ProcessInfo.processInfo.processIdentifier
    var timeZone: TimeZone = .current
    var now: () -> Date = Date.init

    func run(jobID: String) throws -> Int32 {
        guard let id = UUID(uuidString: jobID),
              let job = try JobStore(url: paths.jobsFile).load().first(where: { $0.id == id }) else {
            throw RunError.unknownJob(jobID)
        }
        let store = RunStore(directory: paths.runsDirectory)
        let journal = try RunJournal(store: store, record: store.begin(job: job, processID: processID, now: now()))
        let output = try journal.openLog()
        if !power.state().allowsRun {
            journal.note("Sundial: the Mac is asleep on battery; waiting until it is awake or on power", to: output)
            repeat { power.waitForChange() } while !power.state().allowsRun
            let started = now()
            try journal.startCommand(now: started)
            let waited = RunRecord.formatDuration(started.timeIntervalSince(journal.record.startedAt))
            journal.note("Sundial: started at \(JobRunner.time(started, timeZone: timeZone)) after waiting \(waited)", to: output)
        } else {
            try journal.startCommand(now: now())
        }
        let now = self.now
        let timeZone = self.timeZone
        power.onSleep = { @Sendable isOnPower in
            let date = now()
            journal.addSleep(RunRecord.Sleep(at: date, isOnPower: isOnPower))
            journal.note("Sundial: the Mac went to sleep at \(JobRunner.time(date, timeZone: timeZone)) \(isOnPower ? "on power" : "on battery") during this run", to: output)
        }
        let release = power.keepAwake(reason: "Sundial is running \(job.name)")
        let outcome: ProcessOutcome
        do {
            outcome = try launcher.run(
                executable: JobRunner.shell,
                arguments: ["-c", job.command],
                environment: environment(),
                directory: job.workingDirectoryURL(home: paths.home),
                output: output
            )
        } catch {
            journal.note("Sundial could not start the command: \(error.localizedDescription)", to: output)
            outcome = ProcessOutcome(exitCode: 127, signal: nil)
        }
        release()
        power.onSleep = nil
        try? output.close()
        try journal.finish(exitCode: outcome.exitCode, signal: outcome.signal, now: now())
        store.prune(now: now())
        if let signal = outcome.signal { return 128 + signal }
        return outcome.exitCode ?? 1
    }

    nonisolated static func time(_ date: Date, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

    func environment() -> [String: String] {
        let home = paths.home.path
        let searchPath = [
            "\(home)/.local/share/mise/shims",
            "\(home)/.local/bin",
            "/opt/homebrew/bin",
            "/opt/homebrew/sbin",
            "/usr/local/bin",
            "/usr/bin",
            "/bin",
            "/usr/sbin",
            "/sbin",
        ]
        let inherited = (baseEnvironment["PATH"] ?? "").split(separator: ":").map(String.init)
        var environment = baseEnvironment
        environment["PATH"] = (searchPath + inherited.filter { !searchPath.contains($0) && !$0.isEmpty }).joined(separator: ":")
        environment["HOME"] = home
        environment["SHELL"] = JobRunner.shell.path
        environment["LANG"] = baseEnvironment["LANG"] ?? "en_US.UTF-8"
        return environment
    }
}

nonisolated private final class RunJournal: @unchecked Sendable {
    private let store: RunStore
    private let lock = NSLock()
    private var current: RunRecord

    init(store: RunStore, record: RunRecord) {
        self.store = store
        current = record
    }

    var record: RunRecord { lock.withLock { current } }

    func openLog() throws -> FileHandle {
        let path = store.logURL(record.id).path
        let descriptor = open(path, O_WRONLY | O_APPEND)
        guard descriptor >= 0 else { throw CocoaError(.fileWriteUnknown, userInfo: [NSFilePathErrorKey: path]) }
        return FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
    }

    func note(_ line: String, to output: FileHandle) {
        lock.withLock { try? output.write(contentsOf: Data("\(line)\n".utf8)) }
    }

    func startCommand(now: Date) throws {
        try lock.withLock { current = try store.startCommand(current, now: now) }
    }

    func addSleep(_ sleep: RunRecord.Sleep) {
        lock.withLock {
            var slept = current
            slept.sleeps.append(sleep)
            current = (try? store.addSleep(sleep, to: current)) ?? slept
        }
    }

    func finish(exitCode: Int32?, signal: Int32?, now: Date) throws {
        try lock.withLock { current = try store.finish(current, exitCode: exitCode, signal: signal, now: now) }
    }
}
