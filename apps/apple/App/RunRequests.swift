import Foundation

nonisolated struct RunRequests {
    static let freshness: TimeInterval = 60

    let directory: URL
    var fileManager: FileManager = .default

    func requestURL(_ jobID: UUID) -> URL { directory.appending(path: jobID.uuidString.lowercased()) }

    func request(jobID: UUID, now: Date = Date()) throws {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = requestURL(jobID)
        try Data().write(to: url, options: .atomic)
        try fileManager.setAttributes([.modificationDate: now], ofItemAtPath: url.path)
    }

    func consume(jobID: UUID, now: Date = Date()) -> Bool {
        let url = requestURL(jobID)
        guard let modified = try? fileManager.attributesOfItem(atPath: url.path)[.modificationDate] as? Date else { return false }
        try? fileManager.removeItem(at: url)
        return abs(now.timeIntervalSince(modified)) <= RunRequests.freshness
    }
}
