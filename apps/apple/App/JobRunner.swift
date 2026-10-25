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
    var baseEnvironment: [String: String] = ProcessInfo.processInfo.environment
    var processID: Int32 = ProcessInfo.processInfo.processIdentifier
    var now: () -> Date = Date.init

    func run(jobID: String) throws -> Int32 {
        guard let id = UUID(uuidString: jobID),
              let job = try JobStore(url: paths.jobsFile).load().first(where: { $0.id == id }) else {
            throw RunError.unknownJob(jobID)
        }
        let store = RunStore(directory: paths.runsDirectory)
        let record = try store.begin(job: job, processID: processID, now: now())
        let output = try FileHandle(forWritingTo: store.logURL(record.id))
        let outcome: ProcessOutcome
        do {
            outcome = try launcher.run(
                executable: JobRunner.shell,
                arguments: ["-l", "-c", job.command],
                environment: environment(),
                directory: job.workingDirectoryURL(home: paths.home),
                output: output
            )
        } catch {
            _ = try? output.seekToEnd()
            try? output.write(contentsOf: Data("Sundial could not start the command: \(error.localizedDescription)\n".utf8))
            outcome = ProcessOutcome(exitCode: 127, signal: nil)
        }
        try? output.close()
        _ = try store.finish(record, exitCode: outcome.exitCode, signal: outcome.signal, now: now())
        store.prune(now: now())
        if let signal = outcome.signal { return 128 + signal }
        return outcome.exitCode ?? 1
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
