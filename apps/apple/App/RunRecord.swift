import Darwin
import Foundation

nonisolated struct RunRecord: Codable, Identifiable, Hashable {
    enum Status: Hashable {
        case waiting
        case running
        case succeeded
        case failed
        case interrupted
        case skipped

        var title: String {
            switch self {
            case .waiting: return "Waiting"
            case .running: return "Running"
            case .succeeded: return "Succeeded"
            case .failed: return "Failed"
            case .interrupted: return "Interrupted"
            case .skipped: return "Skipped"
            }
        }

        var isFailure: Bool { self == .failed || self == .interrupted }
        var isActive: Bool { self == .waiting || self == .running }
    }

    struct Sleep: Codable, Hashable {
        var at: Date
        var isOnPower: Bool
    }

    var id: String
    var jobID: UUID
    var jobName: String
    var command: String
    var startedAt: Date
    var commandStartedAt: Date?
    var finishedAt: Date?
    var exitCode: Int32?
    var signal: Int32?
    var processID: Int32
    var sleeps: [Sleep] = []
    var skipped = false

    func status(isProcessAlive: (Int32) -> Bool = RunRecord.isProcessAlive) -> Status {
        if skipped { return .skipped }
        guard finishedAt != nil else {
            guard isProcessAlive(processID) else { return .interrupted }
            return commandStartedAt == nil ? .waiting : .running
        }
        return exitCode == 0 && signal == nil ? .succeeded : .failed
    }

    func duration(now: Date = Date()) -> TimeInterval {
        guard let commandStartedAt else { return 0 }
        return max(0, (finishedAt ?? now).timeIntervalSince(commandStartedAt))
    }

    func wait(now: Date = Date()) -> TimeInterval {
        max(0, (commandStartedAt ?? finishedAt ?? now).timeIntervalSince(startedAt))
    }

    func durationText(status: Status, now: Date = Date()) -> String {
        switch status {
        case .interrupted, .skipped: return "—"
        case .waiting: return RunRecord.formatDuration(wait(now: now))
        default: return RunRecord.formatDuration(duration(now: now))
        }
    }

    var sleptDuringRun: Bool { !sleeps.isEmpty }

    func waitText(status: Status, now: Date = Date()) -> String? {
        let waited = wait(now: now)
        guard status != .waiting, commandStartedAt != nil, waited >= RunRecord.noticeableWait else { return nil }
        return "Waited \(RunRecord.formatDuration(waited))"
    }

    func notes(status: Status, now: Date = Date()) -> [String] {
        var notes: [String] = []
        if sleptDuringRun { notes.append("Mac slept during run") }
        if let waitText = waitText(status: status, now: now) { notes.append(waitText) }
        return notes
    }

    var outcome: String? {
        if let signal { return "Signal \(signal)" }
        if let exitCode { return "Exit \(exitCode)" }
        return nil
    }

    static let noticeableWait: TimeInterval = 60

    static func isProcessAlive(_ processID: Int32) -> Bool {
        guard processID > 0 else { return false }
        return kill(processID, 0) == 0 || errno == EPERM
    }

    static func latestPerJob(_ runs: [RunRecord], limit: Int) -> [RunRecord] {
        let latest = Dictionary(grouping: runs, by: \.jobID).compactMap { $0.value.max { $0.startedAt < $1.startedAt } }
        return Array(latest.sorted { $0.startedAt > $1.startedAt }.prefix(max(0, limit)))
    }

    static func formatDuration(_ interval: TimeInterval) -> String {
        if interval < 1 { return "<1s" }
        let seconds = Int(interval.rounded(.down))
        if seconds < 60 { return "\(seconds)s" }
        if seconds < 3600 { return "\(seconds / 60)m \(seconds % 60)s" }
        return "\(seconds / 3600)h \(seconds % 3600 / 60)m"
    }
}

nonisolated extension RunRecord {
    private enum CodingKeys: String, CodingKey {
        case id, jobID, jobName, command, startedAt, commandStartedAt, finishedAt, exitCode, signal, processID, sleeps, skipped
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        jobID = try container.decode(UUID.self, forKey: .jobID)
        jobName = try container.decode(String.self, forKey: .jobName)
        command = try container.decode(String.self, forKey: .command)
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        finishedAt = try container.decodeIfPresent(Date.self, forKey: .finishedAt)
        exitCode = try container.decodeIfPresent(Int32.self, forKey: .exitCode)
        signal = try container.decodeIfPresent(Int32.self, forKey: .signal)
        processID = try container.decode(Int32.self, forKey: .processID)
        if container.contains(.sleeps) {
            sleeps = try container.decode([Sleep].self, forKey: .sleeps)
            commandStartedAt = try container.decodeIfPresent(Date.self, forKey: .commandStartedAt)
        } else {
            sleeps = []
            commandStartedAt = startedAt
        }
        skipped = try container.decodeIfPresent(Bool.self, forKey: .skipped) ?? false
    }
}
