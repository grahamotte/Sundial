import Foundation

struct JobStore {
    let url: URL
    var fileManager: FileManager = .default

    func load() throws -> [Job] {
        guard fileManager.fileExists(atPath: url.path) else { return [] }
        return try JSONDecoder().decode([Job].self, from: Data(contentsOf: url))
    }

    func save(_ jobs: [Job]) throws {
        try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(JobStore.sorted(jobs)).write(to: url, options: .atomic)
    }

    static func sorted(_ jobs: [Job]) -> [Job] {
        jobs.sorted {
            let order = $0.name.localizedStandardCompare($1.name)
            return order == .orderedSame ? $0.id.uuidString < $1.id.uuidString : order == .orderedAscending
        }
    }
}
