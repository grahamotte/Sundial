import Foundation

struct LaunchAgentManager {
    static let launchctl = "/bin/launchctl"

    let directory: URL
    let executablePath: String
    let userID: UInt32
    let commands: CommandRunning
    var fileManager: FileManager = .default

    var domain: String { "gui/\(userID)" }

    func plistURL(for job: Job) -> URL {
        directory.appending(path: "\(job.label).plist")
    }

    func plist(for job: Job) -> [String: Any] {
        [
            "Label": job.label,
            "ProgramArguments": [executablePath, "run", job.id.uuidString],
            "StartCalendarInterval": job.schedule.launchdIntervals,
            "AssociatedBundleIdentifiers": [SundialPaths.bundleIdentifier],
            "ProcessType": "Standard",
        ]
    }

    func plistData(for job: Job) throws -> Data {
        try PropertyListSerialization.data(fromPropertyList: plist(for: job), format: .xml, options: 0)
    }

    func sync(_ jobs: [Job]) throws -> [String] {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        var failures: [String] = []
        let enabled = jobs.filter(\.isEnabled)

        for job in enabled {
            let url = plistURL(for: job)
            let data = try plistData(for: job)
            let existing = try? Data(contentsOf: url)
            if existing == data && isLoaded(job.label) { continue }
            if existing != nil { commands.run(LaunchAgentManager.launchctl, ["bootout", "\(domain)/\(job.label)"]) }
            try data.write(to: url, options: .atomic)
            if commands.run(LaunchAgentManager.launchctl, ["bootstrap", domain, url.path]) != 0 {
                failures.append(job.name)
            }
        }

        let enabledLabels = Set(enabled.map(\.label))
        let files = (try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        for file in files where file.pathExtension == "plist" {
            let label = file.deletingPathExtension().lastPathComponent
            guard label.hasPrefix(SundialPaths.labelPrefix), !enabledLabels.contains(label) else { continue }
            commands.run(LaunchAgentManager.launchctl, ["bootout", "\(domain)/\(label)"])
            try fileManager.removeItem(at: file)
        }

        return failures
    }

    func runNow(_ job: Job) throws {
        if job.isEnabled && isLoaded(job.label) {
            commands.run(LaunchAgentManager.launchctl, ["kickstart", "\(domain)/\(job.label)"])
        } else {
            try commands.spawn(executablePath, ["run", job.id.uuidString])
        }
    }

    func isLoaded(_ label: String) -> Bool {
        commands.run(LaunchAgentManager.launchctl, ["print", "\(domain)/\(label)"]) == 0
    }
}
