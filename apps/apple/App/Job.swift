import Foundation

struct Job: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var command: String
    var workingDirectory: String
    var schedule: Schedule
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        name: String = "",
        command: String = "",
        workingDirectory: String = "~",
        schedule: Schedule = .interval(minutes: 60),
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.command = command
        self.workingDirectory = workingDirectory
        self.schedule = schedule
        self.isEnabled = isEnabled
    }

    var label: String { SundialPaths.labelPrefix + id.uuidString.lowercased() }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && schedule.isValid
    }

    func workingDirectoryURL(home: URL) -> URL {
        let path = workingDirectory.trimmingCharacters(in: .whitespacesAndNewlines)
        if path.isEmpty || path == "~" { return home }
        if path.hasPrefix("~/") { return home.appending(path: String(path.dropFirst(2)), directoryHint: .isDirectory) }
        return URL(filePath: path, directoryHint: .isDirectory)
    }

    static func abbreviatedPath(_ path: String, home: URL) -> String {
        let homePath = home.path(percentEncoded: false).trimmingSuffix("/")
        if path == homePath { return "~" }
        if path.hasPrefix(homePath + "/") { return "~" + path.dropFirst(homePath.count) }
        return path
    }

    func duplicated() -> Job {
        Job(name: "\(name) Copy", command: command, workingDirectory: workingDirectory, schedule: schedule, isEnabled: isEnabled)
    }
}

private extension String {
    func trimmingSuffix(_ suffix: String) -> String {
        hasSuffix(suffix) && count > suffix.count ? String(dropLast(suffix.count)) : self
    }
}
