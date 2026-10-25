import Foundation

struct RunStore {
    static let retention: TimeInterval = 30 * 24 * 60 * 60
    static let maxLogBytes = 5_000_000

    let directory: URL
    var fileManager: FileManager = .default

    func recordURL(_ id: String) -> URL { directory.appending(path: "\(id).json") }
    func logURL(_ id: String) -> URL { directory.appending(path: "\(id).log") }

    func begin(job: Job, processID: Int32, now: Date = Date()) throws -> RunRecord {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let milliseconds = Int64((now.timeIntervalSince1970 * 1000).rounded(.down))
        let suffix = UUID().uuidString.prefix(8).lowercased()
        let record = RunRecord(
            id: String(format: "%013lld-%@", milliseconds, String(suffix)),
            jobID: job.id,
            jobName: job.name,
            command: job.command,
            startedAt: now,
            processID: processID
        )
        guard fileManager.createFile(atPath: logURL(record.id).path, contents: nil) else {
            throw CocoaError(.fileWriteUnknown, userInfo: [NSFilePathErrorKey: logURL(record.id).path])
        }
        try write(record)
        return record
    }

    func finish(_ record: RunRecord, exitCode: Int32?, signal: Int32?, now: Date = Date()) throws -> RunRecord {
        var finished = record
        finished.finishedAt = now
        finished.exitCode = exitCode
        finished.signal = signal
        try trimLog(record.id)
        try write(finished)
        return finished
    }

    func records() -> [RunRecord] {
        let decoder = JSONDecoder()
        let files = (try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        return files
            .filter { $0.pathExtension == "json" }
            .compactMap { try? decoder.decode(RunRecord.self, from: Data(contentsOf: $0)) }
            .sorted { $0.startedAt > $1.startedAt }
    }

    func log(for id: String, limit: Int = RunStore.maxLogBytes) -> String {
        guard let handle = try? FileHandle(forReadingFrom: logURL(id)) else { return "" }
        defer { try? handle.close() }
        let size = (try? handle.seekToEnd()) ?? 0
        let start = size > UInt64(limit) ? size - UInt64(limit) : 0
        try? handle.seek(toOffset: start)
        let data = (try? handle.readToEnd()) ?? Data()
        return String(decoding: data, as: UTF8.self)
    }

    func trimLog(_ id: String) throws {
        let url = logURL(id)
        let size = (try? fileManager.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.intValue ?? 0
        guard size > RunStore.maxLogBytes else { return }
        let marker = "[Sundial trimmed \(size - RunStore.maxLogBytes) earlier bytes of output]\n"
        let tail = Data(log(for: id, limit: RunStore.maxLogBytes).utf8)
        try (Data(marker.utf8) + tail).write(to: url, options: .atomic)
    }

    func prune(now: Date = Date()) {
        let cutoff = now.addingTimeInterval(-RunStore.retention)
        let keep = Set(records().filter { $0.startedAt >= cutoff }.map(\.id))
        let files = (try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
        let recorded = Set(files.filter { $0.pathExtension == "json" }.map { $0.deletingPathExtension().lastPathComponent })
        for file in files where ["json", "log"].contains(file.pathExtension) {
            let id = file.deletingPathExtension().lastPathComponent
            if keep.contains(id) { continue }
            let modified = (try? file.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            if file.pathExtension == "log" && !recorded.contains(id) && modified >= cutoff { continue }
            try? fileManager.removeItem(at: file)
        }
    }

    func delete(jobID: UUID) {
        for record in records() where record.jobID == jobID {
            try? fileManager.removeItem(at: recordURL(record.id))
            try? fileManager.removeItem(at: logURL(record.id))
        }
    }

    private func write(_ record: RunRecord) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(record).write(to: recordURL(record.id), options: .atomic)
    }
}
