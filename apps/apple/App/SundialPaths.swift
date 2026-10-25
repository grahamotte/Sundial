import Foundation

struct SundialPaths {
    static let bundleIdentifier = "com.grahamotte.sundial"
    #if SUNDIAL_DEV
    static let labelPrefix = "\(bundleIdentifier).dev.job."
    static let supportFolder = "Sundial Dev"
    #else
    static let labelPrefix = "\(bundleIdentifier).job."
    static let supportFolder = "Sundial"
    #endif

    let home: URL
    let supportDirectory: URL
    let launchAgentsDirectory: URL

    init(home: URL) {
        self.home = home
        supportDirectory = home.appending(path: "Library/Application Support/\(SundialPaths.supportFolder)", directoryHint: .isDirectory)
        launchAgentsDirectory = home.appending(path: "Library/LaunchAgents", directoryHint: .isDirectory)
    }

    static var standard: SundialPaths {
        SundialPaths(home: FileManager.default.homeDirectoryForCurrentUser)
    }

    var jobsFile: URL { supportDirectory.appending(path: "jobs.json") }
    var runsDirectory: URL { supportDirectory.appending(path: "Runs", directoryHint: .isDirectory) }
}
